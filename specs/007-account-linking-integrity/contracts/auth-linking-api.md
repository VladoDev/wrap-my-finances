# Contract: Account Linking, Deletion & App Check

Builds on `003`'s `AuthRepository` contract (`currentUserId`, `ensureSignedIn`,
`runWhenAuthenticated`, unchanged). Adds linking, conflict resolution, and deletion.

## `AuthRepository` — additive members

```dart
abstract class AuthRepository {
  // ...existing members, unchanged...

  /// Whether the current session has a Google or Apple provider attached.
  /// `false` for a purely anonymous session.
  bool get isLinked;

  /// Attempts to link the current anonymous session to a Google account.
  /// On success, the uid is unchanged and every existing document is
  /// automatically still owned by it (research.md #1) — no further action
  /// needed by the caller. On `credential-already-in-use`, returns a
  /// `Failed` result carrying a `LinkConflictFailure` (not a generic
  /// `UnknownFailure`) so the caller can route to conflict resolution
  /// rather than showing a generic error (spec.md FR-004).
  Future<Result<void>> linkWithGoogle();

  /// Same contract as [linkWithGoogle], for Apple. Both exist in this
  /// feature together — Apple requires Sign in with Apple wherever Google
  /// Sign-In is offered (App Store Review Guideline 4.8).
  Future<Result<void>> linkWithApple();

  /// Resolves a [LinkConflictFailure] surfaced by [linkWithGoogle]/
  /// [linkWithApple], per [resolution]:
  /// - [LinkConflictResolution.merge]: reads the current (still-anonymous)
  ///   session's full expense/category history into memory, switches to
  ///   the existing account via the held credential, then writes that
  ///   history into the existing account's collections with fresh ids.
  /// - [LinkConflictResolution.discardLocal]: batch-deletes the current
  ///   session's expense/category history while still authenticated as it,
  ///   then switches to the existing account via the held credential.
  ///
  /// Either path requires network for both the read/delete phase and the
  /// switch/write phase; a mid-flow network loss is surfaced as a retryable
  /// failure, never as a silent partial state (spec.md FR-006 / US4).
  Future<Result<void>> resolveLinkConflict(
    LinkConflict conflict,
    LinkConflictResolution resolution,
  );

  /// Deletes every expense and category document, the `users/{uid}`
  /// document, and the Firebase Auth user record itself, in that order.
  /// On `requires-recent-login`, re-prompts the linked provider's sign-in
  /// and retries once — never surfaces that error directly to the caller.
  Future<Result<void>> deleteAccount();
}
```

## New failure case

```dart
/// Distinguishes "the credential is already tied to a different account"
/// from a generic failure, so callers can route to conflict-resolution UI
/// instead of a plain error message (spec.md FR-004).
final class LinkConflictFailure extends Failure {
  const LinkConflictFailure(this.conflict);
  final LinkConflict conflict;
}
```

## App Check activation (not a repository member — a `bootstrap()`-time call)

```dart
// After Firebase.initializeApp(), before any other Firebase SDK call:
await FirebaseAppCheck.instance.activate(
  androidProvider: env == AppEnvironment.prod
      ? AndroidProvider.playIntegrity
      : AndroidProvider.debug,
  appleProvider: env == AppEnvironment.prod
      ? AppleProvider.appAttest
      : AppleProvider.debug,
);
```

This alone does **not** enforce anything — see `research.md` #4. Enforcement is a Firebase
Console/CLI-level toggle per project, enabled only after the client-side call above is live in
both flavors, and never enabled on `prod` without explicit human confirmation in-session.

## Stability notes for consumers

- `linkWithGoogle`/`linkWithApple`/`resolveLinkConflict`/`deleteAccount`/`isLinked` are wholly new;
  no existing caller of `AuthRepository` is affected.
- `currentUserId` never changes as a result of a successful (non-conflict) link — any code that
  cached a uid across a link operation remains correct.
- A successful `resolveLinkConflict`/a signed-in-via-conflict session **does** change
  `currentUserId` (it becomes the existing account's uid) — any UI holding a stale reference to the
  pre-conflict uid must re-read it after the operation completes.
