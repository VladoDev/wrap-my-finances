# Governance Checklist: Principle 9 — Localized and Consistent by Construction

**Purpose**: Validate the quality, completeness, and cross-document consistency of Constitution
Principle 9's requirements — not whether any code implements them yet. This checks whether the
principle itself, and the docs it depends on (`docs/UI_UX_SPEC.md`, `docs/TECH_STACK.md`,
`docs/ARCHITECTURE.md`, `docs/DATA_MODEL.md`, `docs/ROADMAP.md`), are unambiguous, internally
consistent, and complete enough for a future `/speckit.plan` to act on without guessing.

**Created**: 2026-08-08

**Feature**: [`.specify/memory/constitution.md` §Principle 9](../constitution.md)

**Note**: This is a governance checklist, not a feature checklist — it is scoped to the
constitution amendment and its supporting docs, not to `specs/001-environment-foundation/`, which
has no localization or design-system surface.

## Requirement Completeness

- [ ] CHK001 - Does Principle 9 (or a referenced doc) specify what happens when a string is needed
      before the localization class can resolve it (e.g., a crash-handler message shown before
      `configureDependencies`/locale resolution completes)? [Gap]
- [ ] CHK002 - Is the ARB template locale's review/approval process defined (who writes the source
      English string before translation)? [Gap]
- [ ] CHK003 - Does any doc specify how pluralization and gender agreement (relevant for Spanish,
      Portuguese, Italian, French) are to be authored in ARB files? [Gap]
- [ ] CHK004 - Is the process for translating a *new* key documented (e.g., must all 5 locales be
      filled in the same PR, or is a placeholder/fallback strategy allowed pre-merge)? [Gap,
      Constitution §P9]
- [ ] CHK005 - Does `docs/ARCHITECTURE.md`'s canonical directory structure show where generated
      localization code and ARB source files live? [Gap — not present in the tree as of this
      amendment, Architecture §Directory Structure]
- [ ] CHK006 - Is there a requirement covering RTL layout, or is RTL explicitly declared out of
      scope given the five supported locales are all LTR? [Gap]

## Requirement Clarity

- [ ] CHK007 - Is "complete translations" in Principle 9 quantified (100% of keys, or is a
      tolerance defined for in-flight features)? [Ambiguity, Constitution §P9]
- [ ] CHK008 - Is "consistent" in the design-system half of Principle 9 defined with a concrete
      check (e.g., a lint rule name), or only as a prose intent? [Ambiguity, Constitution §P9]
- [ ] CHK009 - Does the principle distinguish between a hex value appearing in a *test fixture or
      golden test* versus in shipped widget code, or does the "no hex outside app_colors.dart"
      rule apply uniformly to all Dart files including tests? [Ambiguity, Constitution §P9]
- [ ] CHK010 - Is "ad hoc" `TextStyle` construction precisely bounded — does copying a style from
      `app_typography.dart` and applying `.copyWith()` for a one-off weight change count as
      compliant or as a violation? [Ambiguity, Constitution §P9]

## Requirement Consistency

- [ ] CHK011 - Does `docs/DATA_MODEL.md`'s Category Document schema conflict with Principle 9's
      "default categories are stored with a translation key, not a literal name" rule? [Conflict —
      the current example document stores `"name": "Food & Dining"` as literal text with
      `isDefault: true`, Data-Model §Category Document, Constitution §P9]
- [ ] CHK012 - Does `docs/DATA_MODEL.md` define a field (e.g., `nameKey` vs `name`) that
      distinguishes a default category's translation key from a user-created category's literal
      name, consistent with Principle 9's split? [Gap, Constitution §P9]
- [ ] CHK013 - Is the "no raw hex outside `app_colors.dart`" rule already stated in
      `docs/UI_UX_SPEC.md` (§Color) fully consistent with Principle 9's broader "no hex value may
      appear outside `app_colors.dart`" — i.e., does UI_UX_SPEC's version implicitly scope this to
      color tokens only, while Principle 9 states it as an absolute for the whole codebase? Confirm
      both are read as the same rule. [Consistency, UI_UX_SPEC §Color, Constitution §P9]
- [ ] CHK014 - `docs/UI_UX_SPEC.md` §7 "Layout under translation" already requires content-sized
      pill buttons and two-line wrapping for translated text — does this fully satisfy Principle
      9's "layouts MUST tolerate text expansion without clipping or overflowing," or does the
      constitution impose a stricter/broader bar (e.g., covering the Wrapped story cards, not just
      pills and category tiles)? [Consistency, UI_UX_SPEC §7, Constitution §P9]
- [ ] CHK015 - `docs/ROADMAP.md` Phase 1 lists "Setup l10n.yaml and l10n.arb files" alongside the
      Design System task — does Principle 9's "before a feature is considered done" bar apply
      retroactively to Phase 1 as a whole, or only to features specified after this amendment's
      ratification date? [Ambiguity, Constitution §P9, Roadmap §Phase 1]

## Acceptance Criteria Quality

- [ ] CHK016 - Is "a missing key in any locale is a CI failure" measurable/verifiable as stated —
      does it name (or defer to a follow-up) the specific check that will enforce it, given CI
      itself is not yet implemented per this amendment's Sync Impact Report? [Measurability,
      Constitution §P9]
- [ ] CHK017 - Can "text expansion without clipping or overflowing" be objectively verified, or
      does it need a concrete test method (e.g., pseudo-locale/longest-string golden tests) named
      somewhere before a feature can claim compliance? [Measurability, Constitution §P9,
      UI_UX_SPEC §7]
- [ ] CHK018 - Is there a defined acceptance check for "no hex value outside app_colors.dart" (e.g.,
      a custom lint rule or a grep-based CI step), or does compliance currently rely on manual code
      review only? [Gap, Traceability]

## Scenario Coverage

- [ ] CHK019 - Are requirements defined for the scenario where a user's device locale is one of the
      5 supported languages but the OS reports a regional variant not explicitly listed (e.g.,
      `pt-PT` vs `pt-BR`, `fr-CA` vs `fr-FR`)? [Coverage, Gap]
- [ ] CHK020 - Are requirements defined for a locale change *while the app is running* (e.g., user
      changes system language mid-session) — does the UI need to react live, or is a restart
      acceptable? [Coverage, Gap]
- [ ] CHK021 - Are requirements defined for how a user-created category's literal name (which has
      no translation) is displayed to a user running the app in a *different* locale than the one
      it was created in? [Coverage, Gap, Constitution §P9]
- [ ] CHK022 - Does any doc address whether the Wrapped shareable card (rasterized to an image, per
      `docs/TECH_STACK.md` §UI) is subject to the same design-token and translation-length rules,
      given it is a rendered artifact rather than a live widget tree? [Coverage, Gap]

## Edge Case Coverage

- [ ] CHK023 - Is the behavior specified when a translation string contains user-supplied
      interpolation (e.g., a formatted amount or date inside a translated sentence) — does the
      interpolation itself still have to go through `intl` formatting rather than string
      concatenation, and is that explicit rather than implied? [Edge Case, Constitution §P9]
- [ ] CHK024 - Is there a stated fallback when a locale's translation is present but a specific
      plural/gender form is missing (partial-key rather than whole-key gap)? [Edge Case, Gap]

## Dependencies & Assumptions

- [ ] CHK025 - Is the assumption that `flutter_localizations` + `gen_l10n` (named in
      `docs/TECH_STACK.md` §Localization) is the only mechanism for satisfying Principle 9 made
      explicit, ruling out ad hoc translation maps as a non-compliant alternative? [Assumption,
      TECH_STACK §Localization, Constitution §P9]
- [ ] CHK026 - Is the dependency between Principle 9's CI gate and the not-yet-implemented CI
      pipeline (per `docs/TECH_STACK.md` §CI/CD and this amendment's Sync Impact Report) tracked
      anywhere as a blocking prerequisite, so it isn't silently dropped when CI is finally set up?
      [Dependency, Gap]

## Ambiguities & Conflicts Requiring Resolution

- [ ] CHK027 - Is a requirement & acceptance-criteria ID scheme established for constitution
      principles themselves (e.g., "P9-R1", "P9-AC1"), so future specs can cite exactly which
      clause of Principle 9 they satisfy, the way `[Spec §FR-001]` works for feature specs?
      [Traceability, Gap]

## Notes

- CHK011 is the most consequential finding: `docs/DATA_MODEL.md`'s existing Category Document
  schema was written before Principle 9 existed and directly contradicts it. Resolve before any
  categories feature is specified — either amend `DATA_MODEL.md` (adding a `nameKey`/`name` split)
  or narrow Principle 9's category clause, per the constitution's own amendment procedure.
- CHK005 and CHK015 point at the same root cause: ARCHITECTURE.md and ROADMAP.md predate this
  amendment and haven't been reconciled with it yet. The constitution's own Governance section
  requires updating every contradicting `/docs` file "in the same commit" as the amendment — this
  checklist is evidence that step is still outstanding for this amendment.
- Check items off as findings are resolved (update the referenced doc, or accept the ambiguity and
  narrow the principle's wording in a follow-up PATCH amendment).
