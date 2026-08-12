import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/core/navigation/app_shell.dart';
import 'package:wrap_my_finances/features/expenses/presentation/pages/expense_capture_page.dart';
import 'package:wrap_my_finances/features/expenses/presentation/pages/expense_history_page.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/pages/wrapped_route_page.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/wrapped_auto_trigger_gate.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

// `initialLocation` defaults to the first route ('/') and no code path here
// persists or restores a prior location — this, not an explicit check, is
// what keeps capture the fixed launch destination (FR-012,
// specs/005-expense-history-undo/research.md).
final _router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => WrappedAutoTriggerGate(
        child: AppShell(currentLocation: state.uri.toString(), child: child),
      ),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ExpenseCapturePage(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const ExpenseHistoryPage(),
        ),
      ],
    ),
    // A sibling of ShellRoute, not nested inside it — the floating nav bar
    // has no role in a full-screen, swipe-to-dismiss story sequence. See
    // specs/006-monthly-wrapped-summary/research.md #8.
    GoRoute(
      path: '/wrapped/:monthKey',
      builder: (context, state) => WrappedRoutePage(
        monthKey: state.pathParameters['monthKey']!,
        onDismissed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
    ),
  ],
);

/// The app shell: [MaterialApp.router] with two routes — capture (always
/// the launch destination, FR-001/FR-012) and history — wrapped in
/// [AppShell]'s floating nav bar.
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
