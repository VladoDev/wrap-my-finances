# Contract: Design System Public API

This feature's consumers are **future features**, not external systems — but the boundary is real:
every feature built after this one depends on this API and must not reach around it (e.g. by
constructing a `TextStyle` inline or importing `app_colors.dart` directly, which is impossible by
construction — see `research.md`). This document is that dependency contract.

## Token access

```dart
extension DesignTokensX on BuildContext {
  AppColorsExtension get colors;
  AppTypographyExtension get typography;
  AppSpacingExtension get spacing;
}
```

Callers obtain tokens exclusively through these three getters. `Theme.of(context)` and
`.extension<T>()` are implementation details of this file and are never called directly outside
`lib/core/design_system/`.

## `AppColorsExtension` surface

```dart
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color danger;
  final Color onDanger;
  final Color outline;

  static const AppColorsExtension light = /* ... */;
}
```

Guarantee: every field is a token name, never a raw value, at every call site. Adding a dark variant
is `static const AppColorsExtension dark = AppColorsExtension(...)` plus wiring a second `ThemeData`
— no change to this class's field list and no change to any file outside
`lib/core/design_system/tokens/app_colors.dart` and `lib/core/design_system/theme/app_theme.dart`.

## `AppTypographyExtension` surface

```dart
class AppTypographyExtension extends ThemeExtension<AppTypographyExtension> {
  final TextStyle titleMedium;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle labelLarge;

  static AppTypographyExtension get standard => /* built from GoogleFonts.nunito(...) */;
}
```

Guarantee: no field carries a `color`. Callers apply color via `.copyWith(color:
context.colors.<token>)`.

## `AppSpacingExtension` surface

```dart
class AppSpacingExtension extends ThemeExtension<AppSpacingExtension> {
  final double spacingXs, spacingSm, spacingMd, spacingLg, spacingXl;
  final double radiusSm, radiusMd, radiusLg;
  final ShapeBorder radiusPill; // StadiumBorder

  static const AppSpacingExtension standard = /* ... */;
}
```

## Primitive widgets

```dart
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
}
enum AppButtonVariant { primary, secondary, danger }

class AppCard extends StatelessWidget {
  const AppCard({this.title, this.body, this.child, super.key});
  final String? title;
  final String? body;
  final Widget? child;
}

class AppChip extends StatelessWidget {
  const AppChip({required this.label, this.variant = AppChipVariant.neutral, super.key});
  final String label;
  final AppChipVariant variant;
}
enum AppChipVariant { neutral, primary, secondary }

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.hint,
    this.errorText,
    this.controller,
    super.key,
  });
  final String label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
}
```

Guarantee: every constructor parameter that renders as text is a plain `String` supplied by the
caller (typically an `AppLocalizations.of(context)!.xxx` lookup) — no primitive contains a string
literal of its own, and no primitive reads `Directionality`, `Locale`, or brightness itself; it
only ever asks the theme for tokens.

## Stability notes for consumers

- Adding a new token field to any `*Extension` class is additive and non-breaking.
- Removing or renaming an existing token field is breaking and requires updating every consumer in
  the same change — there is no default/fallback value.
- No primitive listed here will gain a `color` or raw numeric-literal parameter; a caller that needs
  a value not already exposed as a token requests a new token, rather than passing a literal
  through.
