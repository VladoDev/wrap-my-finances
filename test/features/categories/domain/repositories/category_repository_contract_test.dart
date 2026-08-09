import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/categories/domain/repositories/category_repository.dart';

/// Proves `CategoryRepository` is a compilable, exercisable contract with
/// no Flutter/Firebase dependency — the actual implementation arrives in
/// `004`.
class _FakeCategoryRepository implements CategoryRepository {
  final List<Category> _stored = [
    Category(
      id: 'cat_food',
      color: '#FF5722',
      iconName: 'restaurant',
      isDefault: true,
      sortOrder: 1,
      isActive: true,
      usageCount: 0,
      nameKey: 'category_food',
    ),
  ];

  @override
  Future<Result<List<Category>>> getActive() async {
    return Success(_stored.where((c) => c.isActive).toList());
  }

  @override
  Stream<List<Category>> watchActive() {
    return Stream.value(_stored.where((c) => c.isActive).toList());
  }

  @override
  Future<Result<void>> incrementUsage(String categoryId) async {
    return const Success(null);
  }
}

void main() {
  test(
    'a fake CategoryRepository compiles and exercises getActive/watchActive/incrementUsage',
    () async {
      final repository = _FakeCategoryRepository();

      final active = await repository.getActive();
      expect(active, isA<Success<List<Category>>>());

      final watched = await repository.watchActive().first;
      expect(watched, hasLength(1));

      final incremented = await repository.incrementUsage('cat_food');
      expect(incremented, isA<Success<void>>());
    },
  );
}
