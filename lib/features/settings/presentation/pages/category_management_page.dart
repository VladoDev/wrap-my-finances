import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/categories/presentation/all_categories_provider.dart';
import 'package:wrap_my_finances/features/categories/presentation/category_icon_map.dart';
import 'package:wrap_my_finances/features/categories/presentation/category_name_resolver.dart';
import 'package:wrap_my_finances/features/settings/presentation/widgets/category_editor_sheet.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// The Settings category management screen (US7): every category, active
/// and archived — create, rename/recolor/re-icon, drag-to-reorder, and
/// archive/unarchive. Archiving never touches any `expenses` document that
/// references the category (FR-009/FR-010).
class CategoryManagementPage extends ConsumerWidget {
  /// Creates the page.
  const CategoryManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.settingsCategoriesSection)),
      body: categoriesAsync.when(
        data: (categories) => ReorderableListView(
          onReorderItem: (oldIndex, newIndex) =>
              _reorder(ref, categories, oldIndex, newIndex),
          children: [
            for (final category in categories)
              _CategoryRow(key: ValueKey(category.id), category: category),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const SizedBox.shrink(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context),
        tooltip: l10n.settingsCategoryCreateCta,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _reorder(
    WidgetRef ref,
    List<Category> categories,
    int oldIndex,
    int newIndex,
  ) async {
    final reordered = List<Category>.of(categories);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    await ref.read(categoryRepositoryProvider).reorder([
      for (final category in reordered) category.id,
    ]);
  }

  Future<void> _openEditor(BuildContext context, [Category? category]) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryEditorSheet(category: category),
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.category, required super.key});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final label = resolveCategoryName(context, category);

    return ListTile(
      leading: Icon(
        resolveCategoryIcon(category.iconName),
        color: colors.onBackground,
      ),
      title: Text(label),
      subtitle: category.isActive
          ? null
          : Text(
              l10n.settingsCategoryArchivedLabel,
              style: context.typography.bodySmall.copyWith(
                color: colors.onSurface,
              ),
            ),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => CategoryEditorSheet(category: category),
      ),
      trailing: IconButton(
        icon: Icon(
          category.isActive ? Icons.archive_outlined : Icons.unarchive_outlined,
        ),
        tooltip: category.isActive
            ? l10n.settingsCategoryArchiveCta
            : l10n.settingsCategoryUnarchiveCta,
        onPressed: () => ref
            .read(categoryRepositoryProvider)
            .setActive(category.id, isActive: !category.isActive),
      ),
    );
  }
}
