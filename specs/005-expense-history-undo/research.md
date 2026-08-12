# Phase 0 Research: Historial de Gastos con Borrado Reversible

## Decision: `ExpenseRepository.delete()` is corrected to mean soft-delete, not renamed

`003`'s contract already declares `Future<Result<void>> delete(String expenseId)` on
`ExpenseRepository`. `004`'s implementation made it a literal hard `.delete()` call, with its own
doc comment admitting "no caller exists yet" — an unvalidated stub, not a settled design. This
product has exactly one user-facing "delete an expense" concept, and per `docs/DATA_MODEL.md` that
concept **is** soft delete (`deletedAt` set, purged 30 days later) — there is no separate
hard-delete affordance anywhere in the product. So `delete()`'s *implementation* is corrected here
to set `deletedAt` instead of removing the document, with no signature change (still
`Future<Result<void>> delete(String expenseId)`) and no new method name. This is a correction of an
unvalidated stub now getting its first real caller, the same category of fix `004` itself made to
`003`'s local-write-detection design — not a breaking contract change.

The 30-day purge (research decision below) is what performs the actual hard delete, and does so
through a data-source-internal operation, not through this same `delete()` member.

## Decision: `firestore.rules` needs no changes

Checked against the existing ruleset from `003`:

- The soft-delete write is `.update({'deletedAt': <timestamp>})` on an expense the caller already
  owns. `isValidExpense()`'s `hasOnly([...])` already includes `deletedAt`; it isn't part of
  `hasAll`'s required fields and carries no type constraint. The existing
  `allow update: if isOwner(userId) && isValidExpense() && incoming().createdAt == resource.data.createdAt`
  already permits this write unchanged.
- The 30-day purge's hard delete is `allow delete: if isOwner(userId);` — already unconditional.

Both writes this feature needs were already anticipated and already covered. Zero rules changes,
zero new rules tests — the same outcome `004` reached for its own writes.

## Decision: "instant local filter, single write at expiry" — the pending-deletion set lives in the presentation layer, not the data layer

The plan input is explicit: the entry filters out of view at the instant of the swipe; the
`deletedAt` write happens only once, at expiry, never twice. Concretely:

- `ExpenseHistoryController` (Riverpod) holds an in-memory `Set<String>` of expense ids currently
  "pending deletion," plus one `Timer` per id.
- The controller wraps `ExpenseRepository.watchAll()`'s stream and maps it through a filter that
  excludes any id in that set — this is the "filtered from the query instantly" behavior, achieved
  entirely client-side, without touching Firestore. `watchAll()` itself keeps returning the
  document (its `deletedAt` genuinely is still `null` in Firestore) for as long as the undo window
  is open.
- Swiping starts a 5-second `Timer` (see the next decision for the exact value) and adds the id to
  the set. Tapping "Deshacer" cancels that `Timer` and removes the id — **zero Firestore writes**
  happen for an undone deletion, satisfying "deshacer no requiera una segunda escritura" by never
  requiring a *first* one either.
- If the `Timer` fires (or the app backgrounds — next decision), the controller calls
  `expenseRepository.delete(id)` — the one and only write, fire-and-forget (`unawaited`), since no
  UI state is still waiting on it by that point (the entry already left the view at swipe time).
  This deliberately skips `004`'s `Future.any`-race/local-write-confirmation technique: that
  machinery exists to gate *user-visible feedback* on local persistence without waiting on the
  server, and nothing here is gating feedback on this write's completion — the row is already gone.
- Because the underlying Firestore stream never lost the document, "Deshacer" restoring it to its
  original chronological position is automatic — it was never actually removed from the list the
  stream produces, only from the client-side filtered projection of it.

**Alternative considered**: write `deletedAt` immediately at swipe time, and have "Deshacer" write
`deletedAt: null` to reverse it. Rejected — this is exactly the "second write" the plan input rules
out, and it also means a delete performed while briefly offline-then-reconnecting could sync before
the person taps undo, creating a race the instant-client-filter design avoids entirely.

## Decision: backgrounding the app during the undo window confirms the deletion immediately

`spec.md`'s Edge Cases already settle the product behavior: closing or backgrounding the app during
the undo window confirms the delete, matching "there's no way to show Undo if the app isn't in the
foreground." The reason this needs an explicit implementation decision: a `Timer` scheduled against
Dart's event loop does not reliably keep counting wall-clock time once iOS/Android suspends the
app's process — it may fire immediately on resume instead of having fired while backgrounded,
silently extending the "undo window" past what the person saw. `ExpenseHistoryController` listens
for `AppLifecycleState.paused` (via `WidgetsBindingObserver`/`AppLifecycleListener`) and, on that
transition, immediately fires every still-pending deletion's write and cancels its `Timer`, rather
than relying on the `Timer` alone.

## Decision: the undo window is 5 seconds, taken directly from `docs/UI_UX_SPEC.md` §4

`docs/UI_UX_SPEC.md` §4 already specifies "a snackbar with 'Undo' appears for 5 seconds" for this
exact interaction. `spec.md`'s Assumptions flagged this as an adjustable reference value; this plan
adopts it as-is rather than inventing a different number — it's already the documented product
decision, not a new one this feature is making.

## Decision: the 30-day purge is a client-triggered use case run fire-and-forget at bootstrap

`docs/DATA_MODEL.md` leaves "purged by a maintenance routine" open-ended; the plan input settles it
as running at app bootstrap, non-blocking — the same fire-and-forget pattern `003`'s
`SignInAnonymouslyUseCase` and `004`'s `SeedDefaultCategoriesUseCase` already establish. A new
`PurgeExpiredDeletedExpensesUseCase` (domain), called via `AuthRepository.runWhenAuthenticated`,
queries `where('deletedAt', isLessThan: <now - 30 days>)` — a single-field range query, already
covered by Firestore's automatic single-field indexing (no composite index needed, and
`firestore.indexes.json` has no `fieldOverrides` excluding `deletedAt`) — and hard-deletes each
match. This is client-side and per-user by construction (it only ever touches the signed-in
person's own `expenses` subcollection), consistent with Security Rules already allowing this from
the client rather than requiring a Cloud Function.

**Alternative considered**: a scheduled Cloud Function purging across all users. Rejected for this
feature — it would need a new deployment surface (Cloud Functions aren't part of this project yet)
for a per-user cleanup task the client can already do safely under existing rules; `docs/DATA_MODEL.md`
itself flags a Cloud Function as the option "if [the purge] ever moves" off the client, implying the
client is the starting point, not a stopgap.

## Decision: no `usageCount` adjustment on delete

Deleting an expense does **not** decrement its category's `usageCount`. `spec.md` never asks for
this, and `usageCount` is documented (`004`'s `data-model.md`) as a frequency *heuristic* driving
picker ordering, not an audit-exact count — a momentary intent to use that category is still a real
signal even if the expense is later corrected away. Decrementing would also have to handle "Deshacer"
symmetrically (re-increment), adding a second write path to a feature whose whole point is
minimizing writes. Flagged explicitly here as a deliberate scope decision, not an oversight.

## Decision: navigation is a `go_router` `ShellRoute`, not `Scaffold.bottomNavigationBar`

`docs/UI_UX_SPEC.md` §4 describes the nav bar as "floating... detached from the bottom edge," which
`Scaffold.bottomNavigationBar` (a docked slot) cannot render — it needs to be a `Stack`/`Align`
overlay instead. `go_router`'s `ShellRoute` wraps both routes (`/` capture, `/history` history) in a
shared builder that lays the floating pill over whichever child route is active, while each route
keeps owning its own `Scaffold` exactly as `004` already built it — `ExpenseCapturePage` is
unchanged except for reserving bottom safe-area space so its own "Continuar" button and the new
floating pill never overlap. `initialLocation: '/'` on the router (already implicit — no
location-restoration mechanism is introduced) is what satisfies FR-012's "capture is always the
launch destination, regardless of where the person was when the app closed": there is simply no
code path that remembers or restores the last route.

**Alternative considered**: `StatefulShellRoute` (preserves each branch's scroll/controller state
across switches). Rejected for now — this feature has no expensive per-branch state worth
preserving yet (the history list re-subscribes to a live stream every time regardless), and the
plain `ShellRoute` is the smaller option; revisit if a future feature gives the history screen
state worth keeping warm across navigations.

**Bug found by the regression test this decision's own plan input required**: `ExpenseCapturePage`
(`004`) dismissed its category bottom sheet via `Navigator.of(context, rootNavigator: true).pop()`.
In `004`'s single-route tree that coincidentally targeted the same `Navigator` as the default
(non-root) lookup would have, so the distinction never mattered. Once `ShellRoute` added a nested
`Navigator` above the capture route, `rootNavigator: true` started popping `go_router`'s own root
navigator instead of the bottom sheet — crashing with "popped the last page off of the stack" on
every successful submit. `integration_test/expense_capture_with_history_shell_test.dart` (the test
the plan input explicitly asked for) caught this on its first run, before any manual testing did.
Fixed by using the nearest `Navigator.of(context)` instead — this is exactly the kind of regression
that test existed to catch, not a hypothetical.

## Decision: the empty state and category identity reuse existing primitives only

- The empty state is a large `Icon` (already-bundled Material icon, same "no new asset" choice
  `004` made for category icons) inside a soft circular fill using `context.colors`/`.spacing`,
  plus localized title/body text via `context.typography` — no illustration package, no SVG/Lottie
  asset, per the plan input's explicit instruction.
- Category identity per entry reuses `004`'s `resolveCategoryIcon`/`resolveCategoryName` and
  `categoryPalette`-derived color unchanged — this feature adds no new category-presentation code.

## Decision: day grouping and subtotals are a plain-Dart, presentation-local fold

Grouping a `List<Expense>` by calendar day and summing each group's `amountMinor` is pure
value-in-value-out logic with no Firestore/Flutter dependency — implemented as a plain function in
`expenses/presentation/`, mirroring `004`'s `AmountInputState` "fast to unit-test, no widget
bindings needed" precedent. Grouping uses the expense's `date` field's local calendar day directly
(already device-local, since `004` sets it via `DateTime.now()`), with no timezone conversion of
its own.

## Decision: the timing-regression test extends `004`'s integration test, pumping the real app shell

The plan input requires proof that `004`'s measured logging time doesn't regress with the history
feature (nav bar, extra route, extra provider) present in the widget tree. Rather than a new
micro-benchmark, `integration_test/expense_capture_with_history_shell_test.dart` pumps the actual
`App` widget (real `go_router` config, both routes registered, the floating nav bar rendered) with
the same fakes `004`'s test uses, and asserts the same two-tap flow (type amount → "Continuar" →
category) completes and persists correctly — proving the shell adds no additional screen, dialog,
or tap to the path, which is the structural guarantee Constitution Principle 1 actually requires
(the numeric p90 budget itself is `004`'s own instrumented, already-passing measurement; this test
proves nothing in this feature's tree can add a step in front of it).
