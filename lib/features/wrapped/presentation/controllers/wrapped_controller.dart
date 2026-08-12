import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Wrapped story sequencer's state: which scene is showing, whether
/// auto-advance is paused, and whether the sequence has been dismissed.
@immutable
class WrappedState {
  /// Creates a state.
  const WrappedState({
    required this.sceneIndex,
    required this.sceneCount,
    required this.isPaused,
    required this.isDismissed,
  });

  /// The starting state: first scene, running, not dismissed.
  factory WrappedState.initial(int sceneCount) => WrappedState(
    sceneIndex: 0,
    sceneCount: sceneCount,
    isPaused: false,
    isDismissed: false,
  );

  /// Index of the currently visible scene, `0`-based.
  final int sceneIndex;

  /// Total number of scenes in this sequence.
  final int sceneCount;

  /// Whether auto-advance is currently suspended (long-press held).
  final bool isPaused;

  /// Whether the sequence has ended — either dismissed (swipe-down) or
  /// advanced past the last scene.
  final bool isDismissed;

  /// Copies this state, overriding the given fields.
  WrappedState copyWith({int? sceneIndex, bool? isPaused, bool? isDismissed}) {
    return WrappedState(
      sceneIndex: sceneIndex ?? this.sceneIndex,
      sceneCount: sceneCount,
      isPaused: isPaused ?? this.isPaused,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}

/// Orchestrates the Wrapped story sequence: auto-advance, tap-right/
/// tap-left, long-press-pause, and swipe-down-dismiss (FR-006/FR-007). Pure
/// Riverpod state — no Firestore/navigation side effect lives here; a
/// caller observes [WrappedState.isDismissed] and reacts (e.g. marking the
/// month seen, popping the route). See
/// `specs/006-monthly-wrapped-summary/contracts/wrapped-domain-api.md`.
class WrappedController extends StateNotifier<WrappedState> {
  /// Creates the controller for a sequence of [sceneCount] scenes.
  /// [storyAdvanceDuration] is required (not defaulted) so callers always
  /// supply `context.motion.storyAdvanceDuration` explicitly rather than a
  /// second literal duplicating that token — see
  /// `specs/006-monthly-wrapped-summary/research.md` #5.
  WrappedController({
    required int sceneCount,
    required this.storyAdvanceDuration,
  }) : super(WrappedState.initial(sceneCount)) {
    _scheduleAutoAdvance();
  }

  /// How long each scene stays on screen before auto-advancing.
  final Duration storyAdvanceDuration;

  Timer? _timer;

  void _scheduleAutoAdvance() {
    _timer?.cancel();
    if (state.isPaused || state.isDismissed) return;
    _timer = Timer(storyAdvanceDuration, advance);
  }

  /// Advances to the next scene, or dismisses if already on the last one.
  void advance() {
    if (state.isDismissed) return;
    if (state.sceneIndex + 1 >= state.sceneCount) {
      dismiss();
      return;
    }
    state = state.copyWith(sceneIndex: state.sceneIndex + 1);
    _scheduleAutoAdvance();
  }

  /// Goes back one scene. No-ops on the first scene.
  void goBack() {
    if (state.isDismissed || state.sceneIndex == 0) return;
    state = state.copyWith(sceneIndex: state.sceneIndex - 1);
    _scheduleAutoAdvance();
  }

  /// Suspends auto-advance for as long as the pointer is held down.
  void pause() {
    if (state.isDismissed) return;
    _timer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  /// Resumes auto-advance after [pause].
  void resume() {
    if (state.isDismissed) return;
    state = state.copyWith(isPaused: false);
    _scheduleAutoAdvance();
  }

  /// Ends the sequence immediately, from any scene.
  void dismiss() {
    _timer?.cancel();
    state = state.copyWith(isDismissed: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Riverpod provider for [WrappedController], keyed by its (`sceneCount`,
/// `storyAdvanceDuration`) arguments — a record, so structural equality is
/// automatic.
final AutoDisposeStateNotifierProviderFamily<
  WrappedController,
  WrappedState,
  ({int sceneCount, Duration storyAdvanceDuration})
>
wrappedControllerProvider = StateNotifierProvider.autoDispose
    .family<
      WrappedController,
      WrappedState,
      ({int sceneCount, Duration storyAdvanceDuration})
    >((ref, args) {
      return WrappedController(
        sceneCount: args.sceneCount,
        storyAdvanceDuration: args.storyAdvanceDuration,
      );
    });
