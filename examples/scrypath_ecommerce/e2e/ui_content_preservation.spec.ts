import { chromium, test as base, type Browser } from "@playwright/test";
import { runPreservationCase, launchPreservationBrowser, CONTENT_ELEMENTS, OVERFLOW_ELEMENTS } from "./helpers/ui-preservation-states";

const test = base.extend<{ preservationBrowser: Browser }>({
  preservationBrowser: [async ({}, use) => {
    const browser = await launchPreservationBrowser(chromium);
    try { await use(browser); } finally { await browser.close(); }
  }, { scope: "worker" }]
});

test.describe.configure({ mode: "serial" });

for (const element of OVERFLOW_ELEMENTS) {
  test(`${element} overflow`, async ({ preservationBrowser, request }, testInfo) => {
    test.setTimeout(90_000);
    await runPreservationCase({ browser: preservationBrowser, request, testInfo, element, category: "overflow" });
  });
}

for (const element of CONTENT_ELEMENTS) {
  test(`${element} long-text`, async ({ preservationBrowser, request }, testInfo) => {
    test.setTimeout(90_000);
    await runPreservationCase({ browser: preservationBrowser, request, testInfo, element, category: "long-text" });
  });
}
