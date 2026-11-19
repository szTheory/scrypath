#!/usr/bin/env node
// ScrypathOps re-skin capture (Phase 187, SKIN-08).
//
// Captures three screens (Control room, Search health with the `all-statuses` fixture scenario, Failed
// sync work) in light and dark at 1280 and 390 px: 12 full-page PNGs plus a manifest that names the
// source commit, so a before set and an after set can be compared by someone looking at them. Nothing
// here is a gate: the captures are review context, not a baseline, and no image is compared by pixel.
//
//   node scripts/reskin-capture.mjs --label before --base-url http://127.0.0.1:4102 --out DIR
//   node scripts/reskin-capture.mjs --label after --base-url http://127.0.0.1:4102 --out DIR --allow-stale-source
//   node scripts/reskin-capture.mjs --check DIR
//
// The stack must be a MIX_ENV=test build: the `all-statuses` Search health scenario is a test-only
// fixture route and the seed endpoint (`/dev/e2e/seed`) exists only there.
//
// The manifest names the source that rendered the images, so two things are checked rather than
// assumed (review WR-02):
//
// 1. "No capture from a dirty tree" means: refuse to run when `git status --porcelain` lists any
//    change outside `.planning/`, tracked or untracked (a new `.ex`, `.heex`, `.css` or `.js` file
//    under a bind-mounted dev stack is compiled whatever git thinks of it; `.planning/` edits cannot
//    change what renders; gitignored files are never listed). The manifest's `clean` is the result
//    of that check, not a constant, and the complete status output is recorded as `git_status`.
// 2. The stack serves the build it claims to. The script fetches the ops stylesheet the stack links
//    from `/admin/search`, hashes it, and compares it with `scrypath_ops/priv/static/assets/css/app.css`
//    at HEAD. A mismatch means the running image or watcher is not rendering HEAD, so the capture is
//    refused unless `--allow-stale-source` is passed; both hashes, the match result and the flag are
//    recorded in the manifest (`served_css_sha256`, `head_css_sha256`, `served_css_matches_head`,
//    `allow_stale_source`), and `--check` re-derives the match from the two hashes.
//
// This file is deliberately not a Playwright spec (no `*.spec.ts`), so Playwright discovery and the
// evidence inventory ignore it, and it does not touch the fixture-overlay files. It imports only
// `node:*` modules and, in capture mode, `chromium` from the already-installed `@playwright/test`.

import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { existsSync, readdirSync, readFileSync, renameSync, rmSync, mkdirSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(HERE, "../../..");

export const SCHEMA = "scrypath.reskin-capture.v1";
export const MANIFEST_NAME = "manifest.json";
export const SCENARIO = "all-statuses";
export const SEED_SCENARIO = "incident";
export const THEMES = ["light", "dark"];
export const VIEWPORTS = [
  { width: 1280, height: 900 },
  { width: 390, height: 844 },
];
export const SCREENS = [
  { id: "control-room", route: "/admin/search" },
  { id: "search-health", route: `/admin/search/phase173/health?scenario=${SCENARIO}` },
  { id: "failed-sync", route: "/admin/search/failed-sync" },
];

/** Where the demo mounts ScrypathOps, and the page whose `<link>` names the stylesheet the stack serves. */
export const OPS_MOUNT = "/admin/search";
/** The committed build of the ops stylesheet; the stack must serve exactly these bytes. */
export const OPS_STYLESHEET_PATH = "scrypath_ops/priv/static/assets/css/app.css";

/** The 12 file names a complete capture set holds: `{screen}-{theme}-{width}.png`. */
export function expectedFiles() {
  const names = [];
  for (const screen of SCREENS) {
    for (const theme of THEMES) {
      for (const viewport of VIEWPORTS) names.push(`${screen.id}-${theme}-${viewport.width}.png`);
    }
  }
  return names;
}

export function sha256(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

/**
 * Reads a plain `git status --porcelain` listing, untracked entries included, and returns `{ clean, offending }`.
 * Every tracked change and every untracked, non-ignored file or directory outside `.planning/` is
 * offending: a bind-mounted dev stack compiles whatever is on disk, tracked or not. Ignored (`!!`)
 * entries only appear when asked for and never count. `.planning/` edits cannot change what renders.
 */
export function inspectTree(statusText) {
  const offending = [];
  for (const line of String(statusText).split("\n")) {
    if (line.trim() === "") continue;
    const code = line.slice(0, 2);
    if (code === "!!") continue;
    const rest = line.slice(3).trim();
    // A rename reads `old -> new`; both sides count.
    for (const raw of rest.split(" -> ")) {
      const file = raw.replace(/^"(.*)"$/, "$1");
      if (!file.startsWith(".planning/")) offending.push(code === "??" ? `${file} (untracked)` : file);
    }
  }
  return { clean: offending.length === 0, offending };
}

/** Throws when the tree is not clean (see `inspectTree`); otherwise returns its `{ clean, offending }`. */
export function assertCleanTree(statusText) {
  const tree = inspectTree(statusText);
  if (!tree.clean) {
    throw new Error(
      `refusing to capture from a dirty tree: changes outside .planning/: ${tree.offending.join(", ")}. ` +
        "Commit them (or remove the untracked files) so the manifest names the source that rendered the images.",
    );
  }
  return tree;
}

/**
 * The ops stylesheet URL a page links: the one `<link rel="stylesheet">` whose path ends in
 * `/assets/css/app.css`, preferring the one under `mount` (the host may link its own `app.css`).
 * Throws when none or more than one candidate remains, so a hash is never taken of a guess.
 */
export function findOpsStylesheetHref(html, mount = OPS_MOUNT) {
  const hrefs = [];
  for (const [tag] of String(html).matchAll(/<link\b[^>]*>/gi)) {
    if (!/\brel\s*=\s*["']?[^"'>]*\bstylesheet\b/i.test(tag)) continue;
    const match = /\bhref\s*=\s*(?:"([^"]*)"|'([^']*)')/i.exec(tag);
    const href = (match?.[1] ?? match?.[2] ?? "").replaceAll("&amp;", "&");
    if (/\/assets\/css\/app\.css(?:[?#].*)?$/.test(href)) hrefs.push(href);
  }
  const mounted = hrefs.filter((href) => href.startsWith(`${mount}/`));
  const candidates = [...new Set(mounted.length > 0 ? mounted : hrefs)];
  if (candidates.length !== 1) {
    throw new Error(
      `expected exactly one ops stylesheet link (…/assets/css/app.css) on the ${mount} page, found ${candidates.length}` +
        (candidates.length > 0 ? `: ${candidates.join(", ")}` : ""),
    );
  }
  return candidates[0];
}

/**
 * Compares the stylesheet the stack serves with the one committed at HEAD. Equal hashes return
 * `{ matches: true, allowStale }`. Different hashes throw (the stack is not rendering HEAD) unless
 * `allowStale` is set, in which case `{ matches: false, allowStale: true }` is returned for the manifest.
 */
export function assessStylesheet({ servedSha256, headSha256, allowStale = false }) {
  const matches = servedSha256 === headSha256;
  if (!matches && !allowStale) {
    throw new Error(
      `the stack serves a different ops stylesheet than HEAD (served ${servedSha256}, HEAD ${headSha256}): ` +
        "its image or watcher is not rendering this commit. Rebuild and restart the stack, or pass " +
        "--allow-stale-source to capture anyway and record that in the manifest.",
    );
  }
  return { matches, allowStale: Boolean(allowStale) };
}

/** Fetches the ops stylesheet the stack at `baseUrl` links from its Search page, and hashes the bytes. */
export async function fetchServedStylesheet(baseUrl, { mount = OPS_MOUNT } = {}) {
  const pageUrl = `${baseUrl}${mount}`;
  const page = await fetch(pageUrl, { redirect: "follow" }).catch((error) => {
    throw new Error(`could not read ${pageUrl} to find the served stylesheet: ${error.message}`);
  });
  if (!page.ok) throw new Error(`${pageUrl} returned HTTP ${page.status}; cannot find the served stylesheet`);
  const sheetUrl = new URL(findOpsStylesheetHref(await page.text(), mount), page.url);
  const sheet = await fetch(sheetUrl).catch((error) => {
    throw new Error(`could not read ${sheetUrl}: ${error.message}`);
  });
  if (!sheet.ok) throw new Error(`${sheetUrl} returned HTTP ${sheet.status}; cannot hash the served stylesheet`);
  return { url: `${sheetUrl.pathname}${sheetUrl.search}`, sha256: sha256(Buffer.from(await sheet.arrayBuffer())) };
}

/** The sha256 of the ops stylesheet as committed at HEAD. */
export function headStylesheetSha256() {
  return sha256(gitBytes(["show", `HEAD:${OPS_STYLESHEET_PATH}`]));
}

/**
 * Provenance a manifest states about itself, checked for consistency. A manifest taken before the
 * served-stylesheet check carries none of these fields and is accepted as it stands; a manifest that
 * carries them must not contradict itself: `clean` is not false, the match flag is what its two hashes
 * say, and a mismatch is only present when `allow_stale_source` was recorded.
 */
export function checkProvenance(manifest) {
  const errors = [];
  if (manifest.clean === false) errors.push(`${MANIFEST_NAME} records a dirty tree (clean: false)`);
  const served = manifest.served_css_sha256;
  const head = manifest.head_css_sha256;
  if (served === undefined && head === undefined && manifest.served_css_matches_head === undefined) return errors;
  if (typeof served !== "string" || typeof head !== "string") {
    errors.push(`${MANIFEST_NAME} records a served-stylesheet check without both served_css_sha256 and head_css_sha256`);
    return errors;
  }
  const matches = served === head;
  if (manifest.served_css_matches_head !== matches) {
    errors.push(`${MANIFEST_NAME} says served_css_matches_head is ${String(manifest.served_css_matches_head)}, but its two hashes say ${matches}`);
  }
  if (!matches && manifest.allow_stale_source !== true) {
    errors.push(`${MANIFEST_NAME} records a served stylesheet that differs from HEAD without allow_stale_source`);
  }
  return errors;
}

/**
 * Checks a capture directory: the manifest exists and is ours, every one of the 12 expected PNGs exists
 * and matches the manifest hash, and nothing else sits in the directory. Returns { ok, count, errors }.
 */
export function checkInventory(dir) {
  const errors = [];
  const expected = expectedFiles();
  const manifestPath = path.join(dir, MANIFEST_NAME);
  if (!existsSync(dir)) return { ok: false, count: 0, errors: [`capture directory is missing: ${dir}`] };
  let manifest = null;
  if (!existsSync(manifestPath)) {
    errors.push(`${MANIFEST_NAME} is missing`);
  } else {
    try {
      manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
    } catch (error) {
      errors.push(`${MANIFEST_NAME} is not valid JSON: ${error.message}`);
    }
  }
  if (manifest) {
    if (manifest.schema !== SCHEMA) errors.push(`${MANIFEST_NAME} schema is ${String(manifest.schema)}, expected ${SCHEMA}`);
    if (!Array.isArray(manifest.files)) errors.push(`${MANIFEST_NAME} has no files list`);
    errors.push(...checkProvenance(manifest));
  }
  const listed = new Map((Array.isArray(manifest?.files) ? manifest.files : []).map((entry) => [entry?.name, entry]));
  let count = 0;
  for (const name of expected) {
    const file = path.join(dir, name);
    if (!existsSync(file)) {
      errors.push(`missing capture: ${name}`);
      continue;
    }
    count += 1;
    if (manifest) {
      const entry = listed.get(name);
      if (!entry) errors.push(`${name} is not listed in ${MANIFEST_NAME}`);
      else if (entry.sha256 !== sha256(readFileSync(file))) errors.push(`hash mismatch: ${name} differs from its ${MANIFEST_NAME} entry`);
    }
  }
  if (manifest && Array.isArray(manifest.files)) {
    for (const name of listed.keys()) {
      if (!expected.includes(name)) errors.push(`${MANIFEST_NAME} lists an unexpected file: ${String(name)}`);
    }
  }
  for (const name of readdirSync(dir)) {
    if (name !== MANIFEST_NAME && !expected.includes(name)) errors.push(`unexpected file in the capture directory: ${name}`);
  }
  return { ok: errors.length === 0, count, errors };
}

function git(args) {
  return execFileSync("git", args, { cwd: REPO_ROOT, encoding: "utf8", maxBuffer: 16 * 1024 * 1024 });
}

function gitBytes(args) {
  return execFileSync("git", args, { cwd: REPO_ROOT, encoding: "buffer", maxBuffer: 64 * 1024 * 1024 });
}

export function parseArgs(argv) {
  const args = { label: null, baseUrl: null, out: null, scenario: SCENARIO, check: null, allowStaleSource: false };
  for (let index = 0; index < argv.length; index += 1) {
    const flag = argv[index];
    const take = () => {
      const value = argv[(index += 1)];
      if (value === undefined || value.startsWith("--")) throw new Error(`${flag} needs a value`);
      return value;
    };
    if (flag === "--label") args.label = take();
    else if (flag === "--base-url") args.baseUrl = take().replace(/\/+$/, "");
    else if (flag === "--out") args.out = path.resolve(take());
    else if (flag === "--scenario") args.scenario = take();
    else if (flag === "--check") args.check = path.resolve(take());
    else if (flag === "--allow-stale-source") args.allowStaleSource = true;
    else throw new Error(`unknown argument ${flag}`);
  }
  return args;
}

async function capture({ label, baseUrl, out, allowStaleSource }) {
  if (!["before", "after"].includes(label)) throw new Error("--label must be before or after");
  if (!baseUrl) throw new Error("--base-url is required");
  if (!out) throw new Error("--out is required");

  // One status read serves the refusal and the manifest, so what was checked is what is recorded.
  const statusText = git(["status", "--porcelain"]);
  const tree = assertCleanTree(statusText);
  const sourceSha = git(["rev-parse", "HEAD"]).trim();
  const gitStatus = statusText.split("\n").filter(Boolean);

  // The stack must be rendering HEAD's stylesheet, or the manifest's source_sha labels images that
  // came from different code (the base Compose stack runs a baked image until it is rebuilt).
  const served = await fetchServedStylesheet(baseUrl);
  const headCssSha256 = headStylesheetSha256();
  const stylesheet = assessStylesheet({ servedSha256: served.sha256, headSha256: headCssSha256, allowStale: allowStaleSource });
  if (!stylesheet.matches) console.warn("warning: capturing from a stack whose ops stylesheet differs from HEAD (--allow-stale-source)");

  // Evidence is never overwritten in place: a populated destination is refused, and the tool's own
  // half-written scratch directory is replaced.
  if (existsSync(out) && readdirSync(out).length > 0) {
    throw new Error(`${out} already holds files; captures are never overwritten in place (choose a new --out)`);
  }
  const scratch = `${out}.partial`;
  rmSync(scratch, { recursive: true, force: true });
  mkdirSync(scratch, { recursive: true });

  const { chromium, request } = await import("@playwright/test");
  const browser = await chromium.launch();
  const files = [];
  let seed = null;
  try {
    const api = await request.newContext({ baseURL: baseUrl });
    const seeded = await api.post("/dev/e2e/seed", { data: { scenario: SEED_SCENARIO } });
    if (!seeded.ok()) {
      throw new Error(`seed ${SEED_SCENARIO} failed: HTTP ${seeded.status()} ${await seeded.text()} (is this a MIX_ENV=test stack?)`);
    }
    const seedBody = await seeded.json();
    seed = { scenario: SEED_SCENARIO, failed_count: seedBody.failed_count ?? null };
    await api.dispose();

    for (const theme of THEMES) {
      for (const viewport of VIEWPORTS) {
        const context = await browser.newContext({
          baseURL: baseUrl,
          viewport,
          colorScheme: theme,
          reducedMotion: "reduce",
        });
        // Same mechanism as e2e/helpers/ui-preservation-states.ts setTheme: the stored preference.
        await context.addInitScript((value) => {
          if (location.origin === "null") return;
          localStorage.setItem("phx:theme", value);
        }, theme);
        for (const screen of SCREENS) {
          const page = await context.newPage();
          const pageErrors = [];
          page.on("pageerror", (error) => pageErrors.push(error.message));
          page.setDefaultTimeout(20_000);
          const response = await page.goto(screen.route);
          if (!response?.ok()) throw new Error(`${screen.id} ${theme} ${viewport.width}: navigation returned ${response?.status() ?? "no response"}`);
          await page.waitForFunction(() => Boolean(window.liveSocket?.isConnected?.()) && Boolean(document.querySelector("[data-phx-main].phx-connected")));
          await page.evaluate(() => document.fonts.ready);
          // Client hooks (relative times, copy buttons) settle after the first patch.
          await page.waitForTimeout(400);

          const observed = await page.evaluate(() => ({
            h1: document.querySelector("h1")?.innerText?.trim() ?? null,
            effective: document.documentElement.dataset.themeEffective ?? null,
            preference: document.documentElement.dataset.themePreference ?? null,
            postureRows: document.querySelectorAll("[data-testid='posture-row']").length,
            scenario: document.querySelector("#phase173-fixture-scenario")?.value ?? null,
            pageWidth: document.documentElement.scrollWidth,
            finalPath: `${location.pathname}${location.search}`,
          }));
          if (observed.effective !== theme || observed.preference !== theme) {
            throw new Error(`${screen.id} ${theme} ${viewport.width}: theme did not apply (${JSON.stringify(observed)})`);
          }
          if (screen.id === "search-health" && (observed.scenario !== SCENARIO || observed.postureRows !== 5)) {
            throw new Error(`search-health must show the ${SCENARIO} scenario with 5 rows, got ${JSON.stringify(observed)}`);
          }

          const name = `${screen.id}-${theme}-${viewport.width}.png`;
          const bytes = await page.screenshot({ fullPage: true, animations: "disabled", caret: "hide" });
          writeFileSync(path.join(scratch, name), bytes);
          files.push({
            name,
            sha256: sha256(bytes),
            bytes: bytes.length,
            screen: screen.id,
            theme,
            width: viewport.width,
            height: viewport.height,
            route: screen.route,
            final_path: observed.finalPath,
            h1: observed.h1,
            posture_rows: screen.id === "search-health" ? observed.postureRows : null,
            page_width: observed.pageWidth,
            page_errors: pageErrors,
          });
          console.log(`captured ${name}`);
          await page.close();
        }
        await context.close();
      }
    }
    const chromiumVersion = browser.version();
    const manifest = {
      schema: SCHEMA,
      label,
      source_sha: sourceSha,
      clean: tree.clean,
      git_status: gitStatus,
      served_css_url: served.url,
      served_css_sha256: served.sha256,
      head_css_path: OPS_STYLESHEET_PATH,
      head_css_sha256: headCssSha256,
      served_css_matches_head: stylesheet.matches,
      allow_stale_source: stylesheet.allowStale,
      base_url: baseUrl,
      scenario: SCENARIO,
      seed,
      chromium_version: chromiumVersion,
      captured_at: new Date().toISOString(),
      files,
    };
    writeFileSync(path.join(scratch, MANIFEST_NAME), `${JSON.stringify(manifest, null, 2)}\n`);
  } finally {
    await browser.close();
  }

  if (existsSync(out)) rmSync(out, { recursive: true, force: true }); // empty directory only (checked above)
  renameSync(scratch, out);
  const result = checkInventory(out);
  if (!result.ok) throw new Error(`capture finished but the inventory check failed:\n${result.errors.join("\n")}`);
  console.log(`capture inventory: ${result.count}/${expectedFiles().length}`);
}

async function main(argv) {
  const args = parseArgs(argv);
  if (args.check) {
    const result = checkInventory(args.check);
    if (!result.ok) {
      for (const error of result.errors) console.error(error);
      console.error(`capture inventory: ${result.count}/${expectedFiles().length}`);
      process.exitCode = 1;
      return;
    }
    console.log(`capture inventory: ${result.count}/${expectedFiles().length}`);
    return;
  }
  if (args.scenario !== SCENARIO) throw new Error(`--scenario must be ${SCENARIO}`);
  await capture(args);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main(process.argv.slice(2)).catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}
