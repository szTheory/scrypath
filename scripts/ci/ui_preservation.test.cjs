"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const preservation = fs.existsSync(path.join(__dirname, "ui_preservation.cjs")) ? require("./ui_preservation.cjs") : {};

const sourceSha = "a".repeat(40);
const treeSha = "b".repeat(64);
const project = "scrypath-p185-0123456789abcdef";

function validManifest() {
  const captures = preservation.expectedCaptureIds().map((id) => {
    const [deployment, surface, theme, widthText] = id.split("--");
    const width = Number(widthText);
    const files = Object.fromEntries(["copy.json", "viewport.png", "full.png", "hover.png", "focus.png"].map((kind) => [kind, { path: `${id}--${kind}`, sha256: "c".repeat(64) }]));
    if (surface === "control-room" && width === 390) files.navigation = { path: `${id}--navigation.png`, sha256: "c".repeat(64) };
    return { id, deployment, surface, theme, width, viewport: { width, height: width === 390 ? 844 : 900 }, files, browser_version: "chromium-123", platform: "darwin-arm64", data_identity: "state-digest" };
  });
  const identities = ["web", "standalone_ops"].map((service) => ({ service, id: `${service}-image`, labels: { "org.opencontainers.image.revision": sourceSha }, source_sha: sourceSha, tree_sha256: treeSha }));
  return {
    schema: "scrypath.ui-disposable.v1", mode: "disposable", purpose: "historical-baseline",
    source: { source_sha: sourceSha, tree_sha256: treeSha },
    runtime: {
      compose_project: project, owned: true, isolated: true, source_match: true, retained_resources_disjoint: true,
      host_ports: ["127.0.0.1:53111->4002/tcp", "127.0.0.1:53112->4003/tcp"],
      volumes: [`${project}-postgres`, `${project}-meili`], images: identities,
      containers: identities.map(({ service, source_sha, tree_sha256 }) => ({ service, id: `${service}-container`, name: `${service}-container`, labels: { "org.opencontainers.image.revision": source_sha }, source_sha, tree_sha256 })),
      mounts: [], routes: { mounted: true, standalone: true },
    },
    environment: { browser_version: "chromium-123", platform: "darwin-arm64", data_identity: "state-digest" },
    captures,
  };
}

function expected() {
  return { source_sha: sourceSha, tree_sha256: treeSha, retained_project: "scrypath_ecommerce", retained_port: 4002, retained_volumes: ["scrypath_ecommerce_postgres_data"] };
}

test("frozen preservation matrix covers 72 host and 63 standalone observations", () => {
  const ids = preservation.expectedCaptureIds();
  assert.equal(ids.filter((id) => id.startsWith("host--")).length, 72);
  assert.equal(ids.filter((id) => id.startsWith("standalone--")).length, 63);
  assert.equal(ids.length, 135);
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
  assert.ok(preservation.disposableProvenanceErrors(manifest, expected()).some((error) => error.includes("source SHA or tree fingerprint")));
  manifest.source.tree_sha256 = treeSha;
  manifest.runtime.images[0].labels["org.opencontainers.image.revision"] = "f".repeat(40);
  manifest.runtime.containers[1].source_sha = "e".repeat(40);
  assert.ok(preservation.disposableProvenanceErrors(manifest, expected()).some((error) => error.includes("source")));
});

test("source identity changes during startup or capture are rejected", () => {
  assert.deepEqual(preservation.sourceChangeErrors({ source_sha: sourceSha, tree_sha256: treeSha }, { source_sha: sourceSha, tree_sha256: treeSha }), []);
  assert.ok(preservation.sourceChangeErrors({ source_sha: sourceSha, tree_sha256: treeSha }, { source_sha: "f".repeat(40), tree_sha256: treeSha }).some((error) => error.includes("Source changed")));
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
