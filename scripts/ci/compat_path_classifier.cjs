"use strict";

// Decides whether the advisory `compatibility` matrix (four Elixir/OTP cells, about 28 runner
// minutes) can be skipped for a pull request.
//
// The matrix answers one question: does the library still compile and pass the root test suite on
// the supported Elixir and OTP versions. Only paths that the BEAM compiles or executes can change
// that answer. A pull request whose changed paths all sit outside RELEVANT_PATTERN (docs, website,
// brand, planning notes, the separate ScrypathOps app, the demo app) cannot, so the cells are skipped.
//
// It fails open, like `ecommerce_path_classifier.cjs`. The cells RUN for every event other than
// `pull_request` (push to main, schedule, workflow_dispatch, merge_group), for an empty diff, for a
// diff that cannot be computed, for any error, and for any pull request that touches one relevant
// path. Only a pull request with a non-empty diff and no relevant path reports run=false.
//
// Output contract (the only thing the workflow reads): the output file, or stdout when no file is
// given, receives exactly two lines, `run=<true|false>` and `reason=<fixed vocabulary word>`. Changed
// paths are attacker-controlled, so paths and error text only ever go to stderr, JSON-quoted and
// truncated, behind a fixed prefix.

const fs = require("node:fs");
const { changedPathsFromGit } = require("./ecommerce_path_classifier.cjs");

// A path that can change what the matrix proves. Verbatim, greppable, and mirrored by the tracked
// top-level inventory test, which makes a new top-level entry choose a side instead of defaulting
// to "skip". No `g`, `y` or `m` flag: a stateful regex makes `.test` flaky across paths, and `m`
// would let `$` match before an embedded newline.
//
// Reasons for each entry: lib/ is the library; dev/ holds the Mix tasks compiled into the test
// environment (`elixirc_paths(:test)`); test/ is the suite the cells run; config/, priv/, mix.exs and
// mix.lock change compilation and dependencies; scripts/ is executed by tests inside the suite
// (`scripts/ci/*.test.cjs`, `scripts/ci_monitor.cjs`); ci.yml defines the matrix itself.
const RELEVANT_PATTERN = new RegExp(
  String.raw`^(lib/|dev/|test/|config/|priv/|scripts/|mix\.exs$|mix\.lock$|\.github/workflows/ci\.yml$)`,
);

const REASONS = Object.freeze({
  nonPullRequestEvent: "non-pull-request-event",
  emptyDiff: "empty-diff",
  unusablePath: "unusable-path",
  relevantPath: "relevant-path",
  noRelevantPath: "no-relevant-path",
  diffError: "diff-error",
});

const MAX_LOG_CHARS = 200;

/**
 * Pure decision. Order matters: (1) any event other than exactly `pull_request` runs; (2) an empty
 * list, or a list with no usable entry, runs; (3) any entry that is not a non-empty string runs;
 * (4) any relevant path runs; (5) otherwise skip.
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
    return { run: true, reason: REASONS.unusablePath };
  }

  if (candidates.some((entry) => RELEVANT_PATTERN.test(entry))) {
    return { run: true, reason: REASONS.relevantPath };
  }

  return { run: false, reason: REASONS.noRelevantPath };
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
  // Prefixed so a log line can never start with `::` and be read as a workflow command, and
  // JSON-quoted by callers so an embedded newline cannot start a second line.
  process.stderr.write(`compat-path: ${message}\n`);
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
  if (result.reason === REASONS.relevantPath) {
    const first = paths.find((entry) => typeof entry === "string" && RELEVANT_PATTERN.test(entry));
    logLine(`first relevant path ${quoted(first)}`);
  }
  return result;
}

/**
 * CLI entry. Everything that can fail sits inside one try/catch: any thrown error becomes run=true,
 * reason=diff-error and the process still exits 0 so the step succeeds and the cells run. A failure
 * to write the output file exits 1 instead, which fails the job; the workflow consumer treats a
 * non-success classifier as "run the cells" too.
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

module.exports = { RELEVANT_PATTERN, REASONS, classify, main };

if (require.main === module) {
  process.exitCode = main();
}
