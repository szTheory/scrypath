import {expect, test} from "@playwright/test";
import {mkdir} from "node:fs/promises";
import AxeBuilder from "@axe-core/playwright";
import {waitForLiveConnected} from "./helpers/e2e";

// Read-only: safe against the retained preview; never seed or change index settings.
const artifacts = "ui-review-artifacts/settings-layout-followup";
test.use({timezoneId: "America/New_York"});

for (const theme of ["light", "dark"]) {
  for (const width of [1440, 768, 390, 320]) {
    test(`settings metadata stays in place and status text aligns: ${theme}, ${width}px`, async ({page}) => {
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
      await page.goto("/admin/search/sync-drift?schema=ScrypathEcommerce.Catalog.Product");
      const section = page.locator("section").filter({has: page.locator("#sync-drift-heading")});
      const metadata = page.locator("#settings-checked-at");
      await expect(metadata).toContainText("Checking…");
      await expect(metadata.getByRole("button")).toHaveCount(0);
      const headerHeight = () => section.locator(":scope > div").first().evaluate(el => el.getBoundingClientRect().height);
      const pendingHeight = await headerHeight();
      await section.screenshot({path: `${artifacts}/pending-${theme}-${width}.png`});

      release();
      await waitForLiveConnected(page);
      await expect(metadata.locator("time")).toBeVisible();
      await expect(metadata.locator(".ops-time__label")).toHaveText("Settings checked");
      expect(await headerHeight()).toBe(pendingHeight);
      await expect(page.locator("#sync-drift-refresh").locator("..")).toContainText("Sync checked");
      const source = await metadata.locator("time").getAttribute("datetime");
      await page.evaluate(() => Object.defineProperty(navigator, "clipboard", {
        configurable: true,
        value: {writeText: async (text: string) => {(window as any).copiedTimestamp = text;}}
      }));
      await metadata.getByRole("button").click();
      await expect(page.locator("[data-ops-notification-message]")).toHaveText("Timestamp copied");
      expect(await page.evaluate(() => (window as any).copiedTimestamp)).toBe(source);
      expect(await headerHeight()).toBe(pendingHeight);
      await page.getByRole("combobox", {name: "Time zone"}).selectOption("local");
      await expect(metadata.locator("time")).toContainText(/EDT|EST/);
      expect(await headerHeight()).toBe(pendingHeight);

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
