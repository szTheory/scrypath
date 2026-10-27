"use strict";

const fs = require("node:fs");
const path = require("node:path");

const MAX_CASES = 50000;
const MAX_SUITE_DEPTH = 100;
const MAX_REPORT_ERRORS = 100;
const MAX_ERROR_TEXT = 2000;

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
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
  return reconcileInventory({ inventory, report, repoRoot: path.resolve(runDir, "../../.."), requireMandatoryCases: true });
}

function main(argv = process.argv.slice(2)) {
  const [command] = argv;
  const runDir = parseRunDir(argv);
  if (command !== "reconcile") throw new Error(`Unknown evidence command: ${command || "(missing)"}`);
  const result = runReconcile(runDir);
  process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
  return result.eligible ? 0 : 1;
}

if (require.main === module) {
  try {
    process.exitCode = main();
  } catch (error) {
    process.stderr.write(`ecommerce-evidence: ${error.message}\n`);
    process.exitCode = 1;
  }
}

module.exports = { caseIdentity, reconcileInventory, runReconcile };
