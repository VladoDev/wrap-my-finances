import 'package:flutter/material.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// The history screen's empty state: a warm, illustrated-with-existing-
/// tokens placeholder — a large icon in a soft circular fill plus friendly
/// copy — never a plain "no data" string (FR-014). No new illustration
/// package or asset, per the plan input; the same "reuse the token system,
/// no new dependency" choice `004` made for its success checkmark.
class HistoryEmptyState extends StatelessWidget {
  /// Creates the empty state.
  const HistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.outline),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 56,
                color: colors.primary,
              ),
            ),
            SizedBox(height: spacing.spacingLg),
            Text(
              l10n.historyEmptyTitle,
              textAlign: TextAlign.center,
              style: context.typography.titleMedium.copyWith(
                color: colors.onBackground,
              ),
            ),
            SizedBox(height: spacing.spacingXs),
            Text(
              l10n.historyEmptySubtitle,
              textAlign: TextAlign.center,
              style: context.typography.bodyMedium.copyWith(
                color: colors.onBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
