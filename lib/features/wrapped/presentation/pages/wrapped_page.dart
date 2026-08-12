import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/controllers/wrapped_controller.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/widgets/wrapped_progress_bar.dart';

/// The minimum downward-drag velocity (logical pixels/second) treated as a
/// deliberate swipe-to-dismiss, rather than an incidental vertical drag.
const double _dismissVelocityThreshold = 200;

/// The full-screen Wrapped story sequencer (FR-006/FR-007): auto-advancing
/// scenes with a visible progress bar, tap-right/tap-left/long-press-pause/
/// swipe-down-dismiss, and reduce-motion-aware transitions (FR-008). Takes a
/// plain scene-widget list — [monthKey] identifies the sequence for
/// [onDismissed] callers (e.g. to mark the month seen), but this widget
/// itself is content-agnostic: real scenes are wired in by
/// `US3`(`wrapped_summary_provider.dart`)/`US5`(the shareable card).
class WrappedPage extends ConsumerWidget {
  /// Creates the page for [monthKey], sequencing [scenes].
  const WrappedPage({
    required this.monthKey,
    required this.scenes,
    this.onDismissed,
    super.key,
  });

  /// `"YYYY-MM"` — identifies which month this sequence is for.
  final String monthKey;

  /// The scene widgets to sequence, in order.
  final List<Widget> scenes;

  /// Called once, the moment the sequence ends (dismissed or advanced past
  /// the last scene), with the fraction of scenes seen (`(sceneIndex + 1) /
  /// sceneCount`) — the one figure Constitution Principle 5 allows this
  /// feature's analytics to carry (FR-017).
  final ValueChanged<double>? onDismissed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = context.motion;
    final colors = context.colors;
    final spacing = context.spacing;
    final args = (
      sceneCount: scenes.length,
      storyAdvanceDuration: motion.storyAdvanceDuration,
    );
    final provider = wrappedControllerProvider(args);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    ref.listen(provider, (previous, next) {
      if (next.isDismissed && previous?.isDismissed != true) {
        final completionRatio = (next.sceneIndex + 1) / next.sceneCount;
        onDismissed?.call(completionRatio);
      }
    });

    return Scaffold(
      backgroundColor: colors.onBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(spacing.spacingLg),
                child: reduceMotion
                    ? AnimatedSwitcher(
                        duration: motion.crossfadeDuration,
                        child: KeyedSubtree(
                          key: ValueKey(state.sceneIndex),
                          child: scenes[state.sceneIndex],
                        ),
                      )
                    : KeyedSubtree(
                        key: ValueKey(state.sceneIndex),
                        child: scenes[state.sceneIndex]
                            .animate()
                            .fadeIn(
                              duration: motion.countUpDuration,
                              curve: motion.springCurve,
                            )
                            .scale(
                              begin: const Offset(0.85, 0.85),
                              end: const Offset(1, 1),
                              duration: motion.countUpDuration,
                              curve: motion.springCurve,
                            ),
                      ),
              ),
            ),
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: _TapRegion(
                      onTap: controller.goBack,
                      onLongPressStart: controller.pause,
                      onLongPressEnd: controller.resume,
                      onDismiss: controller.dismiss,
                    ),
                  ),
                  Expanded(
                    child: _TapRegion(
                      onTap: controller.advance,
                      onLongPressStart: controller.pause,
                      onLongPressEnd: controller.resume,
                      onDismiss: controller.dismiss,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: spacing.spacingMd,
              left: spacing.spacingMd,
              right: spacing.spacingMd,
              child: WrappedProgressBar(
                sceneCount: scenes.length,
                activeIndex: state.sceneIndex,
                duration: motion.storyAdvanceDuration,
                isPaused: state.isPaused,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One half of the full-screen gesture surface — tap to advance/go back,
/// long-press to pause/resume, drag down to dismiss. A single
/// [GestureDetector] per side (rather than nesting one over the tap `Row`)
/// avoids gesture-arena conflicts between tap, long-press, and vertical
/// drag.
class _TapRegion extends StatelessWidget {
  const _TapRegion({
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.onDismiss,
  });

  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPressStart: (_) => onLongPressStart(),
      onLongPressEnd: (_) => onLongPressEnd(),
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > _dismissVelocityThreshold) {
          onDismiss();
        }
      },
      child: const SizedBox.expand(),
    );
  }
}
