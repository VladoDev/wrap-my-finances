# Phase 0 Research: Auth & Domain Contracts Foundation

No `NEEDS CLARIFICATION` markers remained in the Technical Context — `docs/ARCHITECTURE.md`,
`docs/DATA_MODEL.md` (including its Security Rules section), and Constitution Principles 2/3/4/7
already fix the framework, layering, and rules content. What they leave open is *structural*: how
the "buffer lives in a use case, never a widget" requirement is actually shaped as a reusable
mechanism when no concrete write use case exists yet in this feature, where Firestore's persistence
configuration belongs now that `auth` is a real feature, what happens to the `001` diagnostics
screen once its rules block is replaced, and how the rules test suite gets a Java-dependent emulator
into the same CI workflow `002` already built. This document records those decisions.

## Decision: The pre-auth write buffer is a generic `AuthRepository` primitive, not a feature-specific queue

**Decision**: `AuthRepository` (domain, `features/auth/domain/repositories/auth_repository.dart`)
exposes `Future<T> runWhenAuthenticated<T>(Future<T> Function(String uid) operation)` in addition to
`String? get currentUserId` and `Future<String> ensureSignedIn()`. The `data` implementation
(`FirebaseAuthRepository`) holds an in-memory FIFO queue of pending `operation`s; if
`FirebaseAuth.instance.currentUser` is already non-null, `operation` runs immediately; otherwise it
is queued and a subscription to `authStateChanges()` flushes the entire queue, in order, the moment
a non-null user appears.

**Rationale**: `docs/ARCHITECTURE.md` states the buffer "belongs in `LogExpense`, not the widget" —
but `LogExpense` doesn't exist yet; this feature's explicit scope is repository *interfaces* for
`expenses`/`categories`, not their use cases (spec FR-007/FR-008/FR-016). Building the buffer as a
generic primitive on `AuthRepository` resolves this without inventing a use case this feature isn't
supposed to own: a future `LogExpense` (built in `004`) calls
`authRepository.runWhenAuthenticated((uid) => expenseRepository.create(...))` and gets buffering for
free, with zero buffering logic of its own — satisfying "the buffer lives in a use case, never a
widget" by construction, since only use cases (never widgets) hold an `AuthRepository` reference at
all. This feature demonstrates and tests the mechanism directly (queue an operation before sign-in
resolves, using `firebase_auth_mocks` to control timing, and assert it flushes after), without
needing a real expense write to exist.

**Alternatives considered**:
- *A standalone `PendingWriteBuffer` under `core/`, unrelated to auth* — rejected: the buffer's
  entire reason to exist is "wait for a UID," which is exactly what `AuthRepository` already
  models; a separate class would just re-implement the same wait with an extra indirection.
- *Defer the buffer to `004`, since no use case needs it yet* — rejected: spec FR-004/FR-005 are
  explicit acceptance criteria of *this* feature, and `docs/ARCHITECTURE.md` treats the buffer as
  part of the auth/session contract, not an expense-specific concern — `004` should find it ready,
  not build it under time pressure alongside the keypad.

## Decision: `SignInAnonymouslyUseCase` replaces the raw `FirebaseAuth` call in `bootstrap()`

**Decision**: `bootstrap()` calls `getIt<SignInAnonymouslyUseCase>().call()` (still fire-and-forget,
still never awaited) instead of `FirebaseAuth.instance.signInAnonymously()` directly. The use case
(domain) calls `AuthRepository.ensureSignedIn()`; the repository implementation checks
`FirebaseAuth.instance.currentUser` first and only calls `signInAnonymously()` if it's null, so a
warm session (app relaunch) doesn't re-trigger sign-in.

**Rationale**: Spec FR-002 requires the session lifecycle to live inside the `auth` feature's three
layers, not as an inline SDK call in `bootstrap.dart` — the exact gap `001` left as acknowledged
scaffolding (see `001-environment-foundation`'s own notes on `env_checks` being temporary). This is
a pure refactor: the *behavior* (silent, non-blocking, fire-and-forget anonymous sign-in) is
unchanged from `001`; only where the call lives changes.

**Alternatives considered**:
- *Await `ensureSignedIn()` inside `bootstrap()`* — rejected: would reintroduce a startup delay
  Constitution Principle 1 (indirectly, via the 3-second budget once the keypad exists) and
  `docs/ARCHITECTURE.md` both rule out — sign-in must resolve in parallel with first frame.

## Decision: Firestore persistence configuration stays in `bootstrap()`, not inside `auth`

**Decision**: `FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true,
cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED)` remains exactly where `001` put it, in
`bootstrap()`, untouched by this feature.

**Rationale**: Spec FR-003 requires this configuration to exist; it does not require it to live
inside `auth`. Firestore's cache behavior is an app-wide, `core`-level concern that has nothing to
do with *identity* — every feature's repository reads through the same configured instance,
regardless of which user is signed in. Moving it into `auth` would conflate "who is signed in" with
"how the local cache behaves," two orthogonal concerns `docs/ARCHITECTURE.md`'s feature boundaries
don't ask to be merged.

**Alternatives considered**:
- *Move it into `FirebaseModule` (`core/di/firebase_module.dart`)* — a reasonable alternative not
  taken only because `001` already placed it correctly at the one point that's guaranteed to run
  once, before any repository reads Firestore; moving it captures no benefit this feature needs and
  would be a diff with no behavioral change, purely for its own sake.

## Decision: `expenses`/`categories` domain entities exclude persistence-only fields

**Decision**: The `Expense` entity carries `id`, `amount` (a `Money`), `categoryId`, `date`, `note`,
and `createdAt`. The `Category` entity carries `id`, a resolved-name pair (`nameKey`/`name`, exactly
one non-null — mirroring the Firestore invariant), `color`, `iconName`, `isDefault`, `sortOrder`,
`isActive`, `usageCount`, and `lastUsedAt`. Neither entity carries `monthKey`, `syncedAt`,
`deletedAt`, or `schemaVersion`.

**Rationale**: `docs/DATA_MODEL.md`'s documents describe the *persisted* shape; `monthKey` is a
denormalized index only Firestore queries need, `syncedAt` is a `FieldValue.serverTimestamp()`
artifact domain code must never read (Constitution Principle 2), and `schemaVersion` is a
data-layer migration concern. `docs/ARCHITECTURE.md`'s own dependency rule keeps `data/` models
(which *do* carry these fields, for `fromJson`/`toJson`) separate from `domain/` entities — this
feature's entities are the domain half of that split; `004`'s data models are the other half.
`deletedAt` is soft-delete state a future `DeleteExpense`/timeline use case will need, but no such
use case exists in this feature to consume it, so it's left for `004` to add when it's needed,
rather than speculatively added now.

**Alternatives considered**:
- *Mirror the Firestore document shape exactly in the domain entity* — rejected: this is precisely
  the layering violation `docs/ARCHITECTURE.md` warns against (domain leaking persistence
  concerns), and it would make the entity's public API a lie about what domain logic actually needs.

## Decision: `firestore.rules` adopts `docs/DATA_MODEL.md`'s ruleset verbatim, `env_checks` deleted entirely

**Decision**: The `isValidCategory()` function currently in `firestore.rules` (a `001`-era stub that
only validates `name`/`color`/`iconName`, with no `nameKey` support at all) is replaced by the
version in `docs/DATA_MODEL.md`, which adds the `nameKey`/`name` XOR invariant, `keys().hasOnly(...)`
constraints, and the size caps. The `env_checks` match block and `isValidEnvironmentProbe()`
function are deleted outright, along with `lib/core/diagnostics/` (entity, repository, page) and
its tests, and `firebase/tests/env_checks.rules.test.js`.

**Rationale**: Spec FR-009/FR-010/FR-017 are explicit. The existing `isValidCategory()` predates
`docs/DATA_MODEL.md`'s final invariant design (it was written in `001` before categories had a
nameKey/name distinction at all) — this is the first feature to actually need the real shape, so
this is when it gets adopted, not a speculative change. `env_checks` was always documented as
temporary scaffolding (see `001-environment-foundation/research.md`: "expected to be removed once a
real feature supersedes the diagnostics screen") — this is that feature.

**Alternatives considered**:
- *Keep `env_checks` alongside the new rules, remove it later* — rejected: its only purpose was
  proving environment isolation, which the new rules test suite's cross-user isolation tests (spec
  FR-014) demonstrate more rigorously anyway; keeping a second, redundant mechanism serves nothing.

## Decision: The app's root route becomes a minimal, localized placeholder — not a deleted route

**Decision**: `lib/core/diagnostics/presentation/pages/environment_status_page.dart` is deleted.
`app.dart`'s root route now renders `PlaceholderHomePage` (`lib/core/presentation/pages/`), showing
only the `dev`-flavor ribbon banner from `docs/UI_UX_SPEC.md` §6 — no environment name text, no
probe-write control (both were `env_checks`-specific). The banner's one string
(`"DEV BUILD"`) moves to a new `common_devBuild` ARB key across all five locales, rather than
staying a Dart string literal.

**Rationale**: The app needs *something* at its single route today (`go_router` needs a widget),
and this feature explicitly ships no product screen — so the replacement must be strictly smaller
than a product screen, matching `001`'s own precedent of a temporary, disposable placeholder.
Localizing its one string, even though the page itself is throwaway, costs one ARB key and keeps
Constitution Principle 9 ("No user-visible string may be embedded in Dart code") honestly satisfied
for every line of code this feature adds — "it's just a placeholder" is not one of the principle's
stated exceptions, and `002` already built the infrastructure that makes this nearly free.

**Alternatives considered**:
- *An empty `Scaffold()` with no content at all* — rejected: silently drops the dev/prod visual
  distinction Constitution Principle 6 requires ("Dev and prod builds must be distinguishable at a
  glance"), which `001` correctly built and this feature has no reason to regress.
- *Keep `EnvironmentStatusPage`'s exact unlocalized strings* — rejected: perpetuates a Principle 9
  gap that predates the l10n infrastructure `002` built specifically to close it.

## Decision: The Security Rules emulator suite runs as a second job in the existing CI workflow

**Decision**: `.github/workflows/ci.yml` (from `002`) gets a second job, `rules-tests`, alongside
`analyze-and-test`. It sets up Node.js and a JDK (the Firestore/Auth emulator requires Java),
installs `firebase-tools` via `npm install -g`, installs `firebase/tests`' npm dependencies, and
runs `firebase emulators:exec --only auth,firestore "npm test"` from `firebase/tests/`.

**Rationale**: Spec FR-015 requires the suite to run "in the same CI workflow," not necessarily the
same job — a second job in the same workflow file satisfies this while keeping the Node/Java
toolchain isolated from the Flutter toolchain `analyze-and-test` already uses, so the two run in
parallel rather than serializing unrelated setup steps. `001` already produced a working local
version of this exact command (`firebase emulators:exec --only firestore "npm test"`, per its
`tasks.md`); this feature only needs to make it run in CI instead of by hand, and extend
`firebase/tests/` with rules coverage for the new collections.

**Alternatives considered**:
- *A separate workflow file* — rejected: `docs/TECH_STACK.md`'s CI/CD section describes one
  pipeline running analyze/test/build; splitting rules testing into a disconnected workflow is
  exactly the failure mode spec FR-015/US7 exist to prevent (a check nobody notices because it's
  not part of "the" CI run people look at).

## Decision: Rules tests are reorganized by collection, not left as one `env_checks`-shaped file

**Decision**: `firebase/tests/env_checks.rules.test.js` is deleted. In its place:
`firebase/tests/users.rules.test.js`, `firebase/tests/categories.rules.test.js`, and
`firebase/tests/expenses.rules.test.js` — one file per top-level concern, each covering ownership,
validation, and cross-user isolation for that collection, plus the catch-all case (verified once,
in whichever file is simplest to host it — `users.rules.test.js`).

**Rationale**: `firebase/tests/package.json`'s test script already globs `**/*.rules.test.js`, so no
tooling change is needed to pick up the new files — only deleting the old one and adding the new
ones. Splitting by collection mirrors `firestore.rules`' own structure and keeps each file's
`describe` block focused, matching the granularity spec FR-014 lists its required scenarios at.
