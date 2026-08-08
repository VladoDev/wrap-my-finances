# Implementation Plan: Fundación de Entornos (dev / prod)

**Branch**: `001-environment-foundation` | **Date**: 2026-08-07 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-environment-foundation/spec.md`

## Summary

Bootstrap the Flutter project with two independent build flavors (`dev`, `prod`), each wired to
its own Firebase project, each installable side by side on one device with distinct identity. A
pure-Dart startup guard rejects any build where the native flavor and the Dart entrypoint
disagree, before any Firebase connection is attempted. A minimal, temporary diagnostics screen
(replaced by real product screens in later features) shows the active environment and lets `dev`
write a probe document, which is the mechanism used to prove data isolation between projects.
Firestore Security Rules and indexes are deployed to both projects from the same repository
files, with the default CLI target pointed at `dev` and `prod` gated behind an explicit alias.
A silent anonymous sign-in (no UI, no account linking) runs during `bootstrap()` so the Security
Rules can require an authenticated session on every write, including the probe write itself —
this pulls forward only the sign-in call from `ROADMAP.md` Phase 1, not that phase's account
-linking or in-memory-buffering concerns.

Technical approach: native flavor configuration (Android product flavors, iOS build
configurations/schemes) generated once via `flutter_flavorizr` and then committed and
hand-maintained; two `flutterfire configure` runs producing committed `firebase_options_*.dart`
files; a small `core/config` module (`AppEnvironment`, flavor-consistency check) and a small
`core/diagnostics` module (probe entity, Firestore-backed repository, one page) that follow the
same Clean Architecture layering as every other feature, even though the diagnostics module itself
is disposable scaffolding.

## Technical Context

**Language/Version**: Dart / Flutter, latest stable channel (unpinned per `TECH_STACK.md`;
`pubspec.lock` is the source of truth)

**Primary Dependencies**: `firebase_core`, `cloud_firestore`, `firebase_auth` (anonymous sign-in
only — no UI), `get_it` + `injectable` (environment singleton registration), `flutter_launcher_icons`
(per-flavor icons), `flutter_flavorizr` (one-time native scaffolding tool, removed from
`pubspec.yaml` once native config is committed and stable)

**Storage**: Cloud Firestore — two isolated projects (`wrap-my-finances-dev`,
`wrap-my-finances-prod`), one new top-level collection for this feature (see `data-model.md`)

**Testing**: `flutter_test` (unit test for the flavor-consistency guard and the probe
repository against `fake_cloud_firestore`); `@firebase/rules-unit-testing` against the local
emulator for the new Security Rules block

**Target Platform**: iOS 15+, Android API 24+ (per `TECH_STACK.md`; web/desktop are anti-goals) —
raised from the originally-planned iOS 14+ mid-implementation when the Firebase iOS SDK's Swift
Package Manager integration required 15.0

**Project Type**: Mobile app (Flutter, iOS + Android)

**Performance Goals**: None beyond baseline Flutter + Firebase cold start; this feature predates
the numeric keypad, so the 3-second logging budget (Constitution Principle 1) does not apply yet

**Constraints**: The probe write must succeed with no network connection and use a client-generated
document ID (Constitution Principle 2); `lib/main.dart` must not exist, forcing every run/build
command to state `-t` explicitly (per `ENVIRONMENTS.md` §2-3)

**Scale/Scope**: One diagnostics screen, two entrypoints, native config for two flavors, one
Firestore collection, one Security Rules block — no product features

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Applies? | Assessment |
|---|---|---|
| 1. The Logging Path Is Sacred | No | No keypad or logging UI exists yet; nothing in this feature touches the logging path. |
| 2. Offline-First, Always | Yes | The probe write uses a client-generated ID (`collection.doc()`), never awaits server ack before confirming, and does not sort/group by `serverTimestamp()`. Satisfied by design (see `data-model.md`). |
| 3. Anti-Goals Are Binding | Yes | This feature introduces no income/debt/budget/recurring/OCR/multi-currency/web/desktop/third-environment/local-SQL functionality. It does pull forward the anonymous *sign-in call* from `ROADMAP.md` Phase 1, which the constitution explicitly permits: "Anonymous authentication is NOT an anti-goal." No visible auth UI, account linking, or account management is added — that remains Phase 3. |
| 4. Layer Boundaries Are Enforced | Yes | The diagnostics probe gets its own thin `domain` (entity + repository interface), `data` (Firestore impl), and `presentation` (one page) split under `core/diagnostics/`, even though it is temporary — no exception is made for scaffolding code. `domain/` stays free of Firebase/Flutter imports. |
| 5. Money Is Exact and Private | No | No monetary values or telemetry are introduced by this feature. |
| 6. Environments Are Isolated and Symmetric | Yes | This is the feature's core purpose: two flavors, two Firebase projects, symmetric rules/indexes, `default` alias on `dev`. |
| 7. Security Rules Are the Only Real Boundary | Yes | The `env_checks` rule requires `request.auth != null` in addition to field/type/size validation, and ends with the existing trailing catch-all. It has no per-user ownership check, but ownership does not apply here: the probe document represents no user data and belongs to no specific account — the same way `firestore.rules`' catch-all itself has no owner concept. |
| 8. Accessible by Construction | Yes | The diagnostics screen's environment label and probe-write control meet the 48×48dp tap target and WCAG AA contrast rules despite being temporary UI. |

**Initial gate result**: PASS. No unresolved violations and no Complexity Tracking entries are
required — requiring `request.auth != null` on `env_checks` brings this feature into full
compliance with Principle 7 rather than needing a documented deviation from it.

**Post-Phase 1 re-check**: PASS, unchanged. `data-model.md` confirms the `env_checks` rule
requires an authenticated session plus field/type/size validation, ending in the existing trailing
catch-all (Principle 7 satisfied); the probe entity is a client-generated-ID, no-`serverTimestamp`
design (Principle 2 satisfied); the anonymous sign-in added to `bootstrap()` has no UI and no
account-linking logic, so no anti-goal-listed or Phase-3 functionality was introduced (Principle 3
satisfied); no money, analytics, or anti-goal-listed functionality was introduced during design
(Principle 5 unaffected); the diagnostics module keeps `domain/data/presentation` separation with
no Firebase import in `domain/` (Principle 4 satisfied).

## Project Structure

### Documentation (this feature)

```text
specs/001-environment-foundation/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

No `contracts/` directory: this feature exposes no interface to other systems or clients — it is
an internal app-bootstrap concern (native build config, Firebase project wiring, one diagnostics
screen).

### Source Code (repository root)

```text
android/
└── app/
    ├── build.gradle.kts              # productFlavors { dev, prod }, applicationIdSuffix
    └── src/
        ├── dev/google-services.json      # gitignored, from flutterfire configure
        └── prod/google-services.json     # gitignored, from flutterfire configure

ios/
├── flavors/
│   ├── dev/GoogleService-Info.plist      # gitignored, from flutterfire configure
│   └── prod/GoogleService-Info.plist     # gitignored, from flutterfire configure
└── Runner.xcodeproj/                     # 6 build configurations + dev/prod schemes

lib/
├── main_dev.dart                     # entrypoint, dev flavor
├── main_prod.dart                    # entrypoint, prod flavor
├── bootstrap.dart                    # Firebase init, flavor-consistency guard, anonymous
│                                      # sign-in (silent, no UI), DI, runApp
├── app.dart                          # MaterialApp.router, single diagnostics route
└── core/
    ├── config/
    │   ├── app_environment.dart          # AppEnvironment enum (dev/prod)
    │   ├── flavor_guard.dart             # pure function: validates appFlavor vs AppEnvironment
    │   ├── firebase_options_dev.dart     # generated by flutterfire, committed
    │   └── firebase_options_prod.dart    # generated by flutterfire, committed
    ├── di/
    │   ├── injection.dart                # configureDependencies(AppEnvironment)
    │   └── injection.config.dart         # generated
    └── diagnostics/
        ├── domain/
        │   ├── entities/environment_probe.dart
        │   └── repositories/environment_probe_repository.dart
        ├── data/
        │   └── repositories/firestore_environment_probe_repository.dart
        └── presentation/
            └── pages/environment_status_page.dart

firestore.rules             # includes the env_checks block, deployed to both projects
firestore.indexes.json      # unchanged by this feature (no new queries need an index)
.firebaserc                  # default → dev, explicit dev/prod aliases
firebase.json                 # emulator config, iOS build-config → project mapping

test/
└── core/
    ├── config/flavor_guard_test.dart
    └── diagnostics/data/firestore_environment_probe_repository_test.dart
```

**Structure Decision**: Single Flutter mobile project (no separate backend/frontend split — the
"backend" is Firebase, configured, not coded). The diagnostics probe lives under `core/` rather
than `features/` because it is not a product feature: it exists solely to prove environment
isolation and is expected to be deleted once a real feature (e.g., expense logging) provides a
natural way to verify the same thing. It still respects the full Clean Architecture layering so
removing it later is a deletion, not a refactor.

## Complexity Tracking

*No entries.* Requiring `request.auth != null` on the `env_checks` collection satisfies
Principle 7 directly rather than needing a documented deviation. The only scope note worth
recording here is non-complexity: only the anonymous *sign-in call* moves from `ROADMAP.md`
Phase 1 into this feature — Phase 1's harder concerns (in-memory buffering of writes made before
the UID resolves, account linking, Settings UI) are untouched and remain there.
