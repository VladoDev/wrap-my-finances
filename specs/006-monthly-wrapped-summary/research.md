# Phase 0 Research: Resumen Mensual Animado y Compartible

## 1. The `users/{userId}` document does not exist yet — this feature creates it

**Finding**: `docs/DATA_MODEL.md` §1 documents a `users/{userId}` document carrying `timeZone`
and `wrappedLastSeenMonth`, described as already driving the trigger. It does not. Grepping the
codebase confirms no feature has ever written to that path: `FirebaseAuthRepository.ensureSignedIn()`
only calls `signInAnonymously()`; every existing Firestore access goes straight to the
`categories`/`expenses` subcollections. `004`'s `DeviceLocaleDefaults` (see #2 below) was the
interim workaround for exactly this gap, scoped to currency/monthKey only.

**Decision**: `006` creates and maintains this document. A new `user_profile` feature
(`lib/features/user_profile/`) owns it, mirroring the existing `categories`/`expenses`
feature-per-collection structure:

- `UserProfileRepository.ensureExists()` — creates the document with `timeZone` defaulted from
  `DeviceLocaleDefaults`-style device locale mapping and `wrappedLastSeenMonth: null` if it
  doesn't exist yet; no-ops if it does. Called fire-and-forget from `bootstrap()`, same slot as
  `SeedDefaultCategoriesUseCase` and `PurgeExpiredDeletedExpensesUseCase`.
- `UserProfileRepository.watchProfile()` — live stream, read by the auto-trigger check.
- `UserProfileRepository.markWrappedSeen(String monthKey)` — single-field update.

**Rationale**: The cross-device "exactly once per month" requirement (acceptance criterion 1) is
unsatisfiable with a local-only flag — a purely on-device preference would pass single-device
testing and silently fail the actual requirement the moment a second device is involved. Building
the real document is less work than building a convincing fake of it.

**Alternatives considered**: Keep treating this as out of scope and gate the trigger on a local
`SharedPreferences` flag. Rejected — contradicts acceptance criterion 1 outright, and this project's
established practice (see `004`'s and `005`'s research.md) is to surface a missing dependency and
build the minimal real version, not to defer it silently a second time.

**Security Rules consequence**: `docs/DATA_MODEL.md`'s current `firestore.rules` draft validates
`incoming().uid == userId` on create/update but has no `isValidUserProfile()` field/type/range
check (unlike `isValidExpense()`/`isValidCategory()`). Per Constitution Principle 7, this plan adds
one: `timeZone` a non-empty string, `wrappedLastSeenMonth` either `null` or matching
`^[0-9]{4}-[0-9]{2}$`, and the write's key set restricted to the fields this feature and `004`'s
device-locale interim actually populate. See `contracts/security-rules-delta.md`.

## 2. `monthKey` on existing expenses stays device-local; only the trigger's month boundary uses the new stored time zone

**Finding**: `ExpenseModel.fromEntity` computes `monthKey` via `DeviceLocaleDefaults.monthKeyFor`,
which uses `DateTime.now()` in the device's local time — not a stored IANA zone, since none existed
until this feature. Retroactively recomputing already-written `monthKey` values, or changing how
new expenses compute theirs, is out of scope for `006` (it belongs to whichever feature makes
`004`'s device-locale interim the real stored preference, tracked already in that research.md).

**Decision**: Leave expense-write-time `monthKey` computation untouched. The new `timeZone` field
is used only for the Wrapped **trigger's** month-boundary check (acceptance criterion 1: "evaluado
en la zona horaria almacenada del usuario") — i.e., to compute "what is the previous calendar
month, right now, for this user" when deciding whether to auto-show. Since `timeZone` defaults to
the device's zone at profile-creation time and nothing in the app currently lets it diverge from
the device zone, this is observably identical to using device-local time today, while being the
correct extension point once Settings (Phase 3) lets a user set a real stored zone.

**Alternatives considered**: Recompute month boundaries with full IANA time zone arithmetic via a
package like `timezone`. Rejected as scope creep — no code path today can make `timeZone` diverge
from the device's own zone, so the precision would be unobservable until Settings exists.

## 3. Manual access to a past month (User Story 4) hooks into the existing History screen

**Finding**: `docs/UI_UX_SPEC.md` §3 says the entry point is "always available from Settings" —
but no Settings screen exists, and `004`/`005` both explicitly excluded it. `005`'s History screen
(`ExpenseHistoryPage`) is the only secondary screen that exists today.

**Decision**: Add a small, always-visible affordance at the top of the History screen (a pill
button, matching existing `AppButton`/`AppChip` primitives) that opens a bottom sheet listing every
month that has at least one non-deleted expense, most recent first, each navigating to
`/wrapped/:monthKey` on tap. The month list is derived client-side from the same `watchAll()` stream
`ExpenseHistoryController` already holds (grouping by `monthKey` prefix of each expense's `date`) —
no new Firestore query.

**Rationale**: Reuses data already in memory, adds no new repository surface, and gives every user
story a real, reachable entry point today. When Settings ships (Phase 3, per `docs/ROADMAP.md`),
this affordance can move there or stay as a shortcut — a UI relocation, not a data model change.

**Alternatives considered**: Add a temporary minimal Settings screen just to host this one entry
point. Rejected — a whole new screen (navigation, empty states, localization) is a disproportionate
amount of net-new surface for what the spec treats as a P2 convenience, and it would front-run
Phase 3's actual Settings scope.

## 4. `flutter_animate` and `share_plus` are added to `pubspec.yaml` for the first time

**Finding**: Both packages are named in `docs/TECH_STACK.md` for exactly this feature (Wrapped
stories, shareable card) but neither has been added yet — grep of `pubspec.yaml` confirms.

**Decision**: Add both as direct dependencies. `flutter_animate` drives every Wrapped story
transition (count-up numbers, spring/bounce entrances); `share_plus` invokes the platform share
sheet with the rasterized card image.

## 5. Bounce/spring curves are design-system tokens, not per-widget literals

**Finding**: The existing token files (`app_colors.dart`, `app_typography.dart`, `app_spacing.dart`)
are each a `ThemeExtension`, resolved via `context.colors`/`.typography`/`.spacing` in
`design_tokens.dart`. Nothing analogous exists yet for motion.

**Decision**: Add `AppMotionExtension` (`lib/core/design_system/tokens/app_motion.dart`) following
the exact same `ThemeExtension` shape: `springCurve` (the bounce/spring `Curve` every entrance
animation uses), `storyAdvanceDuration` (5–7s per `docs/UI_UX_SPEC.md` §3, expressed as a single
token so the exact value is set once), `countUpDuration`, and `crossfadeDuration` (the reduce-motion
fallback). Exposed as `context.motion` via `design_tokens.dart`, matching `context.colors` etc.
Widgets read `context.motion.springCurve`, never `Curves.elasticOut` or a bare `Duration(...)`
inline — same discipline Principle 9 already requires for color/type/spacing.

**Rationale**: This is a direct instruction from the plan input ("las curvas de rebote se definen
como tokens junto al resto del sistema de diseño, no como valores sueltos en cada widget"), and it
matches the existing token architecture exactly, so it is a natural extension rather than a new
pattern.

## 6. Partial-sync detection: local count vs. server-side `count()` aggregation

**Finding**: `docs/DATA_MODEL.md`'s "Wrapped aggregation" section specifies comparing a local
cache-served query against a server-side `count()` aggregation to detect an incomplete local cache
on a fresh install. `cloud_firestore: ^6.8.0` (already a dependency) supports `Query.count().get()`.
`fake_cloud_firestore: ^4.2.0` (already a dev dependency) implements it too
(`lib/src/fake_aggregate_query.dart`), so this is testable without the emulator.

**Decision**: `WrappedRepository.getSummary(monthKey)` runs the existing
`ExpenseRemoteDataSource`-equivalent local query (`monthKey` == X, `deletedAt` == null, served from
cache) to compute the four figures, and in parallel issues
`.where('monthKey', isEqualTo: monthKey).where('deletedAt', isNull: true).count().get(const
GetOptions(source: Source.server))` to get the authoritative document count. If the local query's
document count is less than the server count, the summary is returned in a `syncing` state (no
figures rendered) rather than a possibly-partial total. No composite index changes needed — the
existing `(monthKey, deletedAt, date)` index already covers this exact filter combination.

**Alternatives considered**: Trust the local cache unconditionally and accept the rare
fresh-install undercount. Rejected — `docs/DATA_MODEL.md` names this exact failure mode as the one
correctness caveat of the whole aggregation design, and acceptance criterion 8 restates it directly.

## 7. Auto-trigger check runs in the presentation layer, not `bootstrap()`

**Finding**: `bootstrap()`'s existing fire-and-forget jobs (sign-in, category seeding, purge) are
all "do a thing," not "decide whether to navigate." None of them has router/`BuildContext` access,
and none needs it.

**Decision**: A `wrappedAutoTriggerProvider` (`FutureProvider`, presentation layer) evaluates the
trigger algorithm (see `data-model.md` § Trigger algorithm) once per app session, using
`UserProfileRepository` and `WrappedRepository`. A thin `ConsumerWidget` wraps `App`'s router child
(inside the existing `ShellRoute`, so it doesn't shadow either destination) and listens for the
provider to resolve; when it resolves to a month worth showing, it calls
`context.go('/wrapped/$monthKey')` via a post-frame callback. Ensures the check runs after first
frame — never blocking or delaying the capture screen's paint (Constitution Principle 1).

**Rationale**: Keeps the trigger decision colocated with the navigation it causes, using the same
Riverpod-owns-reactive-state / GetIt-owns-infrastructure split every other feature already follows,
rather than inventing a new cross-cutting mechanism.

## 8. `/wrapped/:monthKey` is a top-level route, outside the `ShellRoute`

**Finding**: `AppShell` renders the floating nav bar over whatever the `ShellRoute` is showing.
Wrapped is a full-screen, edge-to-edge stories experience with its own swipe-down-to-dismiss
gesture — the floating nav bar has no role there and swiping near its hit area could conflict with
the dismiss gesture.

**Decision**: `GoRoute(path: '/wrapped/:monthKey', ...)` is declared as a sibling of the
`ShellRoute`, not nested inside it, so `AppShell` never wraps it. Dismissing (swipe down, or
reaching the end of the sequence) calls `context.pop()` (or `context.go('/')` if reached via the
auto-trigger, which has no prior route to pop to) back to the capture screen, per FR-001 keeping
capture the fixed launch destination.

## 10. Widget-test disposal for Timer-driven Riverpod controllers must be inline, not `addTearDown`

**Finding**: `WrappedController` (a `StateNotifier` owning a raw `Timer` for auto-advance, created
via a `StateNotifierProvider.autoDispose.family`) triggers flutter_test's "A Timer is still pending
even after the widget tree was disposed" (`!timersPending`) assertion when the disposing
`tester.pumpWidget(const SizedBox.shrink())` + `tester.pumpAndSettle()` sequence is registered via
`addTearDown()`. Isolated with a minimal reproduction (see `wrapped_page_test.dart`'s history):
calling the identical two lines **inline at the end of the test body** instead of inside an
`addTearDown` callback resolves it every time, with no other change. `addTearDown` callbacks appear
not to get the same pump/flush guarantees as code awaited directly in the test body — the provider
disposal (and the timer cancellation it triggers) doesn't reliably complete before flutter_test's
end-of-test invariant check runs.

**Decision**: Every `WrappedPage`/`WrappedController` widget test disposes inline
(`await tester.pumpWidget(const SizedBox.shrink()); await tester.pumpAndSettle();` as the last two
lines of the test body), never via `addTearDown`. `wrapped_controller_test.dart`'s plain
(non-widget-tree) tests are unaffected — they construct `WrappedController` directly and
`addTearDown(controller.dispose)` there works fine, since no widget tree/Riverpod container is
involved.

**Rationale**: This is a real, reproducible interaction between flutter_test's `addTearDown` timing
and Riverpod's `autoDispose` grace mechanism for `Timer`-owning notifiers — not a bug in
`WrappedController` itself (its own unit tests, using real `Timer`s directly with
`addTearDown(controller.dispose)` and no Riverpod/widget tree involved, are unaffected). Worth
documenting explicitly since every future widget test that mounts `WrappedPage` will hit the same
failure mode if it reaches for the more idiomatic-looking `addTearDown`.

## 11. `wrapped_*` ARB keys carry the native-review metadata `docs/TECH_STACK.md` already specifies

**Finding**: `docs/TECH_STACK.md` § Localization already documents the convention: `wrapped_*` ARB
keys carry an `@`-metadata comment flagging them for native-speaker review. No `wrapped_*` keys
exist yet in any of the five ARB files.

**Decision**: Every new ARB key this feature adds (`wrappedGrandTotalTitle`,
`wrappedBlackHoleTitle`, `wrappedHabitTitle`, `wrappedBiggestHitTitle`, `wrappedSyncingMessage`,
`wrappedShareAmountsToggleLabel`, `wrappedSuppressedCardTitle`, etc.) gets a `@`-block whose
`description` ends with the same native-review flag already used as precedent, satisfying the plan
input's explicit instruction.
