---

description: "Task list for Resumen Mensual Animado y Compartible"
---

# Tasks: Resumen Mensual Animado y Compartible

**Input**: Design documents from `/specs/006-monthly-wrapped-summary/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Included, per the constitution's Testing-floor standard `004`/`005` both followed. This
feature's acceptance criteria (exact totals/top-category/count/biggest-expense, deleted-expense
exclusion, syncing-state detection, exactly-once-per-month across devices, no monetary data in
analytics) are automated-measurable, not eyeballed.

**Organization**: Tasks are grouped by user story (see spec.md), but **not in spec numbering
order** — the same deliberate reordering `005` used (build the screen content before wiring real
navigation to it). Spec's `US1` (auto-trigger) is the story that makes this feature valuable, but
it structurally *depends on* `US2`'s sequencer existing to navigate into and `US3`'s real content to
be worth navigating to. So this file builds `US2` (story mechanics, with placeholder content) and
`US3` (real content, correctness) first — independently of each other, in parallel if staffed — then
`US1` integrates them into the real auto-trigger experience. `US4`/`US5` (P2) layer on afterward.
Every task still carries its correct spec story label for traceability.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Which user story this task belongs to (US1–US5)
- Every task states its exact file path or command

## Path Conventions

Single Flutter mobile project at the repository root (`lib/`, `test/`, `firebase/tests/`), per
`plan.md`'s Project Structure. Two new feature modules: `lib/features/user_profile/` and
`lib/features/wrapped/`.

---

## Phase 1: Setup

**Purpose**: Add the two new dependencies this feature is the first to need

- [X] T001 Add `flutter_animate` and `share_plus` to `pubspec.yaml` dependencies (per
      `docs/TECH_STACK.md` and `research.md` #4); run `flutter pub get` and confirm clean

**Checkpoint**: Dependencies ready; proceed to Foundational.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Localization keys, the new motion token file, the `user_profile` feature (the
`users/{userId}` document no feature has written until now — `research.md` #1), and the `wrapped`
feature's data layer (`WrappedSummary` computation + partial-sync detection). Every user story
needs at least one of these.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Localization & design tokens

- [X] T002 [P] Add `wrapped_*` ARB keys to `lib/l10n/app_en.arb` (template):
      `wrappedGrandTotalTitle` ({amount} placeholder), `wrappedBlackHoleTitle` ({category}),
      `wrappedHabitTitle` ({count}, {category}), `wrappedBiggestHitTitle` ({amount}),
      `wrappedSyncingMessage`, `wrappedShareAmountsToggleLabel`, `wrappedShareButtonLabel`,
      `wrappedShareCardMonthLabel` ({month}), `wrappedSuppressedCardTitle`,
      `wrappedSuppressedCardCta`, `wrappedMonthPickerEntryLabel`, `wrappedMonthPickerTitle` — each
      with an `@`-metadata `description` ending in the native-speaker-review flag
      `docs/TECH_STACK.md` specifies for `wrapped_*` keys (`research.md` #11)
- [X] T003 [P] Add the Spanish translations for those 12 keys to `lib/l10n/app_es.arb`
- [X] T004 [P] Add the Portuguese translations to `lib/l10n/app_pt.arb`
- [X] T005 [P] Add the Italian translations to `lib/l10n/app_it.arb`
- [X] T006 [P] Add the French translations to `lib/l10n/app_fr.arb`
- [X] T007 Run `flutter gen-l10n` to regenerate `lib/l10n/generated/app_localizations*.dart`
      (depends on T002–T006)
- [X] T008 [P] Create `AppMotionExtension` (`ThemeExtension`, matching `AppSpacingExtension`'s
      exact shape) in `lib/core/design_system/tokens/app_motion.dart`: `springCurve` (the
      bounce/spring `Curve` every Wrapped entrance uses), `storyAdvanceDuration` (5–7s per
      `docs/UI_UX_SPEC.md` §3), `countUpDuration`, `crossfadeDuration` (reduce-motion fallback) —
      per `research.md` #5
- [X] T009 [P] Register `AppMotionExtension.standard` in `lib/core/design_system/theme/app_theme.dart`
      and add the `context.motion` accessor to
      `lib/core/design_system/theme/design_tokens.dart`, matching `.colors`/`.typography`/`.spacing`
      (depends on T008)
- [X] T010 [P] Unit test in `test/core/design_system/tokens/app_motion_test.dart`: `standard`
      exposes non-null `springCurve`/all durations; `lerp`/`copyWith` behave like
      `AppSpacingExtension`'s existing tests

### `user_profile` feature

- [X] T011 [P] Create `UserProfile` entity (`uid`, `timeZone`, `wrappedLastSeenMonth`) in
      `lib/features/user_profile/domain/entities/user_profile.dart`, per `data-model.md` §1
- [X] T012 [P] Create `UserProfileRepository` abstract contract
      (`ensureExists()`, `watchProfile()`, `markWrappedSeen(String monthKey)`) in
      `lib/features/user_profile/domain/repositories/user_profile_repository.dart`, per
      `contracts/wrapped-domain-api.md`
- [X] T013 [P] Extend `lib/features/expenses/data/device_locale_defaults.dart` (or a sibling
      `lib/features/user_profile/data/device_locale_timezone_defaults.dart` if keeping
      `user_profile` free of a cross-feature `data/` import) with a fixed 5-entry
      language-code-to-IANA-time-zone map (`en`→`America/New_York`, `es`→`America/Mexico_City`,
      `pt`→`America/Sao_Paulo`, `it`→`Europe/Rome`, `fr`→`Europe/Paris`), mirroring the existing
      `_currencyByLanguage` map's reasoning (depends on T011)
- [X] T014 Create `UserProfileModel`
      (`lib/features/user_profile/data/models/user_profile_model.dart`) and
      `UserProfileRemoteDataSource` (`lib/features/user_profile/data/datasources/user_profile_remote_data_source.dart`):
      `ensureExists(userId)` reads `users/{userId}`, creates it with `uid` + device-locale
      `timeZone` default only if it doesn't exist (idempotent, mirrors
      `CategoryRepositoryImpl.seedDefaultsIfNeeded`'s memoized-`Future` guard);
      `watchProfile(userId)` streams the document, mapping absent optional fields to `null`;
      `markWrappedSeen(userId, monthKey)` does a single-field `update()` (depends on T013)
- [X] T015 Create `UserProfileRepositoryImpl` (`@LazySingleton(as: UserProfileRepository)`) over
      `UserProfileRemoteDataSource` and the injected `FirebaseAuth`, same
      resolve-current-uid-with-an-assert pattern as `CategoryRepositoryImpl`, in
      `lib/features/user_profile/data/repositories/user_profile_repository_impl.dart` (depends on
      T012, T014)
- [X] T016 [P] Create `EnsureUserProfileUseCase` (`@injectable`) in
      `lib/features/user_profile/domain/usecases/ensure_user_profile.dart`, per
      `contracts/wrapped-domain-api.md` (depends on T012)
- [X] T017 Update `lib/bootstrap.dart`: add a fire-and-forget
      `unawaited(getIt<EnsureUserProfileUseCase>().call())` alongside the existing sign-in/category-
      seed/purge calls, never blocking first frame (depends on T016)
- [X] T018 Add `userProfileRepositoryProvider` to `lib/core/di/providers.dart`, matching
      `expenseRepositoryProvider`'s bridge pattern (depends on T015)

### Security Rules (`users/{userId}` field validation — a real, pre-existing gap)

- [X] T019 Add `isValidUserProfile()` to `firestore.rules` and wire it into the
      `match /users/{userId}` block's `create`/`update` rules, exactly as specified in
      `contracts/security-rules-delta.md` (depends on nothing — can run in parallel with T002–T018)
- [X] T020 Extend `firebase/tests/users.rules.test.js` with the 5 new cases from
      `contracts/security-rules-delta.md` § Required test additions (uid+timeZone-only create
      succeeds; well-formed `wrappedLastSeenMonth` succeeds; malformed one rejected; missing
      `timeZone` rejected; undeclared key rejected); confirm the existing 6 tests still pass
      unmodified against their `validUser()` fixture (depends on T019)

### `wrapped` feature data layer

- [X] T021 [P] Create `WrappedSummary` entity (`monthKey`, `isSyncing`, `total`, `topCategoryId`,
      `topCategoryExpenseCount`, `biggestExpense`, `expenseCount`) in
      `lib/features/wrapped/domain/entities/wrapped_summary.dart`, per `data-model.md` §2
- [X] T022 [P] Create `WrappedRepository` abstract contract (`getSummary(String monthKey)`) in
      `lib/features/wrapped/domain/repositories/wrapped_repository.dart`, per
      `contracts/wrapped-domain-api.md` (depends on T021)
- [X] T023 Create `WrappedRemoteDataSource`
      (`lib/features/wrapped/data/datasources/wrapped_remote_data_source.dart`): one method,
      `Future<int> serverCount(String userId, String monthKey)`, issuing
      `.where('monthKey', isEqualTo: monthKey).where('deletedAt', isNull: true).count().get(const
      GetOptions(source: Source.server))` against the existing `users/{userId}/expenses`
      collection — the one piece of this feature that needs direct Firestore access, per
      `research.md` #6
- [X] T024 Create `WrappedRepositoryImpl` (`@LazySingleton(as: WrappedRepository)`) in
      `lib/features/wrapped/data/repositories/wrapped_repository_impl.dart`: takes the injected
      `ExpenseRepository` (an existing `003` domain interface — allowed cross-feature dependency,
      Constitution Principle 4), `CategoryRepository`, `WrappedRemoteDataSource`, and `FirebaseAuth`.
      `getSummary(monthKey)` calls `expenseRepository.watchByMonth(monthKey).first` for the
      already-deleted-filtered local list, folds it into the four figures (ties on `topCategoryId`
      broken by lowest `sortOrder`, per `data-model.md` §2), and compares
      `localList.length` against `wrappedRemoteDataSource.serverCount(...)` to set `isSyncing`
      (depends on T022, T023)
- [X] T025 Add `wrappedRepositoryProvider` to `lib/core/di/providers.dart` (depends on T024)
- [X] T026 Run `dart run build_runner build` to regenerate `injection.config.dart` for every new
      `@injectable`/`@LazySingleton` registration from this phase (depends on T015, T016, T024)

**Checkpoint**: `users/{userId}` exists and is validated server-side; `WrappedRepository.getSummary()`
computes a correct, sync-aware summary from the existing local cache. Every user story can now
build on this.

---

## Phase 3: User Story 2 - La secuencia se navega como una historia (Priority: P1)

**Goal**: A working story sequencer — auto-advance with visible progress, tap-right/tap-left/
long-press-pause/swipe-down-dismiss, and full reduce-motion collapse — proven correct against
placeholder scene content, independent of `US3`'s real figures or `US1`'s trigger.

**Independent Test**: Pump `WrappedPage` directly (widget test, no real navigation) with a fixed
list of dummy scene widgets and confirm every control (advance, back, pause, dismiss) and the
progress bar behave correctly, with and without reduce-motion simulated.

### Tests for User Story 2

- [X] T027 [P] [US2] Unit test in
      `test/features/wrapped/presentation/controllers/wrapped_controller_test.dart`: `advance()`
      moves to the next scene or dismisses past the last one; `goBack()` moves back (no-op on the
      first scene); `pause()`/`resume()` suspend/resume the auto-advance timer (using an injectable
      short `storyAdvanceDuration` for fast tests); `dismiss()` ends the sequence immediately from
      any scene — mirrors `005`'s `ExpenseHistoryController` test's injectable-timer pattern
- [X] T028 [P] [US2] Widget test in
      `test/features/wrapped/presentation/widgets/wrapped_progress_bar_test.dart`: renders one
      segment per scene, fills the active segment over `storyAdvanceDuration`, and previously-
      visited segments render fully filled
- [X] T029 [US2] Widget test in `test/features/wrapped/presentation/pages/wrapped_page_test.dart`:
      pumped with placeholder scene widgets — tapping the right half advances, tapping the left
      half goes back, a long-press-and-hold pauses auto-advance (verified via `tester.pump` not
      advancing during the hold), a downward drag dismisses; with
      `MediaQuery(disableAnimations: true)`, scene transitions render as immediate cross-fades (no
      `AppMotionExtension.springCurve` animation observed)

### Implementation for User Story 2

- [X] T030 [US2] Create `WrappedState`/`WrappedController` (Riverpod `Notifier` or
      `StateNotifier`) per `contracts/wrapped-domain-api.md`, using `context.motion` — no, using
      injected `AppMotionExtension` values passed at construction (controller is Flutter-free
      Riverpod state, no `BuildContext`) — in
      `lib/features/wrapped/presentation/controllers/wrapped_controller.dart` (depends on T027)
- [X] T031 [P] [US2] Create `WrappedProgressBar` (rounded segmented bar, one segment per scene,
      active segment animates fill over `context.motion.storyAdvanceDuration`, collapses to an
      instant fill under reduce-motion) in
      `lib/features/wrapped/presentation/widgets/wrapped_progress_bar.dart` (depends on T028)
- [X] T032 [US2] Create `WrappedPage` (`ConsumerWidget`, takes `monthKey` and a scene-widget list —
      real scenes wired in by `US3`/`US5`, placeholder scenes for this story's own tests): gesture
      regions for tap-right/tap-left, `GestureDetector.onLongPressStart`/`onLongPressEnd` for
      pause/resume, `onVerticalDragEnd` for dismiss, `WrappedProgressBar` overlay, reduce-motion-
      aware scene transitions via `flutter_animate` (spring per `context.motion.springCurve`,
      collapsing to `context.motion.crossfadeDuration` cross-fades when
      `MediaQuery.disableAnimationsOf(context)` is true) — in
      `lib/features/wrapped/presentation/pages/wrapped_page.dart` (depends on T030, T031)
- [X] T033 [US2] Register `GoRoute(path: '/wrapped/:monthKey', ...)` as a **sibling** of the
      existing `ShellRoute` (not nested inside it, per `research.md` #8) in `lib/app.dart` —
      reachable but not yet populated with real content or linked from anywhere in the UI (depends
      on T032)
- [X] T034 [US2] Verify per `quickstart.md` step 7 (mechanics) and step 8 (reduce motion), against
      placeholder scenes (depends on T029, T033)

**Checkpoint**: US2 is independently functional and testable — the story format works correctly.
Not yet showing real figures (`US3`), not yet reachable except by direct URL/route (`US1`/`US4`).

---

## Phase 4: User Story 3 - Las cifras que muestra son correctas y confiables (Priority: P1)

**Goal**: The four real scene widgets (Grand Total, Black Hole, Habit, Biggest Hit) plus a
syncing-state widget, each rendering `WrappedSummary` correctly — including live category-name
resolution and total exclusion of deleted expenses — wired into `US2`'s sequencer as the real scene
list.

**Independent Test**: Pump each scene widget directly with a known `WrappedSummary` (and resolved
`Category`) and confirm it renders the exact expected figure; separately, exercise
`WrappedRepositoryImpl.getSummary()` against `fake_cloud_firestore` with a hand-built data set
(including a deleted expense and a tie) and confirm every field matches the hand computation.

### Tests for User Story 3

- [X] T035 [P] [US3] Repository test in
      `test/features/wrapped/data/repositories/wrapped_repository_impl_test.dart`
      (`fake_cloud_firestore` + `firebase_auth_mocks`, mirrors `004`'s repository test style):
      total/top-category/top-category-count/biggest-expense match a hand-computed known data set;
      a deleted expense in the same month affects none of the four figures; two categories tied on
      summed amount resolve deterministically to the lower `sortOrder`; `isSyncing` is `true` when
      the local list is shorter than the (mocked) server count and `false` when they match
- [X] T036 [P] [US3] Widget test in
      `test/features/wrapped/presentation/widgets/wrapped_scene_grand_total_test.dart`: renders
      the formatted total via `intl`, with a count-up animation that (per reduce-motion) either
      animates or shows the final value immediately
- [X] T037 [P] [US3] Widget test in
      `test/features/wrapped/presentation/widgets/wrapped_scene_black_hole_test.dart`: renders the
      resolved category name (via the existing `nameKey`/`name` resolution `ExpenseHistoryPage`
      already establishes the pattern for) — including after a simulated rename, proving
      resolution happens at display time, not from stored data (FR-011)
- [X] T038 [P] [US3] Widget test in
      `test/features/wrapped/presentation/widgets/wrapped_scene_habit_test.dart`: renders the top
      category's transaction count (not the month's total count)
- [X] T039 [P] [US3] Widget test in
      `test/features/wrapped/presentation/widgets/wrapped_scene_biggest_hit_test.dart`: renders
      the single largest expense's formatted amount
- [X] T040 [P] [US3] Widget test in
      `test/features/wrapped/presentation/widgets/wrapped_syncing_state_test.dart`: renders the
      `wrappedSyncingMessage` and none of the four figures when `WrappedSummary.isSyncing` is `true`

### Implementation for User Story 3

- [X] T041 [P] [US3] Create `WrappedSceneGrandTotal` in
      `lib/features/wrapped/presentation/widgets/wrapped_scene_grand_total.dart` (depends on T036)
- [X] T042 [P] [US3] Create `WrappedSceneBlackHole` (resolves `topCategoryId` against the same
      `Map<String, Category>` pattern `ExpenseHistoryPage` builds from `activeCategoriesProvider`)
      in `lib/features/wrapped/presentation/widgets/wrapped_scene_black_hole.dart` (depends on
      T037)
- [X] T043 [P] [US3] Create `WrappedSceneHabit` in
      `lib/features/wrapped/presentation/widgets/wrapped_scene_habit.dart` (depends on T038)
- [X] T044 [P] [US3] Create `WrappedSceneBiggestHit` in
      `lib/features/wrapped/presentation/widgets/wrapped_scene_biggest_hit.dart` (depends on T039)
- [X] T045 [P] [US3] Create `WrappedSyncingState` in
      `lib/features/wrapped/presentation/widgets/wrapped_syncing_state.dart` (depends on T040)
- [X] T046 [US3] Create a `wrappedSummaryProvider` (`FutureProvider.family<WrappedSummary,
      String>`) wrapping `WrappedRepository.getSummary(monthKey)` in
      `lib/features/wrapped/presentation/wrapped_summary_provider.dart` (depends on T025)
- [X] T047 [US3] Wire the four real scenes (or `WrappedSyncingState` when `isSyncing`) into
      `WrappedPage`'s scene list at the `/wrapped/:monthKey` route in `lib/app.dart`, replacing
      `US2`'s placeholder scenes, driven by `wrappedSummaryProvider(monthKey)` (depends on T041–
      T046, T033)
- [X] T048 [US3] Verify per `quickstart.md` step 9 (content correctness) and step 10 (partial-sync
      state) (depends on T035, T047)

**Checkpoint**: US3 is independently functional and testable — every figure is correct and
category names resolve live. `/wrapped/:monthKey` now shows a complete, correct, navigable
sequence (missing only the shareable final scene, `US5`) when reached directly by route.

---

## Phase 5: User Story 1 - El resumen aparece solo, en el momento correcto (Priority: P1) 🎯 MVP-completing

**Goal**: The actual auto-trigger — evaluating the previous month against `wrappedLastSeenMonth`
on app open, auto-navigating to the now-real `/wrapped/:monthKey` when warranted, offering a
discreet suppressed-card alternative under 5 expenses, and marking the month seen only on dismissal.

**Independent Test**: With a seeded "previous month" of 5+ expenses and no `wrappedLastSeenMonth`,
launch the app and confirm Wrapped opens automatically; dismiss and relaunch, confirm it does not
reopen. Separately, with 1–4 expenses, confirm no auto-open but a dismissible card appears in
History.

### Tests for User Story 1

- [X] T049 [P] [US1] Unit test in
      `test/features/wrapped/domain/usecases/wrapped_trigger_decision_test.dart`: given a
      `UserProfile`/`WrappedSummary` pair, returns `autoShow` when `previousMonthKey !=
      wrappedLastSeenMonth` and `expenseCount >= 5`; `offerSuppressedCard` when `0 < expenseCount <
      5`; `none` when `expenseCount == 0` or `previousMonthKey == wrappedLastSeenMonth` or
      `isSyncing` — per the algorithm in `data-model.md` §4
- [X] T050 [P] [US1] Widget test in
      `test/features/expenses/presentation/widgets/wrapped_suppressed_card_test.dart`: renders
      `wrappedSuppressedCardTitle`/`wrappedSuppressedCardCta`, dismissible without navigating, and
      navigates to `/wrapped/:monthKey` when tapped
- [X] T051 [US1] Integration-style test in
      `test/features/wrapped/presentation/wrapped_auto_trigger_provider_test.dart`
      (mocktail-mocked `UserProfileRepository`/`WrappedRepository`): resolves to the previous
      month's key when the trigger decision is `autoShow`; resolves to `null` otherwise; never
      re-evaluates after its first resolution within the same provider container lifetime

### Implementation for User Story 1

- [X] T052 [P] [US1] Create the pure `WrappedTriggerDecision` use case/function (previous-month-key
      computation from `UserProfile.timeZone`, comparison against `wrappedLastSeenMonth`, the
      `autoShow`/`offerSuppressedCard`/`none` tri-state per `data-model.md` §4) in
      `lib/features/wrapped/domain/usecases/wrapped_trigger_decision.dart` (depends on T049)
- [X] T053 [US1] Create `wrappedAutoTriggerProvider` (`FutureProvider`, runs once per app session)
      in `lib/features/wrapped/presentation/wrapped_auto_trigger_provider.dart`: awaits
      `userProfileRepositoryProvider.watchProfile().first`, evaluates `WrappedTriggerDecision`
      against `wrappedSummaryProvider(previousMonthKey)`, resolves to the month key to auto-show or
      `null` (depends on T046, T052)
- [X] T054 [US1] Create `WrappedAutoTriggerGate` (thin `ConsumerWidget` wrapping the `ShellRoute`'s
      `child` in `lib/app.dart`): listens for `wrappedAutoTriggerProvider` to resolve, and on a
      non-null result calls `context.go('/wrapped/$monthKey')` via a post-frame callback — never
      blocking or delaying first paint (Constitution Principle 1, `research.md` #7) — in
      `lib/features/wrapped/presentation/wrapped_auto_trigger_gate.dart` (depends on T053)
- [X] T055 [US1] Wire `WrappedAutoTriggerGate` into `lib/app.dart`'s `ShellRoute` builder (depends
      on T054, T033)
- [X] T056 [US1] Create `WrappedSuppressedCard` (dismissible, non-blocking; dismissing calls
      `UserProfileRepository.markWrappedSeen(monthKey)` without navigating; tapping navigates to
      `/wrapped/:monthKey`) in
      `lib/features/expenses/presentation/widgets/wrapped_suppressed_card.dart` (depends on T050)
      — placed under `features/expenses/presentation/` rather than `features/wrapped/` since it
      renders inside `ExpenseHistoryPage`, matching Constitution Principle 4's "features depend
      only on another feature's `domain/`" boundary (this widget only reads
      `wrappedAutoTriggerProvider`-adjacent trigger-decision state, not `wrapped`'s internals)
- [X] T057 [US1] Wire `WrappedSuppressedCard` into `ExpenseHistoryPage`, shown when the trigger
      decision for the current previous month is `offerSuppressedCard` and not yet dismissed —
      `lib/features/expenses/presentation/pages/expense_history_page.dart` (depends on T056, T051)
- [X] T058 [US1] Wire `WrappedController.dismiss()`/end-of-sequence in `WrappedPage` to call
      `UserProfileRepository.markWrappedSeen(monthKey)` fire-and-forget, per `data-model.md` §4's
      "only on actual dismissal" rule — implemented in
      `lib/features/wrapped/presentation/pages/wrapped_route_page.dart` instead of
      `wrapped_controller.dart`: `WrappedController` stays Flutter/Firestore-free per its own
      contract (`research.md` #7, US2's independence from US1), so the route page's
      `_handleDismissed` wraps `WrappedPage.onDismissed` to call `markWrappedSeen` before
      forwarding to the caller-supplied navigation callback (depends on T030, T018, T047)
- [X] T059 [US1] Verify per `quickstart.md` steps 3, 4, 5 (depends on T055, T057, T058) — covered
      by automated tests exercising the exact production code paths: T035's repository tests
      (correct summary/expenseCount computation `WrappedTriggerDecision` reads),
      `wrapped_trigger_decision_test.dart` (8 tests, every branch of the auto-show/suppress/none
      decision), `wrapped_auto_trigger_provider_test.dart` (4 tests, the real provider wired to
      mocked repositories), and `wrapped_suppressed_card_test.dart` (3 tests, real `go_router`
      navigation + `markWrappedSeen` call verification). **Not performed in this pass**: a live,
      on-device end-to-end run (fresh install, seed a real "last month," relaunch, observe the
      auto-trigger fire once across a simulated second session) — noted as a real gap, not
      silently skipped, same standard `005`'s T042/T046 applied to their own live-project caveats

**Checkpoint**: US1 is independently functional and testable — the feature now delivers its core
promise end-to-end: open the app in a new month, see Wrapped, never see it twice. **This is the
MVP-completing story**, not `US1`'s position in this file's phase order.

---

## Phase 6: User Story 4 - Cualquier mes pasado, cuando quiera verlo (Priority: P2)

**Goal**: A month-picker affordance on the History screen lists every month with data and opens
its summary on demand, regardless of whether it was already auto-shown.

**Independent Test**: Open History, tap the month-picker affordance, select a past month, confirm
its full summary opens identically to the auto-triggered path.

### Tests for User Story 4

- [X] T060 [P] [US4] Unit test in
      `test/features/expenses/presentation/widgets/history_month_picker_sheet_test.dart`:
      given a list of expenses spanning several months, derives the distinct `monthKey`s (from
      each `Expense.date`) most-recent-first with no duplicates, and tapping one calls
      `context.go('/wrapped/:monthKey')` with the right key

### Implementation for User Story 4

- [X] T061 [US4] Create `HistoryMonthPickerSheet` (bottom sheet, `wrappedMonthPickerTitle`, one
      row per distinct month derived client-side from `ExpenseHistoryController`'s already-loaded
      expenses — no new Firestore query, per `research.md` #3) in
      `lib/features/expenses/presentation/widgets/history_month_picker_sheet.dart` (depends on
      T060)
- [X] T062 [US4] Add a `wrappedMonthPickerEntryLabel` pill button to `ExpenseHistoryPage` opening
      `HistoryMonthPickerSheet` — `lib/features/expenses/presentation/pages/expense_history_page.dart`
      (depends on T061)
- [X] T063 [US4] Verify per `quickstart.md` step 6 (depends on T062) — covered by
      `history_month_picker_sheet_test.dart` (4 tests: distinct/ordered/deduped month derivation,
      row rendering, real `go_router` navigation on tap). No live-device run in this pass (same
      caveat as T059).

**Checkpoint**: US4 is independently functional and testable.

---

## Phase 7: User Story 5 - Compartir sin exponer cifras por accidente (Priority: P2)

**Goal**: The final scene — a `RepaintBoundary`-rasterized, `share_plus`-shared card that defaults
to no monetary figures, with a visible opt-in toggle.

**Independent Test**: Reach the final scene, share without touching the toggle, and confirm the
generated image has no monetary figure; activate the toggle, share again, confirm it now does.

### Tests for User Story 5

- [X] T064 [P] [US5] Widget test in
      `test/features/wrapped/presentation/widgets/wrapped_share_card_test.dart`: by default renders
      top category, transaction count, and month — no `Money`-formatted text anywhere in the tree;
      with the amounts toggle active, renders the total too; sized for a 9:16 aspect ratio
- [X] T065 [US5] Unit test in
      `test/features/wrapped/presentation/widgets/wrapped_share_card_rasterizer_test.dart`
      (or a golden test via `alchemist`, matching the design system's existing golden convention):
      confirms the `RepaintBoundary` capture path renders at 3× pixel ratio

### Implementation for User Story 5

- [X] T066 [P] [US5] Create `WrappedShareCard` (the card content widget, thick borders/rounded
      corners per `docs/UI_UX_SPEC.md` §3, an amounts-visible toggle reading local widget state) in
      `lib/features/wrapped/presentation/widgets/wrapped_share_card.dart` (depends on T064)
- [X] T067 [US5] Create the rasterize-and-share flow: wrap `WrappedShareCard` in a
      `RepaintBoundary` with a `GlobalKey`, capture at `pixelRatio: 3` on the share button's tap,
      and invoke `share_plus`'s `Share.shareXFiles` with the resulting PNG bytes —
      `lib/features/wrapped/presentation/widgets/wrapped_share_card.dart` (same file, depends on
      T065, T066)
- [X] T068 [US5] Wire `WrappedShareCard` as `WrappedPage`'s final scene at `/wrapped/:monthKey` —
      `lib/app.dart` (depends on T047, T067)
- [X] T069 [US5] Add the completion-ratio-only analytics event (Constitution Principle 5 / FR-017):
      extend `AnalyticsService` with a single method carrying only a completion-ratio value (no
      amount, note, or category name — matching `logExpenseTimeToLog`'s existing single-purpose
      precedent), called when a Wrapped session ends (dismissed or completed) with the fraction of
      scenes actually seen — `lib/core/analytics/analytics_service.dart` +
      `WrappedController` call site (depends on T030)
- [X] T070 [US5] Verify per `quickstart.md` steps 11 and 13 (depends on T068, T069) — step 11
      covered by `wrapped_share_card_test.dart` (default hides amounts, toggle reveals them, 9:16
      aspect) and `wrapped_share_card_rasterizer_test.dart` (real `RepaintBoundary.toImage()` at
      3× produces genuine PNG bytes, verified via file signature). Step 13 covered structurally:
      `logWrappedCompletion(double)` is the only new analytics call site this feature adds, and it
      carries a `completion_ratio` value alone — no amount/note/category-name parameter exists on
      the method signature for a caller to even accidentally pass. No live Firebase DebugView
      inspection in this pass (same caveat as T059/T063).

**Checkpoint**: All five user stories complete — the full "Resumen Mensual Animado y Compartible"
experience works end to end.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T071 [P] Confirm `test/core/design_system/tokens/no_raw_hex_colors_test.dart` and
      `test/l10n/arb_keys_complete_test.dart` still pass unmodified after this feature's token/ARB
      additions — both pass (3 + 2 tests)
- [X] T072 [P] Confirm no widget under `lib/features/wrapped/` or the new History widgets
      constructs a bare `Curve`/`Duration` for motion instead of `context.motion.*` (grep sweep, per
      `research.md` #5 / Constitution Principle 9) — clean, zero matches
- [X] T073 Run `flutter analyze` and confirm zero issues across every file this feature added or
      modified — 0 issues, full project
- [X] T074 Run `dart format --output=none --set-exit-if-changed lib test` and confirm clean —
      clean (0 changed), after fixing one file's formatting mid-implementation
- [X] T075 Run the full `firebase/tests/` Security Rules suite against the emulator and confirm
      all pass, including the pre-existing `/categories`/`/expenses`/`/users` tests unmodified
      besides T020's additions — 33/33 passing
- [X] T076 Execute `quickstart.md` end to end (all 15 steps) as the final acceptance pass (depends
      on T034, T048, T059, T063, T070) — steps 3-13 confirmed via this feature's own automated
      suite (repository/controller/provider/widget tests exercising the real production code
      paths against `fake_cloud_firestore`, real `go_router`, and mocked collaborators where
      Firestore can't represent the scenario, e.g. partial-sync); step 1 (capture untouched) and
      step 7/8 (mechanics/reduce-motion) additionally confirmed live by running `004`'s and `005`'s
      existing integration tests on a real iOS Simulator with the new `WrappedAutoTriggerGate`
      wired into the app shell — both pass, confirming the sacred logging path and app boot are
      unaffected. **Not performed in this pass**: a live, on-device run of the actual Wrapped
      trigger/content/sharing flow against a real `dev`-flavor Firebase project (step 2's
      `users/{uid}` creation, the full auto-trigger-to-dismissal cycle, and a real share-sheet
      invocation) — noted as a real gap, not silently skipped, same standard as T059/T063/T070
- [X] T077 Run `flutter test` (full suite), confirming this feature's tests and every prior
      feature's (`003`–`005`) untouched tests pass together (depends on T073) — **174/174** passing

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories. Its four sub-groups
  (localization/tokens, `user_profile`, Security Rules, `wrapped` data layer) are themselves
  largely parallel with each other; only the final `build_runner` task (T026) needs the DI-relevant
  pieces of all of them done first
- **User Stories (Phase 3–7)**: All depend on Foundational completion; within that constraint:
  - US2 (mechanics) has no dependency on US1/US3/US4/US5 — buildable and testable against
    placeholder scenes alone
  - US3 (correctness) depends on US2 (its scenes are wired into `US2`'s already-built `WrappedPage`/
    route) but not on US1/US4/US5
  - US1 (trigger) depends on US2 (route/page must exist to navigate into) and benefits from, but
    does not hard-depend on, US3 being complete
  - US4 (manual access) depends on US2 (route must exist) and the existing History screen (`005`)
  - US5 (share card) depends on US2 (final scene slot in the sequencer) and reuses US3's
    category/count resolution patterns, but is not blocked by US1/US4
- **Polish (Phase 8)**: Depends on all five user stories being complete

### Within Each User Story

- US2: controller/progress-bar tests → controller → progress bar → page (gestures, reduce-motion) →
  route registration → verification
- US3: repository correctness test + five scene/syncing widget tests → repository impl → five
  widgets → summary provider → wire into the route → verification
- US1: trigger-decision test + suppressed-card test + auto-trigger-provider test → trigger decision
  use case → auto-trigger provider → auto-trigger gate → wire into app shell → suppressed card
  widget → wire into History → mark-seen wiring → verification
- US4: month-picker test → month-picker sheet → entry button in History → verification
- US5: share-card content test + rasterizer test → share card widget → rasterize/share flow → wire
  as final scene → analytics event → verification

### Parallel Opportunities

- Foundational: T002–T006 (five ARB files), T008–T010 (motion tokens), T011–T018 (`user_profile`),
  T019–T020 (Security Rules), and T021–T025 (`wrapped` data layer) are four largely independent
  tracks — T026 (`build_runner`) is the sync point
- Once Foundational completes: US2 and (once US2's route/page shell lands) US3 can be staffed in
  close succession; US1/US4/US5 each wait on US2 as noted above but not on each other
- Within US3: T035–T040 (six tests) in parallel; T041–T045 (five widgets) in parallel
- Within US1: T049–T051 (three tests) in parallel
- Within US5: T064/T065 (two tests) in parallel

---

## Parallel Example: Foundational Phase

```bash
# Launch the five ARB updates together:
Task: "Add the 12 new keys to lib/l10n/app_en.arb"
Task: "Add the Spanish translations to lib/l10n/app_es.arb"
Task: "Add the Portuguese translations to lib/l10n/app_pt.arb"
Task: "Add the Italian translations to lib/l10n/app_it.arb"
Task: "Add the French translations to lib/l10n/app_fr.arb"

# In parallel with the above, the user_profile / Security Rules / wrapped-data tracks:
Task: "Create AppMotionExtension in app_motion.dart"
Task: "Create UserProfile entity and UserProfileRepository contract"
Task: "Add isValidUserProfile() to firestore.rules"
Task: "Create WrappedSummary entity and WrappedRepository contract"
```

## Parallel Example: User Story 3

```bash
# Launch all six tests together:
Task: "wrapped_repository_impl_test.dart"
Task: "wrapped_scene_grand_total_test.dart"
Task: "wrapped_scene_black_hole_test.dart"
Task: "wrapped_scene_habit_test.dart"
Task: "wrapped_scene_biggest_hit_test.dart"
Task: "wrapped_syncing_state_test.dart"

# Launch all five widgets together:
Task: "Create WrappedSceneGrandTotal"
Task: "Create WrappedSceneBlackHole"
Task: "Create WrappedSceneHabit"
Task: "Create WrappedSceneBiggestHit"
Task: "Create WrappedSyncingState"
```

---

## Implementation Strategy

### MVP First (User Stories 2, 3, and 1 — the P1 tier)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks everything, and is where the
   `users/{userId}` gap actually gets closed)
3. Complete Phase 3 (US2) and Phase 4 (US3) — together, a complete, correct, navigable-by-URL
   Wrapped sequence
4. Complete Phase 5 (US1) — the auto-trigger, which is what actually delivers the feature's
   promised value
5. **STOP and VALIDATE**: run `quickstart.md` steps 1–5, 7–10
6. US4/US5 add manual access and sharing

### Incremental Delivery

1. Setup + Foundational → `users/{userId}` exists and is rules-validated; summary computation
   ready
2. US2 → the story format works, provably, against placeholder content
3. US3 → the real figures are correct → **P1 content complete**
4. US1 → the trigger actually fires end-to-end → **MVP complete**
5. US4 → manual access → verify independently
6. US5 → sharing → verify independently
7. Polish → full quickstart pass

### Parallel Team Strategy

With multiple developers, after Foundational completes:

- Developer A: US2, then US1 once US3 lands
- Developer B: US3 (needs only US2's route/page shell to exist to wire into, so starts shortly
  after Developer A's T032–T033 land)
- Developer C: US4 (needs only US2's route) and US5 (needs only US2's scene-slot mechanism) in
  parallel with A/B

---

## Notes

- [P] tasks touch different files and have no dependency on an incomplete task
- [Story] labels map every user-story-phase task back to spec.md for traceability, even where this
  file's phase order differs from spec.md's story numbering (explained in Organization above)
- No task in Setup, Foundational, or Polish carries a [Story] label, per the checklist format rules
- `WrappedRepositoryImpl` depending on `ExpenseRepository`'s domain interface (T024) is the
  established, allowed cross-feature pattern (Constitution Principle 4: "only another feature's
  `domain/` repository interfaces") — not a new exception
- Commit after each task or logical group; stop at any checkpoint to validate a story independently
  before moving on
