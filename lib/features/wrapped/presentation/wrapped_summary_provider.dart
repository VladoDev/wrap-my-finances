import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/features/wrapped/domain/entities/wrapped_summary.dart';

/// Computes the `WrappedSummary` for a given `"YYYY-MM"` month key, per
/// `WrappedRepository.getSummary`. A thin `FutureProvider.family` wrapper,
/// matching `docs/TECH_STACK.md`'s "Riverpod owns... stream/future
/// subscriptions" rule.
final AutoDisposeFutureProviderFamily<WrappedSummary, String>
wrappedSummaryProvider = FutureProvider.autoDispose
    .family<WrappedSummary, String>((ref, monthKey) async {
      final result = await ref
          .watch(wrappedRepositoryProvider)
          .getSummary(monthKey);
      return result.when(
        success: (summary) => summary,
        failed: (failure) {
          throw StateError('WrappedRepository.getSummary failed: $failure');
        },
      );
    });
