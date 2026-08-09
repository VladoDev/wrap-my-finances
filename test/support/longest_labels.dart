import 'dart:convert';
import 'dart:io';

const _supportedLocales = ['en', 'es', 'pt', 'it', 'fr'];

/// Returns the longest translated value for [arbKey] across all five
/// supported locales, measured by rendered character count. Used by
/// FR-013's 200%-text-scale widget tests so the stress-test input is
/// always the actual worst case, not an assumption about which language
/// wins (see data-model.md).
String longestLabelFor(String arbKey) {
  var longest = '';
  for (final locale in _supportedLocales) {
    final arb =
        jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
            as Map<String, dynamic>;
    final value = arb[arbKey] as String?;
    if (value != null && value.length > longest.length) {
      longest = value;
    }
  }
  return longest;
}
