import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/core/design_system/widgets/app_button.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

// Guards FR-010/FR-011 (US3): a primitive that renders localized text shows
// the correct translation for every supported locale, sourced from
// AppLocalizations rather than a literal string.
void main() {
  const expectedByLocale = {
    'en': 'Continue',
    'es': 'Continuar',
    'pt': 'Continuar',
    'it': 'Continua',
    'fr': 'Continuer',
  };

  for (final entry in expectedByLocale.entries) {
    testWidgets('renders "${entry.value}" under locale ${entry.key}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: Locale(entry.key),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: AppButton(
                  label: AppLocalizations.of(context)!.commonContinue,
                  onPressed: () {},
                ),
              );
            },
          ),
        ),
      );

      expect(find.text(entry.value), findsOneWidget);
    });
  }
}
