import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/di/providers.dart';

/// Temporary diagnostics screen for this feature only (see `research.md`):
/// confirms which environment is active and, in `dev`, offers a control to
/// write an environment-probe test document. Expected to be superseded by
/// real product screens.
class EnvironmentStatusPage extends ConsumerWidget {
  /// Creates the page.
  const EnvironmentStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(appEnvironmentProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Environment: ${env.name}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (env.showDebugBanner) ...[
                const SizedBox(height: 16),
                Container(
                  key: const Key('debug-banner'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'DEV BUILD',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              if (env.allowSeeding) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  key: const Key('write-probe-button'),
                  onPressed: () => _writeProbe(ref),
                  child: const Text('Write test document'),
                ),
                const SizedBox(height: 8),
                Text(
                  ref.watch(environmentProbeResultProvider) ?? '',
                  key: const Key('probe-result-text'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _writeProbe(WidgetRef ref) async {
    final repository = ref.read(environmentProbeRepositoryProvider);
    final result = await repository.writeProbe('probe');
    ref.read(environmentProbeResultProvider.notifier).state = result.when(
      success: (probe) => 'Wrote probe ${probe.id}',
      failed: (failure) => 'Error: ${failure.runtimeType}',
    );
  }
}
