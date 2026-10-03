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
  const seed = await seedScenario(request, "e2e_search_catalog");
  const runMarker = marker();
  recordEvidence(testInfo, { fixture_marker: runMarker, schema: "Elixir.ScrypathEcommerce.Catalog.Variant", checked_outcome: "fixture setup started" });
  const fixture = await prepareRecoveryFixture(request, { tenantId: seed.tenant_id!, marker: runMarker });
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
  await page.getByRole("link", { name: "Start recovery" }).click();
  await expect(page.getByRole("heading", { name: "Posture", exact: true })).toBeVisible();
  await waitForLiveConnected(page);
  const variantHandoff = page.getByTestId("posture-failed-sync-link").filter({ hasText: "Variant" });
  await expect(variantHandoff).toBeVisible();
  await variantHandoff.click();
  await expect(page.getByRole("heading", { name: "Failed sync work" })).toBeVisible();
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Variant/);
  await waitForLiveConnected(page);

  const failedRow = page.getByTestId("failed-sync-row").filter({ has: page.getByRole("heading", { name: `Failed job ${fixture.original_job_id}` }) });
  await expect(failedRow).toBeVisible();
  const retry = failedRow.getByRole("button", { name: "Retry sync work" });
  await expect(retry).toBeVisible();
  await retry.click();

  const receipt = failedRow.getByTestId("recovery-receipt");
  await expect(receipt).toBeVisible();
  await expect(receipt).toContainText(`Original failure #${fixture.original_job_id} retained`);
  const receiptText = await receipt.innerText();
  const acceptedMatch = receiptText.match(/Queue job (\d+)/);
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
  await handoff.click();
  await expect(page.getByRole("heading", { name: "Sync and drift" })).toBeVisible();
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Variant/);
  await waitForLiveConnected(page);
  const recoveryStatus = page.locator("#recovery-observation");
  await page.getByRole("button", { name: "Refresh recovery status" }).click();
  await expect(recoveryStatus).toContainText("Recovery verified", { timeout: 30_000 });
  const observedText = await recoveryStatus.getByTestId("recovery-evidence").innerText();
  const observedTask = observedText.match(/Meilisearch task (\d+)/);
  expect(observedTask, "verified recovery must expose its exact backend task").not.toBeNull();
  await expect(recoveryStatus).toContainText(`Queue job ${acceptedJobId}`);

  const evidence = await waitForRecoveryEvidence(request, {
    marker: fixture.marker, acceptedJobId, handle: handle!, generation: 1,
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
    generation: "1", task_uid: String(evidence.task_uid), document_id: String(fixture.document_id)
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
  await expect(page.getByTestId("failed-sync-row").filter({ has: page.getByRole("heading", { name: `Failed job ${fixture.original_job_id}` }) })).toBeVisible();
  await page.reload();
  await expect(page.getByRole("heading", { name: "Failed sync work" })).toBeVisible();
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Variant/);
  await expect(page.getByTestId("failed-sync-row").filter({ has: page.getByRole("heading", { name: `Failed job ${fixture.original_job_id}` }) })).toBeVisible();

  await page.goto("/admin/search/failed-sync?schema=Elixir.NotAllowlisted");
  await expect(page.getByText("That schema is unavailable")).toBeVisible();
  await expect(page.getByTestId("failed-sync-retry")).toHaveCount(0);
  await page.goBack();
  await expect(page.getByRole("heading", { name: "Failed sync work" })).toBeVisible();
  await expect(page).toHaveURL(/schema=ScrypathEcommerce\.Catalog\.Variant/);
  await expect(page.getByTestId("failed-sync-row").filter({ has: page.getByRole("heading", { name: `Failed job ${fixture.original_job_id}` }) })).toBeVisible();
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
  await page.getByRole("link", { name: "Pre-flight sync drift" }).click();
  await expect(page.getByRole("heading", { name: "Sync and drift" })).toBeVisible();
  await waitForLiveConnected(page);
  await page.getByRole("button", { name: "Check index contract" }).click();
  await expect(page.getByText("Contract dimensions")).toBeVisible();
  const advanced = page.locator("details").filter({ has: page.locator("summary", { hasText: "Advanced: index promotion" }) });
  await advanced.locator("summary").click();
  await expect(advanced.getByRole("button", { name: "Promote target index" })).toBeEnabled();
  await advanced.getByRole("button", { name: "Promote target index" }).click();
  await expect(page.getByRole("heading", { name: "Confirm index promotion" })).toBeVisible();
  await page.getByRole("dialog", { name: "Confirm index promotion" }).getByRole("button", { name: "Promote target index", exact: true }).click();

  const promotionStatus = page.locator("details").filter({ hasText: "Advanced: index promotion" });
  await expect(promotionStatus).toContainText("Index swap completed", { timeout: 30_000 });
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
