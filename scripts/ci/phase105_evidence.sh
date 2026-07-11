#!/usr/bin/env bash

set -euo pipefail

RESULTS_DIR="examples/scrypath_ecommerce/test-results"
PLAYWRIGHT_JSON="${RESULTS_DIR}/phase105-playwright.json"
EVIDENCE_NDJSON="${PHASE105_EVIDENCE_PATH:-${RESULTS_DIR}/phase105-evidence.ndjson}"
EVIDENCE_JSON="${RESULTS_DIR}/phase105-evidence.json"
EVIDENCE_SUMMARY_MD="${RESULTS_DIR}/phase105-evidence-summary.md"

mkdir -p "${RESULTS_DIR}"
touch "${EVIDENCE_NDJSON}"

node <<'NODE'
const fs = require("fs");

const resultsDir = "examples/scrypath_ecommerce/test-results";
const playwrightJsonPath = `${resultsDir}/phase105-playwright.json`;
const evidenceNdjsonPath = process.env.PHASE105_EVIDENCE_PATH || `${resultsDir}/phase105-evidence.ndjson`;
const evidenceJsonPath = `${resultsDir}/phase105-evidence.json`;
const evidenceSummaryPath = `${resultsDir}/phase105-evidence-summary.md`;
const lightParityPath = `${resultsDir}/admin-light-parity.json`;
const visualJudgePath = `${resultsDir}/ops-ui-visual-judge.json`;

const runId = process.env.GITHUB_RUN_ID || "unknown";
const runAttempt = Number(process.env.GITHUB_RUN_ATTEMPT || "0");
const sha = process.env.GITHUB_SHA || "unknown";
const eventName = process.env.GITHUB_EVENT_NAME || "unknown";
const startedAt = process.env.PHASE105_E2E_STARTED_AT || "";
const endedAt = process.env.PHASE105_E2E_ENDED_AT || "";
const conclusion = process.env.PHASE105_E2E_CONCLUSION || "unknown";
const browserConclusion = process.env.PHASE105_BROWSER_CONCLUSION || "unknown";
const lightParityConclusion = process.env.PHASE105_LIGHT_PARITY_CONCLUSION || "unknown";
const contrastConclusion = process.env.PHASE105_CONTRAST_CONCLUSION || "unknown";

function parseEpochSeconds(iso) {
  if (!iso) return null;
  const ms = Date.parse(iso);
  if (Number.isNaN(ms)) return null;
  return Math.floor(ms / 1000);
}

const startSec = parseEpochSeconds(startedAt);
const endSec = parseEpochSeconds(endedAt);
const runtimeSeconds = startSec != null && endSec != null && endSec >= startSec ? endSec - startSec : null;

function readNdjson(path) {
  try {
    const raw = fs.readFileSync(path, "utf8");
    return raw
      .split("\n")
      .map((line) => line.trim())
      .filter((line) => line.length > 0)
      .map((line) => JSON.parse(line));
  } catch {
    return [];
  }
}

function readJson(path) {
  try {
    return JSON.parse(fs.readFileSync(path, "utf8"));
  } catch {
    return null;
  }
}

function flattenSpecs(suites, acc) {
  for (const suite of suites || []) {
    for (const spec of suite.specs || []) {
      acc.push(spec);
    }
    flattenSpecs(suite.suites || [], acc);
  }
}

function extractSpecs(report) {
  const specs = [];
  for (const suite of report?.suites || []) {
    flattenSpecs([suite], specs);
  }
  return specs;
}

function isFailedOutcome(status) {
  return status === "failed" || status === "timedOut" || status === "interrupted";
}

function classifyFailure(events, report) {
  if (browserConclusion === "success" && lightParityConclusion === "failure") return "light_parity";
  if (browserConclusion === "success" && contrastConclusion === "failure") return "token_contrast";
  if (events.length === 0) return "infra_boot";

  const evOps = new Set(events.map((ev) => ev.operation));
  const hadSeed = evOps.has("seed");
  const hadDrain = evOps.has("drain");
  const hadSearchVisible = evOps.has("search_visible");
  const hadOperatorState = evOps.has("operator_state") || evOps.has("swap_outcome");

  if (!hadSeed) return "fixture_seed";
  if (!hadDrain) return "queue_drain";
  if (!hadSearchVisible) return "search_visibility";
  if (!hadOperatorState) return "operator_state";

  const failedSpecTitles = extractSpecs(report)
    .filter((spec) =>
      (spec.tests || []).some((test) =>
        (test.results || []).some((result) => isFailedOutcome(result.status))
      )
    )
    .map((spec) => spec.title);
  if (failedSpecTitles.some((title) => title.includes("[shell-wash]"))) return "shell_wash_visual";

  const specOutcomes = extractSpecs(report).flatMap((spec) => spec.tests || []).flatMap((test) => test.results || []);
  if (specOutcomes.some((result) => isFailedOutcome(result.status))) return "playwright_assertion";
  return "unknown";
}

let report = null;
report = readJson(playwrightJsonPath);

const lightParity = readJson(lightParityPath);
const visualJudge = readJson(visualJudgePath);

const events = readNdjson(evidenceNdjsonPath);
const specs = report ? extractSpecs(report) : [];
const testResults = specs.flatMap((spec) => spec.tests || []);
const allResultAttempts = testResults.flatMap((test) => test.results || []);
const shellWashSpecs = specs.filter((spec) => spec.title.includes("[shell-wash]"));
const shellWashFailedSpecs = shellWashSpecs
  .filter((spec) =>
    (spec.tests || []).some((test) =>
      (test.results || []).some((result) => isFailedOutcome(result.status))
    )
  )
  .map((spec) => spec.title);
const failedSpecs = specs
  .filter((spec) =>
    (spec.tests || []).some((test) =>
      (test.results || []).some((result) => isFailedOutcome(result.status))
    )
  )
  .map((spec) => spec.title);
const operationCounts = events.reduce((acc, event) => {
  const operation = event.operation || "unknown";
  acc[operation] = (acc[operation] || 0) + 1;
  return acc;
}, {});

const flakySignal = testResults.some((test) =>
  (test.results || []).some((result) => result.retry > 0 && result.status === "passed")
);

const summary = {
  run_id: runId,
  run_attempt: runAttempt,
  sha,
  event: eventName,
  job_name: "phase105-e2e",
  conclusion,
  browser_conclusion: browserConclusion,
  light_parity_conclusion: lightParityConclusion,
  contrast_conclusion: contrastConclusion,
  light_parity_status: lightParity?.status || "unknown",
  light_parity_width_mismatches: lightParity?.width_mismatches?.length ?? null,
  light_parity_missing: lightParity?.missing?.length ?? null,
  light_parity_extra: lightParity?.extra?.length ?? null,
  shell_wash_conclusion:
    shellWashSpecs.length === 0 ? "missing" : shellWashFailedSpecs.length === 0 ? "success" : "failure",
  shell_wash_specs_total: shellWashSpecs.length,
  shell_wash_failed_specs: shellWashFailedSpecs,
  visual_judge_status: visualJudge?.status || "unknown",
  visual_judge_findings: visualJudge?.findings?.length ?? null,
  visual_judge_claims: visualJudge?.claim_verdicts?.length ?? null,
  visual_judge_required: visualJudge?.required === true,
  visual_judge_skipped_reason: visualJudge?.skipped_reason || null,
  runtime_seconds: runtimeSeconds,
  flaky_signal: flakySignal,
  failure_classification: conclusion === "success" ? null : classifyFailure(events, report),
  specs_total: specs.length,
  tests_total: testResults.length,
  attempts_total: allResultAttempts.length,
  failed_specs: failedSpecs,
  operation_counts: operationCounts,
  evidence_events_count: events.length,
  generated_at_utc: new Date().toISOString()
};

const lines = [
  "# Phase 105 E2E Evidence Summary",
  "",
  `- run_id: ${summary.run_id}`,
  `- run_attempt: ${summary.run_attempt}`,
  `- sha: ${summary.sha}`,
  `- event: ${summary.event}`,
  `- job_name: ${summary.job_name}`,
  `- conclusion: ${summary.conclusion}`,
  `- browser_conclusion: ${summary.browser_conclusion}`,
  `- light_parity_conclusion: ${summary.light_parity_conclusion}`,
  `- contrast_conclusion: ${summary.contrast_conclusion}`,
  `- light_parity_status: ${summary.light_parity_status}`,
  `- shell_wash_conclusion: ${summary.shell_wash_conclusion}`,
  `- shell_wash_specs_total: ${summary.shell_wash_specs_total}`,
  `- visual_judge_status: ${summary.visual_judge_status}`,
  `- visual_judge_claims: ${summary.visual_judge_claims ?? "unknown"}`,
  `- visual_judge_required: ${summary.visual_judge_required}`,
  `- runtime_seconds: ${summary.runtime_seconds ?? "unknown"}`,
  `- flaky_signal: ${summary.flaky_signal}`,
  `- failure_classification: ${summary.failure_classification ?? "none"}`,
  `- specs_total: ${summary.specs_total}`,
  `- tests_total: ${summary.tests_total}`,
  `- attempts_total: ${summary.attempts_total}`,
  `- evidence_events_count: ${summary.evidence_events_count}`,
  `- generated_at_utc: ${summary.generated_at_utc}`,
  "",
  "## Operation Counts",
  "",
  ...Object.entries(summary.operation_counts)
    .sort(([left], [right]) => left.localeCompare(right))
    .map(([operation, count]) => `- ${operation}: ${count}`),
  "",
  "## Failed Specs",
  "",
  ...(summary.failed_specs.length === 0
    ? ["- none"]
    : summary.failed_specs.map((title) => `- ${title}`)),
  "",
  "## Light Parity",
  "",
  `- status: ${summary.light_parity_status}`,
  `- missing: ${summary.light_parity_missing ?? "unknown"}`,
  `- width_mismatches: ${summary.light_parity_width_mismatches ?? "unknown"}`,
  `- extra: ${summary.light_parity_extra ?? "unknown"}`,
  "",
  "## Shell Wash",
  "",
  `- conclusion: ${summary.shell_wash_conclusion}`,
  `- specs_total: ${summary.shell_wash_specs_total}`,
  ...(summary.shell_wash_failed_specs.length === 0
    ? ["- failed_specs: none"]
    : summary.shell_wash_failed_specs.map((title) => `- failed_spec: ${title}`)),
  "",
  "## Advisory Visual Judge",
  "",
  `- status: ${summary.visual_judge_status}`,
  `- findings: ${summary.visual_judge_findings ?? "unknown"}`,
  `- claims: ${summary.visual_judge_claims ?? "unknown"}`,
  `- required: ${summary.visual_judge_required}`,
  `- skipped_reason: ${summary.visual_judge_skipped_reason ?? "none"}`
];

fs.writeFileSync(evidenceJsonPath, JSON.stringify(summary, null, 2));
fs.writeFileSync(evidenceSummaryPath, `${lines.join("\n")}\n`);
NODE

echo "Wrote ${EVIDENCE_JSON} and ${EVIDENCE_SUMMARY_MD}"
