import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/core/design_system/widgets/app_button.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/core/errors/failure.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_result.dart';
import 'package:wrap_my_finances/features/auth/domain/usecases/link_account.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// The Account section's real content: a "link account" call to action
/// with Google/Apple options while unlinked, or a linked-status line once
/// a provider is attached (`007` US1) — plus, always, the permanent
/// account-deletion action (US6, spec.md acceptance criterion 8). Never an
/// interruption — this only ever renders inside Settings, per FR-001.
class SettingsAccountSection extends ConsumerStatefulWidget {
  /// Creates the section.
  const SettingsAccountSection({super.key});

  @override
  ConsumerState<SettingsAccountSection> createState() =>
      _SettingsAccountSectionState();
}

class _SettingsAccountSectionState
    extends ConsumerState<SettingsAccountSection> {
  bool _isLinking = false;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;

    if (_isLinking || _isDeleting) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLinkSection(context),
        SizedBox(height: spacing.spacingLg),
        AppButton(
          label: l10n.settingsDeleteAccountCta,
          variant: AppButtonVariant.danger,
          onPressed: _confirmDelete,
        ),
      ],
    );
  }

  Widget _buildLinkSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final spacing = context.spacing;
    final isLinked = ref.watch(isLinkedProvider);

    if (isLinked) {
      final providerLabel = ref.watch(linkedProviderLabelProvider) ?? '';
      return Text(
        l10n.settingsLinkedAsLabel(providerLabel),
        style: context.typography.bodyMedium.copyWith(
          color: colors.onBackground,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsLinkAccountCta,
          style: context.typography.bodyMedium.copyWith(
            color: colors.onBackground,
          ),
        ),
        SizedBox(height: spacing.spacingMd),
        AppButton(
          label: l10n.settingsLinkGoogleOption,
          onPressed: () => _link(LinkProvider.google),
        ),
        SizedBox(height: spacing.spacingSm),
        AppButton(
          label: l10n.settingsLinkAppleOption,
          variant: AppButtonVariant.secondary,
          onPressed: () => _link(LinkProvider.apple),
        ),
      ],
    );
  }

  Future<void> _link(LinkProvider provider) async {
    setState(() => _isLinking = true);
    final useCase = ref.read(linkAccountUseCaseProvider);
    final result = await useCase(provider);
    if (!mounted) return;
    setState(() => _isLinking = false);

    switch (result) {
      case LinkSucceeded():
        ref
          ..invalidate(isLinkedProvider)
          ..invalidate(linkedProviderLabelProvider);
      case LinkConflictDetected(:final conflict):
        unawaited(context.push('/link-conflict', extra: conflict));
      case LinkFailed(:final failure):
        // Any other LinkFailed (not offline) leaves the CTA visible, no
        // separate handling needed, so the user can simply retry.
        if (failure is NetworkFailure) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.settingsLinkUnavailableOfflineMessage),
            ),
          );
        }
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsDeleteAccountConfirmTitle),
        content: Text(l10n.settingsDeleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.settingsDeleteAccountCta),
          ),
        ],
      ),
    );
    if (!mounted || !(confirmed ?? false)) return;

    setState(() => _isDeleting = true);
    final useCase = ref.read(deleteAccountUseCaseProvider);
    final result = await useCase(
      onReauthRequired: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsDeleteAccountReauthMessage)),
        );
      },
    );
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (result case Success()) {
      // The account and its identity are gone — the app needs a new
      // anonymous session before any further write, per Constitution
      // Principle 2 (never leaves a write stranded with no session at
      // all). Established eagerly here rather than left to whichever
      // write happens to come next.
      await ref.read(authRepositoryProvider).ensureSignedIn();
      if (!mounted) return;
      ref
        ..invalidate(isLinkedProvider)
        ..invalidate(linkedProviderLabelProvider);
      context.go('/');
    }
  }
}
