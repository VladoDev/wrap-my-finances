# Quickstart: Validating Auth & Domain Contracts Foundation

This guide proves each acceptance scenario in `spec.md`. Like `002`, most of it runs as automated
tests rather than manual app interaction, since this feature ships no product screen.

## Prerequisites

- Flutter SDK installed; `flutter pub get` run after this feature's dependencies (none new beyond
  what `001`/`002` already added) are confirmed in `pubspec.yaml`.
- Node.js + `firebase-tools` installed locally (already used by `firebase/tests/` since `001`); a
  JDK installed (required by the Firestore/Auth emulator).

## 1. Anonymous session establishes silently (US1 / SC-001)

```bash
flutter test test/features/auth/domain/usecases/sign_in_anonymously_test.dart
```

**Expected**: passes — confirms `SignInAnonymouslyUseCase` calls `AuthRepository.ensureSignedIn()`
exactly once and returns without requiring any UI interaction, using a fake repository double.

Manual spot-check: run the app (`flutter run --flavor dev -t lib/main_dev.dart`) and confirm no
screen, dialog, or control related to authentication ever appears, at any point.

## 2. Firestore persistence is configured (US1, supporting infra)

```bash
grep -n "persistenceEnabled" lib/bootstrap.dart
```

**Expected**: still present, unchanged from `001` — this feature doesn't move it (see
`research.md`).

## 3. Pre-auth writes are buffered and flushed automatically (US2 / SC-002)

```bash
flutter test test/features/auth/data/repositories/firebase_auth_repository_test.dart
```

**Expected**: passes — using `firebase_auth_mocks` with a controllable sign-in delay, a test calls
`runWhenAuthenticated` before sign-in resolves, asserts the operation has **not** run yet, then
resolves sign-in and asserts the operation runs exactly once, in the order it was queued relative
to any other pending operations.

## 4. The buffer lives in a use case, not a widget (US2, architectural check)

```bash
grep -rn "runWhenAuthenticated\|_QueuedOperation" lib/ --include="*.dart" | grep -v "lib/features/auth/"
```

**Expected**: no output — the buffering mechanism's implementation is confined entirely to
`lib/features/auth/`; nothing under `lib/core/design_system/` or any `presentation/` directory
references it directly.

## 5. Domain contracts for expenses/categories compile and test in isolation (US3 / SC-003)

```bash
flutter test test/features/expenses/domain/ test/features/categories/domain/
```

**Expected**: passes — entity construction tests and a repository-interface compile-check (a
`FakeExpenseRepository`/`FakeCategoryRepository` implementing the abstract class) run with no
`flutter_test` widget bindings initialized, proving no Flutter/Firebase dependency exists.

```bash
find lib/features/expenses lib/features/categories -path "*/data/*" -o -path "*/presentation/*"
```

**Expected**: no output — confirms no `data/`/`presentation/` files exist yet for either feature.

## 6. Security Rules protect real product data, not just diagnostics (US4 / SC-004, SC-006)

```bash
grep -n "env_checks" firestore.rules
```

**Expected**: no output — the block is gone.

```bash
firebase emulators:exec --only auth,firestore "npm test" --project wrap-my-finances-rules-test
```
(run from `firebase/tests/`)

**Expected**: all scenarios in `users.rules.test.js`, `categories.rules.test.js`, and
`expenses.rules.test.js` pass, including the `nameKey`/`name` XOR rejection cases.

## 7. Dev gets the ruleset automatically; prod requires explicit confirmation (US5 / SC-007)

```bash
firebase deploy --only firestore:rules,firestore:indexes -P dev
```

**Expected**: completes without any additional confirmation step.

```bash
firebase deploy --only firestore:rules,firestore:indexes -P prod
```

**Expected**: only run after explicit, separate human confirmation obtained in the same session —
never as part of a scripted or automatic step.

There is no `firebase firestore:rules:get` CLI command — fetch the deployed ruleset via the
Firebase Rules REST API instead:

```bash
TOKEN=$(gcloud auth print-access-token)
RELEASE=$(curl -s -H "Authorization: Bearer $TOKEN" \
  -H "x-goog-user-project: wrap-my-finances-dev" \
  "https://firebaserules.googleapis.com/v1/projects/wrap-my-finances-dev/releases/cloud.firestore" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['rulesetName'])")
curl -s -H "Authorization: Bearer $TOKEN" -H "x-goog-user-project: wrap-my-finances-dev" \
  "https://firebaserules.googleapis.com/v1/$RELEASE" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['source']['files'][0]['content'])" \
  > /tmp/dev-rules.txt
diff /tmp/dev-rules.txt firestore.rules
```

**Expected**: no diff — confirms SC-006 (deployed ruleset matches the repo).

## 8. Rules verification runs in CI automatically (US6 / US7 / FR-015)

```bash
git commit --allow-empty -m "trigger CI" && git push
```

**Expected**: the GitHub Actions run for this branch shows two jobs — `analyze-and-test` (from
`002`) and `rules-tests` (new in this feature) — both required to pass for the workflow to
succeed. Temporarily break a rule (e.g. remove the `isOwner` check from `expenses`) in a scratch
commit and confirm `rules-tests` fails; then revert.

## 9. Full suite, as CI runs it

```bash
flutter test
```

**Expected**: every Dart-side test above, plus `001`'s unaffected tests (flavor guard, etc.),
passes in one run.
