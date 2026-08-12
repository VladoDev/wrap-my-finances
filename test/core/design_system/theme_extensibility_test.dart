import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/tokens/app_colors.dart';
import 'package:wrap_my_finances/core/design_system/tokens/app_spacing.dart';
import 'package:wrap_my_finances/core/design_system/tokens/app_typography.dart';
import 'package:wrap_my_finances/core/design_system/widgets/app_button.dart';
import 'package:wrap_my_finances/core/design_system/widgets/app_card.dart';
import 'package:wrap_my_finances/core/design_system/widgets/app_chip.dart';
import 'package:wrap_my_finances/core/design_system/widgets/app_text_field.dart';

// Guards FR-007/FR-008: a future dark scheme must be addable as one more
// ThemeExtension instance, with zero changes to any primitive's source
// file. This test proves that by swapping in a throwaway, test-only
// AppColorsExtension instance and asserting every shipped primitive
// renders its values — no primitive file is imported for edit, only for
// use. See research.md.
const _alternateColors = AppColorsExtension(
  background: Color(0xFF000011),
  onBackground: Color(0xFFFFFFFF),
  surface: Color(0xFF000022),
  onSurface: Color(0xFFFFFFFF),
  primary: Color(0xFF00FF00),
  onPrimary: Color(0xFF000000),
  secondary: Color(0xFFFF00FF),
  onSecondary: Color(0xFF000000),
  danger: Color(0xFF0000FF),
  onDanger: Color(0xFFFFFFFF),
  outline: Color(0xFFFFFFFF),
  categoryPalette: [
    Color(0xFF111111),
    Color(0xFF222222),
    Color(0xFF333333),
    Color(0xFF444444),
    Color(0xFF555555),
    Color(0xFF666666),
    Color(0xFF777777),
  ],
);

ThemeData _alternateTheme() {
  return ThemeData(
    useMaterial3: true,
    extensions: <ThemeExtension<dynamic>>[
      _alternateColors,
      AppTypographyExtension.standard,
      AppSpacingExtension.standard,
    ],
  );
}

void main() {
  testWidgets('AppButton renders the swapped-in AppColorsExtension instance', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _alternateTheme(),
        home: Scaffold(
          body: AppButton(label: 'Continue', onPressed: () {}),
        ),
      ),
    );

    final material = tester
        .widgetList<Material>(
          find.descendant(
            of: find.byType(AppButton),
            matching: find.byType(Material),
          ),
        )
        .first;
    expect(material.color, _alternateColors.primary);
  });

  testWidgets('AppCard renders the swapped-in AppColorsExtension instance', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _alternateTheme(),
        home: const Scaffold(
          body: AppCard(title: 'Title', body: 'Body'),
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, _alternateColors.surface);
  });

  testWidgets('AppChip renders the swapped-in AppColorsExtension instance', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _alternateTheme(),
        home: const Scaffold(body: AppChip(label: 'Tag')),
      ),
    );

    final chip = tester.widget<Chip>(find.byType(Chip));
    expect(chip.backgroundColor, _alternateColors.surface);
  });

  testWidgets(
    'AppTextField renders the swapped-in AppColorsExtension instance',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: _alternateTheme(),
          home: const Scaffold(body: AppTextField(label: 'Label')),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      final border = field.decoration!.enabledBorder! as OutlineInputBorder;
      expect(border.borderSide.color, _alternateColors.outline);
    },
  );
}
