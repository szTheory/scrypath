import { expect, test, type Browser } from "@playwright/test";
import { mkdirSync } from "node:fs";
import { join } from "node:path";

const ENTRYPOINTS = [
  { name: "mounted", url: "/admin/search/phase173/health", row: "posture-ScrypathEcommerce.Catalog.Product" },
  {
    name: "standalone",
    url: process.env.PHASE173_OPS_BASE_URL ?? "http://ops:4003/ops/phase173/health",
    row: "posture-ScrypathOps.Test.OpsPostA"
  }
] as const;

const SOURCE_ISO = "2026-10-04T13:02:05.123456-04:00";

async function openPage(browser: Browser, width: number, theme: "light" | "dark") {
  const context = await browser.newContext({
    viewport: { width, height: 1000 },
    hasTouch: true,
    colorScheme: theme
  });
  await context.addInitScript((value) => {
    localStorage.setItem("phx:theme", value);
    const testWindow = window as typeof window & {
      __phase173ClipboardWrites: string[];
      __phase173ResolveClipboardWrite: (() => void) | null;
    };
    testWindow.__phase173ClipboardWrites = [];
    testWindow.__phase173ResolveClipboardWrite = null;
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: {
        writeText(text: string) {
          testWindow.__phase173ClipboardWrites.push(text);
          return new Promise<void>((resolve) => {
            testWindow.__phase173ResolveClipboardWrite = resolve;
          });
        }
      }
    });
  }, theme);
  const page = await context.newPage();
  return { context, page };
}

for (const entrypoint of ENTRYPOINTS) {
  test(`${entrypoint.name} copies one exact operational timestamp after clipboard resolution`, async ({ browser }) => {
    test.setTimeout(90_000);
    const captureDir = join(process.cwd(), "test-results", "phase173-copy-captures");
    mkdirSync(captureDir, { recursive: true });

    for (const width of [390, 1440]) {
      for (const theme of ["light", "dark"] as const) {
        const { context, page } = await openPage(browser, width, theme);
        await page.goto(entrypoint.url);
        await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
        const row = page.locator(`[id="${entrypoint.row}"]`);
        await expect(row).toBeVisible();
        const time = row.locator(".ops-signal-group").first().locator(".ops-time").first();
        await expect(time.locator(".ops-time__exact")).toHaveText(SOURCE_ISO);

        const copy = time.getByRole("button", { name: "Copy timestamp", exact: true });
        await expect(copy).toBeVisible();
        await copy.click();
        await expect.poll(() => page.evaluate(() =>
          (window as typeof window & { __phase173ClipboardWrites: string[] }).__phase173ClipboardWrites
        )).toEqual([SOURCE_ISO]);

        const feedback = time.locator("[data-ops-time-feedback-text]");
        await expect(feedback).not.toContainText("Timestamp copied");
        await page.evaluate(() =>
          (window as typeof window & { __phase173ResolveClipboardWrite: (() => void) | null })
            .__phase173ResolveClipboardWrite?.()
        );
        await expect(feedback).toHaveText("Timestamp copied");
        await expect(time.locator("time.ops-time__value")).toHaveText("2 days ago");

        await page.evaluate(() => window.scrollTo(0, 0));
        await page.screenshot({
          path: join(captureDir, `phase173-copy-${entrypoint.name}-${width}-${theme}-success.png`),
          fullPage: true
        });
        await context.close();
      }
    }
  });

  test(`${entrypoint.name} keeps the latest clipboard outcome when writes settle out of order`, async ({ browser }) => {
    const { context, page } = await openPage(browser, 390, "light");
    await page.goto(entrypoint.url);
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    const time = page.locator(`[id="${entrypoint.row}"] .ops-signal-group`).first().locator(".ops-time").first();
    const copy = time.getByRole("button", { name: "Copy timestamp", exact: true });
    const feedback = time.locator("[data-ops-time-feedback-text]");
    await page.evaluate(() => {
      const testWindow = window as typeof window & {
        __phase173QueuedWrites: Array<{ resolve: () => void; reject: (error: Error) => void }>;
      };
      testWindow.__phase173QueuedWrites = [];
      Object.defineProperty(navigator, "clipboard", {
        configurable: true,
        value: {
          writeText() {
            return new Promise<void>((resolve, reject) => {
              testWindow.__phase173QueuedWrites.push({ resolve, reject });
            });
          }
        }
      });
    });

    await copy.click();
    await expect.poll(() => page.evaluate(() =>
      (window as typeof window & { __phase173QueuedWrites: unknown[] }).__phase173QueuedWrites.length
    )).toBe(1);
    await copy.click();
    await expect.poll(() => page.evaluate(() =>
      (window as typeof window & { __phase173QueuedWrites: unknown[] }).__phase173QueuedWrites.length
    )).toBe(2);
    await page.evaluate(() =>
      (window as typeof window & {
        __phase173QueuedWrites: Array<{ resolve: () => void; reject: (error: Error) => void }>;
      }).__phase173QueuedWrites[1].reject(new Error("denied"))
    );
    await expect(feedback).toHaveText("Could not copy timestamp. Select and copy the exact value.");
    await expect(time.locator("details")).toHaveAttribute("open", "");

    await page.evaluate(() =>
      (window as typeof window & {
        __phase173QueuedWrites: Array<{ resolve: () => void; reject: (error: Error) => void }>;
      }).__phase173QueuedWrites[0].resolve()
    );
    await expect(feedback).toHaveText("Could not copy timestamp. Select and copy the exact value.");
    await expect(time.locator("details")).toHaveAttribute("open", "");
    await context.close();
  });
}
