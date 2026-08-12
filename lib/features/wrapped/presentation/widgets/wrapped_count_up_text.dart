import 'package:flutter/material.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';

/// A number that counts up from `0` to [value] over
/// `context.motion.countUpDuration` (`docs/UI_UX_SPEC.md` §3: "Numbers
/// count up dynamically"). Under reduce motion, renders [value] immediately
/// — no animation, per FR-008.
class WrappedCountUpText extends StatelessWidget {
  /// Creates a count-up display of [value], formatted by [formatter] at
  /// each animated step.
  const WrappedCountUpText({
    required this.value,
    required this.formatter,
    this.style,
    super.key,
  });

  /// The final value to count up to.
  final double value;

  /// Formats the current (possibly mid-animation) value for display.
  final String Function(double value) formatter;

  /// Text style applied to the rendered number.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      return Text(formatter(value), style: style);
    }

    final motion = context.motion;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: motion.countUpDuration,
      curve: motion.springCurve,
      builder: (context, animatedValue, _) {
        // elasticOut-style curves can briefly overshoot below 0 on the way
        // in — clamp so the display never flashes a negative figure.
        final clamped = animatedValue.clamp(0, double.infinity).toDouble();
        return Text(formatter(clamped), style: style);
      },
    );
  }
}
