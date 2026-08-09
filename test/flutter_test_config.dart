import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';

// Applies the app's real theme (AppColorsExtension/AppTypographyExtension/
// AppSpacingExtension) to every golden test in this project, so golden
// images actually exercise the design tokens rather than Alchemist's
// default Material theme. See US7/FR-014.
//
// `platformGoldensConfig` is restricted to macOS: Alchemist's default runs
// the human-readable "platform" variant on every host OS
// (`HostPlatform.values`), which would require committing a separate
// reference image per OS. Developers here work on macOS; CI
// (.github/workflows/ci.yml) runs on `ubuntu-latest`. Restricting to macOS
// means the readable variant only runs (and is only expected to exist)
// locally, while CI verifies exclusively via the `ci` variant below, whose
// Ahem-font/obscured-text images are committed from a Linux run so they
// match what CI actually renders — see research.md.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: AppTheme.light,
      platformGoldensConfig: PlatformGoldensConfig(
        platforms: {HostPlatform.macOS},
      ),
    ),
    run: testMain,
  );
}
