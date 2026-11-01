"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const zlib = require("node:zlib");
const bundle = require("./ui_preservation_bundle.cjs");
const png = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=", "base64");
const name = `${bundle.PREFIX}e1-empty-light-1440.png`;
const entries = [{ path: name, bytes: png }];
const mutate = (fn) => {
  const value = JSON.parse(zlib.gunzipSync(bundle.encodeBundle(entries)));
  fn(value);
  return zlib.gzipSync(Buffer.from(JSON.stringify(value)));
};

test("packaging preserves every raw byte and hash without editing PNGs", () => {
  const input = [...entries, { path: `${bundle.PREFIX}e2-empty-dark-390.png`, bytes: png }];
  const first = bundle.encodeBundle(input);
  assert.deepEqual(first, bundle.encodeBundle(input.slice().reverse()));
  const decoded = bundle.decodeBundle(first);
  assert.equal(decoded.size, 2);
  for (const item of input) assert.deepEqual(decoded.get(item.path), item.bytes);
});

test("tampered bytes, hash, size, noncanonical base64 and duplicate paths fail", () => {
  for (const change of [
    (v) => { v.entries[0].bytes_base64 = Buffer.from("changed").toString("base64"); },
    (v) => { v.entries[0].sha256 = "0".repeat(64); },
    (v) => { v.entries[0].size_bytes++; },
    (v) => { v.entries[0].bytes_base64 += "\n"; },
    (v) => { v.entries.push(v.entries[0]); },
    (v) => { v.entries[0].unexpected = true; },
  ]) assert.throws(() => bundle.decodeBundle(mutate(change)));
});

test("paths and compressed/expanded/member bounds remain closed", () => {
  for (const invalid of ["../outside.png", `${bundle.PREFIX}../outside.png`, `${bundle.PREFIX}nested/a.png`, `${bundle.PREFIX}.hidden.png`, `${bundle.PREFIX}a.json`]) {
    assert.throws(() => bundle.encodeBundle([{ path: invalid, bytes: png }]));
  }
  const packed = bundle.encodeBundle(entries);
  assert.throws(() => bundle.decodeBundle(packed, { ...bundle.LIMITS, compressed: packed.length - 1 }));
  assert.throws(() => bundle.decodeBundle(packed, { ...bundle.LIMITS, expanded: 32 }));
  assert.throws(() => bundle.decodeBundle(packed, { ...bundle.LIMITS, members: 0 }));
  assert.throws(() => bundle.encodeBundle(entries, { ...bundle.LIMITS, expanded: png.length - 1 }));
});

test("exclusive publication cannot replace an existing raw bundle", (t) => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "p185-bundle-"));
  t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  const target = path.join(directory, "raw.json.gz");
  const receipt = bundle.writeExclusive(target, entries);
  const before = fs.readFileSync(target);
  assert.equal(receipt.sha256, bundle.sha256(before));
  assert.throws(() => bundle.writeExclusive(target, entries), /EEXIST/);
  assert.deepEqual(fs.readFileSync(target), before);
  assert.deepEqual(fs.readdirSync(directory), ["raw.json.gz"]);
});

test("run packaging joins real staged bytes to observed paths and hashes", (t) => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "p185-pack-run-"));
  t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  const imagePath = path.join(directory, bundle.STAGING_PATH, name);
  fs.mkdirSync(path.dirname(imagePath), { recursive: true });
  fs.writeFileSync(imagePath, png);
  const event = { operation: "ui_preservation_case", observations: [{ images: [{ path: name, sha256: bundle.sha256(png) }] }] };
  fs.writeFileSync(path.join(directory, "phase105-evidence.ndjson"), `${JSON.stringify(event)}\n`);
  const receipt = bundle.packRun(directory);
  const members = bundle.loadRunBundle(directory, receipt.sha256);
  assert.deepEqual(members.get(name), png);
  assert.deepEqual(fs.readFileSync(imagePath), png, "raw staging remains unchanged");
  assert.throws(() => bundle.loadRunBundle(directory, "0".repeat(64)), /hash mismatch/);
});

test("run packaging rejects unobserved, missing, tampered and symlinked staging", (t) => {
  for (const failure of ["extra", "missing", "tampered", "symlink", "reused", "empty-directory"]) {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), "p185-pack-negative-"));
    t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
    const imagePath = path.join(directory, bundle.STAGING_PATH, name);
    fs.mkdirSync(path.dirname(imagePath), { recursive: true });
    fs.writeFileSync(imagePath, png);
    const image = { path: name, sha256: bundle.sha256(png) };
    const observations = [{ images: [image] }];
    if (failure === "extra") fs.writeFileSync(path.join(path.dirname(imagePath), "extra.png"), png);
    if (failure === "missing") fs.unlinkSync(imagePath);
    if (failure === "tampered") fs.writeFileSync(imagePath, "changed");
    if (failure === "symlink") { fs.unlinkSync(imagePath); fs.symlinkSync(__filename, imagePath); }
    if (failure === "reused") observations.push({ images: [image] });
    if (failure === "empty-directory") fs.mkdirSync(path.join(path.dirname(imagePath), "unobserved-empty"));
    fs.writeFileSync(path.join(directory, "phase105-evidence.ndjson"), `${JSON.stringify({ operation: "ui_preservation_case", observations })}\n`);
    assert.throws(() => bundle.packRun(directory), undefined, failure);
    assert.equal(fs.existsSync(path.join(directory, bundle.BUNDLE_PATH)), false);
  }
});

test("aggregate staged size is rejected before any member body/hash is read", (t) => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "p185-pack-size-"));
  t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  const images = [];
  for (let index = 0; index < 5; index++) {
    const name = `${bundle.PREFIX}oversized-${index}.png`;
    const file = path.join(directory, bundle.STAGING_PATH, name);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    const fd = fs.openSync(file, "wx");
    fs.writeSync(fd, png.subarray(0, 8));
    fs.ftruncateSync(fd, 64 * 1024 * 1024);
    fs.closeSync(fd);
    images.push({ path: name, sha256: "0".repeat(64) });
  }
  fs.writeFileSync(path.join(directory, "phase105-evidence.ndjson"), JSON.stringify({ operation: "ui_preservation_case", observations: [{ images }] }) + "\n");
  assert.throws(() => bundle.packRun(directory), /expanded byte bound before reading/);
  assert.equal(fs.existsSync(path.join(directory, bundle.BUNDLE_PATH)), false);
});

test("bundle readers reject a symlinked artifact parent", (t) => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "p185-bundle-parent-"));
  t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  const source = path.join(directory, "source");
  const run = path.join(directory, "run");
  fs.mkdirSync(source);
  fs.mkdirSync(run);
  fs.symlinkSync(source, path.join(run, "ui-review-artifacts"));
  assert.throws(() => bundle.loadRunBundle(run, "0".repeat(64)), /symlinks/);
});
