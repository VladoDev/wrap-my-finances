import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wrap_my_finances/core/analytics/analytics_service.dart';
import 'package:wrap_my_finances/core/errors/failure.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/core/instrumentation/app_launch_clock.dart';
import 'package:wrap_my_finances/features/auth/domain/repositories/auth_repository.dart';
import 'package:wrap_my_finances/features/categories/domain/repositories/category_repository.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/expenses/domain/repositories/expense_repository.dart';
import 'package:wrap_my_finances/features/expenses/domain/usecases/log_expense.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockExpenseRepository extends Mock implements ExpenseRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockAnalyticsService extends Mock implements AnalyticsService {}

class _MockAppLaunchClock extends Mock implements AppLaunchClock {}

void main() {
  late _MockAuthRepository authRepository;
  late _MockExpenseRepository expenseRepository;
  late _MockCategoryRepository categoryRepository;
  late _MockAnalyticsService analyticsService;
  late _MockAppLaunchClock appLaunchClock;
  late LogExpense logExpense;
  late Expense draft;
  late Expense persisted;

  setUpAll(() {
    draft = Expense(
      id: '',
      amount: const Money(minorUnits: 500, currencyCode: 'MXN'),
      categoryId: 'cat_food',
      date: DateTime(2026, 8, 11),
      createdAt: DateTime(2026, 8, 11),
    );
    persisted = Expense(
      id: 'exp_real_id',
      amount: draft.amount,
      categoryId: draft.categoryId,
      date: draft.date,
      createdAt: draft.createdAt,
    );
    registerFallbackValue(draft);
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    expenseRepository = _MockExpenseRepository();
    categoryRepository = _MockCategoryRepository();
    analyticsService = _MockAnalyticsService();
    appLaunchClock = _MockAppLaunchClock();
    logExpense = LogExpense(
      authRepository,
      expenseRepository,
      categoryRepository,
      appLaunchClock,
      analyticsService,
    );

    // runWhenAuthenticated just invokes the operation with a fixed uid,
    // matching FirebaseAuthRepository's real contract.
    when(
      () => authRepository.runWhenAuthenticated<Result<Expense>>(any()),
    ).thenAnswer((invocation) {
      final operation =
          invocation.positionalArguments.first
              as Future<Result<Expense>> Function(String);
      return operation('uid_123');
    });
    when(() => appLaunchClock.elapsedSinceLaunch()).thenReturn(
      const Duration(milliseconds: 1200),
    );
  });

  test(
    'invokes runWhenAuthenticated, create, incrementUsage, and '
    'logExpenseTimeToLog exactly once each, only after create succeeds',
    () async {
      when(
        () => expenseRepository.create(any()),
      ).thenAnswer((_) async => Success(persisted));
      when(
        () => categoryRepository.incrementUsage(any()),
      ).thenAnswer((_) async => const Success(null));

      final result = await logExpense.call(draft);

      expect(result, isA<Success<Expense>>());
      expect((result as Success<Expense>).value, persisted);

      verify(
        () => authRepository.runWhenAuthenticated<Result<Expense>>(any()),
      ).called(1);
      verify(() => expenseRepository.create(draft)).called(1);
      verify(() => categoryRepository.incrementUsage('cat_food')).called(1);
      verify(() => analyticsService.logExpenseTimeToLog(any())).called(1);
    },
  );

  test(
    'does not increment usage or report timing when create fails',
    () async {
      when(() => expenseRepository.create(any())).thenAnswer(
        (_) async =>
            Failed(UnknownFailure(Exception('boom'), StackTrace.empty)),
      );

      final result = await logExpense.call(draft);

      expect(result, isA<Failed<Expense>>());
      verifyNever(() => categoryRepository.incrementUsage(any()));
      verifyNever(() => analyticsService.logExpenseTimeToLog(any()));
    },
  );
}
