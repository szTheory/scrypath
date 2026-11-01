"use strict";

const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");
const evidence = require("./ecommerce_evidence.cjs");
const build = require("./ecommerce_build.cjs");
const pairs = require("./ui_state_pairs.cjs");
const { PNG } = require("../../examples/scrypath_ecommerce/node_modules/pngjs");

const BEFORE_SHA = "1".repeat(40);
const CANDIDATE_SHA = "2".repeat(40);
const BEFORE_BUILD_SHA = "3".repeat(40);
const CANDIDATE_BUILD_SHA = "4".repeat(40);
const BEFORE_TREE = `sha256:${"a".repeat(64)}`;
const CANDIDATE_TREE = `sha256:${"b".repeat(64)}`;
const FIXTURE = `sha256:${"c".repeat(64)}`;
const RUNTIME = `sha256:${"d".repeat(64)}`;
const BROWSER = `sha256:${"e".repeat(64)}`;
const BROWSER_CANDIDATE = `sha256:${"9".repeat(64)}`;
const APP_BEFORE = `sha256:${"f".repeat(64)}`;
const APP_CANDIDATE = `sha256:${"0".repeat(64)}`;
const OPS_BEFORE = `sha256:${"7".repeat(64)}`;
const OPS_CANDIDATE = `sha256:${"8".repeat(64)}`;
const BASE = `sha256:${"6".repeat(64)}`;
const BEFORE_SOURCE_LAYER = `sha256:${"5".repeat(64)}`;
const CANDIDATE_SOURCE_LAYER = `sha256:${"a".repeat(64)}`;
const CLOCK = `sha256:${"4".repeat(64)}`;

function digest(bytes) {
  return crypto.createHash("sha256").update(bytes).digest("hex");
}

function canonical(value) {
  return Array.isArray(value)
    ? value.map(canonical)
    : value && typeof value === "object"
      ? Object.fromEntries(Object.keys(value).sort().map((key) => [key, canonical(value[key])]))
      : value;
}

const browser = { engine: "chromium", version: "140.0.0.0", package: "@playwright/test", package_version: "1.60.0" };
const dataRecipe = { protocol: "phase185-test-data-v1", fixture: "synthetic-unit-only" };
const dataRecipeSha = `sha256:${digest(Buffer.from(JSON.stringify(canonical(dataRecipe))))}`;
const profileRecipe = {
  browser,
  launch_args: ["--disable-partial-raster"],
  locale: "en-US",
  timezone: "UTC",
  device_scale_factor: 1,
  font_profile: {
    method: "retained-cdp-fixed-font-v1",
    fixed_font_family: "Liberation Mono",
    applied: "before-first-navigation",
    lifetime: "page-context"
  },
  font_profile_setup: { method: "retained-cdp-fixed-font-v1", font_families: { fixed: "Liberation Mono" }, applied: "before-first-navigation", lifetime: "page-context" }
};
const PROFILE = `sha256:${digest(Buffer.from(JSON.stringify(canonical(profileRecipe))))}`;
const recipe = {
  ...profileRecipe,
  browser_date: { fixed: true, timers_running: true, timer_elapsed_ms: 40, observed: "2026-10-31T23:41:34.668Z" },
  profile_sha256: PROFILE,
  clock_sha256: CLOCK,
  data_recipe_sha256: dataRecipeSha
};
const recipeSha = `sha256:${digest(Buffer.from(JSON.stringify(canonical(recipe))))}`;

function authority() {
  return {
    schema: "scrypath.ui-state-pair-authority.v2",
    qualification: {
      path: "/private/tmp/plan05-qualification.json",
      sha256: `sha256:${"6".repeat(64)}`,
      environment: {
        browser_version: browser.version,
        browser_launch: { timeout: 30000, args: ["--disable-partial-raster"] },
        browser_font_profile: { method: "retained-cdp-fixed-font-v1", font_families: { fixed: "Liberation Mono" }, applied: "before-first-navigation", lifetime: "page-context" },
        clock: { utc: recipe.browser_date.observed, sha256: CLOCK.slice(7), timezone: "UTC", locale: "en-US", browser_mode: "fixed-date" }
      },
      browser_runtime: { browser_image_id: `sha256:${"b".repeat(64)}`, effective_runtime_sha256: RUNTIME, browser_base_layers_sha256: BASE, playwright_package_version: browser.package_version },
      record: {
        schema: "scrypath.phase185-before-qualification.v1",
        status: "qualified",
        source_sha: BEFORE_SHA,
        browser_runtime_equivalence: { rootfs_layers_equal: true, effective_config_equal: true, source_sha: BEFORE_SHA, actual_image_id: `sha256:${"b".repeat(64)}` }
      }
    },
    expected: {
      before: { product_source_sha: BEFORE_SHA, build_source_sha: BEFORE_BUILD_SHA, product_tree_sha256: BEFORE_TREE, fixture_overlay_sha256: FIXTURE,
        application_image_id: APP_BEFORE, standalone_ops_image_id: OPS_BEFORE, browser_image_id: BROWSER, browser_source_layer_id: BEFORE_SOURCE_LAYER,
        browser_base_layers_sha256: BASE, effective_runtime_sha256: RUNTIME },
      candidate: { product_source_sha: CANDIDATE_SHA, build_source_sha: CANDIDATE_BUILD_SHA, product_tree_sha256: CANDIDATE_TREE, fixture_overlay_sha256: FIXTURE,
        application_image_id: APP_CANDIDATE, standalone_ops_image_id: OPS_CANDIDATE, browser_image_id: BROWSER_CANDIDATE, browser_source_layer_id: CANDIDATE_SOURCE_LAYER,
        browser_base_layers_sha256: BASE, effective_runtime_sha256: RUNTIME },
      fixture_overlay_sha256: FIXTURE,
      effective_runtime_sha256: RUNTIME,
      browser_base_layers_sha256: BASE,
      recipe: structuredClone(recipe)
    }
  };
}

function png(color = 20) {
  const image = new PNG({ width: 1, height: 1 });
  image.data.set([color, 30, 40, 255]);
  return PNG.sync.write(image);
}

function runReceipt({ sourceSha, buildSha, productTreeSha, appImageId, opsImageId, browserImageId, sourceLayerId, imageBytes = png(), mutateCase } = {}) {
  const beforeSide = sourceSha === BEFORE_SHA;
  buildSha ??= beforeSide ? BEFORE_BUILD_SHA : CANDIDATE_BUILD_SHA;
  productTreeSha ??= beforeSide ? BEFORE_TREE : CANDIDATE_TREE;
  appImageId ??= beforeSide ? APP_BEFORE : APP_CANDIDATE;
  opsImageId ??= beforeSide ? OPS_BEFORE : OPS_CANDIDATE;
  browserImageId ??= beforeSide ? BROWSER : BROWSER_CANDIDATE;
  sourceLayerId ??= beforeSide ? BEFORE_SOURCE_LAYER : CANDIDATE_SOURCE_LAYER;
  const cases = evidence.preservationCases.map((entry) => {
    const state = {
      element: entry.element,
      category: entry.category,
      route: entry.element === "E1" ? "/" : "/admin/search/search",
      theme: "light",
      viewport: { width: 1440, height: 900 },
      scroll: { x: 0, y: 0 },
      focus: { name: `control-${entry.id}` },
      data_identity: `data-${entry.id}`
    };
    const widths = entry.category === "overflow" ? [1440, 768, 390] : [1440];
    const images = widths.map((width) => ({ path: `ui-review-artifacts/iteration3-journeys/phase185-held-out/${entry.id.replaceAll(" ", "-")}-${width}.png`, sha256: digest(imageBytes), viewport: { width, height: width === 390 ? 844 : 900 }, capture: "full-page-real-product-state" }));
    const item = {
      id: entry.id,
      test_identity: JSON.stringify([entry.file, "chromium", [path.posix.basename(entry.file), `${entry.id} held-out assertion`], "shared"]),
      product_source_sha: sourceSha,
      build_source_sha: buildSha,
      product_tree_sha256: productTreeSha,
      fixture_overlay_sha256: FIXTURE,
      recipe_sha256: recipeSha,
      runtime: { application_image_id: appImageId, standalone_ops_image_id: opsImageId, browser_image_id: browserImageId, browser_source_layer_id: sourceLayerId, browser_base_layers_sha256: BASE, effective_runtime_sha256: RUNTIME },
      clock_recipe: recipe,
      data_recipe: structuredClone(dataRecipe),
      state,
      actions: ["navigate", "observe"],
      transport_sequence: [{ operation: "liveview-connected", outcome: "connected" }],
      geometry: [{ name: `element-${entry.element}`, x: 0, y: 0, width: 100, height: 20 }],
      assertions: [{ name: `assert-${entry.id}`, status: "passed", actual: `observed-${entry.id}` }],
      visible_copy: [{ text: `Visible ${entry.id}`, sha256: digest(Buffer.from(`Visible ${entry.id}`)) }],
      images
    };
    return mutateCase?.(item) || item;
  });
  return {
    eligibility: { eligible: true },
    source: { checkout_head: buildSha, built_source_sha: buildSha, product_source_sha: sourceSha },
    images: { application: { runtime_id: appImageId }, standalone_ops: { runtime_id: opsImageId }, browser: { runtime_id: browserImageId } },
    browser: structuredClone(browser),
    artifacts: cases.flatMap((item) => item.images.map((image) => ({ path: image.path, sha256: image.sha256, present: true, copied: true, copy_status: "success" }))),
    preservation: {
      schema: "scrypath.ui-preservation.v1",
      product_source_sha: sourceSha,
      product_tree_sha256: productTreeSha,
      fixture_overlay_sha256: FIXTURE,
      cases
    },
    imageBytes
  };
}

function compare(before = runReceipt({ sourceSha: BEFORE_SHA, buildSha: BEFORE_BUILD_SHA, productTreeSha: BEFORE_TREE, appImageId: APP_BEFORE, opsImageId: OPS_BEFORE, browserImageId: BROWSER, sourceLayerId: BEFORE_SOURCE_LAYER }),
  candidate = runReceipt({ sourceSha: CANDIDATE_SHA, buildSha: CANDIDATE_BUILD_SHA, productTreeSha: CANDIDATE_TREE, appImageId: APP_CANDIDATE, opsImageId: OPS_CANDIDATE, browserImageId: BROWSER_CANDIDATE, sourceLayerId: CANDIDATE_SOURCE_LAYER }),
  expectedAuthority = authority()) {
  return pairs.compareValidatedBundles({
    authority: expectedAuthority,
    before,
    candidate,
    readImage: (_side, _item, receipt) => receipt.imageBytes
  });
}

test("source-paired comparator requires exact matched state receipt pairs", () => {
  assert.deepEqual(pairs.requiredCaseIds?.(), evidence.preservationCases.map(({ id }) => id));
  const report = compare();

  assert.equal(report.passed, true);
  assert.equal(report.comparisons.length, 61);
  assert.equal(report.comparisons.reduce((sum, item) => sum + item.viewport_comparisons.length, 0), 79);
  assert.ok(report.comparisons.filter((item) => item.id.endsWith("overflow")).every((item) => item.viewport_comparisons.map((viewport) => viewport.width).join(",") === "1440,768,390"));
  assert.equal(report.aesthetic_approval, "not-provided");
});

test("a source pair rejects missing, extra or duplicate preservation receipts", () => {
  const before = runReceipt({ sourceSha: BEFORE_SHA, productTreeSha: BEFORE_TREE, appImageId: APP_BEFORE });
  const candidate = runReceipt({ sourceSha: CANDIDATE_SHA, productTreeSha: CANDIDATE_TREE, appImageId: APP_CANDIDATE });
  candidate.preservation.cases.pop();
  assert.throws(() => compare(before, candidate), /exactly 61|missing.*case/i);

  candidate.preservation.cases = runReceipt({ sourceSha: CANDIDATE_SHA, productTreeSha: CANDIDATE_TREE, appImageId: APP_CANDIDATE }).preservation.cases;
  candidate.preservation.cases.push({ ...candidate.preservation.cases[0] });
  assert.throws(() => compare(before, candidate), /duplicate/i);
});

test("a source pair rejects independently mismatched source, fixture, runtime and recipe identities", () => {
  const mismatches = [
    (candidate) => { candidate.source.checkout_head = BEFORE_SHA; },
    (candidate) => { candidate.preservation.fixture_overlay_sha256 = `sha256:${"9".repeat(64)}`; },
    (candidate) => { candidate.preservation.cases[0].runtime.effective_runtime_sha256 = `sha256:${"9".repeat(64)}`; },
    (candidate) => { candidate.preservation.cases[0].recipe_sha256 = `sha256:${"9".repeat(64)}`; },
    (candidate) => { candidate.browser.version = "139.0.0.0"; }
  ];
  for (const mutate of mismatches) {
    const candidate = runReceipt({ sourceSha: CANDIDATE_SHA, productTreeSha: CANDIDATE_TREE, appImageId: APP_CANDIDATE });
    mutate(candidate);
    assert.throws(() => compare(undefined, candidate), /source|fixture|runtime|recipe|browser/i);
  }
  const unqualifiedRecipe = authority();
  unqualifiedRecipe.expected.recipe.font_profile.fixed_font_family = "Monospace";
  assert.throws(() => compare(undefined, undefined, unqualifiedRecipe), /qualified raster|font profile/);
});

test("a source pair fails exact pixels, geometry, state, copy and semantic assertions", () => {
  const changes = [
    (item) => { item.geometry[0].width += 1; },
    (item) => { item.state.focus.name = "different focus"; },
    (item) => { item.visible_copy[0].text = "different visible copy"; },
    (item) => { item.assertions[0].actual = "different assertion"; }
  ];
  for (const mutate of changes) {
    const candidate = runReceipt({ sourceSha: CANDIDATE_SHA, productTreeSha: CANDIDATE_TREE, appImageId: APP_CANDIDATE, mutateCase: mutate });
    const report = compare(undefined, candidate);
    assert.equal(report.passed, false);
  }

  const pixelChanged = runReceipt({ sourceSha: CANDIDATE_SHA, productTreeSha: CANDIDATE_TREE, appImageId: APP_CANDIDATE, imageBytes: png(21) });
  assert.equal(compare(undefined, pixelChanged).passed, false);
});

test("the fixed CLI accepts only the documented argv order", () => {
  assert.deepEqual(pairs.parseArgs([
    "compare", "--authority", "/tmp/authority.json", "--before", "/tmp/before/phase105-evidence.json",
    "--candidate", "/tmp/candidate/phase105-evidence.json", "--output", "/tmp/pair"
  ]), {
    authorityPath: "/tmp/authority.json",
    beforePath: "/tmp/before/phase105-evidence.json",
    candidatePath: "/tmp/candidate/phase105-evidence.json",
    outputDirectory: "/tmp/pair"
  });
  assert.throws(() => pairs.parseArgs(["compare", "--before", "/tmp/before.json"]), /Usage/);
});

test("authority loads only when its qualification bytes match the supplied digest", () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "scrypath-pair-authority-"));
  try {
    const value = authority();
    const repositoryRoot = path.resolve(__dirname, "../..");
    const inspectionPath = path.join(directory, "browser-inspection.json");
    const inspection = [{
      Id: value.qualification.browser_runtime.browser_image_id,
      RootFS: { Layers: ["sha256:1111111111111111111111111111111111111111111111111111111111111111", "sha256:2222222222222222222222222222222222222222222222222222222222222222"] },
      Config: { Labels: { "org.opencontainers.image.revision": BEFORE_SHA } },
      Architecture: "arm64", Os: "linux", DockerVersion: "27.0.0"
    }];
    fs.writeFileSync(inspectionPath, JSON.stringify(inspection));
    const qualifiedRuntime = build.phase185RuntimeIdentity({ inspectionPath, repoRoot: repositoryRoot });
    value.qualification.browser_runtime = qualifiedRuntime;
    value.expected.before.effective_runtime_sha256 = qualifiedRuntime.effective_runtime_sha256;
    value.expected.candidate.effective_runtime_sha256 = qualifiedRuntime.effective_runtime_sha256;
    value.expected.effective_runtime_sha256 = qualifiedRuntime.effective_runtime_sha256;
    value.expected.before.browser_base_layers_sha256 = qualifiedRuntime.browser_base_layers_sha256;
    value.expected.candidate.browser_base_layers_sha256 = qualifiedRuntime.browser_base_layers_sha256;
    value.expected.browser_base_layers_sha256 = qualifiedRuntime.browser_base_layers_sha256;
    value.qualification.browser_inspection_path = inspectionPath;
    value.qualification.capture_path = path.join(directory, "capture.json");
    const capture = {
      source: { source_sha: BEFORE_SHA },
      environment: structuredClone(value.qualification.environment)
    };
    const captureBytes = Buffer.from(JSON.stringify(capture));
    fs.writeFileSync(value.qualification.capture_path, captureBytes);
    const qualificationPath = path.join(directory, "qualification.json");
    value.qualification.record.actual_before_sha256 = digest(captureBytes);
    value.qualification.record.pinned_files = [
      { path: value.qualification.capture_path, sha256: digest(captureBytes) },
      { path: inspectionPath, sha256: digest(Buffer.from(JSON.stringify(inspection))) }
    ];
    const qualificationBytes = Buffer.from(`${JSON.stringify(value.qualification.record, null, 2)}\n`);
    fs.writeFileSync(qualificationPath, qualificationBytes);
    value.qualification.path = qualificationPath;
    value.qualification.sha256 = `sha256:${digest(qualificationBytes)}`;
    const authorityPath = path.join(directory, "authority.json");
    fs.writeFileSync(authorityPath, JSON.stringify(value));

    const loaded = pairs.loadAuthority(authorityPath);
    assert.equal(loaded.authority.expected.before.product_source_sha, BEFORE_SHA);
    assert.throws(() => pairs.loadAuthority(authorityPath.replace("authority.json", "missing.json")), /ENOENT/);

    value.qualification.sha256 = `sha256:${"9".repeat(64)}`;
    fs.writeFileSync(authorityPath, JSON.stringify(value));
    assert.throws(() => pairs.loadAuthority(authorityPath), /qualification file does not match/);
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});

test("receipt loading requires a complete recomputable evidence bundle", () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "scrypath-pair-receipt-"));
  try {
    const receiptPath = path.join(directory, "phase105-evidence.json");
    fs.writeFileSync(receiptPath, JSON.stringify({ schema_version: 1 }));
    assert.throws(() => pairs.loadReceiptBundle(receiptPath, "before", authority()), /not independently recomputable and eligible/);
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});

test("run PNG loading verifies path containment, raw hashes and decoded image bytes", () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "scrypath-pair-png-"));
  try {
    const relative = "ui-review-artifacts/iteration3-journeys/phase185-held-out/E1-empty.png";
    const absolute = path.join(directory, relative);
    fs.mkdirSync(path.dirname(absolute), { recursive: true });
    const bytes = png();
    fs.writeFileSync(absolute, bytes);
    const item = { id: "E1 empty", path: relative, sha256: digest(bytes) };

    assert.deepEqual(pairs.readBundledPng({ runRoot: directory }, item), bytes);
    assert.throws(() => pairs.readBundledPng({ runRoot: directory }, { ...item, sha256: "1".repeat(64) }), /raw SHA-256/);
    assert.throws(() => pairs.readBundledPng({ runRoot: directory }, { ...item, path: "../outside.png" }), /outside the held-out PNG bundle/);
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});

test("pair output is atomic, deterministic and never overwritten by different bytes", () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "scrypath-pair-output-"));
  try {
    const outputDirectory = path.join(directory, "comparison");
    const report = { schema: "scrypath.ui-state-pair-comparison.v2", status: "exact-match", cases_compared: 61 };
    const outputPath = pairs.writeOutput(outputDirectory, report);
    const original = fs.readFileSync(outputPath);

    assert.equal(pairs.writeOutput(outputDirectory, report), outputPath);
    assert.deepEqual(fs.readFileSync(outputPath), original);
    assert.throws(() => pairs.writeOutput(outputDirectory, { ...report, status: "mismatch" }), /refusing to overwrite/);
    assert.deepEqual(fs.readFileSync(outputPath), original);
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});
