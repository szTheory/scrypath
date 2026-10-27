#!/usr/bin/env node

"use strict";

const crypto = require("node:crypto");
const { execFileSync, spawnSync } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const beamCache = require("./beam_cache.cjs");
const ecommerceBuild = require("./ecommerce_build.cjs");

const GH = process.env.GH_BIN || "gh";
const WORKFLOW = ".github/workflows/ci.yml";
const REQUIRED_JOBS = [
  "core (required)",
  "package (required)",
  "repository-contracts (required)",
  "backend (required)",
  "ecommerce-mounted (required)",
  "coverage (advisory)",
  "closeout-attestation",
];
const REQUIRED_CACHE_MODES = ["docker-warm", "docker-cold", "beam-fallback", "beam-lock-change", "beam-cold"];
const MODES = [...REQUIRED_CACHE_MODES, "full"];
const MAX_ARCHIVE_BYTES = 512 * 1024 * 1024;
const MAX_ARCHIVE_MEMBER_BYTES = 64 * 1024 * 1024;
const MAX_ARCHIVE_TOTAL_BYTES = 256 * 1024 * 1024;
const MAX_ARCHIVE_MEMBERS = 256;
const MAX_POLL_SECONDS = 3600;
const LOCK_TIMEOUT_MS = 30_000;
const LOCK_RETRY_MS = 40;
const REPOSITORY_ROOT = path.resolve(__dirname, "../..");
const EVIDENCE_FILES = [
  "phase105-evidence.json",
  "phase105-evidence-summary.md",
  "phase105-evidence-input.json",
  "phase105-playwright-list.json",
  "phase105-playwright.json",
  "phase105-evidence.ndjson",
  "admin-light-parity.json",
  "contrast-report.json",
  "lifecycle.json",
  "playwright-report/index.html",
];

class CapabilityDeniedError extends Error {
  constructor(message) {
    super(`AUTH GATE REQUIRED: existing GitHub identity lacks a required workflow_dispatch or Actions read capability (${message}). Authenticate with the maintainer-approved identity, then retry; do not add secrets or elevate token scopes.`);
    this.name = "CapabilityDeniedError";
  }
}

function sha256(bytes) {
  return crypto.createHash("sha256").update(bytes).digest("hex");
}

function canonicalize(value) {
  if (Array.isArray(value)) return value.map(canonicalize);
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.keys(value).sort().map((key) => [key, canonicalize(value[key])]));
  }
  return value;
}

function canonicalJson(value) {
  return JSON.stringify(canonicalize(value));
}

function runCommand(bin, args, options = {}) {
  const result = spawnSync(bin, args, {
    encoding: options.encoding === null ? null : "utf8",
    cwd: options.cwd || process.cwd(),
    env: options.env || process.env,
    timeout: options.timeout || 120_000,
    maxBuffer: options.maxBuffer || 32 * 1024 * 1024,
    input: options.input,
  });
  if (result.error) throw new Error(`${bin} could not run: ${result.error.message}`);
  if (result.status !== 0 && !options.allowFailure) {
    const detail = (Buffer.isBuffer(result.stderr) ? result.stderr.toString("utf8") : result.stderr || "").trim();
    const message = `${bin} ${args.join(" ")} failed (${result.status})${detail ? `: ${detail}` : ""}`;
    if (/HTTP 401|HTTP 403|Resource not accessible by integration|not authorized|permission denied|not logged in|not authenticated|authentication token|gh auth login/i.test(message)) {
      throw new CapabilityDeniedError(message);
    }
    throw new Error(message);
  }
  return result;
}

function commandText(result) {
  const value = result?.stdout ?? result;
  if (Buffer.isBuffer(value)) return value.toString("utf8");
  if (typeof value !== "string") throw new Error("command returned no text output");
  return value;
}

function parseJsonText(text, label) {
  try {
    assertNoDuplicateJsonKeys(text);
    const value = JSON.parse(text);
    if (!value || typeof value !== "object") throw new Error("expected a JSON object or array");
    return value;
  } catch (error) {
    throw new Error(`${label} returned malformed JSON: ${error.message}`);
  }
}

function assertNoDuplicateJsonKeys(text) {
  const stack = [];
  for (let index = 0; index < text.length; index += 1) {
    if (text[index] === '"') {
      const start = index;
      index += 1;
      while (index < text.length) {
        if (text[index] === "\\") index += 2;
        else if (text[index] === '"') break;
        else index += 1;
      }
      if (index >= text.length) break;
      const token = text.slice(start, index + 1);
      let lookahead = index + 1;
      while (/\s/.test(text[lookahead] || " ")) lookahead += 1;
      if (stack.at(-1)?.kind === "object" && text[lookahead] === ":") {
        const key = JSON.parse(token);
        if (stack.at(-1).keys.has(key)) throw new Error(`duplicate JSON field ${JSON.stringify(key)}`);
        stack.at(-1).keys.add(key);
      }
      continue;
    }
    if (text[index] === "{") stack.push({ kind: "object", keys: new Set() });
    else if (text[index] === "[") stack.push({ kind: "array" });
    else if (text[index] === "}" || text[index] === "]") stack.pop();
  }
}

function apiJson(command, endpoint, { paginate = false } = {}) {
  const args = ["api"];
  if (paginate) args.push("--paginate", "--slurp");
  args.push(endpoint);
  return parseJsonText(commandText(command(GH, args)), `gh api ${endpoint}`);
}

function flattenPages(payload, key, label) {
  const pages = Array.isArray(payload) ? payload : [payload];
  const values = [];
  for (const page of pages) {
    if (!page || !Array.isArray(page[key])) throw new Error(`${label} pagination returned malformed or incomplete data`);
    values.push(...page[key]);
  }
  return values;
}

function requireText(value, label) {
  if (typeof value !== "string" || value.trim() === "" || /[\r\n\0]/.test(value)) {
    throw new Error(`${label} must be a non-empty single-line string`);
  }
  return value.trim();
}

function validateSha(value, label = "SHA") {
  if (!/^[a-f0-9]{40}$/.test(value || "")) throw new Error(`${label} must be a full lowercase 40-character SHA`);
  return value;
}

function validateBranch(value) {
  const branch = requireText(value, "branch");
  if (!/^[A-Za-z0-9][A-Za-z0-9._/-]*$/.test(branch) || branch.includes("..") || branch.includes("//") || branch.endsWith("/") || branch.endsWith(".lock")) {
    throw new Error("branch must be a valid branch name without traversal or option-like characters");
  }
  return branch;
}

function validateMode(mode) {
  if (!MODES.includes(mode)) throw new Error(`mode must be one of ${MODES.join(", ")}`);
  return mode;
}

function validateProbeNamespace(value) {
  if (value === undefined || value === "") return "";
  // Keep the command's boundary validator aligned with the policy resolver used
  // by prepare, configure, and handoff verification.
  ecommerceBuild.cacheProbeFor("focused", { web: "scope" }, {}, { namespace: value });
  return value;
}

function validateDispatchCacheMode(value) {
  const mode = value || "normal";
  ecommerceBuild.cacheProbeFor("focused", { web: "scope" }, {}, { mode });
  return mode;
}

function appendWorkflowOutputs(outputPath, values) {
  if (!outputPath) return;
  let contents = "";
  for (const [name, value] of Object.entries(values)) {
    const text = String(value ?? "");
    if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(name) || /[\r\n\0]/.test(text)) throw new Error("workflow output contains an invalid name or multiline value");
    contents += `${name}=${text}\n`;
  }
  fs.appendFileSync(outputPath, contents, { mode: 0o600 });
}

function validateWorkflowInputs({ mode = "normal", namespace = "", outputPath } = {}) {
  const validatedMode = validateDispatchCacheMode(mode);
  const validatedNamespace = validateProbeNamespace(namespace);
  const beamProbe = validatedMode.startsWith("beam-");
  const beamNamespace = beamProbe || validatedMode === "normal" ? validatedNamespace : "";
  const mountedDockerMode = validatedMode === "docker-cold" ? "docker-cold" : "normal";
  const dockerNamespace = validatedMode === "normal" ? validatedNamespace : "";
  appendWorkflowOutputs(outputPath, {
    mode: validatedMode,
    proof_mode: validatedMode === "normal" ? "docker-warm" : validatedMode,
    namespace: validatedNamespace,
    beam_mode: beamProbe ? validatedMode : "normal",
    beam_namespace: beamNamespace,
    mounted_docker_mode: mountedDockerMode,
    mounted_docker_namespace: dockerNamespace,
    full_docker_mode: "normal",
    full_docker_namespace: dockerNamespace,
  });
  return {
    mode: validatedMode,
    namespace: validatedNamespace,
    beam_mode: beamProbe ? validatedMode : "normal",
    beam_namespace: beamNamespace,
    mounted_docker_mode: mountedDockerMode,
    mounted_docker_namespace: dockerNamespace,
    full_docker_mode: "normal",
    full_docker_namespace: dockerNamespace,
  };
}

function validRunIdentity(runId, attempt) {
  const id = String(runId ?? "");
  const number = Number(attempt);
  if (!/^[1-9][0-9]*$/.test(id) || !Number.isSafeInteger(number) || number < 1) throw new Error("GitHub run ID and attempt must be positive integers");
  return { runId: id, attempt: number };
}

function prepareLockProbe({ workspace = REPOSITORY_ROOT, runnerTemp = os.tmpdir(), runId, attempt, sourceSha } = {}) {
  const identity = validRunIdentity(runId, attempt);
  const sourceRoot = fs.realpathSync(workspace);
  const tempRoot = path.resolve(runnerTemp);
  if (tempRoot === sourceRoot || tempRoot.startsWith(`${sourceRoot}${path.sep}`)) throw new Error("lock probe temporary checkout must be outside the source checkout");
  fs.mkdirSync(tempRoot, { recursive: true });
  const workdir = path.join(tempRoot, `phase182-beam-lock-${identity.runId}-${identity.attempt}`);
  if (fs.existsSync(workdir)) throw new Error("lock probe checkout path already exists; refusing to reuse prior probe state");
  const sourceHead = execFileSync("git", ["rev-parse", "HEAD"], { cwd: sourceRoot, encoding: "utf8" }).trim();
  if (sourceSha && sourceHead !== sourceSha) throw new Error("lock probe source checkout does not match the workflow SHA");
  const sourceLock = fs.readFileSync(path.join(sourceRoot, "mix.lock"));
  execFileSync("git", ["clone", "--local", "--no-hardlinks", sourceRoot, workdir], { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
  const clonedHead = execFileSync("git", ["rev-parse", "HEAD"], { cwd: workdir, encoding: "utf8" }).trim();
  if (clonedHead !== sourceHead || !fs.readFileSync(path.join(workdir, "mix.lock")).equals(sourceLock)) {
    throw new Error("temporary lock probe checkout does not match the source revision and lock bytes");
  }
  const comment = `# phase182 lock probe run ${identity.runId} attempt ${identity.attempt}\n`;
  const separator = sourceLock.length === 0 || sourceLock.at(-1) === 10 ? Buffer.alloc(0) : Buffer.from("\n");
  const suffix = Buffer.concat([separator, Buffer.from(comment)]);
  fs.writeFileSync(path.join(workdir, "mix.lock"), Buffer.concat([sourceLock, suffix]));
  const changedLock = fs.readFileSync(path.join(workdir, "mix.lock"));
  if (!changedLock.equals(Buffer.concat([sourceLock, suffix]))) throw new Error("temporary lock probe did not preserve a comment-only lock change");
  execFileSync("git", ["add", "mix.lock"], { cwd: workdir, stdio: "ignore" });
  execFileSync("git", ["-c", "user.name=Phase 182 Cache Probe", "-c", "user.email=ci-cache-probe@example.invalid", "commit", "-m", "chore(ci): phase 182 comment-only cache probe"], { cwd: workdir, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
  const changedFiles = execFileSync("git", ["diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD"], { cwd: workdir, encoding: "utf8" }).trim().split(/\r?\n/).filter(Boolean);
  const status = execFileSync("git", ["status", "--porcelain"], { cwd: workdir, encoding: "utf8" }).trim();
  if (JSON.stringify(changedFiles) !== JSON.stringify(["mix.lock"]) || status !== "") throw new Error("temporary lock probe commit must contain only mix.lock and leave its checkout clean");
  const manifestPath = path.join(tempRoot, `phase182-beam-lock-${identity.runId}-${identity.attempt}.json`);
  const manifest = {
    schema: 1,
    source_root: sourceRoot,
    workdir,
    source_sha: sourceHead,
    lock_before: sha256(sourceLock),
    lock_after: sha256(changedLock),
    suffix: suffix.toString("utf8"),
    owned_copy: true,
    probe_commit: execFileSync("git", ["rev-parse", "HEAD"], { cwd: workdir, encoding: "utf8" }).trim(),
  };
  writeAtomic(manifestPath, manifest);
  return { workdir, manifestPath, manifest };
}

function beamPlanForProbe(plan, { mode = "normal", namespace = "", runId, attempt } = {}) {
  const validatedMode = validateDispatchCacheMode(mode);
  const safeNamespace = validateProbeNamespace(namespace);
  const identity = validRunIdentity(runId, attempt);
  if (!plan || !plan.identity || !/^[a-f0-9]{64}$/.test(plan.identity.locks_digest || "") || !/^[a-f0-9]{64}$/.test(plan.identity.source_digest || "")) {
    throw new Error("BEAM cache plan is missing its exact lock/source identity");
  }
  const result = structuredClone(plan);
  const namespaceSuffix = safeNamespace ? `phase182-${safeNamespace}-` : "";
  result.downloads_restore_prefix = `${plan.downloads_restore_prefix}${namespaceSuffix}`;
  result.resolved_restore_prefix = `${plan.resolved_restore_prefix}${namespaceSuffix}`;
  result.downloads_key = `${result.downloads_restore_prefix}${plan.identity.locks_digest}`;
  result.resolved_key = `${result.resolved_restore_prefix}${plan.identity.source_digest}`;
  if (validatedMode === "beam-fallback" || validatedMode === "beam-lock-change") {
    const unique = `phase182-${identity.runId}-${identity.attempt}`;
    result.downloads_key = `${result.downloads_key}-${unique}`;
    result.resolved_key = `${result.resolved_key}-${unique}`;
    // A resolved build is never restored in these probes. The compatible Hex
    // archive prefix remains available so the test isolates the intended layer.
    result.resolved_restore_prefix = "";
  }
  result.probe = { mode: validatedMode, namespace: safeNamespace, run_id: identity.runId, run_attempt: identity.attempt };
  return result;
}

function configureDockerBake({ manifestPath, mode = "normal", namespace = "", env = process.env } = {}) {
  const validatedMode = validateDispatchCacheMode(mode);
  const safeNamespace = validateProbeNamespace(namespace);
  const manifestFile = path.resolve(requireText(manifestPath, "Docker build manifest"));
  const manifest = parseJsonText(fs.readFileSync(manifestFile, "utf8"), "Docker image handoff manifest");
  const bakeFile = path.join(path.dirname(manifestFile), "bake.json");
  const bake = parseJsonText(fs.readFileSync(bakeFile, "utf8"), "Docker Bake configuration");
  if (!bake.target || !manifest.cache_base_scopes || typeof manifest.cache_base_scopes !== "object") {
    throw new Error("Docker build manifest is missing base target cache scopes");
  }
  const expected = ecommerceBuild.cacheProbeFor(manifest.scope, manifest.cache_base_scopes, env, {
    mode: validatedMode,
    namespace: safeNamespace,
  });
  if (canonicalJson(manifest.cache_probe) !== canonicalJson({ mode: expected.mode, namespace: expected.namespace }) ||
    canonicalJson(manifest.cache_scopes) !== canonicalJson(expected.scopes) ||
    canonicalJson(manifest.cache_policy) !== canonicalJson(expected.policy)) {
    throw new Error("prepared Docker cache probe does not match the validated dispatch policy");
  }
  ecommerceBuild.verifyCacheProbeBake(bake, expected);
  manifest.import_status = expected.policy.import ? "pending" : "not_configured";
  manifest.export_status = expected.policy.export ? "pending" : "not_configured";
  writeAtomic(manifestFile, manifest);
  return { manifest, bake, manifestFile, bakeFile, mode: validatedMode, namespace: safeNamespace };
}

function ghaCacheSettings(bake) {
  const targets = Object.values(bake.target || {});
  const settings = (field) => targets.flatMap((target) => Array.isArray(target[field]) ? target[field] : []);
  const imports = settings("cache-from").filter((value) => /^type=gha,/.test(value));
  const exports = settings("cache-to").filter((value) => /^type=gha,/.test(value));
  const scope = (value) => value.match(/(?:^|,)scope=([^,]+)/)?.[1] || "";
  return {
    imports,
    exports,
    importScopes: [...new Set(imports.map(scope).filter(Boolean))].sort(),
    exportScopes: [...new Set(exports.map(scope).filter(Boolean))].sort(),
  };
}

function writeDockerProbeProof({ manifestPath, outputPath, baselinePath = "", inspectPath = "", env = process.env } = {}) {
  const mode = validateDispatchCacheMode(env.PHASE182_CACHE_MODE);
  if (mode !== "normal" && mode !== "docker-cold") throw new Error("Docker probe proof is only valid for normal or docker-cold dispatches");
  const identity = validRunIdentity(env.GITHUB_RUN_ID, env.GITHUB_RUN_ATTEMPT);
  const manifest = parseJsonText(fs.readFileSync(manifestPath, "utf8"), "Docker image handoff manifest");
  const bake = parseJsonText(fs.readFileSync(path.join(path.dirname(manifestPath), "bake.json"), "utf8"), "Docker Bake configuration");
  const settings = ghaCacheSettings(bake);
  const artifactMode = mode === "normal" ? "docker-warm" : mode;
  const scopes = mode === "docker-cold" ? [] : settings.importScopes;
  const exportScopes = mode === "normal" ? settings.exportScopes : [];
  const expectedTargets = Object.keys(manifest.tags || {}).sort();
  const targetScopes = structuredClone(manifest.cache_scopes || {});
  const targetCacheSettings = Object.fromEntries(Object.entries(bake.target || {}).map(([service, target]) => [service, {
    import: Array.isArray(target["cache-from"]) ? target["cache-from"] : [],
    export: Array.isArray(target["cache-to"]) ? target["cache-to"] : [],
  }]));
  if (canonicalJson(expectedTargets) !== canonicalJson(Object.keys(bake.target || {}).sort()) ||
      canonicalJson(expectedTargets) !== canonicalJson(Object.keys(targetScopes).sort())) {
    throw new Error("checked Docker Bake targets do not match the image handoff manifest");
  }
  validateDockerRecipeBindings({
    recipeIds: manifest.recipe_ids,
    imageIds: manifest.image_ids,
    recipeDigest: manifest.recipe_digest,
    expectedTargets,
  });
  validateDockerTargetBindings({
    scope: manifest.scope,
    expected_targets: expectedTargets,
    target_scopes: targetScopes,
    target_cache_settings: targetCacheSettings,
    import_scopes: scopes,
    export_scopes: exportScopes,
  }, artifactMode);
  const cacheFrom = Object.values(bake.target || {}).flatMap((target) => Array.isArray(target["cache-from"]) ? target["cache-from"] : []);
  let builder;
  if (mode === "docker-cold") {
    const builderId = requireText(manifest.builder_id || env.BUILDER_ID, "fresh builder ID");
    const baseline = fs.readFileSync(baselinePath, "utf8").split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
    const inspect = fs.readFileSync(inspectPath, "utf8");
    const inspectedName = inspect.match(/^Name:\s*(.+)$/m)?.[1]?.trim();
    const driver = inspect.match(/^Driver:\s*(.+)$/m)?.[1]?.trim();
    const fresh = inspectedName === builderId && !baseline.includes(builderId) && driver === "docker-container";
    if (!fresh || settings.imports.length || settings.exports.length || cacheFrom.length) throw new Error("docker-cold builder or Bake configuration is not fresh and cache-free");
    builder = {
      id: builderId,
      created_for_run_id: identity.runId,
      created_for_attempt: identity.attempt,
      created_at: new Date().toISOString(),
      driver,
      cache_from: cacheFrom,
      fresh,
      persistent: false,
      baseline_names: baseline,
    };
  }
  const primaryOutcome = env.PRIMARY_VERIFICATION_OUTCOME || "";
  const proof = {
    schema: 1,
    mode: artifactMode,
    repository: requireText(env.GITHUB_REPOSITORY, "GitHub repository"),
    branch: requireText(env.GITHUB_REF_NAME, "GitHub branch"),
    source_sha: validateSha(env.GITHUB_SHA, "GitHub source SHA"),
    run_id: identity.runId,
    run_attempt: identity.attempt,
    commands: { primary_verification: primaryOutcome },
    normal_command_outcome: primaryOutcome,
    ...(builder ? { builder } : {}),
    cache: {
      kind: "buildkit",
      imports_enabled: mode === "docker-cold" ? false : settings.imports.length > 0,
      actual_import: false,
      actual_export: false,
      imported_digest: null,
      exported_digest: null,
      importer: scopes.length ? "gha" : null,
      exporter: exportScopes.length || mode === "normal" && manifest.cache_policy?.export ? "gha" : null,
      scope: manifest.scope,
      expected_targets: expectedTargets,
      target_scopes: targetScopes,
      target_cache_settings: targetCacheSettings,
      recipe_digest: manifest.recipe_digest,
      recipe_ids: structuredClone(manifest.recipe_ids),
      image_ids: structuredClone(manifest.image_ids),
      import_scopes: scopes,
      export_scopes: exportScopes,
      ...(mode === "docker-cold" ? { miss_reason: "fresh builder with BuildKit cache imports disabled" } : {}),
    },
  };
  writeAtomic(outputPath, proof);
  return proof;
}

function writeBeamProbeProof({ planPath, outputPath, lockManifestPath = "", env = process.env } = {}) {
  const mode = validateDispatchCacheMode(env.PHASE182_CACHE_MODE);
  if (!mode.startsWith("beam-")) throw new Error("BEAM cache proof is only valid for a BEAM probe dispatch");
  const identity = validRunIdentity(env.GITHUB_RUN_ID, env.GITHUB_RUN_ATTEMPT);
  const plan = parseJsonText(fs.readFileSync(planPath, "utf8"), "BEAM cache probe plan");
  const lockManifest = lockManifestPath ? parseJsonText(fs.readFileSync(lockManifestPath, "utf8"), "temporary lock probe manifest") : null;
  const downloadsKey = plan.downloads_key;
  const resolvedKey = plan.resolved_key;
  const downloadsRestoreKey = env.DOWNLOADS_MATCHED_KEY || "";
  const resolvedRestoreKey = env.RESOLVED_MATCHED_KEY || "";
  const downloadsHit = env.DOWNLOADS_CACHE_HIT === "true";
  const resolvedHit = env.RESOLVED_CACHE_HIT === "true";
  const sourceLock = lockManifest ? fs.readFileSync(path.join(lockManifest.source_root, "mix.lock")) : null;
  const changedLock = lockManifest ? fs.readFileSync(path.join(lockManifest.workdir, "mix.lock")) : null;
  const expectedChangedLock = lockManifest ? Buffer.concat([sourceLock, Buffer.from(lockManifest.suffix)]) : null;
  const lockProbe = lockManifest ? {
    owned_copy: lockManifest.owned_copy === true,
    source_lock_unchanged: sha256(sourceLock) === lockManifest.lock_before,
    versions_unchanged: changedLock.equals(expectedChangedLock) && sha256(changedLock) === lockManifest.lock_after,
  } : undefined;
  const cache = {
    kind: "beam",
    imports_enabled: mode !== "beam-cold",
    downloads_key: downloadsKey,
    downloads_restore_prefix: plan.downloads_restore_prefix,
    downloads_restore_key: downloadsRestoreKey || null,
    downloads_hit: downloadsHit,
    downloads_restored: Boolean(downloadsRestoreKey),
    resolved_key: resolvedKey,
    resolved_restore_prefix: plan.resolved_restore_prefix,
    resolved_restore_key: resolvedRestoreKey || null,
    resolved_hit: resolvedHit,
    resolved_primary_hit: resolvedHit,
    fallback: Boolean(downloadsRestoreKey && downloadsRestoreKey !== downloadsKey),
    resolved_lock_before: lockManifest?.lock_before || plan.identity.locks_digest,
    resolved_lock_after: lockManifest?.lock_after || plan.identity.locks_digest,
    runtime: Object.fromEntries(["runner_image", "os", "arch", "elixir", "otp", "mix_env", "mix_target", "profile"].map((key) => [key, plan.identity[key]])),
  };
  const commands = {
    deps_get: env.DEPS_GET_OUTCOME || "",
    compile: env.COMPILE_OUTCOME || "",
    verify: env.VERIFY_OUTCOME || "",
    primary_verification: env.VERIFY_OUTCOME || "",
  };
  const proof = {
    schema: 1,
    mode,
    repository: requireText(env.GITHUB_REPOSITORY, "GitHub repository"),
    branch: requireText(env.GITHUB_REF_NAME, "GitHub branch"),
    source_sha: validateSha(env.GITHUB_SHA, "GitHub source SHA"),
    run_id: identity.runId,
    run_attempt: identity.attempt,
    runner: {
      fresh: true,
      id: `${requireText(env.RUNNER_NAME, "GitHub runner name")} ${identity.runId}/${identity.attempt}`,
      created_for_run_id: identity.runId,
      created_for_attempt: identity.attempt,
    },
    cache,
    commands,
    normal_command_outcome: commands.verify,
    ...(lockProbe ? { lock_probe: lockProbe } : {}),
  };
  writeAtomic(outputPath, proof);
  return proof;
}

function validateFlags(flags, { createOutput = true } = {}) {
  const repository = requireText(flags.repo, "repository");
  if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository)) throw new Error("repository must be OWNER/REPO");
  return {
    repo: repository,
    branch: validateBranch(flags.branch),
    sha: validateSha(flags.sha),
    sessionId: requireText(flags.sessionId, "session ID"),
    mode: validateMode(flags.mode),
    probeNamespace: validateProbeNamespace(flags.probeNamespace),
    outputDir: validateOutputRoot(flags.outputDir, { create: createOutput }),
  };
}

function validateOutputRoot(value, { create = true } = {}) {
  const output = path.resolve(requireText(value, "output directory"));
  if (create) fs.mkdirSync(path.dirname(output), { recursive: true });
  if (fs.existsSync(output) && fs.lstatSync(output).isSymbolicLink()) throw new Error("candidate session root cannot be a symbolic link");
  if (create) fs.mkdirSync(output, { recursive: true, mode: 0o700 });
  if (!fs.existsSync(output) || !fs.statSync(output).isDirectory()) throw new Error("candidate session root must already exist");
  const resolved = fs.realpathSync(output);
  const source = fs.realpathSync(REPOSITORY_ROOT);
  if (resolved === source || resolved.startsWith(`${source}${path.sep}`)) {
    throw new Error("candidate session output directory must be outside the source checkout");
  }
  return resolved;
}

function withSessionLock(root, callback, timeoutMs = LOCK_TIMEOUT_MS) {
  const lockPath = path.join(root, ".phase182.lock");
  const deadline = Date.now() + timeoutMs;
  let descriptor;
  while (descriptor === undefined) {
    try {
      descriptor = fs.openSync(lockPath, "wx", 0o600);
      fs.writeSync(descriptor, `${process.pid}\n`);
    } catch (error) {
      if (error.code !== "EEXIST") throw error;
      if (Date.now() >= deadline) throw new Error("timed out waiting for candidate session aggregate lock");
      Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, LOCK_RETRY_MS);
    }
  }
  try {
    return callback();
  } finally {
    fs.closeSync(descriptor);
    fs.unlinkSync(lockPath);
  }
}

function writeAtomic(file, value) {
  const directory = path.dirname(file);
  fs.mkdirSync(directory, { recursive: true, mode: 0o700 });
  const temporary = path.join(directory, `.${path.basename(file)}.${process.pid}.${crypto.randomBytes(8).toString("hex")}.tmp`);
  try {
    fs.writeFileSync(temporary, `${JSON.stringify(value, null, 2)}\n`, { flag: "wx", mode: 0o600 });
    fs.renameSync(temporary, file);
  } finally {
    if (fs.existsSync(temporary)) fs.unlinkSync(temporary);
  }
}

function sessionIdentity(flags) {
  return {
    schema: 1,
    repository: flags.repo,
    branch: flags.branch,
    sha: flags.sha,
    session_id: flags.sessionId,
    created_at: new Date().toISOString(),
    invocations: [],
  };
}

function ensureSessionLocked(flags) {
  const manifestPath = path.join(flags.outputDir, "phase182-session.json");
  if (!fs.existsSync(manifestPath)) {
    const unexpected = fs.readdirSync(flags.outputDir).filter((entry) => entry !== ".phase182.lock");
    if (unexpected.length) throw new Error(`nonempty unowned candidate session root: ${unexpected.join(", ")}`);
    writeAtomic(manifestPath, sessionIdentity(flags));
  }
  const manifest = parseJsonText(fs.readFileSync(manifestPath, "utf8"), "candidate session manifest");
  for (const [key, expected] of [["repository", flags.repo], ["branch", flags.branch], ["sha", flags.sha], ["session_id", flags.sessionId]]) {
    if (manifest[key] !== expected) throw new Error(`candidate session identity mismatch for ${key}; use a new session root for changed source/ref/session identity`);
  }
  if (manifest.schema !== 1 || !Array.isArray(manifest.invocations)) throw new Error("candidate session manifest is malformed");
  return { manifestPath, manifest };
}

function beginInvocation(flags) {
  return withSessionLock(flags.outputDir, () => {
    const { manifestPath, manifest } = ensureSessionLocked(flags);
    if (manifest.invocations.some((entry) => entry.status === "running")) {
      const error = "candidate session has an unfinished invocation; reconcile it before dispatching another run";
      const token = `${Date.now()}-${process.pid}-${crypto.randomBytes(6).toString("hex")}`;
      const relativeDir = path.posix.join("attempts", flags.mode, token);
      const invocationDir = path.join(flags.outputDir, ...relativeDir.split("/"));
      fs.mkdirSync(invocationDir, { recursive: false, mode: 0o700 });
      const receipt = {
        schema: 1,
        repository: flags.repo,
        branch: flags.branch,
        sha: flags.sha,
        session_id: flags.sessionId,
        mode: flags.mode,
        invocation_id: token,
        eligible: false,
        error,
        collected_at: new Date().toISOString(),
      };
      const receiptPath = path.join(invocationDir, "receipt.json");
      writeAtomic(receiptPath, receipt);
      const entry = {
        invocation_id: token,
        mode: flags.mode,
        directory: relativeDir,
        status: "ineligible",
        started_at: receipt.collected_at,
        completed_at: receipt.collected_at,
        receipt: path.relative(flags.outputDir, receiptPath).split(path.sep).join("/"),
        receipt_sha256: sha256(fs.readFileSync(receiptPath)),
        run_id: null,
        run_attempt: null,
        error,
      };
      manifest.invocations.push(entry);
      writeAtomic(manifestPath, manifest);
      updateAggregatesLocked(flags, manifest);
      throw new Error(error);
    }
    const token = `${Date.now()}-${process.pid}-${crypto.randomBytes(6).toString("hex")}`;
    const relativeDir = path.posix.join("attempts", flags.mode, token);
    const invocationDir = path.join(flags.outputDir, ...relativeDir.split("/"));
    fs.mkdirSync(path.dirname(invocationDir), { recursive: true, mode: 0o700 });
    fs.mkdirSync(invocationDir, { recursive: false, mode: 0o700 });
    const entry = {
      invocation_id: token,
      mode: flags.mode,
      directory: relativeDir,
      status: "running",
      started_at: new Date().toISOString(),
      receipt: null,
      receipt_sha256: null,
    };
    manifest.invocations.push(entry);
    writeAtomic(manifestPath, manifest);
    return { manifestPath, invocationDir, entry };
  });
}

function safeRelative(value, label) {
  const normalized = requireText(value, label).replaceAll("\\", "/");
  if (normalized.startsWith("/") || /^[A-Za-z]:/.test(normalized) || normalized.split("/").some((part) => part === ".." || part === "" || part === ".") || normalized.includes("\0")) {
    throw new Error(`${label} must be a safe relative path`);
  }
  return normalized;
}

function resolveSessionPath(root, relative, label) {
  const clean = safeRelative(relative, label);
  const result = path.resolve(root, clean);
  if (result !== root && !result.startsWith(`${root}${path.sep}`)) throw new Error(`${label} escapes candidate session root`);
  const realRoot = fs.realpathSync(root);
  const realResult = fs.realpathSync(result);
  if (realResult !== realRoot && !realResult.startsWith(`${realRoot}${path.sep}`)) throw new Error(`${label} resolves outside candidate session root`);
  return realResult;
}

function sanitizedError(error) {
  return String(error?.message || error)
    .replace(/(?:gh[pousr]_[A-Za-z0-9_]{12,}|github_pat_[A-Za-z0-9_]{12,})/g, "[redacted]")
    .replace(/(?:\/Users\/|\/home\/|\/private\/tmp\/)[^\s:'"]+/g, "[local-path]")
    .slice(0, 1200);
}

function finalizeInvocation(flags, context, receipt) {
  const receiptPath = path.join(context.invocationDir, "receipt.json");
  writeAtomic(receiptPath, receipt);
  const relativeReceipt = path.relative(flags.outputDir, receiptPath).split(path.sep).join("/");
  const receiptHash = sha256(fs.readFileSync(receiptPath));
  return withSessionLock(flags.outputDir, () => {
    const { manifestPath, manifest } = ensureSessionLocked(flags);
    const entry = manifest.invocations.find((item) => item.invocation_id === context.entry.invocation_id);
    if (!entry || entry.status !== "running") throw new Error("candidate invocation disappeared or was already finalized");
    entry.status = receipt.eligible === true ? "eligible" : "ineligible";
    entry.completed_at = new Date().toISOString();
    entry.receipt = relativeReceipt;
    entry.receipt_sha256 = receiptHash;
    entry.run_id = receipt.run?.id || null;
    entry.run_attempt = receipt.run?.attempt || null;
    entry.error = receipt.error || null;
    writeAtomic(manifestPath, manifest);
    updateAggregatesLocked(flags, manifest);
    return { receiptPath, receiptHash, manifestPath, manifest };
  });
}

function readManifestReceipt(root, entry, expectedIdentity) {
  if (!entry.receipt || !/^[a-f0-9]{64}$/.test(entry.receipt_sha256 || "")) throw new Error(`invocation ${entry.invocation_id} has no verified receipt reference`);
  const file = resolveSessionPath(root, entry.receipt, "invocation receipt path");
  const bytes = fs.readFileSync(file);
  if (sha256(bytes) !== entry.receipt_sha256) throw new Error(`invocation ${entry.invocation_id} receipt digest mismatch`);
  const receipt = parseJsonText(bytes.toString("utf8"), "invocation receipt");
  for (const [field, wanted] of Object.entries(expectedIdentity)) {
    if (receipt[field] !== wanted) throw new Error(`invocation ${entry.invocation_id} has a foreign ${field}`);
  }
  return receipt;
}

function updateAggregatesLocked(flags, manifest) {
  const expected = { repository: flags.repo, branch: flags.branch, sha: flags.sha, session_id: flags.sessionId };
  const receipts = manifest.invocations.filter((entry) => entry.status !== "running" && entry.receipt).map((entry) => ({
    entry,
    receipt: readManifestReceipt(flags.outputDir, entry, expected),
  }));
  const accepted = receipts.filter(({ entry, receipt }) => entry.status === "eligible" && receipt.eligible === true);
  const byMode = Object.fromEntries(REQUIRED_CACHE_MODES.map((mode) => [mode, accepted.filter(({ entry }) => entry.mode === mode)]));
  const latestByMode = (mode) => manifest.invocations.filter((entry) => entry.mode === mode).at(-1);
  if (REQUIRED_CACHE_MODES.every((mode) => byMode[mode].length > 0 && latestByMode(mode)?.status === "eligible")) {
    const aggregate = {
      schema: 1,
      authority: "phase182-manifest-listed-cache-receipts",
      ...expected,
      eligible: true,
      modes: Object.fromEntries(REQUIRED_CACHE_MODES.map((mode) => [mode, {
        accepted: byMode[mode].at(-1).entry.receipt,
        attempts: receipts.filter(({ entry }) => entry.mode === mode).map(({ entry }) => ({
          receipt: entry.receipt,
          status: entry.status,
          run_id: entry.run_id,
          run_attempt: entry.run_attempt,
          receipt_sha256: entry.receipt_sha256,
        })),
      }])),
      browser_aggregates: [...new Set(accepted.map(({ receipt }) => receipt.browser?.receipt_path).filter(Boolean))],
      attempt_history: receipts.map(({ entry }) => ({ mode: entry.mode, status: entry.status, receipt: entry.receipt, run_id: entry.run_id, run_attempt: entry.run_attempt })),
    };
    writeAtomic(path.join(flags.outputDir, "cache-acceptance.json"), aggregate);
  }

  const fullProofs = accepted.filter(({ entry, receipt }) => entry.mode === "full" && receipt.browser?.eligible === true);
  if (fullProofs.length && latestByMode("full")?.status === "eligible") {
    const aggregate = {
      schema: 1,
      authority: "phase182-manifest-listed-browser-receipts",
      ...expected,
      eligible: true,
      accepted: fullProofs.at(-1).entry.receipt,
      browser_aggregate: fullProofs.at(-1).receipt.browser.receipt_path,
      attempts: receipts.filter(({ entry }) => entry.mode === "full").map(({ entry }) => ({
        receipt: entry.receipt,
        status: entry.status,
        run_id: entry.run_id,
        run_attempt: entry.run_attempt,
        receipt_sha256: entry.receipt_sha256,
      })),
    };
    writeAtomic(path.join(flags.outputDir, "full-acceptance.json"), aggregate);
  }
}

function validateCommonRun(proof, expected) {
  const run = proof?.run;
  if (!run || typeof run !== "object") throw new Error("run identity is missing");
  const joins = [
    ["repository", expected.repository],
    ["branch", expected.branch],
    ["sha", expected.sha],
    ["event", "workflow_dispatch"],
    ["workflow", WORKFLOW],
    ["status", "completed"],
    ["conclusion", "success"],
  ];
  for (const [field, wanted] of joins) if (run[field] !== wanted) throw new Error(`run ${field} does not match the requested ${field === "sha" ? "source SHA" : field}`);
  if (!/^[1-9][0-9]*$/.test(String(run.id)) || !Number.isSafeInteger(Number(run.attempt)) || run.attempt < 1) throw new Error("run ID/attempt is malformed");
  if (!Array.isArray(run.previous_attempts)) throw new Error("previous attempt history is missing");
  if (run.previous_attempts.length !== Number(run.attempt) - 1) throw new Error("previous attempt history is incomplete");
  const previousNumbers = run.previous_attempts.map((item) => item.attempt).sort((a, b) => a - b);
  if (previousNumbers.some((attempt, index) => attempt !== index + 1)) throw new Error("previous attempt history is duplicated or out of sequence");
  if (proof.session?.repository !== expected.repository || proof.session?.branch !== expected.branch || proof.session?.sha !== expected.sha || proof.session?.session_id !== expected.sessionId) {
    throw new Error("proof session identity mismatch");
  }
  for (const previous of run.previous_attempts) {
    if (!Number.isInteger(previous.attempt) || previous.attempt < 1 || previous.attempt >= run.attempt || !["success", "failure", "cancelled", "timed_out", "action_required", "neutral", "skipped"].includes(previous.conclusion)) {
      throw new Error("previous failed-attempt history is malformed or incomplete");
    }
  }
}

function validTimestamp(value, label) {
  const parsed = Date.parse(value || "");
  if (typeof value !== "string" || !Number.isFinite(parsed)) throw new Error(`${label} is missing or invalid`);
  return parsed;
}

function validateBrowserAcceptance(proof) {
  const identity = {
    repository: proof?.session?.repository,
    branch: proof?.session?.branch,
    sha: proof?.session?.sha,
    sessionId: proof?.session?.session_id,
  };
  if (!identity.repository || !identity.branch || !identity.sha || !identity.sessionId) throw new Error("browser session identity is incomplete");
  validateCommonRun(proof, { ...identity, sessionId: identity.sessionId });
  if (proof.raw_verifier_outcome !== "success") throw new Error("raw verifier outcome is not successful");
  if (proof.job_conclusion !== "success") throw new Error("full advisory browser job did not conclude successfully");
  const browser = proof.aggregate;
  if (!browser || browser.valid !== true || browser.eligible !== true) throw new Error("browser aggregate is invalid or ineligible");
  if (browser.repository !== identity.repository || browser.source_sha !== identity.sha || browser.run_id !== String(proof.run.id) || Number(browser.attempt) !== proof.run.attempt) {
    throw new Error("browser aggregate identity does not join the selected run/source");
  }
  if (!Number.isSafeInteger(browser.case_count) || browser.case_count <= 0 || !Number.isSafeInteger(browser.attempts_total) || browser.attempts_total <= 0) {
    throw new Error("browser aggregate has zero or malformed cases/attempts");
  }
  if (browser.event !== "workflow_dispatch" || browser.source?.mode !== "hosted" || browser.source?.dirty !== false ||
      browser.source?.checkout_head !== identity.sha || browser.source?.built_source_sha !== identity.sha || browser.source?.event_sha !== identity.sha) {
    throw new Error("browser checkout, event and built source identities do not match the selected SHA");
  }
  for (const kind of ["application", "browser"]) {
    const image = browser.images?.[kind];
    if (!image || image.built_id !== image.runtime_id || image.source_sha !== identity.sha || !/^sha256:[a-f0-9]{64}$/.test(image.built_id || "")) {
      throw new Error(`browser ${kind} built/runtime image identity does not match the selected source`);
    }
  }
  const artifact = proof.artifact;
  if (!artifact || artifact.name !== `ecommerce-e2e-evidence-${proof.run.id}-${proof.run.attempt}` || artifact.source_sha !== identity.sha || artifact.run_id !== String(proof.run.id) || Number(artifact.attempt) !== proof.run.attempt) {
    throw new Error("browser evidence artifact does not belong to the selected source/run/attempt");
  }
  if (!/^sha256:[a-f0-9]{64}$/.test(artifact.digest || "") || artifact.digest !== `sha256:${artifact.archive_sha256}` || !/^[a-f0-9]{64}$/.test(artifact.member_sha256 || "")) {
    throw new Error("browser archive digest or aggregate member digest is invalid");
  }
  const start = validTimestamp(proof.job_started_at, "browser job start");
  const end = validTimestamp(proof.job_completed_at, "browser job completion");
  const uploaded = validTimestamp(proof.uploaded_at, "browser artifact upload time");
  if (end < start || uploaded < start || uploaded > end + 60_000) throw new Error("browser job and artifact timing is inconsistent");
  const elapsed = (uploaded - start) / 1000;
  if (elapsed > 1800) throw new Error("browser proof exceeded the 1800 seconds acceptance budget");
  const reserve = 1800 - elapsed;
  if (!Number.isFinite(proof.finalization_reserve_seconds) || proof.finalization_reserve_seconds < 300 || Math.abs(proof.finalization_reserve_seconds - reserve) > 2) {
    throw new Error("browser proof did not preserve and measure the 300-second finalization reserve");
  }
  return true;
}

function expectedDockerTargets(scope, mode) {
  if (mode === "docker-warm" && scope === "full") return ["browser", "standalone_ops", "web"];
  if (mode === "docker-cold" && scope === "focused") return ["browser", "web"];
  throw new Error(`Docker cache probe mode ${mode} does not match Compose scope ${scope}`);
}

function targetGhaScopes(settings, field) {
  return (settings[field] || []).filter((value) => typeof value === "string" && /^type=gha,/.test(value))
    .map((value) => value.match(/(?:^|,)scope=([^,]+)/)?.[1] || "");
}

function validateDockerTargetBindings(cache, mode) {
  const expectedTargets = expectedDockerTargets(cache.scope, mode);
  const targetScopes = cache.target_scopes;
  const targetSettings = cache.target_cache_settings;
  const targets = (value) => value && typeof value === "object" && !Array.isArray(value) ? Object.keys(value).sort() : [];
  if (canonicalJson(cache.expected_targets) !== canonicalJson(expectedTargets) ||
      canonicalJson(targets(targetScopes)) !== canonicalJson(expectedTargets) ||
      canonicalJson(targets(targetSettings)) !== canonicalJson(expectedTargets)) {
    throw new Error("Docker cache proof target mapping does not match the checked Compose recipes");
  }
  const mappedScopes = [];
  for (const service of expectedTargets) {
    const scope = targetScopes[service];
    const settings = targetSettings[service];
    if (typeof scope !== "string" || !/^[a-z0-9][a-z0-9-]{0,127}$/.test(scope) ||
        !settings || !Array.isArray(settings.import) || !Array.isArray(settings.export)) {
      throw new Error(`Docker cache proof has an invalid checked target mapping for ${service}`);
    }
    const importScopes = targetGhaScopes(settings, "import");
    const exportScopes = targetGhaScopes(settings, "export");
    if (mode === "docker-warm" && (canonicalJson(importScopes) !== canonicalJson([scope]) || canonicalJson(exportScopes) !== canonicalJson([scope]))) {
      throw new Error(`Docker cache proof Bake settings do not match the checked scope for ${service}`);
    }
    if (mode === "docker-cold" && (settings.import.length !== 0 || settings.export.length !== 0)) {
      throw new Error(`docker-cold must not configure cache import or export for ${service}`);
    }
    mappedScopes.push(scope);
  }
  if (new Set(mappedScopes).size !== expectedTargets.length) throw new Error("Docker cache proof target scopes must be distinct per recipe");
  const expectedScopes = mode === "docker-warm" ? mappedScopes.slice().sort() : [];
  if (canonicalJson(cache.import_scopes) !== canonicalJson(expectedScopes) ||
      canonicalJson(cache.export_scopes) !== canonicalJson(expectedScopes)) {
    throw new Error("Docker cache proof scopes do not match the checked target mapping");
  }
  return expectedTargets;
}

function validateDockerRecipeBindings({ recipeIds, imageIds, recipeDigest, expectedTargets }) {
  const exactKeys = (value) => value && typeof value === "object" && !Array.isArray(value) &&
    canonicalJson(Object.keys(value).sort()) === canonicalJson(expectedTargets.slice().sort());
  if (!exactKeys(recipeIds) || !exactKeys(imageIds)) {
    throw new Error("Docker cache proof is missing exact per-target recipe and image identities");
  }
  for (const service of expectedTargets) {
    if (!/^sha256:[a-f0-9]{64}$/.test(recipeIds[service] || "") ||
        !/^sha256:[a-f0-9]{64}$/.test(imageIds[service] || "")) {
      throw new Error(`Docker cache proof has an invalid recipe or image identity for ${service}`);
    }
  }
  if (recipeDigest !== `sha256:${sha256(canonicalJson(recipeIds))}`) {
    throw new Error("Docker cache proof recipe digest does not match the per-target recipe identities");
  }
  return true;
}

function validateDockerHandoffBindings({ cache, handoff, mode, sourceSha }) {
  const expectedScope = mode === "docker-warm" ? "full" : mode === "docker-cold" ? "focused" : "";
  const expectedProbeMode = mode === "docker-warm" ? "normal" : mode;
  if (!expectedScope || !handoff || handoff.schema_version !== 1 || handoff.scope !== expectedScope ||
      handoff.source_sha !== sourceSha || handoff.cache_probe?.mode !== expectedProbeMode ||
      handoff.handoff_status !== "runtime_verified" || handoff.cache_action_outcome !== "success" ||
      handoff.cache_handoff_outcome !== "success" ||
      canonicalJson(handoff.cache_scopes) !== canonicalJson(cache.target_scopes)) {
    throw new Error("Docker cache proof does not join the checked browser image handoff");
  }
  if (mode === "docker-warm" && (handoff.import_status !== "completed" || handoff.export_status !== "completed")) {
    throw new Error("Docker warm proof requires completed per-target import and export handoff status");
  }
  if (mode === "docker-cold" && (handoff.import_status !== "not_configured" || handoff.export_status !== "not_configured")) {
    throw new Error("Docker cold proof must retain disabled import and export handoff status");
  }
  const expectedTargets = validateDockerTargetBindings(cache, mode);
  validateDockerRecipeBindings({
    recipeIds: handoff.recipe_ids,
    imageIds: handoff.image_ids,
    recipeDigest: handoff.recipe_digest,
    expectedTargets,
  });
  if (canonicalJson(cache.recipe_ids) !== canonicalJson(handoff.recipe_ids) ||
      cache.recipe_digest !== handoff.recipe_digest ||
      canonicalJson(cache.image_ids) !== canonicalJson(handoff.image_ids) ||
      canonicalJson(handoff.runtime_image_ids) !== canonicalJson(handoff.image_ids)) {
    throw new Error("Docker cache proof recipe or image identities differ from the verified handoff");
  }
  return true;
}

function parseBuildKitCacheProgress(logText, targetScopes, recipeBindings = {}) {
  const expectedTargets = Object.keys(targetScopes || {}).sort();
  const targetSet = new Set(expectedTargets);
  const lines = String(logText).split(/\r?\n/);
  const buildKitLines = lines.map((line) => line.replace(
    /^[^\t\r\n]+\t[^\t\r\n]+\t\uFEFF?\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z\s+#/,
    "#",
  ));
  const vertices = new Map();
  const byIdLines = new Map();
  const terminal = new Map();
  for (let index = 0; index < lines.length; index += 1) {
    const line = buildKitLines[index];
    const start = line.match(/^#(\d+)\s+(?:\[([^\]]+)\]\s+)?(.*?)\s*$/);
    if (!start) continue;
    const id = start[1];
    if (!byIdLines.has(id)) byIdLines.set(id, []);
    byIdLines.get(id).push(index);
    const outcome = start[2] ? null : start[3].match(/^(DONE|CACHED|ERROR|CANCELED)(?:\s|$)/i)?.[1]?.toUpperCase();
    if (outcome) terminal.set(id, outcome);
    else if (start[2]) {
      const service = start[2].trim().split(/\s+/)[0];
      const title = start[3].trim();
      if (targetSet.has(service) && !vertices.has(id)) vertices.set(id, { id, service, title, line: index });
    }
  }

  const imports = new Map(expectedTargets.map((service) => [service, []]));
  const exports = new Map(expectedTargets.map((service) => [service, []]));
  const cachedSteps = new Map(expectedTargets.map((service) => [service, []]));
  const importLineIndexes = new Set();
  const exportLineIndexes = new Set();
  const cachedLineIndexes = new Set();
  for (const vertex of vertices.values()) {
    const { service, title, id, line } = vertex;
    const status = terminal.get(id) || "";
    if (/^importing cache (?:manifest )?from gha\b/i.test(title)) {
      imports.get(service).push({ id, outcome: status });
      importLineIndexes.add(line);
      (byIdLines.get(id) || []).forEach((lineIndex) => importLineIndexes.add(lineIndex));
    } else if (/^exporting to GitHub Actions Cache\b/i.test(title)) {
      exports.get(service).push({ id, outcome: status });
      (byIdLines.get(id) || []).forEach((lineIndex) => exportLineIndexes.add(lineIndex));
    } else if (title && !/^(?:internal\b|importing cache\b|exporting\b|load (?:build definition|metadata|build context)\b)/i.test(title) && status === "CACHED") {
      cachedSteps.get(service).push(id);
      cachedLineIndexes.add(line);
      (byIdLines.get(id) || []).forEach((lineIndex) => cachedLineIndexes.add(lineIndex));
    }
  }

  const recipeIds = recipeBindings.recipe_ids || {};
  const imageIds = recipeBindings.image_ids || {};
  const sharedCachedSteps = new Map(expectedTargets.map((service) => [service, []]));
  const recipeGroups = new Map();
  for (const service of expectedTargets) {
    const recipeId = recipeIds[service];
    const imageId = imageIds[service];
    if (typeof recipeId !== "string" || typeof imageId !== "string" || !recipeId || !imageId) continue;
    const key = `${recipeId}\0${imageId}`;
    if (!recipeGroups.has(key)) recipeGroups.set(key, []);
    recipeGroups.get(key).push(service);
  }
  for (const services of recipeGroups.values()) {
    if (services.length < 2) continue;
    const hitSources = services.filter((service) => cachedSteps.get(service).length > 0);
    if (!hitSources.length) continue;
    for (const service of services) {
      if (cachedSteps.get(service).length > 0) continue;
      for (const from of hitSources) {
        sharedCachedSteps.get(service).push({ from, steps: cachedSteps.get(from).slice() });
      }
    }
  }

  const importComplete = expectedTargets.length > 0 && expectedTargets.every((service) => {
    const entries = imports.get(service);
    return entries.length === 1 && ["DONE", "CACHED"].includes(entries[0].outcome) &&
      (cachedSteps.get(service).length > 0 || sharedCachedSteps.get(service).length > 0);
  });
  const matchingLines = (predicate) => buildKitLines.flatMap((line, index) => predicate(line) ? [lines[index]] : []);
  const cacheFailureLines = matchingLines((line) => /(?:^|\s)ERROR(?::|\s)/i.test(line) && /cache|export|import/i.test(line));
  const exporterWarnings = matchingLines((line) => /warning/i.test(line) && /cache|exporter/i.test(line) && /ignored|fail|error|unsupported|not supported/i.test(line));
  const exportComplete = expectedTargets.length > 0 && expectedTargets.every((service) => {
    const entries = exports.get(service);
    return entries.length === 1 && ["DONE", "CACHED"].includes(entries[0].outcome);
  }) && cacheFailureLines.length === 0 && exporterWarnings.length === 0;
  const matchedLines = (indexes) => [...indexes].sort((left, right) => left - right).map((index) => lines[index]);
  const importBytes = matchedLines(importLineIndexes).join("\n");
  const exportBytes = matchedLines(exportLineIndexes).join("\n");
  const cachedBytes = matchedLines(cachedLineIndexes).join("\n");
  const progressTargets = Object.fromEntries(expectedTargets.map((service) => [service, {
    imports: imports.get(service),
    cached_steps: cachedSteps.get(service),
    shared_cached_steps: sharedCachedSteps.get(service),
    exports: exports.get(service),
  }]));
  const cacheBindings = { recipe_ids: recipeIds, image_ids: imageIds };
  return {
    import_complete: importComplete,
    export_complete: exportComplete,
    imported_digest: importBytes ? `sha256:${sha256(importBytes)}` : null,
    exported_digest: exportBytes ? `sha256:${sha256(exportBytes)}` : null,
    cached_steps_digest: cachedBytes ? `sha256:${sha256(cachedBytes)}` : null,
    cache_binding_digest: cachedBytes ? `sha256:${sha256(canonicalJson({ cached: cachedBytes, bindings: cacheBindings, targets: progressTargets }))}` : null,
    targets: progressTargets,
    exporter_warnings: exporterWarnings,
    cache_errors: cacheFailureLines,
  };
}

function validateCacheAcceptance(proof) {
  const mode = validateMode(proof?.mode);
  if (!REQUIRED_CACHE_MODES.includes(mode)) throw new Error("full mode does not declare a cache probe");
  const identity = {
    repository: proof?.session?.repository,
    branch: proof?.session?.branch,
    sha: proof?.session?.sha,
    sessionId: proof?.session?.session_id,
  };
  if (!identity.repository || !identity.branch || !identity.sha || !identity.sessionId) throw new Error("cache session identity is incomplete");
  validateCommonRun(proof, { ...identity, sessionId: identity.sessionId });
  if (proof.normal_command_outcome !== "success" || proof.commands?.primary_verification !== "success") throw new Error("normal verification command did not complete successfully");
  const cache = proof.cache;
  if (!cache || !["buildkit", "beam"].includes(cache.kind)) throw new Error("cache proof kind is missing");
  if (!/^[a-f0-9]{64}$/.test(cache.log_sha256 || "") || typeof cache.log_text !== "string" || sha256(cache.log_text) !== cache.log_sha256) {
    throw new Error("cache proof is missing real hashed job log evidence");
  }
  const lines = cache.log_text.split(/\r?\n/);
  const has = (pattern) => lines.some((line) => pattern.test(line));
  const artifact = proof.artifact;
  if (!artifact || artifact.name !== `phase182-cache-probe-${mode}-${proof.run.id}-${proof.run.attempt}` ||
      artifact.source_sha !== identity.sha || artifact.run_id !== String(proof.run.id) || Number(artifact.attempt) !== proof.run.attempt ||
      !/^sha256:[a-f0-9]{64}$/.test(artifact.digest || "") || artifact.digest !== `sha256:${artifact.archive_sha256}`) {
    throw new Error("cache proof immutable artifact does not join the selected run/source/attempt");
  }
  if (mode === "docker-warm") {
    const expectedTargets = validateDockerTargetBindings(cache, mode);
    validateDockerRecipeBindings({
      recipeIds: cache.recipe_ids,
      imageIds: cache.image_ids,
      recipeDigest: cache.recipe_digest,
      expectedTargets,
    });
    const evidence = parseBuildKitCacheProgress(cache.log_text, cache.target_scopes, {
      recipe_ids: cache.recipe_ids,
      image_ids: cache.image_ids,
    });
    if (cache.kind !== "buildkit" || cache.imports_enabled !== true || cache.actual_import !== evidence.import_complete || cache.actual_export !== evidence.export_complete ||
        evidence.import_complete !== true || evidence.export_complete !== true ||
        cache.imported_digest !== evidence.imported_digest || cache.exported_digest !== evidence.exported_digest ||
        cache.cached_steps_digest !== evidence.cached_steps_digest || cache.cache_binding_digest !== evidence.cache_binding_digest ||
        canonicalJson(cache.progress) !== canonicalJson(evidence.targets) ||
        cache.importer !== "gha" || cache.exporter !== "gha" || expectedTargets.length < 2 ||
        proof.commands.primary_verification !== "success") {
      throw new Error("docker-warm requires actual GHA import and export log evidence");
    }
  } else if (mode === "docker-cold") {
    const expectedTargets = validateDockerTargetBindings(cache, mode);
    validateDockerRecipeBindings({
      recipeIds: cache.recipe_ids,
      imageIds: cache.image_ids,
      recipeDigest: cache.recipe_digest,
      expectedTargets,
    });
    if (cache.kind !== "buildkit" || cache.imports_enabled !== false || cache.actual_import !== false || cache.actual_export !== false || !proof.builder || proof.builder.fresh !== true || proof.builder.persistent !== false ||
        proof.builder.created_for_run_id !== String(proof.run.id) || proof.builder.created_for_attempt !== proof.run.attempt || !requireText(proof.builder.id, "fresh builder ID") ||
        proof.builder.driver !== "docker-container" || !Array.isArray(proof.builder.cache_from) || proof.builder.cache_from.length !== 0 ||
        validTimestamp(proof.builder.created_at, "fresh builder creation time") < validTimestamp(proof.run.started_at, "run start") ||
        !proof.commands.primary_verification || has(/importing cache manifest|importing cache from/i)) {
      throw new Error("docker-cold requires a fresh builder and imports must be disabled");
    }
  } else {
    if (cache.kind !== "beam" || !cache.runtime || !["runner_image", "elixir", "otp", "os", "arch", "mix_env", "mix_target", "profile"].every((key) => typeof cache.runtime[key] === "string" && cache.runtime[key])) {
      throw new Error("BEAM cache proof must bind the exact runtime tuple");
    }
    if (!["deps_get", "compile", "verify"].every((name) => proof.commands?.[name] === "success") ||
        !has(/mix deps\.get/) || !has(/mix compile/) || !has(/mix verify\.[a-z0-9_.-]+/)) {
      throw new Error("BEAM cache proof must show successful normal mix deps.get, compile and verification commands");
    }
    const hasRestore = has(/Cache restored from|Cache hit for/i);
    if (mode === "beam-cold") {
      if (cache.imports_enabled !== false || proof.runner?.fresh !== true || !proof.runner?.id ||
          proof.runner.created_for_run_id !== String(proof.run.id) || proof.runner.created_for_attempt !== proof.run.attempt ||
          cache.downloads_hit === true || cache.resolved_hit === true || hasRestore || has(/Cache not found for input keys:/i)) {
        throw new Error("beam-cold imports must be disabled on a fresh runner");
      }
    } else if (mode === "beam-fallback") {
      if (cache.imports_enabled !== true || cache.downloads_restored !== true || cache.downloads_hit === true || cache.resolved_primary_hit !== false || cache.fallback !== true ||
          !cache.downloads_key || !cache.resolved_key || !cache.downloads_restore_prefix || cache.resolved_restore_prefix !== "" ||
          !cache.downloads_restore_key?.startsWith(cache.downloads_restore_prefix) || cache.downloads_restore_key === cache.downloads_key ||
          cache.resolved_restore_key || !has(new RegExp(`Cache restored from key: ${escapeRegExp(cache.downloads_restore_key)}`)) ||
          !has(new RegExp(`Cache not found for input keys: ${escapeRegExp(cache.resolved_key)}`)) ||
          !/^[a-f0-9]{64}$/.test(cache.resolved_lock_before || "") || cache.resolved_lock_before !== cache.resolved_lock_after) {
        throw new Error("beam-fallback requires a compatible download restore and exact-lock resolved miss");
      }
    } else if (mode === "beam-lock-change") {
      const lockProbe = proof.lock_probe;
      if (cache.imports_enabled !== true || cache.downloads_restored !== true || cache.downloads_hit === true || cache.resolved_primary_hit !== false || cache.fallback !== true ||
          !cache.downloads_key || !cache.resolved_key || !cache.downloads_restore_prefix || cache.resolved_restore_prefix !== "" ||
          !cache.downloads_restore_key?.startsWith(cache.downloads_restore_prefix) || cache.downloads_restore_key === cache.downloads_key ||
          cache.resolved_restore_key || !has(new RegExp(`Cache restored from key: ${escapeRegExp(cache.downloads_restore_key)}`)) ||
          !has(new RegExp(`Cache not found for input keys: ${escapeRegExp(cache.resolved_key)}`)) ||
          !/^[a-f0-9]{64}$/.test(cache.resolved_lock_before || "") || !/^[a-f0-9]{64}$/.test(cache.resolved_lock_after || "") ||
          cache.resolved_lock_before === cache.resolved_lock_after || !lockProbe || lockProbe.owned_copy !== true ||
          lockProbe.source_lock_unchanged !== true || lockProbe.versions_unchanged !== true) {
        throw new Error("beam-lock-change requires a byte-changed lock miss with a compatible download fallback");
      }
    }
  }
  return true;
}

function escapeRegExp(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function workflowCacheInput(mode) {
  if (mode === "docker-cold" || mode === "beam-cold" || mode === "beam-fallback" || mode === "beam-lock-change") return mode;
  return "normal";
}

function listWorkflowRuns(command, repo, branch) {
  const endpoint = `repos/${repo}/actions/workflows/ci.yml/runs?event=workflow_dispatch&branch=${encodeURIComponent(branch)}&per_page=100`;
  return flattenPages(apiJson(command, endpoint, { paginate: true }), "workflow_runs", "workflow run");
}

function runSummary(raw, repo) {
  return {
    id: String(raw.id ?? raw.databaseId ?? ""),
    attempt: Number(raw.run_attempt ?? raw.runAttempt ?? raw.attempt),
    repository: raw.repository?.full_name || raw.repository || repo,
    repository_id: repositoryId(raw.repository?.id ?? raw.repository_id),
    head_repository: raw.head_repository?.full_name || "",
    head_repository_id: repositoryId(raw.head_repository?.id ?? raw.head_repository_id),
    branch: raw.head_branch || raw.headBranch || "",
    sha: raw.head_sha || raw.headSha || "",
    event: raw.event || "",
    workflow: raw.path || raw.workflowPath || "",
    status: raw.status || "",
    conclusion: raw.conclusion || "",
    started_at: raw.run_started_at || raw.started_at || raw.startedAt || "",
    completed_at: raw.updated_at || raw.completed_at || raw.updatedAt || "",
    previous_attempts: [],
    workflow_id: raw.workflow_id || raw.workflowDatabaseId,
  };
}

function repositoryId(value) {
  const id = String(value ?? "");
  return /^[1-9][0-9]*$/.test(id) && Number.isSafeInteger(Number(id)) ? id : null;
}

function waitForDispatchedRun(command, flags, beforeIds, options) {
  const timeoutSeconds = Number(options.timeoutSeconds || 3600);
  if (!Number.isSafeInteger(timeoutSeconds) || timeoutSeconds < 1 || timeoutSeconds > MAX_POLL_SECONDS) throw new Error(`timeout must be between 1 and ${MAX_POLL_SECONDS} seconds`);
  const pollMilliseconds = options.pollMilliseconds ?? 5000;
  const deadline = Date.now() + timeoutSeconds * 1000;
  while (Date.now() <= deadline) {
    const candidate = listWorkflowRuns(command, flags.repo, flags.branch)
      .filter((run) => !beforeIds.has(String(run.id)) && !beforeIds.has(String(run.databaseId)))
      .find((run) => (run.head_sha || run.headSha) === flags.sha && (run.head_branch || run.headBranch) === flags.branch && run.event === "workflow_dispatch");
    if (candidate) {
      const runId = String(candidate.id ?? candidate.databaseId);
      const detail = apiJson(command, `repos/${flags.repo}/actions/runs/${runId}`);
      const summary = runSummary(detail, flags.repo);
      if (summary.repository !== flags.repo || summary.head_repository !== flags.repo || !summary.repository_id || !summary.head_repository_id || summary.workflow !== WORKFLOW || summary.sha !== flags.sha || summary.branch !== flags.branch || summary.event !== "workflow_dispatch" || summary.id !== runId) {
        throw new Error("new workflow dispatch run does not match the requested ref and source SHA");
      }
      if (summary.status === "completed") return summary;
    }
    if (options.sleep) options.sleep(pollMilliseconds);
    else Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, pollMilliseconds);
  }
  throw new Error(`timed out waiting for a newly dispatched CI run at ${flags.sha} on ${flags.branch}`);
}

function collectAttemptJobs(command, repo, runId, attempt) {
  const endpoint = `repos/${repo}/actions/runs/${runId}/attempts/${attempt}/jobs?per_page=100`;
  const pages = flattenPages(apiJson(command, endpoint, { paginate: true }), "jobs", "job");
  const ids = new Set();
  for (const job of pages) {
    const id = String(job.id ?? "");
    if (!/^[1-9][0-9]*$/.test(id) || ids.has(id)) throw new Error("attempt jobs contain an invalid or duplicate job ID");
    ids.add(id);
  }
  return pages;
}

function summarizePreviousAttempts(command, repo, runId, latestAttempt) {
  const attempts = [];
  for (let attempt = 1; attempt < latestAttempt; attempt += 1) {
    const detail = apiJson(command, `repos/${repo}/actions/runs/${runId}/attempts/${attempt}`);
    const conclusion = detail.conclusion;
    if (!new Set(["success", "failure", "cancelled", "timed_out", "action_required", "neutral", "skipped"]).has(conclusion)) {
      throw new Error(`previous attempt ${attempt} has no authoritative terminal conclusion`);
    }
    const jobs = collectAttemptJobs(command, repo, runId, attempt);
    if (jobs.length === 0) throw new Error(`previous attempt ${attempt} has no readable job history`);
    attempts.push({
      attempt,
      conclusion,
      failed_jobs: jobs.filter((job) => job.conclusion !== "success").map((job) => job.name).sort(),
      job_count: jobs.length,
    });
  }
  return attempts;
}

function validateCompletedJobs(jobs) {
  for (const name of REQUIRED_JOBS) {
    const matches = jobs.filter((job) => job.name === name);
    if (matches.length !== 1 || matches[0].status !== "completed" || matches[0].conclusion !== "success") {
      throw new Error(`${name} must have exactly one completed successful job in the selected attempt`);
    }
  }
  const browserJobs = jobs.filter((job) => job.name === "ecommerce-e2e (advisory)");
  if (browserJobs.length !== 1 || browserJobs[0].status !== "completed" || !["success", "failure"].includes(browserJobs[0].conclusion)) {
    throw new Error("full advisory browser job must have exactly one completed attempt");
  }
  return browserJobs[0];
}

function getJobLog(command, repo, runId, attempt, job) {
  const result = command(GH, ["run", "view", runId, "--attempt", String(attempt), "--job", String(job.id), "--log", "--repo", repo], { maxBuffer: 32 * 1024 * 1024 });
  return commandText(result);
}

function findStep(job, fragment) {
  const steps = Array.isArray(job.steps) ? job.steps : [];
  const matches = steps.filter((step) => typeof step.name === "string" && step.name.includes(fragment));
  if (matches.length !== 1) throw new Error(`selected job must contain exactly one ${fragment} step`);
  return matches[0];
}

function requireArtifact(artifacts, name, run, repo) {
  const matches = artifacts.filter((artifact) => artifact.name === name);
  if (matches.length !== 1 || matches[0].expired !== false) throw new Error(`expected exactly one live ${name} artifact from the selected attempt`);
  const artifact = matches[0];
  if (!/^[1-9][0-9]*$/.test(String(artifact.id || "")) || !/^sha256:[a-f0-9]{64}$/.test(artifact.digest || "")) throw new Error(`${name} lacks an immutable artifact ID or SHA-256 digest`);
  if (String(artifact.workflow_run?.id) !== run.id || artifact.workflow_run?.head_sha !== run.sha || artifact.workflow_run?.head_branch !== run.branch) {
    throw new Error(`${name} artifact belongs to another run/ref/source`);
  }
  const workflowRun = artifact.workflow_run;
  if (repositoryId(workflowRun?.repository_id) !== run.repository_id || repositoryId(workflowRun?.head_repository_id) !== run.head_repository_id) {
    throw new Error(`${name} artifact is not owned by ${repo}`);
  }
  if (workflowRun?.head_repository?.full_name && workflowRun.head_repository.full_name !== repo) throw new Error(`${name} artifact is not owned by ${repo}`);
  return artifact;
}

function downloadArtifact(command, repo, artifact, runDirectory) {
  const result = command(GH, ["api", `repos/${repo}/actions/artifacts/${artifact.id}/zip`], { encoding: null, maxBuffer: MAX_ARCHIVE_BYTES + 1 });
  const bytes = Buffer.isBuffer(result?.stdout) ? result.stdout : Buffer.isBuffer(result) ? result : Buffer.from(String(result?.stdout || ""));
  if (bytes.length === 0 || bytes.length > MAX_ARCHIVE_BYTES) throw new Error(`artifact archive is empty or exceeds the ${MAX_ARCHIVE_BYTES}-byte safety limit`);
  const digest = sha256(bytes);
  if (artifact.digest !== `sha256:${digest}`) throw new Error(`${artifact.name} immutable archive digest does not match downloaded bytes`);
  const archivePath = path.join(runDirectory, `${artifact.name}.zip`);
  fs.writeFileSync(archivePath, bytes, { flag: "wx", mode: 0o600 });
  return { bytes, digest, archivePath };
}

function listArchive(command, archivePath) {
  const result = command("unzip", ["-Z1", archivePath], { maxBuffer: 1024 * 1024 });
  const members = commandText(result).split(/\r?\n/).filter(Boolean);
  if (members.length === 0 || members.length > MAX_ARCHIVE_MEMBERS) throw new Error("artifact archive is empty or exceeds the member-count limit");
  const seen = new Set();
  for (const member of members) {
    const clean = safeRelative(member.replace(/\/$/, "directory"), "archive member path");
    if (clean.endsWith("/directory")) continue;
    if (seen.has(clean)) throw new Error(`artifact archive contains a duplicate member: ${clean}`);
    seen.add(clean);
  }
  return members.filter((member) => !member.endsWith("/"));
}

function logicalArtifactPath(member) {
  const exact = EVIDENCE_FILES.find((file) => member === file || member.endsWith(`/${file}`));
  if (exact) return exact;
  // Hosted uploads wrap the run directory in test-results/docker-full/<run>/,
  // so keep the deepest allowlisted root (for example the inner playwright-report/)
  // rather than treating that outer storage path as the declared artifact path.
  const candidates = ["test-results/", "playwright-report/", "ui-review-artifacts/", "logs/", "compose/"]
    .map((prefix) => ({ prefix, index: member.lastIndexOf(prefix) }))
    .filter(({ index }) => index >= 0)
    .sort((left, right) => right.index - left.index);
  const logical = candidates.length ? member.slice(candidates[0].index) : null;
  if (logical?.split("/").some((segment) => segment.startsWith("."))) return null;
  return logical;
}

function extractBrowserArchive(command, archivePath, runDirectory) {
  fs.mkdirSync(runDirectory, { recursive: false, mode: 0o700 });
  const members = listArchive(command, archivePath);
  const mapped = new Map();
  let total = 0;
  for (const member of members) {
    const logical = logicalArtifactPath(member);
    if (!logical) continue;
    if (!EVIDENCE_FILES.includes(logical) && !["test-results/", "playwright-report/", "ui-review-artifacts/", "logs/", "compose/"].some((prefix) => logical.startsWith(prefix))) continue;
    if (mapped.has(logical)) throw new Error(`browser evidence archive has ambiguous member path ${logical}`);
    const bytesValue = command("unzip", ["-p", archivePath, member], { encoding: null, maxBuffer: MAX_ARCHIVE_MEMBER_BYTES + 1 });
    const bytes = Buffer.isBuffer(bytesValue?.stdout) ? bytesValue.stdout : Buffer.isBuffer(bytesValue) ? bytesValue : Buffer.from(String(bytesValue?.stdout || ""));
    if (bytes.length > MAX_ARCHIVE_MEMBER_BYTES) throw new Error(`browser artifact member exceeds ${MAX_ARCHIVE_MEMBER_BYTES} bytes: ${logical}`);
    total += bytes.length;
    if (total > MAX_ARCHIVE_TOTAL_BYTES) throw new Error("browser evidence archive exceeds the total extracted-size limit");
    const destination = path.join(runDirectory, ...logical.split("/"));
    fs.mkdirSync(path.dirname(destination), { recursive: true, mode: 0o700 });
    fs.writeFileSync(destination, bytes, { flag: "wx", mode: 0o600 });
    mapped.set(logical, bytes);
  }
  for (const required of EVIDENCE_FILES) {
    if (!mapped.has(required)) throw new Error(`browser evidence artifact is missing required member ${required}`);
  }
  return mapped;
}

function validateBrowserArchive(command, archivePath, runDirectory, run, browserJob, artifact, identity, browserValidator) {
  const members = extractBrowserArchive(command, archivePath, runDirectory);
  const evidence = require("./ecommerce_evidence.cjs");
  const validation = browserValidator ? browserValidator(runDirectory, { run, identity, artifact }) : evidence.validateReceipt({ runDir: runDirectory });
  if (!validation.valid || !validation.eligible || !validation.receipt) {
    throw new Error(`authoritative browser aggregate is malformed or ineligible: ${(validation.reasons || []).map((reason) => reason.code).join(", ") || "unknown reason"}`);
  }
  const receipt = validation.receipt;
  const aggregateMember = members.get("phase105-evidence.json");
  const stages = receipt.stages || {};
  const browserStage = stages.browser || {};
  const verifierStep = findStep(browserJob, "Run advisory full E2E proof");
  const uploadStep = findStep(browserJob, "Upload advisory E2E evidence");
  // The Actions jobs REST endpoint exposes `conclusion` on step records, not
  // the workflow expression `outcome` field. Job-level continue-on-error keeps
  // this per-step conclusion available even when the advisory job is green.
  if (verifierStep.status !== "completed" || !["success", "failure"].includes(verifierStep.conclusion)) {
    throw new Error("raw ecommerce verifier step has no completed outcome");
  }
  if ((browserStage.exit_code === 0) !== (verifierStep.conclusion === "success")) {
    throw new Error("raw ecommerce verifier step disagrees with its aggregate exit status");
  }
  if (uploadStep.status !== "completed" || uploadStep.conclusion !== "success") {
    throw new Error("advisory E2E evidence upload step did not complete successfully");
  }
  const jobStarted = browserJob.started_at;
  const jobCompleted = browserJob.completed_at;
  const uploadedAt = uploadStep.completed_at || artifact.created_at;
  const elapsed = (validTimestamp(uploadedAt, "ecommerce-e2e artifact upload") - validTimestamp(jobStarted, "ecommerce-e2e job start")) / 1000;
  const proof = {
    run,
    session: { repository: identity.repo, branch: identity.branch, sha: identity.sha, session_id: identity.sessionId },
    eligible: validation.eligible,
    raw_verifier_outcome: verifierStep.conclusion,
    job_conclusion: browserJob.conclusion,
    job_started_at: jobStarted,
    job_completed_at: jobCompleted,
    uploaded_at: uploadedAt,
    finalization_reserve_seconds: 1800 - elapsed,
    artifact: {
      name: artifact.name,
      digest: artifact.digest,
      archive_sha256: sha256(fs.readFileSync(archivePath)),
      member_sha256: sha256(aggregateMember),
      run_id: run.id,
      attempt: run.attempt,
      source_sha: identity.sha,
    },
    aggregate: {
      valid: validation.valid,
      eligible: validation.eligible,
      repository: receipt.source?.mode === "hosted" ? identity.repo : "",
      source_sha: receipt.sha,
      run_id: String(receipt.run_id),
      attempt: receipt.run_attempt,
      case_count: receipt.tests_total,
      attempts_total: receipt.attempts_total,
      event: receipt.event,
      source: receipt.source,
      images: receipt.images,
    },
    receipt_path: path.join(runDirectory, "phase105-evidence.json"),
    receipt_sha256: sha256(aggregateMember),
  };
  validateBrowserAcceptance(proof);
  return proof;
}

function readJsonMember(command, archivePath, members, expectedName) {
  const candidates = members.filter((member) => member === expectedName || member.endsWith(`/${expectedName}`));
  if (candidates.length !== 1) throw new Error(`artifact must contain exactly one ${expectedName} member`);
  const value = command("unzip", ["-p", archivePath, candidates[0]], { encoding: null, maxBuffer: MAX_ARCHIVE_MEMBER_BYTES + 1 });
  const bytes = Buffer.isBuffer(value?.stdout) ? value.stdout : Buffer.isBuffer(value) ? value : Buffer.from(String(value?.stdout || ""));
  if (!bytes.length || bytes.length > MAX_ARCHIVE_MEMBER_BYTES) throw new Error(`${expectedName} member is empty or oversized`);
  return parseJsonText(bytes.toString("utf8"), expectedName);
}

function selectCacheJob(mode, jobs) {
  const name = mode.startsWith("docker-") ? (mode === "docker-cold" ? "ecommerce-mounted (required)" : "ecommerce-e2e (advisory)") : "core (required)";
  const matches = jobs.filter((job) => job.name === name);
  if (matches.length !== 1) throw new Error(`cache probe requires exactly one ${name} job`);
  return matches[0];
}

function cacheLogForMode(mode, command, repo, run, jobs) {
  const job = selectCacheJob(mode, jobs);
  const raw = getJobLog(command, repo, run.id, run.attempt, job);
  return { job, raw };
}

function validateProbeArtifact(command, repo, artifact, runDirectory, mode, run, session, jobLog, imageHandoff) {
  const { archivePath } = downloadArtifact(command, repo, artifact, runDirectory);
  const members = listArchive(command, archivePath);
  const probe = readJsonMember(command, archivePath, members, "phase182-cache-proof.json");
  if (probe.mode !== mode || probe.repository !== repo || probe.branch !== run.branch || probe.source_sha !== run.sha ||
      String(probe.run_id) !== run.id || Number(probe.run_attempt) !== run.attempt) {
    throw new Error("cache proof artifact identity does not match its selected run/ref/source/mode");
  }
  const cache = { ...probe.cache };
  if (mode.startsWith("docker-")) {
    if (mode === "docker-warm") {
      validateDockerHandoffBindings({ cache, handoff: imageHandoff, mode, sourceSha: run.sha });
    }
    const evidence = parseBuildKitCacheProgress(jobLog, cache.target_scopes, {
      recipe_ids: cache.recipe_ids,
      image_ids: cache.image_ids,
    });
    cache.actual_import = evidence.import_complete;
    cache.actual_export = evidence.export_complete;
    cache.imported_digest = evidence.imported_digest;
    cache.exported_digest = evidence.exported_digest;
    cache.cached_steps_digest = evidence.cached_steps_digest;
    cache.cache_binding_digest = evidence.cache_binding_digest;
    cache.progress = evidence.targets;
  }
  const proof = {
    ...probe,
    run,
    session,
    cache: {
      ...cache,
      log_text: jobLog,
      log_sha256: sha256(jobLog),
    },
    artifact: {
      name: artifact.name,
      digest: artifact.digest,
      archive_sha256: sha256(fs.readFileSync(archivePath)),
      run_id: run.id,
      attempt: run.attempt,
      source_sha: run.sha,
    },
  };
  validateCacheAcceptance(proof);
  return proof;
}

function collectRun(inputFlags, dependencies = {}) {
  const flags = validateFlags(inputFlags);
  const command = dependencies.command || runCommand;
  const invocation = beginInvocation(flags);
  const session = { repository: flags.repo, branch: flags.branch, sha: flags.sha, session_id: flags.sessionId };
  let run = null;
  try {
    command(GH, ["auth", "status"]);
    const ref = apiJson(command, `repos/${flags.repo}/git/ref/heads/${flags.branch}`);
    if (ref.object?.sha !== flags.sha) throw new Error(`candidate branch ${flags.branch} does not point to requested source SHA ${flags.sha}`);
    const beforeIds = new Set(listWorkflowRuns(command, flags.repo, flags.branch).map((item) => String(item.id ?? item.databaseId)));
    const cacheMode = workflowCacheInput(flags.mode);
    const dispatch = ["workflow", "run", "ci.yml", "--ref", flags.branch, "-f", `phase182_cache_mode=${cacheMode}`, "-f", `phase182_probe_namespace=${flags.probeNamespace}`, "--repo", flags.repo];
    command(GH, dispatch);
    run = waitForDispatchedRun(command, flags, beforeIds, dependencies);
    run.previous_attempts = summarizePreviousAttempts(command, flags.repo, run.id, run.attempt);
    const workflow = apiJson(command, `repos/${flags.repo}/actions/workflows/ci.yml`);
    if (workflow.path !== WORKFLOW) throw new Error("selected workflow metadata is not the existing CI workflow");
    const jobs = collectAttemptJobs(command, flags.repo, run.id, run.attempt);
    const browserJob = validateCompletedJobs(jobs);
    const artifacts = flattenPages(apiJson(command, `repos/${flags.repo}/actions/runs/${run.id}/artifacts?per_page=100`, { paginate: true }), "artifacts", "artifact");
    const browserArtifact = requireArtifact(artifacts, `ecommerce-e2e-evidence-${run.id}-${run.attempt}`, run, flags.repo);
    const runDirectory = path.join(invocation.invocationDir, "runs", `${run.id}-attempt-${run.attempt}`);
    fs.mkdirSync(path.dirname(runDirectory), { recursive: true, mode: 0o700 });
    fs.mkdirSync(runDirectory, { recursive: false, mode: 0o700 });
    const browserDownload = downloadArtifact(command, flags.repo, browserArtifact, runDirectory);
    const browserLog = getJobLog(command, flags.repo, run.id, run.attempt, browserJob);
    let imageHandoff = null;
    if (flags.mode === "docker-warm") {
      const browserMembers = listArchive(command, browserDownload.archivePath);
      imageHandoff = readJsonMember(command, browserDownload.archivePath, browserMembers, "image-handoff.json");
    }
    const browser = validateBrowserArchive(command, browserDownload.archivePath, path.join(runDirectory, "browser"), run, browserJob, browserArtifact, flags, dependencies.browserValidator);

    let cache;
    let cacheArtifact;
    if (REQUIRED_CACHE_MODES.includes(flags.mode)) {
      cacheArtifact = requireArtifact(artifacts, `phase182-cache-probe-${flags.mode}-${run.id}-${run.attempt}`, run, flags.repo);
      const { job, raw } = cacheLogForMode(flags.mode, command, flags.repo, run, jobs);
      cache = validateProbeArtifact(command, flags.repo, cacheArtifact, runDirectory, flags.mode, run, session, raw, imageHandoff);
      cache.cache_job = { id: String(job.id), name: job.name, conclusion: job.conclusion };
    }
    const receipt = {
      schema: 1,
      repository: flags.repo,
      branch: flags.branch,
      sha: flags.sha,
      session_id: flags.sessionId,
      mode: flags.mode,
      invocation_id: invocation.entry.invocation_id,
      eligible: browser.eligible === true && (!cache || cache.mode === flags.mode),
      run,
      required_jobs: jobs.filter((job) => REQUIRED_JOBS.includes(job.name)).map((job) => ({ id: String(job.id), name: job.name, status: job.status, conclusion: job.conclusion })),
      browser: {
        eligible: browser.eligible,
        receipt_path: path.relative(flags.outputDir, browser.receipt_path).split(path.sep).join("/"),
        receipt_sha256: browser.receipt_sha256,
        raw_verifier_outcome: browser.raw_verifier_outcome,
        job_conclusion: browser.job_conclusion,
        artifact: { name: browserArtifact.name, digest: browserArtifact.digest, archive_sha256: browser.artifact.archive_sha256 },
        timing: { started_at: browser.job_started_at, completed_at: browser.job_completed_at, uploaded_at: browser.uploaded_at, finalization_reserve_seconds: browser.finalization_reserve_seconds },
        aggregate: browser.aggregate,
        log_sha256: sha256(browserLog),
      },
      ...(cache ? {
        cache: {
          eligible: true,
          mode: flags.mode,
          kind: cache.cache.kind,
          cache: Object.fromEntries(Object.entries(cache.cache).filter(([key]) => key !== "log_text")),
          builder: cache.builder || null,
          normal_command_outcome: cache.normal_command_outcome,
          artifact: { name: cacheArtifact.name, digest: cacheArtifact.digest },
          job: cache.cache_job,
        },
      } : {}),
      collected_at: new Date().toISOString(),
    };
    const finalized = finalizeInvocation(flags, invocation, receipt);
    return { ...finalized, run, browser, cache, runDirectory };
  } catch (error) {
    const failure = {
      schema: 1,
      repository: flags.repo,
      branch: flags.branch,
      sha: flags.sha,
      session_id: flags.sessionId,
      mode: flags.mode,
      invocation_id: invocation.entry.invocation_id,
      eligible: false,
      run,
      error: sanitizedError(error),
      collected_at: new Date().toISOString(),
    };
    finalizeInvocation(flags, invocation, failure);
    throw error;
  }
}

function verifyManifest(flags) {
  const manifestPath = path.join(flags.outputDir, "phase182-session.json");
  if (!fs.existsSync(manifestPath)) throw new Error("candidate session manifest is missing");
  const manifest = parseJsonText(fs.readFileSync(manifestPath, "utf8"), "candidate session manifest");
  const identity = { repository: flags.repo, branch: flags.branch, sha: flags.sha, session_id: flags.sessionId };
  for (const [key, value] of Object.entries(identity)) if (manifest[key] !== value) throw new Error(`candidate session identity mismatch for ${key}`);
  if (manifest.schema !== 1 || !Array.isArray(manifest.invocations)) throw new Error("candidate session manifest is malformed");
  if (manifest.invocations.some((entry) => entry.status === "running")) throw new Error("candidate session has unfinished invocations; reconcile them before acceptance");
  const invocationIds = new Set();
  const receipts = manifest.invocations.map((entry) => {
    if (!entry || typeof entry !== "object" || invocationIds.has(entry.invocation_id)) throw new Error("candidate session has a missing or duplicate invocation ID");
    invocationIds.add(entry.invocation_id);
    return { entry, receipt: readManifestReceipt(flags.outputDir, entry, identity) };
  });
  for (const { entry, receipt } of receipts) {
    if (!entry.invocation_id || !MODES.includes(entry.mode) || !["eligible", "ineligible"].includes(entry.status) ||
        receipt.invocation_id !== entry.invocation_id || receipt.mode !== entry.mode || receipt.eligible !== (entry.status === "eligible")) {
      throw new Error(`candidate invocation ${entry.invocation_id || "<missing>"} does not match its manifest entry`);
    }
    if (receipt.browser) {
      const browserPath = resolveSessionPath(flags.outputDir, receipt.browser.receipt_path, "authoritative browser aggregate path");
      const browserBytes = fs.readFileSync(browserPath);
      if (sha256(browserBytes) !== receipt.browser.receipt_sha256) throw new Error(`candidate invocation ${entry.invocation_id} browser aggregate digest mismatch`);
      const aggregate = parseJsonText(browserBytes.toString("utf8"), "authoritative browser aggregate");
      const aggregateMismatches = [];
      if (String(aggregate.run_id) !== receipt.run?.id) aggregateMismatches.push("run ID");
      if (Number(aggregate.run_attempt) !== receipt.run?.attempt) aggregateMismatches.push("run attempt");
      if (aggregate.sha !== flags.sha) aggregateMismatches.push("source SHA");
      if (aggregate.event !== "workflow_dispatch") aggregateMismatches.push("event");
      if (aggregate.source?.mode !== "hosted" || aggregate.source?.dirty !== false || aggregate.source?.checkout_head !== flags.sha || aggregate.source?.built_source_sha !== flags.sha || aggregate.source?.event_sha !== flags.sha) aggregateMismatches.push("hosted source identity");
      if (aggregate.eligibility?.eligible !== true) aggregateMismatches.push("eligibility");
      if (aggregate.tests_total !== receipt.browser.aggregate?.case_count) aggregateMismatches.push("case count");
      if (aggregate.attempts_total !== receipt.browser.aggregate?.attempts_total) aggregateMismatches.push("attempt count");
      if (aggregateMismatches.length) throw new Error(`candidate invocation ${entry.invocation_id} browser aggregate has mismatched ${aggregateMismatches.join(", ")}`);
    }
  }
  const eligible = receipts.filter(({ entry, receipt }) => entry.status === "eligible" && receipt.eligible === true);
  for (const { entry, receipt } of eligible) {
    if (receipt.browser?.eligible !== true) throw new Error(`eligible invocation ${entry.invocation_id} is missing its authoritative browser aggregate`);
    if (REQUIRED_CACHE_MODES.includes(entry.mode)) {
      const proof = receipt.cache;
      if (!proof?.eligible || proof.mode !== entry.mode) throw new Error(`cache invocation ${entry.invocation_id} has no cache proof`);
    }
  }
  return { manifest, receipts, eligible, identity };
}

function validateAggregate(flags, kind) {
  const session = verifyManifest(flags);
  const expectedPath = path.join(flags.outputDir, kind === "caches" ? "cache-acceptance.json" : "full-acceptance.json");
  if (!fs.existsSync(expectedPath)) throw new Error(`${kind} acceptance aggregate is missing; no stale or synthetic file can satisfy the session`);
  const aggregate = parseJsonText(fs.readFileSync(expectedPath, "utf8"), `${kind} acceptance aggregate`);
  const expectedIdentity = { repository: flags.repo, branch: flags.branch, sha: flags.sha, session_id: flags.sessionId };
  for (const [key, value] of Object.entries(expectedIdentity)) if (aggregate[key] !== value) throw new Error(`${kind} acceptance aggregate has a foreign ${key}`);
  if (aggregate.eligible !== true) throw new Error(`${kind} acceptance aggregate is not eligible`);
  if (kind === "caches") {
    const perMode = Object.fromEntries(REQUIRED_CACHE_MODES.map((mode) => [mode, session.eligible.filter(({ entry }) => entry.mode === mode)]));
    if (REQUIRED_CACHE_MODES.some((mode) => perMode[mode].length === 0 || session.manifest.invocations.filter((entry) => entry.mode === mode).at(-1)?.status !== "eligible")) {
      throw new Error("cache acceptance is missing a latest eligible attempt for one or more required cache modes");
    }
    for (const mode of REQUIRED_CACHE_MODES) {
      const group = aggregate.modes?.[mode];
      const expectedAttempts = session.receipts.filter(({ entry }) => entry.mode === mode).map(({ entry }) => ({
        receipt: entry.receipt,
        status: entry.status,
        run_id: entry.run_id,
        run_attempt: entry.run_attempt,
        receipt_sha256: entry.receipt_sha256,
      }));
      if (!group || !Array.isArray(group.attempts) || canonicalJson(group.attempts) !== canonicalJson(expectedAttempts)) {
        throw new Error(`cache acceptance has incomplete ${mode} attempt history`);
      }
      const acceptedPath = perMode[mode].at(-1).entry.receipt;
      if (group.accepted !== acceptedPath) throw new Error(`cache acceptance selects a receipt not owned by this candidate session for ${mode}`);
    }
    const expectedHistory = session.receipts.map(({ entry }) => ({ mode: entry.mode, status: entry.status, receipt: entry.receipt, run_id: entry.run_id, run_attempt: entry.run_attempt }));
    if (canonicalJson(aggregate.attempt_history) !== canonicalJson(expectedHistory)) throw new Error("cache acceptance has incomplete candidate-session attempt history");
    const expectedBrowserAggregates = [...new Set(session.eligible.map(({ receipt }) => receipt.browser?.receipt_path).filter(Boolean))];
    if (canonicalJson(aggregate.browser_aggregates) !== canonicalJson(expectedBrowserAggregates)) throw new Error("cache acceptance does not reference exactly the session's accepted browser aggregates");
  } else {
    const full = session.eligible.filter(({ entry }) => entry.mode === "full" && entry.receipt.browser?.eligible === true);
    if (!full.length || session.manifest.invocations.filter((entry) => entry.mode === "full").at(-1)?.status !== "eligible" || aggregate.accepted !== full.at(-1).entry.receipt || aggregate.browser_aggregate !== full.at(-1).receipt.browser.receipt_path) {
      throw new Error("full acceptance does not reference an eligible authoritative browser aggregate from this session");
    }
    const expectedAttempts = session.receipts.filter(({ entry }) => entry.mode === "full").map(({ entry }) => ({
      receipt: entry.receipt,
      status: entry.status,
      run_id: entry.run_id,
      run_attempt: entry.run_attempt,
      receipt_sha256: entry.receipt_sha256,
    }));
    if (canonicalJson(aggregate.attempts) !== canonicalJson(expectedAttempts)) throw new Error("full acceptance has incomplete candidate-session attempt history");
  }
  return { valid: true, eligible: true, kind, repository: flags.repo, branch: flags.branch, sha: flags.sha, session_id: flags.sessionId, invocation_count: session.receipts.length };
}

function parseArgs(argv) {
  const positional = [];
  const flags = {};
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith("--")) { positional.push(token); continue; }
    const name = token.slice(2);
    if (Object.hasOwn(flags, name)) throw new Error(`option --${name} must be supplied once`);
    const value = argv[index + 1];
    if (!value || value.startsWith("--")) throw new Error(`option --${name} requires a value`);
    flags[name] = value;
    index += 1;
  }
  return { positional, flags };
}

function toFlags(flags) {
  return {
    repo: flags.repo,
    branch: flags.branch,
    sha: flags.sha,
    sessionId: flags["session-id"],
    mode: flags.mode,
    probeNamespace: flags["probe-namespace"],
    outputDir: flags["output-dir"],
  };
}

function help() {
  process.stdout.write("Usage:\n");
  process.stdout.write("  node scripts/ci/phase182_acceptance.cjs run --mode docker-warm|docker-cold|beam-fallback|beam-lock-change|beam-cold|full --branch BRANCH --sha SHA --session-id SESSION --output-dir DIR [--repo OWNER/REPO] [--probe-namespace SLUG]\n");
  process.stdout.write("  node scripts/ci/phase182_acceptance.cjs validate --mode caches|full --input SESSION_ROOT --repo OWNER/REPO --branch BRANCH --sha SHA --session-id SESSION\n");
  process.stdout.write("  node scripts/ci/phase182_acceptance.cjs validate-inputs --output GITHUB_OUTPUT\n");
  process.stdout.write("  node scripts/ci/phase182_acceptance.cjs prepare-lock --output GITHUB_OUTPUT\n");
  process.stdout.write("  node scripts/ci/phase182_acceptance.cjs beam-plan --graph root --root DIR --output FILE\n");
  process.stdout.write("  node scripts/ci/phase182_acceptance.cjs configure-docker --manifest FILE\n");
  process.stdout.write("  node scripts/ci/phase182_acceptance.cjs write-docker-proof --manifest FILE --output FILE\n");
  process.stdout.write("  node scripts/ci/phase182_acceptance.cjs write-beam-proof --plan FILE --output FILE [--lock-manifest FILE]\n");
}

function main(argv = process.argv.slice(2)) {
  try {
    const { positional, flags } = parseArgs(argv);
    const commandName = positional[0];
    if (commandName === "help" || commandName === undefined || commandName === "--help") { help(); return 0; }
    if (commandName === "validate-inputs") {
      const result = validateWorkflowInputs({
        mode: process.env.PHASE182_CACHE_MODE || "normal",
        namespace: process.env.PHASE182_PROBE_NAMESPACE || "",
        outputPath: flags.output || process.env.GITHUB_OUTPUT,
      });
      process.stdout.write(`${JSON.stringify(result)}\n`);
      return 0;
    }
    if (commandName === "prepare-lock") {
      const prepared = prepareLockProbe({
        workspace: process.env.GITHUB_WORKSPACE || REPOSITORY_ROOT,
        runnerTemp: process.env.RUNNER_TEMP || os.tmpdir(),
        runId: process.env.GITHUB_RUN_ID,
        attempt: process.env.GITHUB_RUN_ATTEMPT,
        sourceSha: process.env.GITHUB_SHA,
      });
      appendWorkflowOutputs(flags.output || process.env.GITHUB_OUTPUT, {
        beam_root: prepared.workdir,
        lock_manifest: prepared.manifestPath,
      });
      process.stdout.write(`${JSON.stringify({ beam_root: prepared.workdir, lock_manifest: prepared.manifestPath })}\n`);
      return 0;
    }
    if (commandName === "beam-plan") {
      if (flags.graph !== "root" || !flags.root || !flags.output) throw new Error("beam-plan requires --graph root, --root DIR and --output FILE");
      const rawPlan = beamCache.buildPlan({ graph: flags.graph, root: flags.root });
      const plan = beamPlanForProbe(rawPlan, {
        mode: process.env.PHASE182_CACHE_MODE || "normal",
        namespace: process.env.PHASE182_PROBE_NAMESPACE || "",
        runId: process.env.GITHUB_RUN_ID,
        attempt: process.env.GITHUB_RUN_ATTEMPT,
      });
      if (plan.probe.mode === "beam-lock-change") {
        plan.paths.resolved = plan.paths.resolved.map((relativePath) => path.resolve(flags.root, relativePath));
      }
      beamCache.writePlan(flags.output, plan);
      beamCache.appendGithubOutputs(flags["output-github"] || process.env.GITHUB_OUTPUT, plan);
      process.stdout.write(`BEAM cache probe plan written: mode=${plan.probe.mode} namespace=${plan.probe.namespace || "production"}\n`);
      return 0;
    }
    if (commandName === "configure-docker") {
      if (!flags.manifest) throw new Error("configure-docker requires --manifest FILE");
      const result = configureDockerBake({
        manifestPath: flags.manifest,
        mode: process.env.PHASE182_CACHE_MODE || "normal",
        namespace: process.env.PHASE182_PROBE_NAMESPACE || "",
      });
      process.stdout.write(`Docker cache policy configured: scope=${result.manifest.scope} namespace=${result.namespace || "production"} mode=${result.mode}\n`);
      return 0;
    }
    if (commandName === "write-docker-proof") {
      if (!flags.manifest || !flags.output) throw new Error("write-docker-proof requires --manifest FILE and --output FILE");
      writeDockerProbeProof({
        manifestPath: flags.manifest,
        outputPath: flags.output,
        baselinePath: flags.baseline || "",
        inspectPath: flags.inspect || "",
      });
      return 0;
    }
    if (commandName === "write-beam-proof") {
      if (!flags.plan || !flags.output) throw new Error("write-beam-proof requires --plan FILE and --output FILE");
      writeBeamProbeProof({ planPath: flags.plan, outputPath: flags.output, lockManifestPath: flags["lock-manifest"] || process.env.PHASE182_LOCK_PROBE_MANIFEST || "" });
      return 0;
    }
    if (commandName === "run") {
      const parsed = toFlags(flags);
      if (!parsed.repo) {
        const repoOutput = runCommand(GH, ["repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"]);
        parsed.repo = commandText(repoOutput).trim();
      }
      const result = collectRun(parsed);
      process.stdout.write(`${JSON.stringify({ eligible: true, mode: parsed.mode, run: result.run, receipt: result.receiptPath }, null, 2)}\n`);
      return 0;
    }
    if (commandName === "validate") {
      const kind = flags.mode;
      if (!["caches", "full"].includes(kind)) throw new Error("validate --mode must be caches or full");
      const inputFlags = {
        repo: flags.repo,
        branch: flags.branch,
        sha: flags.sha,
        sessionId: flags["session-id"],
        outputDir: flags.input,
        mode: "full",
      };
      const validated = validateFlags({ ...inputFlags, probeNamespace: "" }, { createOutput: false });
      const result = validateAggregate(validated, kind);
      process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
      return 0;
    }
    throw new Error(`unknown command ${commandName}`);
  } catch (error) {
    process.stderr.write(`${sanitizedError(error)}\n`);
    return 1;
  }
}

if (require.main === module) process.exitCode = main();

module.exports = {
  REQUIRED_CACHE_MODES,
  beamPlanForProbe,
  collectRun,
  configureDockerBake,
  parseBuildKitCacheProgress,
  prepareLockProbe,
  validateAggregate,
  validateBrowserAcceptance,
  validateCacheAcceptance,
  validateDispatchCacheMode,
  validateDockerHandoffBindings,
  validateFlags,
  validateProbeNamespace,
  validateWorkflowInputs,
  writeBeamProbeProof,
  writeDockerProbeProof,
};
