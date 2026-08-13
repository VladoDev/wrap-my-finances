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
      currencyCodeOf: () => 'USD',
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

  group('currency preference (007 US8)', () {
    test(
      'submit uses whatever currencyCodeOf() currently returns, read fresh '
      'each time — not a snapshot taken at construction',
      () async {
        var code = 'USD';
        final flexibleController = ExpenseCaptureController(
          logExpense: logExpense,
          locale: 'en',
          currencyCodeOf: () => code,
        );
        when(() => logExpense.call(any())).thenAnswer(
          (_) async => Success(
            Expense(
              id: 'exp_1',
              amount: const Money(minorUnits: 500, currencyCode: 'USD'),
              categoryId: 'cat_food',
              date: DateTime(2026),
              createdAt: DateTime(2026),
            ),
          ),
        );

        flexibleController
          ..appendDigit('5')
          ..advanceToCategory();
        await flexibleController.submit('cat_food');

        final firstDraft =
            verify(
                  () => logExpense.call(captureAny()),
                ).captured.single
                as Expense;
        expect(firstDraft.amount.currencyCode, 'USD');

        // Preference changes — e.g. edited in Settings mid-session — before
        // the next expense is logged.
        code = 'EUR';
        flexibleController
          ..appendDigit('7')
          ..advanceToCategory();
        await flexibleController.submit('cat_food');

        // The second call's captured argument is the *new* draft only —
        // LogExpense.call is a one-shot create, never a read or update, so
        // the first (already-submitted) draft is structurally never
        // touched again by this path.
        final secondDraft =
            verify(() => logExpense.call(captureAny())).captured.last
                as Expense;
        expect(secondDraft.amount.currencyCode, 'EUR');
      },
    );
  });
}
