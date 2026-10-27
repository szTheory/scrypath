const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

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
    assert.match(block, /_build\/test/, `${name} should avoid restoring unrelated compiled environments`);
    assert.match(block, /resolved_restore_prefix/, `${name} should retain exact-lock compatibility for resolved state`);
  }
});

test("cache paths never include Hex or Mix credentials", () => {
  assert.doesNotMatch(workflow, /~\/(?:\.hex|\.mix)(?:\n|\s)*$/m);
  assert.doesNotMatch(workflow, /~\/\.mix(?:\/|\s|$)/);
});
