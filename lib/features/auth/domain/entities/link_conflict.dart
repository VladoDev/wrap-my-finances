/// Represents the acceptance-criterion-4 situation: the credential being
/// linked already belongs to a different, existing account. Deliberately
/// Flutter/Firebase-free (Constitution Principle 4) — carries only what the
/// UI needs to *display* the conflict. The actual pending credential stays
/// inside the `data/` layer, keyed to this conflict internally, the same
/// "memoized private state on the singleton repository" pattern already
/// used for `AuthRepository`'s own `_pendingSignIn`.
class LinkConflict {
  /// Creates a conflict, naming which provider the existing account is
  /// tied to (for display only).
  const LinkConflict({required this.existingProviderLabel});

  /// Which provider (e.g. "Google", "Apple") the conflicting account is
  /// tied to, for display only.
  final String existingProviderLabel;
}
