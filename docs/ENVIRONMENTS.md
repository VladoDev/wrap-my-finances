# Environments & Flavors

This document is the single source of truth for build flavors, Firebase projects, and the
provisioning runbook. Any agent (Spec Kit, Claude Code, Gemini CLI) working on infrastructure
must read this file before running a single `firebase` or `flutterfire` command.

---

## 0. Placeholders — replace before first run

Search-and-replace these across the repository exactly once, at project bootstrap:

| Placeholder | Meaning | Example |
| --- | --- | --- |
| `yourorg` | Reverse-domain org segment | `estudiomartinez` |
| `wrap-my-finances-dev` | Firebase project ID, dev | keep or adjust |
| `wrap-my-finances-prod` | Firebase project ID, prod | keep or adjust |

> **Do not use `com.example.*`.** Google Play rejects it, and the application ID / bundle ID
> is **immutable** after the first store submission. Decide this once, correctly.

### Canonical names

The product name is **Wrap My Finances**. It appears in four different shapes, and each one has
its own constraints — using the wrong shape in the wrong place breaks the build:

| Context | Value | Why this form |
| --- | --- | --- |
| Store listing | `Wrap My Finances` | Full product name, App Store / Play |
| Home screen label | `Wrap` / `Wrap Dev` | See below |
| Dart package (`pubspec.yaml` `name:`) | `wrap_my_finances` | Must be `lower_snake_case` |
| Repository / directory | `wrap-my-finances` | kebab-case convention |
| Application ID / bundle ID | `com.yourorg.wrapmyfinances` | No hyphens or underscores permitted |
| Firebase project ID | `wrap-my-finances-{env}` | Globally unique, ≤30 chars, kebab-case |

**On the home screen label:** iOS truncates icon labels at roughly 12 characters and Android at
a similar width. `Wrap My Finances` renders as `Wrap My Fi…`, which looks unfinished. The label
is therefore `Wrap`, while the store listing keeps the full name. If you prefer a different short
form, change `resValue("string", "app_name", …)` in §4 and `DISPLAY_NAME` in the iOS
configurations — nothing else depends on it.

---

## 1. Environment matrix

Two environments ship in Phase 0. The system is designed so a third (`stg`) can be added by
copying one row — do not add it until there is a real reason (see Anti-Goals).

| | **dev** | **prod** |
| --- | --- | --- |
| Flutter flavor | `dev` | `prod` |
| Entrypoint | `lib/main_dev.dart` | `lib/main_prod.dart` |
| Firebase project ID | `wrap-my-finances-dev` | `wrap-my-finances-prod` |
| Android applicationId | `com.yourorg.wrapmyfinances.dev` | `com.yourorg.wrapmyfinances` |
| iOS bundle ID | `com.yourorg.wrapmyfinances.dev` | `com.yourorg.wrapmyfinances` |
| Home screen label | `Wrap Dev` | `Wrap` |
| Store listing name | — | `Wrap My Finances` |
| App icon | Coral badge overlay | Clean |
| Dev banner in UI | Yes (see UI_UX_SPEC §6) | No |
| Firestore emulator support | Yes (opt-in flag) | Never |
| Crashlytics | Enabled, separate project | Enabled |
| Analytics | Enabled but flagged `env=dev` | Enabled |
| App Check | Debug provider | Play Integrity / DeviceCheck |
| Distribution | Firebase App Distribution | App Store / Play Store |
| Seed data | Allowed | Forbidden |

Both environments run the **same Firestore Security Rules and indexes** from the same files in
this repository. Divergence between dev and prod rules is a bug — it means dev stopped being a
faithful rehearsal of prod.

---

## 2. Run and build commands

```bash
# Dev, against the cloud dev project
flutter run --flavor dev -t lib/main_dev.dart

# Dev, against the local emulator suite
firebase emulators:start --only auth,firestore
flutter run --flavor dev -t lib/main_dev.dart --dart-define=USE_EMULATORS=true

# Prod
flutter run --flavor prod -t lib/main_prod.dart --release

# Release artifacts
flutter build appbundle --flavor prod -t lib/main_prod.dart
flutter build ipa       --flavor prod -t lib/main_prod.dart
```

Every command that specifies `--flavor` must also specify `-t`. Forgetting `-t` silently builds
`lib/main.dart`, which does not exist in this project — that is intentional, so the mistake
fails loudly instead of shipping the wrong Firebase project.

---

## 3. Dart-side wiring

`lib/main.dart` **must not exist**. There are only flavor entrypoints, and both are three lines:

```dart
// lib/main_dev.dart
import 'bootstrap.dart';
import 'core/config/app_environment.dart';
import 'core/config/firebase_options_dev.dart';

void main() => bootstrap(AppEnvironment.dev, DefaultFirebaseOptions.currentPlatform);
```

```dart
// lib/core/config/app_environment.dart
enum AppEnvironment {
  dev(name: 'dev', showDebugBanner: true, allowSeeding: true),
  prod(name: 'prod', showDebugBanner: false, allowSeeding: false);

  const AppEnvironment({
    required this.name,
    required this.showDebugBanner,
    required this.allowSeeding,
  });

  final String name;
  final bool showDebugBanner;
  final bool allowSeeding;

  bool get useEmulators =>
      this == AppEnvironment.dev &&
      const bool.fromEnvironment('USE_EMULATORS');
}
```

`bootstrap()` is responsible for, in order: `WidgetsFlutterBinding.ensureInitialized()`,
`Firebase.initializeApp(options:)`, Firestore persistence settings, emulator wiring when
requested, `configureDependencies(env)` (Injectable), Crashlytics error handlers, and finally
`runApp`.

### Runtime guard against mismatched builds

The single most expensive mistake in a flavored app is a release build wired to the dev
project. Assert it at startup:

```dart
import 'package:flutter/services.dart' show appFlavor;

assert(
  appFlavor == env.name,
  'Flavor mismatch: native flavor "$appFlavor" vs Dart env "${env.name}". '
  'You almost certainly forgot -t lib/main_${appFlavor}.dart',
);
```

`appFlavor` is populated by the Flutter tool from the Xcode scheme (iOS) or Gradle product
flavor (Android), so it reflects the *native* build, which is exactly what the Dart entrypoint
could disagree with.

---

## 4. Native configuration

### Android — `android/app/build.gradle.kts`

```kotlin
android {
    defaultConfig {
        applicationId = "com.yourorg.wrapmyfinances"
        minSdk = 24
    }
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Wrap Dev")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Wrap")
        }
    }
}
```

`AndroidManifest.xml` uses `android:label="@string/app_name"`. The per-flavor
`google-services.json` lives at `android/app/src/dev/google-services.json` and
`android/app/src/prod/google-services.json` — Gradle picks the right one by source set
automatically.

### iOS

Xcode needs six build configurations, not three: `Debug-dev`, `Release-dev`, `Profile-dev`,
`Debug-prod`, `Release-prod`, `Profile-prod`, plus one scheme per flavor named exactly `dev`
and `prod` (the scheme name is what `appFlavor` reports).

`GoogleService-Info.plist` must **not** be added to the target directly. Add a Run Script build
phase, placed *before* "Compile Sources", that copies the right file:

```bash
PLIST="${PROJECT_DIR}/flavors/${FLAVOR:-dev}/GoogleService-Info.plist"
cp "$PLIST" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"
```

Set `FLAVOR` per configuration via a user-defined build setting, or derive it from
`$CONFIGURATION`. Also set `PRODUCT_BUNDLE_IDENTIFIER` and `DISPLAY_NAME` per configuration
rather than editing `Info.plist`.

Bootstrapping this by hand is error-prone; `flutter_flavorizr` can generate the Xcode
configurations and schemes in one pass. Treat its output as a starting point to be reviewed and
committed, not as a dependency — remove it from `pubspec.yaml` once the native setup is stable.

---

## 5. Provisioning runbook (agent-executable)

### 5.1 Guardrails — read first

These are hard constraints on any automated agent with access to the Firebase account:

1. **Never run a destructive command without explicit human confirmation in the current
   session.** Forbidden without confirmation: `projects:delete`, `firestore:delete`,
   `firebase deploy --only firestore` targeting **prod**, `auth:import`, `auth:export`.
2. **Never write seed or test data to `wrap-my-finances-prod`.**
3. **Never commit** `google-services.json`, `GoogleService-Info.plist`, `firebase.json`
   service-account paths, or any `*.keystore` / `*.p12` / `*.mobileprovision`. These are listed
   in `.gitignore`. The generated `firebase_options_*.dart` files **are** committed — they hold
   no secrets (see §7).
4. **Verify before assuming.** The Firebase CLI surface changes frequently; run
   `firebase <command> --help` and `flutterfire configure --help` and adapt, rather than
   trusting the exact flags below.
5. Report the created project IDs and app IDs back to the human before proceeding to §5.4.

### 5.2 Prerequisites

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
firebase projects:list   # confirm the correct Google account is active
```

If several Google accounts are involved, pass `--account you@example.com` explicitly on every
command rather than relying on the default.

### 5.3 Create both Firebase projects

```bash
firebase projects:create wrap-my-finances-dev  --display-name "Wrap My Finances (Dev)"
firebase projects:create wrap-my-finances-prod --display-name "Wrap My Finances"
```

Notes the agent must handle:

- Project IDs are **globally unique across all of Google Cloud**. If either name is taken,
  append a short org suffix (`wrap-my-finances-dev-acme`) and update §1, `.firebaserc`, and every
  command below consistently.
- New Google accounts have a low project-creation quota. If creation fails on quota, stop and
  tell the human — do not retry in a loop.
- Cloud Firestore must be provisioned per project, with a **location that cannot be changed
  later**. Use `nam5` (US multi-region) or `us-central1`; for a Mexico-based user, `us-south1`
  or `northamerica-south1` minimizes latency. Confirm the choice with the human before running:

```bash
firebase firestore:databases:create "(default)" \
  --location=us-central1 --project=wrap-my-finances-dev
firebase firestore:databases:create "(default)" \
  --location=us-central1 --project=wrap-my-finances-prod
```

Then enable **Anonymous** sign-in in Authentication for both projects. This currently has no
stable CLI equivalent and must be done in the console — if the agent cannot do it, it should
emit the two console URLs and pause.

### 5.4 Register apps and generate config

Run once per flavor, from the repository root:

```bash
# dev
flutterfire configure \
  --project=wrap-my-finances-dev \
  --platforms=android,ios \
  --out=lib/core/config/firebase_options_dev.dart \
  --android-package-name=com.yourorg.wrapmyfinances.dev \
  --android-out=android/app/src/dev/google-services.json \
  --ios-bundle-id=com.yourorg.wrapmyfinances.dev \
  --ios-out=ios/flavors/dev/GoogleService-Info.plist \
  --ios-build-config=Debug-dev \
  --yes

# prod
flutterfire configure \
  --project=wrap-my-finances-prod \
  --platforms=android,ios \
  --out=lib/core/config/firebase_options_prod.dart \
  --android-package-name=com.yourorg.wrapmyfinances \
  --android-out=android/app/src/prod/google-services.json \
  --ios-bundle-id=com.yourorg.wrapmyfinances \
  --ios-out=ios/flavors/prod/GoogleService-Info.plist \
  --ios-build-config=Release-prod \
  --yes
```

`flutterfire configure` writes a `firebase.json` block mapping iOS build configurations to
projects. Verify after both runs that it contains entries for **all six** iOS configurations,
not just the two passed above; add the missing ones by hand if needed, or the build will fail
with `FirebaseJsonException: Please run "flutterfire configure"`.

### 5.5 Project aliases and rules deployment

`.firebaserc` (committed):

```json
{
  "projects": {
    "default": "wrap-my-finances-dev",
    "dev": "wrap-my-finances-dev",
    "prod": "wrap-my-finances-prod"
  }
}
```

The default alias points at **dev** deliberately: an accidental `firebase deploy` should hit the
throwaway project, never production.

```bash
firebase deploy --only firestore:rules,firestore:indexes -P dev
# prod requires explicit human confirmation
firebase deploy --only firestore:rules,firestore:indexes -P prod
```

Rules and indexes live in `firestore.rules` and `firestore.indexes.json` (see DATA_MODEL.md) and
are deployed from the same files to both projects.

---

## 6. Local emulator suite

`firebase.json` includes an emulator block for `auth` and `firestore`. When
`--dart-define=USE_EMULATORS=true` is passed to a `dev` build, `bootstrap()` calls
`useAuthEmulator` / `useFirestoreEmulator` **before any other Firebase call**.

Physical Android devices cannot reach `localhost`; use `10.0.2.2` on the Android emulator and the
host machine's LAN IP on real hardware. Firestore offline persistence must be disabled when
talking to the emulator, otherwise a stale cache from the cloud dev project will bleed into
emulator sessions.

---

## 7. What is and is not a secret

The values in `firebase_options_*.dart`, `google-services.json`, and `GoogleService-Info.plist`
are **client identifiers, not credentials**. They are extractable from any shipped binary.
Committing `firebase_options_*.dart` is standard and expected; the platform files are gitignored
only to keep flavor wiring unambiguous, not for secrecy.

Actual security comes from three places, in order of importance:

1. **Firestore Security Rules** — the only thing preventing user A from reading user B's data.
2. **Firebase App Check** — prevents unauthenticated clients (curl, scrapers) from consuming
   your quota against a legitimately-issued API key. Scheduled for Phase 3.
3. **Budget alerts** — set a Cloud Billing alert on the prod project on day one. Firestore's
   free tier is generous, but a runaway retry loop in a released build is a real financial risk.

Real secrets — signing keystores, App Store Connect API keys, service-account JSON — never enter
the repository. They live in the CI secret store and, for local release builds, outside the
project directory.
