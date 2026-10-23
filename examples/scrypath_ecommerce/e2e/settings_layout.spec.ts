import {expect, test} from "@playwright/test";
import {mkdir} from "node:fs/promises";
import AxeBuilder from "@axe-core/playwright";
import {waitForLiveConnected} from "./helpers/e2e";

// Read-only: safe against the retained preview; never seed or change index settings.
const artifacts = "ui-review-artifacts/settings-layout-followup";
test.use({timezoneId: "America/New_York"});

for (const theme of ["light", "dark"]) {
  for (const width of [1440, 768, 390, 320]) {
    test(`settings check in place beside one Checked time: ${theme}, ${width}px`, async ({page}) => {
      await mkdir(artifacts, {recursive: true});
      await page.setViewportSize({width, height: 1000});
      await page.addInitScript(theme => localStorage.setItem("phx:theme", theme), theme);

      // Hold hydration to expose the actual server-rendered placeholder, even on a fast backend.
      let release!: () => void;
      const ready = new Promise<void>(resolve => {release = resolve;});
      await page.routeWebSocket("**/live/websocket**", async socket => {
        await ready;
        socket.connectToServer();
      });
      await page.goto("/admin/search/sync-and-index?schema=ScrypathEcommerce.Catalog.Product");
      const section = page.locator("section").filter({has: page.locator("#index-settings-heading")});
      // Before hydration the settings section says it is still checking, and claims no result.
      await expect(section.locator("#index-settings-checking")).toContainText("Checking Meilisearch settings…");
      await expect(section.locator("#index-settings-status")).toHaveCount(0);
      await expect(page.getByText("Settings checked")).toHaveCount(0);
      const sectionHeight = () => section.evaluate(el => el.getBoundingClientRect().height);
      const pendingHeight = await sectionHeight();
      await section.screenshot({path: `${artifacts}/pending-${theme}-${width}.png`});

      release();
      await waitForLiveConnected(page);
      await expect(section.locator("#index-settings-status")).toBeVisible();
      await expect(section.locator("#index-settings-checking")).toHaveCount(0);
      // One page-level Checked time beside Refresh; no second settings timestamp.
      const refreshRow = page.locator("#sync-and-index-refresh").locator("..");
      await expect(refreshRow.locator(".ops-time__label")).toHaveText("Checked");
      await expect(page.locator(".ops-time__label")).toHaveCount(1);
      const stamp = refreshRow.locator("time");
      const source = await stamp.getAttribute("datetime");
      await page.evaluate(() => Object.defineProperty(navigator, "clipboard", {
        configurable: true,
        value: {writeText: async (text: string) => {(window as any).copiedTimestamp = text;}}
      }));
      await refreshRow.getByRole("button", {name: /Copy timestamp/}).click();
      await expect(page.locator("[data-ops-notification-message]")).toHaveText("Timestamp copied");
      expect(await page.evaluate(() => (window as any).copiedTimestamp)).toBe(source);
      await page.getByRole("combobox", {name: "Show times in"}).selectOption("local");
      await expect(stamp).toContainText(/EDT|EST/);
      if (!(await section.locator(".ops-settings-diff").count())) {
        // A matching result replaces the checking line with one verdict line of similar height.
        expect(Math.abs((await sectionHeight()) - pendingHeight)).toBeLessThan(48);
      }

      const statuses = section.locator(".ops-notice-surface--neutral");
      await expect(statuses).not.toHaveCount(0);
      for (const status of await statuses.all()) {
        const title = await status.locator(".ops-notice-surface__title").boundingBox();
        const body = await status.locator(".ops-notice-surface__body").boundingBox();
        expect(body!.x).toBe(title!.x);
      }
      const differences = section.locator(".ops-settings-diff");
      if (await differences.count()) {
        expect(await differences.evaluate(el => getComputedStyle(el).backgroundImage)).toBe("none");
      }
      expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(width);
      const accessibility = await new AxeBuilder({page}).withTags(["wcag2a", "wcag2aa", "wcag21aa"]).analyze();
      expect(accessibility.violations).toEqual([]);
      await section.screenshot({path: `${artifacts}/loaded-${theme}-${width}.png`});
    });
  }
}
