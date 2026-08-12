import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';

/// Domain contract for persisting and querying expenses. No implementation
/// exists yet — `004` builds `data/`/`presentation/` against this
/// interface. See `contracts/domain-repositories-api.md`.
abstract class ExpenseRepository {
  /// Persists a new expense.
  Future<Result<Expense>> create(Expense expense);

  /// Soft-deletes: sets `deletedAt` on the expense (per
  /// `docs/DATA_MODEL.md`) rather than removing the document — the only
  /// "delete" concept this product has. `005` is this member's first real
  /// caller; see `specs/005-expense-history-undo/research.md`.
  Future<Result<void>> delete(String expenseId);

  /// Live query for all expenses in the given month (`"2026-08"`-style
  /// key). `monthKey` is passed in rather than derived from [Expense],
  /// since the entity itself doesn't carry it.
  Stream<List<Expense>> watchByMonth(String monthKey);

  /// Live query of every non-deleted expense, newest first, unscoped by
  /// month — the source stream the history screen's client-side
  /// pending-deletion filter layers over. Additive per `003`'s contract
  /// stability notes.
  Stream<List<Expense>> watchAll();

  /// Hard-deletes every expense whose `deletedAt` is older than [cutoff].
  /// Called once, fire-and-forget, by `PurgeExpiredDeletedExpensesUseCase`
  /// at bootstrap. Additive per `003`'s contract stability notes.
  Future<Result<void>> purgeDeletedOlderThan(DateTime cutoff);
}
