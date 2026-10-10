import { expect, test, type Page, type TestInfo } from "@playwright/test";
import { mkdir } from "node:fs/promises";
import { join } from "node:path";
import { drainSearchQueue, prepareSwapFixture, probeSwapEvidence, seedScenario, waitForLiveConnected } from "./helpers/e2e";
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
  const marker = `phase175-${crypto.randomUUID().replaceAll("-", "")}`;
  const fixture = await prepareSwapFixture(request, { tenantId: seed.tenant_id!, marker });
  const drained = await drainSearchQueue(request);
  expect(drained.failure, "target preparation finishes without queue failures").toBe(0);

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

  await confirm.click();
  const status = page.locator("#promotion-task-status");
  await expect(status.getByText("Index swap completed", { exact: true })).toBeVisible({ timeout: 30_000 });
  const statusText = await status.innerText();
  const uidText = await status.getByTestId("promotion-task-identity").locator("code").last().innerText();
  const taskUid = Number(uidText);
  expect(Number.isInteger(taskUid), `the rendered task outcome retains the server-returned UID: ${statusText}`).toBe(true);
  expect(taskUid).toBeGreaterThan(fixture.task_baseline);
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
