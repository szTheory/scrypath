"use strict";

// Raw PNG/sample-state packaging only. Source, case, dimensions and runtime
// authority belong to the caller's evidence validator; this module preserves
// payload bytes and bounds both logical members and the serialized bundle.
const fs = require("node:fs");
const path = require("node:path");
const crypto = require("node:crypto");
const zlib = require("node:zlib");
const { TextDecoder } = require("node:util");
const SCHEMA = "scrypath.ui-preservation-raw-bundle.v2";
const PREFIX = "ui-review-artifacts/iteration3-journeys/phase185-held-out/";
const BUNDLE_PATH = "ui-review-artifacts/iteration3-journeys/phase185-held-out.bundle.json.gz";
const STAGING_PATH = "phase185-raw-staging";
const MAX_LOGICAL_MEMBERS = 213 * (2 * 6 + 1);
const LIMITS = Object.freeze({ compressed: 64 * 1024 * 1024, expanded: 256 * 1024 * 1024, members: MAX_LOGICAL_MEMBERS });
const PNG_SIGNATURE = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
const sha256 = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");

function memberPath(value) {
  if (typeof value !== "string" || !value.startsWith(PREFIX) ||
      !/^[a-z0-9][a-z0-9-]*\.(?:png|json)$/.test(value.slice(PREFIX.length))) {
    throw new Error("Invalid raw preservation bundle member path");
  }
  return value;
}

function memberType(name) {
  return name.endsWith(".png") ? "png" : "json";
}

function validateMemberBytes(name, bytes) {
  if (memberType(name) === "png") {
    if (bytes.length < PNG_SIGNATURE.length || !bytes.subarray(0, PNG_SIGNATURE.length).equals(PNG_SIGNATURE)) {
      throw new Error("Raw bundle PNG member has an invalid signature");
    }
    return;
  }

  try {
    const text = new TextDecoder("utf-8", { fatal: true }).decode(bytes);
    JSON.parse(text);
  } catch {
    throw new Error("Raw bundle JSON member must be valid UTF-8 JSON");
  }
}

function exactKeys(value, keys) {
  if (!value || typeof value !== "object" || Array.isArray(value) ||
      JSON.stringify(Object.keys(value).sort()) !== JSON.stringify(keys.slice().sort())) {
    throw new Error("Unexpected raw preservation bundle fields");
  }
}

function assertSerializedBound(entries, blobs, limits = LIMITS) {
  if (!Array.isArray(entries) || !Array.isArray(blobs) ||
      entries.length === 0 || entries.length > limits.members ||
      blobs.length === 0 || blobs.length > entries.length) {
    throw new Error("Invalid raw preservation bundle member count");
  }

  let logicalBytes = 0;
  const memberNames = new Set();
  const blobSizes = new Map();
  let serializedBytes = Buffer.byteLength(JSON.stringify({ schema: SCHEMA, entries: [], blobs: [] }));

  for (let index = 0; index < entries.length; index++) {
    const entry = entries[index];
    memberPath(entry.path);
    if (!/^[a-f0-9]{64}$/.test(entry.sha256 || "") || !Number.isSafeInteger(entry.size_bytes) || entry.size_bytes <= 0 || memberNames.has(entry.path)) {
      throw new Error("Invalid raw preservation bundle member metadata");
    }
    memberNames.add(entry.path);
    logicalBytes += entry.size_bytes;
    if (logicalBytes > limits.expanded) throw new Error("Raw preservation bundle exceeds logical member byte bound");
    serializedBytes += Buffer.byteLength(JSON.stringify(entry)) + (index ? 1 : 0);
    if (serializedBytes > limits.expanded) throw new Error("Raw preservation bundle exceeds expanded byte bound before payload encoding");
  }

  for (let index = 0; index < blobs.length; index++) {
    const blob = blobs[index];
    if (!/^[a-f0-9]{64}$/.test(blob.sha256 || "") || !Number.isSafeInteger(blob.size_bytes) || blob.size_bytes <= 0 || blobSizes.has(blob.sha256)) {
      throw new Error("Invalid raw preservation bundle blob metadata");
    }
    blobSizes.set(blob.sha256, blob.size_bytes);
    serializedBytes += Buffer.byteLength(JSON.stringify({ sha256: blob.sha256, size_bytes: blob.size_bytes, bytes_base64: "" })) + Math.ceil(blob.size_bytes / 3) * 4 + (index ? 1 : 0);
    if (serializedBytes > limits.expanded) throw new Error("Raw preservation bundle exceeds expanded byte bound before payload encoding");
  }

  for (const entry of entries) {
    if (blobSizes.get(entry.sha256) !== entry.size_bytes) throw new Error("Raw preservation member does not match its blob metadata");
  }
}

function decodeBundle(bytes, limits = LIMITS) {
  if (!Buffer.isBuffer(bytes) || bytes.length === 0 || bytes.length > limits.compressed) throw new Error("Raw preservation bundle exceeds compressed byte bound");
  const expanded = zlib.gunzipSync(bytes, { maxOutputLength: limits.expanded });
  const value = JSON.parse(expanded.toString("utf8"));
  exactKeys(value, ["schema", "entries", "blobs"]);
  if (value.schema !== SCHEMA || !Array.isArray(value.entries) || !Array.isArray(value.blobs)) throw new Error("Invalid raw preservation bundle schema");
  if (value.entries.length === 0 || value.entries.length > limits.members || value.blobs.length === 0 || value.blobs.length > value.entries.length) {
    throw new Error("Invalid raw preservation bundle member count");
  }

  const blobs = new Map();
  let uniqueBytes = 0;
  for (const blob of value.blobs) {
    exactKeys(blob, ["sha256", "size_bytes", "bytes_base64"]);
    if (!/^[a-f0-9]{64}$/.test(blob.sha256 || "") || !Number.isSafeInteger(blob.size_bytes) || blob.size_bytes <= 0 || blob.size_bytes > limits.expanded ||
        typeof blob.bytes_base64 !== "string" || blob.bytes_base64.length !== Math.ceil(blob.size_bytes / 3) * 4 || blobs.has(blob.sha256)) {
      throw new Error("Invalid raw preservation bundle blob");
    }
    const raw = Buffer.from(blob.bytes_base64, "base64");
    uniqueBytes += raw.length;
    if (uniqueBytes > limits.expanded || raw.length !== blob.size_bytes || raw.toString("base64") !== blob.bytes_base64 || sha256(raw) !== blob.sha256) {
      throw new Error("Raw preservation blob byte/hash mismatch");
    }
    blobs.set(blob.sha256, raw);
  }

  const members = new Map();
  const referenced = new Set();
  const memberTypes = new Map();
  let logicalBytes = 0;
  for (const entry of value.entries) {
    exactKeys(entry, ["path", "sha256", "size_bytes"]);
    const name = memberPath(entry.path);
    if (members.has(name) || !/^[a-f0-9]{64}$/.test(entry.sha256 || "") || !Number.isSafeInteger(entry.size_bytes) || entry.size_bytes <= 0) {
      throw new Error("Invalid raw preservation bundle member");
    }
    const raw = blobs.get(entry.sha256);
    if (!raw || raw.length !== entry.size_bytes) throw new Error("Raw preservation member references a missing or mismatched blob");
    logicalBytes += entry.size_bytes;
    if (logicalBytes > limits.expanded) throw new Error("Raw preservation bundle exceeds logical member byte bound");
    referenced.add(entry.sha256);
    if (!memberTypes.has(entry.sha256)) memberTypes.set(entry.sha256, new Set());
    memberTypes.get(entry.sha256).add(memberType(name));
    members.set(name, raw);
  }

  if (referenced.size !== blobs.size) throw new Error("Raw preservation bundle contains an unreferenced blob");
  for (const [hash, types] of memberTypes) {
    const raw = blobs.get(hash);
    for (const type of types) validateMemberBytes(`${PREFIX}member.${type}`, raw);
  }
  assertSerializedBound(value.entries, value.blobs, limits);
  return members;
}

function encodeBundle(entries, limits = LIMITS) {
  if (!Array.isArray(entries) || entries.length === 0 || entries.length > limits.members) throw new Error("Invalid raw preservation bundle member count");
  const names = new Set();
  const payloads = new Map();
  const payloadTypes = new Map();
  const members = [];
  let logicalBytes = 0;

  for (const entry of entries) {
    if (!entry || typeof entry !== "object" || Array.isArray(entry)) throw new Error("Raw preservation bundle entries need a path and bytes");
    const name = memberPath(entry.path);
    const bytes = entry.bytes;
    if (names.has(name)) throw new Error("Duplicate raw preservation bundle member path");
    if (!Buffer.isBuffer(bytes) || bytes.length === 0) throw new Error("Raw preservation bundle members need bytes");
    names.add(name);
    logicalBytes += bytes.length;
    if (logicalBytes > limits.expanded) throw new Error("Raw preservation bundle exceeds logical member byte bound");

    const hash = sha256(bytes);
    const existing = payloads.get(hash);
    if (existing && !existing.equals(bytes)) throw new Error("Raw preservation SHA-256 collision between different payload bytes");
    if (!existing) payloads.set(hash, bytes);
    if (!payloadTypes.has(hash)) payloadTypes.set(hash, new Set());
    payloadTypes.get(hash).add(memberType(name));
    members.push({ path: name, sha256: hash, size_bytes: bytes.length });
  }

  for (const [hash, types] of payloadTypes) {
    const bytes = payloads.get(hash);
    for (const type of types) validateMemberBytes(`${PREFIX}member.${type}`, bytes);
  }

  members.sort((a, b) => a.path < b.path ? -1 : a.path > b.path ? 1 : 0);
  const blobMetadata = [...payloads].map(([hash, bytes]) => ({ sha256: hash, size_bytes: bytes.length }))
    .sort((a, b) => a.sha256 < b.sha256 ? -1 : a.sha256 > b.sha256 ? 1 : 0);
  assertSerializedBound(members, blobMetadata, limits);
  const blobs = blobMetadata.map((blob) => ({ ...blob, bytes_base64: payloads.get(blob.sha256).toString("base64") }));
  const json = Buffer.from(JSON.stringify({ schema: SCHEMA, entries: members, blobs }));
  if (json.length > limits.expanded) throw new Error("Raw preservation bundle exceeds expanded byte bound");
  const packed = zlib.gzipSync(json, { level: 6 });
  const decoded = decodeBundle(packed, limits);
  for (const entry of entries) if (!decoded.get(entry.path).equals(entry.bytes)) throw new Error("Raw preservation bundle roundtrip differs");
  return packed;
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
    if (!actual.equals(bytes)) throw new Error("Published raw preservation bundle differs");
    return { path: target, sha256: sha256(bytes), size_bytes: bytes.length, members: entries.length };
  } finally {
    if (fd !== undefined) fs.closeSync(fd);
    try { fs.unlinkSync(temporary); } catch (error) { if (error.code !== "ENOENT") throw error; }
  }
}

function readRegular(file, maxBytes) {
  const stat = fs.lstatSync(file);
  if (!stat.isFile() || stat.isSymbolicLink() || stat.size > maxBytes) throw new Error("Raw preservation input must be a bounded regular file");
  const bytes = fs.readFileSync(file);
  if (bytes.length !== stat.size || bytes.length > maxBytes) throw new Error("Raw preservation input changed while reading");
  return bytes;
}

function runPath(root, relative, createParents = false) {
  const segments = relative.split("/");
  if (segments.some((part) => !part || part === "." || part === "..")) throw new Error("Unsafe raw preservation run path");
  let parent = root;
  for (const part of segments.slice(0, -1)) {
    parent = path.join(parent, part);
    if (createParents && !fs.existsSync(parent)) fs.mkdirSync(parent);
    const stat = fs.lstatSync(parent);
    if (!stat.isDirectory() || stat.isSymbolicLink()) throw new Error("Raw preservation bundle parent directories must not be symlinks");
  }
  return path.join(parent, segments.at(-1));
}

function addExpected(expected, descriptor, type) {
  if (!descriptor || typeof descriptor !== "object" || Array.isArray(descriptor)) throw new Error("Raw preservation event member needs a path and SHA-256");
  const name = memberPath(descriptor.path);
  if (memberType(name) !== type || typeof descriptor.sha256 !== "string" || !/^[a-f0-9]{64}$/.test(descriptor.sha256)) {
    throw new Error("Raw preservation event member has an invalid path type or SHA-256");
  }
  if (expected.has(name)) throw new Error("Raw preservation path reused by distinct observations");
  expected.set(name, descriptor.sha256);
}

function addObservationMembers(expected, observation) {
  if (!observation || typeof observation !== "object" || Array.isArray(observation)) throw new Error("Invalid raw preservation observation");
  if (observation.image != null) addExpected(expected, observation.image, "png");
  if (observation.images != null) {
    if (!Array.isArray(observation.images)) throw new Error("Raw preservation observation images must be an array");
    for (const image of observation.images) addExpected(expected, image, "png");
  }

  if (observation.capture_sampling != null) {
    const sampling = observation.capture_sampling;
    if (typeof sampling !== "object" || Array.isArray(sampling) || !Array.isArray(sampling.samples)) {
      throw new Error("Raw preservation capture sampling needs a samples array");
    }
    for (const sample of sampling.samples) {
      if (!sample || typeof sample !== "object" || Array.isArray(sample)) throw new Error("Invalid raw preservation sample");
      addExpected(expected, { path: sample.path, sha256: sample.sha256 }, "png");
      addExpected(expected, { path: sample.state_path, sha256: sample.state_sha256 }, "json");
    }
  }
}

function directoryEntries(directory, limit, visit) {
  const stat = fs.lstatSync(directory);
  if (!stat.isDirectory() || stat.isSymbolicLink()) throw new Error("Raw preservation staging directories must not be symlinks");
  const dir = fs.opendirSync(directory);
  let count = 0;
  try {
    let entry;
    while ((entry = dir.readSync()) !== null) {
      if (++count > limit) throw new Error("Raw preservation staging exceeds its expected entry bound");
      visit(entry);
    }
  } finally { dir.closeSync(); }
  return count;
}

function uniqueBlobMetadata(memberMetadata) {
  const blobs = new Map();
  for (const member of memberMetadata) {
    const priorSize = blobs.get(member.sha256);
    if (priorSize !== undefined && priorSize !== member.size_bytes) throw new Error("Raw preservation SHA-256 has inconsistent member sizes");
    blobs.set(member.sha256, member.size_bytes);
  }
  return [...blobs].map(([sha256, size_bytes]) => ({ sha256, size_bytes }));
}

function packRun(runRoot) {
  const root = fs.realpathSync(runRoot);
  const lines = readRegular(path.join(root, "phase105-evidence.ndjson"), 16 * 1024 * 1024).toString("utf8").split(/\r?\n/).filter(Boolean);
  const records = lines.map((line) => JSON.parse(line)).filter((record) => record.operation === "ui_preservation_case");
  const expected = new Map();
  for (const record of records) {
    const observations = Array.isArray(record.observations) ? record.observations : [record];
    for (const observation of observations) addObservationMembers(expected, observation);
  }
  if (!expected.size || expected.size > LIMITS.members) throw new Error("No bounded raw preservation event inventory");

  const staging = path.join(root, STAGING_PATH);
  let directory = staging;
  for (const component of PREFIX.split("/").filter(Boolean)) {
    const count = directoryEntries(directory, 1, (entry) => {
      if (entry.name !== component || !entry.isDirectory() || entry.isSymbolicLink()) throw new Error("Unexpected raw preservation staging directory");
    });
    if (count !== 1) throw new Error("Missing raw preservation staging directory");
    directory = path.join(directory, component);
  }

  const files = [];
  directoryEntries(directory, expected.size, (entry) => {
    if (!entry.isFile() || entry.isSymbolicLink()) throw new Error("Raw preservation staging must contain regular files only");
    const name = memberPath(`${PREFIX}${entry.name}`);
    if (!expected.has(name)) throw new Error("Unobserved raw preservation staging member");
    files.push(name);
  });
  if (files.length !== expected.size) throw new Error("Staged raw preservation members differ from the observed event inventory");

  const metadata = files.map((name) => {
    const stat = fs.lstatSync(path.join(staging, name));
    if (!stat.isFile() || stat.isSymbolicLink() || stat.size <= 0 || stat.size > LIMITS.compressed) throw new Error("Raw preservation input must be a bounded regular file");
    return { path: name, sha256: expected.get(name), size_bytes: stat.size };
  });
  const blobs = uniqueBlobMetadata(metadata);
  assertSerializedBound(metadata, blobs, LIMITS);

  const payloads = new Map();
  const entries = [];
  for (const member of metadata) {
    const bytes = readRegular(path.join(staging, member.path), LIMITS.compressed);
    if (bytes.length !== member.size_bytes || sha256(bytes) !== member.sha256) throw new Error("Staged raw preservation member differs from its observed receipt");
    const prior = payloads.get(member.sha256);
    if (prior && !prior.equals(bytes)) throw new Error("Raw preservation SHA-256 collision between different staged payload bytes");
    const payload = prior || bytes;
    if (!prior) payloads.set(member.sha256, payload);
    entries.push({ path: member.path, bytes: payload });
  }
  return writeExclusive(runPath(root, BUNDLE_PATH, true), entries);
}

function loadRunBundle(runRoot, expectedSha256) {
  const bytes = readRegular(runPath(fs.realpathSync(runRoot), BUNDLE_PATH), LIMITS.compressed);
  if (!/^[a-f0-9]{64}$/.test(expectedSha256 || "") || sha256(bytes) !== expectedSha256) throw new Error("Raw preservation bundle artifact hash mismatch");
  return decodeBundle(bytes);
}

if (require.main === module) {
  try {
    if (process.argv.length !== 5 || process.argv[2] !== "pack" || process.argv[3] !== "--run-dir") throw new Error("Usage: ui_preservation_bundle.cjs pack --run-dir DIR");
    process.stdout.write(`${JSON.stringify(packRun(process.argv[4]))}\n`);
  } catch (error) { process.stderr.write(`raw preservation bundle: ${error.message}\n`); process.exitCode = 1; }
}

module.exports = { SCHEMA, PREFIX, BUNDLE_PATH, STAGING_PATH, LIMITS, memberPath, decodeBundle, encodeBundle, writeExclusive, packRun, loadRunBundle, sha256 };
