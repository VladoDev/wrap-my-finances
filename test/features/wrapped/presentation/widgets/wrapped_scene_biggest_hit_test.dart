import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/widgets/wrapped_scene_biggest_hit.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('renders the formatted biggest single expense', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: WrappedSceneBiggestHit(
              biggestExpense: Money(minorUnits: 8500, currencyCode: 'MXN'),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('85.00'), findsOneWidget);
  });
}
