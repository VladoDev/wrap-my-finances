# Phase 1 Data Model: Resumen Mensual Animado y Compartible

No changes to the `Expense` or `Category` domain entities or their Firestore shapes. This feature
adds one new domain entity, one new repository-backed document, and one presentation-only value
object.

## 1. `UserProfile` (domain entity, new — `lib/features/user_profile/domain/entities/`)

Mirrors the subset of `docs/DATA_MODEL.md`'s `users/{userId}` document this feature actually reads
or writes. Deliberately does not model `currencyCode`/`locale`/`defaultCategoryId`/`hapticsEnabled`
— those remain `004`'s `DeviceLocaleDefaults` interim and Phase 3 Settings' concern respectively;
adding fields this feature never touches would be speculative.

| Field | Type | Notes |
|---|---|---|
| `uid` | `String` | Matches the Firebase Auth uid; immutable. |
| `timeZone` | `String` | IANA identifier. Defaulted at profile-creation time from the device's current locale (see `research.md` #2) — not user-editable until Settings (Phase 3) exists. |
| `wrappedLastSeenMonth` | `String?` | `"YYYY-MM"` or `null` if no Wrapped has ever been marked seen. |

## 2. `WrappedSummary` (domain entity, new — `lib/features/wrapped/domain/entities/`)

The computed aggregate for one calendar month. Never persisted — recomputed on demand per
`docs/DATA_MODEL.md`'s "Wrapped aggregation" (no `monthlySummaries` collection).

| Field | Type | Notes |
|---|---|---|
| `monthKey` | `String` | `"YYYY-MM"`. |
| `isSyncing` | `bool` | `true` when the local cache's document count for this month is less than the server-side `count()` for the same filter — see `research.md` #6. When `true`, every field below is meaningless and MUST NOT be displayed. |
| `total` | `Money` | Sum of `amountMinor` over every non-deleted expense in the month, same `currencyCode` convention `Expense`/`Money` already use (single-currency, per Constitution Principle 3). |
| `topCategoryId` | `String?` | The category with the highest summed `amountMinor` this month. `null` only if the month has zero non-deleted expenses (never reached in practice — the trigger and manual entry point both require at least one). Ties break on the category's `sortOrder` ascending (lowest/oldest wins), for a deterministic, stable result — see Edge Cases in `spec.md`. |
| `topCategoryExpenseCount` | `int` | Count of non-deleted expenses in `topCategoryId` this month — "The Habit" story, not the count of all expenses in the month. |
| `biggestExpense` | `Money?` | The single largest non-deleted expense's amount this month. `null` under the same zero-expense condition as `topCategoryId`. |
| `expenseCount` | `int` | Total non-deleted expense count this month — used for the <5 suppression check (acceptance criterion 2) and as the shareable card's default "number of registros." |

Category **names** are deliberately not stored on `WrappedSummary` — FR-011 requires resolving them
at display time, so the presentation layer looks up `topCategoryId` against
`CategoryRepository`'s already-loaded categories (same `Map<String, Category>` pattern
`ExpenseHistoryPage` already builds from `activeCategoriesProvider`, per `research.md`'s note on
inherited category-resolution behavior).

## 3. Firestore document delta: `users/{userId}`

No schema change from `docs/DATA_MODEL.md` §1 — this feature is the first to actually **write** the
document, populating only the fields `UserProfile` models:

```json
{
  "uid": "user_abc123",
  "timeZone": "America/Mexico_City",
  "wrappedLastSeenMonth": null
}
```

`createdAt`, `lastLogin`, `isAnonymous`, `currencyCode`, `locale`, `defaultCategoryId`,
`hapticsEnabled`, `schemaVersion` remain undocumented by this feature's data layer and are left for
whichever future feature (Settings, Phase 3) needs them — the document is created with only the
fields above, and Security Rules validate only those (see `contracts/security-rules-delta.md`).
Reading the document tolerates the other documented fields being absent.

## 4. Trigger algorithm (presentation/domain use case, not a stored entity)

Evaluated once per app session by `wrappedAutoTriggerProvider` (see `research.md` #7):

1. `UserProfileRepository.ensureExists()` has already run at bootstrap (fire-and-forget); await its
   completion (idempotent, cheap if already done).
2. Compute `previousMonthKey` = the calendar month immediately before "now," in `timeZone`.
3. If `previousMonthKey == wrappedLastSeenMonth`: no auto-trigger, no suppressed-card offer either
   (already seen).
4. Else, fetch `WrappedSummary` for `previousMonthKey`.
   - If `isSyncing`: skip this session's check entirely (neither auto-trigger nor suppressed card)
     — showing either while data is known-incomplete would contradict FR-012. Re-evaluated next
     session.
   - If `expenseCount >= 5`: auto-trigger — navigate to `/wrapped/$previousMonthKey`.
   - If `0 < expenseCount < 5`: no auto-trigger; the History screen's suppressed card (see
     `spec.md` User Story 1, Acceptance Scenario 3) becomes visible for `previousMonthKey`.
   - If `expenseCount == 0`: neither — there is nothing to show.
5. `wrappedLastSeenMonth` is updated to `previousMonthKey` only when the user actually dismisses
   Wrapped (auto-shown or opened from the suppressed card) — never merely from having evaluated the
   trigger. This is what keeps a month the user never interacted with from silently being marked
   seen, while still never accumulating a backlog across skipped months (the next session's
   `previousMonthKey` is always the *new* previous month, not the old unseen one).
