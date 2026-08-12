import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/categories/presentation/active_categories_provider.dart';
import 'package:wrap_my_finances/features/expenses/presentation/controllers/expense_history_controller.dart';
import 'package:wrap_my_finances/features/expenses/presentation/widgets/history_day_header.dart';
import 'package:wrap_my_finances/features/expenses/presentation/widgets/history_empty_state.dart';
import 'package:wrap_my_finances/features/expenses/presentation/widgets/history_entry_tile.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// The history screen (FR-001–FR-009, FR-014): a chronological, day-grouped
/// list of logged expenses with swipe-to-delete and an undoable window.
/// Reached only via the floating nav bar `005`'s `US3` adds — this page
/// itself doesn't know how it was reached.
class ExpenseHistoryPage extends ConsumerWidget {
  /// Creates the page.
  const ExpenseHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseHistoryControllerProvider);
    final controller = ref.read(expenseHistoryControllerProvider.notifier);
    final categories =
        ref.watch(activeCategoriesProvider).valueOrNull ?? const [];
    final categoryById = <String, Category>{
      for (final category in categories) category.id: category,
    };
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    if (state.dayGroups.isEmpty) {
      return const Scaffold(body: SafeArea(child: HistoryEmptyState()));
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          children: [
            for (final group in state.dayGroups) ...[
              HistoryDayHeader(
                day: group.day,
                subtotalMinor: group.subtotalMinor,
              ),
              for (final expense in group.expenses)
                Dismissible(
                  key: ValueKey(expense.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: colors.danger,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(
                      horizontal: context.spacing.spacingLg,
                    ),
                    child: Icon(Icons.delete_outline, color: colors.onDanger),
                  ),
                  onDismissed: (_) {
                    controller.requestDelete(expense.id);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(l10n.historyExpenseDeletedMessage),
                          action: SnackBarAction(
                            label: l10n.commonUndo,
                            onPressed: () => controller.undoDelete(expense.id),
                          ),
                        ),
                      );
                  },
                  child: HistoryEntryTile(
                    expense: expense,
                    category: categoryById[expense.categoryId],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
