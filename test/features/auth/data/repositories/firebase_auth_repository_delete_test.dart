import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_auth_mocks/src/mock_user_credential.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/auth/data/apple_sign_in_credential_provider.dart';
import 'package:wrap_my_finances/features/auth/data/google_sign_in_credential_provider.dart';
import 'package:wrap_my_finances/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:wrap_my_finances/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:wrap_my_finances/features/categories/data/repositories/category_repository_impl.dart';
import 'package:wrap_my_finances/features/expenses/data/datasources/expense_remote_data_source.dart';
import 'package:wrap_my_finances/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';

class _FakeGoogleSignInCredentialProvider
    implements GoogleSignInCredentialProvider {
  @override
  Future<AuthCredential> obtainCredential() async =>
      GoogleAuthProvider.credential(idToken: 'id-token');
}

class _FakeAppleSignInCredentialProvider
    implements AppleSignInCredentialProvider {
  @override
  Future<AuthCredential> obtainCredential() async =>
      OAuthProvider('apple.com').credential(
        idToken: 'id-token',
        rawNonce: 'raw-nonce',
      );
}

/// A `delete()` that throws `requires-recent-login` exactly once, then
/// succeeds — `mock_exceptions`' registry throws on every matching call
/// indefinitely once registered, so a genuinely one-shot failure needs a
/// small hand-written override instead.
// ignore: must_be_immutable
class _FlakyDeleteMockUser extends MockUser {
  _FlakyDeleteMockUser({required super.uid});

  int deleteCallCount = 0;
  int reauthenticateCallCount = 0;

  @override
  Future<void> delete() async {
    deleteCallCount++;
    if (deleteCallCount == 1) {
      throw FirebaseAuthException(code: 'requires-recent-login');
    }
  }

  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential? credential,
  ) async {
    reauthenticateCallCount++;
    return MockUserCredential(false, mockUser: this);
  }
}

void main() {
  test(
    'deleteAccount removes every expense/category document and the '
    'users/{uid} document, then calls currentUser!.delete()',
    () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(signedIn: true);
      final uid = auth.currentUser!.uid;
      final expenseRepository = ExpenseRepositoryImpl(
        ExpenseRemoteDataSource(firestore),
        auth,
      );
      final categoryRepository = CategoryRepositoryImpl(
        CategoryRemoteDataSource(firestore),
        auth,
      );
      final authRepository = FirebaseAuthRepository(
        auth,
        firestore,
        _FakeGoogleSignInCredentialProvider(),
        _FakeAppleSignInCredentialProvider(),
        expenseRepository,
        categoryRepository,
      );

      await categoryRepository.seedDefaultsIfNeeded();
      await expenseRepository.create(
        Expense(
          id: '',
          amount: const Money(minorUnits: 500, currencyCode: 'MXN'),
          categoryId: 'irrelevant',
          date: DateTime(2026, 8, 3),
          createdAt: DateTime(2026, 8, 3),
        ),
      );
      await firestore.collection('users').doc(uid).set({
        'timeZone': 'America/Mexico_City',
      });

      final result = await authRepository.deleteAccount();

      expect(result, isA<Success<void>>());
      final userDoc = await firestore.collection('users').doc(uid).get();
      expect(userDoc.exists, isFalse);
      final expenses = await firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .get();
      final categories = await firestore
          .collection('users')
          .doc(uid)
          .collection('categories')
          .get();
      expect(expenses.docs, isEmpty);
      expect(categories.docs, isEmpty);
    },
  );

  test(
    'when currentUser!.delete() throws requires-recent-login, '
    "deleteAccount() re-triggers the linked provider's credential flow and "
    'retries once, rather than surfacing the error directly',
    () async {
      final firestore = FakeFirebaseFirestore();
      final user = _FlakyDeleteMockUser(uid: 'user_a');
      // Populate providerData via the mock's own supported flow — MockUser
      // exposes no public way to construct a raw UserInfo directly (its
      // factory is @protected within firebase_auth_mocks' own library).
      await user.linkWithProvider(GoogleAuthProvider());
      final auth = MockFirebaseAuth(signedIn: true, mockUser: user);
      final expenseRepository = ExpenseRepositoryImpl(
        ExpenseRemoteDataSource(firestore),
        auth,
      );
      final categoryRepository = CategoryRepositoryImpl(
        CategoryRemoteDataSource(firestore),
        auth,
      );
      final authRepository = FirebaseAuthRepository(
        auth,
        firestore,
        _FakeGoogleSignInCredentialProvider(),
        _FakeAppleSignInCredentialProvider(),
        expenseRepository,
        categoryRepository,
      );

      final result = await authRepository.deleteAccount();

      expect(result, isA<Success<void>>());
      expect(user.deleteCallCount, 2);
      expect(user.reauthenticateCallCount, 1);
    },
  );
}
