# Gym Bro — Wireframe Brief

## App overview

Gym Bro is a single-user (Nyel) iOS-first fitness tracker covering workouts, meals, body weight, and progress. It runs as a Capacitor wrapper around a React PWA and talks to a Phoenix/Postgres backend. Desktop is supported but mobile is the default canvas — every screen should be designed for one-thumb operation first, with a desktop layout as a wider variant.

The product has three things no competitor has, and the design should amplify them:

1. A **conversational meal-logging pipeline** — photo + free text + manual + voice all land in the same Anthropic Sonnet vision/text + USDA macros pipeline, with a Refine chat that re-runs analysis instead of forcing field-by-field edits.
2. A **calm, dense, paper-cream aesthetic** with 31 MonkeyType-style themes — every primitive (Card, Stat, Ring, Bar, Chip, NumberCell) is tuned for this. Don't propose flashy or noisy patterns.
3. A **single-user posture** — no follow graph, no social pressure. The home screen is about *you*, not a feed. The design should be opinionated and quiet, not chatty.

### Design system primitives (use these exact names)

`Card`, `CardHeader`, `CardBody`, `CardFooter`, `Button`, `Input`, `Textarea`, `NumberCell`, `Ring`, `Bar`, `Chip`, `Stat`

Do not invent new primitives. If a screen needs a chart, build it from `Bar`. If a screen needs a metric, use `Stat`. If a screen needs a progress wheel, use `Ring`. Selectable filters, tags, deltas, and pills all use `Chip`. All clickable surfaces use `Button` (text, ghost, or primary tone).

### Global behavior

- A persistent floating **Log FAB** sits at the lower-right on every screen except Active Workout. Tap opens a half-sheet (Phase 1 below). Long-press jumps straight to voice capture.
- Tab bar at the bottom on mobile: Today, Train, Eat, Progress, You. Sidebar on desktop with the same items.
- No greeting paragraphs anywhere. Every screen opens on data, not pleasantries.

---

## Information architecture

| Top-level | Sub-views |
|---|---|
| **Today** | (single screen) |
| **Train** | Plan, History |
| **Eat** | Today, History, Library |
| **Progress** | Overview, Lifts, Body, Briefs |
| **You** | Goals, Profile, Appearance, Settings |

Active Workout is a **full-screen takeover** route launched from Train > Plan, not a sub-tab. The Log meal half-sheet is global and overlays whatever the user is on.

---

## Screen-by-screen specs

### 1. Today

**Route:** `/`
**Purpose:** One opinionated "do the right next thing" surface. No greeting, no dashboard, no five-card scroll. The user opens this screen, sees their state, and either taps the hero CTA or the Log FAB.

**Layout (mobile, top to bottom):**

1. **Status Hero `Card`** — full-bleed. Adapts to state:
   - If there's an active workout: `CardHeader` "Resume · Pull Day" + small `Chip` "Set 3 of 5". `CardBody` shows last completed exercise + next exercise as two muted lines. `CardFooter` has a primary `Button` "Resume" full width.
   - Else if it's morning and a template is planned (or autopiloted in Phase 2): `CardHeader` "Today · Push Day". `CardBody` shows a 3-line preview (bench / OHP / dips, target sets x reps). `CardFooter` Button "Start" + ghost Button "Swap".
   - Else if it's evening and no meal logged in 4h: `CardHeader` "Log lunch?" + muted `Chip` "5h since last meal". `CardBody` shows top 3 Recents as `Chip` row. `CardFooter` Button "Log".
   - Else (rest day, all goals on track): `CardHeader` "Rest day". `CardBody` shows 4 small `Stat` cards in a 2x2 grid: sleep, soreness, mood, energy — each tappable to log (Phase 2 Rest Day Inputs).

2. **Fused state strip `Card`** — three small `Ring` components side by side: calories left, protein left, training volume this week vs weekly target. Below the rings, a 7-dot week strip rendered as `Chip` row (filled = trained, hollow = rest, accent = today). Tap any ring opens the relevant deeper view.

3. **Quick Log row** — three pill `Button`s in a row: camera icon "Snap", mic icon "Say it", recent icon "Recent". Each opens the Log half-sheet directly into that tab.

4. **(Conditional) Sunday Brief `Card`** — only Sunday/Monday. `CardHeader` "Last week". `CardBody` is one paragraph of AI-generated recap. `CardFooter` Button "Open full brief" + ghost Button "Dismiss". (Phase 2)

5. **(Conditional) Drift `Card`** — only when triggered. Yellow-tinted. `CardHeader` "Heads up". `CardBody` shows the drift in one line. `CardFooter` two `Button`s: "Yes, intentional" / "Recommit". (Phase 2)

**Desktop note:** Two columns. Left column = Hero + state strip stacked. Right column = Briefs + recent activity feed (last 3 workouts + last 3 meals as compact `Card` rows).

**Design principle:** *One next-action above the fold, one glance-strip under it, one log-row at thumb-line. If the user needs to scroll to act, the screen failed.*

---

### 2. Train > Plan

**Route:** `/train`
**Purpose:** Pick or run a template. Replaces both the old `/train` (Start) and `/train/templates` — they were 80% the same page.

**Layout:**

1. **Active workout banner `Card`** — only renders when a workout is active. `CardHeader` template name. `CardBody` exercise + set position. `CardFooter` primary `Button` "Resume" full width.

2. **Templates section** — header row: "Templates" text + ghost `Button` "+ New" on the right.

3. **Template `Card` list** — one card per template:
   - `CardHeader`: template name + `Chip` showing day-of-week or muscle group tag.
   - `CardBody`: `Chip` row listing exercises, then a `Stat` row at the bottom: "Last session", "Avg volume", "Times run".
   - `CardFooter`: primary `Button` "Start" + ghost `Button` "Edit" + small ghost `Button` "History" that opens a drawer (Phase 1 per-template history with a `Bar` volume trend).
   - Long-press a Card sets it as today's plan (mobile gesture).

4. **Empty state:** single `Card`, `CardBody` "No templates yet", `CardFooter` Button "Create your first template".

**Desktop note:** 2-column grid of template Cards.

**Design principle:** *One source of truth for templates. Edit, start, see history, all from one Card. No separate Templates tab.*

---

### 3. Train > Plan > Template editor

**Route:** `/train/templates/new` and `/train/templates/:name`
**Purpose:** Create or edit a template. Existing TemplateEditorPage is clean — preserve.

**Layout:**

1. `Input` for template name at top.
2. Optional `Chip` row to tag day/muscle group.
3. List of exercise `Card`s. Each card: `CardHeader` exercise name `Input`, `CardBody` a 4-cell grid of `NumberCell`s (sets, reps, weight, rest), an `Input` for RPE target, a `Textarea` for per-exercise sticky note (Phase 1 — surfaces every session). `CardFooter` ghost `Button` "Remove".
4. Full-width ghost `Button` "+ Add exercise".
5. Sticky bottom bar with primary `Button` "Save" + ghost `Button` "Cancel".

**Design principle:** *Edit dense, save fast. The grid of NumberCells is the right pattern — keep it.*

---

### 4. Train > Active Workout (full-screen takeover)

**Route:** `/workout/active`
**Purpose:** Run one set at a time. The top 60% of the viewport is the current set. The bottom 30% is one fat action.

**Layout:**

1. **Top bar** — back `Button` "End" on the left, elapsed-time `Stat` in the center, exercise position `Chip` "Set 3 of 4" on the right.

2. **Current exercise `Card`** (replaces the gb-card divs):
   - `CardHeader`: exercise name (big), `Chip` showing target ("3 x 8 @ 185").
   - `CardBody`: a row of three `NumberCell`s — reps, weight, RPE. Tap-to-edit, oversized for thumb. Below the NumberCells, a muted `Chip` row: "last: 175 x 5 @ 7" and a delta `Chip` "+10lb / same reps" (Phase 1). Tap the prev chip to autofill last session's numbers.
   - `CardFooter`: small ghost `Button` "Skip set" + ghost `Button` "Add note" (opens a Textarea drawer).

3. **Set log `Card`** — completed sets for this exercise, one row per set. Each row: `Chip` "Set 1" + reps x weight + RPE + tiny delta vs previous set.

4. **Sticky bottom action bar** — primary `Button` "Log set" spanning full width, big and tall (thumb target). Below the button, a thin `Bar` progress indicator showing position within the workout (sets done / total sets).

5. **Rest timer takeover** — when a set is logged, the screen pushes a full-screen overlay: a large `Ring` showing rest countdown, exercise name + next set's target in `Stat` form below the ring, two `Button`s: ghost "+30s" / primary "Skip rest". Swipe down dismisses to a sticky pill at the top of Active Workout with the countdown continuing.

6. **PR Replay modal** (Phase 2) — when a PR is detected on set log, modal slides up: `CardHeader` "PR — Bench Press". `CardBody` three Stat cards side-by-side showing last 3 attempts. `Textarea` "Add a note". `CardFooter` Button "Save & continue".

**Design principle:** *One set at a time, full-bleed. Thumb-reachable Log button. Compared-to-last-time is inline, not behind a tap.*

---

### 5. Train > History

**Route:** `/train/history`
**Purpose:** Reverse-chron list of completed sessions, grouped by week with a Bar summary per week.

**Layout:**

1. **Filter `Chip` row** — All / This month / Per template (opens a select). Phase 1 adds filtering.
2. **Weekly section** for each week: a header row showing the week range + a small inline `Bar` for that week's total volume. Below the header, a `Card` per session: `CardHeader` template name + date, `CardBody` `Stat` row (volume, duration, avg RPE), `CardFooter` `Chip` row of exercises. Tap a session opens a detail drawer with set-by-set view.

**Design principle:** *Group by time, summarize by week, drill down on tap. Don't show every set on the list view.*

---

### 6. Eat > Today

**Route:** `/eat`
**Purpose:** Today's macros + today's meals. This is the big-rings home base for nutrition.

**Layout:**

1. **Nudge `Chip` strip** — one line: streak Chip ("Protein 12d streak") + remaining Chip ("62g left, ~4h to bed"). Phase 1.
2. **Macros `Card`** — `CardBody` shows 4 large `Ring` components in a row (kcal, protein, carbs, fat) with current/goal Stat under each ring. No CardHeader, no CardFooter — the rings are the content.
3. **Meals list `Card`s** — one Card per meal, chronologically. `CardHeader` meal name + time-eaten Chip. `CardBody` 4-column Stat row (kcal/P/C/F). `CardFooter` icon Buttons: favorite, quick-access toggle, edit, delete. Swipe-left on a row opens Refine chat. Swipe-up clones to now (Phase 2 gestures).
4. **End-of-Day Closer banner** (after 8pm, conditional) — small Card with `CardBody` "28g protein short — Greek yogurt + whey (in your favorites) closes the gap" + `CardFooter` Button "Log it". (Phase 2)
5. **Macro Roulette `Button`** — small ghost Button at the bottom: "Pick something for me" (Phase 2).

**Design principle:** *Rings as the answer, meals as the receipt, nudges as the only proactive copy.*

---

### 7. Eat > Log half-sheet (global FAB)

**Route:** overlay on any screen
**Purpose:** Log a meal in under 10 seconds for the common case. Replaces navigating to `/eat/log` for most flows.

**Layout (half-sheet, slides up from bottom):**

1. **Tabs row at top** — `Chip`-style tabs: Photo (default) / Say it / Recents / Manual.

2. **Photo tab:**
   - Live camera viewfinder fills the sheet body.
   - Big shutter `Button` at the bottom center.
   - On tap, sheet collapses to a pinned `Chip` at the top of whatever screen the user was on: "Analyzing meal..." with a small spinning indicator. (Optimistic — never block.)
   - When analysis resolves, the Chip becomes "Logged: ~640 kcal, 38g P" with two tiny `Button`s: Edit / Confirm. Tapping Edit opens the existing analysis preview (overall_confidence `Chip`, per-ingredient confidence color, warnings list — and Phase 1 persists these per saved meal). RefineChat sits at the bottom.

3. **Say it tab:** big circular hold-to-talk `Button`. Releases → transcript flows into the same text-analysis pipeline as the Photo path.

4. **Recents tab:** 2x3 grid of last 6 unique meals as small `Card`s with `CardHeader` (name) and `CardBody` (`Stat` row for kcal/P). Tap to clone with now-timestamp. Long-press to favorite.

5. **Manual tab:** the existing form — meal name `Input`, time `Input`, 4 `NumberCell`s for kcal/P/C/F (upgrade from plain Inputs — denser, more on-brand), `Textarea` for notes, ingredient editor below using `NumberCell`s for amount/macros, ghost `Button` "+ Ingredient". Sticky primary `Button` "Save" at bottom.

6. **Pre-cook tab** (Phase 2) — alongside Photo/Say it/Recents/Manual. Snap raw ingredients on the counter. Claude estimates cooked-meal macros + suggests portion split.

7. **Confession Box** (Phase 2) — sub-mode of Manual: just a Textarea "what did you eat?" + Button "Estimate range". Logs as `estimated`-tagged meal.

**Design principle:** *Never block on the AI. The meal is logged the instant the user taps shutter — macros fill in async.*

---

### 8. Eat > History

**Route:** `/eat/history`
**Purpose:** Calendar heatmap of adherence. Flat list moves to drill-down.

**Layout:**

1. **3 `Stat` cards row at top** — protein hit-rate (last 30d), avg kcal, longest goal-hit streak. Phase 1.
2. **Heatmap calendar `Card`** — GitHub-style month grid. Each day cell colored by % of kcal goal hit (in range = accent, under = muted, over = warning tone). Month nav arrows in `CardHeader`. Tap a day → opens drill-down below.
3. **Day drill-down `Card`s** — when a day is selected, list of meal Cards for that day with day-total `Stat` row in a `CardHeader` at the top.
4. **Search `Input`** — filter by meal name (Phase 1).

**Design principle:** *Pattern first, list second. The heatmap shows weekend overshoot or midweek under-eating before the user opens any meal.*

---

### 9. Eat > Library

**Route:** `/eat/library`
**Purpose:** Ingredient frequency wall + photo diary. Replaces the standalone Favorites tab (favorites become a filter Chip here).

**Layout:**

1. **Filter `Chip` row** — All / Favorites / This week / This month.
2. **Ingredient grid** — Cards in a 2-column mobile / 4-column desktop grid. Each `Card`: `CardHeader` ingredient name + `Chip` for tag (protein, carb, etc.). `CardBody` `Stat` row: times eaten, total grams, avg kcal per logging. `CardFooter` ghost `Button` "See meals" (opens filtered Eat > History).
3. **Photo Diary toggle `Button`** at the top right of the screen — switches Library view to a dense photo grid of all meal photos last 30d, no labels, no macros. (Phase 2 — requires persisting photo bytes.)

**Design principle:** *Make the user's actual diet visible. "I ate chicken 14 times" is more honest than any recipe DB.*

---

### 10. Progress > Overview

**Route:** `/progress`
**Purpose:** Top-level stats + Ask Your Data bar + weekly volume bar chart.

**Layout:**

1. **Ask Your Data `Input`** at the very top — placeholder "Ask anything about your data..." (Phase 2). Submits to Claude tool-use.
2. **3 totals `Stat` row** — total sessions, total volume, total time.
3. **Weekly volume `Card`** — `CardHeader` "Last 8 weeks". `CardBody` 8 `Bar` components, one per week. `CardFooter` Chip "vs last week +12%".
4. **Macro adherence `Card`** — `CardHeader` "Nutrition last 30 days". `CardBody` four `Bar` rows for kcal/P/C/F hit-rate.

**Design principle:** *Aggregate, not raw. Detail lives in sub-tabs.*

---

### 11. Progress > Lifts

**Route:** `/progress/lifts`
**Purpose:** Per-exercise e1RM trend. The thing every lifting app has and Gym Bro doesn't.

**Layout:**

1. **Exercise list** — searchable `Input` at top. List of exercises with a `Stat` (current e1RM) and a tiny inline `Bar` sparkline preview. Tap to open detail.
2. **Detail view:**
   - `CardHeader` exercise name + time-range `Chip` row (1M / 3M / 1Y / All).
   - `CardBody` `Bar`-based trend chart of e1RM over time (Epley formula on heaviest set per session).
   - `Stat` row below: current e1RM, all-time best, 30-day change.
   - `CardFooter` list of recent PRs as `Chip` row.

**Design principle:** *One screen per lift, one trend line, one number that matters.*

---

### 12. Progress > Body

**Route:** `/progress/body`
**Purpose:** Body weight time series. Replaces the static weight_kg field on YouPage.

**Layout:**

1. **Quick-log `Card`** at top — single `NumberCell` for today's weight, primary `Button` "Log".
2. **Trend `Card`** — `CardHeader` time-range `Chip` row (1M / 3M / 1Y / All). `CardBody` line/Bar chart with raw points + 7-day moving average. Stat row: current, 7d avg, 30d change.
3. **What-If link** — ghost `Button` "Simulate" opens What-If sub-screen (Phase 2).

**Design principle:** *Smooth before you react. Daily weight is noise; the trend line is the signal.*

---

### 13. Progress > Briefs (Phase 2)

**Route:** `/progress/briefs`
**Purpose:** Archive of all Sunday Night Briefs.

**Layout:** Reverse-chron list of `Card`s. Each: `CardHeader` week range. `CardBody` brief paragraph. `CardFooter` Refine `Button` + `Chip` row of metrics that drove the brief.

**Design principle:** *Every AI artifact persists. The user can scroll back six months and see what the coach said.*

---

### 14. You > Goals

**Route:** `/you`
**Purpose:** Nutrition + training goals. Default landing for You tab (was hidden behind theme picker).

**Layout:**

1. **4 `NumberCell`s** for kcal/P/C/F daily goals.
2. **`NumberCell`** for weekly training-session target.
3. **Suggest `Button`** below the goals — opens a `Card` with `Stat` row showing TDEE/BMR-computed suggestions from existing dob/height/weight. Per-metric "Apply" `Button`. (Phase 1)
4. **Sticky `Button`** "Save" at bottom.

**Design principle:** *The most-touched fields live at the top of the most-visited settings screen.*

---

### 15. You > Profile, Appearance, Settings

**Routes:** `/you/profile`, `/you/appearance`, `/you/settings`

- **Profile:** name, height, dob `Input`s. Weight removed (lives in Progress > Body now).
- **Appearance:** the 31-theme picker. ThemeSwatch grid grouped by family. Brutal Honesty Mode toggle (Phase 2). Refuse to Log Mode toggle (Phase 2). 
- **Settings:** units (kg/lb), week start, notifications, data export (CSV/JSON), sign out. Phase 1 adds these as proper Inputs/toggles instead of being missing.

**Design principle:** *Demote what's set-and-forget. Theme picker is identity-forming but not weekly. Goals are weekly.*

---

## Cross-screen patterns

- **Refine chat tail** appears beneath any AI-generated `Card` (meal analysis, workout autopilot suggestion, brief, drift card). Reuses the existing meal RefineChat pattern.
- **Notes via `Textarea`** appear in: end-of-workout card, per-exercise sticky (persists across sessions), per-meal log sheet, per-day journal in Eat > History day drill-down.
- **Empty states** always use one `Card` with `CardBody` (single-sentence explanation) and `CardFooter` (one primary `Button` to act). No illustrations, no marketing copy.
- **Loading states** are optimistic. The meal logs the instant shutter is tapped; macros fill in async via the pinned analyzing `Chip`. The set logs the instant Log set is tapped; rest timer starts before any network round-trip.
- **Mobile gestures (where supported):** swipe-right on a set row to complete, swipe-left to skip, long-press NumberCell for a big keypad overlay, swipe-left on a meal to open Refine, swipe-up on a meal to clone-to-now, long-press a template to set as today's plan, shake to undo, pull-down to refresh on Today.

## Overall design principle

Quiet, dense, opinionated. The app tells the user the next thing to do, shows them how they're doing in one glance, and gets out of the way. Every screen earns its place by either telling the user what to do next or giving them the truth about what they already did. No greetings. No hype. No social. Just Nyel and his data, rendered in his favorite theme.