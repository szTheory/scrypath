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
