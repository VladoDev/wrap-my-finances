/// A document written to prove that a write from one environment never
/// appears in the other (spec.md User Story 4). Pure domain entity — no
/// Firebase or Flutter imports. See `data-model.md`.
class EnvironmentProbe {
  /// Creates a probe. [id] must be client-generated, never server-assigned.
  const EnvironmentProbe({
    required this.id,
    required this.environmentName,
    required this.createdAtMillis,
    required this.label,
  });

  /// Client-generated document ID.
  final String id;

  /// The [`AppEnvironment.name`] active when this probe was written.
  final String environmentName;

  /// Client clock at creation — never `FieldValue.serverTimestamp()`.
  final int createdAtMillis;

  /// Short human-readable label, capped at 40 characters.
  final String label;
}
