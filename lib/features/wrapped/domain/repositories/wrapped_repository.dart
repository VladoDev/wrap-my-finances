import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/wrapped/domain/entities/wrapped_summary.dart';

/// Domain contract for computing a month's Wrapped summary. Single-member
/// on purpose, matching `AnalyticsService`'s established precedent for a
/// port that genuinely has one operation.
// ignore: one_member_abstracts
abstract class WrappedRepository {
  /// Computes the aggregate for [monthKey] (`"YYYY-MM"`). Compares the
  /// local cache's document count against a server-side `count()` for the
  /// same filter; returns a [WrappedSummary] with `isSyncing: true` and
  /// every other field meaningless if they disagree, per FR-012. Excludes
  /// every expense with a non-null `deletedAt`, per FR-010.
  Future<Result<WrappedSummary>> getSummary(String monthKey);
}
