# Product Context

## Vision

Expense tracking should not feel like accounting; it should be a reflex. This application reduces
the friction of logging a daily expense to under 3 seconds, and rewards that consistency with a
highly engaging, shareable "Wrapped" experience at the end of each month.

The bet is simple: **people abandon budgeting apps because logging is tedious, not because the
reports are bad.** Every product decision optimizes for the logging moment first, and everything
else second.

## Naming

The product is **Wrap My Finances**. Short form on the home screen is `Wrap`; see
[ENVIRONMENTS.md § 0](ENVIRONMENTS.md) for every canonical spelling and where each one is
required.

Two open items, neither blocking Phase 0:

1. **The monthly summary feature is still called "Wrapped" throughout these specs.** That is now
   the internal codename, not necessarily the user-facing string — "Wrap My Finances" and
   "Wrapped" side by side reads redundantly. Candidate user-facing labels: *Your Monthly Wrap*,
   *August Wrap*, *The Wrap*. Decide before Phase 2 builds the story UI; until then, treat
   "Wrapped" in these documents as referring to the feature, not to copy.
2. **Trademark check.** "Wrapped" is strongly associated with Spotify's annual campaign, and the
   resemblance here is deliberate. A finance app in a different class is a different situation
   from a music app, but this is worth a search of the relevant trademark registries — and a
   short conversation with an attorney — before spending money on store assets and marketing
   built around the term. This is a note to get the question asked, not legal advice.

## Target Audience

Designed initially as a personal tool to solve the developer's own tracking needs, but architected
from day one to scale for a public release on the App Store and Google Play. The ideal user
frequently abandons traditional budgeting apps because they are too complex, rigid, or
time-consuming.

Primary market is Mexico (MXN default, Spanish-first copy), with the currency and locale
abstracted so other markets require no code change.

## Core Value Proposition

1. **Unmatched speed.** The app opens directly to a custom numeric keypad. No dashboards, no
   loading spinners, no friction, no login wall.
2. **Absolute simplicity.** Expenses only. No income, no bank sync.
3. **The monthly reward.** A "Wrapped" feature that visualizes spending habits through
   spring-physics animations and story-like summaries, turning financial review into an
   anticipated event rather than a chore.

## Success Metrics

The app is working if these move. They are instrumented in Phase 4 (see ROADMAP.md), but the
definitions are fixed now so the instrumentation is not designed retroactively.

| Metric | Definition | Target |
| --- | --- | --- |
| Time to log | App-open → expense persisted locally, p90 | < 3.0s |
| Cold start to interactive | Process start → keypad accepts input, p90 | < 1.5s |
| Logging streak | Days with ≥1 expense, per active user, per month | ≥ 15 |
| Wrapped completion | Users who reach the final story card / users who open Wrapped | ≥ 60% |
| Wrapped share rate | Share sheet invoked / Wrapped opened | ≥ 15% |
| D30 retention | Users logging an expense 30 days after install | ≥ 25% |

"Time to log" is the north star. Any feature that raises it is rejected by default, regardless of
how valuable it seems in isolation.

## Anti-Goals (What we are NOT building)

To prevent feature creep and ensure a timely launch, the following are strictly out of scope:

- No income tracking, debt tracking, or split-bill functionality.
- No third-party bank API integrations (e.g. Plaid).
- No complex budget creation ("You have $20 left for food").
- No dashboards on the launch screen.
- No mandatory account creation before logging the first expense.
- No recurring or scheduled expenses.
- No receipt photo capture or OCR.
- No multi-currency conversion. One currency per user, chosen once.
- No web or desktop targets. iOS and Android only.
- No third environment (`staging`) until there is a team large enough to need one.

### On anonymous authentication

"No mandatory account creation" does not mean "no authentication". The app signs in
**anonymously and silently** on first launch, before the keypad is even interactive. This is
invisible to the user and is what makes Firestore Security Rules — and therefore any cloud
persistence at all — possible. Converting an anonymous account to Google or Apple Sign-In is
offered later, never demanded.

## Design Philosophy

**"Modern Playful."** Finances are inherently stressful for many. The UI must counteract this by
feeling approachable, tactile, and forgiving: soft rounded edges, bouncy animations, vibrant
category colors, and a slightly cartoonish, friendly aesthetic.

Playful is not the same as noisy. Animation exists to give feedback and reward, never to make the
user wait. Any animation on the logging path that delays input is a defect.

## Non-negotiable constraints

These are enforced in `.specify/memory/constitution.md` and apply to every feature spec:

1. The logging path is sacred. Two taps, under three seconds, always.
2. Offline-first. Every write succeeds with no network and reconciles later.
3. The user's data belongs to the user. No analytics event ever carries an amount, a note, or a
   category name — only counts, durations, and enum identifiers.
4. Feature parity between dev and prod builds. Dev differs in configuration, never in behavior.
