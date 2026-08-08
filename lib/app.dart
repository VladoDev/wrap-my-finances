import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wrap_my_finances/core/diagnostics/presentation/pages/environment_status_page.dart';

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
class App extends StatelessWidget {
  /// Creates the app.
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
    );
  }
}
