# Quickstart: Cuentas Vinculadas e Integridad de la Aplicación

Validation steps for this feature, once implemented. Each step assumes earlier ones passed.

## Prerequisites

- `flutter gen-l10n` — regenerates `AppLocalizations` with the new `settings_*` keys
- `dart run build_runner build` — regenerates `injection.config.dart` for new
  `@injectable`/`@LazySingleton` registrations
- `firebase.rules` deployed to both projects with the delta from
  `contracts/security-rules-delta.md`
- **One-time manual provisioning (not scriptable without human confirmation)**:
  - Enable Google Sign-In and Sign in with Apple as Firebase Auth providers, for both
    `wrap-my-finances-dev` and `wrap-my-finances-prod`, in the Firebase Console.
  - Enable Play Integrity API (Android) and configure App Attest (iOS) for `prod`.
  - Register at least one App Check **debug token** against `wrap-my-finances-dev` only — never
    `prod`.
  - Enable Firestore App Check enforcement in the Firebase Console, **only after** confirming the
    client-side `activate()` call (research.md #4) is live in both flavors' latest builds.

## 1. Linking is optional and never interrupts (FR-001)

Use the app normally — log expenses, browse history — without ever opening Settings. Confirm no
prompt, banner, or blocking screen ever asks to create or link an account. Open Settings and
confirm a "link account" action is present as an ordinary, non-modal option.

## 2. Linking preserves the full anonymous history, no loss or duplication (FR-002, SC-001)

Log several expenses across multiple categories, create a custom category. From Settings, link a
Google or Apple account that has never been used with this app before. Confirm every expense and
category from before linking is still present immediately after, with no duplicates.

## 3. A second device recovers the full history (FR-003, SC-002)

From a second, fresh install (or a signed-out state), sign in with the account linked in step 2.
Confirm the complete history from step 2 appears, unprompted, once sign-in completes.

## 4. Linking to an account that already has its own history (FR-004, FR-005, SC-003)

Prepare an account with its own known history (e.g., the account from step 2). On a *different*
device/fresh install with its own distinct anonymous history, attempt to link that same account.
Confirm the app clearly states both histories exist and presents explicit choices — confirm
neither history changes until a choice is made.

- Choose "combine": confirm the result contains the full union of both histories, no losses.
- Repeat from a fresh conflict state, choose "keep only the account's history, discard this
  device's": confirm the app names what will be discarded and requires explicit confirmation
  before proceeding, and confirm the final state contains only the account's original history.

## 5. Linking offline does not corrupt state (FR-006, SC-004)

Enable airplane mode. Attempt to link an account. Confirm the app communicates the action is
unavailable right now. Confirm the local history is unchanged and expense logging still works
normally, offline, immediately after the failed attempt.

## 6. Illegitimate clients are blocked; the real app is unaffected (FR-007, FR-008, SC-005)

Attempt a direct Firestore read/write against the project using a client that does not present a
valid App Check token (e.g., a raw REST/SDK call outside the app). Confirm it is rejected.
Separately, use the real installed app (`dev` and `prod` builds) through its normal flows and
confirm nothing is blocked or degraded.

## 7. The dev debug mechanism works, and does not exist in prod (FR-009)

Run a `dev`-flavor build with its registered App Check debug token. Confirm Firestore reads/writes
succeed normally. Inspect a `prod`-flavor build/binary and confirm no debug-provider code path or
affordance is reachable.

## 8. Account deletion is permanent and explicitly confirmed (FR-010, FR-011, SC-006)

Sign in with an account that has data. From Settings, request account deletion. Confirm a distinct
explicit confirmation step exists before anything is deleted. Confirm it, then confirm the account
can no longer sign in and none of its expenses or categories are reachable afterward.

## 9. Category management from Settings (FR-012, FR-013)

From Settings, create a category, then rename/recolor/re-icon/reorder it, then archive it. Confirm
each change reflects immediately in the management screen and (where applicable) the capture
picker. Confirm a previously-logged expense referencing the archived category still displays it
correctly in History, and that the category no longer appears in the capture picker.

## 10. Renaming a default category converts it (FR-014)

Rename one of the seeded default categories (e.g., "Food") to custom text. Confirm it now behaves
as a user category: the literal text you typed persists across a locale change (it no longer
translates), matching `docs/DATA_MODEL.md`'s existing invariant.

## 11. Currency and time zone changes never touch past expenses (FR-015, FR-016, FR-017, SC-007)

Log an expense. From Settings, change the time zone. Confirm the expense's month assignment in
History is unchanged. Change the currency preference. Confirm the previously logged expense still
shows its original amount and currency, and log a new expense to confirm it uses the new
preference going forward.

## 12. Localization and design tokens (FR-018, SC-008)

Switch the device language across all five supported locales. Open Settings in each. Confirm every
string renders translated and every visual element uses existing design-system tokens (no raw hex
colors, no ad hoc `TextStyle`/spacing literals).

## 13. No regression to the capture path (Constitution Principle 1)

Run the existing `004`/`005` integration tests with this feature's full navigation (three-tab
shell, App Check active) present in the tree. Confirm the exact two-tap logging flow is unchanged
and still completes in the same time budget.

## 14. Full automated suite

```sh
flutter analyze
dart format --output=none --set-exit-if-changed lib test integration_test
flutter test
flutter test integration_test/ -d <simulator>
```

Plus the Security Rules suite:

```sh
firebase emulators:exec --only firestore "cd firebase/tests && npm test"
```

All must pass, including every prior feature's (`003`–`006`) original suite, unmodified.
