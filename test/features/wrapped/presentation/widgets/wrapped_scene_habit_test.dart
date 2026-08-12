import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/widgets/wrapped_scene_habit.dart';
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

  Future<void> pump(
    WidgetTester tester, {
    required int topCategoryExpenseCount,
    String? topCategoryId,
    Category? topCategory,
  }) {
    return tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WrappedSceneHabit(
              topCategoryExpenseCount: topCategoryExpenseCount,
              topCategoryId: topCategoryId,
              topCategory: topCategory,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders the top category transaction count, not the '
      "month's total count", (tester) async {
    await pump(
      tester,
      topCategoryExpenseCount: 12,
      topCategoryId: category.id,
      topCategory: category,
    );

    expect(find.textContaining('12'), findsOneWidget);
    expect(find.textContaining('Food'), findsOneWidget);
  });
}
