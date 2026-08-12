import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/features/expenses/presentation/money_format.dart';

/// A day group's header: the calendar date and that day's subtotal, both
/// locale-formatted via `intl` (Constitution Principle 9 — never string
/// concatenation).
class HistoryDayHeader extends StatelessWidget {
  /// Creates the header for [day], showing [subtotalMinor].
  const HistoryDayHeader({
    required this.day,
    required this.subtotalMinor,
    super.key,
  });

  /// The calendar day this header labels.
  final DateTime day;

  /// The day's exact subtotal, in integer minor units.
  final int subtotalMinor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final locale = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.spacingLg,
        vertical: spacing.spacingSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat.yMMMMd(locale).format(day),
            style: context.typography.titleMedium.copyWith(
              color: colors.onBackground,
            ),
          ),
          Text(
            formatMinorUnits(subtotalMinor, locale),
            style: context.typography.bodyMedium.copyWith(
              color: colors.onBackground,
            ),
          ),
        ],
      ),
    );
  }
}
