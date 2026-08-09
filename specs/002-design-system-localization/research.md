# Phase 0 Research: Design System & Localization Foundation

No `NEEDS CLARIFICATION` markers remained in the Technical Context — `docs/UI_UX_SPEC.md` §1/§7,
`docs/TECH_STACK.md`, and Constitution Principles 8/9 already fix the framework, dependency, and
platform choices. What they leave open is *structural*: how tokens are shaped as Dart types, which
concrete primitives to build, how the "no hex outside `app_colors.dart`" and "no missing ARB key"
rules get enforced by a machine instead of a code reviewer's eyes, and how to prove the
zero-widget-change dark-scheme claim (spec FR-007/FR-008) without shipping a dark scheme. This
document records those decisions.

## Decision: Three `ThemeExtension` subclasses, one per token file, resolved via `BuildContext` getters

**Decision**: `AppColorsExtension`, `AppTypographyExtension`, and `AppSpacingExtension` (the last
one carrying both spacing *and* radius fields — Principle 9 groups them into a single file,
`app_spacing.dart`) are each a `ThemeExtension<T>` registered in `ThemeData.extensions`. A single
`lib/core/design_system/theme/design_tokens.dart` defines `BuildContext` getters —
`context.colors`, `context.typography`, `context.spacing` — that call
`Theme.of(this).extension<T>()!`. Primitives call only these getters, never `Theme.of(context)`
directly and never the token classes' constructors.

**Rationale**: `ThemeExtension` is Flutter's own mechanism for typed, theme-scoped custom tokens,
already assumed by spec FR-001 ("tokens semánticos resueltos desde el `BuildContext` vía
`ThemeExtension`"). Three separate classes — rather than one large `AppDesignTokens` extension —
mirror the three files the constitution names explicitly and let each token family evolve (or grow
a second instance, for a future dark scheme) independently. Grouping radius with spacing in
`AppSpacingExtension` matches the constitution's own file grouping instead of inventing a fourth
file it doesn't mention.

**Alternatives considered**:
- *One monolithic `ThemeExtension` for everything* — rejected: it would not map cleanly onto the
  three-file split the constitution names, and a future dark scheme would need to redeclare
  typography/spacing fields that don't actually change between light and dark just to override the
  few color fields that do.
- *Plain `InheritedWidget` instead of `ThemeExtension`* — rejected: `ThemeExtension` is already the
  idiomatic Flutter/Material 3 mechanism for this (composes with `ThemeData.extensions`,
  `copyWith`/`lerp` support for free), and the spec names it explicitly.

## Decision: Typography tokens carry no color; color is applied at the call site from `AppColorsExtension`

**Decision**: Every `TextStyle` in `AppTypographyExtension` sets font family, weight, size,
letter-spacing, and height — never `color`. A widget that needs colored text combines the two
token families explicitly: `Text(label, style: context.typography.labelLarge.copyWith(color:
context.colors.onPrimary))`.

**Rationale**: FR-001 requires every *color* to come from a token resolved via `ThemeExtension`. If
`AppTypographyExtension` baked in a color, that literal would either have to duplicate a value from
`app_colors.dart` (two sources of truth for the same color) or `app_typography.dart` would need to
import `app_colors.dart`'s palette — but that palette is intentionally library-private (see next
decision), so it can't be imported at all. Keeping typography shape-only and color paint-only keeps
each token file owning exactly one concern, and it mirrors how Material's own `TextTheme` is
usually combined with `ColorScheme` at the call site.

**Alternatives considered**:
- *Bake a default color into each `TextStyle`* — rejected for the reason above; it also would have
  made the "add a dark scheme without touching widgets" property (FR-007) harder, since a widget
  using an uncolored style automatically picks up the new scheme's color when only
  `AppColorsExtension` changes, whereas a colored style would need updating by hand.

## Decision: The raw hex palette in `app_colors.dart` is library-private; a scanning test is the backstop

**Decision**: `app_colors.dart` declares its literal `Color(0xFF...)` values as top-level `const`
identifiers prefixed with `_` (e.g. `const _coral = Color(0xFFFF6B6B);`), so Dart's own library
privacy makes them physically unimportable from any other file. The same file also builds and
exports the public `AppColorsExtension` instance (`AppColorsExtension.light`) from those private
constants. On top of that, `test/core/design_system/tokens/no_raw_hex_colors_test.dart` walks every
`.dart` file under `lib/`, applies a hex-color regex (`Color\(0x[0-9A-Fa-f]{6,8}\)` and bare
`#[0-9A-Fa-f]{6}` string literals), and fails if any match is found outside
`lib/core/design_system/tokens/app_colors.dart`.

**Rationale**: Spec FR-002/FR-003 ask for "a lint or test" that fails the build on a stray hex
literal. A `custom_lint` rule would need its own analyzer-plugin package and registration — real
infrastructure for a check a 40-line test performs just as reliably, running under the same `flutter
test` command CI already runs. Library privacy is the stronger of the two guards (it's a compile
error, not a lint you could silence with a comment) and is free; the scanning test exists as a
backstop for the case privacy can't catch — someone defining a *new* hex constant in a different
file rather than trying to reach into `app_colors.dart`'s private ones.

**Alternatives considered**:
- *A `custom_lint` rule* — rejected for this feature: heavier to build and maintain than the test
  above for an equivalent guarantee, and `custom_lint`/`riverpod_lint` are reserved in
  `docs/TECH_STACK.md` for Riverpod-specific lints, not general source scanning.
  Revisit only if more scanning rules accumulate later and justify shared lint infrastructure.
- *Rely on code review alone* — rejected: Principle 9 explicitly asks for a machine-verified
  guarantee, not a review convention.

## Decision: WCAG contrast is a small pure-Dart function, tested directly — no external package

**Decision**: `test/support/wcag_contrast.dart` implements the WCAG 2.x relative-luminance and
contrast-ratio formulas (`relativeLuminance(Color)`, `contrastRatio(Color, Color)`) as pure
functions. `test/core/design_system/tokens/app_colors_contrast_test.dart` enumerates every
text/background pair the token contract declares (see `data-model.md`) and asserts each ratio meets
4.5:1 (normal text) or 3:1 (large text / non-text UI components), per the pair's documented usage.

**Rationale**: The WCAG contrast formula is ~15 lines of arithmetic with no meaningful package
ecosystem advantage over hand-rolling it (pulling a dependency for it would be the kind of
unnecessary abstraction the project avoids elsewhere). Keeping it under `test/support/` rather than
`lib/` is deliberate: nothing at runtime needs to *compute* a contrast ratio — only the test suite
that verifies the token contract does — so it doesn't belong in the shipped app.

**Alternatives considered**:
- *A pub.dev contrast-checking package* — rejected: none is part of the already-approved stack in
  `docs/TECH_STACK.md`, and the formula is short enough that a dependency buys little.
- *Manual/visual contrast inspection* — explicitly rejected by spec FR-009 and SC-004.

## Decision: `alchemist` for golden tests, not `golden_toolkit`

**Decision**: The dev dependency for golden testing is `alchemist`. Golden tests run in "CI mode"
(font rendering forced to a deterministic fallback), so the images committed to the repo and
compared in CI don't depend on which OS/font-rendering stack generated them.

**Rationale**: `docs/TECH_STACK.md` lists `golden_toolkit` OR `alchemist` as options. Golden image
pixels are sensitive to the host's font-rasterization engine, which differs between the macOS
machines developers use locally and the Linux CI runners `docs/TECH_STACK.md`'s GitHub Actions
pipeline runs on — the single largest source of "golden test fails only in CI" flakiness. Alchemist
addresses this directly with a CI-specific golden mode (deterministic font fallback) built for
exactly this dev-on-Mac / CI-on-Linux split, and is the actively maintained option of the two named
in `docs/TECH_STACK.md` as of this writing.

**Alternatives considered**:
- *`golden_toolkit`* — rejected: effectively unmaintained, and doesn't provide an equivalent to
  alchemist's CI-only deterministic-font mode, which is exactly the failure mode this project would
  hit first (developers on macOS, CI on Linux runners per `docs/TECH_STACK.md`'s CI/CD section).

**Implementation-time correction**: the "CI mode" ("deterministic font fallback") turned out not to
mean *pixel-identical across host OSes*, only *independent of which font the host has installed*.
Real CI runs (`ubuntu-latest`) failed against `ci/*.png` references generated on a macOS laptop,
because Skia still rasterizes shapes, borders, and shadows with slightly different antialiasing
between macOS and Linux even with text blocked out — the same class of problem alchemist's CI mode
solves for *text*, just not for everything else. Two changes fixed this:

1. `PlatformGoldensConfig` defaults to running the human-readable "platform" variant on
   *every* host OS (`HostPlatform.values`), not just the one that generated the reference image —
   restricted to `{HostPlatform.macOS}` in `test/flutter_test_config.dart`, since only a macOS
   reference is committed.
2. Both golden variants are now mutually exclusive by environment, gated on the `CI` environment
   variable GitHub Actions sets automatically (`Platform.environment.containsKey('CI')`): locally,
   only the "platform" (macOS, human-readable) variant runs and is compared; in CI, only the "ci"
   (Ahem-font, obscured-text) variant runs, compared against reference images generated from an
   actual `ubuntu-latest` run of `flutter test --update-goldens` (via a temporary CI job, downloaded
   and committed, then removed). Each variant is therefore only ever compared against a reference
   generated on the same OS that renders it — the general rule for golden testing on any framework,
   which this project's original setup violated by assuming alchemist's CI mode was exempt from it.

## Decision: ARB key completeness is enforced by a dedicated test, not by `gen_l10n` alone

**Decision**: `test/l10n/arb_keys_complete_test.dart` loads every `.arb` file under `lib/l10n/`,
extracts the message-key set from each (excluding `@@locale` and `@`-prefixed metadata entries),
and asserts that `es`, `pt`, `it`, and `fr` each contain the exact key set of the template
(`app_en.arb`), with no key mapping to an empty or whitespace-only string. This test runs as part
of the same `flutter test` invocation CI already runs on every pull request.

**Rationale**: Flutter's built-in `gen_l10n` tool does not fail the build on a missing translation
by default — it falls back silently to the template locale's string and, at most, emits a warning.
That satisfies neither FR-012 nor SC-006 ("a PR that adds a key only to the template ARB fails
CI"). A dedicated key-diff test is a few lines of `dart:convert` JSON parsing and set comparison,
requires no `gen_l10n` flag research/fragility, and produces a precise failure message naming the
missing key and locale.

**Alternatives considered**:
- *`gen_l10n --no-suppress-warnings` piped into a CI step that greps for "warning"* — rejected:
  couples CI correctness to log-message text, which is fragile and invisible to anyone running
  `flutter test` locally.
- *A dart script run as a separate CI step, outside `flutter test`* — rejected: keeping it as a
  `flutter test` test means it also runs (and protects) locally before every push, not only in CI.

## Decision: `google_fonts` package, self-hosted (bundled) — Nunito as the chosen family

**Decision**: Typography uses the `google_fonts` package (already named in `docs/TECH_STACK.md`),
configured for self-hosting: `GoogleFonts.config.allowRuntimeFetching = false` is set during
`bootstrap()`, and the Nunito `.ttf` files it needs are committed under `assets/fonts/` and
declared in `pubspec.yaml`'s `fonts:` section, so `GoogleFonts.nunito(...)` resolves from the
bundled asset instead of attempting a network fetch. Nunito is the family chosen from the three
`docs/UI_UX_SPEC.md` offers (Nunito, Quicksand, Fredoka).

**Rationale**: `docs/UI_UX_SPEC.md` §1 requires the font be "bundled as an asset... so the first
frame never waits on a network request" and names three candidates without picking one; a decision
has to be made to build anything. Nunito is chosen because it ships true tabular-figure digit
support (needed later for the keypad's amount display per §2, even though the keypad itself is out
of scope here) and full Latin Extended coverage for the accented characters French and Portuguese
need, while remaining the most neutral/legible of the three for body text at small sizes — Fredoka
and Quicksand both lean more decorative, better suited to display-only text than to body copy a
five-language app will render at every size.

**Alternatives considered**:
- *Quicksand or Fredoka* — not rejected outright (either could serve as a future *display*-only
  accent face on top of Nunito for body text), but out of scope: this feature needs one committed
  family to build the typography token set against, and Nunito alone satisfies every primitive this
  feature ships.
- *Plain bundled TTF via `pubspec.yaml`'s `fonts:` section, skipping the `google_fonts` package
  entirely* — rejected: it would work, but `docs/TECH_STACK.md` already names `google_fonts` as the
  chosen package; deviating from it needs its own justification this feature has no reason to make.

**Implementation-time refinement**: Nunito is published upstream (the `google/fonts` repository)
only as a variable font — there is no static per-weight `.ttf` for the `google_fonts` package's
self-hosting file matcher (`findFamilyWithVariantAssetPath`) to find, since it looks for filenames
like `Nunito-Regular.ttf`/`Nunito-Bold.ttf` specifically. `app_typography.dart` therefore builds
`TextStyle`s with `fontFamily: 'Nunito'` directly (Flutter's standard, officially documented way to
consume a variable font registered under one family with multiple `weight:` pubspec entries
pointing at the same file — see `pubspec.yaml`), rather than calling `GoogleFonts.nunito(...)`. The
`google_fonts` dependency and the `GoogleFonts.config.allowRuntimeFetching = false` guard in
`bootstrap()` are kept regardless, both because `docs/TECH_STACK.md` names the package and as a
defensive guard against any future call to `GoogleFonts.*` accidentally attempting a network fetch.

## Decision: Primitives are token-themed Material 3 widgets, not custom-painted from scratch

**Decision**: The four primitives this feature ships — `AppButton`, `AppCard`, `AppChip`,
`AppTextField` — are thin wrappers around Material 3 widgets (`FilledButton`/`OutlinedButton`,
`Card`, `Chip`/`InputChip`, `TextFormField`) restyled entirely from `context.colors` /
`context.typography` / `context.spacing`, not `CustomPaint`/`Canvas` reimplementations.

**Rationale**: Material 3 widgets already provide correct semantics (screen-reader labels, focus
traversal), minimum-interactive-area handling, and platform-appropriate ripple/press feedback —
exactly the accessibility groundwork Principle 8 requires — for free. Reimplementing that from
`CustomPaint` would be real, unjustified complexity for a feature whose job is proving the token
pipeline works, not inventing new interaction primitives. `docs/TECH_STACK.md` already commits to
"Material 3 with a fully customized `ThemeData`" as the UI foundation.

**Alternatives considered**:
- *Fully custom-painted primitives* — rejected as premature complexity; nothing in this feature's
  acceptance criteria requires bespoke rendering, and the "soft, tactile bubble" press-compression
  animation `docs/UI_UX_SPEC.md` §2 describes is scoped to the keypad specifically, which is out of
  scope here.

## Decision: Dark-scheme extensibility (FR-007/FR-008) is proven with a test-only alternate token instance

**Decision**: `test/core/design_system/theme_extensibility_test.dart` constructs a second
`AppColorsExtension` instance with different (test-only, throwaway) values, builds a `MaterialApp`
whose `ThemeData.extensions` uses that instance instead of `AppColorsExtension.light`, pumps each of
the four shipped primitives inside it, and asserts the rendered colors match the alternate
instance's values — without importing, subclassing, or modifying any primitive's source file.

**Rationale**: Spec FR-007 requires that adding a full dark scheme later needs "no widget
modification," and FR-008 requires the spec to describe how that's verified. Actually shipping a
second, real dark `AppColorsExtension` is explicitly out of scope (per the feature's Out-of-Scope
list), so the test proves the *architectural property* — primitives read colors exclusively through
`context.colors`, never a concrete value — using a disposable test instance instead of a real dark
palette. If this test ever needed to touch a primitive's source to pass, that would be the signal
the architecture failed FR-007, which is exactly the failure mode it's designed to catch.

**Alternatives considered**:
- *Ship a real (unused) second `AppColorsExtension` for "dark" now* — rejected: the feature's
  Out-of-Scope section explicitly excludes the dark color scheme; a real second scheme with no way
  to activate it would be dead code shipped for a test that a throwaway instance already covers.
- *Static analysis (grep widgets for `Color(0x` literals)* — this is already `no_raw_hex_colors_test`
  from an earlier decision above; it proves widgets contain no hardcoded colors, but not that they
  *respond correctly* to a swapped token instance. Both tests are needed; they check different
  things.

## Decision: `flutter_localizations` + `gen_l10n`, generated output committed (not a synthetic package)

**Decision**: `l10n.yaml` at the repo root sets `arb-dir: lib/l10n`, `template-arb-file:
app_en.arb`, `output-class: AppLocalizations`, `output-dir: lib/l10n/generated`, and
`synthetic-package: false`. The generated `app_localizations*.dart` files under
`lib/l10n/generated/` are committed, matching this project's existing convention (per
`docs/TECH_STACK.md`'s Development Standards: "`build_runner` output is committed") extended to
`gen_l10n`'s generator.

**Rationale**: `docs/TECH_STACK.md` already names `flutter_localizations` + `gen_l10n` with ARB
files and `en`/`es`/`pt`/`it`/`fr` support; the only open question was the synthetic-package
default. Committing generated output (rather than relying on the synthetic package Flutter
generates into `.dart_tool/`) keeps this generator consistent with how `build_runner` output is
already handled in this repo, and makes `AppLocalizations` importable with a normal, IDE-navigable
path instead of the synthetic package's opaque one.

**Alternatives considered**:
- *Leave `synthetic-package: true` (the Flutter default)* — rejected only for consistency with the
  project's existing "generated code is committed" convention; both approaches work functionally.
