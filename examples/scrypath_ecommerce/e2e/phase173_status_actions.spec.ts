import { expect, test, type Page } from "@playwright/test";
import { mkdir } from "node:fs/promises";
import { join } from "node:path";

import { waitForLiveConnected } from "./helpers/e2e";

type Entry = { name: string; url: string; schema: string };

const standaloneBase = process.env.PHASE173_STANDALONE_BASE_URL || "http://standalone_ops:4003";
const screenshotDir = process.env.PHASE173_SCREENSHOT_DIR || "test-results/phase173";
const entries: Entry[] = [
  {
    name: "mounted",
    url: "/admin/search/phase173/health",
    schema: "ScrypathEcommerce.Catalog.Product"
  },
  {
    name: "standalone",
    url: `${standaloneBase}/ops/phase173/health`,
    schema: "ScrypathOps.Phase173FixtureSchema"
  }
];

async function visit(page: Page, entry: Entry, scenario = "healthy"): Promise<void> {
  const url = new URL(entry.url, process.env.PLAYWRIGHT_BASE_URL || "http://web:4002");
  url.searchParams.set("scenario", scenario);
  await page.goto(url.toString());
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Search health", exact: true })).toBeVisible();
}

async function chooseScenario(page: Page, scenario: string): Promise<void> {
  await page.getByLabel("Fixture scenario").selectOption(scenario);
  await expect(page.getByLabel("Fixture scenario")).toHaveValue(scenario);
  await waitForLiveConnected(page);
}

function metric(page: Page, label: string) {
  return page.locator(".ops-metric").filter({ hasText: label });
}

async function surfaceFingerprint(page: Page): Promise<string[]> {
  return page.evaluate(() => {
    const style = (selector: string) => {
      const node = document.querySelector<HTMLElement>(selector);
      if (!node) return "missing";
      const computed = getComputedStyle(node);
      return `${computed.backgroundColor}|${computed.borderColor}`;
    };

    return [
      style(".ops-verdict"),
      style(".ops-metric"),
      style(".ops-schema-signal-card")
    ];
  });
}

async function setTheme(page: Page, preference: "light" | "dark"): Promise<void> {
  await page.evaluate(
    ({ key, value }) => window.localStorage.setItem(key, value),
    { key: "phx:theme", value: preference }
  );
  await page.reload();
  await waitForLiveConnected(page);
  await expect(page.locator("html")).toHaveAttribute("data-theme-preference", preference);
  await expect(page.locator("html")).toHaveAttribute("data-theme-effective", preference);
}

for (const entry of entries) {
  test(`${entry.name} Search health keeps status local and distinguishes unknown, unused, and empty`, async ({ page }) => {
    test.info().annotations.push({ type: "source-sha", description: process.env.SCRYPATH_SOURCE_SHA || "unknown" });
    await visit(page, entry);

    const baseline = await surfaceFingerprint(page);
    const zeroErrors = metric(page, "Schema check errors");
    await expect(zeroErrors).toHaveAttribute("data-ops-metric-tone", "neutral");
    await expect(zeroErrors.locator(".ops-metric__value")).toHaveText("0");
    await expect(metric(page, "Failed backend tasks")).toHaveAttribute("data-ops-metric-tone", "neutral");
    await expect(page.getByTestId("posture-row").first()).toContainText(entry.schema);

    await chooseScenario(page, "failed");
    await expect(page.locator(".ops-verdict")).toContainText("Degraded");
    await expect(page.locator('[data-testid="ops-verdict-icon"][data-state="warning"]')).toBeVisible();
    const failed = page.getByTestId("posture-row").first();
    await expect(failed).toContainText("backend failed");
    await expect(failed).toContainText("queue failed");
    await expect(failed.locator("[data-testid='posture-failed-sync-link']")).toBeVisible();
    await expect(metric(page, "Failed backend tasks")).toHaveAttribute("data-ops-metric-tone", "warning");
    await expect(metric(page, "Failed backend tasks").locator(".ops-metric__value--warning")).toHaveText("1");
    await expect(page.locator(".ops-metric-success, .ops-schema-signal-card--warning, .ops-schema-signal-card--error")).toHaveCount(0);
    expect(await surfaceFingerprint(page)).toEqual(baseline);

    await chooseScenario(page, "unavailable");
    const unavailable = page.getByTestId("posture-row").first();
    await expect(unavailable).toContainText("fetch error");
    await expect(unavailable).toContainText("Search health could not be checked");
    await expect(unavailable).toContainText("Refresh to try again");
    await expect(unavailable).not.toContainText("backend failed");
    await expect(metric(page, "Schema check errors")).toHaveAttribute("data-ops-metric-tone", "warning");

    await chooseScenario(page, "unknown");
    const unknownQueue = page.getByRole("region", { name: new RegExp(`Queue job signals for ${entry.schema.replaceAll(".", "\\.")}`) });
    await expect(unknownQueue).toContainText("Queue observations unavailable; no queue counts are reported as zero.");
    await expect(page.getByTestId("posture-row").first()).toContainText("Queue observations unavailable");
    await expect(page.getByTestId("posture-row").first()).not.toContainText("queue failed");

    await chooseScenario(page, "queue-unused");
    const unusedRow = page.getByTestId("posture-row").first();
    await expect(unusedRow).toContainText("Queue not used");
    await expect(unusedRow).toContainText("Queue not used in manual sync mode.");
    await expect(unusedRow.getByRole("region", { name: /Queue job signals/ }).locator(".ops-signal-metrics")).toHaveCount(0);

    await chooseScenario(page, "empty");
    await expect(page.getByText("No schemas configured", { exact: true })).toBeVisible();
    await expect(page.getByTestId("posture-row")).toHaveCount(0);
    await expect(page.locator(".ops-metric")).toHaveCount(0);

    await chooseScenario(page, "partial");
    await expect(page.getByTestId("posture-row")).toHaveCount(2);
    await expect(page.getByTestId("posture-row").filter({ hasText: "fetch error" })).toHaveCount(1);
    await expect(page.getByTestId("posture-row").filter({ hasText: entry.schema })).toHaveCount(1);
  });

  test(`${entry.name} Search health wraps long evidence at rail and mobile boundaries`, async ({ page }) => {
    test.info().annotations.push({ type: "source-sha", description: process.env.SCRYPATH_SOURCE_SHA || "unknown" });
    await visit(page, entry, "long");
    await mkdir(screenshotDir, { recursive: true });

    for (const theme of ["light", "dark"] as const) {
      await setTheme(page, theme);
      for (const width of [390, 1279, 1280, 1440]) {
        await page.setViewportSize({ width, height: width === 390 ? 844 : 900 });
        await expect(page.getByTestId("posture-row").first()).toContainText(entry.schema);

        const geometry = await page.evaluate(() => {
          const list = document.querySelector<HTMLElement>(".ops-schema-signal-list")!;
          const row = document.querySelector<HTMLElement>(".ops-schema-signal-card")!;
          const refresh = document.querySelector<HTMLElement>("#search-health-refresh")!;
          const action = document.querySelector<HTMLElement>("[data-testid='posture-failed-sync-link']")!;
          return {
            viewport: window.innerWidth,
            page: document.documentElement.scrollWidth,
            rowWidth: row.clientWidth,
            rowScrollWidth: row.scrollWidth,
            rowGap: getComputedStyle(list).rowGap,
            refreshHeight: refresh.getBoundingClientRect().height,
            inspectHeight: action.getBoundingClientRect().height,
            overflowWrap: getComputedStyle(row).overflowWrap
          };
        });

        expect(geometry.page, `${entry.name} page overflow at ${width}px`).toBeLessThanOrEqual(geometry.viewport);
        expect(geometry.rowScrollWidth, `${entry.name} row overflow at ${width}px`).toBeLessThanOrEqual(geometry.rowWidth + 1);
        expect(geometry.rowGap).toBe("24px");
        expect(geometry.refreshHeight).toBeGreaterThanOrEqual(40);
        expect(geometry.inspectHeight).toBeGreaterThanOrEqual(40);
        expect(geometry.overflowWrap).toBe("anywhere");

        await page.evaluate(() => window.scrollTo(0, 0));
        await page.screenshot({
          path: join(screenshotDir, `${entry.name}-status-${theme}-${width}.png`),
          fullPage: true
        });
      }
    }
  });

  test(`${entry.name} refresh action preserves hover, press, focus, busy, and server eligibility`, async ({ page }) => {
    test.info().annotations.push({ type: "source-sha", description: process.env.SCRYPATH_SOURCE_SHA || "unknown" });
    await visit(page, entry);
    const refresh = page.locator("#search-health-refresh");

    await refresh.hover();
    const hoverBackground = await refresh.evaluate((button) => getComputedStyle(button).backgroundColor);
    expect(hoverBackground).not.toBe("rgba(0, 0, 0, 0)");
    expect(hoverBackground).not.toBe(await page.locator('#theme-toggle [aria-pressed="true"]').evaluate((button) => getComputedStyle(button).backgroundColor));

    const box = await refresh.boundingBox();
    expect(box).not.toBeNull();
    await page.mouse.move(box!.x + box!.width / 2, box!.y + box!.height / 2);
    await page.mouse.down();
    const pressedBackground = await refresh.evaluate((button) => getComputedStyle(button).backgroundColor);
    expect(pressedBackground).not.toBe(hoverBackground);
    await page.mouse.up();

    await refresh.focus();
    const focus = await refresh.evaluate((button) => {
      const style = getComputedStyle(button);
      return { width: style.outlineWidth, offset: style.outlineOffset, style: style.outlineStyle };
    });
    expect(focus).toEqual({ width: "2px", offset: "2px", style: "solid" });

    await refresh.evaluate((button) => button.classList.add("phx-click-loading"));
    await expect(refresh).toBeDisabled();
    await expect(refresh).toHaveAttribute("aria-busy", "true");
    await refresh.evaluate((button) => button.classList.remove("phx-click-loading"));
    await expect(refresh).toBeEnabled();
    await expect(refresh).not.toHaveAttribute("aria-busy");

    await page.emulateMedia({ reducedMotion: "reduce" });
    await refresh.evaluate((button) => button.classList.add("phx-click-loading"));
    await expect
      .poll(() => refresh.locator("svg").evaluate((icon) => getComputedStyle(icon).animationName))
      .toBe("none");
    await refresh.evaluate((button) => button.classList.remove("phx-click-loading"));

    await chooseScenario(page, "refresh-disabled");
    await expect(refresh).toBeDisabled();
    await expect(refresh).toHaveAttribute("data-ops-refresh-eligible", "false");
    await chooseScenario(page, "healthy");
    await expect(refresh).toBeEnabled();
    await expect(refresh).toHaveAttribute("data-ops-refresh-eligible", "true");

    await chooseScenario(page, "refresh-failure");
    await refresh.click();
    await expect(page.getByTestId("posture-row").first()).toContainText("Search health could not be checked");
    await expect(page.getByTestId("posture-row").first()).toContainText("2 days ago");
    await expect(page.getByTestId("posture-row").first()).toContainText("Refresh to try again");
    await expect(page.getByText("Search health refreshed.", { exact: true })).toHaveCount(0);
  });
}
