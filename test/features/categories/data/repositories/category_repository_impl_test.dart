import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:wrap_my_finances/features/categories/data/default_categories.dart';
import 'package:wrap_my_finances/features/categories/data/repositories/category_repository_impl.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';

void main() {
  group('seeding (US1/US3)', () {
    test(
      'seedDefaultsIfNeeded creates exactly 7 categories matching the seed '
      'table',
      () async {
        final firestore = FakeFirebaseFirestore();
        final auth = MockFirebaseAuth(signedIn: true);
        final repository = CategoryRepositoryImpl(
          CategoryRemoteDataSource(firestore),
          auth,
        );

        final result = await repository.seedDefaultsIfNeeded();
        expect(result, isA<Success<void>>());

        final active =
            (await repository.getActive() as Success<List<Category>>).value;
        expect(active, hasLength(7));
        for (final category in active) {
          expect(category.isDefault, isTrue);
          expect(category.name, isNull);
          expect(category.nameKey, isNotNull);
          expect(
            defaultCategorySeeds.map((s) => s.nameKey),
            contains(category.nameKey),
          );
        }
      },
    );

    test('a second call is a no-op (does not duplicate)', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(signedIn: true);
      final repository = CategoryRepositoryImpl(
        CategoryRemoteDataSource(firestore),
        auth,
      );

      await repository.seedDefaultsIfNeeded();
      await repository.seedDefaultsIfNeeded();

      final active =
          (await repository.getActive() as Success<List<Category>>).value;
      expect(active, hasLength(7));
    });
  });

  group('frequency ordering (US3)', () {
    test(
      'watchActive/getActive order categories by usageCount descending',
      () async {
        final firestore = FakeFirebaseFirestore();
        final auth = MockFirebaseAuth(signedIn: true);
        final repository = CategoryRepositoryImpl(
          CategoryRemoteDataSource(firestore),
          auth,
        );
        await repository.seedDefaultsIfNeeded();

        final seeded =
            (await repository.getActive() as Success<List<Category>>).value;
        final target = seeded.firstWhere((c) => c.nameKey == 'category_other');

        // "category_other" is seeded last (sortOrder 7) but used most.
        await repository.incrementUsage(target.id);
        await repository.incrementUsage(target.id);
        await repository.incrementUsage(target.id);

        final reordered =
            (await repository.getActive() as Success<List<Category>>).value;
        expect(reordered.first.nameKey, 'category_other');
        expect(reordered.first.usageCount, 3);
      },
    );
  });
}
