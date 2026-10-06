import { expect, test } from "@playwright/test";

const ENTRYPOINTS = [
  { name: "mounted", url: "/admin/search/phase173/health" },
  {
    name: "standalone",
    url: process.env.PHASE173_OPS_BASE_URL ?? "http://ops:4003/ops/phase173/health"
  }
] as const;

for (const entrypoint of ENTRYPOINTS) {
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
  });
}
