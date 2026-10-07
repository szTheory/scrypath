import { expect, test, type Page, type TestInfo } from "@playwright/test";
import { mkdir } from "node:fs/promises";
import { join } from "node:path";
import { prepareRecoveryFixture, seedScenario, waitForLiveConnected as waitForSocketConnected } from "./helpers/e2e";
import { assertOperatorGeometry, assertReadableControl } from "./helpers/operator-ui";

const standalone = process.env.PHASE174_OPS_BASE_URL ?? "http://ops:4003/ops/phase174";
const captureRoot = "test-results/phase174-captures";
const widths = [1440, 1280, 1279, 390] as const;
const themes = ["light", "dark"] as const;

async function waitForLiveConnected(page: Page) {
  await waitForSocketConnected(page);
  // A connected transport can precede the LiveView join and hook mounting.
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
}

function delayNextLiveViewResponse(page: Page) {
  let holdNext = false;
  let heldResolve!: () => void;
  let releasedResolve!: () => void;
  const held = new Promise<void>((resolve) => (heldResolve = resolve));
  const released = new Promise<void>((resolve) => (releasedResolve = resolve));

  page.routeWebSocket(/\/live\/websocket/, (socket) => {
    const server = socket.connectToServer();
    socket.onMessage((message) => server.send(message));
    server.onMessage((message) => {
      if (!holdNext) {
        socket.send(message);
        return;
      }

      holdNext = false;
      heldResolve();
      setTimeout(() => {
        socket.send(message);
        releasedResolve();
      }, 900);
    });
  });

  return { arm: () => (holdNext = true), held, released };
}

test("mounted target selection stays canonical through worse-row navigation and browser history", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto("/admin/search?schema=ScrypathEcommerce.Catalog.Variant");
  await waitForLiveConnected(page);
  await expect(page.getByTestId("shell-recovery-target").first()).toContainText("Catalog.Variant");

  await page.getByRole("link", { name: /Review Search health/ }).click();
  await waitForLiveConnected(page);
  const rows = page.getByTestId("posture-row");
  await expect(rows.first()).toContainText("Catalog.Product");
  await expect(rows.first()).toContainText("failed");
  await expect(page.getByTestId("recovery-target")).toContainText("Catalog.Variant");

  const productHandoff = page.getByRole("link", {
    name: "View failed sync work for ScrypathEcommerce.Catalog.Product",
    exact: true
  });
  await expect(productHandoff).toHaveAttribute("href", /schema=ScrypathEcommerce.Catalog.Product/);
  await productHandoff.click();
  await waitForLiveConnected(page);
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Product/);

  await page.locator(".ops-schema-picker__option").filter({ hasText: "Variant" }).click();
  await waitForLiveConnected(page);
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Variant/);
  await expect(page.getByTestId("shell-recovery-target").first()).toContainText("Catalog.Variant");
  await page.goBack();
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Product/);
  await expect(page.getByTestId("shell-recovery-target").first()).toContainText("Catalog.Product");
  await page.goForward();
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Variant/);
  await page.reload();
  await waitForLiveConnected(page);
  await expect(page.getByTestId("shell-recovery-target").first()).toContainText("Catalog.Variant");

  for (const schema of ["", "ScrypathEcommerce.Catalog.NotAllowlisted"]) {
    await page.goto(`/admin/search/failed-sync?schema=${encodeURIComponent(schema)}`);
    await waitForLiveConnected(page);
    await expect(page.getByText("That schema is unavailable")).toBeVisible();
    await expect(page.getByTestId("failed-sync-row")).toHaveCount(0);
    await expect(page.getByTestId("failed-sync-retry")).toHaveCount(0);
    await expect(page.getByTestId("recovery-target")).toHaveCount(0);
  }

  await page.goto(`${standalone}/failed-sync?scenario=a-removed&schema=ScrypathOps.Test.OpsPostA`);
  await waitForLiveConnected(page);
  await expect(page.getByText("That schema is unavailable")).toBeVisible();
  await expect(page.getByTestId("failed-sync-row")).toHaveCount(0);
  await expect(page.getByTestId("failed-sync-retry")).toHaveCount(0);
});

test("standalone source-collision action eligibility stays with Queue job 501", async ({ page }) => {
  const schemaA = "ScrypathOps.Test.OpsPostA";
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto(`${standalone}/failed-sync?scenario=source-collision&schema=${schemaA}`);
  await waitForLiveConnected(page);

  const rows = page.getByTestId("failed-sync-row");
  await expect(rows).toHaveCount(2);
  const backendTask = rows.filter({ hasText: "Backend task 501" });
  const queueJob = rows.filter({ hasText: "Queue job 501" });
  await expect(backendTask).toBeVisible();
  await expect(queueJob).toBeVisible();
  expect(await backendTask.getAttribute("id")).not.toBe(await queueJob.getAttribute("id"));
  await expect(backendTask.getByTestId("failed-sync-retry")).toHaveCount(0);
  const queueRetry = queueJob.getByTestId("failed-sync-retry");
  await expect(queueRetry).toBeVisible();
  await queueRetry.click();
  await expect(page).toHaveURL(/sudo\/confirm/);
  const returnTo = new URL(page.url()).searchParams.get("return_to");
  expect(returnTo).toContain(`schema=${schemaA}`);
  expect(returnTo).not.toContain("schema=ScrypathOps.Test.OpsPostB");
  await expect(page.getByTestId("recovery-receipt")).toHaveCount(0);
});

test("real Search health refresh reorders records without moving focus to a different action", async ({ page }) => {
  const schemaA = "ScrypathOps.Test.OpsPostA";
  const token = crypto.randomUUID().replaceAll("-", "");
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto(`${standalone}/health?scenario=reorder-${token}&schema=${schemaA}`);
  await waitForLiveConnected(page);
  const rows = page.getByTestId("posture-row");
  await expect(rows.first()).toHaveAttribute("id", "posture-ScrypathOps.Test.OpsPostB");

  const rowA = rows.filter({ hasText: schemaA });
  const actionA = rowA.getByTestId("posture-failed-sync-link");
  await actionA.focus();
  await expect(actionA).toBeFocused();
  await page.keyboard.press("r");
  await expect(rows.first()).toHaveAttribute("id", "posture-ScrypathOps.Test.OpsPostA");
  await expect(actionA).toBeFocused();
  await expect(page).toHaveURL(new RegExp(`schema=${schemaA.replaceAll(".", "\\.")}`));
  await expect(actionA).toHaveAttribute("href", /schema=ScrypathOps.Test.OpsPostA/);
});

test("selected recovery context remains reachable through the mobile drawer and palette keyboard flow", async ({ page }) => {
  const schemaA = "ScrypathOps.Test.OpsPostA";
  await page.setViewportSize({ width: 1279, height: 900 });
  await page.goto(`${standalone}/health?scenario=a-selected-b-worse&schema=${schemaA}`);
  await waitForLiveConnected(page);
  const opener = page.getByRole("button", { name: "Open navigation" });
  await opener.click();
  const drawer = page.locator("#ops-mobile-nav");
  await expect(drawer).toBeVisible();
  await expect(drawer.getByTestId("shell-recovery-target")).toContainText(schemaA);
  await expect(drawer.getByRole("link", { name: "Failed sync work", exact: true }))
    .toHaveAttribute("href", new RegExp(`schema=${schemaA.replaceAll(".", "\\.")}`));
  await page.keyboard.press("Escape");
  await expect(drawer).toBeHidden();
  await expect(opener).toBeFocused();

  await page.setViewportSize({ width: 390, height: 844 });
  await opener.click();
  await expect(drawer).toBeVisible();
  await drawer.getByRole("link", { name: "Failed sync work", exact: true }).click();
  await waitForLiveConnected(page);
  await expect(page).toHaveURL(new RegExp(`failed-sync\\?schema=${schemaA.replaceAll(".", "\\.")}`));
  await expect(drawer).toBeHidden();
  await expect(page.getByTestId("shell-recovery-target").first()).toContainText(schemaA);

  await page.setViewportSize({ width: 1280, height: 900 });
  await expect(page.locator(".ops-sidebar")).toBeVisible();
  await expect(page.locator(".ops-sidebar").getByTestId("shell-recovery-target")).toContainText(schemaA);
});

test("standalone rendered states preserve unavailable, retained, unknown, empty, and long evidence", async ({ page }) => {
  const schemaA = "ScrypathOps.Test.OpsPostA";
  await page.setViewportSize({ width: 390, height: 844 });

  await page.goto(`${standalone}/health?scenario=no-success&schema=${schemaA}`);
  await waitForLiveConnected(page);
  const rowA = page.getByTestId("posture-row").filter({ hasText: schemaA });
  const noSuccess = rowA;
  await expect(noSuccess).toContainText("No success observed");
  await expect(noSuccess).toContainText("Retrying");

  await page.goto(`${standalone}/health?scenario=unknown&schema=${schemaA}`);
  await waitForLiveConnected(page);
  const unknown = page.getByTestId("posture-row").filter({ hasText: schemaA });
  await expect(unknown).toContainText("No success observed");
  await expect(unknown).not.toContainText("terminal failure");

  const retainedToken = crypto.randomUUID().replaceAll("-", "");
  await page.goto(`${standalone}/health?scenario=retained-${retainedToken}&schema=${schemaA}`);
  await waitForLiveConnected(page);
  const refresh = page.getByRole("button", { name: "Refresh search health" });
  await refresh.click();
  const retained = page.getByTestId("posture-row").filter({ hasText: schemaA });
  await expect(retained).toContainText("Backend observation unavailable");
  await expect(retained).toContainText("last success retained from the previous check");

  await page.goto(`${standalone}/health?scenario=error&schema=${schemaA}`);
  await waitForLiveConnected(page);
  const sourceError = page.getByTestId("posture-row").filter({ hasText: schemaA });
  await expect(sourceError).toContainText("Backend observation unavailable");
  await expect(sourceError).toContainText("Queue observation unavailable");
  await expect(sourceError).not.toContainText("No success observed");

  await page.goto(`${standalone}/failed-sync?scenario=empty-history&schema=${schemaA}`);
  await waitForLiveConnected(page);
  await expect(page.getByTestId("failed-sync-empty-hero")).toContainText("No failed sync work for this schema");
  await expect(page.getByTestId("failed-sync-retry")).toHaveCount(0);

  await page.goto(`${standalone}?scenario=empty`);
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "No schemas configured", exact: true })).toBeVisible();
  await expect(page.getByTestId("recovery-target")).toHaveCount(0);

  const longPrefix = `phase174_${"long_".repeat(14)}`;
  const longDocumentId = `phase174:${"fixture-document-".repeat(10)}501`;
  await page.goto(`${standalone}/failed-sync?scenario=long-value&schema=${schemaA}`);
  await waitForLiveConnected(page);
  for (const width of [390, 1279]) {
    await page.setViewportSize({ width, height: 844 });
    await assertNoPageOverflow(page, `standalone long failed-work evidence ${width}px`);
    const row = page.getByTestId("failed-sync-row").filter({ hasText: "Queue job 501" });
    const reason = await row.getByTestId("failed-sync-reason").textContent();
    expect(reason?.trim().length).toBeGreaterThan(450);
    expect(reason?.trim().length).toBeLessThanOrEqual(500);
    expect(reason?.trim()).toMatch(/\.\.\.$/);
    await expect(row).toContainText(longPrefix);
    await row.getByTestId("failed-sync-retry").click();
    const modal = page.getByRole("dialog");
    await expect(modal).toBeVisible();
    await expect(modal).toContainText(longDocumentId);
    await expect(modal).toContainText("1");
    if (width === 390) await page.getByRole("button", { name: /Cancel/i }).click();
  }
});

test("refresh keeps its real label, icon, and prior observation while the LiveView response is pending", async ({ page }) => {
  const schemaA = "ScrypathOps.Test.OpsPostA";
  const token = crypto.randomUUID().replaceAll("-", "");
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto(`${standalone}/health?scenario=busy-${token}&schema=${schemaA}`);
  await waitForLiveConnected(page);

  const rowA = page.getByTestId("posture-row").filter({ hasText: schemaA });
  const before = await rowA.textContent();
  const refresh = page.locator("#search-health-refresh");
  await expect(refresh).toContainText("Refresh");
  await expect(refresh).toHaveAttribute("aria-label", "Refresh search health");
  await expect(refresh.locator("svg")).toBeVisible();
  await refresh.click();
  // The test source blocks its actual backend observation for 700ms.
  // Assert the real pending view without depending on transport selection.
  await expect(refresh).toHaveAttribute("aria-busy", "true");
  await expect(refresh).toContainText("Refresh");
  await expect(refresh.locator("svg")).toBeVisible();
  await expect(rowA).toHaveText(before!);
  await expect(refresh).not.toHaveAttribute("aria-busy", "true");
});

test("retry dispatch retains the source row and withholds its receipt until the server response arrives", async ({ page, request }) => {
  test.setTimeout(120_000);
  const response = delayNextLiveViewResponse(page);
  await page.setViewportSize({ width: 1440, height: 900 });
  const seed = await seedScenario(request, "incident");
  expect(seed.tenant_id).not.toBeNull();
  const marker = `phase174-busy-${crypto.randomUUID().replaceAll("-", "")}`;
  const fixture = await prepareRecoveryFixture(request, { tenantId: seed.tenant_id!, marker });
  await page.goto(`/admin/search/failed-sync?schema=${fixture.schema.replace(/^Elixir\./, "")}`);
  await waitForLiveConnected(page);

  const original = page.getByTestId("failed-sync-row").filter({ hasText: `Queue job ${fixture.original_job_id}` });
  const retry = original.getByTestId("failed-sync-retry");
  await expect(retry).toBeVisible();
  response.arm();
  await retry.click();
  await response.held;
  await expect(retry).toHaveClass(/phx-click-loading/);
  await expect(retry).toContainText("Retry queue job");
  await expect(original).toContainText(`Queue job ${fixture.original_job_id}`);
  await expect(original.getByTestId("recovery-receipt")).toHaveCount(0);
  await response.released;
  await expect(original.getByTestId("recovery-receipt")).toBeVisible();
  await expect(original.getByTestId("recovery-receipt")).toContainText("Terminal completion has not been observed");
});

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
  await assertPaletteFilterClearAndReturn(page, "ScrypathEcommerce.Catalog.Variant");
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
  await assertPaletteFilterClearAndReturn(page, schemaB);
});

async function capture(page: Page, info: TestInfo, entry: string, surface: string, width: number, theme: string) {
  await mkdir(captureRoot, { recursive: true });
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.screenshot({ path: join(captureRoot, `${entry}-${surface}-${width}-${theme}.png`), fullPage: true });
  info.annotations.push({ type: "phase174-capture", description: `${entry}/${surface}/${width}/${theme}` });
}

async function assertPaletteFilterClearAndReturn(page: Page, selectedSchema: string) {
  const opener = page.locator("[data-ops-command-open]").first();
  await opener.focus();
  await page.keyboard.press("Control+k");

  const input = page.locator("#ops-cmdk [data-cmdk-input]");
  await expect(input).toBeFocused();
  await input.fill("failed sync");
  const visibleItems = page.locator("#ops-cmdk [data-cmdk-item]:visible");
  await expect(visibleItems).toHaveCount(1);
  await expect(visibleItems.first()).toHaveAttribute(
    "href",
    new RegExp(`schema=${selectedSchema.replaceAll(".", "\\.")}`)
  );

  await input.fill("");
  await expect(visibleItems).toHaveCount(6);
  for (const item of ["1", "2", "3"]) {
    await expect(page.locator(`#ops-cmdk-item-${item}`)).toHaveAttribute(
      "href",
      new RegExp(`schema=${selectedSchema.replaceAll(".", "\\.")}`)
    );
  }

  await page.keyboard.press("Escape");
  await expect(page.locator("#ops-cmdk")).toBeHidden();
  await expect(opener).toBeFocused();
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
  if (label.includes("control room")) {
    const primaryAction = page.locator("#control-room-health-link");
    await expect(primaryAction, `${label} prominent health action is rendered`).toBeVisible();
    await assertReadableControl(primaryAction, `${label} prominent health action`, 14, 44);
  }
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
