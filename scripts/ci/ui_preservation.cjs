"use strict";

const crypto = require("node:crypto");
const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const net = require("node:net");
const path = require("node:path");

const repositoryRoot = path.resolve(__dirname, "../..");
const exampleRoot = path.join(repositoryRoot, "examples/scrypath_ecommerce");
const sessionRoot = "/private/tmp/scrypath-phase185-execution";
const artifactRoot = path.join(sessionRoot, "ui-review-artifacts", "phase185");
const previewPath = path.join(repositoryRoot, ".planning/UI-PREVIEW.json");
const revisionLabel = "org.opencontainers.image.revision";
const fingerprintLabel = "org.opencontainers.image.source-fingerprint";
const ownerLabel = "com.scrypath.phase185.session";
const themes = ["light", "dark", "system-dark"];
const widths = [1440, 768, 390];
const hostSurfaces = ["storefront", "control-room", "search-health", "failed-sync", "sync-drift", "search", "saved-searches", "help"];
const standaloneSurfaces = hostSurfaces.filter((surface) => surface !== "storefront");
const hostRoutes = {
  storefront: "/", "control-room": "/admin/search/", "search-health": "/admin/search/health",
  "failed-sync": "/admin/search/failed-sync", "sync-drift": "/admin/search/sync-and-index",
  search: "/admin/search/search", "saved-searches": "/admin/search/search?saved=manage", help: "/admin/search/help",
};
const standaloneRoutes = {
  "control-room": "/ops/", "search-health": "/ops/health", "failed-sync": "/ops/failed-sync",
  "sync-drift": "/ops/sync-and-index", search: "/ops/search",
  "saved-searches": "/ops/playbooks?saved=manage", help: "/ops/help",
};
const MAX_ARTIFACT_BYTES = 32 * 1024 * 1024;
const MAX_CAPTURE_BYTES = 2 * 1024 * 1024 * 1024;
const INDEX_PAGE_LIMIT = 1000;
const MAX_INDEX_COUNT = 10_000;
const MAX_DOCUMENT_COUNT = 50_000;

const sha256 = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");
const canonicalize = (value) => Array.isArray(value)
  ? value.map(canonicalize)
  : value && typeof value === "object"
    ? Object.fromEntries(Object.keys(value).sort().map((key) => [key, canonicalize(value[key])]))
    : value;
const canonicalJson = (value) => JSON.stringify(canonicalize(value));
function gitEnvironment(environment = process.env) {
  const clean = Object.fromEntries(Object.entries(environment).filter(([key]) => !/^GIT_/i.test(key)));
  clean.GIT_CONFIG_NOSYSTEM = "1";
  clean.GIT_CONFIG_GLOBAL = process.platform === "win32" ? "NUL" : "/dev/null";
  return clean;
}

function isCanonicalOrigin(origin) {
  return new Set([
    "https://github.com/szTheory/scrypath",
    "https://github.com/szTheory/scrypath.git",
    "ssh://git@github.com/szTheory/scrypath",
    "ssh://git@github.com/szTheory/scrypath.git",
    "git@github.com:szTheory/scrypath",
    "git@github.com:szTheory/scrypath.git",
  ]).has(String(origin).trim());
}

function run(command, args, options = {}) {
  const outputEncoding = options.encoding === "buffer" ? null : (options.encoding || "utf8");
  const result = spawnSync(command, args, {
    cwd: options.cwd || repositoryRoot,
    env: command === "git" ? gitEnvironment(options.env || process.env) : (options.env || process.env),
    encoding: outputEncoding,
    timeout: options.timeout ?? 30_000,
    maxBuffer: options.maxBuffer ?? 32 * 1024 * 1024,
  });
  if (result.error) throw new Error(`${command} failed: ${result.error.message}`);
  if (result.status !== 0) {
    const rawDetail = result.stderr || result.stdout || "";
    const detail = (Buffer.isBuffer(rawDetail) ? rawDetail.toString("utf8") : rawDetail).trim();
    throw new Error(`${command} ${args.join(" ")} exited ${result.status}${detail ? `: ${detail}` : ""}`);
  }
  return options.encoding === "buffer" ? result.stdout : result.stdout.trimEnd();
}

function git(args, options = {}) {
  return run("git", args, options);
}

function writeJson(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const temporary = `${file}.${process.pid}.tmp`;
  fs.writeFileSync(temporary, `${JSON.stringify(value, null, 2)}\n`, { mode: 0o600 });
  fs.renameSync(temporary, file);
}

function readJson(file) {
  const details = fs.lstatSync(file);
  if (details.isSymbolicLink() || !details.isFile() || details.size <= 0 || details.size > 64 * 1024 * 1024) throw new Error(`Refusing unbounded or non-regular JSON input: ${file}`);
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function sourceIdentity(checkRemote = true) {
  const origin = git(["remote", "get-url", "origin"]);
  if (!isCanonicalOrigin(origin)) throw new Error(`Refusing source identity from non-canonical origin: ${origin}`);
  const dirty = git(["status", "--porcelain", "--untracked-files=all"]);
  if (dirty) throw new Error(`Disposable capture requires a clean committed source snapshot:\n${dirty}`);
  const source_sha = git(["rev-parse", "HEAD"]);
  const tree_oid = git(["rev-parse", `${source_sha}^{tree}`]);
  const tree = git(["ls-tree", "-r", "-z", "--full-tree", source_sha], { encoding: "buffer", timeout: 60_000, maxBuffer: 128 * 1024 * 1024 });
  const main_ref = git(["rev-parse", "refs/remotes/origin/main"]);
  const main_included = git(["merge-base", "refs/remotes/origin/main", source_sha]) === main_ref;
  const remote = checkRemote ? git(["ls-remote", "--exit-code", "origin", "refs/heads/main"], { timeout: 15_000, maxBuffer: 1024 * 1024 }) : "";
  const remote_main_ref = checkRemote ? remote.split(/\s+/)[0] : null;
  return {
    source_sha,
    tree_oid,
    tree_sha256: sha256(tree),
    main_ref,
    main_included,
    remote_main_ref,
    remote_main_current: checkRemote && remote_main_ref === main_ref,
  };
}

function ensureArtifactRoot() {
  fs.mkdirSync(artifactRoot, { recursive: true, mode: 0o700 });
  const info = fs.lstatSync(artifactRoot);
  if (info.isSymbolicLink() || !info.isDirectory() || fs.realpathSync(artifactRoot) !== path.resolve(artifactRoot)) {
    throw new Error(`Disposable evidence root is not a stable regular directory: ${artifactRoot}`);
  }
}

function sourceChangeErrors(start, end) {
  const errors = [];
  if (!start?.source_sha || !start?.tree_sha256 || !end?.source_sha || !end?.tree_sha256) errors.push("Source identity is incomplete.");
  else if (start.source_sha !== end.source_sha || start.tree_sha256 !== end.tree_sha256) errors.push("Source changed during capture.");
  return errors;
}

function indexResults(payload) {
  const results = Array.isArray(payload) ? payload : payload?.results;
  if (!Array.isArray(results)) throw new Error("Meilisearch index listing did not contain a results array.");
  if (!Array.isArray(payload)) {
    const { offset, limit, total } = payload;
    if (!Number.isSafeInteger(offset) || offset < 0 || !Number.isSafeInteger(limit) || limit < 1 || !Number.isSafeInteger(total) || total < 0) {
      throw new Error("Meilisearch pagination requires a finite non-negative total, non-negative offset, and positive limit.");
    }
    if (results.length > limit || offset + results.length > total) throw new Error("Meilisearch page exceeds its declared finite bounds.");
  }
  return results;
}

function collectPages(fetchPage, { label, maxItems, pageLimit = INDEX_PAGE_LIMIT }) {
  if (typeof fetchPage !== "function" || !Number.isSafeInteger(maxItems) || maxItems < 1 || !Number.isSafeInteger(pageLimit) || pageLimit < 1 || pageLimit > INDEX_PAGE_LIMIT) {
    throw new Error("Meilisearch pagination requires a bounded fetch function and positive finite limits.");
  }
  const items = [];
  let expectedTotal = null;
  let offset = 0;
  const maxPages = Math.ceil(maxItems / pageLimit) + 1;
  for (let pageNumber = 0; pageNumber < maxPages; pageNumber += 1) {
    const payload = fetchPage(offset, pageLimit);
    if (Array.isArray(payload)) throw new Error(`Meilisearch ${label} response omitted pagination metadata.`);
    const page = indexResults(payload);
    if (payload.offset !== offset || payload.limit !== pageLimit) throw new Error(`Meilisearch ${label} pagination did not match the requested offset and limit.`);
    if (expectedTotal === null) expectedTotal = payload.total;
    else if (payload.total !== expectedTotal) throw new Error(`Meilisearch ${label} total changed during pagination.`);
    if (expectedTotal > maxItems) throw new Error(`Meilisearch ${label} exceeds the ${maxItems} item identity limit.`);
    const expectedPageLength = Math.min(pageLimit, Math.max(0, expectedTotal - offset));
    if (page.length !== expectedPageLength) throw new Error(`Meilisearch ${label} pagination made incomplete or non-progressing results.`);
    items.push(...page);
    offset += page.length;
    if (offset === expectedTotal) return items;
  }
  throw new Error(`Meilisearch ${label} pagination exceeded its finite page bound.`);
}

function normalizePgDump(dump) {
  if (typeof dump !== "string") throw new Error("PostgreSQL data dump must be text.");
  const lines = dump.split("\n");
  const restrict = lines.filter((line) => /^\\restrict [A-Za-z0-9_+/=-]+\r?$/.test(line));
  const unrestrict = lines.filter((line) => /^\\unrestrict [A-Za-z0-9_+/=-]+\r?$/.test(line));
  if (!restrict.length && !unrestrict.length) return dump;
  const token = (line) => line.replace(/^\\(?:un)?restrict /, "").replace(/\r$/, "");
  if (restrict.length !== 1 || unrestrict.length !== 1 || token(restrict[0]) !== token(unrestrict[0])) {
    throw new Error("PostgreSQL dump contains an unmatched or repeated transport restriction nonce.");
  }
  return lines.filter((line) => line !== restrict[0] && line !== unrestrict[0]).join("\n");
}

function stableDataIdentity(state) {
  if (!state || typeof state !== "object" || !state.databases || !Array.isArray(state.indexes)) throw new Error("Rendered-state identity requires database and search-index state.");
  return sha256(canonicalJson({ schema: "scrypath.ui-rendered-state.v2", databases: state.databases, indexes: state.indexes }));
}

function normalizePort(value) {
  if (typeof value === "number") return { host: "127.0.0.1", port: value };
  if (typeof value !== "string") return { host: "", port: NaN };
  const match = value.match(/^(\[[^\]]+\]|[^:]+):(\d+)(?:->\d+(?:\/tcp)?)?$/);
  return match ? { host: match[1].replace(/^\[|\]$/g, ""), port: Number(match[2]) } : { host: "", port: NaN };
}

function disposableProvenanceErrors(manifest, expected = {}) {
  const errors = [];
  if (manifest?.schema !== "scrypath.ui-disposable.v1") errors.push("Unsupported disposable manifest schema.");
  if (manifest?.mode !== "disposable") errors.push("Capture is not explicitly marked disposable.");
  if (!expected.source_sha || !expected.tree_sha256) errors.push("Independent expected source SHA and tree fingerprint are required.");
  if (!expected.retained_project || !Number.isInteger(expected.retained_port) || !Array.isArray(expected.retained_volumes)) errors.push("Retained project, port, and volume identities are required.");

  const project = manifest?.runtime?.compose_project;
  if (typeof project !== "string" || !/^scrypath-p185-[a-z0-9][a-z0-9-]{7,31}$/.test(project)) errors.push("Disposable Compose project is not in the unique phase185 namespace.");
  if (project && expected.retained_project && project === expected.retained_project) errors.push("Disposable capture reuses the retained project.");
  if (manifest?.runtime?.owned !== true || manifest?.runtime?.isolated !== true) errors.push("Disposable stack ownership or isolation is unverified.");
  if (manifest?.runtime?.source_match !== true) errors.push("Disposable image/container source provenance is unverified.");
  if (manifest?.source?.source_sha !== expected.source_sha || manifest?.source?.tree_sha256 !== expected.tree_sha256) errors.push("Disposable manifest source SHA or tree fingerprint does not match the independently pinned source.");

  const runtime = manifest?.runtime || {};
  for (const [kind, identities] of [["image", runtime.images], ["container", runtime.containers]]) {
    if (!Array.isArray(identities) || identities.length < 2) {
      errors.push(`Disposable ${kind} identities are incomplete.`);
      continue;
    }
    for (const identity of identities) {
      if (identity.source_sha !== expected.source_sha || identity.tree_sha256 !== expected.tree_sha256) errors.push(`Disposable ${kind} source labels mismatch for ${identity.service || "unknown service"}.`);
      if (!identity.id || !identity.labels || identity.labels[revisionLabel] !== expected.source_sha) errors.push(`Disposable ${kind} is missing its independently checked source label.`);
      if (kind === "container" && !identity.name) errors.push("Disposable container name identity is missing.");
      if (kind === "container" && expected.retained_container && identity.name === expected.retained_container) errors.push("Disposable capture reuses the retained container.");
    }
  }

  const ports = Array.isArray(runtime.host_ports) ? runtime.host_ports : [];
  if (!ports.length) errors.push("Disposable loopback port identities are missing.");
  for (const value of ports) {
    const { host, port } = normalizePort(value);
    if (!Number.isInteger(port) || !["127.0.0.1", "::1", "localhost"].includes(host)) errors.push(`Disposable target is not a valid loopback port: ${value}.`);
    if (port === expected.retained_port) errors.push("Disposable capture reuses the retained port.");
  }
  const volumes = Array.isArray(runtime.volumes) ? runtime.volumes : [];
  if (!volumes.length) errors.push("Disposable owned volume identities are missing.");
  if (expected.retained_volumes?.some((name) => volumes.includes(name))) errors.push("Disposable capture reuses a retained volume.");
  if (volumes.some((volume) => typeof volume !== "string" || !volume.startsWith(`${project}-`))) errors.push("Disposable volume ownership does not match the unique Compose project.");
  if (runtime.retained_resources_disjoint !== true) errors.push("Disposable resources have not been checked against retained resources.");
  if (runtime.mounts?.some((mount) => mount.type === "bind" && mount.destination === "/app")) errors.push("Disposable app source uses a bind mount instead of the pinned image.");
  if (!runtime.routes?.mounted || !runtime.routes?.standalone) errors.push("Mounted and standalone Ops routes are not both verified.");
  if (manifest?.environment?.browser_version === undefined || !manifest?.environment?.platform || !manifest?.environment?.data_identity) errors.push("Browser, platform, or deterministic data identity is missing.");
  return errors;
}

function expectedCaptureIds() {
  const result = [];
  for (const deployment of ["host", "standalone"]) {
    const surfaces = deployment === "host" ? hostSurfaces : standaloneSurfaces;
    for (const surface of surfaces) for (const theme of themes) for (const width of widths) result.push(`${deployment}--${surface}--${theme}--${width}`);
  }
  return result;
}

function expectedCaptureMetadata() {
  const result = new Map();
  for (const deployment of ["host", "standalone"]) {
    const surfaces = deployment === "host" ? hostSurfaces : standaloneSurfaces;
    const routes = deployment === "host" ? hostRoutes : standaloneRoutes;
    for (const surface of surfaces) for (const theme of themes) for (const width of widths) {
      result.set(`${deployment}--${surface}--${theme}--${width}`, {
        deployment,
        surface,
        theme,
        width,
        height: width === 390 ? 844 : 900,
        route: routes[surface],
      });
    }
  }
  return result;
}

function matrixErrors(manifest) {
  const errors = [];
  const expected = expectedCaptureMetadata();
  const captures = Array.isArray(manifest?.captures) ? manifest.captures : [];
  const found = new Map(captures.map((capture) => [capture.id, capture]));
  if (found.size !== captures.length) errors.push("Capture matrix contains duplicate identities.");
  for (const id of expected.keys()) if (!found.has(id)) errors.push(`Missing paired capture: ${id}.`);
  for (const id of found.keys()) if (!expected.has(id)) errors.push(`Unexpected capture identity: ${id}.`);
  for (const capture of captures) {
    const canonical = expected.get(capture.id);
    if (canonical && (capture.deployment !== canonical.deployment || capture.surface !== canonical.surface || capture.theme !== canonical.theme || capture.width !== canonical.width || capture.route !== canonical.route || capture.viewport?.width !== canonical.width || capture.viewport?.height !== canonical.height)) {
      errors.push(`Capture metadata does not match canonical identity: ${capture.id}.`);
    }
    if (capture.error) errors.push(`Capture failed: ${capture.id}: ${capture.error}`);
    if (!capture.files?.["copy.json"] || !capture.files?.["viewport.png"] || !capture.files?.["full.png"] || !capture.files?.["hover.png"] || !capture.files?.["focus.png"]) errors.push(`Capture lacks image or copy evidence: ${capture.id}.`);
    if (capture.surface === "control-room" && capture.width === 390 && (!capture.files?.["navigation.png"] || capture.mobile_navigation?.expanded !== true || capture.mobile_navigation?.visible !== true || !capture.mobile_navigation?.links?.length)) errors.push(`Compact navigation evidence is missing or did not open: ${capture.id}.`);
    if (!capture.browser_version || !capture.platform || !capture.data_identity) errors.push(`Capture lacks browser, platform, or data identity: ${capture.id}.`);
    if (capture.browser_version !== manifest?.environment?.browser_version || capture.platform !== manifest?.environment?.platform || capture.data_identity !== manifest?.environment?.data_identity) errors.push(`Unpaired browser/platform/data identity: ${capture.id}.`);
    for (const [kind, file] of Object.entries(capture.files || {})) {
      if (file.path !== `${capture.id}--${kind}` || !/^[a-f0-9]{64}$/.test(file.sha256 || "")) errors.push(`Invalid ${kind} artifact path or digest: ${capture.id}.`);
    }
    if (!widths.includes(capture.width)) errors.push(`Unpaired viewport width: ${capture.id}.`);
    if (!themes.includes(capture.theme)) errors.push(`Unpaired theme: ${capture.id}.`);
  }
  return errors;
}

function pngDimensions(bytes) {
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  if (!Buffer.isBuffer(bytes) || bytes.length < 24 || !bytes.subarray(0, 8).equals(signature) || bytes.toString("ascii", 12, 16) !== "IHDR") {
    throw new Error("invalid PNG header");
  }
  const width = bytes.readUInt32BE(16);
  const height = bytes.readUInt32BE(20);
  if (!width || !height || width > 20_000 || height > 50_000) throw new Error("PNG dimensions are outside finite bounds");
  return { width, height };
}

function artifactDirectoryRoot(directory) {
  const absolute = path.resolve(directory);
  const rootStat = fs.lstatSync(absolute);
  if (rootStat.isSymbolicLink() || !rootStat.isDirectory()) throw new Error("Evidence directory must be a regular directory, not a symlink.");
  const real = fs.realpathSync(absolute);
  if (!real.startsWith(`${path.resolve(artifactRoot)}${path.sep}`)) throw new Error("Evidence directory is outside the ignored phase185 artifact root.");
  return { absolute, real };
}

function artifactErrors(manifest, directory) {
  const errors = matrixErrors(manifest);
  let root;
  try { root = artifactDirectoryRoot(directory); }
  catch (error) { errors.push(error.message); return errors; }
  let totalBytes = 0;
  for (const capture of manifest.captures || []) for (const artifact of Object.values(capture.files || {})) {
    try {
      if (typeof artifact.path !== "string" || path.isAbsolute(artifact.path) || path.basename(artifact.path) !== artifact.path) throw new Error("artifact path must be a file directly inside its capture directory");
      const file = path.resolve(root.absolute, artifact.path);
      if (!file.startsWith(`${root.absolute}${path.sep}`)) throw new Error("artifact escapes capture directory");
      const fileStat = fs.lstatSync(file);
      if (fileStat.isSymbolicLink() || !fileStat.isFile()) throw new Error("artifact is not a regular file");
      if (fileStat.size <= 0 || fileStat.size > MAX_ARTIFACT_BYTES) throw new Error("artifact size is outside finite bounds");
      totalBytes += fileStat.size;
      if (totalBytes > MAX_CAPTURE_BYTES) throw new Error("capture directory exceeds its finite total artifact bound");
      if (fs.realpathSync(file).startsWith(`${root.real}${path.sep}`) !== true) throw new Error("artifact resolves outside capture directory");
      const bytes = fs.readFileSync(file);
      if (sha256(bytes) !== artifact.sha256) throw new Error("artifact digest mismatch");
      if (path.extname(artifact.path) === ".png") {
        const size = pngDimensions(bytes);
        const expected = capture.viewport || {};
        const dimensionsMatch = artifact.path.endsWith("--full.png")
          ? size.width === expected.width && size.height >= expected.height
          : size.width === expected.width && size.height === expected.height;
        if (!dimensionsMatch) throw new Error(`${path.basename(artifact.path).split("--").at(-1)} dimensions do not match ${capture.id}`);
      } else if (artifact.path.endsWith("--copy.json")) {
        const copy = JSON.parse(bytes.toString("utf8"));
        const canonical = expectedCaptureMetadata().get(capture.id);
        const expectedPreference = capture.theme === "system-dark" ? "system" : capture.theme;
        if (copy.deployment !== canonical?.deployment || copy.surface !== canonical?.surface || copy.route !== canonical?.route || copy.viewport_width !== canonical?.width || !Number.isFinite(copy.page_width) || copy.page_width < 1 || copy.theme?.preference !== expectedPreference || copy.theme?.effective !== (capture.theme === "light" ? "light" : "dark")) {
          throw new Error(`copy metadata does not match ${capture.id}`);
        }
      }
    } catch (error) { errors.push(`Missing or changed artifact ${artifact.path}: ${error.message}`); }
  }
  return errors;
}

function comparePng(beforeBytes, afterBytes) {
  const pixelmatch = require(path.join(exampleRoot, "node_modules/pixelmatch"));
  const { PNG } = require(path.join(exampleRoot, "node_modules/pngjs"));
  const before = PNG.sync.read(beforeBytes);
  const after = PNG.sync.read(afterBytes);
  if (before.width !== after.width || before.height !== after.height) throw new Error("Image dimensions differ.");
  const diff = new PNG({ width: before.width, height: before.height });
  const pixels = pixelmatch(before.data, after.data, diff.data, before.width, before.height, { threshold: 0.1 });
  return { pixels, total: before.width * before.height, diff: PNG.sync.write(diff) };
}

function runWithTeardown(primary, teardown) {
  try { teardown(); }
  catch (cleanupError) {
    if (primary) {
      primary.cleanupError = cleanupError;
      throw primary;
    }
    throw new Error(`Owned disposable stack teardown failed: ${cleanupError.message}`, { cause: cleanupError });
  }
  if (primary) throw primary;
}

function compareDirectories(beforeDirectory, afterDirectory, outputDirectory, retained) {
  const beforeBytes = fs.readFileSync(path.join(beforeDirectory, "capture.json"));
  const afterBytes = fs.readFileSync(path.join(afterDirectory, "capture.json"));
  const before = JSON.parse(beforeBytes);
  const after = JSON.parse(afterBytes);
  const expected = { retained_project: retained.project, retained_port: retained.port, retained_volumes: retained.volumes, retained_container: retained.container };
  const errors = [...artifactErrors(before, beforeDirectory), ...artifactErrors(after, afterDirectory)];
  errors.push(...matrixErrors(before), ...matrixErrors(after));
  if (before.environment.browser_version !== after.environment.browser_version) errors.push("Before and candidate browser versions differ.");
  if (before.environment.platform !== after.environment.platform) errors.push("Before and candidate platforms differ.");
  if (before.environment.data_identity !== after.environment.data_identity) errors.push("Before and candidate data-state digests differ.");
  if (before.runtime.compose_project !== after.runtime.compose_project) errors.push("Before and candidate Compose projects differ.");
  if (before.runtime.volumes?.join("\n") !== after.runtime.volumes?.join("\n")) errors.push("Before and candidate owned volume identities differ.");
  if (before.runtime.host_ports?.join("\n") !== after.runtime.host_ports?.join("\n")) errors.push("Before and candidate loopback port identities differ.");
  if (after.runtime.main_inclusion?.included !== true || after.runtime.main_inclusion?.remote_current !== true) errors.push("Candidate does not include current remote main provenance.");
  if (after.source.source_sha !== run("git", ["rev-parse", "HEAD"]) || after.source.tree_sha256 !== sourceIdentity().tree_sha256) errors.push("Candidate source changed after its capture.");
  const beforeExpected = { source_sha: before.source.source_sha, tree_sha256: before.source.tree_sha256, ...expected };
  const afterExpected = { source_sha: after.source.source_sha, tree_sha256: after.source.tree_sha256, ...expected };
  errors.push(...disposableProvenanceErrors(before, beforeExpected), ...disposableProvenanceErrors(after, afterExpected));
  if (errors.length) throw new Error(`Cannot compare unverified disposable captures:\n${errors.join("\n")}`);

  const byId = new Map(after.captures.map((capture) => [capture.id, capture]));
  const comparisons = [];
  for (const left of before.captures) {
    const right = byId.get(left.id);
    for (const kind of ["viewport.png", "full.png", "hover.png", "focus.png", ...(left.files["navigation.png"] ? ["navigation.png"] : [])]) {
      if (Boolean(left.files[kind]) !== Boolean(right.files[kind])) throw new Error(`Before/candidate image pairing differs for ${left.id} (${kind}).`);
      const leftBytes = fs.readFileSync(path.join(beforeDirectory, left.files[kind].path));
      const rightBytes = fs.readFileSync(path.join(afterDirectory, right.files[kind].path));
      const { pixels, total, diff } = comparePng(leftBytes, rightBytes);
      const artifact = `${left.id}--${kind.replace(/\.png$/, "")}-diff.png`;
      fs.mkdirSync(outputDirectory, { recursive: true, mode: 0o700 });
      fs.writeFileSync(path.join(outputDirectory, artifact), diff, { mode: 0o600 });
      const beforeCopy = readJson(path.join(beforeDirectory, left.files["copy.json"].path));
      const afterCopy = readJson(path.join(afterDirectory, right.files["copy.json"].path));
      comparisons.push({ id: left.id, artifact: kind, diff: artifact, width: left.viewport.width, height: left.viewport.height, differing_pixels: pixels, total_pixels: total, ratio: pixels / total, copy_changed: beforeCopy.text !== afterCopy.text, copy_sha256_before: left.files["copy.json"].sha256, copy_sha256_after: right.files["copy.json"].sha256 });
    }
  }
  const report = { schema: "scrypath.ui-preservation-comparison.v1", status: "pending-review", before_source: before.source, after_source: after.source, environment: before.environment, comparisons, note: "Mechanical matched comparisons only; no aesthetic approval or automatic acceptance." };
  writeJson(path.join(outputDirectory, "comparison.json"), report);
  return report;
}

function verifyRetainedInventory() {
  const preview = readJson(previewPath);
  const project = preview.compose_project || preview.compose?.project || preview.project || "scrypath_ecommerce";
  const port = Number(new URL(preview.url).port || 80);
  const volumes = run("docker", ["volume", "ls", "--filter", `label=com.docker.compose.project=${project}`, "--format", "{{.Name}}"])
    .split("\n").filter(Boolean);
  return { project, port, volumes, container: preview.container || preview.container_name || "scrypath_ecommerce-web-1", checkout: preview.checkout, branch: preview.branch, url: preview.url };
}

function composeFiles(project, override, imageOverride) {
  return ["compose", "-p", project, "-f", path.join(exampleRoot, "compose.yaml"), "-f", path.join(exampleRoot, "compose.e2e.yaml"), "-f", path.join(exampleRoot, "compose.phase173.yaml"), "-f", imageOverride, "-f", override];
}

function openLoopbackPort() {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.once("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const port = server.address().port;
      server.close((error) => error ? reject(error) : resolve(port));
    });
  });
}

async function reservePorts() {
  const web = await openLoopbackPort();
  let standalone = await openLoopbackPort();
  while (standalone === web) standalone = await openLoopbackPort();
  return { web, standalone };
}

function dockerIdentity(project, service, env) {
  const compose = [...composeFiles(project, env.UI_PRESERVATION_COMPOSE, env.UI_PRESERVATION_IMAGE_OVERRIDE), "ps", "-q", service];
  const ids = run("docker", compose, { env, timeout: 30_000 }).split(/\s+/).filter(Boolean);
  if (ids.length !== 1) throw new Error(`Expected exactly one disposable ${service} container, found ${ids.length}.`);
  const container = JSON.parse(run("docker", ["inspect", "--format", "{{json .}}", ids[0]], { env }));
  const image = JSON.parse(run("docker", ["image", "inspect", "--format", "{{json .}}", container.Image], { env }));
  return { id: ids[0], container, image };
}

function teardownOwnedProject(project, sessionId, retained, compose, env, removeVolumes = true) {
  const containerIds = run("docker", ["ps", "-aq", "--filter", `label=com.docker.compose.project=${project}`]).split("\n").filter(Boolean);
  for (const id of containerIds) {
    const container = JSON.parse(run("docker", ["inspect", "--format", "{{json .}}", id], { env }));
    if (container.Config?.Labels?.[ownerLabel] !== sessionId) throw new Error(`Refusing teardown: container ${id} is not owned by this session.`);
  }
  const volumes = run("docker", ["volume", "ls", "--filter", `label=com.docker.compose.project=${project}`, "--format", "{{.Name}}"], { env }).split("\n").filter(Boolean);
  for (const volume of volumes) {
    const details = JSON.parse(run("docker", ["volume", "inspect", "--format", "{{json .}}", volume], { env }));
    if (details.Labels?.[ownerLabel] !== sessionId || retained.volumes.includes(volume)) throw new Error(`Refusing teardown: volume ${volume} is not exclusively owned by this session.`);
  }
  const args = [...compose, "down"];
  if (removeVolumes) args.push("--volumes");
  args.push("--remove-orphans");
  run("docker", args, { env, timeout: 60_000 });
}

function buildAndStart(project, sessionId, ports, retained, source, workDir, artifactDirectory) {
  if (project === retained.project || ports.web === retained.port || ports.standalone === retained.port) throw new Error("Refusing retained project or port for disposable stack.");
  const buildDir = path.join(workDir, "build");
  fs.mkdirSync(buildDir, { recursive: true, mode: 0o700 });
  const buildEnv = { ...gitEnvironment(process.env), E2E_PROJECT_NAME: project, E2E_SCOPE: "full", SCRYPATH_SOURCE_SHA: source.source_sha, E2E_SOURCE_FINGERPRINT: "" };
  const buildHelper = path.join(repositoryRoot, "scripts/ci/ecommerce_build.cjs");
  run("node", [buildHelper, "prepare", "--scope", "full", "--output", buildDir], { env: buildEnv, timeout: 120_000 });
  run("docker", ["buildx", "bake", "--file", path.join(buildDir, "bake.json")], { env: buildEnv, timeout: 1_200_000 });
  const handoff = path.join(buildDir, "image-handoff.json");
  run("node", [buildHelper, "verify-handoff", "--manifest", handoff], { env: { ...buildEnv, E2E_IMAGE_OVERRIDE: path.join(buildDir, "image-override.json") }, timeout: 120_000 });

  const postgresVolume = `${project}-postgres`;
  const meiliVolume = `${project}-meili`;
  const override = path.join(workDir, "compose.override.yaml");
  fs.writeFileSync(override, [
    "services:",
    "  postgres:",
    "    volumes: [postgres-data:/var/lib/postgresql/data]",
    `    labels: [\"${ownerLabel}=${sessionId}\"]`,
    "  meilisearch:",
    "    volumes: [meilisearch-data:/meili_data]",
    `    labels: [\"${ownerLabel}=${sessionId}\"]`,
    "  web:",
    `    ports: [\"127.0.0.1:${ports.web}:4002\"]`,
    `    labels: [\"${ownerLabel}=${sessionId}\"]`,
    "  standalone_ops:",
    `    ports: [\"127.0.0.1:${ports.standalone}:4003\"]`,
    `    labels: [\"${ownerLabel}=${sessionId}\"]`,
    "  browser:",
    "    entrypoint: [sleep]",
    "    command: [infinity]",
    `    volumes: [${JSON.stringify(`${artifactDirectory}:/artifacts`)}]`,
    `    labels: [\"${ownerLabel}=${sessionId}\"]`,
    "volumes:",
    `  postgres-data: {name: \"${postgresVolume}\", labels: [\"${ownerLabel}=${sessionId}\"]}`,
    `  meilisearch-data: {name: \"${meiliVolume}\", labels: [\"${ownerLabel}=${sessionId}\"]}`,
    "",
  ].join("\n"), { mode: 0o600 });
  const overridePath = path.join(buildDir, "image-override.json");
  const env = { ...buildEnv, E2E_IMAGE_OVERRIDE: overridePath, UI_PRESERVATION_COMPOSE: override, UI_PRESERVATION_IMAGE_OVERRIDE: overridePath };
  run("node", [buildHelper, "verify-handoff", "--manifest", handoff], { env, timeout: 120_000 });
  const compose = composeFiles(project, override, overridePath);
  try {
    run("docker", [...compose, "config", "--quiet"], { env, timeout: 30_000 });
    run("docker", [...compose, "up", "-d", "--no-build", "--pull", "never", "postgres", "meilisearch", "web", "standalone_ops", "browser"], { env, timeout: 1_200_000 });
    run("node", [buildHelper, "verify-handoff", "--manifest", handoff, "--runtime"], { env, timeout: 120_000 });
    const web = dockerIdentity(project, "web", env);
    const standalone = dockerIdentity(project, "standalone_ops", env);
    const browser = dockerIdentity(project, "browser", env);
    const images = [web, standalone, browser].map(({ image, container }, index) => {
    const service = ["web", "standalone_ops", "browser"][index];
    const labels = image.Config?.Labels || {};
    const containerLabels = container.Config?.Labels || {};
    return {
      service, id: image.Id, labels,
      source_sha: labels[revisionLabel], tree_sha256: source.tree_sha256,
      container_id: container.Id, container_name: String(container.Name || "").replace(/^\//, ""), container_source_sha: containerLabels[revisionLabel],
      container_tree_sha256: source.tree_sha256,
    };
    });
    for (const item of images) {
      if (item.labels[revisionLabel] !== source.source_sha || item.container_source_sha !== source.source_sha) throw new Error(`Disposable ${item.service} image/container label mismatch.`);
      if (item.labels[fingerprintLabel] && item.labels[fingerprintLabel] !== source.dirty_fingerprint) throw new Error(`Disposable ${item.service} source fingerprint mismatch.`);
    }
    const volumes = run("docker", ["volume", "ls", "--filter", `label=com.docker.compose.project=${project}`, "--format", "{{.Name}}"], { env }).split("\n").filter(Boolean);
    if (volumes.length < 2 || volumes.some((volume) => !volume.startsWith(`${project}-`))) throw new Error("Disposable Compose volumes are incomplete or not project-owned.");
    const inspect = JSON.parse(run("docker", ["inspect", "--format", "{{json .}}", web.id], { env }));
    const mounts = (inspect.Mounts || []).map(({ Type, Destination }) => ({ type: Type, destination: Destination }));
    if (mounts.some((mount) => mount.type === "bind" && mount.destination === "/app")) throw new Error("Disposable app container unexpectedly uses a source bind mount.");
    return { env, override, compose, handoff, images, volumes, mounts, artifactDirectory, runtimeImageIds: readJson(handoff).runtime_image_ids };
  } catch (error) {
    try { teardownOwnedProject(project, sessionId, retained, compose, env, true); }
    catch (cleanupError) { error.cleanupError = cleanupError; }
    throw error;
  }
}

async function waitForRoute(baseUrl, route) {
  const url = new URL(route, baseUrl);
  const response = await fetch(url, { signal: AbortSignal.timeout(10_000) });
  if (!response.ok) throw new Error(`Disposable route ${url} returned ${response.status}.`);
}

function captureInBrowser(stack, outputDirectory, dataIdentity) {
  const sourcePath = "/app/examples/scrypath_ecommerce/e2e/ui-review.mjs";
  const script = `import(${JSON.stringify(`file://${sourcePath}`)}).then(async (ui) => { console.log = (...args) => console.error(...args); const result = await ui.captureDisposableMatrix({ hostUrl: "http://web:4002", standaloneUrl: "http://standalone_ops:4003", output: "/artifacts", dataIdentity: ${JSON.stringify(dataIdentity)}, allowComposeNetwork: true }); process.stdout.write(JSON.stringify({ captures: result.captures, browserVersion: result.browserVersion, dataIdentity: result.dataIdentity, platform: process.platform + "-" + process.arch })); }).catch((error) => { console.error(error.stack || error.message); process.exitCode = 1; });`;
  const output = run("docker", [...stack.compose, "exec", "-T", "browser", "node", "--input-type=module", "-e", script], { env: stack.env, timeout: 1_200_000 });
  const result = JSON.parse(output);
  if (result.captures.length !== expectedCaptureIds().length) throw new Error(`Browser image captured ${result.captures.length} entries; expected ${expectedCaptureIds().length}.`);
  if (path.resolve(outputDirectory) !== path.resolve(stack.artifactDirectory)) throw new Error("Browser artifact mount does not match the host evidence directory.");
  return result;
}

function stackDataIdentity(stack) {
  const databaseNames = ["scrypath_ecommerce_test", "scrypath_ops_phase173_test"];
  const databases = Object.fromEntries(databaseNames.map((database) => {
    const dump = run("docker", [...stack.compose, "exec", "-T", "postgres", "pg_dump", "--no-owner", "--no-privileges", "--data-only", "--column-inserts", "-U", "postgres", database], { env: stack.env, timeout: 60_000 });
    return [database, sha256(normalizePgDump(dump))];
  }));
  const indexes = collectPages((offset, limit) => JSON.parse(run("docker", [...stack.compose, "exec", "-T", "meilisearch", "curl", "--silent", "--show-error", "--fail", `http://127.0.0.1:7700/indexes?limit=${limit}&offset=${offset}`], { env: stack.env, timeout: 30_000 })), { label: "index list", maxItems: MAX_INDEX_COUNT });
  const indexData = indexes.map(({ uid }) => {
    const base = `http://127.0.0.1:7700/indexes/${encodeURIComponent(uid)}`;
    const settings = JSON.parse(run("docker", [...stack.compose, "exec", "-T", "meilisearch", "curl", "--silent", "--show-error", "--fail", `${base}/settings`], { env: stack.env, timeout: 30_000 }));
    const docs = collectPages((offset, limit) => JSON.parse(run("docker", [...stack.compose, "exec", "-T", "meilisearch", "curl", "--silent", "--show-error", "--fail", `${base}/documents?limit=${limit}&offset=${offset}`], { env: stack.env, timeout: 30_000 })), { label: `documents for ${uid}`, maxItems: MAX_DOCUMENT_COUNT });
    docs.sort((left, right) => String(left.id ?? left._id ?? "").localeCompare(String(right.id ?? right._id ?? "")));
    return { uid, primaryKey: indexes.find((index) => index.uid === uid)?.primaryKey ?? null, settings, documents: docs };
  }).sort((left, right) => left.uid.localeCompare(right.uid));
  return stableDataIdentity({ databases, indexes: indexData });
}

async function captureBefore(sessionPath) {
  if (fs.existsSync(sessionPath)) throw new Error(`Refusing to overwrite an existing disposable session: ${sessionPath}`);
  ensureArtifactRoot();
  const source = sourceIdentity();
  const retained = verifyRetainedInventory();
  const sessionId = crypto.randomBytes(8).toString("hex");
  const project = `scrypath-p185-${sessionId}`;
  const ports = await reservePorts();
  const workDir = path.join(path.dirname(sessionPath), `build-${sessionId}`);
  fs.mkdirSync(workDir, { recursive: true, mode: 0o700 });
  const output = path.join(artifactRoot, `before-${source.source_sha.slice(0, 12)}-${sessionId}`);
  fs.mkdirSync(output, { recursive: false, mode: 0o700 });
  const stack = buildAndStart(project, sessionId, ports, retained, source, workDir, output);
  let primary = null;
  try {
    const hostUrl = `http://127.0.0.1:${ports.web}`;
    const standaloneUrl = `http://127.0.0.1:${ports.standalone}`;
    await waitForRoute(hostUrl, "/");
    await waitForRoute(hostUrl, "/admin/search/");
    await waitForRoute(standaloneUrl, "/ops/");
    const before = sourceIdentity(false);
    const sourceErrors = sourceChangeErrors(source, before);
    if (sourceErrors.length) throw new Error(sourceErrors.join("\n"));
    const dataIdentity = stackDataIdentity(stack);
    const captures = captureInBrowser(stack, output, dataIdentity);
    const afterCaptureSource = sourceIdentity(false);
    const captureSourceErrors = sourceChangeErrors(source, afterCaptureSource);
    if (captureSourceErrors.length) throw new Error(captureSourceErrors.join("\n"));
    const manifest = {
      schema: "scrypath.ui-disposable.v1", mode: "disposable", purpose: "historical-baseline",
      generated_at: new Date().toISOString(), session_id: sessionId,
      source: { ...source, tree_sha256: source.tree_sha256 },
      runtime: {
        compose_project: project, owned: true, isolated: true, source_match: true,
        retained_resources_disjoint: project !== retained.project && ![ports.web, ports.standalone].includes(retained.port) && !stack.volumes.some((volume) => retained.volumes.includes(volume)),
        host_ports: [`127.0.0.1:${ports.web}->4002/tcp`, `127.0.0.1:${ports.standalone}->4003/tcp`],
        volumes: stack.volumes, images: stack.images.map(({ service, id, labels }) => ({ service, id, labels, source_sha: source.source_sha, tree_sha256: source.tree_sha256 })),
        containers: stack.images.map(({ service, container_id, container_name, container_source_sha }) => ({ service, id: container_id, name: container_name, labels: { [revisionLabel]: container_source_sha }, source_sha: source.source_sha, tree_sha256: source.tree_sha256 })),
        mounts: stack.mounts, routes: { mounted: true, standalone: true },
        main_inclusion: { local_main_ref: source.main_ref, included: source.main_included, remote_main_ref: source.remote_main_ref, remote_current: source.remote_main_current },
        handoff: stack.handoff,
      },
      environment: { platform: captures.platform, browser_version: captures.browserVersion, data_identity: captures.dataIdentity },
      capture_directory: output, captures: captures.captures,
      capture_errors: [], status: "pending-review",
    };
    const errors = disposableProvenanceErrors(manifest, { source_sha: source.source_sha, tree_sha256: source.tree_sha256, retained_project: retained.project, retained_port: retained.port, retained_volumes: retained.volumes, retained_container: retained.container });
    errors.push(...artifactErrors(manifest, output));
    if (errors.length) throw new Error(`Disposable capture verification failed:\n${errors.join("\n")}`);
    const bytes = Buffer.from(`${JSON.stringify(manifest, null, 2)}\n`);
    manifest.capture_sha256 = sha256(bytes);
    writeJson(path.join(output, "capture.json"), manifest);
    const session = { schema: "scrypath.ui-session.v1", status: "before-captured", session_id: sessionId, source, retained_inventory: retained, project, ports, compose_files: stack.compose, compose_override: stack.override, build_dir: workDir, handoff: stack.handoff, volume_names: stack.volumes, before: path.join(output, "capture.json"), data_identity: captures.dataIdentity, browser_version: captures.browserVersion, platform: `${process.platform}-${process.arch}` };
    writeJson(sessionPath, session);
    console.log(JSON.stringify({ status: session.status, before: session.before, project, ports, source }, null, 2));
  } catch (error) { primary = error; }
  runWithTeardown(primary, () => {
    if (primary) teardownOwnedProject(project, sessionId, retained, stack.compose, stack.env, true);
  });
}

function captureManifestErrors(manifest, retained) {
  return [
    ...disposableProvenanceErrors(manifest, {
      source_sha: manifest.source.source_sha,
      tree_sha256: manifest.source.tree_sha256,
      retained_project: retained.project,
      retained_port: retained.port,
      retained_volumes: retained.volumes,
      retained_container: retained.container,
    }),
    ...artifactErrors(manifest, manifest.capture_directory),
  ];
}

async function captureAfter(sessionPath) {
  const session = readJson(sessionPath);
  if (session.schema !== "scrypath.ui-session.v1" || session.status !== "before-captured") throw new Error("Session is not ready for a candidate capture.");
  const retained = session.retained_inventory;
  const before = readJson(session.before);
  const beforeErrors = captureManifestErrors(before, retained);
  if (beforeErrors.length) throw new Error(`Frozen before evidence is invalid:\n${beforeErrors.join("\n")}`);
  const source = sourceIdentity();
  if (!source.main_included || !source.remote_main_current) throw new Error("Candidate source does not include current remote main; refresh and reconcile this worktree before candidate capture.");
  const project = session.project;
  const ports = session.ports;
  if (project === retained.project || ports.web === retained.port || ports.standalone === retained.port) throw new Error("Session targets a retained project or port.");
  const workDir = path.join(path.dirname(sessionPath), `candidate-${session.session_id}`);
  fs.mkdirSync(workDir, { recursive: true, mode: 0o700 });
  const output = path.join(artifactRoot, `after-${source.source_sha.slice(0, 12)}-${session.session_id}`);
  fs.mkdirSync(output, { recursive: false, mode: 0o700 });
  const stack = buildAndStart(project, session.session_id, ports, retained, source, workDir, output);
  let primary = null;
  try {
    const dataIdentity = stackDataIdentity(stack);
    if (dataIdentity !== session.data_identity) throw new Error("Candidate startup changed the frozen database/search state digest.");
    const hostUrl = `http://127.0.0.1:${ports.web}`;
    const standaloneUrl = `http://127.0.0.1:${ports.standalone}`;
    await waitForRoute(hostUrl, "/admin/search/");
    await waitForRoute(standaloneUrl, "/ops/");
    const afterStartupSource = sourceIdentity(false);
    const sourceErrors = sourceChangeErrors(source, afterStartupSource);
    if (sourceErrors.length) throw new Error(sourceErrors.join("\n"));
    const captures = captureInBrowser(stack, output, dataIdentity);
    const afterCaptureSource = sourceIdentity(false);
    const captureSourceErrors = sourceChangeErrors(source, afterCaptureSource);
    if (captureSourceErrors.length) throw new Error(captureSourceErrors.join("\n"));
    const manifest = {
      schema: "scrypath.ui-disposable.v1", mode: "disposable", purpose: "candidate",
      generated_at: new Date().toISOString(), session_id: session.session_id,
      source,
      runtime: {
        compose_project: project, owned: true, isolated: true, source_match: true,
        retained_resources_disjoint: project !== retained.project && ![ports.web, ports.standalone].includes(retained.port) && !stack.volumes.some((volume) => retained.volumes.includes(volume)),
        host_ports: [`127.0.0.1:${ports.web}->4002/tcp`, `127.0.0.1:${ports.standalone}->4003/tcp`],
        volumes: stack.volumes, images: stack.images.map(({ service, id, labels }) => ({ service, id, labels, source_sha: source.source_sha, tree_sha256: source.tree_sha256 })),
        containers: stack.images.map(({ service, container_id, container_name, container_source_sha }) => ({ service, id: container_id, name: container_name, labels: { [revisionLabel]: container_source_sha }, source_sha: source.source_sha, tree_sha256: source.tree_sha256 })),
        mounts: stack.mounts, routes: { mounted: true, standalone: true },
        main_inclusion: { local_main_ref: source.main_ref, included: source.main_included, remote_main_ref: source.remote_main_ref, remote_current: source.remote_main_current },
        handoff: stack.handoff,
      },
      environment: { platform: captures.platform, browser_version: captures.browserVersion, data_identity: captures.dataIdentity },
      capture_directory: output, captures: captures.captures,
      capture_errors: [], status: "pending-review",
    };
    const errors = captureManifestErrors(manifest, retained);
    if (errors.length) throw new Error(`Candidate capture verification failed:\n${errors.join("\n")}`);
    const bytes = Buffer.from(`${JSON.stringify(manifest, null, 2)}\n`);
    manifest.capture_sha256 = sha256(bytes);
    writeJson(path.join(output, "capture.json"), manifest);
    session.status = "candidate-captured";
    session.candidate = path.join(output, "capture.json");
    session.candidate_source = source;
    session.candidate_data_identity = dataIdentity;
    session.candidate_build_dir = workDir;
    session.candidate_compose_files = stack.compose;
    session.candidate_compose_override = stack.override;
    session.candidate_handoff = stack.handoff;
    session.candidate_volume_names = stack.volumes;
    writeJson(sessionPath, session);
    console.log(JSON.stringify({ status: session.status, candidate: session.candidate, project, ports, source }, null, 2));
  } catch (error) { primary = error; }
  runWithTeardown(primary, () => {});
}

function teardownSession(sessionPath) {
  const session = readJson(sessionPath);
  if (session.schema !== "scrypath.ui-session.v1" || !/^scrypath-p185-[a-z0-9][a-z0-9-]{7,31}$/.test(session.project)) throw new Error("Refusing teardown for an unowned session.");
  if (session.project === session.retained_inventory.project || Object.values(session.ports).includes(session.retained_inventory.port)) throw new Error("Refusing teardown of a retained project or port.");
  const useCandidate = ["candidate-captured", "compared-pending-review"].includes(session.status);
  const override = useCandidate ? session.candidate_compose_override : session.compose_override;
  const buildDir = useCandidate ? session.candidate_build_dir : session.build_dir;
  const imageOverride = path.join(buildDir, "build", "image-override.json");
  const compose = composeFiles(session.project, override, imageOverride);
  const env = { ...process.env, E2E_PROJECT_NAME: session.project, E2E_SCOPE: "full", E2E_IMAGE_OVERRIDE: imageOverride };
  teardownOwnedProject(session.project, session.session_id, session.retained_inventory, compose, env, true);
  session.status = "torn-down";
  writeJson(sessionPath, session);
}

function compareSession(sessionPath) {
  const session = readJson(sessionPath);
  if (session.schema !== "scrypath.ui-session.v1" || session.status !== "candidate-captured" || !session.candidate) throw new Error("Session has no verified before/candidate pair.");
  const beforeDirectory = path.dirname(session.before);
  const afterDirectory = path.dirname(session.candidate);
  const output = path.join(artifactRoot, `comparison-${session.session_id}`);
  const report = compareDirectories(beforeDirectory, afterDirectory, output, session.retained_inventory);
  session.status = "compared-pending-review";
  session.comparison = path.join(output, "comparison.json");
  writeJson(sessionPath, session);
  console.log(JSON.stringify({ status: session.status, comparison: session.comparison, captures_compared: report.comparisons.length }, null, 2));
}

function usage() {
  return "Usage: node scripts/ci/ui_preservation.cjs capture-before --session /private/tmp/scrypath-phase185-execution/ui-session.json | capture-after --session FILE | compare --session FILE | teardown --session FILE";
}

async function main(argv) {
  const [command, ...args] = argv;
  if (!new Set(["capture-before", "capture-after", "compare", "teardown"]).has(command)) throw new Error(usage());
  if (args.length !== 2 || args[0] !== "--session" || !path.isAbsolute(args[1])) throw new Error("--session must be followed by an explicit absolute path.\n" + usage());
  if (path.resolve(args[1]) !== "/private/tmp/scrypath-phase185-execution/ui-session.json") throw new Error("Plan 185 session must use /private/tmp/scrypath-phase185-execution/ui-session.json.");
  if (command === "capture-before") return captureBefore(args[1]);
  if (command === "capture-after") return captureAfter(args[1]);
  if (command === "compare") return compareSession(args[1]);
  if (command === "teardown") return teardownSession(args[1]);
}

if (require.main === module) main(process.argv.slice(2)).catch((error) => {
  console.error(error.message);
  if (error.cleanupError) console.error(`Cleanup also failed: ${error.cleanupError.message}`);
  process.exitCode = 1;
});

module.exports = {
  artifactRoot,
  artifactErrors,
  collectPages,
  comparePng,
  disposableProvenanceErrors,
  expectedCaptureIds,
  gitEnvironment,
  indexResults,
  isCanonicalOrigin,
  matrixErrors,
  normalizePgDump,
  runWithTeardown,
  sourceChangeErrors,
  stableDataIdentity,
  sourceIdentity,
};
