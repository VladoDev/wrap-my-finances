import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/core/design_system/widgets/app_card.dart';

import '../../../support/longest_labels.dart';

// Guards FR-013 (US6): AppCard must survive its longest translated
// title/body text at 200% text scale without clipping or overflow. Guards
// US7/FR-014: at least one golden test per primitive, in the light scheme.
void main() {
  // goldenTest registers the test synchronously; the returned Future
  // resolves only after the test runs, so it is intentionally not awaited
  // ignore: discarded_futures
  goldenTest(
    'renders title+body and child-only in the light color scheme',
    fileName: 'app_card',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'title and body',
          child: const AppCard(title: 'Title', body: 'Body text goes here.'),
        ),
        GoldenTestScenario(
          name: 'child only',
          child: const AppCard(child: Icon(Icons.check_circle, size: 32)),
        ),
      ],
    ),
  );

  testWidgets(
    'AppCard renders long translated title/body at 200% text scale without overflow',
    (tester) async {
      final longestTitle = longestLabelFor('commonRetry');
      final longestBody = longestLabelFor('commonDelete');

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SizedBox(
                width: 220,
                child: AppCard(title: longestTitle, body: longestBody),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(longestTitle), findsOneWidget);
      expect(find.text(longestBody), findsOneWidget);
    },
  );
}
