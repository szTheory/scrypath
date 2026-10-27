#!/usr/bin/env node

"use strict";

const crypto = require("node:crypto");
const { execFileSync } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const CACHE_SCHEMA = "beam-v1";
const repositoryRoot = path.resolve(__dirname, "../..");

const graphs = {
  root: {
    manifests: ["mix.exs"],
    locks: ["mix.lock"],
    sourceRoots: ["lib", "test", "config", "priv"],
    resolvedPaths: ["deps", "_build/test"]
  },
  ops: {
    manifests: ["mix.exs", "scrypath_ops/mix.exs"],
    locks: ["mix.lock", "scrypath_ops/mix.lock"],
    sourceRoots: ["lib", "test", "config", "priv", "scrypath_ops/lib", "scrypath_ops/test", "scrypath_ops/config", "scrypath_ops/priv"],
    resolvedPaths: ["deps", "_build/test", "scrypath_ops/deps", "scrypath_ops/_build/test"]
  },
  ecommerce: {
    manifests: ["mix.exs", "scrypath_ops/mix.exs", "examples/scrypath_ecommerce/mix.exs"],
    locks: ["mix.lock", "scrypath_ops/mix.lock", "examples/scrypath_ecommerce/mix.lock"],
    sourceRoots: ["lib", "test", "config", "priv", "scrypath_ops/lib", "scrypath_ops/test", "scrypath_ops/config", "scrypath_ops/priv", "examples/scrypath_ecommerce/lib", "examples/scrypath_ecommerce/test", "examples/scrypath_ecommerce/config", "examples/scrypath_ecommerce/priv"],
    resolvedPaths: ["deps", "_build/test"]
  },
  "phoenix-example": {
    manifests: ["mix.exs", "examples/phoenix_meilisearch/mix.exs"],
    locks: ["mix.lock", "examples/phoenix_meilisearch/mix.lock"],
    sourceRoots: ["lib", "test", "config", "priv", "examples/phoenix_meilisearch/lib", "examples/phoenix_meilisearch/test", "examples/phoenix_meilisearch/config", "examples/phoenix_meilisearch/priv"],
    resolvedPaths: ["deps", "_build/test", "examples/phoenix_meilisearch/deps", "examples/phoenix_meilisearch/_build/test"]
  }
};

const identityFields = [
  "graph",
  "runner_image",
  "os",
  "arch",
  "elixir",
  "otp",
  "mix_env",
  "mix_target",
  "profile",
  "manifests_digest",
  "locks_digest",
  "source_digest"
];

function sha256(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function requireText(name, value) {
  if (typeof value !== "string" || value.trim() === "" || /[\r\n\0]/.test(value)) {
    throw new Error(`missing or invalid ${name}`);
  }
  return value.trim();
}

function requireDigest(name, value) {
  if (typeof value !== "string" || !/^[a-f0-9]{64}$/.test(value)) {
    throw new Error(`missing or invalid ${name}; expected a lowercase SHA-256 digest`);
  }
  return value;
}

function cacheIdentity(input) {
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    throw new Error("cache identity inputs must be an object");
  }

  const graph = requireText("graph", input.graph);
  if (!Object.hasOwn(graphs, graph)) throw new Error(`unsupported graph: ${graph}`);

  return {
    cache_schema: CACHE_SCHEMA,
    graph,
    runner_image: requireText("runner_image", input.runner_image),
    os: requireText("os", input.os),
    arch: requireText("arch", input.arch),
    elixir: requireText("elixir", input.elixir),
    otp: requireText("otp", input.otp),
    mix_env: requireText("mix_env", input.mix_env),
    mix_target: requireText("mix_target", input.mix_target),
    profile: requireText("profile", input.profile),
    manifests_digest: requireDigest("manifests_digest", input.manifests_digest),
    locks_digest: requireDigest("locks_digest", input.locks_digest),
    source_digest: requireDigest("source_digest", input.source_digest)
  };
}

function cachePlan(identityInput) {
  const identity = cacheIdentity(identityInput);
  const compatibility = {
    cache_schema: identity.cache_schema,
    graph: identity.graph,
    runner_image: identity.runner_image,
    os: identity.os,
    arch: identity.arch,
    elixir: identity.elixir,
    otp: identity.otp,
    mix_env: identity.mix_env,
    mix_target: identity.mix_target,
    profile: identity.profile,
    manifests_digest: identity.manifests_digest
  };
  const compatibleDigest = sha256(JSON.stringify(compatibility));
  const downloadPrefix = `beam-v1-downloads-${compatibleDigest}-`;
  const resolvedPrefix = `beam-v1-resolved-${compatibleDigest}-${identity.locks_digest}-`;
  const graph = graphs[identity.graph];

  return {
    identity,
    downloads_key: `${downloadPrefix}${identity.locks_digest}`,
    downloads_restore_prefix: downloadPrefix,
    resolved_key: `${resolvedPrefix}${identity.source_digest}`,
    resolved_restore_prefix: resolvedPrefix,
    plt_key: `beam-v1-plts-${compatibleDigest}-${identity.locks_digest}-${identity.source_digest}`,
    paths: {
      downloads: ["~/.hex/packages"],
      resolved: [...graph.resolvedPaths],
      plt: identity.graph === "root" ? ["priv/plts"] : []
    }
  };
}

function runtimeIdentity(env, elixirVersionOutput) {
  const imageOs = requireText("ImageOS", env.ImageOS);
  const imageVersion = requireText("ImageVersion", env.ImageVersion);
  const elixirOutput = elixirVersionOutput ?? execFileSync("elixir", ["--version"], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"]
  });
  const elixir = elixirOutput.match(/^Elixir\s+([^\s]+)/m)?.[1];
  const otp = elixirOutput.match(/^(Erlang\/OTP\s+[^\r\n]+)$/m)?.[1];

  return {
    runner_image: `${imageOs}/${imageVersion}`,
    os: requireText("RUNNER_OS", env.RUNNER_OS),
    arch: requireText("RUNNER_ARCH", env.RUNNER_ARCH),
    elixir: requireText("resolved Elixir version", elixir),
    otp: requireText("resolved OTP runtime", otp),
    mix_env: requireText("MIX_ENV", env.MIX_ENV),
    mix_target: requireText("MIX_TARGET", env.MIX_TARGET),
    profile: requireText("BEAM_CACHE_PROFILE", env.BEAM_CACHE_PROFILE)
  };
}

function assertInsideRoot(root, relativePath) {
  const absolute = path.resolve(root, relativePath);
  if (absolute !== root && !absolute.startsWith(`${root}${path.sep}`)) {
    throw new Error(`cache input escaped repository root: ${relativePath}`);
  }
  return absolute;
}

function hashPaths(rootInput, relativePaths) {
  const root = path.resolve(rootInput);
  const hash = crypto.createHash("sha256");

  for (const relativePath of [...relativePaths].sort()) {
    const absolute = assertInsideRoot(root, relativePath);
    const stat = fs.lstatSync(absolute);
    hash.update(relativePath).update("\0");
    if (stat.isSymbolicLink()) {
      hash.update("symlink:").update(fs.readlinkSync(absolute));
    } else if (stat.isFile()) {
      hash.update(fs.readFileSync(absolute));
    } else {
      throw new Error(`cache input is not a file: ${relativePath}`);
    }
    hash.update("\0");
  }

  return hash.digest("hex");
}

function collectSourceFiles(rootInput, graphName) {
  const root = path.resolve(rootInput);
  const graph = graphs[graphName];
  if (!graph) throw new Error(`unsupported graph: ${graphName}`);
  const files = [];

  function visit(relativePath) {
    const absolute = assertInsideRoot(root, relativePath);
    const stat = fs.lstatSync(absolute);
    if (stat.isSymbolicLink() || stat.isFile()) {
      if (!/(^|\/)priv\/plts(?:\/|$)/.test(relativePath)) files.push(relativePath);
      return;
    }
    if (!stat.isDirectory()) return;
    for (const entry of fs.readdirSync(absolute).sort()) {
      visit(path.posix.join(relativePath.split(path.sep).join("/"), entry));
    }
  }

  for (const sourceRoot of graph.sourceRoots) {
    const absolute = assertInsideRoot(root, sourceRoot);
    if (fs.existsSync(absolute)) visit(sourceRoot);
  }

  if (files.length === 0) throw new Error(`graph ${graphName} has no source files to fingerprint`);
  return files.sort();
}

function buildPlan({ graph, root = repositoryRoot, env = process.env, elixirVersionOutput } = {}) {
  const graphName = requireText("graph", graph);
  const graphConfig = graphs[graphName];
  if (!graphConfig) throw new Error(`unsupported graph: ${graphName}`);
  const runtime = runtimeIdentity(env, elixirVersionOutput);
  const sourceFiles = collectSourceFiles(root, graphName);
  const identity = cacheIdentity({
    graph: graphName,
    ...runtime,
    manifests_digest: hashPaths(root, graphConfig.manifests),
    locks_digest: hashPaths(root, graphConfig.locks),
    source_digest: hashPaths(root, sourceFiles)
  });

  return { ...cachePlan(identity), source_files: sourceFiles };
}

function writePlan(outputPath, plan) {
  const absolute = path.resolve(outputPath);
  fs.mkdirSync(path.dirname(absolute), { recursive: true });
  const temporary = `${absolute}.${process.pid}.tmp`;
  fs.writeFileSync(temporary, `${JSON.stringify(plan, null, 2)}${os.EOL}`, { mode: 0o600 });
  fs.renameSync(temporary, absolute);
}

function appendGithubOutputs(outputPath, plan) {
  if (!outputPath) return;
  const scalarOutputs = {
    downloads_key: plan.downloads_key,
    downloads_restore_prefix: plan.downloads_restore_prefix,
    resolved_key: plan.resolved_key,
    resolved_restore_prefix: plan.resolved_restore_prefix,
    plt_key: plan.plt_key
  };
  let contents = "";
  for (const [name, value] of Object.entries(scalarOutputs)) {
    contents += `${name}=${value}\n`;
  }
  for (const [name, value] of Object.entries(plan.paths)) {
    const delimiter = `BEAM_CACHE_${name.toUpperCase()}_${crypto.randomBytes(8).toString("hex")}`;
    contents += `${name}_paths<<${delimiter}\n${value.join("\n")}\n${delimiter}\n`;
  }
  fs.appendFileSync(outputPath, contents, { mode: 0o600 });
}

function parsePlanArgs(argv) {
  if (argv[0] !== "plan") throw new Error("usage: beam_cache.cjs plan --graph <name> --output <file>");
  const options = {};
  for (let index = 1; index < argv.length; index += 1) {
    const option = argv[index];
    if (!["--graph", "--output"].includes(option) || !argv[index + 1]) {
      throw new Error(`unexpected or incomplete option: ${option}`);
    }
    options[option.slice(2)] = argv[++index];
  }
  if (!options.graph || !options.output) {
    throw new Error("both --graph and --output are required");
  }
  return options;
}

function main(argv = process.argv.slice(2)) {
  try {
    const options = parsePlanArgs(argv);
    const plan = buildPlan({ graph: options.graph });
    writePlan(options.output, plan);
    appendGithubOutputs(process.env.GITHUB_OUTPUT, plan);
    process.stdout.write(`BEAM cache plan written: graph=${plan.identity.graph} schema=${plan.identity.cache_schema}\n`);
  } catch (error) {
    process.stderr.write(`beam_cache: ${error.message}\n`);
    return 1;
  }
  return 0;
}

if (require.main === module) process.exitCode = main();

module.exports = { CACHE_SCHEMA, buildPlan, cacheIdentity, cachePlan, collectSourceFiles, hashPaths, runtimeIdentity, writePlan, appendGithubOutputs };
