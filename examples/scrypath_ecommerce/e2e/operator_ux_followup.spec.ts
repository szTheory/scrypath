import { AxeBuilder } from "@axe-core/playwright";
import { expect, test, type Page } from "@playwright/test";
import { assertOperatorGeometry } from "./helpers/operator-ui";
import { waitForLiveConnected } from "./helpers/e2e";

// Read-only follow-up proof: no seed, recovery mutation, or persisted file change.
const surfaces = [
  ["", "Control Room"], ["/health", "Search health"],
  ["/failed-sync", "Failed sync work"], ["/sync-drift", "Sync and drift"],
  ["/search", "Search"], ["/playbooks", "Saved playbooks"]
] as const;
const schema = "ScrypathEcommerce.Catalog.Product";
const draft = JSON.stringify({ playbook_format: 1, mode: "search", schema, q: "quantum", opts: { page: { size: 2 } } });

async function open(page: Page, suffix: string, theme: string) {
  await page.goto(`/admin/search${suffix}`);
  await waitForLiveConnected(page);
  await page.locator(`#theme-toggle [data-phx-theme='${theme}']`).click();
  await expect(page.locator("html")).toHaveAttribute("data-theme-effective", theme);
}

for (const width of [1440, 390]) for (const theme of ["light", "dark"]) {
  for (const [suffix, heading] of surfaces) {
    test(`UX inventory ${heading} ${width} ${theme}`, async ({ page }, info) => {
      await page.setViewportSize({ width, height: 900 });
      await open(page, suffix, theme);
      await expect(page.locator("#ops-main h1")).toHaveCount(1);
      await expect(page.getByRole("heading", { name: heading, exact: true, level: 1 })).toBeVisible();
      await assertOperatorGeometry(page, heading, [".ops-command-hint", "#theme-toggle"]);
      const labelFit = await page.locator(".ops-command-hint").evaluate(button => {
        const bounds = button.getBoundingClientRect();
        return Array.from(button.querySelectorAll("span")).filter(span => getComputedStyle(span).display !== "none").every(span => {
          const r = span.getBoundingClientRect(); return r.left >= bounds.left && r.right <= bounds.right;
        });
      });
      expect(labelFit).toBe(true);
      if (width === 390) for (const selector of [".ops-help__trigger", ".ops-time__disclosure > summary", ".ops-segmented-btn"]) {
        const heights = await page.locator(selector).evaluateAll(nodes => nodes.filter(node => node.checkVisibility()).map(node => node.getBoundingClientRect().height));
        for (const height of heights) expect(height, selector).toBeGreaterThanOrEqual(44);
      }
      if (suffix === "" || suffix === "/health") await expect(page.getByTestId("recovery-target")).toHaveCount(0);
      const contrast = await new AxeBuilder({ page }).include("#ops-main").withRules(["color-contrast"]).analyze();
      await info.attach("contrast.json", { body: JSON.stringify(contrast, null, 2), contentType: "application/json" });
      expect(contrast.violations).toEqual([]);
      await info.attach("after.png", { body: await page.screenshot({ fullPage: true }), contentType: "image/png" });
    });
  }

  test(`UX recovery and configuration ${width} ${theme}`, async ({ page }) => {
    await page.setViewportSize({ width, height: 900 });
    await open(page, "/health", theme);
    const row = page.getByTestId("posture-row").filter({ hasText: schema });
    await expect(row).toBeVisible();
    const details = row.locator("details.ops-schema-health");
    if ((await details.getAttribute("open")) === null) await details.locator("summary").click();
    const sync = row.getByTestId("posture-sync-link");
    const hasPending = (await row.getByTestId("schema-health-status").innerText()).includes("pending");
    if (await sync.count()) {
      await expect(sync).toHaveAttribute("href", `/admin/search/sync-drift?schema=${schema}`);
      await sync.click();
    } else {
      const failed = row.getByTestId("posture-failed-sync-link");
      await expect(failed).toBeVisible();
      await expect(failed).toHaveAttribute("href", `/admin/search/failed-sync?schema=${schema}`);
      await failed.click();
      await waitForLiveConnected(page);
      if (width < 1280) await page.getByRole("button", { name: "Open navigation" }).click();
      await page.locator(width < 1280 ? "#ops-mobile-nav" : ".ops-sidebar").getByRole("link", { name: "Sync and drift", exact: true }).click();
    }
    await waitForLiveConnected(page);
    await expect(page.getByRole("radio", { name: new RegExp(schema) })).toBeChecked();
    if (hasPending) await expect(page.locator("#sync-work-status")).toContainText("pending");
    else await expect(page.locator("#sync-work-status")).not.toBeEmpty();
    await expect(page.getByTestId("configuration-not-checked")).toBeVisible();
    await page.getByRole("button", { name: "Check index configuration", exact: true }).click();
    await expect(page.getByTestId("configuration-details")).toBeAttached();
    const matches = await page.getByText("Index configuration matches", { exact: true }).isVisible();
    if (matches) {
      await expect(page.getByTestId("configuration-details")).not.toHaveAttribute("open");
      await page.getByTestId("configuration-details").locator("summary").click();
    } else {
      await expect(page.getByText("Index configuration differs", { exact: true })).toBeVisible();
      await expect(page.getByTestId("configuration-details")).toHaveAttribute("open", "");
    }
    await expect(page.locator(".ops-table-scroll").first()).toBeVisible();
    const contrast = await new AxeBuilder({ page }).include(".ops-table-scroll").withRules(["color-contrast"]).analyze();
    expect(contrast.violations).toEqual([]);
    await page.getByRole("link", { name: /Review search health/ }).last().click();
    await expect(page).toHaveURL(url => url.pathname.endsWith("/health") && !url.searchParams.has("schema"));
  });

  test(`UX search and playbook input identity ${width} ${theme}`, async ({ page }) => {
    await page.setViewportSize({ width, height: 900 });
    await open(page, "/search", theme);
    await expect(page.getByRole("button", { name: "Run search", exact: true })).toHaveCount(1);
    await expect(page.locator("#search-options")).not.toHaveAttribute("open");
    await page.locator("#search-options > summary").click();
    await page.getByLabel("Result limit", { exact: true }).fill("2");
    await page.getByLabel("Search text").fill("quantum");
    await page.locator("#search-options > summary").click();
    await page.getByRole("button", { name: "Run search", exact: true }).click();
    await expect(page.locator("#search-completion-status")).toContainText("quantum");
    await expect(page.locator("#search-completion-status")).toHaveAttribute("aria-live", "polite");
    await expect(page).toHaveURL(/page_size=2/);
    await page.getByLabel("Search text").fill("edited but not run");
    await expect(page.locator("#search-completion-status")).toContainText("quantum");
    await expect(page.locator("#search-completion-status")).not.toContainText("edited but not run");
    await page.getByRole("button", { name: "Save as playbook", exact: true }).click();
    await expect(page.getByLabel("Filename (.json)", { exact: true })).toBeVisible();
    await expect(page.getByTestId("search-capture-preview-pre")).toContainText('"q": "quantum"');

    await open(page, "/playbooks", theme);
    const row = page.locator(".ops-object-item").first();
    await expect(row).toBeVisible();
    const names = await page.getByRole("button", { name: /^Load preview of / }).allTextContents();
    expect(names.length).toBeGreaterThan(0);
    await expect(row.getByRole("button", { name: /^Rename / })).toBeHidden();
    await row.locator("details > summary").click();
    const rename = row.getByRole("button", { name: /^Rename / });
    await rename.click();
    await expect(page.locator("#rename-new-name-input")).toBeFocused();
    await page.locator("#rename-new-name-input").fill("invalid/name.json");
    await expect(page.locator("#rename-new-name-input")).toBeFocused();
    await page.locator("#rename-playbook-modal [data-ops-modal-cancel]").click();
    await expect(rename).toBeFocused();
    await row.getByRole("button", { name: /^Load preview of / }).click();
    await expect(page.locator("#playbook-run-origin")).toContainText("Loaded file:");
    const previous = await page.locator("#playbook-run-origin").innerText();
    await page.locator("#playbook-import > summary").click();
    await page.locator("#playbook-paste > summary").click();
    await page.locator("#playbook-paste-json").fill(draft);
    await page.getByRole("button", { name: "Import from paste", exact: true }).click();
    await expect(page.locator("#playbook-run-origin")).toHaveText("Imported from pasted JSON");
    await expect(page.locator("#playbook-run-origin")).not.toHaveText(previous);
    await expect(page.locator("#playbook-paste")).toHaveAttribute("open", "");
    await page.locator("#playbook-import input[type=file]").setInputFiles({ name: "audit-draft.json", mimeType: "application/json", buffer: Buffer.from(draft) });
    await page.getByRole("button", { name: "Import playbook JSON", exact: true }).click();
    await expect(page.getByTestId("playbook-preview-marker")).toBeVisible();
    await expect(page.locator("#playbook-run-origin")).toHaveText("Imported from uploaded JSON");
  });
}
