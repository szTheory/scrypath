import {expect, test} from "@playwright/test";
import {seedScenario, waitForLiveConnected} from "./helpers/e2e";
import {mkdir} from "node:fs/promises";
import {guardVerificationTarget} from "./helpers/verification-target.mjs";
const artifacts = "ui-review-artifacts/iteration3-journeys";
test.beforeEach(async ({baseURL}) => {
  await guardVerificationTarget(baseURL, reason => test.skip(true, reason), async () => {
    await mkdir(artifacts, {recursive: true});
  });
});

test("limits validate on blur, correct inline and preserve the previous run on invalid submission", async ({page, request}) => {
  await seedScenario(request, "all_green");
  await page.goto("/admin/search/search"); await waitForLiveConnected(page);
  const limit = page.getByLabel("Results per page", {exact: true});
  await expect(page.locator("#search_page_size-error")).toBeHidden();
  await limit.fill("51"); await limit.press("Tab");
  await expect(page.locator("#search_page_size-error")).toHaveText("Enter a whole number from 1 to 50.");
  await expect(limit).toHaveAttribute("aria-invalid", "true");
  await expect(page.locator("#search-results-heading")).toHaveCount(0);
  await page.screenshot({path: `${artifacts}/validation.png`, fullPage: true});
  await limit.fill("3"); await expect(page.locator("#search_page_size-error")).toBeHidden();
  await page.getByRole("button", {name:"Run search", exact:true}).click();
  await expect(page.locator(".ops-readable-hit")).toHaveCount(3);
  const run = await page.locator("#search-run-attribution").getAttribute("data-run-id");
  await limit.fill("1.5"); await page.getByRole("button", {name:"Run search", exact:true}).click();
  await expect(limit).toBeFocused();
  await expect(page.locator("#search-run-attribution")).toHaveAttribute("data-run-id", run!);
  await expect(page.locator(".ops-readable-hit")).toHaveCount(3);
});

test("combined results are one compact backend-ordered list with real page traversal and complete copyable source data", async ({page, request}) => {
  await seedScenario(request,"all_green");
  await page.goto("/admin/search/search?mode=multi"); await waitForLiveConnected(page);
  await expect(page.locator(".ops-schema-picker__name")).toHaveText(["Product","Variant"]);
  await expect(page.getByRole("checkbox")).toHaveCount(2);
  await page.getByLabel("Results per page", {exact: true}).fill("3");
  await page.getByRole("button", {name:"Run search", exact:true}).click();
  await expect(page.locator("#search-outcome")).toHaveText("3 results shown");
  const titles = await page.locator(".ops-hit-heading h3").allTextContents();
  await expect(page.locator(".ops-readable-hit")).toHaveCount(3);
  await expect(page.getByText(/returned no matches|No matching documents returned for this index/)).toHaveCount(0);
  await page.screenshot({path:`${artifacts}/combined-page-1.png`, fullPage:true});
  await page.getByRole("button",{name:"Next",exact:true}).click();
  await expect(page.getByRole("navigation",{name:"Result pages"})).toContainText("Page 2");
  expect(await page.locator(".ops-hit-heading h3").allTextContents()).not.toEqual(titles);
  await expect(page.locator(".ops-hit-rank").first()).toHaveText("4");
  await page.getByRole("button",{name:"Previous",exact:true}).click();
  await expect(page.locator(".ops-hit-heading h3")).toHaveText(titles);
  await page.getByText("Response data",{exact:true}).click();
  await expect(page.locator(".ops-run-data")).toContainText("reconstructed from the combined response");
  const code = page.locator(".ops-run-data .ops-code-block").first();
  expect(await code.locator("pre").evaluate(el => parseFloat(getComputedStyle(el).paddingTop))).toBeGreaterThanOrEqual(40);
  const raw = await code.locator("pre").textContent();
  await page.evaluate(() => Object.defineProperty(navigator,"clipboard",{configurable:true,value:{writeText:async (text:string) => {(window as any).copied=text}}}));
  await code.getByRole("button").click();
  expect(await page.evaluate(() => (window as any).copied)).toBe(raw);
  const box = await code.boundingBox(); const copy = await code.getByRole("button").boundingBox();
  expect(copy!.y).toBeGreaterThanOrEqual(box!.y); expect(copy!.y+copy!.height).toBeLessThan(box!.y+box!.height);
});

test("one purposeful zero-match state and no duplicate per-schema empty cards", async ({page, request}) => {
  await seedScenario(request,"all_green");
  await page.goto("/admin/search/search?mode=multi"); await waitForLiveConnected(page);
  await page.getByLabel("Search text").fill("zzzz-no-such-document-ui-iteration3");
  await page.getByRole("button",{name:"Run search",exact:true}).click();
  await expect(page.locator(".ops-empty-hero")).toHaveCount(1);
  await expect(page.locator(".ops-empty-hero")).toContainText("No matching documents");
  await expect(page.locator("[data-index-outcome=no-hits]")).toHaveCount(0);
  await page.screenshot({path:`${artifacts}/empty.png`,fullPage:true});
});

test("Save sits by Run, validates the name and offers Save and Save as after edits", async ({page, request}) => {
  await seedScenario(request,"all_green");
  await page.goto("/admin/search/search"); await waitForLiveConnected(page);
  await page.getByLabel("Search text").fill("quantum");
  await page.getByRole("button",{name:"Run search",exact:true}).click();
  const save = page.locator("#search-save-new");
  await expect(save).toBeEnabled();
  expect((await save.boundingBox())!.y).toBe((await page.locator("#ops-search-playground-form button[type=submit]").boundingBox())!.y);
  await save.click();
  const dialog = page.getByRole("dialog",{name:"Save search"});
  await expect(dialog.getByLabel("Name",{exact:true})).toBeFocused();
  await dialog.getByLabel("Name",{exact:true}).fill("n".repeat(121));
  await dialog.getByRole("button",{name:"Save",exact:true}).click();
  await expect(page.locator("#saved-search-name-input-error")).toContainText("Enter a name of up to 120 characters.");
  await expect(dialog.getByLabel("Name",{exact:true})).toBeFocused();
  const name = `ui3-${Date.now()}`;
  await dialog.getByLabel("Name",{exact:true}).fill(name);
  await dialog.getByRole("button",{name:"Save",exact:true}).click();
  await expect(dialog).toBeHidden();
  await expect(page.locator("#saved-search-status")).toContainText(`Loaded “${name}”`);
  await expect(save).toHaveCount(0);
  await page.getByLabel("Search text").fill("changed");
  await expect(page.locator("#search-run-attribution")).toContainText("Run search to update these results.");
  await expect(page.locator("#search-save-loaded")).toBeVisible();
  await expect(page.locator("#search-save-as")).toBeVisible();
  await page.locator("#saved-search-picker-button").click();
  await expect(page.locator("#saved-search-menu").getByRole("button",{name:new RegExp(name)})).toBeVisible();
});

test("contextual help opens at a visible heading in a new tab and preserves the task", async ({page, context, request}) => {
  await seedScenario(request,"all_green");
  await page.goto("/admin/search/search?mode=multi"); await waitForLiveConnected(page);
  await page.getByRole("button",{name:"Run search",exact:true}).click();
  await expect(page.locator(".ops-readable-hit").first()).toBeVisible();
  const run = await page.locator("#search-run-attribution").getAttribute("data-run-id");
  for (const width of [1440,390]) {
    await page.setViewportSize({width,height:900});
    for (const [name,fragment] of [["How ordering works","ranking"],["About this limit","limits"]]) {
      const [help] = await Promise.all([context.waitForEvent("page"),page.getByRole("link",{name:new RegExp(name)}).first().click()]);
      await help.setViewportSize({width,height:900});
      await help.reload();
      await waitForLiveConnected(help);
      const target = help.locator(`#${fragment}`);
      await expect(target.getByRole("heading")).toBeInViewport();
      const box = await target.getByRole("heading").boundingBox(); const header = await help.locator(".ops-header").boundingBox();
      expect(box!.y).toBeGreaterThanOrEqual(header!.height);
      await help.screenshot({path:`${artifacts}/help-${fragment}-${width}.png`});
      await help.close();
      await expect(page.locator("#search-run-attribution")).toHaveAttribute("data-run-id",run!);
    }
  }
  await page.goto("/admin/search/help#ranking"); await waitForLiveConnected(page);
  await expect(page.locator("#ranking h3")).toBeInViewport();
});

test("health stages align, icons are consistent, refresh is singular and settings explain missing filters", async ({page,request}) => {
  await page.goto("/admin/search/phase173/health?scenario=processing"); await waitForLiveConnected(page);
  const row=page.getByTestId("posture-row").first();
  for (const theme of ["light","dark"]) {
    await page.getByRole("button",{name:`Use ${theme} theme`,exact:true}).click();
    for (const width of [1440,768,390]) {
      await page.setViewportSize({width,height:900});
      const times=await row.locator(".ops-signal-success").evaluateAll(els=>els.map(el=>el.getBoundingClientRect().y));
      if(width>=768) expect(Math.abs(times[0]-times[1])).toBeLessThan(2);
      expect(await row.locator(".ops-signal-counts dt").count()).toBe(await row.locator(".ops-signal-counts dt svg").count());
      expect(await page.evaluate(()=>document.documentElement.scrollWidth)).toBeLessThanOrEqual(width);
      await page.screenshot({path:`${artifacts}/health-${theme}-${width}.png`,fullPage:true});
    }
  }
  await seedScenario(request,"incident");
  await page.goto("/admin/search/sync-and-index"); await waitForLiveConnected(page);
  await expect(page.locator("#index-settings-status")).toBeVisible();
  await expect(page.getByRole("button",{name:"Refresh settings",exact:true})).toHaveCount(0);
  await expect(page.getByText("Not enabled for filtering",{exact:true})).toBeVisible();
  await expect(page.getByText(/\d+ failed sync operations?/)).toBeVisible();
  await page.screenshot({path:`${artifacts}/settings.png`,fullPage:true});
});
