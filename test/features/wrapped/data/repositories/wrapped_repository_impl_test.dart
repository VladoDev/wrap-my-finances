import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:wrap_my_finances/features/categories/data/repositories/category_repository_impl.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/categories/domain/repositories/category_repository.dart';
import 'package:wrap_my_finances/features/expenses/data/datasources/expense_remote_data_source.dart';
import 'package:wrap_my_finances/features/expenses/data/models/expense_model.dart';
import 'package:wrap_my_finances/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/expenses/domain/repositories/expense_repository.dart';
import 'package:wrap_my_finances/features/wrapped/data/datasources/wrapped_remote_data_source.dart';
import 'package:wrap_my_finances/features/wrapped/data/repositories/wrapped_repository_impl.dart';
import 'package:wrap_my_finances/features/wrapped/domain/entities/wrapped_summary.dart';

class _MockExpenseRepository extends Mock implements ExpenseRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockWrappedRemoteDataSource extends Mock
    implements WrappedRemoteDataSource {}

Expense _expense({
  required String id,
  required int minorUnits,
  required String categoryId,
}) {
  final date = DateTime(2026, 7, 15);
  return Expense(
    id: id,
    amount: Money(minorUnits: minorUnits, currencyCode: 'MXN'),
    categoryId: categoryId,
    date: date,
    createdAt: date,
  );
}

void main() {
  group('against a real Firestore-backed local cache', () {
    Future<
      ({
        WrappedRepositoryImpl repository,
        FakeFirebaseFirestore firestore,
        String uid,
      })
    >
    setUp(List<Expense> expenses) async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(signedIn: true);
      final uid = auth.currentUser!.uid;

      final expenseRepository = ExpenseRepositoryImpl(
        ExpenseRemoteDataSource(firestore),
        auth,
      );
      for (final expense in expenses) {
        await firestore
            .collection('users')
            .doc(uid)
            .collection('expenses')
            .doc(expense.id)
            .set(ExpenseModel.fromEntity(expense).toJson());
      }

      final categoryRepository = CategoryRepositoryImpl(
        CategoryRemoteDataSource(firestore),
        auth,
      );
      await categoryRepository.seedDefaultsIfNeeded();

      final repository = WrappedRepositoryImpl(
        expenseRepository,
        categoryRepository,
        WrappedRemoteDataSource(firestore),
        auth,
      );

      return (repository: repository, firestore: firestore, uid: uid);
    }

    test(
      'total/topCategory/topCategoryExpenseCount/biggestExpense match a '
      'hand-computed known data set',
      () async {
        final env = await setUp([
          _expense(id: 'a', minorUnits: 500, categoryId: 'cat_food'),
          _expense(id: 'b', minorUnits: 700, categoryId: 'cat_food'),
          _expense(id: 'c', minorUnits: 300, categoryId: 'cat_transport'),
        ]);

        final result = await env.repository.getSummary('2026-07');

        final summary = (result as Success<WrappedSummary>).value;
        expect(summary.isSyncing, isFalse);
        expect(summary.total.minorUnits, 1500); // 500+700+300
        expect(summary.expenseCount, 3);
        expect(summary.topCategoryId, 'cat_food'); // 1200 > 300
        expect(summary.topCategoryExpenseCount, 2);
        expect(summary.biggestExpense!.minorUnits, 700);
      },
    );

    test('a deleted expense in the same month affects none of the four '
        'figures', () async {
      final env = await setUp([
        _expense(id: 'a', minorUnits: 500, categoryId: 'cat_food'),
        _expense(id: 'b', minorUnits: 900, categoryId: 'cat_transport'),
      ]);
      await env.firestore
          .collection('users')
          .doc(env.uid)
          .collection('expenses')
          .doc('b')
          .update({'deletedAt': DateTime(2026, 7, 20)});

      final result = await env.repository.getSummary('2026-07');

      final summary = (result as Success<WrappedSummary>).value;
      expect(summary.total.minorUnits, 500);
      expect(summary.expenseCount, 1);
      expect(summary.topCategoryId, 'cat_food');
      expect(summary.biggestExpense!.minorUnits, 500);
    });

    test(
      'two categories tied on summed amount resolve deterministically to '
      'the lower sortOrder',
      () async {
        // Seed first (auto-generated Firestore ids, not literal
        // "cat_food"/"cat_transport"), then look up the real ids so the
        // expenses reference categories with a known relative sortOrder —
        // food is seeded with sortOrder 1, transport with sortOrder 2 (see
        // data/default_categories.dart).
        final firestore = FakeFirebaseFirestore();
        final auth = MockFirebaseAuth(signedIn: true);
        final uid = auth.currentUser!.uid;
        final categoryRepository = CategoryRepositoryImpl(
          CategoryRemoteDataSource(firestore),
          auth,
        );
        await categoryRepository.seedDefaultsIfNeeded();
        final categories =
            (await categoryRepository.getActive() as Success<List<Category>>)
                .value;
        final foodId = categories
            .firstWhere((c) => c.nameKey == 'category_food')
            .id;
        final transportId = categories
            .firstWhere((c) => c.nameKey == 'category_transport')
            .id;

        final expenseRepository = ExpenseRepositoryImpl(
          ExpenseRemoteDataSource(firestore),
          auth,
        );
        for (final expense in [
          _expense(id: 'a', minorUnits: 500, categoryId: transportId),
          _expense(id: 'b', minorUnits: 500, categoryId: foodId),
        ]) {
          await firestore
              .collection('users')
              .doc(uid)
              .collection('expenses')
              .doc(expense.id)
              .set(ExpenseModel.fromEntity(expense).toJson());
        }

        final repository = WrappedRepositoryImpl(
          expenseRepository,
          categoryRepository,
          WrappedRemoteDataSource(firestore),
          auth,
        );

        final result = await repository.getSummary('2026-07');

        final summary = (result as Success<WrappedSummary>).value;
        expect(summary.topCategoryId, foodId);
      },
    );

    test('zero non-deleted expenses returns an empty, non-syncing summary', (
      // No trigger/manual-access path ever reaches this in practice (spec
      // Edge Cases), but the repository handles it gracefully regardless.
    ) async {
      final env = await setUp(const []);

      final result = await env.repository.getSummary('2026-07');

      final summary = (result as Success<WrappedSummary>).value;
      expect(summary.isSyncing, isFalse);
      expect(summary.expenseCount, 0);
      expect(summary.topCategoryId, isNull);
      expect(summary.biggestExpense, isNull);
    });
  });

  group('partial-sync detection (mocked collaborators)', () {
    late _MockExpenseRepository expenseRepository;
    late _MockCategoryRepository categoryRepository;
    late _MockWrappedRemoteDataSource remoteDataSource;
    late MockFirebaseAuth auth;
    late WrappedRepositoryImpl repository;

    setUp(() {
      expenseRepository = _MockExpenseRepository();
      categoryRepository = _MockCategoryRepository();
      remoteDataSource = _MockWrappedRemoteDataSource();
      auth = MockFirebaseAuth(signedIn: true);
      repository = WrappedRepositoryImpl(
        expenseRepository,
        categoryRepository,
        remoteDataSource,
        auth,
      );
      when(
        () => categoryRepository.getActive(),
      ).thenAnswer((_) async => const Success<List<Category>>([]));
    });

    test('isSyncing is true when the local count is less than the server '
        'count', () async {
      when(() => expenseRepository.watchByMonth('2026-07')).thenAnswer(
        (_) => Stream.value([
          _expense(id: 'a', minorUnits: 100, categoryId: 'cat_food'),
        ]),
      );
      when(
        () => remoteDataSource.serverCount(auth.currentUser!.uid, '2026-07'),
      ).thenAnswer((_) async => 5);

      final result = await repository.getSummary('2026-07');

      final summary = (result as Success<WrappedSummary>).value;
      expect(summary.isSyncing, isTrue);
    });

    test(
      'isSyncing is false when the local count matches the server count',
      () async {
        when(() => expenseRepository.watchByMonth('2026-07')).thenAnswer(
          (_) => Stream.value([
            _expense(id: 'a', minorUnits: 100, categoryId: 'cat_food'),
          ]),
        );
        when(
          () => remoteDataSource.serverCount(auth.currentUser!.uid, '2026-07'),
        ).thenAnswer((_) async => 1);

        final result = await repository.getSummary('2026-07');

        final summary = (result as Success<WrappedSummary>).value;
        expect(summary.isSyncing, isFalse);
      },
    );
  });
}
