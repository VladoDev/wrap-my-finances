/// The two build flavors this app ships, per `docs/ENVIRONMENTS.md`.
///
/// `name` must match the native flavor name exactly — `flavor_guard.dart`
/// compares it against `appFlavor` at startup.
enum AppEnvironment {
  /// Development flavor: connects to `wrap-my-finances-dev`, shows a debug
  /// indicator, and allows writing environment-probe test documents.
  dev(
    name: 'dev',
    showDebugBanner: true,
    allowSeeding: true,
    firestoreCollectionPath: 'env_checks',
  ),

  /// Production flavor: connects to `wrap-my-finances-prod`, with no debug
  /// affordance of any kind.
  prod(
    name: 'prod',
    showDebugBanner: false,
    allowSeeding: false,
    firestoreCollectionPath: 'env_checks',
  );

  const AppEnvironment({
    required this.name,
    required this.showDebugBanner,
    required this.allowSeeding,
    required this.firestoreCollectionPath,
  });

  /// Must equal the native flavor name (`appFlavor`) exactly.
  final String name;

  /// Whether the diagnostics screen shows a visible debug indicator.
  final bool showDebugBanner;

  /// Whether the diagnostics screen offers the "write test document" control.
  final bool allowSeeding;

  /// Firestore collection used for the environment-isolation probe document.
  final String firestoreCollectionPath;
}
