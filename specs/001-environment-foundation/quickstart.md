# Quickstart: Validating the Environment Foundation

This guide proves each acceptance scenario in `spec.md` against a real device or emulator. It
assumes the provisioning runbook in `docs/ENVIRONMENTS.md` §5 has already been run (both Firebase
projects exist, `flutterfire configure` has produced both `firebase_options_*.dart` files, and
native flavor configuration is committed).

## Prerequisites

- Flutter SDK installed, `flutter doctor` clean for at least one target platform.
- Both Firebase projects (`wrap-my-finances-dev`, `wrap-my-finances-prod`) provisioned per
  `docs/ENVIRONMENTS.md` §5.3–5.4.
- Firebase CLI authenticated (`firebase login`) for the rules-deployment steps.
- A physical device or emulator/simulator with enough free storage for two app installs.

## 1. Dev variant connects to the dev project (US1 / SC-001)

```bash
flutter run --flavor dev -t lib/main_dev.dart
```

**Expected**: the app launches to `EnvironmentStatusPage`, showing a visible "dev" indicator.

## 2. Prod variant connects to the prod project, with no debug indicator (US2 / SC-002)

```bash
flutter run --flavor prod -t lib/main_prod.dart --release
```

**Expected**: the app launches to `EnvironmentStatusPage` with no environment label, no debug
menu, and no control to write a probe document.

## 3. Both variants coexist on one device (US3 / SC-004)

1. Run step 1, let it finish installing, then stop it without uninstalling.
2. Run step 2 on the same device/emulator.
3. Check the home screen: two distinct icons/labels ("Wrap Dev" and "Wrap").
4. Open each independently; both must launch correctly.
5. Uninstall the `dev` build. Reopen `prod` — it must still work unchanged.

## 4. Data isolation between environments (US4 / SC-003)

1. With the `dev` build running (step 1), on `EnvironmentStatusPage`, trigger the "write test
   document" control. Note the generated document ID shown on screen.
2. Open the Firebase Console (or `firebase firestore:get`) for **`wrap-my-finances-dev`** and
   confirm the document exists at `env_checks/{that ID}`.
3. Open the console for **`wrap-my-finances-prod`** and confirm no document with that ID exists
   there.
4. Repeat in the opposite direction: write (or manually create, via the `prod` project's console)
   a document under `env_checks` in `wrap-my-finances-prod`, then confirm from the `dev` build (or
   the `dev` project's console) that it is not visible there.

## 5. Offline write succeeds (Constitution Principle 2 check, supports US4)

This step reuses the `dev` build from step 1, which has already completed its anonymous sign-in
while online — the Firebase Auth SDK persists that session locally, so it survives losing network.
It does not test a first-ever launch performed entirely offline (see spec.md Edge Cases): the very
first anonymous sign-in requires connectivity once, exactly like Firestore's own first sync.

1. Enable airplane mode on the device running the `dev` build.
2. Trigger the "write test document" control again.
3. **Expected**: the screen confirms the write immediately (no spinner, no error) — the document
   ID appears before any network reconnects.
4. Disable airplane mode and confirm, after a few seconds, that the document is now visible in the
   `wrap-my-finances-dev` console (proving the local write reconciled).

## 6. Mismatched flavor fails loudly (US5 / SC-005)

This requires deliberately building an inconsistent combination — not a normal command a
developer would run by accident, so it is exercised as a build/run experiment:

```bash
# Native flavor = prod, Dart entrypoint = dev
flutter run --flavor prod -t lib/main_dev.dart
```

**Expected**: the app fails to start with an exception message naming both the native flavor
(`prod`) and the Dart environment (`dev`) in conflict, raised before any `Firebase.initializeApp`
call. Repeat with `--flavor dev -t lib/main_prod.dart` for the opposite direction.

Also confirm the "no default entrypoint" guard:

```bash
flutter run --flavor dev
```

**Expected**: build fails because `lib/main.dart` does not exist — Flutter's default entrypoint
resolution has nothing to fall back to.

## 7. Rules and indexes are symmetric across projects (US6 / SC-006)

```bash
firebase deploy --only firestore:rules,firestore:indexes -P dev
firebase deploy --only firestore:rules,firestore:indexes -P prod
```

**Expected**: both commands deploy from the same `firestore.rules` / `firestore.indexes.json`
files (no per-environment copies exist in the repository to diverge in the first place).

Automated check (run against the emulator, not the live projects):

```bash
firebase emulators:exec --only firestore "npm test" --project wrap-my-finances-dev
```

**Expected**: the rules test suite (see `plan.md` Testing) passes, covering: a well-formed
`env_checks` write is accepted, a malformed one (wrong type, extra field, oversized `label`) is
rejected, and a write to an undeclared top-level collection is rejected by the trailing catch-all.

## 8. Default deploy target is dev (US6 / SC-007)

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

**Expected**: this targets `wrap-my-finances-dev` (the `default` alias in `.firebaserc`), never
`wrap-my-finances-prod`. Confirm via the CLI's own project-selection output before it deploys.
