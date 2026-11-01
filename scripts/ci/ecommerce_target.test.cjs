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
