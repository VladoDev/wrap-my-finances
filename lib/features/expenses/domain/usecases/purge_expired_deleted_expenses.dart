import 'package:injectable/injectable.dart';
import 'package:wrap_my_finances/features/auth/domain/repositories/auth_repository.dart';
import 'package:wrap_my_finances/features/expenses/domain/repositories/expense_repository.dart';

/// How long a soft-deleted expense survives before being hard-deleted for
/// good, per `docs/DATA_MODEL.md`.
const Duration expiredDeletionAge = Duration(days: 30);

/// Hard-deletes every expense soft-deleted more than [expiredDeletionAge]
/// ago. Called fire-and-forget from `bootstrap()`, alongside sign-in and
/// category seeding — never awaited, never blocks first frame. Idempotent,
/// so running it on every launch is safe. See
/// `specs/005-expense-history-undo/contracts/expense-history-api.md`.
@injectable
class PurgeExpiredDeletedExpensesUseCase {
  /// Creates the use case.
  PurgeExpiredDeletedExpensesUseCase(
    this._authRepository,
    this._expenseRepository,
  );

  final AuthRepository _authRepository;
  final ExpenseRepository _expenseRepository;

  /// Runs the purge, deferring until sign-in resolves if it hasn't yet.
  Future<void> call() {
    return _authRepository.runWhenAuthenticated(
      (uid) => _expenseRepository.purgeDeletedOlderThan(
        DateTime.now().subtract(expiredDeletionAge),
      ),
    );
  }
}
