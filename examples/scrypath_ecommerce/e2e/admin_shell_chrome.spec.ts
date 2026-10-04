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
import { existsSync, mkdirSync, readdirSync, unlinkSync, writeFileSync } from "node:fs";
import { join } from "node:path";

import {
  drainSearchQueue,
  seedScenario,
  waitForLiveConnected,
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

import { assertDialogCycle, assertOperatorGeometry, assertReadableControl, scanNonContrastA11y } from "./helpers/operator-ui";

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

  const maxHeight = viewport === "desktop" ? 96 : 120;
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

test.use({ actionTimeout: 10_000 });

test.describe("admin shell chrome -- SHELL-DARK-01", () => {
  test.describe.configure({ timeout: 120_000 });
  test.beforeEach(() => cleanupShellChromePlaybooks());
  test.afterEach(async ({ page }, testInfo) => {
    cleanupShellChromePlaybooks();
    if (testInfo.status !== testInfo.expectedStatus) {
      await testInfo.attach("shell-first-failure.png", { body: await page.screenshot({ fullPage: true }), contentType: "image/png" });
    }
  });

  test("[layout] narrow operator header controls do not overlap", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await gotoControlRoom(page);

    await assertOperatorGeometry(page, "390px header", [
      ".ops-header .ops-nav-trigger", ".ops-header .ops-command-hint", ".ops-header #theme-toggle"
    ]);
    await page.getByRole("button", { name: "Jump to surface", exact: true }).click();
    await expect(page.locator("#ops-cmdk")).toBeVisible();
  });

  test("[shell-chrome] playbook modal focus lifecycle and overlay isolation", async ({ page }) => {
    const basename = `${SHELL_PLAYBOOK_PREFIX}modal-${Date.now()}.json`;
    await page.setViewportSize({ width: 390, height: 844 });
    mkdirSync(PLAYBOOK_WORKSPACE_DIR, { recursive: true });
    writeFileSync(join(PLAYBOOK_WORKSPACE_DIR, basename), "{}\n");
    await gotoPlaybooks(page);

    const row = page.locator(".ops-object-item").filter({ hasText: basename });
    await expect(row).toHaveCount(1);
    const renameTrigger = row.getByRole("button", { name: "Rename" });

    await pressCommandPaletteShortcut(page);
    await expect(page.locator("#ops-cmdk")).toBeVisible();
    // Model a modal-opening event arriving while the palette has made the page inert.
    await renameTrigger.evaluate((element: HTMLButtonElement) => element.click());

    const modal = page.locator("#rename-playbook-modal");
    const cancel = modal.locator("[data-ops-modal-cancel]");
    const input = page.locator("#rename-new-name-input");
    const submit = modal.getByRole("button", { name: "Rename", exact: true });

    await expect(modal).toBeVisible();
    await expect(page.locator("#ops-cmdk")).toBeHidden();
    await expect(input).toBeFocused();
    await page.keyboard.press("Control+K");
    await expect(page.locator("#ops-cmdk")).toBeHidden();

    const close = modal.getByRole("button", { name: "Close Rename playbook dialog" });
    await assertDialogCycle(page, [close, input, cancel, submit], "rename");
    await expect(page.locator(".ops-header")).toHaveAttribute("inert", "");
    await input.focus();
    await input.fill("invalid/name.json");
    await expect(input).toHaveValue("invalid/name.json");
    await expect(input).toHaveAttribute("value", "invalid/name.json");
    // phx-change sends a real server patch; focus must remain on the edited input.
    await expect(input).toBeFocused();
    await expect(modal).toBeVisible();
    await page.keyboard.press("Escape");
    await expect(modal).toBeHidden();
    await expect(renameTrigger).toBeFocused();

    await expect(page.locator(".ops-header")).not.toHaveAttribute("inert", "");
    await page.getByRole("button", { name: "Open navigation" }).click();
    await expect(page.locator("#ops-mobile-nav")).toBeVisible();
    await row.getByRole("button", { name: "Duplicate" }).evaluate((element: HTMLButtonElement) => element.click());
    const duplicate = page.locator("#duplicate-playbook-modal");
    const duplicateInput = page.locator("#dup-to-name-input");
    await expect(duplicateInput).toBeFocused();
    await expect(page.locator("#ops-mobile-nav")).toBeHidden();
    await page.keyboard.press("Shift+/");
    await expect(page.locator("#ops-cheatsheet")).toBeHidden();
    await assertDialogCycle(page, [
      duplicate.getByRole("button", { name: "Close Duplicate playbook dialog" }),
      duplicateInput, duplicate.getByRole("button", { name: "Cancel duplicate" }),
      duplicate.getByRole("button", { name: "Duplicate", exact: true })
    ], "duplicate");
    await duplicateInput.fill(`${SHELL_PLAYBOOK_PREFIX}duplicate.json`);
    await expect(duplicateInput).toHaveAttribute("value", `${SHELL_PLAYBOOK_PREFIX}duplicate.json`);
    await expect(duplicateInput).toBeFocused();
    await duplicate.getByRole("button", { name: "Cancel duplicate" }).click();
    await expect(duplicate).toBeHidden();
    await expect(row.getByRole("button", { name: "Duplicate" })).toBeFocused();

    const deleteTrigger = row.getByRole("button", { name: "Delete" });
    await openShortcutSheet(page);
    await deleteTrigger.evaluate((element: HTMLButtonElement) => element.click());
    await expect(page.locator("#ops-cheatsheet")).toBeHidden();
    const deleteModal = page.locator("#delete-playbook-modal");
    await expect(deleteModal).toBeVisible();
    await expect(deleteModal.getByRole("button", { name: "Cancel delete" })).toBeFocused();
    await assertDialogCycle(page, [
      deleteModal.getByRole("button", { name: "Close Delete playbook file dialog" }),
      page.locator("#delete-confirm-input"),
      deleteModal.getByRole("button", { name: "Cancel delete" }),
      deleteModal.getByRole("button", { name: "Confirm delete" })
    ], "delete");
    const successorSelector = await deleteModal.getAttribute("data-ops-modal-successor");
    expect(successorSelector).toBeTruthy();

    await deleteTrigger.evaluate((el) => el.remove());
    await deleteModal.getByRole("button", { name: "Cancel delete" }).click();
    await expect(deleteModal).toBeHidden();
    const successor = page.locator(successorSelector as string);
    await expect(successor).toBeFocused();
    await page.reload();
    await expect(row).toBeVisible();
    await row.getByRole("button", { name: "Delete" }).click();
    await expect(deleteModal.getByRole("button", { name: "Cancel delete" })).toBeFocused();
    const afterDelete = await deleteModal.getAttribute("data-ops-modal-successor");
    await page.locator("#delete-confirm-input").fill(basename);
    await deleteModal.getByRole("button", { name: "Confirm delete" }).click();
    await expect(deleteModal).toBeHidden();
    await expect(row).toHaveCount(0);
    await expect(page.locator(afterDelete!)).toBeFocused();
    await expect(page.locator(".ops-header")).not.toHaveAttribute("inert", "");
  });

  test("[shell-chrome] successful rename returns focus to the catalog", async ({ page }) => {
    const basename = `${SHELL_PLAYBOOK_PREFIX}rename-${Date.now()}.json`;
    const renamed = basename.replace("rename-", "renamed-");
    mkdirSync(PLAYBOOK_WORKSPACE_DIR, { recursive: true });
    writeFileSync(join(PLAYBOOK_WORKSPACE_DIR, basename), "{}\n");
    await gotoPlaybooks(page);
    const row = page.locator(".ops-object-item").filter({ hasText: basename });
    await row.getByRole("button", { name: "Rename", exact: true }).click();
    const modal = page.locator("#rename-playbook-modal");
    const input = page.locator("#rename-new-name-input");
    await input.fill("invalid/name.json");
    await modal.getByRole("button", { name: "Rename", exact: true }).click();
    const error = modal.getByRole("alert");
    await expect(error).toContainText("Filename");
    await expect(input).toHaveAttribute("aria-invalid", "true");
    await expect(error).not.toHaveAttribute("inert", "");
    expect(await error.evaluate(el => el.closest("[inert]") === null)).toBe(true);
    expect(await modal.evaluate(el => el.contains(document.activeElement))).toBe(true);
    await input.fill(renamed);
    await modal.getByRole("button", { name: "Rename", exact: true }).click();
    await expect(modal).toBeHidden();
    await expect(row).toHaveCount(0);
    await expect(page.locator(".ops-object-item").filter({ hasText: renamed })).toHaveCount(1);
    await expect(page.locator("#playbook-catalog-heading")).toBeFocused();
    await expect(page.locator(".ops-header")).not.toHaveAttribute("inert", "");
  });

  test("[layout] representative operator boundaries and non-contrast accessibility", async ({ page, request }, testInfo) => {
    test.setTimeout(180_000);
    await seedScenario(request, "incident");
    await page.addInitScript(() => localStorage.setItem("phx:theme", "light"));
    for (const width of [320, 390, 1279, 1280, 1440]) {
      await page.setViewportSize({ width, height: 900 });
      for (const surface of SHELL_SURFACES) {
        await surface.prepare(page);
        await page.evaluate(() => window.scrollTo(0, 0));
        await assertOperatorGeometry(page, `${surface.name} ${width}px`, [
          ...(width < 1280 ? [".ops-header .ops-nav-trigger"] : []),
          ".ops-header .ops-command-hint", ".ops-header #theme-toggle"
        ]);
        await assertReadableControl(page.locator(".ops-command-hint"), "command action", 14, 40);
        await assertReadableControl(page.locator("#theme-toggle button").first(), "theme target", 0, 44);
        const heading = page.locator("#ops-main h3:visible").first();
        if (await heading.count()) await assertReadableControl(heading, `${surface.name} record heading`, 16);
        const primary = {
          "Control Room": page.getByTestId("intent-incident"),
          "Posture": page.getByTestId("posture-failed-sync-link").first(),
          "Failed Sync": page.getByTestId("failed-sync-retry").first(),
          "Sync/Drift": page.getByRole("button", { name: "Refresh sync status", exact: true }),
          "Search": page.getByRole("button", { name: "Run search", exact: true }),
          "Playbooks": page.getByRole("button", { name: "Load preview", exact: true }).first()
        }[surface.name]!;
        await primary.click({ trial: true });
        await assertReadableControl(primary, `${surface.name} common action`, 14, 40);
        await page.evaluate(() => window.scrollTo(0, 0));
        if (width === 390 && surface.name === "Failed Sync") {
          const summary = page.locator("#failed-sync-rollups-heading").locator("..");
          await expect(summary.locator("span.rounded-full")).toHaveCount(5);
          await expect(summary).toContainText("5 failed sync jobs");
          expect((await summary.boundingBox())!.height, "total plus five reason counts remain compact").toBeLessThanOrEqual(160);
          await expect(page.getByRole("radio")).toHaveCount(2);
        }
        if (width === 390) {
          await scanNonContrastA11y(page, testInfo, `${surface.name}-incident-light-390`);
          await testInfo.attach(`${surface.name}-light-390.png`, { body: await page.screenshot({ fullPage: true }), contentType: "image/png" });
        }
      }
    }
  });

  test("[layout] long content and five-schema native select", async ({ page }, testInfo) => {
    await page.setViewportSize({ width: 320, height: 900 });
    await page.goto("/admin/search/ui-fixtures");
    await waitForLiveConnected(page);
    const select = page.getByRole("combobox", { name: "Schema" });
    await expect(select.locator("option")).toHaveCount(5);
    await select.focus();
    await select.selectOption("ScrypathEcommerce.Catalog.Inventory.Warehouse.StockKeepingUnitWithAnIntentionallyLongName");
    await expect(page.locator("#selected-schema")).toContainText("StockKeepingUnitWithAnIntentionallyLongName");
    await expect(select).toBeFocused();
    await assertReadableControl(select, "schema select", 14, 40);
    await page.getByText("Diagnostics", { exact: true }).click();
    await page.evaluate(() => window.scrollTo(0, 0));
    await assertOperatorGeometry(page, "long identifiers 320px", [".ops-command-hint", "#theme-toggle"]);
    await scanNonContrastA11y(page, testInfo, "long-content-select-partial-320");
    await testInfo.attach("long-content-select-320.png", { body: await page.screenshot({ fullPage: true }), contentType: "image/png" });
  });

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
