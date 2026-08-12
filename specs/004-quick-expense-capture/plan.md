# Implementation Plan: Captura de Gasto en Menos de Tres Segundos

**Branch**: `004-quick-expense-capture` | **Date**: 2026-08-11 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-quick-expense-capture/spec.md`

## Summary

The single screen the app opens to: a keypad that captures an amount, a bottom sheet that captures
a category, and a `LogExpense` use case that persists the result and never waits for the network.
This is the first feature to give `003`'s domain-only `expenses`/`categories` contracts a real
`data/`/`presentation/` implementation, and the first to write to Firestore at all beyond
`firestore.rules` itself.

Riverpod owns the screen's reactive state (`ExpenseCaptureState`, `AmountInputState`); GetIt/
Injectable owns the new infrastructure (`ExpenseRepositoryImpl`, `CategoryRepositoryImpl`,
`FirebaseAnalyticsService`), per the boundary `docs/TECH_STACK.md` already draws — neither is
reimplemented, both are reused exactly as `003` left them (`AuthRepository`,
`runWhenAuthenticated`, `ExpenseRepository`/`CategoryRepository` interfaces, `Money`).

The one genuinely new piece of complexity is how a Firestore write is confirmed "local" without
awaiting the SDK's server-acknowledged `Future` — `research.md`'s local-write-detection decision — which
is what makes the 3-second budget, the never-wait-for-server feedback rule, and the
no-network-is-not-an-error rule all true simultaneously, by construction, rather than by three
separate mechanisms.

Two gaps were found between the plan input's assumptions and the repository's actual state and are
corrected here, not silently worked around: the `category_*` ARB keys do not exist yet (this feature
adds them, exactly where `docs/ROADMAP.md` always intended), and no `users/{userId}` profile
document exists yet to source a stored currency/timezone (this feature derives both from the
device's locale as a documented interim default). See `research.md` for both.

## Technical Context

**Language/Version**: Dart / Flutter, latest stable channel (unpinned per `docs/TECH_STACK.md`)

**Primary Dependencies**: `cloud_firestore`, `flutter_riverpod`, `get_it` + `injectable`, `intl`
(all already present); **new**: `firebase_analytics` (pulled forward from its `docs/ROADMAP.md`
Phase 4 slot, scoped to exactly one event — see research.md). No new dev dependency:
`fake_cloud_firestore` and `firebase_auth_mocks` are already present, unused by any Firestore-backed
feature until now.

**Storage**: Cloud Firestore — first feature to write `users/{userId}/expenses/*` and
`users/{userId}/categories/*`; `firestore.rules`/`firestore.indexes.json` unchanged (already cover
every write shape this feature produces, per `003`)

**Testing**: `flutter_test` + `mocktail` for use case/controller unit tests; `fake_cloud_firestore` +
`firebase_auth_mocks` for repository tests and the full-flow `integration_test/` (both already
present, exercised for the first time by this feature); `alchemist` golden tests for the two new
design-system tokens' effect on existing widgets (regression only — no new golden subjects expected
since no shared widget changes)

**Target Platform**: iOS 15+, Android API 24+ — unchanged

**Project Type**: Mobile app (Flutter) — first feature to add product screens; replaces
`PlaceholderHomePage` as the app's single route

**Performance Goals**: p90 time from app open to local expense persistence < 3000ms (FR-003/SC-001,
Constitution Principle 1) — the measured, not asserted, gate this entire feature exists to satisfy

**Constraints**: no screen, dialog, confirmation, or spinner on the logging path (Principle 1); no
write may await server acknowledgement (Principle 2); no analytics event may carry a monetary
amount, note, or category name (Principle 5); every user-visible string ships in all five locales,
every new color/typography/radius/spacing value lives only in its token file (Principle 9); minimum
48×48dp tap targets, color never the sole signal, reduce-motion respected (Principle 8)

**Scale/Scope**: 1 screen (`ExpenseCapturePage`), 2 new data-layer implementations
(`ExpenseRepositoryImpl`, `CategoryRepositoryImpl`), 2 new use cases (`LogExpense`,
`SeedDefaultCategoriesUseCase`), 2 new `core/` abstractions (`AppLaunchClock`, `AnalyticsService`),
1 additive interface member (`CategoryRepository.seedDefaultsIfNeeded()`), 2 new design-system
tokens (`displayLarge` typography, `categoryPalette` colors), 7 seeded default categories, 10 new
ARB keys across 5 locales, 0 changes to `firestore.rules`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Applies? | Assessment |
|---|---|---|
| 1. The Logging Path Is Sacred | Yes | Core purpose of this feature. App root route becomes the keypad directly; two taps after the amount (Next, category) complete the log; no confirmation step exists anywhere in the flow; instrumented via `AppLaunchClock`/`AnalyticsService`, not asserted — the constitution's own compliance mechanism. |
| 2. Offline-First, Always | Yes | Core purpose. The local-write-detection decision (research.md) means success is confirmed from the local cache, never the server; `Expense.id`/`Category` seed ids are client-generated via `collection.doc()`; no query on this path sorts/groups by `syncedAt`. |
| 3. Anti-Goals Are Binding | Yes | No income/debt/budget/recurring/OCR/multi-currency/dashboard/web/desktop functionality introduced. The device-locale currency fallback (research.md) is a single fixed code per write, not user-facing currency conversion or selection — it does not reintroduce the anti-goal. |
| 4. Layer Boundaries Are Enforced | Yes | `LogExpense`/`SeedDefaultCategoriesUseCase` (domain) depend only on abstract `ExpenseRepository`/`CategoryRepository`/`AuthRepository`/`AnalyticsService`/`AppLaunchClock` — all Flutter/Firebase-free. `ExpenseRepositoryImpl`/`CategoryRepositoryImpl` (data) are the only files importing `cloud_firestore` for this feature. `category_name_resolver.dart`/`category_icon_map.dart` (the only two places `AppLocalizations`/`IconData` are touched for categories) live in `presentation/`. Widgets read repositories via the single Riverpod-bridge-provider pattern `docs/TECH_STACK.md` specifies — never `getIt` directly. |
| 5. Money Is Exact and Private | Yes | `amountMinor` stays an `int` end to end — `AmountInputState` parses to an `int`, `Money` stores an `int`, `isValidExpense()` validates an `int`. The one new analytics event (`time_to_log_expense`) carries only a `duration_ms` integer — no amount, note, or category name ever reaches `AnalyticsService`. |
| 6. Environments Are Isolated and Symmetric | Yes | No change to flavor config; `firestore.rules`/indexes remain identical across `dev`/`prod` (unchanged by this feature); dev-flavor `firebase_analytics` events land in the `dev` Firebase project like every other dev-flavor write. |
| 7. Security Rules Are the Only Real Boundary | Yes | No rules change needed — `003`'s `isValidExpense()`/`isValidCategory()` already validate every write shape this feature produces (research.md's "no changes needed" correction), so this feature is a pure, already-covered consumer of the existing, tested boundary. |
| 8. Accessible by Construction | Yes | Keypad keys and category tiles sized ≥48×48dp; `keypadAmountSemanticLabel` gives the amount display a semantic label; category tiles carry both an icon and a localized text label (color is never the only signal, per `docs/UI_UX_SPEC.md` §5); the success animation collapses to a cross-fade under reduce-motion. |
| 9. Localized and Consistent by Construction | Yes | Core purpose alongside Principle 1. 10 new ARB keys ship in all five locales in the same change (data-model.md); default category names are `nameKey`-only, resolved in `presentation/`, never a literal; the two new visual values this feature needs (`displayLarge` typography, `categoryPalette` colors) are added to their respective token files, not written ad hoc; `no_raw_hex_colors_test.dart` and `arb_keys_complete_test.dart` (both unmodified, both already enforced) are the backstop. |

**Initial gate result**: PASS. No violations requiring a Complexity Tracking entry. The one piece of
non-obvious complexity (local-write detection via the doc's own snapshot existence) is the necessary minimum
mechanism for Principles 1 and 2 simultaneously — the direct persistence-side counterpart to `003`'s
identity-side `runWhenAuthenticated` buffer, not complexity added for its own sake.

**Post-Phase 1 re-check**: PASS, unchanged. `data-model.md` confirms every new Firestore field this
feature writes already has server-side validation in `003`'s ruleset; the two design-system token
additions are additions to existing single-source-of-truth files, not new sources of literals; the
two corrected assumptions (ARB keys, device-locale currency/timezone) are scoped, documented, and
reversible without touching any `003` contract when their real prerequisites (Phase 1's own ARB
authoring step, Phase 3's Settings/user-profile feature) land.

## Project Structure

### Documentation (this feature)

```text
specs/004-quick-expense-capture/
├── plan.md                        # This file (/speckit-plan command output)
├── research.md                    # Phase 0 output
├── data-model.md                  # Phase 1 output
├── quickstart.md                  # Phase 1 output
├── contracts/
│   └── expense-capture-api.md
├── checklists/
│   └── requirements.md
└── tasks.md                       # Phase 2 output (/speckit-tasks — NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── app.dart                                          # MODIFIED: root route → ExpenseCapturePage
├── bootstrap.dart                                     # MODIFIED: + AppLaunchClock capture (first
│                                                       #   statement), + SeedDefaultCategoriesUseCase
│                                                       #   fire-and-forget call alongside sign-in
├── core/
│   ├── analytics/
│   │   ├── analytics_service.dart                     # NEW: abstract, Duration-only
│   │   └── firebase_analytics_service.dart             # NEW: @LazySingleton(as: AnalyticsService)
│   ├── instrumentation/
│   │   └── app_launch_clock.dart                       # NEW: plain-Dart clock
│   ├── design_system/
│   │   └── tokens/
│   │       ├── app_colors.dart                         # MODIFIED: + categoryPalette (7 Colors)
│   │       └── app_typography.dart                     # MODIFIED: + displayLarge
│   └── di/
│       ├── injection.config.dart                       # MODIFIED: regenerated
│       └── providers.dart                               # MODIFIED: + expenseRepositoryProvider,
│                                                          #   categoryRepositoryProvider (bridge)
├── features/
│   ├── expenses/
│   │   ├── domain/
│   │   │   └── usecases/
│   │   │       └── log_expense.dart                     # NEW
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── expense_model.dart                   # NEW: fromEntity/toJson, monthKey/syncedAt/
│   │   │   │                                             #   deletedAt/schemaVersion
│   │   │   ├── datasources/
│   │   │   │   └── expense_remote_data_source.dart        # NEW: owns the local-write-existence detection
│   │   │   └── repositories/
│   │   │       └── expense_repository_impl.dart            # NEW: @LazySingleton(as: ExpenseRepository)
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   ├── amount_input_state.dart                 # NEW: plain-Dart, no Widget/BuildContext
│   │       │   └── expense_capture_controller.dart          # NEW: Riverpod, orchestrates the screen
│   │       ├── pages/
│   │       │   └── expense_capture_page.dart                # NEW: the app's new root route
│   │       └── widgets/
│   │           ├── amount_display.dart                      # NEW: uses displayLarge
│   │           ├── amount_keypad.dart                        # NEW: token-driven, no new literals
│   │           ├── category_picker_sheet.dart                 # NEW
│   │           └── success_feedback_overlay.dart               # NEW: implicit-animation checkmark
│   └── categories/
│       ├── domain/
│       │   ├── usecases/
│       │   │   └── seed_default_categories.dart           # NEW
│       │   └── repositories/
│       │       └── category_repository.dart                # MODIFIED: + seedDefaultsIfNeeded()
│       ├── data/
│       │   ├── models/
│       │   │   └── category_model.dart                     # NEW
│       │   ├── datasources/
│       │   │   └── category_remote_data_source.dart          # NEW: seed batch write + queries
│       │   └── repositories/
│       │       └── category_repository_impl.dart              # NEW: @LazySingleton(as: CategoryRepository)
│       └── presentation/
│           ├── category_icon_map.dart                        # NEW: iconName → IconData
│           └── category_name_resolver.dart                    # NEW: nameKey/name → localized String
└── l10n/
    └── app_{en,es,pt,it,fr}.arb                                # MODIFIED: + 10 keys (data-model.md)

firestore.rules                                                  # UNCHANGED
firestore.indexes.json                                            # UNCHANGED
firebase/tests/                                                    # UNCHANGED

integration_test/
└── expense_capture_flow_test.dart                                  # NEW: full flow, fake_cloud_firestore
                                                                     #   + firebase_auth_mocks, no network

test/
├── core/
│   ├── analytics/
│   │   └── firebase_analytics_service_test.dart                     # NEW
│   ├── instrumentation/
│   │   └── app_launch_clock_test.dart                                 # NEW
│   └── design_system/tokens/                                          # UNCHANGED tests still pass
│       ├── no_raw_hex_colors_test.dart                                #   (regression guard)
│       └── app_colors_contrast_test.dart                              #   (regression guard)
└── features/
    ├── expenses/
    │   ├── domain/usecases/
    │   │   └── log_expense_test.dart                                    # NEW
    │   ├── data/
    │   │   ├── models/expense_model_test.dart                           # NEW
    │   │   └── repositories/expense_repository_impl_test.dart            # NEW: fake_cloud_firestore
    │   └── presentation/
    │       ├── controllers/
    │       │   ├── amount_input_state_test.dart                          # NEW
    │       │   └── expense_capture_controller_test.dart                   # NEW
    │       └── widgets/                                                   # NEW: golden + interaction tests
    └── categories/
        ├── domain/usecases/
        │   └── seed_default_categories_test.dart                          # NEW
        └── data/
            ├── models/category_model_test.dart                            # NEW
            └── repositories/category_repository_impl_test.dart             # NEW: fake_cloud_firestore
```

**Structure Decision**: Single Flutter mobile project, unchanged from `001`–`003`. This is the first
feature to populate `expenses`/`categories`' `data/` and `presentation/` layers — their `domain/`
layers (from `003`) gain exactly one additive member and nothing else. `auth`'s three layers (from
`003`) are consumed, not modified.

## Complexity Tracking

*No entries.* The local-write-detection mechanism (racing `.set()` against the doc's own snapshot) is the necessary minimum
complexity for Principles 1 and 2 to hold simultaneously on a real Firestore write — the same
standard `003`'s Complexity Tracking applied to `runWhenAuthenticated`. Every other design choice in
`research.md` was the smaller of the available options: reusing `003`'s contracts unmodified where
possible and widening additively where not; built-in implicit animations instead of pulling
`flutter_animate` forward; a five-entry locale→currency map instead of relying on opaque CLDR
inference; sequential writes instead of a new cross-repository transaction abstraction.
