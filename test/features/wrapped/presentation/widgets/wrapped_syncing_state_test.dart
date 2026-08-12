import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/widgets/wrapped_syncing_state.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('renders the syncing message and no monetary figure', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: WrappedSyncingState()),
      ),
    );

    expect(find.text('Still syncing your data…'), findsOneWidget);
  });
}
