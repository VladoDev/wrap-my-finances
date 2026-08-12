# Quickstart: Historial de Gastos con Borrado Reversible

Validation steps for this feature, once implemented. Each step assumes earlier ones passed.

## Prerequisites

- `flutter gen-l10n` — regenerates `AppLocalizations` with the new keys (data-model.md)
- `dart run build_runner build` — regenerates `injection.config.dart` for the new
  `@injectable`/`@LazySingleton` registrations
- Firestore emulator running locally, or a `dev`-flavor build against `wrap-my-finances-dev`

## 1. Capture is still the launch destination (FR-012)

`flutter run --flavor dev -t lib/main_dev.dart` on a fresh install. Confirm the first frame is the
capture screen. Navigate to History, background the app (or kill and relaunch), reopen. Confirm the
first frame is the capture screen again — not History.

## 2. History groups by day with correct subtotals (FR-001, FR-002, SC-001)

Log a handful of expenses across at least two different days (adjust the device clock or use
existing seeded data). Open History. Confirm expenses are grouped by day, newest day first,
newest-within-day first, and each day's subtotal equals the sum of that day's `amountMinor`.

## 3. Category identity without color (FR-003, FR-004)

Confirm each entry shows amount, category, and time, and that the category's icon+label alone
(with color hidden or in grayscale, e.g. via an accessibility inspector) still identifies it
unambiguously.

## 4. Swipe-to-delete, no confirmation, instant exclusion (FR-005, FR-006, SC-002)

Swipe an entry away. Confirm: no dialog appears; the entry and its amount leave the day subtotal
immediately (under a visible frame, not after a network round trip).

## 5. Undo restores exactly, no second write (FR-007, FR-008, FR-009, SC-003)

Swipe an entry, tap "Deshacer" before the window closes. Confirm it reappears in its original
position with identical data. Inspect the Firestore document directly (emulator UI or REST API, per
`004`'s quickstart precedent) and confirm `deletedAt` was never set during this sequence.

## 6. Undo window expiry writes exactly once (FR-009)

Swipe an entry and let the window expire without tapping "Deshacer". Confirm the document's
`deletedAt` is now set (one write), and the entry does not reappear.

## 7. Backgrounding confirms pending deletions (Edge Case)

Swipe an entry, then immediately background the app before the window would normally expire.
Reopen. Confirm the deletion is already confirmed (`deletedAt` set), not still pending.

## 8. Offline parity (FR-010, SC-004)

Enable airplane mode. Repeat steps 4–6. Confirm identical behavior and timing to steps 4–6 with
connectivity.

## 9. Empty state (FR-014)

On an account with zero expenses (or after deleting all of them and letting their windows expire),
open History. Confirm an illustrated, warm empty state renders — not a plain "no data" string.

## 10. 30-day purge (FR-015, SC-006)

Seed an expense with `deletedAt` set more than 30 days in the past (directly via the emulator/REST
API — not reachable through the UI). Relaunch the app. Confirm the document no longer exists after
relaunch, while a soft-deleted expense less than 30 days old still exists (hidden, not gone).

## 11. No regression to the 004 logging path (FR-013, SC-005)

Run `flutter test integration_test/expense_capture_with_history_shell_test.dart -d <simulator>`.
Confirm the exact two-tap flow (amount → "Continuar" → category) still completes and persists
correctly with the full navigation shell (floating nav bar, both routes registered) present in the
tree — no additional screen, dialog, or tap introduced.

## 12. Full automated suite

```sh
flutter analyze
dart format --output=none --set-exit-if-changed lib test integration_test
flutter test
flutter test integration_test/ -d <simulator>
```

All must pass, including `004`'s original suite (unmodified) and this feature's own tests.
