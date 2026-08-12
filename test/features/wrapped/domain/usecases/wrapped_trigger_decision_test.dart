import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/user_profile/domain/entities/user_profile.dart';
import 'package:wrap_my_finances/features/wrapped/domain/entities/wrapped_summary.dart';
import 'package:wrap_my_finances/features/wrapped/domain/usecases/wrapped_trigger_decision.dart';

WrappedSummary _summary({
  required String monthKey,
  required bool isSyncing,
  required int expenseCount,
}) {
  return WrappedSummary(
    monthKey: monthKey,
    isSyncing: isSyncing,
    total: const Money(minorUnits: 0, currencyCode: 'MXN'),
    topCategoryId: expenseCount > 0 ? 'cat_food' : null,
    topCategoryExpenseCount: expenseCount,
    biggestExpense: expenseCount > 0
        ? const Money(minorUnits: 100, currencyCode: 'MXN')
        : null,
    expenseCount: expenseCount,
  );
}

void main() {
  group('decideWrappedTrigger', () {
    test(
      'autoShow when the previous month is unseen and has 5+ expenses',
      () {
        const profile = UserProfile(
          uid: 'u1',
          timeZone: 'America/Mexico_City',
          wrappedLastSeenMonth: '2026-06',
        );
        final summary = _summary(
          monthKey: '2026-07',
          isSyncing: false,
          expenseCount: 5,
        );

        expect(
          decideWrappedTrigger(profile: profile, summary: summary),
          WrappedTriggerResult.autoShow,
        );
      },
    );

    test('offerSuppressedCard when the previous month is unseen with 1-4 '
        'expenses', () {
      const profile = UserProfile(
        uid: 'u1',
        timeZone: 'America/Mexico_City',
      );
      final summary = _summary(
        monthKey: '2026-07',
        isSyncing: false,
        expenseCount: 3,
      );

      expect(
        decideWrappedTrigger(profile: profile, summary: summary),
        WrappedTriggerResult.offerSuppressedCard,
      );
    });

    test('none when the month has zero expenses', () {
      const profile = UserProfile(
        uid: 'u1',
        timeZone: 'America/Mexico_City',
      );
      final summary = _summary(
        monthKey: '2026-07',
        isSyncing: false,
        expenseCount: 0,
      );

      expect(
        decideWrappedTrigger(profile: profile, summary: summary),
        WrappedTriggerResult.none,
      );
    });

    test('none when the month was already marked seen', () {
      const profile = UserProfile(
        uid: 'u1',
        timeZone: 'America/Mexico_City',
        wrappedLastSeenMonth: '2026-07',
      );
      final summary = _summary(
        monthKey: '2026-07',
        isSyncing: false,
        expenseCount: 20,
      );

      expect(
        decideWrappedTrigger(profile: profile, summary: summary),
        WrappedTriggerResult.none,
      );
    });

    test('none when the summary is still syncing, regardless of count', () {
      const profile = UserProfile(
        uid: 'u1',
        timeZone: 'America/Mexico_City',
      );
      final summary = _summary(
        monthKey: '2026-07',
        isSyncing: true,
        expenseCount: 20,
      );

      expect(
        decideWrappedTrigger(profile: profile, summary: summary),
        WrappedTriggerResult.none,
      );
    });

    test('exactly 5 expenses meets the auto-show threshold', () {
      const profile = UserProfile(
        uid: 'u1',
        timeZone: 'America/Mexico_City',
      );
      final summary = _summary(
        monthKey: '2026-07',
        isSyncing: false,
        expenseCount: 5,
      );

      expect(
        decideWrappedTrigger(profile: profile, summary: summary),
        WrappedTriggerResult.autoShow,
      );
    });
  });

  group('previousMonthKey', () {
    test('returns the prior calendar month, zero-padded', () {
      expect(previousMonthKey(DateTime(2026, 8, 12)), '2026-07');
    });

    test('rolls back across a year boundary', () {
      expect(previousMonthKey(DateTime(2026, 1, 15)), '2025-12');
    });
  });
}
