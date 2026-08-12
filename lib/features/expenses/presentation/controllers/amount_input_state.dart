import 'package:meta/meta.dart';

/// Decimal/grouping separators for the five locales this app supports.
/// Fixed and explicit rather than inferred from `intl`'s CLDR data — the
/// same "five-way lookup deserves a five-entry map, not opaque inference"
/// reasoning `specs/004-quick-expense-capture/research.md` applies to
/// currency. Falls back to `en`'s separators for an unrecognized locale.
const Map<String, (String decimal, String group)> _localeSeparators = {
  'en': ('.', ','),
  'es': (',', '.'),
  'pt': (',', '.'),
  'it': (',', '.'),
  'fr': (',', ' '),
};

/// Locale-aware, keypad-driven amount input. Plain Dart — no `Widget`, no
/// `BuildContext` — so it is fast to unit test and carries no Flutter
/// dependency, mirroring how `003` kept `Money`/`Expense` framework-free.
/// Every mutator is pure, returning a new [AmountInputState]; none ever
/// throws — an invalid keystroke (a second separator, a third decimal
/// digit, a digit that would exceed the 1,000,000.00 ceiling) is silently
/// ignored, per `docs/UI_UX_SPEC.md` §2's keypad rules.
@immutable
class AmountInputState {
  /// Creates an empty amount input for [locale] (a language code such as
  /// `"es"`; see `_localeSeparators`).
  const AmountInputState({required this.locale})
    : integerDigits = '',
      decimalDigits = '',
      hasDecimalSeparator = false;

  const AmountInputState._({
    required this.locale,
    required this.integerDigits,
    required this.decimalDigits,
    required this.hasDecimalSeparator,
  });

  /// The maximum capturable amount, 1,000,000.00, in minor units — matches
  /// `isValidExpense()`'s `amountMinor <= 100000000` server-side cap.
  static const int maxMinorUnits = 100000000;

  /// The active locale's language code.
  final String locale;

  /// Digits typed before the decimal separator (may be empty).
  final String integerDigits;

  /// Digits typed after the decimal separator — never more than 2.
  final String decimalDigits;

  /// Whether the decimal separator key has been pressed.
  final bool hasDecimalSeparator;

  (String, String) get _separators =>
      _localeSeparators[locale] ?? _localeSeparators['en']!;

  /// The locale's decimal separator symbol (`.` or `,`).
  String get decimalSeparatorSymbol => _separators.$1;

  /// The locale's thousands-grouping separator symbol.
  String get groupingSeparatorSymbol => _separators.$2;

  /// The typed amount as integer minor units (cents). `0` when empty.
  int get minorUnits {
    final wholeUnits = integerDigits.isEmpty ? 0 : int.parse(integerDigits);
    final paddedDecimal = decimalDigits.padRight(2, '0');
    return wholeUnits * 100 + int.parse(paddedDecimal);
  }

  /// `true` once a non-zero amount has been typed — drives FR-010's
  /// disabled-"Next" state.
  bool get isValid => minorUnits > 0;

  /// The locale-formatted string to render — live thousands grouping on the
  /// integer part, the typed decimal digits exactly as entered (not padded,
  /// so a lone decimal separator shows as e.g. `"12,"` while typing).
  String get formattedDisplay {
    final groupedInteger = _groupDigits(
      integerDigits.isEmpty ? '0' : integerDigits,
      groupingSeparatorSymbol,
    );
    if (!hasDecimalSeparator) return groupedInteger;
    return '$groupedInteger$decimalSeparatorSymbol$decimalDigits';
  }

  static String _groupDigits(String digits, String separator) {
    final reversed = digits.split('').reversed.toList();
    final grouped = StringBuffer();
    for (var i = 0; i < reversed.length; i++) {
      if (i != 0 && i % 3 == 0) grouped.write(separator);
      grouped.write(reversed[i]);
    }
    return grouped.toString().split('').reversed.join();
  }

  AmountInputState _copyWith({
    String? integerDigits,
    String? decimalDigits,
    bool? hasDecimalSeparator,
  }) {
    return AmountInputState._(
      locale: locale,
      integerDigits: integerDigits ?? this.integerDigits,
      decimalDigits: decimalDigits ?? this.decimalDigits,
      hasDecimalSeparator: hasDecimalSeparator ?? this.hasDecimalSeparator,
    );
  }

  /// Appends [digit] (a single character, `"0"`–`"9"`). Ignored once two
  /// decimal digits are already typed, or once the result would exceed
  /// [maxMinorUnits].
  AmountInputState appendDigit(String digit) {
    if (hasDecimalSeparator) {
      if (decimalDigits.length >= 2) return this;
      final candidate = _copyWith(decimalDigits: decimalDigits + digit);
      return candidate.minorUnits > maxMinorUnits ? this : candidate;
    }
    if (integerDigits.length >= 9) return this;
    final candidate = _copyWith(integerDigits: integerDigits + digit);
    return candidate.minorUnits > maxMinorUnits ? this : candidate;
  }

  /// Presses the decimal separator key. A no-op if already pressed — only
  /// one decimal separator is ever accepted.
  AmountInputState appendDecimalSeparator() {
    if (hasDecimalSeparator) return this;
    return _copyWith(hasDecimalSeparator: true);
  }

  /// Removes the last keystroke: a decimal digit, then the separator, then
  /// an integer digit. A no-op when the amount is already empty.
  AmountInputState backspace() {
    if (decimalDigits.isNotEmpty) {
      return _copyWith(
        decimalDigits: decimalDigits.substring(0, decimalDigits.length - 1),
      );
    }
    if (hasDecimalSeparator) {
      return _copyWith(hasDecimalSeparator: false);
    }
    if (integerDigits.isNotEmpty) {
      return _copyWith(
        integerDigits: integerDigits.substring(0, integerDigits.length - 1),
      );
    }
    return this;
  }
}
