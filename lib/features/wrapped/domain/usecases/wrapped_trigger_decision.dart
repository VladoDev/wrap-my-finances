import 'package:wrap_my_finances/features/user_profile/domain/entities/user_profile.dart';
import 'package:wrap_my_finances/features/wrapped/domain/entities/wrapped_summary.dart';

/// The three outcomes evaluating the Wrapped auto-trigger can reach. See
/// `specs/006-monthly-wrapped-summary/data-model.md` §4.
enum WrappedTriggerResult {
  /// Navigate to `/wrapped/:monthKey` automatically.
  autoShow,

  /// Don't auto-show, but offer a small, dismissible card for it.
  offerSuppressedCard,

  /// Neither — nothing to show, or already seen.
  none,
}

/// The minimum non-deleted expense count for a month to auto-trigger
/// Wrapped, per acceptance criterion 2.
const int wrappedAutoTriggerMinimumExpenseCount = 5;

/// Pure decision function: given the user's profile and the previous
/// month's summary, decides whether to auto-show, offer discreetly, or do
/// nothing. No side effects, no Firestore/navigation access — see
/// `specs/006-monthly-wrapped-summary/data-model.md` §4 steps 3-4.
WrappedTriggerResult decideWrappedTrigger({
  required UserProfile profile,
  required WrappedSummary summary,
}) {
  if (summary.monthKey == profile.wrappedLastSeenMonth) {
    return WrappedTriggerResult.none;
  }
  if (summary.isSyncing) return WrappedTriggerResult.none;
  if (summary.expenseCount >= wrappedAutoTriggerMinimumExpenseCount) {
    return WrappedTriggerResult.autoShow;
  }
  if (summary.expenseCount > 0) {
    return WrappedTriggerResult.offerSuppressedCard;
  }
  return WrappedTriggerResult.none;
}

/// `"YYYY-MM"` for the calendar month immediately before [now]. Uses
/// [now]'s own time zone (device-local when called with `DateTime.now()`)
/// rather than a stored IANA zone — see
/// `specs/006-monthly-wrapped-summary/research.md` #2 for why that's
/// observably equivalent today.
String previousMonthKey(DateTime now) {
  final previousMonthDate = DateTime(now.year, now.month - 1);
  final year = previousMonthDate.year.toString().padLeft(4, '0');
  final month = previousMonthDate.month.toString().padLeft(2, '0');
  return '$year-$month';
}
