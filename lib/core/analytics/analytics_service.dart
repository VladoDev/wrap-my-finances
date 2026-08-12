/// Abstract analytics port. Flutter/Firebase-free — safe for `domain/` code
/// to depend on directly, the same way `AuthRepository` is (Constitution
/// Principle 4).
///
/// Constitution Principle 5: no method on this interface may ever be passed
/// a monetary amount, an expense note, or a user-authored category name.
// A top-level function can't be swapped via @LazySingleton(as: ...) DI or
// stubbed with a mocktail fake the way every other port in this codebase
// (AuthRepository, ExpenseRepository, CategoryRepository) is — this class
// stays single-member on purpose, matching that established pattern.
// ignore: one_member_abstracts
abstract class AnalyticsService {
  /// Reports the measured time from process start to local expense
  /// persistence (FR-003/SC-001). [elapsed] only — no financial data.
  void logExpenseTimeToLog(Duration elapsed);
}
