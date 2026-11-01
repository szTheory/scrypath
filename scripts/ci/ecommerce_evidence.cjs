"use strict";

const fs = require("node:fs");
const rawBundle = require("./ui_preservation_bundle.cjs");
const crypto = require("node:crypto");
const path = require("node:path");
const { execFileSync, spawnSync } = require("node:child_process");

const REPOSITORY_ROOT = path.resolve(__dirname, "../..");
const MAX_CASES = 50000;
const MAX_SUITE_DEPTH = 100;
const MAX_REPORT_ERRORS = 100;
const MAX_ERROR_TEXT = 2000;
const MAX_JSON_BYTES = 8 * 1024 * 1024;
const MAX_NDJSON_BYTES = 16 * 1024 * 1024;
const MAX_ARTIFACT_BYTES = 64 * 1024 * 1024;
const MAX_TOTAL_ARTIFACT_BYTES = 256 * 1024 * 1024;
const MAX_ARTIFACTS = 256;
const MAX_IMAGE_DIMENSION = 16384;
const MAX_IMAGE_PIXELS = 20000000;
const RECEIPT_NAME = "phase105-evidence.json";
const SUMMARY_NAME = "phase105-evidence-summary.md";
const BEFORE_ONLY_RECEIPT_NAME = "phase185-before-only-evidence.json";
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
const BEFORE_ONLY_REQUIRED_ARTIFACT_PATHS = [
  INPUT_NAME,
  INVENTORY_NAME,
  PLAYWRIGHT_NAME,
  EVENTS_NAME,
  "lifecycle.json",
  "playwright-report/index.html"
];
const ALLOWED_ARTIFACT_PREFIXES = [
  "playwright-report/",
  "test-results/",
  "ui-review-artifacts/iteration3-journeys/",
  "logs/",
  "compose/",
  "partitions/",
  "blob-report/"
];
const REQUIRED_STAGES = ["inventory", "browser", "light_parity", "contrast", "artifact_copy"];
const PRESERVATION_STATE_ELEMENTS = ["E1", "E2", "E3", "E4", "E5", "E6"];
const PRESERVATION_STATE_CATEGORIES = ["empty", "loading", "error", "populated", "partial", "zero-one-many"];
const PRESERVATION_ACTION_ELEMENTS = ["E8", "E9", "E10"];
const PRESERVATION_CONTENT_ELEMENTS = ["E1", "E2", "E3", "E4", "E5", "E6", "E7", "E8", "E9", "E10"];
const PRESERVATION_OVERFLOW_ELEMENTS = ["E1", "E2", "E3", "E4", "E5", "E6", "E7", "E8", "E10"];
const PRODUCT_SOURCE_EXCLUDED_FILES = new Set([
  "examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex",
  "examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/live/e2e_ui_fixture_live.ex"
]);
const PRESERVATION_FIXTURE_FILES = [
  "examples/scrypath_ecommerce/e2e/ui_state_preservation.spec.ts",
  "examples/scrypath_ecommerce/e2e/ui_content_preservation.spec.ts",
  "examples/scrypath_ecommerce/e2e/helpers/e2e.ts",
  "examples/scrypath_ecommerce/e2e/helpers/ui-preservation-states.ts",
  "examples/scrypath_ecommerce/e2e/ui-review.mjs",
  "examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts",
  "examples/scrypath_ecommerce/e2e/helpers/verification-target.mjs",
  "examples/scrypath_ecommerce/playwright.config.ts",
  "examples/scrypath_ecommerce/package.json",
  "examples/scrypath_ecommerce/package-lock.json",
  "examples/scrypath_ecommerce/Dockerfile.e2e",
  "examples/scrypath_ecommerce/compose.phase173.yaml",
  "examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex",
  "examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/live/e2e_ui_fixture_live.ex",
  "examples/scrypath_ecommerce/test/support/phase173_fixture_source.ex",
  "scrypath_ops/test/support/phase173_fixture_source.ex",
  "examples/scrypath_ecommerce/compose.phase185.yaml",
  "examples/scrypath_ecommerce/compose.e2e.yaml",
  "examples/scrypath_ecommerce/scripts/verify-e2e.sh",
  "examples/scrypath_ecommerce/docker-playwright.sh",
  "scripts/ci/ecommerce_evidence.cjs",
  "scripts/ci/ecommerce_evidence.test.cjs",
  "scripts/ci/ui_state_pairs.cjs",
  "scripts/ci/ui_state_pairs.test.cjs",
  "scripts/ci/ui_preservation_bundle.cjs",
  "scripts/ci/ui_preservation_bundle.test.cjs",
  "scripts/ci/ecommerce_build.cjs",
  "scripts/ci/ecommerce_build.test.cjs"
];
const PRESERVATION_ARTIFACT_ROOT = "ui-review-artifacts/iteration3-journeys/phase185-held-out/";
const PRESERVATION_VIEWPORT_WIDTHS = [1440, 768, 390];
const PRESERVATION_THEMES = ["light", "dark", "system-dark"];
const PRESERVATION_CASES = Object.freeze([
  ...PRESERVATION_STATE_ELEMENTS.flatMap((element) => PRESERVATION_STATE_CATEGORIES.map((category) => ({
    id: `${element} ${category}`,
    file: "e2e/ui_state_preservation.spec.ts",
    element,
    category
  }))),
  ...PRESERVATION_ACTION_ELEMENTS.flatMap((element) => ["loading", "error"].map((category) => ({
    id: `${element} ${category}`,
    file: "e2e/ui_state_preservation.spec.ts",
    element,
    category
  }))),
  ...PRESERVATION_OVERFLOW_ELEMENTS.map((element) => ({
    id: `${element} overflow`,
    file: "e2e/ui_content_preservation.spec.ts",
    element,
    category: "overflow"
  })),
  ...PRESERVATION_CONTENT_ELEMENTS.map((element) => ({
    id: `${element} long-text`,
    file: "e2e/ui_content_preservation.spec.ts",
    element,
    category: "long-text"
  }))
]);
const PRODUCT_SOURCE_ROOTS = [
  "examples/scrypath_ecommerce/assets",
  "examples/scrypath_ecommerce/config",
  "examples/scrypath_ecommerce/lib",
  "scrypath_ops/assets",
  "scrypath_ops/config",
  "scrypath_ops/lib"
];

function sourceDigest(root, files) {
  const entries = files.slice().sort((left, right) => left.localeCompare(right)).map((relative) => {
    const absolute = path.join(root, ...relative.split("/"));
    const stat = fs.lstatSync(absolute);
    if (!stat.isFile() || stat.isSymbolicLink()) throw new TypeError(`${relative} must be a regular source file`);
    return { path: relative, sha256: crypto.createHash("sha256").update(fs.readFileSync(absolute)).digest("hex") };
  });
  return `sha256:${crypto.createHash("sha256").update(JSON.stringify(entries)).digest("hex")}`;
}

function listRegularFiles(root, relative, excluded = new Set()) {
  const absolute = path.join(root, ...relative.split("/"));
  const entries = fs.readdirSync(absolute, { withFileTypes: true }).sort((left, right) => left.name.localeCompare(right.name));
  const files = [];
  for (const entry of entries) {
    const child = `${relative}/${entry.name}`;
    if (excluded.has(child)) continue;
    if (entry.isSymbolicLink()) throw new TypeError(`${child} must not be a symlink`);
    if (entry.isDirectory()) files.push(...listRegularFiles(root, child, excluded));
    else if (entry.isFile()) files.push(child);
    else throw new TypeError(`${child} is not a regular source file`);
  }
  return files;
}

function gitObjectEntries(repoRoot, sourceSha, directories, excluded = new Set()) {
  const root = path.resolve(repoRoot);
  if (!/^[a-f0-9]{40}$/.test(sourceSha || "")) throw new TypeError("source revision must be a full Git commit SHA");
  const resolved = execFileSync("git", ["-C", root, "rev-parse", "--verify", `${sourceSha}^{commit}`], { encoding: "utf8" }).trim();
  if (resolved !== sourceSha) throw new TypeError("source revision did not resolve to the exact pinned Git commit");
  const listing = execFileSync("git", ["-C", root, "ls-tree", "-r", "-z", "--full-tree", sourceSha, "--", ...directories], { encoding: "buffer" });
  const rows = [];
  for (const record of listing.toString("utf8").split("\0").filter(Boolean)) {
    const tab = record.indexOf("\t");
    if (tab < 0) throw new TypeError("Git tree entry is malformed");
    const [mode, type, oid] = record.slice(0, tab).split(" ");
    const relative = record.slice(tab + 1);
    if (excluded.has(relative)) continue;
    if (type !== "blob" || !["100644", "100755"].includes(mode) || !/^[a-f0-9]{40}$/.test(oid || "")) {
      throw new TypeError(`${relative} is not a regular file in the pinned source tree`);
    }
    const bytes = execFileSync("git", ["-C", root, "cat-file", "blob", oid], { encoding: "buffer" });
    rows.push({ path: relative, sha256: crypto.createHash("sha256").update(bytes).digest("hex") });
  }
  return rows.sort((left, right) => left.path.localeCompare(right.path));
}

function sourceDigestFromGit(repoRoot, sourceSha, directories, excluded = new Set(), expectedFiles = null) {
  const entries = gitObjectEntries(repoRoot, sourceSha, directories, excluded);
  if (entries.length === 0) throw new TypeError("pinned Git source tree contains no files in the requested roots");
  if (expectedFiles && (entries.length !== expectedFiles.length || expectedFiles.some((relative) => !entries.some((entry) => entry.path === relative)))) {
    throw new TypeError("pinned Git source is missing one or more declared test-overlay files");
  }
  return `sha256:${crypto.createHash("sha256").update(JSON.stringify(entries)).digest("hex")}`;
}

function fixtureOverlayDigest(repoRoot = path.resolve(__dirname, "../.."), sourceSha = null) {
  const root = path.resolve(repoRoot);
  if (sourceSha) return sourceDigestFromGit(root, sourceSha, PRESERVATION_FIXTURE_FILES, new Set(), PRESERVATION_FIXTURE_FILES);
  return sourceDigest(root, PRESERVATION_FIXTURE_FILES);
}

function productTreeIdentity(repoRoot = path.resolve(__dirname, "../.."), sourceSha = null) {
  const root = path.resolve(repoRoot);
  if (sourceSha) return sourceDigestFromGit(root, sourceSha, PRODUCT_SOURCE_ROOTS, PRODUCT_SOURCE_EXCLUDED_FILES);
  const files = PRODUCT_SOURCE_ROOTS.flatMap((directory) => listRegularFiles(root, directory, PRODUCT_SOURCE_EXCLUDED_FILES));
  return sourceDigest(root, files);
}

function validateSourceOverlay(repoRoot, productSourceSha, buildSourceSha, { requireCurrentHead = false, validateWorkingOverlay = false } = {}) {
  const root = path.resolve(repoRoot);
  const productTreeSha256 = productTreeIdentity(root, productSourceSha);
  const buildProductTreeSha256 = productTreeIdentity(root, buildSourceSha);
  if (productTreeSha256 !== buildProductTreeSha256) {
    throw new TypeError("test-only build overlay changes the independently qualified product source tree");
  }
  const head = execFileSync("git", ["-C", root, "rev-parse", "--verify", "HEAD^{commit}"], { encoding: "utf8" }).trim();
  if (requireCurrentHead && head !== buildSourceSha) throw new TypeError("actual build source OID does not match the checked out build commit");
  const changed = execFileSync("git", ["-C", root, "diff", "--name-only", "-z", productSourceSha, buildSourceSha, "--"], { encoding: "buffer" })
    .toString("utf8").split("\0").filter(Boolean);
  const declared = new Set(PRESERVATION_FIXTURE_FILES);
  const workingChanges = validateWorkingOverlay
    ? execFileSync("git", ["-C", root, "diff", "--name-only", "-z", productSourceSha, "--"], { encoding: "buffer" }).toString("utf8").split("\0").filter(Boolean)
    : [];
  const untracked = validateWorkingOverlay
    ? execFileSync("git", ["-C", root, "ls-files", "--others", "--exclude-standard", "-z"], { encoding: "buffer" }).toString("utf8").split("\0").filter(Boolean)
    : [];
  const actualOverlayChanges = [...new Set([...changed, ...workingChanges, ...untracked])].sort();
  const unexpected = actualOverlayChanges.filter((relative) => !declared.has(relative));
  if (unexpected.length > 0) {
    throw new TypeError(`build overlay changes files outside the declared test-only fixture set: ${unexpected.slice(0, 5).join(", ")}`);
  }
  const committedFixtureOverlaySha256 = fixtureOverlayDigest(root, buildSourceSha);
  const workingFixtureOverlaySha256 = validateWorkingOverlay ? fixtureOverlayDigest(root) : committedFixtureOverlaySha256;
  if (validateWorkingOverlay && workingFixtureOverlaySha256 !== committedFixtureOverlaySha256) {
    throw new TypeError("working test-only fixture bytes do not match the actual overlay build Git object");
  }
  const fixtureOverlaySha256 = workingFixtureOverlaySha256;
  return { productTreeSha256, fixtureOverlaySha256, changedFiles: actualOverlayChanges };
}

function validateBeforeQualification({ repoRoot, qualificationPath, productSourceSha, buildSourceSha, qualificationSha256 } = {}) {
  if (!path.isAbsolute(qualificationPath || "") || !validSha(productSourceSha) || !validSha(buildSourceSha) || !validDigest(qualificationSha256)) {
    throw new TypeError("before qualification requires absolute raw evidence and independently pinned product/build OIDs and qualification digest");
  }
  const qualificationStat = fs.lstatSync(qualificationPath);
  if (qualificationStat.isSymbolicLink() || !qualificationStat.isFile() || qualificationStat.size <= 0 || qualificationStat.size > MAX_JSON_BYTES) {
    throw new TypeError("pinned before qualification must be a bounded regular file without symlinks");
  }
  const qualificationBytes = fs.readFileSync(qualificationPath);
  const actualQualificationSha256 = `sha256:${crypto.createHash("sha256").update(qualificationBytes).digest("hex")}`;
  if (actualQualificationSha256 !== qualificationSha256) throw new TypeError("raw before qualification bytes do not match the independent qualification digest pin");
  const qualification = JSON.parse(qualificationBytes.toString("utf8"));
  const runtime = qualification.browser_runtime_equivalence;
  if (qualification.schema !== "scrypath.phase185-before-qualification.v1" || qualification.status !== "qualified" ||
    qualification.source_sha !== productSourceSha || runtime?.source_sha !== productSourceSha || runtime?.rootfs_layers_equal !== true ||
    runtime?.effective_config_equal !== true || !/^sha256:[a-f0-9]{64}$/.test(runtime?.actual_image_id || "") ||
    !/^[a-f0-9]{64}$/.test(qualification.actual_before_sha256 || "")) {
    throw new TypeError("raw qualification is not the independently pinned, qualified Plan05 before product and browser runtime");
  }
  const capturePin = (qualification.pinned_files || []).find((item) => item?.sha256 === qualification.actual_before_sha256 && path.basename(item.path || "") === "capture.json");
  if (!capturePin || !path.isAbsolute(capturePin.path)) throw new TypeError("raw qualification does not pin its actual before capture manifest");
  const captureStat = fs.lstatSync(capturePin.path);
  if (captureStat.isSymbolicLink() || !captureStat.isFile()) throw new TypeError("qualified before capture must be a regular file without symlinks");
  const captureBytes = fs.readFileSync(capturePin.path);
  if (crypto.createHash("sha256").update(captureBytes).digest("hex") !== qualification.actual_before_sha256) {
    throw new TypeError("qualified before capture bytes do not match the raw qualification digest");
  }
  const capture = JSON.parse(captureBytes.toString("utf8"));
  const environment = capture.environment;
  const clock = environment?.clock;
  const font = environment?.browser_font_profile;
  const date = new Date(clock?.utc || "");
  if (capture.source?.source_sha !== productSourceSha || !/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z$/.test(clock?.utc || "") ||
    Number.isNaN(date.getTime()) || date.toISOString() !== clock.utc || !/^[a-f0-9]{64}$/.test(clock?.sha256 || "") ||
    clock.timezone !== "UTC" || clock.locale !== "en-US" || clock.browser_mode !== "fixed-date" ||
    !(environment.browser_launch?.args || []).includes("--disable-partial-raster") ||
    font?.method !== "retained-cdp-fixed-font-v1" || font?.font_families?.fixed !== "Liberation Mono" ||
    font?.applied !== "before-first-navigation" || font?.lifetime !== "page-context") {
    throw new TypeError("pinned before capture does not establish the qualified fixed-clock, raster and retained-font recipe");
  }
  const overlay = validateSourceOverlay(repoRoot, productSourceSha, buildSourceSha, { requireCurrentHead: true, validateWorkingOverlay: true });
  return {
    product_source_sha: productSourceSha,
    build_source_sha: buildSourceSha,
    tree: overlay.productTreeSha256,
    overlay: overlay.fixtureOverlaySha256,
    product_tree_sha256: overlay.productTreeSha256,
    fixture_overlay_sha256: overlay.fixtureOverlaySha256,
    qualification_sha256: actualQualificationSha256,
    clock_instant: clock.utc
  };
}

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

  if (/^[^/]+\.spec\.ts$/.test(relative)) relative = `e2e/${relative}`;
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

// Required scenario identities are an explicit verification contract. Additions are
// allowed; removing or renaming an intended case requires a reviewed contract change.
const REQUIRED_UI_CASES = [
  [
    "ui_followup.spec.ts",
    "active, backend-failed, retrying and completed observations have distinct useful states"
  ],
  [
    "ui_followup.spec.ts",
    "generic fields remain readable across compact themes without guessing data types"
  ],
  [
    "ui_followup.spec.ts",
    "mounted: copy feedback leaves timestamp and refresh geometry unchanged"
  ],
  [
    "ui_followup.spec.ts",
    "multi-schema result limit applies to the combined response and help is local"
  ],
  [
    "ui_followup.spec.ts",
    "readable results retain submitted criteria, copy exact data and lead to the saved file"
  ],
  [
    "ui_followup.spec.ts",
    "standalone: copy feedback leaves timestamp and refresh geometry unchanged"
  ],
  [
    "ui_followup.spec.ts",
    "task help stays within the installed mount and explains saved inputs"
  ],
  [
    "ui_iteration3.spec.ts",
    "combined results are one compact backend-ordered list with real page traversal and complete copyable source data"
  ],
  [
    "ui_iteration3.spec.ts",
    "contextual help opens at a visible heading in a new tab and preserves the task"
  ],
  [
    "ui_iteration3.spec.ts",
    "health stages align, icons are consistent, refresh is singular and settings explain missing filters"
  ],
  [
    "ui_iteration3.spec.ts",
    "limits validate on blur, correct inline and preserve the previous run on invalid submission"
  ],
  [
    "ui_iteration3.spec.ts",
    "one purposeful zero-match state and no duplicate per-schema empty cards"
  ],
  [
    "ui_iteration3.spec.ts",
    "Save sits by Run, validates the name and offers Save and Save as after edits"
  ]
];

function mandatoryInventoryReasons(cases, { preservationOnly = false } = {}) {
  const reasons = [];
  if (!preservationOnly) {
    const requiredFiles = ["ui_followup.spec.ts", "ui_iteration3.spec.ts", "phase173_shell.spec.ts"];
    for (const basename of requiredFiles) {
      if (!cases.some((item) => path.posix.basename(item.identity.file) === basename)) {
        reasons.push(errorReason("missing_required_suite", `Full inventory is missing ${basename}`));
      }
    }
    const actualKeys = new Set(cases.map((item) => item.identity.key));
    for (const [file, title] of REQUIRED_UI_CASES) {
      const expected = caseIdentity({ file: `e2e/${file}`, project: "chromium", title_path: [file, title] });
      if (!actualKeys.has(expected.key)) {
        reasons.push(errorReason("missing_required_case", `Full inventory is missing intended case: ${title}`, expected.key));
      }
    }
    const phase173 = cases.filter((item) => path.posix.basename(item.identity.file) === "phase173_shell.spec.ts");
    for (const entrypoint of ["mounted", "standalone"]) {
      if (!phase173.some((item) => item.identity.entrypoint === entrypoint)) {
        reasons.push(errorReason("missing_required_entrypoint", `Phase 173 inventory is missing the ${entrypoint} entrypoint`));
      }
    }
  }
  const preservationCaseCounts = new Map();
  for (const item of cases) {
    const fileName = path.posix.basename(item.identity.file);
    if (fileName !== "ui_state_preservation.spec.ts" && fileName !== "ui_content_preservation.spec.ts") continue;
    const title = item.identity.title_path.at(-1) || "";
    const match = title.match(/^(E(?:10|[1-9])) (empty|loading|error|populated|partial|zero-one-many|overflow|long-text)\b/);
    if (!match) continue;
    const id = `${match[1]} ${match[2]}`;
    const expected = PRESERVATION_CASES.find((preservationCase) => preservationCase.id === id);
    if (!expected || expected.file !== `e2e/${fileName}`) {
      reasons.push(errorReason("unexpected_preservation_case", `Preservation case is outside its declared suite: ${id}`, item.identity.key));
      continue;
    }
    preservationCaseCounts.set(id, (preservationCaseCounts.get(id) || 0) + 1);
    if (item.identity.project !== "chromium") {
      reasons.push(errorReason("invalid_preservation_project", `Preservation case ${id} must run in Chromium`, item.identity.key));
    }
  }
  for (const preservationCase of PRESERVATION_CASES) {
    const count = preservationCaseCounts.get(preservationCase.id) || 0;
    if (count === 0) {
      reasons.push(errorReason("missing_required_case", `Full inventory is missing intended case: ${preservationCase.id}`));
    } else if (count !== 1) {
      reasons.push(errorReason("duplicate_preservation_case", `Full inventory contains ${count} copies of ${preservationCase.id}`));
    }
  }
  return reasons;
}

function preservationIdForCase(item) {
  const fileName = path.posix.basename(item.file);
  if (fileName !== "ui_state_preservation.spec.ts" && fileName !== "ui_content_preservation.spec.ts") return null;
  const title = item.title_path.at(-1) || "";
  const match = title.match(/^(E(?:10|[1-9])) (empty|loading|error|populated|partial|zero-one-many|overflow|long-text)\b/);
  if (!match) return null;
  const id = `${match[1]} ${match[2]}`;
  return PRESERVATION_CASES.some((preservationCase) => preservationCase.id === id && preservationCase.file === `e2e/${fileName}`)
    ? id
    : null;
}

function loadPreservationRawBundle(runRoot, artifacts, reasons) {
  const artifact = artifacts.find((item) => item.path === rawBundle.BUNDLE_PATH);
  const empty = { metadata: null, members: new Map(), artifacts: new Map() };
  if (!artifact?.present || !artifact.sha256 || artifact.copied !== true || artifact.copy_status !== "success") {
    reasons.push(errorReason("missing_preservation_bundle", "All raw held-out PNGs must be copied in the bounded, hash-verified raw bundle"));
    return empty;
  }
  try {
    const members = rawBundle.loadRunBundle(runRoot, artifact.sha256);
    const entries = [...members].map(([path, bytes]) => ({ path, sha256: rawBundle.sha256(bytes), size_bytes: bytes.length })).sort((a, b) => a.path.localeCompare(b.path));
    return {
      metadata: { path: rawBundle.BUNDLE_PATH, sha256: artifact.sha256, size_bytes: artifact.size_bytes, members: entries },
      members,
      artifacts: new Map(entries.map((entry) => [entry.path, { ...entry, present: true, copied: true, copy_status: "success", storage: "raw-bundle-member" }]))
    };
  } catch (error) {
    reasons.push(errorReason("invalid_preservation_bundle", error.message));
    return empty;
  }
}

function preservationSemanticIdentity(value) {
  if (!isRecord(value)) return null;
  return { tag: value.tag, role: value.role, name: value.name, href: value.href };
}

function validatePreservationInteractionTarget(target) {
  const identity = preservationSemanticIdentity(target);
  const supportedTags = new Set(["a", "button", "input", "select", "textarea"]);
  const supportedRoles = new Set(["button", "link", "checkbox", "radio", "option", "tab", "menuitem"]);
  if (!identity || typeof identity.tag !== "string" || identity.tag.trim() === "" ||
    typeof identity.role !== "string" || identity.role.trim() === "" ||
    typeof identity.name !== "string" || identity.name.trim() === "" ||
    !(identity.href === null || typeof identity.href === "string") ||
    (!supportedTags.has(identity.tag) && !supportedRoles.has(identity.role))) {
    throw new TypeError("hover proof must identify a real, named interactive target");
  }
  return identity;
}

function validatePreservationSampleProof({ sampling, imagePath, sampleKind, imageSha, imageRaster, state, viewport, documentGeometry, dpr, interactionTarget, expectHover, seenPaths, rawBundleState, decodedDimensions, label }) {
  if (!isRecord(sampling) || sampling.method !== "consecutive-exact-v1" || sampling.max_samples !== 6 || sampling.max_elapsed_ms !== 10000 ||
    !Array.isArray(sampling.samples) || sampling.samples.length < 2 || sampling.samples.length > 6 || sampling.selected !== sampling.samples.length - 1) {
    throw new TypeError("raw capture lacks the bounded first-consecutive stationary sample proof");
  }
  if (!(["held-out", "hover"].includes(sampleKind)) || (sampleKind === "hover") !== expectHover) throw new TypeError("raw capture sample path kind does not match its capture state");
  const captureId = imagePath.replace(/(?:--hover)?\.png$/i, "");
  const targetIdentity = interactionTarget ? validatePreservationInteractionTarget(interactionTarget) : null;
  const actualSnapshots = [];
  for (let index = 0; index < sampling.samples.length; index += 1) {
    const sample = sampling.samples[index];
    const previous = sampling.samples[index - 1];
    if (!isRecord(sample) || !/^[a-f0-9]{64}$/.test(sample.sha256 || "") || !/^[a-f0-9]{64}$/.test(sample.state_sha256 || "") ||
      !Number.isFinite(sample.elapsed_ms) || sample.elapsed_ms < 0 || sample.elapsed_ms > 10000 || (previous && sample.elapsed_ms < previous.elapsed_ms)) {
      throw new TypeError("raw capture sample hashes/timing are invalid");
    }
    const sampleStem = `${captureId}--${sampleKind === "hover" ? "hover" : "held-out"}-sample-${index}`;
    const expectedImagePath = `${sampleStem}.png`;
    const expectedStatePath = `${sampleStem}.json`;
    if (sample.path !== expectedImagePath || sample.state_path !== expectedStatePath) throw new TypeError("raw capture sample paths must be the canonical image-bound PNG/JSON pair");
    let afterSnapshot = null;
    for (const [samplePath, expectedHash, kind] of [[sample.path, sample.sha256, "png"], [sample.state_path, sample.state_sha256, "json"]]) {
      rawBundle.memberPath(samplePath);
      if (!samplePath.endsWith(`.${kind}`) || seenPaths.has(samplePath)) throw new TypeError("raw sample paths are reused or have the wrong media type");
      seenPaths.add(samplePath);
      const rawArtifact = rawBundleState.artifacts.get(samplePath);
      const sampleBytes = rawBundleState.members.get(samplePath);
      if (!rawArtifact?.present || rawArtifact.sha256 !== expectedHash || !Buffer.isBuffer(sampleBytes) || rawBundle.sha256(sampleBytes) !== expectedHash) {
        throw new TypeError("raw sample PNG/state bytes are absent or do not match the observed hashes");
      }
      if (kind === "png") {
        const prior = decodedDimensions.get(expectedHash);
        if (prior && !prior.bytes.equals(sampleBytes)) throw new TypeError("Equal raw sample hashes have different bytes");
        const dimensions = prior?.dimensions || pngDimensions(sampleBytes, `${label} raw sample`);
        if (!prior) decodedDimensions.set(expectedHash, { bytes: sampleBytes, dimensions });
        if (dimensions.width !== imageRaster.width || dimensions.height !== imageRaster.height) throw new TypeError("raw sample raster dimensions differ from the observation geometry");
      } else {
        const snapshot = JSON.parse(new TextDecoder("utf-8", { fatal: true }).decode(sampleBytes));
        if (!isRecord(snapshot) || snapshot.schema !== "scrypath.ui-capture-state.v1" || !isRecord(snapshot.before) || !isRecord(snapshot.after)) {
          throw new TypeError("raw sample state is not an actual before/after capture snapshot");
        }
        const rootSnapshot = Object.fromEntries(Object.entries(snapshot).filter(([name]) => !["before", "after"].includes(name)));
        const beforeJson = JSON.stringify(canonicalize(snapshot.before));
        const afterJson = JSON.stringify(canonicalize(snapshot.after));
        if (beforeJson !== afterJson || JSON.stringify(canonicalize(rootSnapshot)) !== afterJson ||
          crypto.createHash("sha256").update(afterJson).digest("hex") !== state.dom_state_sha256) {
          throw new TypeError("raw before/after sample state differs from the actual observation DOM-state identity");
        }
        const rawViewport = snapshot.after.viewport;
        if (rawViewport?.inner?.width !== viewport.width || rawViewport?.inner?.height !== viewport.height ||
          rawViewport?.document?.width !== documentGeometry.width || rawViewport?.document?.height !== documentGeometry.height ||
          rawViewport?.scroll?.x !== state.scroll.x || rawViewport?.scroll?.y !== state.scroll.y || rawViewport?.dpr !== dpr || rawViewport?.scale !== 1 ||
          !isRecord(rawViewport.client) || !Number.isFinite(rawViewport.client.width) || !Number.isFinite(rawViewport.client.height) ||
          rawViewport.client.width <= 0 || rawViewport.client.width > viewport.width || rawViewport.client.height <= 0 || rawViewport.client.height > viewport.height) {
          throw new TypeError("raw sample state viewport, document, scroll or DPR differs from the actual observation");
        }
        if (!Array.isArray(snapshot.after.hover) || !Array.isArray(state.hover) ||
          JSON.stringify(canonicalize(snapshot.after.hover)) !== JSON.stringify(canonicalize(state.hover))) {
          throw new TypeError("raw sample hover state differs from the normalized observation hover state");
        }
        if (expectHover === false && snapshot.after.hover.length !== 0) throw new TypeError("the full-page neutral capture must have no hovered controls");
        const rawFocus = snapshot.after.focus;
        if (targetIdentity) {
          const focusIdentity = preservationSemanticIdentity(rawFocus?.element);
          const focusedControl = Array.isArray(snapshot.after.controls)
            ? snapshot.after.controls.find((control) => JSON.stringify(canonicalize(preservationSemanticIdentity(control))) === JSON.stringify(canonicalize(targetIdentity)))
            : null;
          if (JSON.stringify(canonicalize(focusIdentity)) !== JSON.stringify(canonicalize(targetIdentity)) || rawFocus?.focus_visible !== true ||
            snapshot.after.document_has_focus !== true || !focusedControl ||
            JSON.stringify(canonicalize(focusedControl.rect)) !== JSON.stringify(canonicalize(rawFocus.rect)) ||
            !isRecord(rawFocus.rect) || ![rawFocus.rect.x, rawFocus.rect.y, rawFocus.rect.width, rawFocus.rect.height].every(Number.isFinite) ||
            rawFocus.rect.width <= 0 || rawFocus.rect.height <= 0 || state.focus?.name !== targetIdentity.name ||
            state.focus?.role !== targetIdentity.role || state.focus?.tag !== targetIdentity.tag || state.focus?.focus_visible !== true ||
            state.focus?.document_has_focus !== true || !isRecord(rawFocus.outline) ||
            JSON.stringify(canonicalize(state.focus.outline)) !== JSON.stringify(canonicalize(rawFocus.outline)) || state.focus.opacity !== rawFocus.opacity) {
            throw new TypeError("raw capture must bind the named target, focus-visible state, document focus and actual focus style");
          }
        }
        if (expectHover === true) {
          const hoveredTarget = snapshot.after.hover.some((entry) => {
            const bounds = entry?.rect;
            return isRecord(entry) && isRecord(bounds) && [bounds.x, bounds.y, bounds.width, bounds.height].every(Number.isFinite) &&
              bounds.width > 0 && bounds.height > 0 && bounds.x < viewport.width && bounds.y < viewport.height &&
              bounds.x + bounds.width > 0 && bounds.y + bounds.height > 0 &&
              JSON.stringify(canonicalize(preservationSemanticIdentity(entry.element))) === JSON.stringify(canonicalize(targetIdentity));
          });
          if (!hoveredTarget) throw new TypeError("raw hover proof does not show the named target under the pointer");
        }
        afterSnapshot = snapshot.after;
      }
    }
    actualSnapshots.push(afterSnapshot);
    if (index > 0 && index < sampling.selected && sample.sha256 === previous.sha256 && sample.state_sha256 === previous.state_sha256) {
      throw new TypeError("raw capture continued beyond an earlier consecutive exact sample pair");
    }
  }
  const selectedSample = sampling.samples[sampling.selected];
  const previousSample = sampling.samples[sampling.selected - 1];
  if (selectedSample.sha256 !== imageSha || previousSample.sha256 !== imageSha || selectedSample.state_sha256 !== previousSample.state_sha256) {
    throw new TypeError("selected raw PNG is not the first consecutive exact image/state sample pair");
  }
  return actualSnapshots[sampling.selected];
}

function validatePreservationEvents(events, reconciliation, context, reasons) {
  const preservationTests = reconciliation.cases.filter((item) => preservationIdForCase(item));
  const passedTests = new Map(preservationTests.map((item) => [preservationIdForCase(item), item]));
  const rows = events.filter((event) => event.operation === "ui_preservation_case");
  const rowsById = new Map();
  const effectiveRuntimes = new Set(rows.map((event) => event.runtime?.effective_runtime_sha256).filter(Boolean));
  const recipes = new Set(rows.map((event) => event.recipe_sha256).filter(Boolean));
  if (effectiveRuntimes.size > 1) reasons.push(errorReason("mixed_preservation_runtime", "Held-out cases use more than one effective test runtime identity"));
  if (recipes.size > 1) reasons.push(errorReason("mixed_preservation_recipe", "Held-out cases use more than one browser/profile/clock/data recipe"));
  for (const event of rows) {
    const id = typeof event.case_id === "string" ? event.case_id : "";
    if (!PRESERVATION_CASES.some((preservationCase) => preservationCase.id === id)) {
      reasons.push(errorReason("unexpected_preservation_case_receipt", `Unknown preservation case receipt: ${id || "(missing id)"}`));
      continue;
    }
    if (rowsById.has(id)) {
      reasons.push(errorReason("duplicate_preservation_case_receipt", `Multiple preservation receipts exist for ${id}`));
      continue;
    }
    rowsById.set(id, event);
  }

  const artifactByPath = new Map(context.artifacts.map((artifact) => [artifact.path, artifact]));
  const seenObservationPaths = new Set();
  const decodedDimensions = new Map();
  const validated = [];
  for (const expected of PRESERVATION_CASES) {
    const event = rowsById.get(expected.id);
    const testCase = passedTests.get(expected.id);
    if (!event || !testCase) {
      reasons.push(errorReason("missing_preservation_case_receipt", `Missing successful test or actual receipt for ${expected.id}`));
      continue;
    }
    const identity = testCase;
    // Playwright JSON reports a successful expected test as "expected";
    // retain "passed" for previously supported normalized report inputs.
    if (identity.attempts?.length !== 1 || identity.attempts[0]?.retry !== 0 || identity.attempts[0]?.status !== "passed" ||
      identity.expected_status !== "passed" || !["expected", "passed"].includes(identity.outcome)) {
      reasons.push(errorReason("preservation_test_not_single_clean_pass", `Held-out case ${expected.id} must have exactly one successful first attempt`, identity.key));
    }
    if (event.test_identity !== identity.key) reasons.push(errorReason("preservation_identity_mismatch", `Receipt identity does not match the successful test for ${expected.id}`, identity.key));
    if (event.product_source_sha !== context.productSourceSha || event.build_source_sha !== context.checkoutHead || event.product_tree_sha256 !== context.productTreeSha256) {
      reasons.push(errorReason("preservation_source_mismatch", `Receipt product/build/tree identities do not match the independently checked run source for ${expected.id}`, identity.key));
    }
    if (event.fixture_overlay_sha256 !== context.fixtureOverlaySha256) reasons.push(errorReason("preservation_fixture_mismatch", `Receipt fixture overlay does not match the checked out test-only fixtures for ${expected.id}`, identity.key));
    const runtime = event.runtime;
    if (!isRecord(runtime) || runtime.application_image_id !== context.applicationRuntimeId || runtime.standalone_ops_image_id !== context.standaloneOpsRuntimeId || runtime.browser_image_id !== context.browserRuntimeId ||
      !validDigest(runtime.effective_runtime_sha256) || !validDigest(runtime.browser_source_layer_id) || !validDigest(runtime.browser_base_layers_sha256) || !validDigest(event.recipe_sha256)) {
      reasons.push(errorReason("preservation_runtime_mismatch", `Receipt runtime identity does not match the run for ${expected.id}`, identity.key));
    }
    const recipe = event.clock_recipe;
    const clockSha = recipe?.clock_sha256;
    const profile = recipe?.font_profile;
    const profileRecipe = isRecord(recipe) ? Object.fromEntries(Object.entries(recipe).filter(([key]) => !["browser_date", "clock_sha256", "profile_sha256", "data_recipe_sha256"].includes(key))) : null;
    const sharedRecipe = commonRecipe(recipe);
    const dataRecipeSha = isRecord(event.data_recipe) ? `sha256:${crypto.createHash("sha256").update(JSON.stringify(canonicalize(event.data_recipe))).digest("hex")}` : "";
    if (!isRecord(recipe) || recipe.browser?.engine !== "chromium" || recipe.browser?.package !== "@playwright/test" ||
      !/^\d+\.\d+\.\d+(?:\.\d+)?(?:[-+][0-9A-Za-z.-]+)?$/.test(recipe.browser?.version || "") ||
      !/^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/.test(recipe.browser?.package_version || "") ||
      !Array.isArray(recipe.launch_args) || !recipe.launch_args.includes("--disable-partial-raster") ||
      recipe.locale !== "en-US" || recipe.timezone !== "UTC" || recipe.device_scale_factor !== 1 ||
      recipe.browser_date?.fixed !== true || recipe.browser_date?.timers_running !== true ||
      !Number.isFinite(recipe.browser_date?.timer_elapsed_ms) || recipe.browser_date.timer_elapsed_ms <= 20 ||
      !/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z$/.test(recipe.browser_date?.observed || "") ||
      !isRecord(profile) || profile.method !== "retained-cdp-fixed-font-v1" || profile.fixed_font_family !== "Liberation Mono" ||
      profile.applied !== "before-first-navigation" || profile.lifetime !== "page-context" ||
      !validDigest(recipe.profile_sha256) || !validDigest(recipe.data_recipe_sha256) || !validDigest(clockSha) ||
      `sha256:${crypto.createHash("sha256").update(JSON.stringify(canonicalize(profileRecipe))).digest("hex")}` !== recipe.profile_sha256 ||
      dataRecipeSha !== recipe.data_recipe_sha256 ||
      `sha256:${crypto.createHash("sha256").update(JSON.stringify(canonicalize(sharedRecipe))).digest("hex")}` !== event.recipe_sha256) {
      reasons.push(errorReason("invalid_preservation_clock_recipe", `Receipt lacks an observed fixed-clock recipe and genuine per-run timer sample for ${expected.id}`, identity.key));
    }
    if (!Array.isArray(event.actions) || event.actions.length === 0 || event.actions.some((action) => typeof action !== "string" || action.trim() === "")) {
      reasons.push(errorReason("invalid_preservation_actions", `Receipt lacks a concrete action sequence for ${expected.id}`, identity.key));
    }
    if (!Array.isArray(event.assertions) || event.assertions.length === 0 || event.assertions.some((assertion) =>
      !isRecord(assertion) || typeof assertion.name !== "string" || assertion.name.trim() === "" ||
      assertion.status !== "passed" || typeof assertion.actual !== "string" || assertion.actual.trim() === "")) {
      reasons.push(errorReason("invalid_preservation_case_assertions", `Receipt lacks passing observed case semantics for ${expected.id}`, identity.key));
    }
    if (!Array.isArray(event.transport_sequence) || event.transport_sequence.length === 0 || event.transport_sequence.some((step) =>
      !isRecord(step) || typeof step.operation !== "string" || step.operation.trim() === "" || typeof step.outcome !== "string" || step.outcome.trim() === "")) {
      reasons.push(errorReason("invalid_preservation_transport", `Receipt lacks observed request/LiveView transport outcomes for ${expected.id}`, identity.key));
    }

    const expectedMatrix = expected.category === "overflow" || expected.category === "long-text"
      ? PRESERVATION_THEMES.flatMap((theme) => PRESERVATION_VIEWPORT_WIDTHS.map((width) => `${theme}|${width}`))
      : null;
    const observations = [];
    const observationIds = new Set();
    if (!Array.isArray(event.observations)) {
      reasons.push(errorReason("missing_preservation_observations", `${expected.id} must carry explicit themed viewport observations`, identity.key));
    } else if (expectedMatrix && event.observations.length !== expectedMatrix.length) {
      reasons.push(errorReason("incomplete_preservation_observations", `${expected.id} requires all ${expectedMatrix.length} theme × viewport observations`, identity.key));
    } else if (!expectedMatrix && event.observations.length !== 1) {
      reasons.push(errorReason("invalid_preservation_observation_count", `${expected.id} must have exactly one explicitly declared theme and viewport observation`, identity.key));
    }
    for (const observation of Array.isArray(event.observations) ? event.observations : []) {
      try {
        if (!isRecord(observation) || !PRESERVATION_THEMES.includes(observation.theme) || !isRecord(observation.viewport) ||
          !PRESERVATION_VIEWPORT_WIDTHS.includes(observation.viewport.width) || observation.viewport.height !== (observation.viewport.width === 390 ? 844 : 900)) {
          throw new TypeError("observation must declare an approved theme and viewport");
        }
        const key = `${observation.theme}|${observation.viewport.width}`;
        if (observationIds.has(key)) throw new TypeError(`duplicate observation ${key}`);
        observationIds.add(key);
        if (expectedMatrix && !expectedMatrix.includes(key)) throw new TypeError(`unexpected observation ${key}`);
        const state = observation.state;
        if (observation.capture_profile !== "fullpage-neutral-and-viewport-hover-v1" ||
          !isRecord(state) || state.element !== expected.element || state.category !== expected.category || typeof state.route !== "string" || !state.route.startsWith("/") ||
          state.theme !== observation.theme || state.color_scheme !== (observation.theme === "light" ? "light" : "dark") ||
          !isRecord(state.viewport) || state.viewport.width !== observation.viewport.width || state.viewport.height !== observation.viewport.height ||
          !isRecord(state.scroll) || !Number.isFinite(state.scroll.x) || !Number.isFinite(state.scroll.y) ||
          !isRecord(state.focus) || typeof state.focus.name !== "string" || state.focus.name.trim() === "" ||
          state.focus.focus_visible !== true || state.focus.document_has_focus !== true ||
          !Array.isArray(state.hover) || state.hover.length !== 0 ||
          typeof state.data_identity !== "string" || state.data_identity.trim() === "" ||
          state.clock?.clock_sha256 !== clockSha || state.clock?.browser_iso !== recipe?.browser_date?.observed || state.clock?.server_iso !== recipe?.browser_date?.observed) {
          throw new TypeError("observation state/profile must record the neutral capture, matching route, theme, viewport, scroll, focus, data identity and fixed clock");
        }
        // The producer records the target in each captured state. A duplicate
        // top-level field is not required, but cannot contradict that evidence.
        const interactionTarget = state.interaction_target;
        const targetIdentity = validatePreservationInteractionTarget(interactionTarget);
        if (observation.interaction_target !== undefined &&
          JSON.stringify(canonicalize(preservationSemanticIdentity(observation.interaction_target))) !== JSON.stringify(canonicalize(targetIdentity))) {
          throw new TypeError("duplicate observation target contradicts its captured state target");
        }
        if (state.focus.name !== targetIdentity.name || state.focus.role !== targetIdentity.role || state.focus.tag !== targetIdentity.tag) {
          throw new TypeError("neutral capture focus must remain bound to its named interaction target");
        }
        if (!Array.isArray(observation.geometry) || observation.geometry.length === 0 || observation.geometry.some((item) =>
          !isRecord(item) || typeof item.name !== "string" || item.name.trim() === "" || ![item.x, item.y, item.width, item.height].every(Number.isFinite))) {
          throw new TypeError("observation lacks measured element and document geometry");
        }
        const documentGeometry = observation.geometry.find((item) => item.name === `document-${observation.viewport.width}` && item.viewport_width === observation.viewport.width);
        if (!documentGeometry || documentGeometry.width < observation.viewport.width || documentGeometry.height < observation.viewport.height) {
          throw new TypeError("observation does not report full-page document dimensions for its viewport");
        }
        if (!Array.isArray(observation.assertions) || observation.assertions.length === 0 || observation.assertions.some((assertion) =>
          !isRecord(assertion) || typeof assertion.name !== "string" || assertion.name.trim() === "" || assertion.status !== "passed" || typeof assertion.actual !== "string" || assertion.actual.trim() === "")) {
          throw new TypeError("observation lacks passing semantic and geometry assertions");
        }
        if (!Array.isArray(observation.visible_copy) || observation.visible_copy.length === 0 || observation.visible_copy.some((copy) =>
          !isRecord(copy) || typeof copy.text !== "string" || copy.text.trim() === "" || typeof copy.sha256 !== "string" || crypto.createHash("sha256").update(copy.text).digest("hex") !== copy.sha256)) {
          throw new TypeError("observation lacks exact visible copy and matching hashes");
        }
        const image = observation.image;
        if (!isRecord(image) || typeof image.path !== "string" || !/^[a-f0-9]{64}$/.test(image.sha256 || "")) throw new TypeError("observation image path and SHA-256 are required");
        const imagePath = normalizeArtifactPath(image.path);
        if (!imagePath.startsWith(PRESERVATION_ARTIFACT_ROOT) || path.posix.extname(imagePath).toLowerCase() !== ".png") throw new TypeError("image must be a PNG in the held-out preservation artifact bundle");
        if (seenObservationPaths.has(imagePath)) throw new TypeError("raw image artifact paths must be globally unique across every case and observation");
        seenObservationPaths.add(imagePath);
        if (image.capture !== "full-page-real-product-state" || !isRecord(image.viewport) || image.viewport.width !== observation.viewport.width || image.viewport.height !== observation.viewport.height ||
          !isRecord(image.full_page_raster) || !Number.isInteger(image.full_page_raster.width) || !Number.isInteger(image.full_page_raster.height)) {
          throw new TypeError("image metadata must bind the declared viewport and actual full-page raster geometry");
        }
        const artifact = context.rawBundle.artifacts.get(imagePath);
        if (!artifact?.present || artifact.sha256 !== image.sha256 || artifact.copied !== true || artifact.copy_status !== "success") throw new TypeError("image must be declared, copied, present and hash-matched in this run");
        const imageBytes = context.rawBundle.members.get(imagePath);
        const priorDimensions = decodedDimensions.get(image.sha256);
        if (priorDimensions && !priorDimensions.bytes.equals(imageBytes)) throw new TypeError("Equal raw image hashes have different bytes");
        const raster = priorDimensions?.dimensions || pngDimensions(imageBytes, `${expected.id} ${key}`);
        if (!priorDimensions) decodedDimensions.set(image.sha256, { bytes: imageBytes, dimensions: raster });
        const dpr = recipe.device_scale_factor;
        const expectedRaster = { width: observation.viewport.width * dpr, height: documentGeometry.height * dpr };
        if (image.full_page_raster.width !== raster.width || image.full_page_raster.height !== raster.height ||
          raster.width !== expectedRaster.width || raster.height !== expectedRaster.height) {
          throw new TypeError(`decoded full-page raster ${raster.width}x${raster.height} does not match viewport/document geometry ${expectedRaster.width}x${expectedRaster.height}`);
        }
        const sampling = observation.capture_sampling;
        const primarySnapshot = validatePreservationSampleProof({
          sampling, imagePath, sampleKind: "held-out", imageSha: image.sha256, imageRaster: raster, state, viewport: observation.viewport,
          documentGeometry, dpr, interactionTarget, expectHover: false, seenPaths: seenObservationPaths,
          rawBundleState: context.rawBundle, decodedDimensions, label: `${expected.id} ${key} full-page`
        });

        const hoverCapture = observation.hover_capture;
        if (!isRecord(hoverCapture) || !isRecord(hoverCapture.state) || !isRecord(hoverCapture.image) ||
          !Array.isArray(hoverCapture.assertions) || hoverCapture.assertions.length === 0 || hoverCapture.assertions.some((assertion) =>
            !isRecord(assertion) || typeof assertion.name !== "string" || assertion.name.trim() === "" || assertion.status !== "passed" ||
            typeof assertion.actual !== "string" || assertion.actual.trim() === "")) {
          throw new TypeError("observation lacks passing assertions and a separate viewport-hover state/image/sample proof");
        }
        const hoverState = hoverCapture.state;
        const crossShotStateIdentity = (value) => ({
          ...Object.fromEntries(Object.entries(value).filter(([name]) => !["hover", "dom_state_sha256", "focus"].includes(name))),
          focus: Object.fromEntries(["name", "role", "tag", "focus_visible", "document_has_focus"].map((name) => [name, value.focus?.[name]]))
        });
        if (JSON.stringify(canonicalize(crossShotStateIdentity(hoverState))) !== JSON.stringify(canonicalize(crossShotStateIdentity(state))) ||
          !Array.isArray(hoverState.hover) || hoverState.hover.length === 0 || !/^[a-f0-9]{64}$/.test(hoverState.dom_state_sha256 || "")) {
          throw new TypeError("hover state must preserve route, theme, viewport, scroll, data, clock and focused-control identity while retaining its own style");
        }
        const hoverImage = hoverCapture.image;
        if (typeof hoverImage.path !== "string" || !/^[a-f0-9]{64}$/.test(hoverImage.sha256 || "") ||
          hoverImage.path !== imagePath.replace(/\.png$/, "--hover.png")) {
          throw new TypeError("hover image must use the canonical viewport-hover capture path and SHA-256");
        }
        const hoverImagePath = normalizeArtifactPath(hoverImage.path);
        if (!hoverImagePath.startsWith(PRESERVATION_ARTIFACT_ROOT) || seenObservationPaths.has(hoverImagePath) ||
          hoverImage.capture !== "viewport-real-product-hover" ||
          JSON.stringify(canonicalize(hoverImage.viewport)) !== JSON.stringify(canonicalize(observation.viewport)) ||
          !isRecord(hoverImage.viewport_raster) || hoverImage.viewport_raster.width !== observation.viewport.width ||
          hoverImage.viewport_raster.height !== observation.viewport.height) {
          throw new TypeError("hover image must be a unique exact viewport raster in the held-out preservation bundle");
        }
        seenObservationPaths.add(hoverImagePath);
        const hoverArtifact = context.rawBundle.artifacts.get(hoverImagePath);
        if (!hoverArtifact?.present || hoverArtifact.sha256 !== hoverImage.sha256 || hoverArtifact.copied !== true || hoverArtifact.copy_status !== "success") {
          throw new TypeError("hover image must be declared, copied, present and hash-matched in this run");
        }
        const hoverImageBytes = context.rawBundle.members.get(hoverImagePath);
        if (!Buffer.isBuffer(hoverImageBytes)) throw new TypeError("hover image raw bytes are absent from the bounded bundle");
        const priorHoverDimensions = decodedDimensions.get(hoverImage.sha256);
        if (priorHoverDimensions && !priorHoverDimensions.bytes.equals(hoverImageBytes)) throw new TypeError("Equal raw hover image hashes have different bytes");
        const hoverRaster = priorHoverDimensions?.dimensions || pngDimensions(hoverImageBytes, `${expected.id} ${key} hover`);
        if (!priorHoverDimensions) decodedDimensions.set(hoverImage.sha256, { bytes: hoverImageBytes, dimensions: hoverRaster });
        if (hoverRaster.width !== observation.viewport.width || hoverRaster.height !== observation.viewport.height ||
          hoverImage.viewport_raster.width !== hoverRaster.width || hoverImage.viewport_raster.height !== hoverRaster.height) {
          throw new TypeError("decoded hover image must be exactly the unscaled current viewport raster");
        }
        const hoverSnapshot = validatePreservationSampleProof({
          sampling: hoverCapture.capture_sampling, imagePath: hoverImagePath, sampleKind: "hover", imageSha: hoverImage.sha256,
          imageRaster: hoverRaster, state: hoverState, viewport: observation.viewport, documentGeometry, dpr,
          interactionTarget, expectHover: true, seenPaths: seenObservationPaths,
          rawBundleState: context.rawBundle, decodedDimensions, label: `${expected.id} ${key} hover`
        });
        const rawCrossShotIdentity = (value) => {
          const focusedControl = value.controls.find((control) =>
            JSON.stringify(canonicalize(preservationSemanticIdentity(control))) === JSON.stringify(canonicalize(targetIdentity)));
          return {
            schema: value.schema,
            viewport: value.viewport,
            theme: value.theme,
            document_has_focus: value.document_has_focus,
            focus: { element: preservationSemanticIdentity(value.focus?.element), focus_visible: value.focus?.focus_visible },
            focused_control: focusedControl ? {
              ...preservationSemanticIdentity(focusedControl),
              value: focusedControl.value,
              checked: focusedControl.checked,
              selected: focusedControl.selected,
              disabled: focusedControl.disabled,
              expanded: focusedControl.expanded,
              pressed: focusedControl.pressed
            } : null
          };
        };
        if (JSON.stringify(canonicalize(rawCrossShotIdentity(primarySnapshot))) !== JSON.stringify(canonicalize(rawCrossShotIdentity(hoverSnapshot)))) {
          throw new TypeError("viewport-hover raw state differs from the neutral capture in shared viewport, theme or focused-control identity");
        }
        observations.push({
          theme: observation.theme,
          viewport: { width: observation.viewport.width, height: observation.viewport.height },
          capture_profile: observation.capture_profile,
          state,
          interaction_target: targetIdentity,
          geometry: observation.geometry,
          assertions: observation.assertions,
          capture_sampling: sampling,
          visible_copy: observation.visible_copy,
          image: { path: imagePath, sha256: image.sha256, viewport: image.viewport, full_page_raster: raster, capture: image.capture },
          hover_capture: {
            state: hoverState,
            image: { path: hoverImagePath, sha256: hoverImage.sha256, viewport: hoverImage.viewport, viewport_raster: hoverRaster, capture: hoverImage.capture },
            capture_sampling: hoverCapture.capture_sampling,
            assertions: hoverCapture.assertions
          }
        });
      } catch (error) {
        reasons.push(errorReason("invalid_preservation_observation", `${expected.id}: ${error.message}`, identity.key));
      }
    }
    if (expectedMatrix && expectedMatrix.some((key) => !observationIds.has(key))) {
      reasons.push(errorReason("missing_preservation_observation", `${expected.id} does not cover every light/dark/system-dark × 1440/768/390 observation`, identity.key));
    }
    let clockArtifact = null;
    try {
      if (!isRecord(event.clock_artifact) || typeof event.clock_artifact.path !== "string" || event.clock_artifact.path !== "ui-review-artifacts/iteration3-journeys/phase185-held-out/phase185-clock.txt" || !/^[a-f0-9]{64}$/.test(event.clock_artifact.sha256 || "")) throw new TypeError("the immutable fixed-clock bytes must be a declared run artifact");
      const artifact = artifactByPath.get(event.clock_artifact.path);
      if (!artifact?.present || artifact.sha256 !== event.clock_artifact.sha256 || artifact.copied !== true || artifact.copy_status !== "success" || `sha256:${event.clock_artifact.sha256}` !== clockSha) throw new TypeError("fixed-clock artifact bytes do not match the observed clock digest");
      const bytes = fs.readFileSync(resolveArtifact(context.runRoot, event.clock_artifact.path).path);
      const { instant } = parsePhase185ClockFixture(bytes);
      if (instant !== recipe?.browser_date?.observed || !/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z$/.test(instant)) throw new TypeError("actual server/browser clock does not match the preserved immutable fixture bytes");
      clockArtifact = { path: event.clock_artifact.path, sha256: event.clock_artifact.sha256 };
    } catch (error) {
      reasons.push(errorReason("invalid_preservation_clock_artifact", `${expected.id}: ${error.message}`, identity.key));
    }
    validated.push({ id: expected.id, test_identity: identity.key, product_source_sha: event.product_source_sha, build_source_sha: event.build_source_sha, product_tree_sha256: event.product_tree_sha256,
      fixture_overlay_sha256: event.fixture_overlay_sha256, runtime: isRecord(runtime) ? runtime : null,
      recipe_sha256: event.recipe_sha256, clock_recipe: isRecord(recipe) ? recipe : null, data_recipe: isRecord(event.data_recipe) ? event.data_recipe : null, clock_artifact: clockArtifact,
      actions: Array.isArray(event.actions) ? event.actions : [], assertions: Array.isArray(event.assertions) ? event.assertions : [],
      transport_sequence: Array.isArray(event.transport_sequence) ? event.transport_sequence : [], observations
    });
  }
  if (context.rawBundle.members.size !== seenObservationPaths.size || [...context.rawBundle.members.keys()].some((name) => !seenObservationPaths.has(name))) {
    reasons.push(errorReason("unexpected_preservation_bundle_member", "The bounded bundle must contain exactly the observed raw case images"));
  }
  return validated.sort((left, right) => left.id.localeCompare(right.id));
}

function reconcileInventory({ inventory, report, repoRoot = process.cwd(), allowedSkips = [], requireMandatoryCases = false, preservationOnly = false } = {}) {
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

  if (requireMandatoryCases) reasons.push(...mandatoryInventoryReasons(inventoryResult.cases, { preservationOnly }));
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

const FULL_PARTITIONS = ["ordinary", "preservation"];
const PRESERVATION_FILES = new Set([
  "examples/scrypath_ecommerce/e2e/ui_state_preservation.spec.ts",
  "examples/scrypath_ecommerce/e2e/ui_content_preservation.spec.ts"
]);

function partitionInventory(inventory, group, repoRoot = REPOSITORY_ROOT) {
  if (!FULL_PARTITIONS.includes(group)) throw new Error("unknown full-run partition");
  const parsed = parsePlaywrightCases(inventory, { repoRoot, label: "inventory" });
  const reasons = [...parsed.reasons];
  addDuplicateReasons(parsed.cases, "inventory", reasons);
  if (reasons.length || !parsed.cases.length) throw new Error("partitioning requires a nonempty valid unfiltered inventory");
  const selected = parsed.cases.filter(({ identity }) => PRESERVATION_FILES.has(identity.file) === (group === "preservation"));
  if (!selected.length) throw new Error(`full-run partition is empty: ${group}`);
  return { cases: selected, files: [...new Set(selected.map(({ identity }) => identity.file))].sort() };
}

function auditPartitionReports({ inventory, reports, repoRoot = REPOSITORY_ROOT }) {
  if (!Array.isArray(reports) || reports.length !== 2) throw new Error("exactly two serial partition reports are required");
  const inventories = parsePlaywrightCases(inventory, { repoRoot, label: "inventory" });
  const expected = new Set(inventories.cases.map(({ identity }) => identity.key));
  const seen = new Set();
  const parts = FULL_PARTITIONS.map((group) => {
    const matches = reports.filter((item) => item.group === group);
    if (matches.length !== 1 || matches[0].exit_code !== 0) throw new Error(`partition did not exit successfully: ${group}`);
    const config = matches[0].report?.config;
    if (config?.workers !== 1 || config.fullyParallel !== false || config.shard !== null ||
      !Array.isArray(config.projects) || config.projects.length !== 1 || config.projects[0].name !== "chromium" ||
      config.projects[0].retries !== 0 || config.projects[0].repeatEach !== 1) throw new Error("partition changed the single-worker Chromium/no-retry policy");
    const planned = partitionInventory(inventory, group, repoRoot);
    const wanted = new Set(planned.cases.map(({ identity }) => identity.key));
    const parsed = parsePlaywrightCases(matches[0].report, { repoRoot, includeAttempts: true, label: "report" });
    if (parsed.reasons.length || parsed.cases.length !== wanted.size) throw new Error(`partition report count/shape mismatch: ${group}`);
    for (const item of parsed.cases) {
      if (!wanted.has(item.identity.key) || seen.has(item.identity.key)) throw new Error("partition reports overlap or contain an unexpected identity");
      if (item.expected_status !== "passed" || item.outcome !== "expected" || item.attempts.length !== 1 || item.attempts[0].retry !== 0 || item.attempts[0].status !== "passed") throw new Error("partition contains a failed, skipped, expected-failure or retried case");
      seen.add(item.identity.key);
    }
    return { group, cases: wanted.size, files: planned.files };
  });
  if (seen.size !== expected.size || [...expected].some((key) => !seen.has(key))) throw new Error("partition union does not equal the complete inventory");
  return { protocol: "serial-two-group-v1", cases: seen.size, parts };
}

function partitionRoot(runDir, group) {
  if (!FULL_PARTITIONS.includes(group)) throw new Error("unknown full-run partition");
  return path.join(`${runDir}.parts`, group, path.basename(runDir));
}

function runFullPartition(runDir, group) {
  if (path.basename(runDir) !== process.env.E2E_RUN_ID || !/^phase185-[A-Za-z0-9._-]+$/.test(process.env.E2E_RUN_ID || "")) throw new Error("partition needs the canonical owned run identity");
  const directory = partitionRoot(runDir, group);
  if (fs.existsSync(directory)) throw new Error("partition directory already exists");
  const started = new Date();
  const result = spawnSync("bash", [path.join(REPOSITORY_ROOT, "examples/scrypath_ecommerce/docker-playwright.sh")], {
    cwd: path.join(REPOSITORY_ROOT, "examples/scrypath_ecommerce"),
    env: { ...process.env, E2E_ARTIFACT_DIR: directory, E2E_FULL_PARTITION: group },
    stdio: "inherit", timeout: 880000
  });
  const code = result.error?.code === "ETIMEDOUT" ? 124 : (result.status ?? 1);
  if (fs.existsSync(directory)) {
    const metadata = { group, run_id: process.env.E2E_RUN_ID, source_sha: process.env.SCRYPATH_SOURCE_SHA,
      image_ids: [process.env.E2E_APPLICATION_IMAGE_ID, process.env.E2E_STANDALONE_OPS_IMAGE_ID, process.env.E2E_BROWSER_IMAGE_ID],
      started_at: started.toISOString(), ended_at: new Date().toISOString(), exit_code: code, operation_cap_seconds: 900 };
    fs.writeFileSync(path.join(directory, "partition-run.json"), `${JSON.stringify(metadata, null, 2)}\n`, { flag: "wx" });
  }
  return code;
}

function assembleFullPartitions(runDir) {
  if (fs.existsSync(runDir) || path.basename(runDir) !== process.env.E2E_RUN_ID) throw new Error("aggregate needs a fresh owned run directory");
  const read = (directory, name) => {
    const file = path.join(directory, name), stat = fs.lstatSync(file);
    if (!stat.isFile() || stat.isSymbolicLink() || stat.size > MAX_JSON_BYTES) throw new Error("invalid partition metadata file");
    return JSON.parse(fs.readFileSync(file, "utf8"));
  };
  const rows = FULL_PARTITIONS.map((group) => {
    const directory = partitionRoot(runDir, group), metadata = read(directory, "partition-run.json");
    if (metadata.group !== group || metadata.run_id !== process.env.E2E_RUN_ID || metadata.source_sha !== process.env.SCRYPATH_SOURCE_SHA ||
      JSON.stringify(metadata.image_ids) !== JSON.stringify([process.env.E2E_APPLICATION_IMAGE_ID, process.env.E2E_STANDALONE_OPS_IMAGE_ID, process.env.E2E_BROWSER_IMAGE_ID]) ||
      metadata.exit_code !== 0 || metadata.operation_cap_seconds !== 900 || Date.parse(metadata.ended_at) - Date.parse(metadata.started_at) > 900000 || !(Date.parse(metadata.ended_at) >= Date.parse(metadata.started_at))) throw new Error("partition run/source/image/deadline mismatch");
    return { group, directory, metadata, inventory: read(directory, INVENTORY_NAME), report: read(directory, PLAYWRIGHT_NAME), stages: read(directory, "stages.json") };
  });
  const keySet = (inventory) => parsePlaywrightCases(inventory, { repoRoot: REPOSITORY_ROOT }).cases.map(({ identity }) => identity.key).sort();
  if (JSON.stringify(keySet(rows[0].inventory)) !== JSON.stringify(keySet(rows[1].inventory))) throw new Error("partition discovery inventories disagree");
  if (Date.parse(rows[0].metadata.ended_at) > Date.parse(rows[1].metadata.started_at)) throw new Error("partitions were not serial");
  const audit = auditPartitionReports({ inventory: rows[0].inventory, reports: rows.map((row) => ({ ...row, exit_code: row.metadata.exit_code })) });
  fs.mkdirSync(runDir, { mode: 0o700 });
  fs.mkdirSync(path.join(runDir, "blob-report"));
  const move = (source, destination) => {
    const stat = fs.lstatSync(source);
    if (stat.isSymbolicLink()) throw new Error("partition artifacts must not be links");
    if (stat.isDirectory()) {
      fs.mkdirSync(destination, { recursive: true });
      for (const name of fs.readdirSync(source)) if (!name.startsWith(".")) move(path.join(source, name), path.join(destination, name));
    } else {
      if (!stat.isFile() || fs.existsSync(destination)) throw new Error("partition artifact collision or nonregular file");
      fs.mkdirSync(path.dirname(destination), { recursive: true }); fs.renameSync(source, destination);
    }
  };
  for (const row of rows) {
    const destination = path.join(runDir, "partitions", row.group); fs.mkdirSync(destination, { recursive: true });
    for (const name of [INVENTORY_NAME, PLAYWRIGHT_NAME, "stages.json", "partition-run.json", "phase105-evidence.ndjson", "browser.log"]) fs.copyFileSync(path.join(row.directory, name), path.join(destination, name));
    if (fs.lstatSync(path.join(row.directory, "blob-report/report.zip")).size > MAX_ARTIFACT_BYTES) throw new Error("partition blob report exceeds the artifact bound");
    move(path.join(row.directory, "blob-report/report.zip"), path.join(runDir, "blob-report", `${row.group}.zip`));
    for (const name of ["test-results", "ui-review-artifacts", "phase185-raw-staging"]) if (fs.existsSync(path.join(row.directory, name))) move(path.join(row.directory, name), path.join(runDir, name));
  }
  fs.copyFileSync(path.join(rows[0].directory, INVENTORY_NAME), path.join(runDir, INVENTORY_NAME));
  fs.copyFileSync(path.join(runDir, INVENTORY_NAME), path.join(runDir, "phase105-inventory.json"));
  fs.writeFileSync(path.join(runDir, "phase105-evidence.ndjson"), rows.map((row) => fs.readFileSync(path.join(row.directory, "phase105-evidence.ndjson"), "utf8")).join(""));
  fs.writeFileSync(path.join(runDir, "browser.log"), rows.map((row) => fs.readFileSync(path.join(row.directory, "browser.log"), "utf8")).join("\n"));
  const merged = spawnSync("npx", ["playwright", "merge-reports", "--reporter=list,json,html", path.join(runDir, "blob-report")], {
    cwd: path.join(REPOSITORY_ROOT, "examples/scrypath_ecommerce"), stdio: "inherit", timeout: 120000,
    env: { ...process.env, PLAYWRIGHT_JSON_OUTPUT_FILE: path.join(runDir, PLAYWRIGHT_NAME), PLAYWRIGHT_HTML_OUTPUT_DIR: path.join(runDir, "playwright-report"), PLAYWRIGHT_HTML_OPEN: "never" }
  });
  if (merged.status !== 0) throw new Error("partition report merge failed");
  const reconciliation = reconcileInventory({ inventory: rows[0].inventory, report: read(runDir, PLAYWRIGHT_NAME), repoRoot: REPOSITORY_ROOT });
  if (!reconciliation.eligible || reconciliation.case_count !== audit.cases) throw new Error("merged report differs from the complete disjoint partition union");
  const stages = { inventory: rows[0].stages.inventory, browser: { started_at: rows[0].stages.browser.started_at, ended_at: rows[1].stages.browser.ended_at, exit_code: 0 }, light_parity: { started_at: null, ended_at: null, exit_code: null }, contrast: { started_at: null, ended_at: null, exit_code: null }, artifact_copy: { started_at: null, ended_at: null, exit_code: null } };
  fs.writeFileSync(path.join(runDir, "stages.json"), `${JSON.stringify(stages, null, 2)}\n`);
  const receipt = { ...audit, run_id: process.env.E2E_RUN_ID, source_sha: process.env.SCRYPATH_SOURCE_SHA, parts: rows.map((row) => ({ ...row.metadata, report: `partitions/${row.group}/${PLAYWRIGHT_NAME}`, report_sha256: `sha256:${crypto.createHash("sha256").update(fs.readFileSync(path.join(runDir, "partitions", row.group, PLAYWRIGHT_NAME))).digest("hex")}` })) };
  validateFullPartitionEvidence(runDir, receipt, rows[0].inventory, read(runDir, PLAYWRIGHT_NAME), process.env.SCRYPATH_SOURCE_SHA, rows[0].metadata.image_ids, process.env.E2E_RUN_ID);
  fs.writeFileSync(path.join(runDir, "partitions/manifest.json"), `${JSON.stringify(receipt, null, 2)}\n`);
  return receipt;
}

function finishPartitionChecks(runDir) {
  const stagesFile = path.join(runDir, "stages.json");
  const stages = readJson(stagesFile);
  const environment = { ...process.env, E2E_ARTIFACT_DIR: runDir, PHASE105_EVIDENCE_PATH: path.join(runDir, EVENTS_NAME), ADMIN_SCREENSHOT_DIR: path.join(runDir, "test-results/admin-screenshots"), ADMIN_LIGHT_PARITY_REPORT: path.join(runDir, "admin-light-parity.json"), CONTRAST_REPORT_DIR: path.join(runDir, "test-results/contrast") };
  let first = 0;
  for (const [name, command, args] of [["light_parity", "npm", ["run", "test:e2e:admin-light-parity"]], ["contrast", "node", ["contrast-checker.mjs"]]]) {
    const started_at = new Date().toISOString();
    const log = fs.openSync(path.join(runDir, `${name}.log`), "wx");
    let result;
    try { result = spawnSync(command, args, { cwd: path.join(REPOSITORY_ROOT, "examples/scrypath_ecommerce"), env: environment, stdio: ["ignore", log, log], timeout: 120000 }); }
    finally { fs.closeSync(log); }
    const exit_code = result.error?.code === "ETIMEDOUT" ? 124 : (result.status ?? 1);
    stages[name] = { started_at, ended_at: new Date().toISOString(), exit_code };
    fs.writeFileSync(stagesFile, `${JSON.stringify(stages, null, 2)}\n`);
    fs.appendFileSync(path.join(runDir, EVENTS_NAME), `${JSON.stringify({ operation: name, ...stages[name] })}\n`);
    if (!first && exit_code) first = exit_code;
  }
  const token = path.join(runDir, "test-results/contrast/contrast-report.token.json");
  if (fs.existsSync(token)) fs.copyFileSync(token, path.join(runDir, "contrast-report.json"));
  return first;
}

function validateFullPartitionEvidence(root, manifest, inventory, report, sourceSha, imageIds, runId) {
  root = fs.realpathSync(root);
  if (manifest.protocol !== "serial-two-group-v1" || manifest.source_sha !== sourceSha || manifest.run_id !== runId || !Array.isArray(manifest.parts) || manifest.parts.length !== 2) throw new Error("serial partition source/run/protocol mismatch");
  const rows = FULL_PARTITIONS.map((group, index) => {
    const row = manifest.parts[index];
    if (row.group !== group || row.exit_code !== 0 || row.operation_cap_seconds !== 900 || row.source_sha !== sourceSha || row.run_id !== runId ||
      JSON.stringify(row.image_ids) !== JSON.stringify(imageIds) || !Number.isFinite(Date.parse(row.started_at)) || !Number.isFinite(Date.parse(row.ended_at)) ||
      Date.parse(row.ended_at) < Date.parse(row.started_at) || Date.parse(row.ended_at) - Date.parse(row.started_at) > 900000) throw new Error("serial partition status/source/image/deadline mismatch");
    if (index && Date.parse(manifest.parts[index - 1].ended_at) > Date.parse(row.started_at)) throw new Error("partition execution overlaps");
    const relative = `partitions/${group}/${PLAYWRIGHT_NAME}`;
    if (row.report !== relative) throw new Error("partition report locator mismatch");
    const file = resolveArtifact(root, relative);
    if (file.stat.size > MAX_JSON_BYTES || `sha256:${crypto.createHash("sha256").update(fs.readFileSync(file.path)).digest("hex")}` !== row.report_sha256) throw new Error("partition report digest mismatch");
    return { group, exit_code: row.exit_code, report: readJson(file.path) };
  });
  const audit = auditPartitionReports({ inventory, reports: rows });
  if (audit.cases !== manifest.cases) throw new Error("partition declared case count mismatch");
  const raw = rows.flatMap((row) => parsePlaywrightCases(row.report, { includeAttempts: true, repoRoot: REPOSITORY_ROOT }).cases);
  const merged = parsePlaywrightCases(report, { includeAttempts: true, repoRoot: REPOSITORY_ROOT }).cases;
  const canonical = (cases) => JSON.stringify(cases.sort((a, b) => a.identity.key.localeCompare(b.identity.key)));
  if (canonical(raw) !== canonical(merged)) throw new Error("merged outcomes differ from raw partition reports");
  return manifest;
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

function isAllowedArtifactPath(value) {
  if (typeof value !== "string" || value.trim() === "" || value.includes("\0")) return false;
  const relative = value.trim().replaceAll("\\", "/");
  const segments = relative.split("/");
  return !relative.startsWith("/") &&
    !/^[A-Za-z]:\//.test(relative) &&
    !segments.some((segment) => segment === "" || segment === "." || segment === ".." || segment.startsWith(".")) &&
    ALLOWED_ARTIFACT_PREFIXES.some((prefix) => relative.startsWith(prefix));
}

function normalizeArtifactPath(value, { allowOutputs = false } = {}) {
  if (typeof value !== "string" || value.trim() === "" || value.includes("\0")) {
    throw new TypeError("artifact path must be a non-empty relative path");
  }
  const normalized = value.trim().replaceAll("\\", "/");
  if (normalized.startsWith("/") || /^[A-Za-z]:\//.test(normalized)) throw new TypeError("absolute artifact paths are forbidden");
  const segments = normalized.split("/");
  if (segments.some((segment) => segment === ".." || segment === "")) throw new TypeError("artifact traversal is forbidden");
  if (segments.some((segment) => segment.startsWith("."))) throw new TypeError("hidden artifact paths are excluded by the hosted uploader");
  const clean = path.posix.normalize(normalized);
  if (
    !REQUIRED_ARTIFACT_PATHS.includes(clean) &&
    !(allowOutputs && (clean === RECEIPT_NAME || clean === SUMMARY_NAME || clean === BEFORE_ONLY_RECEIPT_NAME)) &&
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
    if (error.code === "ENOENT" && !required) return null;
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

function parsePhase185ClockFixture(bytes) {
  if (!Buffer.isBuffer(bytes) || bytes.length === 0 || bytes.length > 128) throw new TypeError("Clock fixture must contain at most128 bytes of a single UTC instant");
  const raw = new TextDecoder("utf-8", { fatal: true }).decode(bytes);
  const instant = raw.endsWith("\n") ? raw.slice(0, -1) : raw;
  if (!/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z$/.test(instant) || Number.isNaN(Date.parse(instant)) || new Date(instant).toISOString() !== instant) throw new TypeError("Clock fixture must be one millisecond UTC instant with at most one final LF");
  return { instant, sha256: `sha256:${crypto.createHash("sha256").update(bytes).digest("hex")}` };
}

function commonRecipe(recipe) {
  if (!isRecord(recipe)) return null;
  const normalized = structuredClone(recipe);
  if (isRecord(normalized.browser_date)) delete normalized.browser_date.timer_elapsed_ms;
  return normalized;
}

function pngDimensions(bytes, label = "PNG") {
  if (!Buffer.isBuffer(bytes) || bytes.length < 24 || !bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) {
    throw new TypeError(`${label} does not have a complete PNG header`);
  }
  const width = bytes.readUInt32BE(16);
  const height = bytes.readUInt32BE(20);
  if (!Number.isInteger(width) || !Number.isInteger(height) || width < 1 || height < 1 ||
    width > MAX_IMAGE_DIMENSION || height > MAX_IMAGE_DIMENSION || width * height > MAX_IMAGE_PIXELS) {
    throw new RangeError(`${label} dimensions exceed the bounded image policy`);
  }
  // Metadata and historical receipt tools also run in clean, Node-free
  // consumer copies. Only actual image validation needs the browser package.
  const { PNG } = require("../../examples/scrypath_ecommerce/node_modules/pngjs");
  const decoded = PNG.sync.read(bytes);
  if (decoded.width !== width || decoded.height !== height) throw new TypeError(`${label} decoded dimensions disagree with its PNG header`);
  return { width, height };
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

function buildReceipt(runDir, { generatedAt = new Date().toISOString(), expectedSource = null, scope = "full", repoRoot = REPOSITORY_ROOT, verifyGitObjects = true } = {}) {
  if (scope !== "full" && scope !== "before-only") throw new TypeError("evidence scope must be full or before-only");
  const beforeOnly = scope === "before-only";
  const reasons = [];
  const root = resolveRunRoot(runDir);
  const input = readJsonArtifact(root, INPUT_NAME, reasons);
  const inventory = readJsonArtifact(root, INVENTORY_NAME, reasons);
  const report = readJsonArtifact(root, PLAYWRIGHT_NAME, reasons);
  const lightParity = readJsonArtifact(root, "admin-light-parity.json", reasons, { required: !beforeOnly });
  const contrast = readJsonArtifact(root, "contrast-report.json", reasons, { required: !beforeOnly });
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
  const productSourceSha = requiredString(sourceInput, "product_source_sha", "source", reasons);
  const qualificationSha256 = typeof sourceInput.qualification_sha256 === "string" ? sourceInput.qualification_sha256 : null;
  if (expectedSource && (expectedSource.sourceSha !== productSourceSha || expectedSource.buildSourceSha !== checkoutHead ||
      (beforeOnly && expectedSource.qualificationSha256 !== qualificationSha256))) {
    reasons.push(errorReason("expected_source_mismatch", "Run product and build source SHAs do not match the independent pair authority"));
  }
  if (beforeOnly && !validDigest(qualificationSha256)) {
    reasons.push(errorReason("invalid_before_qualification_digest", "Before-only evidence must retain the independently pinned raw Plan05 qualification digest"));
  }
  const builtSourceSha = requiredString(sourceInput, "built_source_sha", "source", reasons);
  const eventSha = typeof sourceInput.event_sha === "string" && sourceInput.event_sha.trim() ? sourceInput.event_sha.trim() : null;
  const dirty = sourceInput.dirty;
  if (typeof dirty !== "boolean") reasons.push(errorReason("missing_source_dirty_state", "source.dirty must be a boolean"));
  if (!validSha(checkoutHead)) reasons.push(errorReason("invalid_checkout_sha", "source.checkout_head must be a full Git SHA"));
  if (!validSha(builtSourceSha)) reasons.push(errorReason("invalid_built_source_sha", "source.built_source_sha must be a full Git SHA"));
  if (sourceMode === "hosted") {
    if (!validSha(eventSha)) reasons.push(errorReason("invalid_event_sha", "hosted source.event_sha must be a full Git SHA"));
    if (dirty !== false) reasons.push(errorReason("hosted_source_dirty", "hosted proof requires a clean checkout"));
    if ((!beforeOnly && (eventSha !== checkoutHead || eventSha !== builtSourceSha || eventSha !== productSourceSha)) || eventSha !== checkoutHead || eventSha !== builtSourceSha || workflowInput.sha !== eventSha) {
      reasons.push(errorReason("source_sha_mismatch", "checkout, event, built source and workflow SHA must match"));
    }
  } else if (dirty === true) {
    if (!validDigest(sourceInput.dirty_fingerprint)) {
      reasons.push(errorReason("missing_dirty_fingerprint", "dirty local proof requires a full SHA-256 source fingerprint"));
    }
  } else if (sourceMode === "local" && checkoutHead !== builtSourceSha) {
    reasons.push(errorReason("source_sha_mismatch", "clean local checkout and built source SHA must match"));
  }
  if (!validSha(productSourceSha)) reasons.push(errorReason("invalid_product_source_sha", "source.product_source_sha must be a full Git SHA"));

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
  const standaloneOpsInput = isRecord(imageInput.standalone_ops) ? imageInput.standalone_ops : {};
  const standaloneOpsBuiltId = requiredString(standaloneOpsInput, "built_id", "images.standalone_ops", reasons);
  const standaloneOpsRuntimeId = requiredString(standaloneOpsInput, "runtime_id", "images.standalone_ops", reasons);
  if (!validDigest(standaloneOpsBuiltId) || !validDigest(standaloneOpsRuntimeId) || standaloneOpsBuiltId !== standaloneOpsRuntimeId) {
    reasons.push(errorReason("invalid_image_id", "standalone_ops built/runtime IDs must be the same immutable sha256 digest"));
  }
  images.standalone_ops = { built_id: standaloneOpsBuiltId, runtime_id: standaloneOpsRuntimeId };

  const composeScope = requiredString(composeInput, "scope", "compose", reasons);
  const composeProject = requiredString(composeInput, "project", "compose", reasons);
  const targets = Array.isArray(composeInput.targets) ? composeInput.targets.filter((target) => typeof target === "string") : [];
  const modelDigest = requiredString(composeInput, "model_digest", "compose", reasons);
  if (composeScope !== "full") reasons.push(errorReason("wrong_compose_scope", "Browser proof requires full Compose scope"));
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

  const stageNames = beforeOnly ? ["inventory", "browser", "artifact_copy"] : REQUIRED_STAGES;
  const stages = {};
  for (const name of stageNames) stages[name] = normalizeStage(name, stageInput[name], reasons);

  const checkers = {};
  for (const [name, file, checker] of [
    ["light_parity", "admin-light-parity.json", lightParity],
    ["contrast", "contrast-report.json", contrast]
  ]) {
    if (beforeOnly) continue;
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
    repoRoot: REPOSITORY_ROOT,
    allowedSkips: Array.isArray(manifest.allowed_skips) ? manifest.allowed_skips : [],
    requireMandatoryCases: true,
    preservationOnly: beforeOnly
  });
  reasons.push(...reconciliation.reasons);
  if (beforeOnly && reconciliation.case_count !== PRESERVATION_CASES.length) {
    reasons.push(errorReason("before_only_scope_mismatch", `Before-only receipt must contain only the ${PRESERVATION_CASES.length} held-out preservation cases`));
  }

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

  const requiredArtifactPaths = beforeOnly ? BEFORE_ONLY_REQUIRED_ARTIFACT_PATHS : REQUIRED_ARTIFACT_PATHS;
  const artifactPaths = new Set([...requiredArtifactPaths, ...declaredByPath.keys()]);
  const artifacts = [];
  let totalArtifactBytes = 0;
  for (const artifactPath of [...artifactPaths].sort()) {
    const declared = declaredByPath.get(artifactPath);
    const required = requiredArtifactPaths.includes(artifactPath) || declared?.required === true;
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
  const actualBrowserRecipe = events.find((event) => event.operation === "ui_preservation_case")?.clock_recipe?.browser;
  if (!isRecord(actualBrowserRecipe) || actualBrowserRecipe.engine !== "chromium" || actualBrowserRecipe.package !== "@playwright/test" ||
    !/^[0-9]+\.[0-9]+\.[0-9]+(?:\.[0-9]+)?(?:[-+][0-9A-Za-z.-]+)?$/.test(actualBrowserRecipe.version || "") ||
    actualBrowserRecipe.package_version !== packageVersion) {
    reasons.push(errorReason("actual_browser_profile_missing", "Actual Chromium and installed Playwright versions must be observed by held-out browser cases"));
  }
  let productTreeSha256 = null;
  let fixtureOverlaySha256 = null;
  try {
    if (expectedSource) {
      const sourceRoot = path.resolve(repoRoot);
      const gitAvailable = (() => {
        try { execFileSync("git", ["-C", sourceRoot, "rev-parse", "--git-dir"], { stdio: "ignore" }); return true; }
        catch { return false; }
      })();
      if (verifyGitObjects && !gitAvailable) throw new TypeError("Pinned source replay requires the independently available Git objects");
      if (verifyGitObjects && gitAvailable) {
        const overlay = validateSourceOverlay(sourceRoot, expectedSource.sourceSha, expectedSource.buildSourceSha);
        productTreeSha256 = overlay.productTreeSha256;
        fixtureOverlaySha256 = overlay.fixtureOverlaySha256;
      } else {
        productTreeSha256 = productTreeIdentity(sourceRoot);
        fixtureOverlaySha256 = fixtureOverlayDigest(sourceRoot);
      }
    } else {
      productTreeSha256 = productTreeIdentity(REPOSITORY_ROOT);
      fixtureOverlaySha256 = fixtureOverlayDigest(REPOSITORY_ROOT);
    }
  } catch (error) {
    reasons.push(errorReason("preservation_source_identity_unavailable", error.message));
  }
  if (expectedSource && (!validDigest(expectedSource.productTreeSha256) || !validDigest(expectedSource.fixtureOverlaySha256))) {
    reasons.push(errorReason("invalid_expected_preservation_identity", "Independent pair authority requires full product-tree and fixture-overlay SHA-256 digests"));
  }
  if (expectedSource && (expectedSource.productTreeSha256 !== productTreeSha256 || expectedSource.fixtureOverlaySha256 !== fixtureOverlaySha256)) {
    reasons.push(errorReason("expected_preservation_identity_mismatch", "Run product tree or test-only fixture overlay differs from the independent pair authority"));
  }
  const preservationBundle = loadPreservationRawBundle(root, artifacts, reasons);
  const preservationCases = validatePreservationEvents(events, reconciliation, {
    runRoot: root,
    checkoutHead,
    productSourceSha,
    productTreeSha256,
    fixtureOverlaySha256,
    applicationRuntimeId: images.application?.runtime_id,
    standaloneOpsRuntimeId: images.standalone_ops?.runtime_id,
    browserRuntimeId: images.browser?.runtime_id,
    rawBundle: preservationBundle,
    artifacts
  }, reasons);
  const operationCounts = {};
  for (const event of events) operationCounts[event.operation] = (operationCounts[event.operation] || 0) + 1;
  const sortedOperations = Object.fromEntries(Object.entries(operationCounts).sort(([left], [right]) => left.localeCompare(right)));

  if (manifest.first_failure !== null && manifest.first_failure !== undefined) {
    reasons.push(errorReason("original_run_failure", "The verifier recorded an original failure; later evidence collection cannot replace it"));
  }
  let execution = null;
  if (manifest.execution !== undefined || fs.existsSync(path.join(root, "partitions/manifest.json"))) {
    try {
      if (beforeOnly || manifest.execution?.protocol !== "serial-two-group-v1" || manifest.execution?.path !== "partitions/manifest.json") throw new Error("serial partition declaration is missing or invalid");
      const partManifest = readJsonArtifact(root, "partitions/manifest.json", reasons);
      execution = validateFullPartitionEvidence(root, partManifest, inventory, report, checkoutHead,
        [images.application?.runtime_id, images.standalone_ops?.runtime_id, images.browser?.runtime_id], lifecycle.run_id);
    } catch (error) { reasons.push(errorReason("invalid_serial_partition_evidence", error.message)); }
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
    product_source_sha: productSourceSha,
    dirty: typeof dirty === "boolean" ? dirty : null,
    event_sha: eventSha,
    built_source_sha: builtSourceSha,
    dirty_fingerprint: typeof sourceInput.dirty_fingerprint === "string" ? sourceInput.dirty_fingerprint : null,
    ...(beforeOnly ? { qualification_sha256: qualificationSha256 } : {})
  };
  const compose = { scope: composeScope, project: composeProject, targets: [...new Set(targets)].sort(), model_digest: modelDigest };
  const browser = isRecord(actualBrowserRecipe)
    ? { engine: actualBrowserRecipe.engine, version: actualBrowserRecipe.version, package: actualBrowserRecipe.package, package_version: actualBrowserRecipe.package_version }
    : { engine: browserEngine, version: browserVersion, package: packageName, package_version: packageVersion };
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
    scope,
    source,
    images,
    compose,
    browser,
    workflow,
    stages,
    ...(execution ? { execution } : {}),
    checkers,
    cases: reconciliation.cases,
    preservation: {
      schema: beforeOnly ? "scrypath.ui-preservation-before-only.v2" : "scrypath.ui-preservation.v2",
      product_source_sha: productSourceSha,
      build_source_sha: checkoutHead,
      product_tree_sha256: productTreeSha256,
      fixture_overlay_sha256: fixtureOverlaySha256,
      raw_bundle: preservationBundle.metadata,
      cases: preservationCases
    },
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
    light_parity_conclusion: stages.light_parity?.exit_code === 0 ? "success" : beforeOnly ? "not-run" : "failure",
    contrast_conclusion: stages.contrast?.exit_code === 0 ? "success" : beforeOnly ? "not-run" : "failure",
    light_parity_status: checkers.light_parity?.status ?? "not-run",
    light_parity_width_mismatches: checkers.light_parity?.width_mismatches ?? null,
    light_parity_missing: checkers.light_parity?.missing ?? null,
    light_parity_extra: checkers.light_parity?.extra ?? null,
    shell_wash_conclusion: shellWash.length === 0 ? "missing" : shellWash.every((item) => item.attempts.every((attempt) => attempt.status === "passed")) ? "success" : "failure",
    shell_wash_specs_total: shellWash.length,
    shell_wash_failed_specs: shellWash.filter((item) => item.attempts.some((attempt) => attempt.status !== "passed")).map((item) => item.title_path.join(" › ")),
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
    ...(isLegacyJudgeReceipt(receipt) ? [
    `- visual_judge_status: ${receipt.visual_judge_status}`,
    `- visual_judge_claims: ${receipt.visual_judge_claims ?? "unknown"}`,
    `- visual_judge_required: ${receipt.visual_judge_required}`
    ] : []),
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
    ...(isLegacyJudgeReceipt(receipt) ? [
    "",
    "## Advisory Visual Judge",
    "",
    `- status: ${receipt.visual_judge_status}`,
    "- findings: not required",
    `- claims: ${receipt.visual_judge_claims ?? "not required"}`,
    `- required: ${receipt.visual_judge_required}`,
    `- skipped_reason: ${receipt.visual_judge_skipped_reason}`
    ] : [])
  ];
  return `${lines.join("\n")}\n`;
}

// Only the exact previously valid retired-field shape is accepted. Unknown
// fields and synthetic approvals still fail the aggregate equality check.
const LEGACY_JUDGE_FIELDS = Object.freeze({
    visual_judge_status: "not-required",
    visual_judge_findings: null,
    visual_judge_claims: null,
    visual_judge_required: false,
    visual_judge_skipped_reason: "The paid judge is outside browser eligibility.",
});
function isLegacyJudgeReceipt(receipt) {
  return Object.entries(LEGACY_JUDGE_FIELDS).every(([key, value]) => Object.hasOwn(receipt, key) && receipt[key] === value);
}
function withoutLegacyJudgeFields(receipt) {
  if (!isLegacyJudgeReceipt(receipt)) return receipt;
  return Object.fromEntries(Object.entries(receipt).filter(([key]) => !Object.hasOwn(LEGACY_JUDGE_FIELDS, key)));
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

function writeEvidence({ runDir, now, expectedSource = null, repoRoot = REPOSITORY_ROOT, verifyGitObjects = true } = {}) {
  const root = resolveRunRoot(runDir);
  const generatedAt = now instanceof Date ? now.toISOString() : typeof now === "string" ? now : new Date().toISOString();
  const receipt = buildReceipt(root, { generatedAt, expectedSource, repoRoot, verifyGitObjects });
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

function beforeOnlySourceFromEnvironment(environment = process.env) {
  const expectedSource = {
    sourceSha: environment.E2E_PRODUCT_SOURCE_SHA,
    buildSourceSha: environment.SCRYPATH_SOURCE_SHA,
    productTreeSha256: environment.E2E_PRODUCT_TREE_SHA256,
    fixtureOverlaySha256: environment.E2E_FIXTURE_OVERLAY_SHA256,
    qualificationSha256: environment.E2E_PHASE185_QUALIFICATION_SHA256
  };
  if (!validSha(expectedSource.sourceSha) || !validSha(expectedSource.buildSourceSha) ||
    !validDigest(expectedSource.productTreeSha256) || !validDigest(expectedSource.fixtureOverlaySha256) || !validDigest(expectedSource.qualificationSha256)) {
    throw new TypeError("before-only collection requires independently pinned product/build Git OIDs and product/fixture tree digests");
  }
  return expectedSource;
}

function buildBeforeOnlyReceipt({ runDir, expectedSource, repoRoot = REPOSITORY_ROOT, generatedAt = new Date().toISOString(), verifyGitObjects = true } = {}) {
  const pinned = expectedSource || beforeOnlySourceFromEnvironment();
  return buildReceipt(runDir, { generatedAt, expectedSource: pinned, scope: "before-only", repoRoot, verifyGitObjects });
}

function writeBeforeOnlyEvidence({ runDir, expectedSource, repoRoot = REPOSITORY_ROOT, now } = {}) {
  const root = resolveRunRoot(runDir);
  if (fs.existsSync(path.join(root, RECEIPT_NAME)) || fs.existsSync(path.join(root, SUMMARY_NAME)) || fs.existsSync(path.join(root, BEFORE_ONLY_RECEIPT_NAME))) {
    throw new Error("before-only collection requires a fresh run directory and cannot reuse a full receipt");
  }
  const generatedAt = now instanceof Date ? now.toISOString() : typeof now === "string" ? now : new Date().toISOString();
  const receipt = buildBeforeOnlyReceipt({ runDir: root, expectedSource, repoRoot, generatedAt, verifyGitObjects: false });
  writeAtomic(root, BEFORE_ONLY_RECEIPT_NAME, `${JSON.stringify(receipt, null, 2)}\n`);
  return receipt;
}

function validateBeforeOnlyReceipt({ runDir, expectedSource, repoRoot = REPOSITORY_ROOT } = {}) {
  let root;
  let receipt;
  try {
    root = resolveRunRoot(runDir);
    const receiptFile = resolveArtifact(root, BEFORE_ONLY_RECEIPT_NAME, { allowOutputs: true });
    if (receiptFile.stat.size > MAX_JSON_BYTES) throw new RangeError("before-only receipt exceeds the parsing size limit");
    receipt = JSON.parse(fs.readFileSync(receiptFile.path, "utf8"));
    if (!isRecord(receipt) || receipt.scope !== "before-only" || receipt.preservation?.schema !== "scrypath.ui-preservation-before-only.v2" || typeof receipt.generated_at_utc !== "string") {
      throw new TypeError("before-only receipt schema is invalid or belongs to the full-run scope");
    }
  } catch (error) {
    return { valid: false, eligible: false, reasons: [errorReason("invalid_before_only_receipt", error.message)] };
  }
  let recomputed;
  try {
    recomputed = buildBeforeOnlyReceipt({ runDir: root, expectedSource: expectedSource || beforeOnlySourceFromEnvironment(), repoRoot, generatedAt: receipt.generated_at_utc, verifyGitObjects: true });
  } catch (error) {
    return { valid: false, eligible: false, reasons: [errorReason("before_only_receipt_recompute_failed", error.message)] };
  }
  const sameAggregate = JSON.stringify(canonicalize(receipt)) === JSON.stringify(canonicalize(recomputed));
  const valid = sameAggregate;
  const eligible = valid && receipt.eligibility?.eligible === true;
  const reasons = [];
  if (!sameAggregate) reasons.push(errorReason("before_only_receipt_mismatch", "Stored before-only receipt does not match its scoped inputs, source objects and artifacts"));
  if (receipt.eligibility?.eligible !== true) reasons.push(...(Array.isArray(receipt.reasons) ? receipt.reasons : [errorReason("ineligible_before_only_receipt", "Stored before-only receipt is not eligible")]));
  return { valid, eligible, reasons: normalizeReasons(reasons), receipt };
}

function validateReceipt({ runDir, expectedSource = null, repoRoot = REPOSITORY_ROOT, verifyGitObjects = true } = {}) {
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
    if (receipt.scope !== "full" || receipt.preservation?.schema !== "scrypath.ui-preservation.v2") throw new TypeError("stored receipt is not a canonical full-run receipt");
    recomputed = buildReceipt(root, { generatedAt: receipt.generated_at_utc, expectedSource, repoRoot, verifyGitObjects });
  } catch (error) {
    return { valid: false, eligible: false, reasons: [errorReason("receipt_recompute_failed", error.message)] };
  }
  const sameAggregate = JSON.stringify(canonicalize(withoutLegacyJudgeFields(receipt))) === JSON.stringify(canonicalize(recomputed));
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
  return reconcileInventory({ inventory, report, repoRoot: REPOSITORY_ROOT, requireMandatoryCases: true });
}

function main(argv = process.argv.slice(2)) {
  const [command] = argv;
  const runDir = parseRunDir(argv);
  if (command === "partition-files") {
    const group = argv[argv.indexOf("--group") + 1];
    const file = path.join(runDir, INVENTORY_NAME);
    if (fs.lstatSync(file).size > MAX_JSON_BYTES) throw new Error("partition inventory is too large");
    const files = partitionInventory(readJson(file), group).files;
    for (const file of files) {
      if (!/^examples\/scrypath_ecommerce\/e2e\/[A-Za-z0-9_./-]+\.spec\.ts$/.test(file)) throw new Error("unsupported test source path in partition inventory");
      process.stdout.write(`^${path.resolve(REPOSITORY_ROOT, file).replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$\n`);
    }
    return 0;
  }
  if (command === "partition-run") return runFullPartition(runDir, argv[argv.indexOf("--group") + 1]);
  if (command === "assemble-partitions") { assembleFullPartitions(runDir); return finishPartitionChecks(runDir); }
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
  if (command === "write-before-only") {
    const receipt = writeBeforeOnlyEvidence({ runDir, expectedSource: beforeOnlySourceFromEnvironment() });
    process.stdout.write(`${JSON.stringify({ scope: receipt.scope, eligibility: receipt.eligibility, reasons: receipt.reasons, files: [BEFORE_ONLY_RECEIPT_NAME] }, null, 2)}\n`);
    return receipt.eligibility.eligible ? 0 : 1;
  }
  if (command === "validate-receipt") {
    const result = validateReceipt({ runDir });
    process.stdout.write(`${JSON.stringify({ valid: result.valid, eligible: result.eligible, reasons: result.reasons }, null, 2)}\n`);
    return result.valid && result.eligible ? 0 : 1;
  }
  if (command === "validate-before-only-receipt") {
    const result = validateBeforeOnlyReceipt({ runDir, expectedSource: beforeOnlySourceFromEnvironment() });
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
  assembleFullPartitions,
  partitionInventory,
  auditPartitionReports,
  validateFullPartitionEvidence,
  parsePhase185ClockFixture,
  caseIdentity,
  isAllowedArtifactPath,
  reconcileInventory,
  preservationCases: PRESERVATION_CASES,
  fixtureOverlayDigest,
  productTreeIdentity,
  productSourceRoots: PRODUCT_SOURCE_ROOTS,
  preservationFixtureFiles: PRESERVATION_FIXTURE_FILES,
  validateSourceOverlay,
  validateBeforeQualification,
  runReconcile,
  renderSummary,
  writeEvidence,
  writeBeforeOnlyEvidence,
  validateReceipt,
  validateBeforeOnlyReceipt
};
