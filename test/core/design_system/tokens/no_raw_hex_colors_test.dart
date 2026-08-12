import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

// Guards FR-002/FR-003: every hex color literal in this app lives in exactly
// one file. `app_colors.dart`'s own literals are library-private (see that
// file), which already makes them unimportable elsewhere; this test is the
// backstop for someone defining a *new* hex constant in a different file
// rather than reaching into app_colors.dart's private ones. See research.md.
void main() {
  test('no hex color literal exists outside app_colors.dart', () {
    final libDir = Directory('lib');
    final allowedFile = p.normalize(
      'lib/core/design_system/tokens/app_colors.dart',
    );

    final hexColorConstructor = RegExp(r'Color\(0x[0-9A-Fa-f]{6,8}\)');
    final hexStringLiteral = RegExp('''['"]#[0-9A-Fa-f]{6}['"]''');

    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final relativePath = p.normalize(entity.path);
      if (relativePath == allowedFile) continue;

      final content = entity.readAsStringSync();
      final lines = content.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final hasHexLiteral =
            hexColorConstructor.hasMatch(line) ||
            hexStringLiteral.hasMatch(line);
        if (hasHexLiteral) {
          violations.add('$relativePath:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Hex color literals must only appear in $allowedFile. '
          'Found:\n${violations.join('\n')}',
    );
  });
}
