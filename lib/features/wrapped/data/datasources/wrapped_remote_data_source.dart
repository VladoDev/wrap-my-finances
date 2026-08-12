import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

/// The one piece of Wrapped aggregation that needs direct Firestore access:
/// a server-side `count()` to detect an incomplete local cache, per
/// `docs/DATA_MODEL.md`'s "Wrapped aggregation" correctness caveat. See
/// `specs/006-monthly-wrapped-summary/research.md` #6.
@injectable
class WrappedRemoteDataSource {
  /// Creates a data source over the injected `FirebaseFirestore` instance.
  WrappedRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  /// The authoritative, server-side count of non-deleted expenses in
  /// [monthKey] for [userId] — `AggregateQuery.get()` defaults to
  /// `AggregateSource.server`, so this never answers from the (possibly
  /// incomplete) local cache.
  Future<int> serverCount(String userId, String monthKey) async {
    final query = _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .where('monthKey', isEqualTo: monthKey)
        .where('deletedAt', isNull: true);

    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }
}
