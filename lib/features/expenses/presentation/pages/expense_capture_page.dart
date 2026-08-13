import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/core/design_system/tokens/app_colors.dart';
import 'package:wrap_my_finances/core/design_system/tokens/app_spacing.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/features/categories/presentation/active_categories_provider.dart';
import 'package:wrap_my_finances/features/expenses/presentation/controllers/expense_capture_controller.dart';
import 'package:wrap_my_finances/features/expenses/presentation/current_currency_code_provider.dart';
import 'package:wrap_my_finances/features/expenses/presentation/widgets/amount_display.dart';
import 'package:wrap_my_finances/features/expenses/presentation/widgets/amount_keypad.dart';
import 'package:wrap_my_finances/features/expenses/presentation/widgets/category_picker_sheet.dart';
import 'package:wrap_my_finances/features/expenses/presentation/widgets/success_feedback_overlay.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// The app's only screen (FR-001): the app opens directly here, with no
/// dashboard, loading indicator, or welcome screen in front of it. See
/// `specs/004-quick-expense-capture/spec.md`.
class ExpenseCapturePage extends ConsumerStatefulWidget {
  /// Creates the page.
  const ExpenseCapturePage({super.key});

  @override
  ConsumerState<ExpenseCapturePage> createState() => _ExpenseCapturePageState();
}

class _ExpenseCapturePageState extends ConsumerState<ExpenseCapturePage> {
  bool _categorySheetOpen = false;
  bool _showSuccess = false;
  String? _lastAttemptedCategoryId;

  void _openCategorySheet(ExpenseCaptureController controller) {
    _categorySheetOpen = true;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        // Without this, the sheet is capped at Flutter's default 9/16 of
        // screen height with no way to grow or scroll — the category grid
        // (now open-ended since 007 lets people add their own categories)
        // was clipping past that cap instead of showing every option.
        isScrollControlled: true,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        builder: (_) => Consumer(
          builder: (context, ref, _) {
            final categories =
                ref.watch(activeCategoriesProvider).valueOrNull ?? const [];
            return CategoryPickerSheet(
              categories: categories,
              onSelected: (categoryId) {
                _lastAttemptedCategoryId = categoryId;
                unawaited(controller.submit(categoryId));
              },
            );
          },
        ),
      ).whenComplete(() => _categorySheetOpen = false),
    );
  }

  void _showLocalWriteError(ExpenseCaptureController controller) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.expenseSaveErrorMessage),
          action: SnackBarAction(
            label: l10n.commonRetry,
            onPressed: () {
              final categoryId = _lastAttemptedCategoryId;
              if (categoryId != null) {
                unawaited(controller.submit(categoryId));
              }
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(expenseCaptureControllerProvider.notifier);

    ref.listen<ExpenseCaptureState>(expenseCaptureControllerProvider, (
      previous,
      next,
    ) {
      if (next.step == CaptureStep.category && !_categorySheetOpen) {
        _openCategorySheet(controller);
      }

      final justSucceeded =
          previous != null &&
          previous.isSubmitting &&
          !next.isSubmitting &&
          next.lastError == null &&
          next.step == CaptureStep.amount;
      if (justSucceeded) {
        if (_categorySheetOpen) {
          // The *nearest* Navigator, not rootNavigator: true — 005's
          // go_router ShellRoute added a nested Navigator above this
          // page's route, so "root" no longer means "the bottom sheet's
          // own navigator" the way it coincidentally did in 004's
          // single-route tree. Popping the wrong one crashes go_router by
          // popping the last page off its stack instead of dismissing the
          // sheet.
          Navigator.of(context).pop();
        }
        setState(() => _showSuccess = true);
      }

      final newError =
          next.lastError != null && next.lastError != previous?.lastError;
      if (newError) {
        _showLocalWriteError(controller);
      }
    });

    final state = ref.watch(expenseCaptureControllerProvider);
    final env = ref.watch(appEnvironmentProvider);
    // Not otherwise used on this screen — watching it here just keeps
    // currentCurrencyCodeProvider's stream warm from launch (research.md
    // #5), since capture is always the first screen shown (FR-001).
    ref.watch(currentCurrencyCodeProvider);
    final colors = context.colors;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(spacing.spacingLg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Center(
                      child: AmountDisplay(
                        formattedAmount: state.amount.formattedDisplay,
                      ),
                    ),
                  ),
                  AmountKeypad(
                    decimalSeparatorSymbol: state.amount.decimalSeparatorSymbol,
                    isNextEnabled: state.amount.isValid,
                    onDigit: controller.appendDigit,
                    onDecimalSeparator: controller.appendDecimalSeparator,
                    onBackspace: controller.backspace,
                    onNext: controller.advanceToCategory,
                  ),
                  // Reserves clearance for AppShell's floating nav pill
                  // (005) so it never overlaps "Continuar" — composed from
                  // existing spacing tokens, not a new literal value.
                  // Verified against the pill's actual on-device footprint
                  // (icon height + its own padding/margin), not guessed.
                  SizedBox(
                    height:
                        spacing.spacingXl +
                        spacing.spacingXl +
                        spacing.spacingMd,
                  ),
                ],
              ),
            ),
            if (env.showDebugBanner)
              _DevBanner(colors: colors, spacing: spacing),
            if (_showSuccess)
              SuccessFeedbackOverlay(
                onCompleted: () => setState(() => _showSuccess = false),
              ),
          ],
        ),
      ),
    );
  }
}

/// The dev-flavor ribbon banner from `docs/UI_UX_SPEC.md` §6, carried over
/// unchanged from `003`'s now-removed `PlaceholderHomePage` — positioned so
/// it never overlaps the amount display or intercepts touches.
class _DevBanner extends StatelessWidget {
  const _DevBanner({required this.colors, required this.spacing});

  final AppColorsExtension colors;
  final AppSpacingExtension spacing;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.all(spacing.spacingMd),
        child: Container(
          key: const Key('debug-banner'),
          padding: EdgeInsets.symmetric(
            horizontal: spacing.spacingMd,
            vertical: spacing.spacingSm,
          ),
          decoration: BoxDecoration(
            color: colors.danger,
            borderRadius: BorderRadius.circular(spacing.radiusSm),
          ),
          child: Text(
            AppLocalizations.of(context)!.commonDevBuild,
            style: context.typography.bodySmall.copyWith(
              color: colors.onDanger,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
