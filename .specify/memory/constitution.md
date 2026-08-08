<!--
Sync Impact Report — Constitution Amendment
Version change: 1.0.0 → 1.1.0 (MINOR — new principle added, no existing principle redefined)
Modified principles: none renamed or redefined
Added sections:
  - Principle 9: Localized and Consistent by Construction
Removed sections: none
Templates/docs requiring follow-up (not modified by this command — out of scope for
/speckit.constitution; track as separate work):
  - docs/UI_UX_SPEC.md: confirm app_colors.dart / app_typography.dart / app_spacing.dart token
    files are named and scoped exactly as Principle 9 assumes.
  - docs/TECH_STACK.md: already lists `intl` for locale-aware formatting; no contradiction found.
  - CI configuration: add the "missing ARB key fails the build" check described in Principle 9
    once CI is set up (tracked in ROADMAP.md Phase 0, not yet implemented as of this amendment).
Deferred TODOs: none
-->

# Wrap My Finances Constitution

Wrap My Finances is a mobile expense tracker whose entire product thesis is that logging a
purchase must take under three seconds and must never fail. Its mission is to make financial
awareness a reflex rather than a chore, and to reward consistency with a monthly, shareable,
animated summary.

This document is the source of law for the project. Every feature specification, implementation
plan, and task list is checked against it. Where this document and any other document in `/docs`
disagree, this document wins and the other is corrected.

---

## Core Principles

### Principle 1: The Logging Path Is Sacred

**Rule**: Logging an expense MUST take at most two taps after the amount is entered, and MUST
complete in under 3 seconds at p90 measured from app open to local persistence. The app MUST
open directly to the numeric keypad. No feature may add a screen, a dialog, a confirmation, a
spinner, or a network wait to this path. Any change that raises the measured time-to-log is
rejected, regardless of the value it adds elsewhere.

**Rationale**: Users abandon budgeting apps because logging is tedious, not because reports are
bad. Every other feature in this product is worthless if the data never gets entered. This is the
one constraint that cannot be traded away, so it is stated first and enforced hardest.

### Principle 2: Offline-First, Always

**Rule**: Every user-initiated write MUST succeed with no network connection and reconcile
later. Document IDs MUST be generated client-side. The UI MUST NOT await server acknowledgement
before confirming success to the user. No query used on the logging or timeline path may depend
on `FieldValue.serverTimestamp()` for ordering or grouping, because it reads back as `null` from
the local cache. Network failure is the normal case here, not an error state.

**Rationale**: The 3-second promise cannot be kept over a cellular connection in a restaurant
basement. Offline-first is not a resilience feature; it is the mechanism by which Principle 1 is
achievable at all.

### Principle 3: Anti-Goals Are Binding

**Rule**: The following are OUT OF SCOPE and MUST NOT be specified, planned, or implemented
without a documented amendment to this constitution: income tracking, debt tracking, split bills,
bank API integrations, budget limits, recurring expenses, receipt capture or OCR, multi-currency
conversion, dashboards on the launch screen, web or desktop targets, a third environment, and a
local SQL database alongside the Firestore cache.

Anonymous authentication is NOT an anti-goal. "No mandatory account creation" means the user is
never asked to sign up; it does not mean the app is unauthenticated.

**Rationale**: A short list of things a product refuses to do is worth more than a long list of
things it does. Feature creep is the specific failure mode this project is most exposed to,
because every excluded feature is individually reasonable.

### Principle 4: Layer Boundaries Are Enforced

**Rule**: The codebase follows feature-first Clean Architecture. `domain/` MUST NOT import
Flutter, Firebase, or `data/`. `presentation/` MUST NOT import `data/`. Features MUST NOT import
each other's internals — only another feature's `domain/` repository interfaces. `core/` MUST NOT
import from `features/`. No exception crosses a layer boundary; failures are values
(`Result<T>` over a sealed `Failure`), not thrown.

Riverpod owns reactive state; GetIt/Injectable owns infrastructure construction. Widgets MUST NOT
reference `getIt` directly. If this boundary starts leaking, the remedy is to remove GetIt, never
to add a third pattern.

**Rationale**: A domain layer that can be unit-tested with zero setup is the entire return on the
cost of this architecture. One import of `cloud_firestore` into `domain/` forfeits it.

### Principle 5: Money Is Exact and Private

**Rule**: Monetary values MUST be stored and computed as integer minor units, never as
floating-point. Amounts MUST be formatted for display only at the presentation layer.

No analytics or telemetry event may ever carry a monetary amount, an expense note, or a
user-authored category name. Events carry counts, durations, and enum identifiers only.
Crashlytics reports only genuinely unexpected failures; an offline user is not a crash.

**Rationale**: `0.1 + 0.2 != 0.3`, and rounding drift in a spending total is both incorrect and
visibly incorrect to the user. Separately, spending data is among the most sensitive data a
person holds; shipping it to an analytics pipeline is a betrayal that no product metric justifies.

### Principle 6: Environments Are Isolated and Symmetric

**Rule**: The project ships exactly two flavors, `dev` and `prod`, each bound to its own Firebase
project. Test or seed data MUST NEVER be written to the production project. Both environments MUST
deploy the same Security Rules and indexes from the same files — divergence is a defect, because
it means `dev` has stopped rehearsing `prod`. Prod builds MUST contain no debug affordance: no
environment label, no developer menu, no seed button. Every build command that passes `--flavor`
MUST also pass `-t`; `lib/main.dart` does not exist so that omitting it fails loudly.

**Rationale**: The `applicationId` is immutable after first store submission and a polluted
production dataset cannot be cleanly separated after the fact. Both mistakes are cheap to prevent
in Phase 0 and expensive to correct at any later point.

### Principle 7: Security Rules Are the Only Real Boundary

**Rule**: Firestore Security Rules MUST validate ownership, field presence, types, and ranges
server-side. Client-side validation is a UX affordance and carries no security weight. Rules MUST
end with a catch-all denying everything not explicitly matched. Rules MUST have an automated test
suite run in CI on every pull request, covering at minimum cross-user read denial, invalid amount
rejection, and unauthenticated access denial.

**Rationale**: Rules are the only thing standing between one user's spending history and
another's. Anything verified by hand-clicking a console is unverified.

### Principle 8: Accessible by Construction

**Rule**: Minimum tap target 48×48 dp. WCAG AA contrast on all text. Color MUST NOT be the only
carrier of meaning. Text MUST scale to 200% without clipping. All motion MUST collapse to
cross-fades when the platform reduce-motion setting is enabled. Icon-only controls MUST carry
semantic labels.

**Rationale**: The "Modern Playful" aesthetic pulls toward pastel-on-pastel and color-coded
categories, which are precisely the two most common accessibility failures. Naming them here is
what prevents the aesthetic from producing them. Retrofitting accessibility costs several times
what building it in does.

### Principle 9: Localized and Consistent by Construction

**Rule**: No user-visible string may be embedded in Dart code. All text lives in ARB files and is
accessed through the generated localization class. Every feature MUST ship complete translations
in all five supported languages — English, Spanish, Portuguese, Italian, and French — before it
can be considered done. A missing key in any locale is a CI failure, not a warning. Dates,
numbers, and amounts MUST be formatted with `intl` according to the active locale, never by
manual string concatenation.

All UI MUST be built from the design system tokens defined in `docs/UI_UX_SPEC.md`. No hex color
value may appear outside `app_colors.dart`; no `TextStyle` may be constructed ad hoc outside
`app_typography.dart`; no border radius or spacing value may be written as a literal outside
`app_spacing.dart`. Layouts MUST tolerate text expansion without clipping or overflowing.

Default categories are stored with a translation key, not a literal name. Only user-created
categories store literal text.

**Rationale**: Retrofitting translation is several times more expensive than translating from the
start, and a design system that applies "almost always" is not a design system. The cartoon
aesthetic depends on pill-shaped buttons and content-width cards, which are exactly the layouts
that break when French and Portuguese run 15 to 30 percent longer than English.

---

## Development Standards

- **Linting**: `very_good_analysis`, plus `custom_lint` and `riverpod_lint`. CI fails on analyzer
  warnings and on unformatted code.
- **Testing floor**: every use case has a unit test; every repository has a test against
  `fake_cloud_firestore`; the design system has golden tests; Security Rules have their own suite.
  A feature without tests is not done.
- **Generated code**: `build_runner` output is committed. `firebase_options_*.dart` is committed;
  `google-services.json`, `GoogleService-Info.plist`, keystores, and provisioning profiles are not.
- **Secrets**: signing keys and service-account credentials live in the CI secret store and never
  in the repository. Client Firebase identifiers are not secrets and are not treated as such.
- **Phase discipline**: work follows ROADMAP.md phase order. Phase 0 (flavors and both Firebase
  projects) completes before feature work begins.

## Agent Operating Rules

These bind any AI agent with credentials to the Firebase account or the repository:

- Destructive commands — `projects:delete`, `firestore:delete`, `auth:import`, `auth:export`, and
  any deploy targeting **prod** — REQUIRE explicit human confirmation in the current session.
  Prior authorization does not carry across sessions.
- The `default` alias in `.firebaserc` points at `dev`, so an accidental deploy hits the
  disposable project.
- Agents MUST NOT commit credentials, generated platform config files, or anything matched by
  `.gitignore`, and MUST NOT force-push or rewrite history on `main`.
- When a CLI flag or command in the documentation does not match reality, the agent stops and
  reports rather than improvising a workaround. Tooling drifts; the specs are corrected, not
  routed around silently.

## Governance

**Authority**: This constitution supersedes all other project documentation. A specification,
plan, or pull request that conflicts with it is rejected, not negotiated.

**Amendment procedure**: Amendments require (1) a written rationale naming the principle changed
and the problem that forced it, (2) a version bump per the policy below, (3) an update to every
document in `/docs` that the change contradicts, in the same commit. Adding a feature currently
listed under Principle 3 requires an amendment — not an exception, not a one-off.

**Versioning policy**:
- **MAJOR** — a principle is removed or redefined in a backward-incompatible way.
- **MINOR** — a principle or section is added, or guidance is materially expanded.
- **PATCH** — clarification, wording, or typo fixes with no change in meaning.

**Compliance review**: Every pull request verifies compliance. `/speckit.plan` must include a
Constitution Check section naming which principles the plan touches. Principle 1 is verified by
measurement, not by assertion — the time-to-log instrumentation is the check.

**Complexity justification**: Any deviation toward more complexity must be justified in writing
in the plan that introduces it. "It might be useful later" is not a justification.

**Version**: 1.1.0 | **Ratified**: 2026-08-07 | **Last Amended**: 2026-08-08
