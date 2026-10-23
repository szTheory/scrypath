import { expect, test, type TestInfo } from "@playwright/test";

import {
  drainSearchQueue,
  prepareRecoveryFixture,
  prepareSwapFixture,
  probeSwapEvidence,
  seedScenario,
  waitForLiveConnected,
  waitForRecoveryEvidence,
  type RecoveryEvidence
} from "./helpers/e2e";

import { assertOperatorGeometry, scanNonContrastA11y } from "./helpers/operator-ui";

test.use({ actionTimeout: 10_000 });

const marker = () => `phase172-${crypto.randomUUID().replaceAll("-", "")}`;

function recordEvidence(testInfo: TestInfo, evidence: Record<string, unknown>) {
  testInfo.annotations.push({ type: "phase172-operator-evidence", description: JSON.stringify(evidence) });
}

test.afterEach(async ({ page }, testInfo) => {
  if (testInfo.status === testInfo.expectedStatus) return;

  const annotations = testInfo.annotations
    .filter((annotation) => annotation.type === "phase172-operator-evidence")
    .map((annotation) => {
      try { return JSON.parse(annotation.description ?? "{}"); } catch { return {}; }
    });
  const sourceSha = process.env.SCRYPATH_SOURCE_SHA || process.env.GITHUB_SHA || "unknown";
  await testInfo.attach("operator-first-failure.json", {
    body: JSON.stringify({ source_sha: sourceSha, duration_ms: testInfo.duration, evidence: annotations }, null, 2),
    contentType: "application/json"
  });
  await testInfo.attach("operator-first-failure.png", {
    body: await page.screenshot({ fullPage: true }),
    contentType: "image/png"
  });
});

test("operator verifies a rendered recovery for the non-first Variant schema", async ({ page, request }, testInfo) => {
  test.setTimeout(90_000);
  const startedAt = Date.now();
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.addInitScript(() => localStorage.setItem("phx:theme", "dark"));
  const seed = await seedScenario(request, "e2e_search_catalog");
  const runMarker = marker();
  recordEvidence(testInfo, { fixture_marker: runMarker, schema: "Elixir.ScrypathEcommerce.Catalog.Variant", checked_outcome: "fixture setup started" });
  const fixture = await prepareRecoveryFixture(request, { tenantId: seed.tenant_id!, marker: runMarker });
  // Rows name their source as "Oban <queue> #<id>"; match the id exactly.
  const originalJobLabel = new RegExp(`Oban \\S+ #${fixture.original_job_id}\\b`);
  recordEvidence(testInfo, {
    fixture_marker: fixture.marker, schema: fixture.schema, index: fixture.index,
    original_job_id: fixture.original_job_id, original_attempt: fixture.original_attempt,
    expected_document_id: fixture.document_id, expected_value: fixture.expected_sku
  });
  expect(fixture.schema).toBe("Elixir.ScrypathEcommerce.Catalog.Variant");
  expect(fixture.index).toContain("variant");

  await page.goto("/admin/search");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Control Room" })).toBeVisible();
  const healthRoute = page.getByRole("link", { name: "View search health", exact: true });
  await expect(healthRoute).toHaveCount(1);
  await expect(healthRoute).toBeVisible();
  const affectedScope = page.getByTestId("control-room-affected-scope");
  await expect(affectedScope).toContainText(fixture.schema.replace(/^Elixir\./, ""));
  const secondaryIntents = page.getByTestId("control-room-secondary-intents");
  await expect(secondaryIntents).toBeVisible();
  await expect(secondaryIntents.getByTestId("control-room-verify-change")).toContainText("Check sync and settings");
  await expect(secondaryIntents.getByTestId("control-room-explore-search")).toContainText("Try a search");
  const scopePrecedesRoute = await page.evaluate(() => {
    const scope = document.querySelector('[data-testid="control-room-affected-scope"]');
    const route = document.querySelector('[data-testid="control-room-health-link"]');
    return Boolean(scope && route && (scope.compareDocumentPosition(route) & Node.DOCUMENT_POSITION_FOLLOWING));
  });
  expect(scopePrecedesRoute, "observed degraded scope must precede the primary health route").toBe(true);
  const routePrecedesIntents = await page.evaluate(() => {
    const route = document.querySelector('[data-testid="control-room-health-link"]');
    const intents = document.querySelector('[data-testid="control-room-secondary-intents"]');
    return Boolean(route && intents && (route.compareDocumentPosition(intents) & Node.DOCUMENT_POSITION_FOLLOWING));
  });
  expect(routePrecedesIntents, "the health verdict and route must precede secondary intent cards").toBe(true);
  await healthRoute.click();
  await expect(page.getByRole("heading", { name: "Search health", exact: true })).toBeVisible();
  await waitForLiveConnected(page);
  const variantHandoff = page.getByTestId("posture-row").filter({ has: page.getByRole("heading", { name: "Variant", exact: true }) }).getByTestId("posture-failed-sync-link");
  await expect(variantHandoff).toBeVisible();
  await variantHandoff.click();
  await expect(page.getByRole("heading", { name: "Failed sync work" })).toBeVisible();
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Variant/);
  await waitForLiveConnected(page);

  // The deep link preselects the Variant schema filter; adding Product widens it in the URL.
  const variantFilter = page.getByRole("checkbox", { name: /^Variant/ });
  const productFilter = page.getByRole("checkbox", { name: /^Product/ });
  await expect(variantFilter).toBeChecked();
  await expect(productFilter).not.toBeChecked();
  await productFilter.check();
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Product/);
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Variant/);
  await productFilter.uncheck();
  await expect(page).not.toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Product/);
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Variant/);

  const failedRow = page.getByTestId("failed-sync-row").filter({ hasText: originalJobLabel });
  await expect(failedRow).toBeVisible();
  await expect(failedRow.getByTestId("failed-sync-retry")).toBeEnabled();
  const rowText = await failedRow.innerText();
  expect(rowText).toMatch(originalJobLabel);
  expect(rowText).toContain("Variant");
  await expect(page.locator("input[name='schema[]']:checked")).toHaveValue("ScrypathEcommerce.Catalog.Variant");
  await expect(failedRow.getByTestId("failed-sync-reason")).not.toBeEmpty();

  const lightPreference = page.locator("#theme-toggle button").filter({ hasText: "Light" });
  await lightPreference.click();
  await expect(page.locator("html")).toHaveAttribute("data-theme-preference", "light");
  const darkPreference = page.locator("#theme-toggle button").filter({ hasText: "Dark" });
  await darkPreference.click();
  await expect(page.locator("html")).toHaveAttribute("data-theme-preference", "dark");

  for (const width of [320, 390]) {
    await page.setViewportSize({ width, height: 900 });
    await expect(failedRow).toBeVisible();
    const geometry = await page.evaluate(() => ({
      width: document.documentElement.clientWidth,
      scrollWidth: document.documentElement.scrollWidth
    }));
    expect(geometry.scrollWidth, `failed-work page must not overflow at ${width}px`).toBeLessThanOrEqual(geometry.width + 1);
    await expect(page.locator("input[name='schema[]']:checked")).toHaveValue("ScrypathEcommerce.Catalog.Variant");
    await expect(failedRow.getByTestId("failed-sync-reason")).toBeVisible();
    await expect(failedRow.getByTestId("failed-sync-reason")).not.toBeEmpty();
  }

  await page.setViewportSize({ width: 1440, height: 900 });
  const retry = failedRow.getByRole("button", { name: "Retry" });
  await retry.focus();
  await expect(retry).toBeFocused();
  await expect(page.getByRole("button", { name: "Refresh failed sync work" })).toBeVisible();
  await page.getByRole("button", { name: "Refresh failed sync work" }).click();
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Variant/);
  await expect(page.getByText("Failed sync work refreshed.", { exact: true })).toBeVisible();
  await expect(retry).toBeVisible();
  await retry.click();

  const receipt = failedRow.getByTestId("recovery-receipt");
  await expect(receipt).toBeVisible();
  await scanNonContrastA11y(page, testInfo, "retry-accepted-dark-desktop");
  await expect(receipt).toContainText(`Original job #${fixture.original_job_id} is retained`);
  const receiptText = await receipt.innerText();
  const acceptedMatch = receiptText.match(/Oban job #(\d+)/);
  expect(acceptedMatch, "rendered receipt must identify the accepted queue job").not.toBeNull();
  const acceptedJobId = Number(acceptedMatch![1]);
  expect(acceptedJobId).not.toBe(fixture.original_job_id);
  recordEvidence(testInfo, { original_job_id: fixture.original_job_id, accepted_job_id: acceptedJobId, accepted_attempt: receiptText.match(/attempt (\d+)/i)?.[1] ?? null, checked_outcome: "rendered retry acceptance" });
  const recoveryDrain = await drainSearchQueue(request);
  expect(recoveryDrain.failure).toBe(0);
  expect(recoveryDrain.success).toBeGreaterThan(0);
  const handoff = receipt.getByRole("link", { name: "Check sync status" });
  const handoffHref = await handoff.getAttribute("href");
  expect(handoffHref).toBeTruthy();
  const handoffUrl = new URL(handoffHref!, page.url());
  const handle = handoffUrl.searchParams.get("recovery");
  expect(handle).toBeTruthy();
  // Failed sync loads every schema at once, so the generation only has to identify this receipt.
  const generationParam = handoffUrl.searchParams.get("recovery_generation");
  expect(generationParam).toMatch(/^\d+$/);
  const originGeneration = Number(generationParam);
  await handoff.click();
  await expect(page.getByRole("heading", { name: "Sync and index" })).toBeVisible();
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Variant/);
  await waitForLiveConnected(page);
  const recoveryStatus = page.locator("#recovery-observation");
  await page.getByRole("button", { name: "Refresh recovery status" }).click();
  await expect(recoveryStatus).toContainText("Recovery verified", { timeout: 30_000 });
  await scanNonContrastA11y(page, testInfo, "recovery-verified-dark-desktop");
  await page.evaluate(() => window.scrollTo(0, 0));
  await assertOperatorGeometry(page, "verified recovery", [".ops-command-hint", "#theme-toggle"]);
  await testInfo.attach("recovery-verified-dark-1440.png", { body: await page.screenshot({ fullPage: true }), contentType: "image/png" });
  const observedText = await recoveryStatus.getByTestId("recovery-evidence").innerText();
  const observedTask = observedText.match(/Meilisearch task (\d+)/);
  expect(observedTask, "verified recovery must expose its exact backend task").not.toBeNull();
  await expect(recoveryStatus).toContainText(`Queue job ${acceptedJobId}`);

  const evidence = await waitForRecoveryEvidence(request, {
    marker: fixture.marker, acceptedJobId, handle: handle!, generation: originGeneration,
    taskUid: Number(observedTask![1]), documentId: fixture.document_id, timeoutMs: 30_000
  });
  expect(evidence).toMatchObject({
    original_job_id: fixture.original_job_id,
    original_attempt: fixture.original_attempt,
    accepted_job_id: acceptedJobId,
    task_status: "succeeded",
    task_type: "documentAdditionOrUpdate",
    task_index: fixture.index,
    expected_sku: fixture.expected_sku,
    active_document: true
  } as Partial<RecoveryEvidence>);
  expect(evidence.task_uid).toBe(Number(observedTask![1]));
  expect(evidence.accepted_attempt).toBeGreaterThan(0);
  expect(evidence.task_uid).toBeGreaterThan(fixture.task_baseline);
  recordEvidence(testInfo, { ...evidence, checked_outcome: "Recovery verified", elapsed_ms: Date.now() - startedAt });
  const probeParams = {
    marker: fixture.marker, accepted_job_id: String(acceptedJobId), handle: handle!,
    generation: String(originGeneration), task_uid: String(evidence.task_uid), document_id: String(fixture.document_id)
  };
  const oldTask = await request.get("/dev/e2e/recovery-probe", {
    params: { ...probeParams, task_uid: String(fixture.task_baseline) }
  });
  expect(oldTask.status(), "an older successful task cannot verify this recovery").toBe(422);
  const wrongDocument = await request.get("/dev/e2e/recovery-probe", {
    params: { ...probeParams, document_id: String(fixture.document_id + 1) }
  });
  expect(wrongDocument.status(), "a different document cannot verify this recovery").toBe(422);

  await page.goBack();
  await expect(page.getByRole("heading", { name: "Failed sync work" })).toBeVisible();
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Variant/);
  await expect(page.locator("input[name='schema[]']:checked")).toHaveValue("ScrypathEcommerce.Catalog.Variant");
  await page.goForward();
  await expect(page.getByRole("heading", { name: "Sync and index" })).toBeVisible();
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Variant/);
  await page.goBack();
  await expect(page.getByRole("heading", { name: "Failed sync work" })).toBeVisible();
  await expect(page.locator("input[name='schema[]']:checked")).toHaveValue("ScrypathEcommerce.Catalog.Variant");
  await page.reload();
  await expect(page.getByRole("heading", { name: "Failed sync work" })).toBeVisible();
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Variant/);
  await expect(page.getByTestId("failed-sync-row").filter({ hasText: originalJobLabel })).toBeVisible();

  await page.goto("/admin/search/failed-sync?schema=Elixir.NotAllowlisted");
  await expect(page.getByText("That schema is unavailable.")).toBeVisible();
  await expect(page.getByTestId("failed-sync-retry")).toHaveCount(0);
  await expect(page.locator("input[name='schema[]']:checked")).toHaveCount(0);
  await expect(page.getByTestId("failed-sync-row")).toHaveCount(0);
  await page.goBack();
  await expect(page.getByRole("heading", { name: "Failed sync work" })).toBeVisible();
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Variant/);
  await expect(page.getByTestId("failed-sync-row").filter({ hasText: originalJobLabel })).toBeVisible();
});

test("operator promotes only this returned task pair and unique target document", async ({ page, request }, testInfo) => {
  test.setTimeout(90_000);
  const startedAt = Date.now();
  const seed = await seedScenario(request, "e2e_search_catalog");
  const runMarker = marker();
  recordEvidence(testInfo, { fixture_marker: runMarker, schema: "Elixir.ScrypathEcommerce.Catalog.Product", checked_outcome: "target setup started" });
  const fixture = await prepareSwapFixture(request, { tenantId: seed.tenant_id!, marker: runMarker });
  const swapDrain = await drainSearchQueue(request);
  expect(swapDrain.failure).toBe(0);
  recordEvidence(testInfo, { fixture_marker: runMarker, schema: fixture.schema, live_index: fixture.live_index, target_index: fixture.target_index, expected_document_id: fixture.document_id, expected_value: fixture.expected_name, task_baseline: fixture.task_baseline });

  await page.goto("/admin/search");
  await waitForLiveConnected(page);
  await page.getByTestId("control-room-verify-change").click();
  await expect(page.getByRole("heading", { name: "Sync and index" })).toBeVisible();
  await waitForLiveConnected(page);
  await page.getByRole("button", { name: "Refresh sync and index settings" }).click();
  await expect(page.getByText(/Meilisearch settings (match|differ)/|/Meilisearch settings (match|differ)/).first()).toBeVisible();
  // Promotion controls appear only because the fixture prepared a target index.
  const advanced = page.locator("#index-promotion");
  await expect(advanced).toContainText(fixture.target_index);
  await expect(advanced.getByRole("button", { name: "Promote target index" })).toBeEnabled();
  await advanced.getByRole("button", { name: "Promote target index" }).click();
  const confirmation = page.getByRole("dialog", { name: "Confirm index promotion" });
  await expect(confirmation).toBeVisible();
  await expect(confirmation).toHaveAttribute("data-ops-modal-successor", "#promote-target-index");
  await expect(confirmation).toContainText(`Schema: ${fixture.schema.replace(/^Elixir\./, "")}`);
  await expect(confirmation.locator("p").filter({ hasText: "Live index:" })).toContainText(fixture.live_index);
  await expect(confirmation.locator("p").filter({ hasText: "Target index:" })).toContainText(fixture.target_index);
  await expect(confirmation).toContainText("Effect: replace live index contents and settings with the prepared target.");
  await testInfo.attach("phase175-promotion-confirmation-before.png", {
    body: await page.screenshot(), contentType: "image/png"
  });

  const close = confirmation.getByRole("button", { name: "Close Confirm index promotion dialog" });
  const cancel = confirmation.getByRole("button", { name: "Cancel index swap", exact: true });
  const confirm = confirmation.getByRole("button", { name: "Promote target index", exact: true });
  await close.focus();
  await expect(close).toBeFocused();
  await page.keyboard.press("Shift+Tab");
  await expect(confirm).toBeFocused();
  await page.keyboard.press("Tab");
  await expect(close).toBeFocused();

  for (const theme of ["light", "dark"]) {
    await page.locator("html").evaluate((html, value) => html.setAttribute("data-theme", value), theme);
    for (const width of [1440, 768, 390, 320]) {
      await page.setViewportSize({ width, height: 900 });
      const geometry = await confirmation.evaluate((dialog) => {
        const content = dialog.querySelector(".modal-box")!.getBoundingClientRect();
        return {
          viewportWidth: document.documentElement.clientWidth,
          scrollWidth: document.documentElement.scrollWidth,
          left: content.left,
          right: content.right,
          actionButtons: Array.from(dialog.querySelectorAll(".modal-box form > div button")).map((button) => {
            const buttonRect = button.getBoundingClientRect();
            return { left: buttonRect.left, right: buttonRect.right };
          })
        };
      });
      expect(geometry.scrollWidth, `promotion confirmation must not cause page overflow at ${width}px (${theme})`).toBeLessThanOrEqual(geometry.viewportWidth + 1);
      expect(geometry.left, `promotion confirmation must fit the left edge at ${width}px (${theme})`).toBeGreaterThanOrEqual(0);
      expect(geometry.right, `promotion confirmation must fit the right edge at ${width}px (${theme})`).toBeLessThanOrEqual(width + 1);
      expect(geometry.actionButtons.every((button) => button.left >= 0 && button.right <= width + 1),
        `promotion actions must fit the viewport at ${width}px (${theme})`).toBe(true);
      await expect(confirmation.locator("p").filter({ hasText: "Live index:" })).toContainText(fixture.live_index);
      await expect(confirmation.locator("p").filter({ hasText: "Target index:" })).toContainText(fixture.target_index);
      if (width === 320) {
        await testInfo.attach(`phase175-promotion-confirmation-320-${theme}.png`, {
          body: await page.screenshot(), contentType: "image/png"
        });
      }
    }
  }

  await page.locator("html").evaluate((html) => html.removeAttribute("data-theme"));
  await page.setViewportSize({ width: 1440, height: 900 });
  const promotionTrigger = advanced.getByRole("button", { name: "Promote target index" });
  await cancel.click();
  await expect(confirmation).toHaveCount(0);
  await expect(promotionTrigger).toBeFocused();
  await promotionTrigger.click();
  await expect(confirmation).toBeVisible();
  await expect(confirmation).toContainText(`Schema: ${fixture.schema.replace(/^Elixir\./, "")}`);
  await confirm.click();

  const promotionStatus = page.locator("#index-promotion");
  await expect(promotionStatus.getByText("Index swap completed", { exact: true })).toBeVisible({ timeout: 30_000 });
  const taskText = await promotionStatus.innerText();
  const taskMatch = taskText.match(/Task\s+(\d+)/);
  expect(taskMatch, "completed promotion must retain its returned task UID").not.toBeNull();
  const taskUid = Number(taskMatch![1]);
  const evidence = await probeSwapEvidence(request, {
    marker: fixture.marker, taskUid, liveIndex: fixture.live_index, targetIndex: fixture.target_index,
    taskBaseline: fixture.task_baseline, documentId: fixture.document_id
  });
  expect(evidence).toMatchObject({
    task_uid: taskUid, task_status: "succeeded", task_type: "indexSwap",
    live_index: fixture.live_index, target_index: fixture.target_index,
    swapped_pair: [fixture.live_index, fixture.target_index],
    document_id: fixture.document_id, expected_name: fixture.expected_name, active_document: true
  });
  expect(evidence.task_uid).toBeGreaterThan(fixture.task_baseline);
  await expect(advanced.getByRole("button", { name: "Refresh checks" })).toBeVisible();
  await advanced.getByRole("button", { name: "Refresh checks" }).click();
  await expect(advanced).toContainText(`Task ${taskUid}`);
  const refreshedEvidence = await probeSwapEvidence(request, {
    marker: fixture.marker, taskUid, liveIndex: fixture.live_index, targetIndex: fixture.target_index,
    taskBaseline: fixture.task_baseline, documentId: fixture.document_id
  });
  expect(refreshedEvidence.task_uid, "refresh must re-read the retained task without a second swap").toBe(taskUid);
  expect(refreshedEvidence.active_document, "refresh must retain authoritative active-document proof").toBe(true);
  await testInfo.attach("phase175-promotion-confirmation-after.png", {
    body: await page.screenshot(), contentType: "image/png"
  });

  const stale = await request.get("/dev/e2e/swap-probe", { params: {
    marker: fixture.marker, task_uid: String(fixture.task_baseline), live_index: fixture.live_index,
    target_index: fixture.target_index, task_baseline: String(fixture.task_baseline),
    document_id: String(fixture.document_id)
  }});
  expect(stale.status()).toBe(422);
  const wrongDocument = await request.get("/dev/e2e/swap-probe", { params: {
    marker: fixture.marker, task_uid: String(taskUid), live_index: fixture.live_index,
    target_index: fixture.target_index, task_baseline: String(fixture.task_baseline),
    document_id: String(Object.values(seed.products)[0])
  }});
  expect(wrongDocument.status()).toBe(422);
  recordEvidence(testInfo, { ...evidence, checked_outcome: "exact swap verified", elapsed_ms: Date.now() - startedAt });
});
