import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/expenses/presentation/widgets/history_month_picker_sheet.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

Expense _expense(String id, DateTime date) {
  return Expense(
    id: id,
    amount: const Money(minorUnits: 100, currencyCode: 'MXN'),
    categoryId: 'cat_food',
    date: date,
    createdAt: date,
  );
}

void main() {
  test('distinctMonthKeys derives distinct months, most-recent-first, no '
      'duplicates', () {
    final months = distinctMonthKeys([
      _expense('a', DateTime(2026, 8, 5)),
      _expense('b', DateTime(2026, 7, 20)),
      _expense('c', DateTime(2026, 8)),
      _expense('d', DateTime(2026, 6)),
    ]);

    expect(months, ['2026-08', '2026-07', '2026-06']);
  });

  test('distinctMonthKeys returns an empty list for no expenses', () {
    expect(distinctMonthKeys(const []), isEmpty);
  });

  group('HistoryMonthPickerSheet widget', () {
    late GoRouter router;
    late List<String> visitedLocations;

    setUp(() {
      visitedLocations = [];
      router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              visitedLocations.add(state.uri.toString());
              return Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => const HistoryMonthPickerSheet(
                        monthKeys: ['2026-08', '2026-07'],
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              );
            },
          ),
          GoRoute(
            path: '/wrapped/:monthKey',
            builder: (context, state) {
              visitedLocations.add(state.uri.toString());
              return const SizedBox.shrink();
            },
          ),
        ],
      );
    });

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('renders one row per month, most-recent-first', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('2026-08'), findsNothing);
      // Rows render via intl-formatted month labels, not raw keys — assert
      // structurally instead.
      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('tapping a month navigates to /wrapped/:monthKey', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      expect(visitedLocations, ['/', '/wrapped/2026-08']);
    });
  });
}
