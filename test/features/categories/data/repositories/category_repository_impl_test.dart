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

  group('category management (007 US7)', () {
    late CategoryRepositoryImpl repository;

    setUp(() {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(signedIn: true);
      repository = CategoryRepositoryImpl(
        CategoryRemoteDataSource(firestore),
        auth,
      );
    });

    test(
      'create produces the exact expected Firestore document state',
      () async {
        final result = await repository.create(
          name: 'Side Hustle',
          color: '#00BFA5',
          iconName: 'briefcase',
        );

        final category = (result as Success<Category>).value;
        expect(category.name, 'Side Hustle');
        expect(category.nameKey, isNull);
        expect(category.isDefault, isFalse);
        expect(category.color, '#00BFA5');
        expect(category.iconName, 'briefcase');
        expect(category.isActive, isTrue);
        expect(category.usageCount, 0);

        final all =
            (await repository.getAll() as Success<List<Category>>).value;
        expect(all, hasLength(1));
        expect(all.single.id, category.id);
      },
    );

    test(
      'update on a user category rewrites name/color/iconName without '
      'touching isDefault/nameKey',
      () async {
        final created =
            (await repository.create(
                      name: 'Side Hustle',
                      color: '#00BFA5',
                      iconName: 'briefcase',
                    )
                    as Success<Category>)
                .value;

        await repository.update(
          created.id,
          name: 'Freelance',
          color: '#FF5722',
          iconName: 'home',
        );

        final all =
            (await repository.getAll() as Success<List<Category>>).value;
        final updated = all.single;
        expect(updated.name, 'Freelance');
        expect(updated.nameKey, isNull);
        expect(updated.isDefault, isFalse);
        expect(updated.color, '#FF5722');
        expect(updated.iconName, 'home');
      },
    );

    test(
      'reorder rewrites sortOrder for every category in orderedIds, '
      '1-based, matching the given order',
      () async {
        final a =
            (await repository.create(
                      name: 'A',
                      color: '#FF5722',
                      iconName: 'home',
                    )
                    as Success<Category>)
                .value;
        final b =
            (await repository.create(
                      name: 'B',
                      color: '#FF5722',
                      iconName: 'home',
                    )
                    as Success<Category>)
                .value;
        final c =
            (await repository.create(
                      name: 'C',
                      color: '#FF5722',
                      iconName: 'home',
                    )
                    as Success<Category>)
                .value;

        await repository.reorder([c.id, a.id, b.id]);

        final all =
            (await repository.getAll() as Success<List<Category>>).value;
        final byId = {for (final category in all) category.id: category};
        expect(byId[c.id]!.sortOrder, 1);
        expect(byId[a.id]!.sortOrder, 2);
        expect(byId[b.id]!.sortOrder, 3);
      },
    );

    test(
      'setActive(isActive: false) archives without touching any other '
      'field, and unarchiving restores isActive: true',
      () async {
        final created =
            (await repository.create(
                      name: 'Side Hustle',
                      color: '#00BFA5',
                      iconName: 'briefcase',
                    )
                    as Success<Category>)
                .value;

        await repository.setActive(created.id, isActive: false);
        var all = (await repository.getAll() as Success<List<Category>>).value;
        expect(all.single.isActive, isFalse);
        expect(all.single.name, 'Side Hustle');

        await repository.setActive(created.id, isActive: true);
        all = (await repository.getAll() as Success<List<Category>>).value;
        expect(all.single.isActive, isTrue);
      },
    );

    test(
      'update(name: ...) on a default category clears nameKey, sets name, '
      "and flips isDefault to false — docs/DATA_MODEL.md's conversion "
      'invariant',
      () async {
        await repository.seedDefaultsIfNeeded();
        final seeded =
            (await repository.getActive() as Success<List<Category>>).value;
        final food = seeded.firstWhere((c) => c.nameKey == 'category_food');
        expect(food.isDefault, isTrue);

        await repository.update(food.id, name: 'Groceries');

        final all =
            (await repository.getAll() as Success<List<Category>>).value;
        final converted = all.firstWhere((c) => c.id == food.id);
        expect(converted.isDefault, isFalse);
        expect(converted.nameKey, isNull);
        expect(converted.name, 'Groceries');
      },
    );
  });
}
