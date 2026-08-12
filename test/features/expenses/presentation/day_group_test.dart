import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/expenses/presentation/day_group.dart';

Expense _expense({
  required String id,
  required int minorUnits,
  required DateTime date,
}) {
  return Expense(
    id: id,
    amount: Money(minorUnits: minorUnits, currencyCode: 'MXN'),
    categoryId: 'cat_food',
    date: date,
    createdAt: date,
  );
}

void main() {
  test('groups expenses by calendar day', () {
    final expenses = [
      _expense(id: 'a', minorUnits: 100, date: DateTime(2026, 8, 10, 9)),
      _expense(id: 'b', minorUnits: 200, date: DateTime(2026, 8, 11, 14)),
      _expense(id: 'c', minorUnits: 300, date: DateTime(2026, 8, 10, 18)),
    ];

    final groups = groupByDay(expenses);

    expect(groups, hasLength(2));
    expect(groups.map((g) => g.day), [
      DateTime(2026, 8, 11),
      DateTime(2026, 8, 10),
    ]);
  });

  test('orders days descending and expenses within a day descending', () {
    final expenses = [
      _expense(id: 'morning', minorUnits: 100, date: DateTime(2026, 8, 10, 9)),
      _expense(id: 'evening', minorUnits: 300, date: DateTime(2026, 8, 10, 18)),
    ];

    final groups = groupByDay(expenses);

    expect(groups, hasLength(1));
    expect(groups.single.expenses.map((e) => e.id), ['evening', 'morning']);
  });

  test("each subtotal equals the exact sum of that day's amountMinor", () {
    final expenses = [
      _expense(id: 'a', minorUnits: 10, date: DateTime(2026, 8, 10)),
      _expense(id: 'b', minorUnits: 333, date: DateTime(2026, 8, 10)),
      _expense(id: 'c', minorUnits: 1267, date: DateTime(2026, 8, 10)),
    ];

    final groups = groupByDay(expenses);

    expect(groups.single.subtotalMinor, 10 + 333 + 1267);
  });

  test('returns an empty list for no expenses', () {
    expect(groupByDay(const []), isEmpty);
  });
}
