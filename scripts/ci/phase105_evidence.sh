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

const runId = process.env.GITHUB_RUN_ID || "unknown";
const runAttempt = Number(process.env.GITHUB_RUN_ATTEMPT || "0");
const sha = process.env.GITHUB_SHA || "unknown";
const eventName = process.env.GITHUB_EVENT_NAME || "unknown";
const startedAt = process.env.PHASE105_E2E_STARTED_AT || "";
const endedAt = process.env.PHASE105_E2E_ENDED_AT || "";
const conclusion = process.env.PHASE105_E2E_CONCLUSION || "unknown";

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

  const specOutcomes = extractSpecs(report).flatMap((spec) => spec.tests || []).flatMap((test) => test.results || []);
  if (specOutcomes.some((result) => isFailedOutcome(result.status))) return "playwright_assertion";
  return "unknown";
}

let report = null;
if (fs.existsSync(playwrightJsonPath)) {
  try {
    report = JSON.parse(fs.readFileSync(playwrightJsonPath, "utf8"));
  } catch {
    report = null;
  }
}

const events = readNdjson(evidenceNdjsonPath);
const specs = report ? extractSpecs(report) : [];
const testResults = specs.flatMap((spec) => spec.tests || []);
const allResultAttempts = testResults.flatMap((test) => test.results || []);
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
    : summary.failed_specs.map((title) => `- ${title}`))
];

fs.writeFileSync(evidenceJsonPath, JSON.stringify(summary, null, 2));
fs.writeFileSync(evidenceSummaryPath, `${lines.join("\n")}\n`);
NODE

echo "Wrote ${EVIDENCE_JSON} and ${EVIDENCE_SUMMARY_MD}"
