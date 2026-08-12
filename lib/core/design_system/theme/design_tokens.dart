import 'package:flutter/material.dart';
import 'package:wrap_my_finances/core/design_system/tokens/app_colors.dart';
import 'package:wrap_my_finances/core/design_system/tokens/app_motion.dart';
import 'package:wrap_my_finances/core/design_system/tokens/app_spacing.dart';
import 'package:wrap_my_finances/core/design_system/tokens/app_typography.dart';

/// The single entry point every widget uses to resolve design tokens.
/// `Theme.of(context).extension<T>()` is an implementation detail confined
/// to this file — callers use `context.colors`/`.typography`/`.spacing`/
/// `.motion` exclusively. See contracts/design-system-api.md.
extension DesignTokensX on BuildContext {
  /// Semantic color tokens for the active theme.
  AppColorsExtension get colors =>
      Theme.of(this).extension<AppColorsExtension>()!;

  /// Semantic typography tokens for the active theme.
  AppTypographyExtension get typography =>
      Theme.of(this).extension<AppTypographyExtension>()!;

  /// Semantic spacing/radius tokens for the active theme.
  AppSpacingExtension get spacing =>
      Theme.of(this).extension<AppSpacingExtension>()!;

  /// Semantic motion tokens (curves/durations) for the active theme.
  AppMotionExtension get motion =>
      Theme.of(this).extension<AppMotionExtension>()!;
}
