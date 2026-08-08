# Phase 1 Data Model: Fundación de Entornos (dev / prod)

This feature introduces one runtime configuration entity (not persisted), one Firestore
collection (persisted, temporary), and relies on one Firebase-managed session (not modeled as an
app entity at all). Everything else described in `docs/DATA_MODEL.md` (`users`, `categories`,
`expenses`) belongs to later features and is untouched here.

## Anonymous session (Firebase-managed, no app entity)

`bootstrap()` calls `FirebaseAuth.instance.signInAnonymously()` so every write — including the
probe write below — carries an authenticated session. This is not a domain entity: the app never
reads or stores anything about this session beyond checking that it exists
(`FirebaseAuth.instance.currentUser != null`) before writing. No `users/{userId}` document is
created by this feature; that profile document belongs to Phase 1 per `ROADMAP.md`.

## `AppEnvironment` (runtime configuration, not persisted)

Registered once in `bootstrap()` as a `get_it` singleton; read by any layer that needs to know
which environment is active.

| Field | Type | Description |
|---|---|---|
| `name` | `String` | `"dev"` or `"prod"` — must match the native flavor name exactly, since `flavor_guard.dart` compares it against `appFlavor`. |
| `showDebugBanner` | `bool` | `true` for `dev`, `false` for `prod`. Drives FR-005/FR-006. |
| `allowSeeding` | `bool` | `true` for `dev`, `false` for `prod`. Drives whether `EnvironmentStatusPage` offers the "write test document" control (FR-007). |
| `firestoreCollectionPath` | `String` | Always `"env_checks"` for this feature; kept as a field (rather than a hardcoded string in the repository) so the collection name has exactly one source of truth. |

No validation rules: this is a compile-time-fixed enum with exactly two variants, not user input.

## `EnvironmentProbe` (domain entity)

Represents one document written to prove that a write from one environment never appears in the
other. Lives in `core/diagnostics/domain/entities/environment_probe.dart`; contains no Firebase
types.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Client-generated (`collection.doc().id`), never server-assigned. Satisfies Constitution Principle 2 (offline-first document identity). |
| `environmentName` | `String` | The `AppEnvironment.name` active when the document was written (`"dev"` or `"prod"`). Included in the document itself so a human inspecting the Firebase console can confirm which environment produced it, independent of which project they're looking at. |
| `createdAtMillis` | `int` | Client clock at creation (`DateTime.now().millisecondsSinceEpoch`), **not** `FieldValue.serverTimestamp()` — consistent with the `createdAt`/`syncedAt` split documented in `docs/DATA_MODEL.md`, and required because this value must be readable immediately from the local cache with no network. |
| `label` | `String` | A short human-readable string entered or defaulted at write time (e.g. `"probe"`), purely so the diagnostics screen has something to display back after a successful write. Capped at 40 characters. |

**State transitions**: none. A probe document is created once and never updated; the diagnostics
screen only ever reads back the most recent one it wrote in the current session, to confirm the
write succeeded locally.

**Relationships**: none. `EnvironmentProbe` does not reference `users`, `expenses`, or
`categories` — it predates all of them.

## Firestore collection: `env_checks/{docId}`

```json
{
  "id": "probe_9f2ac1",
  "environmentName": "dev",
  "createdAtMillis": 1786732800000,
  "label": "probe"
}
```

- **Path**: `env_checks/{docId}` — top-level, not nested under `users/{userId}` (see
  `research.md` for the rationale).
- **Indexes**: none required. The diagnostics screen only ever does a direct document read of the
  ID it just wrote (`env_checks/{docId}`), never a query, so no entry is added to
  `firestore.indexes.json`.
- **Lifecycle**: documents are not deleted automatically by this feature. Because `env_checks` is
  deployed to both projects and `dev` allows unbounded probe writes, a future feature may add a
  cleanup routine; out of scope here since the spec does not require it.

### Security Rules addition

Appended to `firestore.rules`, before the existing trailing catch-all (the catch-all must remain
the last match block so it continues to deny every other undeclared path):

```
function isValidEnvironmentProbe() {
  return incoming().keys().hasOnly(['id', 'environmentName', 'createdAtMillis', 'label'])
    && incoming().keys().hasAll(['id', 'environmentName', 'createdAtMillis', 'label'])
    && incoming().id is string
    && incoming().environmentName is string
    && (incoming().environmentName == 'dev' || incoming().environmentName == 'prod')
    && incoming().createdAtMillis is int
    && incoming().label is string
    && incoming().label.size() <= 40;
}

match /env_checks/{docId} {
  allow read:              if request.auth != null;
  allow create:            if request.auth != null && isValidEnvironmentProbe();
  allow update, delete:    if false;
}
```

Notes:

- Both `read` and `create` require `request.auth != null` — an authenticated session, established
  via the silent anonymous sign-in `bootstrap()` performs (see `research.md`), but no ownership
  check: the probe document represents no user data and belongs to no specific account, so there
  is no `isOwner()`-style condition to write. Isolation between `dev` and `prod` data is provided
  structurally (two entirely separate Firebase projects, each with its own Firestore instance),
  not by this rule — the rule's job is only to keep the collection from being writable by an
  unauthenticated client.
- Field presence, types, an enum-style check on `environmentName`, and a size cap on `label` are
  still enforced server-side, per Principle 7's requirement that client-side validation carries no
  security weight.
- `update` and `delete` are both denied — a probe document is write-once, matching its "no state
  transitions" domain model above.
- This block is additive to the existing rules file; the `users/**` rules from
  `docs/DATA_MODEL.md` are unchanged.
