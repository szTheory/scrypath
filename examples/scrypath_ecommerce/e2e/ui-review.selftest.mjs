import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { test } from "node:test";
import { captureDisposableMatrix, cleanGitEnvironment, dimensions, disposableClockErrors, entryFixtureErrors, isCanonicalOrigin, previewSourceErrors, reviewArtifactRoot, reviewErrors, reviewTemplate, standaloneRoutes, surfaces, themes, viewports } from "./ui-review.mjs";

test("disposable captures require a valid fixed browser clock before launching Chromium", async () => {
  const utc = "2026-10-31T12:00:00.000Z";
  const { createHash } = await import("node:crypto");
  const clock = { utc, sha256: createHash("sha256").update(`${utc}\n`).digest("hex"), timezone: "UTC", locale: "en-US", browser_mode: "fixed-date" };
  assert.deepEqual(disposableClockErrors(clock), []);
  for (const invalid of [undefined, { ...clock, sha256: "0".repeat(64) }, { ...clock, timezone: "America/New_York" }, { ...clock, utc: "2026-10-31T99:00:00.000Z" }]) {
    assert.ok(disposableClockErrors(invalid).length);
    await assert.rejects(captureDisposableMatrix({ hostUrl: "http://web:4002", standaloneUrl: "http://standalone_ops:4003", output: "/artifacts", dataIdentity: "fixture", clock: invalid, allowComposeNetwork: true }), /clock/i);
  }
});

test("standalone saved-search capture follows the canonical search route", () => {
  assert.equal(standaloneRoutes["saved-searches"], "/ops/search?saved=manage");
});

test("Playwright output cleanup preserves UI review evidence", async () => {
  const demoRoot = fileURLToPath(new URL("../", import.meta.url));
  const temporaryDemo = await mkdtemp(path.join(tmpdir(), "scrypath-ui-review-output-"));
  const reviewDirectory = path.join(temporaryDemo, path.relative(demoRoot, reviewArtifactRoot));
  const phase185Directory = path.join(reviewDirectory, "phase185");
  const legacyCleanupDirectory = path.join(reviewDirectory, "iteration3-journeys");
  const playwrightDirectory = path.join(temporaryDemo, "test-results");
  try {
    await mkdir(phase185Directory, { recursive: true });
    await mkdir(legacyCleanupDirectory, { recursive: true });
    await mkdir(playwrightDirectory, { recursive: true });
    const evidence = path.join(phase185Directory, "capture.json");
    await writeFile(evidence, "preserve this review");
    await writeFile(path.join(legacyCleanupDirectory, "old-output.json"), "legacy output");
    await rm(playwrightDirectory, { recursive: true, force: true });
    await rm(legacyCleanupDirectory, { recursive: true, force: true });
    assert.equal(await readFile(evidence, "utf8"), "preserve this review");
  } finally {
    await rm(temporaryDemo, { recursive: true, force: true });
  }
});

function fixture() {
  const source = { tree_sha256: "current" };
  const captures = surfaces.flatMap(({ id: surface }) => themes.flatMap((theme) => viewports.map(({ width }) => ({ id: `${surface}--${theme}--${width}`, surface, checks: [], files: { "viewport.png": {}, "full.png": {}, "copy.json": {} } }))));
  const manifest = { source, runtime: { source_match: true, main_included: true }, captures };
  const review = reviewTemplate(manifest, "capture-digest");
  review.status = "reviewed";
  for (const row of review.surfaces) Object.assign(row, { verdict: "acceptable", rationale: "Fixture only, never a product review.", evidence: captures.filter(({ surface }) => surface === row.id).map(({ id }) => id) });
  for (const row of review.dimensions) Object.assign(row, { verdict: "acceptable", rationale: "Fixture only.", evidence: [captures[0].id] });
  review.coverage = { verdict: "supported", rationale: "Test fixture only.", evidence: ["isolated-test-receipt"] };
  return { source, manifest, review };
}

test("a capture is pending until all review dimensions and state evidence are supplied", () => {
  const { source, manifest } = fixture();
  const errors = reviewErrors(reviewTemplate(manifest, "capture-digest"), manifest, "capture-digest", source);
  assert.ok(errors.some((error) => error.includes("pending")));
  assert.ok(errors.some((error) => error.includes("Journey/state")));
});

test("a different preview worktree or omitted main commits cannot masquerade as latest", () => {
  assert.deepEqual(previewSourceErrors("/current", "/current", true), []);
  assert.equal(previewSourceErrors("/current", "/old", false).length, 2);
  assert.equal(previewSourceErrors("/current", "/current", true, false).length, 1);
  assert.ok(previewSourceErrors("/current", "/current", true, true, false).some((error) => error.includes("stale against the remote")));
  const { source, manifest, review } = fixture();
  manifest.runtime.source_match = false;
  assert.ok(reviewErrors(review, manifest, "capture-digest", source).some((error) => error.includes("provenance")));
});

test("disposable captures cannot target retained loopback or arbitrary network hosts", async () => {
  await assert.rejects(captureDisposableMatrix({ hostUrl: "http://127.0.0.1:4002", standaloneUrl: "http://127.0.0.1:4003", output: "/tmp/evidence", dataIdentity: "digest" }), /retained-preview targets are not accepted/);
  await assert.rejects(captureDisposableMatrix({ hostUrl: "http://example.com:4002", standaloneUrl: "http://standalone_ops:4003", output: "/tmp/evidence", dataIdentity: "digest", allowComposeNetwork: true }), /exact owned Compose service routes/);
});

test("disposable entry fixtures distinguish host incident data from standalone empty allowlists", () => {
  const incidentSummary = "Control Room 3 sync jobs failed";
  const incidentFailures = "3 failed, 2 retrying Product Invalid data Meilisearch rejected it Unknown cause";
  const standaloneSummary = "No search schemas configured. Configure the host application's schema allowlist";
  const standaloneFailures = "No schemas configured. Add allowlisted schema modules with schema_allowlist in :scrypath_ops";
  assert.deepEqual(entryFixtureErrors("host", "control-room", incidentSummary), []);
  assert.deepEqual(entryFixtureErrors("host", "failed-sync", incidentFailures), []);
  assert.deepEqual(entryFixtureErrors("standalone", "control-room", standaloneSummary), []);
  assert.deepEqual(entryFixtureErrors("standalone", "failed-sync", standaloneFailures), []);
  assert.ok(entryFixtureErrors("host", "failed-sync", "No failures" ).length > 0);
  assert.ok(entryFixtureErrors("standalone", "control-room", incidentSummary).length > 0);
});

test("UI review Git reads ignore inherited repository redirects and require canonical origin", () => {
  assert.deepEqual(cleanGitEnvironment({ PATH: "/usr/bin", GIT_DIR: "/tmp/forged.git", GIT_WORK_TREE: "/tmp/forged" }), {
    PATH: "/usr/bin", GIT_CONFIG_NOSYSTEM: "1", GIT_CONFIG_GLOBAL: "/dev/null"
  });
  assert.equal(isCanonicalOrigin("https://github.com/szTheory/scrypath.git"), true);
  assert.equal(isCanonicalOrigin("git@github.com:szTheory/scrypath.git"), true);
  assert.equal(isCanonicalOrigin("https://example.com/szTheory/scrypath.git"), false);
});

test("reviewing reported screens alone cannot omit the rest of the inventory", () => {
  const { source, manifest, review } = fixture();
  assert.deepEqual(reviewErrors(review, manifest, "capture-digest", source), []);
  review.surfaces = review.surfaces.filter(({ id }) => id !== "saved-searches");
  review.dimensions = review.dimensions.filter(({ id }) => id !== dimensions.at(-1));
  const errors = reviewErrors(review, manifest, "capture-digest", source);
  assert.ok(errors.some((error) => error.startsWith("saved-searches:")));
  assert.ok(errors.some((error) => error.startsWith("unreported-problems:")));
});

test("a stale source, tampered capture binding, or incomplete matrix cannot pass", () => {
  const { source, manifest, review } = fixture();
  review.capture_sha256 = "other-capture";
  manifest.captures.pop();
  const errors = reviewErrors(review, manifest, "capture-digest", { tree_sha256: `${source.tree_sha256}-changed` });
  assert.ok(errors.some((error) => error.includes("Source changed")));
  assert.ok(errors.some((error) => error.includes("different capture")));
  assert.ok(errors.some((error) => error.includes("missing")));
});

test("a needs-work verdict, mechanical failure, or open finding remains visible", () => {
  const { source, manifest, review } = fixture();
  review.surfaces[0].verdict = "needs-work";
  manifest.captures[0].checks.push({ rule: "page-overflow" });
  review.findings.push({ disposition: "open", evidence: [manifest.captures[0].id], rationale: "Observed overflow." });
  const errors = reviewErrors(review, manifest, "capture-digest", source);
  assert.ok(errors.some((error) => error.includes("needs work")));
  assert.ok(errors.some((error) => error.includes("Mechanical")));
  assert.ok(errors.some((error) => error.includes("open")));
});

test("a pass cannot cite nonexistent screenshots or omit a theme/width", () => {
  const { source, manifest, review } = fixture();
  review.surfaces[0].evidence = ["not-a-capture"];
  delete manifest.captures[0].files["full.png"];
  const errors = reviewErrors(review, manifest, "capture-digest", source);
  assert.ok(errors.some((error) => error.includes("unknown capture")));
  assert.ok(errors.some((error) => error.includes("not every theme/width")));
  assert.ok(errors.some((error) => error.includes("artifact is missing")));
});
