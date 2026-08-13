import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

/// Exchanges an interactive Google sign-in for a Firebase [AuthCredential].
/// Isolated from `FirebaseAuthRepository` so the exact `google_sign_in:
/// ^7.2.0` call shape (`GoogleSignIn.instance`, `authenticate()`,
/// synchronous `.authentication.idToken` — a redesign from older
/// `signIn()`-based APIs, see `research.md` #8) lives in one place and the
/// repository's own tests can substitute a fake instead of exercising
/// platform channels.
@lazySingleton
class GoogleSignInCredentialProvider {
  Future<void>? _initialization;

  /// Runs the interactive Google sign-in flow and returns a credential
  /// ready for `FirebaseAuth.linkWithCredential`/`signInWithCredential`.
  Future<AuthCredential> obtainCredential() async {
    // `initialize` must be called exactly once per process, per the
    // package's own contract — memoized the same way `FirebaseAuthRepository`
    // memoizes `_pendingSignIn`.
    _initialization ??= GoogleSignIn.instance.initialize();
    await _initialization;

    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google sign-in did not return an ID token.');
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }
}
