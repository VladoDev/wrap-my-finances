/// The two build flavors this app ships, per `docs/ENVIRONMENTS.md`.
///
/// `name` must match the native flavor name exactly — `flavor_guard.dart`
/// compares it against `appFlavor` at startup.
enum AppEnvironment {
  /// Development flavor: connects to `wrap-my-finances-dev`, shows a debug
  /// indicator.
  dev(name: 'dev', showDebugBanner: true),

  /// Production flavor: connects to `wrap-my-finances-prod`, with no debug
  /// affordance of any kind.
  prod(name: 'prod', showDebugBanner: false);

  const AppEnvironment({required this.name, required this.showDebugBanner});

  /// Must equal the native flavor name (`appFlavor`) exactly.
  final String name;

  /// Whether the app shows a visible debug indicator (the dev-flavor ribbon
  /// banner, per `docs/UI_UX_SPEC.md` §6).
  final bool showDebugBanner;
}
