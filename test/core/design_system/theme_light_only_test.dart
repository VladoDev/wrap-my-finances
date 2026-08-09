import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/core/design_system/widgets/app_button.dart';
import 'package:wrap_my_finances/core/design_system/widgets/app_card.dart';

// Guards FR-005/FR-006: the app is pinned to ThemeMode.light and must never
// react to the platform's brightness setting.
void main() {
  Future<Color?> pumpAndGetButtonColor(
    WidgetTester tester,
    Brightness platformBrightness,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(platformBrightness: platformBrightness),
        child: MaterialApp(
          theme: AppTheme.light,
          themeMode: AppTheme.themeMode,
          home: const Scaffold(
            body: Column(
              children: [
                AppButton(label: 'Continue', onPressed: null),
                AppCard(title: 'Title', body: 'Body'),
              ],
            ),
          ),
        ),
      ),
    );

    final buttonMaterial = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(AppButton),
            matching: find.byType(Material),
          )
          .first,
    );
    return buttonMaterial.color;
  }

  testWidgets(
    'AppButton renders the same color under dark and light platform brightness',
    (tester) async {
      final darkColor = await pumpAndGetButtonColor(tester, Brightness.dark);
      final lightColor = await pumpAndGetButtonColor(tester, Brightness.light);

      expect(darkColor, equals(lightColor));
    },
  );

  testWidgets(
    'MaterialApp resolves ThemeData.brightness to light regardless of platform',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: MaterialApp(
            theme: AppTheme.light,
            themeMode: AppTheme.themeMode,
            home: const Scaffold(body: SizedBox()),
          ),
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      expect(Theme.of(context).brightness, Brightness.light);
    },
  );
}
