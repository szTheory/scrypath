import { expect, test } from "@playwright/test";

const standalone = process.env.PHASE174_OPS_BASE_URL ?? "http://ops:4003/ops/phase174";
const entries = [
  { name: "mounted", base: "/admin/search", schema: "ScrypathEcommerce.Catalog.Variant" },
  { name: "standalone", base: standalone, schema: "ScrypathOps.Test.OpsPostB" }
];

for (const entry of entries) {
  for (const width of [1440, 390]) {
    for (const theme of ["light", "dark"]) {
      test(`${entry.name} overall health and explicit recovery at ${width}px in ${theme}`, async ({ page }, info) => {
        test.setTimeout(60_000);
        await page.setViewportSize({ width, height: 900 });
        const errors: string[] = [];
        page.on("pageerror", error => errors.push(error.message));
        const mount = new URL(entry.base, "http://web:4002").pathname;
        const connected = async () => {
          await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
        };
        const openNavigation = async () => {
          if (width < 1280) await page.getByRole("button", { name: "Open navigation" }).click();
          return page.locator(width < 1280 ? "#ops-mobile-nav" : ".ops-sidebar");
        };
        const capture = async (name: string) => {
          await page.evaluate(() => window.scrollTo(0, 0));
          const path = info.outputPath(`${name}.png`);
          await page.screenshot({ path, fullPage: true });
          await info.attach(name, { path, contentType: "image/png" });
          expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(width);
        };

        // Old bookmarks normalize both overviews, even when the obsolete schema is invalid.
        for (const suffix of ["", "/health"]) {
          await page.goto(`${entry.base}${suffix}?schema=Removed.Schema&note=keep`);
          await connected();
          await expect(page).toHaveURL(url => url.pathname === `${mount}${suffix}` && !url.searchParams.has("schema") && url.searchParams.get("note") === "keep");
          await page.locator(`#theme-toggle [data-phx-theme='${theme}']`).click();
          await expect(page.getByTestId("recovery-target")).toHaveCount(0);
          await expect(page.getByText("That schema is unavailable", { exact: true })).toHaveCount(0);
          await expect(page.locator("#ops-command-palette-destinations")).not.toHaveAttribute("data-recovery-target");
          if (suffix === "/health") {
            await expect(page.getByTestId("posture-row")).toHaveCount(2);
            await expect(page.getByTestId("posture-next-checks")).toHaveCount(0);
            await expect(page.locator("#ops-main a").filter({ hasText: "View failed sync work" }).first()).toHaveAttribute("href", /schema=/);
          } else await expect(page.locator("#control-room-health-link")).toHaveAttribute("href", `${mount}/health`);
          await capture(suffix ? "health" : "control-room");
        }

        // Picking a row establishes scope where there is a real selector and scoped content.
        const row = page.getByTestId("posture-row").filter({ hasText: entry.schema });
        const details = row.locator("details.ops-schema-health");
        if (!(await details.evaluate(node => (node as HTMLDetailsElement).open))) {
          await row.locator("summary.ops-schema-health__summary").click();
        }
        await row.getByTestId("posture-failed-sync-link").click();
        await connected();
        await expect(page.getByRole("radio", { name: new RegExp(entry.schema.split(".").at(-1)!) })).toBeChecked();
        await expect(page.locator("#ops-command-palette-destinations")).toHaveAttribute("data-recovery-target", entry.schema);
        const nav = await openNavigation();
        await expect(nav.getByRole("link", { name: "Search health", exact: true })).toHaveAttribute("href", `${mount}/health`);
        await expect(nav.getByRole("link", { name: "Sync and drift", exact: true })).toHaveAttribute("href", `${mount}/sync-drift?schema=${entry.schema}`);
        await nav.getByRole("link", { name: "Search health", exact: true }).click();
        await connected();
        await expect(page).toHaveURL(url => url.pathname === `${mount}/health` && !url.searchParams.has("schema"));
        await expect(page.getByTestId("posture-row")).toHaveCount(2);
        await expect(page.getByTestId("recovery-target")).toHaveCount(0);

        // History returns to the exact chosen schema; reloading keeps that scoped choice.
        await page.goBack();
        await connected();
        await expect(page).toHaveURL(url => url.pathname.endsWith("/failed-sync") && url.searchParams.get("schema") === entry.schema);
        await page.reload();
        await connected();
        await expect(page.getByRole("radio", { name: new RegExp(entry.schema.split(".").at(-1)!) })).toBeChecked();
        await expect(page.locator("#ops-palette-destination-health")).toHaveAttribute("href", `${mount}/health`);
        await page.locator("[data-ops-command-open]").first().click();
        await expect(page.locator("#ops-cmdk-item-1")).toHaveAttribute("href", `${mount}/health`);
        await page.locator("#ops-cmdk-item-1").click();
        await connected();
        await expect(page.getByTestId("posture-row")).toHaveCount(2);
        await expect(page.getByTestId("recovery-target")).toHaveCount(0);
        expect(errors).toEqual([]);
      });
    }
  }
}
