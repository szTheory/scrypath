import { test, expect } from "@playwright/test";

test("harness configuration is discoverable", async () => {
  expect(1 + 1).toBe(2);
});

test("showcase navigation exposes storefront and operator surfaces", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { name: "Tenant-scoped catalog search" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Operator posture" })).toBeVisible();

  await page.goto("/admin/search/posture");
  await expect(page.getByRole("heading", { name: "Posture / health" })).toBeVisible();

  await page.goto("/admin/search/failed-sync");
  await expect(page.getByRole("heading", { name: "Failed sync work" })).toBeVisible();

  await page.goto("/admin/search/sync-drift");
  await expect(page.getByRole("heading", { name: "Sync / drift" })).toBeVisible();

  await page.goto("/admin/search/search");
  await expect(page.getByRole("heading", { name: "Search & federation" })).toBeVisible();

  await page.goto("/admin/search/playbooks");
  await expect(page.getByRole("heading", { name: "Saved playbooks" })).toBeVisible();
});
