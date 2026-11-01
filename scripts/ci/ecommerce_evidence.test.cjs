"use strict";

const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");
const { PNG } = require("../../examples/scrypath_ecommerce/node_modules/pngjs");
const rawBundle = require("./ui_preservation_bundle.cjs");

let evidence = {};
try {
  evidence = require("./ecommerce_evidence.cjs");
} catch (error) {
  if (error.code !== "MODULE_NOT_FOUND") throw error;
}

function testCase({ file = "e2e/example.spec.ts", project = "chromium", title, expectedStatus = "passed", suiteTitle }) {
  return { file, project, title, expectedStatus, suiteTitle };
}

function playwrightReport(cases, { results = false, errors = [] } = {}) {
  return {
    config: { rootDir: "." }, errors,
    suites: cases.map((item) => ({
      title: item.suiteTitle || "e2e", suites: [],
      specs: [{ title: item.title, file: item.file, tests: [{
        projectName: item.project, expectedStatus: item.expectedStatus,
        ...(results ? { status: item.status || "passed", results: item.results || [{ retry: 0, status: item.status || "passed", duration: 1 }] } : {})
      }] }]
    }))
  };
}

function reconcile(inventoryCases, resultCases = inventoryCases, options = {}) {
  return evidence.reconcileInventory?.({
    inventory: playwrightReport(inventoryCases),
    report: playwrightReport(resultCases, { results: true, errors: options.errors || [] }),
    repoRoot: path.resolve(__dirname, "../.."),
    allowedSkips: options.allowedSkips || []
  });
}

test("one legitimate Playwright-shaped case reconciles by full identity", () => {
  const cases = [testCase({ title: "task help stays within the installed mount" })];
  const result = reconcile(cases);

  assert.equal(result?.eligible, true);
  assert.equal(result?.cases.length, 1);
  assert.deepEqual(result?.cases[0].attempts.map(({ retry, status }) => ({ retry, status })), [
    { retry: 0, status: "passed" }
  ]);
});

test("adjacent same-title cases remain distinct across file, project, and entrypoint", () => {
  const cases = [
    testCase({ file: "e2e/one.spec.ts", title: "same title" }),
    testCase({ file: "e2e/two.spec.ts", title: "same title" }),
    testCase({ file: "e2e/one.spec.ts", project: "firefox", title: "same title" }),
    testCase({ file: "e2e/phase173_shell.spec.ts", title: "mounted: same title" }),
    testCase({ file: "e2e/phase173_shell.spec.ts", title: "standalone: same title" })
  ];
  const result = reconcile(cases);
  const identities = cases.map((item) =>
    evidence.caseIdentity?.({
      file: item.file,
      project: item.project,
      title_path: [item.title],
      entrypoint: item.file.includes("phase173_shell") ? item.title.split(":")[0] : "shared"
    })
  );

  assert.equal(result?.eligible, true);
  assert.equal(result?.cases.length, 5);
  assert.equal(new Set(identities.map((identity) => identity?.key)).size, 5);
  assert.deepEqual(
    identities.slice(-2).map((identity) => identity?.entrypoint),
    ["mounted", "standalone"]
  );
});

test("an identical composite inventory identity is rejected", () => {
  const duplicate = testCase({ file: "e2e/one.spec.ts", project: "chromium", title: "same title" });
  const result = reconcile([duplicate, duplicate]);

  assert.equal(result?.eligible, false);
  assert.ok(result?.reasons.some((reason) => reason.code === "duplicate_inventory_identity"));
});

test("an identical composite report identity is rejected", () => {
  const item = testCase({ title: "same title" });
  const report = playwrightReport([item, item], { results: true });
  const result = evidence.reconcileInventory?.({
    inventory: playwrightReport([item]),
    report,
    repoRoot: path.resolve(__dirname, "../..")
  });

  assert.equal(result?.eligible, false);
  assert.ok(result?.reasons.some((reason) => reason.code === "duplicate_report_identity"));
});

test("report ordering does not change set equality or attempts", () => {
  const cases = [testCase({ title: "first" }), testCase({ title: "second" })];
  const forward = reconcile(cases, cases);
  const reverse = reconcile(cases, [...cases].reverse());

  assert.equal(forward?.eligible, true);
  assert.deepEqual(reverse, forward);
});

test("missing, null, malformed, and empty inventory or result reports reject", () => {
  const item = testCase({ title: "one case" });
  const validInventory = playwrightReport([item]);
  const validReport = playwrightReport([item], { results: true });
  const invalidPairs = [
    [null, validReport],
    [{ suites: [] }, validReport],
    [validInventory, null],
    [validInventory, { suites: [] }],
    [validInventory, { suites: "malformed" }],
    [validInventory, { ...validReport, errors: [{ message: "report error" }] }]
  ];

  for (const [inventory, report] of invalidPairs) {
    const result = evidence.reconcileInventory?.({ inventory, report, repoRoot: path.resolve(__dirname, "../..") });
    assert.equal(result?.eligible, false);
    assert.ok(result?.reasons.length > 0);
  }
});

test("missing attempts, skips, retry passes, and expected-failure masking reject clean proof", () => {
  const item = testCase({ title: "required case" });
  const inventory = playwrightReport([item]);
  const variations = [
    playwrightReport([{ ...item, status: "passed", results: [] }], { results: true }),
    playwrightReport([{ ...item, status: "skipped", results: [] }], { results: true }),
    playwrightReport([{ ...item, results: [{ retry: 1, status: "passed" }] }], { results: true }),
    playwrightReport(
      [{ ...item, expectedStatus: "failed", status: "expected", results: [{ retry: 0, status: "failed" }] }],
      { results: true }
    )
  ];

  for (const report of variations) {
    const result = evidence.reconcileInventory?.({
      inventory,
      report,
      repoRoot: path.resolve(__dirname, "../..")
    });
    assert.equal(result?.eligible, false);
    assert.ok(result?.reasons.length > 0);
  }
});

test("an intentional skip needs an identity-scoped reason and never becomes a clean pass", () => {
  const item = testCase({ title: "optional case" });
  const inventory = playwrightReport([item]);
  const report = playwrightReport([{ ...item, status: "skipped", results: [] }], { results: true });
  const unexplained = evidence.reconcileInventory?.({ inventory, report, repoRoot: path.resolve(__dirname, "../..") });
  const key = evidence.caseIdentity?.({
    file: item.file,
    project: item.project,
    title_path: ["e2e", item.title],
    entrypoint: "shared"
  })?.key;
  const explained = evidence.reconcileInventory?.({
    inventory,
    report,
    repoRoot: path.resolve(__dirname, "../.."),
    allowedSkips: [{ identity: key, reason: "external fixture is unavailable" }]
  });

  assert.ok(unexplained?.reasons.some((reason) => reason.code === "unexplained_skip"));
  assert.equal(explained?.eligible, false);
  assert.ok(explained?.reasons.some((reason) => reason.code === "intentional_skip_not_clean"));
});

test("malformed and zero-case CLI reports exit nonzero", () => {
  const runDir = fs.mkdtempSync(path.join(os.tmpdir(), "scrypath-evidence-cli-"));
  try {
    fs.writeFileSync(path.join(runDir, "phase105-playwright-list.json"), JSON.stringify({ suites: [] }));
    fs.writeFileSync(path.join(runDir, "phase105-playwright.json"), JSON.stringify({ suites: [] }));
    const result = spawnSync(
      process.execPath,
      [path.join(__dirname, "ecommerce_evidence.cjs"), "reconcile", "--run-dir", runDir],
      { encoding: "utf8" }
    );

    assert.notEqual(result.status, 0);
  } finally {
    fs.rmSync(runDir, { recursive: true, force: true });
  }
});

const UNIT_TEST_PNGS = new Map([1440, 768, 390].map((width) => {
  const image = new PNG({ width, height: width === 390 ? 844 : 900 });
  for (let pixel = 0; pixel < image.data.length; pixel += 4) image.data.set([30, 40, 50, 255], pixel);
  return [width, PNG.sync.write(image)];
}));

const SOURCE_SHA = "a".repeat(40);
const IMAGE_ID = `sha256:${"b".repeat(64)}`;

function tokenContrastReport({ aaFails = 0, advisories = 1, passes = 0 } = {}) {
  const findings = [
    ...Array.from({ length: aaFails }, () => ({ severity: "aa-fail", producer: "token", pass_aa: false })),
    ...Array.from({ length: advisories }, () => ({ severity: "aaa-body-advisory", producer: "token", pass_aa: true })),
    ...Array.from({ length: passes }, () => ({ severity: "pass", producer: "token", pass_aa: true }))
  ];
  return {
    schema: "scrypath.contrast.v1",
    producer: "token",
    generated: "2026-10-26T23:00:00.000Z",
    summary: { aa_fail: aaFails, aaa_advisory: advisories, total: findings.length },
    findings
  };
}

function completeReceiptCases() {
  return [
    testCase({ file: "e2e/ui_followup.spec.ts", suiteTitle: "ui_followup.spec.ts", title: "active, backend-failed, retrying and completed observations have distinct useful states" }),
    testCase({ file: "e2e/ui_followup.spec.ts", suiteTitle: "ui_followup.spec.ts", title: "generic fields remain readable across compact themes without guessing data types" }),
    testCase({ file: "e2e/ui_followup.spec.ts", suiteTitle: "ui_followup.spec.ts", title: "mounted: copy feedback leaves timestamp and refresh geometry unchanged" }),
    testCase({ file: "e2e/ui_followup.spec.ts", suiteTitle: "ui_followup.spec.ts", title: "multi-schema result limit applies to the combined response and help is local" }),
    testCase({ file: "e2e/ui_followup.spec.ts", suiteTitle: "ui_followup.spec.ts", title: "readable results retain submitted criteria, copy exact data and lead to the saved file" }),
    testCase({ file: "e2e/ui_followup.spec.ts", suiteTitle: "ui_followup.spec.ts", title: "standalone: copy feedback leaves timestamp and refresh geometry unchanged" }),
    testCase({ file: "e2e/ui_followup.spec.ts", suiteTitle: "ui_followup.spec.ts", title: "task help stays within the installed mount and explains saved inputs" }),
    testCase({ file: "e2e/ui_iteration3.spec.ts", suiteTitle: "ui_iteration3.spec.ts", title: "combined results are one compact backend-ordered list with real page traversal and complete copyable source data" }),
    testCase({ file: "e2e/ui_iteration3.spec.ts", suiteTitle: "ui_iteration3.spec.ts", title: "contextual help opens at a visible heading in a new tab and preserves the task" }),
    testCase({ file: "e2e/ui_iteration3.spec.ts", suiteTitle: "ui_iteration3.spec.ts", title: "health stages align, icons are consistent, refresh is singular and settings explain missing filters" }),
    testCase({ file: "e2e/ui_iteration3.spec.ts", suiteTitle: "ui_iteration3.spec.ts", title: "limits validate on blur, correct inline and preserve the previous run on invalid submission" }),
    testCase({ file: "e2e/ui_iteration3.spec.ts", suiteTitle: "ui_iteration3.spec.ts", title: "one purposeful zero-match state and no duplicate per-schema empty cards" }),
    testCase({ file: "e2e/ui_iteration3.spec.ts", suiteTitle: "ui_iteration3.spec.ts", title: "Save sits by Run, validates the name and offers Save and Save as after edits" }),
    testCase({ file: "e2e/phase173_shell.spec.ts", suiteTitle: "phase173_shell.spec.ts", title: "mounted shell renders light preference" }),
    testCase({ file: "e2e/phase173_shell.spec.ts", suiteTitle: "phase173_shell.spec.ts", title: "standalone shell renders light preference" }),
    ...evidence.preservationCases.map(({ id, file }) => testCase({
      file,
      suiteTitle: path.posix.basename(file),
      title: `${id} preserves held-out content and state`
    }))
  ];
}

function stage(startedAt, endedAt, exitCode = 0) {
  return { started_at: startedAt, ended_at: endedAt, exit_code: exitCode };
}

const QUALIFICATION_SHA256 = `sha256:${"d".repeat(64)}`;

function createQualifiedSourceRepo({ separateOverlayCommit = false } = {}) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "scrypath-qualified-source-"));
  const git = (...args) => {
    const result = spawnSync("git", ["-C", root, ...args], { encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
    return result.stdout.trim();
  };
  const writeFiles = (files, label) => {
    for (const relative of files) {
      const absolute = path.join(root, relative);
      fs.mkdirSync(path.dirname(absolute), { recursive: true });
      fs.writeFileSync(absolute, `${label}:${relative}\n`);
    }
  };
  const addRepoContent = () => git("add", "--", ...["examples", "scrypath_ops", "scripts"].filter((directory) => fs.existsSync(path.join(root, directory))));

  try {
    git("init", "-q");
    git("config", "user.name", "Scrypath Test");
    git("config", "user.email", "scrypath-test@example.invalid");
    writeFiles(evidence.productSourceRoots.map((directory) => `${directory}/identity.txt`), "product");
    if (!separateOverlayCommit) writeFiles(evidence.preservationFixtureFiles, "overlay");
    addRepoContent();
    git("commit", "-qm", separateOverlayCommit ? "qualified product source" : "qualified product and harness source");
    const productSha = git("rev-parse", "HEAD");
    if (separateOverlayCommit) {
      writeFiles(evidence.preservationFixtureFiles, "overlay");
      addRepoContent();
      git("commit", "-qm", "test-only harness overlay");
    }
    const buildSha = git("rev-parse", "HEAD");
    return {
      root,
      productSha,
      buildSha,
      productTreeSha256: evidence.productTreeIdentity(root, productSha),
      fixtureOverlaySha256: evidence.fixtureOverlayDigest(root, buildSha)
    };
  } catch (error) {
    fs.rmSync(root, { recursive: true, force: true });
    throw error;
  }
}

function createCompleteRun({ beforeOnly = false, sourceSha = SOURCE_SHA, buildSourceSha = sourceSha, productTreeSha256, fixtureOverlaySha256, qualificationSha256 = QUALIFICATION_SHA256, looseImages = false } = {}) {
  const runDir = fs.mkdtempSync(path.join(os.tmpdir(), "scrypath-evidence-run-"));
  const allCases = completeReceiptCases();
  const cases = beforeOnly ? allCases.filter((item) => /ui_(state|content)_preservation/.test(item.file)) : allCases;
  const image = { built_id: IMAGE_ID, runtime_id: IMAGE_ID, source_sha: buildSourceSha };
  const manifest = {
    schema_version: 1,
    source: {
      mode: "hosted",
      checkout_head: buildSourceSha,
      product_source_sha: sourceSha,
      product_tree_sha256: null,
      fixture_overlay_sha256: null,
      dirty: false,
      event_sha: buildSourceSha,
      built_source_sha: buildSourceSha,
      ...(beforeOnly ? { qualification_sha256: qualificationSha256 } : {})
    },
    images: { application: { ...image }, standalone_ops: { built_id: IMAGE_ID, runtime_id: IMAGE_ID }, browser: { ...image } },
    compose: {
      scope: "full",
      project: "scrypath_ecommerce_verify_phase182",
      targets: ["web", "standalone_ops"],
      model_digest: `sha256:${"c".repeat(64)}`
    },
    browser: { engine: "chromium", version: "140.0.0.0", package: "@playwright/test", package_version: "1.54.2" },
    workflow: {
      event: "workflow_dispatch",
      ref: "refs/heads/worktree-agent-p182-03",
      sha: buildSourceSha,
      run_id: "123456789",
      run_attempt: 1,
      job_name: "phase105-e2e",
      job_conclusion: "success"
    },
    stages: {
      inventory: stage("2026-10-26T23:00:00.000Z", "2026-10-26T23:00:01.000Z"),
      browser: stage("2026-10-26T23:00:02.000Z", "2026-10-26T23:01:02.000Z"),
      light_parity: stage("2026-10-26T23:01:03.000Z", "2026-10-26T23:01:04.000Z"),
      contrast: stage("2026-10-26T23:01:05.000Z", "2026-10-26T23:01:06.000Z"),
      artifact_copy: stage("2026-10-26T23:01:07.000Z", "2026-10-26T23:01:08.000Z")
    },
    checkers: {
      light_parity: { path: "admin-light-parity.json", status: "pass" },
      contrast: { path: "contrast-report.json", status: "pass" }
    },
    cleanup: { status: "clean", project: "scrypath_ecommerce_verify_phase182", containers: 0, networks: 0, volumes: 0 },
    artifacts: [
      {
        path: "ui-review-artifacts/iteration3-journeys/iteration3-proof.png",
        required: true,
        copied: true,
        copy_status: "success"
      },
      { path: "ui-review-artifacts/iteration3-journeys/phase185-held-out/phase185-clock.txt", required: true, copied: true, copy_status: "success" }
    ],
    allowed_skips: [],
    first_failure: null
  };

  fs.mkdirSync(path.join(runDir, "playwright-report"), { recursive: true });
  fs.mkdirSync(path.join(runDir, "ui-review-artifacts/iteration3-journeys"), { recursive: true });
  fs.mkdirSync(path.join(runDir, "ui-review-artifacts/iteration3-journeys/phase185-held-out"), { recursive: true });
  fs.writeFileSync(path.join(runDir, "phase105-playwright-list.json"), JSON.stringify(playwrightReport(cases)));
  fs.writeFileSync(path.join(runDir, "phase105-playwright.json"), JSON.stringify(playwrightReport(cases, { results: true })));
  const evidenceEvents = [{ operation: "seed" }];
  const repositoryRoot = path.resolve(__dirname, "../..");
  const productTreeSha = productTreeSha256 || evidence.productTreeIdentity(repositoryRoot);
  const fixtureOverlaySha = fixtureOverlaySha256 || evidence.fixtureOverlayDigest(repositoryRoot);
  manifest.source.product_tree_sha256 = productTreeSha;
  manifest.source.fixture_overlay_sha256 = fixtureOverlaySha;
  const clockBytes = Buffer.from("2026-10-31T12:00:00.000Z", "utf8");
  const clockSha = `sha256:${crypto.createHash("sha256").update(clockBytes).digest("hex")}`;
  const clockPath = "ui-review-artifacts/iteration3-journeys/phase185-held-out/phase185-clock.txt";
  fs.writeFileSync(path.join(runDir, clockPath), clockBytes);
  const canonicalize = (value) => Array.isArray(value) ? value.map(canonicalize) : value && typeof value === "object"
    ? Object.fromEntries(Object.keys(value).sort().map((key) => [key, canonicalize(value[key])])) : value;
  const hashJson = (value) => `sha256:${crypto.createHash("sha256").update(JSON.stringify(canonicalize(value))).digest("hex")}`;
  const browserRecipe = { engine: "chromium", version: "140.0.0.0", package: "@playwright/test", package_version: "1.54.2" };
  const fontProfile = { method: "retained-cdp-fixed-font-v1", fixed_font_family: "Liberation Mono", applied: "before-first-navigation", lifetime: "page-context" };
  const profileSetup = { method: "retained-cdp-fixed-font-v1", font_families: { fixed: "Liberation Mono" }, applied: "before-first-navigation", lifetime: "page-context" };
  const dataRecipe = { protocol: "phase185-heldout-deterministic-data-v1", seed_endpoint: "/dev/e2e/seed", operational_scenarios: ["all_green", "degraded", "incident", "empty"], saved_search_prefix: "phase185-heldout-", clock_sha256: clockSha };
  const profileRecipe = { browser: browserRecipe, launch_args: ["--disable-partial-raster"], locale: "en-US", timezone: "UTC", device_scale_factor: 1, font_profile: fontProfile, font_profile_setup: profileSetup };
  const profileSha = hashJson(profileRecipe);
  const dataRecipeSha = hashJson(dataRecipe);
  const clockRecipe = { ...profileRecipe, browser_date: { fixed: true, timers_running: true, timer_elapsed_ms: 40, observed: "2026-10-31T12:00:00.000Z" }, clock_sha256: clockSha, profile_sha256: profileSha, data_recipe_sha256: dataRecipeSha };
  const sharedRecipe = structuredClone(clockRecipe);
  delete sharedRecipe.browser_date.timer_elapsed_ms;
  const recipeSha = hashJson(sharedRecipe);
  const runtime = {
    application_image_id: IMAGE_ID,
    standalone_ops_image_id: IMAGE_ID,
    browser_image_id: IMAGE_ID,
    effective_runtime_sha256: `sha256:${"d".repeat(64)}`,
    browser_source_layer_id: `sha256:${"1".repeat(64)}`,
    browser_base_layers_sha256: `sha256:${"2".repeat(64)}`
  };
  const imageArtifacts = [];
  for (const preservationCase of evidence.preservationCases) {
    const title = `${preservationCase.id} preserves held-out content and state`;
    const identity = evidence.caseIdentity({
      file: preservationCase.file,
      project: "chromium",
      title_path: [path.posix.basename(preservationCase.file), title]
    });
    const matrix = preservationCase.category === "overflow" || preservationCase.category === "long-text"
      ? ["light", "dark", "system-dark"].flatMap((theme) => [1440, 768, 390].map((width) => ({ theme, width })))
      : [{ theme: "light", width: 1440 }];
    const observations = matrix.map(({ theme, width }) => {
      const height = width === 390 ? 844 : 900;
      const pngBytes = UNIT_TEST_PNGS.get(width);
      const imagePath = `ui-review-artifacts/iteration3-journeys/phase185-held-out/${preservationCase.id.replaceAll(" ", "-").toLowerCase()}-${theme}-${width}.png`;
      fs.writeFileSync(path.join(runDir, imagePath), pngBytes);
      imageArtifacts.push({ path: imagePath, required: true, copied: true, copy_status: "success" });
      const copyText = `TEST_FIXTURE_ONLY_NOT_A_REAL_${preservationCase.id.replaceAll(" ", "_")}_${theme}_${width}_CAPTURE`;
      const state = {
        element: preservationCase.element,
        category: preservationCase.category,
        route: "/",
        theme,
        color_scheme: theme === "light" ? "light" : "dark",
        viewport: { width, height },
        scroll: { x: 0, y: 0 },
        focus: { name: `TEST_FIXTURE_ONLY_${theme}_${width}` },
        data_identity: "TEST_FIXTURE_ONLY_NOT_A_REAL_CAPTURE",
        clock: { browser_iso: "2026-10-31T12:00:00.000Z", server_iso: "2026-10-31T12:00:00.000Z", clock_sha256: clockSha }
      };
      return {
        theme, viewport: { width, height }, state,
        geometry: [{ name: `case-target-${width}`, x: 0, y: 0, width: 100, height: 20, viewport_width: width }, { name: `document-${width}`, x: 0, y: 0, width, height, viewport_width: width }],
        assertions: [{ name: `assert-${preservationCase.id}-${theme}-${width}`, status: "passed", actual: "TEST_FIXTURE_ONLY" }],
        visible_copy: [{ text: copyText, sha256: crypto.createHash("sha256").update(copyText).digest("hex") }],
        capture_sampling: { method: "consecutive-exact-v1", max_samples: 6, max_elapsed_ms: 10000, selected: 1, samples: [0, 1].map((index) => ({ path: `test-sample-${index}.png`, state_path: `test-sample-${index}.json`, sha256: crypto.createHash("sha256").update(pngBytes).digest("hex"), state_sha256: "a".repeat(64), elapsed_ms: 10 + index })) },
        image: { path: imagePath, sha256: crypto.createHash("sha256").update(pngBytes).digest("hex"), viewport: { width, height }, full_page_raster: { width, height }, capture: "full-page-real-product-state" }
      };
    });
    evidenceEvents.push({
      operation: "ui_preservation_case",
      case_id: preservationCase.id,
      test_identity: identity.key,
      product_source_sha: sourceSha,
      build_source_sha: buildSourceSha,
      product_tree_sha256: productTreeSha,
      fixture_overlay_sha256: fixtureOverlaySha,
      runtime,
      recipe_sha256: recipeSha,
      clock_recipe: clockRecipe,
      data_recipe: dataRecipe,
      clock_artifact: { path: clockPath, sha256: crypto.createHash("sha256").update(clockBytes).digest("hex") },
      actions: ["TEST_FIXTURE_ONLY"],
      transport_sequence: [{ operation: "TEST_FIXTURE_ONLY", outcome: "TEST_FIXTURE_ONLY" }],
      observations
    });
  }
  if (looseImages) manifest.artifacts.push(...imageArtifacts);
  else {
    const members = imageArtifacts.map(({ path: relative }) => ({ path: relative, bytes: fs.readFileSync(path.join(runDir, relative)) }));
    rawBundle.writeExclusive(path.join(runDir, rawBundle.BUNDLE_PATH), members);
    manifest.artifacts.push({ path: rawBundle.BUNDLE_PATH, required: true, copied: true, copy_status: "success" });
  }
  fs.writeFileSync(path.join(runDir, "phase105-evidence.ndjson"), `${evidenceEvents.map((event) => JSON.stringify(event)).join("\n")}\n`);
  fs.writeFileSync(path.join(runDir, "admin-light-parity.json"), JSON.stringify({ status: "pass", missing: [], extra: [], width_mismatches: [] }));
  fs.writeFileSync(path.join(runDir, "contrast-report.json"), JSON.stringify(tokenContrastReport()));
  fs.writeFileSync(path.join(runDir, "lifecycle.json"), JSON.stringify({ cleanup: { ...manifest.cleanup } }));
  fs.writeFileSync(path.join(runDir, "playwright-report/index.html"), "<html>complete report</html>\n");
  fs.writeFileSync(path.join(runDir, "ui-review-artifacts/iteration3-journeys/iteration3-proof.png"), "synthetic screenshot fixture\n");
  fs.writeFileSync(path.join(runDir, "phase105-evidence-input.json"), `${JSON.stringify(manifest, null, 2)}\n`);
  return { runDir, manifest };
}

function updateRunManifest(runDir, update) {
  const file = path.join(runDir, "phase105-evidence-input.json");
  const manifest = JSON.parse(fs.readFileSync(file, "utf8"));
  update(manifest);
  fs.writeFileSync(file, `${JSON.stringify(manifest, null, 2)}\n`);
}

test("ordinary full rejects loose preservation PNGs without its bounded raw bundle", () => {
  const fixture = createCompleteRun({ looseImages: true });
  try {
    const receipt = evidence.writeEvidence({ runDir: fixture.runDir });
    if (receipt.eligibility.eligible !== false || !receipt.reasons.some((reason) => reason.code === "missing_preservation_bundle")) {
      throw new Error("MISSING_PRESERVATION_BUNDLE_WAS_ACCEPTED: loose per-case PNGs cannot replace the bounded raw bundle");
    }
  } finally { fs.rmSync(fixture.runDir, { recursive: true, force: true }); }
});

test("one aggregate binds exact source, reports, checkers, artifacts and derived summary", () => {
  const { runDir } = createCompleteRun();
  try {
    const receipt = evidence.writeEvidence?.({ runDir });

    assert.equal(receipt?.eligibility.eligible, true, JSON.stringify(receipt?.reasons));
    assert.equal(receipt?.eligibility.clean, true);
    assert.equal(receipt?.eligibility.class, "hosted-exact-sha");
    assert.equal(receipt?.cases.length, 76);
    assert.equal(receipt?.preservation?.cases.length, 61);
    assert.equal(Object.keys(receipt).some(key => key.startsWith("visual_judge_")), false);
    assert.equal(receipt?.workflow.sha, receipt?.source.event_sha);
    assert.equal(receipt?.source.event_sha, receipt?.source.checkout_head);
    assert.equal(receipt?.images.application.built_id, receipt?.images.application.runtime_id);
    assert.equal(receipt?.images.browser.built_id, receipt?.images.browser.runtime_id);
    assert.deepEqual(receipt?.checkers.contrast, {
      path: "contrast-report.json",
      status: "pass",
      outcome: "success",
      missing: null,
      extra: null,
      width_mismatches: null,
      aa_fail: 0,
      total: 1
    });
    assert.ok(receipt?.artifacts.every((artifact) => artifact.present && artifact.sha256));
    assert.deepEqual(JSON.parse(fs.readFileSync(path.join(runDir, "phase105-evidence.json"), "utf8")), receipt);
    assert.equal(
      fs.readFileSync(path.join(runDir, "phase105-evidence-summary.md"), "utf8"),
      evidence.renderSummary?.(receipt)
    );
    assert.equal(evidence.validateReceipt?.({ runDir }).valid, true);

    const cli = spawnSync(
      process.execPath,
      [path.join(__dirname, "ecommerce_evidence.cjs"), "validate-receipt", "--run-dir", runDir],
      { encoding: "utf8" }
    );
    assert.equal(cli.status, 0, cli.stderr);

    const summaryPath = path.join(runDir, "phase105-evidence-summary.md");
    fs.writeFileSync(summaryPath, fs.readFileSync(summaryPath, "utf8").replace("eligibility: pass", "eligibility: fail"));
    const mismatchedSummary = evidence.validateReceipt?.({ runDir });
    assert.equal(mismatchedSummary?.valid, false);
    assert.ok(mismatchedSummary?.reasons.some((reason) => reason.code === "summary_mismatch"));
  } finally {
    fs.rmSync(runDir, { recursive: true, force: true });
  }
});

test("independent pair authority can revalidate a source-bound bundle after checkout changes", () => {
  const source = createQualifiedSourceRepo();
  const expectedSource = {
    sourceSha: source.productSha,
    buildSourceSha: source.buildSha,
    productTreeSha256: source.productTreeSha256,
    fixtureOverlaySha256: source.fixtureOverlaySha256
  };
  const { runDir } = createCompleteRun({
    sourceSha: source.productSha,
    buildSourceSha: source.buildSha,
    productTreeSha256: source.productTreeSha256,
    fixtureOverlaySha256: source.fixtureOverlaySha256
  });
  try {
    const written = evidence.writeEvidence({ runDir, expectedSource, repoRoot: source.root });
    fs.writeFileSync(path.join(source.root, evidence.productSourceRoots[0], "identity.txt"), "comparator checkout drift\n");
    const verified = evidence.validateReceipt({ runDir, expectedSource, repoRoot: source.root });
    const wrongSource = evidence.validateReceipt({ runDir, expectedSource: { ...expectedSource, sourceSha: "b".repeat(40) }, repoRoot: source.root });

    assert.equal(written.eligibility.eligible, true, JSON.stringify(written.reasons));
    assert.equal(verified.valid, true);
    assert.equal(verified.eligible, true);
    assert.equal(wrongSource.valid, false);
    assert.ok(wrongSource.reasons.some((reason) => reason.code === "receipt_mismatch"));
  } finally {
    fs.rmSync(runDir, { recursive: true, force: true });
    fs.rmSync(source.root, { recursive: true, force: true });
  }
});

test("product tree identity can be recomputed from a pinned Git object after the worktree changes", () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "scrypath-product-tree-object-"));
  const productRoots = [
    "examples/scrypath_ecommerce/assets",
    "examples/scrypath_ecommerce/config",
    "examples/scrypath_ecommerce/lib",
    "scrypath_ops/assets",
    "scrypath_ops/config",
    "scrypath_ops/lib"
  ];
  const git = (...args) => {
    const result = spawnSync("git", ["-C", root, ...args], { encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
    return result.stdout.trim();
  };

  try {
    for (const directory of productRoots) {
      const absolute = path.join(root, directory, "identity.txt");
      fs.mkdirSync(path.dirname(absolute), { recursive: true });
      fs.writeFileSync(absolute, `qualified:${directory}\n`);
    }
    git("init", "-q");
    git("config", "user.name", "Scrypath Test");
    git("config", "user.email", "scrypath-test@example.invalid");
    git("add", "--", "examples", "scrypath_ops");
    git("commit", "-qm", "qualified product tree");
    const qualifiedCommit = git("rev-parse", "HEAD");
    const qualifiedTree = evidence.productTreeIdentity(root);

    fs.writeFileSync(path.join(root, productRoots[0], "identity.txt"), "candidate worktree contents\n");
    assert.notEqual(evidence.productTreeIdentity(root), qualifiedTree);
    assert.equal(evidence.productTreeIdentity(root, qualifiedCommit), qualifiedTree);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test("historical test-overlay digest is replayed from its Git tree, independent of the comparator checkout", () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "scrypath-fixture-tree-object-"));
  const productRoots = [
    "examples/scrypath_ecommerce/assets",
    "examples/scrypath_ecommerce/config",
    "examples/scrypath_ecommerce/lib",
    "scrypath_ops/assets",
    "scrypath_ops/config",
    "scrypath_ops/lib"
  ];
  const git = (...args) => {
    const result = spawnSync("git", ["-C", root, ...args], { encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
    return result.stdout.trim();
  };

  try {
    for (const directory of productRoots) {
      const absolute = path.join(root, directory, "identity.txt");
      fs.mkdirSync(path.dirname(absolute), { recursive: true });
      fs.writeFileSync(absolute, `product:${directory}\n`);
    }
    for (const relative of evidence.preservationFixtureFiles) {
      const absolute = path.join(root, relative);
      fs.mkdirSync(path.dirname(absolute), { recursive: true });
      fs.writeFileSync(absolute, `qualified-overlay:${relative}\n`);
    }
    git("init", "-q");
    git("config", "user.name", "Scrypath Test");
    git("config", "user.email", "scrypath-test@example.invalid");
    git("add", "--", "examples", "scrypath_ops", "scripts");
    git("commit", "-qm", "qualified product source");
    const productSha = git("rev-parse", "HEAD");
    const firstFixture = path.join(root, evidence.preservationFixtureFiles[0]);
    fs.writeFileSync(firstFixture, "committed test-only overlay\n");
    git("add", "--", evidence.preservationFixtureFiles[0]);
    git("commit", "-qm", "test-only harness overlay");
    const buildSha = git("rev-parse", "HEAD");
    const qualifiedOverlay = evidence.fixtureOverlayDigest(root, buildSha);

    fs.writeFileSync(path.join(root, evidence.preservationFixtureFiles[1]), "candidate comparator checkout\n");
    const currentOverlay = evidence.fixtureOverlayDigest(root);
    assert.notEqual(currentOverlay, qualifiedOverlay);
    const replayed = evidence.validateSourceOverlay(root, productSha, buildSha);
    assert.equal(replayed.productTreeSha256, evidence.productTreeIdentity(root, productSha));
    assert.equal(replayed.fixtureOverlaySha256, qualifiedOverlay);
    assert.deepEqual(replayed.changedFiles, [evidence.preservationFixtureFiles[0]]);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test("before source qualification requires independently pinned raw bytes, capture, clock and Git overlay", () => {
  const source = createQualifiedSourceRepo({ separateOverlayCommit: true });
  const evidenceRoot = fs.mkdtempSync(path.join(os.tmpdir(), "scrypath-before-qualification-"));
  const capturePath = path.join(evidenceRoot, "actual-before", "capture.json");
  const clockBytes = Buffer.from("2026-10-31T23:31:05.798Z", "utf8");
  const clockSha = crypto.createHash("sha256").update(clockBytes).digest("hex");
  const capture = {
    source: { source_sha: source.productSha },
    environment: {
      browser_launch: { args: ["--disable-partial-raster"] },
      browser_font_profile: { method: "retained-cdp-fixed-font-v1", font_families: { fixed: "Liberation Mono" }, applied: "before-first-navigation", lifetime: "page-context" },
      clock: { utc: "2026-10-31T23:31:05.798Z", sha256: clockSha, timezone: "UTC", locale: "en-US", browser_mode: "fixed-date" }
    }
  };
  fs.mkdirSync(path.dirname(capturePath), { recursive: true });
  const captureBytes = Buffer.from(JSON.stringify(capture));
  fs.writeFileSync(capturePath, captureBytes);
  const captureSha = crypto.createHash("sha256").update(captureBytes).digest("hex");
  const qualification = {
    schema: "scrypath.phase185-before-qualification.v1",
    status: "qualified",
    source_sha: source.productSha,
    actual_before_sha256: captureSha,
    pinned_files: [{ path: capturePath, sha256: captureSha }],
    browser_runtime_equivalence: {
      source_sha: source.productSha,
      actual_image_id: `sha256:${"a".repeat(64)}`,
      rootfs_layers_equal: true,
      effective_config_equal: true
    }
  };
  const qualificationPath = path.join(evidenceRoot, "185-05-qualification.json");
  const qualificationBytes = Buffer.from(JSON.stringify(qualification));
  fs.writeFileSync(qualificationPath, qualificationBytes);
  const qualificationSha256 = `sha256:${crypto.createHash("sha256").update(qualificationBytes).digest("hex")}`;
  try {
    const validated = evidence.validateBeforeQualification({
      repoRoot: source.root,
      qualificationPath,
      productSourceSha: source.productSha,
      buildSourceSha: source.buildSha,
      qualificationSha256
    });
    assert.equal(validated.product_tree_sha256, source.productTreeSha256);
    assert.equal(validated.fixture_overlay_sha256, source.fixtureOverlaySha256);
    assert.equal(validated.qualification_sha256, qualificationSha256);
    assert.equal(validated.clock_instant, capture.environment.clock.utc);

    fs.writeFileSync(qualificationPath, Buffer.from(JSON.stringify({ ...qualification, status: "unqualified" })));
    assert.throws(() => evidence.validateBeforeQualification({
      repoRoot: source.root,
      qualificationPath,
      productSourceSha: source.productSha,
      buildSourceSha: source.buildSha,
      qualificationSha256
    }), /independent qualification digest pin/i);
  } finally {
    fs.rmSync(evidenceRoot, { recursive: true, force: true });
    fs.rmSync(source.root, { recursive: true, force: true });
  }
});

test("the before-only evidence command emits a separate held-out receipt schema", () => {
  const source = createQualifiedSourceRepo({ separateOverlayCommit: true });
  const expectedSource = {
    sourceSha: source.productSha,
    buildSourceSha: source.buildSha,
    productTreeSha256: source.productTreeSha256,
    fixtureOverlaySha256: source.fixtureOverlaySha256,
    qualificationSha256: QUALIFICATION_SHA256
  };
  const { runDir } = createCompleteRun({
    beforeOnly: true,
    sourceSha: source.productSha,
    buildSourceSha: source.buildSha,
    productTreeSha256: expectedSource.productTreeSha256,
    fixtureOverlaySha256: expectedSource.fixtureOverlaySha256
  });
  try {
    const written = evidence.writeBeforeOnlyEvidence({ runDir, expectedSource, repoRoot: source.root });
    assert.equal(written.eligibility.eligible, true, JSON.stringify(written.reasons));

    const beforePath = path.join(runDir, "phase185-before-only-evidence.json");
    const receipt = JSON.parse(fs.readFileSync(beforePath, "utf8"));
    assert.equal(receipt.scope, "before-only");
    assert.equal(receipt.preservation.schema, "scrypath.ui-preservation-before-only.v1");
    assert.equal(receipt.preservation.cases.length, 61);
    assert.equal(fs.existsSync(path.join(runDir, "phase105-evidence.json")), false);
    const validation = evidence.validateBeforeOnlyReceipt({ runDir, expectedSource, repoRoot: source.root });
    assert.equal(validation.valid, true, JSON.stringify(validation.reasons));
  } finally {
    fs.rmSync(runDir, { recursive: true, force: true });
    fs.rmSync(source.root, { recursive: true, force: true });
  }
});

test("contrast eligibility follows the token report schema, consistent counts, zero AA failures, and raw stage result", () => {
  const cases = [
    {
      name: "wrong schema",
      mutateReport(report) { report.schema = "untrusted.contrast.v0"; }
    },
    {
      name: "wrong producer",
      mutateReport(report) { report.producer = "untrusted"; }
    },
    {
      name: "inconsistent summary",
      mutateReport(report) { report.summary.total += 1; }
    },
    {
      name: "empty report",
      report: tokenContrastReport({ advisories: 0 })
    },
    {
      name: "AA failure",
      report: tokenContrastReport({ aaFails: 1 }),
      stageExitCode: 1,
      checkerStatus: "fail"
    },
    {
      name: "nonzero stage despite a zero-AA report",
      report: tokenContrastReport(),
      stageExitCode: 1,
      checkerStatus: "fail"
    }
  ];

  for (const scenario of cases) {
    const { runDir } = createCompleteRun();
    try {
      const reportPath = path.join(runDir, "contrast-report.json");
      const report = scenario.report || JSON.parse(fs.readFileSync(reportPath, "utf8"));
      scenario.mutateReport?.(report);
      fs.writeFileSync(reportPath, JSON.stringify(report));
      updateRunManifest(runDir, (manifest) => {
        if (scenario.stageExitCode !== undefined) {
          manifest.stages.contrast.exit_code = scenario.stageExitCode;
        }
        if (scenario.checkerStatus) manifest.checkers.contrast.status = scenario.checkerStatus;
      });

      const receipt = evidence.writeEvidence?.({ runDir });
      assert.equal(receipt?.eligibility.eligible, false, `${scenario.name} must not certify contrast`);
      if (scenario.name === "wrong schema" || scenario.name === "wrong producer" || scenario.name === "inconsistent summary" || scenario.name === "empty report") {
        assert.ok(receipt?.reasons.some((reason) => reason.code === "invalid_contrast_report"));
      }
    } finally {
      fs.rmSync(runDir, { recursive: true, force: true });
    }
  }
});

test("missing or malformed required reports block receipt eligibility", () => {
  for (const malformed of [false, true]) {
    const { runDir } = createCompleteRun();
    try {
      const reportPath = path.join(runDir, "phase105-playwright.json");
      if (malformed) fs.writeFileSync(reportPath, "{");
      else fs.rmSync(reportPath);
      const receipt = evidence.writeEvidence?.({ runDir });

      assert.equal(receipt?.eligibility.eligible, false);
      assert.ok(receipt?.reasons.length > 0);
    } finally {
      fs.rmSync(runDir, { recursive: true, force: true });
    }
  }
});

test("writer CLI requires an explicit run directory and propagates incomplete proof", () => {
  const script = path.join(__dirname, "ecommerce_evidence.cjs");
  const missingRunDir = spawnSync(process.execPath, [script, "write-evidence"], { encoding: "utf8" });
  assert.notEqual(missingRunDir.status, 0);

  const { runDir } = createCompleteRun();
  try {
    fs.rmSync(path.join(runDir, "contrast-report.json"));
    const result = spawnSync(process.execPath, [script, "write-evidence", "--run-dir", runDir], { encoding: "utf8" });
    assert.notEqual(result.status, 0);
    assert.match(result.stdout, /\"eligible\": false/);
  } finally {
    fs.rmSync(runDir, { recursive: true, force: true });
  }
});

test("legacy shell entrypoint delegates to the same writer with an explicit run directory", () => {
  const wrapper = path.join(__dirname, "phase105_evidence.sh");
  const missingRunDir = spawnSync("bash", [wrapper], { encoding: "utf8" });
  assert.equal(missingRunDir.status, 64);

  const { runDir } = createCompleteRun();
  try {
    const result = spawnSync("bash", [wrapper, "--run-dir", runDir], { encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
    assert.ok(fs.existsSync(path.join(runDir, "phase105-evidence.json")));
    assert.ok(fs.existsSync(path.join(runDir, "phase105-evidence-summary.md")));
  } finally {
    fs.rmSync(runDir, { recursive: true, force: true });
  }
});

test("forged SHA or image identity rejects even when the advisory job says success", () => {
  for (const mutate of [
    (manifest) => (manifest.source.event_sha = "f".repeat(40)),
    (manifest) => (manifest.images.application.runtime_id = `sha256:${"e".repeat(64)}`)
  ]) {
    const { runDir } = createCompleteRun();
    try {
      updateRunManifest(runDir, mutate);
      const receipt = evidence.writeEvidence?.({ runDir });
      assert.equal(receipt?.workflow.job_conclusion, "success");
      assert.equal(receipt?.eligibility.eligible, false);
      assert.ok(receipt?.reasons.length > 0);
    } finally {
      fs.rmSync(runDir, { recursive: true, force: true });
    }
  }
});

test("failed artifact copies, raw verifier errors, and unclean cleanup block eligibility", () => {
  const mutations = [
    (manifest) => (manifest.artifacts[0].copied = false),
    (manifest) => (manifest.stages.browser.exit_code = 1),
    (manifest) => (manifest.cleanup.containers = 1)
  ];
  for (const mutate of mutations) {
    const { runDir } = createCompleteRun();
    try {
      updateRunManifest(runDir, mutate);
      const receipt = evidence.writeEvidence?.({ runDir });
      assert.equal(receipt?.eligibility.eligible, false);
    } finally {
      fs.rmSync(runDir, { recursive: true, force: true });
    }
  }
});

test("dirty local evidence keeps its fingerprint and cannot claim hosted clean proof", () => {
  const { runDir } = createCompleteRun();
  try {
    updateRunManifest(runDir, (manifest) => {
      manifest.source.mode = "local";
      manifest.source.dirty = true;
      manifest.source.dirty_fingerprint = `sha256:${"d".repeat(64)}`;
      manifest.source.event_sha = null;
      for (const image of Object.values(manifest.images)) image.source_fingerprint = manifest.source.dirty_fingerprint;
      manifest.workflow.event = "local";
      manifest.workflow.run_id = "local-123";
      manifest.workflow.ref = "local-worktree";
    });
    const receipt = evidence.writeEvidence?.({ runDir });

    assert.equal(receipt?.eligibility.eligible, true);
    assert.equal(receipt?.eligibility.clean, false);
    assert.equal(receipt?.eligibility.class, "local-dirty");
    assert.equal(receipt?.source.dirty_fingerprint, `sha256:${"d".repeat(64)}`);
  } finally {
    fs.rmSync(runDir, { recursive: true, force: true });
  }
});

test("artifact path traversal and symlink escapes are rejected", () => {
  const { runDir } = createCompleteRun();
  const outside = path.join(os.tmpdir(), `scrypath-evidence-outside-${process.pid}.txt`);
  try {
    fs.writeFileSync(outside, "outside\n");
    updateRunManifest(runDir, (manifest) => {
      manifest.artifacts.push({ path: "../outside.txt", required: true, copied: true, copy_status: "success" });
    });
    const traversal = evidence.writeEvidence?.({ runDir });
    assert.equal(traversal?.eligibility.eligible, false);
    assert.ok(traversal?.reasons.some((reason) => reason.code === "unsafe_artifact_path"));
  } finally {
    fs.rmSync(runDir, { recursive: true, force: true });
    fs.rmSync(outside, { force: true });
  }

  const symlinkRun = createCompleteRun();
  const symlinkOutside = path.join(os.tmpdir(), `scrypath-evidence-symlink-${process.pid}.txt`);
  try {
    fs.writeFileSync(symlinkOutside, "outside\n");
    const linkPath = path.join(symlinkRun.runDir, "ui-review-artifacts/iteration3-journeys/linked.png");
    fs.symlinkSync(symlinkOutside, linkPath);
    updateRunManifest(symlinkRun.runDir, (manifest) => {
      manifest.artifacts.push({ path: "ui-review-artifacts/iteration3-journeys/linked.png", required: true, copied: true, copy_status: "success" });
    });
    const receipt = evidence.writeEvidence?.({ runDir: symlinkRun.runDir });
    assert.equal(receipt?.eligibility.eligible, false);
    assert.ok(receipt?.reasons.some((reason) => reason.code === "unsafe_artifact_path"));
  } finally {
    fs.rmSync(symlinkRun.runDir, { recursive: true, force: true });
    fs.rmSync(symlinkOutside, { force: true });
  }
});

test("artifact selection matches the hosted uploader hidden-file policy", () => {
  assert.equal(evidence.isAllowedArtifactPath("test-results/.last-run.json"), false);
  assert.equal(evidence.isAllowedArtifactPath("test-results/.hidden/screenshot.png"), false);
  assert.equal(evidence.isAllowedArtifactPath("test-results/admin-screenshots/owned.png"), true);
  assert.equal(evidence.isAllowedArtifactPath("playwright-report/data/trace.png"), true);
  assert.equal(evidence.isAllowedArtifactPath("ui-review-artifacts/iteration3-journeys/health.png"), true);
  assert.equal(evidence.isAllowedArtifactPath("../test-results/escape.png"), false);

  const { runDir } = createCompleteRun();
  try {
    fs.mkdirSync(path.join(runDir, "test-results"), { recursive: true });
    fs.writeFileSync(path.join(runDir, "test-results/.last-run.json"), '{"status":"passed"}\n');
    updateRunManifest(runDir, (manifest) => {
      manifest.artifacts.push({ path: "test-results/.last-run.json", required: false, copied: true, copy_status: "success" });
    });
    const receipt = evidence.writeEvidence?.({ runDir });
    assert.equal(receipt?.eligibility.eligible, false);
    assert.ok(receipt?.reasons.some((reason) => reason.code === "unsafe_artifact_path"));
  } finally {
    fs.rmSync(runDir, { recursive: true, force: true });
  }
});


test("full inventory requires every intended UI identity even when reports omit the same case", () => {
  const cases = completeReceiptCases();
  const verify = (items) => evidence.reconcileInventory({ inventory: playwrightReport(items), report: playwrightReport(items, { results: true }), requireMandatoryCases: true });
  assert.equal(verify(cases).eligible, true);
  for (const expected of cases.filter((item) => /ui_(followup|iteration3)/.test(item.file))) {
    const reduced = cases.filter((item) => item !== expected);
    const result = verify(reduced);
    assert.equal(result.eligible, false, expected.title);
    assert.ok(result.reasons.some((r) => r.code === "missing_required_case"), expected.title);
    const renamed = cases.map((item) => item === expected ? { ...item, title: item.title + " removed" } : item);
    assert.equal(verify(renamed).eligible, false, "a replacement title cannot fill the required identity");
  }
});

test("full inventory requires the exact held-out preservation case identities", () => {
  const cases = completeReceiptCases().filter((item) => !item.title.startsWith("E1 empty "));
  const result = evidence.reconcileInventory?.({
    inventory: playwrightReport(cases),
    report: playwrightReport(cases, { results: true }),
    repoRoot: path.resolve(__dirname, "../.."),
    requireMandatoryCases: true
  });

  assert.equal(result?.eligible, false);
  assert.ok(result?.reasons.some((reason) =>
    reason.code === "missing_required_case" && reason.message.includes("E1 empty")
  ));
});

test("a full inventory cannot duplicate or relocate a held-out case identity", () => {
  const cases = completeReceiptCases();
  const target = cases.find((item) => item.title.startsWith("E1 empty "));
  const duplicated = [...cases, { ...target, title: "E1 empty second named case" }];
  const misplaced = cases.map((item) => item === target ? { ...item, file: "e2e/ui_content_preservation.spec.ts" } : item);

  for (const inventoryCases of [duplicated, misplaced]) {
    const result = evidence.reconcileInventory({
      inventory: playwrightReport(inventoryCases),
      report: playwrightReport(inventoryCases, { results: true }),
      repoRoot: path.resolve(__dirname, "../.."),
      requireMandatoryCases: true
    });
    assert.equal(result.eligible, false);
    assert.ok(result.reasons.some((reason) =>
      ["duplicate_preservation_case", "unexpected_preservation_case"].includes(reason.code)
    ));
  }
});

test("a full receipt cannot pass without actual per-case state, assertion, copy and image events", () => {
  const { runDir } = createCompleteRun();
  try {
    const eventsPath = path.join(runDir, "phase105-evidence.ndjson");
    fs.writeFileSync(eventsPath, `${fs.readFileSync(eventsPath, "utf8").split(/\r?\n/).filter((line) => {
      if (!line.trim()) return false;
      return JSON.parse(line).operation !== "ui_preservation_case";
    }).join("\n")}\n`);
    const receipt = evidence.writeEvidence?.({ runDir });

    assert.equal(receipt?.eligibility.eligible, false);
    assert.ok(receipt?.reasons.some((reason) =>
      reason.code === "missing_preservation_case_receipt"
    ));
  } finally {
    fs.rmSync(runDir, { recursive: true, force: true });
  }
});

test("a held-out receipt rejects altered copy, duplicate cases and image bytes", () => {
  const { runDir } = createCompleteRun();
  const eventsPath = path.join(runDir, "phase105-evidence.ndjson");
  try {
    const events = fs.readFileSync(eventsPath, "utf8").trim().split(/\r?\n/).map((line) => JSON.parse(line));
    const first = events.find((event) => event.operation === "ui_preservation_case");
    first.observations[0].visible_copy[0].text += " changed";
    events.push({ ...first });
    fs.writeFileSync(eventsPath, `${events.map((event) => JSON.stringify(event)).join("\n")}\n`);
    fs.writeFileSync(path.join(runDir, first.observations[0].image.path), Buffer.from("tampered image"));

    const receipt = evidence.writeEvidence?.({ runDir });
    assert.equal(receipt?.eligibility.eligible, false);
    assert.ok(receipt?.reasons.some((reason) => reason.code === "duplicate_preservation_case_receipt"));
    assert.ok(receipt?.reasons.some((reason) => reason.code === "invalid_preservation_observation"));
  } finally {
    fs.rmSync(runDir, { recursive: true, force: true });
  }
});

test("held-out receipts bind source, fixture, runtime, recipe, state, transport and measured geometry", () => {
  const mutations = [
    ["product source", (event) => { event.product_source_sha = "b".repeat(40); }, "preservation_source_mismatch"],
    ["tree", (event) => { event.product_tree_sha256 = `sha256:${"a".repeat(64)}`; }, "preservation_source_mismatch"],
    ["fixture", (event) => { event.fixture_overlay_sha256 = `sha256:${"a".repeat(64)}`; }, "preservation_fixture_mismatch"],
    ["runtime", (event) => { event.runtime.effective_runtime_sha256 = `sha256:${"a".repeat(64)}`; }, "mixed_preservation_runtime"],
    ["recipe", (event) => { event.recipe_sha256 = `sha256:${"a".repeat(64)}`; }, "mixed_preservation_recipe"],
    ["state", (event) => { event.observations[0].state.category = "error"; }, "invalid_preservation_observation"],
    ["transport", (event) => { event.transport_sequence = []; }, "invalid_preservation_transport"],
    ["geometry", (event) => { event.observations[0].geometry = []; }, "invalid_preservation_observation"],
    ["sampling missing", (event) => { delete event.observations[0].capture_sampling; }, "invalid_preservation_observation"],
    ["sampling unbounded", (event) => { event.observations[0].capture_sampling.max_samples = 7; }, "invalid_preservation_observation"],
    ["sampling not exact", (event) => { event.observations[0].capture_sampling.samples[0].sha256 = "0".repeat(64); }, "invalid_preservation_observation"],
    ["assertion", (event) => { event.observations[0].assertions[0].status = "failed"; }, "invalid_preservation_observation"]
  ];

  for (const [label, mutate, expectedCode] of mutations) {
    const { runDir } = createCompleteRun();
    try {
      const eventsPath = path.join(runDir, "phase105-evidence.ndjson");
      const events = fs.readFileSync(eventsPath, "utf8").trim().split(/\r?\n/).map((line) => JSON.parse(line));
      mutate(events.find((event) => event.operation === "ui_preservation_case"));
      fs.writeFileSync(eventsPath, `${events.map((event) => JSON.stringify(event)).join("\n")}\n`);
      const receipt = evidence.writeEvidence({ runDir });
      assert.equal(receipt.eligibility.eligible, false, label);
      assert.ok(receipt.reasons.some((reason) => reason.code === expectedCode), label);
    } finally {
      fs.rmSync(runDir, { recursive: true, force: true });
    }
  }
});

test("held-out receipts reject missing observations, mismatched clock, stopped timer or altered clock artifact", () => {
  const mutations = [
    ["missing overflow viewport", (event) => { event.observations.pop(); }, "incomplete_preservation_observations"],
    ["browser clock differs from server", (event) => { event.observations[0].state.clock.browser_iso = "2026-10-31T12:00:01.000Z"; }, "invalid_preservation_observation"],
    ["timer witness absent", (event) => { event.clock_recipe.browser_date.timers_running = false; event.recipe_sha256 = `sha256:${"a".repeat(64)}`; }, "invalid_preservation_clock_recipe"],
    ["clock artifact digest altered", (event) => { event.clock_artifact.sha256 = "a".repeat(64); }, "invalid_preservation_clock_artifact"]
  ];
  for (const [label, mutate, expectedCode] of mutations) {
    const { runDir } = createCompleteRun();
    try {
      const eventsPath = path.join(runDir, "phase105-evidence.ndjson");
      const events = fs.readFileSync(eventsPath, "utf8").trim().split(/\r?\n/).map((line) => JSON.parse(line));
      const target = label === "missing overflow viewport"
        ? events.find((event) => event.operation === "ui_preservation_case" && event.case_id.endsWith("overflow"))
        : events.find((event) => event.operation === "ui_preservation_case");
      mutate(target);
      fs.writeFileSync(eventsPath, `${events.map((event) => JSON.stringify(event)).join("\n")}\n`);
      const receipt = evidence.writeEvidence({ runDir });
      assert.equal(receipt.eligibility.eligible, false, label);
      assert.ok(receipt.reasons.some((reason) => reason.code === expectedCode), label);
    } finally {
      fs.rmSync(runDir, { recursive: true, force: true });
    }
  }
});

test("a small decoded image cannot claim a real 1440px full-page capture", () => {
  const { runDir } = createCompleteRun();
  try {
    const eventsPath = path.join(runDir, "phase105-evidence.ndjson");
    const events = fs.readFileSync(eventsPath, "utf8").trim().split(/\r?\n/).map((line) => JSON.parse(line));
    const first = events.find((event) => event.operation === "ui_preservation_case");
    const image = first.observations[0].image;
    const tiny = new PNG({ width: 1, height: 1 });
    tiny.data.set([1, 2, 3, 255]);
    const bytes = PNG.sync.write(tiny);
    fs.writeFileSync(path.join(runDir, image.path), bytes);
    image.sha256 = crypto.createHash("sha256").update(bytes).digest("hex");
    const manifest = JSON.parse(fs.readFileSync(path.join(runDir, "phase105-evidence-input.json"), "utf8"));
    const bundlePath = path.join(runDir, rawBundle.BUNDLE_PATH);
    const members = rawBundle.decodeBundle(fs.readFileSync(bundlePath));
    members.set(image.path, bytes);
    // This deliberately constructs a newly hash-consistent bad bundle, so the
    // geometry guard rather than the archive hash must reject the tiny PNG.
    const packed = rawBundle.encodeBundle([...members].map(([path, bytes]) => ({ path, bytes })));
    fs.writeFileSync(bundlePath, packed);
    fs.writeFileSync(path.join(runDir, "phase105-evidence-input.json"), JSON.stringify(manifest));
    fs.writeFileSync(eventsPath, `${events.map((event) => JSON.stringify(event)).join("\n")}\n`);

    const receipt = evidence.writeEvidence({ runDir });
    assert.equal(receipt.eligibility.eligible, false);
    assert.ok(receipt.reasons.some((reason) => reason.code === "invalid_preservation_observation" && /decoded full-page raster/.test(reason.message)));
  } finally {
    fs.rmSync(runDir, { recursive: true, force: true });
  }
});

test("synthetic untrusted reviewer metadata cannot become canonical evidence", () => {
  const { runDir } = createCompleteRun();
  const marker = "TEST_FIXTURE_ONLY_NOT_A_REAL_REVIEW_OR_APPROVAL";
  const syntheticApproval = {
    status: "approved",
    reviewer: "SYNTHETIC_TEST_FIXTURE_NOT_A_PERSON",
    marker
  };
  try {
    updateRunManifest(runDir, (manifest) => {
      manifest.independent_reviewer_approval = syntheticApproval;
      manifest.reviewer_approval = syntheticApproval;
    });

    for (const fileName of ["phase105-playwright-list.json", "phase105-playwright.json"]) {
      const reportPath = path.join(runDir, fileName);
      const report = JSON.parse(fs.readFileSync(reportPath, "utf8"));
      report.metadata = {
        independent_reviewer_approval: syntheticApproval,
        reviewer_approval: syntheticApproval
      };
      fs.writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`);
    }

    const receipt = evidence.writeEvidence?.({ runDir });
    const receiptText = fs.readFileSync(path.join(runDir, "phase105-evidence.json"), "utf8");
    const summary = fs.readFileSync(path.join(runDir, "phase105-evidence-summary.md"), "utf8");

    assert.equal(receipt?.eligibility.eligible, true);
    assert.equal(Object.keys(receipt).some(key => key.startsWith("visual_judge_")), false);

    assert.equal(Object.hasOwn(receipt, "independent_reviewer_approval"), false);
    assert.equal(Object.hasOwn(receipt, "reviewer_approval"), false);
    assert.equal(receiptText.includes(marker), false);
    assert.doesNotMatch(receiptText, /independent_reviewer_approval|reviewer_approval/);
    assert.equal(summary.includes(marker), false);
    assert.doesNotMatch(summary, /independent_reviewer_approval|reviewer_approval/);
    assert.doesNotMatch(summary, /visual_judge_|Advisory Visual Judge/);
    assert.equal(evidence.validateReceipt?.({ runDir }).valid, true);
  } finally {
    fs.rmSync(runDir, { recursive: true, force: true });
  }
});

test("receipt validation rejects a synthetic independent approval inserted into the stored aggregate", () => {
  const { runDir } = createCompleteRun();
  const marker = "TEST_FIXTURE_ONLY_NOT_A_REAL_REVIEW_OR_APPROVAL";
  try {
    evidence.writeEvidence?.({ runDir });
    const receiptPath = path.join(runDir, "phase105-evidence.json");
    const receipt = JSON.parse(fs.readFileSync(receiptPath, "utf8"));
    receipt.independent_reviewer_approval = {
      status: "approved",
      reviewer: "SYNTHETIC_TEST_FIXTURE_NOT_A_PERSON",
      marker
    };
    fs.writeFileSync(receiptPath, `${JSON.stringify(receipt, null, 2)}\n`);

    const validation = evidence.validateReceipt?.({ runDir });
    assert.equal(validation?.valid, false);
    assert.ok(validation?.reasons.some((reason) => reason.code === "receipt_mismatch"));

    const cli = spawnSync(
      process.execPath,
      [path.join(__dirname, "ecommerce_evidence.cjs"), "validate-receipt", "--run-dir", runDir],
      { encoding: "utf8" }
    );
    assert.equal(cli.status, 1, cli.stderr);
    const cliResult = JSON.parse(cli.stdout);
    assert.equal(cliResult.valid, false);
    assert.ok(cliResult.reasons.some((reason) => reason.code === "receipt_mismatch"));
  } finally {
    fs.rmSync(runDir, { recursive: true, force: true });
  }
});

test("receipt validation rejects an appended synthetic independent approval in its Markdown summary", () => {
  const { runDir } = createCompleteRun();
  const marker = "TEST_FIXTURE_ONLY_NOT_A_REAL_REVIEW_OR_APPROVAL";
  try {
    evidence.writeEvidence?.({ runDir });
    fs.appendFileSync(
      path.join(runDir, "phase105-evidence-summary.md"),
      `\n- independent_reviewer_approval: ${marker}\n`
    );

    const validation = evidence.validateReceipt?.({ runDir });
    assert.equal(validation?.valid, false);
    assert.ok(validation?.reasons.some((reason) => reason.code === "summary_mismatch"));

    const cli = spawnSync(
      process.execPath,
      [path.join(__dirname, "ecommerce_evidence.cjs"), "validate-receipt", "--run-dir", runDir],
      { encoding: "utf8" }
    );
    assert.equal(cli.status, 1, cli.stderr);
    const cliResult = JSON.parse(cli.stdout);
    assert.equal(cliResult.valid, false);
    assert.ok(cliResult.reasons.some((reason) => reason.code === "summary_mismatch"));
  } finally {
    fs.rmSync(runDir, { recursive: true, force: true });
  }
});


test("legacy judge fields remain readable without rewriting receipt bytes", () => {
  const {runDir} = createCompleteRun();
  try {
    const receipt = evidence.writeEvidence({runDir});
    Object.assign(receipt, {
      visual_judge_status: "not-required", visual_judge_findings: null,
      visual_judge_claims: null, visual_judge_required: false,
      visual_judge_skipped_reason: "The paid judge is outside browser eligibility."
    });
    const file = path.join(runDir, "phase105-evidence.json");
    const summaryFile = path.join(runDir, "phase105-evidence-summary.md");
    fs.writeFileSync(file, JSON.stringify(receipt, null, 2) + "\n");
    fs.writeFileSync(summaryFile, evidence.renderSummary(receipt));
    const before = [fs.readFileSync(file), fs.readFileSync(summaryFile)];
    assert.equal(evidence.validateReceipt({runDir}).valid, true);
    assert.deepEqual([fs.readFileSync(file), fs.readFileSync(summaryFile)], before);
    receipt.visual_judge_status = "approved";
    fs.writeFileSync(file, JSON.stringify(receipt));
    assert.equal(evidence.validateReceipt({runDir}).valid, false);
  } finally { fs.rmSync(runDir, {recursive:true, force:true}); }
});

test("separate and interrupted runs cannot borrow another invocation's evidence", () => {
  const first = createCompleteRun(), second = createCompleteRun(), interruptedRun = createCompleteRun();
  try {
    updateRunManifest(second.runDir, m => { m.workflow.run_id = "987654321"; });
    evidence.writeEvidence({runDir:first.runDir});
    evidence.writeEvidence({runDir:second.runDir});
    fs.copyFileSync(path.join(first.runDir,"phase105-evidence.json"), path.join(second.runDir,"phase105-evidence.json"));
    fs.copyFileSync(path.join(first.runDir,"phase105-evidence-summary.md"), path.join(second.runDir,"phase105-evidence-summary.md"));
    assert.equal(evidence.validateReceipt({runDir:second.runDir}).valid, false);
    assert.throws(() => evidence.writeEvidence({runDir:second.runDir}), /outputs already exist/);
    fs.unlinkSync(path.join(interruptedRun.runDir,"ui-review-artifacts/iteration3-journeys/iteration3-proof.png"));
    const interrupted = evidence.writeEvidence({runDir:interruptedRun.runDir});
    assert.equal(interrupted.eligibility.eligible, false);
    assert.equal(evidence.validateReceipt({runDir:first.runDir}).eligible, true);
  } finally {
    fs.rmSync(first.runDir,{recursive:true,force:true});
    fs.rmSync(second.runDir,{recursive:true,force:true});
    fs.rmSync(interruptedRun.runDir,{recursive:true,force:true});
  }
});
