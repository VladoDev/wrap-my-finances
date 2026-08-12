/// Abstract analytics port. Flutter/Firebase-free — safe for `domain/` code
/// to depend on directly, the same way `AuthRepository` is (Constitution
/// Principle 4).
///
/// Constitution Principle 5: no method on this interface may ever be passed
/// a monetary amount, an expense note, or a user-authored category name.
abstract class AnalyticsService {
  /// Reports the measured time from process start to local expense
  /// persistence (FR-003/SC-001). [elapsed] only — no financial data.
  void logExpenseTimeToLog(Duration elapsed);

  /// Reports how much of a Wrapped sequence was seen before it ended
  /// (dismissed or reached the last scene), as a `0.0`-`1.0`
  /// [completionRatio]. No amount, note, or category name — the one figure
  /// `docs/TECH_STACK.md`'s `wrapped_completion_rate` event carries
  /// (Constitution Principle 5, FR-017).
  void logWrappedCompletion(double completionRatio);
}
