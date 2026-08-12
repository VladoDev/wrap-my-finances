import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/auth/domain/repositories/auth_repository.dart';
import 'package:wrap_my_finances/features/expenses/domain/repositories/expense_repository.dart';
import 'package:wrap_my_finances/features/expenses/domain/usecases/purge_expired_deleted_expenses.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  test(
    'runs via runWhenAuthenticated and purges with a cutoff 30 days before now',
    () async {
      final authRepository = _MockAuthRepository();
      final expenseRepository = _MockExpenseRepository();
      final useCase = PurgeExpiredDeletedExpensesUseCase(
        authRepository,
        expenseRepository,
      );

      when(
        () => authRepository.runWhenAuthenticated<void>(any()),
      ).thenAnswer((invocation) {
        final operation =
            invocation.positionalArguments.first
                as Future<void> Function(
                  String,
                );
        return operation('uid_123');
      });
      when(
        () => expenseRepository.purgeDeletedOlderThan(any()),
      ).thenAnswer((_) async => const Success(null));

      final before = DateTime.now().subtract(expiredDeletionAge);
      await useCase.call();
      final after = DateTime.now().subtract(expiredDeletionAge);

      final captured =
          verify(
                () => expenseRepository.purgeDeletedOlderThan(captureAny()),
              ).captured.single
              as DateTime;
      expect(
        captured.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        captured.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
      verify(
        () => authRepository.runWhenAuthenticated<void>(any()),
      ).called(1);
    },
  );
}
