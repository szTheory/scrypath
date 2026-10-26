const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const {
  chmodSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const repositoryRoot = path.resolve(__dirname, "../..");
const verifierSource = path.join(
  repositoryRoot,
  "examples/scrypath_ecommerce/scripts/verify-e2e.sh",
);
const browserSource = path.join(
  repositoryRoot,
  "examples/scrypath_ecommerce/docker-playwright.sh",
);

function tempDirectory(t) {
  const directory = mkdtempSync(path.join(os.tmpdir(), "scrypath-e2e-lifecycle-"));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  return directory;
}

function installDockerDouble(root) {
  const binDirectory = path.join(root, "bin");
  mkdirSync(binDirectory, { recursive: true });
  const logPath = path.join(root, "docker.jsonl");
  const dockerPath = path.join(binDirectory, "docker");
  writeFileSync(
    dockerPath,
    `#!/usr/bin/env node
const fs = require("node:fs");
const args = process.argv.slice(2);
fs.appendFileSync(process.env.FAKE_DOCKER_LOG, JSON.stringify(args) + "\\n");
if (process.env.FAKE_DOCKER_CONFIG_FAIL === "1" && args[0] === "compose" && args.includes("config")) process.exit(18);
if (args[0] === "compose" && args.includes("logs")) process.stdout.write("fake compose diagnostics\\n");
`,
  );
  chmodSync(dockerPath, 0o755);
  return { binDirectory, logPath };
}

function dockerCalls(logPath) {
  if (!existsSync(logPath)) return [];
  return readFileSync(logPath, "utf8")
    .trim()
    .split("\n")
    .filter(Boolean)
    .map((line) => JSON.parse(line));
}

function runVerifier(t, args, extraEnv = {}) {
  const root = tempDirectory(t);
  const exampleDirectory = path.join(root, "example");
  const scriptDirectory = path.join(exampleDirectory, "scripts");
  mkdirSync(scriptDirectory, { recursive: true });
  const scriptPath = path.join(scriptDirectory, "verify-e2e.sh");
  writeFileSync(scriptPath, readFileSync(verifierSource));

  const { binDirectory, logPath } = installDockerDouble(root);
  const result = spawnSync("bash", [scriptPath, ...args], {
    cwd: exampleDirectory,
    encoding: "utf8",
    env: {
      ...process.env,
      PATH: `${binDirectory}${path.delimiter}${process.env.PATH}`,
      FAKE_DOCKER_LOG: logPath,
      ...extraEnv,
    },
  });
  return { ...result, calls: dockerCalls(logPath) };
}

function composeProjectCalls(calls) {
  return calls.filter((call) => call[0] === "compose" && call.includes("-p"));
}

function composeFiles(call) {
  const files = [];
  for (let index = 0; index < call.length; index += 1) {
    if (call[index] === "-f") files.push(call[index + 1]);
  }
  return files;
}

function installBrowserDoubles(root) {
  const binDirectory = path.join(root, "bin");
  mkdirSync(binDirectory, { recursive: true });
  const curlLog = path.join(root, "curl.log");
  const browserLog = path.join(root, "browser.log");
  const curlPath = path.join(binDirectory, "curl");
  const npmPath = path.join(binDirectory, "npm");
  const npxPath = path.join(binDirectory, "npx");

  writeFileSync(
    curlPath,
    `#!/usr/bin/env node
const fs = require("node:fs");
const args = process.argv.slice(2);
const url = args.at(-1) || "";
fs.appendFileSync(process.env.FAKE_CURL_LOG, url + "\\n");
if (process.env.FAKE_CURL_FAIL_URL === url) process.exit(22);
`,
  );
  writeFileSync(
    npmPath,
    `#!/usr/bin/env node
require("node:fs").appendFileSync(process.env.FAKE_BROWSER_LOG, "npm " + process.argv.slice(2).join(" ") + "\\n");
`,
  );
  writeFileSync(
    npxPath,
    `#!/usr/bin/env node
require("node:fs").appendFileSync(process.env.FAKE_BROWSER_LOG, "npx " + process.argv.slice(2).join(" ") + "\\n");
`,
  );
  for (const command of [curlPath, npmPath, npxPath]) chmodSync(command, 0o755);
  return { binDirectory, curlLog, browserLog };
}

function runBrowser(t, extraEnv = {}) {
  const root = tempDirectory(t);
  const { binDirectory, curlLog, browserLog } = installBrowserDoubles(root);
  const result = spawnSync("bash", [browserSource], {
    cwd: path.dirname(browserSource),
    encoding: "utf8",
    env: {
      ...process.env,
      PATH: `${binDirectory}${path.delimiter}${process.env.PATH}`,
      FAKE_CURL_LOG: curlLog,
      FAKE_BROWSER_LOG: browserLog,
      E2E_SCOPE: "full",
      E2E_READINESS_ONLY: "1",
      E2E_READINESS_TIMEOUT_SECONDS: "2",
      E2E_CURL_TIMEOUT_SECONDS: "1",
      PLAYWRIGHT_BASE_URL: "http://web:4002",
      CONTRAST_REPORT_DIR: path.join(root, "contrast-results"),
      ...extraEnv,
    },
  });
  return {
    ...result,
    curlUrls: existsSync(curlLog) ? readFileSync(curlLog, "utf8").trim().split("\n") : [],
    browserInvocations: existsSync(browserLog) ? readFileSync(browserLog, "utf8") : "",
  };
}

test("full readiness diagnostic uses the full overlay without claiming browser acceptance", (t) => {
  const result = runVerifier(t, ["full", "--readiness-only"]);
  assert.equal(result.status, 0, result.stderr);

  const calls = composeProjectCalls(result.calls);
  assert.ok(calls.length > 0, "expected owned Compose calls");
  assert.ok(
    calls.every((call) => composeFiles(call).includes("compose.phase173.yaml")),
    "every full-scope Compose operation must include the Phase 173 overlay",
  );
  const projects = new Set(calls.map((call) => call[call.indexOf("-p") + 1]));
  assert.equal(projects.size, 1, "config, execution, diagnostics and teardown share one project");
  assert.match(result.stdout, /readiness-only diagnostic/i);
  assert.doesNotMatch(result.stdout, /Docker verifier passed|full browser.*passed/i);
});

test("focused verification keeps its existing Compose service scope", (t) => {
  const result = runVerifier(t, ["focused"]);
  assert.equal(result.status, 0, result.stderr);
  const calls = composeProjectCalls(result.calls);
  assert.ok(calls.some((call) => call.includes("config")));
  assert.ok(calls.some((call) => call.includes("up")));
  assert.ok(calls.every((call) => !composeFiles(call).includes("compose.phase173.yaml")));
});

test("full readiness checks both Ops fixture routes before running Playwright", (t) => {
  const result = runBrowser(t);
  assert.equal(result.status, 0, result.stderr);
  assert.ok(
    result.curlUrls.includes("http://web:4002/admin/search/phase173/health"),
    "mounted Ops fixture route must be probed from the browser network",
  );
  assert.ok(
    result.curlUrls.includes("http://standalone_ops:4003/ops/phase173/health"),
    "standalone Ops fixture route must be probed from the browser network",
  );
  assert.match(result.stdout, /readiness-only diagnostic/i);
  assert.equal(result.browserInvocations, "", "readiness diagnostics must not execute browser suites");
});

test("full readiness fails when either Ops fixture route stays unavailable", (t) => {
  const result = runBrowser(t, {
    FAKE_CURL_FAIL_URL: "http://standalone_ops:4003/ops/phase173/health",
  });
  assert.notEqual(result.status, 0, "missing standalone readiness must fail");
  assert.match(result.stderr, /standalone.*fixture route|standalone_ops.*health/i);
  assert.equal(result.browserInvocations, "", "browser suites cannot run after route readiness fails");
});

test("unsupported verifier arguments and Compose config failures return nonzero", (t) => {
  const unsupported = runVerifier(t, ["full", "--unknown"]);
  assert.notEqual(unsupported.status, 0, "unsupported arguments must be rejected");

  const invalidConfig = runVerifier(t, ["full"], { FAKE_DOCKER_CONFIG_FAIL: "1" });
  assert.notEqual(invalidConfig.status, 0, "invalid merged Compose config must fail");
});
