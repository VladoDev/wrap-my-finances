/// Closed set of failure kinds that can cross a repository boundary.
///
/// Hand-written `sealed class` rather than `freezed` — see `research.md`
/// ("Result/Failure are hand-written sealed classes, not freezed").
sealed class Failure {
  const Failure();
}

/// The operation required network access that was not available.
final class NetworkFailure extends Failure {
  /// Creates a network failure.
  const NetworkFailure();
}

/// Security Rules denied the operation.
final class PermissionDeniedFailure extends Failure {
  /// Creates a permission-denied failure.
  const PermissionDeniedFailure();
}

/// The requested document does not exist.
final class NotFoundFailure extends Failure {
  /// Creates a not-found failure.
  const NotFoundFailure();
}

/// A field failed local validation before being sent.
final class ValidationFailure extends Failure {
  /// Creates a validation failure for [field].
  const ValidationFailure(this.field);

  /// The name of the field that failed validation.
  final String field;
}

/// An unexpected failure — the only variant that reports to Crashlytics.
final class UnknownFailure extends Failure {
  /// Creates an unknown failure wrapping the original [error]/[stackTrace].
  const UnknownFailure(this.error, this.stackTrace);

  /// The original error object.
  final Object error;

  /// The original stack trace.
  final StackTrace stackTrace;
}
