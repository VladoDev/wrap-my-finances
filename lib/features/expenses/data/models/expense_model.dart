import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wrap_my_finances/features/expenses/data/device_locale_defaults.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';

// device_locale_defaults.dart is still used for monthKeyFor below —
// currencyCode resolution moved to the caller (007 US8): the draft's own
// Expense.amount.currencyCode is now the real, already-resolved value
// (ExpenseCaptureController reads currentCurrencyCodeProvider at submit
// time), not the 'XXX' placeholder this factory used to override.

/// Firestore document shape for an expense, per `docs/DATA_MODEL.md`. Adds
/// the infrastructure-only fields (`monthKey`, `syncedAt`, `deletedAt`,
/// `schemaVersion`) the domain `Expense` entity deliberately doesn't carry.
class ExpenseModel {
  /// Creates a model with every Firestore field explicit.
  const ExpenseModel({
    required this.id,
    required this.amountMinor,
    required this.currencyCode,
    required this.categoryId,
    required this.date,
    required this.monthKey,
    required this.note,
    required this.createdAt,
  });

  /// Builds the write payload for a new [expense]. `currencyCode` is
  /// [expense]'s own, already-resolved `amount.currencyCode` — the caller's
  /// job, not this factory's (007 US8). `monthKey` is still derived from
  /// the device's current locale/timezone — see `device_locale_defaults.dart`.
  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      amountMinor: expense.amount.minorUnits,
      currencyCode: expense.amount.currencyCode,
      categoryId: expense.categoryId,
      date: expense.date,
      monthKey: DeviceLocaleDefaults.monthKeyFor(expense.date),
      note: expense.note,
      createdAt: expense.createdAt,
    );
  }

  /// Reconstructs a model from a Firestore document snapshot's data.
  factory ExpenseModel.fromJson(String id, Map<String, Object?> json) {
    return ExpenseModel(
      id: id,
      amountMinor: json['amountMinor']! as int,
      currencyCode: json['currencyCode']! as String,
      categoryId: json['categoryId']! as String,
      date: (json['date']! as Timestamp).toDate(),
      monthKey: json['monthKey']! as String,
      note: json['note'] as String?,
      createdAt: (json['createdAt']! as Timestamp).toDate(),
    );
  }

  /// Firestore document id.
  final String id;

  /// Integer minor units — see Constitution Principle 5.
  final int amountMinor;

  /// ISO 4217 currency code.
  final String currencyCode;

  /// Plain string reference to a category document.
  final String categoryId;

  /// The expense date — the only field sorted/grouped by.
  final DateTime date;

  /// Denormalized `"YYYY-MM"` index, per `docs/DATA_MODEL.md`.
  final String monthKey;

  /// Optional note (always `null` in this feature — FR-017).
  final String? note;

  /// Client clock at creation, immutable.
  final DateTime createdAt;

  /// The write payload. `syncedAt` is `FieldValue.serverTimestamp()`
  /// (never read back by domain/presentation code, Constitution Principle
  /// 2); `deletedAt` is `null` — no delete path exists in this feature.
  Map<String, Object?> toJson() {
    return {
      'id': id,
      'amountMinor': amountMinor,
      'currencyCode': currencyCode,
      'categoryId': categoryId,
      'date': Timestamp.fromDate(date),
      'monthKey': monthKey,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'syncedAt': FieldValue.serverTimestamp(),
      'deletedAt': null,
      'schemaVersion': 1,
    };
  }

  /// Converts to the domain entity `003` defined — no Firestore type
  /// crosses this boundary.
  Expense toEntity() {
    return Expense(
      id: id,
      amount: Money(minorUnits: amountMinor, currencyCode: currencyCode),
      categoryId: categoryId,
      date: date,
      createdAt: createdAt,
      note: note,
    );
  }
}
