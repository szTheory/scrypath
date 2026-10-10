import { expect, test, type Page } from "@playwright/test";

const entries = [
  { name: "mounted", url: "/admin/search/phase173/health" },
  {
    name: "standalone",
    url: process.env.PHASE173_OPS_BASE_URL ?? "http://ops:4003/ops/phase173/health"
  }
] as const;

async function refreshScenario(page: Page, scenario: string) {
  const refresh = page.getByRole("button", { name: "Refresh search health", exact: true });
  await refresh.evaluate((button, value) => button.setAttribute("phx-value-scenario", value), scenario);
  await refresh.click();
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
}

for (const entry of entries) {
  for (const width of [1440, 390]) {
    test.describe(`${entry.name} quiet health at ${width}px`, () => {
      test.use({ viewport: { width, height: 900 }, hasTouch: width === 390 });

      for (const theme of ["light", "dark"] as const) {
        test(`keeps healthy details quiet and exposes actionable work in ${theme}`, async ({ page }, info) => {
          // Includes keyboard interaction, eight LiveView refreshes, and three captures.
          test.setTimeout(60_000);
          const errors: string[] = [];
          page.on("pageerror", error => errors.push(error.message));
          await page.goto(entry.url);
          await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
          await page.locator(`#theme-toggle [data-phx-theme='${theme}']`).click();
          await expect(page.locator("html")).toHaveAttribute("data-theme-effective", theme);

          const rows = page.getByTestId("posture-row");
          const details = page.locator("details.ops-schema-health");
          const firstDetails = details.first();
          const firstSummary = firstDetails.locator("summary.ops-schema-health__summary");
          const firstBody = firstDetails.locator(".ops-schema-health__details");
          const metrics = page.locator(".ops-metric");
          const capture = async (state: string) => {
            await page.evaluate(() => window.scrollTo(0, 0));
            const path = info.outputPath(`${state}.png`);
            await page.screenshot({ path, fullPage: true });
            await info.attach(state, { path, contentType: "image/png" });
            expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(width);
          };

          await expect(page.getByRole("heading", { name: "Per-schema health", exact: true })).toBeVisible();
          await expect(page.getByTestId("health-schema-count")).toContainText("2 schemas");
          await expect(metrics).toHaveCount(0);
          await expect(rows).toHaveCount(2);
          await expect(page.locator("details.ops-schema-health[open]")).toHaveCount(0);
          await expect(rows.first().getByTestId("schema-health-status")).toHaveText("No pending or failed work");
          await expect(firstBody).toBeHidden();
          await capture("healthy");

          // Native disclosure works from the keyboard and keeps source evidence available.
          await firstSummary.focus();
          await page.keyboard.press("Enter");
          await expect(firstBody).toBeVisible();
          await expect(firstBody.locator(".ops-time__copy").first()).toBeVisible();
          await expect(firstBody.locator(".ops-signal-metrics dt").filter({ hasText: /^(Pending|Failed|Retrying)$/ })).toHaveCount(0);
          const exactTime = await firstBody.locator(".ops-time__exact").last().textContent();
          const help = firstBody.getByRole("button", { name: "About Queue jobs", exact: true });
          await help.click();
          await expect(page.locator(".ops-help__content:popover-open")).toHaveCount(1);
          await firstSummary.click();
          await expect(firstBody).toBeHidden();
          await expect(page.locator(".ops-help__content:popover-open")).toHaveCount(0);
          await firstSummary.focus();
          await page.keyboard.press("Space");
          await expect(firstBody).toBeVisible();
          await page.keyboard.press("Space");
          await expect(firstBody).toBeHidden();

          await refreshScenario(page, "failed");
          await expect(metrics).toHaveCount(2);
          await expect(page.locator("details.ops-schema-health[open]")).toHaveCount(2);
          await expect(metrics.filter({ hasText: "Failed backend tasks" })).toContainText("2");
          await expect(metrics.filter({ hasText: "Failed queue jobs" })).toContainText("4");
          await expect(metrics.filter({ hasText: "Incomplete checks" })).toHaveCount(0);
          await expect(rows.first().getByTestId("schema-health-status")).toContainText("failed");
          await capture("failed");

          // Retained completion comes from the preceding successful check.
          await refreshScenario(page, "default");
          await expect(metrics).toHaveCount(0);
          await expect(page.locator("details.ops-schema-health[open]")).toHaveCount(0);
          await refreshScenario(page, "queue-error");
          await expect(metrics).toHaveCount(1);
          await expect(metrics).toContainText("Incomplete checks");
          await expect(page.locator("details.ops-schema-health[open]")).toHaveCount(2);
          await expect(rows.first().getByTestId("schema-health-status")).toHaveText("Queue status unavailable");
          const queue = firstBody.locator("[aria-label^='Queue job health']");
          await expect(queue).toContainText("Queue observation unavailable");
          await expect(queue.locator(".ops-signal-metrics")).toHaveCount(0);
          await expect(queue.locator(".ops-time__exact")).toHaveText(exactTime!);
          await capture("unavailable");

          await refreshScenario(page, "retrying");
          await expect(metrics).toHaveCount(0);
          await expect(page.locator("details.ops-schema-health[open]")).toHaveCount(2);
          await expect(rows.first().getByTestId("schema-health-status")).toHaveText("2 queue jobs retrying");
          await expect(queue.locator(".ops-signal-metrics")).toContainText(/Retrying\s*2/);

          await refreshScenario(page, "no-success");
          await expect(metrics).toHaveCount(0);
          await expect(page.locator("details.ops-schema-health[open]")).toHaveCount(2);
          await expect(rows.first().getByTestId("schema-health-status")).toHaveText("1 backend task pending");
          await expect(firstBody).toContainText("No success observed");

          await refreshScenario(page, "manual");
          await expect(metrics).toHaveCount(0);
          await expect(page.locator("details.ops-schema-health[open]")).toHaveCount(0);
          await firstSummary.click();
          await expect(queue).toContainText("Queue not used in manual sync mode.");
          await expect(rows.first().getByTestId("schema-health-status")).not.toContainText("unavailable");

          await refreshScenario(page, "empty");
          await expect(page.getByText("No schemas configured", { exact: true })).toBeVisible();
          await expect(rows).toHaveCount(0);
          await expect(metrics).toHaveCount(0);
          expect(errors).toEqual([]);
        });
      }
    });
  }
}
