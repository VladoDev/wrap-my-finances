/// Session/identity contract every future write-triggering use case depends
/// on instead of handling sign-in timing itself. See
/// `specs/003-auth-domain-foundation/contracts/auth-api.md`.
abstract class AuthRepository {
  /// The resolved UID, or `null` if sign-in hasn't completed yet. Never
  /// blocks.
  String? get currentUserId;

  /// Resolves once a UID exists — immediately if already signed in,
  /// otherwise after sign-in completes.
  Future<String> ensureSignedIn();

  /// Runs [operation] immediately if a UID already exists; otherwise defers
  /// it until sign-in resolves, then runs it. This is the buffer
  /// Constitution Principle 2 and `docs/ARCHITECTURE.md` describe — see
  /// `research.md`.
  Future<T> runWhenAuthenticated<T>(Future<T> Function(String uid) operation);
}
