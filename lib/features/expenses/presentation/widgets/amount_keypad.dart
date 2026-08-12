import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/core/design_system/widgets/app_button.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// The oversized numeric keypad (`docs/UI_UX_SPEC.md` §2): digits,
/// locale-aware decimal separator, backspace, and the "Next" action —
/// every color/spacing/radius value from `context.colors`/`.spacing`, none
/// new (Constitution Principle 9). Digit/backspace keys sit in the lower
/// third of the screen so the primary action stays reachable one-handed.
class AmountKeypad extends StatelessWidget {
  /// Creates the keypad.
  const AmountKeypad({
    required this.decimalSeparatorSymbol,
    required this.isNextEnabled,
    required this.onDigit,
    required this.onDecimalSeparator,
    required this.onBackspace,
    required this.onNext,
    super.key,
  });

  /// The active locale's decimal separator symbol.
  final String decimalSeparatorSymbol;

  /// Whether the "Next" button should be enabled (FR-010).
  final bool isNextEnabled;

  /// Called with a single digit character when a digit key is tapped.
  final ValueChanged<String> onDigit;

  /// Called when the decimal separator key is tapped.
  final VoidCallback onDecimalSeparator;

  /// Called when the backspace key is tapped.
  final VoidCallback onBackspace;

  /// Called when "Next" is tapped.
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _KeypadRow(keys: const ['1', '2', '3'], onDigit: onDigit),
        SizedBox(height: spacing.spacingSm),
        _KeypadRow(keys: const ['4', '5', '6'], onDigit: onDigit),
        SizedBox(height: spacing.spacingSm),
        _KeypadRow(keys: const ['7', '8', '9'], onDigit: onDigit),
        SizedBox(height: spacing.spacingSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _KeypadKey(
              label: decimalSeparatorSymbol,
              onTap: onDecimalSeparator,
            ),
            _KeypadKey(label: '0', onTap: () => onDigit('0')),
            _KeypadKey(
              icon: Icons.backspace_outlined,
              semanticLabel: MaterialLocalizations.of(
                context,
              ).backButtonTooltip,
              onTap: onBackspace,
            ),
          ],
        ),
        SizedBox(height: spacing.spacingLg),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: AppLocalizations.of(context)!.commonContinue,
            onPressed: isNextEnabled ? onNext : null,
          ),
        ),
      ],
    );
  }
}

class _KeypadRow extends StatelessWidget {
  const _KeypadRow({required this.keys, required this.onDigit});

  final List<String> keys;
  final ValueChanged<String> onDigit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final digit in keys)
          _KeypadKey(label: digit, onTap: () => onDigit(digit)),
      ],
    );
  }
}

/// A single soft, tactile "bubble" key — pill-shaped, ≥48×48dp, per
/// `docs/UI_UX_SPEC.md` §1/§2 and Constitution Principle 8.
class _KeypadKey extends StatelessWidget {
  const _KeypadKey({
    required this.onTap,
    this.label,
    this.icon,
    this.semanticLabel,
  });

  final String? label;
  final IconData? icon;
  final String? semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: Material(
        color: colors.surface,
        shape: spacing.radiusPill,
        child: InkWell(
          customBorder: spacing.radiusPill,
          onTap: () {
            unawaited(HapticFeedback.lightImpact());
            onTap();
          },
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            child: label != null
                ? Text(
                    label!,
                    style: context.typography.titleMedium.copyWith(
                      color: colors.onSurface,
                    ),
                  )
                : Icon(icon, color: colors.onSurface),
          ),
        ),
      ),
    );
  }
}
