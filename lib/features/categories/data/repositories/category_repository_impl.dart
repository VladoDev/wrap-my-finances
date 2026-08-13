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

  // Keyed by uid, not a single Future — `007`'s account-merge flow can
  // switch this singleton's authenticated identity mid-process
  // (`FirebaseAuthRepository._mergeIntoExistingAccount`), so a single
  // shared guard would wrongly no-op the second uid's seed check.
  final Map<String, Future<void>> _seedFutures = {};

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
    // Memoized/shared Future per uid — see `_seedFutures`' doc comment.
    final uid = _currentUserId;
    try {
      final future = _seedFutures.putIfAbsent(
        uid,
        () => _remoteDataSource.seedDefaultsIfNeeded(uid),
      );
      await future;
      return const Success(null);
    } on Object catch (error, stackTrace) {
      // Allow a later call to retry rather than permanently caching a
      // failed attempt. The removed value is itself a Future — discarding
      // it, not awaiting it, is the point.
      // ignore: unawaited_futures
      _seedFutures.remove(uid);
      return Failed(UnknownFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<List<Category>>> getAll() async {
    try {
      return Success(await _remoteDataSource.getAll(_currentUserId));
    } on Object catch (error, stackTrace) {
      return Failed(UnknownFailure(error, stackTrace));
    }
  }

  @override
  Stream<List<Category>> watchAll() {
    return _remoteDataSource.watchAll(_currentUserId);
  }

  @override
  Future<Result<Category>> create({
    required String name,
    required String color,
    required String iconName,
  }) async {
    try {
      final category = await _remoteDataSource.create(
        _currentUserId,
        name: name,
        color: color,
        iconName: iconName,
      );
      return Success(category);
    } on Object catch (error, stackTrace) {
      return Failed(UnknownFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> update(
    String categoryId, {
    String? name,
    String? color,
    String? iconName,
  }) async {
    try {
      await _remoteDataSource.update(
        _currentUserId,
        categoryId,
        name: name,
        color: color,
        iconName: iconName,
      );
      return const Success(null);
    } on Object catch (error, stackTrace) {
      return Failed(UnknownFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> reorder(List<String> orderedIds) async {
    try {
      await _remoteDataSource.reorder(_currentUserId, orderedIds);
      return const Success(null);
    } on Object catch (error, stackTrace) {
      return Failed(UnknownFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> setActive(
    String categoryId, {
    required bool isActive,
  }) async {
    try {
      await _remoteDataSource.setActive(
        _currentUserId,
        categoryId,
        isActive: isActive,
      );
      return const Success(null);
    } on Object catch (error, stackTrace) {
      return Failed(UnknownFailure(error, stackTrace));
    }
  }
}
