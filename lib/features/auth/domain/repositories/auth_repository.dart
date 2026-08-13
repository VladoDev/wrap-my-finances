import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_conflict.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_conflict_resolution.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_result.dart';

/// Session/identity contract every future write-triggering use case depends
/// on instead of handling sign-in timing itself. See
/// `specs/003-auth-domain-foundation/contracts/auth-api.md` and
/// `specs/007-account-linking-integrity/contracts/auth-linking-api.md`.
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

  /// Whether the current session has a Google or Apple provider attached.
  /// `false` for a purely anonymous session.
  bool get isLinked;

  /// Which provider (e.g. "Google", "Apple") the current session is linked
  /// to, for display only — `null` exactly when [isLinked] is `false`.
  String? get linkedProviderLabel;

  /// Attempts to link the current anonymous session to a Google account.
  /// On [LinkSucceeded], the uid is unchanged and every existing document
  /// is automatically still owned by it (research.md #1) — no further
  /// action needed by the caller. On [LinkConflictDetected], the caller
  /// must route to conflict-resolution UI, never treat it as a generic
  /// error (spec.md FR-004).
  Future<LinkResult> linkWithGoogle();

  /// Same contract as [linkWithGoogle], for Apple. Both exist in this
  /// feature together — Apple requires Sign in with Apple wherever Google
  /// Sign-In is offered (App Store Review Guideline 4.8).
  Future<LinkResult> linkWithApple();

  /// Resolves a [LinkConflictDetected] surfaced by [linkWithGoogle]/
  /// [linkWithApple], per [resolution]:
  /// - [LinkConflictResolution.merge]: reads the current (still-anonymous)
  ///   session's full expense/category history into memory, switches to
  ///   the existing account via the credential held internally since the
  ///   conflict was detected, then writes that history into the existing
  ///   account's collections with fresh ids.
  /// - [LinkConflictResolution.discardLocal]: batch-deletes the current
  ///   session's expense/category history while still authenticated as it,
  ///   then switches to the existing account.
  ///
  /// Either path requires network for both phases; a mid-flow network loss
  /// is surfaced as a retryable failure, never as a silent partial state
  /// (spec.md FR-006 / US4).
  Future<Result<void>> resolveLinkConflict(
    LinkConflict conflict,
    LinkConflictResolution resolution,
  );

  /// Deletes every expense and category document, the `users/{uid}`
  /// document, and the Firebase Auth user record itself, in that order.
  /// On `requires-recent-login`, calls [onReauthRequired] (so the UI can
  /// explain the native sign-in sheet it's about to see, per
  /// `settingsDeleteAccountReauthMessage`) before re-prompting the linked
  /// provider's sign-in and retrying once — never surfaces that error
  /// directly to the caller.
  Future<Result<void>> deleteAccount({void Function()? onReauthRequired});
}
