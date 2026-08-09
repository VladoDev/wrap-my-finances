import 'package:meta/meta.dart';

/// An amount of money as an integer minor-unit count plus its currency —
/// never a `double` (Constitution Principle 5: "`0.1 + 0.2 != 0.3`, and
/// rounding drift in a spending total is both incorrect and visibly
/// incorrect to the user"). Formatting to a display string happens only at
/// the presentation layer, via `intl`.
@immutable
class Money {
  /// Creates a money value. [minorUnits] is the integer amount in the
  /// currency's smallest unit (e.g. cents); [currencyCode] is an ISO 4217
  /// code such as `"MXN"`.
  const Money({required this.minorUnits, required this.currencyCode});

  /// Integer amount in the currency's smallest unit.
  final int minorUnits;

  /// ISO 4217 currency code.
  final String currencyCode;

  @override
  bool operator ==(Object other) {
    return other is Money &&
        other.minorUnits == minorUnits &&
        other.currencyCode == currencyCode;
  }

  @override
  int get hashCode => Object.hash(minorUnits, currencyCode);

  @override
  String toString() => 'Money($minorUnits $currencyCode)';
}
