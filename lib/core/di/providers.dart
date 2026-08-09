import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/config/app_environment.dart';
import 'package:wrap_my_finances/core/di/injection.dart';

/// The single bridge between GetIt's [AppEnvironment] singleton and Riverpod.
/// Widgets read this instead of calling `getIt` directly.
final appEnvironmentProvider = Provider<AppEnvironment>(
  (ref) => getIt<AppEnvironment>(),
);
