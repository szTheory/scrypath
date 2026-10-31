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
    compare: () => { comparisons += 1; return { comparisons: [{ differing_pixels: 0, total_pixels: 1, copy_changed: false, state_changed: false, dimensions_changed: false }] }; },
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
    compare: () => ({ comparisons: [{ differing_pixels: 1, total_pixels: 1, copy_changed: false, state_changed: false, dimensions_changed: false }] }),
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
    const mountedInode = fs.statSync(file).ino;
    authority.clock = preservation.writeClockFixture(authority, "2026-10-31T12:00:00.000Z");
    assert.equal(fs.statSync(file).ino, mountedInode, "final publication must retain the mounted clock inode");
    assert.equal(fs.statSync(file).mode & 0o777, 0o444);
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
    const kinds = ["viewport", "full", "hover", "focus", ...(surface === "control-room" && width === 390 ? ["navigation"] : [])];
    const stability = Object.fromEntries(kinds.map((kind) => [kind, {
      method: "consecutive-exact-v1", max_samples: 6, max_elapsed_ms: 10_000,
      samples: [0, 1].map((index) => ({ path: `${id}--${kind}-sample-${index}.png`, sha256: "d".repeat(64), state_path: `${id}--${kind}-sample-${index}.json`, state_sha256: "e".repeat(64), elapsed_ms: index * 16 })),
      selected: 1,
    }]));
    const mobile_navigation = surface === "control-room" && width === 390 ? { expanded: true, visible: true, links: ["Control Room", "Search"] } : undefined;
    const route = deployment === "host"
      ? ({ storefront: "/", "control-room": "/admin/search/", "search-health": "/admin/search/health", "failed-sync": "/admin/search/failed-sync", "sync-drift": "/admin/search/sync-and-index", search: "/admin/search/search", "saved-searches": "/admin/search/search?saved=manage", help: "/admin/search/help" })[surface]
      : ({ "control-room": "/ops/", "search-health": "/ops/health", "failed-sync": "/ops/failed-sync", "sync-drift": "/ops/sync-and-index", search: "/ops/search", "saved-searches": "/ops/search?saved=manage", help: "/ops/help" })[surface];
    return { id, deployment, surface, theme, width, viewport: { width, height: width === 390 ? 844 : 900 }, route, files, stability, mobile_navigation, interaction_target: { tag: "button", role: "button", name: "Continue", href: null }, browser_version: "chromium-123", platform: "linux-arm64", data_identity: "state-digest", clock: { ...clock } };
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
    environment: { browser_version: "chromium-123", browser_launch: { timeout: 30_000, args: ["--disable-partial-raster"] }, platform: "linux-arm64", data_identity: "state-digest", clock },
    captures,
  };
}

function domSnapshotFixture(capture, kind, overrides = {}) {
  const rect = { x: 1, y: 2, width: 120, height: 30 };
  const element = { ...capture.interaction_target };
  const layoutAnchor = { rect, position: "static", display: "block", inset: { top: "auto", right: "auto", bottom: "auto", left: "auto" }, margin: { top: "0px", right: "0px", bottom: "0px", left: "0px" } };
  const effective = capture.theme === "light" ? "light" : "dark";
  return {
    schema: "scrypath.ui-capture-state.v1",
    body_text: "Fixture UI content",
    controls: [{ ...element, value: null, checked: null, selected: null, disabled: false, expanded: null, pressed: null, rect }],
    focus: { element, rect, focus_visible: true, outline: { style: kind === "focus" ? "solid" : "none", width: kind === "focus" ? "2px" : "0px", color: "oklch(0.6 0.2 250)" }, opacity: "1" },
    hover: kind === "hover" ? [{ element, rect }] : [],
    document_has_focus: true,
    layout: { shell: null, shell_content: null, header: null, header_inner: null, main: layoutAnchor, main_inner: layoutAnchor, primary_article: null },
    viewport: { inner: { width: capture.viewport.width, height: capture.viewport.height }, client: { width: capture.viewport.width, height: capture.viewport.height }, document: { width: capture.viewport.width, height: capture.viewport.height }, scroll: { x: 0, y: 0 }, dpr: 1, scale: 1 },
    theme: { preference: capture.theme === "system-dark" ? "system" : capture.theme, effective, data_theme: effective, system_dark: capture.theme !== "light" },
    ...overrides,
  };
}

function domSidecarFixture(capture, kind, overrides = {}) {
  const before = domSnapshotFixture(capture, kind);
  const after = structuredClone(before);
  const root = { ...after, before, after, ...overrides };
  return root;
}

function writeCaptureArtifacts(directory, capture, { stateText = "Fixture UI content" } = {}) {
  fs.mkdirSync(directory, { recursive: true });
  const png = PNG.sync.write(new PNG({ width: capture.viewport.width, height: capture.viewport.height }));
  const canonical = {
    clock: capture.clock,
    observed_at: capture.clock.utc,
    deployment: capture.deployment,
    surface: capture.surface,
    route: capture.route,
    viewport_width: capture.viewport.width,
    page_width: capture.viewport.width,
    theme: { preference: capture.theme === "system-dark" ? "system" : capture.theme, effective: capture.theme === "light" ? "light" : "dark" },
    text: stateText,
  };
  for (const [key, artifact] of Object.entries(capture.files)) {
    const bytes = key === "copy.json" ? Buffer.from(`${JSON.stringify(canonical, null, 2)}\n`) : png;
    fs.writeFileSync(path.join(directory, artifact.path), bytes);
    artifact.sha256 = require("node:crypto").createHash("sha256").update(bytes).digest("hex");
  }
  for (const [kind, proof] of Object.entries(capture.stability)) {
    for (const sample of proof.samples) {
      const imageBytes = png;
      const state = domSidecarFixture(capture, kind);
      state.body_text = stateText;
      state.after.body_text = stateText;
      state.before.body_text = stateText;
      const stateBytes = Buffer.from(`${JSON.stringify(state, null, 2)}\n`);
      fs.writeFileSync(path.join(directory, sample.path), imageBytes);
      fs.writeFileSync(path.join(directory, sample.state_path), stateBytes);
      sample.sha256 = require("node:crypto").createHash("sha256").update(imageBytes).digest("hex");
      sample.state_sha256 = require("node:crypto").createHash("sha256").update(stateBytes).digest("hex");
    }
  }
  return png;
}

function artifactDigest(file) {
  return require("node:crypto").createHash("sha256").update(fs.readFileSync(file)).digest("hex");
}

function writeCompleteArtifactSet(directory, manifest) {
  fs.mkdirSync(directory, { recursive: true });
  for (const capture of manifest.captures) writeCaptureArtifacts(directory, capture);
  fs.writeFileSync(path.join(directory, "capture.json"), "{}\n");
}

function mutateSidecarText(file, text) {
  const state = JSON.parse(fs.readFileSync(file, "utf8"));
  for (const snapshot of [state, state.before, state.after]) if (snapshot) snapshot.body_text = text;
  fs.writeFileSync(file, `${JSON.stringify(state, null, 2)}\n`);
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

test("parent stability regression rejects entries with no screenshot stability proof", () => {
  const manifest = validManifest();
  delete manifest.captures[0].stability.viewport;
  assert.ok(preservation.matrixErrors(manifest).some((error) => /stability/i.test(error)));
});

test("focus capture rejects body focus even when the body claims a large rectangle", () => {
  const capture = validManifest().captures[0];
  const target = { tag: "button", role: "button", name: "Continue", href: null };
  capture.interaction_target = target;
  const sidecar = domSidecarFixture(capture, "focus");
  const body = { tag: "body", role: "generic", name: null, href: null };
  for (const snapshot of [sidecar, sidecar.before, sidecar.after]) {
    snapshot.focus.element = body;
    snapshot.focus.rect = { x: 0, y: 0, width: capture.viewport.width, height: capture.viewport.height };
    snapshot.focus.focus_visible = false;
  }
  assert.ok(preservation.domStateErrors(sidecar, capture, "focus", "body-focus regression").some((error) => /intended focus target|focus-visible evidence/i.test(error)));
});

test("focus and hover proofs bind the intended visible target and opaque computed outline", () => {
  const capture = validManifest().captures[0];
  const baseline = domSidecarFixture(capture, "focus");
  assert.deepEqual(preservation.domStateErrors(baseline, capture, "focus", "valid focus proof"), []);
  const setFocusField = (sidecar, field, value) => {
    for (const snapshot of [sidecar, sidecar.before, sidecar.after]) snapshot.focus[field] = value;
  };

  const wrongTarget = structuredClone(baseline);
  setFocusField(wrongTarget, "element", { tag: "button", role: "button", name: "Other action", href: null });
  assert.ok(preservation.domStateErrors(wrongTarget, capture, "focus", "wrong focus proof").some((error) => /intended focus target/.test(error)));

  const targetNotVisible = structuredClone(baseline);
  for (const snapshot of [targetNotVisible, targetNotVisible.before, targetNotVisible.after]) snapshot.controls[0].name = "Other action";
  assert.ok(preservation.domStateErrors(targetNotVisible, capture, "focus", "missing visible target proof").some((error) => /not among the visible controls/.test(error)));

  const wrongRect = structuredClone(baseline);
  setFocusField(wrongRect, "rect", { x: 0, y: 0, width: 1440, height: 900 });
  assert.ok(preservation.domStateErrors(wrongRect, capture, "focus", "wrong focus rectangle proof").some((error) => /rectangle does not match/.test(error)));

  const hiddenFocus = structuredClone(baseline);
  setFocusField(hiddenFocus, "focus_visible", false);
  assert.ok(preservation.domStateErrors(hiddenFocus, capture, "focus", "hidden focus proof").some((error) => /focus-visible evidence/.test(error)));

  const unfocusedDocument = structuredClone(baseline);
  for (const snapshot of [unfocusedDocument, unfocusedDocument.before, unfocusedDocument.after]) snapshot.document_has_focus = false;
  assert.ok(preservation.domStateErrors(unfocusedDocument, capture, "focus", "unfocused document proof").some((error) => /focus-visible evidence/.test(error)));

  const noOutline = structuredClone(baseline);
  setFocusField(noOutline, "outline", { style: "none", width: "0px", color: "oklch(0.6 0.2 250)" });
  assert.ok(preservation.domStateErrors(noOutline, capture, "focus", "no outline proof").some((error) => /no positive computed width/.test(error)));

  const transparent = structuredClone(baseline);
  setFocusField(transparent, "outline", { style: "solid", width: "2px", color: "rgb(0 0 0 / 0)" });
  assert.ok(preservation.domStateErrors(transparent, capture, "focus", "transparent outline proof").some((error) => /unknown or transparent/.test(error)));

  const unknownColor = structuredClone(baseline);
  setFocusField(unknownColor, "outline", { style: "solid", width: "2px", color: "color(display-p3 1 0 0)" });
  assert.ok(preservation.domStateErrors(unknownColor, capture, "focus", "unknown outline proof").some((error) => /unknown or transparent/.test(error)));

  const rgbColor = structuredClone(baseline);
  setFocusField(rgbColor, "outline", { style: "solid", width: "2px", color: "rgb(20 40 60 / 50%)" });
  assert.deepEqual(preservation.domStateErrors(rgbColor, capture, "focus", "RGB outline proof"), []);

  const wrongHover = domSidecarFixture(capture, "hover");
  for (const snapshot of [wrongHover, wrongHover.before, wrongHover.after]) snapshot.hover[0].element = { ...snapshot.hover[0].element, name: "Other action" };
  assert.ok(preservation.domStateErrors(wrongHover, capture, "hover", "wrong hover proof").some((error) => /intended interaction target/.test(error)));
});

test("stability structure binds exact sample paths, monotonic elapsed bounds, and final selection", () => {
  const manifest = validManifest();
  const capture = manifest.captures[0];
  capture.stability.viewport.samples[0].path = capture.stability.viewport.samples[1].path;
  assert.ok(preservation.matrixErrors(manifest).some((error) => /sample path or digest is invalid/.test(error)));

  const elapsed = validManifest();
  elapsed.captures[0].stability.viewport.samples[1].elapsed_ms = 10_001;
  assert.ok(preservation.matrixErrors(elapsed).some((error) => /elapsed time.*bounded/.test(error)));

  const monotonic = validManifest();
  monotonic.captures[0].stability.viewport.samples[0].elapsed_ms = 5;
  monotonic.captures[0].stability.viewport.samples[1].elapsed_ms = 0;
  assert.ok(preservation.matrixErrors(monotonic).some((error) => /elapsed time.*monotonic/.test(error)));

  const selection = validManifest();
  selection.captures[0].stability.viewport.selected = 0;
  assert.ok(preservation.matrixErrors(selection).some((error) => /final stability sample/.test(error)));

  const extraKind = validManifest();
  extraKind.captures[0].stability.extra = structuredClone(extraKind.captures[0].stability.viewport);
  assert.ok(preservation.matrixErrors(extraKind).some((error) => /missing or contain unmatched kinds/.test(error)));
});

test("capture interaction target must be a named allowed control", () => {
  const badTag = validManifest();
  badTag.captures[0].interaction_target.tag = "body";
  assert.ok(preservation.matrixErrors(badTag).some((error) => /allowed interactive control tag/.test(error)));

  const unnamed = validManifest();
  unnamed.captures[0].interaction_target.name = "  ";
  assert.ok(preservation.matrixErrors(unnamed).some((error) => /non-empty accessible name/.test(error)));

  const absent = validManifest();
  delete absent.captures[0].interaction_target;
  assert.ok(preservation.matrixErrors(absent).some((error) => /interaction target semantic element is invalid/.test(error)));
});

test("storefront DOM-state proof requires the actual observed theme attributes", () => {
  const capture = validManifest().captures.find(({ id }) => id === "host--storefront--system-dark--1440");
  const sidecar = domSidecarFixture(capture, "viewport");
  for (const snapshot of [sidecar, sidecar.before, sidecar.after]) {
    snapshot.theme.preference = null;
    snapshot.theme.effective = null;
  }
  assert.ok(preservation.domStateErrors(sidecar, capture, "viewport", "storefront theme proof").some((error) => /theme state does not match/.test(error)));
});

test("stability proof verifies every sample, sidecar, selected PNG, and finite artifact bound", () => {
  fs.mkdirSync(preservation.artifactRoot, { recursive: true });
  const directory = fs.mkdtempSync(path.join(preservation.artifactRoot, "stability-proof-test-"));
  const manifest = validManifest();
  try {
    writeCompleteArtifactSet(directory, manifest);
    assert.deepEqual(preservation.artifactErrors(manifest, directory), []);

    const capture = manifest.captures[0];
    const proof = capture.stability.viewport;
    const firstImage = path.join(directory, proof.samples[0].path);
    const lastImage = path.join(directory, proof.samples[1].path);
    const selectedImage = path.join(directory, capture.files["viewport.png"].path);
    const firstState = path.join(directory, proof.samples[0].state_path);
    const secondState = path.join(directory, proof.samples[1].state_path);
    const originalPng = fs.readFileSync(firstImage);

    const alternate = PNG.sync.read(originalPng);
    alternate.data[0] = alternate.data[0] ^ 1;
    const changedPng = PNG.sync.write(alternate);
    fs.writeFileSync(lastImage, changedPng);
    proof.samples[1].sha256 = artifactDigest(lastImage);
    const unstableImages = preservation.artifactErrors(manifest, directory);
    assert.ok(unstableImages.some((error) => error.includes("Final two screenshot samples are not byte-identical")));
    assert.ok(unstableImages.some((error) => error.includes("Selected screenshot does not match the final stability sample")));
    fs.writeFileSync(lastImage, originalPng);
    proof.samples[1].sha256 = artifactDigest(lastImage);

    fs.writeFileSync(selectedImage, changedPng);
    capture.files["viewport.png"].sha256 = artifactDigest(selectedImage);
    assert.ok(preservation.artifactErrors(manifest, directory).some((error) => error.includes("Selected screenshot does not match the final stability sample")));
    fs.writeFileSync(selectedImage, originalPng);
    capture.files["viewport.png"].sha256 = artifactDigest(selectedImage);

    mutateSidecarText(firstState, "tampered without updating the sidecar digest");
    assert.ok(preservation.artifactErrors(manifest, directory).some((error) => error.includes("artifact digest mismatch")));
    const originalState = domSidecarFixture(capture, "viewport");
    const originalStateBytes = Buffer.from(`${JSON.stringify(originalState, null, 2)}\n`);
    fs.writeFileSync(firstState, originalStateBytes);
    proof.samples[0].state_sha256 = artifactDigest(firstState);

    mutateSidecarText(secondState, "different but internally stable sample");
    proof.samples[1].state_sha256 = artifactDigest(secondState);
    assert.ok(preservation.artifactErrors(manifest, directory).some((error) => error.includes("DOM state changed between screenshot samples")));
    fs.writeFileSync(secondState, originalStateBytes);
    proof.samples[1].state_sha256 = artifactDigest(secondState);

    const transitioned = JSON.parse(fs.readFileSync(firstState, "utf8"));
    transitioned.after.body_text = "changed while screenshot was being taken";
    fs.writeFileSync(firstState, `${JSON.stringify(transitioned, null, 2)}\n`);
    proof.samples[0].state_sha256 = artifactDigest(firstState);
    assert.ok(preservation.artifactErrors(manifest, directory).some((error) => error.includes("DOM state changed across the screenshot")));
    fs.writeFileSync(firstState, originalStateBytes);
    proof.samples[0].state_sha256 = artifactDigest(firstState);

    const geometry = JSON.parse(fs.readFileSync(firstState, "utf8"));
    for (const snapshot of [geometry, geometry.before, geometry.after]) for (const anchor of Object.values(snapshot.layout)) if (anchor) { anchor.rect.width = 0; anchor.rect.height = 0; }
    fs.writeFileSync(firstState, `${JSON.stringify(geometry, null, 2)}\n`);
    proof.samples[0].state_sha256 = artifactDigest(firstState);
    assert.ok(preservation.artifactErrors(manifest, directory).some((error) => error.includes("no positive-area layout anchor")));
    fs.writeFileSync(firstState, originalStateBytes);
    proof.samples[0].state_sha256 = artifactDigest(firstState);

    fs.unlinkSync(firstImage);
    fs.symlinkSync(path.basename(lastImage), firstImage);
    assert.ok(preservation.artifactErrors(manifest, directory).some((error) => error.includes("artifact is not a regular file")));
    fs.unlinkSync(firstImage);
    fs.writeFileSync(firstImage, originalPng);
    proof.samples[0].sha256 = artifactDigest(firstImage);

    fs.unlinkSync(firstState);
    fs.symlinkSync(path.basename(secondState), firstState);
    assert.ok(preservation.artifactErrors(manifest, directory).some((error) => error.includes("artifact is not a regular file")));
    fs.unlinkSync(firstState);
    fs.writeFileSync(firstState, originalStateBytes);
    proof.samples[0].state_sha256 = artifactDigest(firstState);

    const oversizedCanvasHeader = Buffer.from(originalPng.subarray(0, 24));
    oversizedCanvasHeader.writeUInt32BE(5_000, 16);
    oversizedCanvasHeader.writeUInt32BE(5_000, 20);
    fs.writeFileSync(firstImage, oversizedCanvasHeader);
    proof.samples[0].sha256 = artifactDigest(firstImage);
    assert.ok(preservation.artifactErrors(manifest, directory).some((error) => error.includes("24,000,000-pixel artifact bound")));

    const entries = preservation.captureArtifactEntries(capture);
    assert.equal(entries.filter(({ type }) => type === "sample-state").length, Object.values(capture.stability).reduce((sum, item) => sum + item.samples.length, 0));
    assert.throws(() => preservation.addArtifactBytes(2 * 1024 * 1024 * 1024 - 1, 2), /total artifact bound/);
    assert.throws(() => preservation.addArtifactBytes(0, 0), /positive file sizes/);
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});

test("paired selected DOM states are compared even when image pixels match", () => {
  fs.mkdirSync(preservation.artifactRoot, { recursive: true });
  const beforeDirectory = fs.mkdtempSync(path.join(preservation.artifactRoot, "state-before-test-"));
  const afterDirectory = fs.mkdtempSync(path.join(preservation.artifactRoot, "state-after-test-"));
  const beforeCapture = validManifest().captures[0];
  const afterCapture = structuredClone(beforeCapture);
  try {
    writeCaptureArtifacts(beforeDirectory, beforeCapture);
    writeCaptureArtifacts(afterDirectory, afterCapture);
    const selected = afterCapture.stability.viewport.selected;
    const sample = afterCapture.stability.viewport.samples[selected];
    assert.deepEqual(fs.readFileSync(path.join(beforeDirectory, beforeCapture.files["viewport.png"].path)), fs.readFileSync(path.join(afterDirectory, afterCapture.files["viewport.png"].path)));
    const file = path.join(afterDirectory, sample.state_path);
    mutateSidecarText(file, "same pixels, changed rendered text");
    sample.state_sha256 = artifactDigest(file);
    assert.equal(preservation.selectedDomStateChanged(beforeCapture, afterCapture, beforeDirectory, afterDirectory, "viewport"), true);
    assert.equal(preservation.preservationPassed({ comparisons: [{ differing_pixels: 0, total_pixels: 1, copy_changed: false, state_changed: true, dimensions_changed: false }] }), false);
  } finally {
    fs.rmSync(beforeDirectory, { recursive: true, force: true });
    fs.rmSync(afterDirectory, { recursive: true, force: true });
  }
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
  const budgets = [];
  await assert.rejects(preservation.waitForPublishedClock((remainingMs) => { reads += 1; budgets.push(remainingMs); return "wrong bytes\n"; }, "expected\n", { timeoutMs: 20, intervalMs: 1 }), /not published within/);
  assert.ok(reads >= 2);
  assert.equal(budgets.every(ms => Number.isSafeInteger(ms) && ms > 0 && ms <= 20), true, "every read must receive the remaining total deadline");
  const permission = new Error("Docker permission denied");
  let failedReads = 0;
  await assert.rejects(preservation.waitForPublishedClock(() => { failedReads += 1; throw permission; }, "expected\n", { timeoutMs: 20, intervalMs: 1 }), error => error === permission);
  assert.equal(failedReads, 1);
});


test("captured browser launch metadata matches the actual runner request and rejects recipe drift", async () => {
  const runner = await import("../../examples/scrypath_ecommerce/e2e/ui-review.mjs");
  let received;
  const { launchOptions } = await runner.launchDisposableBrowser({ launch: async options => { received = structuredClone(options); return {}; } });
  assert.deepEqual(launchOptions, received);
  const manifest = validManifest();
  manifest.environment.browser_launch = received;
  assert.deepEqual(preservation.disposableProvenanceErrors(manifest, expected()), []);
  for (const profile of [undefined, { timeout: 30_000, args: [] }, { ...received, ignoreDefaultArgs: true }, { ...received, args: [...received.args, "--disable-web-security"] }, { ...received, timeout: 1 }]) {
    manifest.environment.browser_launch = profile;
    assert.ok(preservation.disposableProvenanceErrors(manifest, expected()).some(error => /browser launch profile/i.test(error)));
  }
});
