---

description: "Task list for Sistema de Diseño y Fundación de Localización"
---

# Tasks: Sistema de Diseño y Fundación de Localización

**Input**: Design documents from `/specs/002-design-system-localization/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Included. This feature's entire value is "verificable mediante tests" (spec.md, Resultado esperado) — every user story's Independent Test *is* an automated test, not a manual check, so test tasks are not optional here.

**Organization**: Tasks are grouped by user story (see spec.md) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Which user story this task belongs to (US1–US7)
- Every task states its exact file path

## Path Conventions

Single Flutter mobile project at the repository root (`lib/`, `test/`), per `plan.md`'s Project Structure. Design-system code lives under `lib/core/design_system/`; localization sources under `lib/l10n/`. No `backend/`/`frontend/` split.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Dependencies, bundled assets, and the CI pipeline this feature's own acceptance criteria (FR-012/SC-006, "fails in CI") depend on

- [X] T001 Add `google_fonts`, `flutter_localizations` (SDK), and `intl` to `dependencies` and `alchemist` to `dev_dependencies` in `pubspec.yaml`; run `flutter pub get` — done; `intl` pinned to `^0.20.2` to match the exact version `flutter_localizations` (SDK) requires
- [X] T002 [P] Download Nunito static `.ttf` files (Regular 400, Bold 700) into `assets/fonts/`, declare them under a `Nunito` font family in `pubspec.yaml`'s `flutter: fonts:` section, and set `GoogleFonts.config.allowRuntimeFetching = false;` as the first line of `bootstrap()` in `lib/bootstrap.dart`, per `research.md`'s self-hosting decision — Nunito is published upstream only as a variable font (no static instances in the `google/fonts` repo), so one `Nunito-Variable.ttf` is bundled with two `weight:` entries (400/700) in pubspec pointing at the same file; Skia resolves the requested static instance from its `wght` axis
- [X] T003 [P] Create `l10n.yaml` at the repository root (`arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-class: AppLocalizations`, `output-dir: lib/l10n/generated`, `synthetic-package: false`) and set `generate: true` under `flutter:` in `pubspec.yaml`, per `research.md`
- [X] T004 Create `.github/workflows/ci.yml` running `flutter pub get`, `dart format --set-exit-if-changed`, `flutter analyze`, and `flutter test` on every pull request — this pipeline does not yet exist in the repository (a gap left from `001-environment-foundation`/`docs/ROADMAP.md` Phase 0), and FR-012/SC-006 of this feature's own spec require a real CI failure, not just a local one, so this feature closes that gap rather than assuming it

**Checkpoint**: Dependencies installed, font bundled, l10n tooling configured, CI pipeline exists and runs `flutter test`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The token files, theme wiring, and localization plumbing every user story depends on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T005 [P] Create `lib/l10n/app_en.arb` (template) with `common_continue`, `common_cancel`, `common_retry`, `common_delete` keys, each with an `@`-metadata description, per `data-model.md`'s ARB contract — implemented with camelCase key names (`commonContinue`, etc.) since that's what `gen-l10n` requires as Dart getter names; the constitution's `snake_case` convention refers to the ARB key across the wider naming scheme, not the generated Dart identifier
- [X] T006 [P] Create `lib/l10n/app_es.arb` with Spanish translations of all four keys (depends on T005 for the key list)
- [X] T007 [P] Create `lib/l10n/app_pt.arb` with Portuguese translations of all four keys (depends on T005)
- [X] T008 [P] Create `lib/l10n/app_it.arb` with Italian translations of all four keys (depends on T005)
- [X] T009 [P] Create `lib/l10n/app_fr.arb` with French translations of all four keys (depends on T005)
- [X] T010 Run `flutter gen-l10n` (or `flutter pub get`, since `generate: true` is set) to produce `lib/l10n/generated/app_localizations*.dart` and confirm it compiles (depends on T003, T005–T009) — `l10n.yaml`'s `synthetic-package` key had to be removed (no longer effective on this Flutter version, deprecation warning); output confirmed under `lib/l10n/generated/`
- [X] T011 [P] Create `lib/core/design_system/tokens/app_colors.dart`: library-private hex constants (`_coral`, `_teal`, `_offWhite`, `_darkNeutral`, `_danger`) and the public `AppColorsExtension` (`background`, `onBackground`, `surface`, `onSurface`, `primary`, `onPrimary`, `secondary`, `onSecondary`, `danger`, `onDanger`, `outline`) with a `static const AppColorsExtension light` instance, per `data-model.md`'s color token table
- [X] T012 [P] Create `lib/core/design_system/tokens/app_typography.dart`: `AppTypographyExtension` (`titleMedium`, `bodyMedium`, `bodySmall`, `labelLarge`) with no `color` set on any style, with a `static AppTypographyExtension get standard`, per `data-model.md`'s typography token table and `research.md`'s "typography carries no color" decision — built with plain `TextStyle(fontFamily: 'Nunito', ...)` rather than `GoogleFonts.nunito(...)`; see research.md's "Implementation-time refinement" note (Nunito ships only as a variable font upstream, so `google_fonts`' static-file matcher can't find it)
- [X] T013 [P] Create `lib/core/design_system/tokens/app_spacing.dart`: `AppSpacingExtension` (`spacingXs/Sm/Md/Lg/Xl`, `radiusSm/Md/Lg`, `radiusPill` as a `StadiumBorder`) with a `static const AppSpacingExtension standard`, per `data-model.md`'s spacing/radius token table
- [X] T014 Create `lib/core/design_system/theme/app_theme.dart`: `AppTheme.light` (a `ThemeData` registering `AppColorsExtension.light`, `AppTypographyExtension.standard`, `AppSpacingExtension.standard` in `extensions`) and the constant `AppTheme.themeMode = ThemeMode.light` (depends on T011, T012, T013)
- [X] T015 [P] Create `lib/core/design_system/theme/design_tokens.dart`: a `BuildContext` extension exposing `.colors` → `AppColorsExtension`, `.typography` → `AppTypographyExtension`, `.spacing` → `AppSpacingExtension`, each via `Theme.of(this).extension<T>()!` (depends on T011, T012, T013)
- [X] T016 Update `lib/app.dart`: pass `theme: AppTheme.light`, `themeMode: ThemeMode.light`, `localizationsDelegates: AppLocalizations.localizationsDelegates`, `supportedLocales: AppLocalizations.supportedLocales` to the existing `MaterialApp.router`; do **not** pass `darkTheme` (depends on T010, T014)
- [X] T017 [P] Create `test/support/wcag_contrast.dart`: pure functions `relativeLuminance(Color)` and `contrastRatio(Color, Color)` implementing the WCAG 2.x formulas, per `research.md`

**Checkpoint**: Tokens, theme, and localization are all wired and compiling. User story implementation can now begin.

---

## Phase 3: User Story 1 - Construir un componente sin escribir un valor de diseño literal (Priority: P1) 🎯 MVP

**Goal**: Every color/typography/radius/spacing value used by a real widget comes from a token resolved via `BuildContext`, and a test proves no hex literal exists outside `app_colors.dart`.

**Independent Test**: Run the hex-literal scanning test; it passes against the shipped primitives and fails if a hex literal is (temporarily) added anywhere else under `lib/`.

### Tests for User Story 1

- [X] T018 [P] [US1] Create `test/core/design_system/tokens/no_raw_hex_colors_test.dart`: walk every `.dart` file under `lib/`, apply a hex-color regex (`Color\(0x[0-9A-Fa-f]{6,8}\)` and bare `#[0-9A-Fa-f]{6}` string literals), and assert the only match location is `lib/core/design_system/tokens/app_colors.dart` — verified it actually catches a violation by temporarily appending a stray hex literal to `app_card.dart` and confirming the test fails naming that exact file/line, then reverted

### Implementation for User Story 1

- [X] T019 [P] [US1] Create `lib/core/design_system/widgets/app_button.dart`: `AppButton` (`label`, `onPressed`, `variant: AppButtonVariant {primary, secondary, danger}`), wrapping `FilledButton` with `radiusPill` shape and the variant's `context.colors`/`context.typography.labelLarge` — no literal colors, styles, radii, or spacing (depends on T014, T015)
- [X] T020 [P] [US1] Create `lib/core/design_system/widgets/app_card.dart`: `AppCard` (`title`, `body`, `child`), using `context.colors.surface`/`onSurface`/`outline`, `context.spacing.radiusMd`/`spacingMd`/`spacingLg`, `context.typography.titleMedium`/`bodyMedium` (depends on T014, T015)
- [X] T021 [P] [US1] Create `lib/core/design_system/widgets/app_chip.dart`: `AppChip` (`label`, `variant: AppChipVariant {neutral, primary, secondary}`), wrapping `Chip` with `radiusPill`, `spacingXs` icon gap, `bodySmall` label, variant colors from `context.colors` (depends on T014, T015)
- [X] T022 [P] [US1] Create `lib/core/design_system/widgets/app_text_field.dart`: `AppTextField` (`label`, `hint`, `errorText`, `controller`), wrapping `TextFormField` with `radiusSm` border, `bodyMedium` input text, `bodySmall` hint/error text, all colors from `context.colors` (depends on T014, T015)

**Checkpoint**: US1 is independently functional and testable — four primitives exist, consume only tokens, and the hex-scan test proves it.

---

## Phase 4: User Story 2 - El tema permanece claro sin importar la configuración del dispositivo (Priority: P1)

**Goal**: The app's `ThemeMode` is pinned to light and never reacts to system brightness; the token architecture is proven extensible to a future dark scheme with zero widget changes.

**Independent Test**: Force `Brightness.dark` in a test `MediaQuery` and confirm rendered colors are unchanged from `Brightness.light`; separately, swap in a throwaway alternate `AppColorsExtension` instance and confirm existing primitives render its values without any primitive source file being touched.

### Tests for User Story 2

- [X] T023 [P] [US2] Create `test/core/design_system/theme_light_only_test.dart`: pump `AppButton` (and `AppCard`) inside `MediaQuery(data: MediaQueryData(platformBrightness: Brightness.dark))` and again with `Brightness.light`; assert the rendered colors are identical in both cases (depends on T019, T020)
- [X] T024 [P] [US2] Create `test/core/design_system/theme_extensibility_test.dart`: construct a second, test-only `AppColorsExtension` instance with different values for every token, build a `MaterialApp` whose `ThemeData.extensions` uses it instead of `AppColorsExtension.light`, pump all four primitives (`AppButton`, `AppCard`, `AppChip`, `AppTextField`), and assert each renders the alternate instance's values (depends on T019, T020, T021, T022)

**Checkpoint**: US2 is independently functional and testable — light mode is enforced by construction, and the dark-scheme-extensibility property (FR-007/FR-008) is proven by test.

---

## Phase 5: User Story 3 - Una persona usuaria ve la interfaz en su propio idioma (Priority: P1)

**Goal**: A primitive that renders a localized label shows the correct translation for each of the five supported locales.

**Independent Test**: Pump `AppButton` under each of `en`/`es`/`pt`/`it`/`fr` locale overrides and confirm the rendered label text matches that locale's ARB value.

### Tests for User Story 3

- [X] T025 [US3] Create `test/core/design_system/widgets/app_button_localization_test.dart`: a parameterized widget test that pumps `AppButton(label: AppLocalizations.of(context)!.commonContinue, ...)` inside a `MaterialApp` with `locale:` set to each of `en`, `es`, `pt`, `it`, `fr` in turn, and asserts the rendered text matches the corresponding `app_<locale>.arb` value (depends on T010, T019)

**Checkpoint**: US3 is independently functional and testable — localized text resolves correctly per device locale.

---

## Phase 6: User Story 4 - Una clave de traducción faltante rompe el build antes de llegar a producción (Priority: P1)

**Goal**: CI fails the moment a key exists in the template ARB but is missing, empty, or untranslated in any other locale.

**Independent Test**: Temporarily add a key to `app_en.arb` only, leave the other four files untouched, and confirm the test fails naming the missing key and locale; then revert and confirm it passes.

### Tests for User Story 4

- [X] T026 [US4] Create `test/l10n/arb_keys_complete_test.dart`: load all five `.arb` files under `lib/l10n/`, extract each file's message-key set (excluding `@@locale` and `@`-prefixed metadata entries), and assert `es`/`pt`/`it`/`fr` each contain exactly the template's key set with no empty/whitespace-only values, failing with a message naming the specific missing key and locale otherwise (depends on T005–T009) — verified it actually catches a violation by temporarily adding a key to `app_en.arb` only and confirming all four locales are reported missing it, then reverted (confirmed byte-identical via `diff`)

**Checkpoint**: All P1 stories (US1, US2, US3, US4) complete — MVP achieved. Design tokens exist and are the only source of design values, the theme is light-only and provably extensible, localization resolves per locale, and a missing translation fails the build.

---

## Phase 7: User Story 5 - Los contrastes de color se verifican por máquina, no por ojo (Priority: P2)

**Goal**: Every text/background token pair meets its WCAG AA threshold, verified by a calculated ratio, not a visual check.

**Independent Test**: Run the contrast test and confirm it reports a ratio ≥4.5:1 (normal text) or ≥3:1 (large text) for every declared pair; temporarily edit a token toward a low-contrast pairing and confirm the test fails, naming that pair.

### Tests for User Story 5

- [X] T027 [US5] Create `test/core/design_system/tokens/app_colors_contrast_test.dart`: using `test/support/wcag_contrast.dart`, enumerate every text/background pair from `data-model.md`'s color token table (`onBackground`/`background`, `onSurface`/`surface`, `onPrimary`/`primary`, `onSecondary`/`secondary`, `onDanger`/`danger`) and assert each meets its documented threshold (4.5:1 normal text, or 3:1 for the `onDanger`/`danger` large-text/UI-component pair) (depends on T011, T017) — all 5 pairs pass with the values chosen in T011 (onPrimary/onSecondary ≈4.57:1/6.55:1 reusing onSurface's dark neutral; onDanger ≈3.16:1 with white, matching the large-text-only threshold documented in data-model.md); verified the test catches a violation by temporarily swapping `danger` to the teal value (ratio drops to 1.93:1) and confirming it fails, then reverted (confirmed byte-identical via `diff`)

**Checkpoint**: US5 is independently functional and testable — contrast compliance is machine-verified.

---

## Phase 8: User Story 6 - Un componente primitivo no se rompe con la traducción más larga a escala máxima (Priority: P2)

**Goal**: Every primitive that renders text tolerates its longest translated label, across all five languages, at 200% text scale, without clipping or overflow.

**Independent Test**: Render each primitive with the longest translated label for its key at `TextScaler.linear(2.0)` and confirm no exception and no overflow error.

### Tests for User Story 6

- [X] T028 [US6] For each `common_*` key used by a primitive, compare the rendered length of its value across all five `app_*.arb` files (T005–T009) and record the longest per key as a constant (e.g. in a shared test fixture) for use by T029–T032 (depends on T005–T009) — implemented as `test/support/longest_labels.dart`'s `longestLabelFor(arbKey)`, computed dynamically from the ARB files at test time rather than hardcoded, so it stays correct if translations change
- [X] T029 [P] [US6] Add a 200%-text-scale test group to `test/core/design_system/widgets/app_button_test.dart`: wrap `AppButton` in `MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(2.0)))` with the longest label from T028, assert `tester.takeException()` is `null` and no overflow is logged (depends on T019, T028) — verified with a manual render-size probe that the button grows/fits (48×200 box, text measured 32px tall) rather than silently clipping
- [X] T030 [P] [US6] Add the equivalent 200%-text-scale test group to `test/core/design_system/widgets/app_card_test.dart` for `AppCard`'s `title`/`body` slots (depends on T020, T028)
- [X] T031 [P] [US6] Add the equivalent 200%-text-scale test group to `test/core/design_system/widgets/app_chip_test.dart` for `AppChip` — the tightest text box of the four primitives, per `data-model.md`, so the primary stress case for this story (depends on T021, T028)
- [X] T032 [P] [US6] Add the equivalent 200%-text-scale test group to `test/core/design_system/widgets/app_text_field_test.dart` for `AppTextField`'s `label`/`hint`/`errorText` (depends on T022, T028)

**Checkpoint**: US6 is independently functional and testable — every primitive survives the worst-case text-length/scale combination.

---

## Phase 9: User Story 7 - Un catálogo de golden tests detecta regresiones visuales (Priority: P3)

**Goal**: Each primitive has at least one golden test, in the light color scheme, that fails if its visual output regresses.

**Independent Test**: Change a token value a primitive consumes (e.g. `radiusMd`), run the golden tests without updating references, and confirm the affected primitive's golden test fails; revert and confirm it passes again.

### Tests for User Story 7

- [X] T033 [P] [US7] Add an `alchemist` golden test group to `test/core/design_system/widgets/app_button_test.dart` covering all three `AppButtonVariant`s in the light scheme (depends on T019) — also added `test/flutter_test_config.dart` wiring `AlchemistConfig(theme: AppTheme.light)` globally, and `dart_test.yaml` declaring the `golden` tag alchemist adds
- [X] T034 [P] [US7] Add an `alchemist` golden test group to `test/core/design_system/widgets/app_card_test.dart` covering `AppCard` with title+body and with only `child` (depends on T020)
- [X] T035 [P] [US7] Add an `alchemist` golden test group to `test/core/design_system/widgets/app_chip_test.dart` covering all three `AppChipVariant`s (depends on T021)
- [X] T036 [P] [US7] Add an `alchemist` golden test group to `test/core/design_system/widgets/app_text_field_test.dart` covering empty, filled, and `errorText`-set states (depends on T022) — first pass revealed a real bug: the default scenario column was too narrow and clipped the field's text; fixed with `scenarioConstraints: BoxConstraints.tightFor(width: 220)` since `AppTextField` is block-level and meant to fill available width, not size to content
- [X] T037 [US7] Run `flutter test --update-goldens test/core/design_system/widgets/` to generate reference PNGs under `test/core/design_system/widgets/goldens/`, then run `flutter test test/core/design_system/widgets/` unmodified to confirm they pass, and commit the images (depends on T033–T036) — visually reviewed all four generated PNGs (both `macos` and `ci` variants) to confirm correct colors/shapes/text, not just "test passed"

**Checkpoint**: All user stories complete — every primitive has committed golden coverage in the light scheme.

---

## Phase 10: Polish & Cross-Cutting Concerns

- [X] T038 [P] Run `flutter analyze` and confirm zero warnings across every file this feature added or touched — clean (0 issues); also confirmed `dart format --output=none --set-exit-if-changed lib test tool` is clean, matching the new CI job's format gate
- [X] T039 Execute `quickstart.md` end-to-end (all 9 steps, including the "temporarily break it" checks in steps 1, 4, and 6) as the final acceptance pass for this feature (depends on T018, T023, T024, T025, T026, T027, T029–T032, T037) — all 9 steps pass; full suite is 40 tests, 0 failures

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Stories (Phase 3–9)**: All depend on Foundational completion; within that constraint:
  - US1 has no dependency on any other story — it is the story that ships the four primitives themselves
  - US2, US3 depend on US1's primitives existing to have something real to render (per `research.md`'s "dark-scheme extensibility must be proven on real primitives, not a fake test widget" reasoning) — they add tests, not new widgets
  - US4 depends only on Foundational (the ARB files) — fully independent of US1–US3
  - US5 depends only on Foundational (`app_colors.dart`, `wcag_contrast.dart`) — fully independent of US1–US4
  - US6, US7 depend on all four primitives (US1) and, for US6, on the ARB files (Foundational) — both extend the same per-primitive test files, so their tasks touch files US1 already created
- **Polish (Phase 10)**: Depends on all seven user stories being complete

### Within Each User Story

- US1: four primitives in parallel (different files) + the hex-scan test in parallel with them
- US2: both tests depend on US1's primitives; the two tests themselves are independent of each other
- US3: single test, depends on US1's `AppButton` and Foundational's generated `AppLocalizations`
- US4: single test, depends only on Foundational's five ARB files
- US5: single test, depends on Foundational's `app_colors.dart` and `wcag_contrast.dart`
- US6: longest-label measurement first, then four per-primitive test additions in parallel
- US7: four per-primitive golden test additions in parallel, then one `--update-goldens` run to generate and commit images

### Parallel Opportunities

- Setup: T002, T003 in parallel (T004 has no file overlap with either, also parallelizable)
- Foundational: T005–T009 (five ARB files) in parallel once T005 fixes the key list; T011/T012/T013 (three token files) in parallel; T015 in parallel with T014 (both depend on T011–T013 but not on each other)
- Once Foundational completes: US1, US4, and US5 can be staffed and worked in parallel (US2, US3, US6, US7 wait on US1's primitives)
- Within US1: T019–T022 (all four primitives) in parallel; T018 (hex-scan test) in parallel with all of them
- Within US6: T029–T032 (four primitives' 200%-scale tests) in parallel after T028
- Within US7: T033–T036 (four primitives' golden tests) in parallel; T037 waits for all four

---

## Parallel Example: Foundational Phase

```bash
# Launch the three token files together:
Task: "Create AppColorsExtension in lib/core/design_system/tokens/app_colors.dart"
Task: "Create AppTypographyExtension in lib/core/design_system/tokens/app_typography.dart"
Task: "Create AppSpacingExtension in lib/core/design_system/tokens/app_spacing.dart"

# Launch the four locale ARB files together (after app_en.arb fixes the key list):
Task: "Create lib/l10n/app_es.arb"
Task: "Create lib/l10n/app_pt.arb"
Task: "Create lib/l10n/app_it.arb"
Task: "Create lib/l10n/app_fr.arb"
```

## Parallel Example: User Story 1

```bash
# Launch all four primitives together:
Task: "Create AppButton in lib/core/design_system/widgets/app_button.dart"
Task: "Create AppCard in lib/core/design_system/widgets/app_card.dart"
Task: "Create AppChip in lib/core/design_system/widgets/app_chip.dart"
Task: "Create AppTextField in lib/core/design_system/widgets/app_text_field.dart"

# Launch the verification test alongside them:
Task: "Create no_raw_hex_colors_test.dart"
```

---

## Implementation Strategy

### MVP First (User Stories 1, 2, 3, and 4 — all P1)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks everything)
3. Complete Phase 3 (US1) — this ships the four primitives and proves token-only consumption
4. Complete Phase 4 (US2), Phase 5 (US3), Phase 6 (US4) — these three add verification on top of US1's output and are independent of each other
5. **STOP and VALIDATE**: run `quickstart.md` steps 1–6
6. This is the MVP — Principle 9's core guarantee (token-only design, five-language localization, CI-enforced translation completeness) is in place

### Incremental Delivery

1. Setup + Foundational → foundation ready
2. US1 → primitives exist, token-only, hex-scan passes → verify independently
3. US2 → light-only + dark-extensibility proven → verify independently
4. US3 → per-locale text resolution proven → verify independently
5. US4 → CI catches a missing key → verify independently → **MVP complete**
6. US5 → contrast compliance machine-verified
7. US6 → 200%-scale/longest-label survival proven
8. US7 → golden coverage in place
9. Polish → final full quickstart pass

### Parallel Team Strategy

With multiple developers, after Foundational completes:
- Developer A: US1 (primitives), then US2 and US3 (both need US1's output)
- Developer B: US4 (fully independent — ARB completeness only)
- Developer C: US5 (fully independent — token contrast only)
- Developer D: US6 then US7 (both need US1's primitives; naturally follow Developer A's work)

---

## Notes

- [P] tasks touch different files and have no dependency on an incomplete task
- [Story] labels map every user-story-phase task back to spec.md for traceability
- No task in Setup, Foundational, or Polish carries a [Story] label, per the checklist format rules
- US2/US6/US7 tasks that extend a test file US1 already created (e.g. `app_button_test.dart`) are correctly unmarked `[P]` relative to each other when they share a file, even across different story phases
- T004 (GitHub Actions CI) closes a gap left over from `001-environment-foundation`/`docs/ROADMAP.md` Phase 0, which named "CI on GitHub Actions: analyze, test, build both flavors" but did not ship it — this feature's own FR-012/SC-006 require a real CI failure, so the pipeline is created here rather than assumed
- Commit after each task or logical group; stop at any checkpoint to validate a story independently before moving on
- No task in this list touches Firestore, Security Rules, or any cloud project — nothing here needs the human-confirmation gates `001-environment-foundation`'s tasks required
