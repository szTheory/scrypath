#!/usr/bin/env node

"use strict";

const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const crypto = require("node:crypto");

const GH = process.env.GH_BIN || "gh";
const GIT = process.env.GIT_BIN || "git";
const REQUIRED_CHECKS = [
  "core (required)",
  "package (required)",
  "repository-contracts (required)",
  "backend (required)",
  "ecommerce-mounted (required)",
];
const READINESS_JOBS = [...REQUIRED_CHECKS, "coverage (advisory)", "closeout-attestation"];
const MAX_ATTESTATION_ARCHIVE_BYTES = 8 * 1024 * 1024;
const MAX_ATTESTATION_MEMBER_BYTES = 1024 * 1024;
const CONDITION_TEXTS = [
  "Every baseline dimension above has been assessed; evidence coverage and known limits are visible.",
  "Every critical, high, or medium-leverage finding is closed with verification or explicitly accepted with rationale and an owner decision. There are no unresolved findings at those levels.",
  "Important adopter workflows have appropriate automated proof for the claims being made. The goal is zero routine human verification/UAT; external credentials, permissions, product decisions, or physical-world checks are the only expected handoffs.",
  "Required CI remains green and lean. Recurring service/E2E proof runs in CI only where its repeat confidence justifies its runtime and maintenance cost; more expensive lower-frequency evidence may remain advisory or scheduled.",
  "Remaining non-UI opportunities are low-leverage, speculative, unsupported, or more costly than their likely benefit, each with a recorded disposition.",
  "Release, package, support, and planning truth are current, with no task-owned cleanup or verification debt hidden at closeout.",
];
const BASELINE_DIMENSIONS = [
  "Public API consistency, ergonomics, compatibility, and error behavior",
  "Core indexing and search correctness, including writes/deletes, inline/manual/Oban synchronization, related data, tenancy, search, facets, federation, settings, and recovery",
  "Ecto, Oban, Meilisearch, Phoenix, and packaged-consumer seams, including representative supported version/runtime combinations",
  "Operational honesty, observability, backfill/reindex safety, failure reporting, and supportability",
  "First-hour and ongoing developer experience, documentation, examples, diagnostics, and adopter issue intake",
  "Security, privacy, dependency health, configuration boundaries, and release/supply-chain integrity",
  "Architecture, readability, maintainability, measured performance, and test/CI signal-to-cost",
];
const BASELINE_CLAIM_DIMENSIONS = {
  "C-02": 1, "C-22": 1,
  "C-03": 2, "C-07": 2, "C-08": 2, "C-09": 2, "C-04": 2, "C-11": 2,
  "C-01": 3, "C-12": 3, "C-10": 3, "C-18": 3,
  "C-13": 4, "C-14": 4, "C-15": 4, "C-16": 4, "C-17": 4,
  "C-05": 5, "C-06": 5, "C-19": 5,
  "C-21": 6, "C-20": 6,
  "C-23": 7, "C-24": 7,
};
const REQUIRED_ASSUMPTIONS = Array.from({ length: 7 }, (_, index) => `EA-167-${String(index + 1).padStart(2, "0")}`);
const BASELINE_PATH = ".planning/milestones/v1.39-phases/162-whole-product-evidence-baseline/162-BASELINE.md";
const AUTHORITY_PATH = ".planning/reference/PRE-OPERATOR-UI-READINESS.md";
const HISTORICAL_ARCHIVE_PATH = ".planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation";

function fail(message) {
  process.stderr.write(`ERROR: ${message}\n`);
  process.exit(1);
}

function run(bin, args, options = {}) {
  const result = spawnSync(bin, args, {
    cwd: options.cwd || process.cwd(),
    encoding: options.encoding === null ? null : "utf8",
    env: process.env,
    input: options.input,
    maxBuffer: options.maxBuffer || 20 * 1024 * 1024,
  });

  if (result.error) {
    if (result.error.code === "ENOBUFS") {
      throw new Error(`${bin} output exceeded the configured safe limit (${options.maxBuffer || 20 * 1024 * 1024} bytes)`);
    }
    throw new Error(`${bin} could not start: ${result.error.message}`);
  }

  if (result.status !== 0 && !options.allowFailure) {
    const rawDetail = result.stderr || result.stdout || "";
    const detail = (Buffer.isBuffer(rawDetail) ? rawDetail.toString("utf8") : rawDetail).trim();
    throw new Error(`${bin} ${args.join(" ")} failed (${result.status})${detail ? `: ${detail}` : ""}`);
  }

  return result;
}

function output(bin, args) {
  return run(bin, args).stdout.trim();
}

function json(bin, args) {
  const text = output(bin, args);
  try {
    return JSON.parse(text || "null");
  } catch (error) {
    throw new Error(`${bin} ${args.join(" ")} returned invalid JSON: ${error.message}`);
  }
}

function jsonValue(bin, args) {
  const text = output(bin, args);
  try {
    assertNoDuplicateJsonKeys(text);
    return JSON.parse(text || "null");
  } catch (error) {
    throw new Error(`${bin} ${args.join(" ")} returned invalid JSON: ${error.message}`);
  }
}

function positiveInteger(value, label) {
  const text = String(value ?? "");
  if (!/^[1-9][0-9]*$/.test(text) || !Number.isSafeInteger(Number(text))) {
    throw new Error(`${label} must be a positive safe integer`);
  }
  return Number(text);
}

function normalizeId(value, label) {
  return String(positiveInteger(value, label));
}

function flattenPages(payload, key, label) {
  const pages = Array.isArray(payload) ? payload : [payload];
  const results = [];
  for (const page of pages) {
    if (!page || !Array.isArray(page[key])) {
      throw new Error(`${label} pagination returned malformed JSON`);
    }
    results.push(...page[key]);
  }
  return results;
}

function flattenArrayPages(payload, label) {
  const pages = Array.isArray(payload) ? payload : [payload];
  const values = [];
  for (const page of pages) {
    if (Array.isArray(page)) values.push(...page);
    else if (page && Array.isArray(page.comments)) values.push(...page.comments);
    else throw new Error(`${label} pagination returned malformed JSON`);
  }
  return values;
}

function apiJson(endpoint, { paginate = false } = {}) {
  const args = ["api"];
  if (paginate) args.push("--paginate", "--slurp");
  args.push(endpoint);
  return jsonValue(GH, args);
}

function requireExternalOutput(outputPath) {
  if (!outputPath || typeof outputPath !== "string") {
    throw new Error("--output must name a receipt file outside the source checkout");
  }
  const absolute = path.resolve(outputPath);
  let ancestor = absolute;
  const suffix = [];
  while (!fs.existsSync(ancestor)) {
    suffix.unshift(path.basename(ancestor));
    ancestor = path.dirname(ancestor);
  }
  const resolved = path.join(fs.realpathSync(ancestor), ...suffix);
  const checkout = fs.realpathSync(process.cwd());
  if (resolved === checkout || resolved.startsWith(`${checkout}${path.sep}`)) {
    throw new Error("--output must be outside the source checkout");
  }
  return resolved;
}

function requireArtifact(artifacts, name, repo, sha, runId) {
  const matchingName = artifacts.filter((artifact) => artifact.name === name);
  const live = matchingName.filter((artifact) => artifact.expired === false);
  if (live.length !== 1 || matchingName.length !== 1) {
    throw new Error(`expected exactly one live ${name} artifact for the selected run, found ${live.length}`);
  }
  const artifact = live[0];
  if (!artifact.digest || !/^sha256:[0-9a-f]{64}$/.test(artifact.digest)) {
    throw new Error(`${name} is missing a valid SHA-256 archive digest`);
  }
  if (!artifact.id || artifact.workflow_run?.head_sha !== sha ||
      normalizeId(artifact.workflow_run?.id, `${name} workflow run id`) !== runId) {
    throw new Error(`${name} is not bound to repository ${repo}, run ${runId}, and source SHA ${sha}`);
  }
  return artifact;
}

function requireSuccessfulAttemptJobs(jobs) {
  const selected = [];
  for (const name of READINESS_JOBS) {
    const matches = jobs.filter((job) => job.name === name);
    if (matches.length !== 1 || matches[0].conclusion !== "success" || matches[0].status !== "completed") {
      throw new Error(`${name} must have exactly one successful job in the selected attempt`);
    }
    selected.push({
      id: normalizeId(matches[0].id, `${name} job id`),
      name,
      status: matches[0].status,
      conclusion: matches[0].conclusion,
      ...(matches[0].html_url ? { url: matches[0].html_url } : {}),
    });
  }
  return selected;
}

function requireAttestation(attestation, expected) {
  if (!attestation || typeof attestation !== "object" || Array.isArray(attestation)) {
    throw new Error("closeout attestation member must contain a JSON object");
  }
  const fields = [
    ["schema", 1],
    ["authority", "github-actions-exact-sha"],
    ["repository", expected.repo],
    ["run_id", expected.runId],
    ["run_attempt", String(expected.attempt)],
    ["event", "workflow_dispatch"],
    ["head_sha", expected.sha],
  ];
  for (const [field, wanted] of fields) {
    if (String(attestation[field]) !== String(wanted)) {
      throw new Error(`closeout attestation ${field} does not match the requested source/run/attempt`);
    }
  }
  if (!Array.isArray(attestation.required_jobs) ||
      JSON.stringify(attestation.required_jobs) !== JSON.stringify(REQUIRED_CHECKS)) {
    throw new Error("closeout attestation required_jobs does not match the required workflow jobs");
  }
  if (!attestation.coverage || attestation.coverage.outcome !== "success") {
    throw new Error("closeout attestation coverage outcome must be success");
  }
  return attestation;
}

function downloadArchive(repo, artifactId, destination) {
  const bytes = run(GH, ["api", `repos/${repo}/actions/artifacts/${artifactId}/zip`], {
    encoding: null,
    maxBuffer: MAX_ATTESTATION_ARCHIVE_BYTES + 1,
  }).stdout;
  if (!Buffer.isBuffer(bytes) || bytes.length === 0 || bytes.length > MAX_ATTESTATION_ARCHIVE_BYTES) {
    throw new Error(`attestation archive is empty or exceeds ${MAX_ATTESTATION_ARCHIVE_BYTES} bytes`);
  }
  fs.writeFileSync(destination, bytes, { flag: "wx" });
  return bytes;
}

function readAttestationMember(archivePath) {
  const listing = run("unzip", ["-Z1", archivePath], { maxBuffer: MAX_ATTESTATION_MEMBER_BYTES }).stdout;
  const members = listing.split(/\r?\n/).filter(Boolean);
  if (members.length !== 1 || members[0] !== "closeout-attestation.json") {
    throw new Error("attestation archive must contain only one closeout-attestation.json member; traversal and duplicate entries are rejected");
  }
  const member = run("unzip", ["-p", archivePath, "closeout-attestation.json"], {
    encoding: null,
    maxBuffer: MAX_ATTESTATION_MEMBER_BYTES + 1,
  }).stdout;
  if (!Buffer.isBuffer(member) || member.length === 0 || member.length > MAX_ATTESTATION_MEMBER_BYTES) {
    throw new Error(`attestation JSON member is empty or exceeds ${MAX_ATTESTATION_MEMBER_BYTES} bytes`);
  }
  let content;
  try {
    assertNoDuplicateJsonKeys(member.toString("utf8"));
    content = JSON.parse(member.toString("utf8"));
  } catch (error) {
    throw new Error(`closeout attestation member is invalid JSON: ${error.message}`);
  }
  return {
    name: members[0],
    bytes: member,
    content,
  };
}

function collectReadiness(flags) {
  const repo = flags.repo;
  if (!repo || !/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repo)) {
    throw new Error("--repo must be an explicit OWNER/REPO value");
  }
  const sha = flags.sha;
  requireExactSha(sha);
  const runId = normalizeId(flags.run, "--run");
  const attempt = positiveInteger(flags.attempt, "--attempt");
  const outputPath = requireExternalOutput(flags.output);
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "scrypath-readiness-"));
  const archivePath = path.join(tempDir, "attestation.zip");

  try {
    const endpoint = `repos/${repo}/actions/runs/${runId}/attempts/${attempt}`;
    const runInfo = apiJson(endpoint);
    if (normalizeId(runInfo.id, "API run id") !== runId ||
        positiveInteger(runInfo.run_attempt, "API run attempt") !== attempt) {
      throw new Error("GitHub returned a different run or requested run attempt");
    }
    if (runInfo.head_sha !== sha) throw new Error(`requested source SHA ${sha} does not match run attempt source ${runInfo.head_sha}`);
    if (runInfo.event !== "workflow_dispatch" || runInfo.status !== "completed" || runInfo.conclusion !== "success") {
      throw new Error("selected workflow run attempt must be a successful completed workflow_dispatch");
    }
    if (runInfo.repository?.full_name !== repo || runInfo.head_repository?.full_name !== repo) {
      throw new Error(`selected run attempt is not owned by requested repository ${repo}`);
    }
    const expectedRunUrl = `https://github.com/${repo}/actions/runs/${runId}`;
    if (runInfo.html_url !== expectedRunUrl) {
      throw new Error("selected run attempt is missing the expected public GitHub run URL");
    }
    const workflowId = normalizeId(runInfo.workflow_id, "workflow id");
    const workflowInfo = apiJson(`repos/${repo}/actions/workflows/${workflowId}`);
    if (workflowInfo.path !== ".github/workflows/ci.yml" || !workflowInfo.name) {
      throw new Error("selected attempt does not belong to the CI workflow metadata");
    }

    const jobPages = apiJson(`repos/${repo}/actions/runs/${runId}/attempts/${attempt}/jobs?per_page=100`, { paginate: true });
    const jobs = requireSuccessfulAttemptJobs(flattenPages(jobPages, "jobs", "job"));
    const artifactPages = apiJson(`repos/${repo}/actions/runs/${runId}/artifacts?per_page=100`, { paginate: true });
    const artifacts = flattenPages(artifactPages, "artifacts", "artifact");
    const coverage = requireArtifact(artifacts, `coverage-report-${sha}`, repo, sha, runId);
    const attestationArtifact = requireArtifact(artifacts, `closeout-attestation-${sha}`, repo, sha, runId);
    const coverageId = normalizeId(coverage.id, "coverage artifact id");
    const archiveBytes = downloadArchive(repo, normalizeId(attestationArtifact.id, "attestation artifact id"), archivePath);
    const actualArchiveSha = crypto.createHash("sha256").update(archiveBytes).digest("hex");
    if (attestationArtifact.digest !== `sha256:${actualArchiveSha}`) {
      throw new Error("attestation archive digest does not match the GitHub artifact API digest");
    }
    const member = readAttestationMember(archivePath);
    const attestation = requireAttestation(member.content, { repo, runId, attempt, sha });
    if (normalizeId(attestation.coverage.artifact_id, "attested coverage artifact id") !== coverageId ||
        attestation.coverage.artifact_digest !== coverage.digest ||
        attestation.coverage.artifact_url !== coverage.url) {
      throw new Error("closeout attestation coverage artifact identity/digest does not match GitHub artifact metadata");
    }
    if (attestation.workflow !== workflowInfo.name || attestation.run_url !== runInfo.html_url) {
      throw new Error("closeout attestation workflow/run URL does not match API metadata");
    }

    const receipt = {
      schema: 1,
      authority: "github-actions-exact-sha",
      repository: repo,
      head_sha: sha,
      source: { head_sha: sha },
      workflow: { id: workflowId, name: workflowInfo.name, path: workflowInfo.path },
      run_id: runId,
      run_attempt: attempt,
      run_url: runInfo.html_url,
      event: runInfo.event,
      status: runInfo.status,
      conclusion: runInfo.conclusion,
      created_at: runInfo.created_at,
      updated_at: runInfo.updated_at,
      jobs,
      coverage_artifact: {
        id: coverageId,
        name: coverage.name,
        url: coverage.url,
        digest: coverage.digest,
        expires_at: coverage.expires_at,
      },
      attestation_artifact: {
        id: normalizeId(attestationArtifact.id, "attestation artifact id"),
        name: attestationArtifact.name,
        url: attestationArtifact.url,
        digest: attestationArtifact.digest,
        expires_at: attestationArtifact.expires_at,
      },
      attestation_archive: { sha256: actualArchiveSha },
      attestation_member: {
        name: member.name,
        sha256: crypto.createHash("sha256").update(member.bytes).digest("hex"),
        content: attestation,
      },
      collected_at_utc: new Date().toISOString(),
      limitations: [
        "This receipt joins GitHub run, attempt, job, artifact, archive, and attestation facts; it does not decide semantic readiness or maintainer approval.",
        "GitHub artifact availability and API facts can expire or change; retain this receipt with the dated assessment.",
      ],
    };
    fs.mkdirSync(path.dirname(outputPath), { recursive: true });
    fs.writeFileSync(outputPath, `${JSON.stringify(receipt, null, 2)}\n`, { flag: "wx" });
    process.stdout.write(`${JSON.stringify(receipt, null, 2)}\n`);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
}

function assertNoDuplicateJsonKeys(text) {
  const stack = [];
  for (let index = 0; index < text.length; index += 1) {
    const char = text[index];
    if (char === '"') {
      const start = index;
      index += 1;
      while (index < text.length) {
        if (text[index] === "\\") index += 2;
        else if (text[index] === '"') break;
        else index += 1;
      }
      if (index >= text.length) break;
      const token = text.slice(start, index + 1);
      let lookahead = index + 1;
      while (/\s/.test(text[lookahead] || " ")) lookahead += 1;
      if (stack.at(-1)?.kind === "object" && text[lookahead] === ":") {
        const key = JSON.parse(token);
        if (stack.at(-1).keys.has(key)) throw new Error(`duplicate JSON field ${JSON.stringify(key)}`);
        stack.at(-1).keys.add(key);
      }
      continue;
    }
    if (char === "{") stack.push({ kind: "object", keys: new Set() });
    else if (char === "[") stack.push({ kind: "array" });
    else if (char === "}" || char === "]") stack.pop();
  }
}

function readRecordFile(file, label) {
  let text;
  try {
    text = fs.readFileSync(file, "utf8");
    assertNoDuplicateJsonKeys(text);
    const value = JSON.parse(text);
    if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error(`${label} must be a JSON object`);
    return value;
  } catch (error) {
    throw new Error(`cannot read ${label}: ${error.message}`);
  }
}

function requireObject(value, label) {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error(`${label} must be an object`);
  return value;
}

function requireText(value, label) {
  if (typeof value !== "string" || !value.trim()) throw new Error(`${label} must be a non-empty string`);
  return value.trim();
}

function requireArray(value, label, { min = 1 } = {}) {
  if (!Array.isArray(value) || value.length < min) throw new Error(`${label} must be an array with at least ${min} item(s)`);
  return value;
}

function rejectUnknownKeys(value, allowed, label) {
  const extra = Object.keys(requireObject(value, label)).filter((key) => !allowed.includes(key));
  if (extra.length) throw new Error(`${label} contains unsupported field(s): ${extra.join(", ")}`);
}

function validIsoDate(value, label) {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value) || Number.isNaN(Date.parse(`${value}T00:00:00Z`))) {
    throw new Error(`${label} must be a valid YYYY-MM-DD date`);
  }
  return value;
}

function validUtcTimestamp(value, label) {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/.test(value) || Number.isNaN(Date.parse(value))) {
    throw new Error(`${label} must be a second-precision UTC timestamp ending in Z`);
  }
  return value;
}

function safeRelativePath(value, label) {
  const relative = requireText(value, label);
  if (path.isAbsolute(relative) || relative.split(/[\\/]/).includes("..") || relative.includes("\\")) {
    throw new Error(`${label} must be a repository-relative path`);
  }
  return relative;
}

function rejectPrivateAndSecretValues(value, pathLabel = "record") {
  if (Array.isArray(value)) {
    value.forEach((entry, index) => rejectPrivateAndSecretValues(entry, `${pathLabel}[${index}]`));
  } else if (value && typeof value === "object") {
    for (const [key, nested] of Object.entries(value)) {
      if (/(?:secret|token|authorization|environment_dump|env_dump)/i.test(key)) {
        throw new Error(`${pathLabel} contains forbidden field ${key}`);
      }
      rejectPrivateAndSecretValues(nested, `${pathLabel}.${key}`);
    }
  } else if (typeof value === "string" && /(?:^|\s|=)(?:\/Users\/|\/home\/|\/private\/tmp\/)/i.test(value)) {
    throw new Error(`${pathLabel} contains a private machine path`);
  }
}

function containedFile(sourceRoot, relative, label) {
  const root = fs.realpathSync(sourceRoot);
  const target = fs.realpathSync(path.join(root, safeRelativePath(relative, label)));
  if (target !== root && !target.startsWith(`${root}${path.sep}`)) throw new Error(`${label} escapes the source root`);
  if (!fs.statSync(target).isFile()) throw new Error(`${label} must name a file`);
  return target;
}

function evidenceReference(value, sourceRoot, label) {
  if (typeof value === "string") {
    if (value.startsWith("https://")) return evidenceReference({ url: value }, sourceRoot, label);
    const relative = safeRelativePath(value, label);
    containedFile(sourceRoot, relative, label);
    return relative;
  }
  const reference = requireObject(value, label);
  rejectUnknownKeys(reference, ["url", "path", "label"], label);
  if (reference.url !== undefined) {
    const urlText = requireText(reference.url, `${label}.url`);
    let parsed;
    try { parsed = new URL(urlText); } catch { throw new Error(`${label}.url must be a public HTTPS evidence URL`); }
    if (parsed.protocol !== "https:" || parsed.username || parsed.password ||
        !["github.com", "api.github.com", "docs.github.com", "hex.pm", "hexdocs.pm"].includes(parsed.hostname) ||
        parsed.pathname === "/") throw new Error(`${label}.url must use an approved public evidence host and non-empty path`);
    if (reference.path !== undefined) throw new Error(`${label} cannot contain both path and url`);
    if (reference.label !== undefined) requireText(reference.label, `${label}.label`);
    return urlText;
  }
  const relative = safeRelativePath(reference.path, `${label}.path`);
  containedFile(sourceRoot, relative, label);
  if (reference.label !== undefined) requireText(reference.label, `${label}.label`);
  return relative;
}

function markdownCell(value) {
  return String(value).replace(/\|/g, "\\|").replace(/[\r\n]+/g, " ");
}

function historicalScope(bytes, scope, heading, label) {
  if (scope === "whole_file") return bytes;
  if (scope !== "named_suffix") throw new Error(`${label} has unsupported historical scope`);
  const marker = Buffer.from(requireText(heading, `${label}.heading`));
  const first = bytes.indexOf(marker);
  if (first < 0 || bytes.indexOf(marker, first + marker.length) >= 0) throw new Error(`${label} historical heading is missing or duplicated`);
  return bytes.subarray(first);
}

function verifyPreservedHistory(record, sourceRoot) {
  const entries = requireArray(record.preserved_history, "preserved_history", { min: 3 });
  const seen = new Set();
  for (const [index, entryValue] of entries.entries()) {
    const entry = requireObject(entryValue, `preserved_history[${index}]`);
    const relative = safeRelativePath(entry.path, `preserved_history[${index}].path`);
    if (seen.has(relative)) throw new Error(`duplicate preserved_history path ${relative}`);
    seen.add(relative);
    const gitSource = requireText(entry.git_source, `preserved_history[${index}].git_source`);
    if (!/^[0-9a-f]{40}$/.test(gitSource)) throw new Error(`preserved_history[${index}].git_source must be a full Git SHA`);
    const currentPath = containedFile(sourceRoot, relative, `preserved_history[${index}].path`);
    run("git", ["-C", sourceRoot, "cat-file", "-e", `${gitSource}^{commit}`]);
    const original = run("git", ["-C", sourceRoot, "show", `${gitSource}:${relative}`], { encoding: null }).stdout;
    const current = fs.readFileSync(currentPath);
    const originalScope = historicalScope(original, entry.scope, entry.heading, `preserved_history[${index}]`);
    const currentScope = historicalScope(current, entry.scope, entry.heading, `preserved_history[${index}]`);
    const originalHash = crypto.createHash("sha256").update(originalScope).digest("hex");
    const currentHash = crypto.createHash("sha256").update(currentScope).digest("hex");
    if (!/^[0-9a-f]{64}$/.test(entry.sha256 || "") || entry.sha256 !== originalHash || currentHash !== originalHash) {
      throw new Error(`preserved historical bytes differ from Git source: ${relative}`);
    }
  }
  if (!seen.has(AUTHORITY_PATH) || !seen.has(BASELINE_PATH)) {
    throw new Error("preserved_history must pin the readiness authority and Phase 162 baseline bytes");
  }
  const archiveSource = entries.find((entry) => entry.path.startsWith(`${HISTORICAL_ARCHIVE_PATH}/`))?.git_source;
  if (!archiveSource) throw new Error("preserved_history must include every archived Phase 164 file");
  const tracked = run("git", ["-C", sourceRoot, "ls-tree", "-r", "--name-only", archiveSource, "--", HISTORICAL_ARCHIVE_PATH]).stdout
    .split(/\r?\n/).filter(Boolean).sort();
  const pinned = [...seen].filter((relative) => relative.startsWith(`${HISTORICAL_ARCHIVE_PATH}/`)).sort();
  if (!tracked.length || JSON.stringify(tracked) !== JSON.stringify(pinned)) {
    throw new Error("preserved_history does not pin the complete Phase 164 archived file set");
  }
}

function validatePinnedBaseline(record, sourceRoot) {
  const baselinePath = containedFile(sourceRoot, BASELINE_PATH, "Phase 162 baseline");
  const rows = fs.readFileSync(baselinePath, "utf8").split(/\r?\n/)
    .map((line) => /^\|\s*(C-[0-9]{2})\s*\|\s*([1-7])\s*\|/.exec(line))
    .filter(Boolean);
  const observed = Object.fromEntries(rows.map((match) => [match[1], Number(match[2])]));
  const expectedIds = Object.keys(BASELINE_CLAIM_DIMENSIONS).sort();
  if (rows.length !== 24 || Object.keys(observed).length !== 24 ||
      expectedIds.some((id) => observed[id] !== BASELINE_CLAIM_DIMENSIONS[id])) {
    throw new Error("Phase 162 baseline must contain the approved 24 unique C-ID/dimension pairs");
  }
  const baseline = requireObject(record.baseline, "baseline");
  const dimensions = requireArray(baseline.dimensions, "baseline.dimensions");
  if (dimensions.length !== 7 || dimensions.some((dimension, index) =>
    dimension.id !== index + 1 || dimension.name !== BASELINE_DIMENSIONS[index])) {
    throw new Error("baseline.dimensions must contain the seven unchanged dimension IDs and texts");
  }
  const claims = requireArray(baseline.claims, "baseline.claims");
  const ids = claims.map((claim) => requireText(claim.id, "baseline claim id"));
  if (claims.length !== 24 || new Set(ids).size !== 24 || expectedIds.some((id) => !ids.includes(id))) {
    throw new Error("baseline must contain exactly 24 unique baseline claim IDs");
  }
  for (const [index, claimValue] of claims.entries()) {
    const claim = requireObject(claimValue, `baseline.claims[${index}]`);
    const id = claim.id;
    if (claim.dimension_id !== observed[id]) throw new Error(`${id} dimension_id differs from the pinned Phase 162 baseline`);
    requireText(claim.source, `${id}.source`);
    const evidenceDate = validIsoDate(claim.evidence_date, `${id}.evidence_date`);
    const assessmentDate = validIsoDate(claim.assessment_date, `${id}.assessment_date`);
    if (evidenceDate > record.cutoff.slice(0, 10) || assessmentDate > record.cutoff.slice(0, 10)) {
      throw new Error(`${id} evidence and assessment dates must not exceed the record cutoff`);
    }
    for (const [pathIndex, pathEntryValue] of requireArray(claim.relevant_paths, `${id}.relevant_paths`).entries()) {
      const pathEntry = typeof pathEntryValue === "string" ? { path: pathEntryValue, disposition: "current" } : requireObject(pathEntryValue, `${id}.relevant_paths[${pathIndex}]`);
      const relative = safeRelativePath(pathEntry.path, `${id}.relevant_paths[${pathIndex}].path`);
      const disposition = requireText(pathEntry.disposition, `${id}.relevant_paths[${pathIndex}].disposition`);
      try {
        containedFile(sourceRoot, relative, `${id} relevant path`);
      } catch (error) {
        if (!disposition.startsWith("archived-link:")) throw error;
      }
    }
    requireText(claim.comparison, `${id}.comparison`);
    requireText(claim.disposition, `${id}.disposition`);
    requireText(claim.limits, `${id}.limits`);
  }
}

function validateSharedRecord(record, sourceRoot, stage) {
  rejectPrivateAndSecretValues(record);
  const commonKeys = [
    "schema", "cutoff", "baseline", "important_workflows", "invalidators", "findings", "opportunities",
    "preserved_history", "conditions", "issue", "source_identities", "delivery", "cleanup", "tracked_inputs", "assumptions",
  ];
  const terminalKeys = ["assessment_id", "assessed_at_utc", "maintainer", "decision", "final_source", "attestation", "delivery_identity", "blockers", "revisit_triggers", "correction"];
  rejectUnknownKeys(record, stage === "terminal" ? [...commonKeys, ...terminalKeys] : commonKeys, "readiness record");
  if (record.schema !== 1) throw new Error("record schema must be version 1");
  validUtcTimestamp(record.cutoff, "cutoff");
  validatePinnedBaseline(record, sourceRoot);
  const workflows = requireArray(record.important_workflows, "important_workflows");
  for (const [index, workflowValue] of workflows.entries()) {
    const workflow = requireObject(workflowValue, `important_workflows[${index}]`);
    requireText(workflow.id, `important_workflows[${index}].id`);
    requireText(workflow.description, `important_workflows[${index}].description`);
    const claims = requireArray(workflow.claims, `important_workflows[${index}].claims`);
    if (claims.some((id) => !Object.hasOwn(BASELINE_CLAIM_DIMENSIONS, id))) throw new Error(`important_workflows[${index}] references an unknown claim`);
  }
  for (const field of ["invalidators", "findings", "opportunities", "tracked_inputs"]) {
    requireArray(record[field], field, { min: field === "findings" || field === "opportunities" ? 0 : 1 });
  }
  for (const [index, invalidatorValue] of record.invalidators.entries()) {
    const invalidator = requireObject(invalidatorValue, `invalidators[${index}]`);
    requireText(invalidator.id, `invalidators[${index}].id`);
    safeRelativePath(invalidator.path, `invalidators[${index}].path`);
    requireText(invalidator.reason, `invalidators[${index}].reason`);
  }
  for (const [index, trackedValue] of record.tracked_inputs.entries()) {
    const tracked = requireObject(trackedValue, `tracked_inputs[${index}]`);
    const relative = safeRelativePath(tracked.path, `tracked_inputs[${index}].path`);
    const disposition = requireText(tracked.disposition, `tracked_inputs[${index}].disposition`);
    try { containedFile(sourceRoot, relative, `tracked_inputs[${index}].path`); }
    catch (error) { if (!disposition.startsWith("archived-link:")) throw error; }
  }
  const conditionRows = requireArray(record.conditions, "conditions");
  if (conditionRows.length !== 6) throw new Error("conditions must contain exactly six unchanged condition texts");
  const conditionIds = new Set();
  conditionRows.forEach((rowValue) => {
    const row = requireObject(rowValue, "conditions[]");
    rejectUnknownKeys(row, stage === "terminal"
      ? ["id", "text", "status", "rationale", "evidence", "evidence_date", "assessment_date", "limits"]
      : ["id", "text"], "conditions[]");
    if (!Number.isInteger(row.id) || row.id < 1 || row.id > 6 || conditionIds.has(row.id) || row.text !== CONDITION_TEXTS[row.id - 1]) {
      throw new Error("conditions IDs and texts must match the six approved conditions exactly once");
    }
    conditionIds.add(row.id);
  });
  verifyPreservedHistory(record, sourceRoot);
  const assumptions = requireArray(record.assumptions, "assumptions");
  const unresolved = new Set(assumptions.filter((item) => item && item.status === "unresolved").map((item) => item.id));
  if (REQUIRED_ASSUMPTIONS.some((id) => !unresolved.has(id))) throw new Error("all seven inherited edge assumptions must remain explicitly unresolved");
  for (const id of REQUIRED_ASSUMPTIONS) {
    const assumption = assumptions.find((item) => item?.id === id);
    requireText(assumption.reason, `${id}.reason`);
  }
  const issue = requireObject(record.issue, "issue");
  const issueRepo = requireText(issue.repository, "issue.repository");
  if (stage === "draft" && issue.status === "pending") {
    requireText(issue.reason, "issue.reason");
  } else {
    const issueNumber = positiveInteger(issue.number, "issue.number");
    const expectedIssueUrl = `https://github.com/${issueRepo}/issues/${issueNumber}`;
    if (issue.url !== expectedIssueUrl) throw new Error("issue URL must be the public GitHub issue URL for its repository and number");
    const remote = apiJson(`repos/${issueRepo}/issues/${issueNumber}`);
    if (remote.number !== issueNumber || remote.html_url !== expectedIssueUrl) throw new Error("readiness issue pointer is not discoverable at the supplied GitHub URL");
  }
  const identities = requireObject(record.source_identities, "source_identities");
  for (const identity of ["candidate", "squash_main", "final_planning_source", "local_artifact", "published"]) {
    const item = requireObject(identities[identity], `source_identities.${identity}`);
    const sha = requireText(item.sha, `source_identities.${identity}.sha`);
    if (!/^[0-9a-f]{40}$/.test(sha) && !(identity === "published" && sha === "not-published")) {
      throw new Error(`source_identities.${identity}.sha must be a full SHA or explicit not-published identity`);
    }
    if (identity === "published") {
      requireText(item.version, "source_identities.published.version");
      requireText(item.tag, "source_identities.published.tag");
    }
  }
  const delivery = requireObject(record.delivery, "delivery");
  const allowedDelivery = stage === "terminal"
    ? ["published", "deferred", "blocked", "not-applicable"]
    : ["published", "deferred", "blocked", "not-applicable", "pending"];
  if (!allowedDelivery.includes(delivery.disposition)) throw new Error("delivery.disposition must be explicit; pending is allowed only before terminal validation and requires a reason");
  requireText(delivery.reason, "delivery.reason");
  const cleanup = requireObject(record.cleanup, "cleanup");
  requireText(cleanup.status, "cleanup.status");
  requireArray(cleanup.items, "cleanup.items", { min: 0 });
}

function canonicalize(value) {
  if (Array.isArray(value)) {
    const entries = value.map(canonicalize);
    if (entries.every((entry) => entry && typeof entry === "object" && !Array.isArray(entry) && Object.hasOwn(entry, "id"))) {
      return entries.sort((left, right) => String(left.id).localeCompare(String(right.id), undefined, { numeric: true }));
    }
    if (entries.every((entry) => ["string", "number"].includes(typeof entry)) && new Set(entries).size === entries.length) {
      return entries.sort((left, right) => String(left).localeCompare(String(right), undefined, { numeric: true }));
    }
    return entries;
  }
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.keys(value).sort().map((key) => [key, canonicalize(value[key])]));
  }
  return value;
}

function renderTerminal(record) {
  const checksum = crypto.createHash("sha256").update(JSON.stringify(canonicalize(record))).digest("hex");
  const judgments = [...record.conditions].sort((left, right) => left.id - right.id)
    .map((condition) => {
      const evidence = condition.evidence.map((entry) => {
        const url = typeof entry === "string" && entry.startsWith("https://") ? entry : (entry?.url || null);
        const label = typeof entry === "string" ? entry : (entry?.label || entry?.path || entry?.url);
        return url ? `[${markdownCell(label)}](${url})` : markdownCell(label);
      }).join("; ");
      return `| ${condition.id} | ${condition.status} | ${condition.evidence_date} | ${markdownCell(evidence)} | ${markdownCell(condition.rationale)} | ${markdownCell(condition.limits)} |`;
    });
  const receipt = record.attestation;
  const lines = [
    `# ${record.assessment_id}`,
    "",
    `- Assessment date: ${record.assessed_at_utc}`,
    `- Decision supplied by @${record.maintainer.login}: **${record.decision}**`,
    `- Decision provenance: ${record.maintainer.decision_provenance}`,
    `- Final planning source: ${record.final_source.sha}`,
    `- Candidate source: ${record.source_identities.candidate.sha}; squash-main source: ${record.source_identities.squash_main.sha}; local artifact: ${record.source_identities.local_artifact.sha}.`,
    `- Published identity: ${record.source_identities.published.version} / ${record.source_identities.published.tag} / ${record.source_identities.published.sha}.`,
    `- Exact-source receipt: ${receipt.repository} run ${receipt.run_id}, attempt ${receipt.run_attempt}, source ${receipt.head_sha}.`,
    `- Coverage artifact ${receipt.coverage_artifact.id} (${receipt.coverage_artifact.digest}); attestation artifact ${receipt.attestation_artifact.id} (${receipt.attestation_artifact.digest}).`,
    `- Delivery: ${record.delivery_identity.disposition}; release ${record.delivery_identity.release}; package ${record.delivery_identity.package}.`,
    ...(record.correction ? [`- Correction: supersedes ${record.correction.supersedes_assessment_id}; ${record.correction.corrected_at_utc}. ${record.correction.reason}`] : []),
    "",
    "| Condition | Supplied status | Evidence date | Evidence | Rationale | Limits |",
    "| --- | --- | --- | --- | --- | --- |",
    ...judgments,
    "",
    "## Blockers",
    ...record.blockers.map((item) => `- ${item}`),
    "",
    "## Revisit triggers",
    ...record.revisit_triggers.map((item) => `- ${item}`),
    "",
    "## Inherited unresolved assumptions",
    ...[...record.assumptions].sort((left, right) => String(left.id).localeCompare(String(right.id), undefined, { numeric: true }))
      .filter((assumption) => REQUIRED_ASSUMPTIONS.includes(assumption.id))
      .map((assumption) => `- ${assumption.id} (unresolved): ${assumption.reason}`),
    "",
    `Record SHA-256: ${checksum}`,
  ];
  return `${lines.join("\n")}\n`;
}

function validateTerminal(record, sourceRoot) {
  validateSharedRecord(record, sourceRoot, "terminal");
  const assessedAt = validUtcTimestamp(record.assessed_at_utc, "assessed_at_utc");
  requireText(record.assessment_id, "assessment_id");
  const maintainer = requireObject(record.maintainer, "maintainer");
  const login = requireText(maintainer.login, "maintainer.login");
  if (!/^[A-Za-z0-9-]{1,39}$/.test(login)) throw new Error("maintainer.login must be a GitHub login");
  requireText(maintainer.decision_provenance, "maintainer.decision_provenance");
  const judgments = requireArray(record.conditions, "conditions");
  if (judgments.length !== 6) throw new Error("terminal conditions must include six supplied judgments");
  const judgmentIds = new Set();
  const statuses = judgments.map((rowValue) => {
    const row = requireObject(rowValue, "conditions[]");
    const id = row.id;
    if (!Number.isInteger(id) || id < 1 || id > 6 || judgmentIds.has(id) || row.text !== CONDITION_TEXTS[id - 1]) throw new Error("terminal condition IDs and texts must match the approved conditions exactly once");
    judgmentIds.add(id);
    if (!["PASS", "FAIL", "UNKNOWN"].includes(row.status)) throw new Error(`condition ${id} status must be supplied as PASS, FAIL, or UNKNOWN`);
    requireText(row.rationale, `condition ${id}.rationale`);
    for (const [evidenceIndex, evidence] of requireArray(row.evidence, `condition ${id}.evidence`).entries()) {
      evidenceReference(evidence, sourceRoot, `condition ${id}.evidence[${evidenceIndex}]`);
    }
    const evidenceDate = validIsoDate(row.evidence_date, `condition ${id}.evidence_date`);
    const assessmentDate = validIsoDate(row.assessment_date, `condition ${id}.assessment_date`);
    if (evidenceDate > assessedAt.slice(0, 10) || assessmentDate !== assessedAt.slice(0, 10)) throw new Error(`condition ${id} evidence/assessment dates must align with the UTC cutoff`);
    requireText(row.limits, `condition ${id}.limits`);
    return row.status;
  });
  if (!Number.isFinite(Date.parse(assessedAt))) throw new Error("assessed_at_utc must be valid");
  if (!["READY FOR OPERATOR UI", "NOT READY"].includes(record.decision)) throw new Error("decision must be explicitly supplied as READY FOR OPERATOR UI or NOT READY");
  if (record.decision === "READY FOR OPERATOR UI" && statuses.some((status) => status !== "PASS")) {
    throw new Error("READY requires six supplied PASS judgments");
  }
  const finalSource = requireObject(record.final_source, "final_source");
  requireExactSha(finalSource.sha);
  if (finalSource.sha !== record.source_identities.final_planning_source.sha) throw new Error("final_source identity must match final_planning_source while remaining separately named");
  const attestation = requireObject(record.attestation, "attestation");
  validateCollectorReceipt(attestation, finalSource.sha, record.issue.repository);
  const deliveryIdentity = requireObject(record.delivery_identity, "delivery_identity");
  requireText(deliveryIdentity.disposition, "delivery_identity.disposition");
  requireText(deliveryIdentity.release, "delivery_identity.release");
  requireText(deliveryIdentity.package, "delivery_identity.package");
  requireArray(record.blockers, "blockers");
  requireArray(record.revisit_triggers, "revisit_triggers");
  if (record.correction !== undefined) {
    const correction = requireObject(record.correction, "correction");
    requireText(correction.supersedes_assessment_id, "correction.supersedes_assessment_id");
    if (correction.supersedes_assessment_id === record.assessment_id) throw new Error("correction must supersede a different prior assessment");
    requireText(correction.reason, "correction.reason");
    if (validUtcTimestamp(correction.corrected_at_utc, "correction.corrected_at_utc") !== assessedAt) {
      throw new Error("correction date must match the separately dated correction assessment");
    }
  }
  return { rendered: renderTerminal(record), statuses };
}

function validateCollectorReceipt(receiptValue, sha, repo) {
  const receipt = requireObject(receiptValue, "final attestation receipt");
  if (receipt.schema !== 1 || receipt.authority !== "github-actions-exact-sha" ||
      receipt.repository !== repo || receipt.head_sha !== sha || receipt.event !== "workflow_dispatch" ||
      receipt.status !== "completed" || receipt.conclusion !== "success") {
    throw new Error("final attestation receipt repository/source/event/outcome does not join the supplied final source");
  }
  const runId = normalizeId(receipt.run_id, "attestation.run_id");
  const attempt = positiveInteger(receipt.run_attempt, "attestation.run_attempt");
  const expectedRunUrl = `https://github.com/${repo}/actions/runs/${runId}`;
  if (receipt.run_url !== expectedRunUrl) throw new Error("attestation receipt run URL does not match its repository and run ID");
  const workflow = requireObject(receipt.workflow, "attestation.workflow");
  if (!/^[1-9][0-9]*$/.test(String(workflow.id || "")) || !requireText(workflow.name, "attestation.workflow.name") ||
      workflow.path !== ".github/workflows/ci.yml") throw new Error("attestation receipt must identify the existing CI workflow metadata");
  const jobs = requireArray(receipt.jobs, "attestation.jobs");
  const expectedJobs = READINESS_JOBS;
  const jobIds = new Set();
  for (const [index, jobValue] of jobs.entries()) {
    const job = requireObject(jobValue, `attestation.jobs[${index}]`);
    const id = normalizeId(job.id, `attestation.jobs[${index}].id`);
    if (jobIds.has(id)) throw new Error("attestation receipt contains duplicate job IDs");
    jobIds.add(id);
  }
  if (jobs.length !== expectedJobs.length || expectedJobs.some((name) => {
    const matches = jobs.filter((job) => job.name === name);
    return matches.length !== 1 || matches[0].status !== "completed" || matches[0].conclusion !== "success";
  })) throw new Error("attestation receipt must retain each exact-attempt required, coverage, and attestation job");
  const coverage = requireObject(receipt.coverage_artifact, "attestation.coverage_artifact");
  const artifact = requireObject(receipt.attestation_artifact, "attestation.attestation_artifact");
  const coverageId = normalizeId(coverage.id, "attestation.coverage_artifact.id");
  normalizeId(artifact.id, "attestation.attestation_artifact.id");
  for (const [label, item] of [["coverage", coverage], ["attestation", artifact]]) {
    if (!/^sha256:[0-9a-f]{64}$/.test(item.digest || "")) throw new Error(`${label} artifact must retain its SHA-256 digest`);
    if (typeof item.expires_at !== "string" || Number.isNaN(Date.parse(item.expires_at))) throw new Error(`${label} artifact must retain its expiry`);
    if (typeof item.url !== "string" || !item.url.startsWith(`https://api.github.com/repos/${repo}/actions/artifacts/`)) throw new Error(`${label} artifact URL is not a public repository artifact URL`);
  }
  const archive = requireObject(receipt.attestation_archive, "attestation.attestation_archive");
  if (!/^[0-9a-f]{64}$/.test(archive.sha256 || "") || artifact.digest !== `sha256:${archive.sha256}`) {
    throw new Error("attestation archive checksum does not match its API artifact digest");
  }
  const member = requireObject(receipt.attestation_member, "attestation.attestation_member");
  if (member.name !== "closeout-attestation.json" || !/^[0-9a-f]{64}$/.test(member.sha256 || "")) {
    throw new Error("attestation member name/checksum is missing or malformed");
  }
  const content = requireObject(member.content, "attestation.attestation_member.content");
  if (content.schema !== 1 || content.authority !== "github-actions-exact-sha" ||
      content.repository !== repo || content.head_sha !== sha || normalizeId(content.run_id, "attested run id") !== runId ||
      positiveInteger(content.run_attempt, "attested run attempt") !== attempt || content.event !== "workflow_dispatch" ||
      content.run_url !== receipt.run_url || content.workflow !== workflow.name ||
      JSON.stringify(content.required_jobs) !== JSON.stringify(REQUIRED_CHECKS)) {
    throw new Error("attestation JSON member does not join the selected attempt and workflow metadata");
  }
  const coverageContent = requireObject(content.coverage, "attestation member coverage");
  if (coverageContent.outcome !== "success" || normalizeId(coverageContent.artifact_id, "attested coverage artifact id") !== coverageId ||
      coverageContent.artifact_digest !== coverage.digest || coverageContent.artifact_url !== coverage.url) {
    throw new Error("attestation coverage identity/digest does not join the API artifact");
  }
  validUtcTimestamp(receipt.collected_at_utc, "attestation.collected_at_utc");
  requireArray(receipt.limitations, "attestation.limitations");
  return receipt;
}

function validateReadiness(flags) {
  const stage = flags.stage;
  if (!["draft", "inputs", "terminal"].includes(stage)) throw new Error("--stage must be draft, inputs, or terminal");
  const sourceRoot = path.resolve(requireText(flags["source-root"], "--source-root"));
  if (!fs.statSync(sourceRoot).isDirectory()) throw new Error("--source-root must name a directory");
  const file = stage === "terminal" ? flags.record : flags.inputs;
  const record = readRecordFile(requireText(file, stage === "terminal" ? "--record" : "--inputs"), `readiness ${stage} record`);
  if (stage === "terminal") {
    const inputs = readRecordFile(requireText(flags.inputs, "--inputs"), "frozen readiness inputs");
    validateSharedRecord(inputs, sourceRoot, "inputs");
    const result = validateTerminal(record, sourceRoot);
    const collectorReceipt = readRecordFile(requireText(flags.receipt, "--receipt"), "exact-source collector receipt");
    validateCollectorReceipt(collectorReceipt, record.final_source.sha, record.issue.repository);
    if (JSON.stringify(canonicalize(collectorReceipt)) !== JSON.stringify(canonicalize(record.attestation))) {
      throw new Error("terminal record's attestation content differs from the explicit collector receipt");
    }
    const inputProjection = {
      schema: inputs.schema,
      cutoff: inputs.cutoff,
      baseline: inputs.baseline,
      important_workflows: inputs.important_workflows,
      invalidators: inputs.invalidators,
      findings: inputs.findings,
      opportunities: inputs.opportunities,
      preserved_history: inputs.preserved_history,
      conditions: inputs.conditions.map(({ id, text }) => ({ id, text })),
      issue: inputs.issue,
      source_identities: inputs.source_identities,
      delivery: inputs.delivery,
      cleanup: inputs.cleanup,
      tracked_inputs: inputs.tracked_inputs,
      assumptions: inputs.assumptions,
    };
    const recordProjection = { ...inputProjection, ...Object.fromEntries(Object.keys(inputProjection).map((key) => [key, record[key]])) };
    recordProjection.conditions = record.conditions.map(({ id, text }) => ({ id, text }));
    if (JSON.stringify(canonicalize(inputProjection)) !== JSON.stringify(canonicalize(recordProjection))) {
      throw new Error("terminal record changes frozen inputs or historical assumptions");
    }
    const receipt = {
      result: "FACTUAL_ONLY_VALID",
      stage,
      decision: record.decision,
      approval: null,
      record_sha256: crypto.createHash("sha256").update(JSON.stringify(canonicalize(record))).digest("hex"),
      rendered_markdown: result.rendered,
      limitations: ["Structural validation verifies supplied fields and joins; it does not assess evidence semantics, readiness, or maintainer approval."],
    };
    process.stdout.write(`${JSON.stringify(receipt, null, 2)}\n`);
    return;
  }
  validateSharedRecord(record, sourceRoot, stage);
  if (stage === "draft" && record.issue.status !== "pending") throw new Error("draft issue pointer must be explicitly pending with a reason");
  process.stdout.write(`${JSON.stringify({ result: "FACTUAL_ONLY_VALID", stage, semantic_decision: null, limitations: ["Structural validation checks inputs only; it does not judge conditions or authorize publication."] }, null, 2)}\n`);
}

function verifyReadinessComment(flags) {
  const repo = requireText(flags.repo, "--repo");
  if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repo)) throw new Error("--repo must be OWNER/REPO");
  const issue = positiveInteger(flags.issue, "--issue");
  const commentId = normalizeId(flags.comment, "--comment");
  const maintainer = requireText(flags.maintainer, "--maintainer");
  const record = readRecordFile(requireText(flags.record, "--record"), "terminal readiness record");
  const sourceRoot = path.resolve(flags["source-root"] || process.cwd());
  const { rendered } = validateTerminal(record, sourceRoot);
  if (record.issue.repository !== repo || record.issue.number !== issue || record.maintainer.login !== maintainer) {
    throw new Error("record repository/issue/maintainer do not match the explicit comment verification target");
  }
  const issueUrl = `https://api.github.com/repos/${repo}/issues/${issue}`;
  const commentUrl = `repos/${repo}/issues/comments/${commentId}`;
  const commentPages = apiJson(`repos/${repo}/issues/${issue}/comments?per_page=100`, { paginate: true });
  const comments = flattenArrayPages(commentPages, "comment");
  const authorityChecksum = crypto.createHash("sha256").update(JSON.stringify(canonicalize(record))).digest("hex");
  const authorityMatches = comments.filter((entry) =>
    typeof entry.body === "string" && (entry.body.includes(record.assessment_id) || entry.body.includes(`Record SHA-256: ${authorityChecksum}`)));
  if (authorityMatches.length !== 1 || normalizeId(authorityMatches[0].id, "readiness comment id") !== commentId) {
    throw new Error("readiness issue contains missing or duplicate terminal authority comments");
  }
  const comment = apiJson(commentUrl);
  const renderedChecksum = rendered.match(/Record SHA-256: ([0-9a-f]{64})\n$/)?.[1];
  const checksumCount = (comment.body?.match(/Record SHA-256:/g) || []).length;
  if (comment.id === undefined || normalizeId(comment.id, "comment id") !== commentId ||
      comment.issue_url !== issueUrl || comment.user?.login !== maintainer ||
      comment.body !== rendered || checksumCount !== 1 || !renderedChecksum) {
    throw new Error("readiness comment is edited, duplicated, on another issue, or authored by another login");
  }
  process.stdout.write(`${JSON.stringify({ result: "FACTUAL_ONLY_VALID", repository: repo, issue, comment_id: commentId, author: maintainer, record_sha256: renderedChecksum, limitations: ["Readback confirms exact public comment identity and body only; it does not certify the supplied judgments or authorize the decision."] }, null, 2)}\n`);
}

function sleep(ms) {
  if (ms <= 0) return;
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
}

function parse(argv) {
  const positional = [];
  const flags = {};

  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith("--")) {
      positional.push(token);
      continue;
    }

    const key = token.slice(2);
    const next = argv[index + 1];
    if (next && !next.startsWith("--")) {
      flags[key] = next;
      index += 1;
    } else {
      flags[key] = true;
    }
  }

  return { positional, flags };
}

function help() {
  process.stdout.write(`Usage: node scripts/ci_monitor.cjs <command> [options]\n\n`);
  process.stdout.write(`Commands:\n`);
  process.stdout.write(`  runs [--branch NAME]                       List recent CI runs\n`);
  process.stdout.write(`  watch RUN_ID                               Watch a run to completion\n`);
  process.stdout.write(`  fail-fast RUN_ID                           Watch and fail on a failed run\n`);
  process.stdout.write(`  log-failed RUN_ID                          Print failed logs\n`);
  process.stdout.write(`  test-summary RUN_ID                        Summarize job conclusions\n`);
  process.stdout.write(`  check-actions [WORKFLOW]                   Require immutable action pins\n`);
  process.stdout.write(`  grep RUN_ID --pattern REGEX                Search run logs\n`);
  process.stdout.write(`  wait-for RUN_ID JOB --keyword TEXT         Wait for a job log marker\n`);
  process.stdout.write(`  closeout [--branch NAME] [--sha SHA] [--push]\n`);
  process.stdout.write(`                                                Dispatch and verify exact-SHA closeout\n`);
  process.stdout.write(`  collect-readiness --repo OWNER/REPO --sha SHA --run ID --attempt N --output PATH\n`);
  process.stdout.write(`  validate-readiness --stage draft|inputs|terminal --inputs PATH --source-root PATH [--receipt PATH --record PATH]\n`);
  process.stdout.write(`  verify-readiness-comment --repo OWNER/REPO --issue NUMBER --comment ID --record PATH --maintainer LOGIN [--source-root PATH]\n`);
  process.stdout.write(`  protect [--branch NAME] [--apply]            Audit or reconcile required checks\n`);
}

function listRuns(branch) {
  const args = [
    "run",
    "list",
    "--workflow",
    "ci.yml",
    "--event",
    "workflow_dispatch",
    "--limit",
    "30",
    "--json",
    "databaseId,headSha,status,conclusion,url,createdAt",
  ];
  if (branch) args.splice(4, 0, "--branch", branch);
  return json(GH, args);
}

function requireExactSha(sha) {
  if (!/^[0-9a-f]{40}$/.test(sha)) {
    throw new Error(`expected a full lowercase 40-character SHA, got ${JSON.stringify(sha)}`);
  }
}

function artifactFor(artifacts, name, sha) {
  const matches = (artifacts || []).filter(
    (artifact) => artifact.name === name && artifact.expired === false,
  );
  if (matches.length !== 1) {
    throw new Error(`expected exactly one live ${name} artifact, found ${matches.length}`);
  }

  const artifact = matches[0];
  if (!artifact.digest || !artifact.id || artifact.workflow_run?.head_sha !== sha) {
    throw new Error(`${name} is missing its id/digest or is not bound to ${sha}`);
  }
  return artifact;
}

function closeout(flags) {
  run(GH, ["auth", "status"]);

  const branch = flags.branch || output(GIT, ["branch", "--show-current"]);
  const sha = flags.sha || output(GIT, ["rev-parse", "HEAD"]);
  const workflow = flags.workflow || "ci.yml";
  const timeoutSeconds = Number(flags["timeout-seconds"] || 3600);
  const pollSeconds = Number(flags["poll-seconds"] || 5);
  requireExactSha(sha);
  if (!branch) throw new Error("cannot dispatch closeout from a detached HEAD");

  const repo = flags.repo || output(GH, ["repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"]);
  const beforeIds = new Set(listRuns(branch).map((item) => item.databaseId));

  if (flags.push) {
    run(GIT, ["push", "origin", `HEAD:refs/heads/${branch}`]);
  }

  const remoteLine = output(GIT, ["ls-remote", "--heads", "origin", `refs/heads/${branch}`]);
  const remoteSha = remoteLine.split(/\s+/)[0] || "";
  if (remoteSha !== sha) {
    throw new Error(`origin/${branch} is ${remoteSha || "missing"}, expected ${sha}; rerun with --push`);
  }

  run(GH, ["workflow", "run", workflow, "--ref", branch]);

  const deadline = Date.now() + timeoutSeconds * 1000;
  let selected;
  while (Date.now() <= deadline) {
    selected = listRuns(branch).find(
      (item) => item.headSha === sha && !beforeIds.has(item.databaseId),
    );
    if (selected) break;
    sleep(pollSeconds * 1000);
  }

  if (!selected) {
    throw new Error(`timed out waiting for a new workflow_dispatch run at ${sha}`);
  }

  run(GH, ["run", "watch", String(selected.databaseId), "--exit-status"]);

  const jobsPayload = json(GH, [
    "api",
    `repos/${repo}/actions/runs/${selected.databaseId}/jobs?per_page=100`,
  ]);
  const jobs = jobsPayload.jobs || [];
  const requiredJobs = [
    ...REQUIRED_CHECKS,
    "coverage (advisory)",
    "closeout-attestation",
  ];

  for (const name of requiredJobs) {
    const matches = jobs.filter((job) => job.name === name);
    if (matches.length !== 1 || matches[0].conclusion !== "success") {
      throw new Error(`${name} must have exactly one successful job, got ${JSON.stringify(matches)}`);
    }
  }

  const artifactPayload = json(GH, [
    "api",
    `repos/${repo}/actions/runs/${selected.databaseId}/artifacts?per_page=100`,
  ]);
  const coverage = artifactFor(artifactPayload.artifacts, `coverage-report-${sha}`, sha);
  const attestation = artifactFor(
    artifactPayload.artifacts,
    `closeout-attestation-${sha}`,
    sha,
  );

  process.stdout.write(
    `${JSON.stringify(
      {
        authority: "github-actions-exact-sha",
        repository: repo,
        workflow,
        run_id: selected.databaseId,
        run_url: selected.url,
        head_sha: sha,
        event: "workflow_dispatch",
        jobs: requiredJobs,
        coverage_artifact: {
          id: coverage.id,
          digest: coverage.digest,
          expires_at: coverage.expires_at,
        },
        closeout_artifact: {
          id: attestation.id,
          digest: attestation.digest,
          expires_at: attestation.expires_at,
        },
      },
      null,
      2,
    )}\n`,
  );
}

function normalizedProtection(payload) {
  return {
    strict: payload.strict === true,
    checks: (payload.checks || [])
      .map(({ context, app_id: appId }) => ({ context, app_id: appId }))
      .sort((left, right) => left.context.localeCompare(right.context)),
  };
}

function protect(flags) {
  run(GH, ["auth", "status"]);

  const repo = flags.repo || output(GH, ["repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"]);
  const branch = flags.branch || "main";
  const appId = Number(flags["app-id"] || 15368);
  const endpoint = `repos/${repo}/branches/${branch}/protection/required_status_checks`;
  const desired = normalizedProtection({
    strict: true,
    checks: REQUIRED_CHECKS.map((context) => ({ context, app_id: appId })),
  });
  const before = normalizedProtection(json(GH, ["api", endpoint]));
  const drift = JSON.stringify(before) !== JSON.stringify(desired);

  if (flags.apply && drift) {
    run(GH, ["api", "--method", "PATCH", endpoint, "--input", "-"], {
      input: JSON.stringify(desired),
    });
  }

  const after = flags.apply ? normalizedProtection(json(GH, ["api", endpoint])) : before;
  const converged = JSON.stringify(after) === JSON.stringify(desired);
  if (flags.apply && !converged) {
    throw new Error(`required checks did not converge: ${JSON.stringify({ desired, after })}`);
  }

  process.stdout.write(
    `${JSON.stringify({ repository: repo, branch, applied: Boolean(flags.apply && drift), drift, converged, before, desired, after }, null, 2)}\n`,
  );
}

function main() {
  const { positional, flags } = parse(process.argv.slice(2));
  const command = positional.shift();

  try {
    switch (command) {
      case undefined:
      case "help":
      case "--help":
        help();
        break;
      case "runs":
        process.stdout.write(`${JSON.stringify(listRuns(flags.branch), null, 2)}\n`);
        break;
      case "watch":
      case "fail-fast":
        run(GH, ["run", "watch", positional[0], "--exit-status"], { allowFailure: false });
        break;
      case "log-failed":
        process.stdout.write(run(GH, ["run", "view", positional[0], "--log-failed"]).stdout);
        break;
      case "test-summary": {
        const repo = output(GH, ["repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"]);
        const payload = json(GH, ["api", `repos/${repo}/actions/runs/${positional[0]}/jobs?per_page=100`]);
        const summary = (payload.jobs || []).map(({ name, conclusion }) => ({ name, conclusion }));
        process.stdout.write(`${JSON.stringify(summary, null, 2)}\n`);
        break;
      }
      case "check-actions": {
        const file = positional[0] || ".github/workflows/ci.yml";
        const content = fs.readFileSync(file, "utf8");
        const unpinned = [...content.matchAll(/^\s*-?\s*uses:\s*([^\s#]+)(?:\s+#.*)?$/gm)]
          .map((match) => match[1])
          .filter((action) => !action.startsWith("./") && !/@[0-9a-f]{40}$/.test(action));
        if (unpinned.length) throw new Error(`mutable action refs: ${unpinned.join(", ")}`);
        process.stdout.write(`All external actions in ${file} use immutable SHA pins.\n`);
        break;
      }
      case "grep": {
        if (!flags.pattern) throw new Error("grep requires --pattern");
        const logs = run(GH, ["run", "view", positional[0], "--log"]).stdout;
        const matcher = new RegExp(flags.pattern);
        process.stdout.write(logs.split("\n").filter((line) => matcher.test(line)).join("\n") + "\n");
        break;
      }
      case "wait-for": {
        if (!flags.keyword) throw new Error("wait-for requires --keyword");
        run(GH, ["run", "watch", positional[0], "--exit-status"]);
        const logs = run(GH, ["run", "view", positional[0], "--job", positional[1], "--log"]).stdout;
        if (!logs.includes(flags.keyword)) throw new Error(`job log did not contain ${flags.keyword}`);
        break;
      }
      case "closeout":
        closeout(flags);
        break;
      case "collect-readiness":
        collectReadiness(flags);
        break;
      case "validate-readiness":
        validateReadiness(flags);
        break;
      case "verify-readiness-comment":
        verifyReadinessComment(flags);
        break;
      case "protect":
        protect(flags);
        break;
      default:
        throw new Error(`unknown command ${command}`);
    }
  } catch (error) {
    fail(error.message);
  }
}

main();
