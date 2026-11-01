"use strict";

const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");
const evidence = require("./ecommerce_evidence.cjs");
const pairs = require("./ui_state_pairs.cjs");
const { PNG } = require("../../examples/scrypath_ecommerce/node_modules/pngjs");

const BEFORE_SHA = "1".repeat(40);
const CANDIDATE_SHA = "2".repeat(40);
const BEFORE_TREE = `sha256:${"a".repeat(64)}`;
const CANDIDATE_TREE = `sha256:${"b".repeat(64)}`;
const FIXTURE = `sha256:${"c".repeat(64)}`;
const RUNTIME = `sha256:${"d".repeat(64)}`;
const BROWSER = `sha256:${"e".repeat(64)}`;
const APP_BEFORE = `sha256:${"f".repeat(64)}`;
const APP_CANDIDATE = `sha256:${"0".repeat(64)}`;
const PROFILE = `sha256:${"3".repeat(64)}`;
const CLOCK = `sha256:${"4".repeat(64)}`;
const DATA = `sha256:${"5".repeat(64)}`;

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

const browser = { engine: "chromium", version: "140.0.0.0", package: "@playwright/test", package_version: "1.54.2" };
const recipe = {
  browser,
  launch_args: ["--disable-partial-raster"],
  locale: "en-US",
  timezone: "UTC",
  device_scale_factor: 1,
  browser_date: { fixed: true, timers_running: true },
  font_profile: {
    method: "retained-cdp-fixed-font-v1",
    fixed_font_family: "Liberation Mono",
    applied: "before-first-navigation",
    lifetime: "page-context"
  },
  profile_sha256: PROFILE,
  clock_sha256: CLOCK,
  data_recipe_sha256: DATA
};
const recipeSha = `sha256:${digest(Buffer.from(JSON.stringify(canonical(recipe))))}`;

function authority() {
  return {
    schema: "scrypath.ui-state-pair-authority.v1",
    qualification: {
      path: "/private/tmp/plan05-qualification.json",
      sha256: `sha256:${"6".repeat(64)}`,
      record: {
        schema: "scrypath.phase185-before-qualification.v1",
        status: "qualified",
        source_sha: BEFORE_SHA,
        browser_runtime_equivalence: { rootfs_layers_equal: true, effective_config_equal: true, source_sha: BEFORE_SHA, actual_image_id: BROWSER }
      }
    },
    expected: {
      before: { source_sha: BEFORE_SHA, product_tree_sha256: BEFORE_TREE, application_image_id: APP_BEFORE },
      candidate: { source_sha: CANDIDATE_SHA, product_tree_sha256: CANDIDATE_TREE, application_image_id: APP_CANDIDATE },
      fixture_overlay_sha256: FIXTURE,
      effective_runtime_sha256: RUNTIME,
      browser_image_id: BROWSER,
      recipe: structuredClone(recipe)
    }
  };
}

function png(color = 20) {
  const image = new PNG({ width: 1, height: 1 });
  image.data.set([color, 30, 40, 255]);
  return PNG.sync.write(image);
}

function runReceipt({ sourceSha, productTreeSha, appImageId, imageBytes = png(), mutateCase } = {}) {
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
    const image = { path: `ui-review-artifacts/iteration3-journeys/phase185-held-out/${entry.id.replaceAll(" ", "-")}.png`, sha256: digest(imageBytes) };
    const item = {
      id: entry.id,
      test_identity: JSON.stringify([entry.file, "chromium", [path.posix.basename(entry.file), `${entry.id} held-out assertion`], "shared"]),
      source_sha: sourceSha,
      product_tree_sha256: productTreeSha,
      fixture_overlay_sha256: FIXTURE,
      recipe_sha256: recipeSha,
      runtime: { application_image_id: appImageId, browser_image_id: BROWSER, effective_runtime_sha256: RUNTIME },
      state,
      actions: ["navigate", "observe"],
      transport_sequence: [{ operation: "liveview-connected", outcome: "connected" }],
      geometry: [{ name: `element-${entry.element}`, x: 0, y: 0, width: 100, height: 20 }],
      assertions: [{ name: `assert-${entry.id}`, status: "passed", actual: `observed-${entry.id}` }],
      visible_copy: [{ text: `Visible ${entry.id}`, sha256: digest(Buffer.from(`Visible ${entry.id}`)) }],
      image
    };
    return mutateCase?.(item) || item;
  });
  return {
    eligibility: { eligible: true },
    source: { checkout_head: sourceSha },
    images: { application: { runtime_id: appImageId }, browser: { runtime_id: BROWSER } },
    browser: structuredClone(browser),
    artifacts: cases.map((item) => ({ path: item.image.path, sha256: item.image.sha256, present: true, copied: true, copy_status: "success" })),
    preservation: {
      schema: "scrypath.ui-preservation.v1",
      product_tree_sha256: productTreeSha,
      fixture_overlay_sha256: FIXTURE,
      cases
    },
    imageBytes
  };
}

function compare(before = runReceipt({ sourceSha: BEFORE_SHA, productTreeSha: BEFORE_TREE, appImageId: APP_BEFORE }),
  candidate = runReceipt({ sourceSha: CANDIDATE_SHA, productTreeSha: CANDIDATE_TREE, appImageId: APP_CANDIDATE }),
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
    const qualificationPath = path.join(directory, "qualification.json");
    const qualificationBytes = Buffer.from(`${JSON.stringify(value.qualification.record, null, 2)}\n`);
    fs.writeFileSync(qualificationPath, qualificationBytes);
    value.qualification.path = qualificationPath;
    value.qualification.sha256 = `sha256:${digest(qualificationBytes)}`;
    const authorityPath = path.join(directory, "authority.json");
    fs.writeFileSync(authorityPath, JSON.stringify(value));

    const loaded = pairs.loadAuthority(authorityPath);
    assert.equal(loaded.authority.expected.before.source_sha, BEFORE_SHA);
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
    const item = { id: "E1 empty", image: { path: relative, sha256: digest(bytes) } };

    assert.deepEqual(pairs.readBundledPng({ runRoot: directory }, item), bytes);
    assert.throws(() => pairs.readBundledPng({ runRoot: directory }, { ...item, image: { ...item.image, sha256: `sha256:${"1".repeat(64)}` } }), /raw SHA-256/);
    assert.throws(() => pairs.readBundledPng({ runRoot: directory }, { ...item, image: { ...item.image, path: "../outside.png" } }), /outside the held-out PNG bundle/);
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});

test("pair output is atomic, deterministic and never overwritten by different bytes", () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "scrypath-pair-output-"));
  try {
    const outputDirectory = path.join(directory, "comparison");
    const report = { schema: "scrypath.ui-state-pair-comparison.v1", status: "exact-match", cases_compared: 61 };
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
