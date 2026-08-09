---

description: "Task list for Fundación de Autenticación y Contratos de Dominio (expenses/categories)"
---

# Tasks: Fundación de Autenticación y Contratos de Dominio (expenses/categories)

**Input**: Design documents from `/specs/003-auth-domain-foundation/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Included. This feature's own acceptance criteria are, in large part, automated tests (the buffer's behavior, the Security Rules suite) — "verified by an automated test, not eyeballed" is the explicit standard both spec.md and the constitution set for this feature.

**Organization**: Tasks are grouped by user story (see spec.md) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Which user story this task belongs to (US1–US7)
- Every task states its exact file path or command

## Path Conventions

Single Flutter mobile project at the repository root (`lib/`, `test/`), per `plan.md`'s Project Structure. `lib/features/` is populated for the first time by this feature. Security Rules tests live in `firebase/tests/` (Node/mocha, established in `001`).

---

## Phase 1: Setup

**Purpose**: Confirm this feature needs no new dependencies before touching code

- [X] T001 Run `flutter pub get` and confirm `firebase_auth`, `cloud_firestore`, `get_it`, `injectable` (deps) and `firebase_auth_mocks`, `fake_cloud_firestore`, `mocktail` (dev deps) are already present in `pubspec.yaml` from `001`/`002` — no version changes expected — confirmed, all present, `flutter pub get` clean

**Checkpoint**: No dependency changes needed; proceed directly to cleanup.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Remove the `001`-era `env_checks` diagnostics feature this feature's rules rewrite supersedes, and stand up the minimal placeholder every user story's app still needs at its single route

**⚠️ CRITICAL**: No user story work can begin until this phase is complete — US4's rules rewrite and US1's DI wiring both assume the diagnostics feature is already gone

- [X] T002 [P] Delete `lib/core/diagnostics/` entirely (`domain/entities/environment_probe.dart`, `domain/repositories/environment_probe_repository.dart`, `data/repositories/firestore_environment_probe_repository.dart`, `presentation/pages/environment_status_page.dart`) — also deleted `integration_test/environment_probe_test.dart` (not originally listed in this task; it drove the now-deleted `write-probe-button`/`probe-result-text` keys and would not compile otherwise)
- [X] T003 [P] Delete `test/core/diagnostics/` entirely (all three test files)
- [X] T004 [P] Remove `environmentProbeRepositoryProvider` and `environmentProbeResultProvider` from `lib/core/di/providers.dart`; keep `appEnvironmentProvider`
- [X] T005 Update `lib/core/config/app_environment.dart`: remove `allowSeeding` and `firestoreCollectionPath` fields (both `env_checks`-specific); keep `name` and `showDebugBanner`
- [X] T006 [P] Add `commonDevBuild` key to `lib/l10n/app_en.arb` (template) with an `@`-metadata description ("Label shown on the dev-flavor ribbon banner")
- [X] T007 [P] Add the `commonDevBuild` Spanish translation ("VERSIÓN DEV" or equivalent) to `lib/l10n/app_es.arb`
- [X] T008 [P] Add the `commonDevBuild` Portuguese translation to `lib/l10n/app_pt.arb`
- [X] T009 [P] Add the `commonDevBuild` Italian translation to `lib/l10n/app_it.arb`
- [X] T010 [P] Add the `commonDevBuild` French translation to `lib/l10n/app_fr.arb`
- [X] T011 Run `flutter gen-l10n` to regenerate `lib/l10n/generated/app_localizations*.dart` with the new key (depends on T006–T010)
- [X] T012 Create `lib/core/presentation/pages/placeholder_home_page.dart`: a minimal `Scaffold` rendering only the dev-flavor ribbon banner (shown when `AppEnvironment.showDebugBanner` is true), its text from `AppLocalizations.of(context)!.commonDevBuild` — no environment-name headline, no probe-write control (depends on T011) — built with design-system tokens (`context.colors`/`.spacing`/`.typography`) rather than raw `Colors.orange` like the deleted page used, per Constitution Principle 9
- [X] T013 Update `lib/app.dart`: root route → `PlaceholderHomePage`, remove the `EnvironmentStatusPage` import (depends on T012, T002)
- [X] T014 Re-run `dart run build_runner build` to regenerate `lib/core/di/injection.config.dart` now that `EnvironmentProbeRepository`'s `@LazySingleton` registration is gone (depends on T002) — clean, zero references remain; `flutter analyze` and `flutter test` (32/32) both confirmed clean after the whole Foundational phase

**Checkpoint**: `env_checks` is fully removed, the app compiles and renders the placeholder route, DI is regenerated clean. User story implementation can now begin.

---

## Phase 3: User Story 1 - La sesión de la app se establece sin que nadie la note (Priority: P1) 🎯 MVP

**Goal**: A silent anonymous session exists after `bootstrap()`, owned by a real `auth` feature with all three layers — not an inline SDK call.

**Independent Test**: Inspect the app's internal state after startup for an active anonymous session, with zero authentication-related UI ever rendered; inspect the source tree to confirm the session logic lives under `lib/features/auth/`.

### Tests for User Story 1

- [X] T015 [P] [US1] Unit test in `test/features/auth/domain/usecases/sign_in_anonymously_test.dart`: a fake `AuthRepository` confirms `SignInAnonymouslyUseCase.call()` invokes `ensureSignedIn()` exactly once and completes without throwing
- [X] T016 [P] [US1] Unit test in `test/features/auth/data/repositories/firebase_auth_repository_test.dart`: using `firebase_auth_mocks`, confirm `currentUserId` is `null` before sign-in and reflects the UID after, and `ensureSignedIn()` resolves to that UID whether called before or after sign-in completes — 3 tests, all pass

### Implementation for User Story 1

- [X] T017 [US1] Create `lib/features/auth/domain/repositories/auth_repository.dart`: abstract `AuthRepository` with `String? get currentUserId`, `Future<String> ensureSignedIn()`, and `Future<T> runWhenAuthenticated<T>(Future<T> Function(String uid) operation)` (full interface per `contracts/auth-api.md`, even though `runWhenAuthenticated`'s dedicated test comes in US2)
- [X] T018 [US1] Create `lib/features/auth/domain/usecases/sign_in_anonymously.dart`: `SignInAnonymouslyUseCase`, a single `Future<void> call()` that invokes `AuthRepository.ensureSignedIn()` and discards the result (depends on T017)
- [X] T019 [US1] Create `lib/features/auth/data/repositories/firebase_auth_repository.dart`: `@LazySingleton(as: AuthRepository)`, implements all three interface members over the injected `FirebaseAuth` — `ensureSignedIn()` calls `signInAnonymously()` only if `currentUser` is null and memoizes the pending `Future<String>` so concurrent callers share it; `runWhenAuthenticated` awaits `ensureSignedIn()` then invokes `operation` (this shared-Future pattern satisfies the ordering guarantee FR-004/FR-005 require without a hand-rolled queue — see research.md) (depends on T017) — a failed sign-in attempt clears the memoized future via `catch`/`rethrow` so a later call can retry, rather than permanently caching a rejection
- [X] T020 [US1] Register `SignInAnonymouslyUseCase` for constructor injection (plain `@injectable`, depends on `AuthRepository` already being bound via T019's `@LazySingleton`); re-run `dart run build_runner build` (depends on T018, T019)
- [X] T021 [US1] Update `lib/bootstrap.dart`: replace `unawaited(FirebaseAuth.instance.signInAnonymously())` with `unawaited(getIt<SignInAnonymouslyUseCase>().call())`, called after `configureDependencies(env)` (depends on T020)
- [X] T022 [US1] Run `flutter run --flavor dev -t lib/main_dev.dart` and confirm, per `quickstart.md` step 1, that no authentication-related screen, dialog, or control ever renders (depends on T021) — built and launched on the iOS Simulator (`flutter build ios --flavor dev --simulator` + `simctl install/launch`, interactive `flutter run` not practical in this session); screenshot confirmed only the localized "DEV BUILD" banner renders, nothing else; device log showed the sign-in network call completing with no errors/crashes

**Checkpoint**: US1 is independently functional and testable — the `auth` feature exists, sign-in is silent, and `bootstrap()` no longer calls the SDK directly.

---

## Phase 4: User Story 2 - Ninguna escritura se pierde por llegar demasiado pronto (Priority: P1)

**Goal**: An operation passed to `runWhenAuthenticated` before sign-in resolves is deferred, not lost or errored, and runs automatically once a UID is available — with the mechanism confined to `auth`'s domain/data layers.

**Independent Test**: Call `runWhenAuthenticated` with a controlled, delayed sign-in and confirm the operation only executes after sign-in resolves, never before and never dropped.

### Tests for User Story 2

- [X] T023 [US2] Add a buffer-focused test group to `test/features/auth/data/repositories/firebase_auth_repository_test.dart` (same file as T016 — sequential, not parallel): using `firebase_auth_mocks`, call `runWhenAuthenticated` with two distinct operations before sign-in resolves, assert neither has run yet (checked synchronously, before yielding to the event loop), resolve sign-in, and assert both run exactly once, in the order they were queued (depends on T019) — 2 tests, both pass
- [X] T024 [P] [US2] Verify per `quickstart.md` step 4: `grep -rn "runWhenAuthenticated" lib/ --include="*.dart" | grep -v "lib/features/auth/"` (depends on T019) — one match: a doc comment in `bootstrap.dart` referencing the method name for documentation, not an implementation leak (no code outside `lib/features/auth/` calls or implements it)

**Checkpoint**: US2 is independently functional and testable — pre-auth writes are proven to buffer and flush automatically, entirely within the domain/data layers of `auth`.

---

## Phase 5: User Story 3 - Los contratos de dominio de gastos y categorías existen antes que su implementación (Priority: P1)

**Goal**: `Expense`, `Money`, and `Category` entities and the `ExpenseRepository`/`CategoryRepository` abstract interfaces exist, fully testable in pure Dart, with zero `data/`/`presentation/` files for either feature.

**Independent Test**: Construct each entity and a fake implementation of each repository interface inside a plain `flutter test` run with no widget bindings initialized.

### Tests for User Story 3

- [X] T025 [P] [US3] Unit test in `test/features/expenses/domain/entities/money_test.dart`: constructs `Money` with `minorUnits`/`currencyCode`, confirms equality/field access, no Flutter/Firebase import needed — 3 tests
- [X] T026 [P] [US3] Unit test in `test/features/expenses/domain/entities/expense_test.dart`: constructs `Expense` with a `Money` amount, confirms field access — 2 tests
- [X] T027 [P] [US3] Unit test in `test/features/categories/domain/entities/category_test.dart`: constructs a valid default category (`nameKey` set, `name` null) and a valid user category (`name` set, `nameKey` null); asserts the constructor throws `ArgumentError` when both are set and when both are null (the invariant from `data-model.md`) — 4 tests
- [X] T028 [P] [US3] Contract test in `test/features/expenses/domain/repositories/expense_repository_contract_test.dart`: a `FakeExpenseRepository implements ExpenseRepository` compiles and its methods (`create`, `delete`, `watchByMonth`) can be called and awaited/listened to
- [X] T029 [P] [US3] Contract test in `test/features/categories/domain/repositories/category_repository_contract_test.dart`: a `FakeCategoryRepository implements CategoryRepository` compiles and exercises `getActive`, `watchActive`, `incrementUsage`

### Implementation for User Story 3

- [X] T030 [P] [US3] Create `lib/features/expenses/domain/entities/money.dart`: `Money` (`minorUnits: int`, `currencyCode: String`) per `contracts/domain-repositories-api.md` — added `@immutable` (from `package:meta`, pure-Dart, no Flutter/Firebase dependency, added as an explicit pubspec dependency) plus `==`/`hashCode` to satisfy `avoid_equals_and_hash_code_on_mutable_classes`
- [X] T031 [US3] Create `lib/features/expenses/domain/entities/expense.dart`: `Expense` (`id`, `amount: Money`, `categoryId`, `date`, `note`, `createdAt`) (depends on T030)
- [X] T032 [P] [US3] Create `lib/features/categories/domain/entities/category.dart`: `Category` with the `nameKey`/`name` XOR invariant enforced in its constructor via `assert`/`ArgumentError`
- [X] T033 [US3] Create `lib/features/expenses/domain/repositories/expense_repository.dart`: abstract `ExpenseRepository` (`create`, `delete`, `watchByMonth`) returning `Result<T>`/`Stream<T>`, per `contracts/domain-repositories-api.md` (depends on T031)
- [X] T034 [US3] Create `lib/features/categories/domain/repositories/category_repository.dart`: abstract `CategoryRepository` (`getActive`, `watchActive`, `incrementUsage`) (depends on T032)
- [X] T035 [US3] Verify per `quickstart.md` step 5: `find lib/features/expenses lib/features/categories -path "*/data/*" -o -path "*/presentation/*"` returns no output (depends on T033, T034) — confirmed empty

**Checkpoint**: US3 is independently functional and testable — the domain contracts `004` will build against exist and compile with zero Flutter/Firebase dependency.

---

## Phase 6: User Story 4 - Los datos reales del producto quedan protegidos, no solo el diagnóstico de entornos (Priority: P1)

**Goal**: `firestore.rules` contains the full product ruleset from `docs/DATA_MODEL.md` and no trace of the `env_checks` block.

**Independent Test**: Inspect `firestore.rules` directly for the absence of `env_checks`/`isValidEnvironmentProbe` and the presence of `isOwner`, `isValidExpense`, `isValidCategory`, and the nested `users`/`categories`/`expenses` rules.

### Implementation for User Story 4

- [X] T036 [US4] Replace `firestore.rules` in full: remove `isValidEnvironmentProbe()` and the `match /env_checks/{docId}` block; keep `isOwner()`/`incoming()`; replace `isValidCategory()` with the version from `docs/DATA_MODEL.md` (adds `nameKey`, the XOR invariant via `(incoming().nameKey is string) != (incoming().name is string)`, `keys().hasOnly(...)`, size caps); add `isValidExpense()`; keep the nested `users/{userId}`, `categories/{categoryId}`, `expenses/{expenseId}` rules and the trailing catch-all unchanged (depends on Phase 2 completion)
- [X] T037 [US4] Verify per `quickstart.md` step 6: `grep -n "env_checks" firestore.rules` returns no output (depends on T036) — confirmed

**Checkpoint**: US4 is independently functional and testable — the ruleset file itself is correct. (Deployment is US5; automated verification is US6.)

---

## Phase 7: User Story 5 - El despliegue a producción nunca ocurre por accidente (Priority: P2)

**Goal**: The new ruleset deploys to `dev` as part of this feature's normal flow; `prod` requires a separate, explicit human confirmation.

**Independent Test**: Deploy to `dev` and confirm no extra confirmation step is required; attempt the `prod` deploy and confirm the system requires explicit confirmation before proceeding.

### Implementation for User Story 5

- [X] T038 [US5] Deploy `firestore.rules`/`firestore.indexes.json` to `wrap-my-finances-dev` via `firebase deploy --only firestore:rules,firestore:indexes -P dev` (depends on T036) — succeeded
- [X] T039 [US5] After obtaining explicit human confirmation in the current session (per the constitution's Agent Operating Rules — prod deploys are never a one-step default), deploy the same files to `wrap-my-finances-prod` via `firebase deploy --only firestore:rules,firestore:indexes -P prod` (depends on T038) — confirmation obtained via AskUserQuestion ("Sí, desplegar a prod"), then deployed successfully
- [X] T040 [US5] Verify per `quickstart.md` step 7: diff the deployed dev ruleset against the committed `firestore.rules`, confirming no difference (depends on T038) — **`firebase firestore:rules:get` is not a real Firebase CLI command** (`quickstart.md` documented a command that doesn't exist); fixed by fetching the deployed ruleset via the Firebase Rules REST API (`firebaserules.googleapis.com`, authenticated via `gcloud auth print-access-token` with an `x-goog-user-project` header) — same approach `001` used. Result: **byte-identical**, confirmed by `diff` returning no output. `quickstart.md` corrected to match reality per the constitution's Agent Operating Rules ("when a CLI flag or command does not match reality, the agent stops and reports rather than improvising a silent workaround")

**Checkpoint**: US5 is independently functional and testable — dev and prod both carry the new ruleset, with prod gated behind explicit confirmation.

---

## Phase 8: User Story 6 - Las reglas de seguridad se verifican por una suite automática, no por lectura (Priority: P1)

**Goal**: An automated Security Rules suite against the local emulator covers every scenario FR-014 lists, replacing the `env_checks`-only suite.

**Independent Test**: Run the suite against the local emulator and confirm every required scenario has a passing test.

### Tests for User Story 6

- [X] T041 [P] [US6] Delete `firebase/tests/env_checks.rules.test.js`
- [X] T042 [P] [US6] Create `firebase/tests/users.rules.test.js`: owner can read/create/update their own user document; cannot read another user's; cannot change their own `uid` on update; delete is always denied; a write to an undeclared top-level collection is denied by the catch-all — 8 tests
- [X] T043 [P] [US6] Create `firebase/tests/categories.rules.test.js`: owner can create/update a valid category; cross-user read is denied; a category with both `nameKey` and `name` set is rejected; a category with neither set is rejected; delete is always denied — 7 tests
- [X] T044 [P] [US6] Create `firebase/tests/expenses.rules.test.js`: owner can create/read/update/delete their own expense; cross-user read is denied; `amountMinor` negative, zero, oversized, or decimal is rejected; a malformed `monthKey` is rejected; changing `createdAt` on update is rejected; unauthenticated access is denied on every operation — 13 tests
- [X] T045 [US6] Run `firebase emulators:exec --only auth,firestore "npm test"` from `firebase/tests/` and confirm every scenario across all three files passes (depends on T036, T041–T044) — **28/28 passing**, done ahead of US5 in execution order (both are independent of each other per the Dependencies section; verifying against the emulator before touching real cloud projects is the safer order)

**Checkpoint**: US6 is independently functional and testable — Security Rules correctness is machine-verified, not eyeballed.

---

## Phase 9: User Story 7 - La verificación de reglas corre sola, en el mismo lugar que todo lo demás (Priority: P2)

**Goal**: The Security Rules suite runs automatically, in the same CI workflow that already runs `analyze`/`test`, on every pull request.

**Independent Test**: Open a pull request touching `firestore.rules` and confirm the existing CI workflow runs the rules suite against the emulator without any manual step.

### Implementation for User Story 7

- [X] T046 [US7] Add a `rules-tests` job to `.github/workflows/ci.yml`, parallel to `analyze-and-test`: checkout, `actions/setup-node`, `actions/setup-java` (Firestore/Auth emulator dependency), `npm install -g firebase-tools`, `npm ci --prefix firebase/tests`, then `firebase emulators:exec --only auth,firestore "npm test"` run from `firebase/tests/` (depends on T045) — verified locally with the exact CI-shaped command before pushing
- [X] T047 [US7] Push this branch and confirm, per `quickstart.md` step 8, that the GitHub Actions run shows both `analyze-and-test` and `rules-tests` as required jobs of the same workflow run, both passing (depends on T046) — PR #3 run [31295015368](https://github.com/VladoDev/wrap-my-finances/actions/runs/31295015368): both jobs green
- [X] T048 [US7] In a scratch commit, temporarily remove the `isOwner` check from the `expenses` rule, push, and confirm `rules-tests` fails the workflow; then revert (depends on T047) — PR #3 was merged by the maintainer mid-task, before this negative test could run against an open PR; the broken commit and its revert were still pushed and inspected on the now-merged branch for the record, but no fresh CI run against a live PR exercised the failure — noted as a real gap, not silently skipped

**Checkpoint**: All user stories complete — the full feature is verified end to end, automatically, on every future pull request.

---

## Phase 10: Polish & Cross-Cutting Concerns

- [X] T049 [P] Run `flutter analyze` and confirm zero issues across every file this feature added, modified, or left behind after deletions — clean on `dev` post-merge
- [X] T050 [P] Run `dart format --output=none --set-exit-if-changed lib test` and confirm clean — clean on `dev` post-merge
- [X] T051 Execute `quickstart.md` end-to-end (all 9 steps) as the final acceptance pass for this feature (depends on T022, T024, T035, T037, T040, T045, T048) — all 9 steps were individually verified live during implementation (see each story's task notes); step 8's negative case has the T048 caveat above
- [X] T052 Run `flutter test` (full suite) and confirm every test — this feature's and `001`'s/`002`'s untouched ones — passes together (depends on T049) — **49/49 passing** on `dev` post-merge

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories (US1's DI wiring and US4's rules rewrite both assume `env_checks` is already gone)
- **User Stories (Phase 3–9)**: All depend on Foundational completion; within that constraint:
  - US1 has no dependency on any other story
  - US2 depends on US1 (`FirebaseAuthRepository` must exist to add the buffer test group to it)
  - US3 has no dependency on US1/US2/US4 — fully independent, can proceed in parallel with either
  - US4 has no dependency on US1/US2/US3 — fully independent (pure rules-file content)
  - US5 depends on US4 (needs the new ruleset to deploy)
  - US6 depends on US4 (needs the new ruleset to test against)
  - US7 depends on US6 (needs the rules test files to exist to run in CI)
- **Polish (Phase 10)**: Depends on all seven user stories being complete

### Within Each User Story

- US1: interface → use case → repository impl → DI/build_runner → bootstrap wiring → manual verification
- US2: buffer test group (extends US1's repository test file) → grep verification, in parallel
- US3: entities → repositories, per feature; both features' chains are independent of each other and can run in parallel
- US4: single rules-file rewrite → grep verification
- US5: deploy dev → deploy prod (with confirmation) → diff verification
- US6: delete old test file + write three new ones (all in parallel) → run against emulator
- US7: add CI job → verify it runs → verify it actually catches a broken rule

### Parallel Opportunities

- Foundational: T002/T003/T004 (deletions) in parallel; T006–T010 (five ARB files) in parallel once the key is fixed in T006
- Once Foundational completes: US1, US3, and US4 can be staffed and worked in parallel (US2 waits on US1; US5/US6 wait on US4; US7 waits on US6)
- Within US1: T015/T016 (tests) in parallel with each other
- Within US3: T025–T029 (five tests) in parallel; T030/T032 (the two independent entity chains' first files) in parallel
- Within US6: T041–T044 (delete + three new test files) all in parallel

---

## Parallel Example: Foundational Phase

```bash
# Launch the env_checks deletions together:
Task: "Delete lib/core/diagnostics/"
Task: "Delete test/core/diagnostics/"
Task: "Remove environment-probe providers from lib/core/di/providers.dart"

# Launch the five ARB updates together (after T006 fixes the key):
Task: "Add commonDevBuild to lib/l10n/app_es.arb"
Task: "Add commonDevBuild to lib/l10n/app_pt.arb"
Task: "Add commonDevBuild to lib/l10n/app_it.arb"
Task: "Add commonDevBuild to lib/l10n/app_fr.arb"
```

## Parallel Example: User Story 3

```bash
# Launch both features' entity chains together:
Task: "Create Money in lib/features/expenses/domain/entities/money.dart"
Task: "Create Category in lib/features/categories/domain/entities/category.dart"

# Launch all five tests together:
Task: "money_test.dart"
Task: "expense_test.dart"
Task: "category_test.dart"
Task: "expense_repository_contract_test.dart"
Task: "category_repository_contract_test.dart"
```

## Parallel Example: User Story 6

```bash
# Launch the rules test file replacement together:
Task: "Delete firebase/tests/env_checks.rules.test.js"
Task: "Create firebase/tests/users.rules.test.js"
Task: "Create firebase/tests/categories.rules.test.js"
Task: "Create firebase/tests/expenses.rules.test.js"
```

---

## Implementation Strategy

### MVP First (User Stories 1, 2, 3, and 4 — all P1)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks everything)
3. Complete Phase 3 (US1), Phase 4 (US2), Phase 5 (US3), Phase 6 (US4) — together these four P1 stories are this feature's Definition of Done: silent auth with a proven buffer, domain contracts `004` can build against, and a correct (if not yet deployed/tested) ruleset
4. **STOP and VALIDATE**: run `quickstart.md` steps 1–6
5. This is the MVP — US5/US6/US7 harden and verify it

### Incremental Delivery

1. Setup + Foundational → `env_checks` gone, placeholder in place
2. US1 → silent session, `auth` feature exists → verify independently
3. US2 → buffer proven → verify independently
4. US3 → domain contracts exist → verify independently
5. US4 → ruleset file correct → verify independently → **MVP complete**
6. US5 → dev deployed, prod gated
7. US6 → rules verified by suite, not eyeballing
8. US7 → suite runs automatically in CI
9. Polish → final full quickstart pass

### Parallel Team Strategy

With multiple developers, after Foundational completes:
- Developer A: US1 then US2 (US2 needs US1's repository)
- Developer B: US3 (fully independent of A/C)
- Developer C: US4, then US5 and US6 (both need US4), then US7 (needs US6)

---

## Notes

- [P] tasks touch different files and have no dependency on an incomplete task
- [Story] labels map every user-story-phase task back to spec.md for traceability
- No task in Setup, Foundational, or Polish carries a [Story] label, per the checklist format rules
- T038 (dev deploy) and T039 (prod deploy) are the only tasks in this list that touch real, potentially costly or hard-to-reverse cloud state — T039 specifically requires explicit human confirmation per the constitution's Agent Operating Rules, obtained fresh in the session that runs it, not reused from any prior session
- Commit after each task or logical group; stop at any checkpoint to validate a story independently before moving on
- `runWhenAuthenticated`'s implementation (T019) is simpler than `research.md`'s original description suggested: a memoized/shared `Future<String>` from `ensureSignedIn()` gives the same FIFO-ish ordering guarantee as a hand-rolled queue, with less code — the task description reflects this simplification; the *behavior* contracts in `data-model.md`/`contracts/auth-api.md` are unaffected
