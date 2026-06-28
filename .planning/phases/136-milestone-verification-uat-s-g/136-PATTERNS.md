# Phase 136: Milestone verification & UAT - Pattern Map

**Mapped:** 2026-06-28
**Files analyzed:** 6 (5 required closeout artifacts + 1 discretionary contrast report)
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/136-milestone-verification-uat-s-g/136-DUALVERIFY-REPORT.md` | report | batch + file-I/O | `.planning/phases/135-shell-chrome-polish-dual-theme-s/135-SHELL-CHROME-REPORT.md` | exact |
| `.planning/phases/136-milestone-verification-uat-s-g/136-ARTIFACT-MANIFEST.json` | manifest/config | batch + transform + file-I/O | `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` + `examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts` | partial |
| `.planning/phases/136-milestone-verification-uat-s-g/136-BEFORE-AFTER.md` | gallery report | file-I/O + transform | `.planning/milestones/v1.33-phases/127-shell-coherence-and-verification/v1.33-BEFORE-AFTER.md` | exact |
| `.planning/phases/136-milestone-verification-uat-s-g/136-MILESTONE-AUDIT.md` | audit report | batch + transform | `.planning/milestones/v1.33-MILESTONE-AUDIT.md` | exact |
| `.planning/phases/136-milestone-verification-uat-s-g/136-UAT.md` | UAT artifact | human event-driven + file-I/O | `.planning/phases/135-shell-chrome-polish-dual-theme-s/135-UAT.md` + `.planning/phases/133-dark-path-motion-expression-r-g/133-UAT.md` | role-match |
| `.planning/phases/136-milestone-verification-uat-s-g/136-CONTRAST-REPORT.md` (optional) | a11y report | batch + file-I/O | `.planning/phases/132-a11y-contrast-remediation-both-themes-hard-gate-g/132-CONTRAST-REPORT.md` | exact |

## Pattern Assignments

### `.planning/phases/136-milestone-verification-uat-s-g/136-DUALVERIFY-REPORT.md` (report, batch + file-I/O)

**Analog:** `.planning/phases/135-shell-chrome-polish-dual-theme-s/135-SHELL-CHROME-REPORT.md`

**Header and scope pattern** (lines 1-10):

```markdown
# Phase 135 Shell Chrome Report

**Requirement:** SHELL-DARK-01
**Plan:** 135-04
**Evidence date:** 2026-06-26

SHELL-DARK-01 is verified for the shared ScrypathOps shell chrome: header/nav, command
palette, shortcut sheet, theme toggle, flash, the live inline brand mark, and the `.ops-shell`
violet wash. The proof is focused on Phase 135 scope and does not replace Phase 136's full
milestone verification, screenshot gallery, audit, or human UAT.
```

Copy this shape, but change the scope sentence to DUALVERIFY-01 and explicitly state that Phase 136 closes the v1.34 milestone proof.

**Automated gate table pattern** (lines 12-22):

```markdown
## Automated Gate Results

| Gate | Command | Result |
| --- | --- | --- |
| Ops UI focused/static gate | `cd scrypath_ops && mix verify.opsui` | PASS: 2 doctests, 146 tests, 0 failures |
| Ops UI precommit gate | `cd scrypath_ops && mix precommit` | PASS: 2 doctests, 146 tests, 0 failures |
| Fast contrast gate | `cd examples/scrypath_ecommerce && make contrast` | PASS: AA failures 0, AAA advisory 19 |
| Focused shell browser proof | `cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run test:e2e:admin-shell -- --reporter=line` | PASS: 30/30 |
| Browser contrast matrix | `cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run test:e2e:admin-contrast -- --reporter=line` | PASS: 3/3 |

The browser gates reused the already-running source ecommerce stack at `http://127.0.0.1:4002`.
```

For Phase 136, include root `mix verify.opsui`, app `mix verify.opsui`, app `mix precommit` if source changed, `make contrast`, admin contrast/depth/path-motion/shell/matrix specs, and operator smoke.

**Theme/system-dark report language** (lines 38-43):

```markdown
## Theme-Mode Coverage

The shell proof runs the full shell suite across explicit light, explicit dark, and system dark,
and across mobile 390px and desktop 1440px viewports. System dark uses Playwright `colorScheme:
"dark"` without forcing `localStorage["phx:theme"]`, so it exercises the separate system-dark
CSS path rather than only `[data-theme="dark"]`.
```

Phase 136 must preserve this explicit "no forced phx:theme" language.

**Artifact hygiene pattern** (lines 121-131):

```markdown
## Generated Artifact Hygiene

Generated proof artifacts stayed out of git staging:

- `.tmp/` remains untracked.
- `examples/scrypath_ecommerce/test-results/` remains ignored/untracked from git status.
- `scrypath_ops/priv/static/**` remains untracked.

`mix precommit` produced formatter-only diffs in three unrelated LiveView files during the gate run.
Those files were clean before the command, were not part of Plan 135-04, and were restored by explicit
path after inspection so the evidence commit stays scoped to this report.
```

For Phase 136, replace the formatter note with any actual defect/fix/rerun notes. If no product source changed, say that directly.

**Decision and multi-source audit pattern** (lines 142-167 and 168-199):

```markdown
## Decision Coverage

| Decision | Coverage |
| --- | --- |
| D-01 | Dark-first and shell-only boundary held; no D-03 light exception was recorded. |
| D-02 | No broad light-theme shell redesign was opened. |

## Multi-Source Audit

| SOURCE | ID | Feature/Requirement | Status | Evidence |
| --- | --- | --- | --- | --- |
| GOAL | - | Header/nav, command palette, theme toggle, flash, and `.ops-shell` wash are brand-expressive and AA-clean across all 6 screens | COVERED | Browser shell 30/30, contrast matrix 3/3, `mix verify.opsui` green |
| REQ | SHELL-DARK-01 | Shell chrome is brand-expressive and AA-clean in both themes; weak header-nav dark contrast fixed; palette/flash adopt dark ambient-shadow-plus-border recipe | COVERED | `make contrast` AA failures 0; shell browser proof explicit light, explicit dark, system dark |
```

Use this for D-01 through D-24 and DUALVERIFY-01. Keep status values concrete: `COVERED`, `GAP`, `FOLLOW-UP`, or `BLOCKER`.

**Contrast transcript pattern to embed or link** from `.planning/phases/132-a11y-contrast-remediation-both-themes-hard-gate-g/132-CONTRAST-REPORT.md` (lines 47-108):

````markdown
## Browser AA Matrix

Environment preparation:

```console
$ cd examples/scrypath_ecommerce && MIX_ENV=test mix e2e.prepare
Prepared E2E search index settings for ecommerce__product.
Prepared E2E search index settings for ecommerce__variant.
```

Browser contrast matrix:

```console
$ cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 CONTRAST_REPORT_DIR=test-results/contrast/phase132 npm run test:e2e:admin-contrast
```

Generated browser reports:

| Scenario | Report | AA failures | AAA advisory |
| --- | --- | ---: | ---: |
| incident | `test-results/contrast/phase132/contrast-report.axe.incident.json` | 0 | 0 |
````

Phase 136 can keep contrast as a subsection in the dual-verify report unless the volume justifies the optional `136-CONTRAST-REPORT.md`.

---

### `.planning/phases/136-milestone-verification-uat-s-g/136-ARTIFACT-MANIFEST.json` (manifest/config, batch + transform + file-I/O)

**Analog:** `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts`

There is no committed Phase artifact manifest JSON with the same role. Use the generated contrast report schema and screenshot matrix naming/count conventions as the closest implementation pattern.

**Generated JSON schema pattern** (lines 209-220):

```typescript
const report = {
  schema: "scrypath.contrast.v1",
  producer: "axe",
  generated: new Date().toISOString(),
  scenario,
  summary: {
    aa_fail: aaFails.length,
    aaa_advisory: aaaAdvisory.length,
    total: findings.length
  },
  findings
};
```

For Phase 136, use the same explicit provenance style. Recommended top-level fields:

```json
{
  "schema": "scrypath.phase136.artifacts.v1",
  "phase": "136",
  "requirement": "DUALVERIFY-01",
  "generated": "2026-06-28T00:00:00Z",
  "source_commit": "HEAD",
  "base_url": "http://127.0.0.1:4002",
  "asset_build_command": "cd scrypath_ops && mix assets.build",
  "server_boot": {
    "method": "source-backed ecommerce server",
    "port": 4002,
    "seed_method": "/dev/e2e/seed"
  },
  "artifacts": []
}
```

**Write-before-gate and namespaced output pattern** (lines 222-230 and 271-274):

```typescript
await mkdir(contrastReportDir, { recursive: true });
const reportBase = `contrast-report.axe.${scenario}`;
await writeFile(
  path.join(contrastReportDir, `${reportBase}.json`),
  JSON.stringify(report, null, 2)
);

await writeFile(
  path.join(contrastReportDir, `${reportBase}.md`),
  md
);
```

For Phase 136, manifest entries should record generated artifact paths and checksums after commands run, not before. Use namespaced paths like `test-results/admin-screenshots/phase136`.

**Screenshot artifact naming/count pattern** from `admin_screenshot_matrix.spec.ts` (lines 11-13, 31, 53-72):

```typescript
 * Output:
 *   - ADMIN_SCREENSHOT_DIR (default test-results/admin-screenshots/)
 *   - files named NN-screen--theme--viewport--state.png

const screenshotDir = process.env.ADMIN_SCREENSHOT_DIR || "test-results/admin-screenshots";

async function shoot(
  browser: Browser,
  capture: ScreenCapture,
  theme: Theme,
  viewport: ViewportName
): Promise<void> {
  const context = await browser.newContext({ viewport: VIEWPORTS[viewport] });
  await context.addInitScript(
    ([key, value]) => {
      window.localStorage.setItem(key, value);
    },
    ["phx:theme", theme]
  );

  const page = await context.newPage();
  try {
    await capture.prepare(page);
    await mkdir(screenshotDir, { recursive: true });
    const name = `${capture.index}-${capture.screen}--${theme}--${viewport}--${capture.state}`;
    await page.screenshot({ path: path.join(screenshotDir, `${name}.png`), fullPage: true });
  } finally {
    await context.close();
  }
}
```

**Historical 40-shot source pattern** (lines 160-218):

```typescript
describeScenario("incident", [
  { index: "00", screen: "control-room", state: "incident", prepare: gotoControlRoom },
  { index: "01", screen: "posture", state: "incident", prepare: gotoPosture },
  { index: "03", screen: "sync-drift", state: "drift", prepare: gotoSyncDrift }
]);

describeScenario("all_green", [
  { index: "04", screen: "control-room", state: "all-green", prepare: gotoControlRoom },
  { index: "05", screen: "posture", state: "all-green", prepare: gotoPosture },
  { index: "06", screen: "search", state: "results", prepare: async (page) => { /* ... */ } }
]);

describeScenario("empty", [
  { index: "07", screen: "failed-sync", state: "empty", prepare: gotoFailedSync },
  { index: "08", screen: "search", state: "zero-results", prepare: async (page) => { /* ... */ } },
  { index: "09", screen: "playbooks", state: "empty-workspace", prepare: gotoPlaybooks }
]);
```

Manifest must explicitly record `expected_count: 40` and `actual_count` for this historical gallery. The broader 13-state `SCENARIO_CAPTURES` helper is a proof substrate, not a silent replacement.

**Artifact hygiene source** from `132-CONTRAST-REPORT.md` (lines 198-205):

```markdown
Generated evidence and build outputs are evidence artifacts only unless already tracked. Do not stage or commit `test-results/`, `.tmp/`, or untracked `scrypath_ops/priv/static/**` outputs for this plan.

Task 2 evidence artifacts kept out of git:

- `examples/scrypath_ecommerce/test-results/contrast/phase132/**`
- `examples/scrypath_ecommerce/.tmp/pixel-diff-fresh/**`
- `examples/scrypath_ecommerce/.tmp/admin-screenshots/**`
- untracked `scrypath_ops/priv/static/**`
```

Manifest should set `committed: false` for generated browser artifacts and `committed: true` only for the Phase 136 Markdown/JSON closeout artifacts.

---

### `.planning/phases/136-milestone-verification-uat-s-g/136-BEFORE-AFTER.md` (gallery report, file-I/O + transform)

**Analog:** `.planning/milestones/v1.33-phases/127-shell-coherence-and-verification/v1.33-BEFORE-AFTER.md`

**Gallery preface and naming pattern** (lines 1-6):

```markdown
# v1.32 -> v1.33 - Admin UI before/after

The v1.33 **after** captures (40-shot matrix: 6 screens x light/dark x mobile 390/desktop 1440 x
scenarios) live in `/Users/jon/projects/scrypath/.tmp/admin-screenshots/`, names
`NN-screen--theme--viewport--state.png`. The v1.32 **before** is regenerable from `main`
(predates this milestone) - see the audit's tech-debt note for the recapture recipe.
```

For Phase 136, replace absolute local paths with Phase 136 manifest paths where possible. If v1.33 before shots are regenerated from a worktree, record commit/branch and boot method.

**Claim-based per-screen sections** (lines 8-44):

```markdown
Per-screen deltas (v1.32 -> v1.33):

## Control Room (`00-control-room`)
- Emoji intent icons -> **violet monoline Heroicons**.
- CTAs: "Start triage / Open sync drift / Open search" -> **"Start recovery / Pre-flight sync drift / Explore search"**.

## Nav / shell (every screen)
- Sidebar groups **"Triage / Probes" -> "Recover / Explore"** (task-first vocabulary); breadcrumbs follow.
- Trust verdict reads **identically** on Control Room <-> Posture ("Can I trust search right now?").

## Search / Federation (`05/06-search`)
- **Loading skeleton + state-aware badge** ("Run a probe / Running... / Last run loaded") on bounded runs.
- Result rows lead with the hit's **human field**, not "Hit 1/2".
```

Phase 136 should be claim-based, not a raw dump. Required claims from context: route orientation, posture trust, failed-sync recovery, drift clarity, search exploration, playbook workspace clarity, shell restraint, focus, and theme parity.

---

### `.planning/phases/136-milestone-verification-uat-s-g/136-MILESTONE-AUDIT.md` (audit report, batch + transform)

**Analog:** `.planning/milestones/v1.33-MILESTONE-AUDIT.md`

**Header/verdict pattern** (lines 1-8):

```markdown
# Milestone Audit: v1.33 Admin UI Insane Polish

**Audited:** 2026-06-03
**Phases:** 119-127 (9 phases)
**Branch:** `gsd/v1.33-admin-ui-insane-polish` (not pushed/merged)
**Verdict:** **PASSED (tech_debt)** - all 12 requirements implemented and statically verified; live
admin Playwright smoke + full v1.32->v1.33 recapture gallery + human UAT deferred to owner sign-off.
```

Phase 136 should avoid `PASSED` until all required gates, gallery, manifest, audit, and UAT are complete. Use `PASSED`, `PASSED (follow_ups)`, or `FAILED/BLOCKED` with explicit blockers.

**Intent vs delivery pattern** (lines 9-15):

```markdown
## Intent vs delivery

The milestone goal: a deliberate, owner-initiated next-level UI/UX + design-system iteration of the
`scrypath_ops` admin console, building on v1.32 - task-first IA, compounding design-system tightening,
mobile-first responsiveness, restrained-but-distinctive brand motion, focusing depth on under-iterated
surfaces. Delivered as scoped; no runtime/product breadth added (scope guard intact).
```

For v1.34, audit the "dark signature + light parity + AA hard gate + system-dark proof" intent and state whether runtime/library scope stayed closed.

**Requirement coverage table pattern** (lines 26-42):

```markdown
## Requirement coverage - 12/12

| Req | Phase | Status | Evidence |
|-----|-------|--------|----------|
| HARNESS-01 | 119 | Complete | 40-shot theme x viewport x state matrix spec; deterministic baseline |
| SHELL-01 | 127 | Complete | verdict unification (P5), mobile header nav (P6), chrome consistency |
| VERIFY-01 | 127 | Substantial | static gates green; live smoke + gallery recapture + UAT pending owner |
```

For Phase 136, cover v1.34 phases 128-136 and DUALVERIFY-01. Include evidence paths, not only prose.

**Gates/deferred/next pattern** (lines 43-62):

```markdown
## Gates (this session)
- `mix verify.opsui`: nav contract OK, 2 doctests, 129 tests, 0 failures.
- `examples/scrypath_ecommerce` `mix compile --warnings-as-errors`: clean.

## Tech debt / deferred
1. **Live mounted-admin Playwright smoke** not re-run this session...

## Next
Owner UAT (boot + click-through). On sign-off: re-run the live admin smoke...
```

For Phase 136, "deferred" must only contain accepted follow-ups from context D-19, not must-fix blockers.

---

### `.planning/phases/136-milestone-verification-uat-s-g/136-UAT.md` (UAT artifact, human event-driven + file-I/O)

**Analogs:** `.planning/phases/135-shell-chrome-polish-dual-theme-s/135-UAT.md`, `.planning/phases/133-dark-path-motion-expression-r-g/133-UAT.md`, `.planning/milestones/v1.16-phases/65-playbook-run-lifecycle-opsui/65-HUMAN-UAT.md`

**Pending UAT frontmatter/current-test pattern** from `135-UAT.md` (lines 1-19):

```markdown
---
status: testing
phase: 135-shell-chrome-polish-dual-theme-s
source:
  - 135-VERIFICATION.md
started: 2026-06-26T12:28:36Z
updated: 2026-06-26T12:28:36Z
---

## Current Test

number: 1
name: Night shell wash visual read
expected: |
  Inspect Control Room, Posture, Failed Sync, Sync/Drift, Search, and Playbooks in
  Night/dark mode at mobile and desktop widths.
awaiting: user response
```

Phase 136 should use `status: testing` until the human reviewer completes sign-off. Source should reference `136-DUALVERIFY-REPORT.md` and `136-BEFORE-AFTER.md`.

**Completed evidence pattern** from `133-UAT.md` (lines 13-27 and 41-52):

```markdown
## Tests

### 1. Playwright path-motion proof
expected: |
  Boot a seeded ops server, then run the focused path-motion spec.
  Result: 7 passed. Reduced-motion <= ~0.02ms + active state visible; patch-refire count 0;
  evidence code blocks shimmer-off (count 0).
result: pass
source: automated
evidence: |
  `make verify-path-motion` (examples/scrypath_ecommerce) boots the containerized test stack
  and runs admin_path_motion.spec.ts -> 7/7 green on 2026-06-25.

## Summary

total: 2
passed: 2
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none - both items automated; 0 human verification required]
```

Phase 136 should keep automated evidence in `source: automated` entries and human observations in `source: human`. Do not mark human UAT complete from automation-only evidence.

**Human UAT compact pattern** from `65-HUMAN-UAT.md` (lines 13-34):

```markdown
## Tests

### 1. Run lifecycle clarity
expected: Catalog "Run now" and preview "Run saved playbook" each show an obvious running state, then a persistent success or failure panel with no confusing intermediate UI.
result: covered by `ScrypathOpsWeb.PlaybookLiveTest` assertions for visible running state and terminal success in both entry paths.

## Summary

total: 2
passed: 2
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

None. Human-only checks were shifted left into automated LiveView integration coverage and Phase 65 verification now passes.
```

For Phase 136, use job-based checks across six surfaces in dark first, then light parity, then system-dark evidence. Include fields for result, evidence, and accepted follow-up.

---

### `.planning/phases/136-milestone-verification-uat-s-g/136-CONTRAST-REPORT.md` (optional a11y report, batch + file-I/O)

**Analog:** `.planning/phases/132-a11y-contrast-remediation-both-themes-hard-gate-g/132-CONTRAST-REPORT.md`

Create this only if the contrast subsection makes `136-DUALVERIFY-REPORT.md` too large. Otherwise fold these sections into the main report.

**Asset build before proof pattern** (lines 5-31):

````markdown
## Static Token Gate

Command order proof:

```console
$ cd scrypath_ops && mix assets.build
...
```

The asset build exited 0 before any static or browser contrast proof, so `scrypath_ops/priv/static/assets/css/app.css` reflects `scrypath_ops/assets/css/app.css`.

Fast token checker:

```console
$ cd examples/scrypath_ecommerce && CONTRAST_REPORT_DIR=test-results/contrast/phase132-token node contrast-checker.mjs

Contrast check: PASS
  AA failures:  0
  AAA advisory: 19
  Report: test-results/contrast/phase132-token/contrast-report.token.json
```
````

**AA/AAA hard-vs-advisory pattern** (lines 91-124):

```markdown
Theme matrix AA status:

AA failures: 0 for light, dark, and system-dark.

| Theme mode | AA failures | Notes |
| --- | ---: | --- |
| light | 0 | Explicit light matrix covered by the passing Playwright run. |
| dark | 0 | Explicit dark matrix covered by the passing Playwright run. |
| system-dark | 0 | System-dark matrix covered by the passing Playwright run and its runtime invariants. |

## AAA Body Advisory

Static token advisory status is report-only:

- Token checker `AAA advisory: 19`
- AAA findings did not affect the static gate exit status.
```

Phase 136 should keep AA failures as blockers and AAA body findings as advisory unless they reveal a new trust/readability regression.

## Shared Patterns

### Root and App Mix Gates

**Source:** `lib/mix/tasks/verify.opsui.ex` and `scrypath_ops/mix.exs`
**Apply to:** `136-DUALVERIFY-REPORT.md`, `136-MILESTONE-AUDIT.md`

Root task docs and command execution (lines 6-21, 35-48):

```elixir
Runs the `scrypath_ops` application tests the same way the **`scrypath-ops`** GitHub Actions job does.

The task runs **`cd scrypath_ops`**, then **`mix deps.get`**, then **`mix test`** with **`CI=true`**.

Mix.shell().info("==> verify.opsui: cd scrypath_ops && mix deps.get && mix test")

script = "export CI=true; printf 'n\\n' | mix deps.get && mix test"

{out, status} =
  System.cmd("bash", ["-lc", script], cd: ops_dir, stderr_to_stdout: true)
```

App aliases (lines 28-31, 75-96):

```elixir
preferred_envs: [precommit: :test, "opsui.test_a11y": :test, "verify.opsui": :test]

defp aliases do
  [
    test: [
      "scrypath_ops.check_nav_contract",
      "ecto.create --quiet",
      "ecto.migrate --quiet",
      "test"
    ],
    "opsui.test_a11y": &opsui_test_a11y/1,
    "verify.opsui": ["test", "opsui.test_a11y"],
    "assets.build": ["compile", "tailwind scrypath_ops", "esbuild scrypath_ops"],
    precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
  ]
end
```

### Source-Backed Browser Proof

**Source:** `examples/scrypath_ecommerce/Makefile`, `admin_path_motion.spec.ts`
**Apply to:** all browser-gate report sections and manifest provenance

Makefile lane variables and browser targets (lines 16-30, 138-155):

```make
WEB_PORT   ?= 4002
PG_PORT    ?= 5432
MEILI_PORT ?= 7700
BASE_URL           := http://127.0.0.1:$(WEB_PORT)
ADMIN_URL          := $(BASE_URL)/admin/search
ADMIN_SCREENSHOT_DIR ?= test-results/admin-screenshots
CONTRAST_REPORT_DIR  ?= test-results/contrast

screenshots-matrix:
	@ADMIN_SCREENSHOT_DIR=$${ADMIN_SCREENSHOT_DIR:-$(ADMIN_SCREENSHOT_DIR)} \
	  PLAYWRIGHT_BASE_URL=http://127.0.0.1:$(WEB_PORT) \
	  npm run test:e2e:admin-matrix

contrast-matrix:
	@CONTRAST_REPORT_DIR=$${CONTRAST_REPORT_DIR:-$(CONTRAST_REPORT_DIR)} \
	  PLAYWRIGHT_BASE_URL=http://127.0.0.1:$(WEB_PORT) \
	  npm run test:e2e:admin-contrast
```

Stale-server warning to carry into report (from `admin_path_motion.spec.ts` lines 29-36):

```typescript
 *   The spec drives a booted, seeded ops server at PLAYWRIGHT_BASE_URL (default
 *   http://127.0.0.1:4002). Boot it against CURRENT source via the compose dev lane
 *   (`make dev` / `compose.yaml + compose.dev.yaml`) - the base `compose.yaml` alone runs
 *   a STALE baked image, so a source-level `.ops-path-*` change would not be exercised
```

### Playwright Script Names

**Source:** `examples/scrypath_ecommerce/package.json`
**Apply to:** `136-DUALVERIFY-REPORT.md`, manifest command provenance

Scripts (lines 5-15):

```json
"scripts": {
  "test:e2e:headed": "playwright test --headed",
  "test:e2e": "playwright test",
  "test:e2e:list": "playwright test --list",
  "test:e2e:admin-shell": "playwright test e2e/admin_shell_chrome.spec.ts",
  "test:e2e:path-motion": "playwright test e2e/admin_path_motion.spec.ts",
  "test:e2e:admin-depth": "playwright test e2e/admin_surface_depth.spec.ts",
  "test:e2e:admin-screens": "playwright test e2e/admin_screenshots.spec.ts",
  "test:e2e:admin-matrix": "playwright test e2e/admin_screenshot_matrix.spec.ts",
  "test:e2e:admin-contrast": "playwright test e2e/admin_contrast_matrix.spec.ts"
}
```

### Theme Grid and System-Dark

**Source:** `examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts`, `admin_contrast_matrix.spec.ts`
**Apply to:** all browser proof reports, `136-BEFORE-AFTER.md`, `136-UAT.md`

Theme helper pattern (lines 5-17, 35-42):

```typescript
export type ThemeMode =
  | { kind: "explicit"; theme: "light" | "dark" }
  | { kind: "system"; colorScheme: "dark" };

export const THEME_MODES: ThemeMode[] = [
  { kind: "explicit", theme: "light" },
  { kind: "explicit", theme: "dark" },
  { kind: "system", colorScheme: "dark" }
];

export async function assertSystemDarkInvariants(page: Page): Promise<void> {
  await expect(page.locator("html")).not.toHaveAttribute("data-theme");
  const mediaMatches = await page.evaluate(
    () => window.matchMedia("(prefers-color-scheme: dark)").matches
  );
  expect(mediaMatches).toBe(true);
  await expect(page.locator("html")).toHaveAttribute("data-theme-effective", "dark");
}
```

Explicit vs system setup (from `admin_contrast_matrix.spec.ts` lines 286-304):

```typescript
const ctxOptions =
  mode.kind === "system"
    ? { viewport: VIEWPORTS[viewport], colorScheme: mode.colorScheme as "dark" }
    : { viewport: VIEWPORTS[viewport] };

const context = await browser.newContext(ctxOptions);

if (mode.kind === "explicit") {
  await context.addInitScript(
    ([key, value]: [string, string]) => {
      window.localStorage.setItem(key, value);
    },
    ["phx:theme", mode.theme]
  );
}
// D-07: system-dark row deliberately OMITS the phx:theme write
```

### Seeded Operator Scenarios

**Source:** `examples/scrypath_ecommerce/e2e/helpers/e2e.ts`
**Apply to:** browser proof command notes, manifest seed provenance, UAT checklist

Seed scenario vocabulary (lines 35-49, 103-120):

```typescript
/**
 * Named operational scenarios understood by /dev/e2e/seed (SEED-01). Each drives the
 * operator UI into a deterministic posture for the screenshot/audit harness:
 *   all_green - catalog synced, no failed sync, no drift (verdict trusts search)
 *   degraded  - catalog synced, drift only (verdict degraded)
 *   incident  - catalog synced, all failed-sync reason classes + drift (can't-fully-trust)
 *   empty     - no synced products / signals (every empty state)
 * `e2e_search_catalog` remains the original deterministic search/tenant-guard lane.
 */
export type SeedScenario =
  | "all_green"
  | "degraded"
  | "incident"
  | "empty"
  | "e2e_search_catalog";

export async function seedScenario(
  request: APIRequestContext,
  scenario: SeedScenario = "e2e_search_catalog"
): Promise<SeedResult> {
  const result = await requestJson<SeedResult>(request, "/dev/e2e/seed", {
    method: "POST",
    data: { scenario }
  });
```

### Mounted Ecommerce Smoke

**Source:** `examples/scrypath_ecommerce/e2e/operator.spec.ts`
**Apply to:** `136-DUALVERIFY-REPORT.md`, `136-MILESTONE-AUDIT.md`

Failed sync triage smoke (lines 11-58):

```typescript
test("operator can triage intentionally failed sync work", async ({ page, request }) => {
  const seed = await seedScenario(request, "e2e_search_catalog");

  await injectFailedSync(request, {
    tenantId: seed.tenant_id,
    scenarioKey: "failed-sync-operator-triage"
  });

  const state = await operatorState(request, {
    tenantId: seed.tenant_id,
    timeoutMs: 15_000,
    minFailedSyncCount: 1
  });

  expect(state.failed_count).toBeGreaterThanOrEqual(1);
  expect(state.retryable).toBeTruthy();

  await page.goto("/admin/search/failed-sync");
  await expect(page.getByRole("heading", { name: "Failed sync jobs" })).toBeVisible();
});
```

Sync/drift swap smoke (lines 60-89):

```typescript
test("operator can initiate zero-downtime swap from sync drift UI", async ({ page, request }) => {
  const seed = await seedScenario(request, "e2e_search_catalog");

  await page.goto("/admin/search/posture");
  await waitForLiveConnected(page);
  await expect(page.locator("[data-ops-refresh]")).toBeVisible();
  await page.locator("[data-ops-refresh]").click();

  await page.goto("/admin/search/sync-drift");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Sync and drift" })).toBeVisible();
  await page.getByRole("button", { name: "Load / refresh contract drift" }).click();
  await expect(page.getByText("Contract dimensions")).toBeVisible();
  await page.getByRole("button", { name: "Swap live index" }).click();
  await expect(page.getByText("Swap live index completed")).toBeVisible();

  const outcome = await waitForSwapOutcome(request, {
    tenantId: seed.tenant_id,
    timeoutMs: 30_000
  });

  expect(outcome.swap_terminal_success).toBeTruthy();
  expect(outcome.active_index_visible).toBeTruthy();
});
```

### Reduced Motion and Focus Proof

**Source:** `admin_path_motion.spec.ts`, `admin_shell_chrome.spec.ts`
**Apply to:** `136-DUALVERIFY-REPORT.md`, `136-UAT.md`

Reduced-motion binding claim (from `admin_path_motion.spec.ts` lines 7-27):

```typescript
 *   1. Reduced-motion neutralization + functional integrity (D-09): under
 *      `prefers-reduced-motion: reduce`, each shipped anchor computes a
 *      transition/animation duration of ~0.01ms ... AND its
 *      active end state is still visually present
 *
 * Every flow is exercised in BOTH dark and light ... plus a system-dark context
 * ... The full 40-shot recapture, before/after gallery, and human milestone UAT
 * are deferred to Phase 136
```

Focus/modal proof (from `admin_shell_chrome.spec.ts` lines 157-180):

```typescript
async function expectAriaModalTruth(
  page: Page,
  selector: "#ops-cmdk" | "#ops-cheatsheet",
  opener: Locator
): Promise<void> {
  const dialog = page.locator(selector);
  const modal = await dialog.getAttribute("aria-modal");

  if (modal === "true") {
    await expect(dialog).toHaveAttribute("role", "dialog");
    expect(await activeElementInside(page, selector), `${selector} initial focus must be inside`).toBe(true);

    await page.keyboard.press("Tab");
    expect(await activeElementInside(page, selector), `${selector} Tab focus must stay bounded`).toBe(true);

    await page.keyboard.press("Escape");
    await expect(dialog).toBeHidden();
    await expect(opener, `${selector} close should restore focus to its opener`).toBeFocused();
  }
}
```

### Screenshot Matrix

**Source:** `admin_screenshot_matrix.spec.ts`
**Apply to:** `136-ARTIFACT-MANIFEST.json`, `136-BEFORE-AFTER.md`, `136-UAT.md`

Matrix loop (lines 78-106):

```typescript
function describeScenario(scenario: SeedScenario, captures: ScreenCapture[]): void {
  test(`admin screenshot matrix - ${scenario}`, async ({ browser, request }) => {
    test.setTimeout(180_000);

    const seed = await seedScenario(request, scenario);

    for (const capture of captures) {
      for (const theme of THEMES) {
        for (const viewport of VIEWPORT_NAMES) {
          await shoot(browser, capture, theme, viewport);
        }
      }
    }
  });
}
```

Phase 136 should report:

- historical gallery: 10 screen-state captures x 2 themes x 2 viewports = 40 PNGs
- broader proof substrate: `SCENARIO_CAPTURES` 13-state set for contrast/depth/shell where applicable
- generated artifact root and checksum source

## No Exact Same-Role Analog

| File | Role | Data Flow | Reason | Planner Instruction |
|------|------|-----------|--------|---------------------|
| `.planning/phases/136-milestone-verification-uat-s-g/136-ARTIFACT-MANIFEST.json` | manifest/config | batch + transform + file-I/O | No prior committed Phase artifact manifest JSON exists. Only `.release-please-manifest.json`, `.bg-shell/manifest.json`, and `scrypath_ops/priv/static/cache_manifest.json` were found, none close to Phase evidence. | Use the contrast report JSON schema pattern, screenshot matrix filename/count pattern, and report artifact-hygiene sections above. |

## Metadata

**Analog search scope:** `.planning/phases`, `.planning/milestones`, `examples/scrypath_ecommerce/e2e`, `examples/scrypath_ecommerce/Makefile`, `examples/scrypath_ecommerce/package.json`, `lib/mix/tasks/verify.opsui.ex`, `scrypath_ops/mix.exs`

**Files scanned:** 558 candidate Markdown/JSON/TypeScript/MJS/Makefile files under the analog search scope

**Pattern extraction date:** 2026-06-28

**Read-only boundary:** Product source was not modified. This pattern map writes only `.planning/phases/136-milestone-verification-uat-s-g/136-PATTERNS.md`.
