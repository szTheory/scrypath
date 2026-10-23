import { expect, test } from "@playwright/test";
import { waitForLiveConnected } from "./helpers/e2e";

// Observation-only regression proof. Never seed or submit recovery/file actions here.
const routes = ["/admin/search/failed-sync", "/admin/search/sync-drift", "/admin/search/search"];

for (const route of routes.slice(0, 2)) {
  test(`unresolved scope never silently selects the first schema — ${route}`, async ({ page }) => {
    await page.goto(`${route}?schema=UnknownSchema`);
    await waitForLiveConnected(page);
    await expect(page.getByRole("radio", { name: /Product/ })).not.toBeChecked();
    await expect(page.getByRole("radio", { name: /Variant/ })).not.toBeChecked();
    await page.getByRole("radio", { name: /Product/ }).check();
    await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Product/);
    await expect(page.getByRole("radio", { name: /Product/ })).toBeChecked();
  });
}
for (const theme of ["light", "dark", "system"] as const) {
  for (const width of [1440, 390]) {
    test(`native schema radios stay visible and select correctly — ${theme} ${width}`, async ({ page }) => {
      await page.setViewportSize({ width, height: 900 });
      await page.emulateMedia({ colorScheme: theme === "light" ? "light" : "dark" });
      await page.addInitScript((value) => {
        if (value === "system") localStorage.removeItem("phx:theme");
        else localStorage.setItem("phx:theme", value);
      }, theme);
      for (const route of routes) {
        await page.goto(route);
        await waitForLiveConnected(page);
        const product = page.getByRole("radio", { name: /Product/ });
        const variant = page.getByRole("radio", { name: /Variant/ });
        await expect(product).toBeVisible();
        await expect(variant).toBeVisible();
        for (const radio of [product, variant]) {
          const size = await radio.boundingBox();
          expect(size?.width).toBeGreaterThanOrEqual(16);
          expect(size?.height).toBeGreaterThanOrEqual(16);
        }
        await variant.check();
        await expect(variant).toBeChecked();
        await expect(product).not.toBeChecked();
        if (!route.endsWith("/search")) {
          await expect(variant).toHaveAttribute("checked", "");
          await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Variant/);
        } else {
          expect(await page.locator("#ops-search-playground-form").evaluate((form) => new FormData(form as HTMLFormElement).get("schema"))).toBe("ScrypathEcommerce.Catalog.Variant");
        }
        await page.mouse.move(0, 0);
        const selectedFill = await variant.evaluate((input) => getComputedStyle(input.closest("label")!).backgroundColor);
        const unselectedFill = await product.evaluate((input) => getComputedStyle(input.closest("label")!).backgroundColor);
        expect(selectedFill).not.toBe(unselectedFill);
        await variant.focus();
        await page.keyboard.press("ArrowUp");
        await expect(product).toBeChecked();
        await expect(variant).not.toBeChecked();
        expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(width);
      }
    });

    test(`shared headers and file actions remain unframed — ${theme} ${width}`, async ({ page }) => {
      await page.setViewportSize({ width, height: 900 });
      await page.emulateMedia({ colorScheme: theme === "light" ? "light" : "dark" });
      await page.addInitScript((value) => {
        if (value === "system") localStorage.removeItem("phx:theme");
        else localStorage.setItem("phx:theme", value);
      }, theme);
      for (const route of ["/admin/search/", "/admin/search/health", ...routes, "/admin/search/playbooks"]) {
        await page.goto(route);
        await waitForLiveConnected(page);
        await expect(page.getByRole("heading", { level: 1 })).toHaveCount(1);
        await expect(page.getByText("Operator workspace", { exact: true })).toHaveCount(0);
      }
      const row = page.locator(".ops-object-item").first();
      await expect(row).toBeVisible();
      expect(await row.evaluate((node) => Boolean(node.closest(".ops-panel")))).toBe(false);
      const disclosure = row.getByTestId("saved-search-manage-actions");
      const framing = await disclosure.evaluate((node) => {
        const style = getComputedStyle(node);
        return { border: style.borderTopWidth, background: style.backgroundColor };
      });
      expect(framing).toEqual({ border: "0px", background: "rgba(0, 0, 0, 0)" });
      for (const action of await row.locator(".ops-action-group").all()) {
        expect(await action.evaluate((node) => getComputedStyle(node).borderTopWidth)).toBe("0px");
        expect(await action.evaluate((node) => getComputedStyle(node).backgroundColor)).toBe("rgba(0, 0, 0, 0)");
      }
      await disclosure.locator("summary").click();
      await expect(disclosure).toHaveAttribute("open", "");
      await expect(disclosure.getByRole("button", { name: /Duplicate/ })).toBeVisible();
      await expect(disclosure.getByRole("button", { name: /Rename/ })).toBeVisible();
      await expect(disclosure.getByRole("button", { name: /Delete/ })).toBeVisible();
      expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(width);
    });
  }
}
