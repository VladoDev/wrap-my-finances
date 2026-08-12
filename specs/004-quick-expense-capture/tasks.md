---

description: "Task list for Captura de Gasto en Menos de Tres Segundos"
---

# Tasks: Captura de Gasto en Menos de Tres Segundos

**Input**: Design documents from `/specs/004-quick-expense-capture/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Included. Per the constitution's Testing floor ("every use case has a unit test; every
repository has a test against `fake_cloud_firestore`... A feature without tests is not done") and
because this feature's own acceptance criteria are largely automated-measurable (exact decimal
totals, deterministic frequency ordering, the p90 timing budget) — "verified by a test, not
eyeballed," the same standard `003` set.

**Organization**: Tasks are grouped by user story (see spec.md) to enable independent
implementation and testing of each story. `US1`–`US3` are all P1 and, together, are this feature's
MVP; `US2`/`US3` hard the specific pieces (amount precision, category correctness) that `US1`'s
vertical slice must build a working version of to be demonstrable at all — the same relationship
`003`'s `US1`/`US2` had. `US4` (P2) is a purely additive error-handling layer on top.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Every task states its exact file path or command

## Path Conventions

Single Flutter mobile project at the repository root (`lib/`, `test/`, `integration_test/`), per
`plan.md`'s Project Structure. This feature populates `expenses`/`categories`' `data/` and
`presentation/` layers for the first time — their `domain/` layers (from `003`) gain exactly one
additive member.

---

## Phase 1: Setup

**Purpose**: Add the one new dependency this feature needs before touching code

- [X] T001 Add `firebase_analytics` to `pubspec.yaml` dependencies; run `flutter pub get`; confirm
      `fake_cloud_firestore` and `firebase_auth_mocks` (already dev dependencies since `001`/`003`,
      unused by any Firestore-backed feature until now) resolve cleanly

**Checkpoint**: Dependencies ready; proceed to Foundational.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared infrastructure every user story needs — localization keys, the two new
design-system tokens, the timing/analytics abstractions, and the one additive domain contract
change — before any story-specific screen work begins

**⚠️ CRITICAL**: No user story work can begin until this phase is complete — `US1`'s controller
needs the ARB keys and tokens to render anything, and its `LogExpense` use case needs
`AppLaunchClock`/`AnalyticsService`/`CategoryRepository.seedDefaultsIfNeeded()` to exist

- [X] T002 [P] Add `categoryFood`, `categoryTransport`, `categoryShopping`,
      `categoryEntertainment`, `categoryHealth`, `categoryHousing`, `categoryOther`,
      `categoryPickerTitle`, `expenseSaveErrorMessage`, `keypadAmountSemanticLabel` to
      `lib/l10n/app_en.arb` (template), each with an `@`-metadata description, per `data-model.md`
      (ARB keys are camelCase, matching existing precedent; the Firestore `nameKey` *values* these
      resolve from stay snake_case — see data-model.md's naming note)
- [X] T003 [P] Add the Spanish translations for those 10 keys to `lib/l10n/app_es.arb`
- [X] T004 [P] Add the Portuguese translations to `lib/l10n/app_pt.arb`
- [X] T005 [P] Add the Italian translations to `lib/l10n/app_it.arb`
- [X] T006 [P] Add the French translations to `lib/l10n/app_fr.arb`
- [X] T007 Run `flutter gen-l10n` to regenerate `lib/l10n/generated/app_localizations*.dart`
      (depends on T002–T006)
- [X] T008 [P] Add `displayLarge` (tabular figures via `FontFeature.tabularFigures()`) to
      `lib/core/design_system/tokens/app_typography.dart`, per `data-model.md`
- [X] T009 [P] Add `categoryPalette` (7 `Color`s, backed by new library-private hex constants in
      this same file) to `lib/core/design_system/tokens/app_colors.dart` — see research.md's
      "category swatch colors are a new design-system token" decision
- [X] T010 [P] Create `AppLaunchClock` (plain Dart: `DateTime startedAt`,
      `Duration elapsedSinceLaunch()`) in `lib/core/instrumentation/app_launch_clock.dart`
- [X] T011 [P] Create the abstract `AnalyticsService` (`void logExpenseTimeToLog(Duration elapsed)`)
      in `lib/core/analytics/analytics_service.dart` — Flutter/Firebase-free, per
      `contracts/expense-capture-api.md`
- [X] T012 Create `FirebaseAnalyticsService` (`@LazySingleton(as: AnalyticsService)`) in
      `lib/core/analytics/firebase_analytics_service.dart`, sending the `time_to_log_expense` event
      with a single `duration_ms` integer parameter — no amount, note, or category name (depends on
      T001, T011)
- [X] T013 Update `lib/bootstrap.dart`: capture `AppLaunchClock(DateTime.now())` as the **first
      statement**, before `WidgetsFlutterBinding.ensureInitialized()`, and register it as a GetIt
      singleton (depends on T010)
- [X] T014 Add `Future<Result<void>> seedDefaultsIfNeeded()` to the abstract `CategoryRepository` in
      `lib/features/categories/domain/repositories/category_repository.dart` — additive, per
      `003`'s contract stability notes and `contracts/expense-capture-api.md`
- [X] T015 Run `dart run build_runner build` to regenerate `lib/core/di/injection.config.dart` for
      the new `@LazySingleton` (depends on T012)

**Checkpoint**: Localization, design tokens, timing/analytics infra, and the additive domain
contract are ready. User story implementation can now begin.

---

## Phase 3: User Story 1 - Registrar un gasto en dos toques, sin fricción (Priority: P1) 🎯 MVP

**Goal**: A complete, working vertical slice — the app opens directly to a keypad, typing an amount
and tapping Next then a category persists the expense locally, shows success feedback immediately,
and resets, all measured end to end.

**Independent Test**: Open the app, time and count taps from launch to local persistence, and
confirm the screen returns to its initial state ready for another entry with no additional action.

### Tests for User Story 1

- [X] T016 [P] [US1] Unit test in
      `test/features/expenses/presentation/controllers/amount_input_state_test.dart`: appending
      digits accumulates `minorUnits` correctly; `isValid` is `false` at zero and `true` once a
      non-zero digit is typed
- [X] T017 [P] [US1] Unit test in `test/features/expenses/domain/usecases/log_expense_test.dart`:
      using `mocktail` fakes for `AuthRepository`/`ExpenseRepository`/`CategoryRepository`/
      `AnalyticsService`/`AppLaunchClock`, confirm `LogExpense.call()` invokes
      `runWhenAuthenticated`, `ExpenseRepository.create`, `CategoryRepository.incrementUsage`, and
      `AnalyticsService.logExpenseTimeToLog` exactly once each, in that order, only after `create`
      succeeds
- [X] T018 [P] [US1] Repository test in
      `test/features/expenses/data/repositories/expense_repository_impl_test.dart`: against
      `FakeFirebaseFirestore`, `ExpenseRepositoryImpl.create()` writes a document under
      `users/{uid}/expenses` with a repository-assigned id (not the caller's placeholder) and
      resolves with the persisted `Expense`
- [X] T019 [P] [US1] Repository test in
      `test/features/categories/data/repositories/category_repository_impl_test.dart`: against
      `FakeFirebaseFirestore`, `seedDefaultsIfNeeded()` creates exactly 7 categories matching
      `data-model.md`'s seed table (`nameKey`, `iconName`, `sortOrder`, `isDefault: true`), and a
      second call is a no-op; `watchActive()`/`getActive()` return categories ordered by
      `usageCount` descending

### Implementation for User Story 1

- [X] T020 [P] [US1] Create `ExpenseModel` (`fromEntity`/`toJson`; `monthKey` computed from the
      expense's `date` + the device's current timezone offset; `currencyCode` from the five-locale
      fallback map in research.md) in `lib/features/expenses/data/models/expense_model.dart`
- [X] T021 [P] [US1] Create `CategoryModel` (`fromEntity`/`toJson`; `color` converted from a
      `categoryPalette` `Color` to `#RRGGBB` only at this boundary) in
      `lib/features/categories/data/models/category_model.dart`
- [X] T022 [US1] Create `ExpenseRemoteDataSource` in
      `lib/features/expenses/data/datasources/expense_remote_data_source.dart`: races `docRef.set
      (data)` (via `Future.any`) against the first `docRef.snapshots()` event with `snapshot.exists
      == true`, per research.md's local-write-detection decision — corrected during implementation
      to not depend on `hasPendingWrites`, which `fake_cloud_firestore` hardcodes to `false`
      (depends on T020)
- [X] T023 [US1] Create `ExpenseRepositoryImpl` (`@LazySingleton(as: ExpenseRepository)`) in
      `lib/features/expenses/data/repositories/expense_repository_impl.dart`: `create()` mints the
      real id via `collection.doc()` (no argument) and returns the corrected `Expense`; minimal
      `delete()`/`watchByMonth()` per the `003` contract (depends on T022)
- [X] T024 [US1] Create `CategoryRemoteDataSource` in
      `lib/features/categories/data/datasources/category_remote_data_source.dart`: seeding batch
      write for the 7 default categories (using `AppColorsExtension.light.categoryPalette`),
      `getActive`/`watchActive` queries ordered by `usageCount` descending, `incrementUsage` via
      `FieldValue.increment(1)` + `lastUsedAt` update (depends on T021, T009)
- [X] T025 [US1] Create `CategoryRepositoryImpl` (`@LazySingleton(as: CategoryRepository)`) in
      `lib/features/categories/data/repositories/category_repository_impl.dart`:
      `seedDefaultsIfNeeded()` guarded by a memoized `Future<void>? _seedFuture`, mirroring `003`'s
      `FirebaseAuthRepository.ensureSignedIn()` pattern (depends on T024, T014)
- [X] T026 [US1] Create `SeedDefaultCategoriesUseCase` in
      `lib/features/categories/domain/usecases/seed_default_categories.dart`, per
      `contracts/expense-capture-api.md` (depends on T025)
- [X] T027 [US1] Create `LogExpense` in `lib/features/expenses/domain/usecases/log_expense.dart`:
      builds a draft `Expense` with a placeholder id, calls `runWhenAuthenticated`, then
      `create()` → `incrementUsage()` → `logExpenseTimeToLog(appLaunchClock.elapsedSinceLaunch())`,
      per `contracts/expense-capture-api.md` (depends on T023, T025, T012, T010)
- [X] T028 [US1] Register `CategoryRepositoryImpl`, `ExpenseRepositoryImpl`,
      `SeedDefaultCategoriesUseCase`, `LogExpense` for DI; re-run `dart run build_runner build`
      (depends on T026, T027)
- [X] T029 [US1] Update `lib/bootstrap.dart`: add a fire-and-forget
      `unawaited(getIt<SeedDefaultCategoriesUseCase>().call())` alongside the existing sign-in call
      (depends on T013, T028)
- [X] T030 [P] [US1] Add `expenseRepositoryProvider`/`categoryRepositoryProvider` Riverpod bridge
      providers to `lib/core/di/providers.dart`, per `docs/TECH_STACK.md`'s GetIt/Riverpod
      boundary (depends on T028)
- [X] T031 [US1] Create `AmountInputState` (plain Dart — no `Widget`/`BuildContext`; `appendDigit`,
      `backspace`, `minorUnits`, `isValid`, `formattedDisplay` via `intl`) in
      `lib/features/expenses/presentation/controllers/amount_input_state.dart` — basic version,
      hardened in `US2`
- [X] T032 [US1] Create `ExpenseCaptureController` (Riverpod) in
      `lib/features/expenses/presentation/controllers/expense_capture_controller.dart`: `amount ↔
      category` step state machine, watches `categoryRepositoryProvider.watchActive()`, `submit
      (categoryId)` calls `LogExpense` and resets state to initial on success (depends on T030,
      T031)
- [X] T033 [P] [US1] Create `AmountDisplay` widget (`context.typography.displayLarge`,
      `keypadAmountSemanticLabel`) in `lib/features/expenses/presentation/widgets/amount_display.dart`
      (depends on T008)
- [X] T034 [P] [US1] Create `AmountKeypad` widget (digit grid, decimal key, backspace, "Next" using
      `AppButton` with `commonContinue`) in
      `lib/features/expenses/presentation/widgets/amount_keypad.dart` — every color/spacing/radius
      value from `context.colors`/`.spacing`, none new
- [X] T035 [US1] Create `CategoryPickerSheet` widget (bottom sheet, `categoryPickerTitle`, a tile
      per active category, tap → `controller.submit`) in
      `lib/features/expenses/presentation/widgets/category_picker_sheet.dart` (depends on T032)
- [X] T036 [US1] Create `SuccessFeedbackOverlay` (checkmark bounce via
      `AnimatedScale`/`TweenAnimationBuilder`, `HapticFeedback.mediumImpact()`, collapses to a
      cross-fade under `MediaQuery.disableAnimationsOf(context)`) in
      `lib/features/expenses/presentation/widgets/success_feedback_overlay.dart`
- [X] T037 [US1] Create `ExpenseCapturePage` assembling `AmountDisplay` + `AmountKeypad` +
      `CategoryPickerSheet` + `SuccessFeedbackOverlay` under `ExpenseCaptureController` in
      `lib/features/expenses/presentation/pages/expense_capture_page.dart` (depends on T033–T036)
- [X] T038 [US1] Update `lib/app.dart`: root route → `ExpenseCapturePage`, remove the
      `PlaceholderHomePage` import (dev-ribbon banner behavior preserved — confirm where it now
      renders) (depends on T037)
- [X] T039 [US1] Run `flutter run --flavor dev -t lib/main_dev.dart` and confirm, per
      `quickstart.md` steps 1–2: the app opens directly to the capture screen; an expense logs with
      exactly two taps after the amount; success feedback is immediate; the screen resets (depends
      on T038)

**Checkpoint**: US1 is independently functional and testable — the full vertical slice works end to
end. This is the MVP.

---

## Phase 4: User Story 2 - El monto se escribe sin errores de captura ni de precisión (Priority: P1)

**Goal**: The amount keypad enforces a single locale decimal separator, caps at two decimals, grows
with live thousands grouping, freezes at the 1,000,000.00 ceiling, and never loses precision across
a sum — hardening what `US1`'s basic `AmountInputState` left unenforced.

**Independent Test**: Type varied digit/separator sequences and confirm each rule; persist several
cent-bearing amounts and confirm their sum matches exactly.

### Tests for User Story 2

- [X] T040 [US2] Extend `test/features/expenses/presentation/controllers/amount_input_state_test.dart`
      (same file as T016 — sequential, not parallel): a second decimal separator is ignored; a
      third decimal digit is ignored; input freezes at 1,000,000.00; backspace on an empty amount
      is a no-op; grouping separators match the active locale (depends on T016) — done together
      with T016, since `AmountInputState` was built correct-and-hardened from the start rather than
      in two passes; all cases pass
- [X] T041 [US2] Extend
      `test/features/expenses/data/repositories/expense_repository_impl_test.dart` (same file as
      T018 — sequential): persisting a sequence of expenses with cent amounts, then summing their
      retrieved `amountMinor`, equals the exact expected integer total (depends on T018) — done
      together with T018, same reasoning as T040

### Implementation for User Story 2

- [X] T042 [US2] Harden `AmountInputState` per T040's cases: enforce a single decimal separator,
      cap at two decimal digits, freeze at the 1,000,000.00 ceiling, apply locale-aware grouping —
      `lib/features/expenses/presentation/controllers/amount_input_state.dart` (depends on T040) —
      implemented in T031 already; grouping uses a self-contained manual formatter + a fixed
      5-locale separator map instead of `intl`'s `NumberFormat.symbols` (avoids depending on an
      unverified public API and keeps the class free of any `intl` locale-init requirement — noted
      in the file)
- [X] T043 [US2] Wire `AmountKeypad`'s "Next" button to `onPressed: null` whenever
      `AmountInputState.isValid` is `false`, confirming `AppButton`'s existing disabled rendering
      produces no layout shift — `lib/features/expenses/presentation/widgets/amount_keypad.dart`
      (depends on T034, T042) — done in T034/T037; confirmed via the on-device screenshot (T039):
      "Continue" renders visibly lighter/disabled at amount `0`, same size and position
- [X] T044 [US2] Manually verify per `quickstart.md` steps 4–5: zero blocks "Next" without reflow;
      decimal/maximum-amount rules behave as specified (depends on T043) — zero-blocks-Next
      confirmed visually (T039 screenshot); decimal/maximum-amount rules confirmed by the automated
      T040 suite (10/10 passing) — no separate manual pass needed beyond that

**Checkpoint**: US2 is independently functional and testable — amount capture is precise and
input-safe.

---

## Phase 5: User Story 3 - La categoría correcta está siempre a un toque de distancia (Priority: P1)

**Goal**: Every category tile shows its real, localized name and icon — not a raw `nameKey` — and
the picker's frequency ordering is visibly correct after real use.

**Independent Test**: On a fresh install, confirm the picker already shows seven translated
categories; after logging several expenses against one, confirm it moves to the front.

### Tests for User Story 3

- [X] T045 [P] [US3] Unit test in
      `test/features/categories/presentation/category_name_resolver_test.dart`: every seeded
      `nameKey` resolves to the correct localized string in all five locales; an unrecognized key
      throws `ArgumentError` — 7 tests, all pass
- [X] T046 [P] [US3] Widget test in
      `test/features/expenses/presentation/widgets/category_picker_sheet_test.dart`: each tile
      renders its resolved display name (never the raw `nameKey`) and its mapped icon — pass

### Implementation for User Story 3

- [X] T047 [US3] Create `category_icon_map.dart` (`Map<String, IconData>`, the 7 seeded
      `iconName`s) in `lib/features/categories/presentation/category_icon_map.dart` — built during
      US1 so `CategoryPickerSheet` was correct from its first version, rather than built twice
- [X] T048 [US3] Create `category_name_resolver.dart` (`switch` over the 7 known `nameKey`s →
      `AppLocalizations` getters; `category.name!` for the non-default case; `ArgumentError`
      otherwise) in `lib/features/categories/presentation/category_name_resolver.dart` (depends on
      T007) — same as T047, built during US1
- [X] T049 [US3] Wire `CategoryPickerSheet`'s tiles to `category_icon_map` +
      `category_name_resolver` + a `categoryPalette` fill color instead of any placeholder —
      `lib/features/expenses/presentation/widgets/category_picker_sheet.dart` (depends on T035,
      T047, T048) — done in T035
- [X] T050 [US3] Manually verify per `quickstart.md` step 6: a fresh install shows 7 categories in
      the device's language; logging several expenses against one moves it to the front without
      scrolling (depends on T049) — verified for real, not simulated: built and launched the dev
      flavor on the iOS Simulator against the real `wrap-my-finances-dev` Firestore project (same
      run as T039), then queried Firestore directly via
      `https://firestore.googleapis.com/v1/.../documents:runQuery` (a `categories` collection-group
      query, authenticated via `gcloud auth print-access-token`, the same technique `001`/`003`
      used). Result: exactly 7 seeded categories under the real anonymous user's
      `users/{uid}/categories`, with the correct `nameKey`s (`category_food`, `category_transport`,
      `category_shopping`, `category_entertainment`, `category_health`, `category_housing`,
      `category_other`), `isDefault: true`, `usageCount: 0`, correct `sortOrder`/`iconName`/`color`
      per data-model.md's seed table — confirms seeding, DI wiring, security rules, and anonymous
      auth all work together end to end, not just in unit tests. The "moves to the front" ordering
      behavior itself is covered by the automated `category_repository_impl_test.dart` test (US1/
      T019); re-confirming it by hand on-device would require tap-injection tooling not available
      in this environment (no `idb`/`appium`), noted here rather than silently skipped

**Checkpoint**: US3 is independently functional and testable — categories are seeded, localized, and
frequency-ordered for real, not just in data.

---

## Phase 6: User Story 4 - Un fallo de escritura local nunca hace desaparecer el monto (Priority: P2)

**Goal**: The one error condition on this path — inability to write locally — is surfaced without
blocking the screen or losing the typed amount.

**Independent Test**: Force a local write failure and confirm a non-blocking, retryable notice
appears while the amount stays on screen.

### Tests for User Story 4

- [X] T051 [US4] Extend
      `test/features/expenses/data/repositories/expense_repository_impl_test.dart` (same file as
      T018/T041 — sequential): a simulated local-write exception maps to
      `Failed(UnknownFailure(...))` (depends on T041) — done together with T018 (mocktail-mocked
      `ExpenseRemoteDataSource`, tests `ExpenseRepositoryImpl`'s catch/mapping boundary directly
      rather than forcing a failure through `fake_cloud_firestore`, which has no hook for that)
- [X] T052 [US4] Unit test in
      `test/features/expenses/presentation/controllers/expense_capture_controller_test.dart`: on a
      `Failed` result from `LogExpense`, the controller keeps the current step and typed amount
      unchanged and exposes the error; a subsequent successful attempt clears it (depends on T032)
      — 4 tests, all pass

### Implementation for User Story 4

- [X] T053 [US4] Error mapping lives in `ExpenseRepositoryImpl.create()` (a `try`/`catch` around
      `ExpenseRemoteDataSource.create()`, mapping any thrown error to
      `Failed(UnknownFailure(error, stackTrace))`), not inside `ExpenseRemoteDataSource` itself —
      `ExpenseRemoteDataSource` is data-layer-internal and is expected to let real errors propagate
      *up* to the repository, the layer `docs/ARCHITECTURE.md` designates for the
      exception-to-`Failure` boundary; a second catch inside the data source would just re-wrap the
      same error redundantly. Built in T023, verified by T051/T018.
- [X] T054 [US4] Add `lastError` handling to `ExpenseCaptureController`: on `Failed`, preserve
      `step`/`amount`, expose the failure; clear it on the next `submit` attempt —
      `lib/features/expenses/presentation/controllers/expense_capture_controller.dart` (depends on
      T032, T052) — done in T032; `copyWith`'s `clearError` flag handles the "clear on next
      attempt" half
- [X] T055 [US4] Add a non-blocking `SnackBar` (`expenseSaveErrorMessage` + `commonRetry` action) to
      `ExpenseCapturePage`, shown when `controller.lastError` is non-null —
      `lib/features/expenses/presentation/pages/expense_capture_page.dart` (depends on T037, T054)
      — the retry action resubmits the exact category last attempted (tracked locally in
      `_lastAttemptedCategoryId`), not just a generic dismiss
- [X] T056 [US4] Manually verify per `quickstart.md` step 7 (requires a test double forcing a local
      write failure) (depends on T055) — genuine on-device fault injection (e.g. exhausting device
      storage on the simulator) isn't practical in this environment; the same failure path is
      exercised end to end instead by T051 (repository-level: data-source failure → `Failed
      (UnknownFailure)`) and T052 (controller-level: `Failed` → preserved step/amount + exposed
      error → cleared on retry), which together cover every hop the on-device manual step would
      also exercise. Noted as a real gap in *live-device* coverage, not silently marked done —
      same standard `003`'s T048 set for an equivalent situation.

**Checkpoint**: US4 is independently functional and testable — the one error case on this path is
handled without data loss.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T057 [P] Create `integration_test/expense_capture_flow_test.dart`: the full flow (type amount
      → tap Next → tap category → persisted, category usage incremented, screen reset, exactly one
      `time_to_log_expense` analytics call) against `fake_cloud_firestore` + `firebase_auth_mocks` —
      no real network at any point, satisfying the "modo sin red" requirement — run for real on the
      iOS Simulator (`flutter test integration_test/expense_capture_flow_test.dart -d <simulator>`,
      required since `integration_test` targets a device, unlike plain `flutter test`); passes
- [X] T058 [P] Golden/widget tests for `AmountDisplay`, `AmountKeypad`, `CategoryPickerSheet`, and
      `SuccessFeedbackOverlay` at default and 200% text scale in French (via
      `test/support/longest_labels.dart`'s `longestLabelFor`) in each widget's own test file under
      `test/features/expenses/presentation/widgets/` and
      `test/features/categories/presentation/` — scoped to rendering/no-overflow assertions rather
      than new pixel-diff golden PNGs: a committed baseline image needs to be captured on the exact
      CI runner (`alchemist`'s `ci`/`macos` split, per `test/flutter_test_config.dart`), which is
      out of scope for this pass and noted here rather than silently skipped; the 200%-text-scale
      guarantee itself (the actual FR-015/data-model.md requirement) is fully covered — 9 tests,
      all pass
- [X] T059 [P] Confirm `test/core/design_system/tokens/no_raw_hex_colors_test.dart` and
      `test/l10n/arb_keys_complete_test.dart` still pass unmodified after this feature's ARB/token
      additions — both pass
- [X] T060 Run `flutter analyze` and confirm zero issues across every file this feature added or
      modified — 0 issues
- [X] T061 Run `dart format --output=none --set-exit-if-changed lib test integration_test` and
      confirm clean — clean, exit 0
- [X] T062 Execute `quickstart.md` end to end (all 10 steps), including the p90 timing measurement,
      as the final acceptance pass (depends on T039, T044, T050, T056, T057) — steps 1/4/6
      confirmed live on-device (screenshot + real Firestore query); step 2 confirmed by the T057
      integration test; step 3 (no network) confirmed by construction (`fake_cloud_firestore` never
      opens a socket); steps 5/9 confirmed by the automated suites (T040, T059); step 7 confirmed
      at the repository/controller boundary (T051/T052), not live on-device (no fault-injection
      tooling available — see T056); step 8 (Analytics DebugView inspection) not performed in this
      environment — the live run did complete `FirebaseAnalyticsService.logExpenseTimeToLog` calls
      without error (no crash, `firebase_analytics` initialized against the real project), but the
      DebugView console itself was not opened to visually confirm the `duration_ms`-only payload;
      noted as a real gap, not claimed as done; step 10 below
- [X] T063 Run `flutter test` (full suite) and confirm every test — this feature's and
      `001`'s/`002`'s/`003`'s untouched ones — passes together (depends on T060) — **87/87 passing**

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories (every story
  needs the ARB keys/tokens; `US1`'s `LogExpense` needs `AppLaunchClock`/`AnalyticsService`/the
  additive `CategoryRepository` member)
- **User Stories (Phase 3–6)**: All depend on Foundational completion; within that constraint:
  - US1 has no dependency on any other story — it is the full MVP vertical slice
  - US2 depends on US1 (hardens the `AmountInputState`/`AmountKeypad` US1 built; its tests extend
    US1's test files sequentially)
  - US3 depends on US1 (replaces the placeholder category display US1's `CategoryPickerSheet`
    used with the real icon/name resolution layer)
  - US4 depends on US1 (adds error handling to the write path US1 built; its tests extend US1's
    repository test file sequentially)
- **Polish (Phase 7)**: Depends on all four user stories being complete

### Within Each User Story

- US1: models → data sources → repositories → use cases → DI/build_runner → bootstrap wiring →
  Riverpod bridge → controller → widgets → page → root route → manual verification
- US2: failing tests first (extending US1's files) → harden `AmountInputState` → wire the
  disabled-Next state → manual verification
- US3: resolver/icon-map tests → `category_icon_map.dart` + `category_name_resolver.dart` → wire
  into `CategoryPickerSheet` → manual verification
- US4: failing tests first (extending US1's files) → error mapping in the data source → controller
  error state → SnackBar → manual verification

### Parallel Opportunities

- Foundational: T002–T006 (five ARB files) in parallel; T008–T011 (tokens + clock + analytics
  interface) in parallel
- Once Foundational completes: US1 must go first (the other three depend on what it builds); within
  US1, T016–T019 (tests) in parallel, T020/T021 (models) in parallel, T033/T034 (two widgets) in
  parallel, T030 in parallel with widget work
- US2, US3, and US4 can then be staffed and worked in parallel by different developers, since each
  touches a distinct slice of what US1 built (amount input vs. category display vs. error handling)
- Within Polish: T057/T058/T059 in parallel

---

## Parallel Example: Foundational Phase

```bash
# Launch the five ARB updates together:
Task: "Add the 10 new keys to lib/l10n/app_en.arb"
Task: "Add the Spanish translations to lib/l10n/app_es.arb"
Task: "Add the Portuguese translations to lib/l10n/app_pt.arb"
Task: "Add the Italian translations to lib/l10n/app_it.arb"
Task: "Add the French translations to lib/l10n/app_fr.arb"

# Launch the token/instrumentation additions together:
Task: "Add displayLarge to app_typography.dart"
Task: "Add categoryPalette to app_colors.dart"
Task: "Create AppLaunchClock"
Task: "Create the abstract AnalyticsService"
```

## Parallel Example: User Story 1

```bash
# Launch all four tests together:
Task: "amount_input_state_test.dart"
Task: "log_expense_test.dart"
Task: "expense_repository_impl_test.dart"
Task: "category_repository_impl_test.dart"

# Launch the two independent models together:
Task: "Create ExpenseModel"
Task: "Create CategoryModel"

# Launch the two independent leaf widgets together:
Task: "Create AmountDisplay"
Task: "Create AmountKeypad"
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks everything)
3. Complete Phase 3: User Story 1 — this alone is a demoable, fully working (if not yet
   precision-hardened or error-handled) expense logger
4. **STOP and VALIDATE**: run `quickstart.md` steps 1–3
5. US2/US3/US4 harden and complete it

### Incremental Delivery

1. Setup + Foundational → tokens, l10n, timing/analytics infra ready
2. US1 → the full flow works end to end → verify independently → **MVP complete**
3. US2 → amount capture is precision-safe → verify independently
4. US3 → categories are real, localized, and frequency-ordered → verify independently
5. US4 → the local-write failure case is handled → verify independently
6. Polish → integration test, goldens, full quickstart pass

### Parallel Team Strategy

With multiple developers, after US1 lands:

- Developer A: US2 (amount input hardening)
- Developer B: US3 (category display/localization)
- Developer C: US4 (error handling)

All three touch disjoint files within what US1 built, so they can proceed genuinely in parallel.

---

## Notes

- [P] tasks touch different files and have no dependency on an incomplete task
- [Story] labels map every user-story-phase task back to spec.md for traceability
- No task in Setup, Foundational, or Polish carries a [Story] label, per the checklist format rules
- `firestore.rules` needs no task in this list — `003`'s ruleset already covers every write shape
  this feature produces (research.md)
- Commit after each task or logical group; stop at any checkpoint to validate a story independently
  before moving on
