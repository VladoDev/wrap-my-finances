import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/config/app_environment.dart';
import 'package:wrap_my_finances/core/diagnostics/data/repositories/firestore_environment_probe_repository.dart';
import 'package:wrap_my_finances/core/diagnostics/domain/entities/environment_probe.dart';
import 'package:wrap_my_finances/core/errors/result.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  test(
    'writes a probe with a client-generated ID and an int timestamp, '
    'never a server sentinel',
    () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'anon-uid', isAnonymous: true),
      );
      final repository = FirestoreEnvironmentProbeRepository(
        firestore,
        auth,
        AppEnvironment.dev,
      );

      final result = await repository.writeProbe('probe');

      expect(result, isA<Success<EnvironmentProbe>>());
      final probe = (result as Success<EnvironmentProbe>).value;
      expect(probe.id, isNotEmpty);
      expect(probe.environmentName, 'dev');
      expect(probe.label, 'probe');

      final snapshot = await firestore
          .collection('env_checks')
          .doc(probe.id)
          .get();
      expect(snapshot.exists, isTrue);

      final data = snapshot.data()!;
      // The document ID must come from collection.doc() locally, never a
      // server-assigned value, and createdAtMillis must be a plain client
      // clock reading — never FieldValue.serverTimestamp() (Constitution
      // Principle 2).
      expect(data['id'], probe.id);
      expect(data['createdAtMillis'], isA<int>());
      expect(data['environmentName'], 'dev');
      expect(data['label'], 'probe');
    },
  );

  test('signs in anonymously first when no session exists yet', () async {
    final auth = MockFirebaseAuth();
    final repository = FirestoreEnvironmentProbeRepository(
      firestore,
      auth,
      AppEnvironment.dev,
    );
    expect(auth.currentUser, isNull);

    final result = await repository.writeProbe('probe');

    expect(result, isA<Success<EnvironmentProbe>>());
    expect(auth.currentUser, isNotNull);
  });
}
