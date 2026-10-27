"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const {
  REQUIRED_CACHE_MODES,
  collectRun,
  validateBrowserAcceptance,
  validateCacheAcceptance,
} = require("./phase182_acceptance.cjs");

const SHA = "0123456789abcdef0123456789abcdef01234567";
const OTHER_SHA = "fedcba9876543210fedcba9876543210fedcba98";
const REPOSITORY = "szTheory/scrypath";
const BRANCH = "candidate/phase182";
const SESSION_ID = "candidate-run-01";
const STARTED = "2026-10-26T12:00:00Z";
const COMPLETED = "2026-10-26T12:10:00Z";

function exactRun(overrides = {}) {
  return {
    id: "12345",
    attempt: 1,
    repository: REPOSITORY,
    branch: BRANCH,
    sha: SHA,
    event: "workflow_dispatch",
    workflow: ".github/workflows/ci.yml",
    status: "completed",
    conclusion: "success",
    started_at: STARTED,
    completed_at: COMPLETED,
    previous_attempts: [],
    ...overrides,
  };
}

function browserProof(overrides = {}) {
  return {
    run: exactRun(),
    session: { repository: REPOSITORY, branch: BRANCH, sha: SHA, session_id: SESSION_ID },
    raw_verifier_outcome: "success",
    job_conclusion: "success",
    job_started_at: STARTED,
    job_completed_at: COMPLETED,
    uploaded_at: "2026-10-26T12:10:10Z",
    artifact: {
      name: "ecommerce-e2e-evidence-12345-1",
      digest: `sha256:${"a".repeat(64)}`,
      archive_sha256: "a".repeat(64),
      member_sha256: "b".repeat(64),
      run_id: "12345",
      attempt: 1,
      source_sha: SHA,
    },
    aggregate: {
      valid: true,
      eligible: true,
      repository: REPOSITORY,
      source_sha: SHA,
      run_id: "12345",
      attempt: 1,
      case_count: 8,
    },
    ...overrides,
  };
}

function cacheProof(mode, overrides = {}) {
  const isDocker = mode.startsWith("docker-");
  const cold = mode === "docker-cold" || mode === "beam-cold";
  return {
    mode,
    run: exactRun(),
    session: { repository: REPOSITORY, branch: BRANCH, sha: SHA, session_id: SESSION_ID },
    builder: {
      id: `builder-${mode}-12345-1`,
      created_for_run_id: "12345",
      created_for_attempt: 1,
      created_at: STARTED,
      fresh: cold,
      persistent: false,
    },
    cache: {
      kind: isDocker ? "buildkit" : "beam",
      imports_enabled: !cold,
      actual_import: !cold,
      actual_export: isDocker && mode === "docker-warm",
      imported_digest: !cold ? "sha256:layer" : null,
      exported_digest: isDocker && mode === "docker-warm" ? "sha256:layer-next" : null,
      log_sha256: "c".repeat(64),
      cache_key: `${mode}-resolved-key`,
      restore_prefix: `${mode}-restore-`,
      hit: !cold,
      miss_reason: cold ? "cache import disabled" : null,
      fallback: mode === "beam-fallback" || mode === "beam-lock-change",
      resolved_lock_before: mode === "beam-lock-change" ? "d".repeat(64) : "d".repeat(64),
      resolved_lock_after: mode === "beam-lock-change" ? "e".repeat(64) : "d".repeat(64),
      runtime: { elixir: "1.19.0", otp: "28.1", os: "Linux", arch: "X64", mix_env: "test" },
    },
    normal_command_outcome: "success",
    job_conclusion: "success",
    ...overrides,
  };
}

test("validateBrowserAcceptance accepts one exact-source, eligible aggregate with raw success", () => {
  assert.equal(validateBrowserAcceptance(browserProof()), true);
});

test("browser acceptance rejects an unrelated run even when its conclusion is green", () => {
  assert.throws(
    () => validateBrowserAcceptance(browserProof({ run: exactRun({ sha: OTHER_SHA }) })),
    /source SHA/,
  );
});

test("browser acceptance rejects raw verifier failure hidden by an advisory green conclusion", () => {
  assert.throws(
    () => validateBrowserAcceptance(browserProof({ raw_verifier_outcome: "failure" })),
    /raw verifier outcome/,
  );
});

test("browser acceptance rejects incomplete aggregate, wrong digest and over-budget timing", () => {
  assert.throws(
    () => validateBrowserAcceptance(browserProof({ aggregate: { valid: true, eligible: false } })),
    /aggregate/,
  );
  assert.throws(
    () => validateBrowserAcceptance(browserProof({ artifact: { ...browserProof().artifact, digest: `sha256:${"0".repeat(64)}` } })),
    /archive digest/,
  );
  assert.throws(
    () => validateBrowserAcceptance(browserProof({ job_completed_at: "2026-10-26T12:31:00Z" })),
    /1800 seconds/,
  );
});

test("cold cache acceptance requires a new builder and disabled imports", () => {
  assert.equal(validateCacheAcceptance(cacheProof("docker-cold")), true);
  assert.throws(
    () => validateCacheAcceptance(cacheProof("docker-cold", {
      builder: { ...cacheProof("docker-cold").builder, persistent: true },
    })),
    /fresh builder/,
  );
  assert.throws(
    () => validateCacheAcceptance(cacheProof("beam-cold", {
      cache: { ...cacheProof("beam-cold").cache, imports_enabled: true },
    })),
    /imports must be disabled/,
  );
});

test("warm and fallback cache claims require actual import/export log evidence and normal commands", () => {
  assert.equal(validateCacheAcceptance(cacheProof("docker-warm")), true);
  assert.equal(validateCacheAcceptance(cacheProof("beam-fallback")), true);
  assert.throws(
    () => validateCacheAcceptance(cacheProof("docker-warm", {
      cache: { ...cacheProof("docker-warm").cache, actual_import: false },
    })),
    /actual GHA import/,
  );
  assert.throws(
    () => validateCacheAcceptance(cacheProof("beam-lock-change", {
      normal_command_outcome: "failure",
    })),
    /normal command/,
  );
});

test("required cache modes are exact and ordered", () => {
  assert.deepEqual(REQUIRED_CACHE_MODES, [
    "docker-warm",
    "docker-cold",
    "beam-fallback",
    "beam-lock-change",
    "beam-cold",
  ]);
});

test("collectRun retains repeated-mode attempts in distinct directories and rejects session mismatch without mutation", async (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-session-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const commands = successfulCommandDouble();
  const flags = {
    repo: REPOSITORY,
    branch: BRANCH,
    sha: SHA,
    sessionId: SESSION_ID,
    mode: "docker-warm",
    outputDir: path.join(root, "candidate"),
  };

  const first = await collectRun(flags, { command: commands, pollMilliseconds: 0 });
  const second = await collectRun(flags, { command: commands, pollMilliseconds: 0 });
  assert.notEqual(first.runDirectory, second.runDirectory);
  assert.equal(fs.existsSync(first.receiptPath), true);
  assert.equal(fs.existsSync(second.receiptPath), true);

  const manifestPath = path.join(flags.outputDir, "phase182-session.json");
  const before = fs.readFileSync(manifestPath, "utf8");
  await assert.rejects(
    collectRun({ ...flags, sha: OTHER_SHA }, { command: commands, pollMilliseconds: 0 }),
    /session.*identity/i,
  );
  assert.equal(fs.readFileSync(manifestPath, "utf8"), before);
});

test("collectRun ignores stale success, exhausts pagination, and binds only a newly dispatched exact-ref run", async (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-collect-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const commands = successfulCommandDouble({ staleRun: true, paginated: true });
  const result = await collectRun({
    repo: REPOSITORY,
    branch: BRANCH,
    sha: SHA,
    sessionId: SESSION_ID,
    mode: "full",
    outputDir: path.join(root, "candidate"),
  }, { command: commands, pollMilliseconds: 0 });
  assert.equal(result.run.id, "12345");
  assert.equal(result.run.sha, SHA);
  assert.equal(result.run.branch, BRANCH);
  assert.equal(result.browser.eligible, true);
  assert.equal(commands.calls.some((call) => call.includes("--paginate")), true);
});

test("collectRun fails closed when run/job/artifact access or dispatch is denied", async (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-denied-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  for (const denied of ["dispatch", "jobs", "artifacts"]) {
    const commands = successfulCommandDouble({ denied });
    await assert.rejects(
      collectRun({
        repo: REPOSITORY,
        branch: BRANCH,
        sha: SHA,
        sessionId: `${SESSION_ID}-${denied}`,
        mode: "full",
        outputDir: path.join(root, denied),
      }, { command: commands, pollMilliseconds: 0 }),
      /denied|403|permission/i,
    );
  }
});

function successfulCommandDouble({ staleRun = false, paginated = false, denied = null } = {}) {
  const calls = [];
  let dispatched = false;
  const run = {
    databaseId: 12345,
    headSha: SHA,
    headBranch: BRANCH,
    event: "workflow_dispatch",
    status: "completed",
    conclusion: "success",
    createdAt: STARTED,
    updatedAt: COMPLETED,
    runAttempt: 1,
    workflowName: "CI",
    workflowPath: ".github/workflows/ci.yml",
  };
  const jobs = [
    { id: 101, name: "core (required)", status: "completed", conclusion: "success", steps: [] },
    { id: 102, name: "package (required)", status: "completed", conclusion: "success", steps: [] },
    { id: 103, name: "repository-contracts (required)", status: "completed", conclusion: "success", steps: [] },
    { id: 104, name: "backend (required)", status: "completed", conclusion: "success", steps: [] },
    { id: 105, name: "ecommerce-mounted (required)", status: "completed", conclusion: "success", steps: [] },
    { id: 106, name: "coverage (advisory)", status: "completed", conclusion: "success", steps: [] },
    { id: 107, name: "closeout-attestation", status: "completed", conclusion: "success", steps: [] },
    { id: 108, name: "ecommerce-e2e (advisory)", status: "completed", conclusion: "success", steps: [
      { name: "Run advisory full E2E proof", status: "completed", conclusion: "success", outcome: "success", started_at: STARTED, completed_at: COMPLETED },
    ] },
  ];
  const artifacts = [{
    id: 201,
    name: "ecommerce-e2e-evidence-12345-1",
    expired: false,
    digest: `sha256:${"a".repeat(64)}`,
    workflow_run: { id: 12345, head_sha: SHA },
    archive: Buffer.from("phase182-fixture-archive"),
    members: {
      "phase105-evidence.json": JSON.stringify({ schema: 1, eligibility: { eligible: true }, source_sha: SHA, run_id: "12345", run_attempt: 1 }),
      "phase105-playwright.json": "{}",
      "phase105-playwright-list.json": "{}",
    },
  }];

  function command(_bin, args) {
    calls.push([...args]);
    const text = args.join(" ");
    if (denied === "dispatch" && text.includes("workflow run")) throw new Error("HTTP 403 permission denied to dispatch workflow");
    if (denied === "jobs" && text.includes("/jobs")) throw new Error("HTTP 403 permission denied to read jobs");
    if (denied === "artifacts" && text.includes("/artifacts")) throw new Error("HTTP 403 permission denied to read artifacts");
    if (text === "auth status") return { stdout: "Logged in", status: 0 };
    if (text.includes("repo view")) return { stdout: JSON.stringify({ nameWithOwner: REPOSITORY }), status: 0 };
    if (text.includes("run list")) {
      const selected = dispatched ? [run] : [];
      const old = staleRun ? [{ ...run, databaseId: 111, headSha: OTHER_SHA }] : [];
      return { stdout: JSON.stringify([...old, ...selected]), status: 0 };
    }
    if (text.includes("workflow run")) { dispatched = true; return { stdout: "", status: 0 }; }
    if (text.includes("/actions/runs/12345/attempts/1/jobs")) {
      return { stdout: JSON.stringify(paginated ? [{ jobs: jobs.slice(0, 4) }, { jobs: jobs.slice(4) }] : { jobs }), status: 0 };
    }
    if (text.includes("/actions/runs/12345/artifacts")) {
      return { stdout: JSON.stringify(paginated ? [{ artifacts: [] }, { artifacts }] : { artifacts }), status: 0 };
    }
    if (text.includes("/actions/artifacts/201/zip")) return { stdout: artifacts[0].archive, status: 0 };
    if (text.includes("ecommerce-e2e-evidence-12345-1")) return { stdout: JSON.stringify(artifacts[0].members), status: 0 };
    if (text.includes("run view")) return { stdout: JSON.stringify({ ...run, databaseId: 12345 }), status: 0 };
    throw new Error(`unexpected command: ${text}`);
  }
  command.calls = calls;
  return command;
}
