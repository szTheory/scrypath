import { chromium, test as base, type Browser } from "@playwright/test";
import { runPreservationCase, launchPreservationBrowser, STATE_ELEMENTS, STATE_CATEGORIES, ACTION_ELEMENTS } from "./helpers/ui-preservation-states";

const test = base.extend<{ preservationBrowser: Browser }>({
  preservationBrowser: [async ({}, use) => {
    const browser = await launchPreservationBrowser(chromium);
    try { await use(browser); } finally { await browser.close(); }
  }, { scope: "worker" }]
});

// Each case resets its owned data. One worker preserves execution order, while
// default mode lets later independent cases report their own failures.
test.describe.configure({ mode: "default" });

for (const element of STATE_ELEMENTS) {
  for (const category of STATE_CATEGORIES) {
    test(`${element} ${category}`, async ({ preservationBrowser, request }, testInfo) => {
      test.setTimeout(90_000);
      await runPreservationCase({ browser: preservationBrowser, request, testInfo, element, category });
    });
  }
}

for (const element of ACTION_ELEMENTS) {
  for (const category of ["loading", "error"] as const) {
    test(`${element} ${category}`, async ({ preservationBrowser, request }, testInfo) => {
      test.setTimeout(90_000);
      await runPreservationCase({ browser: preservationBrowser, request, testInfo, element, category });
    });
  }
}
