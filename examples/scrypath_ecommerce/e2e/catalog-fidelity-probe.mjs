#!/usr/bin/env node
// catalog-fidelity-probe.mjs
//
// A local, NON-GATING check of how faithfully the component catalog (storybook) draws a story next
// to the real screen. It reads computed styles in a real browser; it is not a Playwright spec, so
// the advisory `playwright test` lane never picks it up, and no CI job runs it.
//
// It only loads loopback URLs and local files. A request to any other host is blocked.
//
// Usage (from examples/scrypath_ecommerce/, with the catalog running):
//
//   node e2e/catalog-fidelity-probe.mjs --font primitives/ops_button:default
//   node e2e/catalog-fidelity-probe.mjs --compare areas/health_verdict:shopadelic_failed_journey \
//        --real /path/to/real-page.html
//
// Options:
//   --base <url>     catalog origin, loopback only (default http://127.0.0.1:4003)
//   --selectors <s>  comma-separated selectors for --compare (default: the verdict and status set)
//
// --font <story path>:<variation>
//   Opens the story iframe in light and dark and compares the computed font-family of <body> with
//   the one on <html>. The product stylesheet sets the family on <html>; the storybook sandbox once
//   put a serif family on <body> and every story drew in it. Exit 1 prints both families.
//
// --compare <story path>:<variation> --real <html file>
//   Opens the story iframe and a real page dump (an HTML file the mounted app rendered, served
//   from the same origin so the stylesheet and fonts load, with JavaScript blocked and data-theme
//   set on <html> as storybook.js does), then compares color, background, border, radius, padding,
//   font, line height and letter spacing over the selectors, in light and dark. Exit 1 on any
//   difference or on a selector missing from one side.
//
// Exit codes: 0 same, 1 differences, 2 bad arguments or a probe failure.

import { readFile } from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { chromium } from "playwright-core";

const DEFAULT_BASE = "http://127.0.0.1:4003";
const THEMES = ["light", "dark"];
const VIEWPORT = { width: 1280, height: 900 };
const DEFAULT_SELECTORS = [
  ".ops-verdict",
  ".ops-verdict p.text-ops-h2",
  "[data-sync-status]",
  ".ops-sync-status__word",
  ".ops-time__value"
];
const PROPERTIES = [
  "color",
  "background-color",
  "border-top-color",
  "border-top-width",
  "border-radius",
  "padding-top",
  "padding-left",
  "font-family",
  "font-size",
  "font-weight",
  "line-height",
  "letter-spacing"
];
const LOOPBACK_HOSTS = new Set(["127.0.0.1", "localhost", "[::1]"]);
const REAL_PATH = "/__catalog_probe__/real.html";

function fail(message) {
  console.error(`catalog-fidelity-probe: ${message}`);
  process.exit(2);
}

export function parseArgs(argv) {
  const options = { base: DEFAULT_BASE, selectors: DEFAULT_SELECTORS };
  for (let index = 0; index < argv.length; index += 1) {
    const flag = argv[index];
    const value = argv[index + 1];
    if (!["--font", "--compare", "--real", "--base", "--selectors"].includes(flag)) fail(`unknown option ${flag}`);
    if (value === undefined || value.startsWith("--")) fail(`${flag} needs a value`);
    index += 1;
    if (flag === "--font") options.font = value;
    if (flag === "--compare") options.compare = value;
    if (flag === "--real") options.real = value;
    if (flag === "--base") options.base = value;
    if (flag === "--selectors") options.selectors = value.split(",").map((s) => s.trim()).filter(Boolean);
  }
  return options;
}

export function loopbackBase(base) {
  let url;
  try {
    url = new URL(base);
  } catch {
    return null;
  }
  if (url.protocol !== "http:" || !LOOPBACK_HOSTS.has(url.hostname)) return null;
  return url.origin;
}

// "primitives/ops_button:default" -> { path: "primitives/ops_button", variation: "default" }
export function parseStory(spec) {
  const cut = spec.lastIndexOf(":");
  if (cut < 1 || cut === spec.length - 1) return null;
  const storyPath = spec.slice(0, cut);
  const variation = spec.slice(cut + 1);
  if (!/^[a-z0-9_]+(\/[a-z0-9_]+)*$/.test(storyPath) || !/^[A-Za-z0-9_.-]+$/.test(variation)) return null;
  return { path: storyPath, variation };
}

function storyUrl(base, story, theme) {
  return `${base}/storybook/iframe/${story.path}?variation_id=${encodeURIComponent(story.variation)}&theme=${theme}`;
}

// Blocks every request that is not loopback. Registered first, so every later, more specific
// route runs before it and this one only sees what they did not handle.
async function blockNonLoopback(context) {
  await context.route("**/*", (route) => {
    const { hostname } = new URL(route.request().url());
    if (LOOPBACK_HOSTS.has(hostname)) return route.continue();
    return route.abort("blockedbyclient");
  });
}

async function openStory(context, base, story, theme) {
  const page = await context.newPage();
  await page.goto(storyUrl(base, story, theme), { waitUntil: "load" });
  await page.waitForSelector("[data-phx-main]");
  return page;
}

async function runFont(browser, base, story) {
  let different = false;
  for (const theme of THEMES) {
    const context = await browser.newContext({ viewport: VIEWPORT, colorScheme: "light" });
    await blockNonLoopback(context);
    const page = await openStory(context, base, story, theme);
    const families = await page.evaluate(() => ({
      html: getComputedStyle(document.documentElement).fontFamily,
      body: getComputedStyle(document.body).fontFamily
    }));
    await context.close();

    const same = families.html === families.body;
    console.log(`${same ? "same     " : "DIFFERENT"} ${theme.padEnd(5)} html: ${families.html} | body: ${families.body}`);
    if (!same) different = true;
  }
  return different;
}

function readStyles(page, selectors) {
  return page.evaluate(
    ([sels, props]) =>
      Object.fromEntries(
        sels.map((selector) => {
          const element = document.querySelector(selector);
          if (!element) return [selector, null];
          const style = getComputedStyle(element);
          return [selector, Object.fromEntries(props.map((prop) => [prop, style.getPropertyValue(prop)]))];
        })
      ),
    [selectors, PROPERTIES]
  );
}

async function runCompare(browser, base, story, realHtml, selectors) {
  let different = false;
  for (const theme of THEMES) {
    const context = await browser.newContext({ viewport: VIEWPORT, colorScheme: "light" });
    await blockNonLoopback(context);
    const storyPage = await openStory(context, base, story, theme);

    const realPage = await context.newPage();
    // JavaScript stays off for the real page: no LiveView connect, computed styles only.
    await realPage.route("**/*.js*", (route) => route.abort());
    await realPage.route(`${base}${REAL_PATH}`, (route) => route.fulfill({ contentType: "text/html", body: realHtml }));
    await realPage.goto(`${base}${REAL_PATH}`, { waitUntil: "load" });
    await realPage.evaluate((t) => document.documentElement.setAttribute("data-theme", t), theme);

    const [fromStory, fromReal] = [await readStyles(storyPage, selectors), await readStyles(realPage, selectors)];
    await context.close();

    for (const selector of selectors) {
      const [a, b] = [fromStory[selector], fromReal[selector]];
      if (!a && !b) {
        console.log(`MISSING   ${theme.padEnd(5)} ${selector}: in neither the story nor the real page`);
        different = true;
      } else if (!a || !b) {
        console.log(`MISSING   ${theme.padEnd(5)} ${selector}: not in the ${a ? "real page" : "story"}`);
        different = true;
      } else {
        const diffs = PROPERTIES.filter((prop) => a[prop] !== b[prop]);
        if (diffs.length === 0) console.log(`identical ${theme.padEnd(5)} ${selector}`);
        for (const prop of diffs) {
          console.log(`DIFFERENT ${theme.padEnd(5)} ${selector} ${prop}: story=${a[prop]} | real=${b[prop]}`);
          different = true;
        }
      }
    }
  }
  return different;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const base = loopbackBase(options.base);
  if (!base) fail(`--base must be an http loopback origin (127.0.0.1, localhost or [::1]), got ${options.base}`);
  if (Boolean(options.font) === Boolean(options.compare)) fail("give exactly one of --font and --compare");

  const spec = options.font ?? options.compare;
  const story = parseStory(spec);
  if (!story) fail(`story must look like primitives/ops_button:default, got ${spec}`);

  let realHtml;
  if (options.compare) {
    if (!options.real) fail("--compare needs --real <html file>");
    if (/^[a-z][a-z0-9+.-]*:\/\//i.test(options.real)) fail("--real must be a local file, not a URL");
    realHtml = await readFile(options.real, "utf8");
  }

  const started = Date.now();
  const browser = await chromium.launch();
  let different;
  try {
    different = options.font
      ? await runFont(browser, base, story)
      : await runCompare(browser, base, story, realHtml, options.selectors);
  } finally {
    await browser.close();
  }

  console.log(`${different ? "RESULT: differences found" : "RESULT: no differences"} (${Date.now() - started} ms)`);
  process.exit(different ? 1 : 0);
}

// Run only as a script, so the pure helpers above can be imported by a test.
if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  main().catch((error) => fail(error?.message ?? String(error)));
}
