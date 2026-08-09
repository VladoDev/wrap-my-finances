import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/features/auth/data/repositories/firebase_auth_repository.dart';

void main() {
  group('session resolution (US1)', () {
    test(
      'currentUserId is null before sign-in and reflects the uid after',
      () async {
        final auth = MockFirebaseAuth();
        final repository = FirebaseAuthRepository(auth);

        expect(repository.currentUserId, isNull);

        final uid = await repository.ensureSignedIn();

        expect(repository.currentUserId, uid);
      },
    );

    test(
      'ensureSignedIn resolves immediately when already signed in',
      () async {
        final auth = MockFirebaseAuth(signedIn: true);
        final repository = FirebaseAuthRepository(auth);

        final uid = await repository.ensureSignedIn();

        expect(uid, auth.currentUser!.uid);
      },
    );

    test(
      'ensureSignedIn does not re-trigger sign-in on a warm session',
      () async {
        final auth = MockFirebaseAuth(signedIn: true);
        final repository = FirebaseAuthRepository(auth);
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
        final repository = FirebaseAuthRepository(auth);
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
        final repository = FirebaseAuthRepository(auth);

        final result = await repository.runWhenAuthenticated(
          (uid) async => uid,
        );

        expect(result, auth.currentUser!.uid);
      },
    );
  });
}
