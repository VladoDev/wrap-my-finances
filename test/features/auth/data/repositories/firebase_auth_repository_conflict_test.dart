import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/auth/data/apple_sign_in_credential_provider.dart';
import 'package:wrap_my_finances/features/auth/data/google_sign_in_credential_provider.dart';
import 'package:wrap_my_finances/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_conflict.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_conflict_resolution.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_result.dart';
import 'package:wrap_my_finances/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:wrap_my_finances/features/categories/data/repositories/category_repository_impl.dart';
import 'package:wrap_my_finances/features/expenses/data/datasources/expense_remote_data_source.dart';
import 'package:wrap_my_finances/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';

class _FakeGoogleSignInCredentialProvider
    implements GoogleSignInCredentialProvider {
  _FakeGoogleSignInCredentialProvider(this.credential);
  final AuthCredential credential;

  @override
  Future<AuthCredential> obtainCredential() async => credential;
}

class _FakeAppleSignInCredentialProvider
    implements AppleSignInCredentialProvider {
  _FakeAppleSignInCredentialProvider(this.credential);
  final AuthCredential credential;

  @override
  Future<AuthCredential> obtainCredential() async => credential;
}

/// `firebase_auth_mocks`' `signInWithCredential` always signs back in as
/// whatever `mockUser` the instance was constructed with — it doesn't know
/// how to become a genuinely different user from a credential. This
/// override makes the switch real: calling `signInWithCredential` flips the
/// mock's identity from the initial user to [otherUser], the same way a
/// real `credential-already-in-use` resolution switches from A to B.
class _SwitchableMockFirebaseAuth extends MockFirebaseAuth {
  _SwitchableMockFirebaseAuth({
    required MockUser initialUser,
    required this.otherUser,
  }) : super(signedIn: true, mockUser: initialUser);

  final MockUser otherUser;

  @override
  Future<UserCredential> signInWithCredential(AuthCredential? credential) {
    mockUser = otherUser;
    return super.signInWithCredential(credential);
  }
}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockUser userA;
  late MockUser userB;
  late _SwitchableMockFirebaseAuth auth;
  late ExpenseRepositoryImpl expenseRepository;
  late CategoryRepositoryImpl categoryRepository;
  late FirebaseAuthRepository authRepository;
  late String aFoodCategoryId;
  late String aCustomCategoryId;
  late String bFoodCategoryId;
  late LinkConflict conflict;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    userA = MockUser(uid: 'user_a', isAnonymous: true);
    userB = MockUser(uid: 'user_b');
    auth = _SwitchableMockFirebaseAuth(initialUser: userA, otherUser: userB);
    expenseRepository = ExpenseRepositoryImpl(
      ExpenseRemoteDataSource(firestore),
      auth,
    );
    categoryRepository = CategoryRepositoryImpl(
      CategoryRemoteDataSource(firestore),
      auth,
    );
    authRepository = FirebaseAuthRepository(
      auth,
      firestore,
      _FakeGoogleSignInCredentialProvider(
        GoogleAuthProvider.credential(idToken: 'id-token'),
      ),
      _FakeAppleSignInCredentialProvider(
        OAuthProvider('apple.com').credential(
          idToken: 'id-token',
          rawNonce: 'raw-nonce',
        ),
      ),
      expenseRepository,
      categoryRepository,
    );

    // Seed A's history: defaults, a custom category, and two expenses — one
    // against a default category, one against the custom one.
    await categoryRepository.seedDefaultsIfNeeded();
    final aCategories = (await categoryRepository.getAll()).when(
      success: (value) => value,
      failed: (failure) => throw StateError('setup failed: $failure'),
    );
    aFoodCategoryId = aCategories
        .firstWhere((c) => c.nameKey == 'category_food')
        .id;
    aCustomCategoryId =
        (await categoryRepository.create(
          name: 'Side Hustle',
          color: '#00BFA5',
          iconName: 'briefcase',
        )).when(
          success: (value) => value.id,
          failed: (failure) => throw StateError('setup failed: $failure'),
        );
    await expenseRepository.create(
      Expense(
        id: '',
        amount: const Money(minorUnits: 500, currencyCode: 'MXN'),
        categoryId: aFoodCategoryId,
        date: DateTime(2026, 8, 3),
        createdAt: DateTime(2026, 8, 3),
      ),
    );
    await expenseRepository.create(
      Expense(
        id: '',
        amount: const Money(minorUnits: 1200, currencyCode: 'MXN'),
        categoryId: aCustomCategoryId,
        date: DateTime(2026, 8, 4),
        createdAt: DateTime(2026, 8, 4),
      ),
    );

    // Seed B's own, pre-existing history — defaults plus one expense —
    // while temporarily switching the mock's identity to B directly (not
    // via the repository, since that's the exact mechanism under test).
    auth.mockUser = userB;
    await categoryRepository.seedDefaultsIfNeeded();
    final bCategories = (await categoryRepository.getAll()).when(
      success: (value) => value,
      failed: (failure) => throw StateError('setup failed: $failure'),
    );
    bFoodCategoryId = bCategories
        .firstWhere((c) => c.nameKey == 'category_food')
        .id;
    await expenseRepository.create(
      Expense(
        id: '',
        amount: const Money(minorUnits: 999, currencyCode: 'MXN'),
        categoryId: bFoodCategoryId,
        date: DateTime(2026, 7, 5),
        createdAt: DateTime(2026, 7, 5),
      ),
    );
    auth.mockUser = userA;

    // Trigger the conflict: A attempts to link the credential that's
    // already tied to B.
    whenCalling(Invocation.method(#linkWithCredential, [anything]))
        .on(userA)
        .thenThrow(FirebaseAuthException(code: 'credential-already-in-use'));
    final linkResult = await authRepository.linkWithGoogle();
    conflict = (linkResult as LinkConflictDetected).conflict;
  });

  test(
    'merge reads A while still A, switches to B, and writes every item '
    "into B's collections with fresh ids — B's own prior data survives "
    'untouched alongside the merged data',
    () async {
      final result = await authRepository.resolveLinkConflict(
        conflict,
        LinkConflictResolution.merge,
      );

      expect(result, isA<Success<void>>());
      expect(auth.currentUser!.uid, 'user_b');

      final bCategoriesAfter = (await categoryRepository.getAll()).when(
        success: (value) => value,
        failed: (failure) => throw StateError('assert failed: $failure'),
      );
      // Exactly one set of default categories — A's defaults were mapped
      // onto B's existing ones by nameKey, never duplicated.
      final foodCategories = bCategoriesAfter.where(
        (c) => c.nameKey == 'category_food',
      );
      expect(foodCategories, hasLength(1));
      expect(foodCategories.single.id, bFoodCategoryId);

      // A's user category was recreated under B with a fresh id.
      final mergedCustomCategories = bCategoriesAfter.where(
        (c) => c.name == 'Side Hustle',
      );
      expect(mergedCustomCategories, hasLength(1));
      expect(mergedCustomCategories.single.id, isNot(aCustomCategoryId));

      final bExpensesAfter = await expenseRepository.watchAll().first;
      expect(bExpensesAfter, hasLength(3));
      // B's own prior expense survives, still pointing at B's own category.
      expect(
        bExpensesAfter.where((e) => e.amount.minorUnits == 999),
        hasLength(1),
      );
      // A's default-category expense now points at B's matching default,
      // not a duplicate.
      final mergedFoodExpense = bExpensesAfter.singleWhere(
        (e) => e.amount.minorUnits == 500,
      );
      expect(mergedFoodExpense.categoryId, bFoodCategoryId);
      // A's custom-category expense now points at the freshly-created B
      // category, not A's original (now-foreign) id.
      final mergedCustomExpense = bExpensesAfter.singleWhere(
        (e) => e.amount.minorUnits == 1200,
      );
      expect(mergedCustomExpense.categoryId, mergedCustomCategories.single.id);

      // A's own documents were never touched by the merge.
      final aExpensesAfter = await firestore
          .collection('users')
          .doc('user_a')
          .collection('expenses')
          .get();
      expect(aExpensesAfter.docs, hasLength(2));
    },
  );

  test(
    "discardLocal deletes A's documents before switching to B — confirmed "
    "via a direct Firestore read against A's uid — and B's own data is "
    'unchanged',
    () async {
      final result = await authRepository.resolveLinkConflict(
        conflict,
        LinkConflictResolution.discardLocal,
      );

      expect(result, isA<Success<void>>());
      expect(auth.currentUser!.uid, 'user_b');

      final aExpensesAfter = await firestore
          .collection('users')
          .doc('user_a')
          .collection('expenses')
          .get();
      final aCategoriesAfter = await firestore
          .collection('users')
          .doc('user_a')
          .collection('categories')
          .get();
      expect(aExpensesAfter.docs, isEmpty);
      expect(aCategoriesAfter.docs, isEmpty);

      final bExpensesAfter = await expenseRepository.watchAll().first;
      expect(bExpensesAfter, hasLength(1));
      expect(bExpensesAfter.single.amount.minorUnits, 999);

      final bCategoriesAfter = (await categoryRepository.getAll()).when(
        success: (value) => value,
        failed: (failure) => throw StateError('assert failed: $failure'),
      );
      expect(
        bCategoriesAfter.where((c) => c.nameKey == 'category_food'),
        hasLength(1),
      );
      expect(bCategoriesAfter.where((c) => c.name == 'Side Hustle'), isEmpty);
    },
  );
}
