import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Guards FR-012/SC-006 (US4): a key present in the template ARB
// (lib/l10n/app_en.arb) and missing, empty, or untranslated in any other
// supported locale must fail this test — and therefore CI, since this test
// runs under `flutter test`. See research.md: gen_l10n itself does not fail
// the build on a missing translation, so this check exists independently
// of it.
const _templateLocale = 'en';
const _supportedLocales = ['en', 'es', 'pt', 'it', 'fr'];

Set<String> _messageKeys(Map<String, dynamic> arb) {
  return arb.keys
      .where((key) => key != '@@locale' && !key.startsWith('@'))
      .toSet();
}

void main() {
  final arbByLocale = <String, Map<String, dynamic>>{
    for (final locale in _supportedLocales)
      locale:
          jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
              as Map<String, dynamic>,
  };

  final templateKeys = _messageKeys(arbByLocale[_templateLocale]!);

  test('every non-template locale has every template key, non-empty', () {
    final failures = <String>[];

    for (final locale in _supportedLocales) {
      if (locale == _templateLocale) continue;
      final arb = arbByLocale[locale]!;
      final keys = _messageKeys(arb);

      final missing = templateKeys.difference(keys);
      for (final key in missing) {
        failures.add('locale "$locale" is missing key "$key"');
      }

      for (final key in keys.intersection(templateKeys)) {
        final value = arb[key];
        if (value is! String || value.trim().isEmpty) {
          failures.add('locale "$locale" has an empty value for key "$key"');
        }
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('no non-template locale defines a key absent from the template', () {
    final failures = <String>[];
    for (final locale in _supportedLocales) {
      if (locale == _templateLocale) continue;
      final extra = _messageKeys(arbByLocale[locale]!).difference(templateKeys);
      for (final key in extra) {
        failures.add(
          'locale "$locale" defines key "$key" not present in the template',
        );
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
