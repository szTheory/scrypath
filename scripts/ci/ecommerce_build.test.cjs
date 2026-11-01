"use strict";

const assert = require("node:assert/strict");
const { execFileSync, spawnSync } = require("node:child_process");
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
const { prepareBuild, verifyHandoff, recordCacheOutcome, phase185RuntimeIdentity } = require("./ecommerce_build.cjs");
const { configureDockerBake } = require("./phase182_acceptance.cjs");

const repositoryRoot = path.resolve(__dirname, "../..");
const verifierSource = path.join(
  repositoryRoot,
  "examples/scrypath_ecommerce/scripts/verify-e2e.sh",
);

function makeTempDirectory(t) {
  const directory = mkdtempSync(path.join(os.tmpdir(), "scrypath-ecommerce-build-"));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  return directory;
}

function runPrebuiltVerifier(t, extraEnv = {}) {
  const root = makeTempDirectory(t);
  const exampleDirectory = path.join(root, "examples/scrypath_ecommerce");
  const scriptDirectory = path.join(exampleDirectory, "scripts");
  const ciDirectory = path.join(root, "scripts/ci");
  const binDirectory = path.join(root, "bin");
  mkdirSync(scriptDirectory, { recursive: true });
  mkdirSync(ciDirectory, { recursive: true });
  mkdirSync(binDirectory, { recursive: true });

  const verifierPath = path.join(scriptDirectory, "verify-e2e.sh");
  const dockerLog = path.join(root, "docker.jsonl");
  const helperLog = path.join(root, "helper.jsonl");
  const boundaryLog = path.join(root, "boundary.log");
  const dockerPath = path.join(binDirectory, "docker");
  const gitPath = path.join(binDirectory, "git");
  const boundaryPath = path.join(scriptDirectory, "verify-dependency-boundaries.sh");
  const manifestPath = path.join(root, "image-handoff.json");
  const overridePath = path.join(root, "image-override.json");

  writeFileSync(verifierPath, readFileSync(verifierSource));
  writeFileSync(
    boundaryPath,
    'printf "%s\\n" "$*" >> "$FAKE_BOUNDARY_LOG"\nexit 0\n',
  );
  writeFileSync(manifestPath, JSON.stringify({ schema_version: 1 }));
  writeFileSync(overridePath, JSON.stringify({ services: {} }));
  writeFileSync(
    path.join(ciDirectory, "ecommerce_build.cjs"),
    `"use strict";
const fs = require("node:fs");
fs.appendFileSync(process.env.FAKE_HELPER_LOG, JSON.stringify({args:process.argv.slice(2),hasRuntimeToken:Boolean(process.env.ACTIONS_RUNTIME_TOKEN),mode:process.env.PHASE182_CACHE_MODE,namespace:process.env.PHASE182_PROBE_NAMESPACE}) + "\\n");
if (process.env.FAKE_HELPER_FAIL === "1") process.exit(1);
`,
  );
  writeFileSync(
    dockerPath,
    `#!/usr/bin/env node
const fs = require("node:fs");
const args = process.argv.slice(2);
fs.appendFileSync(process.env.FAKE_DOCKER_LOG, JSON.stringify(args) + "\\n");
if (args[0] === "compose" && args[1] === "version") process.stdout.write("Docker Compose version v2\\n");
if (args[0] === "compose" && args.includes("config") && !args.includes("--quiet")) process.stdout.write("{\\"services\\":{}}\\n");
if (args[0] === "compose" && args.includes("ps") && args.includes("-aq")) process.stdout.write("");
`,
  );
  writeFileSync(
    gitPath,
    `#!/usr/bin/env node
const args = process.argv.slice(2).join(" ");
if (args === "rev-parse --short=8 HEAD") process.stdout.write("deadbeef\\n");
else if (args === "rev-parse HEAD") process.stdout.write("deadbeef00000000000000000000000000000000\\n");
else if (args === "branch --show-current") process.stdout.write("worktree-agent-test\\n");
else if (args === "status --porcelain --untracked-files=all") process.stdout.write("");
else process.exit(2);
`,
  );
  chmodSync(dockerPath, 0o755);
  chmodSync(gitPath, 0o755);

  const result = spawnSync("bash", [verifierPath, "focused"], {
    cwd: exampleDirectory,
    encoding: "utf8",
    env: {
      ...process.env,
      PATH: `${binDirectory}${path.delimiter}${process.env.PATH}`,
      FAKE_DOCKER_LOG: dockerLog,
      FAKE_BOUNDARY_LOG: boundaryLog,
      FAKE_HELPER_LOG: helperLog,
      E2E_RUN_ID: "prebuilt-test-run",
      E2E_PROJECT_NAME: "scrypath-e2e-prebuilt-test",
      E2E_PREBUILT_MANIFEST: manifestPath,
      E2E_IMAGE_OVERRIDE: overridePath,
      E2E_DOCKER_TIMEOUT_SECONDS: "20",
      E2E_FINALIZE_TIMEOUT_SECONDS: "10",
      E2E_FINALIZATION_MARGIN_SECONDS: "0",
      E2E_DEADLINE_EPOCH: String(Math.floor(Date.now() / 1000) + 120),
      ...extraEnv,
    },
  });
  const calls = existsSync(dockerLog)
    ? readFileSync(dockerLog, "utf8").trim().split("\n").filter(Boolean).map(JSON.parse)
    : [];
  const helperCalls = existsSync(helperLog)
    ? readFileSync(helperLog, "utf8").trim().split("\n").filter(Boolean).map(JSON.parse)
    : [];
  return { ...result, calls, helperCalls, overridePath };
}

function composeGraph(scope, project, changeModel = false, env = process.env) {
  const services = {
    web: {
      build: { context: repositoryRoot, dockerfile: "examples/scrypath_ecommerce/Dockerfile" },
      environment: {
        E2E_RUN_ID: env.E2E_RUN_ID || "local-focused",
        E2E_ARTIFACT_DIR: env.E2E_CONTAINER_ARTIFACT_DIR || "/tmp/local-focused",
        E2E_DEADLINE_EPOCH: env.E2E_DEADLINE_EPOCH || "0",
        E2E_EVENT_SHA: env.E2E_EVENT_SHA || "unknown",
        E2E_GIT_REF: env.E2E_GIT_REF || "local",
        E2E_JOB_NAME: env.E2E_JOB_NAME || "local-ecommerce-e2e",
        E2E_JOB_STARTED_AT: env.E2E_JOB_STARTED_AT || "unknown",
        E2E_SOURCE_MODE: env.E2E_SOURCE_MODE || "local",
        E2E_WORKFLOW_RUN_ATTEMPT: env.E2E_WORKFLOW_RUN_ATTEMPT || "1",
        E2E_WORKFLOW_RUN_ID: env.E2E_WORKFLOW_RUN_ID || "local",
        SCRYPATH_SOURCE_SHA: env.SCRYPATH_SOURCE_SHA || "unknown",
      },
    },
    browser: { build: { context: repositoryRoot, dockerfile: "examples/scrypath_ecommerce/Dockerfile.e2e", args: { PLAYWRIGHT_VERSION: "1.60.0" } } },
  };
  if (scope === "full") {
    services.standalone_ops = { build: { context: repositoryRoot, dockerfile: "examples/scrypath_ecommerce/Dockerfile", target: "ops" } };
    services.browser.environment = Object.fromEntries([
      "E2E_APPLICATION_IMAGE_ID", "E2E_STANDALONE_OPS_IMAGE_ID", "E2E_BROWSER_IMAGE_ID",
      "E2E_EFFECTIVE_RUNTIME_SHA256", "E2E_BROWSER_SOURCE_LAYER_ID", "E2E_BROWSER_BASE_LAYERS_SHA256",
      "E2E_PRODUCT_SOURCE_SHA", "E2E_PRODUCT_TREE_SHA256", "E2E_FIXTURE_OVERLAY_SHA256",
      "E2E_BROWSER_PROFILE_SHA256", "E2E_DATA_RECIPE_SHA256",
    ].map((key) => [key, env[key] || ""]));
  }
  if (changeModel) services.web.build.target = "changed";
  const target = Object.fromEntries(Object.entries(services).map(([name, service]) => [name, {
    context: repositoryRoot,
    dockerfile: path.resolve(repositoryRoot, service.build.dockerfile),
    ...(service.build.args ? { args: service.build.args } : {}),
    ...(service.build.target ? { target: service.build.target } : {}),
    labels: {
      "com.docker.compose.project": project,
      "com.docker.compose.service": name,
      "com.docker.compose.version": "2.39.0",
    },
    tags: [`${project}-${name}`],
    output: ["type=docker"],
  }]));
  return { model: { services }, bake: { group: { default: { targets: Object.keys(target) } }, target } };
}

function buildDriver(scope, project, options = {}) {
  const state = { modelChange: false, missingTag: "", runtimeMismatch: "", revisionMismatch: "", manifest: null };
  const driver = (command, args, callOptions = {}) => {
    if (command !== "docker") {
      return execFileSync(command, args, { cwd: callOptions.cwd, env: callOptions.env, encoding: "utf8" }).trimEnd();
    }
    const graph = composeGraph(scope, project, state.modelChange, callOptions.env || process.env);
    if (args.includes("config")) return JSON.stringify(graph.model);
    if (args.includes("build") && args.includes("--print")) return JSON.stringify(graph.bake);
    if (args[0] === "image" && args[1] === "inspect") {
      const tag = args.at(-1);
      if (tag === state.missingTag) throw new Error("No such image");
      const service = tag.slice(`${project}-`.length);
      const source = state.manifest || options.manifest;
      return JSON.stringify({
        Id: state.tagIdMismatch === service ? `sha256:${"f".repeat(64)}` : `sha256:${service.padEnd(64, "a").slice(0, 64)}`,
        RepoTags: [`docker.io/library/${tag}:latest`],
        RootFS: { Layers: [`sha256:${"b".repeat(64)}`, `sha256:${"c".repeat(64)}`, "sha256:5f70bf18a086007016e948b04aed3b82103a36bea41755b6cddfaf10ace3c6ef"] },
        Architecture: "amd64", Os: "linux", DockerVersion: "27.0.0",
        Config: { WorkingDir: "/app/examples/scrypath_ecommerce", Cmd: ["bash", "./docker-playwright.sh"], Labels: {
          "org.opencontainers.image.revision": state.revisionMismatch === service ? "sha256:wrong-source" : source?.source_sha || execFileSync("git", ["rev-parse", "HEAD"], { cwd: repositoryRoot, encoding: "utf8" }).trim(),
          ...(source?.source_fingerprint ? { "org.opencontainers.image.source-fingerprint": source.source_fingerprint } : {}),
        } },
      });
    }
    if (args[0] === "compose" && args.includes("ps")) {
      const service = args.at(-1);
      return `${service}-container`;
    }
    if (args[0] === "inspect") {
      const container = args.at(-1);
      const service = container.replace(/-container$/, "");
      const id = `sha256:${service.padEnd(64, "a").slice(0, 64)}`;
      return JSON.stringify({ Image: state.runtimeMismatch === service ? `sha256:${"f".repeat(64)}` : id });
    }
    throw new Error(`unexpected Docker command: ${args.join(" ")}`);
  };
  return { state, run: driver };
}

function prepareFixture(t, scope = "focused") {
  const output = path.join(makeTempDirectory(t), "prepared");
  const project = "scrypath-e2e-build-test";
  const env = { ...process.env, E2E_SCOPE: scope, E2E_PROJECT_NAME: project };
  const docker = buildDriver(scope, project);
  const result = prepareBuild({ scope, output, env, runCommand: docker.run, project });
  docker.state.manifest = result.manifest;
  return { ...result, project, env, docker };
}

function prepareAndConfigure(t, { scope, env, mode = "normal", namespace = "" }) {
  const output = path.join(makeTempDirectory(t), "prepared");
  const project = env.E2E_PROJECT_NAME;
  const checkedEnv = { ...env, PHASE182_CACHE_MODE: mode, PHASE182_PROBE_NAMESPACE: namespace };
  const docker = buildDriver(scope, project);
  const prepared = prepareBuild({ scope, output, env: checkedEnv, runCommand: docker.run, project });
  docker.state.manifest = prepared.manifest;
  const configured = configureDockerBake({ manifestPath: prepared.manifestPath, mode, namespace, env: checkedEnv });
  const verified = verifyHandoff({ manifestPath: prepared.manifestPath, env: checkedEnv, runCommand: docker.run });
  return { ...prepared, configured, verified, docker };
}

test("prepared cache policy survives configure and canonical prebuilt handoff", (t) => {
  const common = {
    ...process.env,
    GITHUB_ACTIONS: "true",
    GITHUB_REPOSITORY: "szTheory/scrypath",
    E2E_PROJECT_NAME: "scrypath-e2e-policy-test",
  };
  const cases = [
    {
      scope: "focused",
      mode: "normal",
      namespace: "",
      env: { ...common, E2E_SCOPE: "focused", E2E_CACHE_JOB: "mounted", GITHUB_EVENT_NAME: "push", GITHUB_REF: "refs/heads/main" },
      expectedPolicy: { import: true, export: false },
    },
    {
      scope: "full",
      mode: "normal",
      namespace: "candidate-2026",
      env: { ...common, E2E_SCOPE: "full", E2E_CACHE_JOB: "full", GITHUB_EVENT_NAME: "workflow_dispatch", GITHUB_REF: "refs/heads/candidate/phase182" },
      expectedPolicy: { import: true, export: true },
    },
    {
      scope: "focused",
      mode: "docker-cold",
      namespace: "cold-2026",
      env: { ...common, E2E_SCOPE: "focused", E2E_CACHE_JOB: "mounted", GITHUB_EVENT_NAME: "workflow_dispatch", GITHUB_REF: "refs/heads/candidate/phase182" },
      expectedPolicy: { import: false, export: false },
    },
  ];

  for (const scenario of cases) {
    const result = prepareAndConfigure(t, scenario);
    assert.deepEqual(result.manifest.cache_policy, scenario.expectedPolicy);
    assert.equal(result.manifest.cache_probe.mode, scenario.mode);
    assert.equal(result.manifest.cache_probe.namespace, scenario.namespace);
    assert.equal(result.verified.handoff_status, "loaded");
    const bake = JSON.parse(readFileSync(path.join(result.outputDirectory, "bake.json"), "utf8"));
    for (const [service, target] of Object.entries(bake.target)) {
      if (scenario.expectedPolicy.import) assert.match(target["cache-from"][0], new RegExp(`scope=${result.manifest.cache_scopes[service]}`));
      else assert.equal(target["cache-from"], undefined);
      if (scenario.expectedPolicy.export) assert.match(target["cache-to"][0], new RegExp(`scope=${result.manifest.cache_scopes[service]}`));
      else assert.equal(target["cache-to"], undefined);
    }
  }
});

test("probe cache exports reject unsafe namespaces, pull requests, and untrusted repositories", (t) => {
  const base = {
    ...process.env,
    GITHUB_ACTIONS: "true",
    E2E_CACHE_JOB: "full",
    E2E_SCOPE: "full",
    E2E_PROJECT_NAME: "scrypath-e2e-policy-test",
    GITHUB_EVENT_NAME: "workflow_dispatch",
    GITHUB_REF: "refs/heads/candidate/phase182",
    GITHUB_REPOSITORY: "szTheory/scrypath",
  };
  const unsafe = { ...base, PHASE182_PROBE_NAMESPACE: "../production" };
  const unsafeDocker = buildDriver("full", base.E2E_PROJECT_NAME);
  assert.throws(() => prepareBuild({
    scope: "full",
    output: path.join(makeTempDirectory(t), "unsafe"),
    env: unsafe,
    runCommand: unsafeDocker.run,
    project: base.E2E_PROJECT_NAME,
  }), /probe namespace/);

  for (const env of [
    { ...base, GITHUB_EVENT_NAME: "pull_request", GITHUB_REF: "refs/pull/55/merge", PHASE182_PROBE_NAMESPACE: "candidate-2026" },
    { ...base, GITHUB_REPOSITORY: "fork-owner/scrypath", PHASE182_PROBE_NAMESPACE: "candidate-2026" },
  ]) {
    const output = path.join(makeTempDirectory(t), "prepared");
    const docker = buildDriver("full", env.E2E_PROJECT_NAME);
    const prepared = prepareBuild({ scope: "full", output, env, runCommand: docker.run, project: env.E2E_PROJECT_NAME });
    const configured = configureDockerBake({ manifestPath: prepared.manifestPath, mode: "normal", namespace: "candidate-2026", env });
    assert.equal(configured.manifest.cache_policy.import, true);
    assert.equal(configured.manifest.cache_policy.export, false);
    assert.ok(Object.values(configured.bake.target).every((target) => !target["cache-to"]));
  }
});

test("prebuilt verification uses the checked image override without a Compose build", (t) => {
  const result = runPrebuiltVerifier(t, { PHASE182_CACHE_MODE: "normal", PHASE182_PROBE_NAMESPACE: "candidate-2026" });
  assert.equal(result.status, 0, `prebuilt verifier failed:\n${result.stdout}\n${result.stderr}`);
  const pull = result.calls.find((call) => call[0] === "compose" && call.includes("pull"));
  const up = result.calls.find((call) => call[0] === "compose" && call.includes("up"));
  assert.ok(pull, "prebuilt verification must pull only its external runtime dependencies");
  assert.deepEqual(pull.slice(-2), ["postgres", "meilisearch"]);
  assert.ok(up, "expected one canonical Compose up invocation");
  assert.ok(up.includes("--no-build"), "prebuilt verification must start Compose with --no-build");
  assert.ok(up.includes("--pull") && up[up.indexOf("--pull") + 1] === "never");
  assert.ok(result.calls.indexOf(pull) < result.calls.indexOf(up), "external dependencies must be present before Compose up with pull disabled");
  assert.ok(up.includes(result.overridePath), "Compose must include the checked image override file");
  assert.equal(result.helperCalls.length, 2, "verify-handoff must run before Compose up and after runtime starts");
  assert.ok(result.helperCalls.every((call) => call.args[0] === "verify-handoff"));
  assert.ok(result.helperCalls.every((call) => call.hasRuntimeToken === false));
  assert.ok(result.helperCalls.every((call) => call.mode === "normal" && call.namespace === "candidate-2026"));
});

test("prebuilt verification refuses a failed handoff before Compose starts", (t) => {
  const result = runPrebuiltVerifier(t, { FAKE_HELPER_FAIL: "1" });
  assert.equal(result.status, 69);
  assert.ok(!result.calls.some((call) => call.includes("pull")));
  assert.ok(!result.calls.some((call) => call.includes("up")));
  assert.ok(!result.calls.some((call) => call.includes("build") && !call.includes("--print")));
});

test("prepare derives focused and full local tags and keeps separate recipe scopes", (t) => {
  const focused = prepareFixture(t, "focused");
  assert.deepEqual(Object.keys(focused.manifest.tags).sort(), ["browser", "web"]);
  assert.equal(focused.manifest.cache_scopes.web, "scrypath-ecommerce-app-v1");
  assert.equal(focused.manifest.cache_scopes.browser, "scrypath-ecommerce-browser-v1");

  const full = prepareFixture(t, "full");
  assert.deepEqual(Object.keys(full.manifest.tags).sort(), ["browser", "standalone_ops", "web"]);
  assert.equal(full.manifest.cache_scopes.standalone_ops, "scrypath-ecommerce-standalone-ops-v1");
  assert.equal(new Set(Object.values(full.manifest.cache_scopes)).size, 3);
  const bake = JSON.parse(readFileSync(path.join(full.outputDirectory, "bake.json"), "utf8"));
  assert.ok(Object.values(bake.target).every((target) => target.output?.includes("type=docker")));
  assert.ok(Object.values(bake.target).every((target) => !target.push));
  assert.ok(Object.values(bake.target).every((target) => !target["cache-from"] && !target["cache-to"]));
  assert.ok(Object.entries(full.manifest.tags).every(([service, tag]) => tag === `${full.project}-${service}`));
});

test("Phase185 runtime identity separates source COPY from the actual trailing empty WORKDIR layer", (t) => {
  const directory = makeTempDirectory(t);
  const inspectionPath = path.join(directory, "browser-inspection.json");
  const base = {
    Id: `sha256:${"a".repeat(64)}`,
    RootFS: { Layers: [`sha256:${"b".repeat(64)}`, `sha256:${"c".repeat(64)}`, "sha256:5f70bf18a086007016e948b04aed3b82103a36bea41755b6cddfaf10ace3c6ef"] },
    Config: { Env: ["PATH=/usr/bin"], WorkingDir: "/app/examples/scrypath_ecommerce", Cmd: ["bash", "./docker-playwright.sh"], Labels: { "org.opencontainers.image.revision": "before" } },
    Architecture: "amd64", Os: "linux", DockerVersion: "27.0.0"
  };
  writeFileSync(inspectionPath, JSON.stringify([base]));
  const first = phase185RuntimeIdentity({ inspectionPath });
  writeFileSync(inspectionPath, JSON.stringify([{ ...base, Id: `sha256:${"d".repeat(64)}`, RootFS: { Layers: [base.RootFS.Layers[0], `sha256:${"e".repeat(64)}`, base.RootFS.Layers[2]] } }]));
  const changedSource = phase185RuntimeIdentity({ inspectionPath });
  assert.equal(first.browser_source_layer_id, base.RootFS.Layers[1]);
  assert.equal(changedSource.effective_runtime_sha256, first.effective_runtime_sha256);
  writeFileSync(inspectionPath, JSON.stringify([{ ...base, RootFS: { Layers: [`sha256:${"f".repeat(64)}`, base.RootFS.Layers[1], base.RootFS.Layers[2]] } }]));
  assert.notEqual(phase185RuntimeIdentity({ inspectionPath }).effective_runtime_sha256, first.effective_runtime_sha256);
  assert.deepEqual(first.runtime.rootfs_base_layers, [base.RootFS.Layers[0], base.RootFS.Layers[2]]);
  writeFileSync(inspectionPath, JSON.stringify([{ ...base, RootFS: { Layers: [base.RootFS.Layers[0], base.RootFS.Layers[1], `sha256:${"f".repeat(64)}`] } }]));
  assert.throws(() => phase185RuntimeIdentity({ inspectionPath }), /empty WORKDIR layer/);
  writeFileSync(inspectionPath, JSON.stringify([{ ...base, RootFS: { Layers: base.RootFS.Layers.slice(0, 2) } }]));
  assert.throws(() => phase185RuntimeIdentity({ inspectionPath }), /source-copy and trailing WORKDIR/);
  writeFileSync(inspectionPath, JSON.stringify([base]));
  const fixtureRoot = path.join(directory, "source");
  const fixtureExample = path.join(fixtureRoot, "examples/scrypath_ecommerce");
  mkdirSync(fixtureExample, { recursive: true });
  const dockerfile = readFileSync(path.join(repositoryRoot, "examples/scrypath_ecommerce/Dockerfile.e2e"), "utf8");
  writeFileSync(path.join(fixtureExample, "Dockerfile.e2e"), dockerfile.replace('WORKDIR /app/examples/scrypath_ecommerce\nCMD', 'WORKDIR /unexpected\nCMD'));
  assert.throws(() => phase185RuntimeIdentity({ inspectionPath, repoRoot: fixtureRoot }), /verified existing WORKDIR/);
});

test("trusted full CI prepares bounded version-2 cache exporters", (t) => {
  const project = "scrypath-e2e-build-test";
  const output = path.join(makeTempDirectory(t), "prepared");
  const env = {
    ...process.env,
    E2E_SCOPE: "full",
    E2E_CACHE_JOB: "full",
    GITHUB_EVENT_NAME: "workflow_dispatch",
    E2E_PROJECT_NAME: project,
    GITHUB_ACTIONS: "true",
    GITHUB_REF: "refs/heads/main",
    GITHUB_REPOSITORY: "szTheory/scrypath",
  };
  const docker = buildDriver("full", project);
  prepareBuild({ scope: "full", output, env, runCommand: docker.run, project });
  const bake = JSON.parse(readFileSync(path.join(output, "bake.json"), "utf8"));

  assert.deepEqual(bake.target.web["cache-from"], [
    "type=gha,scope=scrypath-ecommerce-app-v1,version=2,timeout=120s",
  ]);
  assert.deepEqual(bake.target.web["cache-to"], [
    "type=gha,scope=scrypath-ecommerce-app-v1,version=2,mode=max,timeout=120s",
  ]);
  assert.deepEqual(bake.target.browser["cache-from"], [
    "type=gha,scope=scrypath-ecommerce-browser-v1,version=2,timeout=120s",
  ]);
  assert.deepEqual(bake.target.browser["cache-to"], [
    "type=gha,scope=scrypath-ecommerce-browser-v1,version=2,mode=max,timeout=120s",
  ]);
  assert.deepEqual(bake.target.standalone_ops["cache-from"], [
    "type=gha,scope=scrypath-ecommerce-standalone-ops-v1,version=2,timeout=120s",
  ]);
  assert.deepEqual(bake.target.standalone_ops["cache-to"], [
    "type=gha,scope=scrypath-ecommerce-standalone-ops-v1,version=2,mode=max,timeout=120s",
  ]);
});

test("pull requests can import but cannot export shared cache scopes", (t) => {
  const project = "scrypath-e2e-build-test";
  const output = path.join(makeTempDirectory(t), "prepared");
  const env = {
    ...process.env,
    E2E_CACHE_JOB: "full",
    GITHUB_EVENT_NAME: "pull_request",
    E2E_PROJECT_NAME: project,
    GITHUB_ACTIONS: "true",
    GITHUB_REF: "refs/pull/55/merge",
    GITHUB_REPOSITORY: "szTheory/scrypath",
  };
  const docker = buildDriver("full", project);
  const result = prepareBuild({ scope: "full", output, env, runCommand: docker.run, project });
  const bake = JSON.parse(readFileSync(path.join(output, "bake.json"), "utf8"));

  assert.equal(result.manifest.cache_policy.import, true);
  assert.equal(result.manifest.cache_policy.export, false);
  assert.ok(Object.values(bake.target).every((target) => target["cache-from"]?.length === 1));
  assert.ok(Object.values(bake.target).every((target) => !target["cache-to"]));
});

test("mounted CI imports stable scopes without exporting them", (t) => {
  const project = "scrypath-e2e-build-test";
  const output = path.join(makeTempDirectory(t), "prepared");
  const env = {
    ...process.env,
    E2E_CACHE_JOB: "mounted",
    GITHUB_EVENT_NAME: "push",
    E2E_PROJECT_NAME: project,
    GITHUB_ACTIONS: "true",
    GITHUB_REF: "refs/heads/main",
    GITHUB_REPOSITORY: "szTheory/scrypath",
  };
  const docker = buildDriver("focused", project);
  const result = prepareBuild({ scope: "focused", output, env, runCommand: docker.run, project });
  const bake = JSON.parse(readFileSync(path.join(output, "bake.json"), "utf8"));

  assert.equal(result.manifest.cache_policy.import, true);
  assert.equal(result.manifest.cache_policy.export, false);
  assert.ok(Object.values(bake.target).every((target) => target["cache-from"]?.length === 1));
  assert.ok(Object.values(bake.target).every((target) => !target["cache-to"]));
});

test("non-main or fork full CI cannot export a shared cache scope", (t) => {
  for (const [repository, ref] of [
    ["szTheory/scrypath", "refs/heads/feature/cache-experiment"],
    ["fork-owner/scrypath", "refs/heads/main"],
  ]) {
    const project = "scrypath-e2e-build-test";
    const output = path.join(makeTempDirectory(t), repository.replace("/", "-"));
    const env = {
      ...process.env,
      E2E_CACHE_JOB: "full",
      GITHUB_EVENT_NAME: "workflow_dispatch",
      E2E_PROJECT_NAME: project,
      GITHUB_ACTIONS: "true",
      GITHUB_REF: ref,
      GITHUB_REPOSITORY: repository,
    };
    const docker = buildDriver("full", project);
    const result = prepareBuild({ scope: "full", output, env, runCommand: docker.run, project });

    assert.equal(result.manifest.cache_policy.import, true);
    assert.equal(result.manifest.cache_policy.export, false);
  }
});

test("distinct Compose recipes cannot share a normalized cache scope", (t) => {
  const project = "scrypath-e2e-build-test";
  const output = path.join(makeTempDirectory(t), "prepared");
  const base = buildDriver("full", project);
  const runCommand = (command, args, options = {}) => {
    const result = base.run(command, args, options);
    if (command !== "docker") return result;
    if (args.includes("config")) {
      const model = JSON.parse(result);
      model.services["standalone-ops"] = {
        build: { context: repositoryRoot, dockerfile: "examples/scrypath_ecommerce/Dockerfile.e2e" },
      };
      return JSON.stringify(model);
    }
    if (args.includes("build") && args.includes("--print")) {
      const bake = JSON.parse(result);
      bake.target["standalone-ops"] = {
        ...bake.target.browser,
        dockerfile: path.resolve(repositoryRoot, "examples/scrypath_ecommerce/Dockerfile.e2e"),
      };
      return JSON.stringify(bake);
    }
    return result;
  };

  assert.throws(
    () => prepareBuild({ scope: "full", output, env: { ...process.env, E2E_PROJECT_NAME: project }, runCommand, project }),
    /distinct Compose recipes collide on cache scope scrypath-ecommerce-standalone-ops-v1/,
  );
});

test("cache outcome records Buildx completion and exporter fallback honestly", (t) => {
  const fixture = prepareFixture(t, "full");
  const manifest = JSON.parse(readFileSync(fixture.manifestPath, "utf8"));
  manifest.cache_policy = { import: true, export: true };
  writeFileSync(fixture.manifestPath, JSON.stringify(manifest));
  const completed = recordCacheOutcome({
    manifestPath: fixture.manifestPath,
    bakeOutcome: "success",
    handoffOutcome: "success",
  });
  assert.equal(completed.import_status, "completed");
  assert.equal(completed.export_status, "completed");

  const fallback = recordCacheOutcome({
    manifestPath: fixture.manifestPath,
    bakeOutcome: "failure",
    handoffOutcome: "success",
  });
  assert.equal(fallback.import_status, "unknown");
  assert.equal(fallback.export_status, "failed_after_image_handoff");
  assert.equal(fallback.cache_action_outcome, "failure");
});

test("image cache contexts exclude local env files and private verification outputs", () => {
  const patterns = readFileSync(path.join(repositoryRoot, ".dockerignore"), "utf8").split(/\r?\n/);

  for (const pattern of [
    ".env",
    ".env.*",
    "**/.env",
    "**/.env.*",
    ".planning",
    "examples/*/test-results",
    "examples/*/playwright-report",
  ]) {
    assert.ok(patterns.includes(pattern), `Docker build context must exclude ${pattern}`);
  }
});

test("verify-handoff rejects a changed event cache policy", (t) => {
  const project = "scrypath-e2e-build-test";
  const output = path.join(makeTempDirectory(t), "prepared");
  const env = {
    ...process.env,
    E2E_CACHE_JOB: "full",
    GITHUB_EVENT_NAME: "workflow_dispatch",
    E2E_PROJECT_NAME: project,
    E2E_SCOPE: "full",
    GITHUB_ACTIONS: "true",
    GITHUB_REF: "refs/heads/main",
    GITHUB_REPOSITORY: "szTheory/scrypath",
  };
  const docker = buildDriver("full", project);
  const prepared = prepareBuild({ scope: "full", output, env, runCommand: docker.run, project });
  env.GITHUB_EVENT_NAME = "pull_request";

  assert.throws(
    () => verifyHandoff({ manifestPath: prepared.manifestPath, env, runCommand: docker.run }),
    /cache policy mismatch/,
  );
});

test("verify-handoff rejects a changed Compose model before inspecting images", (t) => {
  const fixture = prepareFixture(t);
  fixture.docker.state.modelChange = true;
  assert.throws(
    () => verifyHandoff({ manifestPath: fixture.manifestPath, env: fixture.env, runCommand: fixture.docker.run }),
    /Compose model or recipe digest mismatch/,
  );
});

test("verify-handoff ignores run-scoped Compose environment values but retains source checks", (t) => {
  const fixture = prepareFixture(t);
  Object.assign(fixture.env, {
    E2E_RUN_ID: "40456281741-1",
    E2E_CONTAINER_ARTIFACT_DIR: "/tmp/40456281741-1",
    E2E_DEADLINE_EPOCH: "1793061000",
    E2E_EVENT_SHA: fixture.manifest.source_sha,
    E2E_GIT_REF: "agent-p182-08-1793071051075",
    E2E_JOB_NAME: "ecommerce-mounted",
    E2E_JOB_STARTED_AT: "2026-10-27T05:39:38Z",
    E2E_SOURCE_MODE: "hosted",
    E2E_WORKFLOW_RUN_ATTEMPT: "1",
    E2E_WORKFLOW_RUN_ID: "40456281741",
    SCRYPATH_SOURCE_SHA: fixture.manifest.source_sha,
  });

  assert.equal(
    verifyHandoff({ manifestPath: fixture.manifestPath, env: fixture.env, runCommand: fixture.docker.run }).handoff_status,
    "loaded",
  );

  fixture.docker.state.modelChange = true;
  assert.throws(
    () => verifyHandoff({ manifestPath: fixture.manifestPath, env: fixture.env, runCommand: fixture.docker.run }),
    /Compose model or recipe digest mismatch/,
  );
});

test("full runtime handoff accepts measured identities and rejects forged provenance", (t) => {
  const fixture = prepareFixture(t, "full");
  const loaded = verifyHandoff({ manifestPath: fixture.manifestPath, env: fixture.env, runCommand: fixture.docker.run });
  // The disposable global capture runner uses the image-only handoff contract
  // without supplying the canonical full lane's measured browser metadata.
  assert.equal(
    verifyHandoff({ manifestPath: fixture.manifestPath, runtime: true, env: fixture.env, runCommand: fixture.docker.run }).handoff_status,
    "runtime_verified",
  );
  const inspectionPath = path.join(makeTempDirectory(t), "browser-inspection.json");
  const browserImage = JSON.parse(fixture.docker.run("docker", ["image", "inspect", loaded.tags.browser]));
  writeFileSync(inspectionPath, JSON.stringify([browserImage]));
  const measured = phase185RuntimeIdentity({ inspectionPath });
  const derived = {
    E2E_APPLICATION_IMAGE_ID: loaded.image_ids.web,
    E2E_STANDALONE_OPS_IMAGE_ID: loaded.image_ids.standalone_ops,
    E2E_BROWSER_IMAGE_ID: loaded.image_ids.browser,
    E2E_EFFECTIVE_RUNTIME_SHA256: measured.effective_runtime_sha256,
    E2E_BROWSER_SOURCE_LAYER_ID: measured.browser_source_layer_id,
    E2E_BROWSER_BASE_LAYERS_SHA256: measured.browser_base_layers_sha256,
  };
  Object.assign(fixture.env, derived);

  assert.equal(
    verifyHandoff({ manifestPath: fixture.manifestPath, runtime: true, env: fixture.env, runCommand: fixture.docker.run }).handoff_status,
    "runtime_verified",
  );
  for (const [key, value] of Object.entries(derived)) {
    fixture.env[key] = `sha256:${"f".repeat(64)}`;
    assert.throws(
      () => verifyHandoff({ manifestPath: fixture.manifestPath, runtime: true, env: fixture.env, runCommand: fixture.docker.run }),
      new RegExp(`runtime provenance mismatch: ${key}`),
    );
    delete fixture.env[key];
    assert.throws(
      () => verifyHandoff({ manifestPath: fixture.manifestPath, runtime: true, env: fixture.env, runCommand: fixture.docker.run }),
      new RegExp(`runtime provenance mismatch: ${key}`),
    );
    fixture.env[key] = value;
  }
  for (const key of ["E2E_PRODUCT_SOURCE_SHA", "E2E_PRODUCT_TREE_SHA256", "E2E_FIXTURE_OVERLAY_SHA256", "E2E_BROWSER_PROFILE_SHA256", "E2E_DATA_RECIPE_SHA256"]) {
    fixture.env[key] = "changed";
    assert.throws(
      () => verifyHandoff({ manifestPath: fixture.manifestPath, runtime: true, env: fixture.env, runCommand: fixture.docker.run }),
      /Compose model or recipe digest mismatch/,
    );
    delete fixture.env[key];
  }
  fixture.docker.state.tagIdMismatch = "browser";
  assert.throws(
    () => verifyHandoff({ manifestPath: fixture.manifestPath, runtime: true, env: fixture.env, runCommand: fixture.docker.run }),
    /runtime browser image tag mismatch/,
  );
});

test("verify-handoff rejects a changed generated tag mapping", (t) => {
  const fixture = prepareFixture(t);
  const override = JSON.parse(readFileSync(fixture.overridePath, "utf8"));
  override.services.web.image = "untrusted/web:latest";
  writeFileSync(fixture.overridePath, JSON.stringify(override));
  fixture.env.E2E_IMAGE_OVERRIDE = fixture.overridePath;
  assert.throws(
    () => verifyHandoff({ manifestPath: fixture.manifestPath, env: fixture.env, runCommand: fixture.docker.run }),
    /override tag mapping mismatch/,
  );
});

test("verify-handoff rejects a missing local image", (t) => {
  const fixture = prepareFixture(t);
  fixture.docker.state.missingTag = fixture.manifest.tags.web;
  assert.throws(
    () => verifyHandoff({ manifestPath: fixture.manifestPath, env: fixture.env, runCommand: fixture.docker.run }),
    /could not inspect image .*web/,
  );
});

test("verify-handoff rejects an image with the wrong source revision", (t) => {
  const fixture = prepareFixture(t);
  fixture.docker.state.revisionMismatch = "web";
  assert.throws(
    () => verifyHandoff({ manifestPath: fixture.manifestPath, env: fixture.env, runCommand: fixture.docker.run }),
    /local image source SHA mismatch: web/,
  );
});

test("verify-handoff rejects a manifest with a changed local tag", (t) => {
  const fixture = prepareFixture(t);
  const manifest = JSON.parse(readFileSync(fixture.manifestPath, "utf8"));
  manifest.tags.web = "registry.example.invalid/web:latest";
  writeFileSync(fixture.manifestPath, JSON.stringify(manifest));
  assert.throws(
    () => verifyHandoff({ manifestPath: fixture.manifestPath, env: fixture.env, runCommand: fixture.docker.run }),
    /tags or cache scopes mismatch/,
  );
});

test("verify-handoff rejects a runtime image ID mismatch", (t) => {
  const fixture = prepareFixture(t);
  verifyHandoff({ manifestPath: fixture.manifestPath, env: fixture.env, runCommand: fixture.docker.run });
  fixture.docker.state.runtimeMismatch = "web";
  assert.throws(
    () => verifyHandoff({ manifestPath: fixture.manifestPath, runtime: true, env: fixture.env, runCommand: fixture.docker.run }),
    /runtime image ID mismatch: web/,
  );
});
