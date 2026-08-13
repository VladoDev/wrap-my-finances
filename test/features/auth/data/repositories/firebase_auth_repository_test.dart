import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:wrap_my_finances/core/errors/failure.dart';
import 'package:wrap_my_finances/features/auth/data/apple_sign_in_credential_provider.dart';
import 'package:wrap_my_finances/features/auth/data/google_sign_in_credential_provider.dart';
import 'package:wrap_my_finances/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_conflict.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_result.dart';
import 'package:wrap_my_finances/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:wrap_my_finances/features/categories/data/repositories/category_repository_impl.dart';
import 'package:wrap_my_finances/features/expenses/data/datasources/expense_remote_data_source.dart';
import 'package:wrap_my_finances/features/expenses/data/repositories/expense_repository_impl.dart';

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

FirebaseAuthRepository _buildRepository(
  MockFirebaseAuth auth, {
  AuthCredential? googleCredential,
  AuthCredential? appleCredential,
}) {
  final firestore = FakeFirebaseFirestore();
  return FirebaseAuthRepository(
    auth,
    firestore,
    _FakeGoogleSignInCredentialProvider(
      googleCredential ?? GoogleAuthProvider.credential(idToken: 'id-token'),
    ),
    _FakeAppleSignInCredentialProvider(
      appleCredential ??
          OAuthProvider('apple.com').credential(
            idToken: 'id-token',
            rawNonce: 'raw-nonce',
          ),
    ),
    ExpenseRepositoryImpl(ExpenseRemoteDataSource(firestore), auth),
    CategoryRepositoryImpl(CategoryRemoteDataSource(firestore), auth),
  );
}

void main() {
  group('session resolution (US1)', () {
    test(
      'currentUserId is null before sign-in and reflects the uid after',
      () async {
        final auth = MockFirebaseAuth();
        final repository = _buildRepository(auth);

        expect(repository.currentUserId, isNull);

        final uid = await repository.ensureSignedIn();

        expect(repository.currentUserId, uid);
      },
    );

    test(
      'ensureSignedIn resolves immediately when already signed in',
      () async {
        final auth = MockFirebaseAuth(signedIn: true);
        final repository = _buildRepository(auth);

        final uid = await repository.ensureSignedIn();

        expect(uid, auth.currentUser!.uid);
      },
    );

    test(
      'ensureSignedIn does not re-trigger sign-in on a warm session',
      () async {
        final auth = MockFirebaseAuth(signedIn: true);
        final repository = _buildRepository(auth);
        final originalUid = auth.currentUser!.uid;

        final first = await repository.ensureSignedIn();
        final second = await repository.ensureSignedIn();

        expect(first, originalUid);
        expect(second, originalUid);
      },
    );
  });

  group('pre-auth write buffer (US2)', () {
    test(
      'runWhenAuthenticated defers operations until sign-in resolves, then '
      'runs them in order',
      () async {
        final auth = MockFirebaseAuth();
        final repository = _buildRepository(auth);
        final executionOrder = <int>[];

        final first = repository.runWhenAuthenticated((uid) async {
          executionOrder.add(1);
          return uid;
        });
        final second = repository.runWhenAuthenticated((uid) async {
          executionOrder.add(2);
          return uid;
        });

        // Neither operation has run yet — this assertion happens
        // synchronously, before any await yields control back to the
        // event loop, proving the operations were deferred rather than
        // run eagerly.
        expect(executionOrder, isEmpty);

        final results = await Future.wait([first, second]);

        expect(executionOrder, [1, 2]);
        expect(results, [auth.currentUser!.uid, auth.currentUser!.uid]);
      },
    );

    test(
      'runWhenAuthenticated runs immediately when already signed in',
      () async {
        final auth = MockFirebaseAuth(signedIn: true);
        final repository = _buildRepository(auth);

        final result = await repository.runWhenAuthenticated(
          (uid) async => uid,
        );

        expect(result, auth.currentUser!.uid);
      },
    );
  });

  group('linking a clean account (007 US1)', () {
    test(
      'linkWithGoogle calls linkWithCredential with a correctly-shaped '
      'credential and returns LinkSucceeded, uid unchanged',
      () async {
        final auth = MockFirebaseAuth(signedIn: true);
        final repository = _buildRepository(auth);
        final uidBefore = auth.currentUser!.uid;

        final result = await repository.linkWithGoogle();

        expect(result, isA<LinkSucceeded>());
        expect(repository.currentUserId, uidBefore);
      },
    );

    test(
      'linkWithApple calls linkWithCredential with a correctly-shaped '
      'credential and returns LinkSucceeded, uid unchanged',
      () async {
        final auth = MockFirebaseAuth(signedIn: true);
        final repository = _buildRepository(auth);
        final uidBefore = auth.currentUser!.uid;

        final result = await repository.linkWithApple();

        expect(result, isA<LinkSucceeded>());
        expect(repository.currentUserId, uidBefore);
      },
    );

    test('isLinked is false for a purely anonymous session', () async {
      final auth = MockFirebaseAuth(signedIn: true);
      final repository = _buildRepository(auth);

      expect(repository.isLinked, isFalse);
      expect(repository.linkedProviderLabel, isNull);
    });
  });

  group('link conflict detection (007 US3 surface)', () {
    test(
      'linkWithGoogle returns LinkConflictDetected, not a generic failure, '
      "when linkWithCredential throws 'credential-already-in-use'",
      () async {
        final auth = MockFirebaseAuth(signedIn: true);
        whenCalling(Invocation.method(#linkWithCredential, [anything]))
            .on(auth.currentUser!)
            .thenThrow(
              FirebaseAuthException(code: 'credential-already-in-use'),
            );
        final repository = _buildRepository(auth);

        final result = await repository.linkWithGoogle();

        expect(result, isA<LinkConflictDetected>());
      },
    );

    test(
      'linkWithApple returns LinkConflictDetected, not a generic failure, '
      "when linkWithCredential throws 'credential-already-in-use'",
      () async {
        final auth = MockFirebaseAuth(signedIn: true);
        whenCalling(Invocation.method(#linkWithCredential, [anything]))
            .on(auth.currentUser!)
            .thenThrow(
              FirebaseAuthException(code: 'credential-already-in-use'),
            );
        final repository = _buildRepository(auth);

        final result = await repository.linkWithApple();

        expect(result, isA<LinkConflictDetected>());
        expect(
          (result as LinkConflictDetected).conflict,
          isA<LinkConflict>(),
        );
      },
    );

    test(
      'a non-conflict, non-network FirebaseAuthException returns '
      'LinkFailed(UnknownFailure), not LinkConflictDetected',
      () async {
        final auth = MockFirebaseAuth(signedIn: true);
        whenCalling(Invocation.method(#linkWithCredential, [anything]))
            .on(auth.currentUser!)
            .thenThrow(FirebaseAuthException(code: 'internal-error'));
        final repository = _buildRepository(auth);

        final result = await repository.linkWithGoogle();

        expect(result, isA<LinkFailed>());
        expect((result as LinkFailed).failure, isA<UnknownFailure>());
      },
    );
  });

  group('offline linking (007 US4)', () {
    test(
      "linkWithGoogle maps 'network-request-failed' to "
      'LinkFailed(NetworkFailure), not a generic UnknownFailure',
      () async {
        final auth = MockFirebaseAuth(signedIn: true);
        whenCalling(Invocation.method(#linkWithCredential, [anything]))
            .on(auth.currentUser!)
            .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
        final repository = _buildRepository(auth);

        final result = await repository.linkWithGoogle();

        expect(result, isA<LinkFailed>());
        expect((result as LinkFailed).failure, isA<NetworkFailure>());
      },
    );

    test(
      "linkWithApple maps 'network-request-failed' to "
      'LinkFailed(NetworkFailure)',
      () async {
        final auth = MockFirebaseAuth(signedIn: true);
        whenCalling(Invocation.method(#linkWithCredential, [anything]))
            .on(auth.currentUser!)
            .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
        final repository = _buildRepository(auth);

        final result = await repository.linkWithApple();

        expect(result, isA<LinkFailed>());
        expect((result as LinkFailed).failure, isA<NetworkFailure>());
      },
    );
  });
}
