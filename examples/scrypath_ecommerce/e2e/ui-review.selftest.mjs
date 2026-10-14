import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { test } from "node:test";
import { dimensions, previewSourceErrors, reviewArtifactRoot, reviewErrors, reviewTemplate, surfaces, themes, viewports } from "./ui-review.mjs";

test("Playwright output cleanup preserves UI review evidence", async () => {
  const demoRoot = fileURLToPath(new URL("../", import.meta.url));
  const temporaryDemo = await mkdtemp(path.join(tmpdir(), "scrypath-ui-review-output-"));
  const reviewDirectory = path.join(temporaryDemo, path.relative(demoRoot, reviewArtifactRoot));
  const playwrightDirectory = path.join(temporaryDemo, "test-results");
  try {
    await mkdir(reviewDirectory, { recursive: true });
    await mkdir(playwrightDirectory, { recursive: true });
    const evidence = path.join(reviewDirectory, "capture.json");
    await writeFile(evidence, "preserve this review");
    await rm(playwrightDirectory, { recursive: true, force: true });
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

test("reviewing reported screens alone cannot omit the rest of the inventory", () => {
  const { source, manifest, review } = fixture();
  assert.deepEqual(reviewErrors(review, manifest, "capture-digest", source), []);
  review.surfaces = review.surfaces.filter(({ id }) => id !== "playbooks");
  review.dimensions = review.dimensions.filter(({ id }) => id !== dimensions.at(-1));
  const errors = reviewErrors(review, manifest, "capture-digest", source);
  assert.ok(errors.some((error) => error.startsWith("playbooks:")));
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
