import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/categories/domain/repositories/category_repository.dart';
import 'package:wrap_my_finances/features/settings/presentation/widgets/category_editor_sheet.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late _MockCategoryRepository categoryRepository;

  setUpAll(() {
    registerFallbackValue(
      Category(
        id: 'fallback',
        name: 'fallback',
        color: '#FFFFFF',
        iconName: 'category',
        isDefault: false,
        sortOrder: 1,
        isActive: true,
        usageCount: 0,
      ),
    );
  });

  setUp(() {
    categoryRepository = _MockCategoryRepository();
  });

  Future<void> pump(WidgetTester tester, {Category? category}) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(categoryRepository),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CategoryEditorSheet(category: category)),
        ),
      ),
    );
  }

  testWidgets(
    'create mode: entering a name and confirming calls '
    'CategoryRepository.create with the typed name and the pre-selected '
    'color/icon',
    (tester) async {
      when(
        () => categoryRepository.create(
          name: any(named: 'name'),
          color: any(named: 'color'),
          iconName: any(named: 'iconName'),
        ),
      ).thenAnswer(
        (_) async => Success(
          Category(
            id: 'cat_new',
            name: 'Side Hustle',
            color: '#FFFFFF',
            iconName: 'restaurant',
            isDefault: false,
            sortOrder: 1,
            isActive: true,
            usageCount: 0,
          ),
        ),
      );

      await pump(tester);

      await tester.enterText(find.byType(TextField), 'Side Hustle');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final captured = verify(
        () => categoryRepository.create(
          name: captureAny(named: 'name'),
          color: captureAny(named: 'color'),
          iconName: captureAny(named: 'iconName'),
        ),
      ).captured;
      expect(captured[0], 'Side Hustle');
      expect(captured[1], isA<String>());
      expect(captured[2], isA<String>());
    },
  );

  testWidgets(
    'edit mode: pre-fills the existing name/color/icon, and confirming '
    'without changes calls update with the same values',
    (tester) async {
      final existing = Category(
        id: 'cat_food',
        name: 'Groceries',
        color: '#FFB84C',
        iconName: 'restaurant',
        isDefault: false,
        sortOrder: 1,
        isActive: true,
        usageCount: 0,
      );
      when(
        () => categoryRepository.update(
          any(),
          name: any(named: 'name'),
          color: any(named: 'color'),
          iconName: any(named: 'iconName'),
        ),
      ).thenAnswer((_) async => const Success(null));

      await pump(tester, category: existing);

      expect(find.text('Groceries'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      verify(
        () => categoryRepository.update(
          'cat_food',
          name: 'Groceries',
          color: '#FFB84C',
          iconName: 'restaurant',
        ),
      ).called(1);
    },
  );

  testWidgets(
    'recoloring: tapping a different swatch, then confirming, sends the '
    "new swatch's hex, not the original color",
    (tester) async {
      final existing = Category(
        id: 'cat_food',
        name: 'Groceries',
        color: '#FFB84C',
        iconName: 'restaurant',
        isDefault: false,
        sortOrder: 1,
        isActive: true,
        usageCount: 0,
      );
      when(
        () => categoryRepository.update(
          any(),
          name: any(named: 'name'),
          color: any(named: 'color'),
          iconName: any(named: 'iconName'),
        ),
      ).thenAnswer((_) async => const Success(null));

      await pump(tester, category: existing);

      // Tap a swatch other than the first (the pre-selected one is
      // whichever matches the category's own color, not necessarily the
      // first in the palette).
      final swatches = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
      );
      await tester.tap(swatches.last);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final captured = verify(
        () => categoryRepository.update(
          'cat_food',
          name: 'Groceries',
          color: captureAny(named: 'color'),
          iconName: 'restaurant',
        ),
      ).captured;
      expect(captured.single, isNot('#FFB84C'));
    },
  );

  testWidgets(
    're-iconing: tapping a different icon, then confirming, sends the new '
    "icon's key, not the original",
    (tester) async {
      final existing = Category(
        id: 'cat_food',
        name: 'Groceries',
        color: '#FFB84C',
        iconName: 'restaurant',
        isDefault: false,
        sortOrder: 1,
        isActive: true,
        usageCount: 0,
      );
      when(
        () => categoryRepository.update(
          any(),
          name: any(named: 'name'),
          color: any(named: 'color'),
          iconName: any(named: 'iconName'),
        ),
      ).thenAnswer((_) async => const Success(null));

      await pump(tester, category: existing);

      await tester.tap(find.byIcon(Icons.movie));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      verify(
        () => categoryRepository.update(
          'cat_food',
          name: 'Groceries',
          color: '#FFB84C',
          iconName: 'movie',
        ),
      ).called(1);
    },
  );
}
