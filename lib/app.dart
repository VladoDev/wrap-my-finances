import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/core/diagnostics/presentation/pages/environment_status_page.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const EnvironmentStatusPage(),
    ),
  ],
);

/// The app shell: a single-route [MaterialApp.router] pointing at
/// [EnvironmentStatusPage]. This feature adds no other screens.
///
/// [ThemeMode] is fixed to [AppTheme.themeMode] (light) and no `darkTheme`
/// is provided, so system dark mode has no effect (FR-005/FR-006).
/// `localizationsDelegates`/`supportedLocales` are wired here once, at the
/// single app root every future feature's screens inherit from.
class App extends StatelessWidget {
  /// Creates the app.
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: AppTheme.light,
      themeMode: AppTheme.themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
    );
  }
}
