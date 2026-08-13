import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:wrap_my_finances/core/config/app_environment.dart';

/// The App Check provider pair to activate for [env]: Play Integrity/App
/// Attest for `prod`, the debug providers for `dev` — never the other way
/// around, since a debug token must never be registered against `prod`
/// (`research.md` #4). A pure function, deliberately separated from the
/// real `FirebaseAppCheck.instance.activate(...)` call in `bootstrap.dart`
/// so the selection itself is unit-testable without touching Firebase.
({AndroidAppCheckProvider android, AppleAppCheckProvider apple})
appCheckProvidersFor(AppEnvironment env) {
  return switch (env) {
    AppEnvironment.dev => (
      android: const AndroidDebugProvider(),
      apple: const AppleDebugProvider(),
    ),
    AppEnvironment.prod => (
      android: const AndroidPlayIntegrityProvider(),
      apple: const AppleAppAttestProvider(),
    ),
  };
}
