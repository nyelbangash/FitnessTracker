# Sync notes for gym-bro-web → claude.ai/design

First-sync gotchas captured for future re-syncs. The Re-sync risks section at
the bottom is the watch-list for next time.

## Repo shape

- `gym-bro-web` is the CRA app, not a published library. There's no built
  `dist/`, no `package.json` `exports`/`main`/`module`. The converter runs in
  **synth-entry mode** against `src/ui/` (set via `cfg.srcDir`).
- **No TypeScript anywhere.** Every component is `.jsx`. The `<Name>Props`
  bodies were hand-written into `cfg.dtsPropsFor` from the JSX param
  destructuring. If a component gains a new prop, the `dtsPropsFor` entry
  has to be edited by hand — auto-extraction will keep producing weak types
  (`children?: React.ReactNode` and friends).
- The "package" is the CRA app: no separate component library is published.
  Anyone consuming the design system on the claude.ai/design side will get
  the real React components compiled out of `src/ui/*.jsx`.

## Styling

- Styling is **Tailwind utility classes + CSS custom properties + inline
  styles**. The compiled stylesheet that the design system needs is the
  *built* Tailwind output: `build/static/css/main.<hash>.css`.
  `cfg.cssEntry` points at this file.
- **Re-sync risk**: CRA changes the file's hash on every build. After running
  `npm run build`, update `cfg.cssEntry` to the new hash OR add a step that
  copies the file to a stable path. (Idea: a postbuild script that
  `cp build/static/css/main.*.css build/static/css/main.css`.)
- Themes: the app has 31 themes living in `src/theme/themes.js`. Only the
  default ("Paper") theme's CSS variables are baked into the compiled CSS.
  The other 30 are runtime-applied by `ThemeContext`. For the design system
  the agent gets the Paper palette as the "look." Multi-mode tokens are a
  follow-up.

## Excluded / skipped

- `RefineChat` is in the bundle (so the design agent can compose against it)
  but its preview is skipped via `cfg.overrides.RefineChat.skip = true` —
  it imports `../api` and renders nothing without an active `analysisId`.
  When you re-grade in future, leave it skipped unless someone mocks the
  api module.
- `ThemeContext.js` and `themes.js` aren't components — they're not in the
  scope of this sync. Themes are exposed only via the CSS variables that the
  bundle's `styles.css` defines.

## Storybook at the repo root (accidental)

- The user ran `npx storybook init` at the **parent** `FitnessTracker/` dir,
  not inside `workout-meal-tracker/`. There's a `.storybook/` and `stories/`
  one level up that's disconnected from this library.
- We chose **package shape** (no Storybook) on purpose because the install
  at the wrong level isn't useful to us. If you want Storybook fidelity in
  the future, either:
  1. Uninstall the root-level Storybook and `npx storybook init` again
     inside `workout-meal-tracker/`, then re-run /design-sync (it will
     auto-pivot to the storybook shape).
  2. Edit `../.storybook/main.js` to scan `../workout-meal-tracker/src/ui/**`
     and write `.stories.jsx` files for each primitive, then set
     `cfg.storybookConfigDir: "../"` here and re-run.

## Re-sync risks

- **`cssEntry` hash drift** — the file under `build/static/css/main.<hash>.css`
  changes hash on every CRA build. If next sync fails with `[CSS_IMPORT_MISSING]`
  or "no CSS", rebuild the React app and update `cfg.cssEntry` to the new
  hash, or copy the CSS to a stable path.
- **JSX-only contracts** — `cfg.dtsPropsFor` is hand-authored. If a component
  prop signature changes in source and no one updates `dtsPropsFor`, the
  `<Name>Props` contract goes stale silently. Audit on diff.
- **No Storybook means no reference renders**. Every preview was graded on
  the absolute rubric (styled / complete / plausible). If we ever add real
  Storybook, switch to the storybook shape for higher fidelity.
- **RefineChat depends on a runtime API call** — if `src/api.js` moves or
  changes, the bundle may still build but the preview (currently skipped)
  would never work without mocking.
- **Brand fonts** — Fraunces / Inter / JetBrains Mono are loaded via
  `@import url(https://fonts.googleapis.com/...)` in `src/index.css`, which
  gets compiled into the cssEntry. They load over the network at runtime.
  If the design system ever needs offline fonts, vendor the `.woff2` files
  into `fonts/` and rewrite the cssEntry.
