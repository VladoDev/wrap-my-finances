# Phase 1 Data Model: Captura de Gasto en Menos de Tres Segundos

## Domain entities (unchanged from `003`)

`Expense`, `Money`, `Category` are consumed exactly as `003` defined them — see
`specs/003-auth-domain-foundation/contracts/domain-repositories-api.md`. This feature adds no field
to any of them.

## Firestore document shapes (new — first feature to write these)

### Expense document

Path: `users/{userId}/expenses/{expenseId}`. Produced by `ExpenseModel.fromEntity(Expense, {required currencyCode, required monthKey})`.

| Field | Source | Notes |
| --- | --- | --- |
| `id` | `collection.doc().id` | Assigned by the data layer, not the domain draft — see research.md |
| `amountMinor` | `expense.amount.minorUnits` | int, > 0, ≤ 100_000_000 (matches the 1,000,000.00 cap and `isValidExpense()`) |
| `currencyCode` | device-locale fallback map | See research.md's "no user profile document" correction |
| `categoryId` | `expense.categoryId` | Plain string reference |
| `date` | `expense.date` | `DateTime.now()` at submission — this screen has no manual date entry |
| `monthKey` | derived from `date` + device timezone offset | `"YYYY-MM"`, matches `isValidExpense()`'s regex |
| `note` | `expense.note` (always `null` for this feature) | FR-017 excludes note entry; field is written as `null` to match the documented schema shape, ready for a future feature that adds note entry without a schema migration |
| `createdAt` | `DateTime.now()` at write time | Client clock, immutable |
| `syncedAt` | `FieldValue.serverTimestamp()` | Never read by domain/presentation code (Constitution Principle 2) |
| `deletedAt` | `null` | No delete path in this feature |
| `schemaVersion` | `1` | Matches `docs/DATA_MODEL.md` |

### Category document

Path: `users/{userId}/categories/{categoryId}`. Produced by `CategoryModel.fromEntity(Category)`
and, for seeding, built directly from the default-category table below.

| Field | Source | Notes |
| --- | --- | --- |
| `id` | `collection.doc().id` at seed time | Stable per-user; user categories don't exist in this feature (FR-017) |
| `nameKey` / `name` | seed table's `nameKey`; always `null` for `name` | Every category this feature creates is a default category |
| `color` | `AppColorsExtension.light.categoryPalette[i]`, converted to `#RRGGBB` at write time | See research.md — never a literal in seeding code |
| `iconName` | seed table | Key into `category_icon_map.dart`, presentation-only |
| `isDefault` | `true` | |
| `sortOrder` | seed table (1–7) | Tie-break key when `usageCount` is equal |
| `isActive` | `true` | |
| `usageCount` | `0` at seed time; incremented by `incrementUsage()` | Drives FR-006's ordering |
| `lastUsedAt` | `null` at seed time; set on `incrementUsage()` | |
| `schemaVersion` | `1` | |

### Default category seed table

| `nameKey` | `iconName` | Icon (Material) | `sortOrder` | `categoryPalette` index |
| --- | --- | --- | --- | --- |
| `category_food` | `restaurant` | `Icons.restaurant` | 1 | 0 |
| `category_transport` | `directions_car` | `Icons.directions_car` | 2 | 1 |
| `category_shopping` | `shopping_bag` | `Icons.shopping_bag` | 3 | 2 |
| `category_entertainment` | `movie` | `Icons.movie` | 4 | 3 |
| `category_health` | `medical_services` | `Icons.medical_services` | 5 | 4 |
| `category_housing` | `home` | `Icons.home` | 6 | 5 |
| `category_other` | `category` | `Icons.category` | 7 | 6 |

Adding an eighth default category later means: one new row here, one new entry in
`category_icon_map.dart`, one new `switch` branch in `category_name_resolver.dart`, and one new key
in all five ARB files — exactly the "touch the seeding code and the five ARBs" contract the plan
input asked for.

## New ARB keys (all five locales)

**Naming note**: `docs/TECH_STACK.md` documents the `category_*` prefix as `snake_case`, but every
ARB key actually committed so far (`commonContinue`, `commonDevBuild`, ...) is `camelCase` — gen_l10n
turns each key into a Dart getter name, and a `snake_case` key produces a getter that trips
`very_good_analysis`'s naming lints. The **ARB message keys** below follow the established
`camelCase` precedent; the **`nameKey` values stored in Firestore** (`"category_food"`, etc., per
`docs/DATA_MODEL.md`'s example) stay `snake_case`, and are in fact server-enforced as such —
`isValidCategory()`'s `nameKey.matches('^[a-z0-9_]+$')` would reject a camelCase value outright.
`category_name_resolver.dart` (`US3`) is exactly the bridge between the two: it `switch`es on the
snake_case `nameKey` string and returns the matching camelCase ARB getter.

| ARB key | Firestore `nameKey` value (where applicable) | English value | Description |
| --- | --- | --- | --- |
| `categoryFood` | `category_food` | Food | Default category name |
| `categoryTransport` | `category_transport` | Transport | Default category name |
| `categoryShopping` | `category_shopping` | Shopping | Default category name |
| `categoryEntertainment` | `category_entertainment` | Entertainment | Default category name |
| `categoryHealth` | `category_health` | Health | Default category name |
| `categoryHousing` | `category_housing` | Housing | Default category name |
| `categoryOther` | `category_other` | Other | Default category name |
| `categoryPickerTitle` | — | Choose a category | Bottom sheet heading |
| `expenseSaveErrorMessage` | — | Couldn't save — try again | Non-blocking snackbar text for FR-012's local-write failure |
| `keypadAmountSemanticLabel` | — | Amount | Screen-reader label for the amount display (Constitution Principle 8) |

`commonContinue` (existing, from `003`) is reused as the "Next" button label — it is already the
semantically correct string ("advance to the next step") and adding a near-duplicate key would
violate the project's own no-unnecessary-abstraction default.

## Design-system token additions

- `AppTypographyExtension.displayLarge` — new `TextStyle` in `app_typography.dart`, tabular figures
  (`FontFeature.tabularFigures()`), for the large amount display (`docs/UI_UX_SPEC.md` §2: "digits
  are large, chunky... tabular figures so digits do not shift horizontally").
- `AppColorsExtension.categoryPalette` — new `List<Color>` (7 entries) in `app_colors.dart`, backed
  by new library-private hex constants in that same file (the one file allowed to hold them).

Both are additions to the existing single-source-of-truth files, not new files and not literals
outside them.

## Presentation-layer state (new, feature-local — not domain)

### `AmountInputState` (plain Dart, `expenses/presentation/controllers/`)

- `rawDigits: String` — what the user has typed, before formatting
- `minorUnits: int` — parsed integer minor units (0 when empty or all zeros)
- `isValid: bool` — `minorUnits > 0` (drives FR-010's disabled-Next state)
- `formattedDisplay: String` — locale-grouped, decimal-capped display string (via `intl`)
- Mutating operations: `appendDigit`, `appendDecimalSeparator`, `backspace` — each pure, returning a
  new `AmountInputState`, enforcing: single decimal separator, max two decimal digits (further
  digits ignored), 1,000,000.00 ceiling (further digits ignored once reached), backspace on empty is
  a no-op.

### `ExpenseCaptureState` (Riverpod, `expenses/presentation/controllers/`)

- `step: CaptureStep` — `amount | category`
- `amount: AmountInputState`
- `categories: List<Category>` — from `CategoryRepository.watchActive()`, already ordered by
  `usageCount` descending per the repository contract
- `isSubmitting: bool` — true only for the brief window between tapping a category and the local
  write resolving; never gates a spinner, only prevents a double-submit from a fast double-tap
- `lastError: Failure?` — non-null only after a local-write failure (FR-012); cleared on the next
  attempt

## Security Rules

No change. See research.md's "firestore.rules needs no changes for this feature" — `003`'s
`isValidExpense()`/`isValidCategory()` already cover every write shape this feature produces,
including `incrementUsage()`'s partial `update()`.
