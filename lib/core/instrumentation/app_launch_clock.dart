/// Marks when this process started, so any later code can measure elapsed
/// time without threading a timestamp through every layer by hand. Pure
/// Dart — safe for a `domain/` use case to depend on directly (Constitution
/// Principle 4). Constructed with `DateTime.now()` as the first statement of
/// `bootstrap()`, before `WidgetsFlutterBinding.ensureInitialized()`.
class AppLaunchClock {
  /// Creates a clock anchored at [startedAt].
  const AppLaunchClock(this.startedAt);

  /// When this process started.
  final DateTime startedAt;

  /// Time elapsed since [startedAt].
  Duration elapsedSinceLaunch() => DateTime.now().difference(startedAt);
}
