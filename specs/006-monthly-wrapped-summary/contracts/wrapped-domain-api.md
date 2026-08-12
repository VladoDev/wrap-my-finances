# Contract: Wrapped Domain API

Builds on `003`'s `AuthRepository`/`CategoryRepository` and `003`/`005`'s `ExpenseRepository`
contracts unchanged. Adds two new repository interfaces and one new controller.

## `UserProfileRepository` (new, domain — `lib/features/user_profile/domain/repositories/`)

```dart
abstract class UserProfileRepository {
  /// Creates `users/{uid}` with a device-locale-derived `timeZone` and
  /// `wrappedLastSeenMonth: null` if it doesn't exist yet. No-op if it
  /// does. Idempotent — safe to call on every launch. Requires an
  /// authenticated uid (call via `AuthRepository.runWhenAuthenticated`).
  Future<Result<void>> ensureExists();

  /// Live view of the current user's profile. Emits after `ensureExists()`
  /// has created the document, so callers never observe a "does not exist
  /// yet" state once subscribed post-bootstrap.
  Stream<UserProfile> watchProfile();

  /// Sets `wrappedLastSeenMonth` to [monthKey]. Called only when Wrapped
  /// (auto-shown or opened from the suppressed card) is actually dismissed
  /// — never merely from evaluating the trigger. See `data-model.md` §4.
  Future<Result<void>> markWrappedSeen(String monthKey);
}
```

## `WrappedRepository` (new, domain — `lib/features/wrapped/domain/repositories/`)

```dart
abstract class WrappedRepository {
  /// Computes the aggregate for [monthKey] (`"YYYY-MM"`). Compares the
  /// local cache's document count against a server-side `count()` for the
  /// same filter; returns a `WrappedSummary` with `isSyncing: true` and
  /// every other field meaningless if they disagree, per FR-012. Excludes
  /// every expense with a non-null `deletedAt`, per FR-010.
  Future<Result<WrappedSummary>> getSummary(String monthKey);
}
```

## `EnsureUserProfileUseCase` (new, domain)

```dart
class EnsureUserProfileUseCase {
  EnsureUserProfileUseCase(this._authRepository, this._userProfileRepository);
  final AuthRepository _authRepository;
  final UserProfileRepository _userProfileRepository;

  Future<void> call() {
    return _authRepository.runWhenAuthenticated(
      (_) => _userProfileRepository.ensureExists(),
    );
  }
}
```

Called fire-and-forget from `bootstrap()`, alongside `SignInAnonymouslyUseCase`,
`SeedDefaultCategoriesUseCase`, and `PurgeExpiredDeletedExpensesUseCase` — never awaited, never
blocks first frame (Constitution Principle 1).

## `WrappedController` (new, presentation — Riverpod `StateNotifier` or `Notifier`)

```dart
class WrappedController extends Notifier<WrappedState> {
  /// Advances to the next scene, or dismisses (marking the month seen) if
  /// already on the last one. Called by tap-right and by the auto-advance
  /// timer.
  void advance();

  /// Goes back one scene. No-ops on the first scene.
  void goBack();

  /// Suspends the auto-advance timer for as long as the pointer is held
  /// down. Resumes on release.
  void pause();
  void resume();

  /// Swipe-down: dismisses immediately regardless of current scene,
  /// marking the month seen.
  void dismiss();
}
```

Behavioral contract: `advance()`/`goBack()`/`pause()`/`resume()`/`dismiss()` never await Firestore —
`WrappedController` reads its `WrappedSummary` once (already resolved before the page is shown) and
only `dismiss()` (and `advance()` past the last scene) triggers the fire-and-forget
`markWrappedSeen()` call, matching `005`'s `requestDelete`/`undoDelete` "state changes are
synchronous, persistence is a side effect" precedent.

## Navigation contract

- `GoRoute(path: '/wrapped/:monthKey')` is declared as a **sibling** of the existing `ShellRoute`,
  not nested inside it — `AppShell`'s floating nav bar never renders over Wrapped. See
  `research.md` #8.
- Dismissing calls `context.pop()` if Wrapped was opened from History's month picker (a prior route
  exists to return to), or `context.go('/')` if it was auto-triggered (no prior route in this
  session) — either way landing back on capture or history, never on Wrapped itself, and never
  displacing capture as the fixed launch destination (existing FR-001/FR-012 from `005`, unchanged
  by this feature).
- The auto-trigger check (`wrappedAutoTriggerProvider`) runs once per app session, after first
  frame, and only ever navigates *into* `/wrapped/:monthKey` — it never runs again mid-session once
  it has resolved, so backgrounding and foregrounding the app does not re-trigger it.

## Stability notes for consumers

- `ExpenseRepository.watchByMonth()` (declared by `003`, never called by any shipped feature until
  now) is this feature's first real caller — no signature change.
- `CategoryRepository` is read-only from this feature's perspective (name resolution via
  `activeCategoriesProvider`'s existing `Map<String, Category>` pattern) — no new members needed.
- `UserProfileRepository` and `WrappedRepository` are wholly new; no existing caller is affected by
  their introduction.
