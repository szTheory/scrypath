import { expect, test } from "@playwright/test";
import { openManageSavedSearches, pickSavedSearch, saveCurrentSearch, seedScenario, waitForLiveConnected } from "./helpers/e2e";

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
  const name = `ui-baseline-${Date.now()}`;
  await saveCurrentSearch(page, name);
  await expect(page.getByText(`Saved “${name}”.`, { exact: true })).toBeVisible();
  // A fresh visit: picking the saved search fills the form and runs it.
  await page.goto("/admin/search/search");
  await waitForLiveConnected(page);
  await expect(page.locator("#search_q")).toHaveValue("");
  await pickSavedSearch(page, name);
  await expect(page.locator("#search_q")).toHaveValue("quantum");
  await expect(page.getByRole("radio", { name: /Product/ })).toBeChecked();
  await expect(page.locator("#search-run-attribution")).toHaveAttribute("data-query", "quantum");
  await expect(page.getByTestId("search-outcome")).toContainText(/results? shown/i);
  // Editing the inputs keeps the results attributed to the run and offers Save / Save as.
  await page.getByLabel("Search text").fill("edited draft");
  await expect(page.locator("#search-run-attribution")).toBeVisible();
  await expect(page.locator("#search-run-attribution")).toContainText("quantum");
  await expect(page.locator("#search-save-loaded")).toBeVisible();
  await expect(page.locator("#search-save-as")).toBeVisible();
});

test("settings load automatically, show declared/live values and follow a real selection change", async ({ page, request }) => {
  await seedScenario(request, "incident");
  await page.goto("/admin/search/sync-and-index");
  await waitForLiveConnected(page);
  await expect(page.getByText("Meilisearch settings differ from the schema", { exact: true })).toBeVisible();
  const table = page.getByRole("table");
  await expect(table.getByRole("columnheader", { name: "Declared in schema" })).toBeVisible();
  await expect(table.getByRole("columnheader", { name: "Live in Meilisearch" })).toBeVisible();
  await expect(table).toContainText("Filterable attributes");
  await expect(page.locator("#document-freshness-result")).toHaveCount(0);
  await page.getByRole("radio", { name: /Variant/ }).check();
  await expect(page).toHaveURL(/schema=ScrypathEcommerce.Catalog.Variant/);
  await expect(page.getByText("Meilisearch settings match the schema.", { exact: true })).toBeVisible();
  await expect(page.getByRole("table")).toHaveCount(0);
  await expect(page.getByText("ecommerce__variant", { exact: true }).first()).toBeVisible();
  await page.getByRole("button", { name: "Refresh sync and index settings" }).click();
  await expect(page.getByText("Meilisearch settings match the schema.", { exact: true })).toBeVisible();
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
  await expect(page.getByRole("link", { name: /Check sync and index/ })).toHaveAttribute("href", /schema=ScrypathEcommerce.Catalog.Variant/);
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
  await page.getByRole("combobox", { name: "Show times in" }).selectOption("local");
  await expect(time).toContainText(/13:02:05|1:02:05/);
  await expect(time).toContainText("EDT");
  await page.reload();
  await waitForLiveConnected(page);
  await expect(page.getByRole("combobox", { name: "Show times in" })).toHaveValue("local");
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

test("a saved search with options the form can't show runs as saved and lists its inputs", async ({ page }) => {
  const name = `ui-baseline-filter-${Date.now()}`;
  const sheet = await openManageSavedSearches(page);
  await sheet.getByText("Paste JSON instead", { exact: true }).click();
  await sheet.getByLabel("Name", { exact: true }).fill(name);
  await sheet.locator("#saved-search-paste-json").fill(JSON.stringify({
    playbook_format: 1, mode: "search", schema: "ScrypathEcommerce.Catalog.Product", q: "quantum", opts: { filter: { missing_filterable_field: "example" } }
  }));
  await sheet.getByRole("button", { name: "Import", exact: true }).click();
  const row = sheet.locator(".ops-saved-search-row").filter({ hasText: name });
  await expect(row).toBeVisible();
  await row.getByRole("button", { name: `Load ${name}` }).click();
  await expect(sheet).toBeHidden();
  const inputs = page.locator("#search-stored-inputs");
  await expect(inputs).toContainText("Inputs used for these results");
  await expect(inputs).toContainText("missing_filterable_field");
  await expect(page.locator("#search-results-heading")).toBeVisible();
  await expect(page.locator("#search-save-loaded")).toHaveCount(0);
  await page.locator("#saved-search-manage-open").click();
  const reopened = page.getByRole("dialog", { name: "Manage saved searches" });
  await reopened.getByRole("button", { name: `Delete ${name}` }).click();
  await reopened.locator("#saved-search-delete-input").fill(name);
  await reopened.getByRole("button", { name: "Delete", exact: true }).click();
  await expect(reopened.locator(".ops-saved-search-row").filter({ hasText: name })).toHaveCount(0);
});


test("saved-search rows keep readable text above actions on compact screens", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  const sheet = await openManageSavedSearches(page);
  const row = sheet.locator(".ops-saved-search-row").first();
  const title = row.locator(".ops-saved-search-row__name");
  const load = row.getByRole("button", { name: /^Load / });
  const titleBox = (await title.boundingBox())!;
  const loadBox = (await load.boundingBox())!;
  expect(titleBox.width, "title uses the readable row width").toBeGreaterThan(250);
  expect(loadBox.y, "actions follow title and metadata").toBeGreaterThan(titleBox.y + titleBox.height);
  expect(loadBox.height, "row actions keep a 24px target").toBeGreaterThanOrEqual(24);
  const panel = (await sheet.locator(".ops-sheet__panel").boundingBox())!;
  expect(panel.width, "the sheet spans the phone width").toBeGreaterThanOrEqual(388);
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
