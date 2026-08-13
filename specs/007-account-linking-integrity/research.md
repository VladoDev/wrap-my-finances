# Phase 0 Research: Cuentas Vinculadas e Integridad de la Aplicación

## 1. Happy-path linking is uid-preserving — no data migration needed

**Finding**: `FirebaseAuth.currentUser!.linkWithCredential(credential)` on an anonymous user, when
the credential is *not* already tied to another Firebase Auth record, upgrades the existing
anonymous user in place — **same `uid`**, now with an additional (Google or Apple) sign-in
provider attached. Every Firestore document this app writes is keyed by `users/{uid}/...`, so
nothing about the data changes: no read, no write, no migration.

**Decision**: FR-002 ("vincular conserva todo sin duplicar") is satisfied *by construction* on the
happy path — there is no merge logic to write for it. The only path that needs real data-migration
logic is the conflict path (acceptance criterion 4 / US3, `research.md` #2 below). Implementation
work for "just link" is a thin call to `linkWithCredential` plus error-branching on the one
exception code that matters (`credential-already-in-use`).

**Alternatives considered**: None — this is simply how Firebase Auth's anonymous-upgrade flow
works; there is no alternative API shape to weigh.

## 2. The conflict path requires reading the anonymous account's data *before* switching identity

**Finding**: When `linkWithCredential` throws `credential-already-in-use`, the credential is
already tied to a *different* existing `uid` (call it B) — the current anonymous session's `uid`
(call it A) is untouched by the failed link attempt. Firestore Security Rules gate every read/write
under `users/{userId}` on `request.auth.uid == userId`. This has a hard sequencing consequence: the
client can read A's data only while still authenticated as A, and can write into B's collections
only once authenticated as B — and there is no moment where both are true at once. Once the app
calls `signInWithCredential(exception.credential)` to become B, A's documents become **permanently
unreachable** to that device — not deleted, just inert, since no future session can ever satisfy
`isOwner(A)` again from this client.

**Decision**: The "combine both histories" resolution (spec.md US3, scenario 2) must, in one
uninterrupted client session:

1. While still authenticated as A: fetch A's full expense list (`ExpenseRepository.watchAll()`)
   and full category list (needs a new "all categories, including archived" read — `getActive()`
   alone would silently drop archived custom categories from the merge).
2. Hold that data in memory.
3. Call `signInWithCredential` to become B.
4. While authenticated as B: batch-write A's expenses and categories into B's collections, with
   **fresh client-generated ids** (never A's original ids — B's `expenses`/`categories`
   collections may already contain documents, and reusing A's ids risks an accidental overwrite).

The "keep only B's account, discard A's device history" resolution (US3, scenario 3) does the
inverse of step 4: while still authenticated as A (step 1's window), batch-*delete* A's documents
instead of merely abandoning them — an explicit, confirmed discard actually removes the data
(matching FR-005's "nombrando lo que se descarta") rather than leaving orphaned, unreachable
documents sitting in Firestore forever.

**Risk, documented rather than silently accepted**: if the network drops between reading A's data
(step 1) and finishing the write into B (step 4), the app has already lost the ability to re-read
A directly from the server — but Firestore's offline cache means A's data was almost certainly
already fully synced locally from ordinary use before this flow ever started (this app is
offline-first by construction), so the *read* in step 1 is safe from cache even offline. The
*write* in step 4 is the one Firestore already makes durable across a dropped connection (it
queues locally and flushes on reconnect, the same guarantee every other write in this app already
relies on). The one genuine edge case — losing connectivity *mid-merge*, after switching to B but
before the write finishes — is covered by acceptance criterion 5's offline handling: the merge
operation is itself network-dependent and must be retried, not silently abandoned.

**Alternatives considered**: A server-side (Cloud Function) merge, triggered by a document written
under both accounts. Rejected — no Cloud Functions infrastructure exists in this project (grep of
`docs/TECH_STACK.md`/`docs/DATA_MODEL.md` finds exactly one forward-looking mention, about the
30-day purge possibly moving there *someday*), and the client already has everything it needs to
do this correctly in one session without introducing a new deployment surface, language runtime,
and CI pipeline for a single, infrequent, already-solvable-client-side operation.

## 3. Account deletion is client-side; Security Rules must be widened to allow it

**Finding**: `firestore.rules` currently sets `allow delete: if false` on both `users/{userId}`
and `users/{userId}/categories/{categoryId}` — deliberately, per `docs/DATA_MODEL.md`'s existing
note ("deletion is soft, via `isActive`/`deletedAt`; account deletion is a separate, audited flow
(Phase 4) handled outside these rules"). This feature *is* that flow, arriving one phase earlier
than that note anticipated (see spec.md Assumptions).

**Decision**: Client-side, matching this project's established all-Firestore-client pattern (no
Cloud Functions infrastructure exists — same reasoning as `research.md` #2's rejected
alternative). Account deletion:

1. While still authenticated: batch-delete every document in `expenses` and `categories`
   subcollections (both already allow `delete` for the owner — `expenses` since `004`/`005`,
   `categories` needs its `allow delete: if false` changed to `allow delete: if isOwner(userId)`,
   the same ownership check every other rule in this file already uses).
2. Delete the `users/{userId}` document itself — same rule change, same ownership check.
3. Call `FirebaseAuth.currentUser!.delete()` to remove the Auth record itself, so the identity
   cannot be used to sign in again.

**A real subtlety to design around**: `FirebaseAuth.currentUser!.delete()` can fail with
`requires-recent-login` if the session is old. Since this app's only sign-in methods are anonymous
(silent, at every launch) and the Google/Apple link (a one-time action), a session can be
arbitrarily old by the time someone asks to delete their account. The deletion flow must catch
this specific error and re-prompt for the linked provider's sign-in (silently where the platform
allows it, interactively otherwise) immediately before retrying deletion — not surface it as a
generic failure.

**Alternatives considered**: A Cloud Function triggered on `users/{userId}` deletion to cascade
into subcollections (Firestore does not cascade-delete subcollections automatically). Rejected for
the same infrastructure reason as #2 — and unnecessary here regardless, since the client already
holds a live, authenticated session at the exact moment it decides to delete, which is precisely
the condition a Cloud Function's admin-SDK bypass exists to work around when the client *doesn't*
have that.

## 4. App Check enforcement is a Firebase Console/CLI-level toggle, not a Security Rules change

**Finding**: Firebase App Check's client-side half (`FirebaseAppCheck.instance.activate(...)`,
attaching a Play Integrity/App Attest/debug token to every outgoing Firebase SDK call) is
necessary but **not sufficient**. Whether Firestore actually *rejects* requests without a valid
App Check token is a separate, per-product "Enforcement" setting in the Firebase Console (or
`firebase appcheck:...` CLI / Firebase Management API) — it is not expressible anywhere in
`firestore.rules`. A plan that only adds the client SDK call and never flips enforcement on ships
a feature that silently does nothing.

**Decision**: Two-part rollout, in order, per environment:

1. Ship the client-side `activate()` call (Android: Play Integrity in `prod`, debug provider in
   `dev`; iOS: App Attest in `prod`, debug provider in `dev` — matching `docs/ENVIRONMENTS.md`'s
   existing environment matrix, which already lists this exact split under "App Check").
2. **Only after** step 1 is live in both flavors, enable Firestore App Check enforcement in the
   Firebase Console for each project. Flipping enforcement on `wrap-my-finances-prod` before every
   shipped `prod` client has the SDK call live would lock out real users — this ordering
   requirement is documented here so it is not lost between planning and execution, and enabling
   enforcement on **prod** specifically is treated with the same "requires explicit human
   confirmation in-session" care the constitution's Agent Operating Rules already require for
   other prod-affecting actions, even though it is not literally on that section's list.

**Debug provider registration**: the debug token App Check issues for `dev`-flavor builds must be
registered in the Firebase Console **for `wrap-my-finances-dev` only** — registering it against
`prod` would defeat the entire point of the protection. This is a one-time manual provisioning
step per development machine/CI runner, documented in `quickstart.md`.

**Alternatives considered**: None — this is how App Check's enforcement model works; there is no
way to make enforcement itself a `firestore.rules` predicate.

## 5. The capture path's currency must stay a synchronous, already-cached value

**Finding**: `004`'s `ExpenseModel.fromEntity` currently computes `currencyCode` fresh on every
write via `DeviceLocaleDefaults.currencyCodeFor(...)` — a synchronous, no-Firestore-read call, by
design, so the capture path never awaits anything (Constitution Principle 1). This feature's
currency-preference setting (FR-015/FR-017) needs to *replace* that device-locale guess with the
user's real stored preference for expenses logged **after** the change — but the stored preference
lives on the `users/{uid}` document (`006`'s `UserProfile`), and reading it from Firestore at the
moment of writing an expense would reintroduce exactly the async dependency Principle 1 forbids.

**Decision**: The user's current `currencyCode` preference must be exposed to the capture path as
a synchronous value backed by an already-live stream — the same shape `006`'s
`UserProfileRepository.watchProfile()` already established, just read once at app start and kept
warm in a Riverpod provider the capture controller can read via `ref.read`, never `await`.
Falls back to `DeviceLocaleDefaults.currencyCodeFor(...)` for the brief window before the profile
has loaded even once (the same interim-default reasoning `004`'s and `006`'s research.md already
used) or if no preference has ever been explicitly set. This is additive to `006`'s
`UserProfile`/`UserProfileRepository` — this feature widens both to also carry `currencyCode`,
right alongside `timeZone`, since `isValidUserProfile()`'s Security Rule already reserved the key
(added in `006`, deliberately left unvalidated until "a future feature... writes it for real" —
this is that feature) and now needs real type/range validation added
(`contracts/security-rules-delta.md`).

**Alternatives considered**: Read the preference fresh on every expense write. Rejected outright —
directly violates Constitution Principle 1, the one rule this project treats as non-negotiable.

## 6. Timezone-change / `monthKey` non-recalculation is already documented at its canonical location

**Finding**: `docs/DATA_MODEL.md` already states, in the `timeZone` field's own description: "Changing
it only affects how *future* expenses are bucketed — never re-evaluates or reassigns the `monthKey`
already stored on existing documents." This was written during `006`'s planning (which introduced
the stored `timeZone` field) and needs no further documentation — `docs/DATA_MODEL.md` is exactly
"donde alguien la vaya a buscar" (where someone would look for it): the field's own definition,
not a separate note buried in a feature-specific doc that will eventually be harder to find.

**Decision**: No new documentation needed for FR-016. `007`'s job is simply to build the Settings
UI that lets the user *change* `timeZone` — the non-recalculation guarantee this requirement asks
for already exists as a property of how `monthKey` is computed (once, at write time, per `006`'s
own "Wrapped aggregation" design) rather than something this feature has to newly implement or
enforce.

## 7. Category management needs new repository members — none of create/update/reorder exist yet

**Finding**: `CategoryRepository` (declared in `003`, implemented in `004`) currently exposes only
`getActive()`, `watchActive()`, `incrementUsage()`, and `seedDefaultsIfNeeded()` — read-mostly,
built for the capture path's needs. Nothing lets a caller create a new category, edit an existing
one's name/color/icon, change `sortOrder`, or flip `isActive`.

**Decision**: Add to `CategoryRepository`: `create(...)`, `update(...)` (handling the
default-category-renamed-becomes-user-category conversion described in `docs/DATA_MODEL.md`'s
existing invariant — clearing `nameKey`, setting `name`, flipping `isDefault` to `false`, all in
one write, exactly as that invariant already specifies), `reorder(List<String> orderedIds)`, and
`archive(String categoryId)`/`unarchive(String categoryId)` (toggling `isActive`). Also needs a
`getAll()` (active *and* archived) for the management screen's own list — `getActive()`/
`watchActive()` are the capture-path-specific view and deliberately exclude archived categories,
which the management screen must still show.

**Alternatives considered**: None — these are additive members on an existing contract, not a
design choice with real alternatives.

## 8. `google_sign_in` 7.x redesigned its API — confirm the exact shape at implementation time

**Finding**: `flutter pub add --dry-run google_sign_in` resolves `google_sign_in: ^7.2.0`. Recent
major versions of this package restructured around a `GoogleSignIn.instance` singleton with an
`authenticate()`/event-stream shape, replacing the older per-instance `signIn()` call older
tutorials and even some of this project's own prior mental model might assume.

**Decision**: Per the constitution's Agent Operating Rules ("when a CLI flag or command in the
documentation does not match reality, the agent stops and reports rather than improvising a
workaround"), the exact call shape for obtaining a `GoogleAuthCredential` to pass into
`linkWithCredential` must be verified directly against the installed `google_sign_in` version's
API during implementation, not assumed from memory. `sign_in_with_apple: ^8.1.0` similarly needs
its exact `AuthorizationCredentialAppleID` → `OAuthCredential` construction verified at
implementation time.

**Alternatives considered**: None — this is a version-verification task, not a design decision.

## 9. App Check activation is fire-and-forget at `bootstrap()` start, same as sign-in

**Finding**: `FirebaseAppCheck.instance.activate(...)` is async, and Play Integrity/App
Attest attestation (unlike the instant debug provider) can involve a real network round trip. If
`bootstrap()` **awaited** it before `runApp()`, that would directly violate Constitution
Principle 1 (capture screen must paint immediately, no network wait on the path to first frame).
If it's fire-and-forget, there is a narrow window — between `runApp()` and `activate()` actually
resolving — where an outgoing Firestore call would go out without an App Check token attached,
which (once enforcement is on) would be rejected.

**Decision**: Fire-and-forget, dispatched immediately after `Firebase.initializeApp()` — the exact
same `unawaited(...)` pattern `bootstrap()` already uses for `SignInAnonymouslyUseCase` and
`SeedDefaultCategoriesUseCase`. In practice this window closes well before it matters: the first
real Firestore *write* only happens once a user actually taps a category, several rendered frames
after `bootstrap()`'s synchronous phase completes — by which point `activate()` (started at the
very top of `bootstrap()`) has almost always already resolved, doubly so for the instant debug
provider `dev` builds use. Firestore's own offline-queue-and-retry behavior (already this app's
foundation for every write, per Constitution Principle 2) further cushions a write that happens to
race ahead of token attachment. A read racing that exact window is the one theoretically-possible
narrow edge case this decision accepts rather than eliminates — documented here rather than
silently assumed away, the same honesty standard `006`'s research.md already applied to its own
best-effort races.

**Scope note**: App Check enforcement is enabled for **Firestore only**, not Firebase
Authentication — `signInAnonymously()`'s own success is not gated on App Check, so the very first
network call `bootstrap()` makes is never at risk of this race at all. This matches Constitution
Principle 7's own framing ("Rules are the only thing standing between one user's spending history
and another's") — the data store is the asset being protected, not the auth handshake that
precedes reaching it.

**Alternatives considered**: Await `activate()` before `runApp()`. Rejected — directly trades away
Principle 1 for a protection against a window that closes in practice before it can matter.

## 10. Settings ARB keys follow the already-documented `settings_*` convention

**Finding**: `docs/TECH_STACK.md` § Localization already reserves the `settings_*` key prefix
("`settings_*`... for strings shared across features" — actually scoped to this exact screen),
alongside `wrapped_*`, `keypad_*`, and `common_*`. No `settings_*` key exists yet in any ARB file.

**Decision**: Every new string this feature introduces uses the `settings_*` prefix, following the
same `snake_case`-key/`@`-metadata-description convention every prior feature's ARB additions
already established. Unlike `wrapped_*`, `docs/TECH_STACK.md` does not flag `settings_*` for
mandatory native-speaker review — ordinary translation quality applies.
