import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/core/design_system/widgets/app_button.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_conflict.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_conflict_resolution.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// FR-004/FR-005's explicit-decision screen: presents [conflict] with no
/// default choice, and never discards anything without a second,
/// clearly-named confirmation (merging is non-destructive, so it alone
/// skips that second step).
class LinkConflictPage extends ConsumerStatefulWidget {
  /// Creates the page for [conflict].
  const LinkConflictPage({required this.conflict, super.key});

  /// The conflict being resolved.
  final LinkConflict conflict;

  @override
  ConsumerState<LinkConflictPage> createState() => _LinkConflictPageState();
}

class _LinkConflictPageState extends ConsumerState<LinkConflictPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(spacing.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.settingsLinkConflictTitle,
                style: context.typography.displayLarge.copyWith(
                  color: colors.onBackground,
                ),
              ),
              SizedBox(height: spacing.spacingSm),
              Text(
                l10n.settingsLinkConflictBody,
                style: context.typography.bodyMedium.copyWith(
                  color: colors.onBackground,
                ),
              ),
              SizedBox(height: spacing.spacingLg),
              AppButton(
                label: l10n.settingsLinkConflictMergeOption,
                onPressed: _merge,
              ),
              SizedBox(height: spacing.spacingSm),
              AppButton(
                label: l10n.settingsLinkConflictDiscardOption,
                variant: AppButtonVariant.danger,
                onPressed: _confirmDiscard,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _merge() => _resolve(LinkConflictResolution.merge);

  Future<void> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsLinkConflictDiscardConfirmTitle),
        content: Text(l10n.settingsLinkConflictDiscardConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.settingsLinkConflictDiscardOption),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await _resolve(LinkConflictResolution.discardLocal);
    }
  }

  Future<void> _resolve(LinkConflictResolution resolution) async {
    final authRepository = ref.read(authRepositoryProvider);
    final result = await authRepository.resolveLinkConflict(
      widget.conflict,
      resolution,
    );
    if (!mounted) return;

    result.when(
      success: (_) {
        ref
          ..invalidate(isLinkedProvider)
          ..invalidate(linkedProviderLabelProvider);
        context.go('/settings');
      },
      // A failure here (e.g. FR-006's offline case) leaves this screen
      // showing so the user can retry — never silently drops the
      // still-unresolved conflict.
      failed: (_) {},
    );
  }
}
