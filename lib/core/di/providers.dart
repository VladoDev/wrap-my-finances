import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/config/app_environment.dart';
import 'package:wrap_my_finances/core/di/injection.dart';
import 'package:wrap_my_finances/features/categories/domain/repositories/category_repository.dart';
import 'package:wrap_my_finances/features/expenses/domain/repositories/expense_repository.dart';
import 'package:wrap_my_finances/features/expenses/domain/usecases/log_expense.dart';

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

/// The device's current primary language code, read without needing a
/// `BuildContext` — lets `ExpenseCaptureController` be constructed inside a
/// plain Riverpod provider rather than requiring widget-tree plumbing.
/// Overridable in tests via `ProviderScope(overrides: [...])`.
final deviceLanguageCodeProvider = Provider<String>(
  (ref) => PlatformDispatcher.instance.locale.languageCode,
);
