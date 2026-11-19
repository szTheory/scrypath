// Self-test for scripts/reskin-capture.mjs (Phase 187, SKIN-08): the pure parts only. No browser, no
// stack. What it proves: the inventory check accepts a complete set and names whatever is missing,
// altered or extra, and the dirty-tree refusal fires for tracked changes outside `.planning/` only.
//
//   node --test scripts/reskin-capture.selftest.mjs

import { test, after } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, unlinkSync, writeFileSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { MANIFEST_NAME, SCENARIO, SCHEMA, assertCleanTree, checkInventory, expectedFiles, sha256 } from "./reskin-capture.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SCRIPT = path.join(HERE, "reskin-capture.mjs");

const roots = [];
after(() => {
  for (const dir of roots) rmSync(dir, { recursive: true, force: true });
});

/** A complete capture directory: 12 distinct stand-in PNGs and a manifest that matches them. */
function makeCaptureDir() {
  const dir = mkdtempSync(path.join(os.tmpdir(), "reskin-capture-selftest-"));
  roots.push(dir);
  const files = expectedFiles().map((name) => {
    const bytes = Buffer.from(`not a real png: ${name}`);
    writeFileSync(path.join(dir, name), bytes);
    return { name, sha256: sha256(bytes) };
  });
  const manifest = { schema: SCHEMA, label: "before", source_sha: "0".repeat(40), clean: true, git_status: [], files };
  writeFileSync(path.join(dir, MANIFEST_NAME), `${JSON.stringify(manifest, null, 2)}\n`);
  return dir;
}

test("expected inventory is three screens, light and dark, 1280 and 390", () => {
  const names = expectedFiles();
  assert.equal(names.length, 12);
  assert.equal(new Set(names).size, 12);
  for (const screen of ["control-room", "search-health", "failed-sync"]) {
    for (const theme of ["light", "dark"]) {
      for (const width of [1280, 390]) assert.ok(names.includes(`${screen}-${theme}-${width}.png`), `${screen}-${theme}-${width}`);
    }
  }
});

test("the capture scenario is the all-statuses fixture", () => {
  assert.equal(SCENARIO, "all-statuses");
  assert.match(readFileSync(SCRIPT, "utf8"), /phase173\/health\?scenario=\$\{SCENARIO\}/);
});

test("inventory check passes on a complete set with a matching manifest", () => {
  const result = checkInventory(makeCaptureDir());
  assert.deepEqual(result.errors, []);
  assert.equal(result.ok, true);
  assert.equal(result.count, 12);
});

test("inventory check fails naming the file when one PNG is removed", () => {
  const dir = makeCaptureDir();
  const gone = "search-health-dark-390.png";
  unlinkSync(path.join(dir, gone));
  const result = checkInventory(dir);
  assert.equal(result.ok, false);
  assert.equal(result.count, 11);
  assert.ok(result.errors.some((error) => error.includes(gone)), result.errors.join("\n"));
});

test("inventory check fails when a hash differs from the manifest", () => {
  const dir = makeCaptureDir();
  const altered = "control-room-light-1280.png";
  writeFileSync(path.join(dir, altered), "changed after the manifest was written");
  const result = checkInventory(dir);
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((error) => error.includes("hash mismatch") && error.includes(altered)), result.errors.join("\n"));
});

test("inventory check fails when the manifest is missing", () => {
  const dir = makeCaptureDir();
  unlinkSync(path.join(dir, MANIFEST_NAME));
  const result = checkInventory(dir);
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((error) => error.includes(MANIFEST_NAME)), result.errors.join("\n"));
});

test("inventory check fails when a file is not listed in the manifest or an extra file is present", () => {
  const dir = makeCaptureDir();
  const manifestPath = path.join(dir, MANIFEST_NAME);
  const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
  manifest.files = manifest.files.filter((entry) => entry.name !== "failed-sync-dark-1280.png");
  writeFileSync(manifestPath, JSON.stringify(manifest));
  assert.ok(checkInventory(dir).errors.some((error) => error.includes("failed-sync-dark-1280.png is not listed")));

  const clean = makeCaptureDir();
  writeFileSync(path.join(clean, "contact-sheet.png"), "derivative");
  assert.ok(checkInventory(clean).errors.some((error) => error.includes("contact-sheet.png")));
});

test("inventory check fails on a missing directory", () => {
  const result = checkInventory(path.join(os.tmpdir(), "reskin-capture-selftest-does-not-exist"));
  assert.equal(result.ok, false);
});

test("the --check command prints the inventory count and exits non-zero when incomplete", () => {
  const good = spawnSync(process.execPath, [SCRIPT, "--check", makeCaptureDir()], { encoding: "utf8" });
  assert.equal(good.status, 0, good.stderr);
  assert.match(good.stdout, /capture inventory: 12\/12/);

  const dir = makeCaptureDir();
  unlinkSync(path.join(dir, "control-room-dark-390.png"));
  const bad = spawnSync(process.execPath, [SCRIPT, "--check", dir], { encoding: "utf8" });
  assert.notEqual(bad.status, 0);
  assert.match(bad.stderr, /control-room-dark-390\.png/);
  assert.doesNotMatch(bad.stdout, /capture inventory: 12\/12/);
});

test("clean-tree refusal throws on a tracked change outside .planning", () => {
  assert.throws(() => assertCleanTree(" M scrypath_ops/assets/css/app.css\n"), /dirty tree.*scrypath_ops\/assets\/css\/app\.css/);
  assert.throws(() => assertCleanTree("M  examples/scrypath_ecommerce/e2e/ui-review.mjs\n"), /ui-review\.mjs/);
  assert.throws(() => assertCleanTree(" M .planning/UI-PREVIEW.json\n D lib/scrypath.ex\n"), /lib\/scrypath\.ex/);
  assert.throws(() => assertCleanTree("R  .planning/old.md -> docs/new.md\n"), /docs\/new\.md/);
});

test("clean-tree refusal accepts a status that only lists .planning paths, untracked or ignored files, or nothing", () => {
  assert.doesNotThrow(() => assertCleanTree(""));
  assert.doesNotThrow(() => assertCleanTree(" M .planning/UI-PREVIEW.json\n?? .planning/notes.md\n"));
  assert.doesNotThrow(() => assertCleanTree("?? examples/scrypath_ecommerce/priv/playbooks/my-search.json\n!! node_modules/\n"));
});

test("inventory check flags a nested directory as unexpected", () => {
  const dir = makeCaptureDir();
  mkdirSync(path.join(dir, "nested"), { recursive: true });
  assert.ok(checkInventory(dir).errors.some((error) => error.includes("nested")));
});
