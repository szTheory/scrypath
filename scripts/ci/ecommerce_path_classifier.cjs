"use strict";

// Decides whether the browser lanes (`ecommerce-mounted` and the Node step of
// `repository-contracts`) can be skipped for a pull request.
//
// This is an ALLOWLIST that fails open. The lanes are skipped only when the event is
// a pull_request and EVERY changed path is under `.planning/`, under `docs/`, or a
// root-level markdown file. Everything else runs the lanes: any other path, an empty
// diff, a diff that cannot be computed, any error, and every non-pull_request event.
//
// Output contract (the only thing the workflow reads): the output file, or stdout when
// no file is given, receives exactly two lines, `run=<true|false>` and
// `reason=<fixed vocabulary word>`. Changed paths are attacker-controlled (a newline in
// a file name could otherwise inject `run=false` into $GITHUB_OUTPUT), so paths and
// error text only ever go to stderr, JSON-quoted and truncated.

const { execFileSync } = require("node:child_process");
const fs = require("node:fs");

// Verbatim allowlist; keep this literal greppable and identical to the CI-01 requirement.
// No `g`, `y` or `m` flag: a stateful regex makes `.test` flaky across paths, and `m` would
// let `$` match before an embedded newline.
const SKIPPABLE_PATTERN = new RegExp(String.raw`^(\.planning/|docs/|[^/]+\.md$)`);

const REASONS = Object.freeze({
  nonPullRequestEvent: "non-pull-request-event",
  emptyDiff: "empty-diff",
  nonAllowlistedPath: "non-allowlisted-path",
  allPathsAllowlisted: "all-paths-allowlisted",
  diffError: "diff-error",
});

const MAX_DIFF_BYTES = 64 * 1024 * 1024;
const MAX_LOG_CHARS = 200;

/**
 * Pure decision. Order matters: (1) any event other than exactly `pull_request` runs;
 * (2) an empty list, or a list with no usable entry, runs; (3) any entry that is not a
 * non-empty string, and any path that fails the allowlist, runs; (4) otherwise skip.
 */
function classify({ eventName, paths } = {}) {
  if (eventName !== "pull_request") {
    return { run: true, reason: REASONS.nonPullRequestEvent };
  }

  const candidates = Array.isArray(paths)
    ? paths.filter((entry) => typeof entry === "string" && entry !== "")
    : [];

  if (candidates.length === 0) {
    return { run: true, reason: REASONS.emptyDiff };
  }

  // An entry that is not a usable path is unexpected input, not something to ignore: run.
  if (candidates.length !== paths.length) {
    return { run: true, reason: REASONS.nonAllowlistedPath };
  }

  if (candidates.some((entry) => !SKIPPABLE_PATTERN.test(entry))) {
    return { run: true, reason: REASONS.nonAllowlistedPath };
  }

  return { run: false, reason: REASONS.allPathsAllowlisted };
}

function diffNames({ baseRef, head, cwd }) {
  // `--no-renames` lists a move as a delete plus an add, so moving lib/x.ex to docs/x.md
  // still reports the old lib/ path. `-z` keeps unusual file names intact.
  const output = execFileSync(
    "git",
    ["diff", "--name-only", "--no-renames", "-z", `origin/${baseRef}...${head}`, "--"],
    {
      cwd,
      encoding: "utf8",
      maxBuffer: MAX_DIFF_BYTES,
      stdio: ["ignore", "pipe", "pipe"],
    },
  );
  return output.split("\0").filter((entry) => entry !== "");
}

/**
 * Changed paths of `<head>` against `origin/<baseRef>` (three-dot, like ops-ui-path). One
 * `git fetch --no-tags origin <baseRef>` retry when the first diff fails (for example the
 * remote-tracking ref is missing). No `--depth`: a depth-1 fetch into the full-history
 * checkout can truncate the merge base. A second failure propagates to `main`.
 */
function changedPathsFromGit({ baseRef, head = "HEAD", cwd } = {}) {
  if (typeof baseRef !== "string" || baseRef === "" || baseRef.startsWith("-")) {
    throw new Error("missing or unusable base ref");
  }

  try {
    return diffNames({ baseRef, head, cwd });
  } catch (firstError) {
    try {
      execFileSync("git", ["fetch", "--no-tags", "origin", baseRef], {
        cwd,
        stdio: ["ignore", "ignore", "pipe"],
      });
    } catch {
      throw firstError;
    }
    return diffNames({ baseRef, head, cwd });
  }
}

function parseArgs(argv) {
  const options = { output: null, pathsFile: null, cwd: undefined, head: "HEAD" };
  const takesValue = new Map([
    ["--output", "output"],
    ["--paths-file", "pathsFile"],
    ["--cwd", "cwd"],
    ["--head", "head"],
  ]);

  for (let index = 0; index < argv.length; index += 1) {
    const key = takesValue.get(argv[index]);
    if (key === undefined || index + 1 >= argv.length) {
      throw new Error("unsupported or incomplete argument");
    }
    options[key] = argv[index + 1];
    index += 1;
  }

  return options;
}

function pathsFromFile(file) {
  return fs
    .readFileSync(file, "utf8")
    .split("\0")
    .filter((entry) => entry !== "");
}

function logLine(message) {
  // Prefixed so a log line can never start with `::` and be read as a workflow command,
  // and JSON-quoted by callers so an embedded newline cannot start a second line.
  process.stderr.write(`ecommerce-path: ${message}\n`);
}

function quoted(value) {
  const text = typeof value === "string" ? value : String(value);
  const clipped = text.length > MAX_LOG_CHARS ? `${text.slice(0, MAX_LOG_CHARS)}...` : text;
  return JSON.stringify(clipped);
}

function decide(argv, env) {
  const options = parseArgs(argv);
  const eventName = env.GITHUB_EVENT_NAME;

  if (eventName !== "pull_request") {
    return classify({ eventName, paths: [] });
  }

  const baseRef = env.GITHUB_BASE_REF;
  if (typeof baseRef !== "string" || baseRef === "") {
    throw new Error("pull_request event without GITHUB_BASE_REF");
  }

  const paths =
    options.pathsFile === null
      ? changedPathsFromGit({ baseRef, head: options.head, cwd: options.cwd })
      : pathsFromFile(options.pathsFile);

  const result = classify({ eventName, paths });
  if (result.reason === REASONS.nonAllowlistedPath) {
    const offender = paths.find(
      (entry) => typeof entry === "string" && entry !== "" && !SKIPPABLE_PATTERN.test(entry),
    );
    logLine(`first non-allowlisted path ${quoted(offender)}`);
  }
  return result;
}

/**
 * CLI entry. Everything that can fail sits inside one try/catch: any thrown error becomes
 * run=true, reason=diff-error and the process still exits 0 so the step succeeds and the
 * lanes run. A failure to write the output file exits 1 instead, which fails the job; the
 * workflow consumers treat a non-success classifier as "run the lanes" too.
 */
function main(argv = process.argv.slice(2), env = process.env) {
  let result;
  // Found separately from parseArgs so a bad argument elsewhere still reports into the output file.
  const outputIndex = argv.indexOf("--output");
  const outputFile = outputIndex >= 0 && outputIndex + 1 < argv.length ? argv[outputIndex + 1] : null;

  try {
    result = decide(argv, env);
  } catch (error) {
    logLine(`diff-error ${quoted(error && error.message)}`);
    result = { run: true, reason: REASONS.diffError };
  }

  const text = `run=${result.run ? "true" : "false"}\nreason=${result.reason}\n`;
  try {
    if (outputFile === null) {
      process.stdout.write(text);
    } else {
      fs.appendFileSync(outputFile, text);
    }
  } catch (error) {
    logLine(`could not write output ${quoted(error && error.message)}`);
    return 1;
  }

  logLine(`run=${result.run} reason=${result.reason}`);
  return 0;
}

module.exports = { SKIPPABLE_PATTERN, REASONS, classify, changedPathsFromGit, main };

if (require.main === module) {
  process.exitCode = main();
}
