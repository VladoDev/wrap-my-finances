import 'package:flutter/material.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/expenses/presentation/money_format.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/widgets/wrapped_count_up_text.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// Wrapped story 1 — "The Grand Total" (`docs/UI_UX_SPEC.md` §3): the
/// month's total spend, with a count-up animation.
class WrappedSceneGrandTotal extends StatelessWidget {
  /// Creates the scene for [total].
  const WrappedSceneGrandTotal({required this.total, super.key});

  /// The month's total spend.
  final Money total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final colors = context.colors;

    return Center(
      child: WrappedCountUpText(
        value: total.minorUnits / 100,
        formatter: (value) => l10n.wrappedGrandTotalTitle(
          formatMinorUnits((value * 100).round(), locale),
        ),
        style: context.typography.displayLarge.copyWith(
          color: colors.surface,
        ),
      ),
    );
  }
}
