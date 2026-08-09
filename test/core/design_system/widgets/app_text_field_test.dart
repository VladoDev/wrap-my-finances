import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/core/design_system/widgets/app_text_field.dart';

import '../../../support/longest_labels.dart';

// Guards FR-013 (US6): AppTextField must survive its longest translated
// label/hint/errorText at 200% text scale without clipping or overflow.
// Guards US7/FR-014: at least one golden test per primitive, in the light
// color scheme.
void main() {
  // goldenTest registers the test synchronously; the returned Future
  // resolves only after the test runs, so it is intentionally not awaited
  // ignore: discarded_futures
  goldenTest(
    'renders empty, filled, and error states in the light color scheme',
    fileName: 'app_text_field',
    builder: () => GoldenTestGroup(
      // AppTextField is a block-level input meant to fill available width,
      // not size to its content — the default scenario column would clip
      // it, which is not representative of real usage.
      scenarioConstraints: const BoxConstraints.tightFor(width: 220),
      children: [
        GoldenTestScenario(
          name: 'empty',
          child: const AppTextField(label: 'Label'),
        ),
        GoldenTestScenario(
          name: 'with hint',
          child: const AppTextField(label: 'Label', hint: 'Hint text'),
        ),
        GoldenTestScenario(
          name: 'with error',
          child: const AppTextField(
            label: 'Label',
            errorText: 'Required field',
          ),
        ),
      ],
    ),
  );

  testWidgets(
    'AppTextField renders long translated label/hint/error at 200% scale, '
    'no overflow',
    (tester) async {
      final longestLabel = longestLabelFor('commonContinue');
      final longestHint = longestLabelFor('commonCancel');
      final longestError = longestLabelFor('commonDelete');

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SizedBox(
                width: 220,
                child: AppTextField(
                  label: longestLabel,
                  hint: longestHint,
                  errorText: longestError,
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(longestError), findsOneWidget);
    },
  );
}
