import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/features/categories/data/default_categories.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/categories/presentation/category_icon_map.dart';
import 'package:wrap_my_finances/features/expenses/presentation/widgets/category_picker_sheet.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

import '../../../../support/longest_labels.dart';

void main() {
  testWidgets(
    "renders each tile's resolved display name (never the raw nameKey) and "
    'its mapped icon',
    (tester) async {
      final categories = [
        Category(
          id: 'cat_food',
          nameKey: 'category_food',
          color: '#FFB84C',
          iconName: 'restaurant',
          isDefault: true,
          sortOrder: 1,
          isActive: true,
          usageCount: 3,
        ),
        Category(
          id: 'cat_custom',
          name: 'Side Hustle',
          color: '#06D6A0',
          iconName: 'briefcase',
          isDefault: false,
          sortOrder: 2,
          isActive: true,
          usageCount: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CategoryPickerSheet(
              categories: categories,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('category_food'), findsNothing);
      expect(find.text('Side Hustle'), findsOneWidget);
      expect(find.byIcon(resolveCategoryIcon('restaurant')), findsOneWidget);
      // 'briefcase' is not in the icon map — falls back to the default icon.
      expect(find.byIcon(categoryIconFallback), findsOneWidget);
    },
  );

  testWidgets(
    "holds every seeded category's longest translated label at 200% text "
    'scale without clipping (docs/UI_UX_SPEC.md §7)',
    (tester) async {
      final categories = [
        for (final seed in defaultCategorySeeds)
          Category(
            id: 'cat_${seed.nameKey}',
            nameKey: seed.nameKey,
            color: '#FFB84C',
            iconName: seed.iconName,
            isDefault: true,
            sortOrder: seed.sortOrder,
            isActive: true,
            usageCount: 0,
          ),
      ];
      // 'categoryFood' just anchors the message key prefix used by every
      // category-name ARB key below.
      final longestLabels = [
        'categoryFood',
        'categoryTransport',
        'categoryShopping',
        'categoryEntertainment',
        'categoryHealth',
        'categoryHousing',
        'categoryOther',
      ].map(longestLabelFor);
      final worstCase = longestLabels.reduce(
        (a, b) => a.length >= b.length ? a : b,
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CategoryPickerSheet(
                categories: categories,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(worstCase, isNotEmpty);
    },
  );
}
