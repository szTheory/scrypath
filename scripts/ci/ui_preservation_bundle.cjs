"use strict";

// Raw PNG packaging only. Source, case, dimensions and runtime authority belong
// to the caller's evidence validator; this module preserves and bounds bytes.
const fs = require("node:fs");
const path = require("node:path");
const crypto = require("node:crypto");
const zlib = require("node:zlib");
const SCHEMA = "scrypath.ui-preservation-raw-bundle.v1";
const PREFIX = "ui-review-artifacts/iteration3-journeys/phase185-held-out/";
const BUNDLE_PATH = "ui-review-artifacts/iteration3-journeys/phase185-held-out.bundle.json.gz";
const STAGING_PATH = "phase185-raw-staging";
const LIMITS = Object.freeze({ compressed: 64 * 1024 * 1024, expanded: 256 * 1024 * 1024, members: 1024 });
const sha256 = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");

function memberPath(value) {
  if (typeof value !== "string" || !value.startsWith(PREFIX) ||
      !/^[a-z0-9][a-z0-9-]*\.png$/.test(value.slice(PREFIX.length))) {
    throw new Error("Invalid raw PNG bundle member path");
  }
  return value;
}

function exactKeys(value, keys) {
  if (!value || typeof value !== "object" || Array.isArray(value) ||
      JSON.stringify(Object.keys(value).sort()) !== JSON.stringify(keys.slice().sort())) {
    throw new Error("Unexpected raw PNG bundle fields");
  }
}

function decodeBundle(bytes, limits = LIMITS) {
  if (!Buffer.isBuffer(bytes) || bytes.length === 0 || bytes.length > limits.compressed) throw new Error("Raw PNG bundle exceeds compressed byte bound");
  const expanded = zlib.gunzipSync(bytes, { maxOutputLength: limits.expanded });
  const value = JSON.parse(expanded.toString("utf8"));
  exactKeys(value, ["schema", "entries"]);
  if (value.schema !== SCHEMA || !Array.isArray(value.entries) || value.entries.length === 0 || value.entries.length > limits.members) throw new Error("Invalid raw PNG bundle schema/member count");
  const members = new Map();
  let total = 0;
  for (const entry of value.entries) {
    exactKeys(entry, ["path", "sha256", "size_bytes", "bytes_base64"]);
    const name = memberPath(entry.path);
    if (members.has(name)) throw new Error("Duplicate raw PNG bundle member");
    if (!/^[a-f0-9]{64}$/.test(entry.sha256) || !Number.isSafeInteger(entry.size_bytes) || entry.size_bytes <= 0 ||
        typeof entry.bytes_base64 !== "string" || entry.bytes_base64.length > Math.ceil(limits.expanded / 3) * 4) throw new Error("Invalid raw PNG bundle member metadata");
    const raw = Buffer.from(entry.bytes_base64, "base64");
    total += raw.length;
    if (total > limits.expanded || raw.length !== entry.size_bytes || raw.toString("base64") !== entry.bytes_base64 || sha256(raw) !== entry.sha256) throw new Error("Raw PNG bundle member byte/hash mismatch");
    if (raw.length < 8 || !raw.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10]))) throw new Error("Raw bundle member is not PNG bytes");
    members.set(name, raw);
  }
  return members;
}

function encodeBundle(entries, limits = LIMITS) {
  if (!Array.isArray(entries) || entries.length === 0 || entries.length > limits.members) throw new Error("Invalid raw PNG bundle member count");
  const names = new Set();
  let total = 0;
  for (const { path: name, bytes } of entries) {
    memberPath(name);
    if (names.has(name)) throw new Error("Duplicate raw PNG bundle member");
    if (!Buffer.isBuffer(bytes) || bytes.length === 0) throw new Error("Raw PNG bundle members need bytes");
    names.add(name);
    total += bytes.length;
    if (total > limits.expanded) throw new Error("Raw PNG bundle exceeds expanded byte bound");
  }
  assertSerializedBound(entries.map(({ path, bytes }) => ({ path, size_bytes: bytes.length })), limits);
  const serialized = entries.map(({ path, bytes }) => ({ path, sha256: sha256(bytes), size_bytes: bytes.length, bytes_base64: bytes.toString("base64") }));
  serialized.sort((a, b) => a.path.localeCompare(b.path));
  const json = Buffer.from(JSON.stringify({ schema: SCHEMA, entries: serialized }));
  if (json.length > limits.expanded) throw new Error("Raw PNG bundle exceeds expanded byte bound");
  const packed = zlib.gzipSync(json, { level: 6 });
  const decoded = decodeBundle(packed, limits);
  for (const entry of entries) if (!decoded.get(entry.path).equals(entry.bytes)) throw new Error("Raw PNG packaging roundtrip differs");
  return packed;
}

function assertSerializedBound(entries, limits = LIMITS) {
  let size = Buffer.byteLength(JSON.stringify({ schema: SCHEMA, entries: [] }));
  for (let index = 0; index < entries.length; index++) {
    const entry = entries[index];
    size += Buffer.byteLength(JSON.stringify({ path: entry.path, sha256: "0".repeat(64), size_bytes: entry.size_bytes, bytes_base64: "" })) + Math.ceil(entry.size_bytes / 3) * 4 + (index ? 1 : 0);
    if (size > limits.expanded) throw new Error("Raw PNG bundle exceeds expanded byte bound before reading/encoding members");
  }
}

function writeExclusive(target, entries) {
  const bytes = encodeBundle(entries);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  const temporary = `${target}.tmp-${process.pid}-${crypto.randomBytes(8).toString("hex")}`;
  let fd;
  try {
    fd = fs.openSync(temporary, "wx", 0o600);
    fs.writeFileSync(fd, bytes);
    fs.fsyncSync(fd);
    fs.closeSync(fd); fd = undefined;
    // link is exclusive even when another publisher creates target concurrently.
    fs.linkSync(temporary, target);
    const actual = fs.readFileSync(target);
    if (!actual.equals(bytes)) throw new Error("Published raw PNG bundle differs");
    return { path: target, sha256: sha256(bytes), size_bytes: bytes.length, members: entries.length };
  } finally {
    if (fd !== undefined) fs.closeSync(fd);
    try { fs.unlinkSync(temporary); } catch (error) { if (error.code !== "ENOENT") throw error; }
  }
}

function readRegular(file, maxBytes) {
  const stat = fs.lstatSync(file);
  if (!stat.isFile() || stat.isSymbolicLink() || stat.size > maxBytes) throw new Error("Raw bundle input must be a bounded regular file");
  const bytes = fs.readFileSync(file);
  if (bytes.length !== stat.size || bytes.length > maxBytes) throw new Error("Raw bundle input changed while reading");
  return bytes;
}

function runPath(root, relative, createParents = false) {
  const segments = relative.split("/");
  if (segments.some((part) => !part || part === "." || part === "..")) throw new Error("Unsafe raw bundle run path");
  let parent = root;
  for (const part of segments.slice(0, -1)) {
    parent = path.join(parent, part);
    if (createParents && !fs.existsSync(parent)) fs.mkdirSync(parent);
    const stat = fs.lstatSync(parent);
    if (!stat.isDirectory() || stat.isSymbolicLink()) throw new Error("Raw bundle parent directories must not be symlinks");
  }
  return path.join(parent, segments.at(-1));
}

function packRun(runRoot) {
  const root = fs.realpathSync(runRoot);
  const lines = readRegular(path.join(root, "phase105-evidence.ndjson"), 16 * 1024 * 1024).toString("utf8").split(/\r?\n/).filter(Boolean);
  const records = lines.map((line) => JSON.parse(line)).filter((record) => record.operation === "ui_preservation_case");
  const expected = new Map();
  for (const record of records) {
    const observations = Array.isArray(record.observations) ? record.observations : [record];
    for (const observation of observations) for (const image of observation.images || []) {
      const name = memberPath(image.path);
      if (expected.has(name)) throw new Error("Raw PNG path reused by distinct observations");
      if (!/^[a-f0-9]{64}$/.test(image.sha256 || "")) throw new Error("Raw PNG event needs its actual SHA-256");
      expected.set(name, image.sha256);
    }
  }
  if (!expected.size || expected.size > LIMITS.members) throw new Error("No bounded raw PNG event inventory");
  const staging = path.join(root, STAGING_PATH);
  function directoryEntries(directory, limit, visit) {
    const stat = fs.lstatSync(directory);
    if (!stat.isDirectory() || stat.isSymbolicLink()) throw new Error("Raw PNG staging directories must not be symlinks");
    const dir = fs.opendirSync(directory);
    let count = 0;
    try {
      let entry;
      while ((entry = dir.readSync()) !== null) {
        if (++count > limit) throw new Error("Raw PNG staging exceeds its expected entry bound");
        visit(entry);
      }
    } finally { dir.closeSync(); }
    return count;
  }
  let directory = staging;
  for (const component of PREFIX.split("/").filter(Boolean)) {
    const count = directoryEntries(directory, 1, (entry) => {
      if (entry.name !== component || !entry.isDirectory() || entry.isSymbolicLink()) throw new Error("Unexpected raw PNG staging directory");
    });
    if (count !== 1) throw new Error("Missing raw PNG staging directory");
    directory = path.join(directory, component);
  }
  const files = [];
  directoryEntries(directory, expected.size, (entry) => {
    if (!entry.isFile() || entry.isSymbolicLink()) throw new Error("Raw PNG staging must contain regular files only");
    const name = memberPath(`${PREFIX}${entry.name}`);
    if (!expected.has(name)) throw new Error("Unobserved raw PNG staging member");
    files.push(name);
  });
  if (files.length !== expected.size) throw new Error("Staged raw PNGs differ from the observed event inventory");
  const metadata = files.map((name) => {
    const stat = fs.lstatSync(path.join(staging, name));
    if (!stat.isFile() || stat.isSymbolicLink() || stat.size > LIMITS.compressed) throw new Error("Raw bundle input must be a bounded regular file");
    return { path: name, size_bytes: stat.size };
  });
  // Bound the complete serialized allocation before reading any PNG body.
  assertSerializedBound(metadata);
  const entries = files.map((name) => {
    const bytes = readRegular(path.join(staging, name), LIMITS.compressed);
    if (sha256(bytes) !== expected.get(name)) throw new Error("Staged raw PNG hash differs from its observed receipt");
    return { path: name, bytes };
  });
  return writeExclusive(runPath(root, BUNDLE_PATH, true), entries);
}

function loadRunBundle(runRoot, expectedSha256) {
  const bytes = readRegular(runPath(fs.realpathSync(runRoot), BUNDLE_PATH), LIMITS.compressed);
  if (!/^[a-f0-9]{64}$/.test(expectedSha256 || "") || sha256(bytes) !== expectedSha256) throw new Error("Raw PNG bundle artifact hash mismatch");
  return decodeBundle(bytes);
}

if (require.main === module) {
  try {
    if (process.argv.length !== 5 || process.argv[2] !== "pack" || process.argv[3] !== "--run-dir") throw new Error("Usage: ui_preservation_bundle.cjs pack --run-dir DIR");
    process.stdout.write(`${JSON.stringify(packRun(process.argv[4]))}\n`);
  } catch (error) { process.stderr.write(`raw PNG bundle: ${error.message}\n`); process.exitCode = 1; }
}

module.exports = { SCHEMA, PREFIX, BUNDLE_PATH, STAGING_PATH, LIMITS, memberPath, decodeBundle, encodeBundle, writeExclusive, packRun, loadRunBundle, sha256 };
