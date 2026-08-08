// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:wrap_my_finances/core/config/app_environment.dart' as _i795;
import 'package:wrap_my_finances/core/di/firebase_module.dart' as _i919;
import 'package:wrap_my_finances/core/diagnostics/data/repositories/firestore_environment_probe_repository.dart'
    as _i890;
import 'package:wrap_my_finances/core/diagnostics/domain/repositories/environment_probe_repository.dart'
    as _i380;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final firebaseModule = _$FirebaseModule();
    gh.lazySingleton<_i974.FirebaseFirestore>(() => firebaseModule.firestore);
    gh.lazySingleton<_i59.FirebaseAuth>(() => firebaseModule.auth);
    gh.lazySingleton<_i380.EnvironmentProbeRepository>(
      () => _i890.FirestoreEnvironmentProbeRepository(
        gh<_i974.FirebaseFirestore>(),
        gh<_i59.FirebaseAuth>(),
        gh<_i795.AppEnvironment>(),
      ),
    );
    return this;
  }
}

class _$FirebaseModule extends _i919.FirebaseModule {}
