import 'package:injectable/injectable.dart';
import 'package:wrap_my_finances/core/analytics/analytics_service.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/core/instrumentation/app_launch_clock.dart';
import 'package:wrap_my_finances/features/auth/domain/repositories/auth_repository.dart';
import 'package:wrap_my_finances/features/categories/domain/repositories/category_repository.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/domain/repositories/expense_repository.dart';

/// Persists a draft expense, bumps its category's usage count, and reports
/// FR-003/SC-001's timing — the exact pattern
/// `specs/003-auth-domain-foundation/contracts/auth-api.md` prescribed for
/// every future write use case, extended with the two side effects this
/// feature needs. Both side effects fire only after local persistence is
/// confirmed (never before, never gated on the server) — see
/// `specs/004-quick-expense-capture/research.md`.
@injectable
class LogExpense {
  /// Creates the use case.
  LogExpense(
    this._authRepository,
    this._expenseRepository,
    this._categoryRepository,
    this._appLaunchClock,
    this._analyticsService,
  );

  final AuthRepository _authRepository;
  final ExpenseRepository _expenseRepository;
  final CategoryRepository _categoryRepository;
  final AppLaunchClock _appLaunchClock;
  final AnalyticsService _analyticsService;

  /// Logs [draft]. Its `id` field is a placeholder — the repository assigns
  /// the real, client-generated id (see research.md).
  Future<Result<Expense>> call(Expense draft) {
    return _authRepository.runWhenAuthenticated((uid) async {
      final result = await _expenseRepository.create(draft);
      return result.when(
        success: (expense) async {
          await _categoryRepository.incrementUsage(expense.categoryId);
          _analyticsService.logExpenseTimeToLog(
            _appLaunchClock.elapsedSinceLaunch(),
          );
          return Success(expense);
        },
        failed: (failure) async => Failed<Expense>(failure),
      );
    });
  }
}
