import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/categories/presentation/category_icon_map.dart';
import 'package:wrap_my_finances/features/categories/presentation/category_name_resolver.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/presentation/money_format.dart';

/// A single history row: amount, category (icon + resolved name — never
/// color alone, per FR-004/Constitution Principle 8), and time. [category]
/// is resolved by the caller (a read-time join against the categories
/// collection, per `docs/DATA_MODEL.md`'s "renaming applies retroactively"
/// design) — `null` only if the referenced category can no longer be found
/// (not reachable today, since no category deactivation flow exists yet;
/// handled defensively rather than assumed impossible).
class HistoryEntryTile extends StatelessWidget {
  /// Creates the tile for [expense], resolved against [category].
  const HistoryEntryTile({
    required this.expense,
    required this.category,
    super.key,
  });

  /// The expense this row represents.
  final Expense expense;

  /// The expense's category, resolved by the caller. `null` if unresolved.
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final locale = Localizations.localeOf(context).languageCode;
    final categoryLabel = category == null
        ? expense.categoryId
        : resolveCategoryName(context, category!);
    final icon = category == null
        ? categoryIconFallback
        : resolveCategoryIcon(category!.iconName);

    final amountLabel = formatMinorUnits(expense.amount.minorUnits, locale);
    return Semantics(
      label: '$categoryLabel, $amountLabel',
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.spacingLg,
          vertical: spacing.spacingSm,
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.onSurface),
            SizedBox(width: spacing.spacingSm),
            Expanded(
              child: Text(
                categoryLabel,
                style: context.typography.bodyMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ),
            Text(
              DateFormat.jm(locale).format(expense.date),
              style: context.typography.bodySmall.copyWith(
                color: colors.onSurface,
              ),
            ),
            SizedBox(width: spacing.spacingMd),
            Text(
              formatMinorUnits(expense.amount.minorUnits, locale),
              style: context.typography.bodyMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
