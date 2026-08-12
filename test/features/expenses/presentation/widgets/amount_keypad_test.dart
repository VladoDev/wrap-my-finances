import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/features/expenses/presentation/widgets/amount_keypad.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester, {
  required bool isNextEnabled,
  required ValueChanged<String> onDigit,
  required VoidCallback onNext,
  double scale = 1,
}) {
  return tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AmountKeypad(
            decimalSeparatorSymbol: '.',
            isNextEnabled: isNextEnabled,
            onDigit: onDigit,
            onDecimalSeparator: () {},
            onBackspace: () {},
            onNext: onNext,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('tapping a digit invokes onDigit with that digit', (
    tester,
  ) async {
    String? tapped;
    await _pump(
      tester,
      isNextEnabled: true,
      onDigit: (digit) => tapped = digit,
      onNext: () {},
    );

    await tester.tap(find.text('7'));
    expect(tapped, '7');
  });

  testWidgets('"Next" is disabled without changing layout when invalid', (
    tester,
  ) async {
    var nextTapped = false;
    await _pump(
      tester,
      isNextEnabled: false,
      onDigit: (_) {},
      onNext: () => nextTapped = true,
    );

    final enabledButton = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(enabledButton.onPressed, isNull);

    await tester.tap(find.text('Continue'), warnIfMissed: false);
    expect(nextTapped, isFalse);
  });

  testWidgets('renders at 200% text scale without overflow', (tester) async {
    await _pump(
      tester,
      isNextEnabled: true,
      onDigit: (_) {},
      onNext: () {},
      scale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
