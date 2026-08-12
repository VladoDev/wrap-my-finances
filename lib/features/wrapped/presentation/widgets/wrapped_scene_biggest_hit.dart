import 'package:flutter/material.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/expenses/presentation/money_format.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/widgets/wrapped_count_up_text.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// Wrapped story 4 — "The Biggest Hit" (`docs/UI_UX_SPEC.md` §3): the
/// single largest expense of the month.
class WrappedSceneBiggestHit extends StatelessWidget {
  /// Creates the scene for [biggestExpense].
  const WrappedSceneBiggestHit({required this.biggestExpense, super.key});

  /// The month's single largest non-deleted expense.
  final Money biggestExpense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final colors = context.colors;

    return Center(
      child: WrappedCountUpText(
        value: biggestExpense.minorUnits / 100,
        formatter: (value) => l10n.wrappedBiggestHitTitle(
          formatMinorUnits((value * 100).round(), locale),
        ),
        style: context.typography.displayLarge.copyWith(
          color: colors.surface,
        ),
      ),
    );
  }
}
