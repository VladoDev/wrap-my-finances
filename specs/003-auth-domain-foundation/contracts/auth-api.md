# Contract: Auth Feature Public API

Every future feature that writes to Firestore depends on this contract to get a valid,
authenticated write without ever handling sign-in timing itself.

## Consuming the buffer from a future use case

```dart
class LogExpense {
  LogExpense(this._authRepository, this._expenseRepository);
  final AuthRepository _authRepository;
  final ExpenseRepository _expenseRepository;

  Future<Result<Expense>> call(Expense draft) {
    return _authRepository.runWhenAuthenticated(
      (uid) => _expenseRepository.create(draft),
    );
  }
}
```

This is the pattern every future write use case (`004` onward) follows: obtain `AuthRepository`
via DI, call `runWhenAuthenticated`, never check `currentUserId` and branch manually, never show a
loading state while waiting for it.

## `AuthRepository` surface

```dart
abstract class AuthRepository {
  String? get currentUserId;
  Future<String> ensureSignedIn();
  Future<T> runWhenAuthenticated<T>(Future<T> Function(String uid) operation);
}
```

Guarantee: `runWhenAuthenticated` never throws due to sign-in timing — it either runs `operation`
immediately or queues it. `operation` itself can still fail (network, validation) and that failure
propagates normally through its returned `Future`.

## Bootstrap contract

```dart
// lib/bootstrap.dart
await configureDependencies(env);
unawaited(getIt<SignInAnonymouslyUseCase>().call());
```

No caller outside `bootstrap()` invokes `SignInAnonymouslyUseCase` — every other feature depends on
`AuthRepository` only, never triggers sign-in itself.

## Stability notes for consumers

- `AuthRepository` never exposes the underlying `FirebaseAuth`/`User` types — only a `String?` UID.
  A future switch to a different identity provider changes only `FirebaseAuthRepository`.
- `runWhenAuthenticated`'s queue is in-memory and per-process; it does not survive an app restart.
  A write that was queued and the app was killed before sign-in resolved is lost at the domain
  layer — but Firestore's own offline cache (already configured, FR-003) is what actually
  guarantees durability once `operation` runs, not this queue. The queue only bridges the narrow
  window between app start and sign-in resolution.
