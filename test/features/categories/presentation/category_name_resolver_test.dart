import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/features/categories/data/default_categories.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/categories/presentation/category_name_resolver.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

const _supportedLocales = ['en', 'es', 'pt', 'it', 'fr'];

Category _defaultCategory(String nameKey) {
  return Category(
    id: 'cat_test',
    nameKey: nameKey,
    color: '#FFB84C',
    iconName: 'category',
    isDefault: true,
    sortOrder: 1,
    isActive: true,
    usageCount: 0,
  );
}

Future<String> _resolve(
  WidgetTester tester,
  String locale,
  String nameKey,
) async {
  late String resolved;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          resolved = resolveCategoryName(context, _defaultCategory(nameKey));
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return resolved;
}

void main() {
  testWidgets('a user category returns its literal name, ignoring nameKey', (
    tester,
  ) async {
    final category = Category(
      id: 'cat_user',
      name: 'Side Hustle',
      color: '#FFB84C',
      iconName: 'category',
      isDefault: false,
      sortOrder: 1,
      isActive: true,
      usageCount: 0,
    );
    late String resolved;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            resolved = resolveCategoryName(context, category);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(resolved, 'Side Hustle');
  });

  for (final locale in _supportedLocales) {
    testWidgets(
      'every seeded nameKey resolves to a non-empty string under locale '
      '$locale',
      (tester) async {
        for (final seed in defaultCategorySeeds) {
          final resolved = await _resolve(tester, locale, seed.nameKey);
          expect(resolved, isNotEmpty);
        }
      },
    );
  }

  testWidgets('an unrecognized nameKey throws ArgumentError', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            expect(
              () => resolveCategoryName(
                context,
                _defaultCategory('category_bogus'),
              ),
              throwsArgumentError,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
