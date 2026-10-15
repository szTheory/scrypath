#!/usr/bin/env node
// Observe the running UI without seeding, recovery actions, or a paid model call.
import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { mkdir, readFile, realpath, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const demoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
export const reviewArtifactRoot = path.join(demoRoot, "ui-review-artifacts");
const repoRoot = path.resolve(demoRoot, "../..");
export const surfaces = [
  { id: "storefront", route: "/", role: "ROLE-INT", jobs: ["JOB-01", "JOB-02"], purpose: "Verify tenant-scoped search and facets; reach operator help when search fails." },
  { id: "control-room", route: "/admin/search/", role: "ROLE-OPS", jobs: ["JOB-03"], purpose: "Understand the current observation and choose the next safe task." },
  { id: "search-health", route: "/admin/search/health", role: "ROLE-OPS", jobs: ["JOB-03"], purpose: "Identify the affected schema and distinguish backend from queue evidence." },
  { id: "failed-sync", route: "/admin/search/failed-sync", role: "ROLE-OPS", jobs: ["JOB-03"], purpose: "Inspect exact failed work and determine whether recovery is eligible." },
  { id: "sync-drift", route: "/admin/search/sync-drift", role: "ROLE-OWNER", jobs: ["JOB-04"], purpose: "Separate index settings, document visibility, recovery, and promotion evidence." },
  { id: "search", route: "/admin/search/search", role: "ROLE-OWNER", jobs: ["JOB-05"], purpose: "Choose explicit targets, run a bounded query, and interpret attributed results." },
  { id: "playbooks", route: "/admin/search/playbooks", role: "ROLE-OWNER", jobs: ["JOB-05"], purpose: "Understand a saved check and distinguish its definition, draft, and run outcome." },
  { id: "help", route: "/admin/search/help", role: "ROLE-INT", jobs: ["JOB-03", "JOB-05"], purpose: "Understand search, sync and saved inputs without leaving the installed interface." }
];
export const dimensions = [
  "task-flow", "information-hierarchy", "language-and-domain-truth", "visual-composition",
  "interaction-and-accessibility", "responsive-behavior", "cross-screen-consistency", "unreported-problems"
];
export const themes = ["light", "dark", "system-dark"];
export const viewports = [{ width: 1440, height: 900 }, { width: 768, height: 900 }, { width: 390, height: 844 }];
const sha256 = (bytes) => createHash("sha256").update(bytes).digest("hex");
const escapeHtml = (value) => String(value).replace(/[&<>"']/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[char]);

export async function sourceIdentity() {
  const paths = ["AGENTS.md", "PRODUCT.md", "DESIGN.md", ".planning/reference/OPERATOR-UI-QUALITY.md", "scrypath_ops/lib", "scrypath_ops/assets", "scrypath_ops/priv/static", "scrypath_ops/docs", "examples/scrypath_ecommerce/lib", "examples/scrypath_ecommerce/assets", "examples/scrypath_ecommerce/priv/static", "examples/scrypath_ecommerce/e2e", "examples/scrypath_ecommerce/package.json"];
  const files = [...new Set(execFileSync("git", ["ls-files", "-z", "--cached", "--others", "--exclude-standard", "--", ...paths], { cwd: repoRoot }).toString().split("\0").filter(Boolean))].sort();
  const hash = createHash("sha256");
  for (const file of files) {
    let bytes;
    try { bytes = await readFile(path.join(repoRoot, file)); }
    catch (error) { if (error.code !== "ENOENT") throw error; bytes = Buffer.from("<deleted>"); }
    hash.update(`${file}\0${bytes.length}\0`).update(bytes);
  }
  return { head: execFileSync("git", ["rev-parse", "HEAD"], { cwd: repoRoot }).toString().trim(), tree_sha256: hash.digest("hex") };
}

export function previewSourceErrors(expected, mounted, mainIncluded, endpointMatches = true, mainCurrent = true) {
  const errors = [];
  if (expected !== mounted) errors.push(`Preview source mismatch: ${mounted}; expected ${expected}.`);
  if (!mainIncluded) errors.push("Checkout does not include origin/main. Reconcile newer merged work before reviewing the current UI.");
  if (!endpointMatches) errors.push("Review URL does not match the verified preview container's published loopback port.");
  if (!mainCurrent) errors.push("origin/main is stale against the remote main ref. Refresh and reconcile main before treating this preview as latest.");
  return errors;
}

async function verifyPreviewSource() {
  const container = process.env.UI_REVIEW_CONTAINER || "scrypath_ecommerce-web-1";
  const runtime = JSON.parse(execFileSync("docker", ["inspect", container, "--format", '{"mounts":{{json .Mounts}},"ports":{{json .NetworkSettings.Ports}}}'], { encoding: "utf8" }));
  const source = runtime.mounts.find((mount) => mount.Type === "bind" && mount.Destination === "/app")?.Source;
  if (!source) throw new Error(`${container} has no source bind mount at /app; runtime source is unverified.`);
  const mounted = await realpath(source.replace(/^\/host_mnt(?=\/)/, ""));
  const expected = await realpath(repoRoot);
  const mainIncluded = execFileSync("git", ["merge-base", "origin/main", "HEAD"], { cwd: repoRoot, encoding: "utf8" }).trim() === execFileSync("git", ["rev-parse", "origin/main"], { cwd: repoRoot, encoding: "utf8" }).trim();
  const url = new URL(process.env.PLAYWRIGHT_BASE_URL || "http://127.0.0.1:4002");
  const endpointMatches = ["127.0.0.1", "localhost", "[::1]"].includes(url.hostname) && Object.values(runtime.ports).flatMap((ports) => ports || []).some((binding) => binding.HostPort === (url.port || "80") && ["127.0.0.1", "::1"].includes(binding.HostIp));
  const errors = previewSourceErrors(expected, mounted, mainIncluded, endpointMatches);
  if (errors.length) throw new Error(errors.join("\n"));
  return { container, source_match: true, mount: mounted, main_included: true, main_ref: execFileSync("git", ["rev-parse", "origin/main"], { cwd: repoRoot, encoding: "utf8" }).trim() };
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

async function captureSurface(browser, surface, theme, viewport, output) {
  const id = `${surface.id}--${theme}--${viewport.width}`;
  const capture = { id, surface: surface.id, theme, viewport, route: surface.route, checks: [], files: {} };
  const context = await browser.newContext({ baseURL: process.env.PLAYWRIGHT_BASE_URL || "http://127.0.0.1:4002", viewport, colorScheme: theme === "light" ? "light" : "dark", reducedMotion: "reduce" });
  await context.addInitScript((preference) => {
    if (location.origin === "null") return;
    if (preference === "system-dark") localStorage.removeItem("phx:theme");
    else localStorage.setItem("phx:theme", preference);
  }, theme);
  const page = await context.newPage();
  page.setDefaultTimeout(10_000);
  const pageErrors = [];
  page.on("pageerror", (error) => pageErrors.push(error.message));
  try {
    const response = await page.goto(surface.route);
    if (!response?.ok()) throw new Error(`Navigation returned ${response?.status() ?? "no response"}`);
    await page.waitForFunction(() => Boolean(window.liveSocket?.isConnected?.()) && Boolean(document.querySelector("[data-phx-main].phx-connected")));
    await page.evaluate(() => document.fonts.ready);
    const evidence = await page.evaluate(() => {
      const visible = (node) => node.getClientRects().length > 0 && getComputedStyle(node).visibility !== "hidden";
      const nodes = (selector) => [...document.querySelectorAll(selector)].filter(visible);
      return {
        text: document.body.innerText,
        headings: nodes("h1,h2,h3,h4").map((node) => ({ level: node.tagName, text: node.innerText })),
        controls: nodes("a,button,input,select,textarea").map((node) => ({ tag: node.tagName, text: node.innerText || node.getAttribute("aria-label") || node.getAttribute("placeholder"), href: node.getAttribute("href"), disabled: node.disabled === true })),
        page_width: document.documentElement.scrollWidth, viewport_width: window.innerWidth,
        theme: { preference: document.documentElement.dataset.themePreference, effective: document.documentElement.dataset.themeEffective, selected: nodes("[data-phx-theme][aria-pressed='true']").map((node) => node.dataset.phxTheme) }
      };
    });
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
    const save = async (suffix, data) => {
      const name = `${id}--${suffix}`;
      await writeFile(path.join(output, name), data);
      capture.files[suffix] = { path: name, sha256: sha256(data) };
    };
    await save("copy.json", Buffer.from(`${JSON.stringify(evidence, null, 2)}\n`));
    await page.mouse.move(0, 0);
    await save("viewport.png", await page.screenshot({ animations: "disabled" }));
    await save("full.png", await page.screenshot({ fullPage: true, animations: "disabled" }));
    const control = page.locator(surface.id === "storefront" ? ".storefront-search__ops-links a:visible" : "[data-phx-theme][aria-pressed='true']:visible").first();
    if (await control.count()) {
      await control.hover();
      await save("hover.png", await page.screenshot({ animations: "disabled" }));
      await page.mouse.move(0, 0);
      await page.keyboard.press("Tab");
      await control.focus();
      await save("focus.png", await page.screenshot({ animations: "disabled" }));
    }
    const nav = page.getByRole("button", { name: "Open navigation", exact: true });
    if (surface.id === "control-room" && await nav.isVisible()) {
      await nav.click();
      await save("navigation.png", await page.screenshot({ animations: "disabled" }));
    }
  } catch (error) {
    capture.error = error.message;
  } finally { await context.close(); }
  return capture;
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
  const remoteMain = execFileSync("git", ["ls-remote", "--exit-code", "origin", "refs/heads/main"], { cwd: repoRoot, encoding: "utf8", timeout: 10000 }).trim().split(/\s+/)[0];
  const errors = previewSourceErrors(await realpath(repoRoot), runtime.mount, runtime.main_included, true, remoteMain === runtime.main_ref);
  if (errors.length) throw new Error(errors.join("\n"));
  const source = await sourceIdentity();
  const branch = execFileSync("git", ["branch", "--show-current"], { cwd: repoRoot, encoding: "utf8" }).trim();
  const pending = execFileSync("git", ["status", "--porcelain", "--untracked-files=all"], { cwd: repoRoot, encoding: "utf8" }).split("\n").filter(Boolean);
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
