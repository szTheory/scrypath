import { test, expect } from "@playwright/test";

test("harness configuration is discoverable", async () => {
  expect(1 + 1).toBe(2);
});

// Phase 187 (SKIN-02): `font-display: swap` hides a missing font behind the fallback face, so a
// font that 404s in a built image looks fine in a screenshot. This request check is what fails
// instead. The stylesheet's font URLs are CSS-relative, so they must resolve to
// `/admin/search/assets/fonts/` here, two path segments below the root.
test("mounted ops fonts load from the mount prefix", async ({ request }) => {
  const cssResponse = await request.get("/admin/search/assets/css/app.css");
  expect(cssResponse.status()).toBe(200);
  const css = await cssResponse.text();

  const relativeUrls = [...css.matchAll(/url\(\s*["']?(\.\.\/fonts\/[^"')]+\.woff2[^"')]*)["']?\s*\)/g)].map(
    (match) => match[1]
  );
  expect(relativeUrls.length, "the stylesheet must request exactly the interface and mono fonts").toBe(2);
  expect(relativeUrls.map((url) => url.split("?")[0]).sort()).toEqual(["../fonts/mono.woff2", "../fonts/ui.woff2"]);

  for (const relative of relativeUrls) {
    const fontUrl = new URL(relative, cssResponse.url());
    expect(fontUrl.pathname).toMatch(/^\/admin\/search\/assets\/fonts\/(ui|mono)\.woff2$/);
    const fontResponse = await request.get(fontUrl.toString());
    expect(fontResponse.status(), `${fontUrl.pathname} must be served`).toBe(200);
    expect(fontResponse.headers()["content-type"]).toMatch(/^font\/woff2/);
    expect((await fontResponse.body()).byteLength).toBeGreaterThan(1000);
  }
});

test("showcase navigation exposes storefront and operator surfaces", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { name: "Tenant-scoped catalog search" })).toBeVisible();
  await expect(
    page.getByRole("navigation", { name: "Demo operator links" }).getByRole("link", { name: "Search health", exact: true })
  ).toBeVisible();

  await page.goto("/admin/search/health");
  await expect(page.getByRole("heading", { name: "Search health", exact: true })).toBeVisible();

  await page.goto("/admin/search/failed-sync");
  await expect(page.getByRole("heading", { name: "Failed sync work" })).toBeVisible();

  await page.goto("/admin/search/sync-and-index");
  await expect(page.getByRole("heading", { name: "Sync and index", exact: true })).toBeVisible();

  await page.goto("/admin/search/search");
  await expect(page.getByRole("heading", { name: "Search", exact: true })).toBeVisible();

  // Old Saved searches links redirect to Search with the Manage sheet open.
  await page.goto("/admin/search/playbooks");
  await expect(page).toHaveURL(/\/admin\/search\/search\?saved=manage$/);
  await expect(page.getByRole("dialog", { name: "Manage saved searches" })).toBeVisible();
});
