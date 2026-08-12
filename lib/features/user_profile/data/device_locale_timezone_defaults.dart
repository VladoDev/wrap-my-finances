import 'dart:ui' show PlatformDispatcher;

/// `timeZone`'s interim default, derived from the device's current locale —
/// same reasoning as `expenses/data/device_locale_defaults.dart`'s
/// `currencyCode` default (`specs/004-quick-expense-capture/research.md`),
/// kept as a standalone copy here rather than importing that file: features
/// may depend only on another feature's `domain/` repository interfaces
/// (Constitution Principle 4), and `device_locale_defaults.dart` is
/// `expenses`' internal `data/` file, not a domain contract. Revisit once a
/// Settings feature (`docs/ROADMAP.md` Phase 3) introduces the real stored
/// preference, editable independently of device locale.
class DeviceLocaleTimeZoneDefaults {
  const DeviceLocaleTimeZoneDefaults._();

  /// Fixed per this app's five supported languages — deliberately not
  /// inferred from platform time zone APIs, for the same reason
  /// `expenses/data/device_locale_defaults.dart`'s currency map is a fixed
  /// five-entry lookup rather than opaque inference.
  static const Map<String, String> _timeZoneByLanguage = {
    'en': 'America/New_York',
    'es': 'America/Mexico_City',
    'pt': 'America/Sao_Paulo',
    'it': 'Europe/Rome',
    'fr': 'Europe/Paris',
  };

  /// The device's current primary locale, read without needing a
  /// `BuildContext` — safe to call from the data layer.
  static String currentLanguageCode() =>
      PlatformDispatcher.instance.locale.languageCode;

  /// The interim IANA time zone for [languageCode] (defaults to `en`'s if
  /// unrecognized).
  static String timeZoneFor(String languageCode) =>
      _timeZoneByLanguage[languageCode] ?? _timeZoneByLanguage['en']!;
}
