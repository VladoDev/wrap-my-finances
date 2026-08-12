import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/expenses/domain/repositories/expense_repository.dart';
import 'package:wrap_my_finances/features/expenses/presentation/controllers/expense_history_controller.dart';

class _MockExpenseRepository extends Mock implements ExpenseRepository {}

Expense _expense(String id, {DateTime? date}) {
  final effectiveDate = date ?? DateTime(2026, 8, 10);
  return Expense(
    id: id,
    amount: const Money(minorUnits: 500, currencyCode: 'MXN'),
    categoryId: 'cat_food',
    date: effectiveDate,
    createdAt: effectiveDate,
  );
}

void main() {
  // ExpenseHistoryController's AppLifecycleListener needs a bound
  // WidgetsBinding even in these plain (non-testWidgets) unit tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockExpenseRepository repository;
  late StreamController<List<Expense>> expensesController;

  setUp(() {
    repository = _MockExpenseRepository();
    expensesController = StreamController<List<Expense>>.broadcast();
    when(
      () => repository.watchAll(),
    ).thenAnswer((_) => expensesController.stream);
    when(
      () => repository.delete(any()),
    ).thenAnswer((_) async => const Success(null));
  });

  tearDown(() => expensesController.close());

  ExpenseHistoryController buildController({Duration? undoWindow}) {
    final controller = ExpenseHistoryController(
      expenseRepository: repository,
      undoWindow: undoWindow ?? const Duration(milliseconds: 20),
    );
    addTearDown(controller.dispose);
    return controller;
  }

  test(
    'requestDelete excludes the id synchronously, with zero repository calls',
    () async {
      final controller = buildController();
      expensesController.add([_expense('a'), _expense('b')]);
      await Future<void>.delayed(Duration.zero);

      controller.requestDelete('a');

      expect(
        controller.state.dayGroups.single.expenses.map((e) => e.id),
        ['b'],
      );
      verifyNever(() => repository.delete(any()));
    },
  );

  test(
    'undoDelete before the window elapses restores it, still zero '
    'repository calls',
    () async {
      final controller = buildController(
        undoWindow: const Duration(milliseconds: 200),
      );
      expensesController.add([_expense('a')]);
      await Future<void>.delayed(Duration.zero);

      controller.requestDelete('a');
      expect(controller.state.dayGroups, isEmpty);

      controller.undoDelete('a');
      expect(controller.state.dayGroups.single.expenses.map((e) => e.id), [
        'a',
      ]);

      // Give the (cancelled) timer's original duration time to have fired,
      // to prove it really was cancelled, not just not-yet-due.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      verifyNever(() => repository.delete(any()));
    },
  );

  test(
    'backgrounding the app confirms every pending deletion immediately, '
    'without waiting for the window',
    () async {
      final controller = buildController(
        undoWindow: const Duration(minutes: 10), // long enough to prove
        // the flush isn't just the timer coincidentally firing
      );
      expensesController.add([_expense('a'), _expense('b')]);
      await Future<void>.delayed(Duration.zero);

      controller
        ..requestDelete('a')
        ..requestDelete('b');
      expect(controller.state.dayGroups, isEmpty);
      verifyNever(() => repository.delete(any()));

      TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      await Future<void>.delayed(Duration.zero);

      verify(() => repository.delete('a')).called(1);
      verify(() => repository.delete('b')).called(1);
      expect(controller.state.pendingDeletionIds, isEmpty);
    },
  );

  test(
    'letting the window elapse calls ExpenseRepository.delete exactly once',
    () async {
      final controller = buildController(
        undoWindow: const Duration(milliseconds: 20),
      );
      expensesController.add([_expense('a')]);
      await Future<void>.delayed(Duration.zero);

      controller.requestDelete('a');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => repository.delete('a')).called(1);
      expect(controller.state.pendingDeletionIds, isEmpty);
    },
  );
}
