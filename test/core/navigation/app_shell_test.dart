import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/core/navigation/app_shell.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

Future<GoRouter> _pump(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(currentLocation: state.uri.toString(), child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('capture'))),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('history'))),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('settings'))),
          ),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('renders all three nav destinations with semantic labels', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.bySemanticsLabel('Log expense'), findsOneWidget);
    expect(find.bySemanticsLabel('History'), findsOneWidget);
    expect(find.bySemanticsLabel('Settings'), findsOneWidget);
  });

  testWidgets('tapping the settings destination navigates to /settings', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('capture'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('settings'), findsOneWidget);
  });

  testWidgets('tapping the history destination navigates to /history', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('capture'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('History'));
    await tester.pumpAndSettle();

    expect(find.text('history'), findsOneWidget);
  });

  testWidgets('tapping the capture destination navigates back to /', (
    tester,
  ) async {
    final router = await _pump(tester);
    router.go('/history');
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Log expense'));
    await tester.pumpAndSettle();

    expect(find.text('capture'), findsOneWidget);
  });
}
