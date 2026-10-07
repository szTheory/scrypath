import { expect, test, type Page, type TestInfo } from "@playwright/test";
import { mkdir } from "node:fs/promises";
import { join } from "node:path";
import { prepareRecoveryFixture, seedScenario, waitForLiveConnected } from "./helpers/e2e";
import { assertOperatorGeometry, assertReadableControl } from "./helpers/operator-ui";

const standalone = process.env.PHASE174_OPS_BASE_URL ?? "http://ops:4003/ops/phase174";
const captureRoot = "test-results/phase174-captures";
const widths = [1440, 1280, 1279, 390] as const;
const themes = ["light", "dark"] as const;

test("mounted palette recovery destinations follow the selected schema", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto("/admin/search?schema=ScrypathEcommerce.Catalog.Product");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Control Room" })).toBeVisible();
  await page.getByRole("link", { name: /Review Search health/ }).click();
  await waitForLiveConnected(page);
  await page.getByRole("link", { name: "View failed sync work for ScrypathEcommerce.Catalog.Product", exact: true }).click();
  await waitForLiveConnected(page);
  await expect(page.locator("#ops-page-title")).toHaveText("Failed sync work");
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Product/);

  await page.locator(".ops-schema-picker__option").filter({ hasText: "Variant" }).click();
  await waitForLiveConnected(page);
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Variant/);
  const failedSyncHref = await page.locator("#ops-cmdk-item-2").getAttribute("href");
  expect(failedSyncHref, "the rendered Failed sync work destination carries the selected Variant target")
    .toContain("schema=ScrypathEcommerce.Catalog.Variant");
});

test("standalone palette manifest follows the validated fixture schema", async ({ page }, info) => {
  const schemaA = "ScrypathOps.Test.OpsPostA";
  const schemaB = "ScrypathOps.Test.OpsPostB";
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto(`${standalone}/failed-sync?scenario=a-selected-b-worse&schema=${schemaA}`);
  await waitForLiveConnected(page);
  await page.getByRole("radio", { name: /OpsPostB/ }).check();
  await waitForLiveConnected(page);
  await expect(page).toHaveURL(new RegExp(`schema=${schemaB.replaceAll(".", "\\.")}`));
  await expect(page.getByRole("radio", { name: /OpsPostB/ })).toBeChecked();

  const observed = {
    selectedSchema: new URL(page.url()).searchParams.get("schema"),
    manifestTarget: await page.locator("#ops-command-palette-destinations").getAttribute("data-recovery-target"),
    manifestHealthHref: await page.locator("#ops-palette-destination-health").getAttribute("href"),
    paletteHealthHref: await page.locator("#ops-cmdk-item-1").getAttribute("href")
  };
  info.annotations.push({ type: "phase174-standalone-palette-state", description: JSON.stringify(observed) });
  expect(observed).toEqual({
    selectedSchema: schemaB,
    manifestTarget: schemaB,
    manifestHealthHref: expect.stringContaining(`schema=${schemaB}`),
    paletteHealthHref: expect.stringContaining(`schema=${schemaB}`)
  });
});

async function capture(page: Page, info: TestInfo, entry: string, surface: string, width: number, theme: string) {
  await mkdir(captureRoot, { recursive: true });
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.screenshot({ path: join(captureRoot, `${entry}-${surface}-${width}-${theme}.png`), fullPage: true });
  info.annotations.push({ type: "phase174-capture", description: `${entry}/${surface}/${width}/${theme}` });
}

async function assertNoPageOverflow(page: Page, label: string) {
  const dimensions = await page.evaluate(() => ({
    viewport: document.documentElement.clientWidth,
    scroll: document.documentElement.scrollWidth
  }));
  expect(dimensions.scroll, `${label} has no page-level horizontal overflow`).toBeLessThanOrEqual(dimensions.viewport + 1);
}

async function assertEssentialGeometry(page: Page, label: string) {
  await assertOperatorGeometry(page, label, ["[data-ops-command-open]", "#theme-toggle"]);
  await assertReadableControl(page.locator(".text-ops-body").first(), `${label} essential body text`, 14);
  await assertReadableControl(page.locator("[data-ops-command-open]"), `${label} standard command target`, 14, 40);
  await assertReadableControl(page.locator("#theme-toggle button").first(), `${label} standard theme target`, 14, 40);
}

async function assertAssetRequests(page: Page) {
  const statuses = await page.evaluate(async () => {
    const urls = [
      ...Array.from(document.querySelectorAll<HTMLLinkElement>('link[rel="stylesheet"]'), (node) => node.href),
      ...Array.from(document.querySelectorAll<HTMLScriptElement>("script[src]"), (node) => node.src)
    ].filter((url) => url.includes("/assets/"));
    return Promise.all(urls.map(async (url) => (await fetch(url, { method: "HEAD" })).status));
  });
  expect(statuses.length, "production CSS and JS assets are linked").toBeGreaterThanOrEqual(2);
  expect(statuses).toEqual(statuses.map(() => 200));
}

async function exerciseThemeAndPalette(page: Page, base: string) {
  await expect(page.locator("#theme-toggle")).toBeVisible();
  const standalonePage = base.includes("phase174");
  const schemaA = standalonePage ? "ScrypathOps.Test.OpsPostA" : "ScrypathEcommerce.Catalog.Product";
  const schemaB = standalonePage ? "ScrypathOps.Test.OpsPostB" : "ScrypathEcommerce.Catalog.Variant";
  const scenario = standalonePage ? "scenario=no-success&" : "";
  await page.goto(`${base}/failed-sync?${scenario}schema=${schemaA}`);
  await waitForLiveConnected(page);
  await page.locator(".ops-schema-picker__option").filter({ hasText: schemaB.split(".").at(-1)! }).click();
  await waitForLiveConnected(page);
  await expect(page).toHaveURL(new RegExp(`schema=${schemaB.replaceAll(".", "\\.")}`));
  for (const item of ["1", "2", "3"]) {
    const recoveryDestination = page.locator(`#ops-cmdk-item-${item}`);
    await expect(recoveryDestination, `rendered recovery destination ${item} carries the selected ${schemaB} target`)
      .toHaveAttribute("href", new RegExp(`schema=${schemaB.replaceAll(".", "\\.")}`));
  }

  await page.locator("[data-ops-command-open]").focus();
  await page.keyboard.press("Control+k");
  const input = page.locator("#ops-cmdk [data-cmdk-input]");
  await expect(input).toBeFocused();
  await page.keyboard.press("Escape");
  await expect(page.locator("#ops-cmdk")).toBeHidden();
  await expect(page.locator("[data-ops-command-open]")).toBeFocused();

  for (const theme of themes) {
    await page.locator(`#theme-toggle [data-phx-theme="${theme}"]`).click();
    await expect(page.locator("html")).toHaveAttribute("data-theme-preference", theme);
    await expect(page.locator("html")).toHaveAttribute("data-theme", theme);
  }
  await page.locator('#theme-toggle [data-phx-theme="system"]').click();
  await expect(page.locator("html")).toHaveAttribute("data-theme-preference", "system");
}

test("mounted app selects non-first A while Product remains the worse posture and accepts a scoped retry", async ({ page, request }, info) => {
  test.setTimeout(120_000);
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.emulateMedia({ colorScheme: "light", reducedMotion: "reduce" });
  const seed = await seedScenario(request, "incident");
  expect(seed.tenant_id).not.toBeNull();
  const marker = `phase174-${crypto.randomUUID().replaceAll("-", "")}`;
  const fixture = await prepareRecoveryFixture(request, { tenantId: seed.tenant_id!, marker });
  expect(fixture.schema).toBe("Elixir.ScrypathEcommerce.Catalog.Variant");

  await page.goto("/admin/search");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Control Room" })).toBeVisible();
  await page.getByRole("link", { name: /Review Search health/ }).click();
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Search health", exact: true })).toBeVisible();
  const rows = page.getByTestId("posture-row");
  await expect(rows.first()).toContainText("Product");
  await expect(rows.first()).toContainText("failed");
  const handoff = page.getByRole("link", { name: "View failed sync work for ScrypathEcommerce.Catalog.Variant", exact: true });
  await expect(handoff).toBeVisible();
  await handoff.click();
  await waitForLiveConnected(page);
  await expect(page.locator("#ops-page-title")).toHaveText("Failed sync work");
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Variant/);
  const original = page.getByTestId("failed-sync-row").filter({ hasText: `Queue job ${fixture.original_job_id}` });
  await expect(original).toBeVisible();
  const mountedRetry = original.getByTestId("failed-sync-retry");
  await expect(mountedRetry).toBeVisible();
  await assertReadableControl(mountedRetry, "mounted standard retry action", 14, 40);
  await mountedRetry.click();
  const receipt = original.getByTestId("recovery-receipt");
  await expect(receipt).toBeVisible();
  await expect(receipt).toContainText(`Original Queue job ${fixture.original_job_id} failure retained`);
  await expect(receipt).toContainText("Terminal completion has not been observed");
  const href = await receipt.getByRole("link", { name: "Check sync status" }).getAttribute("href");
  expect(href).toContain("Variant");
  info.annotations.push({ type: "phase174-mounted-receipt", description: JSON.stringify({ original: fixture.original_job_id, schema: fixture.schema, href }) });
  await assertAssetRequests(page);

  await page.goBack();
  await expect(page).toHaveURL(/health/);
  await page.reload();
  await expect(page.getByRole("heading", { name: "Search health", exact: true })).toBeVisible();
  await page.goto("/admin/search/failed-sync?schema=NoSuchSchema");
  await expect(page.getByText(/unavailable|allowlisted/i).first()).toBeVisible();
  await expect(page.getByTestId("failed-sync-retry")).toHaveCount(0);

  // Capture final mounted production pages at every approved width and appearance.
  for (const width of widths) {
    await page.setViewportSize({ width, height: 900 });
    for (const theme of themes) {
      await page.emulateMedia({ colorScheme: theme, reducedMotion: "reduce" });
      await page.goto("/admin/search");
      await expect(page.getByRole("heading", { name: "Control Room" })).toBeVisible();
      await assertNoPageOverflow(page, `mounted control room ${width}/${theme}`);
      await assertEssentialGeometry(page, `mounted control room ${width}/${theme}`);
      await capture(page, info, "mounted", "control-room", width, theme);
      await page.goto("/admin/search/health");
      await expect(page.getByRole("heading", { name: "Search health", exact: true })).toBeVisible();
      await assertNoPageOverflow(page, `mounted health ${width}/${theme}`);
      await assertEssentialGeometry(page, `mounted health ${width}/${theme}`);
      await capture(page, info, "mounted", "health", width, theme);
      await page.goto("/admin/search/failed-sync?schema=ScrypathEcommerce.Catalog.Variant");
      await expect(page.locator("#ops-page-title")).toHaveText("Failed sync work");
      await assertNoPageOverflow(page, `mounted failed sync ${width}/${theme}`);
      await assertEssentialGeometry(page, `mounted failed sync ${width}/${theme}`);
      await capture(page, info, "mounted", "failed-sync", width, theme);
    }
  }
  await exerciseThemeAndPalette(page, "/admin/search");
});

test("standalone Ops routes preserve Gating return state, palette patches, focus and responsive captures", async ({ page }, info) => {
  test.setTimeout(120_000);
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.emulateMedia({ colorScheme: "dark" });
  await page.goto(`${standalone}/health`);
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Search health", exact: true })).toBeVisible();
  await expect(page.locator('[id="posture-ScrypathOps.Test.OpsPostA"]')).toBeVisible();
  await expect(page.locator('[id="posture-ScrypathOps.Test.OpsPostB"]')).toBeVisible();
  await expect(page.locator("#ops-cmdk [data-cmdk-item]").first()).toHaveAttribute("href", /phase174/);
  await assertAssetRequests(page);
  await exerciseThemeAndPalette(page, standalone);
  await page.goto(`${standalone}/failed-sync?scenario=no-success&schema=ScrypathOps.Test.OpsPostA`);
  await waitForLiveConnected(page);
  await expect(page.locator("#ops-page-title")).toHaveText("Failed sync work");
  const row = page.getByTestId("failed-sync-row").first();
  await expect(row).toBeVisible();
  const retry = row.getByTestId("failed-sync-retry");
  await expect(retry).toBeVisible();
  await assertReadableControl(retry, "standalone standard retry action", 14, 40);
  await retry.click();
  await expect(page).toHaveURL(/sudo\/confirm/);
  const returnTo = new URL(page.url()).searchParams.get("return_to");
  expect(returnTo).toContain("/ops/phase174/failed-sync");
  expect(returnTo).toContain("OpsPostA");
  await page.goto(new URL(returnTo!, page.url()).toString());
  await waitForLiveConnected(page);
  await expect(page.locator("#ops-page-title")).toHaveText("Failed sync work");
  await expect(page.getByTestId("failed-sync-retry")).toHaveCount(0);
  await expect(page.getByTestId("recovery-receipt")).toHaveCount(0);
  // Returning after confirmation did not replay the retry. A fresh deliberate
  // action on the still-failed source-collision fixture must cross Gating again.
  await page.goto(`${standalone}/failed-sync?scenario=no-success&schema=ScrypathOps.Test.OpsPostA`);
  await waitForLiveConnected(page);
  await expect(page.getByTestId("failed-sync-retry").first()).toBeVisible();
  await page.getByTestId("failed-sync-retry").first().click();
  await expect(page).toHaveURL(/sudo\/confirm/);
  info.annotations.push({ type: "phase174-gating", description: "Real standalone interruption; return preserved validated schema and did not replay; second explicit click re-entered the gate. No host approval performed." });
  for (const width of widths) {
    await page.setViewportSize({ width, height: 900 });
    for (const theme of themes) {
      await page.emulateMedia({ colorScheme: theme, reducedMotion: "reduce" });
      for (const surface of ["health", "failed-sync"] as const) {
        const target = surface === "health"
          ? `${standalone}/health?scenario=a-selected-b-worse&schema=ScrypathOps.Test.OpsPostA`
          : `${standalone}/failed-sync?scenario=no-success&schema=ScrypathOps.Test.OpsPostA`;
        await page.goto(target);
        await expect(page.locator(".ops-shell")).toBeVisible();
        await assertNoPageOverflow(page, `standalone ${surface} ${width}/${theme}`);
        await assertEssentialGeometry(page, `standalone ${surface} ${width}/${theme}`);
        await capture(page, info, "standalone", surface, width, theme);
      }
      await page.goto(standalone);
      await expect(page.getByRole("heading", { name: "Control Room" })).toBeVisible();
      await assertNoPageOverflow(page, `standalone control room ${width}/${theme}`);
      await assertEssentialGeometry(page, `standalone control room ${width}/${theme}`);
      await capture(page, info, "standalone", "control-room", width, theme);
    }
  }
});
