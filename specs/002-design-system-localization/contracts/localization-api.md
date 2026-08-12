# Contract: Localization Public API

## Consuming translated text

```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.commonContinue);
```

`AppLocalizations` is generated from `lib/l10n/*.arb` into `lib/l10n/generated/` (committed, not a
synthetic package — see `research.md`). Feature code imports it the same way it imports any other
generated class in this repo; it never constructs a string by hand or concatenates locale-dependent
fragments (Constitution Principle 9).

## `App` wiring contract

```dart
MaterialApp.router(
  theme: AppTheme.light,
  themeMode: ThemeMode.light,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  // no darkTheme
  routerConfig: _router,
)
```

Every future feature's screens sit under this same `MaterialApp.router` — none of them re-declares
`localizationsDelegates`/`supportedLocales`, and none of them passes a `darkTheme`.

## ARB key namespace contract

- **Template locale**: `app_en.arb`. Every key is authored here first.
- **Supported locales**: `es`, `pt`, `it`, `fr` — each file must carry every key the template has,
  non-empty, before a pull request can merge (enforced by `arb_keys_complete_test.dart`, run inside
  `flutter test`, per FR-012/SC-006).
- **Key naming**: `snake_case`, domain-prefixed. This feature owns the `common_*` prefix (shared,
  reusable strings with no feature-specific meaning). Future features add their own prefixes
  (`keypad_*`, `category_*`, `wrapped_*`, `settings_*`) per `docs/TECH_STACK.md`; they do not repurpose
  `common_*` for feature-specific copy.
- **No literal strings**: any user-visible string added to Dart source outside this mechanism is a
  Principle 9 violation regardless of which feature introduces it.

## Fallback contract

A device locale outside the five supported languages resolves to `en` (the template), never to a
partially-translated state or a raw ARB key.
