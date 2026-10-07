import { expect, test, type Browser, type Page } from "@playwright/test";
import { mkdirSync } from "node:fs";
import { join } from "node:path";

const ENTRYPOINTS = [
  { name: "mounted", url: "/admin/search/phase173/health", row: "posture-ScrypathEcommerce.Catalog.Product" },
  {
    name: "standalone",
    url: process.env.PHASE173_OPS_BASE_URL ?? "http://ops:4003/ops/phase173/health",
    row: "posture-ScrypathOps.Test.OpsPostA"
  }
] as const;

const SOURCE_ISO = "2026-10-04T13:02:05.123456-04:00";
const UTC_ISO = "2026-10-04T17:02:05.123456Z";

async function openPage(browser: Browser, width: number, theme: "light" | "dark") {
  const context = await browser.newContext({
    viewport: { width, height: 1000 },
    hasTouch: true,
    colorScheme: theme
  });
  await context.addInitScript((value) => localStorage.setItem("phx:theme", value), theme);
  const page = await context.newPage();
  return { context, page };
}

for (const entrypoint of ENTRYPOINTS) {
  test(`${entrypoint.name} renders stable exact operational time without overflow`, async ({ browser }) => {
    const captureDir = join(process.cwd(), "test-results", "phase173-time-captures");
    mkdirSync(captureDir, { recursive: true });

    for (const width of [390, 1279, 1280, 1440]) {
      for (const theme of ["light", "dark"] as const) {
        const { context, page } = await openPage(browser, width, theme);
        await page.goto(entrypoint.url);
        await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
        const row = page.locator(`[id="${entrypoint.row}"]`);
        await expect(row).toBeVisible();

        const time = row.locator(".ops-signal-group").first().locator(".ops-time");
        await expect(time).toContainText("2 days ago");
        await expect(time.locator("time.ops-time__value")).toHaveCSS("font-size", "14px");
        expect(await time.locator("time").evaluate((element) => getComputedStyle(element).fontFamily))
          .toBe(await page.locator("body").evaluate((element) => getComputedStyle(element).fontFamily));
        const checked = page.locator("#search-health-refresh").locator("..");
        await expect(checked.locator("details")).toHaveCount(0);
        await expect(checked.locator(".ops-time__copy")).toHaveCount(0);
        await page.locator(`#theme-toggle [data-phx-theme="${theme === "light" ? "dark" : "light"}"]`).click();
        await expect(time).toContainText("2 days ago");
        await page.locator(`#theme-toggle [data-phx-theme="${theme}"]`).click();
        await expect(page.locator("html")).toHaveAttribute("data-theme-effective", theme);
        const details = time.locator("details.ops-time__disclosure");
        const summary = details.locator("summary");
        await summary.click();
        const exact = details.locator("code.ops-time__exact");
        await expect(exact).toHaveText(SOURCE_ISO);
        await expect(details.locator("code.ops-time__utc")).toHaveText(UTC_ISO);
        await expect(exact).toHaveCSS("overflow-wrap", "anywhere");

        await summary.focus();
        await page.keyboard.press("Enter");
        await expect(details).not.toHaveAttribute("open", "");
        await page.touchscreen.tap((await summary.boundingBox())!.x + 8, (await summary.boundingBox())!.y + 8);
        await expect(details).toHaveAttribute("open", "");
        await summary.evaluate((element) => element.blur());

        const dimensions = await page.evaluate(() => ({
          viewport: document.documentElement.clientWidth,
          document: document.documentElement.scrollWidth,
          exactWidth: document.querySelector(".ops-time__exact")?.getBoundingClientRect().width ?? 0
        }));
        expect(dimensions.document).toBeLessThanOrEqual(dimensions.viewport);
        expect(dimensions.exactWidth).toBeGreaterThan(0);

        const ageBox = await time.locator("time.ops-time__value").boundingBox();
        const exactBox = await exact.boundingBox();
        expect(ageBox).not.toBeNull();
        expect(exactBox).not.toBeNull();
        expect(exactBox!.y).toBeGreaterThanOrEqual(ageBox!.y + ageBox!.height - 1);

        await page.evaluate(() => window.scrollTo(0, 0));
        await page.screenshot({
          path: join(captureDir, `phase173-${entrypoint.name}-${width}-${theme}.png`),
          fullPage: true
        });

        await page.getByRole("button", { name: "Refresh search health" }).click();
        await expect(time).toContainText("2 days ago");

        const refresh = page.getByRole("button", { name: "Refresh search health" });
        await refresh.evaluate((button) => button.setAttribute("phx-value-scenario", "source-error"));
        await refresh.click();
        await expect(row).toContainText("fetch error: :fixture_unavailable");
        await expect(row).toContainText("last success retained from the previous check");
        const retainedTime = row.locator(".ops-time").first();
        await expect(retainedTime).toContainText("2 days ago");
        await expect(retainedTime.locator("code.ops-time__exact")).toHaveText(SOURCE_ISO);
        await expect(checked.locator("time")).toHaveAttribute("datetime", "2026-10-07T17:18:42.318Z");

        await context.close();
      }
    }

    for (const scenario of ["source-error", "no-success", "missing-time", "manual"] as const) {
      const { context, page } = await openPage(browser, 390, "light");
      const separator = entrypoint.url.includes("?") ? "&" : "?";
      await page.goto(`${entrypoint.url}${separator}scenario=${scenario}`);
      await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
      const row = page.locator(`[id="${entrypoint.row}"]`);
      await expect(row).toBeVisible();

      if (scenario === "source-error") {
        await expect(row).toContainText("fetch error: :fixture_unavailable");
        const backend = row.locator(".ops-signal-group").first();
        const queue = row.locator(".ops-signal-group").nth(1);
        await expect(backend.locator(".ops-time__reason")).toHaveText(":fixture_unavailable");
        await expect(backend).toContainText("Not observed");
        await expect(backend.locator("details.ops-time__disclosure")).toHaveCount(0);
        await expect(queue.locator("time.ops-time__value")).toHaveText("3 days ago");
        await expect(queue.locator("code.ops-time__exact")).toHaveText(SOURCE_ISO);
      } else if (scenario === "no-success") {
        await expect(row.locator(".ops-signal-group").first().locator(".ops-time")).toContainText("No success observed");
      } else if (scenario === "missing-time") {
        await expect(row.locator(".ops-signal-group").first().locator(".ops-time")).toContainText("Success time not observed");
      } else {
        await expect(row).toContainText("Queue not used in manual sync mode.");
      }

      await context.close();
    }
  });
}
