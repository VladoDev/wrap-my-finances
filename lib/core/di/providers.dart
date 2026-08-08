import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/config/app_environment.dart';
import 'package:wrap_my_finances/core/di/injection.dart';
import 'package:wrap_my_finances/core/diagnostics/domain/repositories/environment_probe_repository.dart';

/// The single bridge between GetIt's [AppEnvironment] singleton and Riverpod.
/// Widgets read this instead of calling `getIt` directly.
final appEnvironmentProvider = Provider<AppEnvironment>(
  (ref) => getIt<AppEnvironment>(),
);

/// The single bridge between GetIt's [EnvironmentProbeRepository] and
/// Riverpod. Widgets read this instead of calling `getIt` directly.
final environmentProbeRepositoryProvider = Provider<EnvironmentProbeRepository>(
  (ref) => getIt<EnvironmentProbeRepository>(),
);

/// Human-readable outcome of the most recent probe write this session
/// (either the written document's ID or an error description). Local,
/// ephemeral UI state for the temporary diagnostics screen — not a domain
/// concept.
final environmentProbeResultProvider = StateProvider<String?>((ref) => null);
