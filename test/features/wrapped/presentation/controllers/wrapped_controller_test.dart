import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/controllers/wrapped_controller.dart';

void main() {
  WrappedController buildController({
    int sceneCount = 3,
    Duration storyAdvanceDuration = const Duration(milliseconds: 20),
  }) {
    final controller = WrappedController(
      sceneCount: sceneCount,
      storyAdvanceDuration: storyAdvanceDuration,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  group('initial state', () {
    test('starts on the first scene, not paused, not dismissed', () {
      final controller = buildController();

      expect(controller.state.sceneIndex, 0);
      expect(controller.state.isPaused, isFalse);
      expect(controller.state.isDismissed, isFalse);
    });
  });

  group('advance', () {
    test('moves to the next scene', () {
      final controller = buildController(
        storyAdvanceDuration: const Duration(minutes: 10),
      )..advance();

      expect(controller.state.sceneIndex, 1);
      expect(controller.state.isDismissed, isFalse);
    });

    test('dismisses once advanced past the last scene', () {
      final controller =
          buildController(
              sceneCount: 2,
              storyAdvanceDuration: const Duration(minutes: 10),
            )
            ..advance() // scene 1 (last)
            ..advance(); // past the last scene

      expect(controller.state.isDismissed, isTrue);
    });

    test('auto-advances after storyAdvanceDuration elapses', () async {
      final controller = buildController(
        storyAdvanceDuration: const Duration(milliseconds: 30),
      );

      await Future<void>.delayed(const Duration(milliseconds: 45));

      expect(controller.state.sceneIndex, 1);
    });
  });

  group('goBack', () {
    test('moves to the previous scene', () {
      final controller =
          buildController(
              storyAdvanceDuration: const Duration(minutes: 10),
            )
            ..advance()
            ..goBack();

      expect(controller.state.sceneIndex, 0);
    });

    test('is a no-op on the first scene', () {
      final controller = buildController(
        storyAdvanceDuration: const Duration(minutes: 10),
      )..goBack();

      expect(controller.state.sceneIndex, 0);
    });
  });

  group('pause/resume', () {
    test('pause suspends auto-advance; resume restarts it', () async {
      final controller = buildController(
        storyAdvanceDuration: const Duration(milliseconds: 30),
      )..pause();

      expect(controller.state.isPaused, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(controller.state.sceneIndex, 0);

      controller.resume();
      expect(controller.state.isPaused, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(controller.state.sceneIndex, 1);
    });
  });

  group('dismiss', () {
    test('ends the sequence immediately from any scene', () {
      final controller =
          buildController(
              storyAdvanceDuration: const Duration(minutes: 10),
            )
            ..advance()
            ..dismiss();

      expect(controller.state.isDismissed, isTrue);
    });

    test('cancels the pending auto-advance timer', () async {
      final controller = buildController()..dismiss();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Had auto-advance not been cancelled, sceneIndex would have moved —
      // confirm it stayed put, proving the timer was cancelled, not just
      // not-yet-due (mirrors 005's "still not due" proof style).
      expect(controller.state.sceneIndex, 0);
      expect(controller.state.isDismissed, isTrue);
    });
  });
}
