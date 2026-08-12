import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/features/expenses/presentation/widgets/amount_display.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

// Guards FR-015: no golden PNG is committed for this feature's screens
// (would need a baseline captured on the exact CI runner, out of scope for
// this pass) — but the 200%-text-scale, no-overflow guarantee data-model.md
// requires is verified directly.
Future<void> _pump(WidgetTester tester, String amount, double scale) {
  return tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AmountDisplay(formattedAmount: amount)),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the formatted amount', (tester) async {
    await _pump(tester, '1,234.56', 1);
    expect(find.text('1,234.56'), findsOneWidget);
  });

  testWidgets('the largest amount renders at 200% scale without overflow', (
    tester,
  ) async {
    await _pump(tester, '1,000,000.00', 2);
    expect(tester.takeException(), isNull);
    expect(find.text('1,000,000.00'), findsOneWidget);
  });
}
