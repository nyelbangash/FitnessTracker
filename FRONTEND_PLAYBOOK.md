# Frontend Playbook — what we did to Gym Bro, applied to MUCA

## Context for the reader

This memo describes a frontend overhaul we did on a React + Tailwind app
(Gym Bro: workout/nutrition tracker, Phoenix API backend). The goal is to
give a different React app (MUCA: educational multi-user collaborative
assistant, FastAPI + WebSocket backend) the same treatment, **but only
the parts that transfer**. MUCA is a chat app, not a forms app — the
underlying domains differ, so don't copy patterns blindly. Use this as a
prioritized to-do list of *design moves and code patterns* worth porting.

The starred items (**★**) are the highest-leverage changes. The rest are
quality-of-life work.

---

## 1. ★ Replace Material-UI with raw Tailwind + a tiny custom primitive set

This was the single biggest improvement. Material-UI fights any aesthetic
that isn't "Google Material," bloats the bundle, and makes theming hard.

**What we did:**

- Removed `@mui/material`, `@mui/icons-material`, `@emotion/react`,
  `@emotion/styled` from package.json
- Kept Tailwind + Lucide icons
- Built ~8 small primitive components in `src/ui/` that everything else
  composes from:
  - `Card` + `CardHeader` + `CardBody` + `CardFooter` — the standard
    surface, dressed with hairline borders and the theme's `--surface`
    color
  - `Button` — 4 variants (`primary` / `default` / `ghost` / `danger`) ×
    4 sizes (`sm` / `md` / `lg` / `xl`). One file, ~50 lines.
  - `Input` + `Textarea` — labeled, themed, with optional hint/error
  - `Chip` — small pill, 3 tones (`default` / `muted` / `accent`)
  - `Stat` — a tabular number tile with label/value/unit/hint
  - Domain-specific ones that may or may not apply to MUCA — `Ring`
    (progress ring), `Bar`, `NumberCell` (tap-to-edit big number)

**Why it works:**

The primitive set is small enough to be memorized, big enough to compose
every page. New surfaces never need new components — they reuse Card +
Button + the appropriate data primitive. This is the same pattern as
shadcn/ui but you don't need a generator.

**Applied to MUCA:** the same Card/Button/Input/Chip primitives will
cover most of the chat UI; the chat-bubble component is the one new
primitive MUCA needs that Gym Bro didn't. Build a `Bubble` (or
`MessageBubble`) primitive with variants for `user` / `assistant` /
`system` / `tool-call` rather than scattering bubble styles across many
files.

**Bundle impact (Gym Bro):** dropped from ~250 KB gzipped to ~106 KB
after MUI removal — most of that was MUI itself.

---

## 2. ★ CSS-variable theming with N themes

Inspired by MonkeyType. We shipped 31 themes; users pick from a search
panel on the profile page. Each theme is just 12 CSS custom properties
applied to `<html>`.

**Pattern:**

1. A single `themes.js` file exporting `{themeId: {bg, surface, surface2,
   text, textMuted, border, accent, accentText, good, warn, bad,
   neutral}}`. Each entry is ~12 hex codes.
2. A `ThemeContext` that applies the chosen theme's vars to
   `document.documentElement` via `root.style.setProperty('--bg', ...)`.
3. `index.css` defines `:root` defaults and component classes that read
   from those vars (`background: var(--surface)`, etc).
4. Tailwind config has `extend.fontFamily` and a few `@layer utilities`
   (like `.bg-surface`, `.text-muted`) that map onto the vars. Most
   styling is still raw Tailwind classes — vars are only for *themeable*
   colors.
5. Theme persists per-user server-side (one new column) and in
   `localStorage` as a fallback for pre-login state.

**Why it works:**

- Adding a theme is appending 12 hex codes to one file. No new CSS, no
  new component, no rebuild needed.
- Components don't know which theme is active — they just read CSS vars.
- A theme picker becomes a feature, not just a setting. **Users feel
  ownership of the app.** This is the highest-emotional-impact change
  in the whole overhaul.

**Applied to MUCA:** ship 6-10 themes for v1 (don't aim for 31; that was
indulgent). Especially valuable for an education app where users sit in
it for long sessions — dark/light is table stakes, but adding
"focus mode" / "high contrast" / "warm low-light" themes is cheap once
the system is built.

---

## 3. ★ Information architecture: 5 top-level destinations, sub-tabs inside

Gym Bro had ~23 routes growing organically. We collapsed to
`Today / Train / Eat / Progress / You` and put history/templates/etc.
behind sub-tabs.

**Pattern:**

- **Sidebar on desktop** (`md:flex hidden`), **bottom tab bar on mobile**
  (`md:hidden fixed bottom-0`)
- Sub-tabs are a horizontal nav under the page heading with an animated
  underline on the active item
- Old URLs redirect to new ones via React Router `<Navigate>` so muscle
  memory doesn't break

**Applied to MUCA:** the natural top-level set is probably
`Spaces / Rooms / Knowledge / Settings / You`, with sub-tabs inside each.
The current MUCA structure looks like everything-in-the-chat-view — a
real navigation layer would help a lot once users have multiple spaces.

---

## 4. ★ A "Today"-style dashboard as the home page

Don't dump people into the most complex screen. Gym Bro's home page is a
greeting line + two main action cards + three small "glance" cards.
**Glanceable in 3 seconds, actionable in 2 clicks.**

**Applied to MUCA:** a home page for MUCA might look like:

- Greeting line ("Morning, Alice. 3 active rooms.")
- Two big action cards: "Continue last conversation" / "New chat"
- Three glances: "Unread mentions" / "Recent files" / "Knowledge added
  this week"

This becomes a place to return to between chats. It also makes the
loading state of "I just opened the app" feel like progress rather than
"which room was I in again?"

---

## 5. ★ Floating action button + command palette

Two affordances for "I want to do the thing fast":

- **Mobile:** a floating round button bottom-right with the
  most-used-action icon. For Gym Bro it's a camera (snap a meal). For
  MUCA it's probably a "compose message" or "new chat" icon.
- **Desktop:** a `Cmd+K` command palette with a static list of actions
  for the first version (fuzzy search comes later). ~80 lines of code.

**Pattern:**

The palette is a fixed-position overlay listening for keydowns at the
window level. Actions are `{label, to}` pairs; selecting one
`navigate()`s. The whole component is under 100 lines in
`layout/CommandPalette.jsx`.

**Applied to MUCA:** ⌘K palette is *especially* good for an app with
many spaces/rooms — let the user jump to any room by name without
clicking through the tree. Worth ranking high.

---

## 6. ★ A "status pill" in the top bar that summarizes app state

A small button in the top-right that always shows the most relevant
thing happening — for Gym Bro it shows the active workout or remaining
calorie budget. Click it → jump to the relevant page.

**Applied to MUCA:** the pill could show "AI is responding…" or "3 new
mentions" or current AI provider (OpenAI/Gemini). Click → jump to the
right room or settings. It's a calming way to surface what's-going-on
without notification toasts.

---

## 7. Mobile-first responsive overhaul

This list isn't novel design — it's a checklist that's easy to skip and
costs nothing once you commit:

- **Bottom tab bar on phones**, sidebar on desktop (single component
  conditionally rendered with `md:hidden` / `hidden md:flex`)
- **iOS safe-area insets** everywhere: `padding-bottom:
  env(safe-area-inset-bottom)` on the tab bar, FAB, and any
  bottom-anchored panel
- **Multi-column grids collapse on mobile**: `grid grid-cols-2
  md:grid-cols-4` (not `grid-cols-4` alone — Tailwind's mobile-first
  default means raw `grid-cols-4` is *always* 4 cols)
- **Tap targets ≥ 40px** — use `p-2` (16px) on icon buttons rather than
  raw icons. Apple's HIG says 44pt minimum.
- **Form labels above inputs**, not next to them — vertical reads better
  on phones
- **Sticky bottom CTAs** on long forms — the primary action follows the
  user as they scroll. Gym Bro's Active Workout uses this for the
  "Complete set" button.
- For floating panels (like chat sidebars), on mobile they become
  **bottom sheets** — full-width-minus-margins, anchored to the bottom

**Applied to MUCA:** the chat interface needs this badly. A WebSocket
chat on a phone is one of the trickiest layouts (keyboard pushes things
around, message list needs to scroll, input bar needs to stay reachable
with the thumb). Worth its own design pass.

---

## 8. Typography hierarchy that uses the right typeface for the right job

Three faces, one purpose each:

- **Serif** (we used Fraunces) — headings only, instant character
- **Sans** (Inter) — body, UI controls, everything that isn't a number
  or heading
- **Monospace** (JetBrains Mono with `font-feature-settings: "tnum"`) —
  any tabular data: numbers, IDs, timestamps, code snippets. Add a
  `.num` utility class.

**Why:** numbers look like numbers, headings have weight, body doesn't
shout. This is one of those "looks designed" moves that takes 5 minutes
to wire up and 5 minutes to revert if you don't like it.

**Applied to MUCA:** monospace for code blocks, timestamps, user IDs,
token counts. The educational-content rendering benefits especially from
this — code examples should be visually distinct from prose.

---

## 9. ★ Streaming / AI response feedback patterns

(MUCA-specific. Gym Bro had a non-streaming AI call for meal-photo
analysis, but the *refinement chat* pattern transfers.)

- **Show the AI's reasoning, not just the answer.** Gym Bro's
  meal-analysis surfaces "warnings" (`Hard to judge oil content`,
  `Pancake portion could vary by 50g`) as warn-color bullets in the UI,
  *under* the numbers. Forces honest design.
- **Refinement chat as a follow-up, not a re-entry.** Once the AI
  returns a draft, a floating chat panel lets the user say "no syrup"
  and the AI re-emits the full structured response with a `reply` field
  acknowledging what changed. Cheaper than letting them re-run the
  whole prompt, and feels more like collaboration.
- **`reply` field in the structured output schema** — even when the AI
  is returning a JSON tool-use, include a free-text `reply: string` field
  for natural-language acknowledgement. The user sees "Got it — removed
  the syrup. Lowered protein from 22g to 18g." next to the new numbers.
  This is the single thing that made the refinement UX feel alive.
- **Confidence flags per item.** Each piece of structured output came
  back with `confidence: low|medium|high` and a `source` tag. The UI
  shows a `?` badge on low-confidence items and a sentence like "Numbers
  below are estimates, review before saving." Makes the AI feel
  trustworthy because it's honest.

**Applied to MUCA:** for an educational tutor, this maps to:
- Show *which knowledge-base sources* the AI used (already partial in MUCA — make it more prominent, like a chip row under the response)
- Allow the student to reply "explain that again" / "I don't follow
  step 3" and have the assistant patch the previous response, not start
  over
- Surface the assistant's confidence and any caveats prominently —
  educational apps where the AI confidently invents answers are
  actively harmful

---

## 10. Calm-dense aesthetic, no chrome

We made hard rules and stuck to them:

- **No glassmorphism, gradients, or glow effects.** Color is for
  meaning (PR celebration / missed goal / in-progress), not decoration.
- **Hairline 1px borders** instead of shadows.
- **Generous whitespace** but tight line-height on body copy.
- **One default border-radius (6px)**, used everywhere.
- **No drop shadows except on floating things** (the FAB, the command
  palette).

**Why:** removing visual noise lets information do the talking. This is
especially helpful for apps with dense data (Gym Bro: macros tables;
MUCA: long chat transcripts + tool outputs + knowledge cards). The user
should be able to skim.

**Applied to MUCA:** the AI response containers should be the visually
quietest thing on the page. Tool-output blocks (code execution, image
generation) should be slightly raised (`--surface-2`) but not flashy.
Reserve color for *new* / *unread* / *error*.

---

## 11. Editable-in-place patterns

After an AI returns a draft, the user reviews and corrects in the same
form. We didn't build a separate "review" screen.

**Pattern:**

- AI fills in the form fields
- Form fields stay editable (input elements, not display elements)
- Save button is unchanged from manual entry
- Trust signal: "Numbers were estimated. Review before logging."

**Applied to MUCA:** when the assistant proposes structured artifacts
(say, a multi-step learning plan, or a quiz), render them as editable
forms the user can tweak before accepting. Don't make them re-prompt.

---

## 12. Backend lessons that affect frontend design

Two specific things from the gym_bro backend that the MUCA frontend
would benefit from on the backend side:

- **An "analysis cache"**: store the AI's last structured response (and
  the inputs that produced it) in an in-memory, short-TTL cache keyed
  by a UUID returned to the client. The refinement endpoint takes that
  UUID + a follow-up message, replays history with the original input
  in context, returns an updated structured response. Saves
  re-uploading or re-streaming large inputs.
- **Forward-only migrations + per-route response schemas.** Every API
  endpoint returns a documented shape with predictable error envelopes
  (`{error: "missing_image"}`, etc). The frontend can write a single
  fallback error renderer.

---

## What NOT to copy

- **Don't copy the active-workout screen design.** That's specific to a
  forms-heavy domain. MUCA's centerpiece is the chat thread.
- **Don't copy the 31-themes count.** Ship 6, add more later.
- **Don't copy `NumberCell` or the rings.** Those are domain-specific.
- **Don't ditch your AI provider abstraction.** MUCA's dual-provider
  (OpenAI/Gemini) is genuinely useful; Gym Bro is hardcoded to
  Anthropic. Keep what you have.
- **Don't copy the route restructuring blindly** — MUCA's nesting
  (Spaces → Rooms → Messages) is different from
  workout/meal flat hierarchies. The *idea* (5 top-level + sub-tabs)
  transfers; the specific routes don't.

---

## Suggested order of operations

If I were doing this on MUCA, I'd attack in this sequence:

1. **Tailwind primitive set** (Card, Button, Input, Chip, Bubble) and
   delete MUI usage in parallel. One PR per page.
2. **CSS-variable theming system** with 6 themes and the picker UI in
   the Settings page. This is high-emotional-impact and unlocks the
   rest.
3. **Restructure routes** to 5 top-level destinations with sub-tabs.
   Redirect old paths.
4. **Build the home dashboard.** Greeting + two action cards + glances.
5. **Mobile responsive pass:** bottom tab bar, FAB for "new chat",
   safe-area insets, sticky message-input bar.
6. **Command palette (⌘K)** for room-jump and quick actions.
7. **Streaming + confidence UX** for AI responses: source chips,
   editable artifacts, `reply` field for refinements.
8. **Status pill** in the top bar.
9. **Typography pass:** add Fraunces / Inter / JetBrains Mono, use
   `.num` utility for tabular data.
10. **Calm-dense pass:** strip remaining gradients/glows, settle on one
    border-radius, audit shadows.

Each is one focused session of work. Steps 1-2 unlock the rest.

---

## Pull quotes to reuse when persuading collaborators

> "The primitive set is small enough to be memorized, big enough to
> compose every page."

> "Color is for meaning, not decoration."

> "Glanceable in 3 seconds, actionable in 2 clicks."

> "Numbers should look like numbers."

> "If the AI is confidently wrong, the UI is broken."

> "Adding a theme should take 30 seconds."
