import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';

// Applies the app's real theme (AppColorsExtension/AppTypographyExtension/
// AppSpacingExtension) to every golden test in this project, so golden
// images actually exercise the design tokens rather than Alchemist's
// default Material theme. See US7/FR-014.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(theme: AppTheme.light),
    run: testMain,
  );
}
