import { expect, test, type Page, type TestInfo } from "@playwright/test";
import { mkdir } from "node:fs/promises";
import { join } from "node:path";
import {
  drainSearchQueue,
  injectFailedSync,
  prepareDeleteRecoveryFixture,
  prepareRecoveryFixture,
  prepareSwapFixture,
  probeDeleteRecoveryEvidence,
  probeSwapEvidence,
  seedScenario,
  waitForLiveConnected,
  waitForRecoveryEvidence
} from "./helpers/e2e";
import { assertDialogCycle, assertOperatorGeometry } from "./helpers/operator-ui";

const standalone = process.env.PHASE175_OPS_BASE_URL ?? "http://ops:4003/ops/phase175";
const captures = "test-results/phase175-captures";
const widths = [390, 768, 1440] as const;
const themes = ["light", "dark"] as const;
const schema = "ScrypathEcommerce.Catalog.Product";

async function ready(page: Page) {
  await waitForLiveConnected(page);
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
}

async function capture(page: Page, info: TestInfo, phase: string, width: number, theme: string) {
  await mkdir(captures, { recursive: true });
  await page.evaluate(() => window.scrollTo(0, 0));
  const name = `mounted-sync-drift-${phase}-${width}-${theme}.png`;
  await page.screenshot({ path: join(captures, name), fullPage: true });
  info.annotations.push({ type: "phase175-capture", description: name });
}

test("mounted confirmation submits one exact pair and verifies its returned task and active document", async ({ page, request }, info) => {
  test.setTimeout(120_000);
  const seed = await seedScenario(request, "e2e_search_catalog");
  expect(seed.tenant_id).not.toBeNull();
  const drained = await drainSearchQueue(request);
  expect(drained.failure, "target preparation finishes without queue failures").toBe(0);
  const marker = `phase175-${crypto.randomUUID().replaceAll("-", "")}`;
  const fixture = await prepareSwapFixture(request, { tenantId: seed.tenant_id!, marker });

  await page.setViewportSize({ width: 1440, height: 900 });
  await page.emulateMedia({ colorScheme: "light", reducedMotion: "reduce" });
  await page.goto(`/admin/search/sync-drift?schema=${schema}`);
  await ready(page);
  await expect(page.getByRole("heading", { name: "Sync and drift", exact: true })).toBeVisible();
  await expect(page.getByRole("radio", { name: /Product/ })).toBeChecked();
  await page.getByRole("button", { name: "Check index configuration", exact: true }).click();
  await expect(page.getByText("Index configuration matches", { exact: true })).toBeVisible();
  const advanced = page.getByTestId("advanced-promotion-disclosure");
  await advanced.locator("summary").click();
  await advanced.getByRole("button", { name: "Refresh sync and configuration checks", exact: true }).click();
  await expect(advanced).toHaveAttribute("open", "");
  await expect(advanced.getByText("Ready for promotion", { exact: true })).toBeVisible();
  await expect(advanced.getByRole("button", { name: "Promote target index", exact: true })).toBeEnabled();
  for (const width of widths) {
    await page.setViewportSize({ width, height: 900 });
    for (const theme of themes) {
      await page.emulateMedia({ colorScheme: theme, reducedMotion: "reduce" });
      await page.locator(`#theme-toggle [data-phx-theme="${theme}"]`).click();
      await expect(page.locator("html")).toHaveAttribute("data-theme-preference", theme);
      await expect(page.locator("html")).toHaveAttribute("data-theme", theme);
      await page.evaluate(() => window.scrollTo(0, 0));
      await assertOperatorGeometry(page, `mounted before confirmation ${width}/${theme}`, ["#ops-page-title", "#sync-drift-schema-form"]);
      await assertNoPageOverflow(page, `mounted before confirmation ${width}/${theme}`);
      await capture(page, info, "before-confirmation-interaction", width, theme);
    }
  }

  await page.setViewportSize({ width: 1440, height: 900 });
  await page.locator('#theme-toggle [data-phx-theme="system"]').click();
  await expect(page.locator("html")).toHaveAttribute("data-theme-preference", "system");
  await expect(page.locator("#theme-toggle [data-phx-theme='system']")).toHaveAttribute("aria-pressed", "true");
  await expect(page.locator("html")).toHaveAttribute("data-theme-effective", "dark");
  expect(await page.evaluate(() => matchMedia("(prefers-reduced-motion: reduce)").matches)).toBe(true);
  await assertNoPageOverflow(page, "mounted System appearance with reduced motion");
  await capture(page, info, "before-confirmation-system-dark-reduced-motion", 1440, "system");
  await page.emulateMedia({ colorScheme: "light", reducedMotion: "reduce" });
  await expect(page.locator("html")).toHaveAttribute("data-theme-effective", "light");
  await assertNoPageOverflow(page, "mounted System Light appearance with reduced motion");
  await capture(page, info, "before-confirmation-system-light-reduced-motion", 1440, "system-light");
  await expect(page.locator("html")).toHaveAttribute("data-theme-effective", "light");
  await page.locator("#theme-toggle [data-phx-theme='system']").click();
  await advanced.getByRole("button", { name: "Promote target index", exact: true }).click();
  const dialog = page.getByRole("dialog", { name: "Confirm index promotion" });
  await expect(dialog).toBeVisible();
  await expect(dialog).toContainText(schema);
  await expect(dialog).toContainText(fixture.live_index);
  await expect(dialog).toContainText(fixture.target_index);
  await expect(dialog).toContainText("Meilisearch swaps this pair atomically");
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.screenshot({ path: join(captures, "mounted-confirmation-1440-light.png"), fullPage: true });
  info.annotations.push({ type: "phase175-capture", description: "mounted-confirmation-1440-light.png" });
  const cancel = dialog.getByRole("button", { name: "Cancel index swap", exact: true });
  const confirm = dialog.getByRole("button", { name: "Promote target index", exact: true });
  const close = dialog.getByRole("button", { name: "Close Confirm index promotion dialog", exact: true });
  await expect(cancel).toBeFocused();
  await assertDialogCycle(page, [close, cancel, confirm], "Phase 175 promotion confirmation");
  await page.keyboard.press("Escape");
  await expect(dialog).toBeHidden();
  await expect(advanced.getByRole("button", { name: "Promote target index", exact: true })).toBeFocused();
  await advanced.getByRole("button", { name: "Promote target index", exact: true }).click();
  await expect(dialog).toBeVisible();
  await expect(dialog).toContainText(fixture.live_index);
  await expect(dialog).toContainText(fixture.target_index);

  // Submit twice in the same browser turn to exercise the in-flight guard before a
  // server patch can disable the confirmation control.
  await confirm.evaluate((button: HTMLButtonElement) => {
    button.form!.requestSubmit(button);
    button.form!.requestSubmit(button);
  });
  const status = page.locator("#promotion-task-status");
  await expect(status.getByText("Index swap completed", { exact: true })).toBeVisible({ timeout: 30_000 });
  const statusText = await status.innerText();
  const uidText = await status.getByTestId("promotion-task-identity").locator("code").last().innerText();
  const taskUid = Number(uidText);
  expect(Number.isInteger(taskUid), `the rendered task outcome retains the server-returned UID: ${statusText}`).toBe(true);
  expect(taskUid).toBe(fixture.task_baseline + 1);
  info.annotations.push({ type: "phase175-mounted-promotion", description: JSON.stringify({ marker, schema: fixture.schema, live_index: fixture.live_index, target_index: fixture.target_index, task_uid: taskUid }) });

  const evidence = await probeSwapEvidence(request, {
    marker: fixture.marker,
    taskUid,
    liveIndex: fixture.live_index,
    targetIndex: fixture.target_index,
    taskBaseline: fixture.task_baseline,
    documentId: fixture.document_id
  });
  expect(evidence).toMatchObject({
    marker,
    task_uid: taskUid,
    task_status: "succeeded",
    task_type: "indexSwap",
    live_index: fixture.live_index,
    target_index: fixture.target_index,
    swapped_pair: [fixture.live_index, fixture.target_index],
    document_id: fixture.document_id,
    expected_name: fixture.expected_name,
    active_document: true
  });

  await expect(status).toContainText(String(taskUid));
  const uidValue = status.getByTestId("promotion-task-identity").locator("code").last();
  await uidValue.selectText();
  expect(await page.evaluate(() => window.getSelection()?.toString())).toBe(String(taskUid));
  await page.keyboard.press("Control+c");
  expect(await page.evaluate(() => window.getSelection()?.toString())).toBe(String(taskUid));
  info.annotations.push({ type: "phase175-exact-value-copy", description: JSON.stringify({ task_uid: taskUid, selected_text: String(taskUid), keyboard_copy: "Control+C", clipboard_readback: "unavailable on the HTTP test origin" }) });
  for (const width of widths) {
    await page.setViewportSize({ width, height: 900 });
    for (const theme of themes) {
      await page.emulateMedia({ colorScheme: theme, reducedMotion: "reduce" });
      await page.locator(`#theme-toggle [data-phx-theme="${theme}"]`).click();
      await expect(page.locator("html")).toHaveAttribute("data-theme-preference", theme);
      await expect(page.locator("html")).toHaveAttribute("data-theme", theme);
      await assertNoPageOverflow(page, `mounted after completed promotion ${width}/${theme}`);
      await capture(page, info, "after-confirmation-interaction", width, theme);
    }
  }
});

test("mounted retry handoff verifies exact upsert job, attempt, task, and active document", async ({ page, request }, info) => {
  test.setTimeout(120_000);
  const seed = await seedScenario(request, "e2e_search_catalog");
  expect(seed.tenant_id).not.toBeNull();
  const initialDrain = await drainSearchQueue(request);
  expect(initialDrain.failure).toBe(0);
  const marker = `phase175-recovery-${crypto.randomUUID().replaceAll("-", "")}`;
  const fixture = await prepareRecoveryFixture(request, { tenantId: seed.tenant_id!, marker });

  await page.goto(`/admin/search/failed-sync?schema=${fixture.schema.replace(/^Elixir\./, "")}`);
  await ready(page);
  const original = page.getByTestId("failed-sync-row").filter({ hasText: `Queue job ${fixture.original_job_id}` });
  await expect(original).toBeVisible();
  await original.getByTestId("failed-sync-retry").click();
  const receipt = original.getByTestId("recovery-receipt");
  await expect(receipt).toBeVisible();
  await expect(receipt).toContainText(`Original Queue job ${fixture.original_job_id} failure retained`);
  const accepted = (await receipt.innerText()).match(/Replacement accepted — queue job (\d+)/);
  expect(accepted, "the retry handoff exposes its replacement job").not.toBeNull();
  const acceptedJobId = Number(accepted![1]);
  expect(acceptedJobId).not.toBe(fixture.original_job_id);
  const href = await receipt.getByRole("link", { name: "Check sync status" }).getAttribute("href");
  expect(href).toBeTruthy();
  const handoff = new URL(href!, page.url());
  const handle = handoff.searchParams.get("recovery");
  const generation = Number(handoff.searchParams.get("recovery_generation"));
  expect(handle).toBeTruthy();
  expect(Number.isInteger(generation) && generation > 0).toBe(true);

  const drained = await drainSearchQueue(request);
  expect(drained.success).toBeGreaterThan(0);
  await receipt.getByRole("link", { name: "Check sync status" }).click();
  await ready(page);
  const recovery = page.locator("#recovery-observation");
  await expect.poll(async () => {
    await recovery.getByRole("button", { name: "Refresh recovery status" }).click();
    return await recovery.innerText();
  }, { timeout: 30_000 }).toContain("Recovery verified");
  const evidenceText = await recovery.getByTestId("recovery-evidence").innerText();
  const task = evidenceText.match(/Meilisearch task (\d+)/);
  expect(task, "verified recovery displays the exact backend task UID").not.toBeNull();
  const probe = await waitForRecoveryEvidence(request, {
    marker,
    acceptedJobId,
    handle: handle!,
    generation,
    taskUid: Number(task![1]),
    documentId: fixture.document_id
  });
  expect(probe).toMatchObject({
    original_job_id: fixture.original_job_id,
    original_attempt: fixture.original_attempt,
    accepted_job_id: acceptedJobId,
    task_type: "documentAdditionOrUpdate",
    task_index: fixture.index,
    document_id: fixture.document_id,
    expected_sku: fixture.expected_sku,
    active_document: true
  });
  expect(probe.task_uid).toBe(Number(task![1]));
  expect(probe.accepted_attempt).toBeGreaterThan(0);
  info.annotations.push({ type: "phase175-recovery-upsert", description: JSON.stringify(probe) });
});

test("mounted delete retry verifies the exact task and expected active-index absence", async ({ page, request }, info) => {
  test.setTimeout(120_000);
  const seed = await seedScenario(request, "e2e_search_catalog");
  expect(seed.tenant_id).not.toBeNull();
  const drained = await drainSearchQueue(request);
  expect(drained.failure).toBe(0);
  const marker = `phase175-delete-${crypto.randomUUID().replaceAll("-", "")}`;
  const fixture = await prepareDeleteRecoveryFixture(request, { tenantId: seed.tenant_id!, marker });

  await page.goto(`/admin/search/failed-sync?schema=${fixture.schema.replace(/^Elixir\./, "")}`);
  await ready(page);
  const original = page.getByTestId("failed-sync-row").filter({ hasText: `Queue job ${fixture.original_job_id}` });
  await expect(original).toBeVisible();
  await expect(original.getByTestId("failed-sync-facts")).toContainText("delete");
  await original.getByTestId("failed-sync-retry").click();
  const dialog = page.getByRole("dialog", { name: "Confirm delete sync work" });
  await expect(dialog).toBeVisible();
  await expect(dialog).toContainText(String(fixture.document_id));
  await dialog.getByRole("button", { name: "Retry delete sync work" }).click();
  const receipt = original.getByTestId("recovery-receipt");
  await expect(receipt).toBeVisible();
  const accepted = (await receipt.innerText()).match(/Replacement accepted — queue job (\d+)/);
  expect(accepted).not.toBeNull();
  const acceptedJobId = Number(accepted![1]);
  const handoffHref = await receipt.getByRole("link", { name: "Check sync status" }).getAttribute("href");
  expect(handoffHref).toBeTruthy();
  const handoff = new URL(handoffHref!, page.url());
  const handle = handoff.searchParams.get("recovery");
  const generation = Number(handoff.searchParams.get("recovery_generation"));
  expect(handle).toBeTruthy();

  const drainResult = await drainSearchQueue(request);
  expect(drainResult.success).toBeGreaterThan(0);
  await receipt.getByRole("link", { name: "Check sync status" }).click();
  await ready(page);
  const recovery = page.locator("#recovery-observation");
  await expect.poll(async () => {
    await recovery.getByRole("button", { name: "Refresh recovery status" }).click();
    return await recovery.innerText();
  }, { timeout: 30_000 }).toContain("Recovery verified");
  const evidenceText = await recovery.getByTestId("recovery-evidence").innerText();
  const task = evidenceText.match(/Meilisearch task (\d+)/);
  expect(task, "verified delete exposes the exact task UID").not.toBeNull();
  const probe = await probeDeleteRecoveryEvidence(request, {
    marker,
    originalJobId: fixture.original_job_id,
    acceptedJobId,
    handle: handle!,
    generation,
    taskUid: Number(task![1]),
    index: fixture.index,
    documentId: fixture.document_id
  });
  expect(probe).toMatchObject({
    accepted_job_id: acceptedJobId,
    task_uid: Number(task![1]),
    task_status: "succeeded",
    task_type: "documentDeletion",
    task_index: fixture.index,
    document_id: fixture.document_id,
    active_document_absent: true
  });
  await expect(recovery.getByTestId("recovery-source")).toContainText("operation delete");
  info.annotations.push({ type: "phase175-recovery-delete", description: JSON.stringify(probe) });
});

test("mounted promotion rejects a newly changed prerequisite before submitting", async ({ page, request }) => {
  test.setTimeout(120_000);
  const seed = await seedScenario(request, "e2e_search_catalog");
  expect(seed.tenant_id).not.toBeNull();
  const marker = `phase175-prerequisite-${crypto.randomUUID().replaceAll("-", "")}`;
  const drained = await drainSearchQueue(request);
  expect(drained.failure).toBe(0);
  const fixture = await prepareSwapFixture(request, { tenantId: seed.tenant_id!, marker });

  await page.goto(`/admin/search/sync-drift?schema=${schema}`);
  await ready(page);
  await page.getByRole("button", { name: "Check index configuration", exact: true }).click();
  await expect(page.getByText("Index configuration matches", { exact: true })).toBeVisible();
  const advanced = page.getByTestId("advanced-promotion-disclosure");
  await advanced.locator("summary").click();
  await advanced.getByRole("button", { name: "Refresh sync and configuration checks", exact: true }).click();
  await expect(advanced.getByText("Ready for promotion", { exact: true })).toBeVisible();
  await advanced.getByRole("button", { name: "Promote target index", exact: true }).click();
  const dialog = page.getByRole("dialog", { name: "Confirm index promotion" });
  await expect(dialog).toBeVisible();

  await injectFailedSync(request, { tenantId: seed.tenant_id!, scenarioKey: marker });
  const confirm = dialog.getByRole("button", { name: "Promote target index", exact: true });
  await confirm.click();
  await expect(page.getByRole("alert")).toContainText("Index promotion blocked");
  await expect(page.getByText("Index swap accepted", { exact: true })).toHaveCount(0);
  await expect(page.locator("#promotion-task-status")).toHaveCount(0);
  // If the stale modal submitted a swap, this exact marker would now be in the live index.
  await expect.poll(async () => {
    const response = await request.get("/dev/e2e/search-visible", {
      params: { tenant_id: String(seed.tenant_id), query: fixture.expected_name }
    });
    expect(response.ok()).toBeTruthy();
    return (await response.json() as { hits: string[] }).hits;
  }).not.toContain(fixture.expected_name);
});

test("standalone stale-sudo promotion return preserves context without replay", async ({ page, request }) => {
  await page.goto(`${standalone}/sync-drift?schema=ScrypathOps.Test.OpsPostB&scenario=auth-return-ready&fixture_auth=expired`);
  await ready(page);
  await page.getByRole("button", { name: "Check index configuration", exact: true }).click();
  await expect(page.getByText("Index configuration matches", { exact: true })).toBeVisible();
  const advanced = page.getByTestId("advanced-promotion-disclosure");
  await advanced.locator("summary").click();
  await advanced.getByRole("button", { name: "Refresh sync and configuration checks", exact: true }).click();
  await expect(advanced.getByText("Ready for promotion", { exact: true })).toBeVisible();
  await advanced.getByRole("button", { name: "Promote target index", exact: true }).click();
  const dialog = page.getByRole("dialog", { name: "Confirm index promotion" });
  await expect(dialog).toBeVisible();
  await dialog.getByRole("button", { name: "Promote target index", exact: true }).click();
  await expect(page).toHaveURL(/\/sudo\/confirm\?/);
  const returnTo = new URL(page.url()).searchParams.get("return_to");
  expect(returnTo).toContain("/ops/phase175/sync-drift");
  expect(returnTo).toContain("ScrypathOps.Test.OpsPostB");
  await page.goto(new URL(returnTo!, page.url()).toString());
  await ready(page);
  await expect(page.getByRole("heading", { name: "Sync and drift", exact: true })).toBeVisible();
  const statsResponse = await request.get(`${standalone}/fixture-status`);
  expect(statsResponse.ok()).toBeTruthy();
  expect(await statsResponse.json()).toMatchObject({ swap_post_count: 1 });
});

test("standalone browser checks only the exact retained fake UID after an unconfirmed read", async ({ page }, info) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.emulateMedia({ colorScheme: "dark", reducedMotion: "reduce" });
  await page.goto(`${standalone}/sync-drift?schema=ScrypathOps.Test.OpsPostB&scenario=accepted-timeout`);
  await ready(page);

  const status = page.locator("#promotion-task-status");
  await expect(status).toContainText("Index swap accepted");
  const identity = status.getByTestId("promotion-task-identity");
  await expect(identity).toContainText("17501");
  await expect(status.getByRole("button", { name: "Check swap status", exact: true })).toBeVisible();
  await status.getByRole("button", { name: "Check swap status", exact: true }).click();
  await expect(status).toContainText("Index swap outcome unconfirmed");
  await expect(identity).toContainText("17501");
  await expect(status).not.toContainText("Index swap running");
  info.annotations.push({ type: "phase175-standalone-exact-recheck", description: JSON.stringify({ scenario: "accepted-timeout", requested_uid: 17501, rendered_outcome: "unconfirmed", swap_resubmitted: false }) });
});

async function assertNoPageOverflow(page: Page, label: string) {
  const dimensions = await page.evaluate(() => ({
    viewport: document.documentElement.clientWidth,
    scroll: document.documentElement.scrollWidth
  }));
  expect(dimensions.scroll, `${label} has no page-level horizontal overflow`).toBeLessThanOrEqual(dimensions.viewport + 1);
}
