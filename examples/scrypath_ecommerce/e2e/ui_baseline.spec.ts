import { expect, test } from "@playwright/test";
import { seedScenario, waitForLiveConnected } from "./helpers/e2e";

// This suite changes only its disposable verifier's catalog/files, never the feedback preview.
test.beforeEach(async ({ baseURL }) => {
  test.skip(!baseURL || (["127.0.0.1", "localhost"].includes(new URL(baseURL).hostname) && new URL(baseURL).port === "4002"), "Use the isolated Docker verifier or a dedicated local port.");
});

test("query → saved inputs → replay keeps results and edited drafts distinct", async ({ page, request }) => {
  await seedScenario(request, "all_green");
  await page.goto("/admin/search/search");
  await waitForLiveConnected(page);
  await page.getByRole("radio", { name: /Product/ }).check();
  await page.getByLabel("Search text").fill("quantum");
  await page.getByRole("button", { name: "Run search", exact: true }).click();
  await expect(page.locator("#search-run-attribution")).toHaveAttribute("data-query", "quantum");
  await expect(page.getByTestId("search-outcome")).toContainText(/results? shown/i);
  await page.getByRole("button", { name: "Save search", exact: true }).first().click();
  const filename = `ui-baseline-${Date.now()}.json`;
  await page.locator("#capture_basename").fill(filename);
  await page.locator("#capture_title").fill("Catalog example");
  await page.locator("#search-capture-form button[type=submit]").click();
  await expect(page.getByText(`Saved search ${filename}.`, { exact: true })).toBeVisible();
  await page.goto("/admin/search/playbooks");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { level: 1 })).toHaveText("Saved searches");
  const row = page.locator(".ops-object-item").filter({ hasText: filename });
  await row.getByRole("button", { name: "Preview", exact: true }).click();
  await expect(page.locator("#saved-search-draft-origin")).toContainText(filename);
  await expect(page.locator("#saved-search-summary")).toContainText("quantum");
  await page.getByRole("button", { name: "Run search", exact: true }).click();
  await expect(page.locator("#saved-search-run-outcome")).toContainText(/completed|returned|result/i);
  await expect(page.locator("#saved-search-run-source")).toContainText(filename);
  await page.getByRole("link", { name: /Explore this query in Search/ }).click();
  await expect(page.locator("#search_q")).toHaveValue("quantum");
  await page.getByRole("button", { name: "Run search", exact: true }).click();
  await expect(page.locator("#search-run-attribution")).toHaveAttribute("data-query", "quantum");
});

test("settings load automatically, show declared/live values and follow a real selection change", async ({ page, request }) => {
  await seedScenario(request, "incident");
  await page.goto("/admin/search/sync-drift");
  await waitForLiveConnected(page);
  await expect(page.getByText("Index settings differ", { exact: true })).toBeVisible();
  const table = page.getByRole("table");
  await expect(table.getByRole("columnheader", { name: "Declared in schema" })).toBeVisible();
  await expect(table.getByRole("columnheader", { name: "Live in Meilisearch" })).toBeVisible();
  await expect(table).toContainText("Filterable attributes");
  await expect(page.locator("#document-freshness-result")).toHaveCount(0);
  await page.getByRole("radio", { name: /Variant/ }).check();
  await expect(page).toHaveURL(/schema=ScrypathEcommerce.Catalog.Variant/);
  await expect(page.getByText("Index settings match", { exact: true })).toBeVisible();
  await expect(page.getByRole("table")).toHaveCount(0);
  await expect(page.getByText("ecommerce__variant", { exact: true }).first()).toBeVisible();
  await page.getByRole("button", { name: "Refresh sync and index settings" }).click();
  await expect(page.getByText("Index settings match", { exact: true })).toBeVisible();
});

test("empty failed work gives one confirmation without zero rollups or a second refresh", async ({ page, request }) => {
  await seedScenario(request, "all_green");
  await page.goto("/admin/search/failed-sync?schema=ScrypathEcommerce.Catalog.Variant");
  await waitForLiveConnected(page);
  await expect(page.getByText("No failed or retrying sync work", { exact: true })).toHaveCount(1);
  await expect(page.getByTestId("failed-sync-empty-hero")).toHaveCount(0);
  await expect(page.getByTestId("failed-sync-row")).toHaveCount(0);
  await expect(page.getByText("dominant reason", { exact: false })).toHaveCount(0);
  await expect(page.getByRole("button", { name: /Refresh/ })).toHaveCount(1);
  await expect(page.getByRole("link", { name: /Check sync and drift/ })).toHaveAttribute("href", /schema=ScrypathEcommerce.Catalog.Variant/);
});

test("shared time preference persists, converts local time and copies exact source precision", async ({ browser }) => {
  const context = await browser.newContext({ timezoneId: "America/New_York", viewport: { width: 390, height: 844 } });
  const page = await context.newPage();
  await page.goto(`${test.info().project.use.baseURL}/admin/search/phase173/health?scenario=healthy`);
  await waitForLiveConnected(page);
  const source = "2026-10-04T13:02:05.123456-04:00";
  const time = page.locator(`[data-ops-timestamp-copy='${source}']`);
  await expect(time).toContainText(/17:02:05|5:02:05/);
  await expect(time).toContainText("UTC");
  await page.getByRole("combobox", { name: "Time zone" }).selectOption("local");
  await expect(time).toContainText(/13:02:05|1:02:05/);
  await expect(time).toContainText("EDT");
  await page.reload();
  await waitForLiveConnected(page);
  await expect(page.getByRole("combobox", { name: "Time zone" })).toHaveValue("local");
  await expect(time).toContainText("EDT");
  await page.evaluate(() => Object.defineProperty(navigator, "clipboard", { configurable: true, value: { writeText: async (value: string) => { (window as any).copiedTime = value; } } }));
  await time.focus();
  await page.keyboard.press("Enter");
  await expect(page.locator("[data-ops-notification-message]")).toHaveText("Timestamp copied");
  expect(await page.evaluate(() => (window as any).copiedTime)).toBe(source);
  await page.evaluate(() => Object.defineProperty(navigator, "clipboard", { configurable: true, value: {} }));
  await time.click();
  await expect(page.locator("[data-ops-notification-source]")).toBeVisible();
  await expect(page.locator("[data-ops-notification-source]")).toHaveText(source);
  await expect(page.locator("[data-ops-notification-message]")).toContainText("Could not copy");
  expect(await time.evaluate(node => getComputedStyle(node).textDecorationLine)).toBe("none");
  expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(390);
  await context.close();
});

test("saved-search errors copy diagnostics only after the browser succeeds", async ({ page }) => {
  await page.goto("/admin/search/playbooks");
  await waitForLiveConnected(page);
  await page.locator("#saved-search-import details > summary").click();
  await page.locator("#saved-search-paste-json").fill(JSON.stringify({
    playbook_format: 1, mode: "search", schema: "ScrypathEcommerce.Catalog.Product", q: "quantum", opts: { filter: { missing_filterable_field: "example" } }
  }));
  await page.locator("#saved-search-import details button[type=submit]").click();
  await page.getByRole("button", { name: "Run search", exact: true }).click();
  const failure = page.getByTestId("run-failure-panel");
  await expect(failure).toBeVisible();
  const copy = failure.getByRole("button", { name: "Copy diagnostics" });
  await page.evaluate(() => Object.defineProperty(navigator, "clipboard", { configurable: true, value: { writeText: () => Promise.reject(new Error("Denied")) } }));
  await copy.click();
  await expect(page.locator("[data-ops-notification-message]")).toContainText("Could not copy");
  await expect(page.locator("[data-ops-notification-source]")).toBeVisible();
  await page.evaluate(() => Object.defineProperty(navigator, "clipboard", { configurable: true, value: { writeText: async (text: string) => { (window as any).copiedDiagnostics = text; } } }));
  await copy.focus(); await page.keyboard.press("Enter");
  await expect(page.locator("[data-ops-notification-message]")).toHaveText("Diagnostics copied");
  expect(JSON.parse(await page.evaluate(() => (window as any).copiedDiagnostics))).toBeTruthy();
});


test("saved-search rows keep readable text above actions on compact screens", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/admin/search/playbooks");
  await waitForLiveConnected(page);
  const row = page.locator(".ops-saved-searches > .ops-object-item").first();
  const title = row.locator("span.font-semibold").first();
  const preview = row.getByRole("button", { name: "Preview", exact: true });
  const titleBox = (await title.boundingBox())!;
  const previewBox = (await preview.boundingBox())!;
  expect(titleBox.width, "title uses the readable row width").toBeGreaterThan(250);
  expect(previewBox.y, "actions follow title and metadata").toBeGreaterThan(titleBox.y + titleBox.height);
  expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(390);
});


test("storefront puts compact results before secondary facets without inventing a zero count", async ({ page, request }) => {
  await seedScenario(request, "incident");
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/");
  await waitForLiveConnected(page);
  await expect(page.getByTestId("storefront-search-unavailable")).toBeVisible();
  await expect(page.getByText("0 visible hits", { exact: true })).toHaveCount(0);
  const results = (await page.getByTestId("storefront-results").boundingBox())!;
  const facets = (await page.locator(".storefront-search__filters").boundingBox())!;
  const query = (await page.getByPlaceholder("Search the catalog").boundingBox())!;
  expect(results.y).toBeGreaterThan(query.y);
  expect(facets.y).toBeGreaterThanOrEqual(results.y + results.height);
});
