import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:wrap_my_finances/features/user_profile/data/device_locale_timezone_defaults.dart';
import 'package:wrap_my_finances/features/user_profile/data/models/user_profile_model.dart';
import 'package:wrap_my_finances/features/user_profile/domain/entities/user_profile.dart';

/// `users/{userId}` persistence — the document `docs/DATA_MODEL.md` §1 has
/// documented since `003` but no feature wrote to until `006`. See
/// `specs/006-monthly-wrapped-summary/research.md` #1.
@injectable
class UserProfileRemoteDataSource {
  /// Creates a data source over the injected `FirebaseFirestore` instance.
  UserProfileRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, Object?>> _userDocRef(String userId) =>
      _firestore.collection('users').doc(userId);

  /// Creates `users/{userId}` with a device-locale-derived `timeZone` and
  /// `wrappedLastSeenMonth: null` if it doesn't exist yet. Idempotent at the
  /// data level (checks for an existing document first); the repository
  /// additionally memoizes this per process, mirroring
  /// `CategoryRemoteDataSource.seedDefaultsIfNeeded`'s two-layer guard.
  Future<void> ensureExists(String userId) async {
    final ref = _userDocRef(userId);
    final existing = await ref.get();
    if (existing.exists) return;

    final profile = UserProfileModel(
      uid: userId,
      timeZone: DeviceLocaleTimeZoneDefaults.timeZoneFor(
        DeviceLocaleTimeZoneDefaults.currentLanguageCode(),
      ),
    );

    final writeFuture = ref.set(profile.toJson());
    final localConfirmed = ref.snapshots().firstWhere((s) => s.exists);
    await Future.any<Object?>([localConfirmed, writeFuture]);
    unawaited(writeFuture.catchError((Object _, StackTrace _) {}));
  }

  /// Live view of `users/{userId}`. Filters out the pre-creation
  /// `exists: false` snapshot a listener attached before `ensureExists()`
  /// completes would otherwise see.
  Stream<UserProfile> watchProfile(String userId) {
    return _userDocRef(userId)
        .snapshots()
        .where((snapshot) => snapshot.exists)
        .map(
          (snapshot) => UserProfileModel.fromJson(snapshot.data()!).toEntity(),
        );
  }

  /// Sets `wrappedLastSeenMonth` to [monthKey] — a single-field update, no
  /// read required.
  Future<void> markWrappedSeen(String userId, String monthKey) {
    return _userDocRef(userId).update({'wrappedLastSeenMonth': monthKey});
  }
}
