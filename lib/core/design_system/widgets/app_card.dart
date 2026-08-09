import 'package:flutter/material.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';

/// A rounded surface container with a thick border accent, per
/// `docs/UI_UX_SPEC.md` §1's "neo-brutalism, light" detail. Supply either
/// [title]/[body] text, an arbitrary [child], or both — a card with only a
/// [child] renders no text of its own, so the 200%-text-scale guarantee
/// (FR-013) does not apply to that configuration (see spec.md Edge Cases).
class AppCard extends StatelessWidget {
  /// Creates a card. [title]/[body] must already be localized by the
  /// caller.
  const AppCard({this.title, this.body, this.child, super.key});

  /// Optional title slot, rendered with `titleMedium`.
  final String? title;

  /// Optional body slot, rendered with `bodyMedium`.
  final String? body;

  /// Optional arbitrary content, rendered below [title]/[body].
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;

    return Container(
      padding: EdgeInsets.all(spacing.spacingMd),
      margin: EdgeInsets.all(spacing.spacingLg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(spacing.radiusMd),
        border: Border.all(color: colors.outline, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: EdgeInsets.only(bottom: spacing.spacingSm),
              child: Text(
                title!,
                style: typography.titleMedium.copyWith(color: colors.onSurface),
              ),
            ),
          if (body != null)
            Text(
              body!,
              style: typography.bodyMedium.copyWith(color: colors.onSurface),
            ),
          ?child,
        ],
      ),
    );
  }
}
