# Phase 0 Research: Fundación de Entornos (dev / prod)

No `NEEDS CLARIFICATION` markers remained in the Technical Context — `docs/ENVIRONMENTS.md`,
`docs/TECH_STACK.md`, and `docs/ARCHITECTURE.md` already answer the framework, dependency, and
platform questions. This document records the decisions specific to *this* feature that those
files leave open: how to prove data isolation without authentication, and how the flavor-mismatch
guard is structured so it stays unit-testable.

## Decision: Environment probe as a dedicated top-level collection, gated by silent anonymous auth

**Decision**: The test document required by User Story 4 (spec.md) lives at
`env_checks/{docId}`, a top-level collection, not nested under `users/{userId}`. Writing to it
requires an authenticated session (`request.auth != null`); `bootstrap()` establishes that session
via a silent anonymous sign-in before any write is attempted.

**Rationale**: Every other collection in `DATA_MODEL.md` is scoped under `users/{userId}` and
protected by an `isOwner()` check that requires `request.auth != null`. A probe document that
exists purely to demonstrate project-level isolation has no natural owner, so nesting it under a
`users/{userId}` document would be a fiction — it stays top-level. Requiring *some* authenticated
session (without ownership) keeps the rule consistent with Principle 7 ("Security Rules Are the
Only Real Boundary") without inventing a fictional owner.

This supersedes an earlier version of this decision, which rejected wiring any auth into Phase 0
on the grounds that it would pull Phase 1 scope forward. On reconsideration (explicit product
direction during task review): the concern was overstated. What actually moves from Phase 1 is
one line — `FirebaseAuth.instance.signInAnonymously()` in `bootstrap()` — not Phase 1's harder
concerns (in-memory buffering of writes made before the UID resolves, account linking, Settings
UI), none of which this feature touches. The constitution explicitly permits this: "Anonymous
authentication is NOT an anti-goal" (Principle 3).

**Alternatives considered**:
- *Leave `env_checks` open to any unauthenticated client* (the original decision) — rejected on
  reconsideration: it is the one collection in the entire schema that would deny Principle 7's
  "MUST validate ownership... server-side" spirit by being writable by literally anyone with the
  project's public client config, which is extractable from any shipped binary (see
  `docs/ENVIRONMENTS.md` §7). Gating it behind *any* authenticated session, even an anonymous one
  with no ownership semantics, closes that gap at negligible cost.
- *Skip Firestore entirely and only prove isolation via the Firebase project IDs in the running
  config* — rejected. It doesn't verify anything about the actual data path (Security Rules
  present, rules deployed, correct project selected at runtime, auth session established); a live
  write/read is the only test that exercises the real mechanism a future bug could break.

## Decision: Anonymous sign-in is awaited inline by the write, not buffered

**Decision**: `bootstrap()` calls `FirebaseAuth.instance.signInAnonymously()` without awaiting it
(fire-and-forget, so it never delays first frame). `FirestoreEnvironmentProbeRepository.writeProbe()`
itself awaits a resolved user (`FirebaseAuth.instance.currentUser`, or the pending sign-in future if
that is still `null`) before writing.

**Rationale**: `ROADMAP.md` Phase 1 describes a more sophisticated pattern for the real logging
path — buffering an expense in memory if the UID has not resolved yet, so the keypad never shows a
spinner (Constitution Principle 1). That complexity exists to protect the 3-second logging budget,
which does not apply here: there is no keypad in this feature, and the probe write is triggered by
an explicit button tap on a diagnostics screen, not a timing-critical path. A direct `await` inside
the one place that needs the UID is simpler and suffices; building the Phase 1 buffering mechanism
here would be solving a problem this feature does not have.

**Alternatives considered**:
- *Replicate Phase 1's in-memory buffer now* — rejected as premature: it is real complexity
  justified by the logging path's constitutional time budget, which this diagnostics screen is not
  subject to.

## Decision: Flavor-consistency guard is a pure function, not an inline assert

**Decision**: `core/config/flavor_guard.dart` exposes a pure function,
`FlavorMismatch? checkFlavorConsistency({required String? appFlavor, required AppEnvironment env})`,
returning a description of the mismatch (or `null` if consistent). `bootstrap()` calls it
immediately after determining `AppEnvironment` and, on a non-null result, throws with the
message before any Firebase call is made.

**Rationale**: `package:flutter/services.dart`'s `appFlavor` constant cannot be swapped in a test.
Wrapping the comparison in a pure function that accepts `appFlavor` as a parameter keeps the
actual mismatch logic unit-testable (feed it `"prod"` / `AppEnvironment.dev` and assert on the
returned message) without needing an integration test that builds a mismatched binary. This also
satisfies Constitution Principle 4: the check is a plain Dart function, not something requiring
Flutter or Firebase to exercise.

**Alternatives considered**:
- *A single `assert()` inline in `bootstrap()`* — rejected as untestable in isolation and, because
  `assert` is stripped in release builds, it would silently stop protecting `prod` exactly where
  the mistake is most expensive. The check must run unconditionally, so it is a thrown exception
  guarded by an explicit `if`, not a language-level `assert`.

## Decision: `flutter_flavorizr` is a bootstrap-only tool

**Decision**: Use `flutter_flavorizr` once to generate the initial Android product flavors and
iOS build configurations/schemes, commit the generated native files, then remove the package from
`pubspec.yaml`.

**Rationale**: Matches the explicit guidance in `TECH_STACK.md` and `ENVIRONMENTS.md` §4: treat
its output as a starting point to review and commit, not a runtime or build-time dependency.
Keeping it in `pubspec.yaml` after native config stabilizes would be an unused dependency with no
purpose.

**Alternatives considered**:
- *Hand-write all six iOS build configurations and the Android flavor block from scratch* —
  viable but slower and more error-prone for the six-configuration iOS requirement called out in
  `ENVIRONMENTS.md` §4; rejected in favor of generating once and reviewing.

## Decision: `Result`/`Failure` are hand-written `sealed class`es, not `freezed`

**Decision**: `lib/core/errors/result.dart` and `lib/core/errors/failure.dart` (per
`ARCHITECTURE.md`) are implemented as plain Dart 3 `sealed class` hierarchies with hand-written
pattern-matching support, not generated via the `freezed` package.

**Rationale**: Adding `freezed`/`freezed_annotation` to `pubspec.yaml` put the dependency
resolver in an unsatisfiable state together with `injectable_generator ^3.1.1` and
`custom_lint`/`flutter_launcher_icons` (see the tooling-drift decision below) at the versions
available today. Dart 3's native `sealed class` plus exhaustive `switch` expressions gives the
same closed-set, pattern-matchable union that `freezed` would generate for `Failure`, with zero
extra dependencies. Per the constitution's Agent Operating Rule ("when a CLI flag or command does
not match reality, the agent stops and reports rather than improvising a workaround"), this
substitution is recorded here rather than silently forcing `freezed` in.

**Alternatives considered**:
- *Pin `injectable_generator` to an older version to make room for `freezed`* — rejected: it
  would hold the DI codegen tooling back project-wide to satisfy a convenience package for two
  small files, and the constraint may simply resolve itself as the ecosystem catches up.
- *Drop `injectable`/`get_it` instead, keep `freezed`* — rejected: `get_it`/`injectable` is a
  constitution-mandated pattern (Principle 4); `freezed` is not.

## Decision: `custom_lint` / `riverpod_lint` deferred — real ecosystem conflict, not a workaround

**Decision**: `pubspec.yaml` does not include `custom_lint` or `riverpod_lint`, even though the
constitution's Development Standards names them alongside `very_good_analysis`.

**Rationale**: `flutter pub add` resolution failed regardless of `flutter_launcher_icons` or
`freezed` presence — the actual conflict is that every published `custom_lint` version constrains
`analyzer` to `<8.0.0`, while `injectable_generator >=3.1.1` (the current `injectable_generator`
release line) requires `analyzer >=10.0.0 <15.0.0`. These two constraints cannot both be satisfied
today. `very_good_analysis` (which has no such conflict) is in place and passing
(`flutter analyze` reports no issues). This is reported here per the constitution's instruction to
stop and report tooling drift rather than route around it silently — it is a gap to close in a
follow-up once the `custom_lint`/`analyzer` ecosystem moves, not a decision to permanently skip
Riverpod-specific linting.

**Alternatives considered**:
- *Downgrade `injectable_generator`* — rejected: same reasoning as the `Result`/`Failure`
  decision above; holds back core DI tooling to satisfy a linting convenience package.
- *Silently omit and not mention it* — rejected: the constitution is explicit that tooling drift
  must be reported, not routed around quietly.

## Decision: CI pipeline changes are out of scope for this feature's Definition of Done

**Decision**: This plan does not include GitHub Actions changes. `ROADMAP.md` Phase 0 lists CI
(analyze/test/build both flavors) as one of its tasks, but none of spec.md's Success Criteria
(SC-001 through SC-007) require it, and the spec's own scope boundary restricts this feature to
the environment/flavor mechanics plus the minimal verification screen.

**Rationale**: Keeps this feature's task list matching exactly what its acceptance criteria
demand. Adding CI here would be scope creep relative to the spec, even though it is legitimate
follow-up work.

**Alternatives considered**:
- *Bundle CI setup into this feature since ROADMAP.md lists it under the same phase* — rejected;
  the spec is the authority for this feature's scope per the constitution's document hierarchy,
  and CI can be planned as its own follow-up feature without blocking this one.
