"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const { execFileSync, spawnSync } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { Worker } = require("node:worker_threads");

const {
  REQUIRED_CACHE_MODES,
  beamPlanForProbe,
  collectRun,
  configureDockerBake,
  parseBuildKitCacheProgress,
  prepareLockProbe,
  validateAggregate,
  validateBrowserAcceptance,
  validateCacheAcceptance,
  validateFlags,
  validateDockerHandoffBindings,
  validateWorkflowInputs,
  writeBeamProbeProof,
  writeDockerProbeProof,
} = require("./phase182_acceptance.cjs");
const { applyCacheProbeToBake, cacheProbeFor } = require("./ecommerce_build.cjs");

const { cachePlan } = require("./beam_cache.cjs");

const SHA = "0123456789abcdef0123456789abcdef01234567";
const OTHER_SHA = "fedcba9876543210fedcba9876543210fedcba98";
const REPOSITORY = "szTheory/scrypath";
const BRANCH = "candidate/phase182";
const SESSION_ID = "candidate-run-01";
const STARTED = "2026-10-26T12:00:00Z";
const COMPLETED = "2026-10-26T12:10:00Z";
const FULL_DOCKER_SCOPES = {
  browser: "scrypath-ecommerce-browser-v1",
  standalone_ops: "scrypath-ecommerce-standalone-ops-v1",
  web: "scrypath-ecommerce-app-v1",
};

function buildKitCacheLog(targetScopes = FULL_DOCKER_SCOPES) {
  const lines = [];
  let vertex = 1;
  for (const service of Object.keys(targetScopes).sort()) {
    lines.push(`#${vertex} [${service}] importing cache manifest from gha`);
    lines.push(`#${vertex} DONE 0.4s`);
    vertex += 1;
  }
  for (const service of Object.keys(targetScopes).sort()) {
    lines.push(`#${vertex} [${service} 3/6] COPY mix.exs mix.exs`);
    lines.push(`#${vertex} CACHED`);
    vertex += 1;
  }
  for (const service of Object.keys(targetScopes).sort()) {
    lines.push(`#${vertex} [${service}] exporting to GitHub Actions Cache`);
    lines.push(`#${vertex} preparing build cache for export`);
    lines.push(`#${vertex} writing cache image manifest`);
    lines.push(`#${vertex} DONE 1.2s`);
    vertex += 1;
  }
  return lines.join("\n");
}

function refreshDockerEvidence(proof, logText) {
  const evidence = parseBuildKitCacheProgress(logText, proof.cache.target_scopes, {
    recipe_ids: proof.cache.recipe_ids,
    image_ids: proof.cache.image_ids,
  });
  proof.cache.log_text = logText;
  proof.cache.log_sha256 = crypto.createHash("sha256").update(logText).digest("hex");
  proof.cache.actual_import = evidence.import_complete;
  proof.cache.actual_export = evidence.export_complete;
  proof.cache.imported_digest = evidence.imported_digest;
  proof.cache.exported_digest = evidence.exported_digest;
  proof.cache.cached_steps_digest = evidence.cached_steps_digest;
  proof.cache.cache_binding_digest = evidence.cache_binding_digest;
  proof.cache.progress = evidence.targets;
  return proof;
}

function dockerRecipeBindings(targetScopes) {
  const recipeIds = Object.fromEntries(Object.keys(targetScopes).sort().map((service, index) => [
    service,
    `sha256:${String(index + 1).repeat(64)}`,
  ]));
  const imageIds = Object.fromEntries(Object.keys(targetScopes).sort().map((service, index) => [
    service,
    `sha256:${String(index + 4).repeat(64)}`,
  ]));
  return {
    recipeIds,
    imageIds,
    recipeDigest: `sha256:${crypto.createHash("sha256").update(JSON.stringify(recipeIds)).digest("hex")}`,
  };
}

function exactRun(overrides = {}) {
  return {
    id: "12345",
    attempt: 1,
    repository: REPOSITORY,
    branch: BRANCH,
    sha: SHA,
    event: "workflow_dispatch",
    workflow: ".github/workflows/ci.yml",
    status: "completed",
    conclusion: "success",
    started_at: STARTED,
    completed_at: COMPLETED,
    previous_attempts: [],
    ...overrides,
  };
}

function browserProof(overrides = {}) {
  return {
    run: exactRun(),
    session: { repository: REPOSITORY, branch: BRANCH, sha: SHA, session_id: SESSION_ID },
    raw_verifier_outcome: "success",
    job_conclusion: "success",
    job_started_at: STARTED,
    job_completed_at: COMPLETED,
    uploaded_at: "2026-10-26T12:10:10Z",
    artifact: {
      name: "ecommerce-e2e-evidence-12345-1",
      digest: `sha256:${"a".repeat(64)}`,
      archive_sha256: "a".repeat(64),
      member_sha256: "b".repeat(64),
      run_id: "12345",
      attempt: 1,
      source_sha: SHA,
    },
    aggregate: {
      valid: true,
      eligible: true,
      repository: REPOSITORY,
      source_sha: SHA,
      run_id: "12345",
      attempt: 1,
      case_count: 8,
      attempts_total: 8,
      event: "workflow_dispatch",
      workflow: { ref: `refs/heads/${BRANCH}` },
      source: { mode: "hosted", dirty: false, checkout_head: SHA, built_source_sha: SHA, event_sha: SHA },
      images: {
        application: { built_id: `sha256:${"1".repeat(64)}`, runtime_id: `sha256:${"1".repeat(64)}`, source_sha: SHA },
        browser: { built_id: `sha256:${"2".repeat(64)}`, runtime_id: `sha256:${"2".repeat(64)}`, source_sha: SHA },
      },
    },
    finalization_reserve_seconds: 1190,
    ...overrides,
  };
}

function cacheProof(mode, overrides = {}) {
  const isDocker = mode.startsWith("docker-");
  const cold = mode === "docker-cold" || mode === "beam-cold";
  const run = overrides.run || exactRun();
  const namespace = overrides.session?.probe_namespace || "";
  const runtime = { runner_image: "ubuntu24/20261019.1.0", elixir: "1.19.0", otp: "Erlang/OTP 28.1", os: "Linux", arch: "X64", mix_env: "test", mix_target: "host", profile: "root-test" };
  const plan = beamPlanForProbe(cachePlan({ ...runtime, graph: "root", manifests_digest: "a".repeat(64), locks_digest: "d".repeat(64), source_digest: "f".repeat(64) }), {
    mode: isDocker ? "normal" : mode, namespace, runId: run.id, attempt: run.attempt,
  });
  const downloadsKey = plan.downloads_key;
  const downloadsRestoreKey = mode === "beam-cold" ? null : `${plan.downloads_restore_prefix}${"c".repeat(64)}`;
  const resolvedKey = plan.resolved_key;
  const logText = mode === "docker-warm"
    ? `Run mix verify.ecommerce_e2e\n${buildKitCacheLog()}\n`
    : mode === "beam-cold"
      ? "Run mix deps.get\nRun mix compile\nRun mix verify.core\n"
      : mode.startsWith("beam-")
        ? `Run mix deps.get\nRun mix compile\nRun mix verify.core\nCache restored from key: ${downloadsRestoreKey}\nCache not found for input keys: ${resolvedKey}\n`
        : "Run mix verify.ecommerce_mounted\nfresh builder; imports disabled\n";
  const targetScopes = mode === "docker-warm" ? { ...FULL_DOCKER_SCOPES } : {
    browser: "scrypath-ecommerce-browser-v1",
    web: "scrypath-ecommerce-app-v1",
  };
  if (namespace && mode === "docker-warm") {
    for (const service of Object.keys(targetScopes)) targetScopes[service] += `-phase182-${namespace}`;
  }
  const targetCacheSettings = Object.fromEntries(Object.entries(targetScopes).map(([service, scope]) => [service, {
    import: mode === "docker-warm" ? [`type=gha,scope=${scope},version=2,timeout=120s`] : [],
    export: mode === "docker-warm" ? [`type=gha,scope=${scope},version=2,mode=max,timeout=120s`] : [],
  }]));
  const recipeBindings = dockerRecipeBindings(targetScopes);
  const dockerEvidence = isDocker && mode === "docker-warm"
    ? parseBuildKitCacheProgress(logText, targetScopes, {
      recipe_ids: recipeBindings.recipeIds,
      image_ids: recipeBindings.imageIds,
    })
    : null;
  return {
    mode,
    run,
    repository: REPOSITORY,
    branch: BRANCH,
    source_sha: SHA,
    run_id: run.id,
    run_attempt: run.attempt,
    session: { repository: REPOSITORY, branch: BRANCH, sha: SHA, session_id: SESSION_ID },
    artifact: {
      name: `phase182-cache-probe-${mode}-${run.id}-${run.attempt}`,
      digest: `sha256:${"c".repeat(64)}`,
      archive_sha256: "c".repeat(64),
      run_id: run.id,
      attempt: run.attempt,
      source_sha: SHA,
    },
    builder: {
      id: `builder-${mode}-12345-1`,
      created_for_run_id: run.id,
      created_for_attempt: run.attempt,
      created_at: run.started_at,
      driver: "docker-container",
      cache_from: cold ? [] : ["type=gha,scope=scrypath-probe"],
      fresh: cold,
      persistent: false,
    },
    cache: {
      kind: isDocker ? "buildkit" : "beam",
      imports_enabled: !cold,
      actual_import: dockerEvidence ? dockerEvidence.import_complete : false,
      actual_export: dockerEvidence ? dockerEvidence.export_complete : false,
      imported_digest: dockerEvidence?.imported_digest || null,
      exported_digest: dockerEvidence?.exported_digest || null,
      cached_steps_digest: dockerEvidence?.cached_steps_digest || null,
      cache_binding_digest: dockerEvidence?.cache_binding_digest || null,
      progress: dockerEvidence?.targets || null,
      importer: mode === "docker-warm" ? "gha" : null,
      exporter: mode === "docker-warm" ? "gha" : null,
      scope: mode === "docker-warm" ? "full" : "focused",
      expected_targets: Object.keys(targetScopes).sort(),
      target_scopes: targetScopes,
      target_cache_settings: targetCacheSettings,
      recipe_digest: recipeBindings.recipeDigest,
      recipe_ids: recipeBindings.recipeIds,
      image_ids: recipeBindings.imageIds,
      import_scopes: mode === "docker-warm" ? Object.values(targetScopes).sort() : [],
      export_scopes: mode === "docker-warm" ? Object.values(targetScopes).sort() : [],
      log_sha256: crypto.createHash("sha256").update(logText).digest("hex"),
      log_text: logText,
      cache_key: `${mode}-resolved-key`,
      restore_prefix: `${mode}-restore-`,
      hit: !cold,
      miss_reason: cold ? "cache import disabled" : null,
      fallback: mode === "beam-fallback" || mode === "beam-lock-change",
      resolved_lock_before: mode === "beam-lock-change" ? "d".repeat(64) : "d".repeat(64),
      resolved_lock_after: mode === "beam-lock-change" ? "e".repeat(64) : "d".repeat(64),
      runtime,
      identity: plan.identity,
      downloads_hit: false,
      downloads_restored: mode === "beam-fallback" || mode === "beam-lock-change",
      resolved_hit: !cold && mode !== "beam-fallback" && mode !== "beam-lock-change",
      resolved_primary_hit: mode !== "beam-cold" && mode !== "beam-fallback" && mode !== "beam-lock-change",
      downloads_key: downloadsKey,
      resolved_key: resolvedKey,
      downloads_restore_prefix: plan.downloads_restore_prefix,
      downloads_restore_key: downloadsRestoreKey,
      resolved_restore_prefix: plan.resolved_restore_prefix,
      resolved_restore_key: null,
      resolved_lock_before: "d".repeat(64),
      resolved_lock_after: mode === "beam-lock-change" ? "e".repeat(64) : "d".repeat(64),
      log_text: logText,
    },
    runner: { fresh: true, id: "GitHub Actions 12345/1", created_for_run_id: run.id, created_for_attempt: run.attempt },
    normal_command_outcome: "success",
    commands: { deps_get: "success", compile: "success", verify: "success", primary_verification: "success" },
    ...(mode === "beam-lock-change" ? { lock_probe: { owned_copy: true, source_lock_unchanged: true, versions_unchanged: true } } : {}),
    job_conclusion: "success",
    ...overrides,
  };
}

test("validateBrowserAcceptance rejects a workflow ref from another branch", () => {
  const proof = browserProof();
  proof.aggregate.workflow.ref = "refs/heads/stale-candidate";
  assert.throws(() => validateBrowserAcceptance(proof), /workflow ref/);
});

test("validateBrowserAcceptance accepts one exact-source, eligible aggregate with raw success", () => {
  assert.equal(validateBrowserAcceptance(browserProof()), true);
});

test("browser acceptance rejects an unrelated run even when its conclusion is green", () => {
  assert.throws(
    () => validateBrowserAcceptance(browserProof({ run: exactRun({ sha: OTHER_SHA }) })),
    /source SHA/,
  );
});

test("browser acceptance rejects raw verifier failure hidden by an advisory green conclusion", () => {
  assert.throws(
    () => validateBrowserAcceptance(browserProof({ raw_verifier_outcome: "failure" })),
    /raw verifier outcome/,
  );
  assert.throws(
    () => validateBrowserAcceptance(browserProof({ job_conclusion: "failure" })),
    /job did not conclude successfully/,
  );
});

test("browser acceptance rejects incomplete aggregate, wrong digest and over-budget timing", () => {
  assert.throws(
    () => validateBrowserAcceptance(browserProof({ aggregate: { valid: true, eligible: false } })),
    /aggregate/,
  );
  assert.throws(
    () => validateBrowserAcceptance(browserProof({ artifact: { ...browserProof().artifact, digest: `sha256:${"0".repeat(64)}` } })),
    /archive digest/,
  );
  assert.throws(
    () => validateBrowserAcceptance(browserProof({ job_completed_at: "2026-10-26T12:31:00Z", uploaded_at: "2026-10-26T12:30:10Z" })),
    /1800 seconds/,
  );
  assert.throws(
    () => validateBrowserAcceptance(browserProof({ aggregate: { ...browserProof().aggregate, case_count: 0 } })),
    /zero or malformed cases/,
  );
  assert.throws(
    () => validateBrowserAcceptance(browserProof({ run: exactRun({ previous_attempts: [{ attempt: 1, conclusion: "failure" }], attempt: 3 }) })),
    /previous attempt history is incomplete/,
  );
});

test("cache acceptance rejects keys and scopes from a different requested namespace", () => {
  for (const mode of ["docker-warm", "beam-fallback", "beam-lock-change", "beam-cold"]) {
    const proof = cacheProof(mode);
    proof.session.probe_namespace = "isolated-candidate";
    assert.throws(() => validateCacheAcceptance(proof), /requested.*namespace|namespace.*requested/);
    const isolated = cacheProof(mode, { session: { ...proof.session } });
    assert.equal(validateCacheAcceptance(isolated), true);
    isolated.session.probe_namespace = "";
    assert.throws(() => validateCacheAcceptance(isolated), /requested.*namespace|namespace.*requested/);
  }
});

test("cold cache acceptance requires a new builder and disabled imports", () => {
  assert.equal(validateCacheAcceptance(cacheProof("docker-cold")), true);
  assert.throws(
    () => validateCacheAcceptance(cacheProof("docker-cold", {
      builder: { ...cacheProof("docker-cold").builder, persistent: true },
    })),
    /fresh builder/,
  );
  assert.throws(
    () => validateCacheAcceptance(cacheProof("beam-cold", {
      cache: { ...cacheProof("beam-cold").cache, imports_enabled: true },
    })),
    /imports must be disabled/,
  );
});

test("warm and fallback cache claims require actual import/export log evidence and normal commands", () => {
  assert.equal(validateCacheAcceptance(cacheProof("docker-warm")), true);
  assert.equal(validateCacheAcceptance(cacheProof("beam-fallback")), true);
  assert.throws(
    () => validateCacheAcceptance(cacheProof("docker-warm", {
      cache: { ...cacheProof("docker-warm").cache, actual_import: false },
    })),
    /actual GHA import/,
  );
  assert.throws(
    () => validateCacheAcceptance(cacheProof("beam-lock-change", {
      normal_command_outcome: "failure",
    })),
    /normal verification command/,
  );
  const missingLog = cacheProof("docker-warm");
  refreshDockerEvidence(missingLog, "Run mix verify.ecommerce_e2e\nexporting to GitHub Actions Cache\n");
  assert.throws(() => validateCacheAcceptance(missingLog), /actual GHA import and export/);
  assert.throws(() => validateCacheAcceptance(cacheProof("beam-lock-change", {
    lock_probe: { owned_copy: true, source_lock_unchanged: false, versions_unchanged: true },
  })), /byte-changed lock miss/);
});

test("BuildKit cache acceptance requires per-target imports, useful cache hits, and completed exports", () => {
  const validLog = buildKitCacheLog();
  const warm = cacheProof("docker-warm");
  assert.equal(validateCacheAcceptance(warm), true);

  const missingTarget = cacheProof("docker-warm");
  refreshDockerEvidence(missingTarget, validLog.replace(/#\d+ \[standalone_ops\] importing cache manifest from gha\n#\d+ DONE 0\.4s\n/, ""));
  assert.throws(() => validateCacheAcceptance(missingTarget), /actual GHA import and export/);

  const missingDone = cacheProof("docker-warm");
  refreshDockerEvidence(missingDone, validLog.replace(/(#\d+ \[web\] exporting to GitHub Actions Cache\n(?:#\d+ .*\n)*?)#(\d+) DONE 1\.2s/, "$1#$2 ERROR: cache exporter failed"));
  assert.throws(() => validateCacheAcceptance(missingDone), /actual GHA import and export/);

  const missingCachedStep = cacheProof("docker-warm");
  refreshDockerEvidence(missingCachedStep, validLog.replace(/#\d+ \[browser 3\/6\] COPY mix\.exs mix\.exs\n#\d+ CACHED\n/, ""));
  assert.throws(() => validateCacheAcceptance(missingCachedStep), /actual GHA import and export/);

  const ignoredExporter = cacheProof("docker-warm");
  refreshDockerEvidence(ignoredExporter, `${validLog}\nWARNING: cache exporter failed and was ignored`);
  assert.throws(() => validateCacheAcceptance(ignoredExporter), /actual GHA import and export/);

  const genericExporter = cacheProof("docker-warm");
  refreshDockerEvidence(genericExporter, validLog.replace(/#\d+ \[web\] exporting to GitHub Actions Cache/, "#99 exporting to GitHub Actions Cache"));
  assert.throws(() => validateCacheAcceptance(genericExporter), /actual GHA import and export/);

  const forgedMapping = cacheProof("docker-warm");
  forgedMapping.cache.target_scopes.web = forgedMapping.cache.target_scopes.browser;
  assert.throws(() => validateCacheAcceptance(forgedMapping), /requested probe namespace/);

  const statusOnly = cacheProof("docker-warm");
  refreshDockerEvidence(statusOnly, "BuildKit cache importer: gha\nBuildKit cache exporter: gha\n");
  statusOnly.cache.actual_import = true;
  statusOnly.cache.actual_export = true;
  assert.throws(() => validateCacheAcceptance(statusOnly), /actual GHA import and export/);
});

test("BuildKit attributes deduplicated cached vertices only to identical recipe and image outputs", () => {
  const proof = cacheProof("docker-warm");
  const recipeIds = { ...proof.cache.recipe_ids, web: proof.cache.recipe_ids.standalone_ops };
  const imageIds = { ...proof.cache.image_ids, web: proof.cache.image_ids.standalone_ops };
  proof.cache.recipe_ids = recipeIds;
  proof.cache.image_ids = imageIds;
  proof.cache.recipe_digest = `sha256:${crypto.createHash("sha256").update(JSON.stringify(recipeIds)).digest("hex")}`;
  const sharedLog = buildKitCacheLog().replace(/^#\d+ \[web 3\/6\] COPY mix\.exs mix\.exs\n#\d+ CACHED\n/m, "");
  refreshDockerEvidence(proof, sharedLog);

  assert.equal(proof.cache.actual_import, true);
  assert.equal(proof.cache.actual_export, true);
  assert.deepEqual(proof.cache.progress.web.cached_steps, []);
  assert.deepEqual(proof.cache.progress.web.shared_cached_steps, [{
    from: "standalone_ops",
    steps: proof.cache.progress.standalone_ops.cached_steps,
  }]);
  assert.equal(validateCacheAcceptance(proof), true);

  const unrelatedRecipe = cacheProof("docker-warm");
  refreshDockerEvidence(unrelatedRecipe, sharedLog);
  assert.equal(unrelatedRecipe.cache.actual_import, false);
  assert.throws(() => validateCacheAcceptance(unrelatedRecipe), /actual GHA import and export/);

  const differentImage = cacheProof("docker-warm");
  const distinctRecipes = { ...differentImage.cache.recipe_ids, web: differentImage.cache.recipe_ids.standalone_ops };
  differentImage.cache.recipe_ids = distinctRecipes;
  differentImage.cache.recipe_digest = `sha256:${crypto.createHash("sha256").update(JSON.stringify(distinctRecipes)).digest("hex")}`;
  refreshDockerEvidence(differentImage, sharedLog);
  assert.equal(differentImage.cache.actual_import, false);
  assert.throws(() => validateCacheAcceptance(differentImage), /actual GHA import and export/);

  const sharedFailure = buildKitCacheLog().replace(/#\d+ DONE 1\.2s/, "#99 ERROR: cache exporter failed");
  const failedProof = cacheProof("docker-warm");
  failedProof.cache.recipe_ids = recipeIds;
  failedProof.cache.image_ids = imageIds;
  failedProof.cache.recipe_digest = proof.cache.recipe_digest;
  refreshDockerEvidence(failedProof, sharedFailure.replace(/^#\d+ \[web 3\/6\] COPY mix\.exs mix\.exs\n#\d+ CACHED\n/m, ""));
  assert.equal(failedProof.cache.actual_export, false);
  assert.throws(() => validateCacheAcceptance(failedProof), /actual GHA import and export/);
});

test("BuildKit rejects malformed recipe bindings and malformed progress as cache proof", () => {
  const malformedBinding = cacheProof("docker-warm");
  malformedBinding.cache.recipe_ids.web = "sha256:not-a-digest";
  assert.throws(() => validateCacheAcceptance(malformedBinding), /invalid recipe or image identity/);

  const mismatchedDigest = cacheProof("docker-warm");
  mismatchedDigest.cache.recipe_digest = `sha256:${"0".repeat(64)}`;
  assert.throws(() => validateCacheAcceptance(mismatchedDigest), /recipe digest/);

  const malformedProgress = parseBuildKitCacheProgress(
    "#x [web 1/3] COPY mix.exs mix.exs\n#x CACHED\n#not-a-vertex DONE 0.1s",
    FULL_DOCKER_SCOPES,
    { recipe_ids: dockerRecipeBindings(FULL_DOCKER_SCOPES).recipeIds, image_ids: dockerRecipeBindings(FULL_DOCKER_SCOPES).imageIds },
  );
  assert.equal(malformedProgress.import_complete, false);
  assert.equal(malformedProgress.export_complete, false);
  assert.equal(malformedProgress.cached_steps_digest, null);
});

test("warm cache bindings join the exact full image handoff identities", () => {
  const cache = cacheProof("docker-warm").cache;
  const handoff = {
    schema_version: 1,
    scope: "full",
    source_sha: SHA,
    cache_probe: { mode: "normal", namespace: "candidate-7" },
    handoff_status: "runtime_verified",
    cache_action_outcome: "success",
    cache_handoff_outcome: "success",
    import_status: "completed",
    export_status: "completed",
    cache_scopes: cache.target_scopes,
    recipe_digest: cache.recipe_digest,
    recipe_ids: cache.recipe_ids,
    image_ids: cache.image_ids,
    runtime_image_ids: cache.image_ids,
  };
  assert.equal(validateDockerHandoffBindings({ cache, handoff, mode: "docker-warm", sourceSha: SHA }), true);
  assert.throws(() => validateDockerHandoffBindings({
    cache,
    handoff: { ...handoff, image_ids: { ...handoff.image_ids, web: `sha256:${"e".repeat(64)}` } },
    mode: "docker-warm",
    sourceSha: SHA,
  }), /recipe or image identities differ/);
});

test("BuildKit cache acceptance parses GitHub CLI job log prefixes without changing raw evidence", () => {
  const lines = buildKitCacheLog().split("\n");
  const githubLog = lines.map((line, index) =>
    `ecommerce-e2e (advisory)\tBake and load checked full images\t${index === 0 ? "\uFEFF" : ""}2026-10-27T09:24:18.5308241Z ${line}`,
  ).join("\n");
  const proof = cacheProof("docker-warm");
  refreshDockerEvidence(proof, githubLog);

  assert.equal(proof.cache.actual_import, true);
  assert.equal(proof.cache.actual_export, true);
  assert.equal(proof.cache.log_sha256, crypto.createHash("sha256").update(githubLog).digest("hex"));
  assert.equal(validateCacheAcceptance(proof), true);
});

test("Docker cache proof binds every checked Bake target to its manifest scope", (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-checked-bake-proof-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const manifestPath = path.join(root, "image-handoff.json");
  const outputPath = path.join(root, "phase182-cache-proof.json");
  const targetCacheSettings = Object.fromEntries(Object.entries(FULL_DOCKER_SCOPES).map(([service, scope]) => [service, {
    "cache-from": [`type=gha,scope=${scope},version=2,timeout=120s`],
    "cache-to": [`type=gha,scope=${scope},version=2,mode=max,timeout=120s`],
  }]));
  const recipeBindings = dockerRecipeBindings(FULL_DOCKER_SCOPES);
  fs.writeFileSync(manifestPath, JSON.stringify({
    scope: "full",
    tags: { browser: "test-browser", standalone_ops: "test-ops", web: "test-web" },
    recipe_digest: recipeBindings.recipeDigest,
    recipe_ids: recipeBindings.recipeIds,
    image_ids: recipeBindings.imageIds,
    cache_scopes: FULL_DOCKER_SCOPES,
    cache_policy: { import: true, export: true },
  }));
  fs.writeFileSync(path.join(root, "bake.json"), JSON.stringify({ target: targetCacheSettings }));
  const env = {
    PHASE182_CACHE_MODE: "normal",
    GITHUB_RUN_ID: "12345",
    GITHUB_RUN_ATTEMPT: "1",
    GITHUB_REPOSITORY: REPOSITORY,
    GITHUB_REF_NAME: BRANCH,
    GITHUB_SHA: SHA,
    PRIMARY_VERIFICATION_OUTCOME: "success",
  };

  const proof = writeDockerProbeProof({ manifestPath, outputPath, env });
  assert.deepEqual(proof.cache.target_scopes, FULL_DOCKER_SCOPES);
  assert.deepEqual(Object.keys(proof.cache.target_cache_settings).sort(), Object.keys(FULL_DOCKER_SCOPES).sort());
  assert.deepEqual(proof.cache.recipe_ids, recipeBindings.recipeIds);
  assert.deepEqual(proof.cache.image_ids, recipeBindings.imageIds);
  assert.equal(JSON.parse(fs.readFileSync(outputPath, "utf8")).cache.target_scopes.web, FULL_DOCKER_SCOPES.web);

  const forgedManifest = { ...JSON.parse(fs.readFileSync(manifestPath, "utf8")), cache_scopes: { ...FULL_DOCKER_SCOPES, web: "scrypath-forged-v1" } };
  fs.writeFileSync(manifestPath, JSON.stringify(forgedManifest));
  assert.throws(() => writeDockerProbeProof({ manifestPath, outputPath, env }), /Bake settings do not match the checked scope/);
});

test("required cache modes are exact and ordered", () => {
  assert.deepEqual(REQUIRED_CACHE_MODES, [
    "docker-warm",
    "docker-cold",
    "beam-fallback",
    "beam-lock-change",
    "beam-cold",
  ]);
});

test("CI exposes bounded opt-in phase182 cache probe inputs", () => {
  const workflow = fs.readFileSync(path.join(__dirname, "../../.github/workflows/ci.yml"), "utf8");
  assert.match(workflow, /workflow_dispatch:\n\s+inputs:\n/);
  assert.match(workflow, /phase182_cache_mode:\n\s+description: [^\n]+\n\s+type: choice\n\s+default: normal\n\s+options:\n(?:\s+- [^\n]+\n){5}/);
  assert.match(workflow, /phase182_probe_namespace:\n\s+description: [^\n]+\n\s+type: string\n\s+default: ""/);
  for (const mode of ["normal", "docker-cold", "beam-cold", "beam-fallback", "beam-lock-change"]) {
    assert.match(workflow, new RegExp(`^\\s+- ${mode.replaceAll("-", "\\-")}\\s*$`, "m"));
  }
  const coreStart = workflow.indexOf("  core:\n");
  const coreEnd = workflow.indexOf("\n  package:\n", coreStart);
  const coreJob = workflow.slice(coreStart, coreEnd < 0 ? undefined : coreEnd);
  assert.ok(coreJob.includes("PHASE182_CACHE_MODE: ${{ steps.phase182_inputs.outputs.beam_mode }}"));
  assert.ok(coreJob.includes("PHASE182_PROBE_NAMESPACE: ${{ steps.phase182_inputs.outputs.beam_namespace }}"));
  for (const jobName of ["ecommerce-mounted", "ecommerce-e2e"]) {
    const job = workflow.match(new RegExp(`  ${jobName}:[\\s\\S]*?(?=\\n  [a-zA-Z0-9_-]+:\\n|$)`))?.[0] || "";
    const beamPlanStart = job.indexOf("- id: beam_cache");
    const beamPlanEnd = job.indexOf("\n      - ", beamPlanStart + 1);
    const beamPlan = job.slice(beamPlanStart, beamPlanEnd < 0 ? undefined : beamPlanEnd);
    assert.match(beamPlan, /PHASE182_CACHE_MODE: normal/);
    assert.match(beamPlan, /PHASE182_PROBE_NAMESPACE: ""/);
    assert.doesNotMatch(job.slice(0, job.indexOf("    steps:")), /PHASE182_CACHE_MODE:|PHASE182_PROBE_NAMESPACE:/);
    const dockerJob = jobName === "ecommerce-mounted" ? "mounted" : "full";
    assert.ok(job.includes("PHASE182_CACHE_MODE: ${{ steps.phase182_inputs.outputs." + dockerJob + "_docker_mode }}"));
    assert.ok(job.includes("PHASE182_PROBE_NAMESPACE: ${{ steps.phase182_inputs.outputs." + dockerJob + "_docker_namespace }}"));
    const verifyStepName = `- name: Verify ${dockerJob} image handoff`;
    const verifyStepStart = job.indexOf(verifyStepName);
    assert.notEqual(verifyStepStart, -1, `${jobName} must verify its checked image handoff`);
    const verifyStepEnd = job.indexOf("\n      - ", verifyStepStart + verifyStepName.length);
    const verifyStep = job.slice(verifyStepStart, verifyStepEnd < 0 ? undefined : verifyStepEnd);
    const runStepName = jobName === "ecommerce-mounted"
      ? "- name: Run mounted E2E proof"
      : "- name: Run advisory full E2E proof";
    const runStepStart = job.indexOf(runStepName);
    assert.notEqual(runStepStart, -1, `${jobName} must run its ordinary E2E verification`);
    const runStepEnd = job.indexOf("\n      - ", runStepStart + runStepName.length);
    const runStep = job.slice(runStepStart, runStepEnd < 0 ? undefined : runStepEnd);
    for (const [stepName, step] of [["handoff", verifyStep], ["E2E verification", runStep]]) {
      assert.match(step, new RegExp(`PHASE182_CACHE_MODE: \\x24\\{\\{ steps\\.phase182_inputs\\.outputs\\.${dockerJob}_docker_mode \\}\\}`), `${jobName} ${stepName} must retain the resolved Docker mode`);
      assert.match(step, new RegExp(`PHASE182_PROBE_NAMESPACE: \\x24\\{\\{ steps\\.phase182_inputs\\.outputs\\.${dockerJob}_docker_namespace \\}\\}`), `${jobName} ${stepName} must retain the resolved Docker namespace`);
    }
  }
});

test("acceptance help and contributor runbook require a session root and exact identity", () => {
  const help = execFileSync(process.execPath, [path.join(__dirname, "phase182_acceptance.cjs"), "help"], { encoding: "utf8" });
  const guide = fs.readFileSync(path.join(__dirname, "../../CONTRIBUTING.md"), "utf8");
  assert.match(help, /validate --mode caches\|full --input SESSION_ROOT --repo OWNER\/REPO --branch BRANCH --sha SHA --session-id SESSION/);
  assert.match(guide, /validate \\\n\s+--mode caches --repo "\$repo" --branch "\$branch" --sha "\$sha" \\\n\s+--session-id "\$session" --input "\$root"/);
  assert.match(guide, /validate \\\n\s+--mode full --repo "\$repo" --branch "\$branch" --sha "\$sha" \\\n\s+--session-id "\$session" --input "\$root"/);
});

test("validate CLI forwards the requested namespace to session identity checks", (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-validate-namespace-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  fs.writeFileSync(path.join(root, "phase182-session.json"), JSON.stringify({
    schema: 1, repository: REPOSITORY, branch: BRANCH, sha: SHA, session_id: SESSION_ID,
    probe_namespace: "isolated", invocations: [],
  }));
  const result = spawnSync(process.execPath, [path.join(__dirname, "phase182_acceptance.cjs"),
    "validate", "--mode", "full", "--input", root, "--repo", REPOSITORY, "--branch", BRANCH,
    "--sha", SHA, "--session-id", SESSION_ID, "--probe-namespace", "isolated",
  ], { encoding: "utf8" });
  assert.equal(result.status, 1);
  assert.match(result.stderr, /full acceptance aggregate is missing/);
  assert.doesNotMatch(result.stderr, /identity mismatch/);
});

test("workflow input validation writes only bounded mode and namespace outputs", (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-inputs-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const outputPath = path.join(root, "github-output.txt");
  const result = validateWorkflowInputs({ mode: "beam-fallback", namespace: "candidate-7", outputPath });
  assert.deepEqual(result, {
    mode: "beam-fallback",
    namespace: "candidate-7",
    beam_mode: "beam-fallback",
    beam_namespace: "candidate-7",
    mounted_docker_mode: "normal",
    mounted_docker_namespace: "",
    full_docker_mode: "normal",
    full_docker_namespace: "",
  });
  assert.match(fs.readFileSync(outputPath, "utf8"), /^mode=beam-fallback\nproof_mode=beam-fallback\nnamespace=candidate-7\nbeam_mode=beam-fallback\nbeam_namespace=candidate-7\nmounted_docker_mode=normal\nmounted_docker_namespace=\nfull_docker_mode=normal\nfull_docker_namespace=\n$/);
  assert.deepEqual(validateWorkflowInputs({ mode: "docker-cold", namespace: "cold-7" }), {
    mode: "docker-cold",
    namespace: "cold-7",
    beam_mode: "normal",
    beam_namespace: "",
    mounted_docker_mode: "docker-cold",
    mounted_docker_namespace: "",
    full_docker_mode: "normal",
    full_docker_namespace: "",
  });
  assert.deepEqual(validateWorkflowInputs({ mode: "normal", namespace: "warm-7" }), {
    mode: "normal",
    namespace: "warm-7",
    beam_mode: "normal",
    beam_namespace: "warm-7",
    mounted_docker_mode: "normal",
    mounted_docker_namespace: "warm-7",
    full_docker_mode: "normal",
    full_docker_namespace: "warm-7",
  });
  for (const mode of ["beam-cold", "beam-fallback", "beam-lock-change"]) {
    assert.deepEqual(validateWorkflowInputs({ mode, namespace: "candidate-7" }), {
      mode,
      namespace: "candidate-7",
      beam_mode: mode,
      beam_namespace: "candidate-7",
      mounted_docker_mode: "normal",
      mounted_docker_namespace: "",
      full_docker_mode: "normal",
      full_docker_namespace: "",
    });
  }
  assert.throws(() => validateWorkflowInputs({ mode: "beam-fallback;touch-pwned", namespace: "" }), /cache mode/);
  assert.throws(() => validateWorkflowInputs({ mode: "beam-fallback", namespace: "candidate\nkey=override" }), /lowercase slug/);
});

test("BEAM probe keys preserve normal keys and isolate forced fallback misses", () => {
  const plan = {
    identity: { locks_digest: "d".repeat(64), source_digest: "e".repeat(64) },
    downloads_restore_prefix: "beam-downloads-compatible-",
    resolved_restore_prefix: "beam-resolved-lock-",
    downloads_key: `beam-downloads-compatible-${"d".repeat(64)}`,
    resolved_key: `beam-resolved-lock-${"e".repeat(64)}`,
    paths: { downloads: ["~/.hex/packages"], resolved: ["deps", "_build/test"] },
  };
  const normal = beamPlanForProbe(plan, { mode: "normal", runId: "101", attempt: 1 });
  assert.equal(normal.downloads_key, plan.downloads_key);
  assert.equal(normal.resolved_key, plan.resolved_key);
  const namespacedSeed = beamPlanForProbe(plan, { mode: "normal", namespace: "candidate-7", runId: "100", attempt: 1 });
  assert.ok(namespacedSeed.downloads_key.startsWith(`${plan.downloads_restore_prefix}phase182-candidate-7-`));
  assert.ok(namespacedSeed.resolved_key.startsWith(`${plan.resolved_restore_prefix}phase182-candidate-7-`));
  const fallback = beamPlanForProbe(plan, { mode: "beam-fallback", namespace: "candidate-7", runId: "101", attempt: 2 });
  assert.ok(fallback.downloads_key.startsWith(`${plan.downloads_restore_prefix}phase182-candidate-7-`));
  assert.ok(fallback.downloads_key.endsWith("-phase182-101-2"));
  assert.ok(fallback.downloads_restore_prefix.startsWith(plan.downloads_restore_prefix));
  assert.equal(fallback.resolved_restore_prefix, "");
  assert.ok(fallback.resolved_key.endsWith("-phase182-101-2"));
});

test("Docker cache configuration verifies the prevalidated policy without rewriting Bake", (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-docker-policy-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const manifestPath = path.join(root, "image-handoff.json");
  const bakePath = path.join(root, "bake.json");
  const env = {
    GITHUB_ACTIONS: "true",
    GITHUB_EVENT_NAME: "workflow_dispatch",
    GITHUB_REPOSITORY: REPOSITORY,
    GITHUB_REF: "refs/heads/candidate/phase182",
    E2E_CACHE_JOB: "full",
  };
  const cacheBaseScopes = { web: "scrypath-web-v1", browser: "scrypath-browser-v1" };
  const probe = cacheProbeFor("full", cacheBaseScopes, env, { mode: "normal", namespace: "candidate-7" });
  const bake = { target: { web: {}, browser: {} } };
  applyCacheProbeToBake(bake, probe);
  const manifest = {
    scope: "full",
    cache_base_scopes: cacheBaseScopes,
    cache_scopes: probe.scopes,
    cache_probe: { mode: probe.mode, namespace: probe.namespace },
    cache_policy: probe.policy,
  };
  fs.writeFileSync(manifestPath, JSON.stringify(manifest));
  fs.writeFileSync(bakePath, JSON.stringify(bake));
  const originalBake = fs.readFileSync(bakePath, "utf8");
  const configured = configureDockerBake({ manifestPath, mode: "normal", namespace: "candidate-7", env });
  assert.deepEqual(configured.manifest.cache_policy, { import: true, export: true });
  for (const [service, target] of Object.entries(configured.bake.target)) {
    assert.match(target["cache-from"][0], new RegExp(`scope=${probe.scopes[service]}`));
    assert.match(target["cache-to"][0], new RegExp(`scope=${probe.scopes[service]}`));
    assert.match(target["cache-to"][0], /mode=max/);
  }
  assert.equal(fs.readFileSync(bakePath, "utf8"), originalBake);
  assert.throws(() => configureDockerBake({ manifestPath, mode: "beam-cold", namespace: "candidate-7", env }), /prepared Docker cache probe/);
});

test("lock-change probe commits only a comment-only change in its temporary checkout", (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-lock-copy-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const source = path.join(root, "source");
  const runnerTemp = path.join(root, "runner-temp");
  fs.mkdirSync(source);
  execFileSync("git", ["init", "--quiet", source]);
  fs.writeFileSync(path.join(source, "mix.lock"), "%{}\n");
  execFileSync("git", ["-C", source, "add", "mix.lock"]);
  execFileSync("git", ["-C", source, "-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "--quiet", "-m", "baseline"]);
  const sourceBytes = fs.readFileSync(path.join(source, "mix.lock"));
  const result = prepareLockProbe({ workspace: source, runnerTemp, runId: "123", attempt: 2 });
  assert.equal(fs.readFileSync(path.join(source, "mix.lock")).equals(sourceBytes), true);
  assert.equal(result.manifest.owned_copy, true);
  assert.match(result.manifest.probe_commit, /^[a-f0-9]{40}$/);
  assert.equal(execFileSync("git", ["-C", result.workdir, "status", "--porcelain"], { encoding: "utf8" }).trim(), "");
  assert.deepEqual(execFileSync("git", ["-C", result.workdir, "diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD"], { encoding: "utf8" }).trim().split("\n"), ["mix.lock"]);
  assert.equal(fs.readFileSync(path.join(result.workdir, "mix.lock"), "utf8"), `${sourceBytes.toString()}# phase182 lock probe run 123 attempt 2\n`);
  const planPath = path.join(root, "beam-plan.json");
  const proofPath = path.join(root, "beam-proof.json");
  fs.writeFileSync(planPath, JSON.stringify({ identity: {
    locks_digest: result.manifest.lock_after,
    source_digest: "e".repeat(64),
    runner_image: "ubuntu24/20261019.1.0",
    os: "Linux",
    arch: "X64",
    elixir: "1.19.0",
    otp: "Erlang/OTP 28.1",
    mix_env: "test",
    mix_target: "host",
    profile: "root-test",
  }, downloads_key: "downloads-primary", downloads_restore_prefix: "downloads-", resolved_key: "resolved-primary", resolved_restore_prefix: "" }));
  const proof = writeBeamProbeProof({
    planPath,
    outputPath: proofPath,
    lockManifestPath: result.manifestPath,
    env: {
      PHASE182_CACHE_MODE: "beam-lock-change",
      GITHUB_REPOSITORY: REPOSITORY,
      GITHUB_REF_NAME: BRANCH,
      GITHUB_SHA: SHA,
      GITHUB_RUN_ID: "123",
      GITHUB_RUN_ATTEMPT: "2",
      RUNNER_NAME: "GitHub Actions 123",
      DOWNLOADS_MATCHED_KEY: "downloads-compatible-old",
      DEPS_GET_OUTCOME: "success",
      COMPILE_OUTCOME: "success",
      VERIFY_OUTCOME: "success",
    },
  });
  assert.deepEqual(proof.lock_probe, { owned_copy: true, source_lock_unchanged: true, versions_unchanged: true });
});

test("collectRun waits for selected-attempt job and artifact metadata without redispatching", (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-metadata-readiness-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const commands = successfulCommandDouble({ mode: "full", pendingJobReads: 2, pendingArtifactReads: 1 });
  const result = collectRun({
    repo: REPOSITORY,
    branch: BRANCH,
    sha: SHA,
    sessionId: SESSION_ID,
    mode: "full",
    outputDir: path.join(root, "candidate"),
  }, { command: commands, pollMilliseconds: 0, timeoutSeconds: 2, sleep: () => {}, browserValidator: validBrowserReceipt });

  assert.equal(JSON.parse(fs.readFileSync(result.receiptPath, "utf8")).eligible, true);
  assert.equal(result.run.id, "12345");
  assert.equal(commands.calls.filter((args) => args[0] === "workflow" && args[1] === "run").length, 1);
});

test("collectRun retains repeated-mode attempts in distinct directories and rejects session mismatch without mutation", async (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-session-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const commands = successfulCommandDouble({ mode: "docker-warm" });
  const flags = {
    repo: REPOSITORY,
    branch: BRANCH,
    sha: SHA,
    sessionId: SESSION_ID,
    mode: "docker-warm",
    outputDir: path.join(root, "candidate"),
  };

  const first = await collectRun(flags, { command: commands, pollMilliseconds: 0, timeoutSeconds: 2, browserValidator: validBrowserReceipt });
  const second = await collectRun(flags, { command: commands, pollMilliseconds: 0, timeoutSeconds: 2, browserValidator: validBrowserReceipt });
  assert.notEqual(first.runDirectory, second.runDirectory);
  assert.equal(fs.existsSync(first.receiptPath), true);
  assert.equal(fs.existsSync(second.receiptPath), true);

  const manifestPath = path.join(flags.outputDir, "phase182-session.json");
  const before = fs.readFileSync(manifestPath, "utf8");
  assert.throws(
    () => collectRun({ ...flags, sha: OTHER_SHA }, { command: commands, pollMilliseconds: 0 }),
    /session.*identity/i,
  );
  assert.throws(
    () => collectRun({ ...flags, probeNamespace: "different" }, { command: commands, pollMilliseconds: 0 }),
    /session.*identity/i,
  );
  assert.equal(fs.readFileSync(manifestPath, "utf8"), before);
});

test("collectRun rejects an artifact when dispatch wiring drops the requested namespace", (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-wrong-namespace-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  assert.throws(() => collectRun({
    repo: REPOSITORY, branch: BRANCH, sha: SHA, sessionId: SESSION_ID,
    mode: "docker-warm", probeNamespace: "isolated", outputDir: path.join(root, "candidate"),
  }, { command: successfulCommandDouble({ mode: "docker-warm" }), pollMilliseconds: 0, timeoutSeconds: 2, browserValidator: validBrowserReceipt }), /requested probe namespace/);
});

test("cache acceptance uses only session-listed receipts and preserves every probe attempt", async (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-cache-session-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const commands = successfulCommandDouble({ mode: "docker-warm" });
  const outputDir = path.join(root, "candidate");
  const base = { repo: REPOSITORY, branch: BRANCH, sha: SHA, sessionId: SESSION_ID, outputDir };

  for (const mode of REQUIRED_CACHE_MODES) {
    commands.setMode(mode);
    await collectRun({ ...base, mode }, { command: commands, pollMilliseconds: 0, timeoutSeconds: 2, browserValidator: validBrowserReceipt });
  }

  const stale = path.join(outputDir, "attempts", "docker-warm", "unlisted", "receipt.json");
  fs.mkdirSync(path.dirname(stale), { recursive: true });
  fs.writeFileSync(stale, JSON.stringify({ eligible: true, sha: OTHER_SHA }));
  const manifest = JSON.parse(fs.readFileSync(path.join(outputDir, "phase182-session.json"), "utf8"));
  assert.equal(manifest.invocations.length, REQUIRED_CACHE_MODES.length);
  assert.equal(validateAggregate({ ...base }, "caches").eligible, true);
  const aggregate = JSON.parse(fs.readFileSync(path.join(outputDir, "cache-acceptance.json"), "utf8"));
  assert.equal(aggregate.attempt_history.length, REQUIRED_CACHE_MODES.length);
  assert.equal(JSON.stringify(aggregate).includes("unlisted"), false);
});

test("concurrent denied dispatches serialize candidate manifest and aggregate updates", async (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-concurrent-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const outputDir = path.join(root, "candidate");
  const modulePath = path.join(__dirname, "phase182_acceptance.cjs");
  const workerSource = `
    const { workerData } = require("node:worker_threads");
    const { collectRun } = require(workerData.modulePath);
    try { collectRun(workerData.flags, { command: () => { throw new Error("HTTP 403 permission denied"); } }); } catch (_) {}
  `;
  const flags = { repo: REPOSITORY, branch: BRANCH, sha: SHA, sessionId: SESSION_ID, mode: "full", outputDir };
  await Promise.all([1, 2].map(() => new Promise((resolve, reject) => {
    const worker = new Worker(workerSource, { eval: true, workerData: { modulePath, flags } });
    worker.once("error", reject);
    worker.once("exit", (code) => code === 0 ? resolve() : reject(new Error(`worker exited ${code}`)));
  })));
  const manifest = JSON.parse(fs.readFileSync(path.join(outputDir, "phase182-session.json"), "utf8"));
  assert.equal(manifest.invocations.length, 2);
  assert.equal(new Set(manifest.invocations.map((entry) => entry.receipt)).size, 2);
  assert.ok(manifest.invocations.every((entry) => entry.status === "ineligible"));
});

test("collectRun ignores stale success, exhausts pagination, and binds only a newly dispatched exact-ref run", async (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-collect-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const commands = successfulCommandDouble({ staleRun: true, paginated: true, mode: "full" });
  const result = await collectRun({
    repo: REPOSITORY,
    branch: BRANCH,
    sha: SHA,
    sessionId: SESSION_ID,
    mode: "full",
    outputDir: path.join(root, "candidate"),
  }, { command: commands, pollMilliseconds: 0, timeoutSeconds: 2, browserValidator: validBrowserReceipt });
  assert.equal(result.run.id, "12345");
  assert.equal(result.run.sha, SHA);
  assert.equal(result.run.branch, BRANCH);
  assert.equal(result.browser.eligible, true);
  assert.equal(commands.calls.some((call) => call.includes("--paginate")), true);
});

test("a successful rerun keeps the failed previous attempt in exact attempt history", async (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-rerun-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const commands = successfulCommandDouble({ mode: "full", attempt: 2 });
  const result = await collectRun({ repo: REPOSITORY, branch: BRANCH, sha: SHA, sessionId: SESSION_ID, mode: "full", outputDir: path.join(root, "candidate") },
    { command: commands, pollMilliseconds: 0, timeoutSeconds: 2, browserValidator: validBrowserReceipt });
  assert.deepEqual(result.run.previous_attempts.map(({ attempt, conclusion }) => ({ attempt, conclusion })), [{ attempt: 1, conclusion: "failure" }]);
  assert.equal(result.run.attempt, 2);
});

test("collectRun rejects a failed raw verifier step masked by an advisory green conclusion", async (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-raw-step-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const commands = successfulCommandDouble({ mode: "full", rawVerifierFailure: true });
  assert.throws(
    () => collectRun({ repo: REPOSITORY, branch: BRANCH, sha: SHA, sessionId: SESSION_ID, mode: "full", outputDir: path.join(root, "candidate") },
      { command: commands, pollMilliseconds: 0, timeoutSeconds: 2, browserValidator: validBrowserReceipt }),
    /raw ecommerce verifier step disagrees/,
  );
});

test("collectRun validates GitHub job-step conclusions and preserves evidence paths inside nested upload roots", async (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-hosted-archive-shape-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const commands = successfulCommandDouble({ mode: "full" });
  const browserValidator = (runDirectory, context) => {
    assert.equal(fs.readFileSync(path.join(runDirectory, "test-results/admin-screenshots/owned.png"), "utf8"), "owned screenshot bytes");
    assert.equal(fs.readFileSync(path.join(runDirectory, "playwright-report/data/owned.png"), "utf8"), "playwright attachment bytes");
    assert.equal(fs.readFileSync(path.join(runDirectory, "ui-review-artifacts/iteration3-journeys/owned.png"), "utf8"), "iteration3 screenshot bytes");
    assert.equal(fs.existsSync(path.join(runDirectory, "test-results/.last-run.json")), false);
    return validBrowserReceipt(runDirectory, context);
  };
  const result = collectRun({ repo: REPOSITORY, branch: BRANCH, sha: SHA, sessionId: SESSION_ID, mode: "full", outputDir: path.join(root, "candidate") },
    { command: commands, pollMilliseconds: 0, timeoutSeconds: 2, browserValidator });
  assert.equal(result.browser.eligible, true);
  assert.equal(result.browser.raw_verifier_outcome, "success");
});

test("collectRun fails closed when run/job/artifact access or dispatch is denied", async (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-denied-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  for (const denied of ["dispatch", "jobs", "artifacts"]) {
    const commands = successfulCommandDouble({ denied, mode: "full" });
    assert.throws(
      () => collectRun({
        repo: REPOSITORY,
        branch: BRANCH,
        sha: SHA,
        sessionId: `${SESSION_ID}-${denied}`,
        mode: "full",
        outputDir: path.join(root, denied),
      }, { command: commands, pollMilliseconds: 0, timeoutSeconds: 2, browserValidator: validBrowserReceipt }),
      /denied|403|permission/i,
    );
  }
});

test("collectRun rejects wrong refs, incomplete job pages, absent artifacts and changed archive bytes", async (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-corrupt-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const cases = [
    [{ refSha: OTHER_SHA }, /does not point to requested source SHA/],
    [{ incompleteJobs: true }, /package \(required\).*successful job/],
    [{ missingBrowserArtifact: true }, /expected exactly one live ecommerce-e2e-evidence/],
    [{ tamperArchive: true }, /immutable archive digest/],
    [{ wrongArtifactSource: true }, /artifact belongs to another run\/ref\/source/],
    [{ wrongArtifactRepository: true }, /artifact is not owned by szTheory\/scrypath/],
  ];
  for (const [options, expected] of cases) {
    const commands = successfulCommandDouble({ ...options, mode: "full" });
    assert.throws(
      () => collectRun({ repo: REPOSITORY, branch: BRANCH, sha: SHA, sessionId: `${SESSION_ID}-${Object.keys(options)[0]}`, mode: "full", outputDir: path.join(root, Object.keys(options)[0]) },
        { command: commands, pollMilliseconds: 0, timeoutSeconds: 2, browserValidator: validBrowserReceipt }),
      expected,
    );
  }
});

test("probe namespace rejects shell and option injection", (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-input-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const base = { repo: REPOSITORY, branch: BRANCH, sha: SHA, sessionId: SESSION_ID, mode: "docker-warm", outputDir: path.join(root, "candidate") };
  for (const probeNamespace of ["-x", "Warm", "probe;echo-pwned", "probe/value"]) {
    assert.throws(() => validateFlags({ ...base, probeNamespace }), /probe namespace must be a lowercase slug/);
  }
  assert.equal(validateFlags({ ...base, probeNamespace: "candidate-182" }).probeNamespace, "candidate-182");
});

function validBrowserReceipt(_runDirectory, context) {
  const run = context.run;
  return {
    valid: true,
    eligible: true,
    reasons: [],
    receipt: authorityAggregate(run),
  };
}

function authorityAggregate(run) {
  return {
    schema_version: 1,
    workflow: { ref: `refs/heads/${run.branch}` },
    source: { mode: "hosted", dirty: false, checkout_head: SHA, built_source_sha: SHA, event_sha: SHA },
    images: {
      application: { built_id: `sha256:${"1".repeat(64)}`, runtime_id: `sha256:${"1".repeat(64)}`, source_sha: SHA },
      browser: { built_id: `sha256:${"2".repeat(64)}`, runtime_id: `sha256:${"2".repeat(64)}`, source_sha: SHA },
    },
    eligibility: { eligible: true },
    event: "workflow_dispatch",
    run_id: run.id,
    run_attempt: run.attempt,
    sha: run.sha,
    stages: { browser: { exit_code: 0 } },
    tests_total: 8,
    attempts_total: 8,
  };
}

function successfulCommandDouble({ staleRun = false, paginated = false, denied = null, mode = "full", missingBrowserArtifact = false, tamperArchive = false, incompleteJobs = false, wrongArtifactSource = false, wrongArtifactRepository = false, refSha = SHA, attempt = 1, rawVerifierFailure = false, pendingJobReads = 0, pendingArtifactReads = 0 } = {}) {
  const calls = [];
  let activeMode = mode;
  let dispatched = false;
  let runCounter = 12344;
  let run;
  let artifacts = [];
  let jobReads = 0;
  let artifactReads = 0;
  const browserMembers = Object.fromEntries([
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
  ].map((name) => [name, name.endsWith(".json") ? "{}" : "fixture\n"]));
  const warmCache = cacheProof("docker-warm").cache;
  browserMembers["image-handoff.json"] = JSON.stringify({
    schema_version: 1,
    scope: "full",
    source_sha: SHA,
    cache_probe: { mode: "normal", namespace: "candidate-7" },
    handoff_status: "runtime_verified",
    cache_action_outcome: "success",
    cache_handoff_outcome: "success",
    import_status: "completed",
    export_status: "completed",
    cache_scopes: warmCache.target_scopes,
    recipe_digest: warmCache.recipe_digest,
    recipe_ids: warmCache.recipe_ids,
    image_ids: warmCache.image_ids,
    runtime_image_ids: warmCache.image_ids,
  });
  const browserArchive = Buffer.from("phase182-browser-archive");
  const cacheArchive = Buffer.from("phase182-cache-archive");
  const jobs = [
    { id: 101, name: "core (required)", status: "completed", conclusion: "success", steps: [] },
    { id: 102, name: "package (required)", status: "completed", conclusion: "success", steps: [] },
    { id: 103, name: "repository-contracts (required)", status: "completed", conclusion: "success", steps: [] },
    { id: 104, name: "backend (required)", status: "completed", conclusion: "success", steps: [] },
    { id: 105, name: "ecommerce-mounted (required)", status: "completed", conclusion: "success", steps: [] },
    { id: 106, name: "coverage (advisory)", status: "completed", conclusion: "success", steps: [] },
    { id: 107, name: "closeout-attestation", status: "completed", conclusion: "success", steps: [] },
    { id: 108, name: "ecommerce-e2e (advisory)", status: "completed", conclusion: "success", started_at: STARTED, completed_at: "2026-10-26T12:11:00Z", steps: [
      { name: "Run advisory full E2E proof", status: "completed", conclusion: rawVerifierFailure ? "failure" : "success", started_at: STARTED, completed_at: COMPLETED },
      { name: "Upload advisory E2E evidence", status: "completed", conclusion: "success", started_at: COMPLETED, completed_at: "2026-10-26T12:10:10Z" },
    ] },
  ];
  const artifactsFor = (runId) => {
    // The workflow_run object returned by GitHub's artifact-list API exposes repository IDs,
    // but omits the nested head_repository.full_name object.
    const artifactWorkflow = {
      id: runId,
      head_sha: wrongArtifactSource ? OTHER_SHA : SHA,
      head_branch: BRANCH,
      repository_id: wrongArtifactRepository ? 999 : 1211932882,
      head_repository_id: 1211932882,
    };
    const selectedRun = exactRun({ id: String(runId), attempt });
    const archiveRoot = `scrypath/scrypath/examples/scrypath_ecommerce/test-results/docker-full/${runId}-${attempt}/`;
    const members = Object.fromEntries(Object.entries({ ...browserMembers, "phase105-evidence.json": JSON.stringify(authorityAggregate(selectedRun)) })
      .map(([member, contents]) => [`${archiveRoot}${member}`, contents]));
    members[`${archiveRoot}test-results/admin-screenshots/owned.png`] = "owned screenshot bytes";
    members[`${archiveRoot}test-results/.last-run.json`] = '{"status":"passed"}\n';
    members[`${archiveRoot}playwright-report/data/owned.png`] = "playwright attachment bytes";
    members[`${archiveRoot}ui-review-artifacts/iteration3-journeys/owned.png`] = "iteration3 screenshot bytes";
    const result = [{
      id: runId * 10 + 1,
      name: `ecommerce-e2e-evidence-${runId}-${attempt}`,
      expired: false,
      digest: `sha256:${crypto.createHash("sha256").update(browserArchive).digest("hex")}`,
      created_at: "2026-10-26T12:10:10Z",
      workflow_run: artifactWorkflow,
      archive: browserArchive,
      members,
    }];
    if (activeMode !== "full") {
      result.push({
        id: runId * 10 + 2,
        name: `phase182-cache-probe-${activeMode}-${runId}-${attempt}`,
        expired: false,
        digest: `sha256:${crypto.createHash("sha256").update(cacheArchive).digest("hex")}`,
        created_at: "2026-10-26T12:10:10Z",
        workflow_run: artifactWorkflow,
        archive: cacheArchive,
        members: { "phase182-cache-proof.json": JSON.stringify(cacheProof(activeMode, { run: exactRun({ id: String(runId), attempt }) })) },
      });
    }
    return missingBrowserArtifact ? result.filter((item) => !item.name.startsWith("ecommerce-e2e-evidence-")) : result;
  };
  const runFor = (runId) => ({
    id: runId,
    run_attempt: attempt,
    repository: { id: 1211932882, full_name: REPOSITORY },
    head_repository: { id: 1211932882, full_name: REPOSITORY },
    head_sha: SHA,
    head_branch: BRANCH,
    event: "workflow_dispatch",
    status: "completed",
    conclusion: "success",
    run_started_at: STARTED,
    updated_at: "2026-10-26T12:11:00Z",
    path: ".github/workflows/ci.yml",
    workflow_id: 77,
  });

  function command(bin, args) {
    calls.push([...args]);
    const text = args.join(" ");
    if (denied === "dispatch" && text.includes("workflow run")) throw new Error("HTTP 403 permission denied to dispatch workflow");
    if (denied === "jobs" && text.includes("/jobs")) throw new Error("HTTP 403 permission denied to read jobs");
    if (denied === "artifacts" && text.includes("/artifacts")) throw new Error("HTTP 403 permission denied to read artifacts");
    if (text === "auth status") return { stdout: "Logged in", status: 0 };
    if (text.includes("repo view")) return { stdout: JSON.stringify({ nameWithOwner: REPOSITORY }), status: 0 };
    if (text.includes("workflow run")) {
      dispatched = true;
      const requested = args.find((arg) => arg.startsWith("phase182_cache_mode="))?.split("=")[1] || "normal";
      activeMode = requested === "normal" ? "docker-warm" : requested;
      run = runFor(++runCounter);
      artifacts = artifactsFor(runCounter);
      return { stdout: "", status: 0 };
    }
    if (bin === "unzip") {
      const archive = artifacts.find((item) => args[1].includes(item.name));
      if (!archive) throw new Error(`unknown archive path ${args[1]}`);
      if (args[0] === "-Z1") return { stdout: `${Object.keys(archive.members).join("\n")}\n` };
      if (args[0] === "-p") return { stdout: Buffer.from(archive.members[args[2]] || "") };
    }
    if (args[0] === "api") {
      const endpoint = args.at(-1);
      if (endpoint.includes("/git/ref/heads/")) return { stdout: JSON.stringify({ ref: `refs/heads/${BRANCH}`, object: { sha: refSha } }) };
      if (endpoint.includes("/actions/workflows/ci.yml/runs?")) {
        const old = staleRun ? [{ id: 111, head_sha: OTHER_SHA, head_branch: BRANCH, event: "workflow_dispatch" }] : [];
        const selected = dispatched ? [run] : [];
        const values = [...old, ...selected];
        return { stdout: JSON.stringify(paginated ? values.map((entry) => ({ workflow_runs: [entry] })) : { workflow_runs: values }) };
      }
      const runDetail = endpoint.match(/\/actions\/runs\/(\d+)$/);
      if (runDetail) return { stdout: JSON.stringify(run) };
      const attemptDetail = endpoint.match(/\/actions\/runs\/(\d+)\/attempts\/(\d+)$/);
      if (attemptDetail) return { stdout: JSON.stringify({ conclusion: "failure", run_attempt: Number(attemptDetail[2]) }) };
      if (endpoint.endsWith("/actions/workflows/ci.yml")) return { stdout: JSON.stringify({ id: 77, name: "CI", path: ".github/workflows/ci.yml" }) };
      if (/\/actions\/runs\/\d+\/attempts\/\d+\/jobs/.test(endpoint)) {
        const observedJobs = jobReads++ < pendingJobReads
          ? jobs.map((job) => job.name === "ecommerce-e2e (advisory)" ? { ...job, status: "in_progress", conclusion: null, completed_at: null } : job)
          : jobs;
        const selectedJobs = incompleteJobs ? observedJobs.filter((job) => job.name !== "package (required)") : observedJobs;
        return { stdout: JSON.stringify(paginated ? [{ jobs: selectedJobs.slice(0, 4) }, { jobs: selectedJobs.slice(4) }] : { jobs: selectedJobs }) };
      }
      if (/\/actions\/runs\/\d+\/artifacts/.test(endpoint)) {
        const observedArtifacts = artifactReads++ < pendingArtifactReads ? [] : artifacts;
        return { stdout: JSON.stringify(paginated ? [{ artifacts: [] }, { artifacts: observedArtifacts }] : { artifacts: observedArtifacts }) };
      }
      const archive = endpoint.match(/\/actions\/artifacts\/(\d+)\/zip$/);
      if (archive) return { stdout: tamperArchive ? Buffer.from("mutated archive bytes") : artifacts.find((item) => String(item.id) === archive[1]).archive };
    }
    if (args[0] === "run" && args[1] === "view") {
      return { stdout: activeMode === "docker-warm"
        ? `Run mix verify.ecommerce_e2e\n${buildKitCacheLog()}\n`
        : activeMode === "beam-cold"
          ? "Run mix deps.get\nRun mix compile\nRun mix verify.core\n"
          : activeMode.startsWith("beam-")
          ? cacheProof(activeMode, { run: exactRun({ id: String(run.id), attempt }) }).cache.log_text
        : "Run advisory full E2E proof\n" };
    }
    throw new Error(`unexpected command: ${text}`);
  }
  command.calls = calls;
  command.setMode = (nextMode) => { activeMode = nextMode; };
  return command;
}

test("full aggregate accepts the parsed receipt from the latest eligible session invocation", (t) => {
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'phase182-full-aggregate-'));
 t.after(()=>fs.rmSync(root,{recursive:true,force:true}));
 const flags={repo:REPOSITORY,branch:BRANCH,sha:SHA,sessionId:SESSION_ID,mode:'full',outputDir:path.join(root,'candidate')};
 collectRun(flags,{command:successfulCommandDouble({mode:'full'}),pollMilliseconds:0,timeoutSeconds:2,browserValidator:validBrowserReceipt});
 assert.equal(validateAggregate(flags,'full').eligible,true);
});
