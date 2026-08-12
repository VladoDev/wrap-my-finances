import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:wrap_my_finances/core/errors/failure.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/expenses/data/datasources/expense_remote_data_source.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/domain/repositories/expense_repository.dart';

/// [ExpenseRepository] over Firestore. Every method returns a [Result],
/// never throws — [ExpenseRemoteDataSource]'s exceptions are caught and
/// mapped here, per `docs/ARCHITECTURE.md`'s "no exception crosses a layer
/// boundary" rule.
///
/// `003`'s contract gives `create`/`delete`/`watchByMonth` no `userId`
/// parameter — every real caller reaches these only from inside
/// `AuthRepository.runWhenAuthenticated`, by which point `FirebaseAuth`'s
/// own `currentUser` is already resolved, so the current uid is read
/// directly from the injected [FirebaseAuth] rather than threaded through
/// every method signature.
@LazySingleton(as: ExpenseRepository)
class ExpenseRepositoryImpl implements ExpenseRepository {
  /// Creates the repository over the injected data source and auth SDK.
  ExpenseRepositoryImpl(this._remoteDataSource, this._auth);

  final ExpenseRemoteDataSource _remoteDataSource;
  final FirebaseAuth _auth;

  String get _currentUserId {
    final uid = _auth.currentUser?.uid;
    assert(
      uid != null,
      'ExpenseRepositoryImpl must only be called from inside '
      'AuthRepository.runWhenAuthenticated, where a uid is guaranteed.',
    );
    return uid!;
  }

  @override
  Future<Result<Expense>> create(Expense expense) async {
    try {
      final created = await _remoteDataSource.create(_currentUserId, expense);
      return Success(created);
    } on Object catch (error, stackTrace) {
      // The one error case FR-012 names: the write never reached the local
      // cache. Reported to Crashlytics (via UnknownFailure) since, unlike
      // an offline server round trip, this signals a real device problem.
      return Failed(UnknownFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> delete(String expenseId) async {
    try {
      await _remoteDataSource.delete(_currentUserId, expenseId);
      return const Success(null);
    } on Object catch (error, stackTrace) {
      return Failed(UnknownFailure(error, stackTrace));
    }
  }

  @override
  Stream<List<Expense>> watchByMonth(String monthKey) {
    return _remoteDataSource.watchByMonth(_currentUserId, monthKey);
  }
}
