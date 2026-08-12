import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/widgets/wrapped_share_card.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

void main() {
  testWidgets(
    'the RepaintBoundary capture path renders at 3x pixel ratio and hands '
    'off PNG bytes',
    (tester) async {
      Uint8List? capturedBytes;

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

      await tester.pumpWidget(
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
              shareImageBytes: (bytes) async => capturedBytes = bytes,
            ),
          ),
        ),
      );

      await tester.runAsync(() async {
        await tester.tap(find.text('Share'));
        // toImage()/toByteData() are real async Skia work even under
        // runAsync — give them genuine time to complete rather than a
        // single fake-clock pump.
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      expect(capturedBytes, isNotNull);
      expect(capturedBytes!.isNotEmpty, isTrue);
      // A PNG file signature — confirms real image bytes, not a stub.
      expect(capturedBytes!.sublist(0, 8), [
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]);
    },
  );

  test('wrappedShareCardPixelRatio is 3, per docs/UI_UX_SPEC.md §3', () {
    expect(wrappedShareCardPixelRatio, 3);
  });
}
