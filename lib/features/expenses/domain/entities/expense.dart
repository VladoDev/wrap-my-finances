import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';

/// A single logged expense. Carries only what domain logic needs — no
/// `monthKey` (a denormalized Firestore index), `syncedAt` (a
/// `FieldValue.serverTimestamp()` artifact domain code must never read, per
/// Constitution Principle 2), `deletedAt`, or `schemaVersion` (data-layer
/// migration concerns). See `data-model.md`.
class Expense {
  /// Creates an expense.
  const Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.createdAt,
    this.note,
  });

  /// Client-generated identifier (Constitution Principle 2).
  final String id;

  /// The spent amount.
  final Money amount;

  /// Plain string reference to a category — not a `DocumentReference`, per
  /// `docs/DATA_MODEL.md`.
  final String categoryId;

  /// The expense date — the only field domain logic sorts/groups by.
  final DateTime date;

  /// Client clock at creation, immutable.
  final DateTime createdAt;

  /// Optional note, capped at 280 characters (matches the Security Rules
  /// cap).
  final String? note;
}
