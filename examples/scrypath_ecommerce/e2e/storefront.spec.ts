import { expect, test } from "@playwright/test";

import {
  deleteProduct,
  drainSearchQueue,
  renameCategory,
  seedScenario,
  waitForSearchHidden,
  waitForSearchVisible
} from "./helpers/e2e";

test("consumer can search and facet deterministic catalog results", async ({ page, request }) => {
  const seed = await seedScenario(request, "e2e_search_catalog");

  await drainSearchQueue(request);

  await waitForSearchVisible(request, {
    tenantId: seed.tenant_id,
    query: "quantum",
    expectedName: "Quantum CyberPhone X"
  });

  await waitForSearchVisible(request, {
    tenantId: seed.tenant_id,
    query: "quantum",
    expectedName: "Quantum CyberPhone Pro"
  });

  await page.goto(`/?tenant_id=${seed.tenant_id}`);

  await page.getByLabel("Search products").fill("quantum");
  // The search input is debounced; wait for the query to land in the URL before the next
  // interaction so a still-pending change can't race the facet click back to browse mode.
  await expect(page).toHaveURL(/[?&]q=quantum/);

  const results = page.getByTestId("storefront-results");

  await expect(results.getByText("Quantum CyberPhone X")).toBeVisible();
  await expect(results.getByText("Quantum CyberPhone Pro")).toBeVisible();

  const smartphoneCategoryId = seed.categories["Smartphones"];

  await page
    .locator(`input[type='checkbox'][name='search[category_id]'][value='${smartphoneCategoryId}']`)
    .check();
  await expect(page).toHaveURL(new RegExp(`category_id=${smartphoneCategoryId}`));

  await expect(results.getByText("Quantum CyberPhone X")).toBeVisible();
  await expect(results.getByText("Quantum CyberPhone Pro")).toBeVisible();
  await expect(results.getByText("Nebula Ultrabook")).not.toBeVisible();
});

test("tenant guard prevents cross-tenant catalog leakage", async ({ page, request }) => {
  const seed = await seedScenario(request, "e2e_search_catalog");

  await drainSearchQueue(request);

  await waitForSearchVisible(request, {
    tenantId: seed.tenant_id,
    query: "quantum",
    expectedName: "Quantum CyberPhone X"
  });

  await page.goto("/");

  const tenant = page.getByLabel("Tenant");
  await tenant.selectOption(String(seed.tenant_id));
  await page.getByLabel("Search products").fill("quantum");
  // Let the debounced query commit before switching tenants below.
  await expect(page).toHaveURL(/[?&]q=quantum/);

  const results = page.getByTestId("storefront-results");
  await expect(results.getByText("Quantum CyberPhone X")).toBeVisible();

  const otherOption = await tenant
    .locator("option")
    .evaluateAll((options, activeTenantId) => {
      const match = options.find((option) => option.getAttribute("value") !== activeTenantId);
      return match?.getAttribute("value") ?? null;
    }, String(seed.tenant_id));

  expect(otherOption).toBeTruthy();

  // Switching the tenant re-runs the (already "quantum") search for the other tenant.
  // Wait for the tenant change to land in the URL — a redundant re-fill here would race the
  // debounced input and revert the active tenant before the assertion.
  await tenant.selectOption(otherOption!);
  await expect(page).toHaveURL(new RegExp(`tenant_id=${otherOption}`));

  await expect(results.getByText("Quantum CyberPhone X")).not.toBeVisible();
});

test("related category changes become visible in storefront search", async ({ page, request }) => {
  const seed = await seedScenario(request, "e2e_search_catalog");
  const smartphoneCategoryId = seed.categories["Smartphones"];

  await drainSearchQueue(request);

  await renameCategory(request, {
    tenantId: seed.tenant_id,
    categoryId: smartphoneCategoryId,
    name: "Pocket Superphones"
  });

  await drainSearchQueue(request);

  await waitForSearchVisible(request, {
    tenantId: seed.tenant_id,
    query: "quantum",
    expectedName: "Quantum CyberPhone X"
  });

  await page.goto(`/?tenant_id=${seed.tenant_id}&q=quantum`);

  const results = page.getByTestId("storefront-results");

  await expect(results.getByText("Quantum CyberPhone X")).toBeVisible();
  await expect(results.getByText("Quantum CyberPhone Pro")).toBeVisible();
  await expect(results).toContainText("Pocket Superphones");
});

test("deleted products leave the visible search index", async ({ page, request }) => {
  const seed = await seedScenario(request, "e2e_search_catalog");
  const productId = seed.products["Quantum CyberPhone Pro"];

  await drainSearchQueue(request);

  await waitForSearchVisible(request, {
    tenantId: seed.tenant_id,
    query: "quantum",
    expectedName: "Quantum CyberPhone Pro"
  });

  await deleteProduct(request, {
    tenantId: seed.tenant_id,
    productId
  });

  await drainSearchQueue(request);

  await waitForSearchHidden(request, {
    tenantId: seed.tenant_id,
    query: "quantum",
    hiddenName: "Quantum CyberPhone Pro"
  });

  await page.goto(`/?tenant_id=${seed.tenant_id}&q=quantum`);

  const results = page.getByTestId("storefront-results");
  await expect(results.getByText("Quantum CyberPhone X")).toBeVisible();
  await expect(results.getByText("Quantum CyberPhone Pro")).not.toBeVisible();
});

test("empty searches show a useful zero-results state", async ({ page, request }) => {
  const seed = await seedScenario(request, "e2e_search_catalog");

  await drainSearchQueue(request);

  await page.goto(`/?tenant_id=${seed.tenant_id}&q=does-not-exist-zzzz`);

  const results = page.getByTestId("storefront-results");
  await expect(results.getByText("No matching results yet")).toBeVisible();
  await expect(results).toContainText("Adjust query or filters");
});
