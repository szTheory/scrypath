import { AxeBuilder } from "@axe-core/playwright";
import { expect, type Locator, type Page, type TestInfo } from "@playwright/test";

// Evidence-focused journeys deliberately open the compact schema summaries.
export async function expandHealthDetails(page: Page): Promise<void> {
  const closed = page.locator(".ops-schema-health:not([open]) > summary");
  while (await closed.count()) await closed.first().click();
}

export async function assertOperatorGeometry(
  page: Page,
  label: string,
  essentialControls: string[]
): Promise<void> {
  const pageSize = await page.evaluate(() => ({
    width: window.innerWidth,
    clientWidth: document.documentElement.clientWidth,
    height: window.innerHeight,
    documentWidth: document.documentElement.scrollWidth,
    bodyWidth: document.body.scrollWidth,
    overflowing: Array.from(document.querySelectorAll("#ops-main *")).filter((el) => {
      const r = el.getBoundingClientRect();
      return r.width > 0 && (r.left < -1 || r.right > window.innerWidth + 1);
    }).slice(0, 12).map((el) => ({ tag: el.tagName, class: el.className, text: el.textContent?.slice(0, 70), width: el.getBoundingClientRect().width }))
  }));
  expect(pageSize.documentWidth, `${label}: document has no horizontal overflow ${JSON.stringify(pageSize.overflowing)}`).toBeLessThanOrEqual(pageSize.clientWidth + 1);
  expect(pageSize.bodyWidth, `${label}: body has no horizontal overflow`).toBeLessThanOrEqual(pageSize.clientWidth + 1);

  const bounds: Array<{ name: string; left: number; right: number; top: number; bottom: number }> = [];
  for (const selector of essentialControls) {
    const control = page.locator(selector).first();
    await expect(control, `${label}: ${selector} is visible`).toBeVisible();
    const geometry = await control.evaluate((element) => {
      const rect = element.getBoundingClientRect();
      const hit = document.elementFromPoint(rect.left + rect.width / 2, rect.top + rect.height / 2);
      return {
        name: element.getAttribute("aria-label") || element.id || element.className,
        left: rect.left,
        right: rect.right,
        top: rect.top,
        bottom: rect.bottom,
        reachable: hit === element || (hit !== null && element.contains(hit))
      };
    });
    expect(geometry.left, `${label}: ${selector} is not clipped on the left`).toBeGreaterThanOrEqual(-1);
    expect(geometry.right, `${label}: ${selector} is not clipped on the right`).toBeLessThanOrEqual(pageSize.width + 1);
    expect(geometry.top, `${label}: ${selector} is not clipped above the viewport`).toBeGreaterThanOrEqual(-1);
    expect(geometry.bottom, `${label}: ${selector} is not clipped below the viewport`).toBeLessThanOrEqual(pageSize.height + 1);
    expect(geometry.reachable, `${label}: ${selector} receives a pointer hit`).toBe(true);
    bounds.push(geometry);
  }

  const overlaps: string[] = [];
  for (let index = 0; index < bounds.length; index += 1) {
    for (let other = index + 1; other < bounds.length; other += 1) {
      const first = bounds[index];
      const second = bounds[other];
      if (first && second && first.left < second.right && second.left < first.right && first.top < second.bottom && second.top < first.bottom) {
        overlaps.push(`${first.name} overlaps ${second.name}`);
      }
    }
  }
  expect(overlaps, `${label}: essential controls do not overlap (${JSON.stringify(bounds)})`).toEqual([]);
}

export async function assertReadableControl(
  control: Locator,
  label: string,
  minimumFontPx: number,
  minimumHeightPx = 0
): Promise<void> {
  const metrics = await control.evaluate((element) => {
    const style = getComputedStyle(element);
    return { fontSize: Number.parseFloat(style.fontSize), height: element.getBoundingClientRect().height };
  });
  expect(metrics.fontSize, `${label}: font size`).toBeGreaterThanOrEqual(minimumFontPx);
  if (minimumHeightPx > 0) {
    expect(metrics.height, `${label}: target height`).toBeGreaterThanOrEqual(minimumHeightPx);
  }
}

export async function assertDialogCycle(
  page: Page,
  focusablesInOrder: Locator[],
  label: string
): Promise<void> {
  const first = focusablesInOrder[0];
  expect(first, `${label}: dialog has focusable controls`).toBeDefined();
  if (!first) return;

  await first.focus();
  for (let index = 1; index < focusablesInOrder.length; index += 1) {
    const expected = focusablesInOrder[index];
    if (!expected) continue;
    await page.keyboard.press("Tab");
    await expect(expected, `${label}: forward Tab ${index + 1}`).toBeFocused();
  }
  await page.keyboard.press("Tab");
  await expect(first, `${label}: Tab wraps to first control`).toBeFocused();

  for (let index = focusablesInOrder.length - 1; index >= 0; index -= 1) {
    const expected = focusablesInOrder[index];
    if (!expected) continue;
    await page.keyboard.press("Shift+Tab");
    await expect(expected, `${label}: backward Tab ${index + 1}`).toBeFocused();
  }
}

export async function scanNonContrastA11y(
  page: Page,
  testInfo: TestInfo,
  label: string
): Promise<void> {
  const results = await new AxeBuilder({ page })
    .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"])
    .disableRules(["color-contrast"])
    .analyze();
  const report = {
    label,
    source_sha: process.env.SCRYPATH_SOURCE_SHA || process.env.GITHUB_SHA || "unknown",
    violations: results.violations.map(({ id, impact, description, nodes }) => ({
      id, impact, description, targets: nodes.map(({ target }) => target)
    })),
    incomplete: results.incomplete.map(({ id, impact, description, nodes }) => ({
      id, impact, description, targets: nodes.map(({ target }) => target)
    }))
  };
  await testInfo.attach(`axe-non-contrast-${label.replaceAll(/[^a-z0-9-]/gi, "-")}.json`, {
    body: JSON.stringify(report, null, 2),
    contentType: "application/json"
  });
  expect(report.violations, `${label}: non-contrast axe violations`).toEqual([]);
}
