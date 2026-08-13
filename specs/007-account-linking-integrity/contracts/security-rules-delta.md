# Contract: Security Rules Delta

Two changes to `firestore.rules`, both additive/widening, both following patterns the file
already establishes elsewhere.

## 1. `isValidUserProfile()` — validate `currencyCode` for real

`006` reserved `currencyCode` in the allowed key set but deliberately left it unvalidated ("the
other six remain unvalidated until a future feature... writes them for real and extends
`isValidUserProfile()` additively" — `specs/006-monthly-wrapped-summary/contracts/
security-rules-delta.md`). This is that feature.

```
function isValidUserProfile() {
  return incoming().keys().hasOnly([
           'uid', 'createdAt', 'lastLogin', 'isAnonymous', 'currencyCode',
           'locale', 'timeZone', 'defaultCategoryId', 'wrappedLastSeenMonth',
           'hapticsEnabled', 'schemaVersion'
         ])
    && incoming().keys().hasAll(['uid', 'timeZone'])
    && incoming().uid is string
    && incoming().timeZone is string
    && incoming().timeZone.size() > 0
    && (!('currencyCode' in incoming())
        || incoming().currencyCode == null
        || (incoming().currencyCode is string && incoming().currencyCode.size() == 3))
    && (!('wrappedLastSeenMonth' in incoming())
        || incoming().wrappedLastSeenMonth == null
        || (incoming().wrappedLastSeenMonth is string
            && incoming().wrappedLastSeenMonth.matches('^[0-9]{4}-[0-9]{2}$')));
}
```

Only the `currencyCode` clause is new (mirrors `isValidExpense()`'s existing
`currencyCode.size() == 3` check exactly, for the same ISO-4217 shape). Nothing else in this
function changes.

## 2. `users/{userId}` and its `categories` subcollection — allow owner delete

```
match /users/{userId} {
  allow read:   if isOwner(userId);
  allow create: if isOwner(userId) && incoming().uid == userId && isValidUserProfile();
  allow update: if isOwner(userId)
                && incoming().uid == resource.data.uid
                && isValidUserProfile();
  allow delete: if isOwner(userId);

  match /categories/{categoryId} {
    allow read:   if isOwner(userId);
    allow create, update: if isOwner(userId) && isValidCategory();
    allow delete: if isOwner(userId);
  }

  match /expenses/{expenseId} {
    // unchanged — allow delete: if isOwner(userId) already present since 004/005
  }
}
```

Both changed lines go from `if false` to `if isOwner(userId)` — the exact same ownership predicate
already governing every other write in this file. No new function, no new logic shape.

## Notes

- These two changes are what `research.md` #3 ("account deletion is client-side") actually
  requires — without them, `AuthRepository.deleteAccount()`'s batch-delete of the user document
  and category subcollection would be rejected by rules that predate this feature's requirement.
- `expenses`' `allow delete` already covers the account-deletion batch-delete; no change needed
  there.
- This is an **additive, backward-compatible** change — no existing `isValidExpense()`/
  `isValidCategory()` rule, and no existing *read*/*create*/*update* rule, is touched.

## Required test additions

Extends the existing `@firebase/rules-unit-testing` suite (Constitution Principle 7), at minimum:

- `firebase/tests/users.rules.test.js`:
  - Owner can delete their own `users/{uid}` document.
  - A different user cannot delete another user's document.
  - Creating/updating a profile with a valid 3-letter `currencyCode` succeeds.
  - Creating/updating a profile with a malformed `currencyCode` (wrong length, not a string) is
    rejected.
  - The existing "owner can create with only `uid`+`timeZone`" test (from `006`) continues to pass
    unmodified — `currencyCode` stays optional.
- `firebase/tests/categories.rules.test.js`:
  - Owner can delete their own category document.
  - A different user cannot delete another user's category document.
