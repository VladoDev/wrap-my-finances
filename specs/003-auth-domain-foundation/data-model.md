# Phase 1 Data Model: Auth & Domain Contracts Foundation

This feature introduces one real, implemented domain contract (`auth`, all three layers) and two
interface-only domain contracts (`expenses`, `categories` — entities + abstract repositories, no
`data/`/`presentation/`). It also replaces the entire Firestore Security Rules file with the
product ruleset from `docs/DATA_MODEL.md`, minus the `env_checks` block this feature removes.

## `auth` feature

### `AuthRepository` (domain interface)

| Member | Signature | Description |
|---|---|---|
| `currentUserId` | `String? get` | The resolved UID, or `null` if sign-in hasn't completed yet. Never blocks. |
| `ensureSignedIn` | `Future<String> ensureSignedIn()` | Resolves once a UID exists — immediately if already signed in, otherwise after sign-in completes. |
| `runWhenAuthenticated` | `Future<T> runWhenAuthenticated<T>(Future<T> Function(String uid) operation)` | Runs `operation` immediately if a UID already exists; otherwise queues it and runs it (in FIFO order relative to other queued operations) the moment sign-in resolves. This **is** the buffer spec FR-004/FR-005 require — see `research.md`. |

### `SignInAnonymouslyUseCase` (domain)

A single-method class (`Future<void> call()`) that calls `AuthRepository.ensureSignedIn()` and
discards the result — `bootstrap()`'s only touchpoint with this feature, called fire-and-forget,
never awaited (Constitution Principle 1/2: never blocks first frame).

### `FirebaseAuthRepository` (data, implements `AuthRepository`)

Wraps `FirebaseAuth` (injected via the existing `FirebaseModule`, per `001`). Internal state: a
`List<_QueuedOperation>` (each holding the caller's `operation` and a `Completer` for its result)
and a subscription to `FirebaseAuth.authStateChanges()` that, on the first non-null `User`, drains
the queue in order and cancels itself (no further work needed once a session is warm).

**State transitions**: unauthenticated → (sign-in call in flight) → authenticated. Never reverses
within a single app session — anonymous sessions aren't signed out by any code in this feature.

### `presentation/`

Intentionally contains no files. `auth` has no screens in this feature — Phase 3's account-linking
UI is the first consumer, per `docs/ROADMAP.md`.

## `expenses` feature (domain only)

### `Money` (domain value object)

| Field | Type | Description |
|---|---|---|
| `minorUnits` | `int` | Integer minor-unit amount (e.g. cents). Never a `double` — Constitution Principle 5. |
| `currencyCode` | `String` | ISO 4217 code, e.g. `"MXN"`. |

No arithmetic operator overloads beyond what's needed to construct/compare — this feature adds no
use case that performs money arithmetic; `004` extends this if/when one needs it.

### `Expense` (domain entity)

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Client-generated, per Constitution Principle 2. |
| `amount` | `Money` | The spent amount. |
| `categoryId` | `String` | Plain string reference, matching `docs/DATA_MODEL.md`'s "not a `DocumentReference`" decision. |
| `date` | `DateTime` | The expense date — the only field domain logic sorts/groups by. |
| `note` | `String?` | Optional, ≤280 chars (matches the Security Rules cap). |
| `createdAt` | `DateTime` | Client clock at creation, immutable. |

Excludes `monthKey`, `syncedAt`, `deletedAt`, `schemaVersion` — see `research.md`.

### `ExpenseRepository` (domain interface)

| Member | Signature | Description |
|---|---|---|
| `create` | `Future<Result<Expense>> create(Expense expense)` | Persists a new expense. |
| `delete` | `Future<Result<void>> delete(String expenseId)` | Soft-deletes (data-layer concern how). |
| `watchByMonth` | `Stream<List<Expense>> watchByMonth(String monthKey)` | Live query for a given month; `monthKey` is passed in as a plain string since the entity itself doesn't carry it. |

No implementation exists yet (FR-007). Signatures may be refined by `004` as its use cases demand;
this is the initial contract, not a frozen one.

## `categories` feature (domain only)

### `Category` (domain entity)

| Field | Type | Description |
|---|---|---|
| `id` | `String` | |
| `nameKey` | `String?` | Non-null only for default categories — see invariant below. |
| `name` | `String?` | Non-null only for user-created categories. |
| `color` | `String` | `#RRGGBB`. |
| `iconName` | `String` | Key into the app's bundled icon set. |
| `isDefault` | `bool` | |
| `sortOrder` | `int` | |
| `isActive` | `bool` | |
| `usageCount` | `int` | |
| `lastUsedAt` | `DateTime?` | |

**Invariant**: exactly one of `nameKey`/`name` is non-null — enforced by the entity's constructor
(throws `ArgumentError` if violated), mirroring the Security Rules invariant below so the same rule
is impossible to violate from either side of the network boundary.

### `CategoryRepository` (domain interface)

| Member | Signature | Description |
|---|---|---|
| `getActive` | `Future<Result<List<Category>>> getActive()` | One-shot fetch, ordered by `usageCount` descending (matches the Firestore index from `docs/DATA_MODEL.md`). |
| `watchActive` | `Stream<List<Category>> watchActive()` | Live query, same ordering. |
| `incrementUsage` | `Future<Result<void>> incrementUsage(String categoryId)` | Called after a category is used to log an expense. |

No implementation exists yet (FR-008).

## Security Rules changes

`firestore.rules` is replaced in full by `docs/DATA_MODEL.md`'s ruleset:

| Removed | Added/changed |
|---|---|
| `isValidEnvironmentProbe()` function | — |
| `match /env_checks/{docId}` block | — |
| `isValidCategory()` (001-era: `name`/`color`/`iconName` only) | `isValidCategory()` (adds `nameKey`, the XOR invariant, `keys().hasOnly(...)`, size caps) |
| — | `isValidExpense()`, `isOwner()`, `incoming()` — unchanged from `docs/DATA_MODEL.md`, not present in the `001` file at all |
| — | `match /users/{userId}` and its nested `categories`/`expenses` blocks |
| Trailing catch-all | Unchanged — still the final rule, now denying `env_checks` too since its block is gone |

`firestore.indexes.json` is unchanged — `001` never touched it, and `docs/DATA_MODEL.md`'s index
definitions were already the target this feature adopts (no new indexes needed since no query use
case ships in this feature).

## Security Rules test coverage (`firebase/tests/*.rules.test.js`)

| File | Scenarios (maps to FR-014) |
|---|---|
| `users.rules.test.js` | Owner can read/create/update own user doc; cannot read another user's; cannot change own `uid` on update; delete always denied; catch-all denies an undeclared top-level collection. |
| `categories.rules.test.js` | Owner can create/update a valid category; cross-user read denied; `nameKey`+`name` both present rejected; both absent rejected; delete always denied. |
| `expenses.rules.test.js` | Owner can create/read/update/delete own expense; cross-user read denied; negative/zero/oversized/decimal `amountMinor` rejected; malformed `monthKey` rejected; `createdAt` change on update rejected; unauthenticated access denied on every operation. |

## CI workflow addition

`.github/workflows/ci.yml` gains a `rules-tests` job (parallel to `analyze-and-test`):

```yaml
rules-tests:
  runs-on: ubuntu-latest
  steps:
    - checkout
    - actions/setup-node (for firebase-tools + mocha)
    - actions/setup-java (Firestore/Auth emulator requirement)
    - npm install -g firebase-tools
    - npm ci --prefix firebase/tests
    - firebase emulators:exec --only auth,firestore "npm test" (run from firebase/tests/)
```
