import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/features/expenses/data/device_locale_defaults.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// Distinct `"YYYY-MM"` keys across [expenses], most-recent-first, no
/// duplicates — derived client-side from data already loaded by
/// `ExpenseHistoryController`, per
/// `specs/006-monthly-wrapped-summary/research.md` #3 (no new Firestore
/// query for manual Wrapped access).
List<String> distinctMonthKeys(List<Expense> expenses) {
  final sorted = [...expenses]..sort((a, b) => b.date.compareTo(a.date));
  final seen = <String>{};
  final ordered = <String>[];
  for (final expense in sorted) {
    final key = DeviceLocaleDefaults.monthKeyFor(expense.date);
    if (seen.add(key)) ordered.add(key);
  }
  return ordered;
}

/// The bottom sheet listing every month with data, for manual Wrapped
/// access (FR-005) — reachable from `ExpenseHistoryPage` regardless of
/// whether a month was already auto-shown.
class HistoryMonthPickerSheet extends StatelessWidget {
  /// Creates the sheet for [monthKeys] (already ordered, most-recent-first).
  const HistoryMonthPickerSheet({required this.monthKeys, super.key});

  /// The months to list, in display order.
  final List<String> monthKeys;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final spacing = context.spacing;
    final router = GoRouter.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(spacing.spacingMd),
            child: Text(
              l10n.wrappedMonthPickerTitle,
              style: context.typography.titleMedium,
            ),
          ),
          for (final monthKey in monthKeys)
            ListTile(
              title: Text(_formatMonth(monthKey, locale)),
              onTap: () {
                Navigator.of(context).pop();
                router.go('/wrapped/$monthKey');
              },
            ),
          SizedBox(height: spacing.spacingMd),
        ],
      ),
    );
  }

  String _formatMonth(String monthKey, String locale) {
    final parts = monthKey.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    return DateFormat.yMMMM(locale).format(date);
  }
}
