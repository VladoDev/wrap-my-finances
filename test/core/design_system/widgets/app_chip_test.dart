import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/core/design_system/widgets/app_chip.dart';

import '../../../support/longest_labels.dart';

// Guards FR-013 (US6): AppChip — the tightest text box of the four
// primitives (see data-model.md) — must survive its longest translated
// label at 200% text scale without clipping or overflow. Guards US7/FR-014:
// at least one golden test per primitive, in the light color scheme.
void main() {
  // goldenTest registers the test synchronously; the returned Future
  // resolves only after the test runs, so it is intentionally not awaited
  // ignore: discarded_futures
  goldenTest(
    'renders each variant in the light color scheme',
    fileName: 'app_chip',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'neutral',
          child: const AppChip(label: 'Tag'),
        ),
        GoldenTestScenario(
          name: 'primary',
          child: const AppChip(label: 'Tag', variant: AppChipVariant.primary),
        ),
        GoldenTestScenario(
          name: 'secondary',
          child: const AppChip(
            label: 'Tag',
            variant: AppChipVariant.secondary,
          ),
        ),
      ],
    ),
  );

  testWidgets(
    'AppChip renders the longest translated label at 200% scale, no overflow',
    (tester) async {
      final longestLabel = longestLabelFor('commonRetry');

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SizedBox(width: 220, child: AppChip(label: longestLabel)),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(longestLabel), findsOneWidget);
    },
  );
}
