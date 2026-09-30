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
