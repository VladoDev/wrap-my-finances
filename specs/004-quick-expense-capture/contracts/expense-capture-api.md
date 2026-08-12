# Contract: Expense Capture Domain API

This feature implements against `003`'s `ExpenseRepository`/`CategoryRepository`/`AuthRepository`
contracts without modifying their existing members, and adds the new surfaces below. Anything
already documented in `specs/003-auth-domain-foundation/contracts/` is not repeated here.

## `CategoryRepository` — additive member

```dart
abstract class CategoryRepository {
  // ...existing members, unchanged...

  /// Seeds the default category set if the user has no categories yet.
  /// Idempotent — safe to call on every app start. Requires an authenticated
  /// UID (call it via `AuthRepository.runWhenAuthenticated`), since writing
  /// a category requires `isOwner(userId)`.
  Future<Result<void>> seedDefaultsIfNeeded();
}
```

Per `003`'s own contract stability notes, this is an additive widening — existing callers
(none yet exist outside this feature) are unaffected.

## `LogExpense` use case (new)

```dart
class LogExpense {
  LogExpense(
    this._authRepository,
    this._expenseRepository,
    this._categoryRepository,
    this._appLaunchClock,
    this._analyticsService,
  );

  final AuthRepository _authRepository;
  final ExpenseRepository _expenseRepository;
  final CategoryRepository _categoryRepository;
  final AppLaunchClock _appLaunchClock;
  final AnalyticsService _analyticsService;

  Future<Result<Expense>> call(Expense draft) {
    return _authRepository.runWhenAuthenticated((uid) async {
      final result = await _expenseRepository.create(draft);
      return result.when(
        success: (expense) async {
          await _categoryRepository.incrementUsage(expense.categoryId);
          _analyticsService.logExpenseTimeToLog(
            _appLaunchClock.elapsedSinceLaunch(),
          );
          return Success(expense);
        },
        failed: (failure) async => Failed<Expense>(failure),
      );
    });
  }
}
```

This is the exact pattern `003`'s `auth-api.md` prescribed for every future write use case, extended
with the two additions this feature needs: the category-usage side effect and the timing/analytics
side effect, both fired only after the expense's `Result` resolves successfully — i.e., only after
local persistence is confirmed (see `research.md`'s local-write-detection decision), never before,
never gated on the server.

## `SeedDefaultCategoriesUseCase` (new)

```dart
class SeedDefaultCategoriesUseCase {
  SeedDefaultCategoriesUseCase(this._authRepository, this._categoryRepository);
  final AuthRepository _authRepository;
  final CategoryRepository _categoryRepository;

  Future<void> call() {
    return _authRepository.runWhenAuthenticated(
      (uid) => _categoryRepository.seedDefaultsIfNeeded(),
    );
  }
}
```

Called fire-and-forget from `bootstrap()`, the same way `003`'s `SignInAnonymouslyUseCase` is —
never awaited, never blocks first frame.

## `AppLaunchClock` (new, `core/instrumentation/`)

```dart
class AppLaunchClock {
  AppLaunchClock(this.startedAt);
  final DateTime startedAt;
  Duration elapsedSinceLaunch() => DateTime.now().difference(startedAt);
}
```

Pure Dart — safe for a domain use case to depend on directly. Registered as a GetIt singleton
constructed with `DateTime.now()` as the first statement of `bootstrap()`.

## `AnalyticsService` (new, `core/analytics/`)

```dart
abstract class AnalyticsService {
  /// Reports FR-003/SC-001's measured duration. [elapsed] only — no
  /// monetary amount, note, or category name may ever be passed to any
  /// method on this interface (Constitution Principle 5).
  void logExpenseTimeToLog(Duration elapsed);
}
```

`FirebaseAnalyticsService` (the `@LazySingleton(as: AnalyticsService)` implementation) sends the
`time_to_log_expense` event with a single `duration_ms` integer parameter.

## `ExpenseRepository.create()` — behavioral contract clarified (no signature change)

`create(Expense expense)` was already specified by `003` to return `Result<Expense>`. This feature
fixes the previously-unspecified *behavior*: the returned `Future` resolves once the write is
confirmed present in the **local** Firestore cache (detected via the document's own snapshot
listener reporting `exists: true`, not `hasPendingWrites` — see research.md's correction), never
once the server acknowledges it. The `Expense` in a `Success` result carries the real,
repository-assigned `id`, which may differ from whatever placeholder the caller's draft carried.

## Stability notes for consumers

- Every new member here returns `Result<T>`/`Future<void>` or takes primitive/domain-only
  parameters — no Flutter or Firebase type crosses into a signature a `domain/` file can see,
  consistent with `003`'s existing contracts.
- A future feature (e.g. manual category management, `Phase 3`) that adds user-created categories
  does not need to change `seedDefaultsIfNeeded()` — it is additive and idempotent, safe to keep
  calling forever.
