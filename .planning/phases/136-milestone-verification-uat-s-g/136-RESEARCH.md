# Phase 136: Milestone Verification UAT S G - Research

**Researched:** 2026-06-28
**Domain:** Elixir/Phoenix LiveView operator UI verification, Playwright accessibility/visual proof, milestone closeout
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### 1. Overall closeout strategy
- **D-01:** Use an **evidence-first layered closeout**. The binding shape is Mix/ExUnit
  + LiveView behavior proof for Phoenix-owned behavior, Playwright/axe/computed-style
  proof for browser-owned theme/accessibility/JS behavior, screenshot artifacts for
  visual review, and bounded human UAT for perceptual claims automation cannot judge.
- **D-02:** Do not use automation-only closeout. It would miss the roadmap's before/after
  gallery and human UAT requirements and would under-prove "both themes are perfect"
  as a design-system milestone.
- **D-03:** Do not promote the full Phase 136 browser bundle into permanent required CI
  during this phase. The optional operator UI remains important proof, but the repo's
  release-train posture still treats expensive browser lanes as advisory unless concrete
  adopter evidence or a maintainer decision changes that policy.
- **D-04:** If a must-fix defect is found, Phase 136 may become a fix-and-rerun loop, but
  only for defects that block the closeout thresholds below. Aesthetic nits or future
  evidence improvements are documented as follow-ups.

### 2. Binding proof gates
- **D-05:** Required Elixir/Phoenix gate bundle:
  - root `mix verify.opsui` for the repository contributor/CI parity contract;
  - ScrypathOps app-level `cd scrypath_ops && mix verify.opsui` when the local alias is
    needed to include `opsui.test_a11y`;
  - `cd scrypath_ops && mix precommit` if source changed during Phase 136 or if the planner
    needs final app-level compile/format/test confidence.
- **D-06:** Required browser/token gate bundle:
  - rebuild ScrypathOps assets before browser proof so the mounted ecommerce app uses
    current source, not stale compiled CSS/JS;
  - run `cd examples/scrypath_ecommerce && make contrast`;
  - run Playwright `admin_contrast_matrix`, `admin_surface_depth`, `admin_path_motion`,
    `admin_shell_chrome`, and `admin_screenshot_matrix`;
  - run the mounted ecommerce admin smoke, preferably `npm run test:e2e -- e2e/operator.spec.ts`
    or the existing full smoke if stable.
- **D-07:** Browser proof must run against a source-backed ecommerce server on a known
  `PLAYWRIGHT_BASE_URL`, not an old baked image. Record the boot method, port, seed
  method, asset-build command, and any retries in the report.
- **D-08:** AA failures are hard blockers in light, dark, and system-dark. AAA body findings
  remain advisory/report-only unless they reveal a new trust/readability regression that
  contradicts the Phase 132 baseline.
- **D-09:** Reduced-motion proof is binding. Path-motion and shell-interaction claims must
  still snap to usable end states under `prefers-reduced-motion: reduce`; no decorative
  loops, re-firing LiveView patch keyframes, or hidden motion regressions.
- **D-10:** System-dark is not optional. Even if the screenshot gallery preserves the
  historical 40-shot light/dark shape, system-dark must be proven by the contrast matrix,
  shell/depth/browser checks, and explicit report language that the media-query path was
  exercised without forcing `localStorage["phx:theme"]`.

### 3. Artifact architecture and repository hygiene
- **D-11:** Commit reports and manifests, not generated binary screenshots. Generated PNGs,
  Playwright traces, test-results, `.tmp`, built `scrypath_ops/priv/static/**`, and raw
  browser JSON outputs stay ignored/untracked unless an existing tracked artifact contract
  says otherwise.
- **D-12:** Produce these Phase 136 closeout artifacts:
  - `136-DUALVERIFY-REPORT.md` — exact command transcript summary, environment, gate
    results, AA/AAA summary, reduced-motion status, smoke status, artifact locations,
    and defect/follow-up decisions.
  - `136-ARTIFACT-MANIFEST.json` — generated artifact index with counts, paths, checksums,
    source commit, command provenance, and whether each artifact is committed or generated.
  - `136-BEFORE-AFTER.md` — dark-weighted v1.33 -> v1.34 gallery narrative with paired
    screenshot references and claim-based captions.
  - `136-MILESTONE-AUDIT.md` — requirement-by-requirement audit of v1.34 intent vs. delivery,
    including phases 128-136 and any evidence gaps.
  - `136-UAT.md` — human UAT checklist, findings, sign-off status, and accepted follow-ups.
- **D-13:** The artifact manifest should record the expected historical 40-shot matrix count
  from `admin_screenshot_matrix.spec.ts`: 10 screen-state captures x 2 themes x 2 viewports.
  If the shared theme grid's newer 13-state set is used for other gates, document that it is
  a broader proof substrate, not a silent replacement for the historical gallery count.
- **D-14:** Preserve the historical 40-shot light/dark gallery by default for comparability
  with v1.33. Do **not** promote full system-dark screenshots into the main gallery unless
  a concrete visual drift concern appears. If needed, add a small system-dark contact sheet
  or targeted spot shots as supplemental evidence.
- **D-15:** The before/after gallery is claim-based, not a raw image dump. Each row should
  name the JTBD claim being proven: route orientation, posture trust, failed-sync recovery,
  drift clarity, search exploration, playbook workspace clarity, shell restraint, focus,
  and theme parity.

### 4. Human UAT and closeout thresholds
- **D-16:** Human UAT is bounded and job-based. The reviewer inspects the six operator
  surfaces in dark first, then light parity, then system-dark evidence, asking:
  "Can I tell search posture, the next recovery/explore action, and whether the UI is calm,
  accessible, and trustworthy?"
- **D-17:** UAT must exercise the domain nouns/events/verbs:
  - nouns: Control Room, Posture, Failed Sync, Sync/Drift, Search, Playbooks, command palette,
    theme toggle, flash, focus ring, result row, drift chip, playbook card;
  - events: seed incident/all_green/empty states, navigate, refresh posture, load drift, run
    search, save a playbook, open/close palette and shortcut sheet, toggle system/light/dark;
  - verbs: inspect, recover, explore, refresh, search, compare, close, switch, trust.
- **D-18:** Must-fix before milestone close:
  - any failing required command or browser gate;
  - any AA contrast failure or disabled/suppressed color-contrast rule;
  - focus not visible, obscured, trapped incorrectly, or not returned after modal/palette close;
  - reduced-motion regression or LiveView patch re-firing motion;
  - stale asset proof, wrong server lane, missing seed proof, or screenshot count/checksum mismatch;
  - visual defect that blocks trust, scanability, task orientation, or light/dark/system parity.
- **D-19:** Acceptable follow-ups:
  - small aesthetic nits that do not affect trust, accessibility, scanability, or theme parity;
  - full system-dark screenshot matrix expansion;
  - permanent CI promotion of browser proof;
  - extra gallery automation or artifact upload workflow;
  - broader brand/docs/HexDocs adoption polish unrelated to v1.34's operator UI proof.
- **D-20:** If Phase 136 edits product source to fix a must-fix issue, the report must name
  the defect, source files changed, gates rerun, screenshots recaptured, and whether the
  before/after gallery was regenerated after the fix. No silent proof reuse after source edits.

### 5. Expert-lens recommendations captured from research
- **D-21:** Elixir/Phoenix idiom: keep framework-owned behavior in Mix/ExUnit/LiveView tests;
  use Playwright only for real browser state such as theme cascade, CSS computed values,
  focus behavior, localStorage/theme selection, screenshots, and axe accessibility scans.
- **D-22:** OSS DX idiom: keep required contributor gates lean and deterministic; store generated
  evidence as artifacts/manifests, not committed binary bloat; avoid making optional admin-browser
  proof a branch-protection blocker without explicit release policy.
- **D-23:** Design-system idiom: final visual review should validate accessibility, clarity,
  consistency, performance, resilience, maintainability, restraint, developer ergonomics, and
  brand fit. It should not reopen palette/type/logo choices; v1.35 kept tokens stable and v1.34
  is verifying inherited brand expression.
- **D-24:** User psychology/JTBD: operational UI should reduce uncertainty. The final proof should
  prioritize calm hierarchy, visible next action, evidence readability, and trust-building states
  over decorative "wow" moments.

### the agent's Discretion
- The planner may choose whether `136-DUALVERIFY-REPORT.md` contains a contrast subsection or
  whether a separate `136-CONTRAST-REPORT.md` is worth creating. The required outcome is one
  clear final AA/AAA summary with generated report paths.
- Exact artifact-manifest schema is left to the planner, but it must be machine-readable JSON,
  include checksums/counts, and distinguish generated artifacts from committed reports.
- If existing server boot scripts are already reliable, use them rather than adding a new harness.
  Add a thin Phase 136 proof harness only if it materially reduces missed commands or stale-server risk.

### Deferred Ideas (OUT OF SCOPE)
- Full system-dark screenshot matrix promotion — defer unless Phase 136 finds a concrete visual drift
  risk not covered by contrast/shell/depth proof.
- Permanent CI/branch-protection promotion of all browser proof — defer until maintainer policy or
  adopter evidence justifies the cost and flake risk.
- Gallery automation beyond a clear Markdown report + manifest — defer unless manual artifact assembly
  becomes repeatably error-prone.
- Additional brand/HexDocs/website adoption polish — out of scope for v1.34 verification; v1.35 already
  handled brand adoption and token stability.
- New operator workflows, nav IA, runtime search capability, or productized admin expansion — out of
  scope under the Phase 97 scope guard and the v1.34 UI-polish boundary.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DUALVERIFY-01 | End-to-end proof: `mix verify.opsui` + ScrypathOps LiveView suite + mounted ecommerce admin Playwright smoke green; CONTRAST-HARNESS-01 AA in both themes with AAA-body report; 40-shot matrix re-captured with a v1.33→v1.34 before/after gallery; milestone audit + human UAT. | Existing commands, specs, reports, and artifact conventions are identified below; no new runtime capability or package install is needed. [VERIFIED: .planning/REQUIREMENTS.md + codebase grep] |
</phase_requirements>

## Summary

Phase 136 should be planned as a closeout and evidence aggregation phase, not as another broad UI polish phase. The repo already contains the required proof machinery: root `mix verify.opsui`, ScrypathOps `verify.opsui`/`opsui.test_a11y`, Playwright contrast/depth/path-motion/shell/screenshot specs, mounted operator smoke, and prior report patterns from Phases 128, 132, 134, and 135. [VERIFIED: codebase grep]

The critical planning risks are operational, not architectural: stale `scrypath_ops` assets, stale/baked ecommerce server lanes, confusing the 13-state contrast/depth substrate with the historical 40-shot gallery, omitting system-dark, treating AAA advisory as a hard gate, committing binary/browser artifacts, and reusing proof after source fixes. [VERIFIED: 136-CONTEXT.md + codebase grep]

**Primary recommendation:** Use the existing harnesses in a strict evidence order: build assets, boot or restart a source-backed ecommerce server, run Elixir gates, run static/browser gates, capture the 40-shot matrix, build a checksum manifest, write the before/after/audit/UAT reports, then rerun any affected proof after must-fix edits. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| ScrypathOps behavior and LiveView render contracts | Frontend Server (Phoenix LiveView) | Database / Storage | Mix/ExUnit and LiveView tests own connected UI behavior, Ecto setup, route contracts, and server-rendered state. [VERIFIED: scrypath_ops/mix.exs + Phoenix LiveView docs] |
| Theme cascade, focus, palette, reduced-motion, screenshots | Browser / Client | Frontend Server | Playwright owns computed CSS, localStorage/system color-scheme, focus interactions, screenshots, traces, and axe scans. [VERIFIED: examples/scrypath_ecommerce/e2e/*.spec.ts] |
| Contrast gate | Browser / Client | Static Node script | `make contrast` performs token-pair checks; `admin_contrast_matrix` performs axe AA/AAA browser scans over light/dark/system-dark. [VERIFIED: Makefile + admin_contrast_matrix.spec.ts] |
| Mounted ecommerce smoke | Browser / Client | API / Backend | `operator.spec.ts` exercises the mounted admin through real browser flows and backend seed/state endpoints. [VERIFIED: operator.spec.ts] |
| Closeout reports and manifest | Planning Docs / Local Filesystem | Browser artifacts | Markdown/JSON summaries are committed; raw screenshots, traces, browser JSON, `.tmp`, and generated static assets stay generated/ignored. [VERIFIED: 136-CONTEXT.md + .gitignore] |
| Human UAT | Human Review | Browser / Planning Docs | Automation cannot judge all perceptual trust/scanability claims, so UAT consumes the live app plus generated gallery evidence. [VERIFIED: 136-CONTEXT.md] |

## Project Constraints (from AGENTS.md)

- Scrypath is an Elixir OSS library; ecosystem fit for Ecto/Phoenix is central. [VERIFIED: AGENTS.md]
- Public v1 targets Meilisearch first while preserving an internal adapter seam; Phase 136 must not add public backend abstraction. [VERIFIED: AGENTS.md]
- v1 supports inline, Oban-backed, and manual sync flows; verification should not hide eventual consistency or operational failure modes. [VERIFIED: AGENTS.md]
- Developer experience and Phoenix ergonomics are top priority, with correctness close behind. [VERIFIED: AGENTS.md]
- Eventual consistency, delete semantics, backfills, and reindex workflows must remain explicit. [VERIFIED: AGENTS.md]
- The release train posture keeps `main` green, uses lean required gates, prefers PR-first serious feature work, and avoids speculative scope when no approved work exists. [VERIFIED: AGENTS.md]
- CONTRIBUTING.md is the source for verification commands and CI/release gates. [VERIFIED: CONTRIBUTING.md]
- No project-local `CLAUDE.md` or `.claude/.agents` skill files exist in this workspace. [VERIFIED: shell probe]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix | Elixir 1.19.5, Mix 1.19.5, OTP 28 local; project floor `~> 1.17` | Run root and ScrypathOps Mix gates | Existing repo language/runtime and supported floor/head policy. [VERIFIED: elixir --version + mix.exs] |
| Phoenix | 1.8.7 in `scrypath_ops/mix.lock` | ScrypathOps Phoenix app | Existing operator UI framework. [VERIFIED: scrypath_ops/mix.lock] |
| Phoenix LiveView | 1.1.31 in `scrypath_ops/mix.lock` | LiveView screens, JS hooks, tests | Existing connected UI substrate; official docs support LiveView behavior tests for server-owned behavior. [VERIFIED: scrypath_ops/mix.lock] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| `@playwright/test` | 1.60.0 in `package-lock`; `package.json` range `^1.54.2` | Browser proof, screenshots, media emulation, smoke tests | Existing executable browser framework; official docs support contexts, screenshots, emulation, traces, and test artifacts. [VERIFIED: package-lock + npm ls] [CITED: https://playwright.dev/docs/emulation] |
| `@axe-core/playwright` | 4.11.3 | Browser accessibility and contrast scanning | Existing axe integration used by contrast and shell gates. [VERIFIED: package-lock + npm registry] [CITED: https://playwright.dev/docs/accessibility-testing] |
| WCAG 2.2 AA/AAA thresholds | AA text 4.5:1, non-text 3:1, AAA text 7:1 | Contrast/focus/reduced-motion closeout criteria | Matches existing token docs and W3C criteria. [VERIFIED: DESIGN-TOKENS.md] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `pixelmatch` | 5.3.0 | Light pixel-diff support | Only if a source fix introduces light-theme movement requiring the existing light diff gate. [VERIFIED: package-lock + npm registry] |
| `pngjs` | 7.0.0 top-level; 6.0.0 transitive under `pixelmatch` | PNG parsing for pixel diffs | Existing support for `light-pixel-diff.mjs`; no new use unless light-diff is required. [VERIFIED: package-lock] |
| Docker / Docker Compose | Docker 29.5.2, Compose v5.1.3 local | Start ecommerce demo dependencies and source-backed test lane | Use existing Makefile/compose paths when a local source server must be booted cleanly. [VERIFIED: docker info + docker compose version] |
| PostgreSQL | local `pg_isready` accepting on default socket | ScrypathOps/Ecto tests and ecommerce demo | Required by Mix/Ecto tests and demo server. [VERIFIED: pg_isready] |
| Meilisearch | not listening on `127.0.0.1:7700` at research time | Search visibility and ecommerce E2E seed flows | Start via `make infra` or compose lane before browser proof. [VERIFIED: curl /health probe + Makefile] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing Playwright specs | New Phase 136 mega-spec | Do not create a parallel harness unless it reduces stale-server or missed-command risk; existing specs already bind the required claims. [VERIFIED: 136-CONTEXT.md] |
| Committed PNG gallery | Git-tracked screenshots | Rejected by context; commit manifest/report references, counts, and checksums instead. [VERIFIED: 136-CONTEXT.md] |
| Permanent CI promotion | Required branch-protection browser lane | Rejected for this phase; keep browser proof advisory unless maintainer policy changes. [VERIFIED: 136-CONTEXT.md + CONTRIBUTING.md] |
| Automation-only closeout | No human UAT | Rejected; roadmap requires gallery/audit/UAT and automation cannot judge all perceptual trust claims. [VERIFIED: 136-CONTEXT.md] |

**Installation:**

```bash
# No new packages should be installed in Phase 136.
# If node_modules is absent, restore the checked-in lockfile state:
cd examples/scrypath_ecommerce && npm ci
```

**Version verification:** `npm ls` shows `@playwright/test@1.60.0`, `@axe-core/playwright@4.11.3`, `pixelmatch@5.3.0`, and `pngjs@7.0.0`; `npx playwright --version` also reports `Version 1.60.0`. [VERIFIED: npm ls + npx playwright --version]

## Package Legitimacy Audit

> Phase 136 should not install or upgrade packages. This audit records the existing browser-test packages so the planner avoids dependency churn. [VERIFIED: package-lock + package-legitimacy seam]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `@playwright/test` | npm | Existing lockfile resolves 1.60.0; latest publish activity was recent at research time | 41,010,180/wk | github.com/microsoft/playwright | SUS if newly installing/upgrading because the seam flagged current package activity as `too-new` | Use existing lockfile only; no install/upgrade task. [VERIFIED: npm registry + package-legitimacy] |
| `@axe-core/playwright` | npm | Existing lockfile resolves 4.11.3; latest publish activity was recent at research time | 5,029,383/wk | github.com/dequelabs/axe-core-npm | SUS if newly installing/upgrading because the seam flagged current package activity as `too-new` | Use existing lockfile only; no install/upgrade task. [VERIFIED: npm registry + package-legitimacy] |
| `pixelmatch` | npm | Existing lockfile resolves 5.3.0 | 7,148,875/wk | github.com/mapbox/pixelmatch | OK | Keep existing; use only through existing light-diff script. [VERIFIED: npm registry + package-legitimacy] |
| `pngjs` | npm | Existing lockfile resolves 7.0.0 | 41,700,566/wk | github.com/pngjs/pngjs | OK | Keep existing; use only through existing light-diff script. [VERIFIED: npm registry + package-legitimacy] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: package-legitimacy seam]
**Packages flagged as suspicious [SUS]:** `@playwright/test`, `@axe-core/playwright` only if a plan tries to install or upgrade them; Phase 136 should avoid that path. [VERIFIED: package-legitimacy seam]

## Architecture Patterns

### System Architecture Diagram

```text
Phase 136 closeout request
  |
  v
Read context + current git state
  |
  v
Build ScrypathOps assets
  |
  v
Boot/restart source-backed ecommerce app on recorded PLAYWRIGHT_BASE_URL
  |
  +--> Elixir/Phoenix gates
  |      root mix verify.opsui
  |      cd scrypath_ops && mix verify.opsui
  |      optional cd scrypath_ops && mix precommit if source changed
  |
  +--> Static/browser gates
  |      make contrast
  |      admin_contrast_matrix
  |      admin_surface_depth
  |      admin_path_motion
  |      admin_shell_chrome
  |      operator.spec.ts smoke
  |
  +--> Screenshot matrix
  |      admin_screenshot_matrix -> 40 PNGs
  |
  v
Manifest builder
  -> paths, counts, sha256, source commit, command provenance, committed/generated flag
  |
  v
Committed closeout docs
  136-DUALVERIFY-REPORT.md
  136-ARTIFACT-MANIFEST.json
  136-BEFORE-AFTER.md
  136-MILESTONE-AUDIT.md
  136-UAT.md
  |
  v
Human UAT sign-off or must-fix loop
```

### Recommended Project Structure

```text
.planning/phases/136-milestone-verification-uat-s-g/
├── 136-RESEARCH.md
├── 136-DUALVERIFY-REPORT.md
├── 136-ARTIFACT-MANIFEST.json
├── 136-BEFORE-AFTER.md
├── 136-MILESTONE-AUDIT.md
└── 136-UAT.md

examples/scrypath_ecommerce/test-results/
├── contrast/
├── admin-screenshots/
├── admin-path-motion/
└── playwright-report/
```

Generated files under `examples/scrypath_ecommerce/test-results/`, `.tmp`, and generated `scrypath_ops/priv/static/**` should remain uncommitted except for the four existing tracked static source files. [VERIFIED: .gitignore + git ls-files]

### Pattern 1: Evidence-First Layered Closeout

**What:** Run server-owned and browser-owned proof separately, then aggregate evidence into committed reports. [VERIFIED: 136-CONTEXT.md]

**When to use:** Always for DUALVERIFY-01. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```bash
mix verify.opsui
cd scrypath_ops && mix verify.opsui
cd examples/scrypath_ecommerce && make contrast
cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run test:e2e:admin-contrast -- --reporter=line
cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run test:e2e:admin-depth -- --reporter=line
cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run test:e2e:path-motion -- --reporter=line
cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run test:e2e:admin-shell -- --reporter=line
cd examples/scrypath_ecommerce && ADMIN_SCREENSHOT_DIR=test-results/admin-screenshots/phase136 PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run test:e2e:admin-matrix -- --reporter=line
cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run test:e2e -- e2e/operator.spec.ts --reporter=line
```

### Pattern 2: Source-Backed Browser Proof

**What:** Rebuild ScrypathOps assets, restart or boot the ecommerce app from current source, and record the boot lane/port before browser proof. [VERIFIED: Makefile + 136-CONTEXT.md]

**When to use:** Before all Playwright gates and screenshots. [VERIFIED: 136-CONTEXT.md]

**Why:** Prior phases recorded that the ecommerce demo can otherwise serve stale path-dependency CSS/JS. [VERIFIED: .planning/STATE.md]

### Pattern 3: Machine-Readable Artifact Manifest

**What:** Write JSON with command provenance, counts, sha256 checksums, source commit, generated-vs-committed status, and known artifact roots. [VERIFIED: 136-CONTEXT.md]

**Example:**

```json
{
  "schema": "scrypath.phase136.artifacts.v1",
  "source_commit": "HEAD",
  "base_url": "http://127.0.0.1:4002",
  "artifacts": [
    {
      "kind": "screenshot-matrix",
      "path": "examples/scrypath_ecommerce/test-results/admin-screenshots/phase136",
      "expected_count": 40,
      "actual_count": 40,
      "committed": false,
      "sha256": "directory-manifest-or-per-file-checksums"
    }
  ]
}
```

### Pattern 4: Job-Based Human UAT

**What:** Convert the context's nouns/events/verbs into a bounded checklist with result, evidence, and accepted follow-up fields. [VERIFIED: 136-CONTEXT.md]

**When to use:** After automated gates and screenshot gallery are available; rerun or amend if must-fix source changes occur. [VERIFIED: 136-CONTEXT.md]

### Anti-Patterns to Avoid

- **New generic verification harness:** Use the existing Mix/Playwright scripts unless a thin wrapper materially reduces stale-server or missed-command risk. [VERIFIED: 136-CONTEXT.md]
- **Automation-only closeout:** It misses required gallery/audit/UAT deliverables. [VERIFIED: 136-CONTEXT.md]
- **Binary artifact commits:** Commit reports and manifests, not screenshots/traces/raw JSON. [VERIFIED: 136-CONTEXT.md]
- **System-dark by implication:** Explicit dark does not prove the media-query path; use `colorScheme: "dark"` with no `phx:theme` write. [VERIFIED: theme-grid.ts + admin_contrast_matrix.spec.ts]
- **Silent proof reuse after fixes:** Any product-source fix invalidates affected screenshots and gates. [VERIFIED: 136-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Accessibility scanning | Custom contrast crawler | `make contrast` and `admin_contrast_matrix.spec.ts` with `@axe-core/playwright` | Existing gate already separates AA failures from AAA advisory and writes scenario reports. [VERIFIED: codebase grep] |
| Browser theme/motion proof | Manual CSS inspection only | Existing Playwright specs with `THEME_MODES`, `assertSystemDarkInvariants`, and reduced-motion contexts | The specs cover actual browser cascade, computed styles, and motion end states. [VERIFIED: e2e specs] |
| LiveView behavior proof | Browser-only assertions | `mix verify.opsui`, `cd scrypath_ops && mix verify.opsui`, focused LiveView test files | Phoenix-owned behavior is cheaper and more deterministic in ExUnit/LiveView tests. [VERIFIED: scrypath_ops/mix.exs] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| Screenshot matrix | New screenshot naming or count scheme | `admin_screenshot_matrix.spec.ts` historical 40-shot output | Existing gallery count and filename convention are part of the milestone contract. [VERIFIED: admin_screenshot_matrix.spec.ts + 136-CONTEXT.md] |
| Checksum logic | Custom crypto implementation | `shasum -a 256` or Node `crypto` APIs | Use standard checksumming; the manifest only needs reproducible identifiers. [ASSUMED] |
| Demo boot lane | Ad hoc Phoenix/Docker commands | Makefile/compose targets plus recorded `PLAYWRIGHT_BASE_URL` | Existing targets encode ports, seed flow, and source-server expectations. [VERIFIED: Makefile] |

**Key insight:** The hard part is not inventing tests; it is sequencing existing proof so every artifact is fresh, attributable, and honest. [VERIFIED: 136-CONTEXT.md + codebase grep]

## Common Pitfalls

### Pitfall 1: Stale Source Or Assets
**What goes wrong:** Browser proof passes against old CSS/JS or a baked image. [VERIFIED: .planning/STATE.md]
**Why it happens:** The ecommerce app serves compiled assets and path-dependency code; prior phases recorded stale-server gotchas. [VERIFIED: .planning/STATE.md]
**How to avoid:** Rebuild `scrypath_ops` assets and restart or boot a source-backed ecommerce lane before browser gates. [VERIFIED: 136-CONTEXT.md]
**Warning signs:** The report lacks boot method, asset-build command, port, seed method, or source commit. [VERIFIED: 136-CONTEXT.md]

### Pitfall 2: Package Version Drift
**What goes wrong:** `package.json` says `^1.54.2`, while lockfile/local Playwright resolves to 1.60.0. [VERIFIED: package.json + package-lock + npm ls]
**Why it happens:** Caret range plus lockfile state. [VERIFIED: package-lock]
**How to avoid:** Use `npm ci` only if needed; do not run `npm install` or upgrade packages in this phase. [VERIFIED: package-lock + package-legitimacy]
**Warning signs:** `package-lock.json` changes during a docs/evidence phase. [VERIFIED: git status methodology]

### Pitfall 3: Confusing 13-State Proof With 40-Shot Gallery
**What goes wrong:** Planner uses the broader `SCENARIO_CAPTURES` 13-state grid as a silent replacement for the historical 40-shot gallery. [VERIFIED: theme-grid.ts + admin_screenshot_matrix.spec.ts]
**Why it happens:** Newer shared theme grid has extra states, while `admin_screenshot_matrix` preserves the historical 10-state light/dark shape. [VERIFIED: codebase grep]
**How to avoid:** Manifest both: 40-shot gallery count for before/after, 13-state substrate for contrast/depth/shell proof. [VERIFIED: 136-CONTEXT.md]
**Warning signs:** `136-ARTIFACT-MANIFEST.json` does not list expected count 40 for screenshot matrix. [VERIFIED: 136-CONTEXT.md]

### Pitfall 4: System-Dark Omitted
**What goes wrong:** Explicit dark passes but media-query system dark is untested. [VERIFIED: theme-grid.ts]
**Why it happens:** `localStorage["phx:theme"]="dark"` exercises a different path from `colorScheme: "dark"` with no theme key. [VERIFIED: admin_contrast_matrix.spec.ts]
**How to avoid:** Require contrast/depth/shell rows to include system-dark invariants. [VERIFIED: codebase grep]
**Warning signs:** Report says "both themes" but does not mention system-dark/no `phx:theme`. [VERIFIED: 136-CONTEXT.md]

### Pitfall 5: Generated Evidence Accidentally Staged
**What goes wrong:** PNGs, traces, `.tmp`, browser JSON, or hashed static assets enter git. [VERIFIED: .gitignore + git status]
**Why it happens:** Browser gates generate many local files under ignored paths, and `scrypath_ops/priv/static` has only a few tracked canonical files. [VERIFIED: git ls-files]
**How to avoid:** Commit only Phase 136 Markdown/JSON reports; use `git status --short` before commit. [VERIFIED: 136-CONTEXT.md]
**Warning signs:** `git status` shows `test-results`, `.tmp`, or `scrypath_ops/priv/static/assets/` staged. [VERIFIED: current git status]

### Pitfall 6: Unrelated Dirty Worktree
**What goes wrong:** Phase 136 commit accidentally includes existing user changes. [VERIFIED: git status]
**Why it happens:** Current worktree contains many modified/untracked files unrelated to this research artifact. [VERIFIED: git status]
**How to avoid:** Plans must stage only explicit Phase 136 report files and must not revert unrelated changes. [VERIFIED: developer instructions + git status]
**Warning signs:** Commit file list includes source files outside `.planning/phases/136-*` without a documented must-fix defect. [VERIFIED: 136-CONTEXT.md]

## Code Examples

### Manifest Count And Checksum Probe

```bash
find examples/scrypath_ecommerce/test-results/admin-screenshots/phase136 -maxdepth 1 -type f -name '*.png' | wc -l
find examples/scrypath_ecommerce/test-results/admin-screenshots/phase136 -maxdepth 1 -type f -name '*.png' -print0 | sort -z | xargs -0 shasum -a 256
```

Source: local artifact-manifest requirement and standard checksum tooling. [VERIFIED: 136-CONTEXT.md] [ASSUMED]

### System-Dark Invariant Already In Harness

```typescript
await expect(page.locator("html")).not.toHaveAttribute("data-theme");
await expect(page.locator("html")).toHaveAttribute("data-theme-effective", "dark");
```

Source: `examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts`. [VERIFIED: codebase grep]

### UAT Result Row Shape

```markdown
| Check | Surface | Theme | Result | Evidence | Follow-up |
|-------|---------|-------|--------|----------|-----------|
| Can I tell whether search can be trusted? | Control Room + Posture | dark first, then light/system-dark | pass/fail | screenshot path + live observation | must/should/nice |
```

Source: Phase 136 human UAT constraints. [VERIFIED: 136-CONTEXT.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| v1.33 two-theme 40-shot matrix for visual audit | v1.34 keeps 40-shot gallery for comparison and adds three-theme contrast/depth/shell proof | Phase 128 onward | System-dark is proven by browser gates, while gallery remains comparable to v1.33. [VERIFIED: ROADMAP + codebase grep] |
| Reports without per-scenario contrast output | Scenario-suffixed contrast report files | After Phase 128 baseline limitation | Phase 136 can summarize per-scenario AA/AAA without clobbered report files. [VERIFIED: 128-CONTRAST-REPORT.md + admin_contrast_matrix.spec.ts] |
| Subjective motion read | Reduced-motion and patch-refire assertions in `admin_path_motion.spec.ts` | Phase 133 | Reduced-motion and LiveView patch safety are binding browser gates. [VERIFIED: admin_path_motion.spec.ts] |
| Shell chrome visual-only review | 33-test shell browser proof plus static token contracts | Phase 135 | Focus, palette/sheet, theme toggle, flash, and shell chrome are automated across light/dark/system-dark. [VERIFIED: test list + 135-SHELL-CHROME-REPORT.md] |

**Deprecated/outdated:**
- Treating explicit dark as sufficient is outdated for this milestone; system-dark is a separate proof path. [VERIFIED: 136-CONTEXT.md]
- Committing generated screenshots as source is rejected for Phase 136. [VERIFIED: 136-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A standard checksum tool such as `shasum -a 256` is acceptable for manifest checksums. | Don't Hand-Roll / Code Examples | Planner may prefer Node `crypto`; either standard approach is fine if deterministic. |
| A2 | A human reviewer will be available to complete bounded UAT during Phase 136. | Architecture Patterns / Validation Architecture | If no reviewer is available, automated proof can finish but milestone UAT cannot honestly pass. |

## Open Questions

1. **Exact v1.33 screenshot source for before/after pairs**
   - What we know: commit `ae33d36` is the v1.33 admin milestone commit, `origin/gsd/v1.33-admin-ui-insane-polish` exists, and the old `v1.33-BEFORE-AFTER.md` documents the 40-shot pattern. [VERIFIED: git log + git branch + file read]
   - What's unclear: the untracked `.tmp/admin-screenshots` directories are not durable evidence and may have been overwritten by later v1.34 recaptures. [VERIFIED: find + .gitignore]
   - Recommendation: use a separate worktree or recorded commit checkout if exact v1.33 screenshots must be regenerated; otherwise label any narrative-only v1.33 comparison honestly in `136-BEFORE-AFTER.md`. [VERIFIED: git log] [ASSUMED]

2. **Separate contrast report or subsection**
   - What we know: context allows either a contrast subsection in `136-DUALVERIFY-REPORT.md` or a separate `136-CONTRAST-REPORT.md`. [VERIFIED: 136-CONTEXT.md]
   - What's unclear: whether the planner wants a smaller main report or one consolidated closeout report. [VERIFIED: 136-CONTEXT.md]
   - Recommendation: keep one `136-DUALVERIFY-REPORT.md` with a contrast subsection unless the browser report volume becomes unwieldy. [ASSUMED]

3. **Server boot lane**
   - What we know: Docker is available, an app is listening on `127.0.0.1:4002`, but Meilisearch is not listening on `127.0.0.1:7700` during research. [VERIFIED: docker info + curl probes]
   - What's unclear: whether the current `:4002` app is source-fresh enough for final proof. [VERIFIED: curl probe only]
   - Recommendation: restart or boot the lane explicitly during execution and record commands instead of relying on the pre-existing process. [VERIFIED: 136-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | Mix gates | ✓ | Elixir 1.19.5 / Mix 1.19.5 / OTP 28 | None needed. [VERIFIED: shell probe] |
| Node.js | Playwright/npm scripts | ✓ | v22.14.0 | None needed. [VERIFIED: shell probe] |
| npm | Browser deps/scripts | ✓ | 11.1.0 | Use `npm ci` if node_modules absent. [VERIFIED: shell probe] |
| Playwright CLI | Browser proof | ✓ | 1.60.0 | Use checked-in lock; do not upgrade. [VERIFIED: npx playwright --version] |
| Docker / Compose | Source-backed demo dependencies | ✓ | Docker 29.5.2 / Compose v5.1.3 | Host `make dev` lane if Docker lane is unsuitable. [VERIFIED: shell probe + Makefile] |
| PostgreSQL | Ecto tests/demo | ✓ | accepting on default socket | Compose Postgres via existing Makefile if default socket is unsuitable. [VERIFIED: pg_isready] |
| Meilisearch | Ecommerce seed/search flows | ✗ at `127.0.0.1:7700` during research | — | Start via `cd examples/scrypath_ecommerce && make infra` or chosen compose lane. [VERIFIED: curl /health + Makefile] |
| Ecommerce app | Playwright target | ✓ but freshness untrusted | Responding on `127.0.0.1:4002` | Restart/boot source lane and record boot method. [VERIFIED: curl + lsof] |

**Missing dependencies with no fallback:** none identified; Meilisearch is missing at the default port but has existing Makefile/compose startup paths. [VERIFIED: Makefile]

**Missing dependencies with fallback:** Meilisearch default listener missing; fallback is `make infra` or lane-specific ports. [VERIFIED: Makefile + curl probe]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Mix/ExUnit + Phoenix LiveViewTest; Playwright `@playwright/test` 1.60.0; axe via `@axe-core/playwright` 4.11.3. [VERIFIED: mix.exs + package-lock] |
| Config file | `scrypath_ops/mix.exs`, `examples/scrypath_ecommerce/playwright.config.ts`. [VERIFIED: codebase grep] |
| Quick run command | `mix verify.opsui`. [VERIFIED: lib/mix/tasks/verify.opsui.ex] |
| Full suite command | Run the Phase 136 gate bundle listed in Pattern 1 against a recorded source-backed `PLAYWRIGHT_BASE_URL`. [VERIFIED: 136-CONTEXT.md] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DUALVERIFY-01 | Root ops UI contributor parity gate green | integration | `mix verify.opsui` | ✅ `lib/mix/tasks/verify.opsui.ex` [VERIFIED] |
| DUALVERIFY-01 | ScrypathOps app LiveView/a11y suite green | integration | `cd scrypath_ops && mix verify.opsui`; optional focused `cd scrypath_ops && mix test test/scrypath_ops_web/live` | ✅ `scrypath_ops/mix.exs`, `scrypath_ops/test/scrypath_ops_web/live/**` [VERIFIED] |
| DUALVERIFY-01 | Static contrast AA green and AAA advisory attached | static | `cd examples/scrypath_ecommerce && make contrast` | ✅ `Makefile`, `contrast-checker.mjs` [VERIFIED] |
| DUALVERIFY-01 | Browser contrast AA green in light/dark/system-dark and AAA body report attached | e2e/a11y | `cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=... npm run test:e2e:admin-contrast -- --reporter=line` | ✅ `admin_contrast_matrix.spec.ts` [VERIFIED] |
| DUALVERIFY-01 | Surface depth proof holds in dark/system-dark and light guard | e2e/computed-style | `npm run test:e2e:admin-depth -- --reporter=line` | ✅ `admin_surface_depth.spec.ts`; 33 tests listed [VERIFIED] |
| DUALVERIFY-01 | Reduced-motion neutralization and patch-refire safety hold | e2e/motion | `npm run test:e2e:path-motion -- --reporter=line` | ✅ `admin_path_motion.spec.ts`; 7 tests listed [VERIFIED] |
| DUALVERIFY-01 | Shell chrome focus/theme/palette/flash proof holds | e2e/browser | `npm run test:e2e:admin-shell -- --reporter=line` | ✅ `admin_shell_chrome.spec.ts`; 33 tests listed [VERIFIED] |
| DUALVERIFY-01 | Historical 40-shot matrix recaptured | e2e/screenshot | `ADMIN_SCREENSHOT_DIR=... npm run test:e2e:admin-matrix -- --reporter=line` | ✅ `admin_screenshot_matrix.spec.ts`; 3 scenario tests / 40 PNG contract [VERIFIED] |
| DUALVERIFY-01 | Mounted ecommerce admin smoke green | e2e/smoke | `npm run test:e2e -- e2e/operator.spec.ts --reporter=line` | ✅ `operator.spec.ts`; 2 tests listed [VERIFIED] |
| DUALVERIFY-01 | Before/after, milestone audit, UAT complete | manual/report | `rg -n "DUALVERIFY-01|PASS|FAIL|follow-up" .planning/phases/136-*/136-*.md` | ❌ Wave 0 creates reports [VERIFIED] |

### Sampling Rate

- **Per task commit:** Run the narrow gate for the artifact being created; at minimum `mix verify.opsui` for source changes and relevant Playwright spec for browser evidence. [VERIFIED: 136-CONTEXT.md]
- **Per wave merge:** Run all required Elixir and browser gates that have been affected by the wave. [VERIFIED: 136-CONTEXT.md]
- **Phase gate:** Full suite green plus reports/manifests/UAT complete before `$gsd-verify-work`. [VERIFIED: .planning/REQUIREMENTS.md]

### Wave 0 Gaps

- [ ] `136-DUALVERIFY-REPORT.md` — command transcript summary, gate results, environment, AA/AAA, reduced-motion, smoke, artifact locations. [VERIFIED: 136-CONTEXT.md]
- [ ] `136-ARTIFACT-MANIFEST.json` — machine-readable generated artifact index with counts/checksums/provenance. [VERIFIED: 136-CONTEXT.md]
- [ ] `136-BEFORE-AFTER.md` — claim-based dark-weighted v1.33→v1.34 gallery. [VERIFIED: 136-CONTEXT.md]
- [ ] `136-MILESTONE-AUDIT.md` — requirement-by-requirement v1.34 audit across phases 128-136. [VERIFIED: 136-CONTEXT.md]
- [ ] `136-UAT.md` — bounded human UAT checklist and sign-off. [VERIFIED: 136-CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no new auth in this phase | Do not change existing ScrypathOps auth/on_mount/security tests unless a must-fix defect is found. [VERIFIED: phase scope + test tree] |
| V3 Session Management | limited | Theme selection uses browser localStorage/root attributes; verify no proof depends on a stale theme key for system-dark. [VERIFIED: theme-grid.ts] |
| V4 Access Control | limited | Mounted admin smoke must use existing routes and seed APIs only; no new privileged workflow. [VERIFIED: operator.spec.ts + phase scope] |
| V5 Input Validation | yes | Seed scenario names, report paths, and manifest paths should be fixed/known values; avoid interpolating untrusted input into shell commands. [VERIFIED: e2e helpers + Makefile] |
| V6 Cryptography | no new crypto | Use standard checksum tools/APIs for manifest digests; do not implement crypto. [ASSUMED] |

### Known Threat Patterns for Elixir/Phoenix + Playwright Closeout

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Stale-server proof misrepresents current source | Spoofing / Repudiation | Record boot command, port, source commit, asset build, seed method, and rerun after fixes. [VERIFIED: 136-CONTEXT.md] |
| Generated artifact tampering or mismatch | Tampering / Repudiation | Manifest expected/actual counts, per-file checksums, and committed/generated status. [VERIFIED: 136-CONTEXT.md] |
| Disabled contrast rule hides a regression | Tampering | Grep for `exclude(`, `disableRules`, or color-contrast suppression and record result. [VERIFIED: 132-CONTRAST-REPORT.md precedent] |
| Focus trap/regression in modal surfaces | Denial of Service / Accessibility | Use existing shell proof for bounded focus and focus return plus human UAT spot checks. [VERIFIED: admin_shell_chrome.spec.ts] |
| Accidental staging of generated artifacts or unrelated user changes | Tampering | Stage only Phase 136 docs; inspect `git status --short` before commit. [VERIFIED: current git status + 136-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/136-milestone-verification-uat-s-g/136-CONTEXT.md` - locked decisions, artifact contract, UAT thresholds. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md` - DUALVERIFY-01 definition. [VERIFIED: codebase grep]
- `.planning/ROADMAP.md` - Phase 136 goal and success criteria. [VERIFIED: codebase grep]
- `.planning/STATE.md` - v1.34 accumulated evidence and stale-server lessons. [VERIFIED: codebase grep]
- `CONTRIBUTING.md` - contributor and CI verification commands. [VERIFIED: codebase grep]
- `lib/mix/tasks/verify.opsui.ex`, `scrypath_ops/mix.exs`, `examples/scrypath_ecommerce/Makefile`, `examples/scrypath_ecommerce/package.json`, `examples/scrypath_ecommerce/playwright.config.ts`. [VERIFIED: codebase grep]
- `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts`, `admin_surface_depth.spec.ts`, `admin_path_motion.spec.ts`, `admin_shell_chrome.spec.ts`, `admin_screenshot_matrix.spec.ts`, `operator.spec.ts`, `helpers/theme-grid.ts`. [VERIFIED: codebase grep]
- `.planning/phases/132-a11y-contrast-remediation-both-themes-hard-gate-g/132-CONTRAST-REPORT.md`, `.planning/phases/135-shell-chrome-polish-dual-theme-s/135-SHELL-CHROME-REPORT.md`, `.planning/milestones/v1.33-MILESTONE-AUDIT.md`. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- Playwright emulation, screenshots/snapshots, trace, and accessibility docs: `https://playwright.dev/docs/emulation`, `https://playwright.dev/docs/screenshots`, `https://playwright.dev/docs/test-snapshots`, `https://playwright.dev/docs/trace-viewer`, `https://playwright.dev/docs/accessibility-testing`. [CITED: playwright.dev]
- Phoenix LiveView docs: `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html`, `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html`. [CITED: hexdocs.pm]
- W3C WCAG 2.2 understanding docs: contrast minimum, contrast enhanced, non-text contrast, focus appearance, animation from interactions. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html]

### Tertiary (LOW confidence)

- `shasum -a 256` as the exact manifest checksum command is an implementation recommendation; Node `crypto` is an acceptable substitute. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions verified from lockfiles, `npm ls`, local runtime probes, and registry metadata. [VERIFIED: shell probes]
- Architecture: HIGH - phase context and existing specs fully define responsibilities. [VERIFIED: codebase grep]
- Pitfalls: HIGH - each pitfall is based on prior phase artifacts or current workspace state, except checksum command preference. [VERIFIED: codebase grep]

**Research date:** 2026-06-28
**Valid until:** 2026-07-05 for npm/browser package currency; 2026-07-28 for local architecture and phase artifact constraints. [ASSUMED]
