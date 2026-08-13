# Data Model

The same schema, rules, and indexes are deployed to **both** Firebase projects
(`wrap-my-finances-dev` and `wrap-my-finances-prod`). See [ENVIRONMENTS.md](ENVIRONMENTS.md).

## Firestore Hierarchy

```
users/{userId}
  ├── categories/{categoryId}
  └── expenses/{expenseId}
```

Nesting under `users/{userId}` keeps every read scoped to one user, makes Security Rules trivial
to reason about, and means a full month of expenses is a single-collection query.

---

## Design decisions

### Money is stored as integer minor units

`amountMinor` is an **integer number of cents**, never a floating-point value. `0.1 + 0.2 != 0.3`
in IEEE-754, and a rounding drift in a spending total is both wrong and visibly wrong to the user.
`$150.00 MXN` is stored as `15000`. Formatting to a display string happens once, at the
presentation layer, via `intl`.

The domain layer wraps this in a `Money` value object so no arithmetic on raw ints leaks into use
cases.

### Timestamps: `createdAt` vs `syncedAt`

Firestore's `FieldValue.serverTimestamp()` reads back as `null` from the local cache until the
write reaches the server. In an offline-first app that means **any query ordered by a server
timestamp will misbehave on exactly the path that matters most**.

Therefore:

- `date` — the expense date, client-generated, **the only field used for sorting, grouping, and
  aggregation**.
- `createdAt` — client clock at creation, immutable, used for tie-breaking and audit.
- `syncedAt` — `FieldValue.serverTimestamp()`, may be `null` locally, used only for diagnostics
  and conflict inspection. Never sorted on.

### `monthKey` is denormalized

Every expense carries `monthKey: "2026-08"`, computed in the **user's stored time zone**, not the
device's current one and not UTC. A purchase at 23:50 on August 31 in Mexico City belongs to
August's Wrapped even if the device is roaming in another zone and even if UTC has already rolled
over.

This turns the Wrapped aggregation into one equality query instead of a range query with
timezone arithmetic, and it makes the result stable no matter where the phone is.

### Soft delete

`deletedAt` supports the undo affordance on swipe-to-delete without a round trip. Documents older
than 30 days with a non-null `deletedAt` are purged by a maintenance routine; until then they are
filtered out of every query.

### Client-generated IDs

Document IDs come from `collection.doc()` with no argument, generated locally. An expense logged
on a plane has a stable identity immediately, and retries are idempotent.

---

## Collections and Documents

### 1. User Document

Path: `users/{userId}`

```json
{
  "uid": "user_abc123",
  "createdAt": "2026-08-07T20:00:00Z",
  "lastLogin": "2026-08-07T20:00:00Z",
  "isAnonymous": true,
  "currencyCode": "MXN",
  "locale": "es-MX",
  "timeZone": "America/Mexico_City",
  "defaultCategoryId": "cat_food",
  "wrappedLastSeenMonth": "2026-07",
  "hapticsEnabled": true,
  "schemaVersion": 1
}
```

- `timeZone` is an IANA identifier, captured on first launch and editable in Settings. It defines
  month boundaries for `monthKey`. Changing it only affects how *future* expenses are bucketed —
  never re-evaluates or reassigns the `monthKey` already stored on existing documents.
- `currencyCode` is captured on first launch and **editable in Settings**, the same "changes the
  default for new expenses, never touches history" shape as `timeZone`.
  > **Amendment (documentation, not constitutional — `007-account-linking-integrity`):** earlier
  > text here said "chosen once." That was never true of `timeZone` and doesn't need to be true
  > of `currencyCode` either — multi-currency *conversion* is the actual anti-goal (Constitution
  > Principle 3), not the ability to change a going-forward preference. Changing this field never
  > converts, reconciles, or re-displays a past expense's already-stored `amountMinor`/
  > `currencyCode` in a different currency. A user who changes it simply has a spending history
  > that mixes currency codes across months, exactly as they entered it — the app does not
  > pretend otherwise.
- `wrappedLastSeenMonth` drives the "show Wrapped on first open of a new month" trigger, so the
  overlay appears exactly once per month, on any device.
- `schemaVersion` exists so a future migration has something to branch on. It is cheap now and
  impossible to add retroactively.

### 2. Category Document

Path: `users/{userId}/categories/{categoryId}`

A default category (seeded on first launch) carries a translation key and no literal name:

```json
{
  "id": "cat_food",
  "nameKey": "category_food",
  "name": null,
  "color": "#FF5722",
  "iconName": "restaurant",
  "isDefault": true,
  "sortOrder": 1,
  "isActive": true,
  "usageCount": 128,
  "lastUsedAt": "2026-08-07T14:30:00Z",
  "schemaVersion": 1
}
```

A user-created category carries the literal text they typed and no translation key:

```json
{
  "id": "cat_9f2ac1",
  "nameKey": null,
  "name": "Side Hustle",
  "color": "#00BFA5",
  "iconName": "briefcase",
  "isDefault": false,
  "sortOrder": 12,
  "isActive": true,
  "usageCount": 3,
  "lastUsedAt": "2026-08-07T09:15:00Z",
  "schemaVersion": 1
}
```

- **Invariant: exactly one of `nameKey` / `name` is non-null, never both, never neither.**
  `nameKey` is non-null only when `isDefault` is `true`; it is a key into the app's ARB files
  (e.g. `"category_food"`, see `docs/TECH_STACK.md` § Localization for the naming convention) and
  is resolved against the active locale at read time. `name` is non-null only when `isDefault` is
  `false`; it is the literal text the user typed and is never translated.
- **Renaming a default category is a one-way conversion to a user category** (Phase 3): the write
  clears `nameKey` to `null`, sets `name` to the literal text the user chose, and flips `isDefault`
  to `false`. From that point the category no longer tracks the device locale — it keeps whatever
  string the user set, in whatever language they typed it.
- `usageCount` and `lastUsedAt` let the category sheet surface the user's most-used categories
  first. This is the highest-leverage optimization available for the 3-second rule: after two
  weeks of use, the right category is almost always in the first row.
- `isActive: false` hides a category from the picker while preserving historical expenses that
  reference it. Categories are never hard-deleted.
- Default categories are seeded on first launch. Their `iconName` values map to a fixed, bundled
  icon set — the string is a key into an app-side map, never a dynamic lookup.

### 3. Expense Document

Path: `users/{userId}/expenses/{expenseId}`

```json
{
  "id": "exp_890123",
  "amountMinor": 15000,
  "currencyCode": "MXN",
  "categoryId": "cat_food",
  "date": "2026-08-07T14:30:00Z",
  "monthKey": "2026-08",
  "note": "Lunch",
  "createdAt": "2026-08-07T14:30:02Z",
  "syncedAt": null,
  "deletedAt": null,
  "schemaVersion": 1
}
```

`categoryId` is a plain string reference, not a Firestore `DocumentReference` — it serializes
cleanly to JSON, survives offline writes, and keeps the data layer free of SDK types in models.

Renaming a category does **not** rewrite historical expenses. The Wrapped resolves category names
at read time from the categories collection, so a rename applies retroactively, which is what
users expect.

---

## Wrapped aggregation

Monthly summaries are **computed on the client** from the local Firestore cache. For a personal
tracker, a month holds on the order of 100–300 documents; a client-side fold is faster than a
round trip, works fully offline, and costs nothing to maintain.

```dart
// One equality query, served from cache when available
final snapshot = await firestore
    .collection('users/$uid/expenses')
    .where('monthKey', isEqualTo: '2026-08')
    .where('deletedAt', isNull: true)
    .get();
```

A `users/{userId}/monthlySummaries/{YYYY-MM}` collection of precomputed aggregates is **not** part
of the design. Revisit only if a real user exceeds ~2,000 expenses in a month, and record it as a
deliberate architectural change if so.

One correctness caveat: on a fresh install before the initial sync completes, a cached query
returns partial data. The Wrapped must detect this (compare against a server-side
`count()` aggregation) and show a syncing state rather than a confidently wrong total.

---

## Indexes

`firestore.indexes.json`, deployed to both projects:

```json
{
  "indexes": [
    {
      "collectionGroup": "expenses",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "monthKey", "order": "ASCENDING" },
        { "fieldPath": "deletedAt", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "expenses",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "deletedAt", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "categories",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "usageCount", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

The `note` field is excluded from single-field indexing — it is never queried, and indexing free
text wastes storage and write cost.

---

## Security Rules

`firestore.rules`, deployed to both projects from the same file:

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }

    function incoming() {
      return request.resource.data;
    }

    function isValidExpense() {
      return incoming().keys().hasOnly([
               'id', 'amountMinor', 'currencyCode', 'categoryId', 'date',
               'monthKey', 'note', 'createdAt', 'syncedAt', 'deletedAt',
               'schemaVersion'
             ])
        && incoming().keys().hasAll([
               'amountMinor', 'currencyCode', 'categoryId', 'date', 'monthKey'
             ])
        && incoming().amountMinor is int
        && incoming().amountMinor > 0
        && incoming().amountMinor <= 100000000
        && incoming().currencyCode is string
        && incoming().currencyCode.size() == 3
        && incoming().categoryId is string
        && incoming().categoryId.size() <= 64
        && incoming().date is timestamp
        && incoming().monthKey is string
        && incoming().monthKey.matches('^[0-9]{4}-[0-9]{2}$')
        && (!('note' in incoming()) || incoming().note == null
            || (incoming().note is string && incoming().note.size() <= 280));
    }

    function isValidCategory() {
      return incoming().keys().hasAll(['nameKey', 'name', 'color', 'iconName'])
        && (incoming().nameKey is string || incoming().nameKey == null)
        && (incoming().name is string || incoming().name == null)
        && (incoming().nameKey is string) != (incoming().name is string)
        && (!(incoming().nameKey is string) || (
              incoming().nameKey.size() > 0
              && incoming().nameKey.size() <= 64
              && incoming().nameKey.matches('^[a-z0-9_]+$')))
        && (!(incoming().name is string) || (
              incoming().name.size() > 0
              && incoming().name.size() <= 40))
        && incoming().color is string
        && incoming().color.matches('^#[0-9A-Fa-f]{6}$')
        && incoming().iconName is string
        && incoming().iconName.size() <= 40;
    }

    match /users/{userId} {
      allow read:   if isOwner(userId);
      allow create: if isOwner(userId) && incoming().uid == userId;
      allow update: if isOwner(userId)
                    && incoming().uid == resource.data.uid;
      allow delete: if false;

      match /categories/{categoryId} {
        allow read:   if isOwner(userId);
        allow create, update: if isOwner(userId) && isValidCategory();
        allow delete: if false;
      }

      match /expenses/{expenseId} {
        allow read:   if isOwner(userId);
        allow create: if isOwner(userId) && isValidExpense();
        allow update: if isOwner(userId) && isValidExpense()
                      && incoming().createdAt == resource.data.createdAt;
        allow delete: if isOwner(userId);
      }
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

Notes:

- The trailing catch-all denies everything not explicitly matched above. Without it, a future
  top-level collection added by mistake is world-writable.
- Amount validation is server-side because client validation is a UX affordance, not a security
  control. A hostile client can write anything the rules permit.
- `delete` on user and category documents is `false` by design: deletion is soft, via `isActive` /
  `deletedAt`. Account deletion is a separate, audited flow (Phase 4) handled outside these rules.
- Expense `delete` is allowed so the 30-day purge of soft-deleted documents can run from the
  client. If that purge ever moves to a Cloud Function, tighten this to `false`.
- The `createdAt` immutability check on update prevents history rewriting.
- `isValidCategory()`'s `(incoming().nameKey is string) != (incoming().name is string)` is an XOR:
  it rejects a document where both `nameKey` and `name` are set, and rejects one where neither is,
  enforcing the § Category Document invariant above server-side rather than trusting the client
  to send exactly one.

### Rules are tested, not eyeballed

`@firebase/rules-unit-testing` covers, at minimum: user A cannot read user B's expenses; a
negative `amountMinor` is rejected; a `double` `amountMinor` is rejected; a malformed `monthKey`
is rejected; an unauthenticated client is rejected everywhere; a write to an undeclared top-level
collection is rejected. These run in CI on every pull request.
