# Phase 1 Data Model: Cuentas Vinculadas e Integridad de la Aplicación

No new Firestore collections. This feature widens two existing domain contracts
(`AuthRepository`, `CategoryRepository`, `UserProfile`/`UserProfileRepository`) and adds
presentation-layer concepts for the linking-conflict and category-management flows.

## 1. `UserProfile` (widened — `lib/features/user_profile/domain/entities/user_profile.dart`)

Adds `currencyCode`, the field `006` reserved in `isValidUserProfile()`'s key set but never
populated or validated.

| Field | Type | Notes |
|---|---|---|
| `uid` | `String` | Unchanged. |
| `timeZone` | `String` | Unchanged. |
| `currencyCode` | `String?` | **New.** ISO 4217 code. `null` until the user explicitly sets one *or* until this feature's first write populates it from `DeviceLocaleDefaults` — see `research.md` #5. Editable going forward; never rewrites a past expense's stored `currencyCode` (`docs/DATA_MODEL.md`, amended). |
| `wrappedLastSeenMonth` | `String?` | Unchanged. |

## 2. `LinkConflict` (new — `lib/features/auth/domain/entities/link_conflict.dart`)

Represents the acceptance-criterion-4 situation: the credential being linked already belongs to a
different, existing account.

| Field | Type | Notes |
|---|---|---|
| `pendingCredential` | opaque credential handle | The Google/Apple credential that triggered `credential-already-in-use`, held only in memory for the duration of the resolution flow — never persisted. |
| `existingProviderLabel` | `String` | Which provider (Google/Apple) the conflicting account is tied to, for display only. |

## 3. `LinkConflictResolution` (new — `lib/features/auth/domain/entities/link_conflict_resolution.dart`)

An enum, not a class — the two explicit choices FR-004/FR-005 require:

- `merge` — combine both histories into the existing account (`research.md` #2, step-by-step
  sequence).
- `discardLocal` — keep only the existing account's history; explicitly delete the current
  device's anonymous data first.

No third, implicit option exists — the resolution flow cannot proceed without one of these two
being chosen.

## 4. `AuthRepository` (widened — `lib/features/auth/domain/repositories/auth_repository.dart`)

New members, additive to the existing `currentUserId`/`ensureSignedIn`/`runWhenAuthenticated`
(`003`, unchanged):

| Member | Returns | Notes |
|---|---|---|
| `isLinked` | `bool` | Whether the current session has a Google/Apple provider attached (vs. still purely anonymous) — drives whether Settings shows "vincular" or account-management UI. |
| `linkWithGoogle()` | `Result<void>` on success, or a `LinkConflict` surfaced via a dedicated failure case | See `contracts/auth-linking-api.md`. |
| `linkWithApple()` | Same shape as `linkWithGoogle()` | Both providers are in this feature together (App Store Review Guideline 4.8 — Apple requires Sign in with Apple wherever Google Sign-In is offered), never split across two features. |
| `resolveLinkConflict(LinkConflict, LinkConflictResolution)` | `Result<void>` | Executes the merge-or-discard sequence from `research.md` #2. |
| `deleteAccount()` | `Result<void>` | Batch-deletes `expenses`/`categories`/the `users/{uid}` document, then deletes the Firebase Auth user record; handles `requires-recent-login` by re-prompting the linked provider (`research.md` #3). |

## 5. `CategoryRepository` (widened — `lib/features/categories/domain/repositories/category_repository.dart`)

New members, additive to the existing `getActive`/`watchActive`/`incrementUsage`/
`seedDefaultsIfNeeded` (`003`/`004`, unchanged):

| Member | Notes |
|---|---|
| `getAll()` | Active *and* archived — the management screen's list, distinct from the capture-path-only `getActive()`. |
| `create(name, color, iconName)` | Always creates a **user** category (`nameKey: null`, `name`: the literal text) — this screen never creates a default/translated category. |
| `update(categoryId, {name?, color?, iconName?})` | If the target is currently a default category (`isDefault: true`) and `name` is provided, this is the rename-becomes-user-category conversion: clears `nameKey`, sets `name`, flips `isDefault` to `false` — the existing `docs/DATA_MODEL.md` invariant, enforced here rather than newly invented. |
| `reorder(List<String> orderedIds)` | Rewrites `sortOrder` to match the given order. |
| `setActive(categoryId, isActive)` | Archive (`false`) / unarchive (`true`). Archiving never touches `expenses` documents that reference the category — they keep displaying it via the existing read-time-resolution join `005`/`006` already established. |

## 6. Security Rules delta

See `contracts/security-rules-delta.md` for the full rule text. Summary of what changes:

- `isValidUserProfile()`: adds real type/range validation for `currencyCode` (3-letter code,
  mirroring `isValidExpense()`'s existing `currencyCode.size() == 3` check) — the key was already
  in the allowed set since `006`, just unvalidated.
- `users/{userId}`: `allow delete` changes from `false` to `isOwner(userId)`.
- `users/{userId}/categories/{categoryId}`: `allow delete` changes from `false` to
  `isOwner(userId)`.
- `users/{userId}/expenses/{expenseId}`: unchanged — `allow delete: if isOwner(userId)` already
  covers the account-deletion batch-delete.
