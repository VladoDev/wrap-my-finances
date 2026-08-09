# Implementation Plan: Sistema de Diseño y Fundación de Localización

**Branch**: `002-design-system-localization` | **Date**: 2026-08-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-design-system-localization/spec.md`

## Summary

Build a consumable design-token layer and a five-language localization pipeline, verified entirely
by automated tests, with zero product screens. Three `ThemeExtension` subclasses —
`AppColorsExtension`, `AppTypographyExtension`, `AppSpacingExtension` — carry every color,
typography, radius, and spacing value the app will ever render, each resolved from `BuildContext`
via getters (`context.colors`, `context.typography`, `context.spacing`); their raw literals live in
exactly one file per family (`app_colors.dart` holding library-private hex constants, so importing
them from outside is a compile error, not just a convention). Four Material-3-based primitives
(`AppButton`, `AppCard`, `AppChip`, `AppTextField`) consume only those tokens. The app's `ThemeMode`
is pinned to `ThemeMode.light` with no `darkTheme`, so system dark mode has no effect; a throwaway
test-only second color-token instance proves a real dark scheme could later be added as one more
instance with zero widget changes. `flutter_localizations` + `gen_l10n` resolve all primitive text
from five ARB files (`en` template, `es`, `pt`, `it`, `fr`); a dedicated test — not `gen_l10n`'s own
lenient fallback behavior — fails the build the moment any locale is missing a key the template has.
A pure-Dart WCAG contrast calculator (test-only) verifies every text/background token pair meets AA;
widget tests verify all four primitives survive the longest of the five languages' translations at
200% text scale without clipping; `alchemist` golden tests (chosen over `golden_toolkit` for its
CI-deterministic-font mode) cover each primitive in the single light color scheme this feature
ships.

Technical approach: everything lives under `lib/core/design_system/` (tokens, theme wiring,
primitive widgets) and `lib/l10n/` (ARB sources + committed generated output), following the same
`core/`-not-`features/` placement precedent `001-environment-foundation` set for infrastructure that
isn't itself a product feature. `app.dart` (already the app shell from `001`) is extended — not
replaced — to wire the theme and localization delegates at the `MaterialApp.router` root, since
every future feature's screens inherit from that single root.

## Technical Context

**Language/Version**: Dart / Flutter, latest stable channel (unpinned per `docs/TECH_STACK.md`;
`pubspec.lock` is the source of truth)

**Primary Dependencies**: `google_fonts` (Nunito, self-hosted/bundled — see `research.md`),
`flutter_localizations` (SDK) + `intl`, dev: `alchemist` (golden tests, chosen over
`golden_toolkit` — see `research.md`)

**Storage**: N/A — this feature persists nothing and touches no Firestore collection or Security
Rule

**Testing**: `flutter_test` for widget/golden tests; `alchemist` for the golden-test harness; plain
`test`-style assertions (via `flutter_test`) for the three verification-only checks this feature
adds — hex-literal scanning, WCAG contrast calculation, and ARB key-completeness — all runnable
through the single `flutter test` command CI already invokes

**Target Platform**: iOS 15+, Android API 24+ (unchanged from `docs/TECH_STACK.md`; this feature
adds no platform-specific code)

**Project Type**: Mobile app (Flutter) — cross-cutting infrastructure module, no new product
feature and no new route beyond what `001-environment-foundation` already wired

**Performance Goals**: None beyond baseline; the one constraint carried over from
`docs/UI_UX_SPEC.md` §1 is that the bundled font must not block first frame on a network fetch
(`GoogleFonts.config.allowRuntimeFetching = false`, fonts shipped as assets)

**Constraints**: `ThemeMode` is a compile-time constant (`ThemeMode.light`), never derived from
`MediaQuery`/`platformBrightness` (FR-005/FR-006); every hex/TextStyle/radius/spacing literal is
confined to its one designated token file (FR-001–FR-004); the token architecture must support a
future dark scheme via one additional `ThemeExtension` instance with no widget-file changes
(FR-007/FR-008)

**Scale/Scope**: 3 token files, 1 theme-wiring file, 4 primitive widgets, 5 ARB locale files (~4
keys each for this feature), 1 committed `gen_l10n` output directory, ~8 new test files (hex scan,
WCAG contrast, ARB completeness, light-only theme, dark-extensibility proof, per-primitive
localization/200%-scale/golden coverage) — no product screens, no new routes, no Firestore or
Security Rules changes

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Applies? | Assessment |
|---|---|---|
| 1. The Logging Path Is Sacred | No | No keypad or logging UI exists in this feature; nothing here touches the logging path. |
| 2. Offline-First, Always | No | No writes, no persistence, no network dependency of any kind is introduced. |
| 3. Anti-Goals Are Binding | Yes | This feature explicitly excludes the dark color scheme, numeric keypad, categories, expenses, and authentication — matching spec's Out-of-Scope and every anti-goal on the list untouched. |
| 4. Layer Boundaries Are Enforced | Yes | Design-system code lives under `core/` as presentation-only infrastructure (widgets + `ThemeExtension`s); it has no `domain/` or `data/` layer to violate, and it imports nothing from any `features/`. |
| 5. Money Is Exact and Private | No | No monetary values, analytics, or telemetry are introduced. |
| 6. Environments Are Isolated and Symmetric | No | This feature is flavor-agnostic; both `dev` and `prod` render the same design system and localized text identically. |
| 7. Security Rules Are the Only Real Boundary | No | No Firestore access, no Security Rules changes. |
| 8. Accessible by Construction | Yes | This is a primary purpose of the feature: automated WCAG AA contrast verification (FR-009), text scaling to 200% without clipping (FR-013), and Material-3-based primitives that inherit correct tap-target and semantic-label handling for free (see `research.md`). |
| 9. Localized and Consistent by Construction | Yes | The other primary purpose: token-only design values with no hex/TextStyle/spacing literal escaping its one designated file (FR-001–FR-004), and a five-language ARB pipeline where a missing key fails CI (FR-010–FR-012). |

**Initial gate result**: PASS. No violations requiring a Complexity Tracking entry — the feature's
entire scope is direct execution of Principles 8 and 9, which is what it was commissioned to build.

**Post-Phase 1 re-check**: PASS, unchanged. `data-model.md` confirms every color token traces to
exactly one file (`app_colors.dart`, library-private literals per `research.md`), every typography
token is shape-only with color applied at the call site from `AppColorsExtension` (so no color
value duplicates outside `app_colors.dart`), and the WCAG contrast table covers every documented
text/fill pair including the two `on*` tokens (`onPrimary`, `onSecondary`) this feature had to
introduce beyond `docs/UI_UX_SPEC.md`'s original six named tokens, plus `onDanger` scoped
correctly to the large-text/UI-component threshold. No domain/data layer, Firestore access, money
value, or anti-goal-listed functionality was introduced during design (Principles 2, 4, 5, 6, 7
remain not-applicable/satisfied by construction).

## Project Structure

### Documentation (this feature)

```text
specs/002-design-system-localization/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md         # Phase 1 output (/speckit-plan command)
├── quickstart.md         # Phase 1 output (/speckit-plan command)
├── contracts/             # Phase 1 output (/speckit-plan command)
│   ├── design-system-api.md
│   └── localization-api.md
├── checklists/
│   └── requirements.md
└── tasks.md              # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

`contracts/` is included, unlike `001-environment-foundation`'s plan: this feature's entire purpose
is to expose a stable API (tokens, primitives, `AppLocalizations`) that every subsequent feature
depends on, so that dependency boundary is documented as a contract rather than left implicit.

### Source Code (repository root)

```text
lib/
├── app.dart                              # EXTENDED (not replaced): wires AppTheme, ThemeMode.light,
│                                          # localizationsDelegates, supportedLocales onto the existing
│                                          # MaterialApp.router from 001-environment-foundation
├── core/
│   └── design_system/
│       ├── tokens/
│       │   ├── app_colors.dart               # ThemeExtension<AppColorsExtension> + private hex palette
│       │   ├── app_typography.dart           # ThemeExtension<AppTypographyExtension>, GoogleFonts.nunito
│       │   └── app_spacing.dart              # ThemeExtension<AppSpacingExtension> (spacing + radius)
│       ├── theme/
│       │   ├── app_theme.dart                # ThemeData.light() wiring all three extensions
│       │   └── design_tokens.dart            # BuildContext.colors / .typography / .spacing getters
│       └── widgets/
│           ├── app_button.dart
│           ├── app_card.dart
│           ├── app_chip.dart
│           └── app_text_field.dart
└── l10n/
    ├── app_en.arb                            # template locale
    ├── app_es.arb
    ├── app_pt.arb
    ├── app_it.arb
    ├── app_fr.arb
    └── generated/                            # gen_l10n output, committed (see research.md)
        └── app_localizations*.dart

l10n.yaml                                     # repo root: arb-dir, output-dir, synthetic-package: false

assets/
└── fonts/
    └── Nunito-*.ttf                          # bundled, self-hosted per research.md

test/
├── support/
│   └── wcag_contrast.dart                    # test-only pure-Dart contrast calculator
├── core/
│   └── design_system/
│       ├── theme_light_only_test.dart            # US2 / FR-005 / FR-006
│       ├── theme_extensibility_test.dart         # US2 / FR-007 / FR-008
│       ├── tokens/
│       │   ├── no_raw_hex_colors_test.dart       # US1 / FR-002 / FR-003
│       │   └── app_colors_contrast_test.dart     # US5 / FR-009
│       └── widgets/
│           ├── app_button_test.dart              # behavior + golden + localization + 200% scale
│           ├── app_card_test.dart
│           ├── app_chip_test.dart
│           ├── app_text_field_test.dart
│           └── goldens/                          # committed reference PNGs (alchemist)
└── l10n/
    └── arb_keys_complete_test.dart               # US4 / FR-012
```

**Structure Decision**: Single Flutter mobile project, no separate backend/frontend split (same as
`001-environment-foundation` — the "backend" for this feature is nonexistent; it is pure
client-side presentation infrastructure). Design-system code and ARB sources live under `core/` and
top-level `l10n/` respectively, not under `features/`, because neither is a product feature — both
are dependencies every future `features/*` module will import. `app.dart` is the one file this
feature modifies rather than creates, since the app shell already exists from
`001-environment-foundation` and there is exactly one root `MaterialApp.router` for the whole app.

## Complexity Tracking

*No entries.* Every design decision in `research.md` (three separate `ThemeExtension`s instead of
one, library-private hex constants instead of a lint plugin, a hand-rolled WCAG formula instead of a
package, Material-3-wrapped primitives instead of custom-painted ones) was chosen specifically
*because* it was the simpler option that still satisfies the relevant functional requirement — none
of them add complexity beyond what Principles 8 and 9 already require this feature to build.
