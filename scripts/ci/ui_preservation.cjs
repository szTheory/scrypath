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
const buildxConfigRoot = path.join(sessionRoot, "docker-buildx");
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
  "saved-searches": "/ops/search?saved=manage", help: "/ops/help",
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

function dockerEnvironment(environment = process.env) {
  return { ...environment, BUILDX_CONFIG: buildxConfigRoot };
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

function localPathForDockerHostMount(source) {
  return String(source).replace(/^\/host_mnt(?=\/)/, "");
}

function run(command, args, options = {}) {
  const outputEncoding = options.encoding === "buffer" ? null : (options.encoding || "utf8");
  const result = spawnSync(command, args, {
    cwd: options.cwd || repositoryRoot,
    env: command === "git" ? gitEnvironment(options.env || process.env) : command === "docker" ? dockerEnvironment(options.env || process.env) : (options.env || process.env),
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
  const temporary = `${file}.${process.pid}.${crypto.randomBytes(6).toString("hex")}.tmp`;
  fs.writeFileSync(temporary, jsonBytes(value), { flag: "wx", mode: 0o600 });
  fs.renameSync(temporary, file);
}

function jsonBytes(value) {
  return Buffer.from(`${JSON.stringify(value, null, 2)}\n`);
}

function readJsonBytes(file, maxBytes = 64 * 1024 * 1024) {
  const details = fs.lstatSync(file);
  if (details.isSymbolicLink() || !details.isFile() || details.size <= 0 || details.size > maxBytes) throw new Error(`Refusing unbounded or non-regular JSON input: ${file}`);
  return fs.readFileSync(file);
}

function readJson(file) {
  return JSON.parse(readJsonBytes(file).toString("utf8"));
}

function authorityPathFor(sessionPath) {
  return path.join(path.dirname(path.resolve(sessionPath)), "ui-session.authority.json");
}

function resourcePlanFor(sessionPath, sessionId, project, ports) {
  const root = path.dirname(path.resolve(sessionPath));
  const buildDir = path.join(root, `build-${sessionId}`);
  const candidateDir = path.join(root, `candidate-${sessionId}`);
  const buildPaths = (directory) => ({
    build_dir: directory,
    bake: path.join(directory, "build", "bake.json"),
    handoff: path.join(directory, "build", "image-handoff.json"),
    image_override: path.join(directory, "build", "image-override.json"),
    ownership_override: path.join(directory, "compose.override.yaml"),
    resume_override: path.join(directory, "compose.resume.override.yaml"),
  });
  return {
    project,
    ports,
    volumes: [`${project}-postgres`, `${project}-meili`],
    volume_keys: { [`${project}-postgres`]: "postgres-data", [`${project}-meili`]: "meilisearch-data" },
    work_dirs: { before: buildDir, candidate: candidateDir },
    compose_paths: { before: buildPaths(buildDir), candidate: buildPaths(candidateDir) },
    artifact_root: path.resolve(artifactRoot),
    services: ["postgres", "meilisearch", "web", "standalone_ops", "browser"],
    container_names: Object.fromEntries(["postgres", "meilisearch", "web", "standalone_ops", "browser"].map((service) => [service, `${project}-${service}-1`])),
    network_name: `${project}_default`,
    source_bind_mounts: composeSourceBindMounts(),
    compose_base_files: [
      path.join(exampleRoot, "compose.yaml"),
      path.join(exampleRoot, "compose.e2e.yaml"),
      path.join(exampleRoot, "compose.phase173.yaml"),
    ],
  };
}

function composeSourceBindMounts() {
  const source = path.join(exampleRoot, "scripts/phase173-create-database.sh");
  const info = fs.lstatSync(source);
  if (!info.isFile() || info.isSymbolicLink()) throw new Error("The Phase 173 PostgreSQL bootstrap must be a regular source file.");
  return [{
    service: "postgres",
    source: path.resolve(source),
    source_sha256: sha256(fs.readFileSync(source)),
    destination: "/docker-entrypoint-initdb.d/10-phase173-create-database.sh",
    read_only: true,
  }];
}

function isAuthorizedOwnedBindMount(authority, service, mount) {
  const mountedSource = path.resolve(localPathForDockerHostMount(mount.Source || ""));
  const expected = authority.resources.source_bind_mounts || composeSourceBindMounts();
  const sourceMount = expected.find((entry) => entry.service === service && entry.destination === mount.Destination && path.resolve(entry.source) === mountedSource);
  if (sourceMount && mount.RW === !sourceMount.read_only) {
    if (sourceMount.source_sha256) {
      const info = fs.lstatSync(sourceMount.source);
      if (!info.isFile() || info.isSymbolicLink() || sha256(fs.readFileSync(sourceMount.source)) !== sourceMount.source_sha256) return false;
    }
    return true;
  }
  return service === "browser" && mount.Destination === "/artifacts" && mount.RW === true
    && Object.values(authority.artifact_directories || {}).includes(mountedSource);
}

function containerIdForService(containers, service) {
  const matches = containers.filter((entry) => entry.service === service && typeof entry.id === "string" && entry.id.length > 0);
  if (matches.length !== 1) throw new Error(`Expected exactly one inspected ${service} container, found ${matches.length}.`);
  return matches[0].id;
}

function sameDockerIdSet(actual, expected) {
  return canonicalJson([...actual].sort()) === canonicalJson([...expected].sort());
}

function createSessionAuthority(sessionPath, session) {
  if (!path.isAbsolute(sessionPath) || session.schema !== "scrypath.ui-session.v2" || !/^[a-f0-9]{16}$/.test(session.session_id || "") || session.project !== `scrypath-p185-${session.session_id}`) {
    throw new Error("Cannot create an ownership authority for an invalid phase185 session.");
  }
  const resources = resourcePlanFor(sessionPath, session.session_id, session.project, session.ports);
  return {
    schema: "scrypath.ui-session-authority.v1",
    session_path: path.resolve(sessionPath),
    session_sha256: sha256(jsonBytes(session)),
    session_id: session.session_id,
    status: session.status,
    source: session.source,
    retained_inventory: session.retained_inventory,
    retained_inventory_sha256: sha256(Buffer.from(canonicalJson(session.retained_inventory))),
    resources,
    artifact_directories: {},
    capture_environment: {},
    candidate_source: null,
    manifests: { before: null, candidate: null },
  };
}

function validateSessionAuthority(session, authority, sessionPath, rawSessionBytes) {
  const errors = [];
  const resolvedPath = path.resolve(sessionPath);
  if (authority?.schema !== "scrypath.ui-session-authority.v1") errors.push("Independent session ownership authority is missing or unsupported.");
  if (authority?.session_path !== resolvedPath || authority?.session_sha256 !== sha256(rawSessionBytes)) errors.push("Editable session bytes do not match the independent creation authority.");
  if (session?.schema !== "scrypath.ui-session.v2") errors.push("Unsupported or forged disposable session schema.");
  if (!/^[a-f0-9]{16}$/.test(session?.session_id || "") || session?.session_id !== authority?.session_id) errors.push("Session identifier does not match its independent creation authority.");
  if (session?.project !== `scrypath-p185-${authority?.session_id}` || session?.project !== authority?.resources?.project) errors.push("Session project does not match its independently allocated project.");
  if (session?.status !== authority?.status) errors.push("Session status does not match its independent creation authority.");
  if (canonicalJson(session?.ports) !== canonicalJson(authority?.resources?.ports)) errors.push("Session ports do not match their independent allocation.");
  if (canonicalJson(session?.source) !== canonicalJson(authority?.source)) errors.push("Session source identity does not match its independent creation authority.");
  if (canonicalJson(session?.retained_inventory) !== canonicalJson(authority?.retained_inventory) || authority?.retained_inventory_sha256 !== sha256(Buffer.from(canonicalJson(authority?.retained_inventory)))) errors.push("Session retained-preview inventory does not match the independent read-only inventory.");
  const expectedPlan = resourcePlanFor(sessionPath, authority?.session_id, authority?.resources?.project, authority?.resources?.ports);
  if (!Object.hasOwn(authority?.resources || {}, "source_bind_mounts")) delete expectedPlan.source_bind_mounts;
  if (canonicalJson(authority?.resources) !== canonicalJson(expectedPlan)) errors.push("Independent resource authority has unexpected Compose paths, volumes, services, or artifact roots.");
  if (session?.build_dir !== expectedPlan.work_dirs.before) errors.push("Session build directory is outside its independent allowlist.");
  if (session?.candidate_build_dir && session.candidate_build_dir !== expectedPlan.work_dirs.candidate) errors.push("Candidate build directory is outside its independent allowlist.");
  for (const role of ["before", "candidate"]) {
    const pinnedSource = role === "before" ? authority?.source : authority?.candidate_source;
    const prefix = role === "before" ? "before" : "after";
    if (pinnedSource) {
      const expectedDirectory = path.join(expectedPlan.artifact_root, `${prefix}-${pinnedSource.source_sha.slice(0, 12)}-${authority.session_id}`);
      const required = role === "candidate" || session?.status !== "starting";
      if ((required && authority?.artifact_directories?.[role] !== expectedDirectory) || (authority?.artifact_directories?.[role] && authority.artifact_directories[role] !== expectedDirectory)) errors.push(`Session ${role} artifact directory is outside its source/session-bound evidence path.`);
    } else if (authority?.artifact_directories?.[role]) errors.push(`Session ${role} artifact directory has no independent source pin.`);
    const sessionPathValue = session?.[role];
    const record = authority?.manifests?.[role];
    if (sessionPathValue && (!record || path.resolve(sessionPathValue) !== record.manifest_path)) errors.push(`Session ${role} manifest path is not independently authorized.`);
    if (record) {
      const expectedDirectory = authority?.artifact_directories?.[role];
      if (record.directory !== expectedDirectory || record.manifest_path !== path.join(expectedDirectory, "capture.json") || record.directory !== path.dirname(record.manifest_path)) errors.push(`Authorized ${role} manifest directory is outside its source/session-bound evidence path.`);
    }
  }
  if (session?.candidate_source && canonicalJson(session.candidate_source) !== canonicalJson(authority?.manifests?.candidate?.source)) errors.push("Candidate source identity is not bound to the independent manifest authority.");
  if (session?.candidate_data_identity && session.candidate_data_identity !== authority?.manifests?.candidate?.data_identity) errors.push("Candidate data identity is not bound to the independent manifest authority.");
  if (session?.data_identity && session.data_identity !== authority?.manifests?.before?.data_identity) errors.push("Frozen data identity is not bound to the independent manifest authority.");
  return errors;
}

function loadAuthorizedSession(sessionPath) {
  const rawSessionBytes = readJsonBytes(sessionPath, 4 * 1024 * 1024);
  const rawAuthorityBytes = readJsonBytes(authorityPathFor(sessionPath), 4 * 1024 * 1024);
  const session = JSON.parse(rawSessionBytes.toString("utf8"));
  const authority = JSON.parse(rawAuthorityBytes.toString("utf8"));
  const errors = validateSessionAuthority(session, authority, sessionPath, rawSessionBytes);
  if (errors.length) throw new Error(`Refusing unverified disposable session:\n${errors.join("\n")}`);
  return { session, authority };
}

function persistAuthorizedSession(sessionPath, session, authority) {
  const bytes = jsonBytes(session);
  const temporary = `${sessionPath}.${process.pid}.${crypto.randomBytes(6).toString("hex")}.tmp`;
  fs.writeFileSync(temporary, bytes, { flag: "wx", mode: 0o600 });
  fs.renameSync(temporary, sessionPath);
  authority.session_sha256 = sha256(bytes);
  authority.status = session.status;
  writeJson(authorityPathFor(sessionPath), authority);
}

function manifestDigest(manifest) {
  // SHA-256 over pretty JSON plus a newline after excluding only `capture_sha256`.
  const unsigned = { ...manifest };
  delete unsigned.capture_sha256;
  return sha256(jsonBytes(unsigned));
}

function recordManifestAuthority(authority, role, manifestPath, manifest, rawBytes) {
  if (!new Set(["before", "candidate"]).has(role)) throw new Error(`Unknown evidence role: ${role}`);
  const independentSource = role === "before" ? authority.source : authority.candidate_source;
  const independentEnvironment = authority.capture_environment?.[role];
  if (!independentSource || !independentEnvironment || canonicalJson(manifest.source) !== canonicalJson(independentSource) || canonicalJson(manifest.environment) !== canonicalJson(independentEnvironment)) {
    throw new Error(`Refusing ${role} manifest without independently captured source and browser/environment facts.`);
  }
  authority.manifests[role] = {
    manifest_path: path.resolve(manifestPath),
    directory: path.dirname(path.resolve(manifestPath)),
    raw_sha256: sha256(rawBytes),
    capture_sha256: manifest.capture_sha256,
    source: independentSource,
    environment: independentEnvironment,
    data_identity: independentEnvironment.data_identity,
    runtime: manifest.runtime,
    runtime_sha256: sha256(Buffer.from(canonicalJson(manifest.runtime))),
  };
}

function manifestAuthorityErrors(manifest, rawBytes, authority, role, manifestPath, treeIdentity = commitTreeIdentity) {
  const errors = [];
  const record = authority?.manifests?.[role];
  if (!record) return [`No independent ${role} manifest authority exists.`];
  if (path.resolve(manifestPath) !== record.manifest_path || path.resolve(manifest.capture_directory || "") !== record.directory) errors.push(`${role} manifest or artifact directory differs from the independent creation record.`);
  if (manifest.session_id !== authority.session_id || manifest.runtime?.compose_project !== authority.resources?.project) errors.push(`${role} session or project identity differs from the independent resource authority.`);
  const expectedPorts = [`127.0.0.1:${authority.resources.ports.web}->4002/tcp`, `127.0.0.1:${authority.resources.ports.standalone}->4003/tcp`];
  if (canonicalJson([...(manifest.runtime?.host_ports || [])].sort()) !== canonicalJson(expectedPorts.sort())) errors.push(`${role} host ports differ from the independent allocation record.`);
  if (canonicalJson([...(manifest.runtime?.volumes || [])].sort()) !== canonicalJson([...authority.resources.volumes].sort())) errors.push(`${role} volumes differ from the exact independent allocation record.`);
  if (sha256(rawBytes) !== record.raw_sha256) errors.push(`${role} raw manifest bytes differ from the independent creation record.`);
  if (manifest.capture_sha256 !== record.capture_sha256 || manifest.capture_sha256 !== manifestDigest(manifest)) errors.push(`${role} manifest checksum is invalid under the documented capture_sha256-excluded serialization.`);
  const independentlyPinnedSource = role === "before" ? authority.source : authority.candidate_source;
  if (canonicalJson(record.source) !== canonicalJson(independentlyPinnedSource) || canonicalJson(manifest.source) !== canonicalJson(independentlyPinnedSource)) errors.push(`${role} source identity differs from the independent creation record.`);
  if (canonicalJson(manifest.environment) !== canonicalJson(record.environment) || manifest.environment?.data_identity !== record.data_identity) errors.push(`${role} browser/platform/data identity differs from the independent creation record.`);
  if (sha256(Buffer.from(canonicalJson(manifest.runtime))) !== record.runtime_sha256) errors.push(`${role} runtime ownership facts differ from the independent creation record.`);
  try {
    const tree = treeIdentity(record.source.source_sha);
    if (tree.tree_oid !== record.source.tree_oid || tree.tree_sha256 !== record.source.tree_sha256) errors.push(`${role} committed source tree does not match the independent Git tree identity.`);
  } catch (error) { errors.push(`${role} committed source tree could not be independently recomputed: ${error.message}`); }
  return errors;
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

function commitTreeIdentity(sourceSha) {
  if (typeof sourceSha !== "string" || !/^[a-f0-9]{40}$/.test(sourceSha)) throw new Error("Committed source SHA must be a full Git object ID.");
  const tree_oid = git(["rev-parse", `${sourceSha}^{tree}`]);
  const tree = git(["ls-tree", "-r", "-z", "--full-tree", sourceSha], { encoding: "buffer", timeout: 60_000, maxBuffer: 128 * 1024 * 1024 });
  return { tree_oid, tree_sha256: sha256(tree) };
}

function ensureArtifactRoot() {
  fs.mkdirSync(artifactRoot, { recursive: true, mode: 0o700 });
  const info = fs.lstatSync(artifactRoot);
  if (info.isSymbolicLink() || !info.isDirectory() || fs.realpathSync(artifactRoot) !== path.resolve(artifactRoot)) {
    throw new Error(`Disposable evidence root is not a stable regular directory: ${artifactRoot}`);
  }
}

function removePreCaptureFiles(sessionPath, workDir, output) {
  for (const directory of [workDir, output]) {
    if (!directory.startsWith(`${sessionRoot}${path.sep}`)) throw new Error(`Refusing to remove a pre-capture path outside ${sessionRoot}.`);
    try {
      const info = fs.lstatSync(directory);
      if (info.isSymbolicLink() || !info.isDirectory() || fs.realpathSync(directory) !== path.resolve(directory)) throw new Error(`Refusing to remove non-regular generated directory ${directory}.`);
      fs.rmSync(directory, { recursive: true, force: false });
    } catch (error) { if (error.code !== "ENOENT") throw error; }
  }
  for (const file of [sessionPath, authorityPathFor(sessionPath)]) {
    try {
      const info = fs.lstatSync(file);
      if (info.isSymbolicLink() || !info.isFile()) throw new Error(`Refusing to remove non-regular generated file ${file}.`);
      fs.unlinkSync(file);
    } catch (error) { if (error.code !== "ENOENT") throw error; }
  }
}

function sourceChangeErrors(start, end) {
  const errors = [];
  if (!start?.source_sha || !start?.tree_oid || !start?.tree_sha256 || !end?.source_sha || !end?.tree_oid || !end?.tree_sha256) errors.push("Source identity is incomplete.");
  else if (start.source_sha !== end.source_sha || start.tree_oid !== end.tree_oid || start.tree_sha256 !== end.tree_sha256) errors.push("Source changed during capture.");
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
  if (manifest?.schema !== "scrypath.ui-disposable.v2") errors.push("Unsupported disposable manifest schema.");
  if (manifest?.mode !== "disposable") errors.push("Capture is not explicitly marked disposable.");
  if (!expected.source_sha || !expected.tree_sha256) errors.push("Independent expected source SHA and tree fingerprint are required.");
  if (!expected.retained_project || !Number.isInteger(expected.retained_port) || !Array.isArray(expected.retained_volumes)) errors.push("Retained project, port, and volume identities are required.");

  const project = manifest?.runtime?.compose_project;
  if (typeof project !== "string" || !/^scrypath-p185-[a-z0-9][a-z0-9-]{7,31}$/.test(project)) errors.push("Disposable Compose project is not in the unique phase185 namespace.");
  if (project && expected.retained_project && project === expected.retained_project) errors.push("Disposable capture reuses the retained project.");
  if (manifest?.runtime?.owned !== true || manifest?.runtime?.isolated !== true) errors.push("Disposable stack ownership or isolation is unverified.");
  if (manifest?.runtime?.source_match !== true) errors.push("Disposable image/container source provenance is unverified.");
  if (manifest?.source?.source_sha !== expected.source_sha || manifest?.source?.tree_oid !== expected.tree_oid || manifest?.source?.tree_sha256 !== expected.tree_sha256) errors.push("Disposable manifest source SHA or full Git tree identity does not match the independently pinned source.");

  const runtime = manifest?.runtime || {};
  for (const [kind, identities] of [["image", runtime.images], ["container", runtime.containers]]) {
    if (!Array.isArray(identities) || identities.length < 2) {
      errors.push(`Disposable ${kind} identities are incomplete.`);
      continue;
    }
    for (const identity of identities) {
      const sourceBuilt = kind === "image" || identity.source_built !== false;
      if (sourceBuilt && (identity.source_sha !== expected.source_sha || identity.tree_oid !== expected.tree_oid || identity.tree_sha256 !== expected.tree_sha256)) errors.push(`Disposable ${kind} source labels mismatch for ${identity.service || "unknown service"}.`);
      if (sourceBuilt && (!identity.id || !identity.labels || identity.labels[revisionLabel] !== expected.source_sha)) errors.push(`Disposable ${kind} is missing its independently checked source label.`);
      if (kind === "container" && (!identity.id || !identity.labels || !identity.labels["com.docker.compose.project"] || !identity.labels["com.docker.compose.service"] || !identity.labels[ownerLabel])) errors.push(`Disposable ${kind} ownership labels are incomplete for ${identity.service || "unknown service"}.`);
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
  if (typeof manifest?.environment?.browser_version !== "string" || !manifest.environment.browser_version || typeof manifest?.environment?.platform !== "string" || !manifest.environment.platform || !manifest?.environment?.data_identity) errors.push("Browser, platform, or deterministic data identity is missing.");
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

function compareDirectories(beforeDirectory, afterDirectory, outputDirectory, authority) {
  const beforeRecord = authority.manifests.before;
  const afterRecord = authority.manifests.candidate;
  if (path.resolve(beforeDirectory) !== beforeRecord.directory || path.resolve(afterDirectory) !== afterRecord.directory) throw new Error("Comparison directories differ from the independent session authority.");
  const beforeBytes = readJsonBytes(beforeRecord.manifest_path);
  const afterBytes = readJsonBytes(afterRecord.manifest_path);
  const before = JSON.parse(beforeBytes.toString("utf8"));
  const after = JSON.parse(afterBytes.toString("utf8"));
  const errors = [
    ...captureManifestErrors(before, beforeBytes, authority, "before"),
    ...captureManifestErrors(after, afterBytes, authority, "candidate"),
  ];
  if (before.environment.browser_version !== after.environment.browser_version) errors.push("Before and candidate browser versions differ.");
  if (before.environment.platform !== after.environment.platform) errors.push("Before and candidate platforms differ.");
  if (before.environment.data_identity !== after.environment.data_identity) errors.push("Before and candidate data-state digests differ.");
  if (before.runtime.compose_project !== after.runtime.compose_project) errors.push("Before and candidate Compose projects differ.");
  if (before.runtime.volumes?.join("\n") !== after.runtime.volumes?.join("\n")) errors.push("Before and candidate owned volume identities differ.");
  if (before.runtime.host_ports?.join("\n") !== after.runtime.host_ports?.join("\n")) errors.push("Before and candidate loopback port identities differ.");
  const currentSource = sourceIdentity();
  if (after.runtime.main_inclusion?.included !== true || after.runtime.main_inclusion?.remote_current !== true || !currentSource.main_included || !currentSource.remote_main_current) errors.push("Candidate does not include the independently checked current canonical remote main.");
  if (after.source.source_sha !== currentSource.source_sha || after.source.tree_oid !== currentSource.tree_oid || after.source.tree_sha256 !== currentSource.tree_sha256 || after.source.remote_main_ref !== currentSource.remote_main_ref) errors.push("Candidate source or remote-main provenance changed after its capture.");
  if (errors.length) throw new Error(`Cannot compare unverified disposable captures:\n${errors.join("\n")}`);

  if (fs.existsSync(outputDirectory)) throw new Error(`Refusing to overwrite existing comparison evidence: ${outputDirectory}`);
  fs.mkdirSync(outputDirectory, { recursive: false, mode: 0o700 });
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
  const previewBytes = readJsonBytes(previewPath, 1024 * 1024);
  const preview = JSON.parse(previewBytes.toString("utf8"));
  const project = preview.compose_project || preview.compose?.project || preview.project || "scrypath_ecommerce";
  const url = new URL(preview.url);
  if (url.protocol !== "http:" || !["127.0.0.1", "localhost", "[::1]"].includes(url.hostname)) throw new Error("Retained preview pointer does not identify a loopback HTTP endpoint.");
  const port = Number(url.port || 80);
  const containerName = preview.container || preview.container_name || "scrypath_ecommerce-web-1";
  const container = JSON.parse(run("docker", ["inspect", "--format", "{{json .}}", containerName], { timeout: 15_000, maxBuffer: 4 * 1024 * 1024 }));
  const labels = container.Config?.Labels || {};
  if (container.State?.Running !== true || labels["com.docker.compose.project"] !== project || labels["com.docker.compose.service"] !== "web") throw new Error("Retained preview container facts do not match UI-PREVIEW.json.");
  const bindings = container.NetworkSettings?.Ports?.["4002/tcp"] || [];
  const actualPorts = bindings.map(({ HostIp, HostPort }) => `${HostIp}:${HostPort}`).sort();
  if (!actualPorts.some((entry) => entry.endsWith(`:${port}`) && (entry.startsWith("127.0.0.1:") || entry.startsWith("::1:")))) throw new Error("Retained preview's actual Docker port does not match UI-PREVIEW.json.");
  const expectedCheckout = fs.realpathSync(preview.checkout);
  const appMount = (container.Mounts || []).find(({ Destination }) => Destination === "/app");
  if (!appMount || appMount.Type !== "bind" || fs.realpathSync(localPathForDockerHostMount(appMount.Source)) !== expectedCheckout) throw new Error("Retained preview's actual /app mount does not match UI-PREVIEW.json.");
  const volumes = run("docker", ["volume", "ls", "--filter", `label=com.docker.compose.project=${project}`, "--format", "{{.Name}}"])
    .split("\n").filter(Boolean);
  const volumeFacts = volumes.map((name) => {
    const volume = JSON.parse(run("docker", ["volume", "inspect", "--format", "{{json .}}", name], { timeout: 15_000, maxBuffer: 2 * 1024 * 1024 }));
    if (volume.Labels?.["com.docker.compose.project"] !== project) throw new Error(`Retained volume ${name} does not match its Compose project label.`);
    return { name, project: volume.Labels["com.docker.compose.project"], compose_volume: volume.Labels["com.docker.compose.volume"] || null };
  }).sort((left, right) => left.name.localeCompare(right.name));
  return {
    pointer_sha256: sha256(previewBytes), project, port, actual_ports: actualPorts, volumes: volumeFacts.map(({ name }) => name),
    volume_facts: volumeFacts, container: containerName, container_id: container.Id, checkout: expectedCheckout,
    mounted_checkout: fs.realpathSync(localPathForDockerHostMount(appMount.Source)), branch: preview.branch, url: preview.url,
  };
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

function dockerContainerIdentity(project, service, env) {
  const compose = [...composeFiles(project, env.UI_PRESERVATION_COMPOSE, env.UI_PRESERVATION_IMAGE_OVERRIDE), "ps", "-q", service];
  const ids = run("docker", compose, { env, timeout: 30_000 }).split(/\s+/).filter(Boolean);
  if (ids.length !== 1) throw new Error(`Expected exactly one disposable ${service} container, found ${ids.length}.`);
  const container = JSON.parse(run("docker", ["inspect", "--format", "{{json .}}", ids[0]], { env }));
  return { service, id: container.Id, name: String(container.Name || "").replace(/^\//, ""), labels: container.Config?.Labels || {} };
}

function candidateServerCommands() {
  return {
    web: ["sh", "-c", "set -eu; cd /app/examples/scrypath_ecommerce; for asset in /app/scrypath_ops/priv/static/assets/js/app.js /app/scrypath_ops/priv/static/assets/css/app.css /app/examples/scrypath_ecommerce/priv/static/assets/js/app.js /app/examples/scrypath_ecommerce/priv/static/assets/css/app.css; do test -s \"$asset\"; done; exec env SCRYPATH_E2E_NO_SANDBOX=1 mix phx.server"],
    standalone_ops: ["sh", "-c", "set -eu; cd /app/scrypath_ops; test -s priv/static/assets/css/app.css; test -s priv/static/assets/js/app.js; exec env PHX_SERVER=true SCRYPATH_OPS_PORT=4003 mix phx.server"],
  };
}

function existingStackContext(authority, role) {
  const paths = authority.resources.compose_paths[role];
  if (!paths || !new Set(["before", "candidate"]).has(role)) throw new Error(`No authorized Compose resources exist for ${role}.`);
  const env = {
    ...gitEnvironment(process.env),
    E2E_PROJECT_NAME: authority.resources.project,
    E2E_SCOPE: "full",
    E2E_IMAGE_OVERRIDE: paths.image_override,
    UI_PRESERVATION_COMPOSE: paths.ownership_override,
    UI_PRESERVATION_IMAGE_OVERRIDE: paths.image_override,
  };
  return { env, compose: composeFiles(authority.resources.project, paths.ownership_override, paths.image_override) };
}

function removeOwnedApplicationContainers(authority, role) {
  const record = authority.manifests[role];
  if (!record?.runtime?.containers) throw new Error(`No independently owned ${role} containers are recorded.`);
  const services = ["web", "standalone_ops", "browser"];
  const containers = record.runtime.containers.filter(({ service }) => services.includes(service));
  if (containers.length !== services.length || services.some((service) => containers.filter((entry) => entry.service === service).length !== 1)) throw new Error(`The ${role} app container inventory is incomplete or ambiguous.`);
  run("docker", ["rm", "--force", ...containers.map(({ id }) => id)], { timeout: 60_000, maxBuffer: 2 * 1024 * 1024 });
}

function assertAllocatedDockerResources(authority, preserveData) {
  const { project, volumes: expectedVolumes, volume_keys: volumeKeys, network_name: networkName, container_names: containerNames } = authority.resources;
  const sessionId = authority.session_id;
  const volumeNames = run("docker", ["volume", "ls", "--format", "{{.Name}}"], { timeout: 15_000, maxBuffer: 4 * 1024 * 1024 }).split("\n").filter(Boolean);
  const matchingVolumes = volumeNames.filter((name) => expectedVolumes.includes(name)).sort();
  if (preserveData ? canonicalJson(matchingVolumes) !== canonicalJson([...expectedVolumes].sort()) : matchingVolumes.length !== 0) throw new Error("Disposable volume names already exist outside the expected candidate transition.");
  for (const name of matchingVolumes) {
    const volume = JSON.parse(run("docker", ["volume", "inspect", "--format", "{{json .}}", name], { timeout: 15_000, maxBuffer: 2 * 1024 * 1024 }));
    if (volume.Labels?.["com.docker.compose.project"] !== project || volume.Labels?.[ownerLabel] !== sessionId || volume.Labels?.["com.docker.compose.volume"] !== volumeKeys[name]) throw new Error(`Disposable volume ${name} does not match the independently allocated project/session/name facts.`);
  }

  const networkNames = run("docker", ["network", "ls", "--format", "{{.Name}}"], { timeout: 15_000, maxBuffer: 4 * 1024 * 1024 }).split("\n").filter(Boolean);
  const hasNetwork = networkNames.includes(networkName);
  if (preserveData !== hasNetwork) throw new Error("Disposable Compose network does not match the expected baseline or candidate transition.");
  if (hasNetwork) {
    const network = JSON.parse(run("docker", ["network", "inspect", "--format", "{{json .}}", networkName], { timeout: 15_000, maxBuffer: 2 * 1024 * 1024 }));
    if (network.Labels?.["com.docker.compose.project"] !== project || network.Labels?.[ownerLabel] !== sessionId) throw new Error("Disposable Compose network is not independently owned by this session.");
  }

  const allowedExisting = preserveData ? new Set(["postgres", "meilisearch"]) : new Set();
  const recorded = new Map((authority.manifests.before?.runtime?.containers || []).map((container) => [container.service, container]));
  for (const service of authority.resources.services) {
    const name = containerNames[service];
    const ids = run("docker", ["ps", "-aq", "--no-trunc", "--filter", `name=^/${name}$`], { timeout: 15_000, maxBuffer: 2 * 1024 * 1024 }).split("\n").filter(Boolean);
    if (!allowedExisting.has(service)) {
      if (ids.length) throw new Error(`Disposable container name ${name} already exists before this service is authorized to run.`);
      continue;
    }
    if (ids.length !== 1) throw new Error(`Expected the single recorded ${service} container to survive candidate replacement.`);
    const container = JSON.parse(run("docker", ["inspect", "--format", "{{json .}}", ids[0]], { timeout: 15_000, maxBuffer: 4 * 1024 * 1024 }));
    const labels = container.Config?.Labels || {};
    if (!sameDockerIdSet(ids, [recorded.get(service)?.id || ""]) || container.Name?.replace(/^\//, "") !== name || labels["com.docker.compose.project"] !== project || labels["com.docker.compose.service"] !== service || labels[ownerLabel] !== sessionId) throw new Error(`Disposable ${service} container does not match its recorded owner and name.`);
  }
}

async function runCandidateTransition({ expectedDataIdentity, readBefore, replace, readAfter, teardown }) {
  const before = await readBefore();
  if (before !== expectedDataIdentity) throw new Error("Frozen before database/search state changed before the candidate transition.");
  let mutationStarted = false;
  let stack;
  let primary = null;
  try {
    stack = await replace(() => { mutationStarted = true; });
    const after = await readAfter(stack);
    if (after !== before) throw new Error("Candidate startup changed the frozen database/search state digest.");
  } catch (error) { primary = error; }
  runWithTeardown(primary, () => {
    if (primary && mutationStarted) teardown();
  });
  return { stack, dataIdentity: before };
}

function teardownOwnedProject(authority, removeVolumes = true) {
  const { project, ports, services, volumes: expectedVolumes, network_name: expectedNetwork } = authority.resources;
  const sessionId = authority.session_id;
  const retained = authority.retained_inventory;
  if (project !== `scrypath-p185-${sessionId}` || project === retained.project || !/^[a-f0-9]{16}$/.test(sessionId)) throw new Error("Refusing teardown without a matching independent project/session authority.");
  assertRetainedInventoryCurrent(authority);

  const containerIds = run("docker", ["ps", "-aq", "--no-trunc", "--filter", `label=com.docker.compose.project=${project}`], { timeout: 15_000, maxBuffer: 2 * 1024 * 1024 }).split("\n").filter(Boolean);
  const containers = containerIds.map((id) => JSON.parse(run("docker", ["inspect", "--format", "{{json .}}", id], { timeout: 15_000, maxBuffer: 4 * 1024 * 1024 })));
  for (const container of containers) {
    const labels = container.Config?.Labels || {};
    const service = labels["com.docker.compose.service"];
    const expectedName = authority.resources.container_names?.[service];
    if (container.Id === retained.container_id || container.Name?.replace(/^\//, "") === retained.container || labels["com.docker.compose.project"] !== project || labels[ownerLabel] !== sessionId || !services.includes(service) || container.Name?.replace(/^\//, "") !== expectedName) {
      throw new Error(`Refusing teardown: Docker container ${container.Id} is not an independently authorized ${project} resource.`);
    }
    for (const mount of container.Mounts || []) {
      if (mount.Type === "volume" && (retained.volumes.includes(mount.Name) || !expectedVolumes.includes(mount.Name))) throw new Error(`Refusing teardown: container ${container.Id} mounts a retained or unallocated volume ${mount.Name}.`);
      if (mount.Type === "bind") {
        if (!isAuthorizedOwnedBindMount(authority, service, mount)) throw new Error(`Refusing teardown: container ${container.Id} has an unallocated bind mount at ${mount.Destination}.`);
      }
      if (!["volume", "bind", "tmpfs"].includes(mount.Type)) throw new Error(`Refusing teardown: container ${container.Id} has unsupported mount type ${mount.Type}.`);
    }
    const expectedHostPort = service === "web" ? ports.web : service === "standalone_ops" ? ports.standalone : null;
    for (const group of Object.values(container.NetworkSettings?.Ports || {})) for (const binding of group || []) {
      const port = Number(binding.HostPort);
      const host = String(binding.HostIp || "");
      if (port === retained.port || !["127.0.0.1", "::1"].includes(host) || !expectedHostPort || host !== "127.0.0.1" || port !== expectedHostPort) throw new Error(`Refusing teardown: container ${container.Id} has a retained, non-loopback, or unallocated host port.`);
    }
    const attachedNetworks = Object.keys(container.NetworkSettings?.Networks || {});
    if (attachedNetworks.some((name) => name !== expectedNetwork)) throw new Error(`Refusing teardown: container ${container.Id} is attached to an unallocated network.`);
  }

  const volumes = run("docker", ["volume", "ls", "--filter", `label=com.docker.compose.project=${project}`, "--format", "{{.Name}}"], { timeout: 15_000, maxBuffer: 2 * 1024 * 1024 }).split("\n").filter(Boolean).sort();
  if (volumes.some((volume) => !expectedVolumes.includes(volume))) throw new Error("Refusing teardown: Docker returned a volume outside the exact allocation record.");
  for (const name of volumes) {
    const volume = JSON.parse(run("docker", ["volume", "inspect", "--format", "{{json .}}", name], { timeout: 15_000, maxBuffer: 2 * 1024 * 1024 }));
    if (retained.volumes.includes(name) || volume.Labels?.["com.docker.compose.project"] !== project || volume.Labels?.[ownerLabel] !== sessionId) throw new Error(`Refusing teardown: volume ${name} is not exclusively owned by this session.`);
  }

  const networkIds = run("docker", ["network", "ls", "-q", "--filter", `label=com.docker.compose.project=${project}`], { timeout: 15_000, maxBuffer: 2 * 1024 * 1024 }).split("\n").filter(Boolean);
  const networks = networkIds.map((id) => JSON.parse(run("docker", ["network", "inspect", "--format", "{{json .}}", id], { timeout: 15_000, maxBuffer: 2 * 1024 * 1024 })));
  const ownedContainerIds = new Set(containerIds);
  for (const network of networks) {
    if (network.Name !== expectedNetwork || network.Labels?.["com.docker.compose.project"] !== project || network.Labels?.[ownerLabel] !== sessionId) throw new Error(`Refusing teardown: network ${network.Id} is not exclusively owned by this session.`);
    const attached = Object.entries(network.Containers || {}).map(([id, { Name }]) => ({ name: Name, id }));
    if (attached.some(({ id }) => !ownedContainerIds.has(id))) throw new Error(`Refusing teardown: network ${network.Id} is connected to an unallocated container.`);
  }

  if (containerIds.length) run("docker", ["rm", "--force", ...containerIds], { timeout: 60_000, maxBuffer: 2 * 1024 * 1024 });
  if (networkIds.length) run("docker", ["network", "rm", ...networkIds], { timeout: 30_000, maxBuffer: 2 * 1024 * 1024 });
  if (removeVolumes && volumes.length) run("docker", ["volume", "rm", ...volumes], { timeout: 60_000, maxBuffer: 2 * 1024 * 1024 });
}

function assertRetainedInventoryCurrent(authority) {
  const actual = verifyRetainedInventory();
  if (canonicalJson(actual) !== canonicalJson(authority.retained_inventory)) throw new Error("Read-only retained-preview Docker facts changed since this disposable session was created.");
  return actual;
}

function assertOwnedRuntime(authority, role) {
  const record = authority.manifests[role];
  if (!record?.runtime) throw new Error(`No independently recorded ${role} Docker runtime facts exist.`);
  const project = authority.resources.project;
  const sessionId = authority.session_id;
  const ids = run("docker", ["ps", "-aq", "--no-trunc", "--filter", `label=com.docker.compose.project=${project}`], { timeout: 15_000, maxBuffer: 2 * 1024 * 1024 }).split("\n").filter(Boolean).sort();
  const expectedIds = record.runtime.containers.map(({ id }) => id).sort();
  if (!sameDockerIdSet(ids, expectedIds)) throw new Error(`${role} Compose container IDs differ from the independent Docker capture record.`);
  for (const id of ids) {
    const container = JSON.parse(run("docker", ["inspect", "--format", "{{json .}}", id], { timeout: 15_000, maxBuffer: 4 * 1024 * 1024 }));
    const labels = container.Config?.Labels || {};
    const expected = record.runtime.containers.find((entry) => entry.id === id);
    if (!expected || labels["com.docker.compose.project"] !== project || labels[ownerLabel] !== sessionId || labels["com.docker.compose.service"] !== expected.service || (expected.source_built && labels[revisionLabel] !== record.source.source_sha) || container.Name?.replace(/^\//, "") !== expected.name) {
      throw new Error(`Docker container ${id} no longer matches independently recorded ${role} ownership/source facts.`);
    }
  }
  const volumes = run("docker", ["volume", "ls", "--filter", `label=com.docker.compose.project=${project}`, "--format", "{{.Name}}"], { timeout: 15_000, maxBuffer: 2 * 1024 * 1024 }).split("\n").filter(Boolean).sort();
  if (canonicalJson(volumes) !== canonicalJson([...authority.resources.volumes].sort())) throw new Error(`${role} Docker volume identities differ from the independent allocation record.`);
  for (const name of volumes) {
    const volume = JSON.parse(run("docker", ["volume", "inspect", "--format", "{{json .}}", name], { timeout: 15_000, maxBuffer: 2 * 1024 * 1024 }));
    if (volume.Labels?.["com.docker.compose.project"] !== project || volume.Labels?.[ownerLabel] !== sessionId || authority.retained_inventory.volumes.includes(name)) throw new Error(`Docker volume ${name} is not independently owned by this disposable session.`);
  }
  const networkIds = run("docker", ["network", "ls", "-q", "--filter", `label=com.docker.compose.project=${project}`], { timeout: 15_000, maxBuffer: 2 * 1024 * 1024 }).split("\n").filter(Boolean);
  if (networkIds.length !== 1) throw new Error(`${role} Docker network inventory is not the single allocated Compose network.`);
  const network = JSON.parse(run("docker", ["network", "inspect", "--format", "{{json .}}", networkIds[0]], { timeout: 15_000, maxBuffer: 2 * 1024 * 1024 }));
  if (network.Name !== authority.resources.network_name || network.Labels?.["com.docker.compose.project"] !== project || network.Labels?.[ownerLabel] !== sessionId) throw new Error(`${role} Docker network ownership differs from the independent allocation record.`);
  const actualPorts = ids.flatMap((id) => {
    const container = JSON.parse(run("docker", ["inspect", "--format", "{{json .NetworkSettings.Ports}}", id], { timeout: 15_000, maxBuffer: 2 * 1024 * 1024 }));
    return Object.values(container || {}).flatMap((bindings) => (bindings || []).map(({ HostIp, HostPort }) => `${HostIp}:${HostPort}`));
  }).sort();
  const expectedPorts = [`127.0.0.1:${authority.resources.ports.web}`, `127.0.0.1:${authority.resources.ports.standalone}`].sort();
  if (canonicalJson(actualPorts) !== canonicalJson(expectedPorts)) throw new Error(`${role} Docker host bindings differ from the independent loopback allocation.`);
  return true;
}

function buildAndStart(project, sessionId, ports, retained, source, workDir, artifactDirectory, authority, options = {}) {
  if (project === retained.project || ports.web === retained.port || ports.standalone === retained.port) throw new Error("Refusing retained project or port for disposable stack.");
  const buildDir = path.join(workDir, "build");
  fs.mkdirSync(buildDir, { recursive: true, mode: 0o700 });
  const buildEnv = { ...gitEnvironment(process.env), E2E_PROJECT_NAME: project, E2E_SCOPE: "full", SCRYPATH_SOURCE_SHA: source.source_sha, E2E_SOURCE_FINGERPRINT: "" };
  const buildHelper = path.join(repositoryRoot, "scripts/ci/ecommerce_build.cjs");
  run("node", [buildHelper, "prepare", "--scope", "full", "--output", buildDir], { env: buildEnv, timeout: 120_000 });
  run("docker", ["buildx", "bake", "--file", path.join(buildDir, "bake.json")], { env: buildEnv, timeout: 1_800_000 });
  const handoff = path.join(buildDir, "image-handoff.json");
  run("node", [buildHelper, "verify-handoff", "--manifest", handoff], { env: { ...buildEnv, E2E_IMAGE_OVERRIDE: path.join(buildDir, "image-override.json") }, timeout: 120_000 });

  const postgresVolume = `${project}-postgres`;
  const meiliVolume = `${project}-meili`;
  const override = path.join(workDir, "compose.override.yaml");
  const candidateCommands = options.preserveData ? candidateServerCommands() : null;
  const webCommand = candidateCommands?.web || null;
  const standaloneCommand = candidateCommands?.standalone_ops || null;
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
    ...(webCommand ? [`    command: ${JSON.stringify(webCommand)}`] : []),
    `    labels: [\"${ownerLabel}=${sessionId}\"]`,
    "  standalone_ops:",
    `    ports: [\"127.0.0.1:${ports.standalone}:4003\"]`,
    ...(standaloneCommand ? [`    command: ${JSON.stringify(standaloneCommand)}`] : []),
    `    labels: [\"${ownerLabel}=${sessionId}\"]`,
    "  browser:",
    "    entrypoint: [sleep]",
    "    command: [infinity]",
    `    volumes: [${JSON.stringify(`${artifactDirectory}:/artifacts`)}]`,
    `    labels: [\"${ownerLabel}=${sessionId}\"]`,
    "volumes:",
    `  postgres-data: {name: \"${postgresVolume}\", labels: [\"${ownerLabel}=${sessionId}\"]}`,
    `  meilisearch-data: {name: \"${meiliVolume}\", labels: [\"${ownerLabel}=${sessionId}\"]}`,
    "networks:",
    `  default: {name: \"${project}_default\", labels: [\"${ownerLabel}=${sessionId}\"]}`,
    "",
  ].join("\n"), { mode: 0o600 });
  const overridePath = path.join(buildDir, "image-override.json");
  const env = { ...buildEnv, E2E_IMAGE_OVERRIDE: overridePath, UI_PRESERVATION_COMPOSE: override, UI_PRESERVATION_IMAGE_OVERRIDE: overridePath };
  run("node", [buildHelper, "verify-handoff", "--manifest", handoff], { env, timeout: 120_000 });
  const compose = composeFiles(project, override, overridePath);
  let mutationStarted = false;
  try {
    run("docker", [...compose, "config", "--quiet"], { env, timeout: 30_000 });
    assertRetainedInventoryCurrent(authority);
    if (options.beforeStart) options.beforeStart(() => { mutationStarted = true; });
    assertAllocatedDockerResources(authority, options.preserveData === true);
    if (!options.beforeStart) mutationStarted = true;
    const services = options.preserveData ? ["web", "standalone_ops", "browser"] : ["postgres", "meilisearch", "web", "standalone_ops", "browser"];
    const upArgs = [...compose, "up", "-d", ...(options.preserveData ? ["--no-deps"] : []), "--no-build", "--pull", "never", ...services];
    run("docker", upArgs, { env, timeout: 1_200_000 });
    run("node", [buildHelper, "verify-handoff", "--manifest", handoff, "--runtime"], { env, timeout: 120_000 });
    const sourceServices = ["web", "standalone_ops", "browser"];
    const sourceStacks = sourceServices.map((service) => dockerIdentity(project, service, env));
    const allContainers = ["postgres", "meilisearch", ...sourceServices].map((service) => dockerContainerIdentity(project, service, env));
    const images = sourceStacks.map(({ image, container }, index) => {
    const service = sourceServices[index];
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
    const volumes = run("docker", ["volume", "ls", "--filter", `label=com.docker.compose.project=${project}`, "--format", "{{.Name}}"], { env }).split("\n").filter(Boolean).sort();
    if (canonicalJson(volumes) !== canonicalJson([...authority.resources.volumes].sort())) throw new Error("Disposable Compose volumes do not match the exact independent allocation.");
    const webId = containerIdForService(allContainers, "web");
    const inspect = JSON.parse(run("docker", ["inspect", "--format", "{{json .}}", webId], { env }));
    const mounts = (inspect.Mounts || []).map(({ Type, Destination }) => ({ type: Type, destination: Destination }));
    if (mounts.some((mount) => mount.type === "bind" && mount.destination === "/app")) throw new Error("Disposable app container unexpectedly uses a source bind mount.");
    return { env, override, compose, handoff, images, containers: allContainers, volumes, mounts, artifactDirectory, runtimeImageIds: readJson(handoff).runtime_image_ids, sessionId };
  } catch (error) {
    if (options.cleanupOnFailure !== false && mutationStarted) {
      try { teardownOwnedProject(authority, true); }
      catch (cleanupError) { error.cleanupError = cleanupError; }
    }
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

function runtimeManifest(stack, source, project, ports, retained) {
  return {
    compose_project: project,
    owned: true,
    isolated: true,
    source_match: true,
    retained_resources_disjoint: project !== retained.project && ![ports.web, ports.standalone].includes(retained.port) && !stack.volumes.some((volume) => retained.volumes.includes(volume)),
    host_ports: [`127.0.0.1:${ports.web}->4002/tcp`, `127.0.0.1:${ports.standalone}->4003/tcp`],
    volumes: stack.volumes,
    images: stack.images.map(({ service, id, labels }) => ({ service, id, labels, source_sha: source.source_sha, tree_sha256: source.tree_sha256, tree_oid: source.tree_oid })),
    containers: stack.containers.map((container) => {
      const sourceBuilt = ["web", "standalone_ops", "browser"].includes(container.service);
      return {
        ...container,
        source_built: sourceBuilt,
        source_sha: sourceBuilt ? source.source_sha : null,
        tree_sha256: sourceBuilt ? source.tree_sha256 : null,
        tree_oid: sourceBuilt ? source.tree_oid : null,
      };
    }),
    mounts: stack.mounts,
    routes: { mounted: true, standalone: true },
    main_inclusion: { local_main_ref: source.main_ref, included: source.main_included, remote_main_ref: source.remote_main_ref, remote_current: source.remote_main_current },
    handoff: stack.handoff,
  };
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
  if (fs.existsSync(sessionPath) || fs.existsSync(authorityPathFor(sessionPath))) throw new Error(`Refusing to overwrite an existing disposable session or authority: ${sessionPath}`);
  ensureArtifactRoot();
  const source = sourceIdentity();
  const retained = verifyRetainedInventory();
  const sessionId = crypto.randomBytes(8).toString("hex");
  const project = `scrypath-p185-${sessionId}`;
  const ports = await reservePorts();
  const workDir = resourcePlanFor(sessionPath, sessionId, project, ports).work_dirs.before;
  const output = path.join(artifactRoot, `before-${source.source_sha.slice(0, 12)}-${sessionId}`);
  const session = { schema: "scrypath.ui-session.v2", status: "starting", session_id: sessionId, source, retained_inventory: retained, project, ports, build_dir: workDir };
  const authority = createSessionAuthority(sessionPath, session);
  authority.artifact_directories.before = output;
  writeJson(sessionPath, session);
  writeJson(authorityPathFor(sessionPath), authority);
  fs.mkdirSync(workDir, { recursive: true, mode: 0o700 });
  fs.mkdirSync(output, { recursive: false, mode: 0o700 });
  let stack;
  let startupAttempted = false;
  let primary = null;
  try {
    stack = buildAndStart(project, sessionId, ports, retained, source, workDir, output, authority, {
      cleanupOnFailure: false,
      beforeStart: (markStarted) => { startupAttempted = true; markStarted(); },
    });
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
      schema: "scrypath.ui-disposable.v2", mode: "disposable", purpose: "historical-baseline",
      generated_at: new Date().toISOString(), session_id: sessionId,
      source,
      runtime: runtimeManifest(stack, source, project, ports, retained),
      environment: { platform: captures.platform, browser_version: captures.browserVersion, data_identity: captures.dataIdentity },
      capture_directory: output, captures: captures.captures,
      capture_errors: [], status: "pending-review",
    };
    const errors = disposableProvenanceErrors(manifest, { source_sha: source.source_sha, tree_oid: source.tree_oid, tree_sha256: source.tree_sha256, retained_project: retained.project, retained_port: retained.port, retained_volumes: retained.volumes, retained_container: retained.container });
    errors.push(...artifactErrors(manifest, output));
    errors.push(...sourceChangeErrors(source, { ...source, ...commitTreeIdentity(source.source_sha) }));
    if (errors.length) throw new Error(`Disposable capture verification failed:\n${errors.join("\n")}`);
    manifest.capture_sha256 = manifestDigest(manifest);
    const bytes = jsonBytes(manifest);
    const manifestPath = path.join(output, "capture.json");
    fs.writeFileSync(manifestPath, bytes, { flag: "wx", mode: 0o600 });
    authority.capture_environment = { ...(authority.capture_environment || {}), before: manifest.environment };
    recordManifestAuthority(authority, "before", manifestPath, manifest, bytes);
    writeJson(authorityPathFor(sessionPath), authority);
    const validationErrors = captureManifestErrors(manifest, bytes, authority, "before");
    if (validationErrors.length) throw new Error(`Disposable capture verification failed:\n${validationErrors.join("\n")}`);
    session.status = "before-captured";
    session.before = manifestPath;
    session.data_identity = captures.dataIdentity;
    session.browser_version = captures.browserVersion;
    session.platform = captures.platform;
    persistAuthorizedSession(sessionPath, session, authority);
    console.log(JSON.stringify({ status: session.status, before: session.before, project, ports, source }, null, 2));
  } catch (error) { primary = error; }
  if (primary && !startupAttempted) {
    try { removePreCaptureFiles(sessionPath, workDir, output); }
    catch (cleanupError) { primary.fileCleanupError = cleanupError; }
  }
  try {
    runWithTeardown(primary, () => {
      if (primary && startupAttempted) teardownOwnedProject(authority, true);
    });
  } catch (error) {
    if (primary && startupAttempted) {
      session.status = "before-failed";
      try { persistAuthorizedSession(sessionPath, session, authority); }
      catch (sessionError) { primary.sessionError = sessionError; }
    }
    throw error;
  }
}

function captureManifestErrors(manifest, rawBytes, authority, role) {
  const record = authority?.manifests?.[role];
  if (!record) return [`No independent ${role} manifest authority exists.`];
  return [
    ...manifestAuthorityErrors(manifest, rawBytes, authority, role, record.manifest_path),
    ...disposableProvenanceErrors(manifest, {
      source_sha: record.source.source_sha,
      tree_oid: record.source.tree_oid,
      tree_sha256: record.source.tree_sha256,
      retained_project: authority.retained_inventory.project,
      retained_port: authority.retained_inventory.port,
      retained_volumes: authority.retained_inventory.volumes,
      retained_container: authority.retained_inventory.container,
    }),
    ...artifactErrors(manifest, record.directory),
  ];
}

async function captureAfter(sessionPath) {
  const { session, authority } = loadAuthorizedSession(sessionPath);
  if (session.status !== "before-captured") throw new Error("Session is not ready for a candidate capture.");
  const retained = assertRetainedInventoryCurrent(authority);
  const beforeRecord = authority.manifests.before;
  const beforeBytes = readJsonBytes(beforeRecord.manifest_path);
  const before = JSON.parse(beforeBytes.toString("utf8"));
  const beforeErrors = captureManifestErrors(before, beforeBytes, authority, "before");
  if (beforeErrors.length) throw new Error(`Frozen before evidence is invalid:\n${beforeErrors.join("\n")}`);
  assertOwnedRuntime(authority, "before");
  const source = sourceIdentity();
  if (!source.main_included || !source.remote_main_current) throw new Error("Candidate source does not include current remote main; refresh and reconcile this worktree before candidate capture.");
  authority.candidate_source = source;
  const project = authority.resources.project;
  const ports = authority.resources.ports;
  if (project === retained.project || ports.web === retained.port || ports.standalone === retained.port) throw new Error("Session targets a retained project or port.");
  const workDir = authority.resources.work_dirs.candidate;
  fs.mkdirSync(workDir, { recursive: true, mode: 0o700 });
  const output = path.join(artifactRoot, `after-${source.source_sha.slice(0, 12)}-${session.session_id}`);
  authority.artifact_directories.candidate = output;
  writeJson(authorityPathFor(sessionPath), authority);
  fs.mkdirSync(output, { recursive: false, mode: 0o700 });
  let startupAttempted = false;
  let transitionFailureHandled = false;
  let transitionCompleted = false;
  let stack;
  let primary = null;
  let transitionMutationStarted = false;
  try {
    const transition = await runCandidateTransition({
      expectedDataIdentity: session.data_identity,
      readBefore: () => stackDataIdentity(existingStackContext(authority, "before")),
      replace: (markMutationStarted) => buildAndStart(project, session.session_id, ports, retained, source, workDir, output, authority, {
        preserveData: true,
        cleanupOnFailure: false,
        beforeStart: (markStarted) => {
          assertOwnedRuntime(authority, "before");
          const current = stackDataIdentity(existingStackContext(authority, "before"));
          if (current !== session.data_identity) throw new Error("Frozen before database/search state changed while the candidate image was being built.");
          markStarted();
          transitionMutationStarted = true;
          startupAttempted = true;
          markMutationStarted();
          removeOwnedApplicationContainers(authority, "before");
        },
      }),
      readAfter: (candidateStack) => stackDataIdentity(candidateStack),
      teardown: () => teardownOwnedProject(authority, true),
    });
    startupAttempted = true;
    transitionCompleted = true;
    stack = transition.stack;
    const dataIdentity = transition.dataIdentity;
    const hostUrl = `http://127.0.0.1:${ports.web}`;
    const standaloneUrl = `http://127.0.0.1:${ports.standalone}`;
    await waitForRoute(hostUrl, "/admin/search/");
    await waitForRoute(standaloneUrl, "/ops/");
    const afterStartupSource = sourceIdentity(false);
    const sourceErrors = sourceChangeErrors(source, afterStartupSource);
    if (sourceErrors.length) throw new Error(sourceErrors.join("\n"));
    const captures = captureInBrowser(stack, output, dataIdentity);
    const afterBrowserDataIdentity = stackDataIdentity(stack);
    if (afterBrowserDataIdentity !== dataIdentity) throw new Error("Browser capture changed the frozen database/search state digest.");
    const afterCaptureSource = sourceIdentity(false);
    const captureSourceErrors = sourceChangeErrors(source, afterCaptureSource);
    if (captureSourceErrors.length) throw new Error(captureSourceErrors.join("\n"));
    const manifest = {
      schema: "scrypath.ui-disposable.v2", mode: "disposable", purpose: "candidate",
      generated_at: new Date().toISOString(), session_id: session.session_id,
      source,
      runtime: runtimeManifest(stack, source, project, ports, retained),
      environment: { platform: captures.platform, browser_version: captures.browserVersion, data_identity: captures.dataIdentity },
      capture_directory: output, captures: captures.captures,
      capture_errors: [], status: "pending-review",
    };
    const errors = disposableProvenanceErrors(manifest, { source_sha: source.source_sha, tree_oid: source.tree_oid, tree_sha256: source.tree_sha256, retained_project: retained.project, retained_port: retained.port, retained_volumes: retained.volumes, retained_container: retained.container });
    errors.push(...artifactErrors(manifest, output));
    if (errors.length) throw new Error(`Candidate capture verification failed:\n${errors.join("\n")}`);
    manifest.capture_sha256 = manifestDigest(manifest);
    const bytes = jsonBytes(manifest);
    const manifestPath = path.join(output, "capture.json");
    fs.writeFileSync(manifestPath, bytes, { flag: "wx", mode: 0o600 });
    authority.capture_environment = { ...(authority.capture_environment || {}), candidate: manifest.environment };
    recordManifestAuthority(authority, "candidate", manifestPath, manifest, bytes);
    writeJson(authorityPathFor(sessionPath), authority);
    const validationErrors = captureManifestErrors(manifest, bytes, authority, "candidate");
    if (validationErrors.length) throw new Error(`Candidate capture verification failed:\n${validationErrors.join("\n")}`);
    session.status = "candidate-captured";
    session.candidate = manifestPath;
    session.candidate_source = source;
    session.candidate_data_identity = dataIdentity;
    session.candidate_build_dir = workDir;
    session.browser_version = captures.browserVersion;
    session.platform = captures.platform;
    persistAuthorizedSession(sessionPath, session, authority);
    console.log(JSON.stringify({ status: session.status, candidate: session.candidate, project, ports, source }, null, 2));
  } catch (error) {
    primary = error;
    if (transitionMutationStarted && !transitionCompleted) transitionFailureHandled = true;
    if (!startupAttempted) {
      try { fs.rmdirSync(output); } catch (cleanupError) { if (cleanupError.code !== "ENOENT" && cleanupError.code !== "ENOTEMPTY") primary.directoryCleanupError = cleanupError; }
    }
  }
  try {
    runWithTeardown(primary, () => {
      if (primary && startupAttempted && !transitionFailureHandled) teardownOwnedProject(authority, true);
    });
  } catch (error) {
    if (primary && startupAttempted) {
      session.status = "candidate-failed";
      try { persistAuthorizedSession(sessionPath, session, authority); }
      catch (sessionError) { primary.sessionError = sessionError; }
    }
    throw error;
  }
}

function teardownSession(sessionPath) {
  const { session, authority } = loadAuthorizedSession(sessionPath);
  assertRetainedInventoryCurrent(authority);
  const role = authority.manifests.candidate ? "candidate" : "before";
  if (authority.manifests[role] && ["before-captured", "candidate-captured", "compared-pending-review"].includes(session.status)) assertOwnedRuntime(authority, role);
  teardownOwnedProject(authority, true);
  session.status = "torn-down";
  persistAuthorizedSession(sessionPath, session, authority);
}

function compareSession(sessionPath) {
  const { session, authority } = loadAuthorizedSession(sessionPath);
  if (session.status !== "candidate-captured" || !session.candidate) throw new Error("Session has no verified before/candidate pair.");
  assertRetainedInventoryCurrent(authority);
  const beforeRecord = authority.manifests.before;
  const candidateRecord = authority.manifests.candidate;
  const beforeDirectory = beforeRecord.directory;
  const afterDirectory = candidateRecord.directory;
  const output = path.join(artifactRoot, `comparison-${session.session_id}`);
  const report = compareDirectories(beforeDirectory, afterDirectory, output, authority);
  session.status = "compared-pending-review";
  session.comparison = path.join(output, "comparison.json");
  persistAuthorizedSession(sessionPath, session, authority);
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
  candidateServerCommands,
  captureManifestErrors,
  collectPages,
  comparePng,
  createSessionAuthority,
  composeSourceBindMounts,
  containerIdForService,
  disposableProvenanceErrors,
  dockerEnvironment,
  expectedCaptureIds,
  gitEnvironment,
  indexResults,
  isAuthorizedOwnedBindMount,
  isCanonicalOrigin,
  localPathForDockerHostMount,
  loadAuthorizedSession,
  manifestAuthorityErrors,
  manifestDigest,
  matrixErrors,
  normalizePgDump,
  persistAuthorizedSession,
  recordManifestAuthority,
  runCandidateTransition,
  runWithTeardown,
  sourceChangeErrors,
  stableDataIdentity,
  sourceIdentity,
  sameDockerIdSet,
  validateSessionAuthority,
};
