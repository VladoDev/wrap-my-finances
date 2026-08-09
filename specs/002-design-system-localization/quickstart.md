# Quickstart: Validating the Design System & Localization Foundation

This guide proves each acceptance scenario in `spec.md` without any product screen — every check
here runs against the test suite or a minimal widget harness, since this feature ships pieces, not
flows. No `flutter run` step is required; everything is `flutter test`.

## Prerequisites

- Flutter SDK installed, `flutter doctor` clean for at least one target platform.
- `flutter pub get` run after this feature's dependencies (`google_fonts`, `flutter_localizations`,
  `intl`, dev: `alchemist`) are added to `pubspec.yaml`.
- `flutter gen-l10n` (or `flutter pub get`, if `generate: true` is set) has produced
  `lib/l10n/generated/app_localizations.dart` from the five ARB files.

## 1. Tokens are the only source of design values (US1 / SC-001)

```bash
flutter test test/core/design_system/tokens/no_raw_hex_colors_test.dart
```

**Expected**: passes — no `Color(0x...)` or `#RRGGBB` literal exists outside
`lib/core/design_system/tokens/app_colors.dart`. To see it catch a real violation, temporarily add
`const _x = Color(0xFF123456);` to any other file under `lib/` and rerun; the test must fail naming
that file.

## 2. The app is always light (US2 / SC-002)

```bash
flutter test test/core/design_system/theme_light_only_test.dart
```

**Expected**: a widget test that pumps the app's root `MaterialApp` inside a `MediaQuery` forced to
`Brightness.dark` and asserts the resolved `ThemeData` (and a sampled primitive's rendered color)
is identical to the same pump under `Brightness.light`.

## 3. Dark-scheme extensibility, proven without shipping one (US2 → FR-007/FR-008)

```bash
flutter test test/core/design_system/theme_extensibility_test.dart
```

**Expected**: passes by swapping in a throwaway, test-only `AppColorsExtension` instance and
confirming every shipped primitive renders its values — with a `git diff` showing this test file is
the only file touched to make the assertion pass (no primitive source file changes).

## 4. Contrast meets WCAG AA by test, not eyeballing (US5 / SC-004)

```bash
flutter test test/core/design_system/tokens/app_colors_contrast_test.dart
```

**Expected**: passes; prints (or asserts inline) the computed ratio for every pair in
`data-model.md`'s token table. To see it catch a real violation, temporarily edit a token value in
`app_colors.dart` toward a low-contrast pairing and rerun — the specific failing pair must be named
in the failure output.

## 5. Text resolves per device locale (US3 / SC-005)

```bash
flutter test test/core/design_system/widgets/app_button_localization_test.dart
```

**Expected**: a parameterized widget test pumps `AppButton` inside a `MaterialApp` with `locale:`
set to each of `en`, `es`, `pt`, `it`, `fr` in turn and asserts the rendered label text matches that
locale's `app_<locale>.arb` value for the key under test.

Manual spot-check on a device/emulator: change the system language to any of the five supported
languages, then run any widget test harness (or a temporary route) that renders a primitive with a
localized label, and confirm the text changes accordingly without any in-app language switch.

## 6. A missing translation fails the build (US4 / SC-006)

```bash
flutter test test/l10n/arb_keys_complete_test.dart
```

**Expected**: passes today (all five ARB files are in sync). To see it catch a real violation,
temporarily add a new key to `lib/l10n/app_en.arb` only, leave the other four untouched, and rerun —
the test must fail, naming the missing key and each locale missing it.

## 7. Primitives survive 200% text scale with the longest translation (US6 / SC-007)

```bash
flutter test test/core/design_system/widgets/ --name "200%"
```

**Expected**: for each primitive that renders text, a widget test wraps it in `MediaQuery(data:
MediaQueryData(textScaler: TextScaler.linear(2.0)))`, feeds it the longest translated label measured
across the five locales for the key under test (see `data-model.md`), and asserts
`tester.takeException()` is `null` and no `RenderFlex overflowed` error is logged.

## 8. Golden coverage per primitive (US7 / SC-008)

```bash
flutter test --update-goldens test/core/design_system/widgets/
flutter test test/core/design_system/widgets/
```

**Expected**: the first command (run once, locally, when a primitive is first built or
intentionally changed) writes/updates the reference PNGs under
`test/core/design_system/widgets/goldens/`. The second command (what CI runs, unmodified) compares
against those committed images and passes. To see it catch a regression, temporarily change a
token value that a primitive consumes (e.g. `radiusMd`) and rerun the second command without
updating goldens — it must fail.

## 9. Full suite, as CI runs it

```bash
flutter test
```

**Expected**: every test above, plus ordinary widget tests for each primitive's non-visual
behavior (e.g. `AppButton.onPressed` firing on tap), passes in one run — this is the exact command
`docs/TECH_STACK.md`'s CI/CD pipeline runs on every pull request.
