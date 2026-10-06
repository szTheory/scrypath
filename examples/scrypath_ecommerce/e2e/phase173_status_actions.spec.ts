import { expect, test } from "@playwright/test";
import { mkdirSync } from "node:fs";
import { join } from "node:path";

const ENTRYPOINTS = [
  {
    name: "mounted",
    url: "/admin/search/phase173/health",
    rows: ["posture-ScrypathEcommerce.Catalog.Product", "posture-ScrypathEcommerce.Catalog.Variant"]
  },
  {
    name: "standalone",
    url: process.env.PHASE173_OPS_BASE_URL ?? "http://ops:4003/ops/phase173/health",
    rows: ["posture-ScrypathOps.Test.OpsPostA", "posture-ScrypathOps.Test.OpsPostB"]
  }
] as const;

const scenarios = ["default", "failed", "unknown", "empty", "partial", "long-value", "source-error", "manual", "no-success"] as const;
type Theme = "light" | "dark" | "system";

async function openScenario(page: import("@playwright/test").Page, url: string, scenario: string, theme: Theme, width: number) {
  await page.setViewportSize({ width, height: 960 });
  await page.emulateMedia({ colorScheme: theme === "system" ? "dark" : theme });
  const separator = url.includes("?") ? "&" : "?";
  await page.goto(`${url}${separator}scenario=${scenario}`);
  const live = page.locator("[data-phx-main]");
  await expect(live).toHaveClass(/phx-connected/);
  await expect(page.getByRole("heading", { name: "Search health", exact: true })).toBeVisible();
  await expect(page.locator("html")).toHaveAttribute("data-theme-effective", theme === "system" ? "dark" : theme);
}

for (const entrypoint of ENTRYPOINTS) {
  test(`${entrypoint.name} status sources stay truthful across themes and responsive widths`, async ({ page }) => {
    const captureDir = join(process.cwd(), "test-results", "phase173-status-captures");
    mkdirSync(captureDir, { recursive: true });

    for (const theme of ["light", "dark", "system"] as const) {
      for (const width of [390, 1279, 1280, 1440]) {
        for (const scenario of scenarios) {
          await openScenario(page, entrypoint.url, scenario, theme, width);
          const rows = page.locator('[data-testid="posture-row"]');

          if (scenario === "empty") {
            await expect(page.getByText(/No schemas are configured for search health/)).toBeVisible();
            await expect(rows).toHaveCount(0);
            await expect(page.locator(".ops-metric")).toHaveCount(0);
          } else {
            await expect(rows).toHaveCount(scenario === "partial" ? 1 : 2);
            for (const id of entrypoint.rows.slice(0, scenario === "partial" ? 1 : 2)) {
              const row = page.locator(`[id="${id}"]`);
              await expect(row).toBeVisible();
              await expect(row.locator("h3")).toContainText(id.replace("posture-", ""));
              await expect(row.locator("h3")).toHaveCSS("overflow-wrap", "anywhere");
            }
            await expect(page.locator(".ops-metric").first()).toContainText("Schemas");
            await expect(page.locator(".ops-metric").nth(1)).toContainText("Schema check errors");
            await expect(page.locator(".ops-metric-success")).toHaveCount(0);
          }

          if (scenario === "failed") {
            await expect(page.locator(".ops-verdict")).toContainText("Degraded");
            await expect(page.locator(".ops-verdict")).toContainText("will not self-heal");
            await expect(page.getByTestId("posture-failed-sync-link").first()).toBeVisible();
            await expect(page.locator(".ops-metric-warning").first()).toBeVisible();
          } else if (scenario === "unknown") {
            // The unknown Meilisearch status fails source decoding explicitly;
            // it must not be represented as zero or as remote terminal failure.
            await expect(rows.first()).toContainText("fetch error:");
            await expect(rows.first()).not.toContainText("backend failed");
            await expect(page.locator(".ops-metric").nth(2)).toContainText("0");
          } else if (scenario === "source-error") {
            await expect(rows.first()).toContainText("fetch error: :fixture_unavailable");
            await expect(rows.first()).toContainText("Not observed");
            await expect(page.locator(".ops-verdict")).toContainText("Degraded");
          } else if (scenario === "manual") {
            await expect(rows.first()).toContainText("Queue not used in manual sync mode.");
          } else if (scenario === "no-success") {
            await expect(rows.first().locator("[aria-label^='Backend task signals']")).toContainText("No success observed");
          } else if (scenario === "partial") {
            await expect(rows).toHaveCount(1);
            await expect(page.locator(".ops-metric").first()).toContainText("1");
          }

          const dimensions = await page.evaluate(() => ({
            viewport: document.documentElement.clientWidth,
            document: document.documentElement.scrollWidth,
            rowGap: getComputedStyle(document.querySelector(".ops-schema-signal-list")!).rowGap
          }));
          expect(dimensions.document).toBeLessThanOrEqual(dimensions.viewport);
          if (scenario !== "empty") expect(Number.parseFloat(dimensions.rowGap)).toBeGreaterThanOrEqual(24);

          const refresh = page.getByRole("button", { name: "Refresh search health" });
          const refreshBox = await refresh.boundingBox();
          expect(refreshBox).not.toBeNull();
          expect(refreshBox!.height).toBeGreaterThanOrEqual(40);
          if (theme === "light" && width === 390 && ["default", "failed"].includes(scenario)) {
            await page.evaluate(() => window.scrollTo(0, 0));
            await page.screenshot({ path: join(captureDir, `phase173-${entrypoint.name}-${scenario}-${theme}-${width}.png`), fullPage: true });
          }
        }
      }
    }
  });

  test(`${entrypoint.name} refresh keeps server eligibility after a LiveView patch`, async ({ page }) => {
    await page.goto(entrypoint.url);
    const live = page.locator("[data-phx-main]");
    await expect(live).toHaveClass(/phx-connected/);

    const refresh = page.getByRole("button", { name: "Refresh search health" });
    await expect(refresh).toBeEnabled();
    // Select a deterministic server fixture for the real LiveView event. This
    // only changes the event input; disabled state must arrive in a server patch.
    await refresh.evaluate((button) => button.setAttribute("phx-value-scenario", "eligibility-disabled"));
    await refresh.click();

    await expect(page.getByText("Refresh is disabled by the phase 173 eligibility fixture.")).toBeVisible();
    await expect(refresh).toBeDisabled();
    await expect(refresh.locator("svg")).toBeVisible();
    await expect(refresh.locator("span")).toHaveText("Refresh");
  });

  test(`${entrypoint.name} quiet action exposes independent focus and transient interaction states`, async ({ page }) => {
    await openScenario(page, entrypoint.url, "default", "light", 1440);
    const refresh = page.getByRole("button", { name: "Refresh search health" });
    await refresh.focus();
    await expect(refresh).toBeFocused();
    const focus = await refresh.evaluate((button) => ({
      width: getComputedStyle(button).outlineWidth,
      style: getComputedStyle(button).outlineStyle,
      offset: getComputedStyle(button).outlineOffset
    }));
    expect(focus).toEqual({ width: "2px", style: "solid", offset: "2px" });

    const before = await refresh.evaluate((button) => getComputedStyle(button).backgroundColor);
    await refresh.hover();
    const hover = await refresh.evaluate((button) => getComputedStyle(button).backgroundColor);
    expect(hover).not.toBe(before);
    await page.mouse.down();
    const pressed = await refresh.evaluate((button) => getComputedStyle(button).backgroundColor);
    expect(pressed).not.toBe(hover);
    await page.mouse.up();

    await refresh.click();
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await expect(refresh).toBeEnabled();
    await expect(refresh.locator("svg")).toBeVisible();
    await expect(refresh.locator("span")).toHaveText("Refresh");
  });
}
