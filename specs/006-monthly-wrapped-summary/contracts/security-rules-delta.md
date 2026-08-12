# Contract: Security Rules Delta

`006` is the first feature to actually write `users/{userId}` (see `research.md` #1). The current
`firestore.rules` (`docs/DATA_MODEL.md` § Security Rules) already scopes `create`/`update` on that
path to `isOwner(userId)` plus `incoming().uid == userId` / `== resource.data.uid`, but — unlike
`isValidExpense()`/`isValidCategory()` — has no field/type/range validation function for it. Per
Constitution Principle 7 ("Rules MUST validate ownership, field presence, types, and ranges
server-side"), this feature adds one.

**Correction found while implementing this contract**: `firebase/tests/users.rules.test.js`
already exists (predates this feature) and its `validUser()` fixture writes the **full**
`docs/DATA_MODEL.md` §1 field set (`uid`, `createdAt`, `lastLogin`, `isAnonymous`, `currencyCode`,
`locale`, `timeZone`, `defaultCategoryId`, `wrappedLastSeenMonth`, `hapticsEnabled`,
`schemaVersion`) — anticipating the document's eventual full shape even though no feature has
populated most of those fields yet. A `hasOnly([...])` restricted to just the three fields this
feature's `UserProfileRepository` writes (`uid`, `timeZone`, `wrappedLastSeenMonth`) would reject
that existing fixture and break all six of that file's already-passing tests. `isValidUserProfile()`
therefore allows the full documented key set, but only **type/range-validates the three fields this
feature actually populates** — validating the other six now would mean inventing constraints no
shipped feature has specified yet, which is exactly the kind of unrequested addition this project
avoids. A future feature (Settings, Phase 3) that starts writing those fields for real extends the
validation for the ones it touches, additively.

## New rule function

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
    && (!('wrappedLastSeenMonth' in incoming())
        || incoming().wrappedLastSeenMonth == null
        || (incoming().wrappedLastSeenMonth is string
            && incoming().wrappedLastSeenMonth.matches('^[0-9]{4}-[0-9]{2}$')));
}
```

## Updated `match /users/{userId}` block

```
match /users/{userId} {
  allow read:   if isOwner(userId);
  allow create: if isOwner(userId) && incoming().uid == userId && isValidUserProfile();
  allow update: if isOwner(userId)
                && incoming().uid == resource.data.uid
                && isValidUserProfile();
  allow delete: if false;

  // ...existing /categories and /expenses subcollection rules, unchanged...
}
```

## Notes

- `keys().hasOnly([...])` allows the full `docs/DATA_MODEL.md` §1 key set — so the existing
  `validUser()` fixture in `firebase/tests/users.rules.test.js` keeps validating unchanged — but
  only `uid`/`timeZone`/`wrappedLastSeenMonth` (the three fields this feature's
  `UserProfileRepository` actually populates, `data-model.md` §3) get real type/range checks. The
  other six remain unvalidated until a future feature (Settings, Phase 3) writes them for real and
  extends `isValidUserProfile()` additively — the same pattern `isValidExpense()`/
  `isValidCategory()` already establish for their own collections.
- `wrappedLastSeenMonth`'s regex mirrors `isValidExpense()`'s existing `monthKey` validation
  (`^[0-9]{4}-[0-9]{2}$`), for the same reason: a malformed value would silently break every future
  month-boundary comparison against it.
- This is an **additive, backward-compatible** rules change — no existing `/categories` or
  `/expenses` rule is touched, and no existing test in `firebase/tests/users.rules.test.js` needs
  to change.

## Required test additions

`006` extends the existing `firebase/tests/users.rules.test.js` suite (Constitution Principle 7 —
"Rules have an automated test suite run in CI"), adding at minimum:

- Creating `users/{uid}` with only `uid` and a valid `timeZone` (no other fields) succeeds — this
  is what `UserProfileRepository.ensureExists()` actually writes.
- Creating it with `wrappedLastSeenMonth` set to a well-formed `"YYYY-MM"` succeeds.
- Creating it with a malformed `wrappedLastSeenMonth` (e.g. `"2026-13"`, `"last month"`) is
  rejected.
- Creating it without `timeZone` is rejected.
- Creating it with an extra, undeclared key (outside the full documented set) is rejected
  (`keys().hasOnly` enforcement).
- The existing six tests (owner create/read, cross-user read denial, `uid`-unchanged update,
  `uid`-changed-on-update rejection, delete always denied, undeclared top-level collection denied,
  unauthenticated denied) continue to pass unmodified against their current `validUser()` fixture.
