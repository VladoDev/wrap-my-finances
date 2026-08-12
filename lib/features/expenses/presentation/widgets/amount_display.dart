import 'package:flutter/material.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// The large, chunky amount readout at the top of the capture screen
/// (`docs/UI_UX_SPEC.md` §2). Purely presentational — [formattedAmount] is
/// already locale-formatted by `AmountInputState`.
class AmountDisplay extends StatelessWidget {
  /// Creates the display for [formattedAmount].
  const AmountDisplay({required this.formattedAmount, super.key});

  /// The locale-formatted amount string to render.
  final String formattedAmount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: AppLocalizations.of(context)!.keypadAmountSemanticLabel,
      value: formattedAmount,
      child: ExcludeSemantics(
        child: Text(
          formattedAmount,
          style: context.typography.displayLarge.copyWith(
            color: colors.onBackground,
          ),
        ),
      ),
    );
  }
}
