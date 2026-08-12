import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';

/// Live, frequency-ordered active categories (FR-006) — a thin
/// `StreamProvider` wrapper over `CategoryRepository.watchActive()`, per
/// `docs/TECH_STACK.md`'s "Riverpod owns... stream subscriptions" rule.
final activeCategoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchActive();
});
