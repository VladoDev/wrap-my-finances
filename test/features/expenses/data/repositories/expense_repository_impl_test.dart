import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wrap_my_finances/core/errors/failure.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/expenses/data/datasources/expense_remote_data_source.dart';
import 'package:wrap_my_finances/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';

class _MockExpenseRemoteDataSource extends Mock
    implements ExpenseRemoteDataSource {}

Expense _draft({required int minorUnits, String categoryId = 'cat_food'}) {
  final now = DateTime.now();
  return Expense(
    id: '',
    amount: Money(minorUnits: minorUnits, currencyCode: 'MXN'),
    categoryId: categoryId,
    date: now,
    createdAt: now,
  );
}

void main() {
  group('create (US1)', () {
    test(
      'writes a document under users/{uid}/expenses with a repository-assigned id',
      () async {
        final firestore = FakeFirebaseFirestore();
        final auth = MockFirebaseAuth(signedIn: true);
        final uid = auth.currentUser!.uid;
        final repository = ExpenseRepositoryImpl(
          ExpenseRemoteDataSource(firestore),
          auth,
        );

        final result = await repository.create(_draft(minorUnits: 15000));

        expect(result, isA<Success<Expense>>());
        final expense = (result as Success<Expense>).value;
        expect(expense.id, isNotEmpty);

        final snapshot = await firestore
            .collection('users')
            .doc(uid)
            .collection('expenses')
            .doc(expense.id)
            .get();
        expect(snapshot.exists, isTrue);
        expect(snapshot.data()!['amountMinor'], 15000);
      },
    );
  });

  group('decimal precision (US2)', () {
    test(
      'persisting a sequence of cent amounts sums to the exact expected total',
      () async {
        final firestore = FakeFirebaseFirestore();
        final auth = MockFirebaseAuth(signedIn: true);
        final uid = auth.currentUser!.uid;
        final repository = ExpenseRepositoryImpl(
          ExpenseRemoteDataSource(firestore),
          auth,
        );

        const amounts = [10, 20, 5, 333, 1267]; // cents — deliberately awkward
        for (final amount in amounts) {
          final result = await repository.create(_draft(minorUnits: amount));
          expect(result, isA<Success<Expense>>());
        }

        final snapshot = await firestore
            .collection('users')
            .doc(uid)
            .collection('expenses')
            .get();
        final total = snapshot.docs
            .map((doc) => doc.data()['amountMinor']! as int)
            .fold<int>(0, (runningTotal, amount) => runningTotal + amount);

        expect(total, amounts.reduce((a, b) => a + b));
      },
    );
  });

  group('local write failure (US4)', () {
    setUpAll(() {
      registerFallbackValue(
        Expense(
          id: '',
          amount: const Money(minorUnits: 0, currencyCode: 'MXN'),
          categoryId: 'cat_food',
          date: DateTime(2026),
          createdAt: DateTime(2026),
        ),
      );
    });

    test(
      'a data source failure maps to Failed(UnknownFailure), never an '
      'exception',
      () async {
        final dataSource = _MockExpenseRemoteDataSource();
        final auth = MockFirebaseAuth(signedIn: true);
        when(() => dataSource.create(any(), any())).thenThrow(
          FirebaseException(plugin: 'cloud_firestore', code: 'unknown'),
        );
        final repository = ExpenseRepositoryImpl(dataSource, auth);

        final result = await repository.create(_draft(minorUnits: 500));

        expect(result, isA<Failed<Expense>>());
        expect((result as Failed<Expense>).failure, isA<UnknownFailure>());
      },
    );
  });
}
