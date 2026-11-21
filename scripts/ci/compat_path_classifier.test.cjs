"use strict";

const assert = require("node:assert/strict");
const { execFileSync, spawnSync } = require("node:child_process");
const { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");
const { RELEVANT_PATTERN, classify, main } = require("./compat_path_classifier.cjs");

const scriptPath = path.join(__dirname, "compat_path_classifier.cjs");
const repositoryRoot = path.resolve(__dirname, "../..");
const PR = "pull_request";

// --- pure classify -----------------------------------------------------------------------

test("the relevant-path literal is the pinned list from the CI-03 decision", () => {
  const literal = String.raw`^(lib/|dev/|test/|config/|priv/|scripts/|mix\.exs$|mix\.lock$|\.github/workflows/ci\.yml$)`;
  assert.ok(readFileSync(scriptPath, "utf8").includes(literal), "verbatim relevant-path literal");
  assert.equal(RELEVANT_PATTERN.source, new RegExp(literal).source);
  assert.equal(RELEVANT_PATTERN.flags, "");
});

test("a pull request that touches no compiled or executed path skips the matrix", () => {
  const result = classify({
    eventName: PR,
    paths: [
      "website/src/index.html",
      "docs/releasing.md",
      "README.md",
      ".planning/STATE.md",
      "brand/logo.svg",
      "scrypath_ops/lib/x.ex",
      "examples/scrypath_ecommerce/lib/x.ex",
      "guides/search.md",
      ".github/workflows/website.yml",
      ".github/dependabot.yml",
      "CHANGELOG.md",
    ],
  });
  assert.deepEqual(result, { run: false, reason: "no-relevant-path" });
});

test("a website-only diff skips", () => {
  assert.deepEqual(classify({ eventName: PR, paths: ["website/scripts/check.mjs"] }), {
    run: false,
    reason: "no-relevant-path",
  });
});

test("each relevant path runs the matrix on its own", () => {
  const relevant = [
    "lib/scrypath.ex",
    "lib/scrypath/deeply/nested/file.ex",
    "dev/mix/tasks/verify/core.ex",
    "test/scrypath/x_test.exs",
    "test/support/case.ex",
    "config/config.exs",
    "priv/static/x.css",
    "scripts/ci/beam_cache.cjs",
    "scripts/ci_monitor.cjs",
    "mix.exs",
    "mix.lock",
    ".github/workflows/ci.yml",
  ];
  for (const entry of relevant) {
    assert.deepEqual(
      classify({ eventName: PR, paths: [entry] }),
      { run: true, reason: "relevant-path" },
      entry,
    );
  }
});

test("one relevant path among irrelevant ones runs the matrix", () => {
  const result = classify({
    eventName: PR,
    paths: ["website/index.html", ".planning/STATE.md", "docs/a.md", "lib/x.ex", "README.md"],
  });
  assert.deepEqual(result, { run: true, reason: "relevant-path" });
});

test("near misses of the relevant list do not match", () => {
  const nearMisses = [
    "library/x.ex",
    "scrypath_ops/lib/x.ex",
    "examples/phoenix_meilisearch/lib/x.ex",
    "website/test/x.mjs",
    "docs/test/x.md",
    "mix.exs.bak",
    "xmix.exs",
    "sub/mix.lock",
    ".github/workflows/ci.yml.disabled",
    ".github/workflows/ci.yaml",
    "lib",
    "test",
    "x/lib/y.ex",
  ];
  for (const nearMiss of nearMisses) {
    assert.deepEqual(
      classify({ eventName: PR, paths: [nearMiss] }),
      { run: false, reason: "no-relevant-path" },
      nearMiss,
    );
  }
});

test("an empty diff runs the matrix", () => {
  for (const paths of [[], [""], ["", ""], undefined, null, "website/x.html", [null, 7, ""]]) {
    assert.deepEqual(classify({ eventName: PR, paths }), { run: true, reason: "empty-diff" });
  }
});

test("an entry that is not a usable path runs the matrix even beside irrelevant paths", () => {
  for (const paths of [
    ["website/a.html", { path: "website/b.html" }, 42],
    ["website/a.html", ""],
    ["docs/x.md", null],
  ]) {
    assert.deepEqual(classify({ eventName: PR, paths }), { run: true, reason: "unusable-path" });
  }
});

test("every event other than pull_request runs the matrix", () => {
  for (const eventName of ["push", "schedule", "workflow_dispatch", "merge_group", "", undefined]) {
    assert.deepEqual(classify({ eventName, paths: ["website/x.html"] }), {
      run: true,
      reason: "non-pull-request-event",
    });
  }
  assert.deepEqual(classify(), { run: true, reason: "non-pull-request-event" });
});

test("the regex is not stateful across repeated matches", () => {
  for (let index = 0; index < 5; index += 1) {
    assert.equal(RELEVANT_PATTERN.test("lib/a.ex"), true);
  }
});

// --- the denylist cannot silently skip a new top-level path --------------------------------
//
// The matrix is skipped when no path is relevant, so a NEW top-level directory would be skipped
// by default. This inventory makes adding one a conscious decision: every tracked top-level entry
// must be listed here as either compiled or executed by the root suite (relevant) or not (listed
// as irrelevant with the reason). A new entry fails this test until it is placed on a side.

const RELEVANT_ENTRIES = ["lib", "dev", "test", "config", "priv", "scripts", "mix.exs", "mix.lock"];

const IRRELEVANT_ENTRIES = {
  ".credo.exs": "lint configuration, not part of the compile and test run",
  ".dockerignore": "Docker build context for the demo images",
  ".formatter.exs": "formatter configuration, checked by core",
  ".github": "workflows other than ci.yml and repository templates; ci.yml is matched by path",
  ".gitignore": "ignore rules",
  ".impeccable": "design tooling state",
  ".planning": "planning records",
  ".release-please-manifest.json": "release metadata",
  "AGENTS.md": "agent instructions",
  "ARCHITECTURE.md": "documentation",
  "CHANGELOG.md": "documentation",
  CODEOWNERS: "review routing",
  "CONTRIBUTING.md": "documentation",
  "DESIGN.md": "documentation",
  "GEMINI.md": "agent instructions",
  "GLOSSARY.md": "documentation",
  LICENSE: "license text",
  "PRODUCT.md": "documentation",
  "README.md": "documentation",
  "SECURITY.md": "documentation",
  bench: "benchmarks, not compiled by the test environment",
  brand: "brand assets and tokens",
  "compose.yaml": "demo stack definition",
  docs: "documentation",
  examples: "separate Mix projects with their own lanes",
  guides: "documentation",
  prompts: "maintainer reference material",
  "release-please-config.json": "release metadata",
  scrypath_ops: "separate Mix project with its own ops-ui lane",
  website: "static site with its own workflow",
};

function git(cwd, ...args) {
  return execFileSync("git", args, { cwd, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
}

test("every tracked top-level entry is classified as relevant or irrelevant", () => {
  const tracked = git(repositoryRoot, "ls-files", "-z").split("\0").filter((entry) => entry !== "");
  assert.ok(tracked.length > 0, "expected a Git checkout with tracked files");

  const topLevel = [...new Set(tracked.map((entry) => entry.split("/")[0]))].sort();
  const known = new Set([...RELEVANT_ENTRIES, ...Object.keys(IRRELEVANT_ENTRIES)]);
  const unclassified = topLevel.filter((entry) => !known.has(entry));
  assert.deepEqual(
    unclassified,
    [],
    "a new top-level entry must be listed in RELEVANT_ENTRIES (and RELEVANT_PATTERN) or IRRELEVANT_ENTRIES " +
      "in scripts/ci/compat_path_classifier.test.cjs: the compatibility matrix is skipped for paths nobody classified",
  );

  // The two lists agree with the real pattern, for each entry as a file and as a directory.
  for (const entry of RELEVANT_ENTRIES) {
    const samples = entry.includes(".") ? [entry] : [`${entry}/x`];
    for (const sample of samples) {
      assert.equal(RELEVANT_PATTERN.test(sample), true, `${sample} must be relevant`);
    }
  }
  for (const entry of Object.keys(IRRELEVANT_ENTRIES)) {
    for (const sample of [entry, `${entry}/x`]) {
      assert.equal(RELEVANT_PATTERN.test(sample), false, `${sample} must not be relevant`);
    }
  }
  assert.equal(RELEVANT_PATTERN.test(".github/workflows/ci.yml"), true);
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

function sandboxGit(cwd, ...args) {
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
  sandboxGit(repo, "add", "-A");
  sandboxGit(repo, "commit", "-q", "-m", message);
}

// A base commit on `main` with a fake `origin/main`, then a `pr` branch for the commits under test.
function makeRepo(t, { withOriginRef = true } = {}) {
  const repo = tempDirectory(t, "scrypath-compat-classifier-repo-");
  sandboxGit(repo, "init", "-q", "-b", "main");
  write(repo, "lib/x.ex", "defmodule X do\nend\n");
  write(repo, "README.md", "# base\n");
  commitAll(repo, "base");
  if (withOriginRef) sandboxGit(repo, "update-ref", "refs/remotes/origin/main", "HEAD");
  sandboxGit(repo, "checkout", "-q", "-b", "pr");
  return repo;
}

// Runs the CLI from a directory that is not the repository, pointing at it with --cwd.
function runCli(t, { repo, event = PR, baseRef = "main", extraArgs = [] } = {}) {
  const work = tempDirectory(t, "scrypath-compat-classifier-out-");
  const output = path.join(work, "github_output");
  writeFileSync(output, "");
  const args = [scriptPath, "--output", output];
  if (repo !== undefined) args.push("--cwd", repo);
  args.push(...extraArgs);
  const childEnv = sanitizedEnv();
  if (event !== null) childEnv.GITHUB_EVENT_NAME = event;
  if (baseRef !== null) childEnv.GITHUB_BASE_REF = baseRef;
  const completed = spawnSync(process.execPath, args, { cwd: work, env: childEnv, encoding: "utf8" });
  return {
    status: completed.status,
    stderr: completed.stderr,
    output: readFileSync(output, "utf8"),
  };
}

const SKIP = "run=false\nreason=no-relevant-path\n";

test("CLI: a website-only commit skips", (t) => {
  const repo = makeRepo(t);
  write(repo, "website/index.html");
  write(repo, "docs/guide.md");
  commitAll(repo, "website and docs");
  const result = runCli(t, { repo });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.output, SKIP);
});

test("CLI: a lib/ commit runs the matrix", (t) => {
  const repo = makeRepo(t);
  write(repo, "website/index.html");
  write(repo, "lib/y.ex");
  commitAll(repo, "website and code");
  const result = runCli(t, { repo });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.output, "run=true\nreason=relevant-path\n");
});

test("CLI: a rename out of lib/ into docs/ still runs the matrix", (t) => {
  const repo = makeRepo(t);
  mkdirSync(path.join(repo, "docs"), { recursive: true });
  sandboxGit(repo, "mv", "lib/x.ex", "docs/x.md");
  sandboxGit(repo, "commit", "-q", "-m", "move code into docs");
  const result = runCli(t, { repo });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.output, "run=true\nreason=relevant-path\n");
});

test("CLI: an empty diff runs the matrix", (t) => {
  const repo = makeRepo(t);
  const result = runCli(t, { repo });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.output, "run=true\nreason=empty-diff\n");
});

test("CLI: a missing origin ref runs the matrix and exits 0", (t) => {
  const repo = makeRepo(t, { withOriginRef: false });
  write(repo, "website/index.html");
  commitAll(repo, "website");
  const result = runCli(t, { repo });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.output, "run=true\nreason=diff-error\n");
});

test("CLI: a missing paths file runs the matrix and exits 0", (t) => {
  const result = runCli(t, {
    extraArgs: ["--paths-file", path.join(os.tmpdir(), "scrypath-no-such-compat-paths-file")],
  });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.output, "run=true\nreason=diff-error\n");
});

test("CLI: a pull request without a base ref runs the matrix and exits 0", (t) => {
  const repo = makeRepo(t);
  write(repo, "website/index.html");
  commitAll(repo, "website");
  const result = runCli(t, { repo, baseRef: null });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.output, "run=true\nreason=diff-error\n");
});

test("CLI: an unknown or incomplete argument runs the matrix and exits 0", (t) => {
  for (const extraArgs of [["--bogus"], ["--head"], ["--paths-file"]]) {
    const result = runCli(t, { extraArgs });
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.output, "run=true\nreason=diff-error\n", extraArgs.join(" "));
  }
});

test("CLI: non-pull-request events run the matrix even for a website-only diff", (t) => {
  const work = tempDirectory(t, "scrypath-compat-classifier-events-");
  const pathsFile = path.join(work, "paths");
  writeFileSync(pathsFile, "website/index.html\0");

  for (const event of ["push", "schedule", "workflow_dispatch", "merge_group", null]) {
    const result = runCli(t, { event, extraArgs: ["--paths-file", pathsFile] });
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.output, "run=true\nreason=non-pull-request-event\n", String(event));
  }
});

test("CLI: output is appended and stdout is used when no output file is given", (t) => {
  const work = tempDirectory(t, "scrypath-compat-classifier-append-");
  const pathsFile = path.join(work, "paths");
  const output = path.join(work, "github_output");
  writeFileSync(pathsFile, "website/index.html\0");
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
  const work = tempDirectory(t, "scrypath-compat-classifier-unwritable-");
  const pathsFile = path.join(work, "paths");
  writeFileSync(pathsFile, "website/index.html\0");
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
  write(repo, "website/a\nrun=false.html");
  write(repo, "lib/y.ex");
  commitAll(repo, "injection attempt beside code");
  const result = runCli(t, { repo });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.output, "run=true\nreason=relevant-path\n");
  for (const line of result.stderr.split("\n").filter((entry) => entry !== "")) {
    assert.ok(line.startsWith("compat-path: "), `unprefixed log line: ${line}`);
  }
});

test("CLI: a hostile irrelevant file name still yields only the two fixed lines", (t) => {
  const repo = makeRepo(t);
  write(repo, "website/a\nrun=true\nreason=injected.html");
  commitAll(repo, "newline in an irrelevant name");
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
