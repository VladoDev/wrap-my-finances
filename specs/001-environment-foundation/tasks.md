---

description: "Task list for Fundación de Entornos (dev / prod)"
---

# Tasks: Fundación de Entornos (dev / prod)

**Input**: Design documents from `/specs/001-environment-foundation/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md (all present; no `contracts/` — this feature exposes no external interface)

**Tests**: Included. The project constitution's Development Standards require a test for every repository and an automated Security Rules suite in CI, so test tasks are not optional here even though they are not written before their implementation (this feature does not mandate strict TDD ordering, only coverage).

**Organization**: Tasks are grouped by user story (see spec.md) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4, US5, US6)
- Every task states its exact file path or command

## Path Conventions

Single Flutter mobile project at the repository root (`lib/`, `android/`, `ios/`, `test/`), per `plan.md`'s Project Structure. No `backend/`/`frontend/` split — Firebase is configured, not coded.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, identifiers, and tooling

- [X] T001 Decide and record the `yourorg` org segment and confirm final identifiers (Dart package `wrap_my_finances`, Android/iOS application ID `com.vlad.wrapmyfinances[.dev]`, Firebase project IDs `wrap-my-finances-dev`/`wrap-my-finances-prod`) per `docs/ENVIRONMENTS.md` §0; update that table if any value changes from the documented default — resolved: org segment is `vlad`
- [X] T002 Run `flutter create` to bootstrap the project skeleton at the repository root with package name `wrap_my_finances`, targeting iOS 14+ and Android API 24+ — deployment target later raised to iOS 15+ across the project (see T017/T023 notes and `docs/TECH_STACK.md`); `flutter create` itself doesn't take an iOS minimum-version flag, the target lives in Xcode project settings
- [X] T003 [P] Add `pubspec.yaml` dependencies: `firebase_core`, `cloud_firestore`, `firebase_auth`, `get_it`, `injectable` (+ `injectable_generator`, `build_runner` as dev dependencies), `flutter_launcher_icons`, `flutter_flavorizr` (dev dependency); run `flutter pub get` — also added `flutter_riverpod`/`riverpod_annotation` (required by Constitution Principle 4's "widgets never touch getIt directly" bridge pattern); `custom_lint`/`riverpod_lint` and `freezed`/`freezed_annotation` were attempted but dropped — see Notes
- [X] T004 [P] Configure `very_good_analysis` in `analysis_options.yaml`
- [X] T005 Delete the generated `lib/main.dart` — this project has no default entrypoint by design, so omitting `-t` fails loudly instead of building the wrong flavor (`docs/ENVIRONMENTS.md` §3) — also removed the default `test/widget_test.dart`, which tested the now-deleted counter app

**Checkpoint**: Project skeleton exists and is correctly named; ready for environment provisioning.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Infrastructure shared by every user story — both Firebase projects, both native flavor configurations, and the app shell that renders the diagnostics screen

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T006 [P] Create the Firebase project `wrap-my-finances-dev` via `firebase projects:create` (`docs/ENVIRONMENTS.md` §5.3); report the created project ID before proceeding; stop and report if project-creation quota is hit — created; had to drop the parenthesized display name `"Wrap My Finances (Dev)"` (GCP rejects parentheses) in favor of `"Wrap My Finances Dev"` — corrected in `docs/ENVIRONMENTS.md` §5.3
- [X] T007 [P] Create the Firebase project `wrap-my-finances-prod` via `firebase projects:create` (`docs/ENVIRONMENTS.md` §5.3); report the created project ID before proceeding — created as `"Wrap My Finances"`
- [X] T007b Enable Anonymous sign-in in the Authentication console for both projects. 
No stable CLI equivalent — emit both console URLs and pause if unable. — confirmed enabled on both via the Identity Toolkit config API after the user enabled it in-console; a programmatic attempt via `identityPlatform:initializeAuth` hit `BILLING_NOT_ENABLED` (that endpoint is the paid Identity Platform upgrade, not plain Firebase Auth) — confirms the doc's "no stable CLI equivalent" note was correct
- [X] T008 Confirm the Firestore database location with the user, then provision the default Firestore database in `wrap-my-finances-dev` via `firebase firestore:databases:create` (`docs/ENVIRONMENTS.md` §5.3) (depends on T006) — user chose `us-central1`; also had to enable the Firestore API itself first (`gcloud services enable firestore.googleapis.com`), which required installing `gcloud` CLI (not previously present) and its own separate login
- [X] T009 Provision the default Firestore database in `wrap-my-finances-prod`, using the same location confirmed in T008 (depends on T007, T008) — done
- [X] T009b Run `firebase init firestore` against the dev project to create 
`firebase.json`, `firestore.rules`, and `firestore.indexes.json`. Populate 
firestore.rules with the base ruleset from docs/DATA_MODEL.md (owner checks + 
trailing catch-all). Add an `emulators` block for `auth` and `firestore` to 
firebase.json per docs/ENVIRONMENTS.md §6. (depends on T008) — done via hand-written files instead of the interactive `firebase init` wizard (not yet authenticated at this point); also included the `env_checks` block up front (normally T033) since writing the whole rules file once was simpler than two passes
- [X] T009c Scaffold the Security Rules test project: firebase/tests/package.json with 
@firebase/rules-unit-testing and a test script that runs against the emulator suite. — `npm install` succeeded after correcting the version to the real latest (`^4.1.0` doesn't exist; used `^5.0.1`)
- [X] T010 Run flutter_flavorizr to generate both Android product flavors and iOS build 
configurations/schemes. Treat output as a starting point. — ran via `dart run flutter_flavorizr -f`; its generic Dart scaffolding (main.dart, flavors.dart, app.dart, pages/) was discarded in favor of this feature's own bootstrap/app/entrypoint design, keeping only the native Android/iOS output
- [X] T011 Hand-review and correct android/app/build.gradle.kts against docs/ENVIRONMENTS.md 
§4 (applicationIdSuffix, resValue app_name). (depends on T010) — inlined flavorizr's separate `flavorizr.gradle.kts` directly into `build.gradle.kts` per the documented pattern; fixed `namespace`/`applicationId` (flavorizr had left the default `com.vlad.wrap_my_finances` with an underscore) to `com.vlad.wrapmyfinances`, and moved `MainActivity.kt` to match
- [X] T011b Hand-review iOS configurations and schemes; confirm all six configs exist and 
scheme names are exactly `dev` and `prod`. (depends on T010) — confirmed: Debug-dev/Release-dev/Profile-dev/Debug-prod/Release-prod/Profile-prod all present with correct `PRODUCT_BUNDLE_IDENTIFIER`, plus `dev.xcscheme`/`prod.xcscheme`
- [X] T012 [P] Create `lib/core/config/app_environment.dart` with the `AppEnvironment` enum (`dev`, `prod`; fields `name`, `showDebugBanner`, `allowSeeding`, `firestoreCollectionPath`) per `data-model.md` (depends on T002)
- [X] T013 [P] Create `lib/core/di/injection.dart` with `configureDependencies(AppEnvironment env)` registering the environment singleton via `get_it`/`injectable`; run `dart run build_runner build` to generate `lib/core/di/injection.config.dart` (depends on T002) — also added `lib/core/di/providers.dart` with the Riverpod bridge provider (`appEnvironmentProvider`) per Constitution Principle 4 ("widgets never touch getIt directly")
- [X] T014 Create `lib/app.dart` with a `MaterialApp.router` whose single route renders `EnvironmentStatusPage` (depends on T012) — added `go_router` dependency to match the project's routing convention
- [X] T015 Create `lib/bootstrap.dart`: `WidgetsFlutterBinding.ensureInitialized()`, `Firebase.initializeApp(options:)`, Firestore settings (`persistenceEnabled: true`, `cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED`), a fire-and-forget `FirebaseAuth.instance.signInAnonymously()` call (not awaited, per `research.md`), `configureDependencies(env)`, `runApp(App())` — no flavor-consistency check yet, added in US5 (depends on T013, T014, T007b)
- [X] T016 [P] Create `lib/core/diagnostics/presentation/pages/environment_status_page.dart`: reads `AppEnvironment` from the DI container, displays its name, and renders a debug banner only when `showDebugBanner` is true (depends on T012) — the "write test document" control (US4/T032) is not yet added

**Checkpoint**: Foundation ready — both Firebase projects exist, both native flavors are configured, and the app shell can render. User story implementation can now begin.

---

## Phase 3: User Story 1 - Dev variant runs and connects to dev (Priority: P1) 🎯 MVP

**Goal**: `flutter run --flavor dev -t lib/main_dev.dart` launches the app connected to `wrap-my-finances-dev`, with a visible dev indicator.

**Independent Test**: Run the command above and confirm the app opens showing the dev indicator.

### Tests for User Story 1

- [X] T021 [P] [US1] Widget test in `test/core/diagnostics/presentation/environment_status_page_dev_test.dart` asserting the debug banner is visible when `AppEnvironment.dev` is active

### Implementation for User Story 1

- [X] T017 [US1] Run `flutterfire configure` for `wrap-my-finances-dev`, producing `lib/core/config/firebase_options_dev.dart`, `android/app/src/dev/google-services.json`, `ios/flavors/dev/GoogleService-Info.plist` (`docs/ENVIRONMENTS.md` §5.4) (depends on T006, T009, T010, T011) — installed `flutterfire_cli` (was not present); command also correctly auto-wired the `com.google.gms.google-services` Gradle plugin
- [X] T018 [US1] Create `lib/main_dev.dart`: `void main() => bootstrap(AppEnvironment.dev, DefaultFirebaseOptions.currentPlatform);` (depends on T017, T015)
- [X] T019 [P] [US1] Add the iOS Run Script build phase (before "Compile Sources") that copies `ios/flavors/${FLAVOR:-dev}/GoogleService-Info.plist` into the built app bundle (`docs/ENVIRONMENTS.md` §4) (depends on T017) — superseded: `flutterfire configure` already added its own `PBXShellScriptBuildPhase` ("FlutterFire: flutterfire bundle-service-file") to the Runner target, which resolves the correct plist per build configuration from `firebase.json` — more robust than a hand-rolled `${FLAVOR:-dev}` guess since it doesn't depend on an env var being set at all. Confirmed it's wired into the target's `buildPhases` list. It only had 2 of 6 iOS build configurations mapped in `firebase.json` (`Debug-dev`, `Release-prod`) — added the missing `Release-dev`, `Profile-dev`, `Debug-prod`, `Profile-prod` entries by hand, per `docs/ENVIRONMENTS.md` §5.4's own warning that this gap is expected
- [X] T020 [P] [US1] Configure the dev app icon (coral badge overlay) and confirm the "Wrap Dev" display name via `flutter_launcher_icons`, scoped to the dev flavor (depends on T010) — redesigned per user direction into a real icon with a "DEV" ribbon banner overlay, generated in light/dark variants by `tool/generate_app_icon.dart` (kept, not deleted — it's the source of truth for this art) using `package:image`; wired via `flavorizr.yaml`'s `icon` fields instead of `flutter_launcher_icons` (redundant second tool, removed from `pubspec.yaml`); confirmed `AppIcon-dev.appiconset`/`AppIcon-prod.appiconset` and per-flavor Android mipmaps generated correctly. **Redesigned a second time**: the initial wallet + ribbon-bow "wrapped-gift" motif was rejected by the user as off-concept and not minimalist; replaced with a receipt (torn/zigzag bottom edge, line-item bars) + coin — a direct, unambiguous "expense tracker" glyph with no product-name wordplay. Same script, same file names, same DEV ribbon treatment; only `buildBaseIcon()`'s composition changed. **Redesigned a third time**: the receipt was also rejected ("no me gustó para nada"); rebuilt from scratch per a user-supplied reference image (a flat-outline piggy bank with a coin dropping into the slot, motion lines, growth arrow) on a new mint-to-teal gradient (was coral/gold). Added `fillEllipse`/`outlinedEllipse`/`thickLine`/`arrowHead` helpers to `tool/generate_app_icon.dart` to approximate the reference's curved silhouette using only ellipse/rect/polygon primitives (`package:image` has no native ellipse or stroked-path support). DEV ribbon overlay untouched throughout all three redesigns, per explicit instruction to keep it
- [X] T022 [US1] Run `flutter run --flavor dev -t lib/main_dev.dart` and confirm against `quickstart.md` step 1 that the app launches connected to `wrap-my-finances-dev` with the dev indicator visible (depends on T018, T019, T020, T021) — built and ran via `flutter build ios --simulator` + `simctl install/launch` (interactive `flutter run` isn't practical in this non-interactive session); screenshot confirmed "Environment: dev", the DEV BUILD banner, and the write-probe button all render correctly

**Checkpoint**: US1 is independently functional and testable.

---

## Phase 4: User Story 2 - Prod variant runs clean (Priority: P1)

**Goal**: `flutter run --flavor prod -t lib/main_prod.dart` launches connected to `wrap-my-finances-prod`, with zero debug affordances.

**Independent Test**: Run the command above and confirm no debug indicator, menu, or seed control appears anywhere.

### Tests for User Story 2

- [X] T026 [P] [US2] Widget test in `test/core/diagnostics/presentation/environment_status_page_prod_test.dart` asserting no debug banner and no probe-write control render when `AppEnvironment.prod` is active

### Implementation for User Story 2

- [X] T023 [US2] Run `flutterfire configure` for `wrap-my-finances-prod`, producing `lib/core/config/firebase_options_prod.dart`, `android/app/src/prod/google-services.json`, `ios/flavors/prod/GoogleService-Info.plist` (`docs/ENVIRONMENTS.md` §5.4) (depends on T007, T009, T010, T011)
- [X] T024 [US2] Create `lib/main_prod.dart`: `void main() => bootstrap(AppEnvironment.prod, DefaultFirebaseOptions.currentPlatform);` (depends on T023, T015)
- [X] T025 [P] [US2] Configure the prod app icon (clean, no badge) and confirm the "Wrap" display name via `flutter_launcher_icons`, scoped to the prod flavor (depends on T010) — same base artwork as dev, without the ribbon banner; see T020 note
- [X] T027 [US2] Run `flutter run --flavor prod -t lib/main_prod.dart --release` and confirm against `quickstart.md` step 2 that the app launches connected to `wrap-my-finances-prod` with zero debug indicators (depends on T024, T025, T026) — the iOS Simulator does not support `--release`/`--profile` builds at all ("not supported for simulators"), so this was verified with a `--debug` build instead: confirmed "Environment: prod", no coral DEV banner, no probe button. Flutter's own framework "DEBUG" corner ribbon is still visible in this build mode — that's Flutter's, not ours, and unrelated to FR-006. Also independently verified on Android (emulator, debug build): same result, "Environment: prod", no banner/button. A true `--release` check on either platform still needs a physical device or a release-capable emulator config — the one remaining gap

**Checkpoint**: US1 and US2 both independently functional.

---

## Phase 5: User Story 4 - Data isolation via probe document (Priority: P1)

**Goal**: A document written from `dev` never appears in `prod`, and vice versa.

**Independent Test**: Write a probe document from the running `dev` build, then confirm from the `prod` project's console that it does not exist there (and repeat in the opposite direction).

### Tests for User Story 4

- [X] T034 [P] [US4] Write Security Rules tests in `firebase/tests/env_checks.rules.test.js` (against the local emulator, using `initializeTestEnvironment`'s authenticated/unauthenticated contexts) covering: an authenticated well-formed probe write is accepted, an authenticated malformed one (wrong type / extra field / oversized `label`) is rejected, an unauthenticated probe write is rejected, and a write to an undeclared top-level collection is still denied by the trailing catch-all (depends on T009c) — all 6 pass against `firebase emulators:exec` (required installing a JDK via Homebrew — see Notes)
- [X] T035 [US4] Unit test in `test/core/diagnostics/data/firestore_environment_probe_repository_test.dart` against `fake_cloud_firestore` confirming the written document uses a client-generated ID and never a server timestamp (depends on T030) — 2 tests pass; added `fake_cloud_firestore`, `firebase_auth_mocks`, `mocktail` as dev dependencies

### Implementation for User Story 4

- [X] T028 [P] [US4] Create `lib/core/diagnostics/domain/entities/environment_probe.dart` (`EnvironmentProbe`: `id`, `environmentName`, `createdAtMillis`, `label`) per `data-model.md`
- [X] T029 [P] [US4] Create `lib/core/diagnostics/domain/repositories/environment_probe_repository.dart`, an abstract repository with `writeProbe(String label)` and `readLatest()`, returning `Result<EnvironmentProbe>` — also created `lib/core/errors/{result,failure}.dart` (hand-written sealed classes, not `freezed` — see Notes)
- [X] T030 [US4] Implement `lib/core/diagnostics/data/repositories/firestore_environment_probe_repository.dart`: awaits `FirebaseAuth.instance.currentUser` (or the pending anonymous sign-in future if still `null`) to satisfy the rule's `request.auth != null`, then writes with a client-generated doc ID (`collection.doc()`) to `env_checks/{docId}`, never awaiting server acknowledgement before returning (depends on T028, T029, T015)
- [X] T031 [US4] Register `EnvironmentProbeRepository` in `lib/core/di/injection.dart` and re-run `dart run build_runner build` (depends on T030, T013) — added `lib/core/di/firebase_module.dart` (`@module` providing `FirebaseFirestore`/`FirebaseAuth` singletons, required for `@LazySingleton` constructor injection)
- [X] T032 [US4] Add the "write test document" control to `environment_status_page.dart`, rendered only when `allowSeeding` is true, calling the repository and displaying the resulting document ID (depends on T016, T031)
- [X] T033 [P] [US4] Append the `env_checks` Security Rules block to `firestore.rules`, immediately before the trailing catch-all: `allow read, create` both require `request.auth != null`, `create` additionally requires `isValidEnvironmentProbe()`, `update`/`delete` are `false` — per `data-model.md` — done early, as part of T009b (writing the whole rules file in one shot)
- [X] T036 [US4] Deploy `firestore.rules` to `wrap-my-finances-dev` only, via `firebase deploy --only firestore:rules -P dev` (depends on T033)
- [X] T037 [US4] Execute `quickstart.md` steps 4 and 5 (data isolation in both directions, offline write) and confirm a probe document written from `dev` never appears in `prod` and vice versa (depends on T032, T034, T035, T036, T027) — step 4 verified live: tapping the button in the running dev app (via a new `integration_test/environment_probe_test.dart`, since OS-level UI automation isn't available in this environment) wrote `env_checks/DMqXWveGf7Lz9hzOPe1k` to `wrap-my-finances-dev` (HTTP 200) and confirmed absent from `wrap-my-finances-prod` (HTTP 404); reverse direction confirmed by writing a doc directly to `prod` and confirming 404 from `dev`. Step 5 (offline) verified by code/unit-test inspection rather than a live airplane-mode run: `writeProbe()` never awaits server acknowledgement and uses a client-generated ID (T035's unit test already asserts this)

**Checkpoint**: All P1 stories (US1, US2, US4) complete — MVP achieved.

---

## Phase 6: User Story 3 - Both variants coexist on one device (Priority: P2)

**Goal**: `dev` and `prod` builds install and run simultaneously on one device without conflict.

**Independent Test**: Install both builds on the same device/emulator; confirm two distinct apps with distinct icons and names, and that uninstalling one does not affect the other.

- [X] T038 [US3] Review the Android `applicationId` (`com.vlad.wrapmyfinances` + `.dev` suffix, from T010) and iOS bundle identifiers (from T011) and confirm they resolve to two distinct installable identifiers — confirmed: `com.vlad.wrapmyfinances` vs `com.vlad.wrapmyfinances.dev` on both platforms
- [X] T039 [US3] Install the dev build then the prod build on the same physical device or emulator and confirm distinct home-screen icons and labels ("Wrap Dev" vs "Wrap"), per `quickstart.md` step 3 (depends on T022, T027, T038) — verified on the iOS Simulator via `xcrun simctl listapps`: `CFBundleIdentifier`/`CFBundleName` confirmed distinct (`com.vlad.wrapmyfinances` / "Wrap" vs `com.vlad.wrapmyfinances.dev` / "Wrap Dev"); icons independently confirmed distinct via the generated `AppIcon-dev`/`AppIcon-prod` appiconsets (T020)
- [X] T040 [US3] Uninstall the dev build and confirm the prod build continues to run unaffected, per `quickstart.md` step 3 (depends on T039) — uninstalled `com.vlad.wrapmyfinances.dev`, relaunched `com.vlad.wrapmyfinances`, confirmed it still runs correctly

**Checkpoint**: US3 complete.

---

## Phase 7: User Story 5 - Mismatched flavor fails loudly (Priority: P2)

**Goal**: A build whose native flavor disagrees with its Dart entrypoint fails at startup with a clear message, before any Firebase connection.

**Independent Test**: Run `--flavor prod -t lib/main_dev.dart` (and the reverse) and confirm the app refuses to start.

### Tests for User Story 5

- [X] T043 [US5] Unit tests in `test/core/config/flavor_guard_test.dart` covering matching `dev`/`dev`, matching `prod`/`prod`, `dev`-native-with-`prod`-entrypoint, and `prod`-native-with-`dev`-entrypoint cases (depends on T041) — all 5 tests pass (added a 5th: no native flavor at all)

### Implementation for User Story 5

- [X] T041 [P] [US5] Create `lib/core/config/flavor_guard.dart` with the pure function `checkFlavorConsistency({required String? appFlavor, required AppEnvironment env})`, returning a mismatch description or `null`, per `research.md`
- [X] T042 [US5] Wire the guard into `lib/bootstrap.dart` as its first statement, throwing with a message naming both the native flavor and the Dart environment before `Firebase.initializeApp` is called (depends on T041, T015)
- [X] T044 [US5] Execute `quickstart.md` step 6: run `--flavor prod -t lib/main_dev.dart`, `--flavor dev -t lib/main_prod.dart`, and `--flavor dev` with no `-t`, and confirm all three fail loudly before any Firebase call (depends on T042, T043) — all three verified on the iOS Simulator: (1) native=prod/dart=dev → device log shows `Flavor mismatch: native flavor "prod" vs Dart env "dev"`; (2) native=dev/dart=prod → `Flavor mismatch: native flavor "dev" vs Dart env "prod"`; (3) `flutter build ios --flavor dev` with no `-t` → fails immediately at the tooling level with `Target file "lib/main.dart" not found.`, before any Xcode build even starts

**Checkpoint**: US5 complete.

---

## Phase 8: User Story 6 - Symmetric rules deployment, safe default (Priority: P3)

**Goal**: The same rules/indexes deploy to both projects from the same files; the default deploy target is `dev`; `prod` requires explicit confirmation.

**Independent Test**: Deploy to both projects from the same files and diff the result; run the default deploy command and confirm it lands on `dev`.

- [X] T045 [P] [US6] Create `.firebaserc` with `projects.default` = `wrap-my-finances-dev`, plus explicit `dev` and `prod` aliases, per `docs/ENVIRONMENTS.md` §5.5
- [X] T046 [US6] Deploy `firestore.rules` and `firestore.indexes.json` to `wrap-my-finances-dev` via `firebase deploy --only firestore:rules,firestore:indexes -P dev` (depends on T033, T045)
- [X] T047 [US6] After obtaining explicit human confirmation (per the constitution's Agent Operating Rules — prod deploys are never a one-step default), deploy the same files to `wrap-my-finances-prod` via `firebase deploy --only firestore:rules,firestore:indexes -P prod` (depends on T046) — asked for and received fresh, explicit confirmation via AskUserQuestion immediately before running this specific command
- [X] T048 [US6] Compare the deployed rules and indexes between both projects (e.g. `firebase firestore:rules:get` per project, or console export) and confirm they are identical, per `quickstart.md` step 7 (depends on T047) — fetched both deployed rulesets via the Firebase Rules API and diffed them: byte-identical (92 lines, zero diff)
- [X] T049 [US6] Execute `quickstart.md` step 8: run `firebase deploy --only firestore:rules,firestore:indexes` with no `-P` flag and confirm the CLI targets `wrap-my-finances-dev` (depends on T045) — confirmed: CLI output read "Deploying to 'wrap-my-finances-dev'..."

**Checkpoint**: All user stories complete.

---

## Phase 9: Polish & Cross-Cutting Concerns

- [X] T050 [P] Confirm `.gitignore` already excludes `google-services.json`, `GoogleService-Info.plist`, and any service-account files; add any missing entries (Constitution Development Standards) — done early alongside T009b; also added keystore/provisioning-profile and Firebase/Node emulator-log patterns
- [X] T051 Run the full `quickstart.md` validation end-to-end (all 8 steps in sequence) as the final acceptance pass for this feature (depends on T037, T040, T044, T048, T049) — all 8 steps passed across this session, on **both** iOS Simulator and the Android emulator (a Fold device, tested on its unfolded/tablet-sized inner display): 1/2 dev+prod launch and connect correctly (debug-mode substituted for release on both platforms' emulators — neither supports release/profile builds for emulated targets, documented gap needing a physical device); 3 coexistence confirmed via `simctl`/`adb`+`aapt` (distinct package IDs, labels, and installed-app lists on both platforms); 4 data isolation confirmed live in both directions against the real projects, independently from both an iOS and an Android build via `integration_test`; 5 offline-write behavior confirmed by code/unit-test inspection; 6 all three flavor-mismatch scenarios confirmed via device logs on both platforms; 7 rules diffed byte-identical between projects; 8 default deploy confirmed targeting dev. `flutter analyze` and `flutter test` (9 tests) both clean; Security Rules suite (6 tests) passing against the emulator. Remaining gap: a true `--release`/`--profile` build (as opposed to `--debug`) on either platform, which requires a physical device or a differently-configured emulator — not blocking, since FR-006 (no debug UI) is governed by our own `AppEnvironment.prod` flag, not Flutter's build mode

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational completion; within that constraint:
  - US1, US2, US4 (all P1) have no dependencies on each other and can proceed in parallel
  - US3 depends on US1 and US2 being runnable (it installs both builds)
  - US5 has no dependency on US1/US2/US3/US4 beyond Foundational — it only touches `bootstrap.dart`/`flavor_guard.dart`
  - US6 depends on US4 (T033 adds the rules block that US6 deploys symmetrically)
- **Polish (Phase 9)**: Depends on all six user stories being complete

### Within Each User Story

- US1: flutterfire config → entrypoint → (iOS copy script, icon) in parallel → run & verify
- US2: mirrors US1 for the prod flavor
- US4: entity + repository interface in parallel → Firestore impl → DI registration → UI control; rules block and its tests proceed in parallel to the Dart-side work; deploy-to-dev and full verification come last
- US5: guard function → wire into bootstrap → tests → verify via quickstart
- US6: `.firebaserc` → deploy dev → deploy prod (with confirmation) → diff → verify default target

### Parallel Opportunities

- Setup: T003, T004 in parallel
- Foundational: T006/T007 (the two Firebase project creations) in parallel; T010/T011 (Android/iOS native config) in parallel; T012/T013/T016 in parallel
- Once Foundational completes: US1, US2, US4, and US5 can be staffed and worked in parallel (US3 and US6 wait on US1/US2 and US4 respectively)
- Within US1: T019, T020, T021 in parallel after T017/T018
- Within US2: T025, T026 in parallel after T023/T024
- Within US4: T028, T029 in parallel; T033, T034 in parallel with the Dart-side chain

---

## Parallel Example: Foundational Phase

```bash
# Launch both Firebase project creations together:
Task: "Create the Firebase project wrap-my-finances-dev via firebase projects:create"
Task: "Create the Firebase project wrap-my-finances-prod via firebase projects:create"

# Launch native flavor configuration together:
Task: "Configure Android product flavors in android/app/build.gradle.kts"
Task: "Configure iOS build configurations and schemes in ios/Runner.xcodeproj"
```

## Parallel Example: User Story 4

```bash
# Launch the domain-layer pieces together:
Task: "Create EnvironmentProbe entity in lib/core/diagnostics/domain/entities/environment_probe.dart"
Task: "Create EnvironmentProbeRepository interface in lib/core/diagnostics/domain/repositories/environment_probe_repository.dart"

# Launch the Security Rules work in parallel with the Dart-side chain:
Task: "Append the env_checks rules block to firestore.rules"
Task: "Write Security Rules tests in firebase/tests/env_checks.rules.test.js"
```

---

## Implementation Strategy

### MVP First (User Stories 1, 2, and 4 — all P1)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks everything)
3. Complete Phase 3 (US1), Phase 4 (US2), and Phase 5 (US4) — together these three P1 stories are the feature's Definition of Done: both flavors run, connect to their own project, and data isolation is proven
4. **STOP and VALIDATE**: run `quickstart.md` steps 1, 2, 4, and 5
5. This is the MVP — everything else hardens it

### Incremental Delivery

1. Setup + Foundational → foundation ready
2. US1 → dev variant runs → verify independently
3. US2 → prod variant runs clean → verify independently
4. US4 → data isolation proven → verify independently → **MVP complete**
5. US3 → coexistence on one device confirmed
6. US5 → mismatched-build guard in place
7. US6 → symmetric, safe-by-default rules deployment
8. Polish → final full quickstart pass

### Parallel Team Strategy

With multiple developers, after Foundational completes:
- Developer A: US1 then US3 (needs US1+US2)
- Developer B: US2
- Developer C: US4 then US6 (needs US4)
- Developer D: US5 (fully independent of the others beyond Foundational)

---

## Notes

- [P] tasks touch different files and have no dependency on an incomplete task
- [Story] labels map every user-story-phase task back to spec.md for traceability
- No task in Setup or Foundational carries a [Story] label, per the checklist format rules
- The `env_checks` collection and its rule are intentionally temporary scaffolding (see `research.md`); they are expected to be removed once a real feature supersedes the diagnostics screen
- Commit after each task or logical group; stop at any checkpoint to validate a story independently before moving on
- T006/T007 (project creation) and T047 (prod deploy) are the only tasks in this list that touch real, potentially costly or hard-to-reverse cloud state — follow the constitution's Agent Operating Rules for confirmation before running them
- **Environment note**: the Firestore/Auth emulator (needed to run T034) requires a JVM; none was present, so `openjdk` was installed via Homebrew (with explicit confirmation) and added to `PATH` in `.zshrc`.
- **Tooling drift (reported per Constitution Agent Operating Rules, not routed around silently)**: as of the dependency versions available today, `custom_lint`/`riverpod_lint` (listed in the constitution's Development Standards) cannot resolve alongside `injectable_generator` — every `custom_lint` release caps `analyzer` at `<8.0.0`, while `injectable_generator >=3.1.1` requires `analyzer >=10.0.0`. This is independent of `flutter_launcher_icons`/`freezed`. Resolution: `custom_lint`/`riverpod_lint` were **not** added; `very_good_analysis` (T004) is in place and passing. Revisit once the ecosystem catches up — do not force it by pinning `injectable_generator` back. `freezed`/`freezed_annotation` were also dropped (not blocked, just unnecessary): `core/errors/result.dart`/`failure.dart` (T029) are hand-written native Dart `sealed class`es instead, which need no code generator and sidestep the conflict entirely.
- **Follow-up fix**: `flutter build ios` triggered a one-time Xcode project-format upgrade ("Updating project for Xcode compatibility") that, as a side effect, wrote `DEVELOPMENT_TEAM = SKYD23YRT4;` (this machine's local Apple Developer Team ID, picked up ambiently from Xcode/keychain state) into 9 build configurations. That value was removed before committing — code signing is an explicit Phase 4 concern per `ROADMAP.md`, and hardcoding one machine's team ID would break builds for anyone else (including CI) without that team's access. Re-run this check after any future `flutter build ios` that logs a project-upgrade message: `grep -c DEVELOPMENT_TEAM ios/Runner.xcodeproj/project.pbxproj` should be `0` before committing.
