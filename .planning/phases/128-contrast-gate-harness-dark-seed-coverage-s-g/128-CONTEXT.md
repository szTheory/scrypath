# Phase 128: Contrast gate harness + dark seed coverage - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Make WCAG AA/AAA **measurable** and the dark state-space **observable** before any
pixels change. This phase builds *measurement instruments only* — no design/token
changes (those start in phase 130). It delivers:

- `@axe-core/playwright` added to the `examples/scrypath_ecommerce` Node/e2e lane.
- A new `admin_contrast_matrix.spec.ts` cloned from the proven
  `admin_screenshot_matrix.spec.ts` harness, walking the admin screens across
  `{light, dark, system-dark}` × seed scenarios and **failing the build on any AA
  color-contrast violation**; AAA (7:1) body-text status reported as advisory.
- A fast, **no-browser** Node token-pair contrast checker exposed as `make contrast`.
- npm script `test:e2e:admin-contrast` + `make contrast` Make target, re-runnable
  locally and usable as a phase gate.
- The existing 40-shot screenshot matrix continues to capture both themes cleanly as
  the dark-audit substrate (unchanged).

**Out of scope:** any change to `--color-*` tokens, `.ops-*` recipes, the dark ramp,
glow/copper/motion. This phase only *measures* — it is run first to learn the real AA
failure set that phases 129–135 then fix. (Phase 97 scope guard holds; UI-polish-only
milestone.)

</domain>

<decisions>
## Implementation Decisions

Four harness-mechanics gray areas were researched (one parallel agent each) and locked.
Calibration: technical owner, opinionated → decisive single recommendations.

### ① Matrix coverage shape — Hybrid (curated baseline + dark-risk supplement)
- **D-01:** Clone the existing **9 curated screen-states** from
  `admin_screenshot_matrix.spec.ts` (incident → control-room/posture/failed-sync(populated)/sync-drift(drift); all_green → control-room/posture/search(results); empty → failed-sync(empty)/search(zero-results)/playbooks(empty)).
- **D-02:** **Add ~3–4 dark-risk states** the screenshot curation omits — these are
  exactly where the missing `#1B2230` surface-2 ramp will bite in dark: **sync-drift
  drift-chips on a non-incident surface**, **posture populated/healthy detail**,
  **playbooks populated** (muted metadata rows), **search results + facet/secondary
  text**. Net ≈ **12–13 page-states**.
- **D-03:** **3 theme-modes**: `light`, `dark`, `system-dark`. **No `system-light` row**
  (redundant — explicit-light already covers it; only dark has a `prefers-color-scheme`
  branch in `app.css`).
- **D-04:** Scope axe to `withRules(['color-contrast'])` (fast, deterministic; this phase
  only gates contrast). **Gate strictly on `violations[]` — NEVER on `incomplete`.**
  axe returns `incomplete` (not violation) for off-screen/unresolvable nodes; gating on
  violations only is what keeps the gate free of false build-fails. Surface `incomplete`
  in the advisory report for manual triage.
- **D-05 (owner override):** **Run BOTH viewports (mobile 390, desktop 1440) and HARD-GATE
  AA on both.** Research default was desktop-gate/mobile-advisory for anti-flake; owner
  chose max coverage. Made safe by D-04 (gate on `violations` only → off-screen
  `incomplete` can't false-fail; only *real* reflow-exposed violations gate, which is the
  intent). Rationale: axe contrast IS viewport-sensitive — mobile reflow stacks muted
  metadata/chips that desktop hides in one row, so mobile carries genuine dark-muted-text
  failures worth gating.
- Approx. run count: ≈13 states × 3 modes × 2 viewports ≈ **~78 axe passes**, each a single
  scoped `color-contrast` analyze on an already-prepared page (no screenshot I/O); seed
  once per scenario group and sweep. Realistic wall time ~2–4 min — acceptable as a gate
  running alongside the screenshot matrix.

### ② System-dark drive mechanism — real OS path + runtime invariant
- **D-06:** Render `system-dark` via `browser.newContext({ colorScheme: "dark" })` **AND
  skip the `phx:theme` `addInitScript` write for that row** (start from clean
  localStorage). Clean storage → the root no-flash init takes its `"system"` branch →
  `data-theme` stays **absent** → the `@media (prefers-color-scheme: dark)` daisyUI
  `prefersdark` tokens apply on `:root`. This is a genuinely **different CSS cascade** than
  explicit `[data-theme="dark"]` (confirmed: `app.css` has a system-only
  `select.ops-form-control` chevron branch `@media (prefers-color-scheme: dark)
  html:not([data-theme="light"])`), which is exactly why it must be tested separately.
- **D-07:** **Reject** the cheap fake (writing `phx:theme="dark"` under a "system" label) —
  it takes the explicit branch and re-tests `[data-theme=dark]` under a false name, never
  exercising the media-query path. The one thing the row exists to catch is the one thing
  that approach cannot catch.
- **D-08:** **Runtime invariants** (after `waitForLiveConnected`, before the axe pass):
  assert `<html>` has **no** `data-theme`; assert
  `matchMedia('(prefers-color-scheme: dark)').matches === true` (guards a silent Playwright
  emulation no-op); assert `data-theme-effective="dark"` (ties the check to the app's own
  OS-resolution logic). Fails loudly if a future regression stamps an attribute in system
  mode.
- **D-09:** Model theme-mode as a **discriminated union** so the fake-system footgun can't
  be reintroduced and per-mode branching is exhaustive:
  `{ kind: "explicit"; theme: "light" | "dark" }  // addInitScript phx:theme, no colorScheme`
  `{ kind: "system"; colorScheme: "dark" }          // colorScheme override, NO phx:theme write`.
  Explicit-light/explicit-dark rows do **not** set `colorScheme` (keeps them honest:
  explicit theme must win regardless of OS). Report/file slug stays flat
  (`light` | `dark` | `system-dark`).

### ③ Token-pair checker — parse-CSS + tiny muted manifest, zero deps
- **D-10:** **`app.css` is the single source of truth for color values.** Parse the two
  daisyUI theme blocks for the 22 semantic `--color-*` hex values; **derive** the pairs
  (`--color-X ↔ --color-X-content`, `base-content ↔ base-100/200/300`, each status `↔
  -content`) by a fixed rule table — never re-declare hex. (Rejects a fully hand-maintained
  manifest: two sources of truth = the exact A11Y-TOKEN-01 drift footgun.)
- **D-11:** A tiny sidecar manifest (`scrypath_ops/assets/css/contrast-pairs.mjs`, beside
  `DESIGN-TOKENS.md`) holds **only the muted-alpha cases** that aren't simple semantic pairs
  (`.ops-text-meta` 55%, `.ops-trail__crumb` 60, header nav `/60`, handoff/palette/preflight
  hints, eyebrow…), referencing **token names not hex**, each with `role` and the **surface
  it composites over**. (Rejects fully-auto extraction: "which surface is this translucent
  token actually on" is unanswerable without a DOM — that ambiguity belongs to axe.)
- **D-12:** **Alpha compositing in sRGB, not OKLCH.** For opacity-only mixes
  `color-mix(in oklch, fg N%, transparent)` the oklch mix-space is a **no-op** on the
  pre-composite color (only alpha changes), so composite over the opaque surface in sRGB:
  `out = fg·α + bg·(1−α)` per channel. This matches what **axe-core itself does**, so the
  fast checker and the browser gate render one verdict. Document this in `DESIGN-TOKENS.md`.
- **D-13:** **Hand-roll the WCAG math (~30 lines), ZERO runtime deps** (sRGB→linear →
  relative luminance → `(L1+0.05)/(L2+0.05)`). Honors the lib's minimal-supply-chain stance;
  no `wcag-contrast`/`polished`. Pin a **golden self-test** (black-on-white = 21:1) so the
  math can't silently rot.
- **D-14:** **Roles → thresholds encoded per pair**: `text` → AA 4.5 / AAA 7.0;
  `large` → 3.0; `ui` (non-text/borders/focus/status + bold `+content` button pairs) → 3.0.
  Muted manifest carries `role:` explicitly; semantic pairs get role from the derivation rule
  table. Never inferred from the value.
- **D-15:** **Lockstep guards in the same `make contrast` run** (turns Option A's one weakness
  into a hard error): (1) token-count assertion vs the expected `--color-*` set; (2) grep every
  `color-mix(in oklch, var(--color-base-content) NN%, transparent)` occurrence in `app.css` and
  **fail on any `(alpha, selector)` not present in the manifest** ("untracked muted token");
  (3) a `DESIGN-TOKENS.md` pointer to `contrast-pairs.mjs` as the muted registry.
- **D-16:** **Location/DX:** the checker is a dependency-free `.mjs` in the
  `examples/scrypath_ecommerce` Node lane (keeps published `scrypath_ops` Node-free).
  `make contrast` (added to `examples/scrypath_ecommerce/Makefile`, sibling of
  `screenshots-matrix`) reads `../../scrypath_ops/assets/css/app.css`, runs **<1s, no browser/
  DB/server**, and runs **before** the slow `test:e2e:admin-contrast` matrix as the fast
  pre-check.

### ④ Report / triage output — one unified schema; gitignore runs, commit curated markdown
- **D-17:** **Both producers (axe matrix + token checker) emit the SAME unified report**
  (`scrypath.contrast.v1`) so the owner sees one failure set, not two formats. Paths
  (mirroring the matrix's `ADMIN_SCREENSHOT_DIR` convention via a `CONTRAST_REPORT_DIR` env):
  - `examples/scrypath_ecommerce/test-results/contrast/contrast-report.json` — machine source
    of truth (**gitignored**; `test-results/` already ignored).
  - `…/contrast/contrast-report.md` — generated human view (**gitignored**).
  - `.planning/phases/128-…/128-CONTRAST-REPORT.md` — **curated markdown promoted into the
    phase dir as committed, diffable evidence** (the artifact phases 129/132 read). Mirrors the
    v1.33 precedent exactly: raw PNGs gitignored, `120-AUDIT-BACKLOG.md` committed.
- **D-18:** **Finding schema fields:** `id, producer (axe|token), severity (aa-fail |
  aaa-body-advisory), screen, theme, viewport, state, shot (NN-screen--theme--viewport--state,
  ties to the PNG), element_role, selector, token_pair, fg, bg, actual_ratio, required_ratio,
  aaa_required, pass_aa, aaa_body_status, axe_rule, impact, fix_class, scope, evidence.`
- **D-19:** **Pre-seed phase 129 so it promotes rather than re-audits:** `scope=systemic`
  auto-tagged when a `(selector|token_pair)` fails on **≥3 distinct screens** (120's rule);
  token-checker findings are systemic by definition. `fix_class` seeded by producer/selector
  (`token|component|screen|motion|seed`) to match the
  `120-AUDIT-BACKLOG.md` columns. The `#1B2230` surface-2 gap surfaces here as the dark
  `aa-fail` cluster on raised `.ops-*` surfaces (becomes DARKAUDIT-01 finding #1).
- **D-20:** **AAA-body advisory:** identify body/long-form by an explicit `BODY_SELECTORS`
  allowlist (NOT axe's noisy global AAA rule). Run axe twice per page — AA ruleset (the gate)
  + `color-contrast-enhanced` scoped to `BODY_SELECTORS` (advisory). Advisory findings get
  `severity: aaa-body-advisory`, live in a **separate report section**, and **never affect
  exit code or the failing count**.
- **D-21:** **CI/exit behavior:** **write report BEFORE deciding exit** (so you can read *why*
  it failed). Exit non-zero **iff `summary.aa_fail > 0`**. Console prints the verdict line +
  AA table locally. CI: append the markdown to `$GITHUB_STEP_SUMMARY` (rich table), emit
  **one annotation per systemic cluster** (not per node), and `upload-artifact` the
  `test-results/contrast/` tree.

### Cross-cutting coherence (all four decisions are consistent by construction)
- **Identical thresholds + rounding in both checkers** (4.5 text / 3.0 large+UI / 7.0
  AAA-body, ratio to 2 dp, sRGB composite) → a pair can't pass the fast checker and fail the
  axe gate on the same fg/bg.
- `system-dark` is one **`theme` value** of the unified schema, not a separate report — and it
  measures the *real* OS-rendered colors (D-06), so the AA gate reflects what operators see.
- Mobile rows, axe `incomplete`, and AAA-body all route through the report's advisory/severity
  buckets — except mobile **AA violations**, which DO gate per owner override (D-05).
- The unified schema + `scope`/`fix_class` pre-seeding is the substrate phases 129 (audit
  backlog) and 132 (hard AA gate) consume.

### Claude's Discretion
- Exact slug/field naming within the agreed schema, the precise dark-risk supplement state
  list (within D-02's intent), and the internal structure of the `.mjs` checker are left to
  the planner/executor, provided the locked behaviors above hold.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` §"Phase 128" — goal, success criteria, `[S] [G]` tags.
- `.planning/REQUIREMENTS.md` → **CONTRAST-HARNESS-01** (the requirement this phase closes),
  plus DARKAUDIT-01 / A11Y-TOKEN-01 / DUALVERIFY-01 (downstream consumers of the report).
- `~/.claude/plans/v1-33-admin-ui-deep-tower.md` — the owner-approved v1.34 source plan.

### Harness being cloned / extended
- `examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts` — the proven matrix
  this clones (scenario-grouped seeding, theme via `addInitScript` localStorage, output
  naming `NN-screen--theme--viewport--state`).
- `examples/scrypath_ecommerce/e2e/helpers/e2e.ts` — `seedScenario`, `waitForLiveConnected`,
  `waitForSearchVisible`, `drainSearchQueue`, `SeedScenario` type.
- `examples/scrypath_ecommerce/Makefile` — add the `contrast` target (sibling of
  `screenshots` / `screenshots-matrix`); follow the `## ` self-documenting help convention.
- `examples/scrypath_ecommerce/package.json` — add `test:e2e:admin-contrast` script + the
  `@axe-core/playwright` devDependency.

### Tokens / design system
- `scrypath_ops/assets/css/app.css` — the two daisyUI theme blocks (22 `--color-*` values),
  `@custom-variant dark (&:where([data-theme=dark], …))` at line ~109, the `color-mix(… base-content N%, transparent)`
  muted patterns, and the system-only `prefers-color-scheme` branches. The token checker's input.
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` — current token doc; keep in lockstep; add the
  muted-registry pointer + the sRGB-composite note.
- `scrypath_ops/assets/vendor/daisyui-theme.js` — `prefersdark: true` on the dark theme emits
  the `@media (prefers-color-scheme: dark) { :root { … } }` block that the system-dark row
  exercises.
- `prompts/scrypath-brand-book.md` — dark-signature intent, 65/20/10/5 ratio, muted-text
  rules, AA/AAA targets (informs which dark states matter + the AAA-body allowlist).

### Downstream report format
- `.planning/milestones/v1.33-phases/120-per-touchpoint-audit/120-AUDIT-BACKLOG.md` — the
  ranked, fix-class-tagged backlog format phase 129 mirrors; the report's `fix_class`/`scope`
  fields pre-seed these columns.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`admin_screenshot_matrix.spec.ts`**: clone wholesale — scenario-grouped seeding loop,
  `shoot()`/`describeScenario()` structure, the `gotoControlRoom/Posture/FailedSync/SyncDrift/
  Search/Playbooks` prepare steps, theme-via-`addInitScript`. Replace the screenshot call with
  a scoped `AxeBuilder().withRules(['color-contrast']).analyze()`; extend the theme list from
  `["light","dark"]` to the 3-mode discriminated union (adds `system-dark` via `colorScheme`).
- **`helpers/e2e.ts`**: `seedScenario` (incident/all_green/empty via `/dev/e2e/seed`),
  `waitForLiveConnected` (where the system-dark runtime invariants attach).
- **Makefile pattern**: `screenshots`/`screenshots-matrix` targets + `ADMIN_SCREENSHOT_DIR`
  env convention → mirror for `contrast` + `CONTRAST_REPORT_DIR`.

### Established Patterns
- **Theme injection** is pre-paint via `context.addInitScript(["phx:theme", theme])`; the
  system-dark row deliberately **omits** this write and uses `newContext({ colorScheme:"dark" })`.
- **No-flash init** in the root layout resolves `phx:theme` (light|dark|absent⇒system) into
  `data-theme` + `data-theme-effective` before first paint — the contract the D-08 invariants assert.
- **Evidence discipline** (v1.33): raw run artifacts gitignored under `test-results/` / `.tmp/`;
  curated audit/report markdown committed into the phase dir. The report follows this exactly.
- **Token system**: daisyUI semantic `--color-X` / `--color-X-content` pairs + `color-mix(in
  oklch, base-content N%, transparent)` muted alphas; two theme blocks (dark `:root` default + light).

### Integration Points
- `@axe-core/playwright` is a NEW devDependency in `examples/scrypath_ecommerce` only —
  `scrypath_ops` stays Node-free.
- `make contrast` reads across the workspace boundary: `examples/scrypath_ecommerce` →
  `../../scrypath_ops/assets/css/app.css`.
- The unified JSON report is the integration seam to phases 129 (audit) and 132 (hard gate).

</code_context>

<specifics>
## Specific Ideas

- Owner explicitly wanted a **one-shot, coherent, "don't make me think"** recommendation set
  backed by per-area research (ecosystem-idiomatic, DX-first, lessons from comparable a11y
  gates) — delivered via four parallel research agents whose findings are folded into the
  decisions above.
- Owner override on **D-05**: both viewports hard-gate AA (chose max coverage over the
  anti-flake desktop-only default; safe because the gate keys on axe `violations` only).
- "Run it first to learn the real failure set" is the load-bearing purpose — under-coverage
  defeats the phase, hence the dark-risk supplement (D-02) and the unified mineable report.

</specifics>

<deferred>
## Deferred Ideas

- **Promote mobile from advisory to a hard gate** was the research default; owner instead
  hard-gated mobile now (D-05), so nothing deferred there. If mobile reflow proves flaky in
  practice, *narrowing* it back to advisory is a future tuning, not a phase-128 deliverable.
- **A `system-light` row** — deliberately excluded as redundant (explicit-light covers it). If
  a future light-specific `prefers-color-scheme` rule is ever added to `app.css`, revisit.
- **Actual contrast fixes** (re-tuning muted alphas, the `#1B2230` surface-2 ramp, glow/copper)
  — out of scope here; phases 130/132 own them. Phase 128 only measures.

None of the above are scope creep into this phase — they are correctly downstream.

</deferred>

---

*Phase: 128-Contrast gate harness + dark seed coverage*
*Context gathered: 2026-06-04*
