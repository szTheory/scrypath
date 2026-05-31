import { expect, test } from "@playwright/test";

import { drainSearchQueue, renameCategory, seedScenario, waitForSearchVisible } from "./helpers/e2e";

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

  const results = page.getByTestId("storefront-results");

  await expect(results.getByText("Quantum CyberPhone X")).toBeVisible();
  await expect(results.getByText("Quantum CyberPhone Pro")).toBeVisible();

  const smartphoneCategoryId = seed.categories["Smartphones"];

  await page
    .locator(`input[type='checkbox'][name='search[category_id]'][value='${smartphoneCategoryId}']`)
    .check();

  await expect(results.getByText("Quantum CyberPhone X")).toBeVisible();
  await expect(results.getByText("Quantum CyberPhone Pro")).toBeVisible();
  await expect(results.getByText("Nebula Ultrabook")).not.toBeVisible();
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
  await expect(results).toContainText("Category: Pocket Superphones");
});
