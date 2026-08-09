import 'package:flutter/material.dart';
import 'package:wrap_my_finances/core/design_system/tokens/app_colors.dart';
import 'package:wrap_my_finances/core/design_system/tokens/app_spacing.dart';
import 'package:wrap_my_finances/core/design_system/tokens/app_typography.dart';

/// Wires the three token families into a single [ThemeData] and fixes the
/// app's theme mode.
///
/// [themeMode] is a compile-time constant — never derived from
/// `MediaQuery`/`platformBrightness` — so a device in system dark mode
/// renders identically to one in light mode. See FR-005/FR-006 and
/// `theme_light_only_test.dart`.
abstract final class AppTheme {
  /// The app's fixed, only theme mode. Passed directly to
  /// `MaterialApp.router` alongside [light]; no `darkTheme` is ever passed.
  static const ThemeMode themeMode = ThemeMode.light;

  /// The single light [ThemeData] this feature ships.
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColorsExtension.light.primary,
      surface: AppColorsExtension.light.surface,
      onSurface: AppColorsExtension.light.onSurface,
    ),
    scaffoldBackgroundColor: AppColorsExtension.light.background,
    extensions: <ThemeExtension<dynamic>>[
      AppColorsExtension.light,
      AppTypographyExtension.standard,
      AppSpacingExtension.standard,
    ],
  );
}
