import assert from "node:assert/strict";
import { createServer } from "node:http";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { test } from "node:test";

const testName = "actual CommandPalette copies patched destinations into ignored links and disconnects";

test(testName, async () => {
  const fixturePath = process.env.SCRYPATH_PALETTE_DOM_FIXTURE;
  const playwrightPath = process.env.PLAYWRIGHT_MODULE;
  assert.ok(fixturePath, "SCRYPATH_PALETTE_DOM_FIXTURE must point to LiveView-rendered shell markup");
  assert.ok(playwrightPath, "PLAYWRIGHT_MODULE must point to the existing Playwright module");

  const fixture = readFileSync(fixturePath, "utf8");
  const html = fixture.replace(/<script\b[^>]*\bsrc="[^"]*"[^>]*><\/script>/g, "");
  const hookSource = readFileSync(resolve("scrypath_ops/assets/js/ops_hooks.js"), "utf8");
  const server = createServer((request, response) => {
    if (request.url === "/fixture.html") {
      response.writeHead(200, { "content-type": "text/html; charset=utf-8" });
      response.end(html);
      return;
    }

    if (request.url === "/ops_hooks.js") {
      response.writeHead(200, { "content-type": "text/javascript; charset=utf-8" });
      response.end(hookSource);
      return;
    }

    if (request.url === "/hook-loader.js") {
      response.writeHead(200, { "content-type": "text/javascript; charset=utf-8" });
      response.end('import { CommandPalette } from "/ops_hooks.js"; window.__paletteHook = CommandPalette;');
      return;
    }

    response.writeHead(404);
    response.end();
  });
  await new Promise((resolveListen) => server.listen(0, "127.0.0.1", resolveListen));

  let browser;
  try {
    const { chromium } = await import(pathToFileURL(playwrightPath).href);
    browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();
    const address = server.address();
    assert.ok(address && typeof address === "object");
    const origin = `http://127.0.0.1:${address.port}`;

    await page.goto(`${origin}/fixture.html`, { waitUntil: "domcontentloaded" });
    await page.addScriptTag({ url: `${origin}/hook-loader.js`, type: "module" });
    await page.waitForFunction(() => Boolean(window.__paletteHook));
    await page.evaluate(() => {
      window.__paletteHook.el = document.querySelector("#ops-command-palette");
      window.__paletteHook.mounted();
    });

    const before = await page.evaluate(() => ({
      manifest: Array.from(document.querySelectorAll("#ops-command-palette-destinations [data-ops-palette-destination]"), (el) => el.getAttribute("href")),
      palette: Array.from(document.querySelectorAll("#ops-command-palette [data-cmdk-item]"), (el) => el.getAttribute("href"))
    }));
    assert.equal(before.manifest.length, 3, "LiveView fixture supplies three server-owned recovery destinations");
    assert.ok(before.manifest.every((href) => href.includes("OpsPostA")), "manifest starts with schema A");
    assert.ok(before.palette.slice(1, 4).every((href) => href.includes("OpsPostA")), "ignored palette starts with schema A");

    await page.evaluate(() => {
      document.querySelectorAll("#ops-command-palette-destinations [data-ops-palette-destination]").forEach((destination) => {
        const url = new URL(destination.getAttribute("href"), "http://ops.local");
        url.searchParams.set("schema", "Elixir.ScrypathOps.Test.OpsPostB");
        destination.setAttribute("href", `${url.pathname}${url.search}`);
      });
    });

    await page.waitForTimeout(30);
    const afterPatch = await page.locator("#ops-command-palette [data-cmdk-item]").evaluateAll((links) =>
      links.slice(1, 4).map((link) => link.getAttribute("href"))
    );
    assert.ok(
      afterPatch.every((href) => href?.includes("OpsPostB")),
      `patched manifest points to B, but ignored palette links are ${JSON.stringify(afterPatch)}`
    );

    const trigger = page.locator("[data-ops-command-open]").first();
    await trigger.click();
    const input = page.locator("#ops-command-palette [data-cmdk-input]");
    await assert.equal(await input.evaluate((element) => document.activeElement === element), true);
    await input.fill("sync drift");
    await assert.equal(await page.locator("#ops-cmdk-item-3").evaluate((element) => !element.parentElement.hidden), true);
    await page.keyboard.press("Escape");
    await page.waitForFunction(() => document.querySelector("#ops-cmdk").hasAttribute("hidden"));
    await assert.equal(await trigger.evaluate((element) => document.activeElement === element), true);

    await page.evaluate(() => {
      window.__paletteHook.destroyed();
      document.querySelectorAll("#ops-command-palette-destinations [data-ops-palette-destination]").forEach((destination) => {
        const url = new URL(destination.getAttribute("href"), "http://ops.local");
        url.searchParams.set("schema", "Elixir.ScrypathOps.Test.OpsPostA");
        destination.setAttribute("href", `${url.pathname}${url.search}`);
      });
    });
    await new Promise((resolveTick) => setTimeout(resolveTick, 0));
    const afterDestroy = await page.locator("#ops-cmdk-item-1").getAttribute("href");
    assert.ok(afterDestroy.includes("OpsPostB"), "destroyed hook no longer observes destination patches");
  } finally {
    if (browser) await browser.close();
    await new Promise((resolveClose) => server.close(resolveClose));
  }
});
