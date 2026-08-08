// Drives the real app against the live wrap-my-finances-dev Firebase
// project (not a fake) to verify quickstart.md step 4 end-to-end: tapping
// "Write test document" succeeds and shows the written document's ID.
//
// Run with: flutter test integration_test/environment_probe_test.dart -d <device>
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wrap_my_finances/app.dart';
import 'package:wrap_my_finances/core/config/app_environment.dart';
import 'package:wrap_my_finances/core/config/firebase_options_dev.dart';
import 'package:wrap_my_finances/core/di/injection.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'writing a probe document from the running dev app succeeds',
    (tester) async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      await configureDependencies(AppEnvironment.dev);

      await tester.pumpWidget(const ProviderScope(child: App()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('write-probe-button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('write-probe-button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final resultText = tester
          .widget<Text>(find.byKey(const Key('probe-result-text')))
          .data;
      // Surfaces the written doc ID in `flutter test` output for manual
      // cross-checking against the Firebase console.
      // ignore: avoid_print
      print('PROBE_RESULT: $resultText');

      expect(resultText, startsWith('Wrote probe '));
    },
  );
}
