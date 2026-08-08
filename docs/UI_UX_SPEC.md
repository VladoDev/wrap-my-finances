# UI and UX Specifications

## 1. Design System (Soft & Friendly)

**Theme concept:** "Modern Playful" — a friendly, slightly cartoonish aesthetic without being
overwhelming. Rounded shapes, soft drop shadows, bouncy interactions.

### Typography

- A rounded, approachable font: **Nunito**, **Quicksand**, or **Fredoka**.
- Bundled as an asset in the shipped build rather than fetched at runtime, so the first frame
  never waits on a network request.
- Keypad digits and totals are large, chunky, and highly readable. The amount display uses
  tabular figures so digits do not shift horizontally as the user types.

### Shape language

- Heavy use of rounded corners — `BorderRadius.circular(24)`, or fully pill-shaped buttons.
- Subtle but thick borders on cards and buttons add to the cartoon feel without looking messy
  (neo-brutalism, light).

### Colors

| Token | Value | Use |
| --- | --- | --- |
| `background` | `#F8F9FA` | Warm off-white base |
| `primary` | `#FF6B6B` | Soft coral, primary action |
| `secondary` | `#4ECDC4` | Vibrant teal, accents |
| `surface` | `#FFFFFF` | Cards, sheets |
| `onSurface` | `#2D3436` | Body text |
| `danger` | `#E17055` | Destructive affordances |

Shadows are soft and slightly tinted with the surface's own hue rather than pure black, to keep
the friendly vibe.

**Contrast is a requirement, not a preference.** Pastel-on-pastel is the failure mode of this
aesthetic. All text/background pairs meet WCAG AA (4.5:1 for body, 3:1 for large text). Category
colors are used as fills behind icons and as accents — never as the color of small text.

### Dark mode

Out of scope for launch, but every color is defined as a semantic token (`background`, not
`offWhite`) so adding a dark scheme later is a theme change, not a refactor. No raw hex values
appear outside `app_colors.dart`.

---

## 2. Frictionless Entry Flow (The 3-Second Rule)

**Initial screen:** bypasses dashboards completely. The user immediately sees the input UI. No
splash screen beyond the OS-provided one, no auth gate, no loading state.

### Layout

- **Top half:** a large, playful display of the current amount. Digits get a slight pop/scale
  animation as they are typed.
- **Bottom half:** a custom, oversized numeric keypad. Buttons look like soft, tactile bubbles
  that compress slightly on press.

### Interaction flow

1. Type the amount on the bubble keypad.
2. Tap the primary "Next" button.
3. A rounded bottom sheet springs up showing a grid of colorful, chunky category icons, **ordered
   by the user's own usage frequency** (see DATA_MODEL.md `usageCount`).
4. Tapping a category saves the expense instantly and resets the screen with a satisfying success
   animation — a quick checkmark bounce plus light haptic feedback.

### Keypad rules

- **Tap targets are at least 48×48 dp**, with generous spacing. Oversized buttons are the point;
  they must also be reachable one-handed on a 6.7" phone, which means the primary action sits in
  the lower third, not at the top.
- **Decimals:** a single separator key, locale-aware (`.` or `,`). Maximum two decimal places;
  further digits are ignored rather than rejected with an error.
- **Maximum amount:** 1,000,000.00. Exceeding it caps the input silently rather than throwing.
- **Zero is not submittable.** The "Next" button is disabled — not hidden — until a non-zero
  amount exists, so the layout never shifts.
- **Backspace** on an empty amount is a no-op, not a navigation event.
- **Formatting** is applied live via `intl` as the user types, with grouping separators.

### Speed budget

Measured from app-open to expense persisted in the local cache, p90 under 3 seconds. The
persistence write is **not awaited** before the success animation plays — the local cache write is
synchronous and the server round trip happens in the background. The UI never blocks on the
network, and there is never a spinner on this path.

If anonymous sign-in has not yet resolved when the user taps a category, the expense is buffered
in memory and flushed when the UID arrives. The user does not see this happen.

### Error states on the logging path

There is exactly one: the expense could not be written locally, which in practice means the
device is out of storage. It shows as a non-blocking snackbar with a retry, and the amount stays
on screen so nothing is lost. Network failures are not error states here — they are the normal
case.

---

## 3. The Monthly "Wrapped" Experience

**Trigger:** the first app open of a new calendar month, evaluated in the user's stored time zone
and gated on `wrappedLastSeenMonth`, so it fires exactly once per month across devices.

**Suppression:** Wrapped does not appear if the month has fewer than 5 expenses. A "Wrapped" built
from three data points is embarrassing rather than delightful, and a bad first impression of the
feature is hard to undo. In that case a small, dismissible card on the timeline offers it anyway
for users who want it.

**Entry point:** always available from Settings, for any past month with data. The overlay is the
surprise; the content is not locked behind it.

### Mechanics

- "Stories" format, auto-advancing every 5–7 seconds.
- Playful, rounded progress bars at the top.
- **Tap right** to advance, **tap left** to go back, **long-press to pause**, **swipe down to
  dismiss**. All four are expected from the format; missing any of them reads as broken.
- Dismissing marks the month as seen. It does not re-prompt.

### Animations (via `flutter_animate`)

- Spring physics and bouncy curves rather than linear movement.
- Numbers count up dynamically.
- Text and custom icons zoom and bounce into place.

**Reduce motion is respected.** When `MediaQuery.disableAnimationsOf(context)` is true, the
spring curves collapse to short cross-fades and counters render their final value immediately.
Vestibular-triggered motion sickness is real, and this feature is the densest concentration of
motion in the app.

### Story sequence

1. **The Grand Total** — "You spent $X this month," with a bouncy shape.
2. **The Black Hole** — "Your top category was [Category]."
3. **The Habit** — "You logged [N] transactions in [Category]."
4. **The Biggest Hit** — "Your largest single expense was $Z."
5. **The Shareable Card** — vibrant summary card with thick borders and rounded corners,
   optimized for screenshotting and sharing.

### The shareable card

- Rendered from a `RepaintBoundary` at 3× pixel ratio and shared via `share_plus`, rather than
  relying on the user screenshotting. A screenshot includes the status bar and the progress bars;
  a rendered image does not.
- **No amounts are included unless the user opts in.** Default share shows the top category, the
  transaction count, and the month — not the total spent. Sharing a financial figure to social
  media is a decision the user should make deliberately, once, with a visible toggle.
- Sized for a 9:16 story frame with safe margins for platform UI overlays.

### Partial-data state

On a fresh install, the local cache may not hold the full month. When the client-side aggregate
disagrees with the server-side count, Wrapped shows a brief syncing state instead of a total it
cannot yet stand behind.

---

## 4. Navigation and Secondary Screens

**Navigation:** a floating bottom navigation bar with rounded edges, detached from the bottom edge
so it reads as a floating pill. Three destinations: Keypad (default), Timeline, Settings. The
keypad is always the launch destination, regardless of where the user was when the app was
backgrounded.

### Timeline

- Simple chronological list, grouped by day with a per-day subtotal.
- Swipe to delete reveals a brightly colored background with a playful trash-can icon that
  shakes slightly.
- **Deletion is soft and undoable.** A snackbar with "Undo" appears for 5 seconds; the row
  animates out immediately but the document is only marked `deletedAt` until the snackbar
  expires. No confirmation dialog — a modal on a destructive-but-reversible action is friction
  for no safety gain.
- Empty state is illustrated and warm, not a bare "No data."

### Settings

Clean, spaced-out toggle switches and rounded buttons for managing categories, currency and time
zone, haptics, linking accounts, and viewing past Wrapped months.

---

## 5. Accessibility

Non-negotiable, and cheaper to build in than to retrofit:

- Minimum tap target 48×48 dp everywhere, including keypad and category grid.
- WCAG AA contrast on all text.
- Every icon-only control has a semantic label. Category tiles announce name and color-independent
  identity — **color is never the only signal**, since category colors are the most colorblind-
  hostile part of this design.
- Text scales with the system setting up to 200% without clipping. The keypad reflows rather than
  truncating.
- Wrapped stories are pausable and back-navigable, so a screen reader user is never outrun by the
  auto-advance.
- Haptics can be disabled in Settings.

---

## 6. Flavor affordances

Dev and prod builds must be distinguishable at a glance, or a bug will eventually be reported
against the wrong environment — or worse, test data will be entered into production.

- **App icon:** the `dev` flavor carries a coral corner badge. Different icon, different name
  (`Wrap Dev` vs `Wrap`), different application ID, so both can be installed side by side.
- **In-app banner:** a small, non-blocking `dev` ribbon in the top-right of the keypad screen,
  showing the flavor name and the short Firebase project ID. Rendered only when
  `AppEnvironment.showDebugBanner` is true, so the widget is compiled out of prod builds by tree
  shaking.
- The banner must not overlap the amount display or intercept touches.
- **Prod builds contain no debug affordances at all** — no environment label, no hidden developer
  menu, no seed-data button.

## 7. Layout under translation

Spanish, Portuguese, Italian, and French run roughly 15–30% longer than English. Pill
buttons and category tiles MUST size to their content with a minimum width, never a
fixed one. Text MUST wrap to two lines rather than ellipsize. Category tiles in the
picker grid MUST hold their longest translated label at 200% text scale without
clipping — verify against `category_food` in French, the current worst case.

The keypad is exempt: digits and the currency symbol are the only text on it.