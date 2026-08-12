---

description: "Task list for Historial de Gastos con Borrado Reversible"
---

# Tasks: Historial de Gastos con Borrado Reversible

**Input**: Design documents from `/specs/005-expense-history-undo/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Included, per the same constitution Testing-floor standard `004` followed. This
feature's acceptance criteria (exact grouping/subtotals, exactly-one-write-per-delete, exact
30-day purge boundary) are automated-measurable, not eyeballed.

**Organization**: Tasks are grouped by user story (see spec.md). `US1` (display) and `US2`
(delete/undo) are both P1 and build a working screen that isn't reachable through production
navigation yet — deliberately: this decouples "does the screen work" from "can a person get to it,"
the same way `004` decoupled the capture flow's own correctness from its later hardening stories.
`US3` (P2) is what actually wires the screen into the app and proves it doesn't regress `004`'s
sacred path. `US4`/`US5` (P3) are independent polish/hygiene layered on top.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Which user story this task belongs to (US1–US5)
- Every task states its exact file path or command

## Path Conventions

Single Flutter mobile project at the repository root (`lib/`, `test/`, `integration_test/`), per
`plan.md`'s Project Structure. This feature is the first to populate `expenses/presentation/`
beyond the capture screen (`004`) and the first to add `lib/core/navigation/`.

---

## Phase 1: Setup

**Purpose**: Confirm this feature needs no new dependencies before touching code

- [X] T001 Confirm no new dependency is needed (`flutter_riverpod`, `go_router`, `cloud_firestore`,
      `intl` are all already present per `plan.md`); run `flutter pub get` and confirm clean

**Checkpoint**: Dependencies ready; proceed to Foundational.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Localization keys and the repository-layer changes every user story needs — the
corrected `delete()`, and the two additive members (`watchAll()`, `purgeDeletedOlderThan()`)

**⚠️ CRITICAL**: No user story work can begin until this phase is complete — `US1` needs
`watchAll()`, `US2` needs the corrected `delete()`, `US5` needs `purgeDeletedOlderThan()`, and all
of them need the new ARB keys to render any text at all

- [X] T002 [P] Add `commonUndo`, `historyExpenseDeletedMessage`, `historyEmptyTitle`,
      `historyEmptySubtitle`, `navCaptureLabel`, `navHistoryLabel` to `lib/l10n/app_en.arb`
      (template), each with an `@`-metadata description, per `data-model.md`
- [X] T003 [P] Add the Spanish translations for those 6 keys to `lib/l10n/app_es.arb`
- [X] T004 [P] Add the Portuguese translations to `lib/l10n/app_pt.arb`
- [X] T005 [P] Add the Italian translations to `lib/l10n/app_it.arb`
- [X] T006 [P] Add the French translations to `lib/l10n/app_fr.arb`
- [X] T007 Run `flutter gen-l10n` to regenerate `lib/l10n/generated/app_localizations*.dart`
      (depends on T002–T006)
- [X] T008 Update `lib/features/expenses/domain/repositories/expense_repository.dart`: correct
      `delete()`'s doc comment to describe soft-delete behavior (no signature change — see
      research.md's "corrected, not renamed" decision); add
      `Stream<List<Expense>> watchAll()` and
      `Future<Result<void>> purgeDeletedOlderThan(DateTime cutoff)`, both additive per `003`'s
      contract stability notes
- [X] T009 Update `lib/features/expenses/data/datasources/expense_remote_data_source.dart`:
      change `delete()` to `.update({'deletedAt': Timestamp.now()})` instead of hard-deleting; add
      `watchAll(String userId)` (`.where('deletedAt', isNull: true).orderBy('date', descending:
      true).snapshots()`, mirrors the existing `(deletedAt, date)` index); add
      `purgeOlderThan(String userId, DateTime cutoff)` (`.where('deletedAt', isLessThan:
      Timestamp.fromDate(cutoff)).get()`, then a batched `.delete()` per match) (depends on T008)
- [X] T010 Update `lib/features/expenses/data/repositories/expense_repository_impl.dart`: wire
      the corrected `delete()` (unchanged call site, new underlying behavior) and the two new
      methods, each still resolving the current uid from the injected `FirebaseAuth` and mapping
      exceptions to `Failed(UnknownFailure(...))`, per `004`'s established pattern (depends on T009)

**Checkpoint**: Repository layer ready — every user story can now build on `watchAll()`, the
corrected `delete()`, and `purgeDeletedOlderThan()`.

---

## Phase 3: User Story 1 - Revisar el historial de gastos, agrupado y con contexto (Priority: P1) 🎯 MVP

**Goal**: A working history screen — day-grouped, subtotaled, each entry showing amount/category/
time with the category identifiable without color — built and verified on its own, before it's
wired into app navigation (`US3`).

**Independent Test**: Pump `ExpenseHistoryPage` (directly, in a widget test — production navigation
is `US3`'s deliverable) against a set of expenses spanning multiple days and confirm the grouping,
order, subtotals, and per-entry content are all correct.

### Tests for User Story 1

- [X] T011 [P] [US1] Unit test in `test/features/expenses/presentation/day_group_test.dart`:
      `groupByDay` groups expenses by calendar day, orders days descending and expenses within a
      day descending, and each `DayGroup.subtotalMinor` equals the exact sum of that day's
      `amountMinor`
- [X] T012 [P] [US1] Widget test in
      `test/features/expenses/presentation/widgets/history_entry_tile_test.dart`: renders amount,
      category (icon + resolved name, reusing `004`'s `resolveCategoryIcon`/`resolveCategoryName`),
      and time; category remains identifiable with color removed/grayscaled
- [X] T013 [P] [US1] Repository test extending
      `test/features/expenses/data/repositories/expense_repository_impl_test.dart` (sequential,
      same file as `004`'s T018/T041/T051 — not parallel with them): `watchAll()` returns only
      non-deleted expenses, ordered by `date` descending, against `FakeFirebaseFirestore`

### Implementation for User Story 1

- [X] T014 [P] [US1] Create `DayGroup` and `groupByDay(List<Expense>) -> List<DayGroup>` (plain
      Dart, no Flutter dependency) in `lib/features/expenses/presentation/day_group.dart`
- [X] T015 [P] [US1] Create `HistoryDayHeader` widget (locale-formatted date via `intl`, day
      subtotal formatted via the same money-formatting approach the capture screen uses) in
      `lib/features/expenses/presentation/widgets/history_day_header.dart`
- [X] T016 [US1] Create `HistoryEntryTile` widget (amount, category icon/name via `004`'s
      resolvers, formatted time via `intl`) in
      `lib/features/expenses/presentation/widgets/history_entry_tile.dart` (depends on T012)
- [X] T017 [US1] Create `ExpenseHistoryController` (Riverpod) exposing `dayGroups` derived from
      `expenseRepositoryProvider.watchAll()` via `groupByDay` — read-only in this story, no
      pending-deletion state yet — in
      `lib/features/expenses/presentation/controllers/expense_history_controller.dart` (depends on
      T014)
- [X] T018 [US1] Create `ExpenseHistoryPage` assembling `HistoryDayHeader` + `HistoryEntryTile`
      into a scrollable, grouped list driven by `ExpenseHistoryController` in
      `lib/features/expenses/presentation/pages/expense_history_page.dart` (depends on T015, T016,
      T017)
- [X] T019 [US1] Verify per `quickstart.md` step 2: pump `ExpenseHistoryPage` with expenses across
      several days and confirm grouping/order/subtotals render correctly (depends on T018)

**Checkpoint**: US1 is independently functional and testable — the history screen displays
correctly. Not yet reachable through the app's real navigation (`US3`), not yet deletable (`US2`).

---

## Phase 4: User Story 2 - Deshacer un error de captura sin fricción (Priority: P1)

**Goal**: Swipe-to-delete with no confirmation, instant exclusion from the view and subtotals, and
a working undo window that never costs more than one Firestore write.

**Independent Test**: Swipe an entry, confirm it and its amount leave the view/subtotal instantly;
tap "Deshacer" within the window and confirm it's restored exactly, with zero Firestore writes
having occurred; separately, let the window expire and confirm exactly one write (`deletedAt` set)
happened.

### Tests for User Story 2

- [X] T020 [P] [US2] Unit test in
      `test/features/expenses/presentation/controllers/expense_history_controller_test.dart`
      (mocktail-mocked `ExpenseRepository`, an injectable short `undoWindow` for fast tests):
      `requestDelete` excludes the id from `dayGroups` synchronously with zero repository calls;
      `undoDelete` called before the window elapses restores it, still zero repository calls;
      letting the window elapse calls `ExpenseRepository.delete()` exactly once
- [X] T021 [P] [US2] Extend
      `test/features/expenses/data/repositories/expense_repository_impl_test.dart` (sequential,
      same file as T013): `delete()` sets `deletedAt` on the document rather than removing it —
      the document still exists afterward
- [X] T022 [US2] Widget test extending
      `test/features/expenses/presentation/pages/expense_history_page_test.dart`: swiping a tile
      removes it immediately with no dialog, shows a snackbar with a "Deshacer" action, and tapping
      it restores the tile to its original position (depends on T018)

### Implementation for User Story 2

- [X] T023 [US2] Extend `ExpenseHistoryController`: `Set<String> pendingDeletionIds`, a per-id
      `Timer` (default 5s per `docs/UI_UX_SPEC.md` §4, injectable for tests),
      `requestDelete(String id)` / `undoDelete(String id)`, and an `AppLifecycleListener` that
      flushes (immediately calls `delete()` for) every still-pending id on
      `AppLifecycleState.paused` — `lib/features/expenses/presentation/controllers/expense_history_controller.dart`
      (depends on T020)
- [X] T024 [US2] Wrap `HistoryEntryTile` in a `Dismissible` (swipe gesture) calling
      `controller.requestDelete(id)` on dismiss —
      `lib/features/expenses/presentation/widgets/history_entry_tile.dart` (depends on T016, T023)
- [X] T025 [US2] Show a `SnackBar` (`historyExpenseDeletedMessage` + `commonUndo` action calling
      `controller.undoDelete(id)`) from `ExpenseHistoryPage` whenever a delete is requested —
      `lib/features/expenses/presentation/pages/expense_history_page.dart` (depends on T018, T023)
- [X] T026 [US2] Verify per `quickstart.md` steps 4–8: instant exclusion, exact-one-write-at-expiry,
      undo restores with zero writes, backgrounding confirms pending deletions, offline parity
      (depends on T024, T025) — steps 4/5/6 confirmed by `expense_history_controller_test.dart`
      (4 tests) and `expense_history_page_test.dart`'s swipe/undo test; step 7 (backgrounding)
      confirmed by the dedicated `handleAppLifecycleStateChanged` test; step 8 (offline parity) is
      true by construction — `fake_cloud_firestore`/undo's local-only path never open a socket at
      all, the same reasoning `004` used for its own "modo sin red" proof

**Checkpoint**: US2 is independently functional and testable — delete/undo work correctly. Still
not reachable through production navigation.

---

## Phase 5: User Story 3 - Moverse entre captura e historial sin tocar la ruta sagrada (Priority: P2)

**Goal**: A real, floating nav bar (per `docs/UI_UX_SPEC.md` §4) wires History into the app for the
first time, with capture proven — not just assumed — to remain the fixed launch destination and
the `004` logging path proven unaffected.

**Independent Test**: From the capture screen, navigate to History and back using the nav bar;
close and reopen the app from History and confirm capture is the first screen; run the dedicated
regression test proving `004`'s two-tap flow is unchanged with the full shell present.

### Tests for User Story 3

- [X] T027 [P] [US3] Widget test in `test/core/navigation/app_shell_test.dart`: renders both nav
      destinations with `navCaptureLabel`/`navHistoryLabel` semantic labels; tapping each navigates
      to the corresponding route — 3 tests, all pass
- [X] T028 [US3] Create `integration_test/expense_capture_with_history_shell_test.dart`: pumps the
      real `App` widget (full `go_router` config, both routes, `AppShell` rendered) with `004`'s
      fakes, and confirms the exact two-tap flow (amount → "Continuar" → category) still completes
      and persists correctly — the test the plan input explicitly requested (depends on T029, T030)
      — **caught a real bug on its first run**: `ExpenseCapturePage`'s bottom-sheet dismissal used
      `Navigator.of(context, rootNavigator: true)`, which under the new `ShellRoute`'s nested
      Navigator popped `go_router`'s root stack instead of the sheet, crashing on every successful
      submit. Fixed (see research.md) and reverified — both this test and `004`'s own integration
      test pass

### Implementation for User Story 3

- [X] T029 [US3] Create `AppShell` (the floating nav bar overlaid via `Stack`/`Align`, not
      `Scaffold.bottomNavigationBar` — see research.md; two destinations, capture and history) in
      `lib/core/navigation/app_shell.dart` (depends on T027)
- [X] T030 [US3] Update `lib/app.dart`: wrap `/` (`ExpenseCapturePage`, unchanged) and a new
      `/history` (`ExpenseHistoryPage`) `GoRoute` in a `ShellRoute` using `AppShell`;
      `initialLocation` stays `/` with no route-restoration logic added (depends on T029, T018)
- [X] T031 [US3] Reserve bottom safe-area space in `ExpenseCapturePage` so its "Continuar" button
      and the new floating nav pill never overlap —
      `lib/features/expenses/presentation/pages/expense_capture_page.dart` (depends on T030) —
      verified on-device (iOS Simulator screenshot); the first spacing guess visually clipped, a
      second, larger token composition confirmed clear
- [X] T032 [US3] Run T028's regression test and verify per `quickstart.md` step 1: capture remains
      the launch destination regardless of prior navigation state (depends on T028, T031) — both
      integration tests pass on the iOS Simulator; capture-as-launch-destination confirmed both
      structurally (`initialLocation`, no restoration code) and live (on-device screenshot)

**Checkpoint**: US3 is independently functional and testable — History is reachable for real, and
`004`'s sacred path is proven, not assumed, unaffected.

---

## Phase 6: User Story 4 - Un historial vacío que no se siente vacío (Priority: P3)

**Goal**: An account with no expenses sees a warm, illustrated-with-existing-tokens empty state.

**Independent Test**: Open History with zero expenses and confirm the empty state renders instead
of the day-grouped list or any plain "no data" text.

### Tests for User Story 4

- [X] T033 [P] [US4] Widget test in
      `test/features/expenses/presentation/widgets/history_empty_state_test.dart`: renders
      `historyEmptyTitle`/`historyEmptySubtitle` and an icon, built only from existing
      `context.colors`/`.spacing`/`.typography` tokens — 2 tests, all pass

### Implementation for User Story 4

- [X] T034 [US4] Create `HistoryEmptyState` (a large existing-Material-icon inside a soft circular
      fill, plus warm localized copy — no new illustration package or asset, per the plan input) in
      `lib/features/expenses/presentation/widgets/history_empty_state.dart` (depends on T033) —
      built during US1 so `ExpenseHistoryPage` had a complete empty-path from its first version,
      rather than built twice (same reasoning `004` applied to `category_icon_map.dart`)
- [X] T035 [US4] Wire `HistoryEmptyState` into `ExpenseHistoryPage` when `dayGroups` is empty —
      `lib/features/expenses/presentation/pages/expense_history_page.dart` (depends on T034, T018)
      — done in T018, same reasoning as T034
- [X] T036 [US4] Verify per `quickstart.md` step 9 (depends on T035) — confirmed by T033's test and
      by `expense_history_page_test.dart`'s "shows the empty state when there are no expenses" test

**Checkpoint**: US4 is independently functional and testable.

---

## Phase 7: User Story 5 - Los gastos borrados no viven para siempre (Priority: P3)

**Goal**: Expenses soft-deleted more than 30 days ago are hard-deleted, fire-and-forget, at app
bootstrap.

**Independent Test**: Seed an expense with `deletedAt` more than 30 days in the past, relaunch the
app, and confirm the document no longer exists — while one soft-deleted less than 30 days ago still
does.

### Tests for User Story 5

- [X] T037 [P] [US5] Unit test in
      `test/features/expenses/domain/usecases/purge_expired_deleted_expenses_test.dart`
      (mocktail fakes for `AuthRepository`/`ExpenseRepository`): confirms
      `runWhenAuthenticated` is used and `purgeDeletedOlderThan` is called with a cutoff 30 days
      before now
- [X] T038 [US5] Extend `test/features/expenses/data/repositories/expense_repository_impl_test.dart`
      (sequential, same file as T013/T021): `purgeDeletedOlderThan()` removes only documents whose
      `deletedAt` is older than the given cutoff, against `FakeFirebaseFirestore`; a document
      soft-deleted more recently survives

### Implementation for User Story 5

- [X] T039 [US5] Create `PurgeExpiredDeletedExpensesUseCase` in
      `lib/features/expenses/domain/usecases/purge_expired_deleted_expenses.dart`, per
      `contracts/expense-history-api.md` (depends on T037)
- [X] T040 [US5] Register `PurgeExpiredDeletedExpensesUseCase` for DI; run
      `dart run build_runner build` (depends on T039)
- [X] T041 [US5] Update `lib/bootstrap.dart`: add a fire-and-forget
      `unawaited(getIt<PurgeExpiredDeletedExpensesUseCase>().call())` alongside the existing
      sign-in/seed calls, never blocking first frame (depends on T040)
- [X] T042 [US5] Verify per `quickstart.md` step 10 (depends on T038, T041) — the exact-boundary
      behavior is confirmed by T038 against `fake_cloud_firestore`; live-verified that wiring the
      use case into `bootstrap()` doesn't crash or block first frame (rebuilt, installed, and
      relaunched on the iOS Simulator — capture screen renders normally). Seeding a real
      40-day-old `deletedAt` document in the live `wrap-my-finances-dev` project and confirming its
      removal end to end was **not** performed in this pass — noted as a real gap in live-project
      coverage, not silently skipped, same standard applied to T056

**Checkpoint**: US5 is independently functional and testable — all five user stories complete.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T043 [P] Confirm `test/core/design_system/tokens/no_raw_hex_colors_test.dart` and
      `test/l10n/arb_keys_complete_test.dart` still pass unmodified after this feature's ARB
      additions — both pass
- [X] T044 Run `flutter analyze` and confirm zero issues across every file this feature added or
      modified — 0 issues
- [X] T045 Run `dart format --output=none --set-exit-if-changed lib test integration_test` and
      confirm clean — clean, exit 0
- [X] T046 Execute `quickstart.md` end to end (all 12 steps) as the final acceptance pass (depends
      on T019, T026, T032, T036, T042) — steps 1/9 confirmed live on-device (iOS Simulator
      screenshots, both before and after fixing the nav-overlap spacing); step 2 (T028's regression
      test, which also caught and confirmed the fix for the `Navigator.of(rootNavigator: true)`
      bug); steps 4–8 confirmed by the controller/page/repository test suites; step 3 (category
      identity without color) by `history_entry_tile_test.dart`; step 10 confirmed against
      `fake_cloud_firestore` (T038) plus a live no-crash bootstrap check, not a live-project purge
      (see T042's caveat); steps 11/12 below
- [X] T047 Run `flutter test` (full suite) and `flutter test integration_test/ -d <simulator>`,
      confirming every test — this feature's and `001`'s/`002`'s/`003`'s/`004`'s untouched ones —
      passes together (depends on T044) — **110/110** unit/widget tests, **2/2** integration tests
      on the iOS Simulator, all passing together

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories (`US1` needs
  `watchAll()`, `US2` needs the corrected `delete()`, `US5` needs `purgeDeletedOlderThan()`, all
  need the new ARB keys)
- **User Stories (Phase 3–7)**: All depend on Foundational completion; within that constraint:
  - US1 has no dependency on any other story — the read-only history screen
  - US2 depends on US1 (swipes against the tiles/controller US1 built; its tests extend US1's
    repository test file sequentially)
  - US3 depends on US1 (routes to `ExpenseHistoryPage`) — not on US2 (navigation doesn't care
    whether delete/undo exist yet, though in practice it will by the time US3 lands)
  - US4 depends on US1 (renders inside `ExpenseHistoryPage`)
  - US5 has no dependency on US1–US4 — it's a bootstrap-only background use case, independent of
    any screen
- **Polish (Phase 8)**: Depends on all five user stories being complete

### Within Each User Story

- US1: day-grouping/tile tests → `DayGroup`/`groupByDay` → leaf widgets → controller → page →
  verification
- US2: failing tests first (extending US1's controller and repository test files) → controller's
  pending-deletion mechanism → swipe gesture → snackbar → verification
- US3: nav-bar test → `AppShell` → `go_router` wiring → capture layout reservation → regression
  test + verification
- US4: empty-state test → `HistoryEmptyState` → wire into the page → verification
- US5: use case test + repository purge test → use case → DI/build_runner → bootstrap wiring →
  verification

### Parallel Opportunities

- Foundational: T002–T006 (five ARB files) in parallel
- Once Foundational completes: US1 and US5 can be staffed in parallel (US5 has no UI dependency at
  all); US2/US3/US4 each wait on specific pieces of US1 as noted above
- Within US1: T011/T012/T013 (tests) in parallel; T014/T015 in parallel
- Within US2: T020/T021 (tests) in parallel
- Within US5: T037 in parallel with US1/US2/US3/US4 work entirely

---

## Parallel Example: Foundational Phase

```bash
# Launch the five ARB updates together:
Task: "Add the 6 new keys to lib/l10n/app_en.arb"
Task: "Add the Spanish translations to lib/l10n/app_es.arb"
Task: "Add the Portuguese translations to lib/l10n/app_pt.arb"
Task: "Add the Italian translations to lib/l10n/app_it.arb"
Task: "Add the French translations to lib/l10n/app_fr.arb"
```

## Parallel Example: User Story 1

```bash
# Launch all three tests together:
Task: "day_group_test.dart"
Task: "history_entry_tile_test.dart"
Task: "watchAll() repository test"

# Launch the two independent leaf pieces together:
Task: "Create DayGroup + groupByDay()"
Task: "Create HistoryDayHeader"
```

---

## Implementation Strategy

### MVP First (User Stories 1 and 2 — both P1)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks everything)
3. Complete Phase 3 (US1) and Phase 4 (US2) — together, a fully correct history-with-undo screen,
   verifiable directly even before it's wired into navigation
4. **STOP and VALIDATE**: run `quickstart.md` steps 2–8
5. US3 makes it reachable; US4/US5 polish and harden

### Incremental Delivery

1. Setup + Foundational → repository layer ready
2. US1 → the screen displays correctly → verify independently
3. US2 → delete/undo work correctly → verify independently → **P1 scope complete**
4. US3 → reachable for real, `004` proven unaffected → verify independently
5. US4 → warm empty state → verify independently
6. US5 → 30-day purge → verify independently
7. Polish → full quickstart pass

### Parallel Team Strategy

With multiple developers, after Foundational completes:

- Developer A: US1 then US2 (US2 needs US1's tiles/controller)
- Developer B: US5 (fully independent — no UI dependency at all)
- Developer C: US3 once US1 lands (needs `ExpenseHistoryPage` to route to); US4 once US1 lands

---

## Notes

- [P] tasks touch different files and have no dependency on an incomplete task
- [Story] labels map every user-story-phase task back to spec.md for traceability
- No task in Setup, Foundational, or Polish carries a [Story] label, per the checklist format rules
- `firestore.rules` needs no task in this list — every write/query this feature performs is already
  covered by `003`'s ruleset (research.md)
- Commit after each task or logical group; stop at any checkpoint to validate a story independently
  before moving on
