import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:wrap_my_finances/core/errors/failure.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/categories/domain/repositories/category_repository.dart';

/// [CategoryRepository] over Firestore. Resolves the current uid from
/// [FirebaseAuth] directly, the same reasoning as `ExpenseRepositoryImpl` —
/// see `specs/004-quick-expense-capture/research.md`.
@LazySingleton(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  /// Creates the repository over the injected data source and auth SDK.
  CategoryRepositoryImpl(this._remoteDataSource, this._auth);

  final CategoryRemoteDataSource _remoteDataSource;
  final FirebaseAuth _auth;

  Future<void>? _seedFuture;

  String get _currentUserId {
    final uid = _auth.currentUser?.uid;
    assert(
      uid != null,
      'CategoryRepositoryImpl must only be called from inside '
      'AuthRepository.runWhenAuthenticated, where a uid is guaranteed.',
    );
    return uid!;
  }

  @override
  Future<Result<List<Category>>> getActive() async {
    try {
      return Success(await _remoteDataSource.getActive(_currentUserId));
    } on Object catch (error, stackTrace) {
      return Failed(UnknownFailure(error, stackTrace));
    }
  }

  @override
  Stream<List<Category>> watchActive() {
    return _remoteDataSource.watchActive(_currentUserId);
  }

  @override
  Future<Result<void>> incrementUsage(String categoryId) async {
    try {
      await _remoteDataSource.incrementUsage(_currentUserId, categoryId);
      return const Success(null);
    } on Object catch (error, stackTrace) {
      return Failed(UnknownFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> seedDefaultsIfNeeded() async {
    // Memoized/shared Future, same pattern FirebaseAuthRepository uses for
    // ensureSignedIn() — safe because this class is a @LazySingleton, so
    // exactly one instance (and one guard) exists per process.
    try {
      _seedFuture ??= _remoteDataSource.seedDefaultsIfNeeded(_currentUserId);
      await _seedFuture;
      return const Success(null);
    } on Object catch (error, stackTrace) {
      // Allow a later call to retry rather than permanently caching a
      // failed attempt.
      _seedFuture = null;
      return Failed(UnknownFailure(error, stackTrace));
    }
  }
}
