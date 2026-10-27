"use strict";

const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

let evidence = {};
try {
  evidence = require("./ecommerce_evidence.cjs");
} catch (error) {
  if (error.code !== "MODULE_NOT_FOUND") throw error;
}

function testCase({ file = "e2e/example.spec.ts", project = "chromium", title, expectedStatus = "passed" }) {
  return { file, project, title, expectedStatus };
}

function playwrightReport(cases, { results = false, errors = [] } = {}) {
  return {
    config: { rootDir: "." },
    errors,
    suites: [
      {
        title: "e2e",
        suites: [],
        specs: cases.map((item) => ({
          title: item.title,
          file: item.file,
          tests: [
            {
              projectName: item.project,
              expectedStatus: item.expectedStatus,
              ...(results
                ? {
                    status: item.status || "passed",
                    results: item.results || [{ retry: 0, status: item.status || "passed", duration: 1 }]
                  }
                : {})
            }
          ]
        }))
      }
    ]
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
    testCase({ file: "e2e/ui_followup.spec.ts", title: "mounted: copy feedback keeps geometry stable" }),
    testCase({ file: "e2e/ui_followup.spec.ts", title: "standalone: copy feedback keeps geometry stable" }),
    testCase({ file: "e2e/ui_iteration3.spec.ts", title: "save sits by run and validates the name" }),
    testCase({ file: "e2e/phase173_shell.spec.ts", title: "mounted shell renders light preference" }),
    testCase({ file: "e2e/phase173_shell.spec.ts", title: "standalone shell renders light preference" })
  ];
}

function stage(startedAt, endedAt, exitCode = 0) {
  return { started_at: startedAt, ended_at: endedAt, exit_code: exitCode };
}

function createCompleteRun() {
  const runDir = fs.mkdtempSync(path.join(os.tmpdir(), "scrypath-evidence-run-"));
  const cases = completeReceiptCases();
  const image = { built_id: IMAGE_ID, runtime_id: IMAGE_ID, source_sha: SOURCE_SHA };
  const manifest = {
    schema_version: 1,
    source: {
      mode: "hosted",
      checkout_head: SOURCE_SHA,
      dirty: false,
      event_sha: SOURCE_SHA,
      built_source_sha: SOURCE_SHA
    },
    images: { application: { ...image }, browser: { ...image } },
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
      sha: SOURCE_SHA,
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
      }
    ],
    allowed_skips: [],
    first_failure: null
  };

  fs.mkdirSync(path.join(runDir, "playwright-report"), { recursive: true });
  fs.mkdirSync(path.join(runDir, "ui-review-artifacts/iteration3-journeys"), { recursive: true });
  fs.writeFileSync(path.join(runDir, "phase105-playwright-list.json"), JSON.stringify(playwrightReport(cases)));
  fs.writeFileSync(path.join(runDir, "phase105-playwright.json"), JSON.stringify(playwrightReport(cases, { results: true })));
  fs.writeFileSync(path.join(runDir, "phase105-evidence.ndjson"), `${JSON.stringify({ operation: "seed" })}\n`);
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

test("one aggregate binds exact source, reports, checkers, artifacts and derived summary", () => {
  const { runDir } = createCompleteRun();
  try {
    const receipt = evidence.writeEvidence?.({ runDir });

    assert.equal(receipt?.eligibility.eligible, true);
    assert.equal(receipt?.eligibility.clean, true);
    assert.equal(receipt?.eligibility.class, "hosted-exact-sha");
    assert.equal(receipt?.cases.length, 5);
    assert.equal(receipt?.visual_judge_status, "not-required");
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
