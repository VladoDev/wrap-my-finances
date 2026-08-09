import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';

/// Domain contract for persisting and querying expenses. No implementation
/// exists yet — `004` builds `data/`/`presentation/` against this
/// interface. See `contracts/domain-repositories-api.md`.
abstract class ExpenseRepository {
  /// Persists a new expense.
  Future<Result<Expense>> create(Expense expense);

  /// Deletes (soft-deletes, per `docs/DATA_MODEL.md` — a data-layer
  /// concern) an expense by id.
  Future<Result<void>> delete(String expenseId);

  /// Live query for all expenses in the given month (`"2026-08"`-style
  /// key). `monthKey` is passed in rather than derived from [Expense],
  /// since the entity itself doesn't carry it.
  Stream<List<Expense>> watchByMonth(String monthKey);
}
