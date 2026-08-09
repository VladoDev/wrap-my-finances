import 'package:flutter/material.dart';

/// Semantic spacing and border-radius tokens, resolved from [BuildContext]
/// via `context.spacing` (see `theme/design_tokens.dart`). No widget may
/// write a spacing or radius value as a literal — see Constitution
/// Principle 9, which groups radius and spacing into this one file.
@immutable
class AppSpacingExtension extends ThemeExtension<AppSpacingExtension> {
  /// Creates a spacing/radius token set. Every field is required.
  const AppSpacingExtension({
    required this.spacingXs,
    required this.spacingSm,
    required this.spacingMd,
    required this.spacingLg,
    required this.spacingXl,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
  });

  /// The single spacing/radius scale this feature ships.
  static const AppSpacingExtension standard = AppSpacingExtension(
    spacingXs: 4,
    spacingSm: 8,
    spacingMd: 16,
    spacingLg: 24,
    spacingXl: 32,
    radiusSm: 8,
    radiusMd: 16,
    radiusLg: 24,
  );

  /// Icon-to-label gaps inside `AppChip`.
  final double spacingXs;

  /// `AppButton`/`AppChip` internal padding (vertical).
  final double spacingSm;

  /// `AppButton` internal padding (horizontal), `AppCard`/`AppTextField`
  /// internal padding.
  final double spacingMd;

  /// `AppCard` external margin, gaps between stacked primitives.
  final double spacingLg;

  /// Reserved for section-level spacing in future features.
  final double spacingXl;

  /// `AppTextField` border radius.
  final double radiusSm;

  /// `AppCard` border radius.
  final double radiusMd;

  /// Reserved — matches `docs/UI_UX_SPEC.md`'s `BorderRadius.circular(24)`
  /// example.
  final double radiusLg;

  /// Fully pill-shaped — `AppButton`, `AppChip`. A shape, not a numeric
  /// radius, so it is exposed as an [OutlinedBorder] rather than a `double`
  /// (both `FilledButton.styleFrom` and `Chip.shape` require this type).
  OutlinedBorder get radiusPill => const StadiumBorder();

  @override
  AppSpacingExtension copyWith({
    double? spacingXs,
    double? spacingSm,
    double? spacingMd,
    double? spacingLg,
    double? spacingXl,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
  }) {
    return AppSpacingExtension(
      spacingXs: spacingXs ?? this.spacingXs,
      spacingSm: spacingSm ?? this.spacingSm,
      spacingMd: spacingMd ?? this.spacingMd,
      spacingLg: spacingLg ?? this.spacingLg,
      spacingXl: spacingXl ?? this.spacingXl,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
    );
  }

  @override
  AppSpacingExtension lerp(
    ThemeExtension<AppSpacingExtension>? other,
    double t,
  ) {
    if (other is! AppSpacingExtension) return this;
    return AppSpacingExtension(
      spacingXs: _lerpDouble(spacingXs, other.spacingXs, t),
      spacingSm: _lerpDouble(spacingSm, other.spacingSm, t),
      spacingMd: _lerpDouble(spacingMd, other.spacingMd, t),
      spacingLg: _lerpDouble(spacingLg, other.spacingLg, t),
      spacingXl: _lerpDouble(spacingXl, other.spacingXl, t),
      radiusSm: _lerpDouble(radiusSm, other.radiusSm, t),
      radiusMd: _lerpDouble(radiusMd, other.radiusMd, t),
      radiusLg: _lerpDouble(radiusLg, other.radiusLg, t),
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
