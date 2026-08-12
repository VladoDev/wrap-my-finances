import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/categories/presentation/active_categories_provider.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/pages/wrapped_page.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/widgets/wrapped_scene_biggest_hit.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/widgets/wrapped_scene_black_hole.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/widgets/wrapped_scene_grand_total.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/widgets/wrapped_scene_habit.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/widgets/wrapped_share_card.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/widgets/wrapped_syncing_state.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/wrapped_summary_provider.dart';

/// Resolves [monthKey]'s `WrappedSummary` and assembles the real scene list
/// (or the single syncing scene, per FR-012) before handing it to the
/// content-agnostic `WrappedPage` sequencer. This is the `/wrapped/:monthKey`
/// route's actual builder.
class WrappedRoutePage extends ConsumerWidget {
  /// Creates the route page for [monthKey].
  const WrappedRoutePage({
    required this.monthKey,
    this.onDismissed,
    super.key,
  });

  /// `"YYYY-MM"`.
  final String monthKey;

  /// Forwarded to `WrappedPage.onDismissed`.
  final VoidCallback? onDismissed;

  void _handleDismissed(WidgetRef ref, double completionRatio) {
    // Fire-and-forget, per data-model.md §4: mark seen only on actual
    // dismissal (never merely from evaluating the trigger), so a month the
    // user never interacted with isn't silently marked as seen.
    unawaited(
      ref.read(userProfileRepositoryProvider).markWrappedSeen(monthKey),
    );
    ref.read(analyticsServiceProvider).logWrappedCompletion(completionRatio);
    onDismissed?.call();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(wrappedSummaryProvider(monthKey));
    final colors = context.colors;

    return summaryAsync.when(
      loading: () => Scaffold(
        backgroundColor: colors.onBackground,
        body: Center(
          child: CircularProgressIndicator(color: colors.surface),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: colors.onBackground,
        body: const SizedBox.shrink(),
      ),
      data: (summary) {
        if (summary.isSyncing) {
          return WrappedPage(
            monthKey: monthKey,
            scenes: const [WrappedSyncingState()],
            onDismissed: (ratio) => _handleDismissed(ref, ratio),
          );
        }

        final categories =
            ref.watch(activeCategoriesProvider).valueOrNull ?? const [];
        final categoryById = <String, Category>{
          for (final category in categories) category.id: category,
        };
        final topCategory = summary.topCategoryId == null
            ? null
            : categoryById[summary.topCategoryId];

        return WrappedPage(
          monthKey: monthKey,
          scenes: [
            WrappedSceneGrandTotal(total: summary.total),
            WrappedSceneBlackHole(
              topCategoryId: summary.topCategoryId,
              topCategory: topCategory,
            ),
            WrappedSceneHabit(
              topCategoryExpenseCount: summary.topCategoryExpenseCount,
              topCategoryId: summary.topCategoryId,
              topCategory: topCategory,
            ),
            WrappedSceneBiggestHit(biggestExpense: summary.biggestExpense!),
            WrappedShareCard(
              monthKey: monthKey,
              topCategoryId: summary.topCategoryId,
              topCategory: topCategory,
              topCategoryExpenseCount: summary.topCategoryExpenseCount,
              total: summary.total,
            ),
          ],
          onDismissed: (ratio) => _handleDismissed(ref, ratio),
        );
      },
    );
  }
}
