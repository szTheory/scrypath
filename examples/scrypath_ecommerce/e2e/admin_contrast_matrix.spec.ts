/**
 * Admin UI contrast matrix (CONTRAST-HARNESS-01).
 *
 * Runs a WCAG AA axe contrast gate across the cross-product of:
 *   ~13 screen-states × {light, dark, system-dark} × {mobile 390px, desktop 1440px}
 *
 * Seeding is grouped by scenario (same as the screenshot matrix) so each scenario is
 * seeded once, then every screen for that scenario is checked across all theme-modes ×
 * viewports.
 *
 * Theme modes (D-03/D-09 discriminated union):
 *   explicit-light  — addInitScript phx:theme="light"; no colorScheme override
 *   explicit-dark   — addInitScript phx:theme="dark";  no colorScheme override
 *   system-dark     — newContext({ colorScheme:"dark" }) with NO phx:theme write (D-07)
 *                     This exercises the @media (prefers-color-scheme: dark) CSS branch,
 *                     a genuinely different cascade from [data-theme=dark] (D-06).
 *
 * Gate behavior (D-04/D-05/D-21):
 *   - AA gate: axe withRules(['color-contrast']), gate on violations[] ONLY — never on
 *     incomplete[] (D-04). Both viewports hard-gate (D-05).
 *   - AAA advisory: second axe pass withRules(['color-contrast-enhanced']) scoped to
 *     BODY_SELECTORS; severity:"aaa-body-advisory"; NEVER affects exit code (D-20).
 *   - Report written BEFORE gate assertion (D-21) so failures are always readable.
 *
 * Output:
 *   - CONTRAST_REPORT_DIR (default test-results/contrast/)
 *   - contrast-report.{json,md} — scrypath.contrast.v1 schema (D-17/D-18)
 */
import { expect, test, type Browser, type Page } from "@playwright/test";
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";

import {
  drainSearchQueue,
  seedScenario,
  waitForLiveConnected,
  waitForSearchVisible,
  type SeedScenario
} from "./helpers/e2e";
import { AxeBuilder } from "@axe-core/playwright";

const contrastReportDir = process.env.CONTRAST_REPORT_DIR || "test-results/contrast";

// ── D-09: Discriminated union for theme modes ─────────────────────────────────

type ThemeMode =
  | { kind: "explicit"; theme: "light" | "dark" }
  | { kind: "system"; colorScheme: "dark" };

const THEME_MODES: ThemeMode[] = [
  { kind: "explicit", theme: "light" },
  { kind: "explicit", theme: "dark" },
  { kind: "system", colorScheme: "dark" }
];

// Flat slug for file naming and report schema `theme` field (D-18):
function themeSlug(mode: ThemeMode): string {
  return mode.kind === "system" ? `system-${mode.colorScheme}` : mode.theme;
}

type ViewportName = "mobile" | "desktop";

const VIEWPORTS: Record<ViewportName, { width: number; height: number }> = {
  mobile: { width: 390, height: 844 },
  desktop: { width: 1440, height: 900 }
};

const VIEWPORT_NAMES: ViewportName[] = ["mobile", "desktop"];

// A single capture target: which screen, what posture state label, and the per-page
// preparation (navigate + trigger + wait for the load-bearing content) before the axe pass.
type ScreenCapture = {
  index: string;
  screen: string;
  state: string;
  prepare: (page: Page) => Promise<void>;
};

// ── D-18: Finding schema ───────────────────────────────────────────────────────

type ContrastFinding = {
  id: string;
  producer: "axe";
  severity: "aa-fail" | "aaa-body-advisory";
  screen: string;
  theme: string;
  viewport: string;
  state: string;
  shot: string;
  element_role: string;
  selector: string;
  token_pair: string | null;
  fg: string | null;
  bg: string | null;
  actual_ratio: number | null;
  required_ratio: number;
  aaa_required: number;
  pass_aa: boolean;
  aaa_body_status: "advisory" | "n/a";
  axe_rule: string;
  impact: string | null;
  fix_class: string;
  scope: "systemic" | "local";
  evidence: string;
};

// ── D-20: AAA-body selectors allowlist ────────────────────────────────────────
// Covers body/long-form text per the brand book's AAA-body targets.

const BODY_SELECTORS = [
  "main p",
  "main li",
  "main dd",
  "main dt",
  ".ops-text-body",
  ".ops-preflight__hint",
  ".ops-handoff__hint",
  ".ops-intent-card__summary"
];

// ── D-08: System-dark runtime invariants ──────────────────────────────────────

async function assertSystemDarkInvariants(page: Page): Promise<void> {
  // 1. <html> must have NO data-theme (proves we're on the media-query path, not explicit)
  await expect(page.locator("html")).not.toHaveAttribute("data-theme");
  // 2. Playwright colorScheme emulation must be active (guards silent no-op)
  const mediaMatches = await page.evaluate(
    () => window.matchMedia("(prefers-color-scheme: dark)").matches
  );
  expect(mediaMatches).toBe(true);
  // 3. App's own OS-resolution logic must resolve to dark
  await expect(page.locator("html")).toHaveAttribute("data-theme-effective", "dark");
}

// ── Report accumulation helpers (D-17/D-18/D-19) ─────────────────────────────

let findingCounter = 0;

function appendFindings(
  findings: ContrastFinding[],
  ctx: {
    capture: ScreenCapture;
    mode: ThemeMode;
    viewport: ViewportName;
    aaResults: { violations: Array<{ id: string; impact: string | null; nodes: Array<{ target: string[]; any: Array<{ data?: { fgColor?: string; bgColor?: string; contrastRatio?: number } }> }> }>; incomplete: Array<{ id: string; impact: string | null; nodes: Array<{ target: string[] }> }> };
    aaaResults: { violations: Array<{ id: string; impact: string | null; nodes: Array<{ target: string[]; any: Array<{ data?: { fgColor?: string; bgColor?: string; contrastRatio?: number } }> }> }> };
  }
): void {
  const slug = themeSlug(ctx.mode);
  const shotBase = `${ctx.capture.index}-${ctx.capture.screen}--${slug}--${ctx.viewport}--${ctx.capture.state}`;

  // AA failures (D-04: gate on violations[] ONLY — never on incomplete[])
  for (const violation of ctx.aaResults.violations) {
    for (const node of violation.nodes) {
      findingCounter++;
      const nodeData = node.any?.[0]?.data ?? {};
      findings.push({
        id: `F-${String(findingCounter).padStart(4, "0")}`,
        producer: "axe",
        severity: "aa-fail",
        screen: ctx.capture.screen,
        theme: slug,
        viewport: ctx.viewport,
        state: ctx.capture.state,
        shot: shotBase,
        element_role: violation.id.includes("large") ? "large" : "text",
        selector: node.target.join(", "),
        token_pair: null,
        fg: nodeData.fgColor ?? null,
        bg: nodeData.bgColor ?? null,
        actual_ratio: nodeData.contrastRatio ?? null,
        required_ratio: 4.5,
        aaa_required: 7.0,
        pass_aa: false,
        aaa_body_status: "n/a",
        axe_rule: violation.id,
        impact: violation.impact,
        fix_class: "token",
        scope: "local", // will be upgraded to "systemic" in writeContrastReport (D-19)
        evidence: `axe:color-contrast violation on ${node.target.join(", ")}`
      });
    }
  }

  // AAA advisory (D-20: severity:"aaa-body-advisory", NEVER affects exit code)
  for (const violation of ctx.aaaResults.violations) {
    for (const node of violation.nodes) {
      findingCounter++;
      const nodeData = node.any?.[0]?.data ?? {};
      findings.push({
        id: `F-${String(findingCounter).padStart(4, "0")}`,
        producer: "axe",
        severity: "aaa-body-advisory",
        screen: ctx.capture.screen,
        theme: slug,
        viewport: ctx.viewport,
        state: ctx.capture.state,
        shot: shotBase,
        element_role: "text",
        selector: node.target.join(", "),
        token_pair: null,
        fg: nodeData.fgColor ?? null,
        bg: nodeData.bgColor ?? null,
        actual_ratio: nodeData.contrastRatio ?? null,
        required_ratio: 4.5,
        aaa_required: 7.0,
        pass_aa: true,
        aaa_body_status: "advisory",
        axe_rule: violation.id,
        impact: violation.impact,
        fix_class: "token",
        scope: "local",
        evidence: `axe:color-contrast-enhanced advisory on ${node.target.join(", ")}`
      });
    }
  }
}

// ── D-19: Promote systemic findings (selector fails on ≥3 distinct screens) ──

function tagSystemicFindings(findings: ContrastFinding[]): void {
  // Count distinct screens per selector (for aa-fail severity)
  const selectorScreens: Record<string, Set<string>> = {};
  for (const f of findings) {
    if (f.severity === "aa-fail") {
      if (!selectorScreens[f.selector]) selectorScreens[f.selector] = new Set();
      selectorScreens[f.selector].add(f.screen);
    }
  }
  for (const f of findings) {
    if (f.severity === "aa-fail" && f.selector) {
      const screenCount = selectorScreens[f.selector]?.size ?? 0;
      if (screenCount >= 3) {
        f.scope = "systemic";
      }
    }
  }
}

// ── D-17/D-21: Write unified report BEFORE gate assertion ─────────────────────

async function writeContrastReport(findings: ContrastFinding[], scenario: SeedScenario): Promise<void> {
  tagSystemicFindings(findings);

  const aaFails = findings.filter(f => f.severity === "aa-fail");
  const aaaAdvisory = findings.filter(f => f.severity === "aaa-body-advisory");

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

  await mkdir(contrastReportDir, { recursive: true });
  // CR-02/WR-04: namespace the report by producer AND scenario so the three scenario
  // tests (incident/all_green/empty) do not clobber one another, and so the axe producer
  // does not collide with the token checker's report. Each scenario gets its own file.
  const reportBase = `contrast-report.axe.${scenario}`;
  await writeFile(
    path.join(contrastReportDir, `${reportBase}.json`),
    JSON.stringify(report, null, 2)
  );

  // Build markdown summary
  const status = aaFails.length > 0 ? "FAIL" : "PASS";
  let md = `# Contrast Report — ${status}\n\n`;
  md += `Generated: ${report.generated}\n`;
  md += `Producer: axe (admin_contrast_matrix.spec.ts)\n`;
  md += `Scenario: ${scenario}\n\n`;
  md += `## Summary\n\n`;
  md += `| Metric | Count |\n|--------|-------|\n`;
  md += `| AA failures (gate) | ${aaFails.length} |\n`;
  md += `| AAA advisory | ${aaaAdvisory.length} |\n`;
  md += `| Total findings | ${findings.length} |\n\n`;

  if (aaFails.length > 0) {
    md += `## AA Failures (${aaFails.length})\n\n`;
    md += `| Screen | Theme | Viewport | State | Selector | Actual | Required | Scope |\n`;
    md += `|--------|-------|----------|-------|----------|--------|----------|-------|\n`;
    const systemic = aaFails.filter(f => f.scope === "systemic");
    const local = aaFails.filter(f => f.scope !== "systemic");
    for (const f of [...systemic, ...local]) {
      md += `| ${f.screen} | ${f.theme} | ${f.viewport} | ${f.state} | \`${f.selector}\` | ${f.actual_ratio ?? "?"} | ${f.required_ratio} | ${f.scope} |\n`;
    }
    md += "\n";
  } else {
    md += `## AA Failures\n\nNo AA violations found.\n\n`;
  }

  if (aaaAdvisory.length > 0) {
    md += `## AAA Advisory (${aaaAdvisory.length})\n\n`;
    md += `> Advisory only — does not affect exit code\n\n`;
    md += `| Screen | Theme | Viewport | Selector | Actual | AAA Target |\n`;
    md += `|--------|-------|----------|----------|--------|------------|\n`;
    for (const f of aaaAdvisory) {
      md += `| ${f.screen} | ${f.theme} | ${f.viewport} | \`${f.selector}\` | ${f.actual_ratio ?? "?"} | ${f.aaa_required} |\n`;
    }
    md += "\n";
  } else {
    md += `## AAA Advisory\n\nNo AAA advisory findings.\n\n`;
  }

  await writeFile(
    path.join(contrastReportDir, `${reportBase}.md`),
    md
  );
}

// ── Core axe check function (D-04/D-06/D-07/D-08/D-09/D-20) ─────────────────

async function axeCheck(
  browser: Browser,
  capture: ScreenCapture,
  mode: ThemeMode,
  viewport: ViewportName,
  findings: ContrastFinding[]
): Promise<void> {
  // D-09: system-dark uses colorScheme override; explicit rows do NOT set colorScheme
  const ctxOptions =
    mode.kind === "system"
      ? { viewport: VIEWPORTS[viewport], colorScheme: mode.colorScheme as "dark" }
      : { viewport: VIEWPORTS[viewport] };

  const context = await browser.newContext(ctxOptions);

  if (mode.kind === "explicit") {
    // D-09: write phx:theme for explicit rows only
    await context.addInitScript(
      ([key, value]: [string, string]) => {
        window.localStorage.setItem(key, value);
      },
      ["phx:theme", mode.theme]
    );
  }
  // D-07: system-dark row deliberately OMITS the phx:theme write

  const page = await context.newPage();
  try {
    await capture.prepare(page);

    // D-08: runtime invariants for system-dark AFTER waitForLiveConnected (called inside prepare)
    if (mode.kind === "system") {
      await assertSystemDarkInvariants(page);
    }

    // D-04: AA gate pass — color-contrast rule only; gate on violations[] NEVER on incomplete[]
    const aaResults = await new AxeBuilder({ page })
      .withRules(["color-contrast"])
      .analyze();

    // D-20: AAA advisory pass — scoped to body selectors; NEVER affects exit code.
    // CR-03: axe-core throws `No elements found for include in page Context` when the
    // ENTIRE include set resolves to zero elements (e.g. empty-state screens with none of
    // the BODY_SELECTORS present). Guard it so the advisory pass can never propagate a
    // throw out of axeCheck and fail the gate. Two layers of protection:
    //   (1) only add includes that actually match on this page, and skip the pass
    //       entirely when nothing matches (no body text to advise on);
    //   (2) wrap analyze() in try/catch as a belt-and-braces — any AAA error is swallowed
    //       and treated as zero advisory findings (D-20: advisory NEVER gates).
    let aaaResults: {
      violations: Array<{
        id: string;
        impact: string | null;
        nodes: Array<{
          target: string[];
          any: Array<{ data?: { fgColor?: string; bgColor?: string; contrastRatio?: number } }>;
        }>;
      }>;
    } = { violations: [] };
    try {
      const aaaBuilder = new AxeBuilder({ page }).withRules(["color-contrast-enhanced"]);
      let includedAny = false;
      for (const sel of BODY_SELECTORS) {
        if ((await page.locator(sel).count()) > 0) {
          aaaBuilder.include(sel);
          includedAny = true;
        }
      }
      if (includedAny) {
        aaaResults = await aaaBuilder.analyze();
      }
    } catch (err) {
      // D-20: AAA is advisory — never let it affect the gate.
      console.warn(`AAA advisory pass skipped (${(err as Error).message})`);
    }

    // Accumulate into unified report (D-17/D-18)
    appendFindings(findings, { capture, mode, viewport, aaResults, aaaResults });
  } finally {
    await context.close();
  }
}

// ── describeScenario loop ─────────────────────────────────────────────────────

function describeScenario(scenario: SeedScenario, captures: ScreenCapture[]): void {
  test(`admin contrast matrix — ${scenario}`, async ({ browser, request }) => {
    test.setTimeout(180_000);

    // Seed the operational state once for this scenario group.
    const seed = await seedScenario(request, scenario);

    // Confirm the catalog is searchable before checking — but only for scenarios that
    // leave the live contract intact. `incident`/`degraded` inject contract drift that
    // drops the tenant_id filterable, so a tenant-filtered visibility probe would fail by
    // design; for those the products are still synced (drift is injected after sync).
    if (scenario === "all_green" && seed.tenant_id) {
      await drainSearchQueue(request);
      await waitForSearchVisible(request, {
        tenantId: seed.tenant_id,
        query: "quantum",
        expectedName: "Quantum CyberPhone X"
      });
    }

    const findings: ContrastFinding[] = [];

    for (const capture of captures) {
      for (const mode of THEME_MODES) {
        for (const viewport of VIEWPORT_NAMES) {
          await axeCheck(browser, capture, mode, viewport, findings);
        }
      }
    }

    // D-21: write report BEFORE deciding exit so failure reasons are always readable
    await writeContrastReport(findings, scenario);

    const aaFails = findings.filter(f => f.severity === "aa-fail").length;
    expect(
      aaFails,
      `${aaFails} AA contrast violations found — see CONTRAST_REPORT_DIR`
    ).toBe(0);
  });
}

// ── Shared prepare steps (verbatim from admin_screenshot_matrix.spec.ts) ──────

async function gotoControlRoom(page: Page): Promise<void> {
  await page.goto("/admin/search");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Control Room" })).toBeVisible();
}

async function gotoPosture(page: Page): Promise<void> {
  await page.goto("/admin/search/posture");
  await waitForLiveConnected(page);
  await page.getByRole("button", { name: "Refresh posture" }).click();
  await expect(page.getByRole("heading", { name: "Posture", exact: true })).toBeVisible();
}

async function gotoFailedSync(page: Page): Promise<void> {
  await page.goto("/admin/search/failed-sync");
  await waitForLiveConnected(page);
  await page.getByRole("button", { name: "Refresh failed sync jobs" }).click();
  await expect(page.getByRole("heading", { name: "Failed sync jobs", exact: true })).toBeVisible();
}

async function gotoSyncDrift(page: Page): Promise<void> {
  await page.goto("/admin/search/sync-drift");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Sync and drift" })).toBeVisible();
  await page.getByRole("button", { name: "Load / refresh contract drift" }).click();
  // load_drift defers the bounded backend read to a :run_drift message (S3 loading
  // state), so the dimensions panel appears a render after the click — toBeVisible polls.
  await expect(page.getByText("Contract dimensions")).toBeVisible();
}

async function gotoSearch(page: Page): Promise<void> {
  await page.goto("/admin/search/search");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Search & federation" })).toBeVisible();
}

async function gotoPlaybooks(page: Page): Promise<void> {
  await page.goto("/admin/search/playbooks");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Saved playbooks" })).toBeVisible();
}

async function runSearch(page: Page, query: string): Promise<void> {
  await page.getByLabel("Search text").fill(query);
  await page.getByRole("button", { name: "Run bounded search" }).click();
}

// ── Scenario groups (D-01 curated 9 states + D-02 dark-risk supplement) ──────

// incident: red posture, populated failed sync, contract drift, can't-fully-trust verdict.
// D-02 supplement index "10": sync-drift drift-chips on the incident surface (dark-risk target).
describeScenario("incident", [
  { index: "00", screen: "control-room", state: "incident", prepare: gotoControlRoom },
  { index: "01", screen: "posture", state: "incident", prepare: gotoPosture },
  {
    index: "02",
    screen: "failed-sync",
    state: "populated",
    prepare: async (page) => {
      await gotoFailedSync(page);
      const row = page.getByTestId("failed-sync-row").first();
      await expect(row).toBeVisible();
    }
  },
  { index: "03", screen: "sync-drift", state: "drift", prepare: gotoSyncDrift },
  // D-02 dark-risk supplement: drift chips + muted metadata on non-incident surface
  {
    index: "10",
    screen: "sync-drift",
    state: "drift-detail",
    prepare: async (page) => {
      await gotoSyncDrift(page);
      // drift chips + muted metadata visible — dark #1B2230 surface-2 gap target
    }
  }
]);

// all_green: healthy posture, trusted verdict, search returns results.
// D-02 supplements: posture healthy-detail (index 11) + search results-with-facets (index 13).
describeScenario("all_green", [
  { index: "04", screen: "control-room", state: "all-green", prepare: gotoControlRoom },
  { index: "05", screen: "posture", state: "all-green", prepare: gotoPosture },
  {
    index: "06",
    screen: "search",
    state: "results",
    prepare: async (page) => {
      await gotoSearch(page);
      await runSearch(page, "quantum");
      await expect(page.getByRole("heading", { name: "Results" })).toBeVisible();
    }
  },
  // D-02 dark-risk supplement: posture populated/healthy — muted metadata rows
  {
    index: "11",
    screen: "posture",
    state: "healthy-detail",
    prepare: async (page) => {
      await gotoPosture(page);
      // posture populated/healthy detail — muted metadata rows in dark
    }
  },
  // D-02 dark-risk supplement: search results with facets/secondary text visible
  {
    index: "13",
    screen: "search",
    state: "results-with-facets",
    prepare: async (page) => {
      await gotoSearch(page);
      await runSearch(page, "quantum");
      await expect(page.getByRole("heading", { name: "Results" })).toBeVisible();
      // facet/secondary text visible — muted text contrast target
    }
  }
]);

// empty: no synced products / signals — every screen renders its empty state.
// D-02 supplement: playbooks populated (index 12) — muted metadata rows in dark.
describeScenario("empty", [
  {
    index: "07",
    screen: "failed-sync",
    state: "empty",
    prepare: gotoFailedSync
  },
  {
    index: "08",
    screen: "search",
    state: "zero-results",
    prepare: async (page) => {
      await gotoSearch(page);
      await runSearch(page, "nothingmatchesthisquery");
      // Either an explicit Results heading with no rows, or the empty/zero-result state.
      await page.waitForTimeout(500);
    }
  },
  {
    index: "09",
    screen: "playbooks",
    state: "empty-workspace",
    prepare: gotoPlaybooks
  },
  // D-02 dark-risk supplement: playbooks with saved items — muted metadata rows in dark
  {
    index: "12",
    screen: "playbooks",
    state: "populated",
    prepare: async (page) => {
      await gotoPlaybooks(page);
      // playbooks with saved items — muted metadata rows in dark
    }
  }
]);
