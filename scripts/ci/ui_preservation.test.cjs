"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const vm = require("node:vm");
const { PNG } = require(path.join(__dirname, "../../examples/scrypath_ecommerce/node_modules/pngjs"));

const preservation = fs.existsSync(path.join(__dirname, "ui_preservation.cjs")) ? require("./ui_preservation.cjs") : {};

const sourceSha = "a".repeat(40);
const treeOid = "d".repeat(40);
const treeSha = "b".repeat(64);
const project = "scrypath-p185-0123456789abcdef";

// Exercise the real private lifecycle/state functions with command/FS boundaries
// substituted by this test loader; no Docker daemon or preview is accessed.
function preservationAtBoundary(spawnSync, unavailablePreview = false, orchestration = null) {
  const filename = path.join(__dirname, "ui_preservation.cjs");
  const boundaryFs = new Proxy(fs, { get(target, property) {
    if (unavailablePreview && ["lstatSync", "readFileSync"].includes(property)) return (file, ...args) => {
      if (String(file).endsWith("/.planning/UI-PREVIEW.json")) throw new Error("retained preview pointer is unavailable");
      return target[property](file, ...args);
    };
    return target[property];
  } });
  const context = { module: { exports: {} }, __dirname, __filename: filename, process, Buffer, URL, console: orchestration ? { log() {} } : console, orchestration, require(name) {
    if (name === "node:child_process") return { spawnSync };
    if (name === "node:fs") return boundaryFs;
    return require(name);
  } };
  const orchestrationIo = orchestration ? "\nloadAuthorizedSession = orchestration.load; compareDirectories = orchestration.compare; persistAuthorizedSession = orchestration.persist;" : "";
  vm.runInNewContext(fs.readFileSync(filename, "utf8") + orchestrationIo + "\nmodule.exports.boundary = {stackDataIdentity, teardownOwnedProject, compareSession};", context, { filename });
  return context.module.exports;
}

test("preservation compare regression counts one-level single-channel pixel changes", () => {
  const { PNG } = require(path.join(__dirname, "../../examples/scrypath_ecommerce/node_modules/pngjs"));
  const before = new PNG({ width: 1, height: 1 });
  const after = new PNG({ width: 1, height: 1 });
  before.data.fill(255); after.data.fill(255); after.data[0] = 254;
  assert.equal(preservation.comparePng(PNG.sync.write(before), PNG.sync.write(after)).pixels, 1);
  after.data.fill(255); after.data[3] = 254;
  assert.equal(preservation.comparePng(PNG.sync.write(before), PNG.sync.write(after)).pixels, 1);
});

test("preservation compare regression permits verification of an already compared pair", () => {
  const session = { status: "compared-pending-review", candidate: "/candidate" };
  const authority = { session_id: "repeat-unit-185", manifests: { before: { directory: "/before" }, candidate: { directory: "/candidate" } } };
  let comparisons = 0;
  const helper = preservationAtBoundary(() => assert.fail("No external command belongs to orchestration unit test"), false, {
    load: () => ({ session, authority }),
    compare: () => { comparisons += 1; return { comparisons: [{ differing_pixels: 0, total_pixels: 1, copy_changed: false, dimensions_changed: false }] }; },
    persist: () => {}
  });
  assert.doesNotThrow(() => helper.boundary.compareSession("/fixture-session"));
  assert.equal(comparisons, 1);
});

test("preservation compare regression fails its command after retaining a visible difference", () => {
  const session = { status: "candidate-captured", candidate: "/candidate" };
  const authority = { session_id: "difference-unit-185", manifests: { before: { directory: "/before" }, candidate: { directory: "/candidate" } } };
  let persisted = false;
  const helper = preservationAtBoundary(() => assert.fail("No external command belongs to orchestration unit test"), false, {
    load: () => ({ session, authority }),
    compare: () => ({ comparisons: [{ differing_pixels: 1, total_pixels: 1, copy_changed: false, dimensions_changed: false }] }),
    persist: () => { persisted = true; }
  });
  assert.throws(() => helper.boundary.compareSession("/fixture-session"), /preservation.*failed/i);
  assert.equal(persisted, true);
});

test("parent regression binds rendered Meilisearch task history in the actual state reader", () => {
  function identity(status, finishedAt) {
    const helper = preservationAtBoundary((command, args) => {
      assert.equal(command, "docker");
      if (args.includes("pg_dump")) return { status: 0, stdout: "INSERT INTO products VALUES (1);", stderr: "" };
      const url = new URL(args.at(-1));
      const payload = url.pathname === "/indexes" ? { results: [{ uid: "products", primaryKey: "id" }], offset: 0, limit: 1000, total: 1 }
        : url.pathname.endsWith("/settings") || url.pathname.endsWith("/stats") ? {}
          : url.pathname.endsWith("/documents") ? { results: [], offset: 0, limit: 1000, total: 0 }
            : url.pathname === "/tasks" ? { results: [{ uid: 4, indexUid: "products", status, type: "documentAdditionOrUpdate", finishedAt }], total: 1, from: 4, next: null, limit: 1000 }
              : assert.fail(`Unexpected state request ${url}`);
      return { status: 0, stdout: JSON.stringify(payload), stderr: "" };
    });
    return helper.boundary.stackDataIdentity({ compose: [], env: {} });
  }
  assert.notEqual(identity("succeeded", "2026-10-31T12:00:00Z"), identity("failed", "2026-10-31T12:00:00Z"));
  assert.notEqual(identity("succeeded", "2026-10-31T12:00:00Z"), identity("succeeded", "2026-10-31T13:00:00Z"));
});

test("parent regression reports full-page dimension changes instead of aborting", () => {
  const { PNG } = require(path.join(__dirname, "../../examples/scrypath_ecommerce/node_modules/pngjs"));
  const before = new PNG({ width: 2, height: 2 });
  const after = new PNG({ width: 2, height: 3 });
  before.data.fill(255); after.data.fill(255);
  const result = preservation.comparePng(PNG.sync.write(before), PNG.sync.write(after));
  assert.equal(result.total, 6);
  assert.ok(result.pixels >= 2);
  assert.equal(result.dimensions_changed, true);
  assert.deepEqual(result.before_dimensions, { width: 2, height: 2 });
  assert.deepEqual(result.after_dimensions, { width: 2, height: 3 });
});

test("parent regression cleans exact disposable resources without a live retained pointer", () => {
  const commands = [];
  const helper = preservationAtBoundary((command, args) => {
    assert.equal(command, "docker"); commands.push(args);
    return { status: 0, stdout: "", stderr: "" };
  }, true);
  const session = { schema: "scrypath.ui-session.v2", status: "starting", session_id: "0123456789abcdef", project,
    ports: { web: 53111, standalone: 53112 }, source: {}, retained_inventory: { project: "scrypath_ecommerce", port: 4002, volumes: [], container: "retained-web", container_id: "retained-id" } };
  const authority = helper.createSessionAuthority("/private/tmp/phase185-test/ui-session.json", session);
  assert.doesNotThrow(() => helper.boundary.teardownOwnedProject(authority));
  assert.equal(commands.length, 3);
  assert.ok(commands.every((args) => args.join(" ").includes(`label=com.docker.compose.project=${project}`)));
});

test("task history accepts one complete bounded snapshot and rejects any omitted tail", () => {
  const complete = { results: [{ uid: 5, status: "succeeded" }, { uid: 1, status: "failed" }], total: 2, from: 5, next: null, limit: 1000 };
  let calls = 0;
  const result = preservation.collectTaskPages((from, limit) => { calls += 1; assert.equal(from, null); assert.equal(limit, 1000); return complete; });
  assert.equal(calls, 1);
  assert.deepEqual(result.map(({ uid }) => uid), [5, 1]);
  for (const invalid of [{ ...complete, next: 0 }, { ...complete, total: 3 }, { ...complete, total: 1001 }, { ...complete, from: 6 }, { ...complete, results: [{ uid: 1 }, { uid: 1 }] }]) {
    assert.throws(() => preservation.collectTaskPages(() => invalid), /Task history/);
  }
  assert.deepEqual(preservation.collectTaskPages(() => ({ results: [], total: 0, from: null, next: null, limit: 1000 })), []);
});

test("clock regression rejects a capture whose observation clock differs from its environment", () => {
  const manifest = validManifest();
  const utc = "2026-10-31T12:00:00.000Z";
  const clock = { utc, sha256: require("node:crypto").createHash("sha256").update(`${utc}\n`).digest("hex"), timezone: "UTC", locale: "en-US", browser_mode: "fixed-date" };
  manifest.environment.clock = clock;
  for (const capture of manifest.captures) capture.clock = { ...clock };
  manifest.captures[0].clock.utc = "2026-10-31T13:00:00.000Z";
  assert.equal(preservation.matrixErrors(manifest).some((error) => /clock/i.test(error)), true);
});

test("clock fixture freezes exact bytes and rejects rewriting, tampering, oversized files and symlinks", () => {
  const directory = fs.mkdtempSync("/private/tmp/phase185-clock-fixture-test-");
  const authority = { resources: { fixture_directory: directory }, clock: null };
  const file = path.join(directory, "clock.txt");
  try {
    preservation.writeClockFixture(authority, "2026-10-31T11:00:00.000Z");
    authority.clock = preservation.writeClockFixture(authority, "2026-10-31T12:00:00.000Z");
    assert.deepEqual(preservation.assertClockFixture(authority), authority.clock);
    assert.throws(() => preservation.writeClockFixture(authority, "2026-10-31T13:00:00.000Z"), /already frozen/);
    fs.unlinkSync(file); fs.writeFileSync(file, "2026-10-31T13:00:00.000Z\n");
    assert.throws(() => preservation.assertClockFixture(authority), /bytes changed/);
    fs.writeFileSync(file, "x".repeat(129));
    assert.throws(() => preservation.assertClockFixture(authority), /bounded regular file/);
    fs.unlinkSync(file); fs.symlinkSync(path.join(directory, "missing"), file);
    assert.throws(() => preservation.assertClockFixture(authority), /bounded regular file/);
  } finally { fs.rmSync(directory, { recursive: true, force: true }); }
});

test("runtime clock proof requires both app probes and all three read-only mounts", () => {
  for (const change of [
    (manifest) => { manifest.runtime.clock_probes.pop(); },
    (manifest) => { manifest.runtime.clock_probes[0].utc = "2026-10-31T13:00:00.000Z"; },
    (manifest) => { manifest.runtime.clock_mounts[0].readonly = false; },
    (manifest) => { manifest.runtime.clock_mounts[0].destination = "/app"; }
  ]) {
    const manifest = validManifest(); change(manifest);
    assert.ok(preservation.disposableProvenanceErrors(manifest, expected()).some((error) => /clock/i.test(error)));
  }
});

test("comparison output is retryable after failure and never overwrites committed evidence", () => {
  const directory = fs.mkdtempSync(path.join(require("node:os").tmpdir(), "phase185-comparison-"));
  const output = path.join(directory, "comparison");
  const primary = new Error("image decoding failed");
  try {
    assert.throws(() => preservation.withComparisonDirectory(output, (staging) => {
      fs.writeFileSync(path.join(staging, "partial-diff.png"), "partial"); throw primary;
    }), (error) => error === primary);
    assert.deepEqual(fs.readdirSync(directory), []);
    assert.equal(preservation.withComparisonDirectory(output, (staging) => { fs.writeFileSync(path.join(staging, "comparison.json"), "complete"); return "reported"; }), "reported");
    assert.equal(fs.readFileSync(path.join(output, "comparison.json"), "utf8"), "complete");
    assert.throws(() => preservation.withComparisonDirectory(output, () => assert.fail("must not run")), /Refusing to overwrite/);
  } finally { fs.rmSync(directory, { recursive: true, force: true }); }
});

test("repeated comparison recomputes and verifies existing artifacts without overwriting tampering", () => {
  const directory = fs.mkdtempSync("/private/tmp/phase185-repeat-comparison-test-");
  const output = path.join(directory, "comparison");
  let invocations = 0;
  const compare = (_before, _after, destination) => {
    invocations += 1; fs.mkdirSync(destination);
    fs.writeFileSync(path.join(destination, "comparison.json"), '{"fixture":"verified inputs"}\n');
    fs.writeFileSync(path.join(destination, "difference.png"), "deterministic-generated-diff");
    return { fixture: "verified inputs" };
  };
  try {
    preservation.compareCapturedDirectories("before", "after", output, {}, compare);
    preservation.compareCapturedDirectories("before", "after", output, {}, compare);
    assert.equal(invocations, 2);
    fs.writeFileSync(path.join(output, "difference.png"), "tampered");
    assert.throws(() => preservation.compareCapturedDirectories("before", "after", output, {}, compare), /differs from recomputed evidence/);
    assert.equal(fs.readFileSync(path.join(output, "difference.png"), "utf8"), "tampered");
    assert.deepEqual(fs.readdirSync(directory), ["comparison"]);
  } finally { fs.rmSync(directory, { recursive: true, force: true }); }
});

function validManifest() {
  const utc = "2026-10-31T12:00:00.000Z";
  const clock = { utc, sha256: require("node:crypto").createHash("sha256").update(`${utc}\n`).digest("hex"), timezone: "UTC", locale: "en-US", browser_mode: "fixed-date" };
  const captures = preservation.expectedCaptureIds().map((id) => {
    const [deployment, surface, theme, widthText] = id.split("--");
    const width = Number(widthText);
    const files = Object.fromEntries(["copy.json", "viewport.png", "full.png", "hover.png", "focus.png"].map((kind) => [kind, { path: `${id}--${kind}`, sha256: "c".repeat(64) }]));
    if (surface === "control-room" && width === 390) files["navigation.png"] = { path: `${id}--navigation.png`, sha256: "c".repeat(64) };
    const mobile_navigation = surface === "control-room" && width === 390 ? { expanded: true, visible: true, links: ["Control Room", "Search"] } : undefined;
    const route = deployment === "host"
      ? ({ storefront: "/", "control-room": "/admin/search/", "search-health": "/admin/search/health", "failed-sync": "/admin/search/failed-sync", "sync-drift": "/admin/search/sync-and-index", search: "/admin/search/search", "saved-searches": "/admin/search/search?saved=manage", help: "/admin/search/help" })[surface]
      : ({ "control-room": "/ops/", "search-health": "/ops/health", "failed-sync": "/ops/failed-sync", "sync-drift": "/ops/sync-and-index", search: "/ops/search", "saved-searches": "/ops/search?saved=manage", help: "/ops/help" })[surface];
    return { id, deployment, surface, theme, width, viewport: { width, height: width === 390 ? 844 : 900 }, route, files, mobile_navigation, browser_version: "chromium-123", platform: "linux-arm64", data_identity: "state-digest", clock: { ...clock } };
  });
  const identities = ["web", "standalone_ops"].map((service) => ({ service, id: `${service}-image`, labels: { "org.opencontainers.image.revision": sourceSha }, source_sha: sourceSha, tree_oid: treeOid, tree_sha256: treeSha }));
  return {
    schema: "scrypath.ui-disposable.v2", mode: "disposable", purpose: "historical-baseline",
    source: { source_sha: sourceSha, tree_oid: treeOid, tree_sha256: treeSha },
    runtime: {
      compose_project: project, owned: true, isolated: true, source_match: true, retained_resources_disjoint: true,
      host_ports: ["127.0.0.1:53111->4002/tcp", "127.0.0.1:53112->4003/tcp"],
      volumes: [`${project}-postgres`, `${project}-meili`], images: identities,
      containers: identities.map(({ service, source_sha, tree_oid, tree_sha256 }) => ({ service, id: `${service}-container`, name: `${service}-container`, source_built: true, labels: { "org.opencontainers.image.revision": source_sha, "com.docker.compose.project": project, "com.docker.compose.service": service, "com.scrypath.phase185.session": "0123456789abcdef" }, source_sha, tree_oid, tree_sha256 })),
      mounts: [], routes: { mounted: true, standalone: true },
      clock_probes: ["web", "standalone_ops"].map((service) => ({ service, utc })),
      clock_mounts: ["web", "standalone_ops", "browser"].map((service) => ({ service, destination: "/phase185-fixture", readonly: true, source: "/private/tmp/fixture-unit" })),
    },
    environment: { browser_version: "chromium-123", platform: "linux-arm64", data_identity: "state-digest", clock },
    captures,
  };
}

function expected() {
  return { source_sha: sourceSha, tree_oid: treeOid, tree_sha256: treeSha, retained_project: "scrypath_ecommerce", retained_port: 4002, retained_volumes: ["scrypath_ecommerce_postgres_data"] };
}

test("frozen preservation matrix covers 72 host and 63 standalone observations", () => {
  const ids = preservation.expectedCaptureIds();
  assert.equal(ids.filter((id) => id.startsWith("host--")).length, 72);
  assert.equal(ids.filter((id) => id.startsWith("standalone--")).length, 63);
  assert.equal(ids.length, 135);
  assert.deepEqual(preservation.matrixErrors(validManifest()), []);
});

test("canonical capture IDs bind route, width, and viewport metadata as one tuple", () => {
  const manifest = validManifest();
  const capture = manifest.captures.find(({ id }) => id === "host--storefront--light--1440");
  capture.width = 768;
  capture.viewport.width = 390;
  capture.route = "/admin/search/";
  assert.ok(preservation.matrixErrors(manifest).some((error) => error.includes("metadata does not match canonical identity: host--storefront--light--1440")));
});

test("viewport PNG IHDR dimensions must match the ID-bound viewport", () => {
  const directory = path.join(preservation.artifactRoot, "test-png-dimensions");
  const manifest = validManifest();
  const capture = manifest.captures[0];
  const png = PNG.sync.write(new PNG({ width: 390, height: 844 }));
  const artifactPath = `${capture.id}--viewport.png`;
  fs.mkdirSync(directory, { recursive: true });
  try {
    fs.writeFileSync(path.join(directory, artifactPath), png);
    capture.files["viewport.png"] = { path: artifactPath, sha256: require("node:crypto").createHash("sha256").update(png).digest("hex") };
    assert.ok(preservation.artifactErrors(manifest, directory).some((error) => error.includes("viewport.png dimensions do not match host--storefront--light--1440")));
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});

test("compact navigation screenshot is required with its image filename key", () => {
  const manifest = validManifest();
  const compact = manifest.captures.find((capture) => capture.id === "host--control-room--light--390");
  delete compact.files["navigation.png"];
  assert.ok(preservation.matrixErrors(manifest).some((error) => error.includes("Compact navigation evidence is missing or did not open: host--control-room--light--390")));
});

test("compact navigation evidence proves the drawer opened with visible links", () => {
  const manifest = validManifest();
  const compact = manifest.captures.find((capture) => capture.id === "host--control-room--light--390");
  compact.mobile_navigation.visible = false;
  assert.ok(preservation.matrixErrors(manifest).some((error) => error.includes("Compact navigation evidence is missing or did not open: host--control-room--light--390")));
});

test("disposable provenance rejects retained project, port, and volume even when disposable mode is selected", () => {
  const manifest = validManifest();
  manifest.runtime.compose_project = "scrypath_ecommerce";
  manifest.runtime.host_ports[0] = "127.0.0.1:4002->4002/tcp";
  manifest.runtime.volumes[0] = "scrypath_ecommerce_postgres_data";
  const errors = preservation.disposableProvenanceErrors(manifest, expected());
  assert.ok(errors.some((error) => error.includes("retained project")));
  assert.ok(errors.some((error) => error.includes("retained port")));
  assert.ok(errors.some((error) => error.includes("retained volume")));
});

test("valid disposable identity passes, while forged source, image, and container labels fail", () => {
  const manifest = validManifest();
  assert.deepEqual(preservation.disposableProvenanceErrors(manifest, expected()), []);
  manifest.source.tree_sha256 = "d".repeat(64);
  assert.ok(preservation.disposableProvenanceErrors(manifest, expected()).some((error) => error.includes("full Git tree identity")));
  manifest.source.tree_sha256 = treeSha;
  manifest.runtime.images[0].labels["org.opencontainers.image.revision"] = "f".repeat(40);
  manifest.runtime.containers[1].source_sha = "e".repeat(40);
  assert.ok(preservation.disposableProvenanceErrors(manifest, expected()).some((error) => error.includes("source")));
});

test("source identity changes during startup or capture are rejected", () => {
  assert.deepEqual(preservation.sourceChangeErrors({ source_sha: sourceSha, tree_oid: treeOid, tree_sha256: treeSha }, { source_sha: sourceSha, tree_oid: treeOid, tree_sha256: treeSha }), []);
  assert.ok(preservation.sourceChangeErrors({ source_sha: sourceSha, tree_oid: treeOid, tree_sha256: treeSha }, { source_sha: "f".repeat(40), tree_oid: treeOid, tree_sha256: treeSha }).some((error) => error.includes("Source changed")));
});

test("Meilisearch index responses accept both array and paginated results shapes", () => {
  assert.deepEqual(preservation.indexResults([{ uid: "products" }]), [{ uid: "products" }]);
  assert.deepEqual(preservation.indexResults({ results: [{ uid: "products" }], offset: 0, limit: 20, total: 1 }), [{ uid: "products" }]);
  assert.throws(() => preservation.indexResults({ error: "unexpected" }), /results array/);
  assert.throws(() => preservation.indexResults({ results: [{ uid: "products" }], offset: 0, limit: 20, total: "many" }), /finite non-negative total/);
});

test("Meilisearch pagination has finite totals, consistent progress, and complete bounded pages", () => {
  const records = [{ uid: "a" }, { uid: "b" }, { uid: "c" }];
  assert.deepEqual(preservation.collectPages((offset, limit) => ({ offset, limit, total: records.length, results: records.slice(offset, offset + limit) }), { label: "indexes", maxItems: 10, pageLimit: 2 }), records);
  assert.throws(() => preservation.collectPages(() => ({ offset: 0, limit: 2, total: 3, results: [] }), { label: "indexes", maxItems: 10, pageLimit: 2 }), /incomplete or non-progressing/);
  assert.throws(() => preservation.collectPages(() => ({ offset: 0, limit: 2, total: 11, results: records.slice(0, 2) }), { label: "indexes", maxItems: 10, pageLimit: 2 }), /exceeds the 10 item/);
});

test("PostgreSQL dump identity ignores only a matched restrict/unrestrict transport nonce", () => {
  const before = "SET statement_timeout = 0;\n\\restrict secretOne\nINSERT INTO products VALUES (1, 'Book');\n\\unrestrict secretOne\n";
  const repeat = "SET statement_timeout = 0;\n\\restrict anotherNonce\nINSERT INTO products VALUES (1, 'Book');\n\\unrestrict anotherNonce\n";
  const changedRow = "SET statement_timeout = 0;\n\\restrict anotherNonce\nINSERT INTO products VALUES (1, 'Pen');\n\\unrestrict anotherNonce\n";
  assert.equal(preservation.normalizePgDump(before), preservation.normalizePgDump(repeat));
  assert.notEqual(preservation.normalizePgDump(before), preservation.normalizePgDump(changedRow));
  assert.throws(() => preservation.normalizePgDump(before.replace("unrestrict secretOne", "unrestrict wrongNonce")), /unmatched or repeated/);
});

test("rendered-state identity changes for real document and settings changes", () => {
  const state = { databases: { ecommerce: "stable-db" }, tasks: [], indexes: [{ uid: "products", primaryKey: "id", settings: { searchableAttributes: ["name"] }, documents: [{ id: 1, name: "Book" }] }] };
  const clone = () => JSON.parse(JSON.stringify(state));
  assert.equal(preservation.stableDataIdentity(state), preservation.stableDataIdentity(clone()));
  const changedRecord = clone();
  changedRecord.indexes[0].documents[0].name = "Pen";
  assert.notEqual(preservation.stableDataIdentity(state), preservation.stableDataIdentity(changedRecord));
  const changedSettings = clone();
  changedSettings.indexes[0].settings.searchableAttributes = ["description"];
  assert.notEqual(preservation.stableDataIdentity(state), preservation.stableDataIdentity(changedSettings));
});

test("non-loopback and retained targets are rejected independently of disposable mode", () => {
  const manifest = validManifest();
  manifest.runtime.host_ports = ["0.0.0.0:53111->4002/tcp", "127.0.0.1:4002->4003/tcp"];
  assert.ok(preservation.disposableProvenanceErrors(manifest, expected()).some((error) => error.includes("loopback")));
  assert.ok(preservation.disposableProvenanceErrors(manifest, expected()).some((error) => error.includes("retained port")));
});

test("missing captures, images, copy, and unmatched browser or data state fail the matrix", () => {
  const manifest = validManifest();
  manifest.captures.pop();
  delete manifest.captures[0].files["copy.json"];
  delete manifest.captures[1].files["viewport.png"];
  manifest.captures[1].browser_version = "chromium-other";
  manifest.captures[2].data_identity = "different-state";
  manifest.captures[3].width = 111;
  manifest.captures[4].theme = "unpaired-theme";
  assert.ok(preservation.matrixErrors(manifest).some((error) => error.includes("Missing paired capture")));
  assert.ok(preservation.matrixErrors(manifest).some((error) => error.includes("image or copy")));
  assert.ok(preservation.matrixErrors(manifest).some((error) => error.includes("Unpaired browser/platform/data")));
  assert.ok(preservation.matrixErrors(manifest).some((error) => error.includes("Unpaired viewport width")));
  assert.ok(preservation.matrixErrors(manifest).some((error) => error.includes("Unpaired theme")));
});

test("PNG comparisons use the installed pixelmatch and pngjs modules", () => {
  const { PNG } = require(path.join(__dirname, "../../examples/scrypath_ecommerce/node_modules/pngjs"));
  const before = new PNG({ width: 2, height: 2 });
  const after = new PNG({ width: 2, height: 2 });
  before.data.fill(255);
  after.data.fill(255);
  after.data[0] = 0;
  const result = preservation.comparePng(PNG.sync.write(before), PNG.sync.write(after));
  assert.equal(result.total, 4);
  assert.equal(result.pixels, 1);
  assert.ok(result.diff.length > 0);
});

test("teardown failures preserve the original capture failure", () => {
  const primary = new Error("capture failed");
  const cleanup = new Error("teardown failed");
  assert.throws(() => preservation.runWithTeardown(primary, () => { throw cleanup; }), (error) => {
    assert.equal(error, primary);
    assert.equal(error.cleanupError, cleanup);
    return true;
  });
});

test("owned Docker bind mounts match the recorded read-only bootstrap or exact artifact directory", () => {
  const root = "/private/tmp/scrypath-phase185-execution";
  const directory = fs.mkdtempSync(path.join(root, "bind-authority-test-"));
  const sessionId = "0123456789abcdef";
  const sessionPath = path.join(directory, "ui-session.json");
  const session = {
    schema: "scrypath.ui-session.v2", status: "starting", session_id: sessionId,
    source: { source_sha: sourceSha, tree_oid: treeOid, tree_sha256: treeSha },
    retained_inventory: { project: "scrypath_ecommerce", port: 4002, volumes: ["scrypath_ecommerce-data"], container: "scrypath_ecommerce-web-1" },
    project, ports: { web: 53111, standalone: 53112 }, build_dir: path.join(directory, `build-${sessionId}`),
  };
  try {
    const authority = preservation.createSessionAuthority(sessionPath, session);
    const bootstrap = authority.resources.source_bind_mounts[0];
    assert.equal(bootstrap.service, "postgres");
    assert.equal(bootstrap.destination, "/docker-entrypoint-initdb.d/10-phase173-create-database.sh");
    assert.equal(bootstrap.read_only, true);
    const actualBootstrap = { Source: bootstrap.source, Destination: bootstrap.destination, RW: false };
    assert.equal(preservation.isAuthorizedOwnedBindMount(authority, "postgres", actualBootstrap), true);
    assert.equal(preservation.isAuthorizedOwnedBindMount(authority, "postgres", { ...actualBootstrap, RW: true }), false);
    assert.equal(preservation.isAuthorizedOwnedBindMount(authority, "postgres", { ...actualBootstrap, Source: `${bootstrap.source}.foreign` }), false);

    const legacyAuthority = structuredClone(authority);
    delete legacyAuthority.resources.source_bind_mounts;
    const rawSessionBytes = Buffer.from(`${JSON.stringify(session, null, 2)}\n`);
    assert.deepEqual(preservation.validateSessionAuthority(session, legacyAuthority, sessionPath, rawSessionBytes), []);
    assert.equal(preservation.isAuthorizedOwnedBindMount(legacyAuthority, "postgres", actualBootstrap), true);

    const clock = { Source: authority.resources.fixture_directory, Destination: "/phase185-fixture", RW: false };
    for (const service of ["web", "standalone_ops", "browser"]) {
      assert.equal(preservation.isAuthorizedOwnedBindMount(authority, service, clock), true);
      assert.equal(preservation.isAuthorizedOwnedBindMount(authority, service, { ...clock, Source: `/host_mnt${clock.Source}` }), true);
      assert.equal(preservation.isAuthorizedOwnedBindMount(authority, service, { ...clock, RW: true }), false);
      assert.equal(preservation.isAuthorizedOwnedBindMount(authority, service, { ...clock, Source: `${clock.Source}-foreign` }), false);
    }
    assert.equal(preservation.isAuthorizedOwnedBindMount(authority, "postgres", clock), false);
    assert.equal(preservation.isAuthorizedOwnedBindMount(authority, "meilisearch", clock), false);

    const artifact = path.join(preservation.artifactRoot, `before-${sessionId}`);
    authority.artifact_directories.before = artifact;
    assert.equal(preservation.isAuthorizedOwnedBindMount(authority, "browser", { Source: artifact, Destination: "/artifacts", RW: true }), true);
    assert.equal(preservation.isAuthorizedOwnedBindMount(authority, "browser", { Source: path.join(preservation.artifactRoot, "foreign"), Destination: "/artifacts", RW: true }), false);
    assert.equal(preservation.isAuthorizedOwnedBindMount(authority, "postgres", { Source: artifact, Destination: "/artifacts", RW: true }), false);
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});

test("post-start runtime inspection resolves the web container from the verified service inventory", () => {
  const containers = [{ service: "postgres", id: "pg-id" }, { service: "web", id: "web-id" }, { service: "standalone_ops", id: "ops-id" }];
  assert.equal(preservation.containerIdForService(containers, "web"), "web-id");
  assert.throws(() => preservation.containerIdForService(containers, "browser"), /Expected exactly one inspected browser container/);
  assert.throws(() => preservation.containerIdForService([...containers, { service: "web", id: "other-web" }], "web"), /Expected exactly one inspected web container/);
});

test("before-runtime ownership compares complete Docker IDs", () => {
  const fullId = "0123456789abcdef".repeat(4);
  assert.equal(preservation.sameDockerIdSet([fullId], [fullId]), true);
  assert.equal(preservation.sameDockerIdSet([fullId.slice(0, 12)], [fullId]), false);
  assert.equal(preservation.sameDockerIdSet([fullId, "f".repeat(64)], [fullId]), false);
});

test("candidate transition preserves the owned state and tears down on post-start failure", async () => {
  const events = [];
  const success = await preservation.runCandidateTransition({
    expectedDataIdentity: "frozen-state",
    readBefore: () => { events.push("read-before"); return "frozen-state"; },
    replace: (markStarted) => { events.push("prepare"); markStarted(); events.push("replace-app-only"); return { id: "candidate" }; },
    readAfter: (stack) => { events.push(`read-after:${stack.id}`); return "frozen-state"; },
    teardown: () => events.push("teardown"),
  });
  assert.equal(success.dataIdentity, "frozen-state");
  assert.deepEqual(events, ["read-before", "prepare", "replace-app-only", "read-after:candidate"]);

  const primary = new Error("candidate changed records after startup");
  const failedEvents = [];
  await assert.rejects(preservation.runCandidateTransition({
    expectedDataIdentity: "frozen-state",
    readBefore: () => "frozen-state",
    replace: (markStarted) => { markStarted(); return { id: "bad-candidate" }; },
    readAfter: () => { throw primary; },
    teardown: () => { failedEvents.push("teardown-owned-stack"); throw new Error("cleanup also failed"); },
  }), (error) => error === primary && error.cleanupError?.message === "cleanup also failed");
  assert.deepEqual(failedEvents, ["teardown-owned-stack"]);
});

test("candidate app commands reuse frozen databases without prepare, seed, or migrate steps", () => {
  const commands = preservation.candidateServerCommands();
  assert.deepEqual(Object.keys(commands), ["web", "standalone_ops"]);
  assert.ok(commands.web.join(" ").includes('test -s "$$asset"'));
  for (const command of Object.values(commands).map((parts) => parts.join(" "))) {
    assert.match(command, /mix phx\.server/);
    assert.doesNotMatch(command, /e2e\.prepare|scrypath\.demo\.seed|ecto\.migrate/);
  }
});

test("production session loader rejects an edited project, override path, or retained inventory", () => {
  const root = "/private/tmp/scrypath-phase185-execution";
  fs.mkdirSync(root, { recursive: true });
  const directory = fs.mkdtempSync(path.join(root, "authority-session-test-"));
  const sessionPath = path.join(directory, "ui-session.json");
  const sessionId = "0123456789abcdef";
  const session = {
    schema: "scrypath.ui-session.v2", status: "starting", session_id: sessionId,
    source: { source_sha: sourceSha, tree_oid: treeOid, tree_sha256: treeSha },
    retained_inventory: { project: "scrypath_ecommerce", port: 4002, volumes: ["scrypath_ecommerce-data"], container: "scrypath_ecommerce-web-1" },
    project: `scrypath-p185-${sessionId}`, ports: { web: 53111, standalone: 53112 },
    build_dir: path.join(directory, `build-${sessionId}`)
  };
  try {
    const authority = preservation.createSessionAuthority(sessionPath, session);
    preservation.persistAuthorizedSession(sessionPath, session, authority);
    assert.equal(preservation.loadAuthorizedSession(sessionPath).session.project, session.project);
    const forged = JSON.parse(fs.readFileSync(sessionPath, "utf8"));
    forged.project = "scrypath-p185-fedcba9876543210";
    forged.compose_override = "/tmp/attacker-compose.yaml";
    forged.retained_inventory.project = "another-running-project";
    fs.writeFileSync(sessionPath, JSON.stringify(forged));
    assert.throws(() => preservation.loadAuthorizedSession(sessionPath), /Editable session bytes do not match the independent creation authority/);
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});

test("production manifest validator rejects a forged manifest even with a recomputed self-checksum", () => {
  const root = "/private/tmp/scrypath-phase185-execution";
  fs.mkdirSync(root, { recursive: true });
  const directory = fs.mkdtempSync(path.join(root, "authority-manifest-test-"));
  const sessionPath = path.join(directory, "ui-session.json");
  const sessionId = "0123456789abcdef";
  const session = {
    schema: "scrypath.ui-session.v2", status: "starting", session_id: sessionId,
    source: { source_sha: sourceSha, tree_oid: treeOid, tree_sha256: treeSha },
    retained_inventory: { project: "scrypath_ecommerce", port: 4002, volumes: ["scrypath_ecommerce-data"], container: "scrypath_ecommerce-web-1" },
    project, ports: { web: 53111, standalone: 53112 }, build_dir: path.join(directory, `build-${sessionId}`)
  };
  try {
    const authority = preservation.createSessionAuthority(sessionPath, session);
    const manifest = validManifest();
    manifest.session_id = sessionId;
    manifest.runtime.compose_project = project;
    authority.clock = manifest.environment.clock;
    for (const mount of manifest.runtime.clock_mounts) mount.source = authority.resources.fixture_directory;
    manifest.capture_directory = path.join(preservation.artifactRoot, `before-${sessionId}`);
    manifest.capture_sha256 = preservation.manifestDigest(manifest);
    const manifestPath = path.join(manifest.capture_directory, "capture.json");
    const originalBytes = Buffer.from(`${JSON.stringify(manifest, null, 2)}\n`);
    authority.capture_environment = { before: manifest.environment };
    preservation.recordManifestAuthority(authority, "before", manifestPath, manifest, originalBytes);
    const validErrors = preservation.manifestAuthorityErrors(manifest, originalBytes, authority, "before", manifestPath, () => ({ tree_oid: treeOid, tree_sha256: treeSha }));
    assert.deepEqual(validErrors, []);

    const forged = JSON.parse(originalBytes.toString("utf8"));
    forged.source.tree_oid = "e".repeat(40);
    forged.capture_sha256 = preservation.manifestDigest(forged);
    assert.equal(forged.capture_sha256, preservation.manifestDigest(forged));
    const forgedBytes = Buffer.from(`${JSON.stringify(forged, null, 2)}\n`);
    const errors = preservation.captureManifestErrors(forged, forgedBytes, authority, "before");
    assert.ok(errors.some((error) => error.includes("raw manifest bytes differ")));
    assert.ok(errors.some((error) => error.includes("source identity differs")));

    const badChecksum = JSON.parse(originalBytes.toString("utf8"));
    badChecksum.capture_sha256 = "f".repeat(64);
    const checksumErrors = preservation.captureManifestErrors(badChecksum, Buffer.from(`${JSON.stringify(badChecksum, null, 2)}\n`), authority, "before");
    assert.ok(checksumErrors.some((error) => error.includes("manifest checksum is invalid")));
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});

test("Git authority drops inherited redirect variables and accepts only the canonical repository", () => {
  assert.deepEqual(preservation.gitEnvironment({ PATH: "/usr/bin", GIT_DIR: "/tmp/forged.git", GIT_WORK_TREE: "/tmp/forged", GIT_INDEX_FILE: "/tmp/forged.index" }), { PATH: "/usr/bin", GIT_CONFIG_NOSYSTEM: "1", GIT_CONFIG_GLOBAL: "/dev/null" });
  assert.equal(preservation.isCanonicalOrigin("https://github.com/szTheory/scrypath.git"), true);
  assert.equal(preservation.isCanonicalOrigin("git@github.com:szTheory/scrypath.git"), true);
  assert.equal(preservation.isCanonicalOrigin("https://example.com/szTheory/scrypath.git"), false);
});

test("Docker Buildx metadata stays under the authorized external session root", () => {
  const environment = preservation.dockerEnvironment({ DOCKER_HOST: "unix:///var/run/docker.sock", BUILDX_CONFIG: "/Users/jon/.docker/buildx" });
  assert.equal(environment.DOCKER_HOST, "unix:///var/run/docker.sock");
  assert.equal(environment.BUILDX_CONFIG, "/private/tmp/scrypath-phase185-execution/docker-buildx");
});

test("retained-preview bind source maps Docker Desktop host paths through the existing host-mount convention", () => {
  assert.equal(preservation.localPathForDockerHostMount("/host_mnt/Users/jon/projects/scrypath"), "/Users/jon/projects/scrypath");
  assert.equal(preservation.localPathForDockerHostMount("/Users/jon/projects/scrypath"), "/Users/jon/projects/scrypath");
});

test("new disposable evidence is rooted outside the implementation checkout", () => {
  assert.equal(preservation.artifactRoot, "/private/tmp/scrypath-phase185-execution/ui-review-artifacts/phase185");
});


test("clock publication waits for exact bytes across transient bind-mount visibility gaps", async () => {
  const expected = "2026-10-31T19:00:00.000Z\n";
  let reads = 0;
  const actual = await preservation.waitForPublishedClock(() => {
    reads += 1;
    if (reads === 1) return "2026-10-31T18:00:00.000Z\n";
    if (reads === 2) throw Object.assign(new Error("mount entry temporarily absent"), { code: "CLOCK_PUBLICATION_PENDING" });
    return expected;
  }, expected, { timeoutMs: 100, intervalMs: 1 });
  assert.equal(actual, expected);
  assert.equal(reads, 3);
});

test("clock publication stays bounded and preserves unrelated command failures", async () => {
  let reads = 0;
  await assert.rejects(preservation.waitForPublishedClock(() => { reads += 1; return "wrong bytes\n"; }, "expected\n", { timeoutMs: 20, intervalMs: 1 }), /not published within/);
  assert.ok(reads >= 2);
  const permission = new Error("Docker permission denied");
  let failedReads = 0;
  await assert.rejects(preservation.waitForPublishedClock(() => { failedReads += 1; throw permission; }, "expected\n", { timeoutMs: 20, intervalMs: 1 }), error => error === permission);
  assert.equal(failedReads, 1);
});
