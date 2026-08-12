import 'package:flutter/material.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/categories/presentation/category_name_resolver.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// Wrapped story 2 — "The Black Hole" (`docs/UI_UX_SPEC.md` §3): the
/// month's top-spending category, resolved at display time (FR-011) so a
/// rename applies retroactively — the same
/// resolve-with-a-raw-id-fallback pattern `HistoryEntryTile` established.
class WrappedSceneBlackHole extends StatelessWidget {
  /// Creates the scene. [topCategoryId] is the raw id from
  /// `WrappedSummary`; [topCategory] is the caller's resolved lookup,
  /// `null` if it couldn't be resolved.
  const WrappedSceneBlackHole({
    required this.topCategoryId,
    required this.topCategory,
    super.key,
  });

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
      child: Text(
        l10n.wrappedBlackHoleTitle(categoryLabel),
        style: context.typography.displayLarge.copyWith(
          color: context.colors.surface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
