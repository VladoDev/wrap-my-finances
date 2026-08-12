import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/widgets/wrapped_share_card.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

void main() {
  final category = Category(
    id: 'cat_food',
    nameKey: 'category_food',
    color: '#FFB84C',
    iconName: 'restaurant',
    isDefault: true,
    sortOrder: 1,
    isActive: true,
    usageCount: 3,
  );

  Future<void> pump(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: WrappedShareCard(
            monthKey: '2026-07',
            topCategoryId: category.id,
            topCategory: category,
            topCategoryExpenseCount: 12,
            total: const Money(minorUnits: 150000, currencyCode: 'MXN'),
          ),
        ),
      ),
    );
  }

  testWidgets('by default renders category, count, and month — no '
      'monetary figure anywhere', (tester) async {
    await pump(tester);

    expect(find.textContaining('Food'), findsWidgets);
    expect(find.textContaining('12'), findsOneWidget);
    expect(find.textContaining('1,500.00'), findsNothing);
  });

  testWidgets('activating the amounts toggle reveals the total', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byType(Switch), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(find.textContaining('1,500.00'), findsOneWidget);
  });

  testWidgets('the card content is sized for a 9:16 aspect ratio', (
    tester,
  ) async {
    await pump(tester);

    final aspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
    expect(aspectRatio.aspectRatio, closeTo(9 / 16, 0.001));
  });
}
