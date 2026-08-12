import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:wrap_my_finances/features/expenses/data/models/expense_model.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';

/// Owns the one piece of genuine complexity this feature's persistence side
/// needs: confirming a write landed in the **local** Firestore cache without
/// ever awaiting the SDK's server-acknowledged `Future` — see
/// `specs/004-quick-expense-capture/research.md`.
@injectable
class ExpenseRemoteDataSource {
  /// Creates a data source over the injected `FirebaseFirestore` instance.
  ExpenseRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, Object?>> _expensesRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('expenses');

  /// Persists [draft] under [userId], assigning the real, client-generated
  /// document id (`003`'s `Expense.id` on [draft] is a caller placeholder,
  /// discarded here). Resolves as soon as the write is visible in the local
  /// cache — never waits for server acknowledgement. Throws if the write
  /// fails before ever reaching the local cache (the one error case FR-012
  /// names); the repository maps that to a `Failure`.
  Future<Expense> create(String userId, Expense draft) async {
    final docRef = _expensesRef(userId).doc();
    final expense = Expense(
      id: docRef.id,
      amount: draft.amount,
      categoryId: draft.categoryId,
      date: draft.date,
      createdAt: draft.createdAt,
      note: draft.note,
    );

    final writeFuture = docRef.set(ExpenseModel.fromEntity(expense).toJson());
    final localConfirmed = docRef.snapshots().firstWhere(
      (snapshot) => snapshot.exists,
    );

    // Whichever completes first: the local cache reflecting the write (the
    // common, near-instant case), or the write itself failing before ever
    // reaching the local cache — both are meaningful outcomes; a slow
    // server round trip is not, and is never awaited here.
    await Future.any<Object?>([localConfirmed, writeFuture]);

    // The write's eventual server round trip (or a late failure after local
    // success) is not this feature's concern — but must still be "handled"
    // so a late rejection never surfaces as an unhandled Future error.
    unawaited(writeFuture.catchError((Object _, StackTrace _) {}));

    return expense;
  }

  /// Soft-delete is a data-layer concern outside this feature's scope
  /// (FR-017); this hard-deletes for contract completeness only — no caller
  /// exists yet.
  Future<void> delete(String userId, String expenseId) {
    return _expensesRef(userId).doc(expenseId).delete();
  }

  /// Live query for a month's expenses, ordered by date — not exercised by
  /// this feature's screen (no history view, FR-017) but required by the
  /// `003` contract for future features to build against.
  Stream<List<Expense>> watchByMonth(String userId, String monthKey) {
    return _expensesRef(userId)
        .where('monthKey', isEqualTo: monthKey)
        .where('deletedAt', isNull: true)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ExpenseModel.fromJson(doc.id, doc.data()).toEntity(),
              )
              .toList(),
        );
  }
}
