import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Exchanges an interactive Apple sign-in for a Firebase [AuthCredential].
/// Isolated from `FirebaseAuthRepository` the same way
/// `GoogleSignInCredentialProvider` is — see `research.md` #8.
@lazySingleton
class AppleSignInCredentialProvider {
  /// Runs the interactive Apple sign-in flow and returns a credential ready
  /// for `FirebaseAuth.linkWithCredential`/`signInWithCredential`. Uses a
  /// nonce, per Firebase's documented Apple sign-in recipe, to bind the
  /// Apple authorization to this specific Firebase auth attempt.
  Future<AuthCredential> obtainCredential() async {
    final rawNonce = _generateNonce();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: _sha256OfString(rawNonce),
    );
    final identityToken = credential.identityToken;
    if (identityToken == null) {
      throw StateError('Apple sign-in did not return an identity token.');
    }
    return OAuthProvider('apple.com').credential(
      idToken: identityToken,
      rawNonce: rawNonce,
    );
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256OfString(String input) =>
      sha256.convert(utf8.encode(input)).toString();
}
