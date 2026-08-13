# Contract: Category Management & Preferences

Builds on `003`'s `CategoryRepository` contract (`getActive`, `watchActive`, `incrementUsage`,
`seedDefaultsIfNeeded`, unchanged) and `006`'s `UserProfileRepository` contract (`ensureExists`,
`watchProfile`, `markWrappedSeen`, unchanged).

## `CategoryRepository` — additive members

```dart
abstract class CategoryRepository {
  // ...existing members, unchanged...

  /// Every category, active and archived — the management screen's list.
  /// Distinct from [getActive]/[watchActive], which are the capture path's
  /// view and deliberately exclude archived categories.
  Future<Result<List<Category>>> getAll();

  /// Creates a new **user** category — nameKey is always null, [name] is
  /// always the literal text given. This screen never creates a
  /// default/translated category.
  Future<Result<Category>> create({
    required String name,
    required String color,
    required String iconName,
  });

  /// Updates an existing category. If the target is currently a default
  /// category (`isDefault: true`) and [name] is provided, this performs
  /// the rename-becomes-user-category conversion documented in
  /// `docs/DATA_MODEL.md`: clears `nameKey`, sets `name`, flips
  /// `isDefault` to `false` — one write, not two.
  Future<Result<void>> update(
    String categoryId, {
    String? name,
    String? color,
    String? iconName,
  });

  /// Rewrites `sortOrder` for every category in [orderedIds] to match the
  /// given order.
  Future<Result<void>> reorder(List<String> orderedIds);

  /// Archives ([isActive]: false) or unarchives ([isActive]: true) a
  /// category. Never touches any `expenses` document that references it.
  Future<Result<void>> setActive(String categoryId, bool isActive);
}
```

## `UserProfileRepository` — widened member

```dart
abstract class UserProfileRepository {
  // ...existing members (ensureExists, watchProfile, markWrappedSeen), unchanged...

  /// Sets the user's `currencyCode` preference. Affects only expenses
  /// logged after this call — never rewrites a past expense's stored
  /// amount or currency (docs/DATA_MODEL.md, amended by this feature).
  Future<Result<void>> updateCurrencyCode(String currencyCode);

  /// Sets the user's `timeZone` preference. Affects only how future
  /// expenses compute `monthKey` — never re-evaluates or reassigns the
  /// `monthKey` already stored on existing documents
  /// (docs/DATA_MODEL.md, already documented since `006`).
  Future<Result<void>> updateTimeZone(String timeZone);
}
```

## Settings navigation contract

- A new route, `/settings`, added as a **third destination** on `AppShell`'s floating nav bar
  (`005`'s existing component) — Capture and History remain unchanged; Capture remains the fixed
  launch destination regardless of where Settings was left (same guarantee `005`/`006` already
  established for History).
- Category management, account linking/deletion, and currency/timezone preferences are sections
  within `/settings`, not separate routes — this feature does not introduce additional top-level
  navigation destinations beyond the one.

## Stability notes for consumers

- All `CategoryRepository` additions are additive; no existing caller (`ExpenseCaptureController`,
  `ExpenseHistoryPage`, `WrappedRoutePage`) is affected.
- `getActive()`/`watchActive()`'s existing "active categories only, ordered by `usageCount`"
  contract is unchanged — archiving a category simply means it stops appearing in that result,
  exactly as it already would for any category with `isActive: false` today.
- `UserProfileRepository.updateCurrencyCode`/`updateTimeZone` are additive; `006`'s
  `ensureExists`/`watchProfile`/`markWrappedSeen` callers are unaffected.
