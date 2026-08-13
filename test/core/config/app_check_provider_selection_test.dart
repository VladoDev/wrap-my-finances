import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/config/app_check_provider_selection.dart';
import 'package:wrap_my_finances/core/config/app_environment.dart';

void main() {
  test('dev resolves to the debug Android/Apple providers', () {
    final result = appCheckProvidersFor(AppEnvironment.dev);

    expect(result.android, isA<AndroidDebugProvider>());
    expect(result.apple, isA<AppleDebugProvider>());
  });

  test('prod resolves to Play Integrity/App Attest', () {
    final result = appCheckProvidersFor(AppEnvironment.prod);

    expect(result.android, isA<AndroidPlayIntegrityProvider>());
    expect(result.apple, isA<AppleAppAttestProvider>());
  });
}
