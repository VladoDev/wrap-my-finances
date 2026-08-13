import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/user_profile/data/datasources/user_profile_remote_data_source.dart';
import 'package:wrap_my_finances/features/user_profile/data/repositories/user_profile_repository_impl.dart';

void main() {
  group('preferences (007 US8)', () {
    test(
      'updateCurrencyCode produces the exact expected single-field '
      'Firestore update',
      () async {
        final firestore = FakeFirebaseFirestore();
        final auth = MockFirebaseAuth(signedIn: true);
        final uid = auth.currentUser!.uid;
        final repository = UserProfileRepositoryImpl(
          UserProfileRemoteDataSource(firestore),
          auth,
        );
        await firestore.collection('users').doc(uid).set({
          'timeZone': 'America/Mexico_City',
          'wrappedLastSeenMonth': '2026-07',
        });

        final result = await repository.updateCurrencyCode('EUR');

        expect(result, isA<Success<void>>());
        final doc = await firestore.collection('users').doc(uid).get();
        expect(doc.data(), {
          'timeZone': 'America/Mexico_City',
          'wrappedLastSeenMonth': '2026-07',
          'currencyCode': 'EUR',
        });
      },
    );

    test(
      'updateTimeZone produces the exact expected single-field Firestore '
      'update, never touching currencyCode/wrappedLastSeenMonth',
      () async {
        final firestore = FakeFirebaseFirestore();
        final auth = MockFirebaseAuth(signedIn: true);
        final uid = auth.currentUser!.uid;
        final repository = UserProfileRepositoryImpl(
          UserProfileRemoteDataSource(firestore),
          auth,
        );
        await firestore.collection('users').doc(uid).set({
          'timeZone': 'America/Mexico_City',
          'currencyCode': 'MXN',
          'wrappedLastSeenMonth': '2026-07',
        });

        final result = await repository.updateTimeZone('Europe/Madrid');

        expect(result, isA<Success<void>>());
        final doc = await firestore.collection('users').doc(uid).get();
        expect(doc.data(), {
          'timeZone': 'Europe/Madrid',
          'currencyCode': 'MXN',
          'wrappedLastSeenMonth': '2026-07',
        });
      },
    );
  });
}
