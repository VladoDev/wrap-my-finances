import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/analytics/analytics_service.dart';
import 'package:wrap_my_finances/core/config/app_environment.dart';
import 'package:wrap_my_finances/core/di/injection.dart';
import 'package:wrap_my_finances/features/auth/domain/repositories/auth_repository.dart';
import 'package:wrap_my_finances/features/auth/domain/usecases/delete_account.dart';
import 'package:wrap_my_finances/features/auth/domain/usecases/link_account.dart';
import 'package:wrap_my_finances/features/categories/domain/repositories/category_repository.dart';
import 'package:wrap_my_finances/features/expenses/domain/repositories/expense_repository.dart';
import 'package:wrap_my_finances/features/expenses/domain/usecases/log_expense.dart';
import 'package:wrap_my_finances/features/user_profile/domain/repositories/user_profile_repository.dart';
import 'package:wrap_my_finances/features/wrapped/domain/repositories/wrapped_repository.dart';

/// The single bridge between GetIt's [AppEnvironment] singleton and Riverpod.
/// Widgets read this instead of calling `getIt` directly.
final appEnvironmentProvider = Provider<AppEnvironment>(
  (ref) => getIt<AppEnvironment>(),
);

/// Bridge for [ExpenseRepository], per `docs/TECH_STACK.md`'s "GetIt owns
/// infrastructure, Riverpod owns everything reactive" boundary — widgets
/// depend on this provider, never on `getIt` directly.
final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => getIt<ExpenseRepository>(),
);

/// Bridge for [CategoryRepository], same reasoning as
/// [expenseRepositoryProvider].
final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => getIt<CategoryRepository>(),
);

/// Bridge for [LogExpense], same reasoning as [expenseRepositoryProvider] —
/// `ExpenseCaptureController` reads this instead of calling `getIt`
/// directly.
final logExpenseProvider = Provider<LogExpense>((ref) => getIt<LogExpense>());

/// Bridge for [UserProfileRepository], same reasoning as
/// [expenseRepositoryProvider].
final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => getIt<UserProfileRepository>(),
);

/// Bridge for [WrappedRepository], same reasoning as
/// [expenseRepositoryProvider].
final wrappedRepositoryProvider = Provider<WrappedRepository>(
  (ref) => getIt<WrappedRepository>(),
);

/// Bridge for [AnalyticsService], same reasoning as
/// [expenseRepositoryProvider] — `WrappedRoutePage` reads this instead of
/// calling `getIt` directly.
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => getIt<AnalyticsService>(),
);

/// Bridge for [AuthRepository], same reasoning as [expenseRepositoryProvider]
/// — `SettingsAccountSection` reads this instead of calling `getIt`
/// directly.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => getIt<AuthRepository>(),
);

/// Whether the current session already has a Google/Apple provider
/// attached. Callers that just changed link state call
/// `ref.invalidate(isLinkedProvider)` to force a re-read, since
/// [AuthRepository.isLinked] itself is a plain, non-reactive getter.
final isLinkedProvider = Provider<bool>(
  (ref) => ref.watch(authRepositoryProvider).isLinked,
);

/// Which provider the current session is linked to, for display — `null`
/// when [isLinkedProvider] is `false`. Same invalidate-to-refresh contract.
final linkedProviderLabelProvider = Provider<String?>(
  (ref) => ref.watch(authRepositoryProvider).linkedProviderLabel,
);

/// Bridge for [LinkAccountUseCase], same reasoning as
/// [expenseRepositoryProvider].
final linkAccountUseCaseProvider = Provider<LinkAccountUseCase>(
  (ref) => getIt<LinkAccountUseCase>(),
);

/// Bridge for [DeleteAccountUseCase], same reasoning as
/// [expenseRepositoryProvider].
final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>(
  (ref) => getIt<DeleteAccountUseCase>(),
);

/// The device's current primary language code, read without needing a
/// `BuildContext` — lets `ExpenseCaptureController` be constructed inside a
/// plain Riverpod provider rather than requiring widget-tree plumbing.
/// Overridable in tests via `ProviderScope(overrides: [...])`.
final deviceLanguageCodeProvider = Provider<String>(
  (ref) => PlatformDispatcher.instance.locale.languageCode,
);
