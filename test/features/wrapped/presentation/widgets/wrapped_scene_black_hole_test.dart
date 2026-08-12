import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/widgets/wrapped_scene_black_hole.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
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
            body: WrappedSceneBlackHole(
              topCategoryId: topCategoryId,
              topCategory: topCategory,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders the resolved category name', (tester) async {
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

    await pump(tester, topCategoryId: category.id, topCategory: category);

    expect(find.textContaining('Food'), findsOneWidget);
  });

  testWidgets(
    'renders the current name after a simulated rename (resolution happens '
    'at display time, not from stored data)',
    (tester) async {
      final renamed = Category(
        id: 'cat_9f2ac1',
        name: 'Side Hustle',
        color: '#00BFA5',
        iconName: 'briefcase',
        isDefault: false,
        sortOrder: 12,
        isActive: true,
        usageCount: 3,
      );

      await pump(tester, topCategoryId: renamed.id, topCategory: renamed);

      expect(find.textContaining('Side Hustle'), findsOneWidget);
    },
  );

  testWidgets('falls back gracefully when the category cannot be resolved', (
    tester,
  ) async {
    await pump(tester, topCategoryId: 'cat_unknown');

    expect(find.textContaining('cat_unknown'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
