# Implementation Plan: Resumen Mensual Animado y Compartible

**Branch**: `006-monthly-wrapped-summary` | **Date**: 2026-08-12 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/006-monthly-wrapped-summary/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

An animated, story-format monthly summary ("Wrapped") that appears automatically on the first app
open of a new calendar month when the previous month has 5+ expenses, offers itself discreetly
otherwise, stays manually reachable for any past month with data, and ends in a shareable image
that defaults to hiding monetary figures. Computed client-side from the local Firestore cache
(`monthKey` equality query, per `docs/DATA_MODEL.md`), with a server-side `count()` check to detect
and surface an incomplete local cache instead of a wrong total. The cross-device "exactly once per
month" requirement forces this feature to finally create the `users/{userId}` document
`docs/DATA_MODEL.md` has documented since `003` but no feature has written until now — see
`research.md` #1.

## Technical Context

**Language/Version**: Dart (Flutter, latest stable channel), SDK `^3.12.2`

**Primary Dependencies**: `flutter_riverpod`, `go_router`, `get_it`/`injectable`, `cloud_firestore`,
`intl` (all existing) — plus **`flutter_animate`** and **`share_plus`**, added by this feature for
the first time (`docs/TECH_STACK.md` names both for exactly this feature; `research.md` #4)

**Storage**: Firestore, offline persistence enabled (existing). New: `users/{userId}` document,
created by this feature (`research.md` #1, `data-model.md` §3). No new collections, no precomputed
`monthlySummaries` (explicitly excluded by `docs/DATA_MODEL.md` and by this plan's input)

**Testing**: `flutter_test`, `mocktail`, `fake_cloud_firestore` (already supports `.count()`
aggregation, verified in `research.md` #6), `firebase_auth_mocks`, `alchemist` (golden),
`@firebase/rules-unit-testing` (Security Rules)

**Target Platform**: iOS 15+, Android API 24+ (existing, unchanged)

**Project Type**: Mobile app (Flutter), feature-first Clean Architecture (existing convention)

**Performance Goals**: Story auto-advance every 5–7s (`docs/UI_UX_SPEC.md` §3, expressed as an
`AppMotionExtension` token — `research.md` #5); the auto-trigger check must add no measurable delay
to capture-screen first paint (Constitution Principle 1 — `research.md` #7 keeps it a
post-first-frame, presentation-layer check, never a `bootstrap()` blocker)

**Constraints**: Offline-first (summary computation must work fully from local cache, with the
`count()` sync check as the one deliberate exception, and even that is non-blocking); reduce-motion
compliance (`MediaQuery.disableAnimationsOf`, established pattern from `004`); zero monetary/note/
category-name data in analytics events (Constitution Principle 5); no precomputed aggregate
collection (`docs/DATA_MODEL.md`, explicit)

**Scale/Scope**: One new feature module (`lib/features/wrapped/`), one new supporting feature module
(`lib/features/user_profile/`), one new design-system token file (`app_motion.dart`), one new
top-level route, one Security Rules addition, ~7–9 new ARB keys across 5 locales, no changes to
existing `Expense`/`Category` entities or their Firestore shapes

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|---|---|---|
| P1 — Logging path is sacred | Wrapped is a wholly new route/screen tree; nothing in `ExpenseCapturePage` or its controller is touched. The auto-trigger check runs post-first-frame in the presentation layer (`research.md` #7), never in `bootstrap()`'s synchronous path. | PASS |
| P2 — Offline-first, always | Summary computation reads the local cache first (existing `watchByMonth`/equality-query pattern). The one network-dependent step (`count()` server check) only ever *downgrades* to a syncing state, never blocks or fails the read; `wrappedLastSeenMonth`/`timeZone` writes are fire-and-forget, UI never awaits them. | PASS |
| P3 — Anti-goals are binding | No month-over-month comparison, no charts, no projections, no budgets, no annual summary, no content personalization — spec's Out of Scope restates the plan input verbatim. | PASS |
| P4 — Layer boundaries enforced | `WrappedSummary`/`UserProfile` domain entities and `WrappedRepository`/`UserProfileRepository` interfaces are Flutter/Firebase-free. `flutter_animate`, `share_plus`, `RepaintBoundary` rasterization, and `go_router` navigation are confined to `presentation/`. Widgets read `WrappedRepository`/`UserProfileRepository` only via the existing GetIt-bridge-through-a-single-Riverpod-provider pattern (`core/di/providers.dart`) — no direct `getIt` access from widgets. | PASS |
| P5 — Money is exact and private | `WrappedSummary.total`/`biggestExpense` stay `Money` (integer minor units) end-to-end; formatting only at presentation. The one analytics event this feature adds carries a completion-ratio value only — no amount, note, or category name, matching `AnalyticsService`'s existing single-purpose-method precedent. | PASS |
| P6 — Environments isolated/symmetric | No flavor-specific behavior introduced; `users/{userId}` is written identically in `dev`/`prod`, same Security Rules file deployed to both. | PASS |
| P7 — Security Rules are the only real boundary | `users/{userId}` create/update currently has **no field validation** (only ownership) — a real gap this feature closes with `isValidUserProfile()` (`contracts/security-rules-delta.md`), tested per the same `@firebase/rules-unit-testing` discipline as `/expenses`/`/categories`. | PASS (gap identified and closed by this plan, not deferred) |
| P8 — Accessible by construction | Reduce-motion collapses every spring/count-up to a cross-fade with immediate final values (FR-008, mirrors `004`'s `SuccessFeedbackOverlay`); tap targets ≥48×48dp on all story controls; text scales to 200% (bounded story copy, no fixed-height text containers); pausable/back-navigable stories so a screen-reader user is never outrun by auto-advance (`docs/UI_UX_SPEC.md` §5, restated). | PASS |
| P9 — Localized and consistent by construction | Every new string is an ARB key across all 5 locales, `wrapped_*`-prefixed with the native-review metadata `docs/TECH_STACK.md` already specifies (`research.md` #11). New motion tokens (`AppMotionExtension`) follow the exact `ThemeExtension` shape `app_colors.dart`/`app_typography.dart`/`app_spacing.dart` already use — no bare `Curve`/`Duration` literals in story widgets (`research.md` #5). Category names resolved at display time via existing `nameKey`/`name` mechanism (FR-011). | PASS |

No violations requiring `Complexity Tracking`.

## Project Structure

### Documentation (this feature)

```text
specs/006-monthly-wrapped-summary/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   ├── wrapped-domain-api.md
│   └── security-rules-delta.md
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

Single Flutter project, feature-first Clean Architecture — the established structure every prior
feature (`003`–`005`) already follows. This feature adds two new feature modules and touches the
app shell, DI wiring, design system, and Security Rules:

```text
lib/
├── app.dart                                  # + top-level /wrapped/:monthKey route (sibling of ShellRoute)
├── bootstrap.dart                             # + fire-and-forget EnsureUserProfileUseCase call
├── core/
│   ├── design_system/
│   │   ├── tokens/
│   │   │   └── app_motion.dart               # NEW — AppMotionExtension (spring curve, durations)
│   │   └── theme/design_tokens.dart          # + context.motion accessor
│   └── di/providers.dart                     # + userProfileRepositoryProvider, wrappedRepositoryProvider
├── features/
│   ├── user_profile/                         # NEW feature module
│   │   ├── domain/
│   │   │   ├── entities/user_profile.dart
│   │   │   ├── repositories/user_profile_repository.dart
│   │   │   └── usecases/ensure_user_profile.dart
│   │   └── data/
│   │       ├── datasources/user_profile_remote_data_source.dart
│   │       ├── models/user_profile_model.dart
│   │       └── repositories/user_profile_repository_impl.dart
│   ├── wrapped/                               # NEW feature module
│   │   ├── domain/
│   │   │   ├── entities/wrapped_summary.dart
│   │   │   └── repositories/wrapped_repository.dart
│   │   ├── data/
│   │   │   ├── datasources/wrapped_remote_data_source.dart
│   │   │   └── repositories/wrapped_repository_impl.dart
│   │   └── presentation/
│   │       ├── controllers/wrapped_controller.dart
│   │       ├── wrapped_auto_trigger_provider.dart
│   │       ├── wrapped_auto_trigger_gate.dart    # wraps ShellRoute's child in app.dart
│   │       ├── pages/wrapped_page.dart
│   │       └── widgets/
│   │           ├── wrapped_progress_bar.dart
│   │           ├── wrapped_scene_grand_total.dart
│   │           ├── wrapped_scene_black_hole.dart
│   │           ├── wrapped_scene_habit.dart
│   │           ├── wrapped_scene_biggest_hit.dart
│   │           ├── wrapped_share_card.dart       # RepaintBoundary, reused on-screen + for rasterization
│   │           └── wrapped_suppressed_card.dart  # shown inline in History (research.md #3)
│   └── expenses/
│       └── presentation/
│           ├── pages/expense_history_page.dart   # + month-picker affordance (research.md #3)
│           └── widgets/history_month_picker_sheet.dart  # NEW
├── l10n/*.arb                                 # + wrapped_* keys, 5 locales (research.md #11)
firestore.rules                                # + isValidUserProfile() (contracts/security-rules-delta.md)
firebase/tests/users.rules.test.js             # + new cases, existing 6 tests unmodified

test/
├── features/user_profile/...
├── features/wrapped/...
├── features/expenses/presentation/widgets/history_month_picker_sheet_test.dart
└── core/design_system/tokens/app_motion_test.dart
```

**Structure Decision**: Two new feature modules (`user_profile`, `wrapped`) under the existing
`lib/features/` convention, each following the standard `domain/`/`data/`/`presentation/` split. No
new top-level directories, no changes to `003`'s `auth`/`categories`/`expenses` module boundaries
beyond the additive History-screen affordance and the new bootstrap call. This mirrors exactly how
`005` added its own feature-internal `presentation/` layer without restructuring `003`/`004`.

## Complexity Tracking

No violations — Constitution Check above is a clean PASS on every principle. This section is
intentionally empty per the template's own instruction ("Fill ONLY if Constitution Check has
violations that must be justified").
