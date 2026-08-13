import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';

/// The "quick checkmark bounce plus light haptic feedback" success signal
/// (`docs/UI_UX_SPEC.md` §2), shown immediately once a write is confirmed
/// locally — never gated on the server (FR-005). Plays once on mount, then
/// calls [onCompleted] so the caller can remove it; fires the haptic once,
/// in `initState`, not on every rebuild.
///
/// Collapses to a plain cross-fade — no scale/bounce — when the platform
/// reduce-motion setting is enabled (Constitution Principle 8).
class SuccessFeedbackOverlay extends StatefulWidget {
  /// Creates the overlay. [onCompleted] fires after the animation ends.
  const SuccessFeedbackOverlay({required this.onCompleted, super.key});

  /// Called once the feedback has finished displaying.
  final VoidCallback onCompleted;

  @override
  State<SuccessFeedbackOverlay> createState() => _SuccessFeedbackOverlayState();
}

class _SuccessFeedbackOverlayState extends State<SuccessFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    unawaited(HapticFeedback.mediumImpact());
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onCompleted();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return IgnorePointer(
      child: Center(
        child: reduceMotion
            ? FadeTransition(
                opacity: _controller,
                child: _CheckmarkBadge(color: colors.secondary),
              )
            : ScaleTransition(
                scale: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.elasticOut,
                ),
                child: _CheckmarkBadge(color: colors.secondary),
              ),
      ),
    );
  }
}

class _CheckmarkBadge extends StatelessWidget {
  const _CheckmarkBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(Icons.check, color: context.colors.onSecondary, size: 56),
    );
  }
}
