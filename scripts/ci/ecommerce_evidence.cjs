"use strict";

const fs = require("node:fs");
const crypto = require("node:crypto");
const path = require("node:path");

const MAX_CASES = 50000;
const MAX_SUITE_DEPTH = 100;
const MAX_REPORT_ERRORS = 100;
const MAX_ERROR_TEXT = 2000;
const MAX_JSON_BYTES = 8 * 1024 * 1024;
const MAX_NDJSON_BYTES = 16 * 1024 * 1024;
const MAX_ARTIFACT_BYTES = 64 * 1024 * 1024;
const MAX_TOTAL_ARTIFACT_BYTES = 256 * 1024 * 1024;
const MAX_ARTIFACTS = 256;
const RECEIPT_NAME = "phase105-evidence.json";
const SUMMARY_NAME = "phase105-evidence-summary.md";
const INPUT_NAME = "phase105-evidence-input.json";
const INVENTORY_NAME = "phase105-playwright-list.json";
const PLAYWRIGHT_NAME = "phase105-playwright.json";
const EVENTS_NAME = "phase105-evidence.ndjson";
const REQUIRED_ARTIFACT_PATHS = [
  INPUT_NAME,
  INVENTORY_NAME,
  PLAYWRIGHT_NAME,
  EVENTS_NAME,
  "admin-light-parity.json",
  "contrast-report.json",
  "lifecycle.json",
  "playwright-report/index.html"
];
const ALLOWED_ARTIFACT_PREFIXES = [
  "playwright-report/",
  "test-results/",
  "ui-review-artifacts/iteration3-journeys/",
  "logs/",
  "compose/"
];
const REQUIRED_STAGES = ["inventory", "browser", "light_parity", "contrast", "artifact_copy"];

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function inspectContrastReport(report, stageExitCode) {
  const summary = isRecord(report?.summary) ? report.summary : {};
  const findings = Array.isArray(report?.findings) ? report.findings : [];
  const findingShapeValid = findings.every((finding) =>
    isRecord(finding) &&
    finding.producer === "token" &&
    ["pass", "aa-fail", "aaa-body-advisory"].includes(finding.severity) &&
    typeof finding.pass_aa === "boolean" &&
    ((finding.severity === "aa-fail") === (finding.pass_aa === false))
  );
  const actualAaFailures = findings.filter((finding) => finding?.severity === "aa-fail").length;
  const actualAaaAdvisories = findings.filter((finding) => finding?.severity === "aaa-body-advisory").length;
  const summaryValid =
    Number.isSafeInteger(summary.aa_fail) && summary.aa_fail >= 0 &&
    Number.isSafeInteger(summary.aaa_advisory) && summary.aaa_advisory >= 0 &&
    Number.isSafeInteger(summary.total) && summary.total >= 0 &&
    summary.aa_fail === actualAaFailures &&
    summary.aaa_advisory === actualAaaAdvisories &&
    summary.total === findings.length;
  const valid =
    isRecord(report) &&
    report.schema === "scrypath.contrast.v1" &&
    report.producer === "token" &&
    typeof report.generated === "string" && report.generated.length > 0 &&
    Array.isArray(report.findings) && report.findings.length > 0 && findingShapeValid && summaryValid;
  return {
    valid,
    passed: valid && stageExitCode === 0 && summary.aa_fail === 0,
    aa_fail: Number.isSafeInteger(summary.aa_fail) ? summary.aa_fail : null,
    total: Number.isSafeInteger(summary.total) ? summary.total : null
  };
}

function cleanText(value, label) {
  if (typeof value !== "string" || value.trim() === "") {
    throw new TypeError(`${label} must be a non-empty string`);
  }
  return value.trim();
}

function normalizeRepoFile(value, repoRoot = process.cwd()) {
  const raw = cleanText(value, "file").replaceAll("\\", "/");
  let relative;

  if (path.posix.isAbsolute(raw)) {
    const absolute = path.resolve(raw);
    const root = path.resolve(repoRoot);
    relative = path.relative(root, absolute).replaceAll("\\", "/");
    if (relative === ".." || relative.startsWith("../") || path.posix.isAbsolute(relative)) {
      throw new TypeError("file must be inside the repository root");
    }
  } else {
    relative = path.posix.normalize(raw.replace(/^\.\//, ""));
    if (relative === ".." || relative.startsWith("../") || path.posix.isAbsolute(relative)) {
      throw new TypeError("file must be repository-relative");
    }
  }

  if (relative.startsWith("e2e/")) relative = `examples/scrypath_ecommerce/${relative}`;
  if (relative === "." || relative === "") throw new TypeError("file must identify a source file");
  return relative;
}

function inferEntrypoint(file, titlePath) {
  const basename = path.posix.basename(file);
  const title = titlePath.join(" ").toLowerCase();
  if (basename === "phase173_shell.spec.ts") {
    if (/\bmounted\s+and\s+standalone\b/.test(title)) return "both";
    if (/^.*\bmounted\b/.test(title)) return "mounted";
    if (/^.*\bstandalone\b/.test(title)) return "standalone";
  }
  if (basename === "ui_followup.spec.ts" || basename === "ui_iteration3.spec.ts") {
    if (/^.*\bmounted\b/.test(title)) return "mounted";
    if (/^.*\bstandalone\b/.test(title)) return "standalone";
  }
  return "shared";
}

function caseIdentity(value, options = {}) {
  if (!isRecord(value)) throw new TypeError("case identity must be an object");
  const file = normalizeRepoFile(value.file, options.repoRoot);
  const project = cleanText(value.project ?? value.projectName, "project");
  const titlePath = value.title_path ?? value.titlePath;
  if (!Array.isArray(titlePath) || titlePath.length === 0) {
    throw new TypeError("title_path must be a non-empty array of strings");
  }
  const titles = titlePath.map((title, index) => cleanText(title, `title_path[${index}]`));
  const entrypoint = cleanText(value.entrypoint ?? inferEntrypoint(file, titles), "entrypoint");
  const identity = { file, project, title_path: titles, entrypoint };
  return { ...identity, key: JSON.stringify([file, project, titles, entrypoint]) };
}

function errorReason(code, message, identity) {
  return { code, message: String(message).slice(0, MAX_ERROR_TEXT), ...(identity ? { identity } : {}) };
}

function normalizeAttempt(result, expectedStatus, index) {
  if (!isRecord(result)) throw new TypeError(`attempt ${index} must be an object`);
  const retry = Number.isInteger(result.retry) && result.retry >= 0 ? result.retry : null;
  const status = typeof result.status === "string" ? result.status : "unknown";
  return {
    retry,
    status,
    expected_status: expectedStatus,
    started_at: typeof result.startTime === "string" ? result.startTime : null,
    duration_ms: Number.isFinite(result.duration) && result.duration >= 0 ? result.duration : null,
    error: typeof result.error?.message === "string" ? result.error.message.slice(0, MAX_ERROR_TEXT) : null
  };
}

function parsePlaywrightCases(report, { repoRoot = process.cwd(), includeAttempts = false, label = "report" } = {}) {
  const reasons = [];
  const cases = [];
  let specCount = 0;
  let visited = 0;

  if (!isRecord(report) || !Array.isArray(report.suites)) {
    return { cases, specCount, reasons: [errorReason(`malformed_${label}`, `${label} must contain a suites array`)] };
  }
  if (Array.isArray(report.errors) && report.errors.length > 0) {
    reasons.push(errorReason(`${label}_errors`, `${label} contains ${Math.min(report.errors.length, MAX_REPORT_ERRORS)} reporter error(s)`));
  } else if (report.errors !== undefined && !Array.isArray(report.errors)) {
    reasons.push(errorReason(`malformed_${label}_errors`, `${label}.errors must be an array when present`));
  }

  function visitSuite(suite, parents, inheritedFile, depth) {
    if (++visited > MAX_CASES * 4) {
      reasons.push(errorReason(`${label}_too_large`, `${label} exceeds the bounded suite limit`));
      return;
    }
    if (!isRecord(suite) || depth > MAX_SUITE_DEPTH) {
      reasons.push(errorReason(`malformed_${label}_suite`, `${label} contains a malformed or excessively nested suite`));
      return;
    }
    const suiteFile = typeof suite.file === "string" && suite.file.trim() !== "" ? suite.file : inheritedFile;
    const suiteTitle = typeof suite.title === "string" ? suite.title.trim() : "";
    const titles = suiteTitle ? [...parents, suiteTitle] : parents;
    if (suite.specs !== undefined && !Array.isArray(suite.specs)) {
      reasons.push(errorReason(`malformed_${label}_specs`, `${label} suite specs must be an array`));
    }
    for (const spec of Array.isArray(suite.specs) ? suite.specs : []) {
      specCount += 1;
      if (!isRecord(spec) || !Array.isArray(spec.tests)) {
        reasons.push(errorReason(`malformed_${label}_spec`, `${label} contains a spec without a tests array`));
        continue;
      }
      const file = typeof spec.file === "string" && spec.file.trim() !== "" ? spec.file : suiteFile;
      const specTitle = typeof spec.title === "string" ? spec.title.trim() : "";
      const titlePath = specTitle ? [...titles, specTitle] : titles;
      if (!file || spec.tests.length === 0) {
        reasons.push(errorReason(`incomplete_${label}_spec`, `${label} spec is missing a source file or project tests`));
        continue;
      }
      for (const testCase of spec.tests) {
        if (!isRecord(testCase)) {
          reasons.push(errorReason(`malformed_${label}_test`, `${label} contains a malformed project test`));
          continue;
        }
        try {
          const identity = caseIdentity(
            { file, project: testCase.projectName ?? testCase.project, title_path: titlePath },
            { repoRoot }
          );
          const expectedStatus = typeof testCase.expectedStatus === "string" ? testCase.expectedStatus : "unknown";
          const rawResults = testCase.results;
          const attempts = includeAttempts && Array.isArray(rawResults)
            ? rawResults.slice(0, MAX_CASES).map((result, index) => normalizeAttempt(result, expectedStatus, index))
            : [];
          cases.push({
            identity,
            expected_status: expectedStatus,
            outcome: typeof testCase.status === "string" ? testCase.status : null,
            attempts
          });
        } catch (error) {
          reasons.push(errorReason(`invalid_${label}_identity`, error.message));
        }
        if (cases.length > MAX_CASES) {
          reasons.push(errorReason(`${label}_too_many_cases`, `${label} exceeds the bounded case limit`));
          return;
        }
      }
    }
    if (suite.suites !== undefined && !Array.isArray(suite.suites)) {
      reasons.push(errorReason(`malformed_${label}_children`, `${label} nested suites must be an array`));
    }
    for (const child of Array.isArray(suite.suites) ? suite.suites : []) {
      visitSuite(child, titles, suiteFile, depth + 1);
    }
  }

  for (const suite of report.suites) visitSuite(suite, [], null, 0);
  if (cases.length === 0) reasons.push(errorReason(`empty_${label}`, `${label} contains zero executable project cases`));
  return { cases, specCount, reasons };
}

function addDuplicateReasons(cases, kind, reasons) {
  const seen = new Set();
  for (const item of cases) {
    const key = item.identity.key;
    if (seen.has(key)) reasons.push(errorReason(`duplicate_${kind}_identity`, `${kind} contains duplicate composite identity`, key));
    seen.add(key);
  }
}

function mandatoryInventoryReasons(cases) {
  const reasons = [];
  const requiredFiles = ["ui_followup.spec.ts", "ui_iteration3.spec.ts", "phase173_shell.spec.ts"];
  for (const basename of requiredFiles) {
    if (!cases.some((item) => path.posix.basename(item.identity.file) === basename)) {
      reasons.push(errorReason("missing_required_suite", `Full inventory is missing ${basename}`));
    }
  }
  const phase173 = cases.filter((item) => path.posix.basename(item.identity.file) === "phase173_shell.spec.ts");
  for (const entrypoint of ["mounted", "standalone"]) {
    if (!phase173.some((item) => item.identity.entrypoint === entrypoint)) {
      reasons.push(errorReason("missing_required_entrypoint", `Phase 173 inventory is missing the ${entrypoint} entrypoint`));
    }
  }
  return reasons;
}

function reconcileInventory({ inventory, report, repoRoot = process.cwd(), allowedSkips = [], requireMandatoryCases = false } = {}) {
  const inventoryResult = parsePlaywrightCases(inventory, { repoRoot, label: "inventory" });
  const reportResult = parsePlaywrightCases(report, { repoRoot, includeAttempts: true, label: "report" });
  const reasons = [...inventoryResult.reasons, ...reportResult.reasons];
  addDuplicateReasons(inventoryResult.cases, "inventory", reasons);
  addDuplicateReasons(reportResult.cases, "report", reasons);

  const inventoryByKey = new Map(inventoryResult.cases.map((item) => [item.identity.key, item]));
  const reportByKey = new Map(reportResult.cases.map((item) => [item.identity.key, item]));
  for (const key of inventoryByKey.keys()) {
    if (!reportByKey.has(key)) reasons.push(errorReason("missing_report_case", "Inventory case has no execution result", key));
  }
  for (const key of reportByKey.keys()) {
    if (!inventoryByKey.has(key)) reasons.push(errorReason("unexpected_report_case", "Execution report contains a case outside the inventory", key));
  }

  const skipReasons = new Map();
  if (!Array.isArray(allowedSkips)) {
    reasons.push(errorReason("malformed_skip_allowlist", "allowedSkips must be an array"));
  } else {
    for (const entry of allowedSkips) {
      if (isRecord(entry) && typeof entry.identity === "string" && entry.identity && typeof entry.reason === "string" && entry.reason.trim()) {
        skipReasons.set(entry.identity, entry.reason.trim());
      }
    }
  }

  const reconciled = [];
  for (const [key, expected] of inventoryByKey) {
    const actual = reportByKey.get(key);
    if (!actual) continue;
    const attempts = actual.attempts;
    if (actual.expected_status !== "passed") {
      reasons.push(errorReason("expected_failure_masking", `Case expected status is ${actual.expected_status}`, key));
    }
    if (actual.outcome === "skipped" || actual.expected_status === "skipped" || attempts.some((attempt) => attempt.status === "skipped")) {
      const skipReason = skipReasons.get(key);
      reasons.push(errorReason(skipReason ? "intentional_skip_not_clean" : "unexplained_skip", skipReason || "Skipped case has no identity-scoped reason", key));
    }
    if (!Array.isArray(attempts) || attempts.length === 0) {
      reasons.push(errorReason("missing_attempt", "Execution case has no result attempt", key));
    }
    for (const attempt of attempts) {
      if (attempt.retry === null) reasons.push(errorReason("invalid_attempt_retry", "Attempt retry index must be a non-negative integer", key));
      else if (attempt.retry !== 0) reasons.push(errorReason("retry_attempt", `Attempt retry index ${attempt.retry} is not clean proof`, key));
      if (attempt.status !== "passed") reasons.push(errorReason("unsuccessful_attempt", `Attempt status is ${attempt.status}`, key));
    }
    if (attempts.length > 1) reasons.push(errorReason("multiple_attempts", "Case produced more than one attempt", key));
    reconciled.push({
      ...expected.identity,
      attempts: attempts.map((attempt) => ({ ...attempt })),
      expected_status: actual.expected_status,
      outcome: actual.outcome || (attempts.length === 1 ? attempts[0].status : "missing")
    });
  }

  if (requireMandatoryCases) reasons.push(...mandatoryInventoryReasons(inventoryResult.cases));
  const uniqueReasons = new Map();
  for (const reason of reasons) {
    const key = `${reason.code}:${reason.identity || ""}:${reason.message}`;
    uniqueReasons.set(key, reason);
  }
  const normalizedReasons = [...uniqueReasons.values()].sort((left, right) =>
    `${left.code}:${left.identity || ""}:${left.message}`.localeCompare(`${right.code}:${right.identity || ""}:${right.message}`)
  );
  reconciled.sort((left, right) => left.key.localeCompare(right.key));
  return {
    eligible: normalizedReasons.length === 0,
    cases: reconciled,
    case_count: reconciled.length,
    inventory_case_count: inventoryResult.cases.length,
    report_case_count: reportResult.cases.length,
    spec_count: inventoryResult.specCount,
    attempts_total: reconciled.reduce((total, item) => total + item.attempts.length, 0),
    reasons: normalizedReasons
  };
}

function normalizeReasons(reasons) {
  const unique = new Map();
  for (const reason of reasons) {
    const key = `${reason.code}:${reason.identity || ""}:${reason.message}`;
    unique.set(key, reason);
  }
  return [...unique.values()].sort((left, right) =>
    `${left.code}:${left.identity || ""}:${left.message}`.localeCompare(`${right.code}:${right.identity || ""}:${right.message}`)
  );
}

function resolveRunRoot(runDir) {
  if (typeof runDir !== "string" || runDir.trim() === "") throw new TypeError("an explicit --run-dir is required");
  const root = fs.realpathSync(path.resolve(runDir));
  if (!fs.statSync(root).isDirectory()) throw new TypeError("--run-dir must identify a directory");
  return root;
}

function normalizeArtifactPath(value, { allowOutputs = false } = {}) {
  if (typeof value !== "string" || value.trim() === "" || value.includes("\0")) {
    throw new TypeError("artifact path must be a non-empty relative path");
  }
  const normalized = value.trim().replaceAll("\\", "/");
  if (normalized.startsWith("/") || /^[A-Za-z]:\//.test(normalized)) throw new TypeError("absolute artifact paths are forbidden");
  const segments = normalized.split("/");
  if (segments.some((segment) => segment === ".." || segment === "")) throw new TypeError("artifact traversal is forbidden");
  const clean = path.posix.normalize(normalized);
  if (
    !REQUIRED_ARTIFACT_PATHS.includes(clean) &&
    !(allowOutputs && (clean === RECEIPT_NAME || clean === SUMMARY_NAME)) &&
    !ALLOWED_ARTIFACT_PREFIXES.some((prefix) => clean.startsWith(prefix))
  ) {
    throw new TypeError("artifact path is outside the evidence allowlist");
  }
  return clean;
}

function resolveArtifact(root, relative, options = {}) {
  const normalized = normalizeArtifactPath(relative, options);
  const parts = normalized.split("/");
  let current = root;
  for (const part of parts) {
    current = path.join(current, part);
    const stat = fs.lstatSync(current);
    if (stat.isSymbolicLink()) throw new TypeError("artifact path contains a symbolic link");
  }
  const real = fs.realpathSync(current);
  const rel = path.relative(root, real);
  if (rel === ".." || rel.startsWith(`..${path.sep}`) || path.isAbsolute(rel)) {
    throw new TypeError("artifact path resolves outside the run directory");
  }
  const stat = fs.statSync(real);
  if (!stat.isFile()) throw new TypeError("artifact path must identify a regular file");
  if (stat.size > MAX_ARTIFACT_BYTES) throw new RangeError("artifact exceeds the per-file size limit");
  return { path: real, relative: normalized, stat };
}

function readJsonArtifact(root, relative, reasons, { required = true } = {}) {
  try {
    const artifact = resolveArtifact(root, relative);
    if (artifact.stat.size > MAX_JSON_BYTES) throw new RangeError("JSON artifact exceeds the parsing size limit");
    const value = JSON.parse(fs.readFileSync(artifact.path, "utf8"));
    if (!isRecord(value)) throw new TypeError("JSON artifact root must be an object");
    return value;
  } catch (error) {
    const code = error.code === "ENOENT" && required ? "missing_required_artifact" : "malformed_json_artifact";
    reasons.push(errorReason(code, `${relative}: ${error.message}`));
    return null;
  }
}

function hashArtifact(root, relative, reasons, { required = true, copied = true, copyStatus = "success", remainingBytes = MAX_TOTAL_ARTIFACT_BYTES } = {}) {
  let pathName = String(relative);
  try {
    pathName = normalizeArtifactPath(relative);
    if (!copied || copyStatus !== "success") {
      reasons.push(errorReason("artifact_copy_failed", `Artifact copy did not succeed for ${pathName}`));
    }
    const artifact = resolveArtifact(root, pathName);
    if (artifact.stat.size > remainingBytes) {
      reasons.push(errorReason("artifacts_too_large", `Combined evidence artifacts exceed the ${MAX_TOTAL_ARTIFACT_BYTES}-byte run limit at ${pathName}`));
      return {
        path: pathName,
        required,
        copied: Boolean(copied),
        copy_status: copyStatus,
        present: true,
        size_bytes: artifact.stat.size,
        sha256: null
      };
    }
    const digest = crypto.createHash("sha256").update(fs.readFileSync(artifact.path)).digest("hex");
    return {
      path: pathName,
      required,
      copied: Boolean(copied),
      copy_status: copyStatus,
      present: true,
      size_bytes: artifact.stat.size,
      sha256: digest
    };
  } catch (error) {
    const missing = error.code === "ENOENT";
    if (required) reasons.push(errorReason(missing ? "missing_required_artifact" : "unsafe_artifact_path", `${pathName}: ${error.message}`));
    return {
      path: pathName,
      required,
      copied: Boolean(copied),
      copy_status: copyStatus,
      present: false,
      size_bytes: null,
      sha256: null
    };
  }
}

function readEvents(root, reasons) {
  let artifact;
  try {
    artifact = resolveArtifact(root, EVENTS_NAME);
  } catch (error) {
    reasons.push(errorReason(error.code === "ENOENT" ? "missing_required_artifact" : "unsafe_artifact_path", `${EVENTS_NAME}: ${error.message}`));
    return [];
  }
  if (artifact.stat.size > MAX_NDJSON_BYTES) {
    reasons.push(errorReason("events_too_large", "Raw evidence events exceed the parsing size limit"));
    return [];
  }
  const raw = fs.readFileSync(artifact.path, "utf8");
  const lines = raw.split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
  if (lines.length === 0) reasons.push(errorReason("empty_evidence_events", "Raw evidence event stream is empty"));
  const events = [];
  for (let index = 0; index < lines.length; index += 1) {
    try {
      const event = JSON.parse(lines[index]);
      if (!isRecord(event) || typeof event.operation !== "string" || event.operation.trim() === "") {
        throw new TypeError("each event must be an object with an operation");
      }
      events.push(event);
    } catch (error) {
      reasons.push(errorReason("malformed_evidence_event", `Event ${index + 1}: ${error.message}`));
    }
  }
  return events;
}

function requiredString(record, key, label, reasons) {
  const value = record?.[key];
  if (typeof value !== "string" || value.trim() === "") {
    reasons.push(errorReason("missing_provenance", `${label}.${key} is required`));
    return "";
  }
  return value.trim();
}

function validSha(value) {
  return typeof value === "string" && /^[a-f0-9]{40}$/i.test(value);
}

function validDigest(value) {
  return typeof value === "string" && /^sha256:[a-f0-9]{64}$/i.test(value);
}

function normalizeStage(name, stage, reasons) {
  if (!isRecord(stage)) {
    reasons.push(errorReason("missing_stage", `Required ${name} stage is missing`));
    return { started_at: null, ended_at: null, exit_code: null };
  }
  const startedAt = typeof stage.started_at === "string" ? stage.started_at : null;
  const endedAt = typeof stage.ended_at === "string" ? stage.ended_at : null;
  const startMs = startedAt ? Date.parse(startedAt) : NaN;
  const endMs = endedAt ? Date.parse(endedAt) : NaN;
  const exitCode = Number.isInteger(stage.exit_code) ? stage.exit_code : null;
  if (!Number.isFinite(startMs) || !Number.isFinite(endMs) || endMs < startMs) {
    reasons.push(errorReason("invalid_stage_timing", `${name} stage needs ordered start and end timestamps`));
  }
  if (exitCode === null) reasons.push(errorReason("missing_raw_status", `${name} stage needs an integer raw exit code`));
  else if (exitCode !== 0) reasons.push(errorReason(name === "browser" ? "raw_verifier_failed" : "stage_failed", `${name} stage exited ${exitCode}`));
  return { started_at: startedAt, ended_at: endedAt, exit_code: exitCode };
}

function buildReceipt(runDir, { generatedAt = new Date().toISOString() } = {}) {
  const reasons = [];
  const root = resolveRunRoot(runDir);
  const input = readJsonArtifact(root, INPUT_NAME, reasons);
  const inventory = readJsonArtifact(root, INVENTORY_NAME, reasons);
  const report = readJsonArtifact(root, PLAYWRIGHT_NAME, reasons);
  const lightParity = readJsonArtifact(root, "admin-light-parity.json", reasons);
  const contrast = readJsonArtifact(root, "contrast-report.json", reasons);
  const lifecycle = readJsonArtifact(root, "lifecycle.json", reasons);
  const manifest = input || {};
  const sourceInput = isRecord(manifest.source) ? manifest.source : {};
  const imageInput = isRecord(manifest.images) ? manifest.images : {};
  const composeInput = isRecord(manifest.compose) ? manifest.compose : {};
  const browserInput = isRecord(manifest.browser) ? manifest.browser : {};
  const workflowInput = isRecord(manifest.workflow) ? manifest.workflow : {};
  const cleanupInput = isRecord(manifest.cleanup) ? manifest.cleanup : {};
  const stageInput = isRecord(manifest.stages) ? manifest.stages : {};
  const checkerInput = isRecord(manifest.checkers) ? manifest.checkers : {};

  const sourceMode = sourceInput.mode === "hosted" || sourceInput.mode === "local" ? sourceInput.mode : "unknown";
  if (sourceMode === "unknown") reasons.push(errorReason("invalid_source_mode", "source.mode must be hosted or local"));
  const checkoutHead = requiredString(sourceInput, "checkout_head", "source", reasons);
  const builtSourceSha = requiredString(sourceInput, "built_source_sha", "source", reasons);
  const eventSha = typeof sourceInput.event_sha === "string" && sourceInput.event_sha.trim() ? sourceInput.event_sha.trim() : null;
  const dirty = sourceInput.dirty;
  if (typeof dirty !== "boolean") reasons.push(errorReason("missing_source_dirty_state", "source.dirty must be a boolean"));
  if (!validSha(checkoutHead)) reasons.push(errorReason("invalid_checkout_sha", "source.checkout_head must be a full Git SHA"));
  if (!validSha(builtSourceSha)) reasons.push(errorReason("invalid_built_source_sha", "source.built_source_sha must be a full Git SHA"));
  if (sourceMode === "hosted") {
    if (!validSha(eventSha)) reasons.push(errorReason("invalid_event_sha", "hosted source.event_sha must be a full Git SHA"));
    if (dirty !== false) reasons.push(errorReason("hosted_source_dirty", "hosted proof requires a clean checkout"));
    if (eventSha !== checkoutHead || eventSha !== builtSourceSha || workflowInput.sha !== eventSha) {
      reasons.push(errorReason("source_sha_mismatch", "checkout, event, built source and workflow SHA must match"));
    }
  } else if (dirty === true) {
    if (!validDigest(sourceInput.dirty_fingerprint)) {
      reasons.push(errorReason("missing_dirty_fingerprint", "dirty local proof requires a full SHA-256 source fingerprint"));
    }
  } else if (sourceMode === "local" && checkoutHead !== builtSourceSha) {
    reasons.push(errorReason("source_sha_mismatch", "clean local checkout and built source SHA must match"));
  }

  const imageKinds = ["application", "browser"];
  const images = {};
  for (const kind of imageKinds) {
    const image = isRecord(imageInput[kind]) ? imageInput[kind] : {};
    const builtId = requiredString(image, "built_id", `images.${kind}`, reasons);
    const runtimeId = requiredString(image, "runtime_id", `images.${kind}`, reasons);
    const imageSourceSha = requiredString(image, "source_sha", `images.${kind}`, reasons);
    if (!validDigest(builtId) || !validDigest(runtimeId)) reasons.push(errorReason("invalid_image_id", `${kind} built/runtime IDs must be immutable sha256 digests`));
    if (builtId !== runtimeId) reasons.push(errorReason("image_identity_mismatch", `${kind} built image differs from the runtime image`));
    if (sourceMode === "hosted" && imageSourceSha !== eventSha) {
      reasons.push(errorReason("image_source_mismatch", `${kind} image source does not match the hosted event SHA`));
    }
    if (sourceMode === "local" && dirty === true && image.source_fingerprint !== sourceInput.dirty_fingerprint) {
      reasons.push(errorReason("image_source_mismatch", `${kind} image does not match the dirty source fingerprint`));
    }
    if (sourceMode === "local" && dirty !== true && imageSourceSha !== checkoutHead) {
      reasons.push(errorReason("image_source_mismatch", `${kind} image source does not match the local checkout SHA`));
    }
    images[kind] = {
      built_id: builtId,
      runtime_id: runtimeId,
      source_sha: imageSourceSha,
      source_fingerprint: typeof image.source_fingerprint === "string" ? image.source_fingerprint : null
    };
  }

  const composeScope = requiredString(composeInput, "scope", "compose", reasons);
  const composeProject = requiredString(composeInput, "project", "compose", reasons);
  const targets = Array.isArray(composeInput.targets) ? composeInput.targets.filter((target) => typeof target === "string") : [];
  const modelDigest = requiredString(composeInput, "model_digest", "compose", reasons);
  if (composeScope !== "full") reasons.push(errorReason("wrong_compose_scope", "Clean browser proof requires full Compose scope"));
  if (!targets.includes("web") || !targets.includes("standalone_ops")) {
    reasons.push(errorReason("missing_compose_target", "Full proof requires web and standalone_ops targets"));
  }
  if (!validDigest(modelDigest)) reasons.push(errorReason("invalid_compose_digest", "compose.model_digest must be a full SHA-256 digest"));

  const browserEngine = requiredString(browserInput, "engine", "browser", reasons);
  const browserVersion = requiredString(browserInput, "version", "browser", reasons);
  const packageName = requiredString(browserInput, "package", "browser", reasons);
  const packageVersion = requiredString(browserInput, "package_version", "browser", reasons);
  if (browserEngine !== "chromium") reasons.push(errorReason("wrong_browser_engine", "Browser proof must identify Chromium"));
  if (!/^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/.test(packageVersion)) {
    reasons.push(errorReason("invalid_browser_package_version", "Browser package version must be exact semver"));
  }

  const workflow = {
    event: requiredString(workflowInput, "event", "workflow", reasons),
    ref: requiredString(workflowInput, "ref", "workflow", reasons),
    sha: requiredString(workflowInput, "sha", "workflow", reasons),
    run_id: requiredString(workflowInput, "run_id", "workflow", reasons),
    run_attempt: Number.isInteger(workflowInput.run_attempt) ? workflowInput.run_attempt : null,
    job_name: requiredString(workflowInput, "job_name", "workflow", reasons),
    job_conclusion: requiredString(workflowInput, "job_conclusion", "workflow", reasons)
  };
  if (!validSha(workflow.sha)) reasons.push(errorReason("invalid_workflow_sha", "workflow.sha must be a full Git SHA"));
  if (!Number.isInteger(workflow.run_attempt) || workflow.run_attempt < 1) reasons.push(errorReason("invalid_workflow_attempt", "workflow.run_attempt must be a positive integer"));
  if (workflow.job_conclusion !== "success") reasons.push(errorReason("workflow_failed", `workflow job conclusion is ${workflow.job_conclusion}`));

  const stages = {};
  for (const name of REQUIRED_STAGES) stages[name] = normalizeStage(name, stageInput[name], reasons);

  const checkers = {};
  for (const [name, file, checker] of [
    ["light_parity", "admin-light-parity.json", lightParity],
    ["contrast", "contrast-report.json", contrast]
  ]) {
    const inputChecker = isRecord(checkerInput[name]) ? checkerInput[name] : {};
    const declaredPath = typeof inputChecker.path === "string" ? inputChecker.path : "";
    const contrastResult = name === "contrast" ? inspectContrastReport(checker, stages.contrast?.exit_code) : null;
    const checkerStatus = name === "contrast"
      ? (contrastResult.passed ? "pass" : "fail")
      : typeof checker?.status === "string" ? checker.status : "missing";
    if (declaredPath !== file) reasons.push(errorReason("invalid_checker_path", `${name} checker must use ${file}`));
    if (name === "contrast" && !contrastResult.valid) {
      reasons.push(errorReason("invalid_contrast_report", "contrast report must follow scrypath.contrast.v1 with consistent typed findings and summary counts"));
    }
    if (inputChecker.status !== "pass" || checkerStatus !== "pass") {
      reasons.push(errorReason("checker_failed", `${name} checker must report pass in both provenance and output`));
    }
    checkers[name] = {
      path: file,
      status: checkerStatus,
      outcome: stages[name]?.exit_code === 0 ? "success" : "failure",
      missing: Array.isArray(checker?.missing) ? checker.missing.length : null,
      extra: Array.isArray(checker?.extra) ? checker.extra.length : null,
      width_mismatches: Array.isArray(checker?.width_mismatches) ? checker.width_mismatches.length : null,
      ...(name === "contrast" ? { aa_fail: contrastResult.aa_fail, total: contrastResult.total } : {})
    };
  }

  const cleanup = {
    status: typeof cleanupInput.status === "string" ? cleanupInput.status : "missing",
    project: typeof cleanupInput.project === "string" ? cleanupInput.project : "",
    containers: Number.isInteger(cleanupInput.containers) ? cleanupInput.containers : null,
    networks: Number.isInteger(cleanupInput.networks) ? cleanupInput.networks : null,
    volumes: Number.isInteger(cleanupInput.volumes) ? cleanupInput.volumes : null
  };
  if (cleanup.status !== "clean" || cleanup.project !== composeProject || cleanup.containers !== 0 || cleanup.networks !== 0 || cleanup.volumes !== 0) {
    reasons.push(errorReason("unclean_cleanup", "Cleanup must confirm zero owned containers, networks and volumes for the Compose project"));
  }
  if (!isRecord(lifecycle?.cleanup) || lifecycle.cleanup.status !== cleanup.status || lifecycle.cleanup.project !== cleanup.project) {
    reasons.push(errorReason("lifecycle_mismatch", "lifecycle.json must confirm the same cleanup outcome"));
  }

  const reconciliation = reconcileInventory({
    inventory,
    report,
    repoRoot: process.cwd(),
    allowedSkips: Array.isArray(manifest.allowed_skips) ? manifest.allowed_skips : [],
    requireMandatoryCases: true
  });
  reasons.push(...reconciliation.reasons);

  const declaredArtifacts = Array.isArray(manifest.artifacts) ? manifest.artifacts : [];
  if (!Array.isArray(manifest.artifacts)) reasons.push(errorReason("malformed_artifact_manifest", "input artifacts must be an array"));
  if (declaredArtifacts.length > MAX_ARTIFACTS) reasons.push(errorReason("too_many_artifacts", "Artifact inventory exceeds its bounded count"));
  const declaredByPath = new Map();
  for (const item of declaredArtifacts.slice(0, MAX_ARTIFACTS)) {
    if (!isRecord(item) || typeof item.path !== "string") {
      reasons.push(errorReason("malformed_artifact_entry", "Artifact manifest entries require a relative path"));
      continue;
    }
    try {
      const normalized = normalizeArtifactPath(item.path);
      if (declaredByPath.has(normalized)) reasons.push(errorReason("duplicate_artifact_path", `Artifact path is repeated: ${normalized}`));
      declaredByPath.set(normalized, item);
    } catch (error) {
      reasons.push(errorReason("unsafe_artifact_path", `${item.path}: ${error.message}`));
    }
  }
  if (reconciliation.cases.some((item) => path.posix.basename(item.file) === "ui_iteration3.spec.ts")) {
    const screenshots = [...declaredByPath.keys()].filter((name) => name.startsWith("ui-review-artifacts/iteration3-journeys/"));
    if (screenshots.length === 0) reasons.push(errorReason("missing_required_screenshot", "Iteration 3 cases require their run-owned journey screenshots"));
  }

  const artifactPaths = new Set([...REQUIRED_ARTIFACT_PATHS, ...declaredByPath.keys()]);
  const artifacts = [];
  let totalArtifactBytes = 0;
  for (const artifactPath of [...artifactPaths].sort()) {
    const declared = declaredByPath.get(artifactPath);
    const required = REQUIRED_ARTIFACT_PATHS.includes(artifactPath) || declared?.required === true;
    const row = hashArtifact(root, artifactPath, reasons, {
      required,
      copied: declared ? declared.copied === true : true,
      copyStatus: declared ? declared.copy_status : "success",
      remainingBytes: Math.max(0, MAX_TOTAL_ARTIFACT_BYTES - totalArtifactBytes)
    });
    totalArtifactBytes += row.size_bytes || 0;
    artifacts.push(row);
  }
  if (totalArtifactBytes > MAX_TOTAL_ARTIFACT_BYTES) reasons.push(errorReason("artifacts_too_large", "Combined evidence artifacts exceed the run size limit"));
  if (stages.artifact_copy.exit_code !== 0) reasons.push(errorReason("artifact_copy_failed", "Artifact collection stage did not exit successfully"));

  const events = readEvents(root, reasons);
  const operationCounts = {};
  for (const event of events) operationCounts[event.operation] = (operationCounts[event.operation] || 0) + 1;
  const sortedOperations = Object.fromEntries(Object.entries(operationCounts).sort(([left], [right]) => left.localeCompare(right)));

  if (manifest.first_failure !== null && manifest.first_failure !== undefined) {
    reasons.push(errorReason("original_run_failure", "The verifier recorded an original failure; later evidence collection cannot replace it"));
  }
  const normalizedReasons = normalizeReasons(reasons);
  let firstFailure = manifest.first_failure ?? null;
  if (firstFailure === null) {
    const failedStage = Object.entries(stages)
      .filter(([, stage]) => stage.exit_code !== 0)
      .sort((left, right) => Date.parse(left[1].started_at || "") - Date.parse(right[1].started_at || ""))[0];
    if (failedStage) firstFailure = { stage: failedStage[0], exit_code: failedStage[1].exit_code };
  }
  if (firstFailure === null && normalizedReasons.length > 0) {
    firstFailure = { stage: "evidence", code: normalizedReasons[0].code, message: normalizedReasons[0].message };
  }

  const hostedClean = sourceMode === "hosted" && normalizedReasons.length === 0;
  const eligibilityClass = sourceMode === "hosted" ? "hosted-exact-sha" : sourceMode === "local" ? (dirty === true ? "local-dirty" : "local-clean") : "unknown";
  const eligibility = {
    eligible: normalizedReasons.length === 0,
    clean: hostedClean,
    class: eligibilityClass,
    status: normalizedReasons.length === 0 ? "pass" : "fail",
    reason_count: normalizedReasons.length
  };
  const source = {
    mode: sourceMode,
    checkout_head: checkoutHead,
    dirty: typeof dirty === "boolean" ? dirty : null,
    event_sha: eventSha,
    built_source_sha: builtSourceSha,
    dirty_fingerprint: typeof sourceInput.dirty_fingerprint === "string" ? sourceInput.dirty_fingerprint : null
  };
  const compose = { scope: composeScope, project: composeProject, targets: [...new Set(targets)].sort(), model_digest: modelDigest };
  const browser = { engine: browserEngine, version: browserVersion, package: packageName, package_version: packageVersion };
  const runtimeStarted = Object.values(stages).map((stage) => Date.parse(stage.started_at || "")).filter(Number.isFinite);
  const runtimeEnded = Object.values(stages).map((stage) => Date.parse(stage.ended_at || "")).filter(Number.isFinite);
  const runtimeSeconds = runtimeStarted.length && runtimeEnded.length
    ? Math.max(0, Math.floor((Math.max(...runtimeEnded) - Math.min(...runtimeStarted)) / 1000))
    : null;
  const failedCases = reconciliation.cases.filter((item) => item.attempts.some((attempt) => attempt.status !== "passed"));
  const shellWash = reconciliation.cases.filter((item) => item.title_path.some((title) => title.includes("[shell-wash]")));
  const shellWashFailed = shellWash.some((item) => item.attempts.some((attempt) => attempt.status !== "passed"));
  const failureClassification = shellWashFailed ? "shell_wash_visual" : normalizedReasons[0]?.code || null;

  return {
    schema_version: 1,
    authority: "scripts/ci/ecommerce_evidence.cjs",
    source,
    images,
    compose,
    browser,
    workflow,
    stages,
    checkers,
    cases: reconciliation.cases,
    artifacts,
    cleanup,
    first_failure: firstFailure,
    eligibility,
    reasons: normalizedReasons,
    run_id: workflow.run_id,
    run_attempt: workflow.run_attempt,
    sha: workflow.sha,
    event: workflow.event,
    job_name: workflow.job_name,
    conclusion: workflow.job_conclusion,
    browser_conclusion: stages.browser.exit_code === 0 ? "success" : "failure",
    light_parity_conclusion: stages.light_parity.exit_code === 0 ? "success" : "failure",
    contrast_conclusion: stages.contrast.exit_code === 0 ? "success" : "failure",
    light_parity_status: checkers.light_parity.status,
    light_parity_width_mismatches: checkers.light_parity.width_mismatches,
    light_parity_missing: checkers.light_parity.missing,
    light_parity_extra: checkers.light_parity.extra,
    shell_wash_conclusion: shellWash.length === 0 ? "missing" : shellWash.every((item) => item.attempts.every((attempt) => attempt.status === "passed")) ? "success" : "failure",
    shell_wash_specs_total: shellWash.length,
    shell_wash_failed_specs: shellWash.filter((item) => item.attempts.some((attempt) => attempt.status !== "passed")).map((item) => item.title_path.join(" › ")),
    visual_judge_status: "not-required",
    visual_judge_findings: null,
    visual_judge_claims: null,
    visual_judge_required: false,
    visual_judge_skipped_reason: "The paid judge is outside browser eligibility.",
    runtime_seconds: runtimeSeconds,
    flaky_signal: reconciliation.cases.some((item) => item.attempts.some((attempt) => attempt.retry > 0)),
    failure_classification: failureClassification,
    specs_total: reconciliation.spec_count,
    tests_total: reconciliation.case_count,
    attempts_total: reconciliation.attempts_total,
    failed_specs: failedCases.map((item) => item.title_path.join(" › ")),
    operation_counts: sortedOperations,
    evidence_events_count: events.length,
    generated_at_utc: generatedAt
  };
}

function renderSummary(receipt) {
  const lines = [
    "# Phase 105 E2E Evidence Summary",
    "",
    `- run_id: ${receipt.run_id}`,
    `- run_attempt: ${receipt.run_attempt ?? "unknown"}`,
    `- sha: ${receipt.sha || "unknown"}`,
    `- event: ${receipt.event || "unknown"}`,
    `- job_name: ${receipt.job_name || "unknown"}`,
    `- conclusion: ${receipt.conclusion || "unknown"}`,
    `- browser_conclusion: ${receipt.browser_conclusion}`,
    `- light_parity_conclusion: ${receipt.light_parity_conclusion}`,
    `- contrast_conclusion: ${receipt.contrast_conclusion}`,
    `- light_parity_status: ${receipt.light_parity_status}`,
    `- shell_wash_conclusion: ${receipt.shell_wash_conclusion}`,
    `- shell_wash_specs_total: ${receipt.shell_wash_specs_total}`,
    `- visual_judge_status: ${receipt.visual_judge_status}`,
    `- visual_judge_claims: ${receipt.visual_judge_claims ?? "unknown"}`,
    `- visual_judge_required: ${receipt.visual_judge_required}`,
    `- runtime_seconds: ${receipt.runtime_seconds ?? "unknown"}`,
    `- flaky_signal: ${receipt.flaky_signal}`,
    `- eligibility: ${receipt.eligibility.status} (${receipt.eligibility.class})`,
    `- clean_hosted_proof: ${receipt.eligibility.clean}`,
    `- failure_classification: ${receipt.failure_classification ?? "none"}`,
    `- specs_total: ${receipt.specs_total}`,
    `- tests_total: ${receipt.tests_total}`,
    `- attempts_total: ${receipt.attempts_total}`,
    `- evidence_events_count: ${receipt.evidence_events_count}`,
    `- generated_at_utc: ${receipt.generated_at_utc}`,
    "",
    "## Eligibility Reasons",
    "",
    ...(receipt.reasons.length === 0 ? ["- none"] : receipt.reasons.map((reason) => `- ${reason.code}: ${reason.message}`)),
    "",
    "## Operation Counts",
    "",
    ...Object.entries(receipt.operation_counts).map(([operation, count]) => `- ${operation}: ${count}`),
    "",
    "## Failed Specs",
    "",
    ...(receipt.failed_specs.length === 0 ? ["- none"] : receipt.failed_specs.map((title) => `- ${title}`)),
    "",
    "## Light Parity",
    "",
    `- status: ${receipt.light_parity_status}`,
    `- missing: ${receipt.light_parity_missing ?? "unknown"}`,
    `- width_mismatches: ${receipt.light_parity_width_mismatches ?? "unknown"}`,
    `- extra: ${receipt.light_parity_extra ?? "unknown"}`,
    "",
    "## Shell Wash",
    "",
    `- conclusion: ${receipt.shell_wash_conclusion}`,
    `- specs_total: ${receipt.shell_wash_specs_total}`,
    ...(receipt.shell_wash_failed_specs.length === 0 ? ["- failed_specs: none"] : receipt.shell_wash_failed_specs.map((title) => `- failed_spec: ${title}`)),
    "",
    "## Advisory Visual Judge",
    "",
    `- status: ${receipt.visual_judge_status}`,
    "- findings: not required",
    `- claims: ${receipt.visual_judge_claims ?? "not required"}`,
    `- required: ${receipt.visual_judge_required}`,
    `- skipped_reason: ${receipt.visual_judge_skipped_reason}`
  ];
  return `${lines.join("\n")}\n`;
}

function canonicalize(value) {
  if (Array.isArray(value)) return value.map(canonicalize);
  if (!isRecord(value)) return value;
  return Object.fromEntries(Object.keys(value).sort().map((key) => [key, canonicalize(value[key])]));
}

function writeAtomic(root, fileName, contents) {
  const target = path.join(root, fileName);
  if (fs.existsSync(target)) throw new Error(`${fileName} already exists; each evidence run needs a fresh directory`);
  const temporary = path.join(root, `.${fileName}.${process.pid}.${crypto.randomBytes(6).toString("hex")}.tmp`);
  try {
    fs.writeFileSync(temporary, contents, { flag: "wx" });
    fs.renameSync(temporary, target);
  } finally {
    if (fs.existsSync(temporary)) fs.unlinkSync(temporary);
  }
}

function writeEvidence({ runDir, now } = {}) {
  const root = resolveRunRoot(runDir);
  const generatedAt = now instanceof Date ? now.toISOString() : typeof now === "string" ? now : new Date().toISOString();
  const receipt = buildReceipt(root, { generatedAt });
  const jsonPath = path.join(root, RECEIPT_NAME);
  const summaryPath = path.join(root, SUMMARY_NAME);
  if (fs.existsSync(jsonPath) || fs.existsSync(summaryPath)) {
    throw new Error("evidence outputs already exist; each run requires a fresh owned artifact directory");
  }
  const json = `${JSON.stringify(receipt, null, 2)}\n`;
  const summary = renderSummary(receipt);
  writeAtomic(root, RECEIPT_NAME, json);
  try {
    writeAtomic(root, SUMMARY_NAME, summary);
  } catch (error) {
    // Keep the aggregate as the authoritative partial record if summary creation fails.
    throw new Error(`aggregate was written but its derived Markdown summary failed: ${error.message}`);
  }
  return receipt;
}

function validateReceipt({ runDir } = {}) {
  let root;
  let receipt;
  try {
    root = resolveRunRoot(runDir);
    const receiptFile = resolveArtifact(root, RECEIPT_NAME, { allowOutputs: true });
    if (receiptFile.stat.size > MAX_JSON_BYTES) throw new RangeError("receipt exceeds the parsing size limit");
    receipt = JSON.parse(fs.readFileSync(receiptFile.path, "utf8"));
    if (!isRecord(receipt) || typeof receipt.generated_at_utc !== "string") throw new TypeError("receipt schema is invalid");
  } catch (error) {
    return { valid: false, eligible: false, reasons: [errorReason("invalid_receipt", error.message)] };
  }
  let summary;
  try {
    const summaryFile = resolveArtifact(root, SUMMARY_NAME, { allowOutputs: true });
    if (summaryFile.stat.size > MAX_JSON_BYTES) throw new RangeError("summary exceeds the parsing size limit");
    summary = fs.readFileSync(summaryFile.path, "utf8");
  } catch (error) {
    return { valid: false, eligible: false, reasons: [errorReason("missing_summary", error.message)] };
  }
  let recomputed;
  try {
    recomputed = buildReceipt(root, { generatedAt: receipt.generated_at_utc });
  } catch (error) {
    return { valid: false, eligible: false, reasons: [errorReason("receipt_recompute_failed", error.message)] };
  }
  const sameAggregate = JSON.stringify(canonicalize(receipt)) === JSON.stringify(canonicalize(recomputed));
  const sameSummary = summary === renderSummary(receipt);
  const valid = sameAggregate && sameSummary;
  const eligible = valid && receipt.eligibility?.eligible === true;
  const reasons = [];
  if (!sameAggregate) reasons.push(errorReason("receipt_mismatch", "Stored aggregate does not match run-owned inputs and artifacts"));
  if (!sameSummary) reasons.push(errorReason("summary_mismatch", "Markdown summary does not derive from the stored aggregate"));
  if (receipt.eligibility?.eligible !== true) reasons.push(...(Array.isArray(receipt.reasons) ? receipt.reasons : [errorReason("ineligible_receipt", "Stored receipt is not eligible")]));
  return { valid, eligible, reasons: normalizeReasons(reasons), receipt };
}

function parseRunDir(argv) {
  const index = argv.indexOf("--run-dir");
  if (index < 0 || !argv[index + 1] || argv[index + 1].startsWith("--")) {
    throw new Error("--run-dir <path> is required");
  }
  if (argv.filter((value) => value === "--run-dir").length !== 1) throw new Error("--run-dir must be supplied once");
  return path.resolve(argv[index + 1]);
}

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function runReconcile(runDir) {
  let inventory;
  let report;
  try {
    inventory = readJson(path.join(runDir, "phase105-playwright-list.json"));
    report = readJson(path.join(runDir, "phase105-playwright.json"));
  } catch (error) {
    return { eligible: false, cases: [], case_count: 0, reasons: [errorReason("unreadable_run_report", error.message)] };
  }
  return reconcileInventory({ inventory, report, repoRoot: process.cwd(), requireMandatoryCases: true });
}

function main(argv = process.argv.slice(2)) {
  const [command] = argv;
  const runDir = parseRunDir(argv);
  if (command === "reconcile") {
    const result = runReconcile(runDir);
    process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
    return result.eligible ? 0 : 1;
  }
  if (command === "write-evidence") {
    const receipt = writeEvidence({ runDir });
    process.stdout.write(`${JSON.stringify({ eligibility: receipt.eligibility, reasons: receipt.reasons, files: [RECEIPT_NAME, SUMMARY_NAME] }, null, 2)}\n`);
    return receipt.eligibility.eligible ? 0 : 1;
  }
  if (command === "validate-receipt") {
    const result = validateReceipt({ runDir });
    process.stdout.write(`${JSON.stringify({ valid: result.valid, eligible: result.eligible, reasons: result.reasons }, null, 2)}\n`);
    return result.valid && result.eligible ? 0 : 1;
  }
  throw new Error(`Unknown evidence command: ${command || "(missing)"}`);
}

if (require.main === module) {
  try {
    process.exitCode = main();
  } catch (error) {
    process.stderr.write(`ecommerce-evidence: ${error.message}\n`);
    process.exitCode = 1;
  }
}

module.exports = {
  caseIdentity,
  reconcileInventory,
  runReconcile,
  renderSummary,
  writeEvidence,
  validateReceipt
};
