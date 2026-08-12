import 'package:meta/meta.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';

/// A calendar day's worth of expenses, for the history screen only — plain
/// Dart, no Flutter dependency, fast to unit test (same "no widget
/// bindings needed" precedent `004`'s `AmountInputState` set).
@immutable
class DayGroup {
  /// Creates a day group. [expenses] must already be sorted newest-first.
  const DayGroup({
    required this.day,
    required this.expenses,
    required this.subtotalMinor,
  });

  /// The calendar day (local), midnight-normalized.
  final DateTime day;

  /// This day's expenses, newest first.
  final List<Expense> expenses;

  /// The exact sum of this day's `amountMinor` values.
  final int subtotalMinor;
}

/// Groups [expenses] by calendar day (using each expense's already-local
/// `date`, per `004`'s device-local design — no timezone conversion here),
/// newest day first, newest expense first within each day.
List<DayGroup> groupByDay(List<Expense> expenses) {
  final byDay = <DateTime, List<Expense>>{};
  for (final expense in expenses) {
    final day = DateTime(
      expense.date.year,
      expense.date.month,
      expense.date.day,
    );
    byDay.putIfAbsent(day, () => []).add(expense);
  }

  final sortedDays = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

  return [
    for (final day in sortedDays)
      DayGroup(
        day: day,
        expenses: (byDay[day]!..sort((a, b) => b.date.compareTo(a.date))),
        subtotalMinor: byDay[day]!.fold(
          0,
          (total, expense) => total + expense.amount.minorUnits,
        ),
      ),
  ];
}
