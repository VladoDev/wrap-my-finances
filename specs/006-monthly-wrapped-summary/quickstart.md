# Quickstart: Resumen Mensual Animado y Compartible

Validation steps for this feature, once implemented. Each step assumes earlier ones passed.

## Prerequisites

- `flutter gen-l10n` — regenerates `AppLocalizations` with the new `wrapped_*` keys (data-model.md)
- `dart run build_runner build` — regenerates `injection.config.dart` for the new
  `@injectable`/`@LazySingleton` registrations (`UserProfileRepositoryImpl`,
  `WrappedRepositoryImpl`, `EnsureUserProfileUseCase`)
- `pubspec.yaml` includes `flutter_animate` and `share_plus` (research.md #4) — run
  `flutter pub get` after pulling
- Firestore emulator running locally with the updated `firestore.rules`
  (`contracts/security-rules-delta.md`) deployed, or a `dev`-flavor build against
  `wrap-my-finances-dev` with the same rules deployed
- Seed at least one month with 5+ non-deleted expenses across at least two categories, and one
  month with 1–4 non-deleted expenses, to exercise both the auto-trigger and suppressed paths

## 1. Capture is still the launch destination, untouched (Constitution Principle 1)

`flutter run --flavor dev -t lib/main_dev.dart` on a fresh install. Confirm the first frame is the
capture screen and its time-to-log is not perceptibly slower than before this feature — the
auto-trigger check must never block or delay first paint (research.md #7).

## 2. `users/{uid}` is created on first launch (research.md #1)

On a fresh install, inspect the Firestore document directly (emulator UI or REST API, per `004`'s
quickstart precedent). Confirm `users/{uid}` exists with `uid` and a non-empty `timeZone`, and
`wrappedLastSeenMonth` absent or `null` — created without blocking the capture screen.

## 3. Automatic trigger on first open of a new month (FR-001, FR-002, SC-001, SC-002)

With a seeded month of 5+ expenses as "last month" and `wrappedLastSeenMonth` unset, open the app.
Confirm the Wrapped sequence appears automatically, unprompted. Dismiss it, relaunch the app.
Confirm it does not appear again. Repeat the relaunch from a second signed-in device/session
sharing the same account and confirm it also does not appear there.

## 4. Suppression under 5 expenses (FR-003)

With a seeded month of 1–4 expenses as "last month," open the app. Confirm Wrapped does **not**
appear automatically. Open History and confirm a small, dismissible card offers that month's
summary. Tap it and confirm the full sequence opens on demand.

## 5. Dismissing marks the month seen (FR-004)

From either path above, dismiss Wrapped (swipe down, or let it finish). Inspect
`users/{uid}.wrappedLastSeenMonth` and confirm it now equals that month's key.

## 6. Manual access to any past month (FR-005)

From History, open the month picker affordance (research.md #3) and select a past month with data,
regardless of whether it was already seen. Confirm its summary opens with the same figures as if
shown automatically.

## 7. Story navigation: advance, back, pause, dismiss (FR-006, FR-007)

Open any Wrapped sequence. Confirm: it auto-advances every 5–7 seconds with a visible progress bar;
tapping the right side advances immediately; tapping the left side goes back one scene (no-op on
the first); holding a touch down pauses the auto-advance and releasing resumes it; swiping down
dismisses immediately from any scene.

## 8. Reduce motion collapses animation, not functionality (FR-008)

Enable the OS-level reduce-motion setting. Reopen a Wrapped sequence. Confirm every scene's numbers
render at their final value immediately (no count-up) and transitions between scenes are short
cross-fades, not spring/bounce — while advance/back/pause/dismiss still work identically to step 7.

## 9. Content correctness against known data (FR-009, FR-010, FR-011, SC-003, SC-004)

Using a month with a known, hand-computed set of non-deleted expenses across multiple categories,
plus at least one deleted expense in that month: confirm the total, top category, that category's
transaction count, and the biggest single expense exactly match the hand computation, and that the
deleted expense does not affect any of the four figures. Rename the top category after logging its
expenses; reopen the summary and confirm it shows the new name.

## 10. Partial-sync state (FR-012)

Simulate an incomplete local cache for a month that has more documents server-side than locally
(e.g. a fresh install before the initial sync completes, or directly clearing the local cache while
offline). Attempt to open that month's summary. Confirm it shows a syncing indicator instead of any
total.

## 11. Shareable card defaults to no amounts (FR-013, FR-014, FR-015, SC-005, SC-006)

Reach the final scene and share without touching any toggle. Inspect the generated image (not a
device screenshot) and confirm it shows the top category, transaction count, and month — no
monetary figure — sized for a 9:16 story frame. Activate the visible amounts toggle and share
again; confirm the regenerated image now includes the monetary figures.

## 12. Localization (FR-016, SC-007)

Switch the device language to each of the five supported locales in turn. Open a Wrapped sequence
in each. Confirm every string renders translated (no missing-key fallback to `en`), and that
numbers/dates format per the active locale.

## 13. Analytics carries no financial data (FR-017, SC-008)

Inspect the analytics events fired during a full Wrapped session (e.g. via the Firebase DebugView
for the dev project). Confirm no event parameter contains a monetary amount, a category name, or
any other user-authored text — only a completion-ratio-style value and non-identifying metadata.

## 14. Security Rules

Run the Security Rules test suite (`contracts/security-rules-delta.md` § Required test additions)
against the emulator. Confirm all pass, including the pre-existing `/categories`/`/expenses` suite
unmodified.

## 15. Full automated suite

```sh
flutter analyze
dart format --output=none --set-exit-if-changed lib test integration_test
flutter test
flutter test integration_test/ -d <simulator>
```

All must pass, including `004`'s and `005`'s original suites (unmodified) and this feature's own
tests.
