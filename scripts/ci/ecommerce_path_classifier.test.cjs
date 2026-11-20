"use strict";

const assert = require("node:assert/strict");
const { execFileSync, spawnSync } = require("node:child_process");
const { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");
const { SKIPPABLE_PATTERN, classify, main } = require("./ecommerce_path_classifier.cjs");

const scriptPath = path.join(__dirname, "ecommerce_path_classifier.cjs");

// --- pure classify -----------------------------------------------------------------------

const PR = "pull_request";

test("the allowlist literal is the CI-01 requirement text", () => {
  const literal = String.raw`^(\.planning/|docs/|[^/]+\.md$)`;
  assert.ok(readFileSync(scriptPath, "utf8").includes(literal), "verbatim allowlist literal");
  assert.equal(SKIPPABLE_PATTERN.source, new RegExp(literal).source);
  assert.equal(SKIPPABLE_PATTERN.flags, "");
});

test("a pull request whose paths are all planning, docs or root markdown skips", () => {
  const result = classify({
    eventName: PR,
    paths: [
      ".planning/STATE.md",
      ".planning/phases/188.1-ci-path-classifier/188.1-01-PLAN.md",
      "docs/guides/search.md",
      "docs/anything.png",
      "README.md",
      "CHANGELOG.md",
      "CONTRIBUTING.md",
    ],
  });
  assert.deepEqual(result, { run: false, reason: "all-paths-allowlisted" });
});

test("a .planning-only diff skips", () => {
  assert.deepEqual(classify({ eventName: PR, paths: [".planning/ROADMAP.md"] }), {
    run: false,
    reason: "all-paths-allowlisted",
  });
});

test("one non-allowlisted path among allowlisted ones runs the lanes", () => {
  const nonAllowlisted = [
    "lib/x.ex",
    "scrypath_ops/lib/x.ex",
    "examples/scrypath_ecommerce/lib/x.ex",
    "scripts/ci/ecommerce_path_classifier.cjs",
    "brand/logo.svg",
    "dev/mix/tasks/x.ex",
    "config/config.exs",
    "priv/static/x.css",
    "language/terms.json",
    "fixtures/x.json",
    "test/x_test.exs",
    "website/index.html",
    "guides/search.md",
    "mix.exs",
    "mix.lock",
    ".github/workflows/ci.yml",
    ".github/workflows/website.yml",
  ];
  for (const extra of nonAllowlisted) {
    const result = classify({
      eventName: PR,
      paths: [".planning/STATE.md", "docs/a.md", "README.md", extra],
    });
    assert.deepEqual(result, { run: true, reason: "non-allowlisted-path" }, extra);
  }
});

test("near misses run the lanes", () => {
  const nearMisses = [
    "docs-extra/x.md",
    ".planning-old/x",
    "sub/README.md",
    "scrypath_ops/docs/x.md",
    "examples/scrypath_ecommerce/docs/x.md",
    "README.md.bak",
    "README.MD",
    "docs",
    ".planning",
    "x/.planning/y.md",
  ];
  for (const nearMiss of nearMisses) {
    assert.deepEqual(
      classify({ eventName: PR, paths: [nearMiss] }),
      { run: true, reason: "non-allowlisted-path" },
      nearMiss,
    );
  }
});

test("an empty diff runs the lanes", () => {
  for (const paths of [[], [""], ["", ""], undefined, null, "docs/x.md", [null, 7, ""]]) {
    assert.deepEqual(classify({ eventName: PR, paths }), { run: true, reason: "empty-diff" });
  }
});

test("an entry that is not a usable path runs the lanes even beside allowlisted paths", () => {
  for (const paths of [
    [".planning/a.md", { path: "lib/x.ex" }, 42],
    [".planning/a.md", ""],
    ["docs/x.md", null],
  ]) {
    assert.deepEqual(classify({ eventName: PR, paths }), { run: true, reason: "non-allowlisted-path" });
  }
});

test("every event other than pull_request runs the lanes", () => {
  for (const eventName of ["push", "schedule", "workflow_dispatch", "merge_group", "", undefined]) {
    assert.deepEqual(classify({ eventName, paths: [".planning/STATE.md"] }), {
      run: true,
      reason: "non-pull-request-event",
    });
  }
  assert.deepEqual(classify(), { run: true, reason: "non-pull-request-event" });
});

test("the regex is not stateful across repeated matches", () => {
  for (let index = 0; index < 5; index += 1) {
    assert.equal(SKIPPABLE_PATTERN.test("docs/a.md"), true);
  }
});

// --- CLI against a throwaway git repository -----------------------------------------------

function sanitizedEnv(extra = {}) {
  const env = {};
  for (const [key, value] of Object.entries(process.env)) {
    if (!key.startsWith("GIT_") && !key.startsWith("GITHUB_")) env[key] = value;
  }
  env.GIT_CONFIG_GLOBAL = "/dev/null";
  env.GIT_CONFIG_NOSYSTEM = "1";
  return { ...env, ...extra };
}

function git(cwd, ...args) {
  return execFileSync(
    "git",
    ["-c", "user.name=t", "-c", "user.email=t@example.com", "-c", "commit.gpgsign=false", ...args],
    { cwd, env: sanitizedEnv(), stdio: ["ignore", "pipe", "pipe"], encoding: "utf8" },
  );
}

function write(root, relative, contents = "x\n") {
  const target = path.join(root, relative);
  mkdirSync(path.dirname(target), { recursive: true });
  writeFileSync(target, contents);
}

function tempDirectory(t, prefix) {
  const directory = mkdtempSync(path.join(os.tmpdir(), prefix));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  return directory;
}

function commitAll(repo, message) {
  git(repo, "add", "-A");
  git(repo, "commit", "-q", "-m", message);
}

// A base commit on `main` with a fake `origin/main`, then a `pr` branch for the commits under test.
function makeRepo(t, { withOriginRef = true } = {}) {
  const repo = tempDirectory(t, "scrypath-path-classifier-repo-");
  git(repo, "init", "-q", "-b", "main");
  write(repo, "lib/x.ex", "defmodule X do\nend\n");
  write(repo, "README.md", "# base\n");
  commitAll(repo, "base");
  if (withOriginRef) git(repo, "update-ref", "refs/remotes/origin/main", "HEAD");
  git(repo, "checkout", "-q", "-b", "pr");
  return repo;
}

// Runs the CLI from a directory that is not the repository, pointing at it with --cwd.
// `event: null` or `baseRef: null` leaves that variable unset.
function runCli(t, { repo, event = PR, baseRef = "main", extraArgs = [], env = {} } = {}) {
  const work = tempDirectory(t, "scrypath-path-classifier-out-");
  const output = path.join(work, "github_output");
  writeFileSync(output, "");
  const args = [scriptPath, "--output", output];
  if (repo !== undefined) args.push("--cwd", repo);
  args.push(...extraArgs);
  const childEnv = sanitizedEnv(env);
  if (event !== null) childEnv.GITHUB_EVENT_NAME = event;
  if (baseRef !== null) childEnv.GITHUB_BASE_REF = baseRef;
  const completed = spawnSync(process.execPath, args, {
    cwd: work,
    env: childEnv,
    encoding: "utf8",
  });
  return {
    status: completed.status,
    stdout: completed.stdout,
    stderr: completed.stderr,
    output: readFileSync(output, "utf8"),
    work,
  };
}

const SKIP = "run=false\nreason=all-paths-allowlisted\n";

test("CLI: a .planning-only commit skips", (t) => {
  const repo = makeRepo(t);
  write(repo, ".planning/STATE.md");
  write(repo, "docs/guide.md");
  write(repo, "NOTES.md");
  commitAll(repo, "planning and docs");
  const result = runCli(t, { repo });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.output, SKIP);
});

test("CLI: a lib/ commit runs the lanes", (t) => {
  const repo = makeRepo(t);
  write(repo, ".planning/STATE.md");
  write(repo, "lib/y.ex");
  commitAll(repo, "code");
  const result = runCli(t, { repo });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.output, "run=true\nreason=non-allowlisted-path\n");
});

test("CLI: a rename out of lib/ into docs/ still runs the lanes", (t) => {
  const repo = makeRepo(t);
  mkdirSync(path.join(repo, "docs"), { recursive: true });
  git(repo, "mv", "lib/x.ex", "docs/x.md");
  git(repo, "commit", "-q", "-m", "move code into docs");
  const result = runCli(t, { repo });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.output, "run=true\nreason=non-allowlisted-path\n");
});

test("CLI: a rename within the allowlist still skips", (t) => {
  const repo = makeRepo(t);
  git(repo, "mv", "README.md", "OVERVIEW.md");
  git(repo, "commit", "-q", "-m", "rename root markdown");
  const result = runCli(t, { repo });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.output, SKIP);
});

test("CLI: an empty diff runs the lanes", (t) => {
  const repo = makeRepo(t);
  const result = runCli(t, { repo });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.output, "run=true\nreason=empty-diff\n");
});

test("CLI: a missing origin ref runs the lanes and exits 0", (t) => {
  const repo = makeRepo(t, { withOriginRef: false });
  write(repo, ".planning/STATE.md");
  commitAll(repo, "planning");
  const result = runCli(t, { repo });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.output, "run=true\nreason=diff-error\n");
});

test("CLI: a missing origin ref is repaired by one fetch of the base branch", (t) => {
  const remote = tempDirectory(t, "scrypath-path-classifier-remote-");
  git(remote, "init", "-q", "-b", "main");
  write(remote, "lib/x.ex");
  commitAll(remote, "base");

  const repo = tempDirectory(t, "scrypath-path-classifier-clone-");
  git(repo, "init", "-q", "-b", "main");
  git(repo, "remote", "add", "origin", remote);
  git(repo, "fetch", "-q", "--no-tags", "origin", "main");
  git(repo, "checkout", "-q", "-b", "pr", "FETCH_HEAD");
  git(repo, "update-ref", "-d", "refs/remotes/origin/main");
  write(repo, ".planning/STATE.md");
  commitAll(repo, "planning");

  const result = runCli(t, { repo });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.output, SKIP);
});

test("CLI: --head classifies another ref", (t) => {
  const repo = makeRepo(t);
  write(repo, "docs/guide.md");
  commitAll(repo, "docs");
  git(repo, "checkout", "-q", "-b", "code-branch");
  write(repo, "lib/y.ex");
  commitAll(repo, "code");
  git(repo, "checkout", "-q", "pr");

  const skipped = runCli(t, { repo, extraArgs: ["--head", "pr"] });
  assert.equal(skipped.output, SKIP);
  const ran = runCli(t, { repo, extraArgs: ["--head", "code-branch"] });
  assert.equal(ran.output, "run=true\nreason=non-allowlisted-path\n");
});

test("CLI: a missing paths file runs the lanes and exits 0", (t) => {
  const result = runCli(t, {
    extraArgs: ["--paths-file", path.join(os.tmpdir(), "scrypath-no-such-paths-file")],
  });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.output, "run=true\nreason=diff-error\n");
});

test("CLI: a pull request without a base ref runs the lanes and exits 0", (t) => {
  const repo = makeRepo(t);
  write(repo, ".planning/STATE.md");
  commitAll(repo, "planning");
  const result = runCli(t, { repo, baseRef: null });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.output, "run=true\nreason=diff-error\n");
});

test("CLI: an unknown or incomplete argument runs the lanes and exits 0", (t) => {
  for (const extraArgs of [["--bogus"], ["--head"], ["--paths-file"]]) {
    const result = runCli(t, { extraArgs });
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.output, "run=true\nreason=diff-error\n", extraArgs.join(" "));
  }
});

test("CLI: a planted paths file classifies like the git path", (t) => {
  const work = tempDirectory(t, "scrypath-path-classifier-paths-");
  const pathsFile = path.join(work, "paths");

  writeFileSync(pathsFile, [".planning/x.md", "docs/y.md", "README.md"].join("\0") + "\0");
  assert.equal(runCli(t, { extraArgs: ["--paths-file", pathsFile] }).output, SKIP);

  writeFileSync(pathsFile, [".planning/x.md", "lib/z.ex"].join("\0") + "\0");
  assert.equal(
    runCli(t, { extraArgs: ["--paths-file", pathsFile] }).output,
    "run=true\nreason=non-allowlisted-path\n",
  );

  writeFileSync(pathsFile, "");
  assert.equal(
    runCli(t, { extraArgs: ["--paths-file", pathsFile] }).output,
    "run=true\nreason=empty-diff\n",
  );
});

test("CLI: non-pull-request events run the lanes even for a planning-only diff", (t) => {
  const work = tempDirectory(t, "scrypath-path-classifier-events-");
  const pathsFile = path.join(work, "paths");
  writeFileSync(pathsFile, ".planning/STATE.md\0");

  for (const event of ["push", "schedule", "workflow_dispatch", "merge_group", null]) {
    const result = runCli(t, { event, extraArgs: ["--paths-file", pathsFile] });
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.output, "run=true\nreason=non-pull-request-event\n", String(event));
  }
});

test("CLI: output is appended and stdout is used when no output file is given", (t) => {
  const work = tempDirectory(t, "scrypath-path-classifier-append-");
  const pathsFile = path.join(work, "paths");
  const output = path.join(work, "github_output");
  writeFileSync(pathsFile, ".planning/STATE.md\0");
  writeFileSync(output, "other=1\n");

  const env = sanitizedEnv({ GITHUB_EVENT_NAME: PR, GITHUB_BASE_REF: "main" });
  const appended = spawnSync(
    process.execPath,
    [scriptPath, "--paths-file", pathsFile, "--output", output],
    { env, encoding: "utf8" },
  );
  assert.equal(appended.status, 0);
  assert.equal(readFileSync(output, "utf8"), `other=1\n${SKIP}`);

  const printed = spawnSync(process.execPath, [scriptPath, "--paths-file", pathsFile], {
    env,
    encoding: "utf8",
  });
  assert.equal(printed.status, 0);
  assert.equal(printed.stdout, SKIP);
});

test("CLI: an unwritable output file fails the step so the workflow fails open", (t) => {
  const work = tempDirectory(t, "scrypath-path-classifier-unwritable-");
  const pathsFile = path.join(work, "paths");
  writeFileSync(pathsFile, ".planning/STATE.md\0");
  const env = sanitizedEnv({ GITHUB_EVENT_NAME: PR, GITHUB_BASE_REF: "main" });
  // A directory cannot be appended to.
  const completed = spawnSync(
    process.execPath,
    [scriptPath, "--paths-file", pathsFile, "--output", work],
    { env, encoding: "utf8" },
  );
  assert.equal(completed.status, 1);
});

test("CLI: a file name with a newline and run=false cannot inject into the output", (t) => {
  const repo = makeRepo(t);
  write(repo, "docs/a\nrun=false.md");
  write(repo, "lib/y.ex");
  commitAll(repo, "injection attempt beside code");
  const result = runCli(t, { repo });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.output, "run=true\nreason=non-allowlisted-path\n");
  for (const line of result.stderr.split("\n").filter((entry) => entry !== "")) {
    assert.ok(line.startsWith("ecommerce-path: "), `unprefixed log line: ${line}`);
  }
});

test("CLI: a hostile allowlisted file name still yields only the two fixed lines", (t) => {
  const repo = makeRepo(t);
  write(repo, "docs/a\nrun=true\nreason=injected.md");
  commitAll(repo, "newline in an allowlisted name");
  const result = runCli(t, { repo });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.output, SKIP);
});

test("main reports an error through the exit status, never by throwing", () => {
  const originalWrite = process.stderr.write;
  process.stderr.write = () => true;
  try {
    assert.equal(
      main(["--output", path.join(os.tmpdir(), "scrypath-no-such-dir", "out")], {
        GITHUB_EVENT_NAME: "push",
      }),
      1,
    );
  } finally {
    process.stderr.write = originalWrite;
  }
});
