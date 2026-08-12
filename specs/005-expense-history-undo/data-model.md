# Phase 1 Data Model: Historial de Gastos con Borrado Reversible

## Domain entities (unchanged)

`Expense` (from `003`) is consumed exactly as-is — no new field. `deletedAt` stays a data-layer-only
concern, exactly as `003`'s original doc comment on `Expense` already anticipated.

## `ExpenseRepository` — one corrected member, two additive members

```dart
abstract class ExpenseRepository {
  Future<Result<Expense>> create(Expense expense); // unchanged (004)

  /// CORRECTED (was a hard-delete stub in 004, "no caller exists yet").
  /// Now sets `deletedAt` — the only "delete" concept this product has.
  Future<Result<void>> delete(String expenseId);

  Stream<List<Expense>> watchByMonth(String monthKey); // unchanged (003/004 contract, unused by any screen yet)

  /// NEW, additive. Live query of every non-deleted expense, ordered by
  /// `date` descending, unscoped by month — the source stream
  /// `ExpenseHistoryController` layers its client-side pending-deletion
  /// filter over.
  Stream<List<Expense>> watchAll();

  /// NEW, additive. Hard-deletes every expense whose `deletedAt` is older
  /// than [cutoff]. Called once, fire-and-forget, from
  /// `PurgeExpiredDeletedExpensesUseCase` at bootstrap.
  Future<Result<void>> purgeDeletedOlderThan(DateTime cutoff);
}
```

Both new members are additive per `003`'s contract stability notes (same precedent `004` already
used for `CategoryRepository.seedDefaultsIfNeeded()`).

## Firestore writes/queries (no schema or rules change)

| Operation | Firestore call | Rule that already covers it |
| --- | --- | --- |
| Soft delete (`delete()`) | `.doc(id).update({'deletedAt': Timestamp.now()})` | `allow update: if isOwner(userId) && isValidExpense() && incoming().createdAt == resource.data.createdAt` |
| History stream (`watchAll()`) | `.where('deletedAt', isNull: true).orderBy('date', descending: true).snapshots()` | `allow read: if isOwner(userId)` — matches the existing `(deletedAt ASC, date DESC)` index from `001`/`003` exactly |
| Purge (`purgeDeletedOlderThan()`) | `.where('deletedAt', isLessThan: Timestamp.fromDate(cutoff)).get()`, then a batch `.delete()` per match | `allow delete: if isOwner(userId)` |

## Presentation-layer state (new, feature-local — not domain)

### `DayGroup` (plain Dart, `expenses/presentation/`)

```dart
class DayGroup {
  final DateTime day;           // calendar day, local
  final List<Expense> expenses; // chronological within the day
  final int subtotalMinor;      // sum of amountMinor, this day only
}
```

Produced by a pure function `groupByDay(List<Expense>) -> List<DayGroup>`, sorted days
descending, expenses within each day descending by time (matches FR-001/FR-002).

### `ExpenseHistoryState` (Riverpod, `expenses/presentation/controllers/`)

- `dayGroups: List<DayGroup>` — the live stream's expenses, minus any pending-deletion ids, grouped.
- `pendingDeletionIds: Set<String>` — expenses swiped away but not yet written to Firestore.
- Internally (not exposed to the UI): one `Timer` per pending-deletion id, and an
  `AppLifecycleListener` that flushes all pending deletions on `AppLifecycleState.paused`.

### Navigation

`go_router`'s route table gains one `ShellRoute` wrapping two `GoRoute`s:

| Path | Page | Notes |
| --- | --- | --- |
| `/` | `ExpenseCapturePage` (unchanged, `004`) | Still the router's `initialLocation` — every app launch starts here (FR-012) |
| `/history` | `ExpenseHistoryPage` (new) | Reached only via the floating nav bar |

The `ShellRoute`'s builder renders the floating nav bar (per `docs/UI_UX_SPEC.md` §4) as a
`Stack`/`Align`-positioned overlay above whichever child route is active — not
`Scaffold.bottomNavigationBar`, which docks rather than floats.

## New ARB keys (all five locales)

| ARB key | English value | Description |
| --- | --- | --- |
| `commonUndo` | Undo | Action label — the undo button in the delete snackbar |
| `historyExpenseDeletedMessage` | Expense deleted | Snackbar text shown after a swipe-to-delete |
| `historyEmptyTitle` | Nothing here yet | Empty-state heading |
| `historyEmptySubtitle` | Expenses you log will show up here | Empty-state body |
| `navCaptureLabel` | Log expense | Semantic label for the nav bar's capture destination |
| `navHistoryLabel` | History | Semantic label/visible label for the nav bar's history destination |

Day-group headers and entry times are formatted via `intl` (locale-aware date/time formatting,
Constitution Principle 9), not ARB strings — no "Today"/"Yesterday" relative-label key is
introduced (out of scope; not requested by any acceptance criterion).

## Security Rules

No change. See research.md's "`firestore.rules` needs no changes" decision — every write and query
this feature performs is already covered by `003`'s ruleset.
