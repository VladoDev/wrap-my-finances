import 'package:flutter/material.dart';

/// Semantic motion tokens (curves/durations), resolved from [BuildContext]
/// via `context.motion` (see `theme/design_tokens.dart`). No widget may
/// construct a bare `Curve`/`Duration` for Wrapped's animations — see
/// Constitution Principle 9, the same discipline
/// `app_colors.dart`/`app_typography.dart`/`app_spacing.dart` already
/// enforce for color/type/spacing.
@immutable
class AppMotionExtension extends ThemeExtension<AppMotionExtension> {
  /// Creates a motion token set. Every field is required.
  const AppMotionExtension({
    required this.springCurve,
    required this.storyAdvanceDuration,
    required this.countUpDuration,
    required this.crossfadeDuration,
  });

  /// The single motion scale this feature ships.
  static const AppMotionExtension standard = AppMotionExtension(
    springCurve: Curves.elasticOut,
    storyAdvanceDuration: Duration(seconds: 6),
    countUpDuration: Duration(milliseconds: 900),
    crossfadeDuration: Duration(milliseconds: 200),
  );

  /// The bounce/spring curve every Wrapped scene entrance uses.
  final Curve springCurve;

  /// How long each Wrapped scene stays on screen before auto-advancing —
  /// 5–7s per `docs/UI_UX_SPEC.md` §3; a single token so the exact value is
  /// set once.
  final Duration storyAdvanceDuration;

  /// How long a Wrapped figure's count-up animation takes.
  final Duration countUpDuration;

  /// The reduce-motion fallback: every spring/count-up animation collapses
  /// to a cross-fade of this duration when
  /// `MediaQuery.disableAnimationsOf(context)` is true.
  final Duration crossfadeDuration;

  @override
  AppMotionExtension copyWith({
    Curve? springCurve,
    Duration? storyAdvanceDuration,
    Duration? countUpDuration,
    Duration? crossfadeDuration,
  }) {
    return AppMotionExtension(
      springCurve: springCurve ?? this.springCurve,
      storyAdvanceDuration: storyAdvanceDuration ?? this.storyAdvanceDuration,
      countUpDuration: countUpDuration ?? this.countUpDuration,
      crossfadeDuration: crossfadeDuration ?? this.crossfadeDuration,
    );
  }

  @override
  AppMotionExtension lerp(
    ThemeExtension<AppMotionExtension>? other,
    double t,
  ) {
    if (other is! AppMotionExtension) return this;
    // A `Curve` has no meaningful interpolation, and this app never
    // animates between themes (`AppTheme.themeMode` is fixed, no
    // `darkTheme`) — snapping at the midpoint is a correct no-op in
    // practice, just satisfying `ThemeExtension`'s contract.
    return t < 0.5 ? this : other;
  }
}
