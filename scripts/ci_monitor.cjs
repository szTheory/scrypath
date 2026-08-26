#!/usr/bin/env node

"use strict";

const { spawnSync } = require("node:child_process");
const fs = require("node:fs");

const GH = process.env.GH_BIN || "gh";
const GIT = process.env.GIT_BIN || "git";
const REQUIRED_CHECKS = [
  "core (required)",
  "package (required)",
  "repository-contracts (required)",
  "backend (required)",
  "ecommerce-mounted (required)",
];

function fail(message) {
  process.stderr.write(`ERROR: ${message}\n`);
  process.exit(1);
}

function run(bin, args, options = {}) {
  const result = spawnSync(bin, args, {
    cwd: options.cwd || process.cwd(),
    encoding: "utf8",
    env: process.env,
    input: options.input,
    maxBuffer: 20 * 1024 * 1024,
  });

  if (result.error) {
    throw new Error(`${bin} could not start: ${result.error.message}`);
  }

  if (result.status !== 0 && !options.allowFailure) {
    const detail = (result.stderr || result.stdout || "").trim();
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
