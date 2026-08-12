import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// The small, dismissible, non-interrupting offer shown on the history
/// screen when [monthKey] had too few expenses to auto-trigger Wrapped
/// (FR-003). Dismissing marks the month seen without navigating; tapping
/// opens the full sequence.
class WrappedSuppressedCard extends ConsumerStatefulWidget {
  /// Creates the card for [monthKey] (`"YYYY-MM"`).
  const WrappedSuppressedCard({required this.monthKey, super.key});

  /// The month this offer is for.
  final String monthKey;

  @override
  ConsumerState<WrappedSuppressedCard> createState() =>
      _WrappedSuppressedCardState();
}

class _WrappedSuppressedCardState extends ConsumerState<WrappedSuppressedCard> {
  bool _dismissed = false;

  void _dismiss() {
    setState(() => _dismissed = true);
    // Fire-and-forget: the card already left the view, per the same
    // "state changes are synchronous, persistence is a side effect"
    // precedent 005's swipe-to-delete established.
    unawaited(
      ref.read(userProfileRepositoryProvider).markWrappedSeen(widget.monthKey),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final spacing = context.spacing;

    return Card(
      color: colors.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMd),
      ),
      margin: EdgeInsets.all(spacing.spacingMd),
      child: Padding(
        padding: EdgeInsets.all(spacing.spacingMd),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.wrappedSuppressedCardTitle,
                    style: context.typography.titleMedium.copyWith(
                      color: colors.onSecondary,
                    ),
                  ),
                  SizedBox(height: spacing.spacingXs),
                  GestureDetector(
                    onTap: () => context.go('/wrapped/${widget.monthKey}'),
                    child: Text(
                      l10n.wrappedSuppressedCardCta,
                      style: context.typography.bodyMedium.copyWith(
                        color: colors.onSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: MaterialLocalizations.of(context).closeButtonLabel,
              child: IconButton(
                icon: Icon(Icons.close, color: colors.onSecondary),
                onPressed: _dismiss,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
