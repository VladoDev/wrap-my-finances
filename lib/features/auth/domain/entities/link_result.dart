import 'package:wrap_my_finances/core/errors/failure.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_conflict.dart';

/// The outcome of `AuthRepository.linkWithGoogle`/`linkWithApple`. A
/// dedicated sealed type — not `Result<void>` — because a conflict is not
/// a generic failure (spec.md FR-004): the caller needs to route to
/// conflict-resolution UI, not an error message. Kept entirely within
/// `auth/domain/` rather than added to the shared `core/errors/failure.dart`
/// hierarchy, since `core/` must never import from `features/`
/// (Constitution Principle 4) and [LinkConflict] is feature-specific.
sealed class LinkResult {
  const LinkResult();
}

/// Linking succeeded — same uid, no data migration needed (research.md #1).
final class LinkSucceeded extends LinkResult {
  /// Creates a success result.
  const LinkSucceeded();
}

/// The credential is already tied to a different, existing account.
final class LinkConflictDetected extends LinkResult {
  /// Creates a conflict result carrying [conflict] for display/resolution.
  const LinkConflictDetected(this.conflict);

  /// The detected conflict.
  final LinkConflict conflict;
}

/// Linking failed for an ordinary reason (network, etc.) — not a conflict.
final class LinkFailed extends LinkResult {
  /// Creates a failure result wrapping [failure].
  const LinkFailed(this.failure);

  /// The underlying failure.
  final Failure failure;
}
