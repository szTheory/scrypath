/**
 * Focused shell chrome proof (SHELL-DARK-01, Phase 135 Plan 01).
 *
 * This is the Wave 0 scaffold for the shared operator chrome: header/nav, theme
 * toggle, command palette, shortcut sheet, flash, and the `.ops-shell` wash. It
 * intentionally reuses the theme-grid helpers so later plans can run focused
 * `--grep` slices before the full shell proof is expected to pass.
 *
 * HOW TO RUN (manual server per playwright.config.ts -- there is NO webServer):
 *   Boot the ecommerce dev lane against current source, then:
 *     cd examples/scrypath_ecommerce
 *     npm run test:e2e:admin-shell -- --reporter=line
 */
import { AxeBuilder } from "@axe-core/playwright";
import {
  expect,
  test,
  type APIRequestContext,
  type Browser,
  type Locator,
  type Page
} from "@playwright/test";
import { existsSync, readdirSync, unlinkSync } from "node:fs";
import { join } from "node:path";

import {
  drainSearchQueue,
  seedScenario,
  waitForSearchVisible
} from "./helpers/e2e";
import {
  assertSystemDarkInvariants,
  gotoControlRoom,
  gotoFailedSync,
  gotoPlaybooks,
  gotoPosture,
  gotoSearch,
  gotoSyncDrift,
  runSearch,
  THEME_MODES,
  themeSlug,
  VIEWPORT_NAMES,
  VIEWPORTS,
  type ThemeMode,
  type ViewportName
} from "./helpers/theme-grid";

const PLAYBOOK_WORKSPACE_DIR = join(process.cwd(), "priv/playbooks");
const SHELL_PLAYBOOK_PREFIX = "shell-chrome-";

type ShellSurface = {
  name: string;
  prepare: (page: Page) => Promise<void>;
  hasPrimaryNavItem: boolean;
};

const SHELL_SURFACES: ShellSurface[] = [
  { name: "Control Room", prepare: gotoControlRoom, hasPrimaryNavItem: true },
  { name: "Posture", prepare: gotoPosture, hasPrimaryNavItem: true },
  { name: "Failed Sync", prepare: gotoFailedSync, hasPrimaryNavItem: true },
  { name: "Sync/Drift", prepare: gotoSyncDrift, hasPrimaryNavItem: true },
  { name: "Search", prepare: gotoSearch, hasPrimaryNavItem: true },
  { name: "Playbooks", prepare: gotoPlaybooks, hasPrimaryNavItem: true }
];

function cleanupShellChromePlaybooks(): void {
  if (!existsSync(PLAYBOOK_WORKSPACE_DIR)) return;

  for (const name of readdirSync(PLAYBOOK_WORKSPACE_DIR)) {
    if (name.startsWith(SHELL_PLAYBOOK_PREFIX) && name.endsWith(".json")) {
      unlinkSync(join(PLAYBOOK_WORKSPACE_DIR, name));
    }
  }
}

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
      if (!el) throw new Error(`shell chrome probe: element not found for ${sel}`);
      return getComputedStyle(el).getPropertyValue(prop);
    },
    [selector, property] as const
  );
}

async function expectNoColorContrastViolations(
  page: Page,
  selectors: string[],
  label: string
): Promise<void> {
  const builder = new AxeBuilder({ page }).withRules(["color-contrast"]);
  let includedAny = false;

  for (const selector of selectors) {
    if ((await page.locator(selector).count()) > 0) {
      builder.include(selector);
      includedAny = true;
    }
  }

  expect(includedAny, `${label}: at least one selector should be present`).toBe(true);
  const results = await builder.analyze();
  expect(results.violations, `${label}: axe color-contrast violations`).toEqual([]);
}

async function activeElementInside(page: Page, selector: string): Promise<boolean> {
  return page.evaluate((sel) => {
    const root = document.querySelector(sel);
    const active = document.activeElement;
    return !!root && !!active && root.contains(active);
  }, selector);
}

async function pressCommandPaletteShortcut(page: Page): Promise<void> {
  await page.keyboard.press(process.platform === "darwin" ? "Meta+K" : "Control+K");
}

async function openCommandPalette(page: Page): Promise<void> {
  await pressCommandPaletteShortcut(page);
  await expect(page.locator("#ops-cmdk")).toBeVisible();
  await expect(page.locator("[data-cmdk-input]")).toBeFocused();
}

async function openShortcutSheet(page: Page): Promise<void> {
  await page.keyboard.press("Shift+/");
  await expect(page.locator("#ops-cheatsheet")).toBeVisible();
}

async function expectAriaModalTruth(
  page: Page,
  selector: "#ops-cmdk" | "#ops-cheatsheet",
  opener: Locator
): Promise<void> {
  const dialog = page.locator(selector);
  const modal = await dialog.getAttribute("aria-modal");

  if (modal === "true") {
    await expect(dialog).toHaveAttribute("role", "dialog");
    expect(await activeElementInside(page, selector), `${selector} initial focus must be inside`).toBe(true);

    await page.keyboard.press("Tab");
    expect(await activeElementInside(page, selector), `${selector} Tab focus must stay bounded`).toBe(true);

    await page.keyboard.press("Escape");
    await expect(dialog).toBeHidden();
    await expect(opener, `${selector} close should restore focus to its opener`).toBeFocused();
  } else {
    await expect(dialog).not.toHaveAttribute("aria-modal", "true");
    await page.keyboard.press("Escape");
    await expect(dialog).toBeHidden();
  }
}

async function expectOneSelectedCommandItem(page: Page): Promise<string> {
  const selected = page.locator("#ops-cmdk [data-cmdk-item][aria-selected='true']");
  await expect(selected).toHaveCount(1);

  const selectedId = await selected.first().getAttribute("id");
  expect(selectedId, "selected command item exposes a stable id").toBeTruthy();
  await expect(page.locator("[data-cmdk-input]")).toHaveAttribute(
    "aria-activedescendant",
    selectedId as string
  );

  return selectedId as string;
}

async function expectThemeRootState(page: Page, theme: "system" | "light" | "dark"): Promise<void> {
  await expect(page.locator("html")).toHaveAttribute("data-theme-preference", theme);

  if (theme === "system") {
    await expect(page.locator("html")).not.toHaveAttribute("data-theme");
  } else {
    await expect(page.locator("html")).toHaveAttribute("data-theme", theme);
    await expect(page.locator("html")).toHaveAttribute("data-theme-effective", theme);
  }
}

async function expectThemeButtonState(page: Page, theme: "system" | "light" | "dark"): Promise<void> {
  const selected = page.locator(`#theme-toggle [data-phx-theme="${theme}"]`);
  await expect(selected).toBeVisible();

  const selectedShadow = await selected.evaluate((el) => getComputedStyle(el).boxShadow);
  expect(selectedShadow, `${theme} theme button must expose a visible selected indicator`).not.toBe("none");

  const ariaPressed = await selected.getAttribute("aria-pressed");
  if (ariaPressed !== null) {
    expect(ariaPressed, `${theme} aria-pressed mirrors selected state`).toBe("true");
  }

  const ariaCurrent = await selected.getAttribute("aria-current");
  if (ariaCurrent !== null) {
    expect(["true", "page"].includes(ariaCurrent), `${theme} aria-current mirrors selected state`).toBe(true);
  }
}

async function expectShellWash(page: Page): Promise<void> {
  const background = await readComputedStyle(page, ".ops-shell", "background-image");
  const radialCount = (background.match(/radial-gradient/g) ?? []).length;
  expect(radialCount, ".ops-shell should keep one quiet radial wash").toBe(1);
  expect(background, ".ops-shell keeps its structural floor gradient").toContain("linear-gradient");
}

async function expectHeaderChrome(page: Page, viewport: ViewportName): Promise<void> {
  const header = page.locator(".ops-header");
  await expect(header).toBeVisible();

  const shadow = await readComputedStyle(page, ".ops-header", "box-shadow");
  const border = await readComputedStyle(page, ".ops-header", "border-bottom-color");
  expect(shadow, ".ops-header must read as a separated shell surface").not.toBe("none");
  expect(border, ".ops-header must expose a measurable divider").not.toBe("rgba(0, 0, 0, 0)");

  const headerBox = await header.boundingBox();
  expect(headerBox, ".ops-header must be measurable").not.toBeNull();
  if (!headerBox) return;

  const maxHeight = viewport === "desktop" ? 96 : 80;
  expect(
    headerBox.height,
    ".ops-header should stay compact as utility chrome"
  ).toBeLessThanOrEqual(maxHeight);

  if (viewport === "desktop") {
    const sidebar = page.locator(".ops-sidebar");
    await expect(sidebar, "desktop primary navigation should live in the sidebar").toBeVisible();
    await expect(page.locator("[data-ops-nav-open]"), "desktop should not show hamburger").toBeHidden();

    const sidebarBox = await sidebar.boundingBox();
    const mainBox = await page.locator("#ops-main").boundingBox();
    expect(sidebarBox, ".ops-sidebar must be measurable on desktop").not.toBeNull();
    expect(mainBox, "#ops-main must be measurable on desktop").not.toBeNull();
    if (!sidebarBox || !mainBox) return;

    expect(sidebarBox.width, ".ops-sidebar should keep a stable desktop rail width").toBeGreaterThan(
      240
    );
    expect(mainBox.x, "#ops-main should not sit underneath the fixed sidebar").toBeGreaterThanOrEqual(
      sidebarBox.width - 1
    );
  } else {
    await expect(page.locator(".ops-sidebar"), "mobile should hide desktop sidebar").toBeHidden();
    await expect(page.locator("[data-ops-nav-open]"), "mobile should expose hamburger").toBeVisible();
    await expect(page.locator("#ops-mobile-nav"), "mobile drawer starts closed").toBeHidden();
  }
}

async function expectActiveNavChrome(
  page: Page,
  viewport: ViewportName,
  surface: ShellSurface
): Promise<void> {
  const active = page.locator(".ops-nav-item-active");

  if (!surface.hasPrimaryNavItem) {
    await expect(active, `${surface.name} has no duplicate primary nav item`).toHaveCount(0);
    return;
  }

  await expect(active, `${surface.name} should mark active sidebar and drawer nav items`).toHaveCount(
    2
  );

  if (viewport === "desktop") {
    await expect(page.locator(".ops-nav-item-active:visible")).toHaveCount(1);
  } else {
    await expect(page.locator(".ops-nav-item-active:visible")).toHaveCount(0);
  }

  const bg = await readComputedStyle(page, ".ops-nav-item-active", "background-color");
  const color = await readComputedStyle(page, ".ops-nav-item-active", "color");
  const shadow = await readComputedStyle(page, ".ops-nav-item-active", "box-shadow");
  expect(bg, ".ops-nav-item-active must have a visible selected fill").not.toBe("rgba(0, 0, 0, 0)");
  expect(color, ".ops-nav-item-active must resolve readable text color").not.toBe("rgba(0, 0, 0, 0)");
  expect(shadow, ".ops-nav-item-active keeps shell depth/glow contract").not.toBe("none");
}

async function expectMobileNavigationDrawer(page: Page): Promise<void> {
  const opener = page.locator("[data-ops-nav-open]");
  const drawer = page.locator("#ops-mobile-nav");

  await expect(opener).toBeVisible();
  await expect(opener).toHaveAttribute("aria-expanded", "false");

  await opener.click();
  await expect(drawer).toBeVisible();
  await expect(opener).toHaveAttribute("aria-expanded", "true");
  await expect(drawer.locator(".ops-nav-item-active")).toBeVisible();
  await expectNoColorContrastViolations(page, ["#ops-mobile-nav"], "mobile navigation drawer");

  await page.keyboard.press("Escape");
  await expect(drawer).toBeHidden();
  await expect(opener).toHaveAttribute("aria-expanded", "false");

  await opener.click();
  await expect(drawer).toBeVisible();
  await drawer.locator(".ops-mobile-nav__backdrop").click({ position: { x: 340, y: 20 } });
  await expect(drawer).toBeHidden();

  await opener.click();
  await expect(drawer).toBeVisible();
  await drawer.getByRole("button", { name: "Close navigation" }).click();
  await expect(drawer).toBeHidden();

  await opener.click();
  await expect(drawer).toBeVisible();
  await drawer.getByRole("link", { name: /Posture/ }).click();
  await expect(page).toHaveURL(/\/admin\/search\/posture$/);
  await expect(drawer).toBeHidden();
}

async function seedAllGreenSearch(request: APIRequestContext): Promise<void> {
  const seed = await seedScenario(request, "all_green");
  if (seed.tenant_id) {
    await drainSearchQueue(request);
    await waitForSearchVisible(request, {
      tenantId: seed.tenant_id,
      query: "quantum",
      expectedName: "Quantum CyberPhone X"
    });
  }
}

async function triggerSearchSaveFlash(page: Page): Promise<void> {
  await gotoSearch(page);
  await runSearch(page, "quantum");
  await expect(page.getByRole("heading", { name: "Results", exact: true })).toBeVisible();

  const basename = `${SHELL_PLAYBOOK_PREFIX}${Date.now()}.json`;
  await page.getByRole("button", { name: "Save as playbook" }).click();
  await page.getByLabel("Basename (.json)").fill(basename);
  await page.getByRole("button", { name: "Save playbook" }).click();
  await expect(page.locator("#flash-group [role='alert']:not([hidden])")).toContainText(
    `Saved playbook ${basename}.`
  );
}

test.describe("admin shell chrome -- SHELL-DARK-01", () => {
  test.describe.configure({ timeout: 120_000 });
  test.beforeEach(() => cleanupShellChromePlaybooks());
  test.afterEach(() => cleanupShellChromePlaybooks());

  for (const mode of THEME_MODES) {
    for (const viewport of VIEWPORT_NAMES) {
      test(`[shell-chrome] shared surfaces (${themeSlug(mode)}, ${viewport})`, async ({
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

            await expect(page.locator("#theme-toggle")).toHaveCount(1);
            await expect(page.locator("#theme-toggle-pill")).toHaveCount(1);
            await expect(page.locator("#flash-group")).toHaveCount(1);
            await expect(page.locator(".ops-shell")).toBeVisible();

            await expectHeaderChrome(page, viewport);
            await expectActiveNavChrome(page, viewport, surface);
            await expectShellWash(page);
            await expectNoColorContrastViolations(
              page,
              [".ops-header", ".ops-sidebar", ".ops-shell", "#theme-toggle", ".ops-nav-item-active"],
              `${surface.name} shell chrome`
            );
          }
        } finally {
          await close();
        }
      });

      if (viewport === "mobile") {
        test(`[shell-chrome] mobile navigation drawer (${themeSlug(mode)}, ${viewport})`, async ({
          browser,
          request
        }) => {
          await seedScenario(request, "incident");

          const { page, close } = await newThemedPage(browser, mode, viewport);
          try {
            await gotoControlRoom(page);
            if (mode.kind === "system") {
              await assertSystemDarkInvariants(page);
            }

            await expectMobileNavigationDrawer(page);
          } finally {
            await close();
          }
        });
      }

      test(`[shell-chrome] theme toggle (${themeSlug(mode)}, ${viewport})`, async ({
        browser,
        request
      }) => {
        await seedScenario(request, "incident");

        const { page, close } = await newThemedPage(browser, mode, viewport);
        try {
          await gotoControlRoom(page);
          if (mode.kind === "system") {
            await assertSystemDarkInvariants(page);
          }

          const lightButton = page.locator('#theme-toggle [data-phx-theme="light"]');
          const darkButton = page.locator('#theme-toggle [data-phx-theme="dark"]');
          const systemButton = page.locator('#theme-toggle [data-phx-theme="system"]');

          await systemButton.click();
          await expectThemeRootState(page, "system");
          await expectThemeButtonState(page, "system");

          await lightButton.click();
          await expectThemeRootState(page, "light");
          await expectThemeButtonState(page, "light");
          const lightPillLeft = await readComputedStyle(page, "#theme-toggle-pill", "left");

          await darkButton.click();
          await expectThemeRootState(page, "dark");
          await expectThemeButtonState(page, "dark");
          const darkPillLeft = await readComputedStyle(page, "#theme-toggle-pill", "left");

          expect(darkPillLeft, "#theme-toggle-pill must move when switching light -> dark").not.toBe(lightPillLeft);
        } finally {
          await close();
        }
      });

      test(`[shell-chrome] command palette (${themeSlug(mode)}, ${viewport})`, async ({
        browser,
        request
      }) => {
        await seedScenario(request, "incident");

        const { page, close } = await newThemedPage(browser, mode, viewport);
        try {
          await gotoControlRoom(page);
          if (mode.kind === "system") {
            await assertSystemDarkInvariants(page);
          }

          const opener = page.locator('#theme-toggle [data-phx-theme="system"]');
          await opener.focus();
          await openCommandPalette(page);

          const input = page.locator("[data-cmdk-input]");
          const initialActiveId = await expectOneSelectedCommandItem(page);
          await page.keyboard.press("ArrowDown");
          const nextActiveId = await expectOneSelectedCommandItem(page);
          expect(nextActiveId, "ArrowDown moves the active command option").not.toBe(initialActiveId);

          await input.fill("zzzz-no-match");
          await expect(page.locator("[data-cmdk-empty]")).toBeVisible();
          await expect(page.locator("#ops-cmdk [data-cmdk-item][aria-selected='true']")).toHaveCount(0);
          await expect(input).not.toHaveAttribute("aria-activedescendant");

          await input.fill("");
          await expectOneSelectedCommandItem(page);

          await expectNoColorContrastViolations(page, ["#ops-cmdk"], "command palette");
          await expectAriaModalTruth(page, "#ops-cmdk", opener);
          await expect(page.locator("#ops-cmdk [data-cmdk-item][aria-selected='true']")).toHaveCount(0);

          await openCommandPalette(page);
          await expect(page.locator("#ops-cmdk-item-0")).toHaveAttribute("href", "/admin/search");
          await page.keyboard.press("Enter");
          await expect(page).toHaveURL(/\/admin\/search$/);
          await expect(page.getByRole("heading", { name: "Control Room" })).toBeVisible();
        } finally {
          await close();
        }
      });

      test(`[shell-chrome] shortcut sheet (${themeSlug(mode)}, ${viewport})`, async ({
        browser,
        request
      }) => {
        await seedScenario(request, "incident");

        const { page, close } = await newThemedPage(browser, mode, viewport);
        try {
          await gotoControlRoom(page);
          if (mode.kind === "system") {
            await assertSystemDarkInvariants(page);
          }

          const opener = page.locator('#theme-toggle [data-phx-theme="system"]');
          await opener.focus();
          await openShortcutSheet(page);

          await expect(page.locator("#ops-cheatsheet .ops-cheatsheet__row")).toHaveCount(4);
          await expectNoColorContrastViolations(page, ["#ops-cheatsheet"], "shortcut sheet");
          await expectAriaModalTruth(page, "#ops-cheatsheet", opener);
        } finally {
          await close();
        }
      });

      test(`[shell-chrome] flash (${themeSlug(mode)}, ${viewport})`, async ({
        browser,
        request
      }) => {
        await seedAllGreenSearch(request);

        const { page, close } = await newThemedPage(browser, mode, viewport);
        try {
          await triggerSearchSaveFlash(page);
          if (mode.kind === "system") {
            await assertSystemDarkInvariants(page);
          }

          const flash = page.locator("#flash-group [role='alert']:not([hidden])").first();
          await expect(flash).toBeVisible();
          await expect(flash).toHaveClass(/ops-flash/);
          await expect(flash).toHaveClass(/ops-flash--info/);
          await expect(flash.locator("svg")).not.toHaveCount(0);
          await expect(flash.getByRole("button", { name: "Close notification" })).toBeVisible();
          await expect(page.locator("#flash-group")).toHaveCount(1);

          const shadow = await flash.evaluate((el) => getComputedStyle(el).boxShadow);
          const border = await flash.evaluate((el) => getComputedStyle(el).borderColor);
          const bg = await flash.evaluate((el) => getComputedStyle(el).backgroundColor);
          expect(shadow, "flash should expose overlay/depth styling").not.toBe("none");
          expect(border, "flash should expose a visible border color").not.toBe("rgba(0, 0, 0, 0)");
          expect(bg, "flash should expose a visible background").not.toBe("rgba(0, 0, 0, 0)");

          await expectNoColorContrastViolations(page, ["#flash-group"], "flash group");
        } finally {
          await close();
        }
      });
    }
  }
});
