import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/expenses/domain/repositories/expense_repository.dart';

/// Proves `ExpenseRepository` is a compilable, exercisable contract with no
/// Flutter/Firebase dependency — the actual implementation arrives in `004`.
class _FakeExpenseRepository implements ExpenseRepository {
  final List<Expense> _stored = [];

  @override
  Future<Result<Expense>> create(Expense expense) async {
    _stored.add(expense);
    return Success(expense);
  }

  @override
  Future<Result<void>> delete(String expenseId) async {
    _stored.removeWhere((e) => e.id == expenseId);
    return const Success(null);
  }

  @override
  Stream<List<Expense>> watchByMonth(String monthKey) {
    return Stream.value(_stored);
  }
}

void main() {
  test(
    'a fake ExpenseRepository compiles and exercises create/delete/watchByMonth',
    () async {
      final repository = _FakeExpenseRepository();
      final expense = Expense(
        id: 'exp_1',
        amount: const Money(minorUnits: 100, currencyCode: 'USD'),
        categoryId: 'cat_food',
        date: DateTime(2026, 8, 7),
        createdAt: DateTime(2026, 8, 7),
      );

      final created = await repository.create(expense);
      expect(created, isA<Success<Expense>>());

      final watched = await repository.watchByMonth('2026-08').first;
      expect(watched, [expense]);

      final deleted = await repository.delete('exp_1');
      expect(deleted, isA<Success<void>>());
    },
  );
}
