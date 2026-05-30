import { expect, test } from "@playwright/test";

import { drainSearchQueue, seedScenario, waitForSearchVisible } from "./helpers/e2e";

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

  await page.goto("/");

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
