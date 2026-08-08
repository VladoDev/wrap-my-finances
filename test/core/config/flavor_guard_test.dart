import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/config/app_environment.dart';
import 'package:wrap_my_finances/core/config/flavor_guard.dart';

void main() {
  group('checkFlavorConsistency', () {
    test('returns null when native flavor matches dev environment', () {
      final result = checkFlavorConsistency(
        appFlavor: 'dev',
        env: AppEnvironment.dev,
      );

      expect(result, isNull);
    });

    test('returns null when native flavor matches prod environment', () {
      final result = checkFlavorConsistency(
        appFlavor: 'prod',
        env: AppEnvironment.prod,
      );

      expect(result, isNull);
    });

    test('flags a dev-native build launched with the prod entrypoint', () {
      final result = checkFlavorConsistency(
        appFlavor: 'dev',
        env: AppEnvironment.prod,
      );

      expect(result, isNotNull);
      expect(result!.nativeFlavor, 'dev');
      expect(result.dartEnvironment, 'prod');
      expect(result.message, contains('dev'));
      expect(result.message, contains('prod'));
    });

    test('flags a prod-native build launched with the dev entrypoint', () {
      final result = checkFlavorConsistency(
        appFlavor: 'prod',
        env: AppEnvironment.dev,
      );

      expect(result, isNotNull);
      expect(result!.nativeFlavor, 'prod');
      expect(result.dartEnvironment, 'dev');
    });

    test('flags a build with no native flavor at all', () {
      final result = checkFlavorConsistency(
        appFlavor: null,
        env: AppEnvironment.dev,
      );

      expect(result, isNotNull);
      expect(result!.nativeFlavor, isNull);
    });
  });
}
