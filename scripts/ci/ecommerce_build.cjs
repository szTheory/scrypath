"use strict";

const crypto = require("node:crypto");
const { execFileSync, spawnSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const repositoryRoot = path.resolve(__dirname, "../..");
const exampleRoot = path.join(repositoryRoot, "examples/scrypath_ecommerce");
const revisionLabel = "org.opencontainers.image.revision";
const fingerprintLabel = "org.opencontainers.image.source-fingerprint";

function canonicalize(value) {
  if (Array.isArray(value)) return value.map(canonicalize);
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.keys(value).sort().map((key) => [key, canonicalize(value[key])]),
    );
  }
  return value;
}

function canonicalJson(value) {
  return JSON.stringify(canonicalize(value));
}

function digest(value) {
  return `sha256:${crypto.createHash("sha256").update(value).digest("hex")}`;
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd || repositoryRoot,
    env: options.env || process.env,
    encoding: "utf8",
    timeout: options.timeout || 120_000,
    maxBuffer: 32 * 1024 * 1024,
  });
  if (result.error) throw new Error(`${command} failed: ${result.error.message}`);
  if (result.status !== 0) {
    const detail = (result.stderr || result.stdout || "").trim();
    throw new Error(`${command} ${args.join(" ")} exited ${result.status}${detail ? `: ${detail}` : ""}`);
  }
  return result.stdout.trimEnd();
}

function sourceFingerprint(root = repositoryRoot) {
  const status = execFileSync("git", ["status", "--porcelain", "--untracked-files=all"], {
    cwd: root,
    encoding: "utf8",
  });
  if (!status.trim()) return "";

  const files = execFileSync("git", ["ls-files", "-co", "--exclude-standard", "-z"], {
    cwd: root,
    encoding: "buffer",
  });
  const hashes = spawnSync("xargs", ["-0", "shasum", "-a", "256"], {
    cwd: root,
    input: files,
    encoding: "buffer",
    maxBuffer: 32 * 1024 * 1024,
  });
  if (hashes.error) throw new Error(`source fingerprint failed: ${hashes.error.message}`);
  if (hashes.status !== 0) throw new Error(`source fingerprint failed with exit ${hashes.status}`);
  return digest(hashes.stdout);
}

function validateScope(scope) {
  if (scope !== "focused" && scope !== "full") {
    throw new Error("scope must be focused or full");
  }
}

function validateProject(project) {
  if (typeof project !== "string" || !/^[a-z0-9][a-z0-9_-]{0,62}$/.test(project)) {
    throw new Error("E2E_PROJECT_NAME must be a lowercase Compose project name");
  }
}

function composeArgs(scope, project, withOverride = false, overridePath = "") {
  validateScope(scope);
  validateProject(project);
  const args = ["compose", "-p", project, "-f", path.join(exampleRoot, "compose.yaml"), "-f", path.join(exampleRoot, "compose.e2e.yaml")];
  if (scope === "full") args.push("-f", path.join(exampleRoot, "compose.phase173.yaml"));
  if (withOverride) args.push("-f", overridePath);
  return args;
}

function recipeOptions(target) {
  const normalized = structuredClone(target);
  delete normalized.tags;
  delete normalized.output;
  delete normalized["cache-from"];
  delete normalized["cache-to"];
  if (normalized.context) {
    const relativeContext = path.relative(repositoryRoot, normalized.context);
    normalized.context = relativeContext || ".";
  }
  if (normalized.dockerfile) {
    normalized.dockerfile = path.relative(normalized.context === "." ? repositoryRoot : path.resolve(repositoryRoot, normalized.context), normalized.dockerfile);
  }
  if (normalized.labels) {
    delete normalized.labels["com.docker.compose.project"];
    delete normalized.labels[revisionLabel];
    delete normalized.labels[fingerprintLabel];
  }
  return normalized;
}

function cacheScopeFor(service) {
  if (service === "web") return "scrypath-ecommerce-app-v1";
  if (service === "browser") return "scrypath-ecommerce-browser-v1";
  if (service === "standalone_ops") return "scrypath-ecommerce-standalone-ops-v1";
  const slug = service.toLowerCase().replace(/[^a-z0-9_-]+/g, "-").replace(/^-+|-+$/g, "");
  if (!slug) throw new Error(`cannot make a stable cache scope for Compose service ${service}`);
  return `scrypath-ecommerce-${slug}-v1`;
}

function resolveBuild(scope, project, env = process.env, runCommand = run) {
  const args = composeArgs(scope, project);
  const callOptions = {
    cwd: repositoryRoot,
    env,
    timeout: Math.min(120_000, Number(env.E2E_DOCKER_TIMEOUT_SECONDS || 120) * 1000),
  };
  const modelText = runCommand("docker", [...args, "config", "--format", "json"], callOptions);
  const bakeText = runCommand("docker", [...args, "build", "--print"], callOptions);
  let model;
  let bake;
  try {
    model = JSON.parse(modelText);
    bake = JSON.parse(bakeText);
  } catch (error) {
    throw new Error(`Compose could not resolve its model and Bake graph: ${error.message}`);
  }

  const services = Object.entries(model.services || {})
    .filter(([, service]) => service.build)
    .map(([name]) => name)
    .sort();
  const targets = bake.target || {};
  if (!services.length || services.length !== Object.keys(targets).length || services.some((name) => !targets[name])) {
    throw new Error("Compose service build graph does not match the generated Bake targets");
  }

  const sourceSha = runCommand("git", ["rev-parse", "HEAD"], { cwd: repositoryRoot, env }).trim();
  if (env.SCRYPATH_SOURCE_SHA && env.SCRYPATH_SOURCE_SHA !== sourceSha) {
    throw new Error("SCRYPATH_SOURCE_SHA does not match the checkout HEAD");
  }
  const fingerprint = sourceFingerprint(repositoryRoot);
  if (env.E2E_SOURCE_FINGERPRINT !== undefined && env.E2E_SOURCE_FINGERPRINT !== fingerprint) {
    throw new Error("E2E_SOURCE_FINGERPRINT does not match the checkout contents");
  }

  const tags = {};
  const cacheScopes = {};
  const recipeIds = {};
  const scopeOwners = new Map();
  for (const service of services) {
    const target = targets[service];
    if (!target.context || !target.dockerfile) throw new Error(`Bake target ${service} is missing its Compose build context`);
    const localTag = `${project}-${service}`;
    if (localTag.length > 128) throw new Error(`generated local image tag is too long for ${service}`);
    tags[service] = localTag;
    target.tags = [localTag];
    target.output = ["type=docker"];
    target.labels = { ...(target.labels || {}), [revisionLabel]: sourceSha };
    if (fingerprint) target.labels[fingerprintLabel] = fingerprint;
    else delete target.labels[fingerprintLabel];

    const recipeId = digest(canonicalJson(recipeOptions(target)));
    const cacheScope = cacheScopeFor(service);
    const priorRecipe = scopeOwners.get(cacheScope);
    if (priorRecipe && priorRecipe !== recipeId) {
      throw new Error(`distinct Compose recipes collide on cache scope ${cacheScope}`);
    }
    scopeOwners.set(cacheScope, recipeId);
    recipeIds[service] = recipeId;
    cacheScopes[service] = cacheScope;
  }

  const recipeDigest = digest(canonicalJson(recipeIds));
  bake.group = { ...(bake.group || {}), default: { targets: services } };
  return {
    model,
    bake,
    services,
    sourceSha,
    sourceFingerprint: fingerprint,
    modelDigest: digest(canonicalJson(model)),
    recipeDigest,
    tags,
    cacheScopes,
  };
}

function writeJson(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const temporaryFile = `${file}.${process.pid}.tmp`;
  fs.writeFileSync(temporaryFile, `${JSON.stringify(value, null, 2)}\n`, { mode: 0o600 });
  fs.renameSync(temporaryFile, file);
}

function prepareBuild({ scope, output, env = process.env, runCommand = run, project = env.E2E_PROJECT_NAME } = {}) {
  validateScope(scope);
  if (!output) throw new Error("--output DIR is required");
  if (!project) throw new Error("E2E_PROJECT_NAME is required for a checked prebuilt handoff");
  const outputDirectory = path.resolve(output);
  const resolved = resolveBuild(scope, project, env, runCommand);
  const overridePath = path.join(outputDirectory, "image-override.json");
  const manifestPath = path.join(outputDirectory, "image-handoff.json");
  const override = {
    services: Object.fromEntries(Object.entries(resolved.tags).map(([service, image]) => [service, { image }])),
  };
  const manifest = {
    schema_version: 1,
    project,
    scope,
    source_sha: resolved.sourceSha,
    source_fingerprint: resolved.sourceFingerprint || null,
    model_digest: resolved.modelDigest,
    recipe_digest: resolved.recipeDigest,
    tags: resolved.tags,
    image_ids: {},
    builder_id: env.BUILDER_ID || null,
    cache_scopes: resolved.cacheScopes,
    import_status: "not_configured",
    export_status: "not_configured",
    override_path: overridePath,
  };
  writeJson(path.join(outputDirectory, "resolved-compose.json"), resolved.model);
  writeJson(path.join(outputDirectory, "bake.json"), resolved.bake);
  writeJson(overridePath, override);
  writeJson(manifestPath, manifest);
  return { outputDirectory, manifestPath, overridePath, manifest };
}

function inspectJson(runCommand, kind, value, env) {
  const args = kind === "image"
    ? ["image", "inspect", "--format", "{{json .}}", value]
    : ["inspect", "--format", "{{json .}}", value];
  try {
    return JSON.parse(runCommand("docker", args, { cwd: repositoryRoot, env }));
  } catch (error) {
    throw new Error(`could not inspect ${kind} ${value}: ${error.message}`);
  }
}

function verifyHandoff({ manifestPath, runtime = false, env = process.env, runCommand = run } = {}) {
  if (!manifestPath) throw new Error("--manifest FILE is required");
  const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  const project = env.E2E_PROJECT_NAME;
  const scope = env.E2E_SCOPE;
  if (manifest.schema_version !== 1) throw new Error("unsupported image handoff schema version");
  if (manifest.project !== project || manifest.scope !== scope) throw new Error("image handoff project or scope mismatch");
  if (!project || !scope) throw new Error("E2E_PROJECT_NAME and E2E_SCOPE are required for prebuilt verification");

  const resolved = resolveBuild(scope, project, env, runCommand);
  if (manifest.source_sha !== resolved.sourceSha || manifest.source_fingerprint !== (resolved.sourceFingerprint || null)) {
    throw new Error("image handoff source SHA or fingerprint mismatch");
  }
  if (manifest.model_digest !== resolved.modelDigest || manifest.recipe_digest !== resolved.recipeDigest) {
    throw new Error("image handoff Compose model or recipe digest mismatch");
  }
  if (canonicalJson(manifest.tags) !== canonicalJson(resolved.tags) || canonicalJson(manifest.cache_scopes) !== canonicalJson(resolved.cacheScopes)) {
    throw new Error("image handoff tags or cache scopes mismatch");
  }

  const overridePath = env.E2E_IMAGE_OVERRIDE || manifest.override_path;
  if (!overridePath || path.resolve(overridePath) !== path.resolve(manifest.override_path)) {
    throw new Error("E2E_IMAGE_OVERRIDE does not match the generated image override");
  }
  const override = JSON.parse(fs.readFileSync(overridePath, "utf8"));
  const expectedOverride = {
    services: Object.fromEntries(Object.entries(resolved.tags).map(([service, image]) => [service, { image }])),
  };
  if (canonicalJson(override) !== canonicalJson(expectedOverride)) throw new Error("image override tag mapping mismatch");

  if (!runtime) {
    const imageIds = {};
    for (const [service, tag] of Object.entries(resolved.tags)) {
      const image = inspectJson(runCommand, "image", tag, env);
      const labels = image.Config?.Labels || {};
      if (!image.Id || !image.RepoTags?.includes(tag)) throw new Error(`local image tag is missing: ${tag}`);
      if (labels[revisionLabel] !== resolved.sourceSha) throw new Error(`local image source SHA mismatch: ${service}`);
      if ((resolved.sourceFingerprint && labels[fingerprintLabel] !== resolved.sourceFingerprint) || (!resolved.sourceFingerprint && labels[fingerprintLabel])) {
        throw new Error(`local image source fingerprint mismatch: ${service}`);
      }
      imageIds[service] = image.Id;
    }
    manifest.image_ids = imageIds;
    manifest.handoff_status = "loaded";
  } else {
    if (!manifest.image_ids || Object.keys(manifest.image_ids).length !== resolved.services.length) {
      throw new Error("image handoff has no complete local image ID set");
    }
    const runtimeIds = {};
    const compose = composeArgs(scope, project, true, overridePath);
    for (const service of resolved.services) {
      const containers = runCommand("docker", [...compose, "ps", "-aq", service], {
        cwd: repositoryRoot,
        env,
        timeout: Math.min(120_000, Number(env.E2E_DOCKER_TIMEOUT_SECONDS || 120) * 1000),
      }).split(/\s+/).filter(Boolean);
      if (containers.length !== 1) throw new Error(`expected one runtime container for ${service}, found ${containers.length}`);
      const container = inspectJson(runCommand, "container", containers[0], env);
      if (container.Image !== manifest.image_ids[service]) throw new Error(`runtime image ID mismatch: ${service}`);
      runtimeIds[service] = container.Image;
    }
    manifest.runtime_image_ids = runtimeIds;
    manifest.handoff_status = "runtime_verified";
  }
  writeJson(manifestPath, manifest);
  return manifest;
}

function parseOptions(args) {
  const options = {};
  for (let index = 0; index < args.length; index += 1) {
    const key = args[index];
    if (key === "--runtime") options.runtime = true;
    else if (key.startsWith("--")) {
      const value = args[index + 1];
      if (!value || value.startsWith("--")) throw new Error(`${key} requires a value`);
      options[key.slice(2)] = value;
      index += 1;
    } else throw new Error(`unexpected argument: ${key}`);
  }
  return options;
}

function main(argv) {
  const [command, ...args] = argv;
  if (command === "fingerprint") {
    process.stdout.write(`${sourceFingerprint()}\n`);
    return;
  }
  const options = parseOptions(args);
  if (command === "prepare") {
    const result = prepareBuild({ scope: options.scope, output: options.output });
    process.stdout.write(`${JSON.stringify(result.manifest)}\n`);
    return;
  }
  if (command === "verify-handoff") {
    const manifest = verifyHandoff({ manifestPath: options.manifest, runtime: options.runtime });
    process.stdout.write(`${JSON.stringify(manifest)}\n`);
    return;
  }
  throw new Error("usage: ecommerce_build.cjs fingerprint | prepare --scope focused|full --output DIR | verify-handoff --manifest FILE [--runtime]");
}

if (require.main === module) {
  try {
    main(process.argv.slice(2));
  } catch (error) {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 1;
  }
}

module.exports = { prepareBuild, verifyHandoff };
