import 'package:flutter/material.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';

/// The rounded, segmented progress bar at the top of the Wrapped sequence
/// (`docs/UI_UX_SPEC.md` §3) — one segment per scene, the active segment
/// fills over [duration], earlier segments render fully filled, later ones
/// empty. [isPaused] freezes the active segment's fill without resetting it.
class WrappedProgressBar extends StatefulWidget {
  /// Creates a progress bar for [sceneCount] scenes, currently on
  /// [activeIndex].
  const WrappedProgressBar({
    required this.sceneCount,
    required this.activeIndex,
    required this.duration,
    required this.isPaused,
    super.key,
  });

  /// Total number of scenes/segments.
  final int sceneCount;

  /// The currently visible scene's index.
  final int activeIndex;

  /// How long the active segment takes to fill.
  final Duration duration;

  /// Whether the active segment's fill is currently frozen.
  final bool isPaused;

  @override
  State<WrappedProgressBar> createState() => _WrappedProgressBarState();
}

class _WrappedProgressBarState extends State<WrappedProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (!widget.isPaused) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant WrappedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      _controller.duration = widget.duration;
      _controller.forward(from: 0);
    } else if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _controller.stop();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          children: [
            for (var i = 0; i < widget.sceneCount; i++) ...[
              if (i > 0) SizedBox(width: spacing.spacingXs),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(spacing.radiusSm),
                  child: LinearProgressIndicator(
                    value: i < widget.activeIndex
                        ? 1
                        : i == widget.activeIndex
                        ? _controller.value
                        : 0,
                    minHeight: spacing.spacingXs,
                    backgroundColor: colors.surface.withValues(alpha: 0.35),
                    valueColor: AlwaysStoppedAnimation<Color>(colors.surface),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
