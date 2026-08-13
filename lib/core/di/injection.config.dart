// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:firebase_analytics/firebase_analytics.dart' as _i398;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:wrap_my_finances/core/analytics/analytics_service.dart'
    as _i499;
import 'package:wrap_my_finances/core/analytics/firebase_analytics_service.dart'
    as _i495;
import 'package:wrap_my_finances/core/di/firebase_module.dart' as _i919;
import 'package:wrap_my_finances/core/instrumentation/app_launch_clock.dart'
    as _i346;
import 'package:wrap_my_finances/features/auth/data/apple_sign_in_credential_provider.dart'
    as _i683;
import 'package:wrap_my_finances/features/auth/data/google_sign_in_credential_provider.dart'
    as _i574;
import 'package:wrap_my_finances/features/auth/data/repositories/firebase_auth_repository.dart'
    as _i153;
import 'package:wrap_my_finances/features/auth/domain/repositories/auth_repository.dart'
    as _i261;
import 'package:wrap_my_finances/features/auth/domain/usecases/delete_account.dart'
    as _i466;
import 'package:wrap_my_finances/features/auth/domain/usecases/link_account.dart'
    as _i281;
import 'package:wrap_my_finances/features/auth/domain/usecases/sign_in_anonymously.dart'
    as _i691;
import 'package:wrap_my_finances/features/categories/data/datasources/category_remote_data_source.dart'
    as _i1029;
import 'package:wrap_my_finances/features/categories/data/repositories/category_repository_impl.dart'
    as _i968;
import 'package:wrap_my_finances/features/categories/domain/repositories/category_repository.dart'
    as _i496;
import 'package:wrap_my_finances/features/categories/domain/usecases/seed_default_categories.dart'
    as _i97;
import 'package:wrap_my_finances/features/expenses/data/datasources/expense_remote_data_source.dart'
    as _i760;
import 'package:wrap_my_finances/features/expenses/data/repositories/expense_repository_impl.dart'
    as _i274;
import 'package:wrap_my_finances/features/expenses/domain/repositories/expense_repository.dart'
    as _i345;
import 'package:wrap_my_finances/features/expenses/domain/usecases/log_expense.dart'
    as _i672;
import 'package:wrap_my_finances/features/expenses/domain/usecases/purge_expired_deleted_expenses.dart'
    as _i520;
import 'package:wrap_my_finances/features/user_profile/data/datasources/user_profile_remote_data_source.dart'
    as _i330;
import 'package:wrap_my_finances/features/user_profile/data/repositories/user_profile_repository_impl.dart'
    as _i693;
import 'package:wrap_my_finances/features/user_profile/domain/repositories/user_profile_repository.dart'
    as _i616;
import 'package:wrap_my_finances/features/user_profile/domain/usecases/ensure_user_profile.dart'
    as _i160;
import 'package:wrap_my_finances/features/wrapped/data/datasources/wrapped_remote_data_source.dart'
    as _i493;
import 'package:wrap_my_finances/features/wrapped/data/repositories/wrapped_repository_impl.dart'
    as _i938;
import 'package:wrap_my_finances/features/wrapped/domain/repositories/wrapped_repository.dart'
    as _i220;

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
    gh.lazySingleton<_i398.FirebaseAnalytics>(() => firebaseModule.analytics);
    gh.lazySingleton<_i683.AppleSignInCredentialProvider>(
      () => _i683.AppleSignInCredentialProvider(),
    );
    gh.lazySingleton<_i574.GoogleSignInCredentialProvider>(
      () => _i574.GoogleSignInCredentialProvider(),
    );
    gh.lazySingleton<_i499.AnalyticsService>(
      () => _i495.FirebaseAnalyticsService(gh<_i398.FirebaseAnalytics>()),
    );
    gh.factory<_i1029.CategoryRemoteDataSource>(
      () => _i1029.CategoryRemoteDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.factory<_i760.ExpenseRemoteDataSource>(
      () => _i760.ExpenseRemoteDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.factory<_i330.UserProfileRemoteDataSource>(
      () => _i330.UserProfileRemoteDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.factory<_i493.WrappedRemoteDataSource>(
      () => _i493.WrappedRemoteDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i496.CategoryRepository>(
      () => _i968.CategoryRepositoryImpl(
        gh<_i1029.CategoryRemoteDataSource>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.lazySingleton<_i345.ExpenseRepository>(
      () => _i274.ExpenseRepositoryImpl(
        gh<_i760.ExpenseRemoteDataSource>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.lazySingleton<_i261.AuthRepository>(
      () => _i153.FirebaseAuthRepository(
        gh<_i59.FirebaseAuth>(),
        gh<_i974.FirebaseFirestore>(),
        gh<_i574.GoogleSignInCredentialProvider>(),
        gh<_i683.AppleSignInCredentialProvider>(),
        gh<_i345.ExpenseRepository>(),
        gh<_i496.CategoryRepository>(),
      ),
    );
    gh.lazySingleton<_i220.WrappedRepository>(
      () => _i938.WrappedRepositoryImpl(
        gh<_i345.ExpenseRepository>(),
        gh<_i496.CategoryRepository>(),
        gh<_i493.WrappedRemoteDataSource>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.factory<_i97.SeedDefaultCategoriesUseCase>(
      () => _i97.SeedDefaultCategoriesUseCase(
        gh<_i261.AuthRepository>(),
        gh<_i496.CategoryRepository>(),
      ),
    );
    gh.factory<_i672.LogExpense>(
      () => _i672.LogExpense(
        gh<_i261.AuthRepository>(),
        gh<_i345.ExpenseRepository>(),
        gh<_i496.CategoryRepository>(),
        gh<_i346.AppLaunchClock>(),
        gh<_i499.AnalyticsService>(),
      ),
    );
    gh.lazySingleton<_i616.UserProfileRepository>(
      () => _i693.UserProfileRepositoryImpl(
        gh<_i330.UserProfileRemoteDataSource>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.factory<_i466.DeleteAccountUseCase>(
      () => _i466.DeleteAccountUseCase(gh<_i261.AuthRepository>()),
    );
    gh.factory<_i691.SignInAnonymouslyUseCase>(
      () => _i691.SignInAnonymouslyUseCase(gh<_i261.AuthRepository>()),
    );
    gh.factory<_i281.LinkAccountUseCase>(
      () => _i281.LinkAccountUseCase(
        gh<_i261.AuthRepository>(),
        gh<_i345.ExpenseRepository>(),
        gh<_i496.CategoryRepository>(),
      ),
    );
    gh.factory<_i520.PurgeExpiredDeletedExpensesUseCase>(
      () => _i520.PurgeExpiredDeletedExpensesUseCase(
        gh<_i261.AuthRepository>(),
        gh<_i345.ExpenseRepository>(),
      ),
    );
    gh.factory<_i160.EnsureUserProfileUseCase>(
      () => _i160.EnsureUserProfileUseCase(
        gh<_i261.AuthRepository>(),
        gh<_i616.UserProfileRepository>(),
      ),
    );
    return this;
  }
}

class _$FirebaseModule extends _i919.FirebaseModule {}
