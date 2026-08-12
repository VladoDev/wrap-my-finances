import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wrap_my_finances/core/errors/failure.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/expenses/domain/usecases/log_expense.dart';
import 'package:wrap_my_finances/features/expenses/presentation/controllers/expense_capture_controller.dart';

class _MockLogExpense extends Mock implements LogExpense {}

void main() {
  late _MockLogExpense logExpense;
  late ExpenseCaptureController controller;

  setUpAll(() {
    registerFallbackValue(
      Expense(
        id: '',
        amount: const Money(minorUnits: 0, currencyCode: 'XXX'),
        categoryId: '',
        date: DateTime(2026),
        createdAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    logExpense = _MockLogExpense();
    controller = ExpenseCaptureController(
      logExpense: logExpense,
      locale: 'en',
    );
  });

  group('happy path (US1)', () {
    test('advanceToCategory is a no-op while the amount is invalid', () {
      controller.advanceToCategory();
      expect(controller.state.step, CaptureStep.amount);
    });

    test('advanceToCategory moves to the category step once valid', () {
      controller
        ..appendDigit('5')
        ..advanceToCategory();
      expect(controller.state.step, CaptureStep.category);
    });
  });

  group('local write failure (US4)', () {
    test(
      'on Failed, preserves the current step and typed amount, exposes the '
      'error',
      () async {
        controller
          ..appendDigit('5')
          ..advanceToCategory();
        final failure = UnknownFailure(
          Exception('disk full'),
          StackTrace.empty,
        );
        when(
          () => logExpense.call(any()),
        ).thenAnswer((_) async => Failed(failure));

        await controller.submit('cat_food');

        expect(controller.state.lastError, failure);
        expect(controller.state.step, CaptureStep.category);
        expect(controller.state.amount.minorUnits, 500);
        expect(controller.state.isSubmitting, isFalse);
      },
    );

    test('a subsequent successful attempt clears the error', () async {
      controller
        ..appendDigit('5')
        ..advanceToCategory();
      when(() => logExpense.call(any())).thenAnswer(
        (_) async => Failed(UnknownFailure(Exception('x'), StackTrace.empty)),
      );
      await controller.submit('cat_food');
      expect(controller.state.lastError, isNotNull);

      when(() => logExpense.call(any())).thenAnswer(
        (_) async => Success(
          Expense(
            id: 'exp_1',
            amount: const Money(minorUnits: 500, currencyCode: 'XXX'),
            categoryId: 'cat_food',
            date: DateTime(2026),
            createdAt: DateTime(2026),
          ),
        ),
      );
      await controller.submit('cat_food');

      expect(controller.state.lastError, isNull);
      expect(controller.state.step, CaptureStep.amount);
    });
  });
}
