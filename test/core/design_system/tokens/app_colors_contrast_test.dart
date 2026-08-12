import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/tokens/app_colors.dart';

import '../../../support/wcag_contrast.dart';

// Guards FR-009/SC-004 (US5): every text/background pair the color tokens
// declare meets its documented WCAG AA threshold, verified by a calculated
// ratio rather than a visual check. See data-model.md's color token table
// for the pairing/threshold rationale — onDanger/danger is intentionally
// checked against the large-text threshold only, never the normal-text one.
void main() {
  const colors = AppColorsExtension.light;

  final normalTextPairs = {
    'onBackground/background': (colors.onBackground, colors.background),
    'onSurface/surface': (colors.onSurface, colors.surface),
    'onPrimary/primary': (colors.onPrimary, colors.primary),
    'onSecondary/secondary': (colors.onSecondary, colors.secondary),
  };

  final largeTextPairs = {'onDanger/danger': (colors.onDanger, colors.danger)};

  for (final entry in normalTextPairs.entries) {
    test('${entry.key} meets WCAG AA for normal text (>= 4.5:1)', () {
      final (fg, bg) = entry.value;
      final ratio = contrastRatio(fg, bg);
      expect(
        ratio,
        greaterThanOrEqualTo(wcagAaNormalText),
        reason: '${entry.key} ratio was ${ratio.toStringAsFixed(2)}:1',
      );
    });
  }

  for (final entry in largeTextPairs.entries) {
    test(
      '${entry.key} meets WCAG AA for large text/UI components (>= 3:1)',
      () {
        final (fg, bg) = entry.value;
        final ratio = contrastRatio(fg, bg);
        expect(
          ratio,
          greaterThanOrEqualTo(wcagAaLargeText),
          reason: '${entry.key} ratio was ${ratio.toStringAsFixed(2)}:1',
        );
      },
    );
  }
}
