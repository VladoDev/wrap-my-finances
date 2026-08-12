# Contract: Expense History & Undoable Delete Domain API

This feature implements against `003`'s `ExpenseRepository`/`AuthRepository` contracts, correcting
one member's behavior (documented in `research.md`) and adding two more. Anything already
documented in `specs/003-auth-domain-foundation/contracts/` or
`specs/004-quick-expense-capture/contracts/` is not repeated here.

## `ExpenseRepository` — corrected and additive members

```dart
abstract class ExpenseRepository {
  // ...existing members (create, watchByMonth), unchanged...

  /// Soft-deletes: sets `deletedAt` on the expense. This is the only
  /// "delete" concept in this product — corrected from 004's unvalidated
  /// hard-delete stub, no signature change.
  Future<Result<void>> delete(String expenseId);

  /// Live query of every non-deleted expense, newest first, unscoped by
  /// month.
  Stream<List<Expense>> watchAll();

  /// Hard-deletes every expense whose `deletedAt` is older than [cutoff].
  Future<Result<void>> purgeDeletedOlderThan(DateTime cutoff);
}
```

## `ExpenseHistoryController` (new, presentation)

```dart
class ExpenseHistoryController extends StateNotifier<ExpenseHistoryState> {
  /// Swipe-to-delete: excludes [expenseId] from the visible projection
  /// immediately and starts its undo window. No Firestore write yet.
  void requestDelete(String expenseId);

  /// Cancels [expenseId]'s pending deletion — it reappears in its original
  /// position, since it was never actually removed from the underlying
  /// stream. No Firestore write occurs for an undone deletion.
  void undoDelete(String expenseId);
}
```

Behavioral contract: exactly one `ExpenseRepository.delete()` call happens per swipe that is *not*
undone within the window (or before the app backgrounds), and exactly zero calls happen per swipe
that *is* undone. `requestDelete`/`undoDelete` never await Firestore — both return synchronously,
satisfying FR-010's "no demora perceptible, con o sin conexión."

## `PurgeExpiredDeletedExpensesUseCase` (new, domain)

```dart
class PurgeExpiredDeletedExpensesUseCase {
  PurgeExpiredDeletedExpensesUseCase(this._authRepository, this._expenseRepository);
  final AuthRepository _authRepository;
  final ExpenseRepository _expenseRepository;

  Future<void> call() {
    return _authRepository.runWhenAuthenticated(
      (uid) => _expenseRepository.purgeDeletedOlderThan(
        DateTime.now().subtract(const Duration(days: 30)),
      ),
    );
  }
}
```

Called fire-and-forget from `bootstrap()`, alongside `SignInAnonymouslyUseCase` and
`SeedDefaultCategoriesUseCase` — never awaited, never blocks first frame (FR: "corre al arranque,
sin bloquear la primera pantalla").

## Navigation contract

- `go_router`'s `initialLocation` is `/` (`ExpenseCapturePage`) and no code path persists or
  restores a prior route — this, not any explicit "always start at capture" check, is what
  satisfies FR-012.
- The floating nav bar exposes exactly two destinations for this feature: capture (`/`) and
  history (`/history`). A third (Settings) is not added by this feature.

## Stability notes for consumers

- `ExpenseRepository.delete()`'s corrected behavior (soft, not hard) is a behavioral fix to an
  already-unstable stub, not a break of any shipped caller — `004` never called it (FR-017 excluded
  delete from that feature's scope).
- `watchAll()` and `purgeDeletedOlderThan()` are additive; no existing caller of
  `ExpenseRepository` needs to change.
- A future feature that needs a bounded/paginated history query widens `watchAll()`'s contract
  additively (e.g. an overload or a new method), per the same stability precedent `003`/`004`
  established.
