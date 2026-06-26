import { expect, type Page } from "@playwright/test";

import { waitForLiveConnected, type SeedScenario } from "./e2e";

export type ThemeMode =
  | { kind: "explicit"; theme: "light" | "dark" }
  | { kind: "system"; colorScheme: "dark" };

export const THEME_MODES: ThemeMode[] = [
  { kind: "explicit", theme: "light" },
  { kind: "explicit", theme: "dark" },
  { kind: "system", colorScheme: "dark" }
];

export function themeSlug(mode: ThemeMode): string {
  return mode.kind === "system" ? `system-${mode.colorScheme}` : mode.theme;
}

export type ViewportName = "mobile" | "desktop";

export const VIEWPORTS: Record<ViewportName, { width: number; height: number }> = {
  mobile: { width: 390, height: 844 },
  desktop: { width: 1440, height: 900 }
};

export const VIEWPORT_NAMES: ViewportName[] = ["mobile", "desktop"];

export type ScreenCapture = {
  index: string;
  screen: string;
  state: string;
  prepare: (page: Page) => Promise<void>;
};

export async function assertSystemDarkInvariants(page: Page): Promise<void> {
  await expect(page.locator("html")).not.toHaveAttribute("data-theme");
  const mediaMatches = await page.evaluate(
    () => window.matchMedia("(prefers-color-scheme: dark)").matches
  );
  expect(mediaMatches).toBe(true);
  await expect(page.locator("html")).toHaveAttribute("data-theme-effective", "dark");
}

export async function gotoControlRoom(page: Page): Promise<void> {
  await page.goto("/admin/search");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Control Room" })).toBeVisible();
}

export async function gotoPosture(page: Page): Promise<void> {
  await page.goto("/admin/search/posture");
  await waitForLiveConnected(page);
  await page.getByRole("button", { name: "Refresh posture" }).click();
  await expect(page.getByRole("heading", { name: "Posture", exact: true })).toBeVisible();
}

export async function gotoFailedSync(page: Page): Promise<void> {
  await page.goto("/admin/search/failed-sync");
  await waitForLiveConnected(page);
  await page.getByRole("button", { name: "Refresh failed sync jobs" }).click();
  await expect(page.getByRole("heading", { name: "Failed sync jobs", exact: true })).toBeVisible();
}

export async function gotoSyncDrift(page: Page): Promise<void> {
  await page.goto("/admin/search/sync-drift");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Sync and drift" })).toBeVisible();
  await page.getByRole("button", { name: "Load / refresh contract drift" }).click();
  await expect(page.getByText("Contract dimensions")).toBeVisible();
}

export async function gotoSearch(page: Page): Promise<void> {
  await page.goto("/admin/search/search");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Search & federation" })).toBeVisible();
}

export async function gotoPlaybooks(page: Page): Promise<void> {
  await page.goto("/admin/search/playbooks");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Saved playbooks" })).toBeVisible();
}

export async function runSearch(page: Page, query: string): Promise<void> {
  await page.getByLabel("Search text").fill(query);
  await page.getByRole("button", { name: "Run bounded search" }).click();
}

export const SCENARIO_CAPTURES: Record<SeedScenario, ScreenCapture[]> = {
  incident: [
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
    {
      index: "10",
      screen: "sync-drift",
      state: "drift-detail",
      prepare: gotoSyncDrift
    }
  ],
  all_green: [
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
    {
      index: "11",
      screen: "posture",
      state: "healthy-detail",
      prepare: gotoPosture
    },
    {
      index: "13",
      screen: "search",
      state: "results-with-facets",
      prepare: async (page) => {
        await gotoSearch(page);
        await runSearch(page, "quantum");
        await expect(page.getByRole("heading", { name: "Results" })).toBeVisible();
      }
    }
  ],
  empty: [
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
        await page.waitForTimeout(500);
      }
    },
    {
      index: "09",
      screen: "playbooks",
      state: "empty-workspace",
      prepare: gotoPlaybooks
    },
    {
      index: "12",
      screen: "playbooks",
      state: "populated",
      prepare: gotoPlaybooks
    }
  ],
  degraded: [],
  e2e_search_catalog: []
};
