#!/usr/bin/env node
// Observe the running UI without seeding, recovery actions, or a paid model call.
import { createHash } from "node:crypto";
import { spawnSync } from "node:child_process";
import { lstat, mkdir, readFile, readlink, realpath, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const demoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
export const reviewArtifactRoot = path.join(demoRoot, "ui-review-artifacts");
const repoRoot = path.resolve(demoRoot, "../..");
const MAX_GIT_OUTPUT_BYTES = 32 * 1024 * 1024;
const MAX_SOURCE_FILE_BYTES = 64 * 1024 * 1024;
const MAX_SOURCE_BYTES = 1024 * 1024 * 1024;
export const surfaces = [
  { id: "storefront", route: "/", role: "ROLE-INT", jobs: ["JOB-01", "JOB-02"], purpose: "Verify tenant-scoped search and facets; reach operator help when search fails." },
  { id: "control-room", route: "/admin/search/", role: "ROLE-OPS", jobs: ["JOB-03"], purpose: "Understand the current observation and choose the next safe task." },
  { id: "search-health", route: "/admin/search/health", role: "ROLE-OPS", jobs: ["JOB-03"], purpose: "Identify the affected schema and distinguish backend from queue evidence." },
  { id: "failed-sync", route: "/admin/search/failed-sync", role: "ROLE-OPS", jobs: ["JOB-03"], purpose: "Inspect exact failed work and determine whether recovery is eligible." },
  { id: "sync-drift", route: "/admin/search/sync-and-index", role: "ROLE-OWNER", jobs: ["JOB-04"], purpose: "Separate index settings, document visibility, recovery, and promotion evidence." },
  { id: "search", route: "/admin/search/search", role: "ROLE-OWNER", jobs: ["JOB-05"], purpose: "Choose explicit targets, run a bounded query, and interpret attributed results." },
  { id: "saved-searches", route: "/admin/search/search?saved=manage", role: "ROLE-OWNER", jobs: ["JOB-05"], purpose: "Find, load, rename, delete, import and export saved searches from Search, and tell a loaded saved search from edited inputs." },
  { id: "help", route: "/admin/search/help", role: "ROLE-INT", jobs: ["JOB-03", "JOB-05"], purpose: "Understand search, sync and saved inputs without leaving the installed interface." }
];
export const dimensions = [
  "task-flow", "information-hierarchy", "language-and-domain-truth", "visual-composition",
  "interaction-and-accessibility", "responsive-behavior", "cross-screen-consistency", "unreported-problems"
];
export const themes = ["light", "dark", "system-dark"];
export const viewports = [{ width: 1440, height: 900 }, { width: 768, height: 900 }, { width: 390, height: 844 }];
export const standaloneRoutes = {
  "control-room": "/ops/",
  "search-health": "/ops/health",
  "failed-sync": "/ops/failed-sync",
  "sync-drift": "/ops/sync-and-index",
  search: "/ops/search",
  "saved-searches": "/ops/search?saved=manage",
  help: "/ops/help"
};
const sha256 = (bytes) => createHash("sha256").update(bytes).digest("hex");

export function disposableClockErrors(clock) {
  if (!clock || typeof clock.utc !== "string" || !/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z$/.test(clock.utc) || !Number.isFinite(Date.parse(clock.utc)) || new Date(clock.utc).toISOString() !== clock.utc) return ["Disposable observation clock must be a canonical UTC timestamp."];
  if (clock.sha256 !== sha256(Buffer.from(`${clock.utc}\n`)) || clock.timezone !== "UTC" || clock.locale !== "en-US" || clock.browser_mode !== "fixed-date") return ["Disposable clock digest, timezone, locale or browser mode is invalid."];
  return [];
}
const escapeHtml = (value) => String(value).replace(/[&<>"']/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[char]);

export function cleanGitEnvironment(environment = process.env) {
  return {
    ...Object.fromEntries(Object.entries(environment).filter(([key]) => !/^GIT_/i.test(key))),
    GIT_CONFIG_NOSYSTEM: "1",
    GIT_CONFIG_GLOBAL: process.platform === "win32" ? "NUL" : "/dev/null"
  };
}

export function isCanonicalOrigin(origin) {
  return new Set([
    "https://github.com/szTheory/scrypath", "https://github.com/szTheory/scrypath.git",
    "ssh://git@github.com/szTheory/scrypath", "ssh://git@github.com/szTheory/scrypath.git",
    "git@github.com:szTheory/scrypath", "git@github.com:szTheory/scrypath.git"
  ]).has(String(origin).trim());
}

function runGit(args, { timeout = 30_000, maxBuffer = MAX_GIT_OUTPUT_BYTES } = {}) {
  const result = spawnSync("git", args, { cwd: repoRoot, env: cleanGitEnvironment(), encoding: "utf8", timeout, maxBuffer });
  if (result.error) throw new Error(`git ${args[0]} failed: ${result.error.message}`);
  if (result.status !== 0) throw new Error(`git ${args.join(" ")} exited ${result.status}: ${(result.stderr || result.stdout || "").trim()}`);
  return result.stdout;
}

function runDocker(args, { timeout = 30_000, maxBuffer = 4 * 1024 * 1024 } = {}) {
  const result = spawnSync("docker", args, { cwd: repoRoot, env: process.env, encoding: "utf8", timeout, maxBuffer });
  if (result.error) throw new Error(`docker ${args[0]} failed: ${result.error.message}`);
  if (result.status !== 0) throw new Error(`docker ${args.join(" ")} exited ${result.status}: ${(result.stderr || result.stdout || "").trim()}`);
  return result.stdout;
}

export async function sourceIdentity() {
  const origin = runGit(["remote", "get-url", "origin"]).trim();
  if (!isCanonicalOrigin(origin)) throw new Error(`Refusing source identity from non-canonical origin: ${origin}`);
  const paths = ["AGENTS.md", "PRODUCT.md", "DESIGN.md", ".planning/reference/OPERATOR-UI-QUALITY.md", "scrypath_ops/lib", "scrypath_ops/assets", "scrypath_ops/priv/static", "scrypath_ops/docs", "examples/scrypath_ecommerce/lib", "examples/scrypath_ecommerce/assets", "examples/scrypath_ecommerce/priv/static", "examples/scrypath_ecommerce/e2e", "examples/scrypath_ecommerce/package.json"];
  const files = [...new Set(runGit(["ls-files", "-z", "--cached", "--others", "--exclude-standard", "--", ...paths]).split("\0").filter(Boolean))].sort();
  const hash = createHash("sha256");
  let totalBytes = 0;
  for (const file of files) {
    let bytes;
    try {
      const absolute = path.join(repoRoot, file);
      const details = await lstat(absolute);
      if (!details.isFile() && !details.isSymbolicLink()) throw new Error(`Source entry is not a regular file: ${file}`);
      if (details.size > MAX_SOURCE_FILE_BYTES) throw new Error(`Source entry exceeds its finite identity bound: ${file}`);
      bytes = details.isSymbolicLink() ? Buffer.from(await readlink(absolute)) : await readFile(absolute);
    }
    catch (error) { if (error.code !== "ENOENT") throw error; bytes = Buffer.from("<deleted>"); }
    totalBytes += bytes.length;
    if (totalBytes > MAX_SOURCE_BYTES) throw new Error("Source fingerprint exceeds its finite total byte bound.");
    hash.update(`${file}\0${bytes.length}\0`).update(bytes);
  }
  return { head: runGit(["rev-parse", "HEAD"]).trim(), tree_sha256: hash.digest("hex") };
}

export function previewSourceErrors(expected, mounted, mainIncluded, endpointMatches = true, mainCurrent = true) {
  const errors = [];
  if (expected !== mounted) errors.push(`Preview source mismatch: ${mounted}; expected ${expected}.`);
  if (!mainIncluded) errors.push("Checkout does not include origin/main. Reconcile newer merged work before reviewing the current UI.");
  if (!endpointMatches) errors.push("Review URL does not match the verified preview container's published loopback port.");
  if (!mainCurrent) errors.push("origin/main is stale against the remote main ref. Refresh and reconcile main before treating this preview as latest.");
  return errors;
}

export function entryFixtureErrors(deployment, surface, text) {
  const requirements = {
    "host:control-room": ["3 sync jobs failed"],
    "host:failed-sync": ["3 failed, 2 retrying", "Invalid data", "Meilisearch rejected it", "Unknown cause"],
    "standalone:control-room": ["No search schemas configured.", "Configure the host application's schema allowlist"],
    "standalone:failed-sync": ["No schemas configured.", "schema_allowlist in :scrypath_ops"],
  }[`${deployment}:${surface}`] || [];
  return requirements.filter((fragment) => !String(text || "").includes(fragment)).map((fragment) => `${deployment} ${surface} entry fixture is missing expected text: ${fragment}`);
}

async function verifyPreviewSource() {
  const container = process.env.UI_REVIEW_CONTAINER || "scrypath_ecommerce-web-1";
  const runtime = JSON.parse(runDocker(["inspect", container, "--format", '{"mounts":{{json .Mounts}},"ports":{{json .NetworkSettings.Ports}}}']));
  const source = runtime.mounts.find((mount) => mount.Type === "bind" && mount.Destination === "/app")?.Source;
  if (!source) throw new Error(`${container} has no source bind mount at /app; runtime source is unverified.`);
  const mounted = await realpath(source.replace(/^\/host_mnt(?=\/)/, ""));
  const expected = await realpath(repoRoot);
  const mainIncluded = runGit(["merge-base", "refs/remotes/origin/main", "HEAD"]).trim() === runGit(["rev-parse", "refs/remotes/origin/main"]).trim();
  const url = new URL(process.env.PLAYWRIGHT_BASE_URL || "http://127.0.0.1:4002");
  const endpointMatches = ["127.0.0.1", "localhost", "[::1]"].includes(url.hostname) && Object.values(runtime.ports).flatMap((ports) => ports || []).some((binding) => binding.HostPort === (url.port || "80") && ["127.0.0.1", "::1"].includes(binding.HostIp));
  const errors = previewSourceErrors(expected, mounted, mainIncluded, endpointMatches);
  if (errors.length) throw new Error(errors.join("\n"));
  return { container, source_match: true, mount: mounted, main_included: true, main_ref: runGit(["rev-parse", "refs/remotes/origin/main"]).trim() };
}

export function reviewTemplate(manifest, digest) {
  const row = (id) => ({ id, verdict: "pending", evidence: [], rationale: "" });
  return {
    schema: "scrypath.ui-review.v1", capture_sha256: digest, status: "pending",
    surfaces: surfaces.map(({ id }) => row(id)), dimensions: dimensions.map(row),
    coverage: { verdict: "pending", evidence: [], rationale: "Entry states only. Cite isolated journey/state proofs or record gaps; never relabel entry screenshots as a completed journey." },
    findings: [],
    source: manifest.source
  };
}

// This validates review completeness/provenance, not aesthetic quality or a reviewer identity.
export function reviewErrors(review, manifest, digest, currentSource) {
  const errors = [];
  if (review.schema !== "scrypath.ui-review.v1" || review.status !== "reviewed") errors.push("Review is pending or has the wrong schema.");
  if (review.capture_sha256 !== digest) errors.push("Review refers to a different capture manifest.");
  if (manifest.source.tree_sha256 !== currentSource.tree_sha256) errors.push("Source changed after capture; recapture affected evidence.");
  if (manifest.captures.length !== surfaces.length * themes.length * viewports.length || manifest.captures.some((capture) => capture.error)) errors.push("Capture matrix is incomplete.");
  if (manifest.source_changed_during_capture) errors.push("Source changed during capture.");
  if (!manifest.runtime?.source_match || !manifest.runtime?.main_included) errors.push("Preview checkout or merged-main provenance is unverified.");
  if (manifest.captures.some((capture) => capture.checks?.length)) errors.push("Mechanical findings remain in the capture; fix and recapture.");
  if (manifest.captures.some((capture) => ["viewport.png", "full.png", "copy.json"].some((key) => !capture.files?.[key]))) errors.push("A required screenshot or copy artifact is missing.");
  const expectedIds = new Set(surfaces.flatMap((surface) => themes.flatMap((theme) => viewports.map(({ width }) => `${surface.id}--${theme}--${width}`))));
  const ids = new Set(manifest.captures.map(({ id }) => id));
  if ([...expectedIds].some((id) => !ids.has(id))) errors.push("A required screen/theme/width is missing.");
  const checkRow = (row, label) => {
    if (!["acceptable", "needs-work"].includes(row?.verdict) || !row?.rationale?.trim() || !row?.evidence?.length) errors.push(`${label}: missing verdict, rationale, or evidence.`);
    if (row?.verdict === "needs-work") errors.push(`${label}: needs work.`);
    if (row?.evidence?.some((id) => !ids.has(id))) errors.push(`${label}: unknown capture evidence.`);
  };
  for (const surface of surfaces) {
    const row = review.surfaces?.find(({ id }) => id === surface.id);
    checkRow(row, surface.id);
    if (manifest.captures.filter((capture) => capture.surface === surface.id).some(({ id }) => !row?.evidence?.includes(id))) errors.push(`${surface.id}: not every theme/width was reviewed.`);
  }
  for (const dimension of dimensions) checkRow(review.dimensions?.find(({ id }) => id === dimension), dimension);
  if (review.coverage?.verdict !== "supported" || !review.coverage?.rationale?.trim() || !review.coverage?.evidence?.length) errors.push("Journey/state coverage is missing or incomplete.");
  if (review.findings?.some((finding) => !["resolved", "advisory"].includes(finding.disposition) || !finding.evidence?.length || !finding.rationale?.trim())) errors.push("An open or undocumented finding remains.");
  return errors;
}

const STABLE_CAPTURE_MAX_SAMPLES = 6;
const STABLE_CAPTURE_MAX_ELAPSED_MS = 10_000;
const CAPTURE_STATE_SCHEMA = "scrypath.ui-capture-state.v1";

function withTimeout(promise, timeoutMs, label) {
  if (!Number.isFinite(timeoutMs) || timeoutMs <= 0) return Promise.reject(new Error(`${label} exceeded its time budget.`));
  let timer;
  const timeout = new Promise((_, reject) => {
    timer = setTimeout(() => reject(new Error(`${label} exceeded its ${Math.ceil(timeoutMs)}ms time budget.`)), timeoutMs);
  });
  return Promise.race([Promise.resolve(promise), timeout]).finally(() => clearTimeout(timer));
}

function remainingMilliseconds(deadline, now, label) {
  const remaining = deadline - now();
  if (remaining <= 0) throw new Error(`${label} exceeded its total capture deadline.`);
  return Math.max(1, Math.ceil(remaining));
}

const DISPOSABLE_BROWSER_FONT_PROFILE = Object.freeze({
  method: "retained-cdp-fixed-font-v1",
  font_families: Object.freeze({ fixed: "Liberation Mono" }),
  applied: "before-first-navigation",
  lifetime: "page-context"
});
const DISPOSABLE_FONT_PROFILE_SETUP_MS = 10_000;

export async function configureDisposableFontProfile(context, page) {
  if (!context || typeof context.newCDPSession !== "function" || !page) throw new TypeError("Disposable font profile requires a BrowserContext and page.");
  const deadline = performance.now() + DISPOSABLE_FONT_PROFILE_SETUP_MS;
  const withinBudget = async (label, operation) => {
    const timeout = deadline - performance.now();
    if (timeout <= 0) throw new Error(`${label} exceeded its total font profile setup deadline.`);
    return withTimeout(operation(), timeout, label);
  };
  const session = await withinBudget("Disposable font CDP session creation", () => context.newCDPSession(page));
  if (!session || typeof session.send !== "function") throw new TypeError("Disposable font CDP session does not support commands.");
  await withinBudget("Disposable Page.enable", () => session.send("Page.enable"));
  await withinBudget("Disposable Page.setFontFamilies", () => session.send("Page.setFontFamilies", { fontFamilies: { ...DISPOSABLE_BROWSER_FONT_PROFILE.font_families } }));
  return { profile: DISPOSABLE_BROWSER_FONT_PROFILE, session };
}

export async function captureViewportImage(page, viewport, { timeout = STABLE_CAPTURE_MAX_ELAPSED_MS } = {}) {
  if (!Number.isSafeInteger(viewport?.width) || !Number.isSafeInteger(viewport?.height) || viewport.width <= 0 || viewport.height <= 0 || viewport.width * viewport.height > 24_000_000) throw new Error("Viewport capture dimensions must be positive bounded integers.");
  if (!Number.isFinite(timeout) || timeout <= 0) throw new Error("Viewport capture timeout must be a positive finite number.");
  const deadline = performance.now() + timeout;
  const boundedEvaluate = (evaluate, label) => withTimeout(evaluate(), remainingMilliseconds(deadline, () => performance.now(), label), label);
  const geometry = () => page.evaluate(() => ({
    width: window.innerWidth, height: window.innerHeight,
    dpr: window.devicePixelRatio, scale: window.visualViewport?.scale ?? 1,
    scrollX: window.scrollX, scrollY: window.scrollY,
    documentWidth: document.documentElement.scrollWidth,
    documentHeight: document.documentElement.scrollHeight
  }));
  await boundedEvaluate(() => page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)))), "Viewport frame settlement");
  const before = await boundedEvaluate(geometry, "Viewport geometry read");
  if (before.width !== viewport.width || before.height !== viewport.height || before.dpr !== 1 || before.scale !== 1 || before.scrollX !== 0 || before.scrollY !== 0) throw new Error("Viewport capture requires the exact unzoomed viewport at scroll origin.");
  // Keep Playwright's animation/caret preparation, using Chromium's document
  // capture route with an exact viewport clip. No viewport resize or pixel edit.
  const screenshotTimeout = remainingMilliseconds(deadline, () => performance.now(), "Viewport screenshot");
  const image = await withTimeout(page.screenshot({ animations: "disabled", fullPage: true, clip: { x: 0, y: 0, width: viewport.width, height: viewport.height }, timeout: screenshotTimeout }), screenshotTimeout, "Viewport screenshot");
  const after = await boundedEvaluate(geometry, "Viewport geometry read");
  if (JSON.stringify(after) !== JSON.stringify(before)) throw new Error(`Viewport capture changed the actual viewport or document layout: ${JSON.stringify({ before, after })}`);
  return image;
}

export function captureUiStateInPage(target) {
  const rect = (node) => {
    if (!node || typeof node.getBoundingClientRect !== "function") return null;
    const bounds = node.getBoundingClientRect();
    return { x: bounds.x, y: bounds.y, width: bounds.width, height: bounds.height };
  };
  const visible = (node) => node.getClientRects().length > 0 && getComputedStyle(node).visibility !== "hidden";
  const boolAttribute = (value) => value === "true" ? true : value === "false" ? false : null;
  const semanticName = (node) => {
    const labelledBy = (node.getAttribute("aria-labelledby") || "").split(/\s+/).filter(Boolean)
      .map((id) => document.getElementById(id)?.innerText || "").filter(Boolean).join(" ");
    const labels = node.labels ? [...node.labels].map((label) => label.innerText || "").filter(Boolean).join(" ") : "";
    return (node.getAttribute("aria-label") || labelledBy || labels || node.getAttribute("title") || node.innerText || node.getAttribute("placeholder") || "").trim();
  };
  const semanticElement = (node) => node ? {
    tag: node.tagName.toLowerCase(),
    role: node.getAttribute("role") || (node.tagName === "A" ? "link" : node.tagName === "BUTTON" ? "button" : node.tagName.toLowerCase()),
    name: semanticName(node),
    href: node.getAttribute("href")
  } : null;
  if (target != null) return semanticElement(target);
  const layoutAnchor = (selectors) => {
    const node = selectors.map((selector) => document.querySelector(selector)).find(Boolean);
    if (!node) return null;
    const style = getComputedStyle(node);
    return {
      rect: rect(node),
      position: style.position,
      display: style.display,
      inset: { top: style.top, right: style.right, bottom: style.bottom, left: style.left },
      margin: { top: style.marginTop, right: style.marginRight, bottom: style.marginBottom, left: style.marginLeft }
    };
  };
  const doc = document.documentElement;
  const active = document.activeElement instanceof Element ? document.activeElement : null;
  const focusStyle = active ? getComputedStyle(active) : null;
  const hovered = new Set(document.querySelectorAll(":hover"));
  const controlNodes = [...document.querySelectorAll("a,button,input,select,textarea,[role='button'],[role='link'],[role='checkbox'],[role='radio'],[role='option'],[role='tab'],[role='menuitem']")].filter((node) => {
    const bounds = rect(node);
    return visible(node) && bounds.width > 0 && bounds.height > 0;
  });
  const hoverNodes = controlNodes.filter((node) => hovered.has(node));
  const controls = controlNodes.map((node) => {
      const selectedAttribute = node.getAttribute("data-theme-selected") ?? node.getAttribute("aria-selected");
      const selected = boolAttribute(selectedAttribute) ?? (node.tagName === "OPTION" ? node.selected === true : null);
      const checked = (node.type === "checkbox" || node.type === "radio") ? node.checked === true : node.getAttribute("aria-checked");
      const value = "value" in node ? (node.multiple && node.tagName === "SELECT" ? [...node.selectedOptions].map((option) => option.value) : node.value) : null;
      return {
        ...semanticElement(node),
        value,
        checked,
        selected,
        disabled: node.disabled === true || node.getAttribute("aria-disabled") === "true",
        expanded: boolAttribute(node.getAttribute("aria-expanded")),
        pressed: node.getAttribute("aria-pressed"),
        rect: rect(node)
      };
    });
  const theme = doc?.dataset || {};
  return {
    schema: "scrypath.ui-capture-state.v1",
    body_text: document.body?.innerText ?? "",
    controls,
    focus: {
      element: semanticElement(active),
      rect: rect(active),
      focus_visible: Boolean(active?.matches(":focus-visible")),
      outline: focusStyle ? { style: focusStyle.outlineStyle, width: focusStyle.outlineWidth, color: focusStyle.outlineColor } : null,
      opacity: focusStyle?.opacity ?? null
    },
    hover: hoverNodes.map((node) => ({ element: semanticElement(node), rect: rect(node) })),
    document_has_focus: document.hasFocus(),
    layout: {
      shell: layoutAnchor([".ops-shell-frame", "body"]),
      shell_content: layoutAnchor([".ops-shell-content", "main", "body"]),
      header: layoutAnchor([".ops-header", "header"]),
      header_inner: layoutAnchor([".ops-header__inner", ".ops-header > div", "header > div", "header"]),
      main: layoutAnchor(["#ops-main", "main", "body"]),
      main_inner: layoutAnchor(["#ops-main > div", "main > div", "main", "body"]),
      primary_article: layoutAnchor([".ops-help-content", "main article", "main", "body"])
    },
    viewport: {
      inner: { width: window.innerWidth, height: window.innerHeight },
      client: { width: doc?.clientWidth ?? 0, height: doc?.clientHeight ?? 0 },
      document: { width: doc?.scrollWidth ?? 0, height: doc?.scrollHeight ?? 0 },
      scroll: { x: window.scrollX, y: window.scrollY },
      dpr: window.devicePixelRatio,
      scale: window.visualViewport?.scale ?? 1
    },
    theme: {
      preference: theme.themePreference ?? null,
      effective: theme.themeEffective ?? null,
      data_theme: doc?.getAttribute("data-theme") ?? null,
      system_dark: window.matchMedia("(prefers-color-scheme: dark)").matches
    }
  };
}

function sampleStateDocument(before, after) {
  const root = after || before;
  return { ...root, before: before || null, after: after || null };
}

function attachCaptureStability(error, stability) {
  if (error && typeof error === "object") error.captureStability = stability;
  return error;
}

async function readPageCaptureState(page, timeoutMs) {
  return withTimeout(page.evaluate(captureUiStateInPage), timeoutMs, "Capture state read");
}

async function waitForTwoFrames(page, timeoutMs) {
  return withTimeout(page.evaluate(() => new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)))), timeoutMs, "Capture frame settlement");
}

export async function prepareCaptureStateInPage() {
  const finiteActiveAnimations = () => document.getAnimations().filter((animation) => {
    const timing = animation.effect?.getComputedTiming?.();
    const active = animation.pending === true || animation.playState === "pending" || animation.playState === "running";
    return active && Number.isFinite(timing?.endTime);
  });
  const settleFrames = () => new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)));
  const maxPasses = 12;

  for (let pass = 0; pass < maxPasses; pass += 1) {
    const active = finiteActiveAnimations();
    if (active.length) await Promise.all(active.map((animation) => animation.finished));
    await document.fonts.ready;
    await settleFrames();
    if (document.fonts.status !== "loading" && finiteActiveAnimations().length === 0) return;
  }
  throw new Error("Entry-state preparation did not reach a stationary font and finite-animation state.");
}

async function preparePageCaptureState(page, timeoutMs) {
  return page.evaluate(prepareCaptureStateInPage, timeoutMs);
}

export async function captureStableImage({
  page,
  id,
  kind,
  captureImage,
  saveSample,
  prepareState = preparePageCaptureState,
  readState = readPageCaptureState,
  waitForFrames = waitForTwoFrames,
  now = () => performance.now(),
  maxSamples = STABLE_CAPTURE_MAX_SAMPLES,
  maxElapsedMs = STABLE_CAPTURE_MAX_ELAPSED_MS
}) {
  if (!page || typeof captureImage !== "function" || typeof saveSample !== "function" || typeof prepareState !== "function" || typeof id !== "string" || !/^[a-z0-9-]+$/i.test(id) || typeof kind !== "string") throw new TypeError("Stable capture requires a page, safe id, kind, image callback, sample saver, and state preparer.");
  if (!Number.isSafeInteger(maxSamples) || maxSamples < 2 || maxSamples > STABLE_CAPTURE_MAX_SAMPLES || !Number.isFinite(maxElapsedMs) || maxElapsedMs <= 0 || maxElapsedMs > STABLE_CAPTURE_MAX_ELAPSED_MS) throw new TypeError("Stable capture bounds must allow at least two samples and stay within the configured sample and time caps.");
  const kindName = kind.replace(/\.png$/i, "");
  if (!/^[a-z0-9-]+$/i.test(kindName)) throw new TypeError("Stable capture kind must be a safe image name.");
  const started = now();
  const deadline = started + maxElapsedMs;
  const elapsed = () => Math.max(0, now() - started);
  const remaining = (phase) => remainingMilliseconds(deadline, now, phase);
  const stability = { method: "consecutive-exact-v1", max_samples: maxSamples, max_elapsed_ms: maxElapsedMs, samples: [], selected: null };
  let firstStateJson = null;
  let priorImage = null;
  let priorStateJson = null;

  const persistSample = async (sampleData, phase = "Capture sample persistence") => {
    const timeout = remaining(phase);
    await withTimeout(saveSample({ ...sampleData, timeout }), timeout, phase);
    return Number(elapsed().toFixed(3));
  };
  const writeFailureState = async (index, before, phase, error, imageBytes = null) => {
    const imagePath = `${id}--${kindName}-sample-${index}.png`;
    const statePath = `${id}--${kindName}-sample-${index}.json`;
    const stateBytes = Buffer.from(`${JSON.stringify(sampleStateDocument(before, null), null, 2)}\n`);
    const failedAttempt = {
      path: imagePath,
      bytes: imageBytes,
      state_path: statePath,
      state_bytes: stateBytes,
      elapsed_ms: Number(elapsed().toFixed(3))
    };
    const failedAttemptProof = {
      path: imageBytes ? imagePath : null,
      sha256: imageBytes ? sha256(imageBytes) : null,
      state_path: statePath,
      state_sha256: sha256(stateBytes),
      elapsed_ms: null,
      phase,
      error: error instanceof Error ? error.message : String(error)
    };
    let evidenceSaved = false;
    try {
      failedAttemptProof.elapsed_ms = await persistSample(failedAttempt, "Failed-attempt evidence persistence");
      stability.failed_attempt = failedAttemptProof;
      evidenceSaved = true;
      remaining("Failed-attempt evidence persistence");
    } catch (persistenceError) {
      if (!evidenceSaved) {
        stability.persistence_error = persistenceError instanceof Error ? persistenceError.message : String(persistenceError);
        if (error && typeof error === "object") error.capturePersistenceError = persistenceError;
      } else if (error && typeof error === "object") {
        error.capturePersistenceError = persistenceError;
      }
    }
    throw attachCaptureStability(error, stability);
  };

  try {
    const prepareTimeout = remaining("Capture entry-state preparation");
    await withTimeout(prepareState(page, prepareTimeout), prepareTimeout, "Capture entry-state preparation");
    remaining("Capture entry-state preparation");

    for (let index = 0; index < maxSamples; index += 1) {
      const frameTimeout = remaining("Capture frame settlement");
      await withTimeout(waitForFrames(page, frameTimeout), frameTimeout, "Capture frame settlement");
      const stateTimeout = remaining("Capture state read");
      const before = await withTimeout(readState(page, stateTimeout), stateTimeout, "Capture state read");
      if (!before || before.schema !== CAPTURE_STATE_SCHEMA) throw new Error("Capture state reader returned an invalid state schema.");
      const beforeJson = JSON.stringify(before);
      if (firstStateJson === null) {
        firstStateJson = beforeJson;
      }

      const samplePath = `${id}--${kindName}-sample-${index}.png`;
      const statePath = `${id}--${kindName}-sample-${index}.json`;
      let image;
      try {
        const timeout = remaining("Capture screenshot");
        image = await withTimeout(captureImage({ timeout }), timeout, "Capture screenshot");
      } catch (error) {
        await writeFailureState(index, before, "screenshot", error);
      }
      if (!Buffer.isBuffer(image)) {
        await writeFailureState(index, before, "screenshot-result", new TypeError("Capture image callback must return PNG bytes."));
      }

      let after;
      try {
        const stateTimeout = remaining("Capture state read");
        after = await withTimeout(readState(page, stateTimeout), stateTimeout, "Capture state read");
      } catch (error) {
        await writeFailureState(index, before, "state-after", error, image);
      }
      if (!after || after.schema !== CAPTURE_STATE_SCHEMA) {
        await writeFailureState(index, before, "state-after-schema", new Error("Capture state reader returned an invalid after-state."), image);
      }
      const afterJson = JSON.stringify(after);
      const stateBytes = Buffer.from(`${JSON.stringify(sampleStateDocument(before, after), null, 2)}\n`);
      const sample = {
        path: samplePath,
        sha256: sha256(image),
        state_path: statePath,
        state_sha256: sha256(stateBytes)
      };
      sample.elapsed_ms = await persistSample({ path: samplePath, bytes: image, state_path: statePath, state_bytes: stateBytes }, "Capture sample persistence");
      stability.samples.push(sample);
      remaining("Capture sample persistence");

      const changedWithinSample = beforeJson !== afterJson;
      const changedAcrossSamples = beforeJson !== firstStateJson;
      if (changedWithinSample || changedAcrossSamples) {
        const reason = changedWithinSample ? "state changed around the screenshot" : "state changed across samples";
        throw attachCaptureStability(new Error(`Stable ${kindName} capture ${reason} at sample ${index}.`), stability);
      }

      const sameAsPrevious = priorImage !== null && priorImage.equals(image) && priorStateJson === afterJson;
      if (sameAsPrevious) {
        remaining("Stable screenshot capture");
        stability.selected = index;
        return { image, stability };
      }
      priorImage = image;
      priorStateJson = afterJson;
      remaining("Stable screenshot capture");
    }
    throw attachCaptureStability(new Error(`Stable ${kindName} capture did not produce two consecutive byte-equal images within ${maxSamples} samples.`), stability);
  } catch (error) {
    throw attachCaptureStability(error, stability);
  }
}

export async function captureSurface(browser, surface, theme, viewport, output, options = {}) {
  const deployment = options.deployment;
  const id = `${deployment ? `${deployment}--` : ""}${surface.id}--${theme}--${viewport.width}`;
  const capture = { id, surface: surface.id, theme, viewport, width: viewport.width, deployment, route: surface.route, checks: [], files: {}, interaction_target: null };
  if (options.clock) capture.clock = options.clock;
  let context = null;
  let fontProfileSetup = null;
  const pageErrors = [];
  try {
    context = await browser.newContext({ baseURL: options.baseURL || process.env.PLAYWRIGHT_BASE_URL || "http://127.0.0.1:4002", viewport, colorScheme: theme === "light" ? "light" : "dark", reducedMotion: "reduce", ...(options.clock ? { timezoneId: options.clock.timezone, locale: options.clock.locale } : {}) });
    await context.addInitScript((preference) => {
      if (location.origin === "null") return;
      if (preference === "system-dark") localStorage.removeItem("phx:theme");
      else localStorage.setItem("phx:theme", preference);
    }, theme);
    const page = await context.newPage();
    if (deployment) {
      fontProfileSetup = await configureDisposableFontProfile(context, page);
      capture.browser_font_profile = fontProfileSetup.profile;
    }
    if (options.clock) await page.clock.setFixedTime(new Date(options.clock.utc));
    page.setDefaultTimeout(10_000);
    page.on("pageerror", (error) => pageErrors.push(error.message));
    const response = await page.goto(surface.route);
    if (!response?.ok()) throw new Error(`Navigation returned ${response?.status() ?? "no response"}`);
    await page.waitForFunction(() => Boolean(window.liveSocket?.isConnected?.()) && Boolean(document.querySelector("[data-phx-main].phx-connected")));
    await page.evaluate(() => document.fonts.ready);
    const evidence = await page.evaluate(({ deployment, surface, theme }) => {
      const visible = (node) => node.getClientRects().length > 0 && getComputedStyle(node).visibility !== "hidden";
      const nodes = (selector) => [...document.querySelectorAll(selector)].filter(visible);
      return {
        deployment, surface, route: `${location.pathname}${location.search}`,
        text: document.body.innerText,
        headings: nodes("h1,h2,h3,h4").map((node) => ({ level: node.tagName, text: node.innerText })),
        controls: nodes("a,button,input,select,textarea").map((node) => ({ tag: node.tagName, text: node.innerText || node.getAttribute("aria-label") || node.getAttribute("placeholder"), href: node.getAttribute("href"), disabled: node.disabled === true })),
        page_width: document.documentElement.scrollWidth, viewport_width: window.innerWidth,
        theme: { requested: theme, preference: document.documentElement.dataset.themePreference, effective: document.documentElement.dataset.themeEffective, selected: nodes("[data-phx-theme][aria-pressed='true']").map((node) => node.dataset.phxTheme) }
      };
    }, { deployment, surface: surface.id, theme });
    if (options.clock) {
      evidence.clock = options.clock;
      evidence.observed_at = await page.evaluate(() => new Date().toISOString());
      if (evidence.observed_at !== options.clock.utc) throw new Error("Browser observation clock did not apply.");
    }
    const fixtureErrors = deployment ? entryFixtureErrors(deployment, surface.id, evidence.text) : [];
    if (fixtureErrors.length) throw new Error(fixtureErrors.join("\n"));
    if (evidence.page_width > viewport.width + 1) capture.checks.push({ rule: "page-overflow", actual: evidence.page_width, expected: viewport.width });
    if (!evidence.headings.some(({ level }) => level === "H1")) capture.checks.push({ rule: "page-heading", message: "No visible H1." });
    if (surface.id !== "storefront") {
      const preference = theme === "system-dark" ? "system" : theme;
      if (evidence.theme.preference !== preference || evidence.theme.selected.length !== 1 || evidence.theme.selected[0] !== preference || evidence.theme.effective !== (theme === "light" ? "light" : "dark")) capture.checks.push({ rule: "theme-selection", actual: evidence.theme });
    }
    const { default: AxeBuilder } = await import("@axe-core/playwright");
    const axe = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa", "wcag21aa"]).analyze();
    for (const violation of axe.violations) capture.checks.push({ rule: violation.id, impact: violation.impact, description: violation.description, nodes: violation.nodes.map(({ target, failureSummary }) => ({ target, failureSummary })) });
    evidence.axe_incomplete = axe.incomplete.map(({ id, nodes }) => ({ id, targets: nodes.map(({ target }) => target) }));
    evidence.page_errors = pageErrors;
    for (const message of pageErrors) capture.checks.push({ rule: "browser-error", message });
    const save = async (suffix, data, { exclusive = false } = {}) => {
      const name = `${id}--${suffix}`;
      await writeFile(path.join(output, name), data, exclusive ? { flag: "wx" } : undefined);
      capture.files[suffix] = { path: name, sha256: sha256(data) };
    };
    const imageFor = async (kind, disposableCapture, retainedCapture) => {
      if (!deployment) return retainedCapture();
      const saveSample = async ({ path: samplePath, bytes, state_path: statePath, state_bytes: stateBytes }) => {
        if (bytes !== null) await writeFile(path.join(output, samplePath), bytes, { flag: "wx" });
        await writeFile(path.join(output, statePath), stateBytes, { flag: "wx" });
      };
      try {
        const result = await captureStableImage({ page, id, kind, captureImage: disposableCapture, saveSample });
        capture.stability ??= {};
        capture.stability[kind] = result.stability;
        return result.image;
      } catch (error) {
        if (error?.captureStability) {
          capture.stability ??= {};
          capture.stability[kind] = error.captureStability;
        }
        throw error;
      }
    };
    const viewportImage = () => imageFor(
      "viewport",
      ({ timeout }) => captureViewportImage(page, viewport, { timeout }),
      () => page.screenshot({ animations: "disabled" })
    );
    await save("copy.json", Buffer.from(`${JSON.stringify(evidence, null, 2)}\n`));
    await page.mouse.move(0, 0);
    await save("viewport.png", await viewportImage(), { exclusive: Boolean(deployment) });
    await save("full.png", await imageFor(
      "full",
      ({ timeout }) => page.screenshot({ fullPage: true, animations: "disabled", timeout }),
      () => page.screenshot({ fullPage: true, animations: "disabled" })
    ), { exclusive: Boolean(deployment) });
    const sheetControl = page.locator(".ops-sheet__panel button:visible, .ops-sheet__panel a:visible, .ops-sheet__panel input:visible, .ops-sheet__panel select:visible, .ops-sheet__panel textarea:visible").first();
    const control = await sheetControl.count()
      ? sheetControl
      : page.locator(surface.id === "storefront" ? ".storefront-search__ops-links a:visible" : "[data-phx-theme][aria-pressed='true']:visible").first();
    if (await control.count()) {
      capture.interaction_target = await control.evaluate(captureUiStateInPage);
      await control.hover();
      await save("hover.png", await imageFor(
        "hover",
        ({ timeout }) => captureViewportImage(page, viewport, { timeout }),
        () => page.screenshot({ animations: "disabled" })
      ), { exclusive: Boolean(deployment) });
      await page.mouse.move(0, 0);
      await page.keyboard.press("Tab");
      await control.focus();
      await save("focus.png", await imageFor(
        "focus",
        ({ timeout }) => captureViewportImage(page, viewport, { timeout }),
        () => page.screenshot({ animations: "disabled" })
      ), { exclusive: Boolean(deployment) });
    }
    const nav = page.getByRole("button", { name: "Open navigation", exact: true });
    if (surface.id === "control-room" && viewport.width === 390) {
      if (!await nav.isVisible()) throw new Error("Compact navigation trigger is missing.");
      await nav.click();
      await page.waitForFunction(() => {
        const trigger = document.querySelector("[data-ops-nav-open]");
        const drawer = document.querySelector("#ops-mobile-nav");
        return trigger?.getAttribute("aria-expanded") === "true" && drawer && !drawer.hidden && drawer.classList.contains("is-open");
      });
      const mobileNavigation = await page.evaluate(() => {
        const drawer = document.querySelector("#ops-mobile-nav");
        const visible = (node) => node.getClientRects().length > 0 && getComputedStyle(node).visibility !== "hidden";
        return {
          expanded: document.querySelector("[data-ops-nav-open]")?.getAttribute("aria-expanded") === "true",
          visible: Boolean(drawer && !drawer.hidden && visible(drawer)),
          links: [...(drawer?.querySelectorAll("a[data-ops-nav-link]") || [])].filter(visible).map((node) => node.innerText.trim()).filter(Boolean)
        };
      });
      if (!mobileNavigation.visible || !mobileNavigation.expanded || mobileNavigation.links.length === 0) throw new Error("Compact navigation did not open with visible links.");
      capture.mobile_navigation = mobileNavigation;
      await page.mouse.move(0, 0);
      await save("navigation.png", await imageFor(
        "navigation",
        ({ timeout }) => captureViewportImage(page, viewport, { timeout }),
        () => page.screenshot({ animations: "disabled" })
      ), { exclusive: Boolean(deployment) });
    }
  } catch (error) {
    capture.error = error.capturePersistenceError
      ? `${error.message}; failed-attempt evidence persistence also failed: ${error.capturePersistenceError.message}`
      : error.message;
  } finally {
    if (context) await context.close();
    fontProfileSetup = null;
  }
  return capture;
}

export async function launchDisposableBrowser(chromium) {
  const launchOptions = { timeout: 30_000, args: ["--disable-partial-raster"] };
  return { browser: await chromium.launch(launchOptions), launchOptions };
}

export async function captureDisposableMatrix({ hostUrl, standaloneUrl, output, dataIdentity, clock, allowComposeNetwork = false }) {
  if (!hostUrl || !standaloneUrl || !output || !dataIdentity) throw new Error("Disposable capture requires both loopback targets, an output directory, and a verified data identity.");
  const host = new URL(hostUrl);
  const standalone = new URL(standaloneUrl);
  const ownedComposeTargets = allowComposeNetwork && host.protocol === "http:" && host.hostname === "web" && host.port === "4002" && host.pathname === "/" && !host.username && !host.password && !host.search && !host.hash && standalone.protocol === "http:" && standalone.hostname === "standalone_ops" && standalone.port === "4003" && standalone.pathname === "/" && !standalone.username && !standalone.password && !standalone.search && !standalone.hash;
  if (!ownedComposeTargets) throw new Error("Disposable browser targets must use the exact owned Compose service routes; loopback retained-preview targets are not accepted.");
  if (path.resolve(output) !== "/artifacts") throw new Error("Disposable captures must write through the helper-owned /artifacts mount.");
  const clockErrors = disposableClockErrors(clock);
  if (clockErrors.length) throw new Error(clockErrors.join("\n"));
  const { chromium } = await import("@playwright/test");
  const { browser, launchOptions } = await launchDisposableBrowser(chromium);
  const captures = [];
  let browserFontProfile = null;
  const appendCapture = (capture) => {
    capture.browser_version = browser.version();
    capture.platform = `${process.platform}-${process.arch}`;
    capture.data_identity = dataIdentity;
    captures.push(capture);
    if (capture.error) throw new Error(`Disposable capture ${capture.id} failed: ${capture.error}`);
    if (!capture.browser_font_profile) throw new Error(`Disposable font profile setup failed for ${capture.id}: ${capture.error || "no acknowledged profile was returned"}`);
    if (browserFontProfile && JSON.stringify(browserFontProfile) !== JSON.stringify(capture.browser_font_profile)) throw new Error(`Disposable font profile changed during capture at ${capture.id}.`);
    browserFontProfile = capture.browser_font_profile;
    console.log(`${capture.id}: ${capture.error ?? `${capture.checks.length} mechanical findings`}`);
  };
  try {
    for (const surface of surfaces) for (const theme of themes) for (const viewport of viewports) {
      const capture = await captureSurface(browser, surface, theme, viewport, output, { deployment: "host", baseURL: hostUrl, dataIdentity, clock });
      appendCapture(capture);
    }
    for (const surface of surfaces.filter(({ id }) => id !== "storefront")) for (const theme of themes) for (const viewport of viewports) {
      const standaloneSurface = { ...surface, route: standaloneRoutes[surface.id] };
      const capture = await captureSurface(browser, standaloneSurface, theme, viewport, output, { deployment: "standalone", baseURL: standaloneUrl, dataIdentity, clock });
      appendCapture(capture);
    }
  } finally { await browser.close(); }
  return { captures, browserVersion: browser.version(), dataIdentity, browserLaunchOptions: launchOptions, browserFontProfile };
}

async function captureAll() {
  const runtime = await verifyPreviewSource();
  const output = path.join(reviewArtifactRoot, new Date().toISOString().replace(/[:.]/g, "-"));
  await mkdir(output, { recursive: true });
  const source = await sourceIdentity();
  const { chromium } = await import("@playwright/test");
  const browser = await chromium.launch();
  const manifest = { schema: "scrypath.ui-capture.v1", generated_at: new Date().toISOString(), source, runtime, base_url: process.env.PLAYWRIGHT_BASE_URL || "http://127.0.0.1:4002", environment: { platform: process.platform, browser: browser.version() }, scope: "Observed entry states, hover, focus, and mobile navigation. No seeding, search submission, saving, retry, or promotion. Docker source mount and inclusion of locally known origin/main verified before capture.", captures: [] };
  try {
    for (const surface of surfaces) for (const theme of themes) for (const viewport of viewports) {
      const capture = await captureSurface(browser, surface, theme, viewport, output);
      manifest.captures.push(capture);
      console.log(`${capture.id}: ${capture.error ?? `${capture.checks.length} mechanical findings`}`);
    }
  } finally { await browser.close(); }
  manifest.source_changed_during_capture = source.tree_sha256 !== (await sourceIdentity()).tree_sha256;
  const bytes = Buffer.from(`${JSON.stringify(manifest, null, 2)}\n`);
  await writeFile(path.join(output, "capture.json"), bytes);
  await writeFile(path.join(output, "review.json"), `${JSON.stringify(reviewTemplate(manifest, sha256(bytes)), null, 2)}\n`);
  const cards = manifest.captures.map((capture) => `<article><h2>${escapeHtml(capture.id)}</h2><p>${escapeHtml(capture.error ?? `${capture.checks.length} mechanical findings`)}</p>${["viewport.png", "full.png", "hover.png", "focus.png", "navigation.png"].filter((key) => capture.files[key]).map((key) => `<a href="${escapeHtml(capture.files[key].path)}">${escapeHtml(key)}</a> `).join("")} ${capture.files["copy.json"] ? `<a href="${escapeHtml(capture.files["copy.json"].path)}">Copy and checks</a><img loading="lazy" src="${escapeHtml(capture.files["viewport.png"].path)}" alt="${escapeHtml(capture.id)}">` : ""}</article>`).join("\n");
  await writeFile(path.join(output, "index.html"), `<!doctype html><html lang="en"><meta charset="utf-8"><title>Scrypath UI review evidence</title><style>body{font:16px system-ui;margin:24px;background:#f3f5f8;color:#141923}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:24px}article{background:white;padding:16px;border:1px solid #dce1e8;border-radius:8px}h2{font-size:16px}img{width:100%;display:block;margin-top:16px}a{line-height:2}</style><h1>UI evidence — review pending</h1><p>Entry-state captures are observations, not approved baselines or completed user journeys. Review the full inventory before consulting the feedback checklist.</p><main>${cards}</main></html>`);
  const failures = manifest.captures.filter(({ error }) => error).length;
  const findings = manifest.captures.reduce((count, capture) => count + capture.checks.length, 0);
  console.log(`Evidence: ${output}\nCapture: ${manifest.captures.length - failures}/${manifest.captures.length}; mechanical findings: ${findings}; design review: pending.`);
  if (failures || manifest.source_changed_during_capture) process.exitCode = 1;
}

async function preflight() {
  const runtime = await verifyPreviewSource();
  const remoteMain = runGit(["ls-remote", "--exit-code", "origin", "refs/heads/main"], { timeout: 15_000, maxBuffer: 1024 * 1024 }).trim().split(/\s+/)[0];
  const errors = previewSourceErrors(await realpath(repoRoot), runtime.mount, runtime.main_included, true, remoteMain === runtime.main_ref);
  if (errors.length) throw new Error(errors.join("\n"));
  const source = await sourceIdentity();
  const branch = runGit(["branch", "--show-current"]).trim();
  const pending = runGit(["status", "--porcelain", "--untracked-files=all"]).split("\n").filter(Boolean);
  console.log(JSON.stringify({ checkout: repoRoot, command_cwd: process.cwd(), branch, source, runtime: { ...runtime, remote_main_current: true }, pending_work: pending }, null, 2));
}

async function checkReview(directory) {
  await verifyPreviewSource();
  const manifestBytes = await readFile(path.join(directory, "capture.json"));
  const manifest = JSON.parse(manifestBytes);
  const review = JSON.parse(await readFile(path.join(directory, "review.json")));
  const errors = reviewErrors(review, manifest, sha256(manifestBytes), await sourceIdentity());
  for (const capture of manifest.captures) for (const file of Object.values(capture.files)) {
    try {
      const target = path.resolve(directory, file.path);
      if (!target.startsWith(`${path.resolve(directory)}${path.sep}`)) throw new Error("Artifact escapes capture directory.");
      if (sha256(await readFile(target)) !== file.sha256) errors.push(`Artifact changed: ${file.path}`);
    } catch (error) { errors.push(`Missing/invalid artifact: ${file.path} (${error.message})`); }
  }
  console.log(errors.length ? errors.join("\n") : "Review completeness and source checks passed; this is not an aesthetic score or identity attestation.");
  if (errors.length) process.exitCode = 1;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    if (process.argv[2] === "--preflight" && process.argv.length === 3) await preflight();
    else if (process.argv[2] === "--check" && process.argv[3]) await checkReview(path.resolve(process.argv[3]));
    else if (process.argv.length === 2) await captureAll();
    else throw new Error("Usage: node e2e/ui-review.mjs [--preflight | --check CAPTURE_DIRECTORY]");
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
