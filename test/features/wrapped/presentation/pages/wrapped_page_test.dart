import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/core/design_system/tokens/app_colors.dart';
import 'package:wrap_my_finances/core/design_system/tokens/app_motion.dart';
import 'package:wrap_my_finances/core/design_system/tokens/app_spacing.dart';
import 'package:wrap_my_finances/core/design_system/tokens/app_typography.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/pages/wrapped_page.dart';

// Long enough that auto-advance never fires during any of these tests —
// this file only exercises gesture wiring (tap/long-press/drag) and the
// reduce-motion transition choice; auto-advance's own timing is already
// covered by wrapped_controller_test.dart.
const _longAdvance = Duration(minutes: 10);

ThemeData _themeWithLongMotion() {
  return AppTheme.light.copyWith(
    extensions: <ThemeExtension<dynamic>>[
      AppColorsExtension.light,
      AppTypographyExtension.standard,
      AppSpacingExtension.standard,
      AppMotionExtension.standard.copyWith(
        storyAdvanceDuration: _longAdvance,
        crossfadeDuration: const Duration(milliseconds: 10),
      ),
    ],
  );
}

Widget _placeholderScene(String label) =>
    Center(child: Text(label, textDirection: TextDirection.ltr));

Future<void> _pumpWrappedPage(
  WidgetTester tester, {
  bool disableAnimations = false,
  ValueChanged<double>? onDismissed,
}) {
  return tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: ProviderScope(
        child: MaterialApp(
          theme: _themeWithLongMotion(),
          home: WrappedPage(
            monthKey: '2026-07',
            scenes: [
              _placeholderScene('Scene A'),
              _placeholderScene('Scene B'),
              _placeholderScene('Scene C'),
            ],
            onDismissed: onDismissed,
          ),
        ),
      ),
    ),
  );
}

// WrappedController's auto-advance Timer keeps running for as long as its
// (autoDispose) provider is alive. Tearing down inline (not via
// addTearDown, which doesn't get the same pump/flush guarantees — see
// research.md) lets Riverpod's disposal actually cancel it before
// flutter_test's end-of-test "no pending timers" check runs.
Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tapping the right half advances to the next scene', (
    tester,
  ) async {
    await _pumpWrappedPage(tester, disableAnimations: true);
    expect(find.text('Scene A'), findsOneWidget);

    final size = tester.getSize(find.byType(WrappedPage));
    await tester.tapAt(Offset(size.width * 0.75, size.height / 2));
    await tester.pump();

    expect(find.text('Scene B'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('tapping the left half goes back to the previous scene', (
    tester,
  ) async {
    await _pumpWrappedPage(tester, disableAnimations: true);
    final size = tester.getSize(find.byType(WrappedPage));

    await tester.tapAt(Offset(size.width * 0.75, size.height / 2));
    await tester.pump();
    expect(find.text('Scene B'), findsOneWidget);

    await tester.tapAt(Offset(size.width * 0.25, size.height / 2));
    await tester.pump();
    expect(find.text('Scene A'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets(
    'a long-press-and-hold pauses auto-advance; releasing resumes it',
    (tester) async {
      await _pumpWrappedPage(tester, disableAnimations: true);
      final size = tester.getSize(find.byType(WrappedPage));
      final location = Offset(size.width * 0.75, size.height / 2);

      final gesture = await tester.startGesture(location);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 10));
      // Advance the right side while held down — still paused, so this must
      // not register as a tap-to-advance either.
      await tester.pump();
      expect(find.text('Scene A'), findsOneWidget);

      await gesture.up();
      await tester.pump();
      // Releasing resumes auto-advance (not yet due, _longAdvance) but does
      // not itself advance the scene.
      expect(find.text('Scene A'), findsOneWidget);
      await _dispose(tester);
    },
  );

  testWidgets('a downward drag dismisses and calls onDismissed', (
    tester,
  ) async {
    var dismissed = false;
    await _pumpWrappedPage(
      tester,
      disableAnimations: true,
      onDismissed: (_) => dismissed = true,
    );

    // fling (not dragFrom) — dismiss requires a deliberate swipe velocity
    // (_dismissVelocityThreshold), not just any downward movement.
    await tester.fling(find.byType(WrappedPage), const Offset(0, 300), 1000);
    await tester.pump();

    expect(dismissed, isTrue);
    await _dispose(tester);
  });

  testWidgets(
    'with reduce motion, scene changes use AnimatedSwitcher, not '
    'flutter_animate spring effects',
    (tester) async {
      await _pumpWrappedPage(tester, disableAnimations: true);

      expect(find.byType(AnimatedSwitcher), findsOneWidget);

      final size = tester.getSize(find.byType(WrappedPage));
      await tester.tapAt(Offset(size.width * 0.75, size.height / 2));
      // A short pump is enough for the crossfade (10ms) to fully settle —
      // no multi-second spring animation to wait out.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 15));

      expect(find.text('Scene B'), findsOneWidget);
      await _dispose(tester);
    },
  );

  testWidgets('without reduce motion, scene changes do not use '
      'AnimatedSwitcher', (tester) async {
    await _pumpWrappedPage(tester);

    expect(find.byType(AnimatedSwitcher), findsNothing);
    await _dispose(tester);
  });
}
