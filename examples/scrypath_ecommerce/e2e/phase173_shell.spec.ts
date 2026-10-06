import { expect, test, type Page } from "@playwright/test";
import { mkdirSync } from "node:fs";
import { join } from "node:path";

const ENTRYPOINTS = [
  {
    name: "mounted",
    path: "/admin/search/phase173/health",
    expectedRows: [
      "posture-ScrypathEcommerce.Catalog.Product",
      "posture-ScrypathEcommerce.Catalog.Variant"
    ]
  },
  {
    name: "standalone",
    url: process.env.PHASE173_OPS_BASE_URL ?? "http://ops:4003/ops/phase173/health",
    expectedRows: ["posture-ScrypathOps.Test.OpsPostA", "posture-ScrypathOps.Test.OpsPostB"]
  }
] as const;

async function expectThemePreference(page: Page, preference: "system" | "light" | "dark") {
  const root = page.locator("html");
  const selected = page.locator(`#theme-toggle [data-phx-theme][data-theme-selected="true"]`);
  await expect(root).toHaveAttribute("data-theme-preference", preference);
  await expect(selected).toHaveCount(1);
  await expect(selected).toHaveAttribute("data-phx-theme", preference);
  await expect(selected).toHaveAttribute("aria-pressed", "true");
}

async function openEntrypoint(page: Page, entrypoint: (typeof ENTRYPOINTS)[number]) {
  await page.goto("url" in entrypoint ? entrypoint.url : entrypoint.path);
  await expect(page.getByRole("heading", { name: "Search health", exact: true })).toBeVisible();
  await expect(page.locator(".ops-shell")).toBeVisible();
  await expect(page.locator("#theme-toggle")).toBeVisible();
  for (const row of entrypoint.expectedRows) {
    // Module names contain periods, so use an attribute selector rather than
    // letting CSS interpret each period as a class boundary.
    await expect(page.locator(`[id="${row}"]`)).toBeVisible();
  }

  const assetStatuses = await page.evaluate(async () => {
    const urls = [
      ...Array.from(document.querySelectorAll<HTMLLinkElement>('link[rel="stylesheet"]'), (el) => el.href),
      ...Array.from(document.querySelectorAll<HTMLScriptElement>("script[src]"), (el) => el.src)
    ].filter((url) => url.includes("/assets/"));
    return Promise.all(urls.map(async (url) => (await fetch(url, { method: "HEAD" })).status));
  });
  expect(assetStatuses.length, "page should load stylesheet and JavaScript assets").toBeGreaterThanOrEqual(2);
  expect(assetStatuses).toEqual(assetStatuses.map(() => 200));
}

function contrastRatio(foreground: string, background: string): number {
  const channels = (color: string) => color.match(/[\d.]+/g)?.slice(0, 3).map(Number);
  const luminance = (color: string) => {
    const rgb = channels(color);
    if (!rgb || rgb.length !== 3) throw new Error(`Could not parse computed color ${color}`);
    const linear = rgb.map((channel) => {
      const value = channel / 255;
      return value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4;
    });
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2];
  };
  const values = [luminance(foreground), luminance(background)].sort((a, b) => b - a);
  return (values[0] + 0.05) / (values[1] + 0.05);
}

test.describe("phase 173 operator shell", () => {
  for (const entrypoint of ENTRYPOINTS) {
    test(`${entrypoint.name} PostureLive keeps the preference visible and operational`, async ({ page, context }) => {
      await page.setViewportSize({ width: 1440, height: 960 });
      await page.emulateMedia({ colorScheme: "dark" });
      await openEntrypoint(page, entrypoint);
      await expectThemePreference(page, "system");
      await expect(page.locator("html")).not.toHaveAttribute("data-theme");
      await expect(page.locator("html")).toHaveAttribute("data-theme-effective", "dark");

      // Confirm the primary selected state remains readable in both explicit appearances.
      for (const theme of ["light", "dark"] as const) {
        const selectedThemeButton = page.locator(`#theme-toggle [data-phx-theme="${theme}"]`);
        await selectedThemeButton.click();
        await expectThemePreference(page, theme);
        // The component intentionally transitions color/surface over 120ms;
        // sample the settled composition rather than an in-between animation frame.
        await page.waitForTimeout(250);
        const colors = await page.locator(`#theme-toggle [data-phx-theme="${theme}"]`).evaluate((button) => ({
          foreground: getComputedStyle(button).color,
          background: (() => {
            const own = getComputedStyle(button).backgroundColor;
            return own === "rgba(0, 0, 0, 0)"
              ? getComputedStyle(button.parentElement!).backgroundColor
              : own;
          })()
        }));
        expect(contrastRatio(colors.foreground, colors.background), `${theme} selected theme contrast (${colors.foreground} on ${colors.background})`).toBeGreaterThanOrEqual(4.5);
      }

      const themeButton = (theme: string) => page.locator(`#theme-toggle [data-phx-theme="${theme}"]`);
      await themeButton("light").click();
      await expectThemePreference(page, "light");
      await expect(page.locator("html")).toHaveAttribute("data-theme", "light");
      await themeButton("dark").click();
      await expectThemePreference(page, "dark");
      await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
      await themeButton("light").focus();
      await page.keyboard.press("Space");
      await expectThemePreference(page, "light");

      const peer = await context.newPage();
      await openEntrypoint(peer, entrypoint);
      await peer.locator('#theme-toggle [data-phx-theme="dark"]').click();
      await expectThemePreference(page, "dark");
      await peer.close();

      await themeButton("system").click();
      await expectThemePreference(page, "system");
      await expect(page.locator("html")).not.toHaveAttribute("data-theme");
      await expect(page.locator("html")).toHaveAttribute("data-theme-effective", "dark");

      await page.emulateMedia({ colorScheme: "light" });
      await expect(page.locator("html")).toHaveAttribute("data-theme-effective", "light");
      await themeButton("dark").click();
      await expect(page.locator("html")).toHaveAttribute("data-theme-effective", "dark");
      await page.reload();
      await expectThemePreference(page, "dark");

      await page.evaluate(() => localStorage.setItem("phx:theme", "sepia"));
      await page.reload();
      await expectThemePreference(page, "system");

      // A blocked storage API must not break a user's in-page theme choice.
      await page.evaluate(() => {
        Object.defineProperty(window, "localStorage", {
          configurable: true,
          value: {
            getItem: () => { throw new DOMException("blocked", "SecurityError"); },
            setItem: () => { throw new DOMException("blocked", "SecurityError"); },
            removeItem: () => { throw new DOMException("blocked", "SecurityError"); }
          }
        });
      });
      await themeButton("light").click();
      await expectThemePreference(page, "light");
      await expect(page.locator("html")).toHaveAttribute("data-theme-effective", "light");

      // Long labels truncate within their nav target instead of widening the page.
      const navOverflow = await page.locator(".ops-sidebar .ops-nav-item__label").first().evaluate((label) => {
        label.textContent = "Search health with an exceptionally long operator destination label ".repeat(5);
        const styles = getComputedStyle(label);
        return {
          truncatesWithinLabel: styles.overflowX === "hidden" && styles.textOverflow === "ellipsis" && styles.whiteSpace === "nowrap",
          pageOverflow: document.documentElement.scrollWidth > document.documentElement.clientWidth
        };
      });
      expect(navOverflow.truncatesWithinLabel, "long nav text is contained by its label").toBe(true);
      expect(navOverflow.pageOverflow, "long nav text does not widen the viewport").toBe(false);

      // Broken wordmark requests leave the accessible home link intact.
      await page.setViewportSize({ width: 1440, height: 900 });
      await page.route("**/images/scrypath-wordmark*", (route) => route.abort());
      await page.reload();
      await expect(page.locator(".ops-sidebar__brand a")).toHaveAttribute("aria-label", "Scrypath home");
      await expect(page.locator(".ops-sidebar__brand a")).toHaveAttribute("href", entrypoint.name === "mounted" ? "/admin/search/phase173" : "/ops/phase173");
      await expect(page.locator(".ops-wordmark img").first()).toHaveJSProperty("naturalWidth", 0);
      await page.unroute("**/images/scrypath-wordmark*");

      // Reconnect feedback stays visible over the shared shell.
      await page.evaluate(() => {
        document.body.classList.add("phx-server-error");
        document.querySelector("#server-error")?.removeAttribute("hidden");
      });
      await expect(page.getByText("Attempting to reconnect", { exact: true }).last()).toBeVisible();
      await expect(page.locator("#theme-toggle")).toBeVisible();
      await expect(page.getByRole("button", { name: "Refresh search health" })).toBeVisible();
      await page.evaluate(() => {
        document.body.classList.remove("phx-server-error");
        document.querySelector("#server-error")?.setAttribute("hidden", "");
      });

      // The table's intentional horizontal overflow retains edge-shadow gradients.
      const scrollCue = await page.evaluate(() => {
        const scroller = document.createElement("div");
        scroller.className = "ops-table-scroll overflow-x-auto";
        scroller.style.cssText = "width: 240px; height: 80px; position: fixed; left: 0; bottom: 0";
        const wide = document.createElement("div");
        wide.style.cssText = "width: 600px; height: 80px";
        scroller.append(wide);
        document.body.append(scroller);
        const image = getComputedStyle(scroller).backgroundImage;
        const result = { canScroll: scroller.scrollWidth > scroller.clientWidth, hasLinear: image.includes("linear-gradient"), hasRadial: image.includes("radial-gradient") };
        scroller.scrollLeft = 40;
        result.canScroll = result.canScroll && scroller.scrollLeft === 40;
        scroller.remove();
        return result;
      });
      expect(scrollCue.canScroll).toBe(true);
      expect(scrollCue.hasLinear).toBe(true);
      expect(scrollCue.hasRadial).toBe(true);
    });

    test(`${entrypoint.name} shell fits the approved widths and produces theme captures`, async ({ page }) => {
      for (const width of [390, 1279, 1280, 1440]) {
        await page.setViewportSize({ width, height: 900 });
        for (const theme of ["light", "dark"] as const) {
          await page.emulateMedia({ colorScheme: theme });
          await page.addInitScript((value) => localStorage.setItem("phx:theme", value), theme);
          await openEntrypoint(page, entrypoint);
          await expectThemePreference(page, theme);

          const dimensions = await page.evaluate(() => ({
            viewport: document.documentElement.clientWidth,
            document: document.documentElement.scrollWidth,
            body: document.body.scrollWidth,
            shell: getComputedStyle(document.querySelector(".ops-shell")!).backgroundImage
          }));
          expect(dimensions.document, `${entrypoint.name} ${width}px ${theme} document overflow`).toBeLessThanOrEqual(dimensions.viewport);
          expect(dimensions.body, `${entrypoint.name} ${width}px ${theme} body overflow`).toBeLessThanOrEqual(dimensions.viewport);
          expect(dimensions.shell, "shared shell uses a flat background").toBe("none");

          if (width === 390 || width === 1440) {
            const captureDir = join(process.cwd(), "test-results", "phase173-captures");
            mkdirSync(captureDir, { recursive: true });
            await page.screenshot({
              path: join(captureDir, `phase173-${entrypoint.name}-${width}-${theme}.png`),
              fullPage: true
            });
          }
          await page.evaluate(() => localStorage.removeItem("phx:theme"));
        }
      }
    });
  }
});
