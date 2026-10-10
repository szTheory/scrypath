import { expect, test } from "@playwright/test";

const standalone = process.env.PHASE174_OPS_BASE_URL ?? "http://ops:4003/ops/phase174";

for (const entry of ["mounted", "standalone"] as const) {
  for (const width of [1440, 390]) {
    test.describe(`${entry} health metric help at ${width}px`, () => {
      test.use({ viewport: { width, height: 900 }, hasTouch: width === 390 });

      for (const theme of ["light", "dark"] as const) {
        test(`explains terms on hover, focus, and tap in ${theme}`, async ({ page }, info) => {
          const errors: string[] = [];
          page.on("pageerror", (error) => errors.push(error.message));
          await page.goto(entry === "mounted" ? "/admin/search/health" : `${standalone}/health`);
          await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
          await page.locator(`#theme-toggle [data-phx-theme='${theme}']`).click();
          await expect(page.locator("html")).toHaveAttribute("data-theme-effective", theme);
          const trigger = page.getByRole("button", { name: "About Schemas", exact: true });
          const explanation = page.locator("#health-schemas-help-content");
          await expect(explanation).toBeHidden();
          await expect(trigger).toHaveAttribute("aria-describedby", "health-schemas-help-content");

          if (width === 1440) {
            await trigger.hover();
            await expect(explanation).toBeVisible();
            await explanation.hover();
            await page.waitForTimeout(200); // Exceeds the pointer gap grace period.
            await expect(explanation).toBeVisible();
            await page.keyboard.press("Escape");
            await expect(explanation).toBeHidden();
            await page.mouse.move(0, 0);
          } else {
            await trigger.tap();
            await expect(explanation).toBeVisible();
            await trigger.tap();
            await expect(explanation).toBeHidden();
            await trigger.tap();
            await expect(explanation).toBeVisible();
            await page.getByRole("heading", { name: "Search health", exact: true }).tap();
            await expect(explanation).toBeHidden();
          }

          await trigger.evaluate((element: HTMLElement) => element.blur());
          await trigger.focus();
          await expect(explanation).toBeVisible();
          await expect(trigger).toHaveAttribute("aria-expanded", "true");
          await expect(explanation).toContainText("usually stored in a database");
          const geometry = await explanation.boundingBox();
          expect(geometry).not.toBeNull();
          expect(geometry!.x).toBeGreaterThanOrEqual(0);
          expect(geometry!.x + geometry!.width).toBeLessThanOrEqual(width);
          expect(geometry!.y).toBeGreaterThanOrEqual(0);
          expect(geometry!.y + geometry!.height).toBeLessThanOrEqual(900);
          const capture = info.outputPath("health-help.png");
          await page.screenshot({ path: capture, fullPage: true });
          await info.attach("health-help", { path: capture, contentType: "image/png" });
          await page.keyboard.press("Escape");
          await expect(explanation).toBeHidden();
          await expect(trigger).toBeFocused();
          await page.keyboard.press("Enter");
          await expect(explanation).toBeVisible();
          await page.keyboard.press("Tab");
          await expect(explanation).toBeHidden();

          await page.getByRole("button", { name: "Refresh search health", exact: true }).click();
          await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
          await trigger.click();
          await expect(explanation).toBeVisible();
          const firstRow = page.getByTestId("posture-row").first();
          if (!(await firstRow.locator("details.ops-schema-health").evaluate((node: HTMLDetailsElement) => node.open))) {
            await firstRow.locator("summary.ops-schema-health__summary").click();
          }
          const syncAction = firstRow.getByTestId("posture-sync-link");
          if (await syncAction.count()) await syncAction.click();
          else await firstRow.getByTestId("posture-failed-sync-link").click();
          await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
          await expect(page.locator(".ops-help__content:popover-open")).toHaveCount(0);
          expect(errors).toEqual([]);
        });
      }
    });
  }
}
