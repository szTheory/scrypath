import { expect, test, type Locator } from "@playwright/test";
import { mkdirSync } from "node:fs";
import { join } from "node:path";
import { expandHealthDetails } from "./helpers/operator-ui";

const ENTRYPOINTS = [
  {
    name: "mounted",
    url: "/admin/search/phase173/health",
    rows: ["posture-ScrypathEcommerce.Catalog.Product", "posture-ScrypathEcommerce.Catalog.Variant"]
  },
  {
    name: "standalone",
    url: process.env.PHASE173_OPS_BASE_URL ?? "http://ops:4003/ops/phase173/health",
    rows: ["posture-ScrypathOps.Test.OpsPostA", "posture-ScrypathOps.Test.OpsPostB"]
  }
] as const;

const scenarios = ["default", "failed", "unknown", "empty", "partial", "long-value", "source-error", "manual", "no-success"] as const;
type Theme = "light" | "dark" | "system";

async function inspectSourceDiagnostics(group: Locator, source: "Backend" | "Queue", reasons: string[]) {
  const copy = group.locator(":scope > p");
  await expect(copy).toBeVisible();
  await expect(copy).toContainText(`${source} observation unavailable`);
  const diagnostics = group.locator("details.ops-disclosure");
  await expect(diagnostics.locator("pre")).not.toBeVisible();
  await diagnostics.locator("summary").click();
  await expect(diagnostics.locator("pre")).toBeVisible();
  for (const reason of reasons) await expect(diagnostics.locator("pre")).toContainText(reason);
  await diagnostics.locator("summary").click();
}

async function openScenario(page: import("@playwright/test").Page, url: string, scenario: string, theme: Theme, width: number) {
  await page.setViewportSize({ width, height: 960 });
  await page.emulateMedia({ colorScheme: theme === "system" ? "dark" : theme });
  const separator = url.includes("?") ? "&" : "?";
  await page.goto(`${url}${separator}scenario=${scenario}`);
  const live = page.locator("[data-phx-main]");
  await expect(live).toHaveClass(/phx-connected/);
  const preference = page.locator(`#theme-toggle [data-phx-theme="${theme}"]`);
  await preference.click();
  await expect(preference).toHaveAttribute("aria-pressed", "true");
  await expect(page.getByRole("heading", { name: "Search health", exact: true })).toBeVisible();
  await expect(page.locator("html")).toHaveAttribute("data-theme-effective", theme === "system" ? "dark" : theme);
  await expect(page.locator("html")).toHaveAttribute("data-theme-preference", theme);
}

for (const entrypoint of ENTRYPOINTS) {
  for (const theme of ["light", "dark", "system"] as const) {
    for (const width of [390, 1279, 1280, 1440]) {
      test(`${entrypoint.name} status sources stay truthful in ${theme} at ${width}px`, async ({ page }) => {
        const captureDir = join(process.cwd(), "test-results", "phase173-status-captures");
        mkdirSync(captureDir, { recursive: true });
        let neutralReference: { verdictBackground: string; verdictBorder: string; rowBackground: string; rowBorder: string } | undefined;
        for (const scenario of scenarios) {
          await openScenario(page, entrypoint.url, scenario, theme, width);
          // State surfaces settle together after route/theme patches.
          await page.waitForTimeout(250);
          const rows = page.locator('[data-testid="posture-row"]');

          if (scenario === "empty") {
            await expect(page.getByText("No schemas configured", { exact: true })).toBeVisible();
            await expect(rows).toHaveCount(0);
            await expect(page.locator(".ops-metric")).toHaveCount(0);
          } else {
            await expect(rows).toHaveCount(scenario === "partial" ? 1 : 2);
            for (const id of entrypoint.rows.slice(0, scenario === "partial" ? 1 : 2)) {
              const row = page.locator(`[id="${id}"]`);
              await expect(row).toBeVisible();
              await expect(row.locator("h3")).toContainText(id.replace("posture-", ""));
              await expect(row.locator("h3")).toHaveCSS("overflow-wrap", "anywhere");
            }
            await expect(page.getByTestId("health-schema-count")).toContainText(scenario === "partial" ? "1 schema" : "2 schemas");
            await expandHealthDetails(page);
            await expect(page.locator(".ops-metric-success")).toHaveCount(0);
          }

          if (scenario === "failed") {
            await expect(page.locator(".ops-verdict")).toContainText("Sync needs attention");
            await expect(page.locator(".ops-verdict")).toContainText(/sync failures? needs? review/);
            await expect(page.getByTestId("posture-failed-sync-link").first()).toBeVisible();
            await expect(page.locator(".ops-metric-warning").first()).toBeVisible();
          } else if (scenario === "unknown") {
            // The unknown Meilisearch status fails source decoding explicitly;
            // it must not be represented as zero or as remote terminal failure.
            await inspectSourceDiagnostics(rows.first().locator(".ops-signal-group").first(), "Backend", ["invalid_task_payload", "mystery", "status: :unknown"]);
            await expect(rows.first()).not.toContainText("backend failed");
            await expect(page.locator(".ops-metric")).toHaveCount(1);
            await expect(page.locator(".ops-metric")).toContainText("Incomplete checks");
          } else if (scenario === "source-error") {
            await inspectSourceDiagnostics(rows.first().locator(".ops-signal-group").first(), "Backend", [":fixture_unavailable"]);
            await expect(rows.first()).toContainText("Not observed");
            await expect(page.locator(".ops-verdict")).toContainText("Sync needs attention");
          } else if (scenario === "manual") {
            await expect(rows.first()).toContainText("Queue not used in manual sync mode.");
          } else if (scenario === "no-success") {
            await expect(rows.first().locator("[aria-label^='Backend task health']")).toContainText("No success observed");
          } else if (scenario === "partial") {
            await expect(rows).toHaveCount(1);
            await expect(page.getByTestId("health-schema-count")).toContainText("1 schema");
          }

          if (["default", "failed"].includes(scenario)) {
            const surfaces = await page.evaluate(() => {
              const verdict = document.querySelector<HTMLElement>(".ops-verdict")!;
              const row = document.querySelector<HTMLElement>(".ops-schema-signal-card")!;
              const verdictStyle = getComputedStyle(verdict);
              const rowStyle = getComputedStyle(row);
              return {
                verdictBackground: verdictStyle.backgroundColor,
                verdictBorder: verdictStyle.borderColor,
                rowBackground: rowStyle.backgroundColor,
                rowBorder: rowStyle.borderColor
              };
          });
          if (scenario === "default") neutralReference = surfaces;
          if (scenario === "failed") expect(surfaces).toEqual(neutralReference);
        }

        const dimensions = await page.evaluate(() => ({
          viewport: document.documentElement.clientWidth,
          document: document.documentElement.scrollWidth,
          rowGap: (() => {
            const list = document.querySelector(".ops-schema-signal-list");
            return list ? getComputedStyle(list).rowGap : null;
          })()
        }));
        expect(dimensions.document).toBeLessThanOrEqual(dimensions.viewport);
        if (scenario !== "empty") expect(Number.parseFloat(dimensions.rowGap ?? "0")).toBeGreaterThanOrEqual(24);

        const refresh = page.getByRole("button", { name: "Refresh search health" });
        const refreshBox = await refresh.boundingBox();
        expect(refreshBox).not.toBeNull();
        expect(refreshBox!.height).toBeGreaterThanOrEqual(40);
        const checked = refresh.locator("..").locator("time");
        await expect(checked).toBeVisible();
        await expect(checked).toHaveCSS("font-size", "14px");
        expect(await checked.evaluate((time) => getComputedStyle(time).fontFamily))
          .toBe(await page.locator("body").evaluate((body) => getComputedStyle(body).fontFamily));
        if ([390, 1440].includes(width) && ["default", "failed"].includes(scenario)) {
          await page.evaluate(() => window.scrollTo(0, 0));
          await page.screenshot({ path: join(captureDir, `phase173-${entrypoint.name}-${scenario}-${theme}-${width}.png`), fullPage: true });
        }
      }
      });
    }
  }

  test(`${entrypoint.name} partial queue failure retains only queue evidence and empty queues stay observed`, async ({ page }) => {
    const captureDir = join(process.cwd(), "test-results", "phase173-status-captures");
    mkdirSync(captureDir, { recursive: true });
    await openScenario(page, entrypoint.url, "default", "light", 390);
    const row = page.locator(`[id="${entrypoint.rows[0]}"]`);
    await expect(row.locator(".ops-badge-success")).toHaveCount(0);
    await expandHealthDetails(page);
    await expect(row.locator(".ops-signal-metrics dt").filter({ hasText: /^(Pending|Failed|Retrying)$/ })).toHaveCount(0);
    await page.getByRole("button", { name: "Refresh search health" }).evaluate((button) =>
      button.setAttribute("phx-value-scenario", "queue-error")
    );
    await page.getByRole("button", { name: "Refresh search health" }).click();
    const backend = row.locator(".ops-signal-group").first();
    const queue = row.locator(".ops-signal-group").nth(1);
    await inspectSourceDiagnostics(queue, "Queue", [":fixture_queue_unavailable"]);
    await expect(backend.locator("time.ops-time__value")).toHaveText("3 days ago");
    await expect(backend.locator(".ops-signal-metrics")).toBeVisible();
    await expect(backend).not.toContainText("observation unavailable");
    await expect(queue.locator("time.ops-time__value")).toHaveText("2 days ago");
    await expect(queue).toContainText("Queue observation unavailable");
    await expect(queue.locator(".ops-time__exact")).toHaveText("2026-10-04T13:02:05.123456-04:00");
    await expect(queue.locator(".ops-time__copy")).toBeVisible();
    await expect(queue.locator(".ops-signal-metrics")).toHaveCount(0);
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);

    await page.getByRole("button", { name: "Refresh search health" }).evaluate((button) =>
      button.setAttribute("phx-value-scenario", "all-source-error")
    );
    await page.getByRole("button", { name: "Refresh search health" }).click();
    await inspectSourceDiagnostics(backend, "Backend", [":fixture_unavailable"]);
    await expect(backend.locator("time.ops-time__value")).toHaveText("3 days ago");
    await inspectSourceDiagnostics(queue, "Queue", [":fixture_queue_unavailable"]);
    await expect(queue.locator("time.ops-time__value")).toHaveText("2 days ago");
    await expect(queue.locator(".ops-time__exact")).toHaveText("2026-10-04T13:02:05.123456-04:00");
    await page.screenshot({ path: join(captureDir, `phase173-${entrypoint.name}-all-source-error-light-390.png`), fullPage: true });

    await openScenario(page, entrypoint.url, "empty-queue", "dark", 1440);
    await expandHealthDetails(page);
    await expect(queue.locator(".ops-signal-metrics dt").filter({ hasText: /^(Pending|Failed|Retrying)$/ })).toHaveCount(0);
    await expect(queue.locator(".ops-signal-metrics")).toBeVisible();
    await expect(queue).toContainText("No success observed");
    await expect(queue).not.toContainText("unavailable");
  });

  test(`${entrypoint.name} neutral chrome and metrics preserve the approved palette`, async ({ page }) => {
    for (const theme of ["light", "dark", "system"] as const) {
      await openScenario(page, entrypoint.url, "failed", theme, 390);
      await page.waitForTimeout(250);
      const colors = await page.evaluate(() => {
        const canvas = document.createElement("canvas");
        canvas.width = canvas.height = 1;
        const context = canvas.getContext("2d")!;
        const sample = (selector: string) => {
          context.clearRect(0, 0, 1, 1);
          context.fillStyle = getComputedStyle(document.querySelector(selector)!).backgroundColor;
          context.fillRect(0, 0, 1, 1);
          return Array.from(context.getImageData(0, 0, 1, 1).data).slice(0, 3);
        };
        return { header: sample(".ops-header"), metric: sample(".ops-muted-panel") };
      });
      const expected = theme === "light"
        ? { header: [255, 255, 255], metric: [237, 239, 242] }
        : { header: [25, 30, 37], metric: [34, 40, 49] };
      for (const role of ["header", "metric"] as const) {
        colors[role].forEach((channel, index) => {
          expect(Math.abs(channel - expected[role][index]), `${theme} ${role} channel ${index}`).toBeLessThanOrEqual(2);
        });
      }
    }
  });

  test(`${entrypoint.name} refresh keeps server eligibility after a LiveView patch`, async ({ page }) => {
    await page.goto(entrypoint.url);
    const live = page.locator("[data-phx-main]");
    await expect(live).toHaveClass(/phx-connected/);

    const refresh = page.getByRole("button", { name: "Refresh search health" });
    await expect(refresh).toBeEnabled();
    // Select a deterministic server fixture for the real LiveView event. This
    // only changes the event input; disabled state must arrive in a server patch.
    await refresh.evaluate((button) => button.setAttribute("phx-value-scenario", "eligibility-disabled"));
    await refresh.click();

    await expect(page.getByText("Refresh is disabled by the phase 173 eligibility fixture.")).toBeVisible();
    await expect(refresh).toBeDisabled();
    await expect(refresh.locator("svg")).toBeVisible();
    await expect(refresh.locator("span")).toHaveText("Refresh");
  });

  test(`${entrypoint.name} quiet action exposes independent focus and transient interaction states`, async ({ page }) => {
    await openScenario(page, entrypoint.url, "default", "light", 1440);
    const refresh = page.getByRole("button", { name: "Refresh search health" });
    await refresh.focus();
    // Enter keyboard modality, then return focus to the action to exercise
    // :focus-visible rather than the browser's programmatic-focus styling.
    await page.keyboard.press("Tab");
    await page.keyboard.press("Shift+Tab");
    await expect(refresh).toBeFocused();
    const focus = await refresh.evaluate((button) => ({
      width: getComputedStyle(button).outlineWidth,
      style: getComputedStyle(button).outlineStyle,
      offset: getComputedStyle(button).outlineOffset
    }));
    expect(focus).toEqual({ width: "2px", style: "solid", offset: "2px" });

    const before = await refresh.evaluate((button) => getComputedStyle(button).backgroundColor);
    await refresh.hover();
    const hover = await refresh.evaluate((button) => getComputedStyle(button).backgroundColor);
    expect(hover).not.toBe(before);
    await page.mouse.down();
    const pressed = await refresh.evaluate((button) => getComputedStyle(button).backgroundColor);
    expect(pressed).not.toBe(hover);
    await page.mouse.up();

    await refresh.click();
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await expect(refresh).toBeEnabled();
    await expect(refresh.locator("svg")).toBeVisible();
    await expect(refresh.locator("span")).toHaveText("Refresh");
  });
}
