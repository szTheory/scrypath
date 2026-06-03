/**
 * Admin UI screenshot matrix (HARNESS-01).
 *
 * Captures the cross-product 6 screens × {light, dark} × {mobile 390px, desktop 1440px},
 * each in the operational state that best exercises it. Seeding is driven through the
 * named operational scenarios added in SEED-01 (/dev/e2e/seed): incident / all_green /
 * empty. To keep the matrix deterministic and cheap, captures are grouped by scenario so
 * each scenario is seeded once, then every screen for that scenario is shot across the
 * theme × viewport grid.
 *
 * Output:
 *   - ADMIN_SCREENSHOT_DIR (default test-results/admin-screenshots/)
 *   - files named NN-screen--theme--viewport--state.png
 *
 * Theme is set via the documented mechanism: the root template's inline script reads
 * localStorage["phx:theme"] on load (light | dark | <absent => system>). We set it with
 * addInitScript on a fresh context so it applies before the first paint.
 */
import { expect, test, type Browser, type Page } from "@playwright/test";
import { mkdir } from "node:fs/promises";
import path from "node:path";

import {
  drainSearchQueue,
  seedScenario,
  waitForLiveConnected,
  waitForSearchVisible,
  type SeedScenario
} from "./helpers/e2e";

const screenshotDir = process.env.ADMIN_SCREENSHOT_DIR || "test-results/admin-screenshots";

type Theme = "light" | "dark";
type ViewportName = "mobile" | "desktop";

const VIEWPORTS: Record<ViewportName, { width: number; height: number }> = {
  mobile: { width: 390, height: 844 },
  desktop: { width: 1440, height: 900 }
};

const THEMES: Theme[] = ["light", "dark"];
const VIEWPORT_NAMES: ViewportName[] = ["mobile", "desktop"];

// A single capture target: which screen, what posture state label, and the per-page
// preparation (navigate + trigger + wait for the load-bearing content) before the shot.
type ScreenCapture = {
  index: string;
  screen: string;
  state: string;
  prepare: (page: Page) => Promise<void>;
};

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

// Run one scenario's screen list across the full theme × viewport grid.
function describeScenario(scenario: SeedScenario, captures: ScreenCapture[]): void {
  test(`admin screenshot matrix — ${scenario}`, async ({ browser, request }) => {
    test.setTimeout(180_000);

    // Seed the operational state once for this scenario group.
    const seed = await seedScenario(request, scenario);

    // Confirm the catalog is searchable before capturing — but only for scenarios that
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

    for (const capture of captures) {
      for (const theme of THEMES) {
        for (const viewport of VIEWPORT_NAMES) {
          await shoot(browser, capture, theme, viewport);
        }
      }
    }
  });
}

// ── Shared prepare steps ───────────────────────────────────────────────────────

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
  await expect(page.getByRole("heading", { name: "Sync & Drift" })).toBeVisible();
  await page.getByRole("button", { name: "Load / refresh contract drift" }).click();
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

// ── Scenario groups ──────────────────────────────────────────────────────────

// incident: red posture, populated failed sync, contract drift, can't-fully-trust verdict.
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
  { index: "03", screen: "sync-drift", state: "drift", prepare: gotoSyncDrift }
]);

// all_green: healthy posture, trusted verdict, search returns results.
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
  }
]);

// empty: no synced products / signals — every screen renders its empty state.
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
  }
]);
