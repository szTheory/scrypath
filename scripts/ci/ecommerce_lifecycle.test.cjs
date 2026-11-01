const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const {
  chmodSync,
  copyFileSync,
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
const composeE2eSource = path.join(
  repositoryRoot,
  "examples/scrypath_ecommerce/compose.e2e.yaml",
);
const dependencyBoundaryVerifier = path.join(
  repositoryRoot,
  "examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh",
);

test("mounted verification runs the clean dependency boundary proof before starting Compose", () => {
  const verifier = readFileSync(verifierSource, "utf8");
  const boundaryProof = 'bash "$script_dir/verify-dependency-boundaries.sh" --runtime';

  assert.ok(
    verifier.includes(boundaryProof),
    `${dependencyBoundaryVerifier} --runtime must be part of the canonical mounted verifier`,
  );
  assert.ok(
    verifier.indexOf(boundaryProof) < verifier.indexOf('echo "Starting isolated Docker verifier project'),
    "the clean target proof must run before the mounted Compose stack starts",
  );
});

test("focused mounted verification invokes the runtime dependency proof", (t) => {
  const result = runVerifier(t, ["focused"]);

  assert.equal(result.status, 0, result.stderr || result.stdout);
  assert.deepEqual(result.boundaryCalls, ["--runtime"]);
});

test("an explicit artifact root inside the checkout is refused before Compose setup", (t) => {
  const result = runVerifier(t, ["focused"], {
    E2E_HOST_ARTIFACT_ROOT: ({ exampleDirectory }) => path.join(exampleDirectory, "test-results", "unsafe-explicit-root"),
  });

  assert.equal(result.status, 64, result.stderr);
  assert.match(result.stderr, /E2E_HOST_ARTIFACT_ROOT must be outside the checkout/i);
  assert.deepEqual(result.calls.map((call) => call.slice(0, 2)), [["compose", "version"]]);
});

test("before-only default artifacts stay outside the checkout before qualification checks", (t) => {
  const result = runVerifier(t, ["full"], {
    E2E_PRESERVATION_MODE: "before-only",
    E2E_PHASE185_QUALIFICATION_PATH: ({ root }) => path.join(root, "missing-qualification.json"),
    TMPDIR: ({ root }) => {
      const externalTemp = `${root}-external-temp`;
      mkdirSync(externalTemp, { recursive: true });
      t.after(() => rmSync(externalTemp, { recursive: true, force: true }));
      return externalTemp;
    },
  });

  assert.equal(result.status, 64, result.stderr);
  assert.match(result.stderr, /Before-only mode requires the regular raw Plan05 qualification/i);
  assert.ok(result.artifactDirectory, "the default before-only artifact directory must be created");
  assert.ok(!result.artifactDirectory.startsWith(`${result.checkoutRoot}${path.sep}`));
  assert.deepEqual(result.calls.map((call) => call.slice(0, 2)), [["compose", "version"]]);
});

test("before-only mode refuses a TMPDIR inside the checkout", (t) => {
  const result = runVerifier(t, ["full"], {
    E2E_PRESERVATION_MODE: "before-only",
    E2E_PHASE185_QUALIFICATION_PATH: ({ root }) => path.join(root, "missing-qualification.json"),
    TMPDIR: ({ exampleDirectory }) => exampleDirectory,
  });

  assert.equal(result.status, 64, result.stderr);
  assert.match(result.stderr, /E2E_HOST_ARTIFACT_ROOT must be outside the checkout/i);
  assert.deepEqual(result.calls.map((call) => call.slice(0, 2)), [["compose", "version"]]);
});

function tempDirectory(t) {
  const directory = mkdtempSync(path.join(os.tmpdir(), "scrypath-e2e-lifecycle-"));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  return directory;
}

function installVerifierFixtureRepo(root) {
  const exampleDirectory = path.join(root, "examples", "scrypath_ecommerce");
  const scriptsDirectory = path.join(exampleDirectory, "scripts");
  const ciDirectory = path.join(root, "scripts", "ci");
  mkdirSync(scriptsDirectory, { recursive: true });
  mkdirSync(ciDirectory, { recursive: true });
  copyFileSync(verifierSource, path.join(scriptsDirectory, "verify-e2e.sh"));
  copyFileSync(dependencyBoundaryVerifier, path.join(scriptsDirectory, "verify-dependency-boundaries.sh"));
  for (const name of ["docker-playwright.sh", "contrast-checker.mjs", "compose.yaml", "compose.e2e.yaml", "compose.phase173.yaml", "compose.phase185.yaml", "Dockerfile.e2e", "package.json", "package-lock.json"]) {
    copyFileSync(path.join(path.dirname(browserSource), name), path.join(exampleDirectory, name));
  }
  const cssDirectory = path.join(root, "scrypath_ops", "assets", "css");
  mkdirSync(cssDirectory, { recursive: true });
  for (const name of ["app.css", "contrast-pairs.mjs"]) {
    copyFileSync(path.join(repositoryRoot, "scrypath_ops", "assets", "css", name), path.join(cssDirectory, name));
  }
  copyFileSync(path.join(repositoryRoot, "scripts", "ci", "ecommerce_build.cjs"), path.join(ciDirectory, "ecommerce_build.cjs"));

  // TEST DOUBLE ONLY: the lifecycle unit tests exercise orchestration and cleanup,
  // not product-tree qualification or acceptance evidence. The fake Docker writer
  // below emits synthetic envelopes; it never calls this module as an authority.
  writeFileSync(
    path.join(ciDirectory, "ecommerce_evidence.cjs"),
    `"use strict";
const crypto = require("node:crypto");
const digest = (value) => "sha256:" + crypto.createHash("sha256").update(value).digest("hex");
module.exports = {
  productTreeIdentity(root) {
    if (!require("node:fs").statSync(root).isDirectory()) throw new Error("test fixture root is unavailable");
    return digest("lifecycle-test-product-tree");
  },
  fixtureOverlayDigest(root) {
    if (!require("node:fs").statSync(root).isDirectory()) throw new Error("test fixture root is unavailable");
    return digest("lifecycle-test-fixture-overlay");
  },
};
`,
  );
  return exampleDirectory;
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
const crypto = require("node:crypto");
const args = process.argv.slice(2);
const imageIds = {
  web: "sha256:" + "1".repeat(64),
  standalone_ops: "sha256:" + "2".repeat(64),
  browser: "sha256:" + "3".repeat(64),
};
const serviceForRef = (value) => Object.keys(imageIds).find((service) => value.endsWith("-" + service)) || "browser";
const projectIndex = args.indexOf("-p");
const project = projectIndex >= 0 ? args[projectIndex + 1] : "scrypath-test";
const composeModel = {
  services: Object.fromEntries(Object.keys(imageIds).map((service) => [service, {
    image: project + "-" + service,
    volumes: [process.env.E2E_PHASE185_CLOCK_PATH + ":/phase185-fixture/clock.txt:ro"],
  }])),
};
const emptyWorkdirLayer = "sha256:" + crypto.createHash("sha256").update(Buffer.alloc(1024)).digest("hex");
const browserInspection = [{
  Id: imageIds.browser,
  Architecture: "arm64",
  Os: "linux",
  DockerVersion: "test-double",
  RootFS: { Type: "layers", Layers: ["sha256:" + "a".repeat(64), "sha256:" + "d".repeat(64), "sha256:" + "b".repeat(64), emptyWorkdirLayer] },
  Config: {
    WorkingDir: "/app/examples/scrypath_ecommerce",
    Cmd: ["bash", "./docker-playwright.sh"],
    Env: ["PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"],
    Labels: {
      "com.docker.compose.project": project,
      "com.docker.compose.service": "browser",
      "com.docker.compose.version": "test-double",
      "org.opencontainers.image.revision": process.env.SCRYPATH_SOURCE_SHA,
    },
  },
}];
fs.appendFileSync(process.env.FAKE_DOCKER_LOG, JSON.stringify(args) + "\\n");
if (process.env.FAKE_DOCKER_CONFIG_FAIL === "1" && args[0] === "compose" && args.includes("config")) process.exit(18);
if (args[0] === "compose" && args.includes("up") && process.env.FAKE_DOCKER_UP_FAIL) process.exit(Number(process.env.FAKE_DOCKER_UP_FAIL));
if (args[0] === "compose" && args.includes("run") && process.env.FAKE_DOCKER_RUN_FAIL) process.exit(Number(process.env.FAKE_DOCKER_RUN_FAIL));
if (args[0] === "compose" && args.includes("down") && process.env.FAKE_DOCKER_DOWN_FAIL) process.exit(Number(process.env.FAKE_DOCKER_DOWN_FAIL));
if (args[0] === "compose" && args.includes("config")) {
  if (args.includes("--format") && args[args.indexOf("--format") + 1] === "json") process.stdout.write(JSON.stringify(composeModel) + "\\n");
  else if (!args.includes("--quiet")) process.stdout.write("services:\\n  web: {}\\n  standalone_ops: {}\\n  browser: {}\\n");
}
if (args[0] === "compose" && args.includes("logs")) process.stdout.write("fake compose diagnostics\\n");
if (args[0] === "compose" && args.includes("ps") && process.env.FAKE_BROWSER_CONTAINER === "1" && process.env.FAKE_DOCKER_CONFIG_FAIL !== "1") process.stdout.write(args.at(-1) + "-container\\n");
if (args[0] === "cp" && process.env.FAKE_DOCKER_CP_FAIL === "1") process.exit(42);
if (args[0] === "cp") {
  const destination = args.at(-1);
  fs.mkdirSync(destination, { recursive: true });
  const stages = Object.fromEntries(["inventory", "browser", "light_parity", "contrast"].map(name => [name, {started_at:"2026-10-26T12:00:00Z",ended_at:"2026-10-26T12:00:01Z",exit_code:0}]));
  fs.writeFileSync(destination + "/stages.json", JSON.stringify(stages) + "\\n");
  fs.writeFileSync(destination + "/phase105-evidence.ndjson", "{\\"operation\\":\\"browser\\"}\\n");
  fs.writeFileSync(destination + "/phase105-playwright-list.json", JSON.stringify({suites:[],errors:[]}));
  if (process.env.FAKE_DOCKER_OMIT_REPORT !== "1") fs.writeFileSync(destination + "/phase105-playwright.json", JSON.stringify({suites:[],errors:[]}));
  fs.mkdirSync(destination + "/playwright-report", { recursive: true });
  fs.writeFileSync(destination + "/playwright-report/index.html", "<html>owned</html>\\n");
  fs.writeFileSync(destination + "/admin-light-parity.json", JSON.stringify({status:"pass",missing:[],extra:[],width_mismatches:[]}));
  const contrastFindings = [{severity:"aaa-body-advisory",producer:"token",pass_aa:true}];
  fs.writeFileSync(destination + "/contrast-report.json", JSON.stringify({
    schema:"scrypath.contrast.v1",
    producer:"token",
    generated:"2026-10-26T12:00:01.000Z",
    summary:{aa_fail:0,aaa_advisory:1,total:1},
    findings:contrastFindings
  }));
  const clockArtifact = destination + "/ui-review-artifacts/iteration3-journeys/phase185-held-out/phase185-clock.txt";
  fs.mkdirSync(require("node:path").dirname(clockArtifact), { recursive: true });
  fs.writeFileSync(clockArtifact, process.env.E2E_PHASE185_CLOCK_INSTANT + "\\n");
}
if (args[0] === "image" && args[1] === "inspect") {
  const service = serviceForRef(args.at(-1));
  if (args.includes("--format")) process.stdout.write(imageIds[service] + "\\n");
  else process.stdout.write(JSON.stringify(browserInspection) + "\\n");
}
if (args[0] === "inspect" && args.includes("--format")) {
  const container = args.at(-1);
  const service = container.replace(/-container$/, "");
  process.stdout.write((imageIds[service] || imageIds.browser) + "\\n");
}
if (args[0] === "run") {
  const input = fs.readFileSync(0, "utf8");
  fs.writeFileSync(process.env.FAKE_DOCKER_STDIN_FILE, input);
  const volume = args.find(value => value.endsWith(":/evidence"));
  const destination = volume ? volume.slice(0, volume.lastIndexOf(":/evidence")) : null;
  const hasWriter = input.includes("node /app/scripts/ci/ecommerce_evidence.cjs write-evidence --run-dir /evidence");
  if (destination && hasWriter && process.env.FAKE_DOCKER_RUN_OMIT_RECEIPT !== "1") {
    const runId = process.env.E2E_WORKFLOW_RUN_ID || process.env.E2E_RUN_ID;
    const sourceSha = process.env.SCRYPATH_SOURCE_SHA;
    const eventSha = process.env.E2E_EVENT_SHA;
    const contrast = JSON.parse(fs.readFileSync(destination + "/contrast-report.json", "utf8"));
    fs.writeFileSync(destination + "/phase105-evidence-input.json", JSON.stringify({
      source: { checkout_head: sourceSha, built_source_sha: sourceSha },
      workflow: { run_id: runId, sha: eventSha },
      checkers: { contrast: { path: "contrast-report.json", status: contrast.schema === "scrypath.contrast.v1" && contrast.producer === "token" && contrast.summary?.total === contrast.findings?.length && contrast.summary?.aa_fail === 0 ? "pass" : "fail" } }
    }));
    fs.writeFileSync(destination + "/phase105-evidence.json", JSON.stringify({
      schema_version: 1,
      authority: "scripts/ci/ecommerce_evidence.cjs",
      run_id: runId,
      sha: eventSha,
      eligibility: { eligible: true }
    }));
    fs.writeFileSync(destination + "/phase105-evidence-summary.md", "# Phase 105 E2E Evidence Summary\\n\\n- run_id: " + runId + "\\n- sha: " + eventSha + "\\n");
  }
}
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
  const exampleDirectory = installVerifierFixtureRepo(root);
  const scriptPath = path.join(exampleDirectory, "scripts", "verify-e2e.sh");
  const requestedRunId = extraEnv.E2E_RUN_ID || "lifecycle-test-run";
  const runId = args[0] === "full" && !requestedRunId.startsWith("phase185-")
    ? `phase185-${requestedRunId}`
    : requestedRunId;
  const resolvedExtraEnv = Object.fromEntries(
    Object.entries(extraEnv).map(([key, value]) => [
      key,
      typeof value === "function" ? value({ root, exampleDirectory }) : value,
    ]),
  );
  const clockInstant = "2026-10-31T12:00:00.000Z";
  const boundaryLogPath = path.join(root, "boundary.log");
  writeFileSync(
    path.join(exampleDirectory, "scripts", "verify-dependency-boundaries.sh"),
    'printf "%s\\n" "$*" >> "$FAKE_BOUNDARY_LOG"\nexit 0\n',
  );

  const { binDirectory, logPath } = installDockerDouble(root);
  const aggregateInputPath = path.join(root, "docker-run.stdin");
  if (extraEnv.FAKE_PREVIOUS_CAPTURE === "1") {
    const previousDirectory = path.join(exampleDirectory, "test-results", `docker-${args[0]}`, "previous-run");
    mkdirSync(previousDirectory, { recursive: true });
    writeFileSync(path.join(previousDirectory, "stale-sentinel.txt"), "must not be copied\n");
  }
  const childEnv = { ...process.env };
  // The fixture must exercise the verifier's own defaults unless a test opts in
  // to an explicit host artifact root. In particular, a maintainer's exported
  // path must not redirect synthetic lifecycle output into the real checkout.
  delete childEnv.E2E_HOST_ARTIFACT_ROOT;
  Object.assign(childEnv, {
    PATH: `${binDirectory}${path.delimiter}${process.env.PATH}`,
    FAKE_DOCKER_LOG: logPath,
    FAKE_BOUNDARY_LOG: boundaryLogPath,
    FAKE_DOCKER_STDIN_FILE: aggregateInputPath,
    FAKE_BROWSER_CONTAINER: args.includes("--readiness-only") ? "0" : "1",
    E2E_RUN_ID: runId,
    E2E_PHASE185_CLOCK_INSTANT: clockInstant,
    ...resolvedExtraEnv,
  });
  const artifactParent = resolvedExtraEnv.E2E_HOST_ARTIFACT_ROOT
    ? path.resolve(exampleDirectory, resolvedExtraEnv.E2E_HOST_ARTIFACT_ROOT)
    : resolvedExtraEnv.E2E_PRESERVATION_MODE === "before-only"
      ? path.resolve(
          exampleDirectory,
          resolvedExtraEnv.TMPDIR || process.env.TMPDIR || "/tmp",
          "scrypath-phase185-before-only",
        )
      : path.join(exampleDirectory, "test-results", `docker-${args[0]}`);
  const result = spawnSync("bash", [scriptPath, ...args], {
    cwd: exampleDirectory,
    encoding: "utf8",
    env: childEnv,
  });
  const artifactDirectory = existsSync(path.join(artifactParent, runId))
    ? path.join(artifactParent, runId)
    : existsSync(artifactParent)
      ? readdirSync(artifactParent).map((name) => path.join(artifactParent, name)).find((candidate) => path.basename(candidate) !== "previous-run") || null
      : null;
  const lifecyclePath = artifactDirectory && path.join(artifactDirectory, "lifecycle.json");
  const lifecycle = lifecyclePath && existsSync(lifecyclePath)
    ? JSON.parse(readFileSync(lifecyclePath, "utf8"))
    : null;
  return {
    ...result,
    calls: dockerCalls(logPath),
    boundaryCalls: existsSync(boundaryLogPath) ? readFileSync(boundaryLogPath, "utf8").trim().split("\n") : [],
    artifactDirectory,
    checkoutRoot: root,
    aggregateInputPath,
    lifecycle,
  };
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
  const sleepPath = path.join(binDirectory, "sleep");
  const nodePath = path.join(binDirectory, "node");

  const playwrightJson = JSON.stringify({
    config: { rootDir: "." },
    errors: [],
    suites: [{
      title: "e2e",
      suites: [],
      specs: [{
        title: "mounted and standalone shell proof",
        file: "e2e/phase173_shell.spec.ts",
        tests: [{
          projectName: "chromium",
          expectedStatus: "passed",
          results: [{ retry: 0, status: "passed", duration: 1 }],
          status: "passed"
        }]
      }]
    }]
  });

  writeFileSync(
    curlPath,
    `#!/usr/bin/env node
const fs = require("node:fs");
const args = process.argv.slice(2);
const url = args.at(-1) || "";
fs.appendFileSync(process.env.FAKE_CURL_LOG, url + "\\n");
if (process.env.FAKE_CURL_FAIL_URL === url) process.exit(22);
if (args.includes("--write-out")) process.stdout.write(process.env.FAKE_CURL_REDIRECT_URL === url ? "302" : "200");
`,
  );
  writeFileSync(
    npmPath,
    `#!/usr/bin/env node
const fs = require("node:fs");
const args = process.argv.slice(2);
fs.appendFileSync(process.env.FAKE_BROWSER_LOG, "npm " + args.join(" ") + "\\n");
if (args.includes("test:e2e")) {
  const delay = Number(process.env.FAKE_NPM_DELAY_MS || 0);
  if (delay > 0) Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, delay);
  const root = process.env.E2E_ARTIFACT_DIR;
  fs.mkdirSync(root, { recursive: true });
  if (process.env.FAKE_BROWSER_NO_REPORT !== "1") {
    fs.writeFileSync(process.env.E2E_PLAYWRIGHT_REPORT, ${JSON.stringify(playwrightJson)} + "\\n");
    fs.mkdirSync(process.env.E2E_HTML_REPORT_DIR, { recursive: true });
    fs.writeFileSync(process.env.E2E_HTML_REPORT_DIR + "/index.html", "<html>owned report</html>\\n");
  }
}
if (args.includes("test:e2e:admin-light-parity")) {
  fs.writeFileSync(process.env.ADMIN_LIGHT_PARITY_REPORT, JSON.stringify({ status: "pass", missing: [], extra: [], width_mismatches: [] }) + "\\n");
}
`,
  );
  writeFileSync(
    npxPath,
    `#!/usr/bin/env node
const fs = require("node:fs");
const args = process.argv.slice(2);
fs.appendFileSync(process.env.FAKE_BROWSER_LOG, "npx " + args.join(" ") + "\\n");
if (args.includes("--list") && process.env.FAKE_BROWSER_NOOP !== "1") process.stdout.write(${JSON.stringify(playwrightJson)} + "\\n");
`,
  );
  writeFileSync(sleepPath, "#!/bin/sh\nexit 0\n");
  // TEST DOUBLE ONLY: the launcher normally packs actual raw browser captures.
  // Lifecycle tests use synthetic Playwright output, so intercept only that
  // container-only pack command and delegate every other Node invocation.
  const nodeExecutable = process.execPath.replace(/'/g, "'\\''");
  const nodeShim = [
    "#!/bin/sh",
    'if [ "$1" = "/app/scripts/ci/ui_preservation_bundle.cjs" ] && [ "$2" = "pack" ]; then',
    "  printf '%s\\n' 'test-double skipped raw capture packing' >>\"$FAKE_BROWSER_LOG\"",
    "  exit 0",
    "fi",
    "exec '" + nodeExecutable + "' \"$@\"",
    "",
  ].join("\n");
  writeFileSync(
    nodePath,
    nodeShim,
  );
  for (const command of [curlPath, npmPath, npxPath, sleepPath, nodePath]) chmodSync(command, 0o755);
  return { binDirectory, curlLog, browserLog };
}

function runBrowser(t, extraEnv = {}) {
  const root = tempDirectory(t);
  const exampleDirectory = installVerifierFixtureRepo(root);
  const { binDirectory, curlLog, browserLog } = installBrowserDoubles(root);
  const runId = extraEnv.E2E_RUN_ID || "phase185-browser-test-run";
  const clockInstant = "2026-10-31T12:00:00.000Z";
  const clockFixturePath = path.join(root, "phase185-clock.txt");
  writeFileSync(clockFixturePath, `${clockInstant}\n`);
  const artifactDirectory = path.join(root, "owned-evidence", runId);
  const result = spawnSync("bash", [path.join(exampleDirectory, "docker-playwright.sh")], {
    cwd: exampleDirectory,
    encoding: "utf8",
    env: {
      ...process.env,
      PATH: `${binDirectory}${path.delimiter}${process.env.PATH}`,
      FAKE_CURL_LOG: curlLog,
      FAKE_BROWSER_LOG: browserLog,
      E2E_SCOPE: "full",
      E2E_READINESS_ONLY: "1",
      E2E_READINESS_TIMEOUT_SECONDS: "30",
      E2E_CURL_TIMEOUT_SECONDS: "1",
      E2E_RUN_ID: runId,
      E2E_PHASE185_CLOCK_PATH: clockFixturePath,
      E2E_PHASE185_CLOCK_INSTANT: clockInstant,
      E2E_ARTIFACT_DIR: artifactDirectory,
      E2E_PLAYWRIGHT_REPORT: path.join(artifactDirectory, "phase105-playwright.json"),
      E2E_HTML_REPORT_DIR: path.join(artifactDirectory, "playwright-report"),
      E2E_LIGHT_REPORT: path.join(artifactDirectory, "admin-light-parity.json"),
      E2E_DEADLINE_EPOCH: String(Math.floor(Date.now() / 1000) + 30),
      E2E_FINALIZATION_MARGIN_SECONDS: "0",
      PLAYWRIGHT_BASE_URL: "http://web:4002",
      CONTRAST_REPORT_DIR: path.join(root, "contrast-results"),
      ...extraEnv,
    },
  });
  return {
    ...result,
    curlUrls: existsSync(curlLog) ? readFileSync(curlLog, "utf8").trim().split("\n") : [],
    browserInvocations: existsSync(browserLog) ? readFileSync(browserLog, "utf8") : "",
    artifactDirectory,
  };
}

test("run_bounded forwards an actual Bash heredoc to its asynchronous command", () => {
  const verifier = readFileSync(verifierSource, "utf8");
  const start = verifier.indexOf("run_bounded() {");
  const end = verifier.indexOf("\n}\n\nrun_execution_bounded()", start);
  assert.ok(start >= 0 && end > start, "expected the production run_bounded function");
  const functionSource = verifier.slice(start, end + 2);
  const result = spawnSync(
    "bash",
    ["-c", `${functionSource}\nrun_bounded 5 cat <<'PAYLOAD'\nphase182-heredoc-payload\nPAYLOAD\n`],
    { encoding: "utf8", timeout: 10_000 },
  );
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stdout, "phase182-heredoc-payload\n");
});

test("full readiness diagnostic uses the full overlay without claiming browser acceptance", (t) => {
  const result = runVerifier(t, ["full", "--readiness-only"]);
  assert.equal(result.status, 0, result.stderr);

  const calls = composeProjectCalls(result.calls);
  assert.ok(calls.length > 0, "expected owned Compose calls");
  assert.ok(
    calls.every((call) => composeFiles(call).includes("compose.phase173.yaml")),
    "every full-scope Compose operation must include the Phase 173 overlay",
  );
  assert.ok(
    calls.every((call) => composeFiles(call).includes("compose.phase185.yaml")),
    "every full-scope Compose operation must include the fixed-clock overlay",
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
  const browserIndex = result.stdout.indexOf("Running the full ecommerce browser");
  assert.ok(mountedIndex >= 0 && standaloneIndex >= 0, "both route checks must complete");
  assert.ok(browserIndex > mountedIndex && browserIndex > standaloneIndex, "browser execution must follow both route checks");
  assert.match(result.browserInvocations, /npx playwright test .*--list .*--reporter=json/);
  assert.equal((result.browserInvocations.match(/npm run test:e2e /g) || []).length, 1);
  assert.match(result.browserInvocations, /npm run test:e2e -- --config .*--project=chromium/);
  assert.doesNotMatch(result.browserInvocations, /--grep(?:-invert)?/);
  const inventory = JSON.parse(readFileSync(path.join(result.artifactDirectory, "phase105-playwright-list.json"), "utf8"));
  const report = JSON.parse(readFileSync(path.join(result.artifactDirectory, "phase105-playwright.json"), "utf8"));
  assert.deepEqual(inventory.suites[0].specs, report.suites[0].specs, "inventory and execution must select the same cases");
  assert.ok(existsSync(path.join(result.artifactDirectory, "playwright-report", "index.html")));
  assert.ok(existsSync(path.join(result.artifactDirectory, "stages.json")));
});

test("full browser discovery rejects a successful no-op and records its raw inventory failure", (t) => {
  const result = runBrowser(t, { E2E_READINESS_ONLY: "0", FAKE_BROWSER_NOOP: "1" });
  assert.notEqual(result.status, 0, `empty discovery output must not pass as a zero-case suite: ${JSON.stringify({ stdout: result.stdout, stderr: result.stderr, invocations: result.browserInvocations })}`);
  assert.doesNotMatch(result.browserInvocations, /npm run test:e2e /, "execution cannot start after invalid inventory");
  const stages = JSON.parse(readFileSync(path.join(result.artifactDirectory, "stages.json"), "utf8"));
  assert.notEqual(stages.inventory.exit_code, 0);
  assert.equal(stages.browser.exit_code, null);
});

test("full browser execution rejects missing current-run JSON or HTML reports", (t) => {
  const result = runBrowser(t, { E2E_READINESS_ONLY: "0", FAKE_BROWSER_NO_REPORT: "1" });
  assert.equal(result.status, 74, result.stderr);
  const stages = JSON.parse(readFileSync(path.join(result.artifactDirectory, "stages.json"), "utf8"));
  assert.equal(stages.browser.exit_code, 74);
  assert.match(result.stderr, /did not produce.*JSON and HTML/i);
});

test("full browser deadline records timeout without replacing the raw test status", (t) => {
  const result = runBrowser(t, {
    E2E_READINESS_ONLY: "0",
    E2E_DEADLINE_EPOCH: String(Math.floor(Date.now() / 1000) + 12),
    FAKE_NPM_DELAY_MS: "20000",
  });
  assert.equal(result.status, 124, result.stderr);
  const stages = JSON.parse(readFileSync(path.join(result.artifactDirectory, "stages.json"), "utf8"));
  assert.equal(stages.browser.exit_code, 124);
  assert.match(result.stderr, /deadline|timed out/i);
});

test("verifier creates a fresh per-run bundle and excludes a previous capture sentinel", (t) => {
  const result = runVerifier(t, ["full"], {
    E2E_RUN_ID: "run-unique-18204",
    FAKE_PREVIOUS_CAPTURE: "1",
  });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(path.basename(result.artifactDirectory), "phase185-run-unique-18204");
  assert.equal(path.basename(path.dirname(result.artifactDirectory)), "docker-full");
  assert.equal(result.lifecycle.run_id, "phase185-run-unique-18204");
  assert.equal(
    readFileSync(path.join(result.artifactDirectory, "phase185-clock.txt"), "utf8"),
    "2026-10-31T12:00:00.000Z\n",
    "the verifier must materialize exact fixed-clock bytes for the readonly Compose mount",
  );
  assert.equal(
    readFileSync(path.join(result.artifactDirectory, "ui-review-artifacts/iteration3-journeys/phase185-held-out/phase185-clock.txt"), "utf8"),
    "2026-10-31T12:00:00.000Z\n",
    "the synthetic browser copy must preserve the fixed-clock artifact bytes",
  );
  for (const file of ["source.json", "compose-model.json", "stages.json", "artifact-manifest.json", "phase105-inventory.json", "phase105-evidence-input.json", "phase105-evidence.json", "phase105-evidence-summary.md"]) {
    assert.ok(existsSync(path.join(result.artifactDirectory, file)), `owned bundle is missing ${file}`);
  }
  const aggregateInput = readFileSync(result.aggregateInputPath, "utf8");
  assert.match(aggregateInput, /node \/app\/scripts\/ci\/ecommerce_evidence\.cjs write-evidence --run-dir \/evidence/);
  const receiptInput = JSON.parse(readFileSync(path.join(result.artifactDirectory, "phase105-evidence-input.json"), "utf8"));
  const receipt = JSON.parse(readFileSync(path.join(result.artifactDirectory, "phase105-evidence.json"), "utf8"));
  const summary = readFileSync(path.join(result.artifactDirectory, "phase105-evidence-summary.md"), "utf8");
  assert.equal(receiptInput.source.checkout_head, "deadbeef00000000000000000000000000000000");
  assert.equal(receipt.run_id, "phase185-run-unique-18204");
  assert.equal(receipt.eligibility.eligible, true);
  assert.match(summary, /- run_id: phase185-run-unique-18204/);
  const manifest = JSON.parse(readFileSync(path.join(result.artifactDirectory, "artifact-manifest.json"), "utf8"));
  assert.equal(manifest.source, "/tmp/phase185-run-unique-18204");
  assert.deepEqual(manifest.allowlist, [
    "/tmp/phase185-run-unique-18204/phase105-playwright-list.json",
    "/tmp/phase185-run-unique-18204/phase105-playwright.json",
    "/tmp/phase185-run-unique-18204/phase105-evidence.ndjson",
    "/tmp/phase185-run-unique-18204/playwright-report/",
    "/tmp/phase185-run-unique-18204/test-results/",
    "/tmp/phase185-run-unique-18204/ui-review-artifacts/iteration3-journeys/",
  ]);
  assert.ok(Array.isArray(manifest.copied_files));
  const downIndex = result.calls.findIndex((call) => call.includes("down"));
  const aggregateIndex = result.calls.findIndex((call) => call[0] === "run");
  assert.ok(aggregateIndex > downIndex, "strict evidence aggregation must happen after owned Compose cleanup");
  assert.equal(existsSync(path.join(result.artifactDirectory, "stale-sentinel.txt")), false);
  assert.equal(existsSync(path.join(path.dirname(result.artifactDirectory), "previous-run", "stale-sentinel.txt")), true);
});

test("a zero-exit no-op aggregate writer cannot pass without current validated outputs", (t) => {
  const result = runVerifier(t, ["full"], { FAKE_DOCKER_RUN_OMIT_RECEIPT: "1" });
  assert.equal(result.status, 76, result.stderr);
  assert.match(result.stderr, /did not create 'phase105-evidence-input\.json'/);
  assert.match(readFileSync(result.aggregateInputPath, "utf8"), /write-evidence --run-dir \/evidence/);
  assert.equal(existsSync(path.join(result.artifactDirectory, "phase105-evidence.json")), false);
  assert.equal(result.lifecycle.cleanup.status, "clean");
});

test("Compose browser evidence directory ends with the exact run ID", () => {
  const verifier = readFileSync(verifierSource, "utf8");
  const compose = readFileSync(composeE2eSource, "utf8");
  const browser = readFileSync(browserSource, "utf8");

  assert.match(verifier, /export E2E_CONTAINER_ARTIFACT_DIR="\/tmp\/\$run_id"/);
  assert.match(compose, /E2E_ARTIFACT_DIR: \$\{E2E_CONTAINER_ARTIFACT_DIR:-\/tmp\/\$\{E2E_RUN_ID/);
  assert.match(browser, /artifact_dir="\$\{E2E_ARTIFACT_DIR:-\/tmp\/\$\{run_id\}\}"/);
});

test("full readiness fails when either Ops fixture route stays unavailable", (t) => {
  const result = runBrowser(t, {
    E2E_READINESS_TIMEOUT_SECONDS: "5",
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
  assert.equal(result.calls.filter((call) => call[0] === "cp").length, 1);
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

test("missing current-run reports block an otherwise successful verifier", (t) => {
  const result = runVerifier(t, ["full"], {
    FAKE_BROWSER_CONTAINER: "1",
    FAKE_DOCKER_OMIT_REPORT: "1",
  });
  assert.equal(result.status, 74, result.stderr);
  assert.equal(result.lifecycle.original_exit_status, 0);
  assert.equal(result.lifecycle.artifact_copy_status, "failed");
  assert.match(result.stderr, /missing required browser evidence: phase105-playwright.json/i);
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


test("redirecting Ops fixture routes cannot satisfy full readiness", (t) => {
  for (const url of ["http://web:4002/admin/search/phase173/health", "http://standalone_ops:4003/ops/phase173/health"]) {
    const result = runBrowser(t, { FAKE_CURL_REDIRECT_URL: url, E2E_READINESS_TIMEOUT_SECONDS: "1" });
    assert.notEqual(result.status, 0, url);
    assert.equal(result.browserInvocations, "", "a redirect must not reach the browser");
  }
});


function runBoundaryCopyFailure(t, target, removalFails) {
  const root = tempDirectory(t);
  const bin = path.join(root, "bin");
  const artifacts = path.join(root, "artifacts");
  const statePath = path.join(root, "boundary-state.json");
  const callsPath = path.join(root, "boundary-calls.jsonl");
  mkdirSync(bin, { recursive: true });
  const docker = path.join(bin, "docker");
  writeFileSync(docker, String.raw`#!/usr/bin/env node
const fs = require("node:fs");
const path = require("node:path");
const args = process.argv.slice(2);
fs.appendFileSync(process.env.FAKE_BOUNDARY_CALLS, JSON.stringify(args) + "\n");
const statePath = process.env.FAKE_BOUNDARY_STATE;
const state = fs.existsSync(statePath) ? JSON.parse(fs.readFileSync(statePath, "utf8")) : { images: {}, containers: [] };
const save = () => fs.writeFileSync(statePath, JSON.stringify(state));
if ((args[0] === "compose" && args[1] === "version") || args[0] === "info") process.exit(0);
if (args[0] === "build") {
  const labels = {};
  args.forEach((value, index) => {
    if (value === "--label") {
      const entry = args[index + 1];
      const separator = entry.indexOf("=");
      labels[entry.slice(0, separator)] = entry.slice(separator + 1);
    }
  });
  state.images[args[args.indexOf("-t") + 1]] = labels;
  save();
  process.exit(0);
}
if (args[0] === "image" && args[1] === "inspect") {
  const labels = state.images[args.at(-1)];
  const key = Object.keys(labels).find(name => args[2].includes(name));
  if (!key) throw new Error("unexpected image label request");
  process.stdout.write(labels[key] + "\n");
  process.exit(0);
}
if (args[0] === "image" && args[1] === "ls") {
  if (state.images[args.at(-1)]) process.stdout.write("sha256:FAKE_BOUNDARY_IMAGE_FOR_TEST_ONLY\\n");
  process.exit(0);
}
if (args[0] === "image" && args[1] === "rm") {
  delete state.images[args.at(-1)];
  save();
  process.exit(0);
}
if (args[0] === "create") {
  const id = "boundary-" + args.at(-1).split(":").at(-1);
  state.containers.push(id);
  save();
  process.stdout.write(id + "\n");
  process.exit(0);
}
if (args[0] === "cp") {
  if (args[1].startsWith("boundary-" + process.env.FAKE_BOUNDARY_TARGET + ":")) process.exit(42);
  const destination = args.at(-1);
  fs.mkdirSync(path.dirname(destination), { recursive: true });
  fs.writeFileSync(destination, "compiled asset\n");
  process.exit(0);
}
if (args[0] === "rm") {
  const id = args.at(-1);
  if (id === "boundary-" + process.env.FAKE_BOUNDARY_TARGET && process.env.FAKE_BOUNDARY_REMOVE_FAIL === "1") process.exit(43);
  state.containers = state.containers.filter(value => value !== id);
  save();
  process.exit(0);
}
throw new Error("unexpected Docker operation: " + JSON.stringify(args));
`);
  chmodSync(docker, 0o755);
  const result = spawnSync("bash", [dependencyBoundaryVerifier, "--runtime"], {
    cwd: repositoryRoot,
    env: {
      ...process.env,
      PATH: `${bin}${path.delimiter}${process.env.PATH}`,
      FAKE_BOUNDARY_CALLS: callsPath,
      FAKE_BOUNDARY_STATE: statePath,
      FAKE_BOUNDARY_TARGET: target,
      FAKE_BOUNDARY_REMOVE_FAIL: removalFails ? "1" : "0",
      SCRYPATH_DEPENDENCY_BOUNDARY_ROOT: repositoryRoot,
      SCRYPATH_DEPENDENCY_BOUNDARY_ARTIFACT_DIR: artifacts,
    },
    encoding: "utf8",
    timeout: 20_000,
    maxBuffer: 2 * 1024 * 1024,
  });
  assert.equal(result.error, undefined, result.error?.message);
  const runs = readdirSync(artifacts).filter(name => name.startsWith("scrypath-dependency-boundary-"));
  assert.equal(runs.length, 1, result.stderr || result.stdout);
  return {
    result,
    state: JSON.parse(readFileSync(statePath, "utf8")),
    calls: readFileSync(callsPath, "utf8").trim().split("\n").map(line => JSON.parse(line)),
    receipt: JSON.parse(readFileSync(path.join(artifacts, runs[0], "runtime-receipt.json"), "utf8")),
  };
}

for (const target of ["runtime-test", "runtime-prod"]) {
  for (const removalFails of [false, true]) {
    test(`runtime boundary target extraction preserves copy failure and reports ${target} cleanup ${removalFails ? "failure" : "success"}`, t => {
      const { result, state, calls, receipt } = runBoundaryCopyFailure(t, target, removalFails);
      const container = `boundary-${target}`;
      assert.equal(result.status, 42, result.stderr || result.stdout);
      assert.ok(calls.some(args => args[0] === "rm" && args.includes(container)), "the failed extraction container must remain owned by cleanup");
      assert.equal(receipt.status, "failed");
      assert.equal(receipt.cleanup_status, removalFails ? 1 : 0);
      assert.deepEqual(state.containers, removalFails ? [container] : []);
      const builtTags = calls.filter(args => args[0] === "build").map(args => args[args.indexOf("-t") + 1]);
      const queriedTags = calls.filter(args => args[0] === "image" && args[1] === "ls").map(args => args.at(-1));
      assert.deepEqual(queriedTags.sort(), builtTags.sort(), "cleanup queries only the image tags created by this fixture run");
      assert.deepEqual(state.images, {}, "all owned image tags are removed even when extraction or container removal fails");
    });
  }
}
