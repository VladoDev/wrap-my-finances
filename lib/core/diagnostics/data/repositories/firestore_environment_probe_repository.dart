import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:wrap_my_finances/core/config/app_environment.dart';
import 'package:wrap_my_finances/core/diagnostics/domain/entities/environment_probe.dart';
import 'package:wrap_my_finances/core/diagnostics/domain/repositories/environment_probe_repository.dart';
import 'package:wrap_my_finances/core/errors/failure.dart';
import 'package:wrap_my_finances/core/errors/result.dart';

/// Firestore-backed [EnvironmentProbeRepository]. Writes a client-generated
/// document to `env_checks/{docId}` and never awaits server acknowledgement
/// before returning (Constitution Principle 2). See `data-model.md`.
@LazySingleton(as: EnvironmentProbeRepository)
class FirestoreEnvironmentProbeRepository
    implements EnvironmentProbeRepository {
  /// Creates the repository from its Firebase dependencies and the active
  /// [AppEnvironment].
  FirestoreEnvironmentProbeRepository(
    this._firestore,
    this._auth,
    this._env,
  );

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AppEnvironment _env;

  EnvironmentProbe? _lastWritten;

  @override
  Future<Result<EnvironmentProbe>> writeProbe(String label) async {
    try {
      await _ensureSignedIn();

      final docRef = _firestore.collection(_env.firestoreCollectionPath).doc();
      final probe = EnvironmentProbe(
        id: docRef.id,
        environmentName: _env.name,
        createdAtMillis: DateTime.now().millisecondsSinceEpoch,
        label: label,
      );

      // Fire-and-forget: the local cache write is synchronous; the returned
      // Future only resolves on server round-trip, which the UI must not
      // await (Constitution Principle 2).
      unawaited(
        docRef.set({
          'id': probe.id,
          'environmentName': probe.environmentName,
          'createdAtMillis': probe.createdAtMillis,
          'label': probe.label,
        }).catchError((Object error, StackTrace stackTrace) {
          // Background reconciliation error — no Logger service exists in
          // this feature's scope yet; a future feature wires one in.
        }),
      );

      _lastWritten = probe;
      return Success(probe);
    } on FirebaseException catch (e) {
      return Failed(_mapFirebaseException(e));
    } on Object catch (e, stackTrace) {
      return Failed(UnknownFailure(e, stackTrace));
    }
  }

  @override
  Future<Result<EnvironmentProbe?>> readLatest() async => Success(_lastWritten);

  Future<void> _ensureSignedIn() async {
    if (_auth.currentUser != null) {
      return;
    }
    await _auth.signInAnonymously();
  }

  Failure _mapFirebaseException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const PermissionDeniedFailure();
      case 'unavailable':
      case 'network-request-failed':
        return const NetworkFailure();
      default:
        return UnknownFailure(e, StackTrace.current);
    }
  }
}
