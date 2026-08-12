import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/tokens/app_motion.dart';

void main() {
  group('AppMotionExtension.standard', () {
    const standard = AppMotionExtension.standard;

    test('exposes a spring curve and every duration token', () {
      expect(standard.springCurve, isNotNull);
      expect(standard.storyAdvanceDuration, greaterThan(Duration.zero));
      expect(standard.countUpDuration, greaterThan(Duration.zero));
      expect(standard.crossfadeDuration, greaterThan(Duration.zero));
    });

    test('storyAdvanceDuration falls within the 5-7s range from '
        'docs/UI_UX_SPEC.md §3', () {
      expect(standard.storyAdvanceDuration.inSeconds, inInclusiveRange(5, 7));
    });
  });

  group('AppMotionExtension.copyWith', () {
    test('overrides only the given fields', () {
      const original = AppMotionExtension.standard;
      final copy = original.copyWith(
        storyAdvanceDuration: const Duration(seconds: 5),
      );

      expect(copy.storyAdvanceDuration, const Duration(seconds: 5));
      expect(copy.springCurve, original.springCurve);
      expect(copy.countUpDuration, original.countUpDuration);
      expect(copy.crossfadeDuration, original.crossfadeDuration);
    });
  });

  group('AppMotionExtension.lerp', () {
    test('returns this unchanged when other is null', () {
      const original = AppMotionExtension.standard;

      expect(original.lerp(null, 1), same(original));
    });

    test('snaps to the nearer endpoint rather than blending', () {
      const a = AppMotionExtension.standard;
      const b = AppMotionExtension(
        springCurve: Curves.linear,
        storyAdvanceDuration: Duration(seconds: 5),
        countUpDuration: Duration(milliseconds: 500),
        crossfadeDuration: Duration(milliseconds: 100),
      );

      expect(a.lerp(b, 0), same(a));
      expect(a.lerp(b, 1), same(b));
    });
  });
}
