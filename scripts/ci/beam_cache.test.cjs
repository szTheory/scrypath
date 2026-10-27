const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const { buildPlan, cacheIdentity, cachePlan, runtimeIdentity } = require("./beam_cache.cjs");

const repositoryRoot = path.resolve(__dirname, "../..");
const workflow = fs.readFileSync(path.join(repositoryRoot, ".github/workflows/ci.yml"), "utf8");
const rootCacheJobs = ["core", "package", "repository-contracts", "backend", "compatibility", "coverage"];

function jobBlock(name) {
  const start = workflow.indexOf(`  ${name}:\n`);
  assert.notEqual(start, -1, `CI job ${name} should exist`);
  const next = workflow.slice(start + 1).search(/^  [A-Za-z0-9_-]+:\n/m);
  return next === -1 ? workflow.slice(start) : workflow.slice(start, start + 1 + next);
}

test("root Mix cache jobs use a compatible Hex fallback and strict resolved cache plan", () => {
  for (const name of rootCacheJobs) {
    const block = jobBlock(name);
    const planner = name === "core"
      ? /phase182_acceptance\.cjs beam-plan --graph root/
      : /beam_cache\.cjs plan --graph root/;
    assert.match(block, planner, `${name} should derive its cache identity from the runtime`);
    assert.match(block, /~\/\.hex\/packages/, `${name} may cache only Hex package archives for download fallback`);
    assert.match(block, /downloads_restore_prefix/, `${name} should limit download fallback to a compatible prefix`);
    assert.match(block, /outputs\.resolved_paths/, `${name} should restore only graph-allowlisted resolved paths`);
    assert.match(block, /resolved_restore_prefix/, `${name} should retain exact-lock compatibility for resolved state`);
    assert.match(block, /MIX_ENV: test/, `${name} should identify the actual Mix environment`);
    assert.match(block, /MIX_TARGET: host/, `${name} should identify the actual Mix target`);
    assert.match(block, /BEAM_CACHE_PROFILE: (root|coverage)-test/, `${name} should identify its compilation profile`);
  }
});

test("cache paths never include Hex or Mix credentials", () => {
  assert.doesNotMatch(workflow, /~\/(?:\.hex|\.mix)(?:\n|\s)*$/m);
  assert.doesNotMatch(workflow, /~\/\.mix(?:\/|\s|$)/);
});

function identity(overrides = {}) {
  return {
    graph: "root",
    runner_image: "ubuntu24/20261019.1.0",
    os: "Linux",
    arch: "X64",
    elixir: "1.19.0",
    otp: "Erlang/OTP 28.1",
    mix_env: "test",
    mix_target: "host",
    profile: "root-test",
    manifests_digest: "1".repeat(64),
    locks_digest: "2".repeat(64),
    source_digest: "3".repeat(64),
    ...overrides
  };
}

test("every platform, toolchain, environment, target, profile and graph boundary changes compatible prefixes", () => {
  const base = cachePlan(identity());
  const mutations = [
    ["graph", "ops"],
    ["runner_image", "ubuntu24/20261020.1.0"],
    ["os", "Windows"],
    ["arch", "ARM64"],
    ["elixir", "1.18.4"],
    ["otp", "Erlang/OTP 27.3"],
    ["mix_env", "dev"],
    ["mix_target", "rpi4"],
    ["profile", "coverage-test"],
    ["manifests_digest", "4".repeat(64)]
  ];

  for (const [field, value] of mutations) {
    const changed = cachePlan(identity({ [field]: value }));
    assert.notEqual(changed.downloads_restore_prefix, base.downloads_restore_prefix, `${field} must separate download fallback`);
    assert.notEqual(changed.resolved_restore_prefix, base.resolved_restore_prefix, `${field} must separate resolved fallback`);
  }
});

test("lock changes retain only compatible Hex download fallback, and source changes retain rebuild compatibility", () => {
  const base = cachePlan(identity());
  const changedLock = cachePlan(identity({ locks_digest: "4".repeat(64) }));
  assert.equal(changedLock.downloads_restore_prefix, base.downloads_restore_prefix);
  assert.notEqual(changedLock.downloads_key, base.downloads_key);
  assert.notEqual(changedLock.resolved_restore_prefix, base.resolved_restore_prefix);
  assert.notEqual(changedLock.resolved_key, base.resolved_key);
  assert.notEqual(changedLock.plt_key, base.plt_key);

  const changedSource = cachePlan(identity({ source_digest: "4".repeat(64) }));
  assert.equal(changedSource.downloads_restore_prefix, base.downloads_restore_prefix);
  assert.equal(changedSource.resolved_restore_prefix, base.resolved_restore_prefix);
  assert.notEqual(changedSource.resolved_key, base.resolved_key);
  assert.notEqual(changedSource.plt_key, base.plt_key);
});

test("identity inputs fail closed when required runtime or graph data is missing or invalid", () => {
  const requiredFields = ["graph", "runner_image", "os", "arch", "elixir", "otp", "mix_env", "mix_target", "profile"];
  for (const field of requiredFields) {
    assert.throws(() => cacheIdentity(identity({ [field]: " " })), new RegExp(`invalid ${field}`));
  }
  for (const field of ["manifests_digest", "locks_digest", "source_digest"]) {
    assert.throws(() => cacheIdentity(identity({ [field]: "not-a-digest" })), new RegExp(`invalid ${field}`));
  }
  assert.throws(() => cacheIdentity(identity({ graph: "unknown" })), /unsupported graph/);
  assert.throws(() => runtimeIdentity({}, "Elixir 1.19.0\nErlang/OTP 28.1"), /ImageOS/);
});

test("archive paths are graph-allowlisted and exclude credentials and isolated proof builds", () => {
  const root = cachePlan(identity());
  const ops = cachePlan(identity({ graph: "ops" }));
  const ecommerce = cachePlan(identity({ graph: "ecommerce" }));
  const phoenix = cachePlan(identity({ graph: "phoenix-example" }));
  assert.deepEqual(root.paths.downloads, ["~/.hex/packages"]);
  assert.deepEqual(root.paths.resolved, ["deps", "_build/test"]);
  assert.deepEqual(root.paths.plt, ["priv/plts"]);
  assert.deepEqual(ops.paths.resolved, ["deps", "_build/test", "scrypath_ops/deps", "scrypath_ops/_build/test"]);
  assert.deepEqual(ecommerce.paths.resolved, ["deps", "_build/test"]);
  assert.ok(phoenix.paths.resolved.includes("examples/phoenix_meilisearch/_build/test"));

  const allPaths = JSON.stringify([root.paths, ops.paths, phoenix.paths]);
  assert.doesNotMatch(allPaths, /\.mix|HEX_HOME|MIX_HOME|no_optional_deps|package[-_]consumer/i);
  assert.doesNotMatch(allPaths, /~\/\.hex(?:\n|\s|$)/);
});

test("path-dependent CI cache consumers use their dependency graph and resolve before verification", () => {
  const consumers = [
    ["ops-ui", "ops", "ops-test", "mix verify.ops_ui"],
    ["phoenix-example", "phoenix-example", "phoenix-test", "mix verify.phoenix_example"],
    ["ecommerce-mounted", "ecommerce", "ecommerce-test", "mix verify.ecommerce_mounted"],
    ["ecommerce-e2e", "ecommerce", "ecommerce-test", "mix verify.ecommerce_e2e"]
  ];

  for (const [jobName, graph, profile, verifyCommand] of consumers) {
    const block = jobBlock(jobName);
    assert.match(block, new RegExp(`beam_cache\\.cjs plan --graph ${graph}`), `${jobName} should key its actual graph`);
    assert.match(block, /MIX_ENV: test/, `${jobName} should identify test compilation`);
    assert.match(block, /MIX_TARGET: host/, `${jobName} should identify the host target`);
    assert.match(block, new RegExp(`BEAM_CACHE_PROFILE: ${profile}`), `${jobName} should identify its compilation profile`);
    const cacheIndex = block.indexOf("actions/cache@");
    const depsIndex = block.indexOf("mix deps.get");
    const verifyIndex = block.indexOf(verifyCommand);
    assert.ok(cacheIndex >= 0 && depsIndex > cacheIndex, `${jobName} must resolve dependencies after cache restore`);
    assert.ok(verifyIndex > depsIndex, `${jobName} must run canonical verification after deps.get`);
  }

  const deepQuality = jobBlock("deep-quality");
  assert.match(deepQuality, /beam_cache\.cjs plan --graph root/);
  assert.match(deepQuality, /outputs\.plt_paths/);
  assert.match(deepQuality, /outputs\.plt_key/);
  const pltCache = deepQuality.match(/- uses: actions\/cache@[^\n]+\n(?:(?!      - ).*\n)*?          path: \$\{\{ steps\.beam_cache\.outputs\.plt_paths \}\}[\s\S]*?(?=      - |$)/);
  assert.ok(pltCache, "deep-quality should cache PLTs in their own action");
  assert.doesNotMatch(pltCache[0], /restore-keys:/, "PLT cache must remain exact-key only");
  assert.ok(deepQuality.indexOf("mix deps.get") > deepQuality.indexOf("actions/cache@"));
});

test("path graph manifests and locks fingerprint only the consuming resolved cache", (t) => {
  const root = fs.mkdtempSync(path.join(require("node:os").tmpdir(), "beam-cache-graph-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));

  const files = {
    "mix.exs": "root manifest\n",
    "mix.lock": "root lock\n",
    "lib/root.ex": "root source\n",
    "scrypath_ops/mix.exs": "ops manifest\n",
    "scrypath_ops/mix.lock": "ops lock\n",
    "scrypath_ops/lib/ops.ex": "ops source\n",
    "examples/scrypath_ecommerce/mix.exs": "ecommerce manifest\n",
    "examples/scrypath_ecommerce/mix.lock": "ecommerce lock\n",
    "examples/scrypath_ecommerce/lib/ecommerce.ex": "ecommerce source\n",
    "examples/phoenix_meilisearch/mix.exs": "phoenix manifest\n",
    "examples/phoenix_meilisearch/mix.lock": "phoenix lock\n",
    "examples/phoenix_meilisearch/lib/phoenix.ex": "phoenix source\n"
  };
  for (const [relative, contents] of Object.entries(files)) {
    const absolute = path.join(root, relative);
    fs.mkdirSync(path.dirname(absolute), { recursive: true });
    fs.writeFileSync(absolute, contents);
  }

  const env = {
    ImageOS: "ubuntu24",
    ImageVersion: "20261019.1.0",
    RUNNER_OS: "Linux",
    RUNNER_ARCH: "X64",
    MIX_ENV: "test",
    MIX_TARGET: "host",
    BEAM_CACHE_PROFILE: "fixture-test"
  };
  const versions = "Erlang/OTP 28.1 [erts-16.1]\nElixir 1.19.0 (compiled with Erlang/OTP 28)\n";
  const plan = (graph) => buildPlan({ graph, root, env, elixirVersionOutput: versions });
  const rootBefore = plan("root");
  const opsBefore = plan("ops");
  const phoenixBefore = plan("phoenix-example");

  fs.appendFileSync(path.join(root, "scrypath_ops/mix.lock"), "changed\n");
  const opsChanged = plan("ops");
  assert.notEqual(opsChanged.resolved_key, opsBefore.resolved_key);
  assert.equal(opsChanged.downloads_restore_prefix, opsBefore.downloads_restore_prefix);
  assert.equal(plan("root").resolved_key, rootBefore.resolved_key);
  fs.appendFileSync(path.join(root, "scrypath_ops/mix.exs"), "changed\n");
  assert.notEqual(plan("ops").downloads_restore_prefix, opsChanged.downloads_restore_prefix);

  const ecommerceBefore = plan("ecommerce");
  fs.appendFileSync(path.join(root, "examples/scrypath_ecommerce/mix.lock"), "changed\n");
  const ecommerceLockChanged = plan("ecommerce");
  assert.notEqual(ecommerceLockChanged.resolved_restore_prefix, ecommerceBefore.resolved_restore_prefix);
  assert.equal(ecommerceLockChanged.downloads_restore_prefix, ecommerceBefore.downloads_restore_prefix);
  fs.appendFileSync(path.join(root, "examples/scrypath_ecommerce/mix.exs"), "changed\n");
  assert.notEqual(plan("ecommerce").downloads_restore_prefix, ecommerceLockChanged.downloads_restore_prefix);

  fs.appendFileSync(path.join(root, "examples/phoenix_meilisearch/mix.lock"), "changed\n");
  const phoenixChanged = plan("phoenix-example");
  assert.notEqual(phoenixChanged.resolved_restore_prefix, phoenixBefore.resolved_restore_prefix);
  assert.equal(phoenixChanged.downloads_restore_prefix, phoenixBefore.downloads_restore_prefix);
  fs.appendFileSync(path.join(root, "examples/phoenix_meilisearch/mix.exs"), "changed\n");
  assert.notEqual(plan("phoenix-example").downloads_restore_prefix, phoenixChanged.downloads_restore_prefix);
});
