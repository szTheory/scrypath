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

async function expectSearchHealthGroupContract(page: Page): Promise<void> {
  const backend = page.getByRole("region", { name: /Backend task signals/ });
  const queue = page.getByRole("region", { name: /Queue job signals/ });
  await expect(backend).toHaveCount(1);
  await expect(queue).toHaveCount(1);
  await expect(backend.locator(".ops-signal-group__title")).toHaveText("Backend tasks");
  await expect(queue.locator(".ops-signal-group__title")).toHaveText("Queue jobs");

  const groupStyles = await page.locator(".ops-signal-group").evaluateAll((groups) =>
    groups.map((group) => {
      const style = getComputedStyle(group);
      return {
        backgroundColor: style.backgroundColor,
        backgroundImage: style.backgroundImage,
        border: [style.borderTopWidth, style.borderRightWidth, style.borderBottomWidth, style.borderLeftWidth],
        borderStyles: [style.borderTopStyle, style.borderRightStyle, style.borderBottomStyle, style.borderLeftStyle],
        borderRadius: style.borderRadius,
        boxShadow: style.boxShadow
      };
    })
  );
  expect(groupStyles).toHaveLength(2);
  for (const style of groupStyles) {
    expect(style.backgroundColor).toBe("rgba(0, 0, 0, 0)");
    expect(style.backgroundImage).toBe("none");
    expect(style.border).toEqual(["0px", "0px", "0px", "0px"]);
    expect(style.borderStyles).toEqual(["none", "none", "none", "none"]);
    expect(style.borderRadius).toBe("0px");
    expect(style.boxShadow).toBe("none");
  }

  for (const title of [backend.locator(".ops-signal-group__title"), queue.locator(".ops-signal-group__title")]) {
    const type = await title.evaluate((node) => {
      const style = getComputedStyle(node);
      return { fontSize: style.fontSize, fontWeight: style.fontWeight, lineHeight: style.lineHeight };
    });
    expect(type).toEqual({ fontSize: "16px", fontWeight: "600", lineHeight: "20.8px" });
  }
}

for (const entry of entries) {
  test(`${entry.name} Search health keeps status local and distinguishes unknown, unused, and empty`, async ({ page }) => {
    test.info().annotations.push({ type: "source-sha", description: process.env.SCRYPATH_SOURCE_SHA || "unknown" });
    await visit(page, entry);

    const baseline = await surfaceFingerprint(page);
    const healthyVerdictIcon = page.getByTestId("ops-verdict-icon");
    await expect(healthyVerdictIcon).toHaveAttribute("data-state", "success");
    const healthyIconColors = await healthyVerdictIcon.evaluate((icon) => ({
      icon: getComputedStyle(icon).color,
      headline: getComputedStyle(icon.parentElement!).color
    }));
    expect(healthyIconColors.icon).toBe(healthyIconColors.headline);
    const healthyRow = page.getByTestId("posture-row").first();
    await expect(healthyRow.locator(".ops-badge-neutral")).toHaveCount(2);
    await expect(healthyRow.locator(".ops-badge-success")).toHaveCount(0);
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
    await expect(unavailable).toContainText("Refresh health to try again");
    await expect(unavailable).not.toContainText("backend failed");
    await expect(metric(page, "Schema check errors")).toHaveAttribute("data-ops-metric-tone", "warning");

    await chooseScenario(page, "unknown");
    const unknownQueue = page.getByTestId("posture-row").first();
    await expect(unknownQueue).toContainText(":phase173_queue_unavailable");
    await expect(unknownQueue).not.toContainText("queue failed");
    await expect(unknownQueue.locator(".ops-schema-signal-card__groups")).toHaveCount(0);

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

    for (const theme of ["light", "dark"] as const) {
      await visit(page, entry, "failed");
      await setTheme(page, theme);
      await mkdir(screenshotDir, { recursive: true });
      for (const width of [390, 1440]) {
        await page.setViewportSize({ width, height: width === 390 ? 844 : 900 });
        await expect(page.locator(".ops-verdict")).toContainText("Degraded");
        await expectSearchHealthGroupContract(page);
        await page.evaluate(() => window.scrollTo(0, 0));
        await page.screenshot({
          path: join(screenshotDir, `${entry.name}-degraded-${theme}-${width}.png`),
          fullPage: true
        });
      }

      await visit(page, entry, "refresh-failure");
      await setTheme(page, theme);
      await page.locator("#search-health-refresh").click();
      const retained = page.locator(".ops-time__retained");
      await expect(retained).toHaveCount(2);
      for (const explanation of await retained.all()) {
        await expect(explanation).toContainText(
          "Current observation is unavailable; this source-local evidence is retained from check"
        );
        await expect
          .poll(() => explanation.evaluate((node) => getComputedStyle(node).fontSize))
          .toBe("14px");
      }
    }
  });

  test(`${entry.name} Search health wraps long evidence at rail and mobile boundaries`, async ({ page }) => {
    test.info().annotations.push({ type: "source-sha", description: process.env.SCRYPATH_SOURCE_SHA || "unknown" });
    await visit(page, entry, "long");
    await mkdir(screenshotDir, { recursive: true });
    const longSchema = page.getByTestId("posture-row").filter({ hasText: "VeryLongSchemaIdentifierForNarrowOperatorDisplays" });
    await expect(longSchema).toHaveCount(1);

    for (const theme of ["light", "dark"] as const) {
      await setTheme(page, theme);
      for (const width of [320, 390, 1279, 1280, 1440]) {
        await page.setViewportSize({ width, height: width === 390 ? 844 : 900 });
        await expect(page.getByTestId("posture-row").filter({ hasText: entry.schema })).toHaveCount(1);

        const geometry = await page.evaluate(() => {
          const list = document.querySelector<HTMLElement>(".ops-schema-signal-list")!;
          const rows = Array.from(document.querySelectorAll<HTMLElement>(".ops-schema-signal-card"));
          const refresh = document.querySelector<HTMLElement>("#search-health-refresh")!;
          const actions = Array.from(document.querySelectorAll<HTMLElement>("[data-testid='posture-failed-sync-link']"));
          return {
            viewport: window.innerWidth,
            page: document.documentElement.scrollWidth,
            rows: rows.map((row) => ({ width: row.clientWidth, scrollWidth: row.scrollWidth, overflowWrap: getComputedStyle(row).overflowWrap })),
            rowGap: getComputedStyle(list).rowGap,
            refreshHeight: refresh.getBoundingClientRect().height,
            inspectHeights: actions.map((action) => action.getBoundingClientRect().height)
          };
        });

        expect(geometry.page, `${entry.name} page overflow at ${width}px`).toBeLessThanOrEqual(geometry.viewport);
        expect(geometry.rows.length).toBe(2);
        for (const row of geometry.rows) {
          expect(row.scrollWidth, `${entry.name} row overflow at ${width}px`).toBeLessThanOrEqual(row.width + 1);
          expect(row.overflowWrap).toBe("anywhere");
        }
        await expect(longSchema.locator("h3")).toContainText("VeryLongSchemaIdentifierForNarrowOperatorDisplays");
        await expect(longSchema).not.toContainText("...");
        expect(geometry.rowGap).toBe("24px");
        expect(geometry.refreshHeight).toBeGreaterThanOrEqual(40);
        for (const height of geometry.inspectHeights) expect(height).toBeGreaterThanOrEqual(40);

        await page.evaluate(() => window.scrollTo(0, 0));
        await page.screenshot({
          path: join(screenshotDir, `${entry.name}-status-${theme}-${width}.png`),
          fullPage: true
        });
      }

      await chooseScenario(page, "failed");
      for (const width of [320, 390]) {
        await page.setViewportSize({ width, height: 844 });
        const row = page.getByTestId("posture-row").filter({ hasText: entry.schema });
        const link = row.getByTestId("posture-failed-sync-link");
        await expect(link).toHaveAttribute("href", new RegExp(`schema=${encodeURIComponent(entry.schema)}$`));
        await expect(link).toBeVisible();
        await link.focus();
        const focus = await link.evaluate((node) => {
          const style = getComputedStyle(node);
          return { width: style.outlineWidth, offset: style.outlineOffset, style: style.outlineStyle };
        });
        expect(focus).toEqual({ width: "2px", offset: "2px", style: "solid" });
        const pageWidth = await page.evaluate(() => document.documentElement.scrollWidth);
        expect(pageWidth, `${entry.name} failed-work page overflow at ${width}px`).toBeLessThanOrEqual(width);
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
    await page.mouse.move(1, 1);
    await page.mouse.up();
    await expect(refresh).toBeEnabled();
    await expect(refresh).not.toHaveAttribute("aria-busy", "true");

    await refresh.focus();
    await page.keyboard.press("Tab");
    await page.keyboard.press("Shift+Tab");
    await expect(refresh).toBeFocused();
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
    await expect(page.getByTestId("posture-row").first()).toContainText("Refresh health to try again");
    await expect(page.getByText("Search health refreshed.", { exact: true })).toHaveCount(0);
  });
}
