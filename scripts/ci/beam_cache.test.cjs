const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const { cacheIdentity, cachePlan, runtimeIdentity } = require("./beam_cache.cjs");

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
    assert.match(block, /beam_cache\.cjs plan --graph root/, `${name} should derive its cache identity from the runtime`);
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
  const phoenix = cachePlan(identity({ graph: "phoenix-example" }));
  assert.deepEqual(root.paths.downloads, ["~/.hex/packages"]);
  assert.deepEqual(root.paths.resolved, ["deps", "_build/test"]);
  assert.deepEqual(root.paths.plt, ["priv/plts"]);
  assert.deepEqual(ops.paths.resolved, ["deps", "_build/test", "scrypath_ops/deps", "scrypath_ops/_build/test"]);
  assert.ok(phoenix.paths.resolved.includes("examples/phoenix_meilisearch/_build/test"));

  const allPaths = JSON.stringify([root.paths, ops.paths, phoenix.paths]);
  assert.doesNotMatch(allPaths, /\.mix|HEX_HOME|MIX_HOME|no_optional_deps|package[-_]consumer/i);
  assert.doesNotMatch(allPaths, /~\/\.hex(?:\n|\s|$)/);
});
