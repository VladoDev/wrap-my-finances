# Phase 0 Research: Captura de Gasto en Menos de Tres Segundos

Every item below was either an explicit instruction in the `/speckit.plan` input, a technical
unknown the spec left to the plan to resolve, or a discrepancy found between what the plan input
assumed and what the repository actually contains. Discrepancies are called out explicitly rather
than silently worked around, per the constitution's Agent Operating Rules ("when a CLI flag or
command does not match reality, the agent stops and reports rather than improvising a silent
workaround" — the same standard applied here to a stated assumption about repo state).

---

## Correction: `category_*` ARB keys do not exist yet

**The plan input states**: "Las claves `category_*` de los cinco ARB ya existen desde la 002."

**Reality, verified by `grep -rn "category" lib/l10n/*.arb`**: no match in any of the five ARB
files. `lib/l10n/app_en.arb` currently contains only `commonContinue`, `commonCancel`,
`commonRetry`, `commonDelete`, `commonDevBuild` — all added by `001`/`003`, none by `002`.

**Resolution**: `docs/ROADMAP.md`'s Phase 1 entry independently confirms these keys were always
meant to be authored alongside the seeding code, not before it: "Author all five ARB files... 
including the `category_*` keys for every default category." This feature is the first to seed
default categories, so it is also the first and correct place to add them. `data-model.md` lists
the exact seven keys. The instruction's *intent* — seeding references stable translation keys, and
adding a new default category later means touching the seeding list and all five ARB files — is
implemented exactly as asked; only the "already exist" premise is corrected.

**Impact flagged to the user**: none on scope (this was always Phase-1, this-feature work per the
roadmap); only on the plan's stated dependency, corrected here.

---

## Correction: no `users/{userId}` profile document exists yet

`docs/DATA_MODEL.md` designs `currencyCode` and the timezone used for `monthKey` as fields
**stored on the user document**, set once and read from there. Grepping the codebase for any write
to `users/{userId}` (outside `firestore.rules` itself) finds none — `003` built `AuthRepository`
(identity only, a UID) but no feature yet creates the corresponding Firestore user profile
document. Settings, where a user would ever change currency or timezone, is explicitly `Phase 3`
per `docs/ROADMAP.md` and out of scope here (spec.md Assumptions).

**Decision**: for this feature only, `currencyCode` and the timezone used to compute `monthKey`
are derived from the **device's current locale** at write time (`Localizations.localeOf(context)`,
which is region-aware — e.g. `es_MX`, not just `es` — unlike the language-only ARB locale), not
read from a stored user document. A five-locale fallback map (`en→USD`, `es→MXN`, `pt→BRL`,
`it→EUR`, `fr→EUR`) is used instead of relying on `intl`'s locale→currency inference, since it is
fully deterministic and trivially testable against exactly the five locales this app supports —
`intl`'s CLDR-based inference is undocumented behavior here and an unnecessary risk for a five-way
lookup. The timezone follows the same device-derived path, via `DateTime.now().timeZoneOffset` at
write time.

**Rationale**: multi-currency conversion is a constitutional anti-goal, and this app has no
currency-*selection* UI in any shipped feature yet — so "the currency the user's device is
currently set to" is a reasonable, honest interim default, not a guess pretending to be the design.

**Explicitly not the final design**: this is a scoped, documented deviation from
`docs/DATA_MODEL.md`'s "stored, not device" intent, made only because the prerequisite (a user
profile document) doesn't exist yet. `docs/ROADMAP.md` Phase 3 ("Settings screen: currency, time
zone...") is the natural place to replace this with the real stored-preference read: once that
document and field exist, `ExpenseModel`'s single call site for `currencyCode`/timezone swaps from
"read device locale" to "read stored user field" with no change to `Expense`, `ExpenseRepository`,
or any other contract this feature or `003` established.

**Impact flagged to the user**: this is a genuine, if small, scope decision the plan input didn't
anticipate — surfaced here rather than assumed silently.

---

## Decision: local persistence is confirmed via the doc's local snapshot, never by awaiting `.set()`

**The problem**: `docs/TECH_STACK.md` § Offline strategy states plainly that the `Future` returned
by a Firestore write "resolves only after the server acknowledges" — it can hang indefinitely
offline. Every promise this feature makes (FR-003's 3-second budget, FR-005's "never waits for the
server," FR-013's "no network is never an error") depends on *never* awaiting that `Future` to
decide the write "succeeded locally."

**Decision**: `ExpenseRemoteDataSource`/`CategoryRemoteDataSource` fire the write
(`docRef.set(data)`) and race it (via `Future.any`) against the **first snapshot from
`docRef.snapshots()` where `snapshot.exists` is `true`** — Firestore delivers an active listener's
own optimistic local write immediately, before any server round trip, which is exactly the "local
persistence" instant FR-003 measures and FR-005's feedback is gated on. Racing (rather than only
awaiting the snapshot) means a write that fails before ever reaching the local cache — the one
genuine failure case FR-012 names — still surfaces promptly, since in that case the snapshot never
fires and the write's own rejection is what completes the race. The `.set()` `Future` is then given
a background `catchError` regardless of which side won, so a later server-side outcome (success or
rejection) never surfaces as an unhandled Future error, but is never awaited by the UI path either.

**Correction during implementation**: the original version of this decision proposed keying off
`docRef.snapshots(includeMetadataChanges: true)`'s `metadata.hasPendingWrites` flag specifically.
That does not work against `fake_cloud_firestore` — its `MockSnapshotMetadata.hasPendingWrites` is
hardcoded to `false` (`fake_cloud_firestore-4.2.0/lib/src/mock_snapshot_metadata.dart`), which would
hang every repository test relying on it forever. Checking `snapshot.exists` instead needs no
metadata support from the fake — it works identically against real Firestore (an optimistic local
write makes the doc exist immediately, before server ack) and the in-memory fake (a `.set()` call
makes the doc exist synchronously) — so this was corrected before either the real or fake
repositories were written, not discovered after the fact.

**Alternatives considered**:
- *Await `.set()` directly*: rejected outright — contradicts `docs/TECH_STACK.md`'s explicit
  warning and would make the entire feature's speed budget dependent on network latency, the exact
  failure mode Constitution Principle 2 exists to prevent.
- *A fixed short timeout race against `.set()`*: rejected — fragile (arbitrary constant), and offers
  no real signal that the *local* write specifically succeeded versus just "hasn't failed yet."
- *`hasPendingWrites` via `includeMetadataChanges: true`*: rejected per the correction above — untestable
  against this project's own test double.

**This is the one piece of genuine complexity this feature's core promise buys** — the direct
counterpart, on the persistence side, to `003`'s `runWhenAuthenticated` buffer on the identity side.
Both exist for the same reason: Constitution Principle 1/2 cannot be satisfied by the SDK's default,
naive `await`.

---

## Decision: repository implementations resolve the current uid from `FirebaseAuth` directly, not a parameter

`003`'s `ExpenseRepository`/`CategoryRepository` contracts give every method no `userId` parameter
at all (`create(Expense expense)`, `incrementUsage(String categoryId)`, etc.) — and `auth-api.md`'s
own `LogExpense` example calls `_expenseRepository.create(draft)` inside
`runWhenAuthenticated((uid) => ...)` without ever passing `uid` into `create()`. The resolution:
`ExpenseRepositoryImpl`/`CategoryRepositoryImpl` take the injected `FirebaseAuth` singleton
(already registered since `001`) and read `_auth.currentUser!.uid` directly at call time, backed by
an `assert` documenting the invariant that guarantees it's non-null — every real call path reaches
these methods only from inside `runWhenAuthenticated`, by which point `FirebaseAuth`'s own
`currentUser` is already resolved. This keeps `003`'s method signatures exactly as specified (no
widening needed here, unlike `seedDefaultsIfNeeded()`) and mirrors how `FirebaseAuthRepository`
itself already reads `_auth.currentUser` directly rather than accepting a uid parameter.

## Decision: `Expense.id` is a caller-supplied placeholder; the repository assigns the real id

`Expense.id` (from `003`) is a required, non-nullable `String` — but domain code must not call
Firestore's `collection.doc()` (a `data/`-layer, Firestore-SDK-specific call) to mint a real id.
`ExpenseRepository.create()` already returns `Result<Expense>`, not `Result<void>` — exactly so the
data layer can hand back the *real*, Firestore-assigned id. `LogExpense` builds its draft `Expense`
with `id: ''`; `ExpenseRepositoryImpl.create()` calls `collection.doc()` (no argument, per
`docs/TECH_STACK.md`'s client-generated-id rule) to mint the real id, writes under that id, and
returns a corrected `Expense` (same fields, real id) as the `Success` value. No change to the `003`
contract; this is precisely the flexibility that contract's `Result<Expense>` return type was
already designed to provide.

---

## Decision: category swatch colors are a new design-system token, not a literal

`docs/DATA_MODEL.md`'s example category document stores `"color": "#FF5722"` as a plain hex string
— but `test/core/design_system/tokens/no_raw_hex_colors_test.dart` (from `002`) fails the build on
**any** hex color literal (`Color(0x...)` or `'#RRGGBB'`) found anywhere in `lib/` outside
`app_colors.dart`. Seeding code that assigns a literal hex string per default category would violate
this test — and, more importantly, the principle it enforces.

**Decision**: add a `categoryPalette` field (`List<Color>`, 7 entries) to `AppColorsExtension` in
`app_colors.dart` — the one file allowed to hold hex literals — following the same
library-private-constant pattern already used for `background`/`primary`/etc. Seeding code
references `AppColorsExtension.light.categoryPalette[i]` (a `Color`, no literal) and the **data
layer** converts that `Color` to its `#RRGGBB` string only at the point of building the Firestore
write payload (`ExpenseModel`'s sibling, `CategoryModel`). No new hex literal appears anywhere in
seeding or feature code; `no_raw_hex_colors_test.dart` needs no change.

**Rationale**: category swatches are exactly the kind of visual value the design-system-token rule
exists to centralize — treating them as an exception because they're "data, not chrome" would be the
same reasoning that produces a second, uncontrolled color source over time.

---

## Decision: default category set (seven categories)

Neither the spec nor `docs/DATA_MODEL.md` names a specific default list — only the `cat_food` /
`category_food` example. A concrete, reasonable set is chosen here (see `data-model.md` for the
full table): food, transport, shopping, entertainment, health, housing, other. Icons come from
Flutter's bundled Material Icons font (`Icons.restaurant`, `Icons.directions_car`, etc.) — already
shipped with the framework, so no new asset or package is needed, consistent with `docs/DATA_MODEL.md`'s
"fixed, bundled icon set... a key into an app-side map, never a dynamic lookup." A
`categories/presentation/category_icon_map.dart` holds that `Map<String, IconData>`, kept in
`presentation/` (not `domain/` or `data/`) since `IconData` is a Flutter type.

---

## Decision: category display-name resolution lives in `presentation/`, as a `switch`

`docs/ARCHITECTURE.md` is explicit: "the generated localization class is consumed only from
`presentation/`... resolving [a category's `nameKey`] to display text happens in the widget tree."
`AppLocalizations` exposes strongly-typed getters (`.categoryFood`, not a dynamic `[key]` lookup), so
a `categories/presentation/category_name_resolver.dart` function switches over the known `nameKey`
values (the same seven from the seed list) to the matching getter, and falls through to `category
.name!` for user-created categories. An unrecognized `nameKey` (which can only originate from this
app's own seeding code, never user input) throws `ArgumentError` — the same "impossible state is a
programmer error, not a runtime failure to swallow" style `Category`'s own constructor already uses.

---

## Decision: amount-input parsing is a plain-Dart, presentation-local helper

Locale-aware digit-by-digit input handling (single decimal separator per locale, cap at two
decimals ignoring further digits, live thousands grouping, a 1,000,000.00 ceiling that freezes
input) is UI-input formatting, not a domain rule — `Money` (from `003`) stays exactly what it is, an
already-resolved integer-minor-units value with no knowledge of how it was typed. This logic lives
in `expenses/presentation/controllers/amount_input_state.dart` as a plain Dart class (no `Widget`,
no `BuildContext`) built on `intl`'s `NumberFormat` for the locale's grouping/decimal symbols — fast
to unit-test without any Flutter widget bindings, mirroring how `003` kept `Money`/`Expense`
Flutter-free.

---

## Decision: the checkmark-bounce success animation uses Flutter's built-in implicit animations, not `flutter_animate`

`flutter_animate` is listed in `docs/TECH_STACK.md` and scheduled by `docs/ROADMAP.md` specifically
for Phase 2's Wrapped spring-physics stories; it is not yet a dependency. This feature's "quick
checkmark bounce" (`docs/UI_UX_SPEC.md` §2) is satisfied by `AnimatedScale`/`TweenAnimationBuilder`
(built into Flutter, zero new dependency), which is simpler than the effect actually needs. Reduce
motion (Constitution Principle 8) collapses it to a cross-fade via
`MediaQuery.disableAnimationsOf(context)`, the same mechanism `docs/UI_UX_SPEC.md` §3 already
specifies for Wrapped. Pulling `flutter_animate` forward into Phase 1 for one small effect is
avoidable complexity; deferred to when Phase 2 actually needs it.

---

## Decision: `time_to_log_expense` instrumentation — new `core/` abstractions, `firebase_analytics` added now

The plan input requires instrumenting SC-001/FR-003 "desde el arranque del proceso hasta el retorno
de la escritura local" and reporting it as an analytics event with no financial data, per
Constitution Principle 5. Two small `core/` abstractions make this possible without domain code
importing Flutter or Firebase:

- `core/instrumentation/app_launch_clock.dart` — `AppLaunchClock(DateTime startedAt)`, plain Dart
  (`DateTime`/`Duration` only), instantiated as the **first statement** in `bootstrap()` (before
  `WidgetsFlutterBinding.ensureInitialized()`) and registered as a GetIt singleton. "Process start"
  for this app is, in practice, the top of `bootstrap()` — `main_{dev,prod}.dart` do nothing before
  calling it.
- `core/analytics/analytics_service.dart` — abstract `AnalyticsService` with
  `void logExpenseTimeToLog(Duration elapsed)`; safe for `domain/` to depend on (same pattern as
  `AuthRepository`: an abstract `core`/domain-level port, Firebase-free). The concrete
  `FirebaseAnalyticsService` (new `data`-adjacent `core/analytics/` impl) sends the
  `time_to_log_expense` event with a single `duration_ms` integer parameter — no amount, no note, no
  category name, per the hard rule in `docs/TECH_STACK.md` § Telemetry.

`LogExpense` (domain) takes both as constructor dependencies, computes
`appLaunchClock.elapsedSinceLaunch()` the instant `ExpenseRepository.create()`'s `Result` resolves
(which, per the local-write-detection decision above, is already the "local persistence" instant),
and reports it — no separate timer plumbing needed in the presentation layer.

**Why `firebase_analytics` now, ahead of its `docs/ROADMAP.md` Phase 4 slot**: the constitution's
own Governance section requires it — "Principle 1 is verified by measurement, not by assertion — the
time-to-log instrumentation is the check." This is a targeted, single-event pull-forward to satisfy
that compliance requirement, not a general adoption of Phase 4's telemetry scope (Crashlytics,
`wrapped_completion_rate`, etc. stay deferred).

---

## Decision: `CategoryRepository` gains `seedDefaultsIfNeeded()` — an additive contract change

`003`'s `contracts/domain-repositories-api.md` explicitly permits this: "`004` may find it needs to
widen a method... that's an additive change to this contract, not a violation of it." A new
`SeedDefaultCategoriesUseCase` (domain, mirrors `003`'s `SignInAnonymouslyUseCase`) calls
`AuthRepository.runWhenAuthenticated((uid) => categoryRepository.seedDefaultsIfNeeded())` and is
invoked fire-and-forget from `bootstrap()`, alongside sign-in — so seeding is normally already
finished by the time the user reaches the category step (a few seconds into a typical amount-entry
interaction), never blocking or spinner-gated either way since the category picker reads from
`watchActive()`, a live stream that simply shows categories as they arrive.

`CategoryRepositoryImpl.seedDefaultsIfNeeded()` guards against double-seeding with a memoized
`Future<void>? _seedFuture`, the same pattern `003`'s `FirebaseAuthRepository` uses for
`ensureSignedIn()` — safe because both are registered `@LazySingleton` (exactly one instance exists
per process).

---

## Decision: `LogExpense`'s two writes are sequential, not one atomic transaction

`LogExpense` calls `expenseRepository.create()` then `categoryRepository.incrementUsage()`, both
inside the same `runWhenAuthenticated` callback, but as two independent local-cache writes rather
than a single cross-repository Firestore transaction. Both apply to the local cache near-instantly
(per the local-write-detection decision), so the speed budget is unaffected either way. The only
risk is a rare partial-failure case (expense saved, usage-count increment fails) — degraded category
ordering, never data loss. `docs/ARCHITECTURE.md` does not call for a shared-transaction primitive
across repositories, and introducing one for this narrow case would be exactly the kind of
complexity Constitution Governance requires written justification for for no corresponding benefit.

---

## Decision: "modo sin red" integration test uses `fake_cloud_firestore` + `firebase_auth_mocks`

Both are already dev dependencies (added in `001`/`003`, unused by any Firestore-backed feature
until now). `FakeFirebaseFirestore` is an in-memory fake — no socket is ever opened, which
*is* "no network mode," more reliably than toggling a real device/emulator's connectivity in CI.
`MockFirebaseAuth` (pre-signed-in) stands in for a resolved anonymous session. The test
(`integration_test/expense_capture_flow_test.dart`) builds the real widget tree
(`ExpenseCapturePage` under a `ProviderScope` with GetIt overridden to the fakes) and drives the
full two-tap flow, asserting: the expense document exists in the fake Firestore with the exact typed
`amountMinor`; the category's `usageCount` incremented; the screen returned to its initial state;
and a fake `AnalyticsService` recorded exactly one `time_to_log_expense` call. This is the same
"exercise the real widget tree against fakes, not a real backend" approach `003` used for
`FirebaseAuthRepository`'s tests, extended to the full screen.

---

## Correction: `firestore.rules` needs no changes for this feature

`003` already replaced the ruleset in full and tested it (28 scenarios,
`firebase/tests/{users,categories,expenses}.rules.test.js`). Every write this feature performs —
expense `create`, category `create` (seeding) and `update` (`incrementUsage`) — is already covered
by `isValidExpense()`/`isValidCategory()` as written; `isValidCategory()` has no `hasOnly(...)`
restriction, so a partial `update()` that only changes `usageCount`/`lastUsedAt` still satisfies it
(Firestore rules see the full post-merge document either way). No rules file change, no new rules
test, no new CI job — `004` is a pure consumer of `003`'s ruleset.
