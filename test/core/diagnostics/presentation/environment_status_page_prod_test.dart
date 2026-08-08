import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/config/app_environment.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/core/diagnostics/presentation/pages/environment_status_page.dart';

void main() {
  testWidgets(
    'shows no debug banner and no write-probe control when '
    'AppEnvironment.prod is active',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appEnvironmentProvider.overrideWithValue(AppEnvironment.prod),
          ],
          child: const MaterialApp(home: EnvironmentStatusPage()),
        ),
      );

      expect(find.byKey(const Key('debug-banner')), findsNothing);
      expect(find.byKey(const Key('write-probe-button')), findsNothing);
      expect(find.text('Environment: prod'), findsOneWidget);
    },
  );
}
