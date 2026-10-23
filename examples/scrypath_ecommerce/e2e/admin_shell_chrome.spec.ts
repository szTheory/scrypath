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
import {
  deleteSavedSearches,
  drainSearchQueue,
  putSavedSearch,
  saveCurrentSearch,
  seedScenario,
  waitForLiveConnected,
  waitForSearchVisible
} from "./helpers/e2e";
import {
  assertSystemDarkInvariants,
  gotoControlRoom,
  gotoFailedSync,
  gotoSavedSearches,
  gotoSearchHealth,
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

const SHELL_SAVED_SEARCH_PREFIX = "shell-chrome-";

type ShellSurface = {
  name: string;
  prepare: (page: Page) => Promise<void>;
  hasPrimaryNavItem: boolean;
};

const SHELL_SURFACES: ShellSurface[] = [
  { name: "Control Room", prepare: gotoControlRoom, hasPrimaryNavItem: true },
  { name: "Search health", prepare: gotoSearchHealth, hasPrimaryNavItem: true },
  { name: "Failed Sync", prepare: gotoFailedSync, hasPrimaryNavItem: true },
  { name: "Sync/Drift", prepare: gotoSyncDrift, hasPrimaryNavItem: true },
  { name: "Search", prepare: gotoSearch, hasPrimaryNavItem: true }
];

async function cleanupShellChromeSavedSearches(request: APIRequestContext): Promise<void> {
  await deleteSavedSearches(request, { prefix: SHELL_SAVED_SEARCH_PREFIX });
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

  await expect.poll(() => selected.evaluate(el => getComputedStyle(el).backgroundColor),
    { message: `${theme} selected preference has a visible neutral fill` }).not.toBe("rgba(0, 0, 0, 0)");

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
  expect(background, "the current shell floor is flat").toBe("none");
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
  for (const item of await active.all()) await expect(item).toHaveAttribute("aria-current", "page");
  expect(bg, ".ops-nav-item-active must have a visible selected fill").not.toBe("rgba(0, 0, 0, 0)");
  expect(color, ".ops-nav-item-active must resolve readable text color").not.toBe("rgba(0, 0, 0, 0)");

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
  await drawer.getByRole("link", { name: /Search health/ }).click();
  await expect(page).toHaveURL(/\/admin\/search\/health$/);
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

  const name = `${SHELL_SAVED_SEARCH_PREFIX}${Date.now()}`;
  await saveCurrentSearch(page, name);
  await expect(page.locator("#flash-group [role='status']:not([hidden])")).toContainText(
    `Saved “${name}”.`
  );
}

test.use({ actionTimeout: 10_000 });

test.describe("admin shell chrome -- SHELL-DARK-01", () => {
  test.describe.configure({ timeout: 120_000 });
  test.beforeEach(async ({ request }) => cleanupShellChromeSavedSearches(request));
  test.afterEach(async ({ page, request }, testInfo) => {
    await cleanupShellChromeSavedSearches(request);
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
    await page.getByRole("button", { name: "Go to…", exact: true }).click();
    await expect(page.locator("#ops-cmdk")).toBeVisible();
  });

  test("[shell-chrome] Manage saved searches sheet focus lifecycle and overlay isolation", async ({ page, request }) => {
    const name = `${SHELL_SAVED_SEARCH_PREFIX}sheet-${Date.now()}`;
    await page.setViewportSize({ width: 390, height: 844 });
    await putSavedSearch(request, name, {});
    await gotoSearch(page);
    const trigger = page.locator("#saved-search-manage-open");

    await pressCommandPaletteShortcut(page);
    await expect(page.locator("#ops-cmdk")).toBeVisible();
    // Model a sheet-opening event arriving while the palette has made the page inert.
    await trigger.evaluate((element: HTMLButtonElement) => element.click());

    const sheet = page.getByRole("dialog", { name: "Manage saved searches" });
    await expect(sheet).toBeVisible();
    await expect(page.locator("#ops-cmdk")).toBeHidden();
    await expect(sheet.locator("[data-ops-sheet-close]")).toBeFocused();
    await page.keyboard.press("Control+K");
    await expect(page.locator("#ops-cmdk")).toBeHidden();
    await expect(page.locator(".ops-header")).toHaveAttribute("inert", "");

    const focusInSheet = () => sheet.evaluate((el) => el.contains(document.activeElement));
    const focusedLabel = () =>
      page.evaluate(() => {
        const el = document.activeElement;
        return el ? `${el.tagName} ${el.getAttribute("aria-label") || el.textContent?.trim().slice(0, 40) || ""}` : "none";
      });
    for (let step = 0; step < 30; step += 1) {
      await page.keyboard.press(step % 7 === 6 ? "Shift+Tab" : "Tab");
      expect(await focusInSheet(), `Tab ${step + 1} stays in the sheet (focus: ${await focusedLabel()})`).toBe(true);
    }

    const row = sheet.locator(".ops-saved-search-row").filter({ hasText: name });
    await expect(row).toHaveCount(1);
    const renameTrigger = row.getByRole("button", { name: `Rename ${name}` });
    await renameTrigger.click();
    const input = sheet.locator("#saved-search-rename-input");
    await expect(input).toBeFocused();
    await input.fill("invalid-but-unsent");
    // phx-change sends a real server patch; focus must remain on the edited input.
    await expect(input).toHaveAttribute("value", "invalid-but-unsent");
    await expect(input).toBeFocused();
    // Escape leaves the row action first and returns to its trigger, keeping the sheet open.
    await page.keyboard.press("Escape");
    await expect(input).toHaveCount(0);
    await expect(sheet).toBeVisible();
    await expect(renameTrigger).toBeFocused();

    await row.getByRole("button", { name: `Delete ${name}` }).click();
    const confirm = sheet.locator("#saved-search-delete-input");
    await expect(confirm).toBeFocused();
    await confirm.fill("wrong name");
    await sheet.getByRole("button", { name: "Delete", exact: true }).click();
    await expect(confirm).toHaveAttribute("aria-invalid", "true");
    await expect(confirm).toBeFocused();
    await confirm.fill(name);
    await sheet.getByRole("button", { name: "Delete", exact: true }).click();
    await expect(row).toHaveCount(0);
    await expect.poll(focusInSheet, { message: "focus stays in the sheet after delete" }).toBe(true);

    await page.keyboard.press("Escape");
    await expect(sheet).toBeHidden();
    await expect(trigger).toBeFocused();
    await expect(page.locator(".ops-header")).not.toHaveAttribute("inert", "");
  });

  test("[shell-chrome] successful rename returns focus to the renamed row", async ({ page, request }) => {
    const name = `${SHELL_SAVED_SEARCH_PREFIX}rename-${Date.now()}`;
    const renamed = name.replace("rename-", "renamed-");
    await putSavedSearch(request, name, {});
    const sheet = await gotoSavedSearches(page).then(() =>
      page.getByRole("dialog", { name: "Manage saved searches" })
    );
    const row = sheet.locator(".ops-saved-search-row").filter({ hasText: name });
    await row.getByRole("button", { name: `Rename ${name}` }).click();
    const input = sheet.locator("#saved-search-rename-input");
    await input.fill("n".repeat(121));
    await sheet.getByRole("button", { name: "Rename", exact: true }).click();
    const error = sheet.locator("#saved-search-rename-input-error");
    await expect(error).toContainText("Enter a name");
    await expect(input).toHaveAttribute("aria-invalid", "true");
    await expect(error).not.toHaveAttribute("inert", "");
    expect(await error.evaluate((el) => el.closest("[inert]") === null)).toBe(true);
    expect(await sheet.evaluate((el) => el.contains(document.activeElement))).toBe(true);
    await input.fill(renamed);
    await sheet.getByRole("button", { name: "Rename", exact: true }).click();
    await expect(row).toHaveCount(0);
    const renamedRow = sheet.locator(".ops-saved-search-row").filter({ hasText: renamed });
    await expect(renamedRow).toHaveCount(1);
    await expect(renamedRow.getByRole("button", { name: `Rename ${renamed}` })).toBeFocused();
    await expect(page.locator(".ops-header")).toHaveAttribute("inert", "");
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
        if (width <= 420) {
          const commandHint = page.locator(".ops-command-hint");
          await expect(commandHint).toHaveAttribute("aria-label", "Go to…");
          const themeLabels = await page.locator("#theme-toggle button span").all();
          expect(themeLabels).toHaveLength(3);
          for (const label of themeLabels) await expect(label).toBeHidden();
          const contentFits = await commandHint.evaluate((element) => element.scrollWidth <= element.clientWidth + 1);
          expect(contentFits, `command action content fits at ${width}px`).toBe(true);

          if (width <= 360) {
            await expect(commandHint.locator(".ops-command-hint__icon")).toBeVisible();
            await expect(commandHint.locator("span")).toBeHidden();
            await assertReadableControl(commandHint, "compact command action", 14, 44);
          } else {
            await expect(commandHint.locator("span")).toBeVisible();
          }
        }
        const heading = page.locator("#ops-main h3:visible").first();
        if (await heading.count()) await assertReadableControl(heading, `${surface.name} record heading`, 16);
        const primary = {
          "Control Room": page.getByTestId("control-room-health-link"),
          "Search health": page.getByTestId("posture-failed-sync-link").first(),
          "Failed Sync": page.getByTestId("failed-sync-retry").first(),
          "Sync/Drift": page.getByRole("button", { name: "Refresh sync and index settings", exact: true }),
          "Search": page.getByRole("button", { name: "Run search", exact: true })
        }[surface.name]!;
        await primary.click({ trial: true });
        await assertReadableControl(primary, `${surface.name} common action`, 14, 40);
        await page.evaluate(() => window.scrollTo(0, 0));
        if (width === 390 && surface.name === "Failed Sync") {
          const filters = page.locator("#failed-sync-filters");
          const causes = filters.getByTestId("failed-sync-cause-filter");
          await expect(causes).toHaveCount(5);
          await expect(causes.filter({ hasText: "Unknown cause" })).toContainText("1");
          for (const chip of await causes.all()) await assertReadableControl(chip, "cause filter chip", 12, 24);
          expect((await filters.boundingBox())!.height, "schema and cause filters remain compact").toBeLessThanOrEqual(240);
          await expect(page.getByRole("radio")).toHaveCount(0);
          await expect(filters.getByRole("checkbox", { name: /^(Product|Variant)/ })).toHaveCount(2);
        }
        if (width === 390) {
          await scanNonContrastA11y(page, testInfo, `${surface.name}-incident-light-390`);
          await testInfo.attach(`${surface.name}-light-390.png`, { body: await page.screenshot({ fullPage: true }), contentType: "image/png" });
        }
      }
    }
  });

  test("[layout] long content and five-schema native radio group", async ({ page }, testInfo) => {
    await page.setViewportSize({ width: 320, height: 900 });
    await page.goto("/admin/search/ui-fixtures");
    await waitForLiveConnected(page);
    await expect(page.getByRole("radio")).toHaveCount(5);
    const selected = page.getByRole("radio", { name: /StockKeepingUnitWithAnIntentionallyLongName/ });
    await selected.check();
    await expect(page.locator("#selected-schema")).toContainText("StockKeepingUnitWithAnIntentionallyLongName");
    await selected.focus();
    await expect(selected).toBeFocused();
    await assertReadableControl(selected.locator(".."), "schema radio row", 14, 40);
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
            await expect(page.locator("#theme-toggle-pill")).toHaveCount(0);
            await expect(page.locator("#theme-toggle button[aria-pressed=true]")).toHaveCount(1);
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
          await expect(lightButton).toHaveAttribute("aria-pressed", "true");

          await darkButton.click();
          await expectThemeRootState(page, "dark");
          await expectThemeButtonState(page, "dark");
          await expect(lightButton).toHaveAttribute("aria-pressed", "false");
          await expect(darkButton).toHaveAttribute("aria-pressed", "true");
          await expect(page.locator("#theme-toggle-pill")).toHaveCount(0);
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

          const hoveredOption = page.locator("#ops-cmdk-item-2");
          await hoveredOption.hover();
          await expect(hoveredOption).toHaveAttribute("aria-selected", "true");
          await expectOneSelectedCommandItem(page);

          await page.keyboard.press("ArrowDown");
          await expect(page.locator("#ops-cmdk-item-3")).toHaveAttribute("aria-selected", "true");
          const hoveredBackground = await hoveredOption.evaluate(
            el => getComputedStyle(el).backgroundColor
          );
          const inactiveBackground = await page
            .locator("#ops-cmdk-item-0")
            .evaluate(el => getComputedStyle(el).backgroundColor);
          expect(
            hoveredBackground,
            "the pointer does not keep a second option highlighted during keyboard navigation"
          ).toBe(inactiveBackground);
          await expectOneSelectedCommandItem(page);

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
          await expect(page.locator("[data-cmdk-input]")).toHaveAttribute("aria-activedescendant", "ops-cmdk-item-0");
          await expect(page.locator("#ops-cmdk-item-0")).toHaveAttribute("aria-selected", "true");
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

          const flash = page.locator("#flash-group [role='status']:not([hidden])").first();
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
