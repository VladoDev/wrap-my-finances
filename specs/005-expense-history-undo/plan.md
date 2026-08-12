# Implementation Plan: Historial de Gastos con Borrado Reversible

**Branch**: `005-expense-history-undo` | **Date**: 2026-08-12 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/005-expense-history-undo/spec.md`

## Summary

The app's second screen and first real navigation: a chronological, day-grouped history of logged
expenses with swipe-to-delete and a five-second undo window, reachable from a floating nav bar that
sits alongside the capture screen `004` already built. Deletion is soft (`deletedAt`, per
`docs/DATA_MODEL.md`) with a client-triggered 30-day purge — but the write to Firestore happens only
once, at the moment the undo window actually expires (or the app backgrounds), never at swipe time
and never a second time to undo. Everything in between is a client-side, in-memory exclusion.

`docs/ROADMAP.md` was amended (documentation, not constitutional) before this spec: history and
delete moved from Phase 4 to Phase 2, because the monthly Wrapped summary Phase 2 also builds
cannot be built on data the user has no way to correct.

One correction carries forward from `004`'s own pattern of fixing unvalidated stubs rather than
leaving them: `ExpenseRepository.delete()`, a hard-delete stub `004` left with "no caller exists
yet," is corrected here — same signature, soft-delete behavior — since this product has exactly one
delete concept and this is its first real caller. `firestore.rules` needs no changes at all: every
write and query this feature performs was already covered by `003`'s ruleset.

## Technical Context

**Language/Version**: Dart / Flutter, latest stable channel (unpinned per `docs/TECH_STACK.md`)

**Primary Dependencies**: `flutter_riverpod`, `go_router`, `cloud_firestore`, `intl` (all already
present, no new dependency — unlike `004`, which added `firebase_analytics`)

**Storage**: Cloud Firestore — reads/writes the same `users/{userId}/expenses` collection `004`
already writes to; `firestore.rules`/`firestore.indexes.json` unchanged (already cover every
write/query this feature produces, per `003`'s existing `(deletedAt ASC, date DESC)` index)

**Testing**: `flutter_test` + `mocktail` for the day-grouping function and controller unit tests;
`fake_cloud_firestore` + `firebase_auth_mocks` for the repository tests (corrected `delete()`,
`watchAll()`, `purgeDeletedOlderThan()`); a new `integration_test/` file pumping the real `App`
widget (full `go_router` shell) to prove no regression to `004`'s measured logging path

**Target Platform**: iOS 15+, Android API 24+ — unchanged

**Project Type**: Mobile app (Flutter) — second product screen; first feature to introduce real
multi-route navigation via `go_router`

**Performance Goals**: Undo and delete complete with no perceptible delay, online or offline
(FR-010); zero regression to `004`'s p90 time-to-log budget (FR-013, Constitution Principle 1) —
verified structurally by this feature's own regression test, not re-measured from scratch

**Constraints**: no confirmation dialog on delete (FR-005); exactly one Firestore write per
non-undone deletion, zero for an undone one (FR-009, per the plan input); capture is always the
app's launch destination regardless of prior navigation state (FR-012); no new illustration
dependency for the empty state (plan input); every new color/typography/radius/spacing value lives
only in its existing token file (Constitution Principle 9)

**Scale/Scope**: 1 new screen (`ExpenseHistoryPage`), 1 new shared nav shell (`AppShell` +
`ShellRoute`), 1 corrected + 2 additive `ExpenseRepository` members, 1 new use case
(`PurgeExpiredDeletedExpensesUseCase`), 1 new controller (`ExpenseHistoryController`), 1 new
plain-Dart helper (`groupByDay`), 6 new ARB keys across 5 locales, 0 changes to `firestore.rules`,
0 new dependencies

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Applies? | Assessment |
|---|---|---|
| 1. The Logging Path Is Sacred | Yes | Core constraint, not core purpose. The floating nav bar and the new route add zero screens/dialogs/spinners to the capture flow; `initialLocation: '/'` with no restoration logic keeps capture as the fixed launch destination. Proven by a dedicated regression test (research.md), not asserted. |
| 2. Offline-First, Always | Yes | Delete/undo/purge all operate against the local cache first; the expiry-time delete write is fire-and-forget, never awaited by any UI feedback; the undo path makes zero network calls at all. |
| 3. Anti-Goals Are Binding | Yes | No editing, notes, filters, search, date ranges, category management, settings, or monthly summary introduced — all explicitly excluded in spec.md's scope. |
| 4. Layer Boundaries Are Enforced | Yes | `PurgeExpiredDeletedExpensesUseCase` (domain) depends only on abstract `ExpenseRepository`/`AuthRepository`. `groupByDay` and `ExpenseHistoryController` are presentation-only, Flutter-safe but Firestore-free beyond the repository abstraction. Only `ExpenseRepositoryImpl`/`ExpenseRemoteDataSource` (data) import `cloud_firestore` for this feature's needs. |
| 5. Money Is Exact and Private | Yes | Day subtotals are computed by summing `amountMinor` (`int`) directly — no floating-point anywhere in the fold. No new analytics event is introduced by this feature at all. |
| 6. Environments Are Isolated and Symmetric | Yes | No flavor-specific code; `firestore.rules`/indexes remain identical and unchanged across `dev`/`prod`. |
| 7. Security Rules Are the Only Real Boundary | Yes | No rules change needed — every write/query this feature performs is already covered and already tested by `003`'s ruleset and rules suite (research.md). |
| 8. Accessible by Construction | Yes | Category identity in each entry never depends on color alone (FR-004); nav bar destinations carry semantic labels (`navCaptureLabel`/`navHistoryLabel`); swipe-to-delete has an equivalent non-gesture affordance to consider at the widget level (tracked in tasks, not a new principle). |
| 9. Localized and Consistent by Construction | Yes | 6 new ARB keys ship in all five locales together; day/time formatting goes through `intl`, never string concatenation; the empty state and nav bar are built entirely from existing `app_colors`/`app_spacing`/`app_typography` tokens, per the plan input's explicit "no new illustration engine" instruction. |

**Initial gate result**: PASS. No violations requiring a Complexity Tracking entry. The
pending-deletion-set-plus-lifecycle-listener mechanism is the minimum machinery FR-009's
exactly-one-write guarantee requires — the persistence-side analog of `003`'s auth buffer and
`004`'s local-write race, not complexity added for its own sake.

**Post-Phase 1 re-check**: PASS, unchanged. `data-model.md` confirms the corrected `delete()` and
the two additive members need no Security Rules change; the nav shell design (research.md) keeps
`ExpenseCapturePage` itself unmodified in substance, only reserving layout space; no money value,
new dependency, or anti-goal-listed functionality was introduced during design.

## Project Structure

### Documentation (this feature)

```text
specs/005-expense-history-undo/
├── plan.md                        # This file
├── research.md                    # Phase 0 output
├── data-model.md                  # Phase 1 output
├── quickstart.md                  # Phase 1 output
├── contracts/
│   └── expense-history-api.md
├── checklists/
│   └── requirements.md
└── tasks.md                       # Phase 2 output (/speckit-tasks — NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── app.dart                                            # MODIFIED: ShellRoute wrapping / and /history
├── bootstrap.dart                                       # MODIFIED: + PurgeExpiredDeletedExpensesUseCase
│                                                          #   fire-and-forget call
├── core/
│   └── di/
│       ├── injection.config.dart                        # MODIFIED: regenerated
│       └── providers.dart                                # MODIFIED: + expenseHistoryControllerProvider
├── features/
│   └── expenses/
│       ├── domain/
│       │   ├── repositories/
│       │   │   └── expense_repository.dart                # MODIFIED: delete() doc corrected;
│       │   │                                               #   + watchAll(), + purgeDeletedOlderThan()
│       │   └── usecases/
│       │       └── purge_expired_deleted_expenses.dart      # NEW
│       ├── data/
│       │   ├── datasources/
│       │   │   └── expense_remote_data_source.dart          # MODIFIED: delete() → soft delete;
│       │   │                                                 #   + watchAll(), + purgeOlderThan()
│       │   └── repositories/
│       │       └── expense_repository_impl.dart              # MODIFIED: wires the 3 changed/new members
│       └── presentation/
│           ├── controllers/
│           │   └── expense_history_controller.dart            # NEW: pending-deletion set, lifecycle
│           ├── day_group.dart                                  # NEW: plain-Dart entity + groupByDay()
│           ├── pages/
│           │   └── expense_history_page.dart                    # NEW
│           └── widgets/
│               ├── history_entry_tile.dart                       # NEW
│               ├── history_empty_state.dart                       # NEW
│               └── history_day_header.dart                        # NEW
├── core/
│   └── navigation/
│       └── app_shell.dart                                # NEW: the floating nav bar + ShellRoute body
└── l10n/
    └── app_{en,es,pt,it,fr}.arb                          # MODIFIED: + 6 keys (data-model.md)

firestore.rules                                            # UNCHANGED
firestore.indexes.json                                      # UNCHANGED
firebase/tests/                                              # UNCHANGED

integration_test/
└── expense_capture_with_history_shell_test.dart              # NEW: 004 regression under the full shell

test/
├── features/expenses/
│   ├── domain/usecases/
│   │   └── purge_expired_deleted_expenses_test.dart            # NEW
│   ├── data/repositories/
│   │   └── expense_repository_impl_test.dart                    # MODIFIED: + delete()-is-soft,
│   │                                                              #   watchAll(), purge tests
│   └── presentation/
│       ├── day_group_test.dart                                   # NEW
│       ├── controllers/
│       │   └── expense_history_controller_test.dart               # NEW
│       ├── pages/
│       │   └── expense_history_page_test.dart                     # NEW
│       └── widgets/
│           ├── history_entry_tile_test.dart                       # NEW
│           └── history_empty_state_test.dart                      # NEW
└── core/navigation/
    └── app_shell_test.dart                                    # NEW
```

**Structure Decision**: Single Flutter mobile project, unchanged from `001`–`004`. This is the first
feature to populate `expenses/presentation/` beyond the capture screen, and the first to add a
`core/navigation/` directory — both additive to the existing `lib/features/expenses/` and `lib/core/`
trees, no restructuring of either.

## Complexity Tracking

*No entries.* The pending-deletion set + `AppLifecycleState.paused` flush is the necessary minimum
mechanism for FR-009's exactly-one-write guarantee — the same standard `003`'s
`runWhenAuthenticated` buffer and `004`'s local-write race were held to. Every other design choice
in `research.md` was the smaller of the available options: correcting `delete()` in place instead of
adding a parallel `softDelete()` name; a plain `ShellRoute` instead of `StatefulShellRoute`; a
client-triggered purge instead of standing up Cloud Functions; reusing `004`'s category-icon/name
resolvers unchanged instead of duplicating them.
