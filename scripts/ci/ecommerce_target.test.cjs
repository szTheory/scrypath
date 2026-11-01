const assert = require("node:assert/strict");
const { chmodSync, existsSync, mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const { pathToFileURL } = require("node:url");
const test = require("node:test");

const verifierPath = path.resolve(__dirname, "../../examples/scrypath_ecommerce/scripts/verify-e2e.sh");

const verificationTargetPath = pathToFileURL(
  path.resolve(__dirname, "../../examples/scrypath_ecommerce/e2e/helpers/verification-target.mjs"),
).href;
const verificationTarget = import(verificationTargetPath);
const axeScanPath = pathToFileURL(
  path.resolve(__dirname, "../../examples/scrypath_ecommerce/e2e/helpers/axe-scan.mjs"),
).href;
const axeScan = import(axeScanPath);

const followupSource = path.resolve(
  __dirname,
  "../../examples/scrypath_ecommerce/e2e/ui_followup.spec.ts",
);
const iteration3Source = path.resolve(
  __dirname,
  "../../examples/scrypath_ecommerce/e2e/ui_iteration3.spec.ts",
);

test("verification target accepts Docker and explicitly isolated local hosts", async () => {
  const { previewRefusalReason } = await verificationTarget;

  assert.equal(previewRefusalReason("http://web:4002"), null);
  assert.equal(previewRefusalReason("http://localhost:4014"), null);
  assert.equal(previewRefusalReason("http://127.0.0.1:4014"), null);
});

test("verification target refuses the retained preview and missing or malformed URLs", async () => {
  const { previewRefusalReason } = await verificationTarget;

  assert.match(previewRefusalReason("http://localhost:4002"), /retained preview/i);
  assert.match(previewRefusalReason("http://127.0.0.1:4002"), /retained preview/i);
  assert.match(previewRefusalReason(undefined), /valid.*URL/i);
  assert.match(previewRefusalReason("not a URL"), /valid.*URL/i);
});

test("verification target refusal callback runs before any guarded mutation", async () => {
  const { guardVerificationTarget } = await verificationTarget;

  for (const baseURL of ["http://localhost:4002", "http://127.0.0.1:4002", undefined, "not a URL"]) {
    const events = [];
    await guardVerificationTarget(
      baseURL,
      (reason) => events.push(["refused", reason]),
      async () => events.push(["mutated"]),
    );

    assert.equal(events.length, 1, `refused target ${String(baseURL)} cannot reach the mutator`);
    assert.equal(events[0][0], "refused");
  }
});

test("follow-up and iteration-3 suites guard before setup and retain all selected cases", async () => {
  const followup = readFileSync(followupSource, "utf8");
  const iteration3 = readFileSync(iteration3Source, "utf8");

  const followupGuard = followup.indexOf("await guardVerificationTarget(");
  const followupCases = followup.indexOf("for (const [name, url]");
  assert.ok(followupGuard > 0 && followupGuard < followupCases);

  const iteration3Guard = iteration3.indexOf("await guardVerificationTarget(");
  const iteration3Setup = iteration3.indexOf("await mkdir(artifacts");
  const iteration3Cases = iteration3.indexOf("test(\"");
  assert.ok(iteration3Guard > 0 && iteration3Guard < iteration3Setup);
  assert.ok(iteration3Setup < iteration3Cases);
  assert.doesNotMatch(followup, /new URL\(baseURL\)\.port/);
  assert.doesNotMatch(iteration3, /new URL\(baseURL\)\.port/);
});


test("all loopback spellings refuse the retained preview before mutation", async () => {
  const { guardVerificationTarget, previewRefusalReason } = await verificationTarget;
  for (const host of ["[::1]", "[0:0:0:0:0:0:0:1]", "127.0.0.2", "127.1", "[::ffff:127.0.0.1]", "localhost."]) {
    const events = [];
    await guardVerificationTarget(`http://${host}:4002`, () => events.push("refused"), () => events.push("mutated"));
    assert.deepEqual(events, ["refused"], host);
    assert.equal(previewRefusalReason(`http://${host}:4014`), null);
  }
});

function assertFullBudgetRefusedBeforeDocker(label, args) {
  const temporaryDirectory = mkdtempSync(path.join(os.tmpdir(), "scrypath-e2e-budget-cap-"));
  const fakeBin = path.join(temporaryDirectory, "bin");
  mkdirSync(fakeBin);
  const fakeDockerPath = path.join(fakeBin, "docker");
  writeFileSync(
    fakeDockerPath,
    String.raw`#!/bin/sh
printf '%s\n' "$*" >> "$FAKE_DOCKER_LOG"
if [ "$1" = "compose" ] && [ "$2" = "version" ]; then
  exit 0
fi
exit 91
`,
    { mode: 0o700 },
  );
  chmodSync(fakeDockerPath, 0o700);

  try {
    const dockerLog = path.join(temporaryDirectory, `${label}-docker.log`);
    const result = spawnSync("bash", [verifierPath, ...args], {
      encoding: "utf8",
      env: {
        ...process.env,
        E2E_DOCKER_TIMEOUT_SECONDS: "901",
        E2E_HOST_ARTIFACT_ROOT: path.join(temporaryDirectory, "artifacts"),
        E2E_RUN_ID: `budget-cap-${label}`,
        FAKE_DOCKER_LOG: dockerLog,
        PATH: `${fakeBin}${path.delimiter}${process.env.PATH || ""}`,
      },
    });

    const output = `${result.stdout || ""}\n${result.stderr || ""}`;
    assert.equal(existsSync(dockerLog), false, `${label} invoked Docker before rejecting its budget`);
    assert.equal(result.status, 64, `${label}: ${output}`);
    assert.match(output, /E2E_DOCKER_TIMEOUT_SECONDS.*900/i);
  } finally {
    rmSync(temporaryDirectory, { recursive: true, force: true });
  }
}

test("full Docker verification refuses budgets over 900 seconds before invoking Docker", () => {
  assertFullBudgetRefusedBeforeDocker("full", ["full"]);
});

test("full readiness-only verification refuses budgets over 900 seconds before invoking Docker", () => {
  assertFullBudgetRefusedBeforeDocker("readiness", ["full", "--readiness-only"]);
});

test("runtime inspection preserves an expired execution status before parsing Compose output", () => {
  const source = readFileSync(verifierPath, "utf8");
  const inspection = source.slice(source.indexOf("inspect_phase185_full_images() {"), source.indexOf("\nrecord_lifecycle() {"));
  const result = spawnSync("bash", ["-c", `
set -u
${inspection}
inspect_full_image() { printf 'sha256:%064d' 0; }
run_execution_bounded() { return 124; }
compose=(docker compose)
artifact_dir="$(mktemp -d)"
project=owned-expired
inspect_phase185_full_images
status=$?
rm -rf "$artifact_dir"
exit "$status"
`], { encoding: "utf8" });
  assert.equal(result.status, 124, result.stderr);
  assert.doesNotMatch(result.stderr, /SyntaxError|Unexpected end of JSON/);
});

test("aggregation without complete runtime identity fails explicitly without invoking Docker", () => {
  const source = readFileSync(verifierPath, "utf8");
  const aggregation = source.slice(source.indexOf("aggregate_full_evidence() {"), source.indexOf("\ncleanup() {"));
  const result = spawnSync("bash", ["-c", `
set -u
${aggregation}
original_exit_status=124
artifact_copy_status=0
cleanup_status=0
browser_image_id="sha256:$(printf '%064d' 0)"
artifact_dir=/unused
scope=full preservation_mode=full run_id=owned-expired SCRYPATH_SOURCE_SHA=unused
E2E_SOURCE_MODE=local source_dirty=false source_fingerprint=unused
E2E_EVENT_SHA=unused E2E_EVENT_NAME=local E2E_GIT_REF=unused
E2E_WORKFLOW_RUN_ID=local E2E_WORKFLOW_RUN_ATTEMPT=1 E2E_JOB_NAME=local
project=owned-expired compose_model_digest=unused application_image_id=unused standalone_image_id=unused
run_finalization_bounded() { echo unexpected-docker >&2; return 99; }
aggregate_full_evidence
`], { encoding: "utf8" });
  assert.equal(result.status, 76, result.stderr);
  assert.match(result.stderr, /complete.*runtime identity/i);
  assert.doesNotMatch(result.stderr, /unbound variable|unexpected-docker/);
});

function fakeFramePage({ frames = 1, iframeCount = 0, duringIframeCount } = {}) {
  const { EventEmitter } = require("node:events");
  const page = new EventEmitter();
  const mainFrame = {};
  page.frames = () => [mainFrame, ...Array.from({ length: frames - 1 }, () => ({}))];
  page.mainFrame = () => mainFrame;
  page.locator = (selector) => {
    assert.equal(selector, "iframe, frame");
    return {
      count: async () => {
        if (duringIframeCount) await duringIframeCount(page);
        return iframeCount;
      },
    };
  };
  return page;
}

test("frame-free Axe scan may use legacy mode and returns the scan result", async () => {
  const { scanWithFrameSafeLegacy } = await axeScan;
  const page = fakeFramePage();
  const calls = [];

  const result = await scanWithFrameSafeLegacy(page, async (legacyMode) => {
    calls.push(legacyMode);
    return { violations: [] };
  });

  assert.deepEqual(calls, [true]);
  assert.deepEqual(result, { violations: [] });
  assert.equal(page.listenerCount("frameattached"), 0);
  assert.equal(page.listenerCount("framedetached"), 0);
});

test("missing Playwright frame APIs keep the normal Axe path", async () => {
  const { scanWithFrameSafeLegacy } = await axeScan;
  const calls = [];
  const result = await scanWithFrameSafeLegacy({}, async (legacyMode) => {
    calls.push(legacyMode);
    return "modern result";
  });
  assert.deepEqual(calls, [false]);
  assert.equal(result, "modern result");
});

test("existing DOM or nested frames keep Axe on its modern path", async () => {
  const { scanWithFrameSafeLegacy } = await axeScan;
  for (const page of [fakeFramePage({ iframeCount: 1 }), fakeFramePage({ frames: 3 })]) {
    const calls = [];
    await scanWithFrameSafeLegacy(page, async (legacyMode) => calls.push(legacyMode));
    assert.deepEqual(calls, [false]);
    assert.equal(page.listenerCount("frameattached"), 0);
    assert.equal(page.listenerCount("framedetached"), 0);
  }
});

test("frame attach-detach during initial DOM check prevents legacy mode", async () => {
  const { scanWithFrameSafeLegacy } = await axeScan;
  const page = fakeFramePage({
    duringIframeCount: async (target) => {
      target.emit("frameattached", {});
      target.emit("framedetached", {});
    },
  });
  const calls = [];

  await scanWithFrameSafeLegacy(page, async (legacyMode) => calls.push(legacyMode));

  assert.deepEqual(calls, [false]);
});

test("frame event during legacy scan discards its result and reruns modern", async () => {
  const { scanWithFrameSafeLegacy } = await axeScan;
  const page = fakeFramePage();
  const calls = [];

  const result = await scanWithFrameSafeLegacy(page, async (legacyMode) => {
    calls.push(["AA", legacyMode]);
    if (legacyMode) page.emit("frameattached", {});
    calls.push(["AAA", legacyMode]);
    return { mode: legacyMode };
  });

  assert.deepEqual(calls, [["AA", true], ["AAA", true], ["AA", false], ["AAA", false]]);
  assert.deepEqual(result, { mode: false });
});

test("legacy failure retries the complete scan in modern mode", async () => {
  const { scanWithFrameSafeLegacy } = await axeScan;
  const page = fakeFramePage();
  const calls = [];
  const legacyError = new Error("legacy scan failed");
  const warnings = [];
  const originalWarn = console.warn;
  console.warn = (...args) => warnings.push(args);

  let result;
  try {
    result = await scanWithFrameSafeLegacy(page, async (legacyMode) => {
      calls.push(legacyMode);
      if (legacyMode) throw legacyError;
      return { mode: legacyMode };
    });
  } finally {
    console.warn = originalWarn;
  }
  assert.deepEqual(calls, [true, false]);
  assert.deepEqual(result, { mode: false });
  assert.equal(warnings.length, 1);
  assert.match(warnings[0][0], /legacy scan failed.*modern frame scanner/i);
  assert.equal(warnings[0][1], legacyError);

  const stablePage = fakeFramePage();
  const stableError = new Error("actual Axe failure");
  const originalStableWarn = console.warn;
  console.warn = () => {};
  let recoverable;
  try {
    recoverable = await scanWithFrameSafeLegacy(stablePage, async (legacyMode) => {
      if (legacyMode) throw stableError;
      return { mode: "modern" };
    });
  } finally {
    console.warn = originalStableWarn;
  }
  assert.deepEqual(recoverable, { mode: "modern" });
  assert.equal(stablePage.listenerCount("frameattached"), 0);
  assert.equal(stablePage.listenerCount("framedetached"), 0);
});

test("modern error remains authoritative when both legacy and modern scans fail", async () => {
  const { scanWithFrameSafeLegacy } = await axeScan;
  const page = fakeFramePage();
  const calls = [];
  const legacyError = new Error("legacy scan failed");
  const modernError = new Error("modern scan failed");
  const originalWarn = console.warn;
  console.warn = () => {};

  try {
    await assert.rejects(
      scanWithFrameSafeLegacy(page, async (legacyMode) => {
        calls.push(legacyMode);
        throw legacyMode ? legacyError : modernError;
      }),
      (error) => error === modernError,
    );
  } finally {
    console.warn = originalWarn;
  }

  assert.deepEqual(calls, [true, false]);
  assert.equal(page.listenerCount("frameattached"), 0);
  assert.equal(page.listenerCount("framedetached"), 0);
});

test("modern fallback errors propagate and frame listeners are cleaned up", async () => {
  const { scanWithFrameSafeLegacy } = await axeScan;
  const page = fakeFramePage({ iframeCount: 1 });
  const requiredError = new Error("required modern scan failed");

  await assert.rejects(
    scanWithFrameSafeLegacy(page, async () => { throw requiredError; }),
    (error) => error === requiredError,
  );
  assert.equal(page.listenerCount("frameattached"), 0);
  assert.equal(page.listenerCount("framedetached"), 0);
});
