import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/features/wrapped/domain/usecases/wrapped_trigger_decision.dart';

/// Resolves to the previous month's key if `WrappedSuppressedCard` should
/// currently be offered (the trigger decision is `offerSuppressedCard`), or
/// `null` otherwise. Depends only on `wrapped`'s and `user_profile`'s
/// `domain/` surfaces (repository interfaces + the pure
/// `decideWrappedTrigger` use case) — never their `presentation/`
/// internals, per Constitution Principle 4.
///
/// Deliberately `.autoDispose` (unlike `wrappedAutoTriggerProvider`): this
/// widget re-evaluates every time the history screen is revisited, so
/// dismissing the card is reflected immediately without needing an app
/// restart — the once-per-session caching that provider needs for
/// correctness doesn't apply here.
final AutoDisposeFutureProvider<String?> wrappedSuppressedCardMonthProvider =
    FutureProvider.autoDispose<String?>((ref) async {
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
          return decision == WrappedTriggerResult.offerSuppressedCard
              ? monthKey
              : null;
        },
        failed: (_) => null,
      );
    });
