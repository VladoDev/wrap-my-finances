import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:wrap_my_finances/core/errors/failure.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/user_profile/data/datasources/user_profile_remote_data_source.dart';
import 'package:wrap_my_finances/features/user_profile/domain/entities/user_profile.dart';
import 'package:wrap_my_finances/features/user_profile/domain/repositories/user_profile_repository.dart';

/// [UserProfileRepository] over Firestore. Resolves the current uid from
/// [FirebaseAuth] directly, the same reasoning as `CategoryRepositoryImpl`.
@LazySingleton(as: UserProfileRepository)
class UserProfileRepositoryImpl implements UserProfileRepository {
  /// Creates the repository over the injected data source and auth SDK.
  UserProfileRepositoryImpl(this._remoteDataSource, this._auth);

  final UserProfileRemoteDataSource _remoteDataSource;
  final FirebaseAuth _auth;

  Future<void>? _ensureExistsFuture;

  String get _currentUserId {
    final uid = _auth.currentUser?.uid;
    assert(
      uid != null,
      'UserProfileRepositoryImpl must only be called from inside '
      'AuthRepository.runWhenAuthenticated, where a uid is guaranteed.',
    );
    return uid!;
  }

  @override
  Future<Result<void>> ensureExists() async {
    // Memoized/shared Future, same pattern CategoryRepositoryImpl uses for
    // seedDefaultsIfNeeded() — safe because this class is a
    // @LazySingleton, so exactly one instance (and one guard) exists per
    // process.
    try {
      _ensureExistsFuture ??= _remoteDataSource.ensureExists(_currentUserId);
      await _ensureExistsFuture;
      return const Success(null);
    } on Object catch (error, stackTrace) {
      // Allow a later call to retry rather than permanently caching a
      // failed attempt.
      _ensureExistsFuture = null;
      return Failed(UnknownFailure(error, stackTrace));
    }
  }

  @override
  Stream<UserProfile> watchProfile() {
    return _remoteDataSource.watchProfile(_currentUserId);
  }

  @override
  Future<Result<void>> markWrappedSeen(String monthKey) async {
    try {
      await _remoteDataSource.markWrappedSeen(_currentUserId, monthKey);
      return const Success(null);
    } on Object catch (error, stackTrace) {
      return Failed(UnknownFailure(error, stackTrace));
    }
  }
}
