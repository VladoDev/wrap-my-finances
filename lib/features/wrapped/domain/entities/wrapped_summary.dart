import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';

/// The computed aggregate for one calendar month — never persisted;
/// recomputed on demand from the local Firestore cache, per
/// `docs/DATA_MODEL.md`'s "Wrapped aggregation" (no `monthlySummaries`
/// collection). See `specs/006-monthly-wrapped-summary/data-model.md` §2.
class WrappedSummary {
  /// Creates a summary. When [isSyncing] is `true`, every other field is
  /// meaningless and MUST NOT be displayed (FR-012).
  const WrappedSummary({
    required this.monthKey,
    required this.isSyncing,
    required this.total,
    required this.topCategoryId,
    required this.topCategoryExpenseCount,
    required this.biggestExpense,
    required this.expenseCount,
  });

  /// `"YYYY-MM"`.
  final String monthKey;

  /// `true` when the local cache's document count for this month is less
  /// than the server-side `count()` for the same filter.
  final bool isSyncing;

  /// Sum of every non-deleted expense's amount this month.
  final Money total;

  /// The category with the highest summed amount this month. `null` only
  /// when [expenseCount] is `0`.
  final String? topCategoryId;

  /// Count of non-deleted expenses in [topCategoryId] this month — "The
  /// Habit" story, not the count of all expenses in the month.
  final int topCategoryExpenseCount;

  /// The single largest non-deleted expense's amount this month. `null`
  /// only when [expenseCount] is `0`.
  final Money? biggestExpense;

  /// Total non-deleted expense count this month.
  final int expenseCount;
}
