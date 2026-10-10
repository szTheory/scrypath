import { expect, test, type Page } from "@playwright/test";
import { waitForLiveConnected } from "./helpers/e2e";

const standalone = process.env.PHASE175_OPS_BASE_URL ?? "http://ops:4003/ops/phase175";

async function ready(page: Page) {
  await waitForLiveConnected(page);
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
}

test("standalone fixture renders task, sync, configuration, scope, and eligibility states", async ({ page }, info) => {
  test.setTimeout(90_000);
  const taskStates = [
    ["accepted-queued", "Index swap accepted"],
    ["accepted-processing", "Index swap running"],
    ["accepted-succeeded", "Index swap completed"],
    ["accepted-failed", "Index swap failed"],
    ["accepted-cancelled", "Index swap cancelled"],
    ["accepted-wrong-uid", "Index swap outcome unconfirmed"],
    ["accepted-malformed", "Index swap outcome unconfirmed"],
    ["accepted-timeout", "Index swap outcome unconfirmed"],
    ["accepted-slow-processing", "Index swap running"]
  ] as const;
  for (const [scenario, expected] of taskStates) {
    await page.goto(`${standalone}/sync-drift?schema=ScrypathOps.Test.OpsPostB&scenario=${scenario}`);
    await ready(page);
    const status = page.locator("#promotion-task-status");
    await expect(status).toContainText("Index swap accepted");
    await expect(status.getByTestId("promotion-task-identity")).toContainText("17501");
    const check = status.getByRole("button", { name: "Check swap status", exact: true });
    if (scenario === "accepted-slow-processing") {
      const pendingRead = check.click();
      await expect(status.getByRole("status")).toContainText("Checking swap status…");
      await expect(check).toBeDisabled();
      await pendingRead;
    } else {
      await check.click();
    }
    await expect(status).toContainText(expected);
    await expect(status.getByTestId("promotion-task-identity")).toContainText("17501");
  }

  for (const scenario of ["sync-error", "queue-error"] as const) {
    await page.goto(`${standalone}/sync-drift?schema=ScrypathOps.Test.OpsPostB&scenario=${scenario}`);
    await ready(page);
    const syncRegion = page.getByRole("region", { name: "Sync status" });
    const syncAlert = syncRegion.getByRole("alert");
    await expect(syncAlert).toContainText("Sync status is unavailable");
    await expect(syncRegion).not.toContainText("No pending or failed sync work found");
    await page.getByRole("button", { name: "Check index configuration", exact: true }).click();
    await expect(page.getByText("Index configuration matches", { exact: true })).toBeVisible();
    await expect(syncAlert).toContainText("Sync status is unavailable");
  }

  await page.goto(`${standalone}/sync-drift?schema=ScrypathOps.Test.OpsPostB&scenario=config-mismatch`);
  await ready(page);
  await page.getByRole("button", { name: "Check index configuration", exact: true }).click();
  await expect(page.getByText("Index configuration differs", { exact: true })).toBeVisible();
  await expect(page.getByTestId("configuration-details")).toHaveAttribute("open", "");

  await page.goto(`${standalone}/sync-drift?schema=ScrypathOps.Test.OpsPostB&scenario=config-error`);
  await ready(page);
  await page.getByRole("button", { name: "Check index configuration", exact: true }).click();
  await expect(page.getByRole("region", { name: "Index configuration" }).getByRole("alert")).toContainText("Index configuration could not be checked");
  await expect(page.getByRole("region", { name: "Sync status" })).toContainText("No pending or failed sync work found");

  await page.goto(`${standalone}/sync-drift?schema=ScrypathOps.Test.OpsPostB&scenario=promotion-blocked`);
  await ready(page);
  const advanced = page.getByTestId("advanced-promotion-disclosure");
  await advanced.locator("summary").click();
  await expect(advanced.getByText("Promotion unavailable", { exact: true })).toBeVisible();
  await expect(advanced.getByRole("button", { name: "Promote target index", exact: true })).toBeDisabled();
  await page.setViewportSize({ width: 390, height: 844 });
  await advanced.locator("code").first().evaluate((element) => {
    element.textContent = "phase175-long-identifier-".repeat(14);
  });
  const dimensions = await page.evaluate(() => ({
    viewport: document.documentElement.clientWidth,
    scroll: document.documentElement.scrollWidth
  }));
  expect(dimensions.scroll, "synthetic long technical identifier stays within a 390px page").toBeLessThanOrEqual(dimensions.viewport + 1);

  await page.goto(`${standalone}/sync-drift?schema=ScrypathOps.Test.OpsPostB&scenario=removed-schema`);
  await ready(page);
  await expect(page.getByText("That schema is unavailable", { exact: true })).toBeVisible();
  await expect(page.locator("#promotion-task-status")).toHaveCount(0);

  await page.goto(`${standalone}/sync-drift?schema=ScrypathOps.Test.OpsPostB&scenario=unexpected-mutation`);
  await ready(page);
  await expect(page.getByText("No schemas configured", { exact: true })).toBeVisible();
  await expect(page.getByTestId("advanced-promotion-disclosure")).toHaveCount(0);

  info.annotations.push({ type: "phase175-ui-state-groups", description: JSON.stringify({ groups: ["empty", "loading", "error", "populated", "partial", "overflow", "zero-one-many", "long-text"], states: taskStates.map(([scenario, outcome]) => ({ scenario, outcome })), sync_errors: 2, configuration_states: 2, blocked_promotion: true, removed_schema: true, synthetic_long_text_layout: "390px inline technical identifier; DOM-only stress input", rendered_entrypoint: "standalone production LiveView" }) });
});
