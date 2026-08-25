/**
 * Deterministic shell wash visual gate (SHELL-DARK-01, Phase 135).
 *
 * The shell chrome proof already asserts the CSS contract. This spec renders the
 * actual `.ops-shell` background with page content hidden, then samples pixels so
 * "quiet top-left ambient glow, not a purple blob" is a CI-failing visual fact
 * rather than a human UAT row.
 *
 * HOW TO RUN (manual server per playwright.config.ts -- there is NO webServer):
 *   Boot the ecommerce dev lane against current source, then:
 *     cd examples/scrypath_ecommerce
 *     npm run test:e2e:admin-shell-wash -- --reporter=line
 */
import { expect, test, type Browser, type Page } from "@playwright/test";
import { PNG } from "pngjs";

import { seedScenario } from "./helpers/e2e";
import {
  assertSystemDarkInvariants,
  gotoControlRoom,
  gotoFailedSync,
  gotoPlaybooks,
  gotoPosture,
  gotoSearch,
  gotoSyncDrift,
  THEME_MODES,
  themeSlug,
  VIEWPORT_NAMES,
  VIEWPORTS,
  type ThemeMode,
  type ViewportName
} from "./helpers/theme-grid";

type PngImage = {
  width: number;
  height: number;
  data: Uint8Array;
};

type Rgb = [number, number, number];

type ShellSurface = {
  name: string;
  prepare: (page: Page) => Promise<void>;
};

const DARK_THEME_MODES = THEME_MODES.filter(
  (mode) => (mode.kind === "explicit" && mode.theme === "dark") || mode.kind === "system"
);

const SHELL_SURFACES: ShellSurface[] = [
  { name: "Control Room", prepare: gotoControlRoom },
  { name: "Posture", prepare: gotoPosture },
  { name: "Failed Sync", prepare: gotoFailedSync },
  { name: "Sync/Drift", prepare: gotoSyncDrift },
  { name: "Search", prepare: gotoSearch },
  { name: "Playbooks", prepare: gotoPlaybooks }
];

const PROBE_STYLE = `
  html[data-shell-wash-probe="true"],
  html[data-shell-wash-probe="true"] body {
    overflow: hidden !important;
  }

  html[data-shell-wash-probe="true"] #ops-main.ops-shell {
    height: 100vh !important;
    min-height: 100vh !important;
    overflow: hidden !important;
  }

  html[data-shell-wash-probe="true"] #ops-main.ops-shell > *,
  html[data-shell-wash-probe="true"] .ops-header,
  html[data-shell-wash-probe="true"] .ops-sidebar,
  html[data-shell-wash-probe="true"] .ops-mobile-nav,
  html[data-shell-wash-probe="true"] #flash-group,
  html[data-shell-wash-probe="true"] #ops-cmdk,
  html[data-shell-wash-probe="true"] #ops-cheatsheet {
    visibility: hidden !important;
  }
`;

async function newThemedPage(
  browser: Browser,
  mode: ThemeMode,
  viewport: ViewportName
): Promise<{ page: Page; close: () => Promise<void> }> {
  const context = await browser.newContext({
    viewport: VIEWPORTS[viewport],
    ...(mode.kind === "system" ? { colorScheme: mode.colorScheme as "dark" } : {})
  });

  if (mode.kind === "explicit") {
    await context.addInitScript(
      ([key, value]: [string, string]) => {
        window.localStorage.setItem(key, value);
      },
      ["phx:theme", mode.theme]
    );
  }

  const page = await context.newPage();
  return { page, close: () => context.close() };
}

async function readComputedStyle(
  page: Page,
  selector: string,
  property: string
): Promise<string> {
  return page.evaluate(
    ([sel, prop]) => {
      const el = document.querySelector(sel);
      if (!el) throw new Error(`shell wash probe: element not found for ${sel}`);
      return getComputedStyle(el).getPropertyValue(prop);
    },
    [selector, property] as const
  );
}

async function enableWashProbe(page: Page): Promise<PngImage> {
  await page.addStyleTag({ content: PROBE_STYLE });
  await page.evaluate(() => {
    document.documentElement.setAttribute("data-shell-wash-probe", "true");
  });

  const shell = page.locator("#ops-main.ops-shell");
  await expect(shell).toBeVisible();
  const image = PNG.sync.read(await shell.screenshot({ animations: "disabled" }));
  expect(image.width, "shell wash screenshot width").toBeGreaterThan(300);
  expect(image.height, "shell wash screenshot height").toBeGreaterThan(500);
  return image;
}

function pixel(image: PngImage, x: number, y: number): Rgb {
  const boundedX = Math.max(0, Math.min(image.width - 1, Math.round(x)));
  const boundedY = Math.max(0, Math.min(image.height - 1, Math.round(y)));
  const index = (boundedY * image.width + boundedX) * 4;
  return [image.data[index], image.data[index + 1], image.data[index + 2]];
}

function sample(image: PngImage, x: number, y: number, radius = 8): Rgb {
  const channels = [0, 0, 0];
  let count = 0;

  for (let yy = y - radius; yy <= y + radius; yy += 4) {
    for (let xx = x - radius; xx <= x + radius; xx += 4) {
      const [r, g, b] = pixel(image, xx, yy);
      channels[0] += r;
      channels[1] += g;
      channels[2] += b;
      count += 1;
    }
  }

  return [channels[0] / count, channels[1] / count, channels[2] / count];
}

function colorDistance(a: Rgb, b: Rgb): number {
  return Math.sqrt(
    (a[0] - b[0]) ** 2 +
      (a[1] - b[1]) ** 2 +
      (a[2] - b[2]) ** 2
  );
}

function violetScore([r, g, b]: Rgb): number {
  return (r + b) / 2 - g;
}

function washBias(sampleColor: Rgb, floorColor: Rgb): number {
  return violetScore(sampleColor) - violetScore(floorColor);
}

function assertShellWashImage(image: PngImage, viewport: ViewportName, label: string): void {
  const margin = viewport === "mobile" ? 28 : 36;
  const near = sample(image, margin, margin);
  const midPoint = viewport === "mobile" ? 172 : 240;
  const farPoint = viewport === "mobile" ? 340 : 560;
  const mid = sample(image, Math.min(image.width - margin, midPoint), Math.min(image.height - margin, midPoint));
  const far = sample(image, Math.min(image.width - margin, farPoint), Math.min(image.height - margin, farPoint));
  const bottomLeft = sample(image, margin, image.height - margin);
  const bottomRight = sample(image, image.width - margin, image.height - margin);

  const nearBias = washBias(near, bottomRight);
  const midBias = washBias(mid, bottomRight);
  const farBias = washBias(far, bottomRight);

  console.info(
    `${label}: shell wash bias near=${nearBias.toFixed(2)} mid=${midBias.toFixed(2)} far=${farBias.toFixed(2)} bottom-edge-delta=${colorDistance(bottomLeft, bottomRight).toFixed(2)}`
  );

  expect(
    nearBias,
    `${label}: top-left wash must be visible enough to prove the brand glow exists`
  ).toBeGreaterThanOrEqual(1.1);
  expect(
    nearBias,
    `${label}: top-left wash must stay quiet, not a saturated blob`
  ).toBeLessThanOrEqual(24);
  expect(
    midBias,
    `${label}: violet wash must decay away from the top-left origin`
  ).toBeLessThan(nearBias);
  expect(
    farBias,
    `${label}: far diagonal sample must be close to the floor`
  ).toBeLessThanOrEqual(Math.max(2.2, nearBias * 0.4));
  expect(
    colorDistance(bottomLeft, bottomRight),
    `${label}: lower edge must not contain a second horizontal violet blob`
  ).toBeLessThanOrEqual(4.5);

  const allowedRadius = viewport === "mobile" ? 410 : 520;
  let outsideHot = 0;
  let outsideTotal = 0;

  for (let y = margin; y < image.height - margin; y += 18) {
    const rowFloor = sample(image, image.width - margin, y, 4);
    for (let x = margin; x < image.width - margin; x += 18) {
      if (Math.hypot(x, y) <= allowedRadius) continue;
      outsideTotal += 1;
      if (washBias(sample(image, x, y, 4), rowFloor) > 3.2) {
        outsideHot += 1;
      }
    }
  }

  const outsideHotRatio = outsideTotal === 0 ? 0 : outsideHot / outsideTotal;
  expect(
    outsideHotRatio,
    `${label}: violet pixels outside the bounded wash envelope`
  ).toBeLessThanOrEqual(0.015);
}

async function expectShellWashGradientContract(page: Page, viewport: ViewportName): Promise<void> {
  const background = await readComputedStyle(page, ".ops-shell", "background-image");
  const radialCount = (background.match(/radial-gradient/g) ?? []).length;
  const linearCount = (background.match(/linear-gradient/g) ?? []).length;
  expect(radialCount, ".ops-shell should keep exactly one radial wash").toBe(1);
  expect(linearCount, ".ops-shell should keep exactly one floor gradient").toBe(1);
  expect(background, ".ops-shell wash must originate at top left").toMatch(
    /at (left top|0% 0%|0px 0px)/
  );
  expect(
    background,
    viewport === "mobile" ? "mobile wash should fade by the 24rem contract" : "desktop wash should fade by the 30rem contract"
  ).toMatch(viewport === "mobile" ? /(384px|24rem)/ : /(480px|30rem)/);
}

test.describe("admin shell wash -- SHELL-DARK-01", () => {
  test.describe.configure({ timeout: 120_000 });

  for (const mode of DARK_THEME_MODES) {
    for (const viewport of VIEWPORT_NAMES) {
      test(`[shell-wash] quiet bounded wash (${themeSlug(mode)}, ${viewport})`, async ({
        browser,
        request
      }) => {
        await seedScenario(request, "incident");

        const { page, close } = await newThemedPage(browser, mode, viewport);
        try {
          for (const surface of SHELL_SURFACES) {
            await surface.prepare(page);

            if (mode.kind === "system") {
              await assertSystemDarkInvariants(page);
            }

            await expectShellWashGradientContract(page, viewport);
            const image = await enableWashProbe(page);
            assertShellWashImage(image, viewport, `${surface.name} ${themeSlug(mode)} ${viewport}`);
          }
        } finally {
          await close();
        }
      });
    }
  }
});
