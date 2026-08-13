---

description: "Task list for Cuentas Vinculadas e Integridad de la Aplicación"
---

# Tasks: Cuentas Vinculadas e Integridad de la Aplicación

**Input**: Design documents from `/specs/007-account-linking-integrity/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Included, per the constitution's Testing-floor standard `004`–`006` all followed. This
feature's acceptance criteria (no data loss/duplication on link, explicit conflict resolution,
offline resilience, permanent deletion, category-history invariants) are automated-measurable, not
eyeballed. `firebase_auth_mocks`' `MockUser`/`MockFirebaseAuth` are mocktail-backed (confirmed by
reading the installed package source — `linkWithCredential`/`signInWithCredential` delegate via
`noSuchMethod`), so `credential-already-in-use` and other `FirebaseAuthException` codes are
stubbable with ordinary `when()` calls, the same pattern every prior feature's auth-adjacent tests
already use.

**Organization**: Tasks are grouped by user story (see spec.md), but **not in spec numbering
order** for the P1 tier — the same deliberate reordering `006` used when a later-numbered story's
machinery is a prerequisite for an earlier-numbered one. Spec's `US1` (link, happy path) is built
first since it is the simplest complete slice. `US3` (conflict resolution) builds the
merge/discard machinery `US1`'s own linking calls can trigger. `US2` (recover history on a new
device) turns out, on inspection, to be `US3`'s exact conflict machinery exercised with a *trivially
empty* local history — not a separate code path — so it is built last among the three and adds
only that one refinement. `US5` (App Check) is fully independent of all account-linking work and
could run in parallel with any of it. `US4`/`US6`/`US7` (P2) and `US8` (P3) layer on afterward.
Every task still carries its correct spec story label for traceability.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Which user story this task belongs to (US1–US8)
- Every task states its exact file path or command

## Path Conventions

Single Flutter mobile project at the repository root (`lib/`, `test/`, `firebase/tests/`), per
`plan.md`'s Project Structure. Widens `lib/features/auth/`, `lib/features/categories/`,
`lib/features/user_profile/`; adds `lib/features/settings/`.

---

## Phase 1: Setup

**Purpose**: Add the three new dependencies this feature is the first to need

- [X] T001 Add `firebase_app_check`, `google_sign_in`, and `sign_in_with_apple` to `pubspec.yaml`
      dependencies (per `docs/ROADMAP.md` Phase 3 and `research.md` #8); run `flutter pub get` and
      confirm clean

**Checkpoint**: Dependencies ready; proceed to Foundational.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Localization keys, the Security Rules changes every write in this feature needs,
`UserProfile`/`CategoryRepository` widened, the Settings screen's shell (route + nav + section
list), and the new domain types/contract every account-linking story builds on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Localization

- [X] T002 [P] Add `settings_*` ARB keys to `lib/l10n/app_en.arb` (template): screen/section
      titles (`settingsTitle`, `settingsAccountSection`, `settingsCategoriesSection`,
      `settingsPreferencesSection`), linking (`settingsLinkAccountCta`, `settingsLinkedAsLabel`
      with a provider-name placeholder, `settingsLinkGoogleOption`, `settingsLinkAppleOption`,
      `settingsLinkUnavailableOfflineMessage`), conflict resolution
      (`settingsLinkConflictTitle`, `settingsLinkConflictBody`, `settingsLinkConflictMergeOption`,
      `settingsLinkConflictDiscardOption`, `settingsLinkConflictDiscardConfirmTitle`,
      `settingsLinkConflictDiscardConfirmBody`), account deletion
      (`settingsDeleteAccountCta`, `settingsDeleteAccountConfirmTitle`,
      `settingsDeleteAccountConfirmBody`, `settingsDeleteAccountReauthMessage`), category
      management (`settingsCategoryCreateCta`, `settingsCategoryEditorNameLabel`,
      `settingsCategoryArchiveCta`, `settingsCategoryUnarchiveCta`,
      `settingsCategoryArchivedLabel`), preferences (`settingsCurrencyLabel`,
      `settingsTimeZoneLabel`) — each with an `@`-metadata `description`, no native-review flag
      required (`research.md` #10)
- [X] T003 [P] Add the Spanish translations for those keys to `lib/l10n/app_es.arb`
- [X] T004 [P] Add the Portuguese translations to `lib/l10n/app_pt.arb`
- [X] T005 [P] Add the Italian translations to `lib/l10n/app_it.arb`
- [X] T006 [P] Add the French translations to `lib/l10n/app_fr.arb`
- [X] T007 Run `flutter gen-l10n` to regenerate `lib/l10n/generated/app_localizations*.dart`
      (depends on T002–T006)

### Security Rules

- [X] T008 [P] Update `firestore.rules` per `contracts/security-rules-delta.md`: add the
      `currencyCode` validation clause to `isValidUserProfile()`; change `allow delete` from
      `false` to `isOwner(userId)` on both `users/{userId}` and its `categories/{categoryId}`
      subcollection (depends on nothing — can run in parallel with T002–T007)
- [X] T009 Extend `firebase/tests/users.rules.test.js` and `firebase/tests/categories.rules.test.js`
      with the cases from `contracts/security-rules-delta.md` § Required test additions (owner
      delete succeeds, cross-user delete denied, valid/malformed `currencyCode`); run
      `firebase emulators:exec --only firestore "cd firebase/tests && npm test"` and confirm all
      pass, including every pre-existing case unmodified (depends on T008)

### `UserProfile` widened (`currencyCode`)

- [X] T010 [P] Add `currencyCode` (`String?`) to
      `lib/features/user_profile/domain/entities/user_profile.dart`, per `data-model.md` §1
- [X] T011 [P] Add `currencyCode` to `UserProfileModel`
      (`lib/features/user_profile/data/models/user_profile_model.dart`) `fromJson`/`toJson`/
      `toEntity` (depends on T010)
- [X] T012 Add `updateCurrencyCode(userId, currencyCode)` and `updateTimeZone(userId, timeZone)`
      to `UserProfileRemoteDataSource`
      (`lib/features/user_profile/data/datasources/user_profile_remote_data_source.dart`) —
      single-field `update()` calls, same shape as the existing `markWrappedSeen` (depends on T011)
- [X] T013 Add `updateCurrencyCode`/`updateTimeZone` to `UserProfileRepository`
      (`lib/features/user_profile/domain/repositories/user_profile_repository.dart`) and
      implement in `UserProfileRepositoryImpl`
      (`lib/features/user_profile/data/repositories/user_profile_repository_impl.dart`), per
      `contracts/category-management-api.md` (depends on T012)

### `CategoryRepository` widened (management operations)

- [X] T014 [P] Add `getAll()`, `create(...)`, `update(...)`, `reorder(...)`, `setActive(...)` to
      `CategoryRepository`
      (`lib/features/categories/domain/repositories/category_repository.dart`), per
      `contracts/category-management-api.md` §1 (depends on nothing — can run in parallel with
      T010–T013)
- [X] T015 Add the corresponding methods to `CategoryRemoteDataSource`
      (`lib/features/categories/data/datasources/category_remote_data_source.dart`):
      `getAll(userId)` (no `isActive` filter, unlike `getActive`); `create(userId, name, color,
      iconName)` (always `nameKey: null`); `update(userId, categoryId, {name, color, iconName})`
      (when the target's `isDefault` is true and `name` is given: clear `nameKey`, set `name`,
      flip `isDefault` to `false` — one write); `reorder(userId, orderedIds)` (batched
      `sortOrder` rewrite); `setActive(userId, categoryId, isActive)` (depends on T014)
- [X] T016 Implement the new `CategoryRepository` members in `CategoryRepositoryImpl`
      (`lib/features/categories/data/repositories/category_repository_impl.dart`), same
      `Result`-mapping pattern every existing member already uses (depends on T015)

### Settings screen shell

- [X] T017 [P] Add a third `_NavItem` (Settings) to `AppShell`
      (`lib/core/navigation/app_shell.dart`), matching the existing Capture/History items —
      `settingsTitle` as its label, current-location check against `/settings`
- [X] T018 [P] Create `SettingsPage` (`lib/features/settings/presentation/pages/settings_page.dart`):
      a scaffold listing three sections (Account, Categories, Preferences) as tappable rows —
      empty/placeholder targets for now, wired to real content by each later story
- [X] T019 Register `GoRoute(path: '/settings', ...)` **inside** the existing `ShellRoute` in
      `lib/app.dart`, alongside `/` and `/history` (unlike `006`'s `/wrapped/:monthKey`, Settings
      is an ordinary shell destination, not a full-screen takeover — the floating nav bar stays
      visible) (depends on T017, T018)

### New domain types & `AuthRepository` contract

- [X] T020 [P] **Deviation from `contracts/auth-linking-api.md`**: the planned
      `LinkConflictFailure extends Failure` in `lib/core/errors/failure.dart` would violate
      Constitution Principle 4 twice (`core/` importing a feature-specific `LinkConflict` type;
      that domain entity holding a raw Firebase `AuthCredential`). Instead created
      `lib/features/auth/domain/entities/link_result.dart`: a sealed `LinkResult`
      (`LinkSucceeded` / `LinkConflictDetected` / `LinkFailed`), kept entirely within
      `features/auth/domain/`, returned by `linkWithGoogle`/`linkWithApple` in place of
      `Result<void>` + `LinkConflictFailure`. `contracts/auth-linking-api.md` and
      `data-model.md` still describe the superseded design and should be corrected to match.
- [X] T021 [P] Create `LinkConflict`
      (`lib/features/auth/domain/entities/link_conflict.dart` — credential-free, display-only
      `existingProviderLabel`) and `LinkConflictResolution`
      (`lib/features/auth/domain/entities/link_conflict_resolution.dart`), per `data-model.md`
      §2–3
- [X] T022 Added `isLinked`, `linkWithGoogle()`, `linkWithApple()` (returning `LinkResult`),
      `resolveLinkConflict(LinkConflict, LinkConflictResolution)`, and `deleteAccount()` to
      `AuthRepository` (`lib/features/auth/domain/repositories/auth_repository.dart`) — contract
      declarations only. Stubbed all five in `FirebaseAuthRepository`
      (`throw UnimplementedError()`) so the build stays green until each story (US1: isLinked/
      linkWithGoogle/linkWithApple; US3: resolveLinkConflict; US6: deleteAccount) replaces its
      own stub (depends on T020, T021)

**Checkpoint**: Security Rules, `UserProfile`, `CategoryRepository`, the Settings shell, and the
`AuthRepository` contract are all ready. Every user story can now build on this.

---

## Phase 3: User Story 1 - Vincular una cuenta sin perder nada (Priority: P1) 🎯 MVP

**Goal**: Linking a never-before-used Google or Apple account succeeds directly — same uid, zero
data migration — and Settings shows a real, working "link account" action.

**Independent Test**: Log expenses and create a category anonymously, link a fresh (never-used)
Google or Apple account from Settings, and confirm the full history is present immediately after,
under the same uid.

### Tests for User Story 1

- [X] T023 [P] [US1] Unit test in
      `test/features/auth/data/repositories/firebase_auth_repository_test.dart` (extended, not a
      new file — `firebase_auth_mocks`' `MockFirebaseAuth`/`MockUser`, plus a fake
      `GoogleSignInCredentialProvider`/`AppleSignInCredentialProvider` injected via the widened
      constructor): `linkWithGoogle()`/`linkWithApple()` call `linkWithCredential` with a
      correctly-shaped credential and return `LinkSucceeded()` (not `Success(null)` — see T020's
      deviation note) when it succeeds, with `currentUserId` unchanged before/after
- [X] T024 [P] [US1] Unit test (same file): `linkWithGoogle()`/`linkWithApple()` return
      `LinkConflictDetected(...)`, not a generic failure, when `linkWithCredential` throws
      `FirebaseAuthException(code: 'credential-already-in-use')` — stubbed via `mock_exceptions`'
      `whenCalling(...).on(auth.currentUser!).thenThrow(...)` (added `mock_exceptions` as a direct
      dev dependency; it was previously transitive-only via `firebase_auth_mocks`)
- [X] T025 [P] [US1] Widget test in
      `test/features/settings/presentation/widgets/settings_account_section_test.dart`: renders
      a "link account" call-to-action with Google/Apple options when `isLinked` is `false`; tapping
      Google/Apple invokes the corresponding link call; also covers the linked-status branch
      (added `linkedProviderLabel` to `AuthRepository` — needed to render `settingsLinkedAsLabel`'s
      `{provider}` placeholder, not explicitly listed in the original task but required by the
      already-authored ARB string)

### Implementation for User Story 1

- [X] T026 [P] [US1] Created the Google Sign-In credential exchange helper in
      `lib/features/auth/data/google_sign_in_credential_provider.dart`: confirmed the installed
      `google_sign_in: ^7.2.0` API against its own source (`GoogleSignIn.instance`, memoized
      `initialize()`, `authenticate()`, synchronous `.authentication.idToken`) rather than assumed
      prior API knowledge, per `research.md` #8
- [X] T027 [P] [US1] Created the Apple Sign-In credential exchange helper in
      `lib/features/auth/data/apple_sign_in_credential_provider.dart`: obtains an `OAuthCredential`
      via `sign_in_with_apple: ^8.1.0`'s `getAppleIDCredential`, with a generated/hashed nonce
      (added `crypto` as a direct dependency for `sha256`)
- [X] T028 [US1] Implemented `linkWithGoogle()`/`linkWithApple()`/`isLinked` in
      `FirebaseAuthRepository`: widened the constructor to take both credential providers; calls
      `_auth.currentUser!.linkWithCredential(credential)`; maps `credential-already-in-use` to
      `LinkConflictDetected` (holding the credential in `_pendingConflictCredential` for US3's
      `resolveLinkConflict`), maps other `FirebaseAuthException`s to `LinkFailed(UnknownFailure(...))`;
      `isLinked`/new `linkedProviderLabel` check `currentUser?.providerData` for a
      `google.com`/`apple.com` entry. Updated the two `integration_test/` call sites and
      `injection.config.dart` (via `build_runner`) for the widened constructor (depends on T023,
      T024, T026, T027)
- [X] T029 [US1] Created `LinkAccountUseCase`
      (`lib/features/auth/domain/usecases/link_account.dart`, `@injectable`, plus a `LinkProvider`
      enum): calls `AuthRepository.linkWithGoogle`/`linkWithApple`, propagates the `LinkResult`
      verbatim for now (`US2`/`US3` extend this call site) (depends on T028)
- [X] T030 [US1] Added `authRepositoryProvider`, `isLinkedProvider` (`Provider<bool>`),
      `linkedProviderLabelProvider` (`Provider<String?>`), and `linkAccountUseCaseProvider` to
      `lib/core/di/providers.dart`, matching the existing bridge pattern
- [X] T031 [US1] Created `SettingsAccountSection`
      (`lib/features/settings/presentation/widgets/settings_account_section.dart`, a
      `ConsumerStatefulWidget` so the post-`await` `ref.invalidate` calls can be guarded by
      `mounted`): shows the link CTA (Google/Apple choice) when `!isLinked`, the linked-status line
      otherwise; on `LinkSucceeded`, invalidates `isLinkedProvider`/`linkedProviderLabelProvider` so
      the UI updates immediately. `LinkConflictDetected`/`LinkFailed` intentionally left unhandled
      here — routing to `LinkConflictPage` is US3's T041 (depends on T029, T030)
- [X] T032 [US1] Wired `SettingsAccountSection` into the Account section of `SettingsPage`
      (depends on T031, T018)
- [X] T033 [US1] Ran `dart run build_runner build` to register `LinkAccountUseCase` for DI
      (depends on T029)
- [X] T034 [US1] Verified automatically: `flutter analyze` clean, full `flutter test` suite green
      (185 tests). `quickstart.md` steps 1–2 also need a real on-device pass with a live Google/
      Apple account and the manual Firebase Console provisioning listed in quickstart.md's
      Prerequisites (Auth providers enabled, App Check debug token registered) — flagged here as
      the same category of human-confirmed step US5 already documents, not yet performed (depends
      on T032, T033)

**Checkpoint**: US1 is independently functional and testable — linking a clean account works
end to end, uid-preserving, with zero data migration.

---

## Phase 4: User Story 3 - Ninguna decisión de datos se toma en automático (Priority: P1)

**Goal**: When the chosen account already has its own history, the app never combines, replaces,
or discards anything without an explicit, clearly-labeled choice.

**Independent Test**: Prepare an account with its own known history; from a device with a
*different*, non-empty anonymous history, attempt to link that account; confirm the app presents
the conflict clearly and that both the "combine" and "discard this device's data" paths behave
exactly as chosen, with nothing lost silently.

### Tests for User Story 3

- [X] T035 [P] [US3] Unit test in
      `test/features/auth/data/repositories/firebase_auth_repository_conflict_test.dart` (new
      file — one shared `FakeFirebaseFirestore` with two uid namespaces, plus a
      `_SwitchableMockFirebaseAuth extends MockFirebaseAuth` that overrides
      `signInWithCredential` to actually flip identity to a second `MockUser`, since the stock
      mock always re-signs-in as its original configured user):
      `resolveLinkConflict(conflict, LinkConflictResolution.merge)` reads the anonymous account's
      full expense/category list, switches identity via the held credential, and writes every
      item into the existing account's collections with fresh ids — confirm the existing
      account's own prior data survives untouched alongside the merged data. Also covers a
      nuance the original task text didn't name: default categories are matched onto the
      existing account's own defaults by `nameKey`, not duplicated (see T038's note)
- [X] T036 [P] [US3] Unit test (same file):
      `resolveLinkConflict(conflict, LinkConflictResolution.discardLocal)` deletes the anonymous
      account's expense/category documents (confirmed via a direct Firestore read against that
      uid after the call) before switching identity, and the existing account's own data is
      unchanged
- [X] T037 [P] [US3] Widget test in
      `test/features/settings/presentation/pages/link_conflict_page_test.dart`: renders both
      options with no default/pre-selected choice; tapping "discard local" shows a distinct
      confirmation naming what will be discarded before it proceeds; tapping "merge" proceeds
      directly (merging is non-destructive, so no second confirmation is required by FR-005)

### Implementation for User Story 3

- [X] T038 [US3] Implemented `resolveLinkConflict`'s `merge` path in `FirebaseAuthRepository`, per
      the exact sequence in `research.md` #2 (read while still A, hold in memory, switch to B via
      `signInWithCredential`, write into B with fresh ids). **Deviation from the literal task
      text, caught while designing the test**: default categories have random per-user Firestore
      ids (`CategoryRemoteDataSource.seedDefaultsIfNeeded` uses `ref.doc()`), so blindly
      recreating every one of A's categories in B would duplicate B's own already-seeded
      defaults. A's default categories are instead matched onto B's by `nameKey` (every account
      gets the same fixed default set, so a match always exists); only A's genuinely
      user-created categories are recreated, with A's expenses' `categoryId` remapped through
      the resulting id map either way. Widened the constructor with `ExpenseRepository`/
      `CategoryRepository` (a feature depending on another feature's `domain/` repository
      interface is explicitly permitted by Constitution Principle 4 — `LogExpense` is the
      established precedent). **Found and fixed a real bug this exposed**:
      `CategoryRepositoryImpl.seedDefaultsIfNeeded()`'s memoized `_seedFuture` was a single
      instance-wide guard, correct only under the assumption that one process ever authenticates
      as one uid — an assumption this exact merge flow breaks by switching identity mid-process.
      Changed it to memoize per-uid (`Map<String, Future<void>> _seedFutures`) (depends on T035)
- [X] T039 [US3] Implemented `resolveLinkConflict`'s `discardLocal` path: hard-deletes A's
      `expenses`/`categories` documents directly via injected `FirebaseFirestore` batch writes
      (added as a new constructor dependency) while still authenticated as A, then switches to B
      via `signInWithCredential` (depends on T036)
- [X] T040 [US3] Created `LinkConflictPage`
      (`lib/features/settings/presentation/pages/link_conflict_page.dart`): presents the
      conflict (`settingsLinkConflictTitle`/`Body`), the merge option, and the discard option
      (a confirmation `AlertDialog`, using `MaterialLocalizations`' built-in Cancel label rather
      than a new ARB key). Registered as a `GoRoute` sibling of `ShellRoute` in `app.dart` at
      `/link-conflict` (`extra:` carries the `LinkConflict` — the same "full-screen, not a shell
      destination" shape `006`'s `/wrapped/:monthKey` established) (depends on T037)
- [X] T041 [US3] **Deviation from the literal task text**: wired the navigation in
      `SettingsAccountSection._link` (a `switch` over the `LinkResult` returned by
      `LinkAccountUseCase`), not inside `LinkAccountUseCase` itself — a domain-layer use case
      cannot import `go_router`/`BuildContext` without violating Constitution Principle 4
      ("domain/ MUST NOT import Flutter"). On `LinkConflictDetected(conflict)`,
      `context.push('/link-conflict', extra: conflict)`; on `LinkFailed`, the CTA simply stays
      visible for retry (depends on T038, T039, T040, T029)
- [X] T042 [US3] Verified automatically: `flutter analyze` clean, full `flutter test` suite green
      (191 tests, including the merge/discard data-correctness tests against known seeded data
      sets). `quickstart.md` step 4's real two-device manual pass not yet performed — same
      human-confirmed-step category as T034 (depends on T041)

**Checkpoint**: US3 is independently functional and testable — every conflict is resolved by an
explicit, informed choice, and both outcomes are provably correct against known data sets.

---

## Phase 5: User Story 2 - Recuperar el historial en un dispositivo nuevo (Priority: P1)

**Goal**: Signing in with an already-linked account from a fresh install recovers the full history
without requiring the person to make a decision about data they don't have.

**Independent Test**: With an account already linked to a known history (from US1/US3's tests),
attempt to link that same account from a fresh install (trivially empty local history) and confirm
the full history appears without any conflict prompt being shown.

### Tests for User Story 2

- [X] T043 [P] [US2] Unit test in
      `test/features/auth/domain/usecases/link_account_test.dart` (new file — mocktail-mocked
      `AuthRepository`/`ExpenseRepository`/`CategoryRepository`): when `linkWithGoogle` returns
      `LinkConflictDetected` **and** the local expense list is empty and every local category is
      a default (never seeded a user category), `LinkAccountUseCase` calls
      `resolveLinkConflict(conflict, LinkConflictResolution.discardLocal)` automatically and
      returns `LinkSucceeded` — no `LinkConflictDetected` is propagated to the caller in this case
- [X] T044 [P] [US2] Unit tests (same file): a non-empty expense list still propagates
      `LinkConflictDetected` and never calls `resolveLinkConflict`; separately, an empty expense
      list but a genuine user-created category (not just defaults) does the same — both cover
      "local history is not empty" per US3's existing, unchanged behavior

### Implementation for User Story 2

- [X] T045 [US2] Extended `LinkAccountUseCase`: on `LinkConflictDetected`, checks whether the
      local session's `ExpenseRepository.watchAll()` is empty and every `CategoryRepository.getAll()`
      entry `isDefault` (a read failure on the category check is treated as "cannot confirm
      empty," never as empty — an ambiguous read must never silently discard real data); if so,
      calls `resolveLinkConflict(conflict, LinkConflictResolution.discardLocal)` directly and
      returns `LinkSucceeded`/`LinkFailed` instead of ever surfacing the conflict, so
      `SettingsAccountSection` never routes to `LinkConflictPage` for this case (depends on T043,
      T044, T041)
- [X] T046 [US2] Verified automatically: `flutter analyze` clean, full `flutter test` suite green
      (194 tests). `quickstart.md` step 3's real two-device manual pass not yet performed — same
      human-confirmed-step category as T034/T042 (depends on T045)

**Checkpoint**: US2 is independently functional and testable — the "new device" experience is
provably just US3's machinery with an empty set on one side, not a separate implementation.

---

## Phase 6: User Story 5 - Solo la aplicación legítima puede acceder a los datos (Priority: P1)

**Goal**: Firebase App Check is active on both flavors — Play Integrity/App Attest in `prod`, a
debug provider in `dev` — protecting Firestore without affecting any legitimate client.

**Independent Test**: Confirm the client-side activation call selects the correct provider per
`AppEnvironment`, confirm it never blocks `runApp()`, and confirm (via `quickstart.md`'s manual
steps, since real enforcement requires Firebase Console access) that a client without a valid
token is rejected while the real app is unaffected.

### Tests for User Story 5

- [X] T047 [P] [US5] Unit test in
      `test/core/config/app_check_provider_selection_test.dart`: given `AppEnvironment.dev`,
      resolves to `AndroidDebugProvider`/`AppleDebugProvider`; given `AppEnvironment.prod`,
      resolves to `AndroidPlayIntegrityProvider`/`AppleAppAttestProvider` — a pure function test,
      no real Firebase call

### Implementation for User Story 5

- [X] T048 [US5] Created the provider-selection pure function in
      `lib/core/config/app_check_provider_selection.dart`, returning a
      `({AndroidAppCheckProvider android, AppleAppCheckProvider apple})` record via the
      non-deprecated `providerAndroid`/`providerApple`-shaped provider classes (depends on T047)
- [X] T049 [US5] Added the fire-and-forget `FirebaseAppCheck.instance.activate(providerAndroid:
      ..., providerApple: ...)` call to `lib/bootstrap.dart`, immediately after
      `Firebase.initializeApp()`, using T048's selection — never awaited before `runApp()`
      (`research.md` #9) (depends on T048)
- [X] T050 [US5] Verified automatically: `flutter analyze` clean, full `flutter test` suite green
      (196 tests). Firebase Console provisioning (Play Integrity/App Attest enablement, debug
      token registration against `wrap-my-finances-dev` only, and enabling Firestore enforcement
      per `quickstart.md` steps 6–7) are manual, human-confirmed steps outside this task's
      automated scope — not yet performed (depends on T049)

**Checkpoint**: US5 is independently functional and testable — App Check is correctly wired
client-side; enforcement itself is a documented manual rollout step (`research.md` #4).

---

## Phase 7: User Story 4 - Vincular sin conexión no rompe nada (Priority: P2)

**Goal**: Attempting to link while offline fails loudly and recoverably — never silently, never
corrupting local state.

**Independent Test**: With the device offline, attempt to link an account; confirm a clear
"unavailable" message appears and that expense logging/history continue to work normally
immediately after.

### Tests for User Story 4

- [X] T051 [P] [US4] Unit tests extending
      `test/features/auth/data/repositories/firebase_auth_repository_test.dart`:
      `linkWithGoogle`/`linkWithApple` map `FirebaseAuthException(code: 'network-request-failed')`
      to `LinkFailed(NetworkFailure())`, not a generic `UnknownFailure`. Also tightened the
      pre-existing generic-failure test to assert `UnknownFailure` specifically (it previously
      only asserted `LinkFailed`, which would have passed even after this change by accident)
- [X] T052 [P] [US4] Widget test extending `settings_account_section_test.dart`: on a
      `NetworkFailure` result, `SettingsAccountSection` shows
      `settingsLinkUnavailableOfflineMessage` (via `SnackBar`) and returns to its normal
      (not-linked, not stuck loading) state — asserted after `pumpAndSettle()`, since the mocked
      Future resolves too fast to reliably catch the loading frame mid-flight

### Implementation for User Story 4

- [X] T053 [US4] Mapped `'network-request-failed'` to `NetworkFailure` in `FirebaseAuthRepository`
      `_link`'s `FirebaseAuthException` branch (depends on T051)
- [X] T054 [US4] Updated `SettingsAccountSection`: added an `_isLinking` bool that swaps the
      whole section for a `CircularProgressIndicator` while a link attempt is in flight (there
      was no loading state at all before this story), cleared unconditionally once the use case
      resolves; on `LinkFailed(NetworkFailure)` specifically, shows a `SnackBar` with
      `settingsLinkUnavailableOfflineMessage` — any other `LinkFailed` just leaves the CTA
      visible for retry (depends on T052, T053)
- [X] T055 [US4] Verified automatically: `flutter analyze` clean, full `flutter test` suite green
      (199 tests). `quickstart.md` step 5's real airplane-mode manual pass not yet performed —
      same human-confirmed-step category as T034/T042/T046 (depends on T054)

**Checkpoint**: US4 is independently functional and testable.

---

## Phase 8: User Story 6 - Eliminar la cuenta y los datos, de forma permanente (Priority: P2)

**Goal**: A confirmed deletion request removes every expense, every category, the user document,
and the Firebase Auth identity itself, permanently.

**Independent Test**: Sign in with an account holding data, request deletion, confirm explicitly,
and verify nothing from that account — data or identity — remains reachable afterward.

### Tests for User Story 6

- [X] T056 [P] [US6] Unit test in
      `test/features/auth/data/repositories/firebase_auth_repository_delete_test.dart` (new file
      — `fake_cloud_firestore` + `firebase_auth_mocks`): `deleteAccount()` removes every document
      under `users/{uid}/expenses`, `users/{uid}/categories`, and the `users/{uid}` document
      itself, then calls `currentUser!.delete()`
- [X] T057 [P] [US6] Unit test (same file): when `currentUser!.delete()` throws
      `requires-recent-login`, `deleteAccount()` re-triggers the linked provider's credential
      flow and retries once, rather than surfacing the error directly. Needed a hand-written
      `_FlakyDeleteMockUser extends MockUser` (fails exactly once, then succeeds) since
      `mock_exceptions`' registry throws on every matching call indefinitely once registered —
      not expressible as a one-shot failure otherwise. Also discovered `MockUser` exposes no
      public way to construct a raw `UserInfo` (its factory is `@protected`), so provider data
      is populated via the mock's own `linkWithProvider()` instead
- [X] T058 [P] [US6] Widget tests added to `settings_account_section_test.dart` (not a separate
      `..._delete_test.dart` file — the delete action lives in the same widget as linking, and
      splitting the test file from the widget file it covers would break this session's existing
      1:1 convention): the delete action requires a distinct explicit confirmation step — a
      single tap never deletes anything, cancelling the confirmation deletes nothing, and only
      confirming calls `AuthRepository.deleteAccount`

### Implementation for User Story 6

- [X] T059 [US6] Implemented `deleteAccount()` in `FirebaseAuthRepository`: hard-deletes
      `expenses`/`categories` via the same `_deleteAllDocsIn` batch helper `resolveLinkConflict`'s
      `discardLocal` path already uses, deletes the `users/{uid}` document, then calls
      `currentUser!.delete()` with reauth-and-retry (T057). **Documented, not silently accepted,
      edge case**: if reauth is cancelled/fails after data is already deleted, the auth identity
      survives with no data — deliberately, since deleting the identity before reauth succeeds
      risks the opposite, worse failure (an orphaned identity with no way back in); every step
      here is idempotent, so calling `deleteAccount()` again simply finishes the job (depends on
      T056, T057)
- [X] T060 [US6] Created `DeleteAccountUseCase`
      (`lib/features/auth/domain/usecases/delete_account.dart`, `@injectable`), wrapping
      `AuthRepository.deleteAccount()`. **Deviation**: widened `AuthRepository.deleteAccount()`
      with an optional `void Function()? onReauthRequired` callback (a plain Dart function type,
      not Flutter's `VoidCallback`, so `domain/` still never imports Flutter) — without it,
      nothing could ever trigger `settingsDeleteAccountReauthMessage`, an ARB string the plan
      already committed to but that isn't observable from outside `FirebaseAuthRepository`
      without a hook (depends on T059)
- [X] T061 [US6] Ran `dart run build_runner build` to register `DeleteAccountUseCase` for DI
      (depends on T060)
- [X] T062 [US6] Added the delete CTA, confirmation dialog, and reauth-prompt `SnackBar` to
      `SettingsAccountSection`; restructured it into an always-shown link-or-status section plus
      an always-shown delete action below (deletion isn't gated on being linked — the spec's
      acceptance criterion 8 has no such requirement, and anonymous accounts have data worth
      deleting too). On success, eagerly calls `ensureSignedIn()` for a fresh anonymous session
      (Constitution Principle 2 — never leaves a write stranded with no session) and navigates to
      `/` (depends on T058, T060, T061)
- [X] T063 [US6] Verified automatically: `flutter analyze` clean, full `flutter test` suite green
      (204 tests). `quickstart.md` step 8's real end-to-end pass not yet performed — same
      human-confirmed-step category as T034/T042/T046/T055 (depends on T062)

**Checkpoint**: US6 is independently functional and testable.

---

## Phase 9: User Story 7 - Gestionar categorías desde Ajustes (Priority: P2)

**Goal**: Create, rename, recolor, re-icon, reorder, and archive categories from Settings, with
zero effect on historical expenses that reference them.

**Independent Test**: From the category management screen, exercise every operation and confirm
each one reflects immediately, with historical expenses referencing an archived or renamed
category continuing to display correctly in History.

### Tests for User Story 7

- [X] T064 [P] [US7] Unit tests extending
      `test/features/categories/data/repositories/category_repository_impl_test.dart`
      (sequential, same file as `004`'s seeding tests): `create`/`update`/`reorder`/`setActive`
      each produce the exact expected Firestore document state against `FakeFirebaseFirestore`
- [X] T065 [P] [US7] Unit test (same file): `update(categoryId, name: ...)` on a category with
      `isDefault: true` clears `nameKey`, sets `name`, and flips `isDefault` to `false` — the
      exact `docs/DATA_MODEL.md` conversion invariant
- [X] T066 [P] [US7] Widget tests in
      `test/features/settings/presentation/pages/category_management_page_test.dart`: lists
      active and archived categories, visually distinguishing archived ones; also covers tapping
      the archive action actually flips `isActive`
- [X] T067 [P] [US7] Widget tests in
      `test/features/settings/presentation/widgets/category_editor_sheet_test.dart`:
      create/rename/recolor/re-icon each call the corresponding repository method with the
      expected arguments
- [X] T068 [P] [US7] Widget test extending
      `test/features/expenses/presentation/widgets/category_picker_sheet_test.dart` (documents,
      rather than newly enforces, that the picker itself performs no `isActive` filtering — the
      real exclusion happens one layer up, in whichever provider supplies its `categories` list),
      plus a new test extending `expense_history_page_test.dart`: **found and fixed a real bug**
      — `ExpenseHistoryPage` resolved categories via `activeCategoriesProvider`
      (`CategoryRepository.watchActive()`), so a historical expense referencing an archived
      category fell back to its raw `categoryId` string instead of resolving normally. Added
      `CategoryRepository.watchAll()` (data source + impl, mirroring `watchActive()` but
      unfiltered) and a new `allCategoriesProvider`, and switched `ExpenseHistoryPage` to it

### Implementation for User Story 7

- [X] T069 [US7] Created `CategoryManagementPage`
      (`lib/features/settings/presentation/pages/category_management_page.dart`): list from
      `allCategoriesProvider` (`watchAll()`, live), archive/unarchive `IconButton` per row via
      `ReorderableListView`'s `onReorderItem` (the non-deprecated replacement for `onReorder`,
      which already pre-adjusts `newIndex` for the removed item), `FloatingActionButton` opens
      `CategoryEditorSheet` in create mode; tapping a row opens it in edit mode (depends on T066)
- [X] T070 [US7] Created `CategoryEditorSheet`
      (`lib/features/settings/presentation/widgets/category_editor_sheet.dart`): name/color/icon
      form (color swatches from `context.colors.categoryPalette`, icons from `categoryIconMap` —
      both fixed, design-token-driven sets per FR-012, never a color wheel or icon search), used
      for both create and rename/recolor/re-icon. Reuses `commonContinue` for the submit action
      rather than adding a new "Save" ARB key across 5 languages (depends on T067)
- [X] T071 [US7] Wired an entry-point button into the Categories section of `SettingsPage`,
      pushing a new `/settings/categories` route (a `ShellRoute` sibling, like `/link-conflict` —
      `CategoryManagementPage`'s own `AppBar`/FAB would collide visually with the floating nav
      bar) (depends on T069, T070, T018)
- [X] T072 [US7] Verified automatically: `flutter analyze` clean, full `flutter test` suite green
      (217 tests). `quickstart.md` steps 9–10's real on-device pass not yet performed — same
      human-confirmed-step category as T034/T042/T046/T055/T063 (depends on T064, T065, T068,
      T071)

**Checkpoint**: US7 is independently functional and testable.

---

## Phase 10: User Story 8 - Cambiar moneda y zona horaria (Priority: P3)

**Goal**: Change the currency and time-zone preference from Settings; neither change touches any
previously-logged expense, and the capture path picks up the new currency for expenses logged
afterward.

**Independent Test**: Log an expense, change the time zone, confirm the expense's month is
unchanged; change the currency, confirm the same expense's stored amount/currency is unchanged,
and confirm a newly-logged expense uses the new currency.

### Tests for User Story 8

- [X] T073 [P] [US8] Unit tests in
      `test/features/user_profile/data/repositories/user_profile_repository_impl_test.dart` (new
      file — `test/features/user_profile/` had no tests at all before this, across `003`–`006`):
      `updateCurrencyCode`/`updateTimeZone` each produce the exact expected single-field Firestore
      update against `FakeFirebaseFirestore`
- [X] T074 [P] [US8] Unit tests in
      `test/features/expenses/presentation/current_currency_code_provider_test.dart` — not
      `test/core/di/...`, see T077's deviation note: resolves to `DeviceLocaleDefaults.
      currencyCodeFor(...)` before the profile has loaded or when no preference is set; resolves
      to `UserProfile.currencyCode` once available
- [X] T075 [P] [US8] Widget tests in
      `test/features/settings/presentation/widgets/currency_picker_test.dart` and
      `timezone_picker_test.dart`: selecting a value calls
      `updateCurrencyCode`/`updateTimeZone` with the chosen value
- [X] T076 [P] [US8] Regression test extending
      `test/features/expenses/presentation/controllers/expense_capture_controller_test.dart` (not
      `expense_model_test.dart`, which didn't exist and wouldn't exercise the real integration
      point — see T078's deviation: the resolved value now flows through `Expense.amount.
      currencyCode` itself, so the meaningful test is at the controller, where `currencyCodeOf()`
      is actually called): an expense submitted after the callback's return value changes is
      captured with the new `currencyCode`; the earlier submission's captured draft is
      untouched — `LogExpense.call` is a one-shot create, never a read or update, so there is no
      code path that could retroactively mutate it

### Implementation for User Story 8

- [X] T077 [US8] Created `currentCurrencyCodeProvider` in
      `lib/features/expenses/presentation/current_currency_code_provider.dart`, **not**
      `lib/core/di/providers.dart` as originally planned: it needs `DeviceLocaleDefaults`, a
      `features/expenses/data/` internal, and `core/` must never import a feature's `data/`
      (Constitution Principle 4) — only `features/expenses/presentation/` itself may reach into
      its own feature's `data/` this way. A synchronous `Provider<String>` backed by a private
      `StreamProvider<UserProfile>` wrapping `UserProfileRepository.watchProfile()`, falling back
      to `DeviceLocaleDefaults` (`research.md` #5) (depends on T074, T013)
- [X] T078 [US8] **Deviation, found while implementing**: `ExpenseModel.fromEntity` doesn't read
      `currentCurrencyCodeProvider` directly — it can't; Riverpod providers aren't reachable from
      a plain data-layer factory. Discovered that `Expense.amount` already carries its own
      `currencyCode` field, which `ExpenseModel.fromEntity` was *discarding* in favor of a fresh
      `DeviceLocaleDefaults` computation, while `ExpenseCaptureController` separately fed it a
      `'XXX'` placeholder specifically because presentation code couldn't reach `data/` to compute
      the real value either — two halves of a workaround for the same gap. Fixed by moving
      resolution to where it belongs: `ExpenseCaptureController` now takes a live
      `String Function() currencyCodeOf` getter (read fresh on every `submit()`, not snapshotted
      at construction, so an in-session preference change takes effect immediately), sets the
      real code directly on the draft's `Money`, and `ExpenseModel.fromEntity` now just trusts
      `expense.amount.currencyCode` — the placeholder and the `DeviceLocaleDefaults` call both
      gone from the data layer. `ExpenseCapturePage` also added a bare `ref.watch
      (currentCurrencyCodeProvider)` (side-effect only, no rendered value) purely to keep the
      underlying stream warm from launch, since capture is always the first screen shown (depends
      on T076, T077)
- [X] T079 [P] [US8] Created `CurrencyPicker`
      (`lib/features/settings/presentation/widgets/currency_picker.dart`) — a curated, fixed list
      (`USD`/`MXN`/`BRL`/`EUR`) matching `DeviceLocaleDefaults`'s own scope exactly (depends on
      T075)
- [X] T080 [P] [US8] Created `TimeZonePicker`
      (`lib/features/settings/presentation/widgets/timezone_picker.dart`) — the same five IANA
      zones `DeviceLocaleTimeZoneDefaults` already establishes. Both pickers read their current
      selection from a new `currentUserProfileProvider`
      (`lib/features/settings/presentation/current_user_profile_provider.dart`) — Settings' own
      copy of the live-profile stream, kept separate from `current_currency_code_provider.dart`'s
      private one since `presentation/`-layer providers aren't shared across feature boundaries,
      only `domain/` contracts are (depends on T075)
- [X] T081 [US8] Wired `CurrencyPicker`/`TimeZonePicker` into the Preferences section of
      `SettingsPage` (depends on T079, T080, T018)
- [X] T082 [US8] Verified automatically: `flutter analyze` clean, full `flutter test` suite green
      (225 tests). `quickstart.md` step 11's real on-device pass not yet performed — same
      human-confirmed-step category as T034/T042/T046/T055/T063/T072 (depends on T078, T081)

**Checkpoint**: US8 is independently functional and testable — all eight user stories complete.

---

## Phase 11: Polish & Cross-Cutting Concerns

- [X] T083 [P] Confirmed `test/core/design_system/tokens/no_raw_hex_colors_test.dart` and
      `test/l10n/arb_keys_complete_test.dart` still pass unmodified after this feature's ARB
      additions
- [X] T084 Ran `flutter analyze`: zero issues across every file this feature added or modified
- [X] T085 Ran `dart format --output=none --set-exit-if-changed lib test integration_test`: clean
      (after formatting 9 files that had drifted — `category_remote_data_source.dart`,
      `expense_capture_controller.dart`/its test, `expense_history_page.dart`,
      `link_conflict_page.dart`/its test, `category_editor_sheet.dart`, `timezone_picker.dart`,
      `settings_account_section_test.dart`)
- [X] T086 Ran the full `firebase/tests/` Security Rules suite against the emulator: 38/38
      passing, same count as after T009 — this phase needed no further rules changes beyond
      Foundational's
- [X] T087 `quickstart.md`'s 14 steps: automated verification (analyze/format/unit+widget
      tests/Security Rules) completed at every checkpoint T034 through T086. The steps requiring
      a real device, a live Google/Apple account, and Firebase Console access (provisioning App
      Check providers/debug tokens, enabling Firestore enforcement, the two-device link/recovery/
      conflict walkthrough, airplane-mode offline check, and the end-to-end account-deletion
      pass) were **not** performed — they need a human with those credentials and devices, the
      same category flagged at every individual story's own verify task (depends on T034, T042,
      T046, T050, T055, T063, T072, T082)
- [X] T088 Ran `flutter test` (full suite): 225 tests passing, zero regressions to any prior
      feature's (`003`–`006`) tests. Attempted `flutter test integration_test/` on the available
      Android emulator: **blocked by a pre-existing environment gap, not a regression** —
      `android/app/src/dev/google-services.json` (gitignored, never committed, project-specific
      Firebase config) doesn't exist in this sandbox, so the dev-flavor build fails before any
      test runs; confirmed this is unrelated to 007 by checking git history (the file has never
      been tracked). The two `integration_test/` files this feature touched
      (`expense_capture_flow_test.dart`/`expense_capture_with_history_shell_test.dart`, both just
      updated for `FirebaseAuthRepository`'s widened constructor) do pass `flutter analyze` and
      contain no logic changes beyond that constructor update, but were not executed end-to-end
      on a device (depends on T084)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories. Its five sub-groups
  (ARB, Security Rules, `UserProfile`, `CategoryRepository`, Settings shell + new `auth` domain
  types) are themselves largely parallel with each other
- **User Stories (Phase 3–10)**: All depend on Foundational completion; within that constraint:
  - US1 (link, happy path) has no dependency on any other story — buildable and testable in
    isolation
  - US3 (conflict resolution) depends on US1 (its own linking calls are what can *trigger* a
    conflict) but not on US2/US4/US5/US6/US7/US8
  - US2 (new-device recovery) depends on US3 (it is US3's exact machinery, exercised with an
    empty local set) — not a parallel, independent implementation
  - US5 (App Check) has no dependency on any account-linking story — fully parallel-capable with
    US1/US3/US2
  - US4 (offline hardening) depends on US1's linking calls existing to harden
  - US6 (account deletion) depends on US1 for the concept of a linked session, but not on
    US2/US3/US4
  - US7 (category management) depends only on Foundational (`CategoryRepository` widened) and the
    Settings shell — independent of every account-linking story
  - US8 (currency/timezone) depends only on Foundational (`UserProfile` widened) and the Settings
    shell — independent of every account-linking story, but is the one story that also touches
    `004`'s existing capture-path code (T078)
- **Polish (Phase 11)**: Depends on all eight user stories being complete

### Parallel Opportunities

- Foundational: T002–T006 (five ARB files), T008 (rules), T010–T011 (UserProfile entity/model),
  T014 (CategoryRepository interface), T017–T018 (Settings shell pieces), T020–T021 (new domain
  types) are largely independent tracks
- Once Foundational completes: US5 can be staffed fully in parallel with US1→US3→US2; US7 and US8
  can each be staffed in parallel with all account-linking work and with each other
- Within US1: T023–T025 (tests) in parallel; T026–T027 (credential helpers) in parallel
- Within US3: T035–T037 (tests) in parallel
- Within US6: T056–T058 (tests) in parallel
- Within US7: T064–T068 (tests) in parallel
- Within US8: T073–T076 (tests) in parallel; T079–T080 (pickers) in parallel

---

## Parallel Example: Foundational Phase

```bash
# Launch the five ARB updates together:
Task: "Add the settings_* keys to lib/l10n/app_en.arb"
Task: "Add the Spanish translations to lib/l10n/app_es.arb"
Task: "Add the Portuguese translations to lib/l10n/app_pt.arb"
Task: "Add the Italian translations to lib/l10n/app_it.arb"
Task: "Add the French translations to lib/l10n/app_fr.arb"

# In parallel with the above:
Task: "Update firestore.rules per the security-rules-delta contract"
Task: "Add currencyCode to the UserProfile entity"
Task: "Add getAll/create/update/reorder/setActive to the CategoryRepository interface"
Task: "Add a third nav item (Settings) to AppShell"
Task: "Add LinkConflictFailure to failure.dart"
```

## Parallel Example: User Story 1

```bash
# Launch all three tests together:
Task: "firebase_auth_repository_test.dart — happy-path link"
Task: "firebase_auth_repository_test.dart — credential-already-in-use maps to LinkConflictFailure"
Task: "settings_account_section_test.dart — link CTA rendering and tap wiring"

# Launch the two credential helpers together:
Task: "Google Sign-In credential exchange helper"
Task: "Apple Sign-In credential exchange helper"
```

---

## Implementation Strategy

### MVP First (User Stories 1, 3, 2, and 5 — the P1 tier)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks everything)
3. Complete Phase 3 (US1) — linking works for the clean case
4. Complete Phase 4 (US3) — conflicts are handled safely, never silently
5. Complete Phase 5 (US2) — new-device recovery, built on US3
6. Complete Phase 6 (US5) — App Check active, independent of the above
7. **STOP and VALIDATE**: run `quickstart.md` steps 1–4, 6–7
8. US4/US6/US7/US8 (P2/P3) extend from there

### Incremental Delivery

1. Setup + Foundational → Security Rules, widened repositories, and the Settings shell ready
2. US1 → linking works for a clean account → verify independently
3. US3 → conflicts are handled explicitly and safely → verify independently
4. US2 → new-device recovery, provably built on US3 → verify independently → **the feature's
   core promise ("conservar su historial al cambiar o perder el dispositivo") is now delivered**
5. US5 → App Check active → verify independently → **the feature's other core promise ("acceso
   protegido contra clientes no legítimos") is now delivered**
6. US4 → offline hardening → verify independently
7. US6 → account deletion → verify independently
8. US7 → category management → verify independently
9. US8 → currency/timezone → verify independently
10. Polish → full quickstart pass

### Parallel Team Strategy

With multiple developers, after Foundational completes:

- Developer A: US1 → US3 → US2 → US4 (the full account-linking arc, in dependency order)
- Developer B: US5 (fully independent) then US6 (needs only US1's "linked session" concept, not
  US3/US2's machinery)
- Developer C: US7 and US8 (both independent of every account-linking story)

---

## Notes

- [P] tasks touch different files and have no dependency on an incomplete task
- [Story] labels map every user-story-phase task back to spec.md for traceability, even where
  this file's phase order differs from spec.md's story numbering (explained in Organization above)
- No task in Setup, Foundational, or Polish carries a [Story] label, per the checklist format rules
- `LinkAccountUseCase` depending on `ExpenseRepository`/`CategoryRepository` (T045) is the
  established, allowed cross-feature pattern (Constitution Principle 4: "only another feature's
  `domain/` repository interfaces") — not a new exception, the same reasoning `006`'s
  `WrappedRepositoryImpl` already used for its own cross-feature dependency
- Commit after each task or logical group; stop at any checkpoint to validate a story independently
  before moving on
