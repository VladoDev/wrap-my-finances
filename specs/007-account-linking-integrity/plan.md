# Implementation Plan: Cuentas Vinculadas e Integridad de la Aplicación

**Branch**: `007-account-linking-integrity` | **Date**: 2026-08-12 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/007-account-linking-integrity/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Lets a user upgrade their anonymous session to a real, recoverable identity (Google or Apple —
both together, since Apple requires it wherever Google is offered) without ever being asked to,
and protects Firestore against non-legitimate clients via Firebase App Check. Linking is
uid-preserving on the happy path (no data migration at all); the one genuinely hard case — the
chosen account already has its own history — is resolved by an explicit, in-memory
read-before-switch-then-write sequence forced by Firestore's ownership-based Security Rules, never
by an automatic merge or silent discard. Also introduces the app's first Settings screen: category
management (create/rename/recolor/reorder/archive), currency/time-zone preferences, and account
deletion (a Phase-4 item pulled forward here because the acceptance criteria asked for it).

## Technical Context

**Language/Version**: Dart (Flutter, latest stable channel), SDK `^3.12.2`

**Primary Dependencies**: `firebase_auth`, `cloud_firestore`, `flutter_riverpod`, `go_router`
(all existing) — plus **`firebase_app_check ^0.4.6`**, **`google_sign_in ^7.2.0`**, and
**`sign_in_with_apple ^8.1.0`**, added by this feature for the first time (`docs/ROADMAP.md`
Phase 3 names all three)

**Storage**: Firestore (existing). No new collections — widens `users/{userId}` (adds
`currencyCode`, already reserved but unvalidated since `006`) and its `categories` subcollection
(no schema change, new write operations only). See `data-model.md`.

**Testing**: `flutter_test`, `mocktail`, `fake_cloud_firestore`, `firebase_auth_mocks`,
`@firebase/rules-unit-testing` (all existing patterns) — `google_sign_in`/`sign_in_with_apple`
credential exchange itself is platform-SDK territory and is exercised through `FirebaseAuth`
fakes/mocks at the repository boundary, not through the real provider SDKs in automated tests

**Target Platform**: iOS 15+, Android API 24+ (existing, unchanged)

**Project Type**: Mobile app (Flutter), feature-first Clean Architecture (existing convention)

**Performance Goals**: No change to the capture path's <3s p90 budget (Constitution Principle 1) —
App Check activation is fire-and-forget at `bootstrap()` start, never awaited before `runApp()`
(`research.md` #9)

**Constraints**: Offline-first for everything already offline-first (expense logging, history);
linking/conflict-resolution/account-deletion are the first genuinely network-required user actions
in this app's history and must fail *loudly and recoverably* rather than silently when offline
(FR-006) — a deliberate, documented exception to "offline is the normal case," not a
contradiction of it, since these operations are inherently about reaching a remote identity
provider. Security Rules remain the only real access boundary (Principle 7); App Check is an
additional layer, not a replacement for rules-level ownership checks.

**Scale/Scope**: One widened feature module (`lib/features/auth/`), one new feature module
(`lib/features/settings/`), widened `CategoryRepository`/`UserProfileRepository`, two Security
Rules changes, ~15-20 new ARB keys across 5 locales, the app's first three-destination nav bar,
zero new Firestore collections

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|---|---|---|
| P1 — Logging path is sacred | Linking/Settings/App Check are entirely new routes/screens; nothing in `ExpenseCapturePage` or its controller is touched. App Check activation is fire-and-forget, never blocks `runApp()` (`research.md` #9). Currency preference is read synchronously from an already-warm provider, never awaited mid-capture (`research.md` #5). | PASS |
| P2 — Offline-first, always | Expense logging/history/Wrapped remain fully offline-first, unchanged. Linking/conflict-resolution/deletion are the first network-*required* actions this app has — explicitly scoped that way (FR-006 requires them to fail loudly, not silently, when offline), which is the correct offline-first behavior for an operation that is inherently about reaching a remote identity provider, not a violation of the principle. | PASS |
| P3 — Anti-goals are binding | No income/debt/budgets/recurring/OCR/multi-currency-*conversion*/web-desktop/third-environment/local-SQL introduced. Changing the `currencyCode` *preference* is explicitly not conversion (`docs/DATA_MODEL.md`, amended) — Anonymous auth is explicitly *not* an anti-goal, and this feature is exactly the "no mandatory account creation, but not unauthenticated" case the constitution already names. | PASS |
| P4 — Layer boundaries enforced | `LinkConflict`/`LinkConflictResolution` are plain domain entities, Flutter/Firebase-free. `AuthRepository`/`CategoryRepository`/`UserProfileRepository` widened, not replaced — implementations stay in `data/`, confined to Firebase SDK types. `google_sign_in`/`sign_in_with_apple` credential objects never cross into `domain/` — converted to a `AuthCredential` at the `data/` boundary, same pattern `FirebaseAuthRepository` already uses. | PASS |
| P5 — Money is exact and private | No monetary values touched by this feature at all — linking/deletion/category management/currency-preference are identity and metadata operations. `currencyCode` stays a plain ISO string, never a computed/converted amount. No new analytics events add monetary data. | PASS |
| P6 — Environments isolated/symmetric | App Check provider selection (`Debug` vs `Play Integrity`/`App Attest`) is keyed off the existing `AppEnvironment` enum, the same conditional `showDebugBanner` already uses — the debug provider is structurally absent from `prod` builds via the same tree-shaking mechanism (`research.md` #4). Debug token registered against `wrap-my-finances-dev` only, never `prod`. | PASS |
| P7 — Security Rules are the only real boundary | Two additive rule changes (`contracts/security-rules-delta.md`): `currencyCode` gets real validation (closing a gap `006` deliberately deferred to "a future feature"), and owner-delete is enabled on `users/{userId}` and its `categories` subcollection (closing the gap `docs/DATA_MODEL.md` already flagged as "a separate, audited flow... handled outside these rules"). App Check is documented as an *additional* layer (`research.md` #4) — it does not replace or weaken rules-level ownership checks. | PASS (two real gaps identified and closed, not deferred) |
| P8 — Accessible by construction | Settings screen (category management, account, preferences) built from the same design-system primitives (`AppButton`, `AppCard`, `AppTextField`, `AppChip`) already accessibility-hardened by prior features — 48×48dp targets, WCAG AA contrast, semantic labels, 200% text scale, color never the only signal on category tiles (already established by `004`'s capture picker, reused here). | PASS |
| P9 — Localized and consistent by construction | Every new string is a `settings_*`-prefixed ARB key across all 5 locales (`research.md` #10), no native-review flag required (unlike `wrapped_*`). All new UI built from existing `context.colors`/`.typography`/`.spacing` tokens — no new token file needed (unlike `006`'s motion tokens; this feature introduces no new animation). Category rename-becomes-user-category conversion reuses the existing `nameKey`/`name` invariant exactly, never bypasses it. | PASS |

No violations requiring `Complexity Tracking`.

## Project Structure

### Documentation (this feature)

```text
specs/007-account-linking-integrity/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   ├── auth-linking-api.md
│   ├── category-management-api.md
│   └── security-rules-delta.md
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

Single Flutter project, feature-first Clean Architecture — the established structure every prior
feature (`003`–`006`) already follows. This feature widens `auth`/`categories`/`user_profile` and
adds one new `settings` feature module:

```text
lib/
├── bootstrap.dart                              # + fire-and-forget FirebaseAppCheck.activate()
├── app.dart                                    # + /settings route, AppShell gets a 3rd destination
├── core/
│   └── navigation/app_shell.dart               # + Settings nav item
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── link_conflict.dart                    # NEW
│   │   │   │   └── link_conflict_resolution.dart         # NEW
│   │   │   └── repositories/auth_repository.dart          # + isLinked, linkWith*, resolveLinkConflict, deleteAccount
│   │   └── data/
│   │       └── repositories/firebase_auth_repository.dart # + implementations, LinkConflictFailure mapping
│   ├── categories/
│   │   ├── domain/repositories/category_repository.dart   # + getAll, create, update, reorder, setActive
│   │   └── data/
│   │       ├── datasources/category_remote_data_source.dart
│   │       └── repositories/category_repository_impl.dart
│   ├── user_profile/
│   │   ├── domain/
│   │   │   ├── entities/user_profile.dart                 # + currencyCode
│   │   │   └── repositories/user_profile_repository.dart  # + updateCurrencyCode, updateTimeZone
│   │   └── data/...                                        # widened accordingly
│   └── settings/                                # NEW feature module
│       └── presentation/
│           ├── pages/
│           │   ├── settings_page.dart                      # entry: sections for account/categories/prefs
│           │   ├── category_management_page.dart
│           │   └── link_conflict_page.dart                 # merge-or-discard decision screen
│           └── widgets/
│               ├── category_editor_sheet.dart               # create/rename/recolor/re-icon
│               ├── currency_picker.dart
│               └── timezone_picker.dart
├── core/errors/failure.dart                     # + LinkConflictFailure
└── l10n/*.arb                                   # + settings_* keys, 5 locales (research.md #10)
firestore.rules                                  # + currencyCode validation, owner-delete (contracts/security-rules-delta.md)
firebase/tests/users.rules.test.js               # + delete/currencyCode cases
firebase/tests/categories.rules.test.js          # + delete cases

test/
├── features/auth/...
├── features/categories/...
├── features/user_profile/...
├── features/settings/...
└── security_rules covered via firebase/tests/ (JS, not Dart — established 006 pattern)
```

**Structure Decision**: One new feature module (`settings`), matching the existing
`lib/features/` convention with a `presentation/`-only footprint (it owns no new domain entities
of its own beyond the tiny `LinkConflict`/`LinkConflictResolution` pair, which live in `auth/`
since that's the domain they actually belong to). Three existing feature modules
(`auth`, `categories`, `user_profile`) are widened additively — no existing member of any of their
contracts changes signature or behavior; everything new is a new method or a new optional field.

## Complexity Tracking

No violations — Constitution Check above is a clean PASS on every principle. This section is
intentionally empty per the template's own instruction ("Fill ONLY if Constitution Check has
violations that must be justified").
