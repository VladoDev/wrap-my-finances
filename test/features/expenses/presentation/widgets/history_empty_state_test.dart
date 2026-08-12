import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/features/expenses/presentation/widgets/history_empty_state.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('renders the warm title, subtitle, and an icon — no new '
      'illustration asset', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: HistoryEmptyState()),
      ),
    );

    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('Expenses you log will show up here'), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    // No Image/asset-backed illustration anywhere in the tree.
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('renders at 200% text scale without overflow', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: HistoryEmptyState()),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
