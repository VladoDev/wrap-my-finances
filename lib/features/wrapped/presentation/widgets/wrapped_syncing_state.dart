import 'package:flutter/material.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// Shown instead of a scene's figure when `WrappedSummary.isSyncing` is
/// `true` — the local cache's document count for the month doesn't yet
/// match the server's, so no total can be shown as confidently correct
/// (FR-012).
class WrappedSyncingState extends StatelessWidget {
  /// Creates the syncing indicator.
  const WrappedSyncingState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: context.colors.surface),
          SizedBox(height: context.spacing.spacingMd),
          Text(
            l10n.wrappedSyncingMessage,
            style: context.typography.titleMedium.copyWith(
              color: context.colors.surface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
