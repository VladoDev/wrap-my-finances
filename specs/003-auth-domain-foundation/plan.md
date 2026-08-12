# Implementation Plan: Fundación de Autenticación y Contratos de Dominio (expenses/categories)

**Branch**: `003-auth-domain-foundation` | **Date**: 2026-08-09 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-auth-domain-foundation/spec.md`

## Summary

Formalize the anonymous session `001` left as an inline `FirebaseAuth` call inside `bootstrap()`
into a real `auth` feature with all three Clean Architecture layers: `AuthRepository` (domain
interface) exposing `currentUserId`, `ensureSignedIn()`, and — the core deliverable —
`runWhenAuthenticated<T>()`, a generic buffering primitive that runs an operation immediately if a
UID already exists or queues and flushes it the moment sign-in resolves. `SignInAnonymouslyUseCase`
replaces the raw SDK call `bootstrap()` used to make. Because no expense/category write use case
exists yet to exercise the buffer against, `runWhenAuthenticated` is tested directly with
`firebase_auth_mocks` controlling sign-in timing — future features call it, none reimplement it.

In parallel, `expenses` and `categories` gain domain-only contracts — entities (`Expense`, `Money`,
`Category`) and abstract repositories (`ExpenseRepository`, `CategoryRepository`) — with zero
`data/`/`presentation/` files, so `004` has a fixed shape to build against without this feature
touching UI at all.

`firestore.rules` is replaced in full by `docs/DATA_MODEL.md`'s product ruleset (`isOwner`,
`isValidExpense`, `isValidCategory` with the `nameKey`/`name` XOR invariant, and the trailing
catch-all), and the `env_checks` diagnostic block/feature from `001` is deleted entirely — its job
is done, and its rules block is what's being replaced. The app's single route gets a minimal,
localized placeholder (dev-ribbon banner only) so `go_router` still has something to render.
`firestore.rules` deploys to `dev` as part of this feature's normal flow; `prod` requires the same
explicit human-confirmation gate `001` used. A new `rules-tests` CI job (parallel to `002`'s
`analyze-and-test`) runs the Security Rules suite against the local emulator on every pull request.

## Technical Context

**Language/Version**: Dart / Flutter, latest stable channel (unpinned per `docs/TECH_STACK.md`)

**Primary Dependencies**: `firebase_auth`, `cloud_firestore`, `get_it` + `injectable` (both already
present); dev: `firebase_auth_mocks`, `fake_cloud_firestore` (both already present, unused until
now); Node/CI-only: `firebase-tools`, `@firebase/rules-unit-testing`, `mocha` (all already present
in `firebase/tests/` since `001`)

**Storage**: Cloud Firestore — no new collections; `firestore.rules` fully replaced,
`firestore.indexes.json` unchanged (already matches `docs/DATA_MODEL.md`)

**Testing**: `flutter_test` + `mocktail` for the use case and repository unit tests;
`firebase_auth_mocks` for controlling anonymous sign-in timing in `FirebaseAuthRepository` tests;
`@firebase/rules-unit-testing` + `mocha` (existing `firebase/tests/` project) for the rules suite,
now covering `users`/`categories`/`expenses` instead of `env_checks`

**Target Platform**: iOS 15+, Android API 24+ — unchanged; this feature adds no platform-specific
code

**Project Type**: Mobile app (Flutter) — one fully-implemented feature (`auth`) plus two
domain-only feature skeletons (`expenses`, `categories`); no product screens

**Performance Goals**: None beyond baseline; `runWhenAuthenticated` must add no latency once a UID
already exists (the common case after the first app launch) — the immediate-run branch has no
queue/await overhead beyond a single `Future` invocation

**Constraints**: Sign-in remains fire-and-forget from `bootstrap()` — never awaited, never blocks
first frame (Constitution Principles 1/2); domain entities for `expenses`/`categories` must compile
and be testable with zero Flutter/Firebase imports (Constitution Principle 4); every Security Rules
scenario in FR-014 must have an automated test, none verified by hand (Constitution Principle 7);
no string this feature adds to Dart code may be a literal (Constitution Principle 9)

**Scale/Scope**: 1 fully-layered feature (`auth`: 1 repository interface + impl, 1 use case, 0
screens), 2 domain-only feature skeletons (3 entities, 2 repository interfaces, 0 use cases, 0
data/presentation), 1 full `firestore.rules` rewrite, 3 rules test files replacing 1, 1 new CI job,
1 new placeholder page, 1 new ARB key across 5 locales — no new product screens, no keypad, no
category picker

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Applies? | Assessment |
|---|---|---|
| 1. The Logging Path Is Sacred | No | No keypad or logging UI exists in this feature; sign-in stays fire-and-forget, preserving the budget for when the keypad arrives. |
| 2. Offline-First, Always | Yes | Core purpose: the buffer exists specifically so a write triggered before the UID resolves still completes locally without the UI awaiting a network round trip; Firestore persistence config (from `001`) is preserved unchanged. |
| 3. Anti-Goals Are Binding | Yes | No income/debt/budget/recurring/OCR/multi-currency/web/desktop functionality introduced; anonymous auth is explicitly not an anti-goal (Principle 3) and this feature only restructures where its existing call lives. |
| 4. Layer Boundaries Are Enforced | Yes | Core purpose: `auth`'s `domain/` has zero Flutter/Firebase imports (verified by a pure-Dart test); `expenses`/`categories` domain entities and repository interfaces are equally Flutter/Firebase-free; `data/` depends on `domain/`, never the reverse; widgets never reference `getIt` or `AuthRepository` directly — only future use cases will. |
| 5. Money Is Exact and Private | Yes | `Money` stores `minorUnits` as `int`, never `double`; no analytics/telemetry is introduced by this feature. |
| 6. Environments Are Isolated and Symmetric | Yes | The new ruleset deploys identically to both `dev` and `prod` from the same file; the placeholder page preserves the dev-ribbon distinction Principle 6 requires; the `default` alias still points at `dev` (unchanged from `001`). |
| 7. Security Rules Are the Only Real Boundary | Yes | Core purpose: the full product ruleset (ownership + field/type/range validation + trailing catch-all) replaces the diagnostic-only rules; an automated test suite against the emulator covers cross-user denial, invalid-amount rejection, and unauthenticated denial — the exact minimum Principle 7 names — plus the `nameKey`/`name` invariant and the `uid`-immutability check. |
| 8. Accessible by Construction | No | The one new UI element (the placeholder page's dev banner) is a direct carry-over of `001`'s already-compliant banner (contrast, no color-only meaning); no new interactive control is introduced. |
| 9. Localized and Consistent by Construction | Yes | The one new user-visible string this feature adds (the dev banner's "DEV BUILD" text) is added as an ARB key (`common_devBuild`) across all five locales, not a Dart literal — closing a gap `001` left before `002`'s l10n infrastructure existed. |

**Initial gate result**: PASS. No violations requiring a Complexity Tracking entry — every
principle this feature touches is either its direct purpose (2, 4, 7) or a straightforward
extension of prior, compliant work (6, 9).

**Post-Phase 1 re-check**: PASS, unchanged. `data-model.md` confirms `AuthRepository`'s buffer is a
single, generic primitive (not duplicated per future feature), the `expenses`/`categories`
entities carry no Firebase/Flutter types, and the Security Rules test matrix in `data-model.md`
covers every scenario FR-014 lists. No money value, analytics event, or anti-goal-listed
functionality was introduced during design.

## Project Structure

### Documentation (this feature)

```text
specs/003-auth-domain-foundation/
├── plan.md               # This file (/speckit-plan command output)
├── research.md            # Phase 0 output (/speckit-plan command)
├── data-model.md           # Phase 1 output (/speckit-plan command)
├── quickstart.md           # Phase 1 output (/speckit-plan command)
├── contracts/                # Phase 1 output (/speckit-plan command)
│   ├── auth-api.md
│   └── domain-repositories-api.md
├── checklists/
│   └── requirements.md
└── tasks.md                # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── app.dart                                  # MODIFIED: root route → PlaceholderHomePage
├── bootstrap.dart                             # MODIFIED: signInAnonymously() call → SignInAnonymouslyUseCase
├── core/
│   ├── di/
│   │   └── injection.dart                     # MODIFIED: re-run build_runner after new @injectable classes
│   ├── diagnostics/                           # DELETED entirely (entity, repository, page)
│   └── presentation/
│       └── pages/
│           └── placeholder_home_page.dart     # NEW: minimal dev-ribbon-only placeholder
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart           # AuthRepository interface
│   │   │   └── usecases/
│   │   │       └── sign_in_anonymously.dart        # SignInAnonymouslyUseCase
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── firebase_auth_repository.dart   # implements AuthRepository, owns the buffer
│   │   └── presentation/                       # intentionally empty — no screens yet
│   ├── expenses/
│   │   └── domain/
│   │       ├── entities/
│   │       │   ├── expense.dart
│   │       │   └── money.dart
│   │       └── repositories/
│   │           └── expense_repository.dart      # abstract only, no impl
│   └── categories/
│       └── domain/
│           ├── entities/
│           │   └── category.dart
│           └── repositories/
│               └── category_repository.dart     # abstract only, no impl
└── l10n/
    └── app_{en,es,pt,it,fr}.arb                 # MODIFIED: + commonDevBuild key

firestore.rules                                  # REPLACED: full docs/DATA_MODEL.md ruleset, env_checks removed
firestore.indexes.json                           # unchanged
.github/workflows/ci.yml                         # MODIFIED: + rules-tests job

firebase/tests/
├── env_checks.rules.test.js                     # DELETED
├── users.rules.test.js                          # NEW
├── categories.rules.test.js                     # NEW
└── expenses.rules.test.js                       # NEW

test/
├── core/diagnostics/                            # DELETED (mirrors lib/ deletion)
├── core/presentation/pages/
│   └── placeholder_home_page_test.dart          # NEW
└── features/
    ├── auth/
    │   ├── domain/usecases/
    │   │   └── sign_in_anonymously_test.dart
    │   └── data/repositories/
    │       └── firebase_auth_repository_test.dart
    ├── expenses/domain/
    │   ├── entities/
    │   │   ├── expense_test.dart
    │   │   └── money_test.dart
    │   └── repositories/
    │       └── expense_repository_contract_test.dart   # fake impl compiles, exercises interface shape
    └── categories/domain/
        ├── entities/
        │   └── category_test.dart                       # includes the nameKey/name invariant assertion
        └── repositories/
            └── category_repository_contract_test.dart
```

**Structure Decision**: Single Flutter mobile project, unchanged from `001`/`002`. This is the
first feature to populate `lib/features/`, per `docs/ARCHITECTURE.md`'s directory structure —
`auth`, `expenses`, and `categories` are created here for the first time. `expenses`/`categories`
intentionally stop at `domain/`; their `data/`/`presentation/` directories are not created by this
feature at all (not even empty), so their absence is a direct, visible signal of scope rather than
a placeholder to be filled in later.

## Complexity Tracking

*No entries.* The one piece of genuine design complexity this feature introduces —
`runWhenAuthenticated`'s in-memory queue — is the minimum mechanism that satisfies FR-004/FR-005
and is explicitly named as necessary complexity by `docs/ARCHITECTURE.md` itself ("the one piece of
genuine complexity the 3-second rule buys"). Every other decision in `research.md` was chosen
specifically because it was the smaller of the available options (domain-only contracts instead of
building `004`'s use cases early; reusing `001`'s confirmation pattern instead of new tooling;
extending the existing CI workflow instead of a second one).
