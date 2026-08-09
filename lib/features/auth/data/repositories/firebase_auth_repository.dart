import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:wrap_my_finances/features/auth/domain/repositories/auth_repository.dart';

/// [AuthRepository] over [FirebaseAuth]. `runWhenAuthenticated`'s buffering
/// is a memoized, shared [Future]: every caller that arrives before sign-in
/// resolves awaits the same in-flight sign-in attempt and each proceeds, in
/// registration order, the moment it resolves — no hand-rolled queue is
/// needed for the ordering guarantee FR-004/FR-005 ask for. See
/// `research.md`.
@LazySingleton(as: AuthRepository)
class FirebaseAuthRepository implements AuthRepository {
  /// Creates the repository over the injected [FirebaseAuth] singleton.
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  Future<String>? _pendingSignIn;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<String> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing.uid;

    _pendingSignIn ??= _signIn();
    try {
      return await _pendingSignIn!;
    } catch (_) {
      // Allow a later call to retry rather than permanently caching a
      // failed attempt (e.g. no connectivity at first launch).
      _pendingSignIn = null;
      rethrow;
    }
  }

  Future<String> _signIn() async {
    final credential = await _auth.signInAnonymously();
    return credential.user!.uid;
  }

  @override
  Future<T> runWhenAuthenticated<T>(
    Future<T> Function(String uid) operation,
  ) async {
    final uid = await ensureSignedIn();
    return operation(uid);
  }
}
