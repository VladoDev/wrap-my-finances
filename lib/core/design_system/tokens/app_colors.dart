import 'package:flutter/material.dart';

// The only file in this repository allowed to contain a raw hex color
// literal (enforced by test/core/design_system/tokens/no_raw_hex_colors_test.dart).
// These constants are library-private on purpose: Dart makes them physically
// unimportable from any other file, so nothing outside this file can ever
// reference a concrete color value. See research.md.
const Color _offWhite = Color(0xFFF8F9FA);
const Color _coral = Color(0xFFFF6B6B);
const Color _teal = Color(0xFF4ECDC4);
const Color _white = Color(0xFFFFFFFF);
const Color _darkNeutral = Color(0xFF2D3436);
const Color _danger = Color(0xFFE17055);

// Category swatch palette — fills behind category icons/accents only, never
// small text (see docs/UI_UX_SPEC.md §1), so these are not held to the
// text-contrast pairing the tokens above are. Kept here, not as literals in
// seeding code, so this remains the one file allowed to hold a hex literal —
// see specs/004-quick-expense-capture/research.md.
const Color _categorySun = Color(0xFFFFB84C);
const Color _categoryGrape = Color(0xFF9B5DE5);
const Color _categoryMint = Color(0xFF06D6A0);
const Color _categorySky = Color(0xFF4CC9F0);
const Color _categoryPeach = Color(0xFFFF9F80);
const Color _categoryRose = Color(0xFFEF476F);
const Color _categoryOlive = Color(0xFF8D9440);

/// Semantic color tokens, resolved from [BuildContext] via
/// `context.colors` (see `theme/design_tokens.dart`). No widget may
/// reference a [Color] literal directly — see Constitution Principle 9.
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  /// Creates a color-token set. Every field is required — there is no
  /// implicit default, so a new scheme must supply a value for every token.
  const AppColorsExtension({
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.danger,
    required this.onDanger,
    required this.outline,
    required this.categoryPalette,
  });

  /// The single light color scheme this feature ships. A future dark scheme
  /// is a second `const AppColorsExtension` instance wired into a second
  /// `ThemeData` — no change to this class or to any widget. See
  /// FR-007/FR-008 and `theme_extensibility_test.dart`.
  static const AppColorsExtension light = AppColorsExtension(
    background: _offWhite,
    onBackground: _darkNeutral,
    surface: _white,
    onSurface: _darkNeutral,
    primary: _coral,
    onPrimary: _darkNeutral,
    secondary: _teal,
    onSecondary: _darkNeutral,
    danger: _danger,
    onDanger: _white,
    outline: _darkNeutral,
    categoryPalette: [
      _categorySun,
      _categoryGrape,
      _categoryMint,
      _categorySky,
      _categoryPeach,
      _categoryRose,
      _categoryOlive,
    ],
  );

  /// App-level background, behind every screen.
  final Color background;

  /// Text/icon color painted directly on [background].
  final Color onBackground;

  /// Card/sheet surface, elevated above [background].
  final Color surface;

  /// Text/icon color painted directly on [surface].
  final Color onSurface;

  /// Primary action fill (buttons, active accents).
  final Color primary;

  /// Text/icon color painted directly on [primary].
  final Color onPrimary;

  /// Secondary accent fill.
  final Color secondary;

  /// Text/icon color painted directly on [secondary].
  final Color onSecondary;

  /// Destructive-action fill. Text painted on top of it only meets WCAG AA
  /// at the large-text/UI-component threshold (3:1), never the normal-text
  /// threshold (4.5:1) — see data-model.md. Callers must pair it with a
  /// bold, ≥14sp label, never small body text.
  final Color danger;

  /// Text/icon color painted directly on [danger].
  final Color onDanger;

  /// Decorative border/shadow accent (the "thick border" neo-brutalism
  /// detail from docs/UI_UX_SPEC.md §1). Never paired with text, so it is
  /// not part of the WCAG contrast contract.
  final Color outline;

  /// Fixed 7-entry swatch palette for default category tiles/icon fills,
  /// indexed by the seed order in data-model.md. Never used for text.
  final List<Color> categoryPalette;

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? onBackground,
    Color? surface,
    Color? onSurface,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? danger,
    Color? onDanger,
    Color? outline,
    List<Color>? categoryPalette,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      outline: outline ?? this.outline,
      categoryPalette: categoryPalette ?? this.categoryPalette,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      categoryPalette: [
        for (var i = 0; i < categoryPalette.length; i++)
          Color.lerp(categoryPalette[i], other.categoryPalette[i], t)!,
      ],
    );
  }
}
