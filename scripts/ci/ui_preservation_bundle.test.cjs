"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const zlib = require("node:zlib");
const bundle = require("./ui_preservation_bundle.cjs");
const png = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=", "base64");
const state = Buffer.from('{"url":"/ops","width":390,"height":844}\n');
const name = `${bundle.PREFIX}e1-empty-light-1440.png`;
const entries = [{ path: name, bytes: png }];
const unpack = (packed) => JSON.parse(zlib.gunzipSync(packed).toString("utf8"));
const mutate = (fn, sourceEntries = entries) => {
  const value = unpack(bundle.encodeBundle(sourceEntries));
  fn(value);
  return zlib.gzipSync(Buffer.from(JSON.stringify(value)));
};

function sampleRun(t, failure = null) {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "p185-sample-run-"));
  t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  const staging = path.join(directory, bundle.STAGING_PATH, bundle.PREFIX);
  fs.mkdirSync(staging, { recursive: true });
  const selected = { path: `${bundle.PREFIX}selected.png`, bytes: png };
  const selectedReceipt = { path: selected.path, sha256: bundle.sha256(png) };
  fs.writeFileSync(path.join(staging, path.basename(selected.path)), selected.bytes);
  const samples = [];
  for (let index = 0; index < 6; index++) {
    const suffix = String(index + 1).padStart(2, "0");
    const image = { path: `${bundle.PREFIX}sample-${suffix}.png`, sha256: bundle.sha256(png) };
    const statePath = `${bundle.PREFIX}sample-${suffix}.json`;
    const stateHash = bundle.sha256(state);
    samples.push({ ...image, state_path: statePath, state_sha256: stateHash });
    if (failure !== "missing-sample-image" || index !== 5) fs.writeFileSync(path.join(staging, path.basename(image.path)), png);
    if (failure !== "missing-sample-state" || index !== 5) fs.writeFileSync(path.join(staging, path.basename(statePath)), state);
    if (failure === "tampered-sample-state" && index === 5) fs.writeFileSync(path.join(staging, path.basename(statePath)), Buffer.from('{"url":"/changed"}'));
    if (failure === "tampered-sample-image" && index === 5) fs.writeFileSync(path.join(staging, path.basename(image.path)), Buffer.from("changed"));
  }
  if (failure === "extra-sample") fs.writeFileSync(path.join(staging, "unobserved.json"), state);
  const event = {
    operation: "ui_preservation_case",
    observations: [{ image: selectedReceipt, capture_sampling: { samples } }],
  };
  fs.writeFileSync(path.join(directory, "phase105-evidence.ndjson"), `${JSON.stringify(event)}\n`);
  return { directory, selected, samples };
}

test("packaging preserves every raw byte and hash while deduplicating equal payloads", () => {
  const input = [
    ...entries,
    { path: `${bundle.PREFIX}e2-empty-dark-390.png`, bytes: png },
    { path: `${bundle.PREFIX}sample-01.json`, bytes: state },
    { path: `${bundle.PREFIX}sample-02.json`, bytes: state },
  ];
  const first = bundle.encodeBundle(input);
  assert.deepEqual(first, bundle.encodeBundle(input.slice().reverse()));
  const value = unpack(first);
  assert.equal(value.entries.length, 4);
  assert.equal(value.blobs.length, 2);
  const decoded = bundle.decodeBundle(first);
  assert.equal(decoded.size, 4);
  assert.strictEqual(decoded.get(name), decoded.get(`${bundle.PREFIX}e2-empty-dark-390.png`));
  assert.strictEqual(decoded.get(`${bundle.PREFIX}sample-01.json`), decoded.get(`${bundle.PREFIX}sample-02.json`));
  for (const item of input) assert.deepEqual(decoded.get(item.path), item.bytes);
});

test("tampered blob bytes, hash, size, noncanonical base64 and duplicate paths fail", () => {
  for (const change of [
    (v) => { v.blobs[0].bytes_base64 = Buffer.from("changed").toString("base64"); },
    (v) => { v.blobs[0].sha256 = "0".repeat(64); },
    (v) => { v.blobs[0].size_bytes++; },
    (v) => { v.blobs[0].bytes_base64 += "\n"; },
    (v) => { v.entries.push(v.entries[0]); },
    (v) => { v.entries[0].unexpected = true; },
  ]) assert.throws(() => bundle.decodeBundle(mutate(change)));
});

test("missing, unreferenced, duplicate and invalid blobs are rejected", () => {
  const jsonBlob = { sha256: bundle.sha256(state), size_bytes: state.length, bytes_base64: state.toString("base64") };
  for (const change of [
    (v) => { v.blobs = []; },
    (v) => { v.blobs.push(jsonBlob); },
    (v) => { v.blobs.push(v.blobs[0]); },
    (v) => { v.blobs[0].extra = true; },
    (v) => { v.blobs[0].sha256 = "A".repeat(64); },
  ]) assert.throws(() => bundle.decodeBundle(mutate(change)));
});

test("paths, payload formats and compressed/expanded/member bounds remain closed", () => {
  for (const invalid of ["../outside.png", `${bundle.PREFIX}../outside.png`, `${bundle.PREFIX}nested/a.png`, `${bundle.PREFIX}.hidden.png`, `${bundle.PREFIX}a.txt`]) {
    assert.throws(() => bundle.encodeBundle([{ path: invalid, bytes: png }]));
  }
  assert.throws(() => bundle.encodeBundle([{ path: `${bundle.PREFIX}invalid.json`, bytes: Buffer.from([0xff]) }]));
  assert.throws(() => bundle.encodeBundle([{ path: `${bundle.PREFIX}invalid.json`, bytes: Buffer.from("not json") }]));
  assert.throws(() => bundle.encodeBundle([{ path: `${bundle.PREFIX}invalid.png`, bytes: Buffer.from("not png") }]));
  const packed = bundle.encodeBundle(entries);
  assert.throws(() => bundle.decodeBundle(packed, { ...bundle.LIMITS, compressed: packed.length - 1 }));
  assert.throws(() => bundle.decodeBundle(packed, { ...bundle.LIMITS, expanded: 32 }));
  assert.throws(() => bundle.decodeBundle(packed, { ...bundle.LIMITS, members: 0 }));
  assert.throws(() => bundle.encodeBundle(entries, { ...bundle.LIMITS, expanded: png.length - 1 }));
  assert.equal(bundle.LIMITS.members, 2769);
  const tooMany = Array.from({ length: bundle.LIMITS.members + 1 }, (_, index) => ({
    path: `${bundle.PREFIX}entry-${String(index).padStart(4, "0")}.png`, bytes: png,
  }));
  assert.throws(() => bundle.encodeBundle(tooMany), /member count/);
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

test("run packaging binds all six sample images and states and preserves content deduplication", (t) => {
  const { directory, samples } = sampleRun(t);
  const receipt = bundle.packRun(directory);
  const members = bundle.loadRunBundle(directory, receipt.sha256);
  assert.equal(receipt.members, 13);
  assert.equal(members.size, 13);
  const value = unpack(fs.readFileSync(path.join(directory, bundle.BUNDLE_PATH)));
  assert.equal(value.blobs.length, 2);
  for (const sample of samples) {
    assert.deepEqual(members.get(sample.path), png);
    assert.deepEqual(members.get(sample.state_path), state);
    assert.strictEqual(members.get(sample.path), members.get(samples[0].path));
    assert.strictEqual(members.get(sample.state_path), members.get(samples[0].state_path));
  }
});

test("run packaging rejects missing or altered sample files and extra staged files", (t) => {
  for (const failure of ["missing-sample-image", "missing-sample-state", "tampered-sample-image", "tampered-sample-state", "extra-sample"]) {
    const { directory } = sampleRun(t, failure);
    assert.throws(() => bundle.packRun(directory), undefined, failure);
    assert.equal(fs.existsSync(path.join(directory, bundle.BUNDLE_PATH)), false);
  }
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

test("run packaging rejects unobserved, missing, tampered, duplicate and symlinked staging", (t) => {
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

test("aggregate logical size is rejected before any member body/hash is read", (t) => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "p185-pack-size-"));
  t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  const images = [];
  for (let index = 0; index < 5; index++) {
    const fileName = `${bundle.PREFIX}oversized-${index}.png`;
    const file = path.join(directory, bundle.STAGING_PATH, fileName);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    const fd = fs.openSync(file, "wx");
    fs.writeSync(fd, png.subarray(0, 8));
    fs.ftruncateSync(fd, 64 * 1024 * 1024);
    fs.closeSync(fd);
    images.push({ path: fileName, sha256: "0".repeat(64) });
  }
  fs.writeFileSync(path.join(directory, "phase105-evidence.ndjson"), JSON.stringify({ operation: "ui_preservation_case", observations: [{ images }] }) + "\n");
  assert.throws(() => bundle.packRun(directory), /logical member byte bound/);
  assert.equal(fs.existsSync(path.join(directory, bundle.BUNDLE_PATH)), false);
});

test("serialized Base64 expansion is preflighted from sparse metadata before payload reads", (t) => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "p185-pack-serialized-size-"));
  t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  const images = [];
  for (let index = 0; index < 4; index++) {
    const imagePath = `${bundle.PREFIX}serialized-${index}.png`;
    const file = path.join(directory, bundle.STAGING_PATH, imagePath);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    const fd = fs.openSync(file, "wx");
    fs.writeSync(fd, png.subarray(0, 8));
    fs.ftruncateSync(fd, 49 * 1024 * 1024);
    fs.closeSync(fd);
    images.push({ path: imagePath, sha256: `${String(index).repeat(64)}` });
  }
  fs.writeFileSync(path.join(directory, "phase105-evidence.ndjson"), JSON.stringify({
    operation: "ui_preservation_case", observations: [{ images }],
  }) + "\n");
  assert.throws(() => bundle.packRun(directory), /expanded byte bound before payload encoding/);
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
