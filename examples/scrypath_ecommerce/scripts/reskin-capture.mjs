#!/usr/bin/env node
// ScrypathOps re-skin capture (Phase 187, SKIN-08).
//
// Captures three screens (Control room, Search health with the `all-statuses` fixture scenario, Failed
// sync work) in light and dark at 1280 and 390 px: 12 full-page PNGs plus a manifest that names the
// source commit, so a before set and an after set can be compared by someone looking at them. Nothing
// here is a gate: the captures are review context, not a baseline, and no image is compared by pixel.
//
//   node scripts/reskin-capture.mjs --label before --base-url http://127.0.0.1:4102 --out DIR
//   node scripts/reskin-capture.mjs --check DIR
//
// The stack must be a MIX_ENV=test build: the `all-statuses` Search health scenario is a test-only
// fixture route and the seed endpoint (`/dev/e2e/seed`) exists only there.
//
// "No capture from a dirty tree" means: refuse to run when `git status --porcelain
// --untracked-files=no` lists a tracked change outside `.planning/` (those can change what renders;
// `.planning/` edits cannot). The complete `git status --porcelain` output is recorded in the manifest
// as `git_status`, so every remaining difference stays visible.
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
 * Throws when a status lists a tracked change outside `.planning/`. Untracked (`??`) and ignored (`!!`)
 * entries never affect rendering decisions here and are only recorded, never refused.
 */
export function assertCleanTree(statusText) {
  const offending = [];
  for (const line of String(statusText).split("\n")) {
    if (line.trim() === "") continue;
    const code = line.slice(0, 2);
    if (code === "??" || code === "!!") continue;
    const rest = line.slice(3).trim();
    // A rename reads `old -> new`; both sides count.
    for (const raw of rest.split(" -> ")) {
      const file = raw.replace(/^"(.*)"$/, "$1");
      if (!file.startsWith(".planning/")) offending.push(file);
    }
  }
  if (offending.length > 0) {
    throw new Error(
      `refusing to capture from a dirty tree: tracked changes outside .planning/: ${offending.join(", ")}. ` +
        "Commit them first so the manifest names the source that rendered the images.",
    );
  }
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

function parseArgs(argv) {
  const args = { label: null, baseUrl: null, out: null, scenario: SCENARIO, check: null };
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
    else throw new Error(`unknown argument ${flag}`);
  }
  return args;
}

async function capture({ label, baseUrl, out }) {
  if (!["before", "after"].includes(label)) throw new Error("--label must be before or after");
  if (!baseUrl) throw new Error("--base-url is required");
  if (!out) throw new Error("--out is required");

  assertCleanTree(git(["status", "--porcelain", "--untracked-files=no"]));
  const sourceSha = git(["rev-parse", "HEAD"]).trim();
  const gitStatus = git(["status", "--porcelain"]).split("\n").filter(Boolean);

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
      clean: true,
      git_status: gitStatus,
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
