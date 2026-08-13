/// The two explicit choices FR-004/FR-005 require when a link conflict is
/// detected — never a third, implicit option.
enum LinkConflictResolution {
  /// Combine both histories into the existing account.
  merge,

  /// Keep only the existing account's history; explicitly delete the
  /// current device's anonymous data first.
  discardLocal,
}
