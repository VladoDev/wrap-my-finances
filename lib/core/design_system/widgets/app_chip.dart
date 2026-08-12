import 'package:flutter/material.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';

/// Visual variant of [AppChip]. Each maps to a fill/label color pair from
/// `AppColorsExtension` — see `data-model.md`.
enum AppChipVariant {
  /// Surface-colored, the default.
  neutral,

  /// Primary-colored accent.
  primary,

  /// Secondary-colored accent.
  secondary,
}

/// A pill-shaped tag/label. The tightest text box of the four primitives
/// this feature ships, so it is the primary stress case for FR-013's
/// 200%-text-scale/longest-translation guarantee (see `data-model.md`).
class AppChip extends StatelessWidget {
  /// Creates a chip. [label] must already be localized by the caller.
  const AppChip({
    required this.label,
    this.variant = AppChipVariant.neutral,
    super.key,
  });

  /// The chip's text label.
  final String label;

  /// Which color variant to render.
  final AppChipVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (Color fill, Color onFill) = switch (variant) {
      AppChipVariant.neutral => (colors.surface, colors.onSurface),
      AppChipVariant.primary => (colors.primary, colors.onPrimary),
      AppChipVariant.secondary => (colors.secondary, colors.onSecondary),
    };

    return Chip(
      label: Text(
        label,
        style: context.typography.bodySmall.copyWith(color: onFill),
      ),
      backgroundColor: fill,
      side: BorderSide(color: colors.outline),
      shape: context.spacing.radiusPill,
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.spacingSm,
        vertical: context.spacing.spacingXs,
      ),
    );
  }
}
