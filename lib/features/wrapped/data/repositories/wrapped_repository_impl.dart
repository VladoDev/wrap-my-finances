import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:wrap_my_finances/core/errors/failure.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/categories/domain/repositories/category_repository.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/expenses/domain/repositories/expense_repository.dart';
import 'package:wrap_my_finances/features/wrapped/data/datasources/wrapped_remote_data_source.dart';
import 'package:wrap_my_finances/features/wrapped/domain/entities/wrapped_summary.dart';
import 'package:wrap_my_finances/features/wrapped/domain/repositories/wrapped_repository.dart';

/// Placeholder currency for the (never-displayed) zero-expense/syncing
/// states — `Money` requires a non-empty code, and these summaries are
/// gated out of the UI before any figure is rendered (FR-012, Edge Cases).
const _placeholderCurrencyCode = 'USD';

/// [WrappedRepository] computed from the existing local cache. Depends on
/// `ExpenseRepository`'s domain interface (an allowed cross-feature
/// dependency, Constitution Principle 4) for the already-deleted-filtered
/// local list, `CategoryRepository` only for `sortOrder` tie-breaking (never
/// for names — those resolve at display time, FR-011), and
/// `WrappedRemoteDataSource` for the one genuinely new Firestore access this
/// feature needs: the server-side `count()`. See
/// `specs/006-monthly-wrapped-summary/research.md` #6.
@LazySingleton(as: WrappedRepository)
class WrappedRepositoryImpl implements WrappedRepository {
  /// Creates the repository over its collaborators.
  WrappedRepositoryImpl(
    this._expenseRepository,
    this._categoryRepository,
    this._remoteDataSource,
    this._auth,
  );

  final ExpenseRepository _expenseRepository;
  final CategoryRepository _categoryRepository;
  final WrappedRemoteDataSource _remoteDataSource;
  final FirebaseAuth _auth;

  String get _currentUserId {
    final uid = _auth.currentUser?.uid;
    assert(
      uid != null,
      'WrappedRepositoryImpl must only be called from inside '
      'AuthRepository.runWhenAuthenticated, where a uid is guaranteed.',
    );
    return uid!;
  }

  @override
  Future<Result<WrappedSummary>> getSummary(String monthKey) async {
    try {
      final localExpenses = await _expenseRepository
          .watchByMonth(monthKey)
          .first;
      final serverCount = await _remoteDataSource.serverCount(
        _currentUserId,
        monthKey,
      );

      if (localExpenses.length < serverCount) {
        return Success(_emptySummary(monthKey, isSyncing: true));
      }
      if (localExpenses.isEmpty) {
        return Success(_emptySummary(monthKey, isSyncing: false));
      }

      final currencyCode = localExpenses.first.amount.currencyCode;
      var totalMinor = 0;
      final amountByCategory = <String, int>{};
      final countByCategory = <String, int>{};
      var biggest = localExpenses.first;

      for (final expense in localExpenses) {
        totalMinor += expense.amount.minorUnits;
        amountByCategory.update(
          expense.categoryId,
          (v) => v + expense.amount.minorUnits,
          ifAbsent: () => expense.amount.minorUnits,
        );
        countByCategory.update(
          expense.categoryId,
          (v) => v + 1,
          ifAbsent: () => 1,
        );
        if (expense.amount.minorUnits > biggest.amount.minorUnits) {
          biggest = expense;
        }
      }

      final categoriesResult = await _categoryRepository.getActive();
      final categories = categoriesResult.when(
        success: (categories) => categories,
        failed: (_) => const <Category>[],
      );
      final sortOrderById = <String, int>{
        for (final category in categories) category.id: category.sortOrder,
      };

      final topCategoryId = _resolveTopCategory(
        amountByCategory,
        sortOrderById,
      );

      return Success(
        WrappedSummary(
          monthKey: monthKey,
          isSyncing: false,
          total: Money(minorUnits: totalMinor, currencyCode: currencyCode),
          topCategoryId: topCategoryId,
          topCategoryExpenseCount: countByCategory[topCategoryId] ?? 0,
          biggestExpense: biggest.amount,
          expenseCount: localExpenses.length,
        ),
      );
    } on Object catch (error, stackTrace) {
      return Failed(UnknownFailure(error, stackTrace));
    }
  }

  /// The category with the highest summed amount. Ties break on the lowest
  /// `sortOrder` (per `data-model.md` §2); a category absent from the
  /// active-category lookup (e.g. deactivated) falls back to a high
  /// synthetic `sortOrder` so a known category always wins over it, with a
  /// final lexical tie-break on the category id for full determinism.
  String? _resolveTopCategory(
    Map<String, int> amountByCategory,
    Map<String, int> sortOrderById,
  ) {
    String? topCategoryId;
    var topAmount = -1;

    for (final entry in amountByCategory.entries) {
      final isBetter =
          topCategoryId == null ||
          entry.value > topAmount ||
          (entry.value == topAmount &&
              _isEarlierCategory(entry.key, topCategoryId, sortOrderById));
      if (isBetter) {
        topCategoryId = entry.key;
        topAmount = entry.value;
      }
    }
    return topCategoryId;
  }

  bool _isEarlierCategory(
    String candidateId,
    String currentId,
    Map<String, int> sortOrderById,
  ) {
    const unknownSortOrder = 1 << 30;
    final candidateSort = sortOrderById[candidateId] ?? unknownSortOrder;
    final currentSort = sortOrderById[currentId] ?? unknownSortOrder;
    if (candidateSort != currentSort) return candidateSort < currentSort;
    return candidateId.compareTo(currentId) < 0;
  }

  WrappedSummary _emptySummary(String monthKey, {required bool isSyncing}) {
    return WrappedSummary(
      monthKey: monthKey,
      isSyncing: isSyncing,
      total: const Money(
        minorUnits: 0,
        currencyCode: _placeholderCurrencyCode,
      ),
      topCategoryId: null,
      topCategoryExpenseCount: 0,
      biggestExpense: null,
      expenseCount: 0,
    );
  }
}
