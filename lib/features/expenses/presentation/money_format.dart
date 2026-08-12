import 'package:intl/intl.dart';

/// Formats [minorUnits] as a locale-grouped decimal string with exactly two
/// decimal digits and no currency symbol — matching `004`'s `AmountDisplay`
/// visual convention (a plain number, no `$` prefix). Display-only, per
/// `docs/DATA_MODEL.md`: the division by 100 here never feeds back into any
/// stored or computed value, only into a rendered string.
String formatMinorUnits(int minorUnits, String locale) {
  return NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: 2,
  ).format(minorUnits / 100);
}
