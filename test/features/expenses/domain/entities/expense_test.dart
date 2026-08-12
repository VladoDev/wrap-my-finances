import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';

void main() {
  test('constructs with a Money amount and all fields accessible, no note', () {
    final expense = Expense(
      id: 'exp_1',
      amount: const Money(minorUnits: 15000, currencyCode: 'MXN'),
      categoryId: 'cat_food',
      date: DateTime(2026, 8, 7, 14, 30),
      createdAt: DateTime(2026, 8, 7, 14, 30, 2),
    );

    expect(expense.id, 'exp_1');
    expect(expense.amount.minorUnits, 15000);
    expect(expense.categoryId, 'cat_food');
    expect(expense.note, isNull);
  });

  test('constructs with an optional note', () {
    final expense = Expense(
      id: 'exp_2',
      amount: const Money(minorUnits: 500, currencyCode: 'USD'),
      categoryId: 'cat_coffee',
      date: DateTime(2026, 8, 7),
      createdAt: DateTime(2026, 8, 7),
      note: 'Lunch',
    );

    expect(expense.note, 'Lunch');
  });
}
