import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/wrapped_auto_trigger_provider.dart';

/// Wraps the `ShellRoute`'s child (`lib/app.dart`): once per app session,
/// when `wrappedAutoTriggerProvider` resolves to a non-null month key,
/// navigates to `/wrapped/:monthKey` via a post-frame callback — never
/// blocking or delaying first paint (Constitution Principle 1). Renders
/// [child] unchanged in every other respect; this widget has no visual
/// output of its own.
class WrappedAutoTriggerGate extends ConsumerStatefulWidget {
  /// Creates the gate around [child].
  const WrappedAutoTriggerGate({required this.child, super.key});

  /// The `ShellRoute`'s current destination.
  final Widget child;

  @override
  ConsumerState<WrappedAutoTriggerGate> createState() =>
      _WrappedAutoTriggerGateState();
}

class _WrappedAutoTriggerGateState
    extends ConsumerState<WrappedAutoTriggerGate> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(wrappedAutoTriggerProvider, (previous, next) {
      next.whenData((monthKey) {
        if (_navigated || monthKey == null) return;
        _navigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/wrapped/$monthKey');
        });
      });
    });

    return widget.child;
  }
}
