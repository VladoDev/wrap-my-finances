import 'package:flutter/material.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/categories/presentation/category_name_resolver.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/widgets/wrapped_count_up_text.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// Wrapped story 3 — "The Habit" (`docs/UI_UX_SPEC.md` §3): how many
/// transactions landed in the top category this month — not the month's
/// total expense count.
class WrappedSceneHabit extends StatelessWidget {
  /// Creates the scene.
  const WrappedSceneHabit({
    required this.topCategoryExpenseCount,
    required this.topCategoryId,
    required this.topCategory,
    super.key,
  });

  /// `WrappedSummary.topCategoryExpenseCount`.
  final int topCategoryExpenseCount;

  /// The top category's id, per `WrappedSummary.topCategoryId`.
  final String? topCategoryId;

  /// The resolved category, if found.
  final Category? topCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoryLabel = topCategory == null
        ? (topCategoryId ?? '')
        : resolveCategoryName(context, topCategory!);

    return Center(
      child: WrappedCountUpText(
        value: topCategoryExpenseCount.toDouble(),
        formatter: (value) =>
            l10n.wrappedHabitTitle(value.round(), categoryLabel),
        style: context.typography.displayLarge.copyWith(
          color: context.colors.surface,
        ),
      ),
    );
  }
}
