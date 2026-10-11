import { test, expect } from "@playwright/test";

test("harness configuration is discoverable", async () => {
  expect(1 + 1).toBe(2);
});

test("showcase navigation exposes storefront and operator surfaces", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { name: "Tenant-scoped catalog search" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Search health" })).toBeVisible();

  await page.goto("/admin/search/health");
  await expect(page.getByRole("heading", { name: "Search health", exact: true })).toBeVisible();

  await page.goto("/admin/search/failed-sync");
  await expect(page.getByRole("heading", { name: "Failed sync work" })).toBeVisible();

  await page.goto("/admin/search/sync-drift");
  await expect(page.getByRole("heading", { name: "Sync and drift", exact: true })).toBeVisible();

  await page.goto("/admin/search/search");
  await expect(page.getByRole("heading", { name: "Search", exact: true })).toBeVisible();

  await page.goto("/admin/search/playbooks");
  await expect(page.getByRole("heading", { name: "Saved playbooks" })).toBeVisible();
});
