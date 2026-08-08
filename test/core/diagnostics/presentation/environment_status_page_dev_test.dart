import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/config/app_environment.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/core/diagnostics/presentation/pages/environment_status_page.dart';

void main() {
  testWidgets(
    'shows the debug banner and the write-probe control when '
    'AppEnvironment.dev is active',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appEnvironmentProvider.overrideWithValue(AppEnvironment.dev),
          ],
          child: const MaterialApp(home: EnvironmentStatusPage()),
        ),
      );

      expect(find.byKey(const Key('debug-banner')), findsOneWidget);
      expect(find.byKey(const Key('write-probe-button')), findsOneWidget);
      expect(find.text('Environment: dev'), findsOneWidget);
    },
  );
}
