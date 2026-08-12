import 'package:flutter/material.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/categories/presentation/category_icon_map.dart';
import 'package:wrap_my_finances/features/categories/presentation/category_name_resolver.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// The rounded bottom sheet shown after entering an amount
/// (`docs/UI_UX_SPEC.md` §2 step 3): a grid of category tiles, already
/// ordered by usage frequency by [categories] (see
/// `CategoryRepository.watchActive()`). Tapping a tile calls [onSelected]
/// once and does not manage loading/dismissal itself — the caller (via
/// `ExpenseCaptureController.submit`) owns that.
class CategoryPickerSheet extends StatelessWidget {
  /// Creates the sheet for [categories].
  const CategoryPickerSheet({
    required this.categories,
    required this.onSelected,
    super.key,
  });

  /// Active categories, already frequency-ordered.
  final List<Category> categories;

  /// Called with the tapped category's id.
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(spacing.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.categoryPickerTitle,
              style: context.typography.titleMedium.copyWith(
                color: context.colors.onSurface,
              ),
            ),
            SizedBox(height: spacing.spacingMd),
            Wrap(
              spacing: spacing.spacingSm,
              runSpacing: spacing.spacingSm,
              children: [
                for (final category in categories)
                  _CategoryTile(
                    category: category,
                    onTap: () => onSelected(category.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  Color get _fillColor {
    final hex = category.color.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final label = resolveCategoryName(context, category);
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMd),
          side: BorderSide(color: colors.outline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(spacing.radiusMd),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 88, minHeight: 88),
            padding: EdgeInsets.all(spacing.spacingSm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _fillColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    resolveCategoryIcon(category.iconName),
                    color: colors.onBackground,
                  ),
                ),
                SizedBox(height: spacing.spacingXs),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: context.typography.bodySmall.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
