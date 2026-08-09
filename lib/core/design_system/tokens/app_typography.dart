import 'package:flutter/material.dart';

const String _fontFamily = 'Nunito';

/// Semantic typography tokens, resolved from [BuildContext] via
/// `context.typography` (see `theme/design_tokens.dart`). No widget may
/// construct a [TextStyle] ad hoc — see Constitution Principle 9.
///
/// Every style is shape-only: font family, weight, size, letter-spacing, and
/// height. None sets [TextStyle.color] — color always comes from
/// `AppColorsExtension` and is applied at the call site
/// (`context.typography.labelLarge.copyWith(color: context.colors.onPrimary)`),
/// so no color value ever needs to live outside `app_colors.dart`. See
/// research.md.
@immutable
class AppTypographyExtension extends ThemeExtension<AppTypographyExtension> {
  /// Creates a typography-token set. Every field is required.
  const AppTypographyExtension({
    required this.titleMedium,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
  });

  /// The single typography scale this feature ships. A getter (per
  /// contracts/design-system-api.md), not a constructor, since it is a
  /// derived constant rather than a value composed from caller-supplied
  /// fields.
  // ignore: prefer_constructors_over_static_methods
  static AppTypographyExtension get standard => const AppTypographyExtension(
    titleMedium: TextStyle(
      fontFamily: _fontFamily,
      fontWeight: FontWeight.w700,
      fontSize: 18,
      height: 1.3,
    ),
    bodyMedium: TextStyle(
      fontFamily: _fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: 16,
      height: 1.4,
    ),
    bodySmall: TextStyle(
      fontFamily: _fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: 14,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontFamily: _fontFamily,
      fontWeight: FontWeight.w700,
      fontSize: 16,
      height: 1.2,
      letterSpacing: 0.2,
    ),
  );

  /// `AppCard` title slot.
  final TextStyle titleMedium;

  /// `AppCard` body slot, `AppTextField` input text.
  final TextStyle bodyMedium;

  /// `AppTextField` hint/helper/error text, `AppChip` label.
  final TextStyle bodySmall;

  /// `AppButton` label.
  final TextStyle labelLarge;

  @override
  AppTypographyExtension copyWith({
    TextStyle? titleMedium,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? labelLarge,
  }) {
    return AppTypographyExtension(
      titleMedium: titleMedium ?? this.titleMedium,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      labelLarge: labelLarge ?? this.labelLarge,
    );
  }

  @override
  AppTypographyExtension lerp(
    ThemeExtension<AppTypographyExtension>? other,
    double t,
  ) {
    if (other is! AppTypographyExtension) return this;
    return AppTypographyExtension(
      titleMedium: TextStyle.lerp(titleMedium, other.titleMedium, t)!,
      bodyMedium: TextStyle.lerp(bodyMedium, other.bodyMedium, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      labelLarge: TextStyle.lerp(labelLarge, other.labelLarge, t)!,
    );
  }
}
