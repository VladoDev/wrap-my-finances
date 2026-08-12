import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/widgets/wrapped_scene_grand_total.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pump(WidgetTester tester, {bool disableAnimations = true}) {
    return tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: WrappedSceneGrandTotal(
              total: Money(minorUnits: 150000, currencyCode: 'MXN'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders the formatted total with reduce motion showing the '
      'final value immediately', (tester) async {
    await pump(tester);

    expect(find.textContaining('1,500.00'), findsOneWidget);
  });

  testWidgets('without reduce motion, counts up to the final value', (
    tester,
  ) async {
    await pump(tester, disableAnimations: false);
    await tester.pump(const Duration(milliseconds: 50));

    // Mid-animation: some text is rendered, but it isn't yet the final
    // value (still counting up).
    expect(find.textContaining('1,500.00'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.textContaining('1,500.00'), findsOneWidget);
  });
}
