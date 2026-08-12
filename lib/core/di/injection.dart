import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:wrap_my_finances/core/config/app_environment.dart';
import 'package:wrap_my_finances/core/di/injection.config.dart';

/// The single GetIt container. Widgets must not reference this directly —
/// go through a Riverpod provider in `providers.dart` instead.
final GetIt getIt = GetIt.instance;

/// Registers the active [AppEnvironment] and initializes every
/// `@injectable`-annotated infrastructure binding for it.
@InjectableInit()
Future<void> configureDependencies(AppEnvironment env) async {
  getIt
    ..registerSingleton<AppEnvironment>(env)
    ..init();
}
