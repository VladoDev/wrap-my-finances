# Quickstart: Captura de Gasto en Menos de Tres Segundos

Validation steps for this feature, once implemented. Each step should be run in order; later steps
assume earlier ones passed.

## Prerequisites

- `flutter pub get` — picks up the new `firebase_analytics` dependency (see research.md)
- `flutter gen-l10n` — regenerates `AppLocalizations` with the new `category_*` and UI keys
  (data-model.md)
- `dart run build_runner build` — regenerates `injection.config.dart` for the new
  `@LazySingleton`/`@injectable` registrations (`ExpenseRepositoryImpl`, `CategoryRepositoryImpl`,
  `FirebaseAnalyticsService`, `LogExpense`, `SeedDefaultCategoriesUseCase`)
- Firestore emulator running locally, or a `dev`-flavor build against the real `wrap-my-finances-dev`
  project

## 1. App opens directly to the capture screen (FR-001)

`flutter run --flavor dev -t lib/main_dev.dart` on a fresh install. Confirm: the first frame shown
is the amount keypad — no dashboard, no loading indicator, no welcome screen. Only the existing
dev-ribbon banner (from `001`/`003`) may also be visible.

## 2. Two-tap logging, no confirmation step (FR-002, FR-004, FR-005)

Type a non-zero amount, tap "Next" (`commonContinue`), tap any category in the sheet that appears.
Confirm: the expense is logged with exactly those two taps; no confirmation dialog appears at any
point; success feedback (visual + haptic) appears immediately, not after a delay; the screen returns
to its empty initial state, ready for another entry.

## 3. No network is never an error (FR-013)

Enable airplane mode. Repeat step 2. Confirm: identical behavior to step 2 — the expense logs
successfully, the same success feedback appears, and no error, warning, or offline indicator is ever
shown on this path.

## 4. Zero amount cannot advance (FR-010)

With the amount at `0`, confirm the "Next" button is visible but disabled, and the screen layout is
pixel-identical to when it's enabled (no reflow).

## 5. Decimal and maximum-amount input rules (FR-009, FR-011)

Type digits including a decimal separator; confirm live thousands grouping and that a second
decimal separator or a third decimal digit is silently ignored. Type past 1,000,000.00; confirm
input freezes at the cap with no error shown.

## 6. Categories seeded and ordered by frequency (FR-006, FR-007)

On a fresh install, open the category sheet immediately after the first amount entry. Confirm seven
default categories already exist, each showing a name in the device's active language (switch device
language and relaunch to confirm at least one other locale). Log several expenses against the same
category; confirm it rises to the front of the sheet, ordered ahead of less-used categories, with no
scrolling required to reach it.

## 7. Local-write failure is non-blocking and preserves the amount (FR-012)

(Requires a debug hook or device-storage-exhaustion simulation — see implementation notes for the
test double used in `test/features/expenses/data/repositories/expense_repository_impl_test.dart`.)
Force a local write failure. Confirm: a non-blocking snackbar appears with a retry action; the typed
amount remains visible on screen; the app is not otherwise blocked.

## 8. Timing instrumentation (FR-003, SC-001)

Repeat step 2 several times. In the Firebase Analytics DebugView (or emulator logs), confirm each
run emits one `time_to_log_expense` event carrying a `duration_ms` integer parameter and nothing
else — no amount, no category name, no note (Constitution Principle 5). Confirm p90 across the runs
is under 3000ms.

## 9. Design-system and localization compliance (FR-015)

Run the existing `test/core/design_system/tokens/no_raw_hex_colors_test.dart` and
`test/l10n/arb_keys_complete_test.dart` — both must still pass unmodified, confirming no new hex
literal or missing translation was introduced. Visually inspect the capture screen and category
sheet at 200% text scale in French (the documented worst case per `docs/UI_UX_SPEC.md` §7) for
clipping or overflow.

## 10. Full automated suite

```sh
flutter analyze
dart format --output=none --set-exit-if-changed lib test
flutter test
flutter test integration_test/expense_capture_flow_test.dart
```

All must pass. The integration test exercises the full flow (type amount → tap Next → tap category →
persisted, category usage incremented, screen reset) against `fake_cloud_firestore` +
`firebase_auth_mocks` — no real network involved at any point, satisfying the "modo sin red"
requirement without depending on real device connectivity toggling.
