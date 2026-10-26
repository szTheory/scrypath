const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const {
  chmodSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readdirSync,
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
  const gitPath = path.join(binDirectory, "git");
  writeFileSync(
    dockerPath,
    `#!/usr/bin/env node
const fs = require("node:fs");
const args = process.argv.slice(2);
fs.appendFileSync(process.env.FAKE_DOCKER_LOG, JSON.stringify(args) + "\\n");
if (process.env.FAKE_DOCKER_CONFIG_FAIL === "1" && args[0] === "compose" && args.includes("config")) process.exit(18);
if (args[0] === "compose" && args.includes("up") && process.env.FAKE_DOCKER_UP_FAIL) process.exit(Number(process.env.FAKE_DOCKER_UP_FAIL));
if (args[0] === "compose" && args.includes("run") && process.env.FAKE_DOCKER_RUN_FAIL) process.exit(Number(process.env.FAKE_DOCKER_RUN_FAIL));
if (args[0] === "compose" && args.includes("down") && process.env.FAKE_DOCKER_DOWN_FAIL) process.exit(Number(process.env.FAKE_DOCKER_DOWN_FAIL));
if (args[0] === "compose" && args.includes("logs")) process.stdout.write("fake compose diagnostics\\n");
if (args[0] === "compose" && args.includes("ps") && process.env.FAKE_BROWSER_CONTAINER === "1") process.stdout.write("browser-container\\n");
if (args[0] === "cp" && process.env.FAKE_DOCKER_CP_FAIL === "1") process.exit(42);
if (args[0] === "ps" && process.env.FAKE_LEAK_CONTAINER === "1") process.stdout.write("owned-container\\n");
if (args[0] === "volume" && process.env.FAKE_LEAK_VOLUME === "1") process.stdout.write("owned-volume\\n");
if (args[0] === "network" && process.env.FAKE_LEAK_NETWORK === "1") process.stdout.write("owned-network\\n");
`,
  );
  writeFileSync(
    gitPath,
    `#!/usr/bin/env node
const args = process.argv.slice(2);
if (args.join(" ") === "rev-parse --short=8 HEAD") process.stdout.write("deadbeef\\n");
else if (args.join(" ") === "rev-parse HEAD") process.stdout.write("deadbeef00000000000000000000000000000000\\n");
else process.exit(2);
`,
  );
  chmodSync(dockerPath, 0o755);
  chmodSync(gitPath, 0o755);
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
  const artifactRoot = path.join(exampleDirectory, "test-results");
  const artifactDirectory = existsSync(artifactRoot)
    ? path.join(artifactRoot, readdirSync(artifactRoot)[0])
    : null;
  const lifecyclePath = artifactDirectory && path.join(artifactDirectory, "lifecycle.json");
  const lifecycle = lifecyclePath && existsSync(lifecyclePath)
    ? JSON.parse(readFileSync(lifecyclePath, "utf8"))
    : null;
  return { ...result, calls: dockerCalls(logPath), artifactDirectory, lifecycle };
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
      E2E_READINESS_TIMEOUT_SECONDS: "5",
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
  const build = calls.find((call) => call.includes("build"));
  assert.ok(build, "readiness diagnostics must build the actual full-stack images");
  for (const service of ["web", "standalone_ops", "browser"]) {
    assert.ok(build.includes(service), `readiness build must include ${service}`);
  }
  const browserRun = calls.find((call) => call.includes("run"));
  assert.ok(browserRun, "readiness diagnostics must execute the browser service");
  assert.ok(browserRun.includes("E2E_READINESS_ONLY=1"), "the browser service must receive diagnostic mode explicitly");
  assert.equal(browserRun.at(-1), "browser");
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

test("full browser execution starts only after both Ops fixture routes respond", (t) => {
  const result = runBrowser(t, { E2E_READINESS_ONLY: "0" });
  assert.equal(result.status, 0, result.stderr);
  const mountedIndex = result.stdout.indexOf("Mounted Ops fixture route is ready");
  const standaloneIndex = result.stdout.indexOf("Standalone Ops fixture route is ready");
  const browserIndex = result.stdout.indexOf("Running the full advisory ecommerce browser");
  assert.ok(mountedIndex >= 0 && standaloneIndex >= 0, "both route checks must complete");
  assert.ok(browserIndex > mountedIndex && browserIndex > standaloneIndex, "browser execution must follow both route checks");
  assert.match(result.browserInvocations, /npm run test:e2e/);
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
  assert.equal(invalidConfig.status, 18, "later finalization errors cannot replace the config failure");
  assert.ok(invalidConfig.lifecycle, "config failures must still produce lifecycle evidence");
  assert.equal(invalidConfig.lifecycle.original_exit_status, 18);
});

test("browser failure stays primary when artifact copies and Compose down also fail", (t) => {
  const result = runVerifier(t, ["full"], {
    FAKE_DOCKER_UP_FAIL: "31",
    FAKE_BROWSER_CONTAINER: "1",
    FAKE_DOCKER_CP_FAIL: "1",
    FAKE_DOCKER_DOWN_FAIL: "43",
  });
  assert.equal(result.status, 31, result.stderr);
  assert.ok(result.lifecycle, "the verifier must write lifecycle evidence before teardown completes");
  assert.equal(result.lifecycle.original_exit_status, 31);
  assert.equal(result.lifecycle.artifact_copy_status, "failed");
  assert.equal(result.lifecycle.cleanup.status, "failed");
  const logIndex = result.calls.findIndex((call) => call.includes("logs"));
  const downIndex = result.calls.findIndex((call) => call.includes("down"));
  assert.ok(logIndex >= 0 && downIndex > logIndex, "diagnostics must be collected before teardown");
  assert.equal(result.calls.filter((call) => call[0] === "cp").length, 2);
});

test("artifact copy failure makes an otherwise successful verification fail", (t) => {
  const result = runVerifier(t, ["full"], {
    FAKE_BROWSER_CONTAINER: "1",
    FAKE_DOCKER_CP_FAIL: "1",
  });
  assert.equal(result.status, 74, result.stderr);
  assert.equal(result.lifecycle.original_exit_status, 0);
  assert.equal(result.lifecycle.artifact_copy_status, "failed");
  assert.equal(result.lifecycle.cleanup.status, "clean");
});

test("Compose down failure makes an otherwise successful verification fail", (t) => {
  const result = runVerifier(t, ["full"], { FAKE_DOCKER_DOWN_FAIL: "43" });
  assert.equal(result.status, 75, result.stderr);
  assert.equal(result.lifecycle.original_exit_status, 0);
  assert.equal(result.lifecycle.cleanup.status, "failed");
});

test("owned network or volume leaks fail success while every query is project-scoped", (t) => {
  for (const [envKey, resource] of [["FAKE_LEAK_NETWORK", "networks"], ["FAKE_LEAK_VOLUME", "volumes"]]) {
    const result = runVerifier(t, ["full"], { [envKey]: "1" });
    assert.equal(result.status, 75, result.stderr);
    assert.equal(result.lifecycle.cleanup.status, "failed");
    assert.equal(result.lifecycle.cleanup[resource], 1);
    const resourceCalls = result.calls.filter((call) =>
      call[0] === "ps" || (call[0] === "volume" && call[1] === "ls") || (call[0] === "network" && call[1] === "ls"),
    );
    assert.ok(resourceCalls.length >= 3, "containers, networks and volumes must all be inspected");
    for (const call of resourceCalls) {
      assert.ok(call.includes(`label=com.docker.compose.project=${result.lifecycle.cleanup.project}`));
      assert.ok(!call.includes("unowned-sentinel"));
    }
  }
});

test("successful verification records readiness and confirms owned resources are gone", (t) => {
  const result = runVerifier(t, ["full"]);
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.lifecycle.original_exit_status, 0);
  assert.equal(result.lifecycle.readiness.status, "passed");
  assert.equal(result.lifecycle.readiness.routes.mounted_ops, "passed");
  assert.equal(result.lifecycle.readiness.routes.standalone_ops, "passed");
  assert.equal(result.lifecycle.cleanup.status, "clean");
  assert.equal(result.lifecycle.cleanup.containers, 0);
  assert.equal(result.lifecycle.cleanup.networks, 0);
  assert.equal(result.lifecycle.cleanup.volumes, 0);
});

test("KEEP_E2E_STACK preserves the owned project and is reported as not clean", (t) => {
  const result = runVerifier(t, ["full"], {
    KEEP_E2E_STACK: "1",
    FAKE_LEAK_CONTAINER: "1",
    FAKE_LEAK_NETWORK: "1",
    FAKE_LEAK_VOLUME: "1",
  });
  assert.equal(result.status, 75, result.stderr);
  assert.equal(result.lifecycle.cleanup.status, "preserved_not_clean");
  assert.match(result.stdout, /preserving.*not clean/i);
  assert.equal(result.calls.some((call) => call.includes("down")), false);
  assert.equal(result.lifecycle.cleanup.containers, 1);
  assert.equal(result.lifecycle.cleanup.networks, 1);
  assert.equal(result.lifecycle.cleanup.volumes, 1);
});
