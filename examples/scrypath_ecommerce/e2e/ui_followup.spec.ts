import {expect, test} from "@playwright/test";
import {seedScenario, waitForLiveConnected} from "./helpers/e2e";
import {guardVerificationTarget} from "./helpers/verification-target.mjs";

const standalone = process.env.PHASE173_STANDALONE_BASE_URL || "http://127.0.0.1:4014";
const source = "2026-10-04T13:02:05.123456-04:00";

test.beforeEach(async ({baseURL}) => {
  await guardVerificationTarget(baseURL, reason => test.skip(true, reason), async () => {});
});

for (const [name, url] of [["mounted", "/admin/search/phase173/health"], ["standalone", `${standalone}/ops/phase173/health`]]) {
  test(`${name}: copy feedback leaves timestamp and refresh geometry unchanged`, async ({page}) => {
    await page.clock.install();
    await page.goto(url);
    await waitForLiveConnected(page);
    for (const width of [1440, 390]) {
      await page.setViewportSize({width, height: 900});
      const stamp = page.locator(`[data-ops-timestamp-copy='${source}']`);
      const refresh = page.locator("#search-health-refresh");
      const before = [await stamp.boundingBox(), await refresh.boundingBox()];
      await page.evaluate(() => Object.defineProperty(navigator, "clipboard", {configurable: true, value: {writeText: async () => {}}}));
      await stamp.click();
      await expect(page.locator("[data-ops-notification-message]")).toHaveText("Timestamp copied");
      expect([await stamp.boundingBox(), await refresh.boundingBox()]).toEqual(before);
      await expect(stamp).toBeFocused();
      await page.clock.fastForward(4001);
      await expect(page.locator("#ops-client-toast")).toBeHidden();
      expect([await stamp.boundingBox(), await refresh.boundingBox()]).toEqual(before);
      await page.evaluate(() => Object.defineProperty(navigator, "clipboard", {configurable: true, value: {writeText: async () => {throw Error("Denied")}}}));
      await stamp.click();
      await expect(page.locator("[data-ops-notification-source]")).toHaveText(source);
      expect([await stamp.boundingBox(), await refresh.boundingBox()]).toEqual(before);
      await page.locator("#ops-client-toast").getByRole("button", {name: "Close notification"}).click();
      await expect(stamp).toBeFocused();
      const select = page.getByRole("combobox", {name: "Show times in"});
      expect(await select.evaluate(el => parseFloat(getComputedStyle(el).paddingRight))).toBeGreaterThanOrEqual(32);
      expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(width);
    }
  });
}

test("task help stays within the installed mount and explains saved inputs", async ({page}) => {
  await page.goto("/admin/search/help");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", {level: 1})).toHaveText("Help");
  await expect(page.locator(".ops-nav-help a").first()).toHaveAttribute("aria-current", "page");
  await expect(page.locator("#saved-searches")).toContainText("not the results");
  await expect(page.locator("#saved-searches")).not.toContainText("folder");
  await expect(page.getByRole("link", {name: "Manage saved searches", exact: true})).toHaveAttribute("href", "/admin/search/search?saved=manage");
  await expect(page.locator("#ranking")).toContainText("not directly comparable");
  await page.getByRole("link", {name: "Open Search", exact: true}).click();
  await expect(page.getByLabel("Search text")).toBeVisible();
  await expect(page.locator("#search-results-heading")).toHaveCount(0);
});

test("active, backend-failed, retrying and completed observations have distinct useful states", async ({page}) => {
  for (const scenario of ["processing", "backend-failed", "retrying", "completed"]) {
    await page.goto(`/admin/search/phase173/health?scenario=${scenario}`);
    await waitForLiveConnected(page);
    const row = page.getByTestId("posture-row").first();
    await expect(row).toContainText("Schema module");
    await expect(row).toContainText("Meilisearch index");
    const backend = row.getByRole("region", {name: /Backend task signals/});
    const queue = row.getByRole("region", {name: /Queue job signals/});
    if (scenario === "processing") {
      await expect(backend).toContainText("Pending");
      await expect(backend).not.toContainText("No pending or failed tasks.");
      await expect(queue).toContainText("Pending");
      await expect(row.locator("[data-tone=error]")).toHaveCount(0);
    } else if (scenario === "backend-failed") {
      await expect(backend.locator("[data-tone=error]")).toContainText("Failed");
      await expect(queue.locator("[data-tone=error]")).toHaveCount(0);
      await expect(row.getByRole("link", {name: /View failed sync work/})).toBeVisible();
    } else if (scenario === "retrying") {
      await expect(queue.locator("[data-tone=retrying]")).toContainText("Retrying");
    } else {
      await expect(backend).toContainText("No pending or failed tasks.");
      await expect(row.locator("[data-tone=error], [data-tone=warning]")).toHaveCount(0);
    }
  }
});

test("readable results retain submitted criteria, copy exact data and lead to the saved file", async ({page, request}) => {
  await seedScenario(request, "all_green");
  await page.goto("/admin/search/search");
  await waitForLiveConnected(page);
  await page.getByLabel("Search text").fill("quantum");
  await page.getByRole("button", {name: "Run search", exact: true}).click();
  const attribution = page.locator("#search-run-attribution");
  await expect(attribution).toHaveAttribute("data-query", "quantum");
  await expect(attribution).toBeHidden();
  const run = await attribution.getAttribute("data-run-id");
  const firstHit = page.locator(".ops-readable-hit").first();
  await expect(firstHit.locator(".ops-hit-description")).toBeVisible();
  const save = page.locator("#search-save-new");
  expect((await save.boundingBox())!.y).toBeLessThan((await firstHit.boundingBox())!.y);
  await firstHit.getByText("Raw hit payload", {exact: true}).click();
  const raw = await firstHit.locator("pre").textContent();
  expect(raw?.startsWith("%{")).toBeTruthy();
  await page.evaluate(() => {
    (window as any).copied = [];
    Object.defineProperty(navigator, "clipboard", {configurable: true, value: {writeText: async (text: string) => {(window as any).copied.push(text)}}});
  });
  await firstHit.getByRole("button", {name: "Copy hit payload"}).click();
  expect(await page.evaluate(() => (window as any).copied)).toEqual([raw]);
  await page.locator("#ops-client-toast").getByRole("button", {name: "Close notification"}).click();
  await page.getByLabel("Search text").fill("an edited draft");
  await expect(attribution).toBeVisible();
  await expect(attribution).toContainText("quantum");
  await expect(attribution).toHaveAttribute("data-run-id", run!);
  // Save search keeps the inputs in the form (the edited draft), not the last run.
  await page.getByLabel("Search text").fill("quantum");
  await save.click();
  const dialog = page.getByRole("dialog", {name: "Save search"});
  await expect(dialog.getByLabel("Name", {exact: true})).toBeFocused();
  await expect(dialog).toContainText("not the results");
  const name = `ui-followup-${Date.now()}`;
  await dialog.getByLabel("Name", {exact: true}).fill(name);
  await dialog.getByRole("button", {name: "Save", exact: true}).click();
  await expect(page.locator("#saved-search-status")).toContainText(`Loaded “${name}”`);
  await page.locator("#saved-search-manage-open").click();
  const sheet = page.getByRole("dialog", {name: "Manage saved searches"});
  const row = sheet.locator(".ops-saved-search-row").filter({hasText: name});
  await expect(row).toBeVisible();
  const href = await row.getByRole("link", {name: `Export ${name}`}).getAttribute("href");
  const exported = JSON.parse(decodeURIComponent(href!.replace("data:application/json;charset=utf-8,", "")));
  expect(exported.q).toBe("quantum");
});

test("multi-schema result limit applies to the combined response and help is local", async ({page, request}) => {
  await seedScenario(request, "all_green");
  await page.goto("/admin/search/search");
  await waitForLiveConnected(page);
  await page.getByRole("button", {name: "Multiple schemas", exact: true}).click();
  await expect(page.getByRole("link", {name: /^How ordering works/}).first()).toHaveAttribute("href", "/admin/search/help#ranking");
  await page.getByLabel("Results per page", {exact: true}).fill("3");
  await page.getByRole("button", {name: "Run search", exact: true}).click();
  await expect(page.locator("#search-run-attribution")).toHaveAttribute("data-limit", "3");
  await expect(page.locator(".ops-readable-hit")).toHaveCount(3);
  await expect(page.getByText("All selected indexes returned results on this run.", {exact: true})).toHaveCount(0);
  await expect(page.locator("#search-combined-results .ops-readable-hit")).toHaveCount(3);
  await expect(page.locator(".ops-combined-order")).toHaveCount(0);
});

test("generic fields remain readable across compact themes without guessing data types", async ({page}) => {
  await page.goto("/admin/search/ui-fixtures");
  await waitForLiveConnected(page);
  const hit = page.locator("#typed-result-fixture");
  await hit.getByText(/^Fields \(/).click();
  await expect(hit).toContainText("false");
  await expect(hit).toContainText("null");
  await expect(hit).toContainText("custom-key-42");
  await expect(hit).toContainText("0");
  const scalar = hit.locator(".ops-hit-fields > div").filter({has: page.getByText("Inventory count", {exact: true})}).first();
  expect((await scalar.locator("dd").boundingBox())!.height, "scalar values do not preserve template whitespace").toBeLessThan(40);
  for (const theme of ["light", "dark"]) {
    await page.getByRole("button", {name: `Use ${theme} theme`, exact: true}).click();
    await expect(hit.locator(".ops-readable-hit")).toHaveCSS("background-color", "rgba(0, 0, 0, 0)");
    for (const width of [320, 390, 768, 1440]) {
      await page.setViewportSize({width, height: 900});
      expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(width);
    }
  }
});
