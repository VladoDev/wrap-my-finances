import 'dart:ui' show PlatformDispatcher;

/// `currencyCode`/`monthKey` interim defaults, derived from the device's
/// current locale rather than a stored user preference — see
/// `specs/004-quick-expense-capture/research.md`'s "no user profile document
/// exists yet" correction. Revisit once a Settings feature (`docs/ROADMAP.md`
/// Phase 3) introduces the real stored preference.
class DeviceLocaleDefaults {
  const DeviceLocaleDefaults._();

  /// Fixed per this app's five supported languages — deliberately not
  /// inferred from `intl`'s CLDR data, for the same reason
  /// `AmountInputState`'s separators are a fixed map: a five-way lookup
  /// deserves a five-entry map, not opaque inference.
  static const Map<String, String> _currencyByLanguage = {
    'en': 'USD',
    'es': 'MXN',
    'pt': 'BRL',
    'it': 'EUR',
    'fr': 'EUR',
  };

  /// The device's current primary locale, read without needing a
  /// `BuildContext` — safe to call from the data layer.
  static String currentLanguageCode() =>
      PlatformDispatcher.instance.locale.languageCode;

  /// The interim currency code for [languageCode] (defaults to `en`'s if
  /// unrecognized).
  static String currencyCodeFor(String languageCode) =>
      _currencyByLanguage[languageCode] ?? _currencyByLanguage['en']!;

  /// `"YYYY-MM"` for [date] — `date` is expected to already be in the
  /// device's local time zone (i.e. from `DateTime.now()`, never
  /// `.toUtc()`), so no separate offset arithmetic is needed here.
  static String monthKeyFor(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$year-$month';
  }
}
