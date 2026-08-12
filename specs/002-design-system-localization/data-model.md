# Phase 1 Data Model: Design System & Localization Foundation

This feature introduces no persisted data and no domain entities in the Clean Architecture sense —
there is no `domain/` layer here at all, because there is nothing to persist or fetch. What it does
introduce is a **token contract** (the typed shape of the design system) and a **translation key
contract** (the ARB namespace). Both are "data models" in the sense that matters for this feature:
structures other code will depend on and tests will verify against. Concrete hex/size values below
are the starting point derived from `docs/UI_UX_SPEC.md` §1; where a value isn't fully specified
there (the `on*` text-color tokens), it is chosen here and its exact value is authoritative only
once it passes the WCAG contrast test described in `research.md` — the test, not this document, is
the final source of truth for SC-004.

## `AppColorsExtension` (color tokens)

A `ThemeExtension<AppColorsExtension>`. Exactly one instance ships with this feature:
`AppColorsExtension.light`. Its raw hex values live only in `app_colors.dart` as library-private
constants (see `research.md`); this table documents the semantic token, not implementation.

| Token | Starting value | Source | Paired with (text/fill role) |
|---|---|---|---|
| `background` | `#F8F9FA` | `docs/UI_UX_SPEC.md` §1 | Body text via `onBackground` |
| `onBackground` | `#2D3436` | Same as `onSurface` — background and surface are both light neutrals | Normal-text pair, ≥4.5:1 |
| `surface` | `#FFFFFF` | `docs/UI_UX_SPEC.md` §1 | Card/sheet content via `onSurface` |
| `onSurface` | `#2D3436` | `docs/UI_UX_SPEC.md` §1 | Normal-text pair, ≥4.5:1 |
| `primary` | `#FF6B6B` | `docs/UI_UX_SPEC.md` §1 | Button fill; label text via `onPrimary` |
| `onPrimary` | `#2D3436` (reuses `onSurface`, not white) | Introduced by this feature | Normal-text pair on `primary`, ≥4.5:1 (white fails at ~2.8:1) |
| `secondary` | `#4ECDC4` | `docs/UI_UX_SPEC.md` §1 | Accent fill; label text via `onSecondary` |
| `onSecondary` | `#2D3436` (reuses `onSurface`) | Introduced by this feature | Normal-text pair on `secondary`, ≥4.5:1 (white fails at ~1.9:1) |
| `danger` | `#E17055` | `docs/UI_UX_SPEC.md` §1 | Destructive fill; label text via `onDanger` — **large-text/UI-component pairing only** (≥3:1); no normal-size text color reaches 4.5:1 against this fill, matching the constitution's own rule that saturated accent fills are never the color small text sits on |
| `onDanger` | `#FFFFFF` | Introduced by this feature | Large-text pair on `danger`, ≥3:1 |
| `outline` | `#2D3436` (reuses `onSurface`) | Introduced by this feature | Decorative — the "thick border" neo-brutalism accent from `docs/UI_UX_SPEC.md` §1; not a text pair, not contrast-tested |

**Validation rule enforced by test**: every row marked "text/fill role" above is one entry in
`app_colors_contrast_test.dart`'s pair table, asserted against the threshold noted (4.5:1 or 3:1).
`outline` is excluded — it decorates borders/shadows, never carries text.

**Extensibility property (FR-007/FR-008)**: nothing above is referenced by any primitive's source
file as a literal — every primitive reads `context.colors.<token>`. `theme_extensibility_test.dart`
swaps in a second, test-only `AppColorsExtension` instance with different values for every token
above and asserts the four primitives render those values, proving a real dark scheme could be
added the same way (a second instance, no widget change) without this feature shipping one.

## `AppTypographyExtension` (typography tokens)

A `ThemeExtension<AppTypographyExtension>`, one instance: `AppTypographyExtension.standard`. Every
field is a `TextStyle` built from `GoogleFonts.nunito(...)`, carrying font weight/size/letter-
spacing/height only — **never `color`** (see `research.md` for why). Only the styles this feature's
four primitives actually consume are defined; the class is designed to grow more fields later
without breaking existing ones.

| Token | Weight | Size (logical px) | Used by |
|---|---|---|---|
| `titleMedium` | 700 (bold) | 18 | `AppCard` title slot |
| `bodyMedium` | 400 (regular) | 16 | `AppCard` body slot, `AppTextField` input text |
| `bodySmall` | 400 (regular) | 14 | `AppTextField` hint/helper/error text, `AppChip` label |
| `labelLarge` | 700 (bold) | 16 | `AppButton` label |

**Validation rule enforced by test**: `theme_extensibility_test.dart` and the golden tests both
exercise these styles at the default text scale; `component_text_scaling_test.dart` (per-primitive)
re-renders each style at `TextScaler.linear(2.0)` with the longest translated label (see ARB
contract below) and asserts no clipping/overflow (FR-013).

## `AppSpacingExtension` (spacing and radius tokens)

A `ThemeExtension<AppSpacingExtension>`, one instance: `AppSpacingExtension.standard`. Groups
spacing and radius per the constitution's `app_spacing.dart` file grouping.

| Token | Value (dp) | Used by |
|---|---|---|
| `spacingXs` | 4 | Icon-to-label gaps inside `AppChip` |
| `spacingSm` | 8 | `AppButton`/`AppChip` internal padding (vertical) |
| `spacingMd` | 16 | `AppButton` internal padding (horizontal), `AppCard` internal padding, `AppTextField` internal padding |
| `spacingLg` | 24 | `AppCard` external margin, gaps between stacked primitives |
| `spacingXl` | 32 | Reserved for section-level spacing in future features |
| `radiusSm` | 8 | `AppTextField` border radius |
| `radiusMd` | 16 | `AppCard` border radius |
| `radiusLg` | 24 | Reserved (matches `docs/UI_UX_SPEC.md`'s `BorderRadius.circular(24)` example) |
| `radiusPill` | `double.infinity` (via `StadiumBorder`) | `AppButton`, `AppChip` — "fully pill-shaped" per `docs/UI_UX_SPEC.md` §1 |

No validation rules beyond FR-004 (no literal spacing/radius outside this file) — enforced by the
same scanning test pattern as `no_raw_hex_colors_test.dart`, extended to flag bare numeric literals
passed to `EdgeInsets`/`BorderRadius` constructors outside `app_spacing.dart`.

## `ThemeMode` fixation

Not a token, but part of this feature's contract: `AppTheme.themeMode` is the constant
`ThemeMode.light`. `App` (in `app.dart`) passes `theme: AppTheme.light`, `themeMode:
ThemeMode.light`, and **does not** pass a `darkTheme`. This is what FR-005/FR-006 require — there is
no code path, at any point, that reads `MediaQuery.platformBrightnessOf(context)` or
`WidgetsBinding.instance.platformDispatcher.platformBrightness`.

## Primitive components

Each is a `StatelessWidget` under `lib/core/design_system/widgets/`, consuming only
`context.colors` / `context.typography` / `context.spacing`, wrapping an equivalent Material 3
widget (see `research.md`). None contains a literal string — every label is a parameter the caller
supplies, typically an `AppLocalizations` lookup.

| Component | Wraps | Key props | Notes |
|---|---|---|---|
| `AppButton` | `FilledButton` | `label: String`, `onPressed: VoidCallback?`, `variant: AppButtonVariant { primary, secondary, danger }` | Pill shape (`radiusPill`), min 48×48dp tap target, label uses `labelLarge` + the variant's `on*` color |
| `AppCard` | `Card` | `title: String?`, `body: String?`, `child: Widget?` | `radiusMd`, `surface`/`onSurface`, thick `outline` border per neo-brutalism; renders no text at all when only `child` is supplied (Edge Case: text-scaling test doesn't apply to that configuration) |
| `AppChip` | `Chip` | `label: String`, `variant: AppChipVariant { neutral, primary, secondary }` | `radiusPill`, `spacingXs` icon gap, `bodySmall` label — tightest text box of the four primitives, so it's the primary stress case for FR-013 |
| `AppTextField` | `TextFormField` | `label: String`, `hint: String?`, `errorText: String?` | `radiusSm`, `bodyMedium` input text, `bodySmall` hint/error, min 48dp height |

## ARB translation key contract

Five files under `lib/l10n/`: `app_en.arb` (template), `app_es.arb`, `app_pt.arb`, `app_it.arb`,
`app_fr.arb`. This feature introduces only `common_*`-prefixed keys (per the `docs/TECH_STACK.md`
naming convention) — generic strings genuinely reusable by future features, not throwaway sample
copy, since no product screen exists yet to own feature-specific keys like `keypad_*` or
`settings_*`.

| Key | English (template) | Used by |
|---|---|---|
| `common_continue` | "Continue" | `AppButton` example/test usage |
| `common_cancel` | "Cancel" | `AppButton` example/test usage |
| `common_retry` | "Retry" | `AppButton` example/test usage |
| `common_delete` | "Delete" | `AppButton` (danger variant) example/test usage |

**Validation rule enforced by test (FR-012/SC-006)**: `arb_keys_complete_test.dart` asserts the key
set of `app_es.arb`, `app_pt.arb`, `app_it.arb`, and `app_fr.arb` exactly equals the key set of
`app_en.arb`, and that no value is empty/whitespace-only.

**Longest-label determination (FR-013)**: for each key above, the implementation phase measures
rendered string length across all five locales and uses the longest as the golden/widget-test input
for that primitive's overflow check. Per `docs/UI_UX_SPEC.md` §7, French and Portuguese are the
likely worst case, but the test picks the actual longest per key rather than assuming which
language wins.

## Relationships

None of the above references `docs/DATA_MODEL.md`'s `users`, `categories`, or `expenses` entities.
This feature is a dependency *of* every future feature (they will consume tokens, primitives, and
`AppLocalizations`), never the reverse.
