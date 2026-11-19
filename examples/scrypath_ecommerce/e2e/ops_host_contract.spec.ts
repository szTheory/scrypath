/**
 * ScrypathOps host contract (Phase 187, UI-SPEC P-17, A11Y-04).
 *
 * ScrypathOps is mounted inside a host application, so the re-skin must not leak into the host and
 * must stay overridable by it. This spec treats the e-commerce demo as the fixture host and proves,
 * in a real browser with no change to host code (`addStyleTag` and a loopback header proxy only):
 *
 *   P-17a  a non-ops host route links no ops stylesheet and computes no `--color-primary`
 *   P-17b  a sentinel element on a host route computes the same style in all six combinations of OS
 *          scheme and stored theme preference, and again after visiting an ops route and coming back
 *   P-17c  a host `--color-primary` rule added after the ops stylesheet wins on `.btn-primary`, in
 *          light, in an explicit dark theme and in System dark. System dark is proved twice: with
 *          the plain `:root { --color-primary: ... }` rule the README tells hosts to write, and
 *          with the dark-scheme form of the override. The guarantee is for unlayered rules: the
 *          daisyUI theme variables live in `@layer base`, so a Tailwind `@theme` override (the
 *          lower `theme` layer) loses to them whatever the load order
 *   P-17d  with `Content-Security-Policy: font-src 'self'` on the ops document both fonts still load
 *          and no `securitypolicyviolation` fires; a planted `font-src 'none'` makes the same probe
 *          fail, so the probe can see a break
 *
 * `document.fonts.check` alone would pass for a family that has no face at all, so the font probe
 * asks `document.fonts.load` for each family and requires a face whose status is `loaded`.
 *
 * HOW TO RUN (manual server per playwright.config.ts, there is NO webServer):
 *   Boot a disposable test stack (see `make up`), then
 *     cd examples/scrypath_ecommerce
 *     PLAYWRIGHT_BASE_URL=http://127.0.0.1:<port> npx playwright test e2e/ops_host_contract.spec.ts --workers=1
 */
import { createServer, request as httpRequest } from "node:http";
import type { AddressInfo } from "node:net";

import { expect, test, type Browser, type BrowserContext, type Page } from "@playwright/test";

import { waitForLiveConnected } from "./helpers/e2e";

const OPS_SHEET = "/admin/search/assets/css/app.css";
const HOST_ROUTES = ["/", "/?q=quantum"] as const;

type Scheme = "light" | "dark";
type Preference = "light" | "dark" | null;
type Combination = { scheme: Scheme; preference: Preference };

// OS scheme x stored preference: the six settled combinations the host can be in.
const COMBINATIONS: Combination[] = [
  { scheme: "light", preference: null },
  { scheme: "light", preference: "light" },
  { scheme: "light", preference: "dark" },
  { scheme: "dark", preference: null },
  { scheme: "dark", preference: "light" },
  { scheme: "dark", preference: "dark" }
];

const label = (c: Combination) => `OS ${c.scheme}, stored ${c.preference ?? "none"}`;

async function newPage(browser: Browser, combination: Combination): Promise<{ context: BrowserContext; page: Page }> {
  const context = await browser.newContext({ colorScheme: combination.scheme });
  if (combination.preference) {
    await context.addInitScript(
      ([key, value]: [string, string]) => {
        try {
          window.localStorage.setItem(key, value);
        } catch {
          // about:blank has no storage; the app's own document does.
        }
      },
      ["phx:theme", combination.preference]
    );
  }
  return { context, page: await context.newPage() };
}

type SentinelStyle = Record<string, string>;

// A bare element with no class or id, appended to the body of the current document, read back through
// getComputedStyle. Nothing about it is ops or host specific, so any change in it comes from a rule
// that reaches ordinary elements.
async function readSentinel(page: Page): Promise<SentinelStyle> {
  return page.evaluate(() => {
    const sentinel = document.createElement("div");
    sentinel.textContent = "host sentinel";
    document.body.appendChild(sentinel);
    const computed = getComputedStyle(sentinel);
    const properties = [
      "color",
      "background-color",
      "font-family",
      "font-size",
      "font-weight",
      "line-height",
      "margin-top",
      "margin-right",
      "margin-bottom",
      "margin-left",
      "padding-top",
      "box-sizing",
      "border-top-width"
    ];
    const style: Record<string, string> = {};
    for (const property of properties) style[property] = computed.getPropertyValue(property);
    style.margin = computed.margin;
    sentinel.remove();
    return style;
  });
}

type HeaderProxy = { origin: string; close: () => Promise<void> };

// A loopback HTTP proxy to the host under test that adds one response header to one document path and
// passes everything else through unchanged. It forwards plain requests only (no WebSocket upgrade).
async function startHeaderProxy(target: string, documentPath: string, name: string, value: string): Promise<HeaderProxy> {
  const upstream = new URL(target);
  const server = createServer((incoming, outgoing) => {
    const forwarded = httpRequest(
      { hostname: upstream.hostname, port: upstream.port, method: incoming.method, path: incoming.url, headers: { ...incoming.headers, host: upstream.host } },
      (response) => {
        const headers = { ...response.headers };
        if ((incoming.url ?? "").split("?")[0] === documentPath) headers[name] = value;
        outgoing.writeHead(response.statusCode ?? 502, headers);
        response.pipe(outgoing);
      }
    );
    forwarded.on("error", () => {
      outgoing.writeHead(502);
      outgoing.end();
    });
    incoming.pipe(forwarded);
  });
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const { port } = server.address() as AddressInfo;
  return {
    origin: `http://127.0.0.1:${port}`,
    close: () =>
      new Promise<void>((resolve) => {
        server.close(() => resolve());
        server.closeAllConnections();
      })
  };
}

async function openHostRoute(page: Page, route: string): Promise<void> {
  await page.goto(route);
  await waitForLiveConnected(page);
}

test.describe("ops host contract", () => {
  test("P-17a a non-ops host route loads no ops stylesheet and computes no accent", async ({ browser }) => {
    const { context, page } = await newPage(browser, { scheme: "light", preference: null });
    try {
      for (const route of HOST_ROUTES) {
        await openHostRoute(page, route);
        const facts = await page.evaluate((sheet) => ({
          links: Array.from(document.querySelectorAll("link[rel=stylesheet]")).map((node) => (node as HTMLLinkElement).getAttribute("href") || ""),
          sheets: Array.from(document.styleSheets).map((s) => s.href || ""),
          primary: getComputedStyle(document.documentElement).getPropertyValue("--color-primary").trim(),
          opsLinkCount: document.querySelectorAll(`link[href*="${sheet}"]`).length
        }), OPS_SHEET);
        expect(facts.opsLinkCount, `${route} links the ops stylesheet`).toBe(0);
        expect(facts.links.some((href) => href.includes(OPS_SHEET)), `${route} stylesheet links: ${facts.links.join(", ")}`).toBe(false);
        expect(facts.sheets.some((href) => href.includes(OPS_SHEET)), `${route} loaded sheets: ${facts.sheets.join(", ")}`).toBe(false);
        expect(facts.primary, `${route} computes --color-primary on the root`).toBe("");
        // The host's own sheet is what the page does load, so the probe is not reading an empty document.
        expect(facts.links.length, `${route} has its own stylesheet`).toBeGreaterThan(0);
      }

      // The same document with the ops sheet linked computes the accent, so an empty value above is a
      // real absence, not a probe that can never see the variable.
      await page.goto("/admin/search");
      await waitForLiveConnected(page);
      const onOps = await page.evaluate(() => getComputedStyle(document.documentElement).getPropertyValue("--color-primary").trim());
      expect(onOps, "the ops route computes --color-primary").not.toBe("");
    } finally {
      await context.close();
    }
  });

  test("P-17b a host sentinel is unchanged by OS scheme, stored theme and a visit to ops", async ({ browser }) => {
    const readings: Array<{ name: string; style: SentinelStyle }> = [];
    for (const combination of COMBINATIONS) {
      const { context, page } = await newPage(browser, combination);
      try {
        await openHostRoute(page, "/");
        const first = await readSentinel(page);
        readings.push({ name: label(combination), style: first });

        // Visit an ops route and come back to the host route: a full navigation, same storage.
        await page.goto("/admin/search");
        await waitForLiveConnected(page);
        await openHostRoute(page, "/");
        const returned = await readSentinel(page);
        readings.push({ name: `${label(combination)}, after visiting ops`, style: returned });
      } finally {
        await context.close();
      }
    }
    expect(readings.length).toBe(COMBINATIONS.length * 2);
    const baseline = readings[0];
    for (const reading of readings.slice(1)) {
      expect(reading.style, `${reading.name} differs from ${baseline.name}`).toEqual(baseline.style);
    }
  });

  test("P-17c a host accent override added after the ops stylesheet wins on the primary button", async ({ browser }) => {
    // `plain` is the rule the README tells hosts to write; `darkScheme` is the dark-scheme form of the same override.
    const plain = ":root{--color-primary:#123456}";
    const darkScheme = "@media (prefers-color-scheme: dark){:root:not([data-theme]){--color-primary:#123456}}";
    const cases: Array<{ name: string; combination: Combination; css: string }> = [
      { name: "light", combination: { scheme: "light", preference: null }, css: plain },
      { name: "explicit dark", combination: { scheme: "light", preference: "dark" }, css: plain },
      { name: "System dark", combination: { scheme: "dark", preference: null }, css: darkScheme },
      { name: "System dark, plain :root rule", combination: { scheme: "dark", preference: null }, css: plain }
    ];
    for (const { name, combination, css } of cases) {
      const { context, page } = await newPage(browser, combination);
      try {
        await page.goto("/admin/search");
        await waitForLiveConnected(page);
        const button = page.locator(".btn-primary:visible").first();
        await expect(button, `${name}: the ops route has a visible primary button`).toBeVisible();
        const before = await button.evaluate((node) => getComputedStyle(node).backgroundColor);
        expect(before, `${name}: the ops accent before the override`).not.toBe("rgb(18, 52, 86)");

        // Added after load, so it comes after the ops stylesheet in the cascade, as a host's would.
        await page.addStyleTag({ content: css });
        await expect.poll(() => button.evaluate((node) => getComputedStyle(node).backgroundColor), { message: `${name}: host accent wins`, timeout: 5_000 }).toBe("rgb(18, 52, 86)");
      } finally {
        await context.close();
      }
    }
  });

  test("P-17d font-src 'self' on the ops document still loads both fonts with no violation", async ({ browser }) => {
    type FontRun = { violations: string[]; loaded: Record<string, string[]>; checks: Record<string, boolean>; notes: string[] };
    const target = test.info().project.use.baseURL;
    if (!target) throw new Error("this spec needs a baseURL (PLAYWRIGHT_BASE_URL)");

    async function runWithCsp(policy: string, expectViolation: boolean): Promise<FontRun> {
      // The header comes from a loopback proxy in this process, not from `page.route`. A document that
      // `route.fulfill` serves is treated by Chromium as public, so on a Compose network (`http://web:4002`,
      // not a secure context) every stylesheet, script and image it asks for from the private address is
      // blocked ("The request client is not a secure context"). Through the proxy the page and all its
      // subresources share one loopback origin, so `'self'` means exactly the host's own origin.
      const proxy = await startHeaderProxy(target as string, "/admin/search", "content-security-policy", policy);
      const { context, page } = await newPage(browser, { scheme: "light", preference: null });
      try {
        await page.addInitScript(() => {
          const sink: string[] = [];
          (window as unknown as { __cspViolations: string[] }).__cspViolations = sink;
          document.addEventListener("securitypolicyviolation", (event) => {
            sink.push(`${event.violatedDirective} blocked ${event.blockedURI}`);
          });
        });
        // Anything that went wrong in the page, so a failure names its cause (a CSP block or something else).
        const notes: string[] = [];
        page.on("requestfailed", (request) => {
          notes.push(`failed ${new URL(request.url()).pathname}: ${request.failure()?.errorText ?? "unknown"}`);
        });
        page.on("console", (message) => {
          if (message.type() === "error") notes.push(`console: ${message.text().slice(0, 160)}`);
        });
        // No waitForLiveConnected: the proxy forwards plain requests only, not the LiveView WebSocket,
        // and fonts do not need the socket (the stylesheet and `document.fonts.load` are enough).
        await page.goto(`${proxy.origin}/admin/search`, { waitUntil: "load" });
        const result = await page.evaluate(async () => {
          const families = ["Hanken Grotesk", "Sometype Mono"];
          const loaded: Record<string, string[]> = {};
          const checks: Record<string, boolean> = {};
          for (const family of families) {
            let faces: FontFace[] = [];
            try {
              faces = await document.fonts.load(`16px "${family}"`);
            } catch {
              faces = [];
            }
            loaded[family] = faces.map((face) => `${face.family}:${face.status}`);
            checks[family] = document.fonts.check(`16px "${family}"`);
          }
          await document.fonts.ready;
          return { loaded, checks };
        });
        // The browser queues a securitypolicyviolation event as a task of its own, so it can arrive
        // after the font promises settle. When one is expected, wait for it; when none is, give any
        // late one half a second before reading the list.
        const readViolations = () => page.evaluate(() => (window as unknown as { __cspViolations: string[] }).__cspViolations.slice());
        if (expectViolation) {
          // A timeout is not an error here: the assertions after the run report what was seen.
          await page
            .waitForFunction(() => (window as unknown as { __cspViolations: string[] }).__cspViolations.length > 0, undefined, { timeout: 5_000 })
            .catch(() => undefined);
        } else {
          await page.waitForTimeout(500);
        }
        return { ...result, violations: await readViolations(), notes };
      } finally {
        await context.close();
        await proxy.close();
      }
    }

    // The probe can fail: with no font allowed, a violation fires and the faces do not load.
    const blocked = await runWithCsp("font-src 'none'", true);
    expect(blocked.violations.length, `a planted font-src 'none' makes the probe see a violation (page notes: ${blocked.notes.join("; ")})`).toBeGreaterThan(0);
    for (const family of ["Hanken Grotesk", "Sometype Mono"]) {
      expect(blocked.loaded[family].some((face) => face.endsWith(":loaded")), `${family} loads under font-src 'none'`).toBe(false);
    }

    const allowed = await runWithCsp("font-src 'self'", false);
    expect(allowed.violations, `font-src 'self' raises no securitypolicyviolation (page notes: ${allowed.notes.join("; ")})`).toEqual([]);
    for (const family of ["Hanken Grotesk", "Sometype Mono"]) {
      expect(allowed.loaded[family].length, `${family} has a face to load`).toBeGreaterThan(0);
      expect(allowed.loaded[family].every((face) => face.endsWith(":loaded")), `${family} faces: ${allowed.loaded[family].join(", ")}`).toBe(true);
      expect(allowed.checks[family], `document.fonts.check for ${family}`).toBe(true);
    }
  });
});
