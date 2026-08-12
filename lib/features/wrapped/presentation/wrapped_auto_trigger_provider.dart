import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/features/wrapped/domain/usecases/wrapped_trigger_decision.dart';

/// Evaluates the auto-trigger once per app session: resolves the current
/// `UserProfile`, computes the previous calendar month, fetches its
/// `WrappedSummary`, and applies `decideWrappedTrigger`. Resolves to the
/// month key to auto-show, or `null` if nothing should happen — the
/// suppressed-card offer is a separate, narrower read
/// (`WrappedSuppressedCard`'s own use of this same decision), not a second
/// value on this provider.
///
/// Deliberately **not** `.autoDispose`: `WrappedAutoTriggerGate` (the only
/// watcher) unmounts whenever the app navigates to `/wrapped/:monthKey`
/// (declared as a sibling of `ShellRoute`, not nested inside it). An
/// `autoDispose` provider would be torn down and re-evaluated on the very
/// next remount — i.e. immediately after dismissing Wrapped — before the
/// `markWrappedSeen` write has necessarily propagated back through
/// `watchProfile()`, risking a spurious re-trigger. Caching for the app's
/// whole lifetime is what "never runs again mid-session once it has
/// resolved" (contracts/wrapped-domain-api.md) actually requires.
final FutureProvider<String?> wrappedAutoTriggerProvider =
    FutureProvider<String?>((ref) async {
      final profile = await ref
          .watch(userProfileRepositoryProvider)
          .watchProfile()
          .first;
      final monthKey = previousMonthKey(DateTime.now());
      final summaryResult = await ref
          .watch(wrappedRepositoryProvider)
          .getSummary(monthKey);

      return summaryResult.when(
        success: (summary) {
          final decision = decideWrappedTrigger(
            profile: profile,
            summary: summary,
          );
          return decision == WrappedTriggerResult.autoShow ? monthKey : null;
        },
        failed: (_) => null,
      );
    });
