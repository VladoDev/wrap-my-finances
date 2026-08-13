import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';

/// Live, `sortOrder`-ordered categories, active *and* archived — a thin
/// `StreamProvider` wrapper over `CategoryRepository.watchAll()`. Distinct
/// from `activeCategoriesProvider`: History's expense→category resolution
/// needs this one, since a historical expense can reference an archived
/// category (US7) and `activeCategoriesProvider` would silently drop it.
final allCategoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});
