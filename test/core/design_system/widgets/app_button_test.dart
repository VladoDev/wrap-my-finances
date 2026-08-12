import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/core/design_system/widgets/app_button.dart';

import '../../../support/longest_labels.dart';

// Guards FR-013 (US6): AppButton must survive its longest translated label
// at 200% text scale without clipping or overflow. Guards US7/FR-014: at
// least one golden test per primitive, in the light color scheme.
void main() {
  // goldenTest registers the test synchronously; the returned Future
  // resolves only after the test runs, so it is intentionally not awaited
  // ignore: discarded_futures
  goldenTest(
    'renders each variant in the light color scheme',
    fileName: 'app_button',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'primary',
          child: AppButton(label: 'Continue', onPressed: () {}),
        ),
        GoldenTestScenario(
          name: 'secondary',
          child: AppButton(
            label: 'Cancel',
            onPressed: () {},
            variant: AppButtonVariant.secondary,
          ),
        ),
        GoldenTestScenario(
          name: 'danger',
          child: AppButton(
            label: 'Delete',
            onPressed: () {},
            variant: AppButtonVariant.danger,
          ),
        ),
        GoldenTestScenario(
          name: 'disabled',
          child: const AppButton(label: 'Continue', onPressed: null),
        ),
      ],
    ),
  );

  testWidgets(
    'AppButton renders the longest translated label at 200% scale, no overflow',
    (tester) async {
      final longestLabel = longestLabelFor('commonContinue');

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SizedBox(
                width: 200,
                child: AppButton(label: longestLabel, onPressed: () {}),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(longestLabel), findsOneWidget);
    },
  );
}
