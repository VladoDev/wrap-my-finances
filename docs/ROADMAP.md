# Roadmap

Five phases. Each is independently shippable to the `dev` flavor via Firebase App Distribution;
only Phase 4 goes to the stores.

---

## Phase 0: Foundations — Flavors & Environments

**Goal:** Two working environments before a single feature is written.

This phase exists because retrofitting flavors is expensive: the Android `applicationId` and iOS
bundle ID are immutable after the first store submission, and separating a polluted production
Firestore from test data after the fact is far harder than never mixing them.

- Bootstrap the Flutter project with `very_good_analysis`.
- Create the `dev` and `prod` Firebase projects, provision Firestore in each, enable Anonymous
  auth. See [ENVIRONMENTS.md § 5](ENVIRONMENTS.md).
- Configure Android product flavors and iOS build configurations and schemes.
- Generate `firebase_options_dev.dart` / `firebase_options_prod.dart` via `flutterfire configure`.
- Implement `AppEnvironment`, `bootstrap()`, and the flavor-mismatch startup assertion.
- Per-flavor app icons and display names.
- Wire `.firebaserc` aliases; deploy rules and indexes to both projects.
- Set up the local emulator suite.
- CI on GitHub Actions: analyze, test, build both flavors.
- Set a Cloud Billing alert on the prod project.

**Done when:** `flutter run --flavor dev -t lib/main_dev.dart` and the `prod` equivalent both
launch, write to their own Firestore project, and can be installed side by side on one device.

---

## Phase 1: Local MVP & Frictionless Entry

**Goal:** The core 3-second logging experience with offline persistence.

- Configure `get_it`, `injectable`, and `go_router`.
- Implement the Design System — theme, semantic color tokens, typography, spacing — with golden
  tests.
- **Anonymous sign-in during `bootstrap()`**, non-blocking, with the in-memory buffer for
  expenses logged before the UID resolves.
- Set up `l10n.yaml`, `flutter_localizations`, and `gen_l10n`.
- Author all five ARB files (`en`, `es`, `pt`, `it`, `fr`), including the `category_*` keys for
  every default category, per the key convention in TECH_STACK.md § Localization.
- Add the CI check that fails the build on any missing translation key in any locale.
- Enable Firestore offline persistence with unlimited cache.
- Build the custom oversized numeric keypad, including decimal, maximum, and formatting rules.
- Seed default categories on first launch.
- Build the category selection bottom sheet, ordered by `usageCount`.
- Implement the `Money` value object and integer-minor-unit storage.
- Riverpod controllers for entry state; `LogExpense` use case.
- Deploy and test Security Rules against the emulator.

> Anonymous auth is in Phase 1, not Phase 3. Security Rules require `request.auth != null`, so
> **no expense can be written to Firestore at all until authentication exists.** A "local-only
> MVP" that skips this either has no persistence or has wide-open rules — both are dead ends.

**Done when:** an expense can be logged in under 3 seconds, in airplane mode, on a fresh install,
and appears on another device after reconnecting.

---

## Phase 2: The Wrapped Experience

**Goal:** The monthly summary that drives retention.

- `monthKey` aggregation queries and the client-side fold into a `MonthlySummary` entity.
- Full-screen story UI: progress bars, tap/long-press/swipe controls.
- Spring-physics animations via `flutter_animate`, with reduce-motion fallbacks.
- Count-up number animations.
- Shareable card rendered from a `RepaintBoundary`, with the amount-visibility toggle.
- Trigger logic driven by `wrappedLastSeenMonth` and the user's time zone.
- The under-5-expenses suppression rule and the partial-sync state.
- Manual entry point in Settings for past months.

**Done when:** a user with a month of data sees Wrapped exactly once on the first open of the new
month, can navigate it fully, and can share a card.

---

## Phase 3: Accounts, Integrity & Management

**Goal:** Secure the data and let users keep it.

- Firebase App Check — Play Integrity on Android, DeviceCheck/App Attest on iOS.
- Google and Apple Sign-In to convert anonymous accounts, with correct handling of the
  credential-already-in-use case (linking an anonymous account to an existing one).
- Settings screen: currency, time zone, haptics, account.
- Manual category management — add, rename, recolor, reorder, archive.
- Security Rules test suite expanded and running in CI.

**Done when:** a user can reinstall the app, sign in, and recover their history.

---

## Phase 4: Polish & Store Release

**Goal:** Production-ready and submitted.

- Firebase Crashlytics and Analytics, with the `time_to_log_expense` and
  `wrapped_completion_rate` events and the no-financial-data-in-telemetry rule enforced.
- Timeline screen with swipe-to-delete, soft delete, and undo.
- 30-day purge of soft-deleted expenses.
- Haptic feedback across the app, respecting the Settings toggle.
- Accessibility audit: contrast, tap targets, semantic labels, 200% text scale.
- Native-speaker translation quality review across all five locales, prioritizing the
  `wrapped_*` copy flagged for human review in the ARB files.
- Account deletion flow (required by both stores).
- Privacy policy, App Store privacy nutrition labels, Play Data Safety form.
- QA on physical iOS and Android devices, including a low-end Android and airplane-mode runs.
- Store assets highlighting the Wrapped feature.
- Submit to App Store and Google Play from the `prod` flavor.

**Done when:** the app is live in both stores.

---

## Explicitly deferred

Not scheduled, and not to be pulled forward without revisiting PRODUCT_CONTEXT.md § Anti-Goals:

- A `staging` environment
- Dark mode
- Precomputed `monthlySummaries` documents
- Recurring expenses, receipt capture, budgets, income
- Web or desktop targets
- A local SQL database alongside the Firestore cache
