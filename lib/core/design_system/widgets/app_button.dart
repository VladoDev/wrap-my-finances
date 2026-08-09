import 'package:flutter/material.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';

/// Visual variant of [AppButton]. Each maps to a fill/label color pair from
/// `AppColorsExtension` — see `data-model.md`.
enum AppButtonVariant {
  /// The default, highest-emphasis variant.
  primary,

  /// Lower-emphasis accent variant.
  secondary,

  /// Destructive-action variant.
  danger,
}

/// A pill-shaped primary action button, per `docs/UI_UX_SPEC.md` §1's
/// "Modern Playful" shape language. Every color, text style, radius, and
/// spacing value comes from `context.colors`/`context.typography`/
/// `context.spacing` — never a literal (Constitution Principle 9).
///
/// Wraps [FilledButton] rather than a `CustomPaint` reimplementation, so it
/// inherits correct semantics, minimum-tap-area handling, and platform
/// press feedback for free (Constitution Principle 8). See research.md.
class AppButton extends StatelessWidget {
  /// Creates a pill-shaped button. [label] must already be localized by the
  /// caller (typically via `AppLocalizations.of(context)!`).
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    super.key,
  });

  /// The button's text label.
  final String label;

  /// Called on tap; `null` renders the button disabled.
  final VoidCallback? onPressed;

  /// Which color/emphasis variant to render.
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (Color fill, Color onFill) = switch (variant) {
      AppButtonVariant.primary => (colors.primary, colors.onPrimary),
      AppButtonVariant.secondary => (colors.secondary, colors.onSecondary),
      AppButtonVariant.danger => (colors.danger, colors.onDanger),
    };

    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: fill,
          foregroundColor: onFill,
          disabledBackgroundColor: fill.withValues(alpha: 0.5),
          disabledForegroundColor: onFill.withValues(alpha: 0.5),
          shape: context.spacing.radiusPill,
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.spacingMd,
            vertical: context.spacing.spacingSm,
          ),
        ),
        child: Text(
          label,
          style: context.typography.labelLarge.copyWith(color: onFill),
        ),
      ),
    );
  }
}
