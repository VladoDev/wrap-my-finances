import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/categories/presentation/category_icon_map.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/expenses/presentation/widgets/history_entry_tile.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

void main() {
  final expense = Expense(
    id: 'exp_1',
    amount: const Money(minorUnits: 15099, currencyCode: 'MXN'),
    categoryId: 'cat_food',
    date: DateTime(2026, 8, 10, 14, 30),
    createdAt: DateTime(2026, 8, 10, 14, 30),
  );
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

  Future<void> pump(WidgetTester tester, {Category? withCategory}) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HistoryEntryTile(expense: expense, category: withCategory),
        ),
      ),
    );
  }

  testWidgets('renders amount, resolved category name, and icon', (
    tester,
  ) async {
    await pump(tester, withCategory: category);

    expect(find.text('150.99'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.byIcon(resolveCategoryIcon('restaurant')), findsOneWidget);
  });

  testWidgets('category remains identifiable when rendered without color', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          invertColors: true,
        ), // proxy for "not relying on hue"
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HistoryEntryTile(expense: expense, category: category),
          ),
        ),
      ),
    );

    // Text label and icon are both still present regardless of color
    // rendering — neither depends on the category's swatch color.
    expect(find.text('Food'), findsOneWidget);
    expect(find.byIcon(resolveCategoryIcon('restaurant')), findsOneWidget);
  });

  testWidgets('falls back gracefully when the category cannot be resolved', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('cat_food'), findsOneWidget);
    expect(find.byIcon(categoryIconFallback), findsOneWidget);
  });
}
