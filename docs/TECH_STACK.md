# Tech Stack

Versions are intentionally unpinned in this document. Use the latest stable release of each
package at bootstrap, let `pubspec.lock` be the source of truth, and commit it.

## Core Framework

- **Framework:** Flutter (latest stable channel)
- **Language:** Dart
- **Minimum target platforms:** iOS 15.0+, Android API 24+ — the Firebase iOS SDK (via Swift
  Package Manager) requires iOS 15.0 as of the versions resolved during Phase 0; raised from the
  originally-planned 14.0 when the real build failed with `Target Integrity` errors demanding 15.0
- **Targets:** iOS and Android only. Web and desktop are explicit anti-goals.

## Architecture & State Management

| Concern | Package | Scope |
| --- | --- | --- |
| Architecture pattern | — | Feature-first Clean Architecture |
| UI state | `flutter_riverpod` + `riverpod_annotation` | Presentation layer only |
| Infrastructure DI | `get_it` + `injectable` | Repositories, data sources, SDK singletons |
| Routing | `go_router` | Declarative, typed routes |
| Immutability | `freezed` + `freezed_annotation` | Entities, models, states, failures |
| Serialization | `json_serializable` | Data-layer models only |

### On running both GetIt and Riverpod

Two DI systems in one app is a smell unless the boundary is explicit, so it is defined here and
enforced in review:

- **GetIt/Injectable owns construction of infrastructure**: `FirebaseFirestore`,
  `FirebaseAuth`, data sources, repository implementations. These are environment-dependent
  (see ENVIRONMENTS.md) and are registered by `configureDependencies(AppEnvironment)`.
- **Riverpod owns everything reactive**: controllers, derived state, stream subscriptions,
  widget rebuilds.
- The bridge is a **single** provider per repository: `final expenseRepositoryProvider =
  Provider((ref) => getIt<ExpenseRepository>());`. Widgets never touch `getIt` directly.

If this boundary starts leaking, the correct fix is to delete GetIt and register infrastructure
as plain Riverpod providers overridden at the root — not to add a third pattern.

## Backend & Data Persistence

- **Platform:** Firebase, **two projects** (dev and prod) — see [ENVIRONMENTS.md](ENVIRONMENTS.md)
- **Authentication:** `firebase_auth`, anonymous by default, upgradeable to Google/Apple
- **Database:** `cloud_firestore`
- **Integrity:** `firebase_app_check` (Play Integrity on Android, DeviceCheck/App Attest on iOS)

### Offline strategy

The app relies on Firestore's built-in offline persistence rather than a separate local
database. Writes are applied to the local cache synchronously and the `Future` returned by
`set()` resolves only after the server acknowledges — so the UI **must not await it**. Fire the
write, update the UI from the local snapshot, and let reconciliation happen in the background.
This is what makes sub-second logging possible without a second storage engine.

Configuration:

```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

Three consequences that must be respected in the data layer:

1. **Document IDs are generated client-side** (`collection.doc()` with no argument) so an
   expense has a stable identity while offline.
2. **`FieldValue.serverTimestamp()` reads back as `null` from the local cache** until the write
   syncs. Never sort or group by it. See DATA_MODEL.md for the `createdAt` / `syncedAt` split.
3. **Queries served from cache only see cached documents.** Aggregations for Wrapped must
   tolerate partial data on a fresh install and say so in the UI rather than showing a wrong
   total.

The chosen approach is deliberately not a local SQL database. If Wrapped aggregation performance
or multi-year history ever forces one, that is a documented architectural change, not a quiet
addition.

## UI, Animations & Design System

- **Core UI:** Material 3 with a fully customized `ThemeData`
- **Animations:** `flutter_animate` — spring-physics curves for the Wrapped stories
- **Typography:** `google_fonts` (Nunito / Quicksand / Fredoka), with fonts **bundled as assets
  for the shipped build** rather than fetched at runtime, so first launch never blocks on network
- **Haptics:** `flutter/services` `HapticFeedback`, wrapped behind a `HapticsService` so it can
  be disabled in settings and stubbed in tests
- **Sharing:** `share_plus`, with the Wrapped card rasterized from a `RepaintBoundary`

## Build Flavors

- **Flavors:** `dev`, `prod` — native configuration per ENVIRONMENTS.md
- **Flavor bootstrap (optional, one-time):** `flutter_flavorizr` to generate Xcode configurations
  and schemes; removed from `pubspec.yaml` once native setup is committed and stable
- **Icons per flavor:** `flutter_launcher_icons`
- **Splash:** `flutter_native_splash`
- **Flavor detection at runtime:** `appFlavor` from `package:flutter/services.dart`

## Telemetry & Analytics

- **Crash reporting:** `firebase_crashlytics`
- **Usage tracking:** `firebase_analytics`

Core events focus on `time_to_log_expense` and `wrapped_completion_rate`. **No event parameter
may ever contain a monetary amount, a note, or a user-authored category name.** Amounts are
logged as bucketed enums if at all. This is a hard rule, not a guideline.

Dev-flavor telemetry goes to the dev Firebase project, so a debugging session never pollutes
production dashboards or crash-free-user rates.

## Testing

| Layer | Tooling |
| --- | --- |
| Unit (domain, use cases) | `test`, `mocktail` |
| Data layer | `fake_cloud_firestore`, `firebase_auth_mocks` |
| Rules | `@firebase/rules-unit-testing` against the emulator suite |
| Widget | `flutter_test` |
| Golden (design system) | `golden_toolkit` or `alchemist` |
| Integration | `integration_test` |

Security Rules tests run in CI on every pull request. Rules are the only thing standing between
one user's data and another's; they are not verified by hand-clicking the console.

## Code Generation & Tooling

- **Runner:** `build_runner` — `dart run build_runner watch -d` during development
- **Linting:** `very_good_analysis`
- **Riverpod lints:** `custom_lint` + `riverpod_lint`
- **Formatting:** `dart format` enforced in CI

## Utilities

- **Formatting:** `intl` for currency and date formatting, locale-aware
- **Money:** integer minor units, never `double` — see DATA_MODEL.md
- **Time zones:** the user's IANA time zone is stored and used for month boundaries, so a
  purchase at 23:50 on the last day of the month lands in the right Wrapped

## CI/CD

- **CI:** GitHub Actions — analyze, test, build both flavors on every PR
- **Dev distribution:** Firebase App Distribution from the `dev` flavor on merge to `main`
- **Store releases:** manual, tag-triggered, `prod` flavor only

Signing keys, App Store Connect credentials, and service-account JSON live in the CI secret
store and never in the repository.
