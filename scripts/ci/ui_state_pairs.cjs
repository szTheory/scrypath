"use strict";

const crypto = require("node:crypto");
const fs = require("node:fs");
const rawBundle = require("./ui_preservation_bundle.cjs");
const path = require("node:path");
const evidence = require("./ecommerce_evidence.cjs");
const { PNG } = require("../../examples/scrypath_ecommerce/node_modules/pngjs");

const AUTHORITY_SCHEMA = "scrypath.ui-state-pair-authority.v2";
const QUALIFICATION_SCHEMA = "scrypath.phase185-before-qualification.v1";
const PAIR_SCHEMA = "scrypath.ui-state-pair-comparison.v2";
const FULL_RECEIPT_NAME = "phase105-evidence.json";
const BEFORE_RECEIPT_NAME = "phase185-before-only-evidence.json";
const OUTPUT_NAME = "ui-state-pairs.json";
const PRESERVATION_PREFIX = "ui-review-artifacts/iteration3-journeys/phase185-held-out/";
const REQUIRED_VIEWPORT_WIDTHS = [1440, 768, 390];
const REQUIRED_THEMES = ["light", "dark", "system-dark"];
const MAX_AUTHORITY_BYTES = 4 * 1024 * 1024;
const MAX_RECEIPT_BYTES = 8 * 1024 * 1024;
const MAX_IMAGE_BYTES = 64 * 1024 * 1024;
const DIGEST = /^sha256:[a-f0-9]{64}$/;
const SHA = /^[a-f0-9]{40}$/;

const digest = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");
const isRecord = (value) => value !== null && typeof value === "object" && !Array.isArray(value);
const canonicalize = (value) => Array.isArray(value)
  ? value.map(canonicalize)
  : value && typeof value === "object"
    ? Object.fromEntries(Object.keys(value).sort().map((key) => [key, canonicalize(value[key])]))
    : value;
const canonicalJson = (value) => JSON.stringify(canonicalize(value));
const commonRecipe = (recipe) => {
  const normalized = structuredClone(recipe);
  if (normalized?.browser_date && typeof normalized.browser_date === "object") delete normalized.browser_date.timer_elapsed_ms;
  return normalized;
};

function fail(code, message) {
  const error = new Error(message);
  error.code = code;
  throw error;
}

function requiredCaseIds() {
  return evidence.preservationCases.map(({ id }) => id);
}

function regularFile(file, maxBytes, label) {
  const absolute = path.resolve(file);
  const stat = fs.lstatSync(absolute);
  if (stat.isSymbolicLink() || !stat.isFile() || stat.size <= 0 || stat.size > maxBytes) {
    fail("invalid_input_file", `${label} must be a bounded, non-empty regular file without symlinks`);
  }
  return { absolute, bytes: fs.readFileSync(absolute) };
}

function parseJsonBytes(bytes, label) {
  try {
    const value = JSON.parse(bytes.toString("utf8"));
    if (!value || typeof value !== "object" || Array.isArray(value)) throw new TypeError("JSON root must be an object");
    return value;
  } catch (error) {
    fail("invalid_json", `${label} is invalid JSON: ${error.message}`);
  }
}

function validateQualificationRecord(authority) {
  const qualification = authority?.qualification;
  const record = qualification?.record;
  const expected = authority?.expected;
  if (!qualification || typeof qualification.path !== "string" || !path.isAbsolute(qualification.path) || !DIGEST.test(qualification.sha256 || "")) {
    fail("invalid_qualification_reference", "Authority must pin the absolute Plan05 qualification file and its SHA-256 digest");
  }
  if (!record || record.schema !== QUALIFICATION_SCHEMA || record.status !== "qualified") {
    fail("unqualified_before_source", "Plan05 qualification record is absent or is not qualified");
  }
  if (record.source_sha !== expected?.before?.product_source_sha || !record.browser_runtime_equivalence?.rootfs_layers_equal ||
    !record.browser_runtime_equivalence?.effective_config_equal || record.browser_runtime_equivalence.source_sha !== record.source_sha) {
    fail("qualification_mismatch", "Plan05 qualification does not bind the expected pre-UI source and equivalent browser runtime");
  }
  const environment = qualification.environment;
  const recipe = expected?.recipe;
  if (!environment || !recipe || environment.browser_version !== recipe.browser?.version ||
    JSON.stringify(environment.browser_launch?.args) !== JSON.stringify(recipe.launch_args) ||
    environment.clock?.utc !== recipe.browser_date?.observed ||
    `sha256:${environment.clock?.sha256}` !== recipe.clock_sha256 ||
    environment.clock?.timezone !== recipe.timezone || environment.clock?.locale !== recipe.locale ||
    environment.clock?.browser_mode !== "fixed-date" ||
    canonicalJson({ ...environment.browser_font_profile, font_families: { fixed: environment.browser_font_profile?.font_families?.fixed } }) !==
      canonicalJson({ method: recipe.font_profile?.method, font_families: { fixed: recipe.font_profile?.fixed_font_family }, applied: recipe.font_profile?.applied, lifetime: recipe.font_profile?.lifetime })) {
    fail("qualification_environment_mismatch", "Capture recipe does not match the independently pinned qualified before environment, clock, launch args and retained font profile");
  }
  if (qualification.browser_runtime?.browser_image_id !== record.browser_runtime_equivalence.actual_image_id ||
    qualification.browser_runtime?.effective_runtime_sha256 !== expected.before.effective_runtime_sha256 ||
    qualification.browser_runtime?.browser_base_layers_sha256 !== expected.browser_base_layers_sha256 ||
    qualification.browser_runtime?.playwright_package_version !== recipe.browser?.package_version) {
    fail("qualification_runtime_mismatch", "New browser builds must retain the qualified executable browser, lock, Dockerfile and immutable base layers");
  }
}

function validateAuthority(authority) {
  if (!authority || authority.schema !== AUTHORITY_SCHEMA) fail("invalid_authority", "Unsupported source-pair authority schema");
  validateQualificationRecord(authority);
  const expected = authority.expected;
  for (const side of ["before", "candidate"]) {
    const source = expected?.[side];
    if (!source || !SHA.test(source.product_source_sha || "") || !SHA.test(source.build_source_sha || "") ||
      !DIGEST.test(source.product_tree_sha256 || "") || !DIGEST.test(source.application_image_id || "") ||
      !DIGEST.test(source.standalone_ops_image_id || "") || !DIGEST.test(source.browser_image_id || "") ||
      !DIGEST.test(source.browser_source_layer_id || "") || !DIGEST.test(source.browser_base_layers_sha256 || "") ||
      !DIGEST.test(source.effective_runtime_sha256 || "") || !DIGEST.test(source.fixture_overlay_sha256 || "")) {
      fail("invalid_expected_source", `Authority must supply independently observed ${side} product/build, tree, app and browser build identities`);
    }
  }
  if (expected.before.product_source_sha === expected.candidate.product_source_sha || expected.before.product_tree_sha256 === expected.candidate.product_tree_sha256) {
    fail("unpaired_sources", "Before and candidate product sources must be independently identified as different revisions and trees");
  }
  for (const [label, value] of [
    ["fixture overlay", expected.fixture_overlay_sha256],
    ["effective runtime", expected.effective_runtime_sha256],
    ["browser base layers", expected.browser_base_layers_sha256]
  ]) {
    if (!DIGEST.test(value || "")) fail("invalid_expected_identity", `Authority ${label} must be a full SHA-256 digest`);
  }
  const recipe = expected.recipe;
  if (!recipe || !recipe.browser || recipe.browser.engine !== "chromium" ||
    !/^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/.test(recipe.browser.package_version || "") ||
    !/^\d+(?:\.\d+){2,3}(?:[-+][0-9A-Za-z.-]+)?$/.test(recipe.browser.version || "")) {
    fail("invalid_capture_recipe", "Authority must pin the qualified Chromium and Playwright browser versions");
  }
  if (!Array.isArray(recipe.launch_args) || !recipe.launch_args.includes("--disable-partial-raster") ||
    recipe.locale !== "en-US" || recipe.timezone !== "UTC" || recipe.device_scale_factor !== 1 ||
    recipe.browser_date?.fixed !== true || recipe.browser_date?.timers_running !== true ||
    recipe.font_profile?.method !== "retained-cdp-fixed-font-v1" ||
    recipe.font_profile?.fixed_font_family !== "Liberation Mono" ||
    recipe.font_profile?.applied !== "before-first-navigation" || recipe.font_profile?.lifetime !== "page-context") {
    fail("invalid_capture_recipe", "Authority capture recipe must preserve the qualified raster, locale, clock, DPR and retained CDP font profile");
  }
  for (const [label, value] of [
    ["browser profile", recipe.profile_sha256],
    ["fixed clock", recipe.clock_sha256],
    ["data recipe", recipe.data_recipe_sha256]
  ]) {
    if (!DIGEST.test(value || "")) fail("invalid_capture_recipe", `Authority ${label} must have a pinned SHA-256 digest`);
  }
  if (!Number.isFinite(recipe.browser_date.timer_elapsed_ms) || recipe.browser_date.timer_elapsed_ms <= 20) {
    fail("invalid_capture_recipe", "Authority must carry an observed fixed Date with running real timers");
  }
  const profileRecipe = Object.fromEntries(Object.entries(recipe).filter(([key]) => !["browser_date", "clock_sha256", "profile_sha256", "data_recipe_sha256"].includes(key)));
  if (`sha256:${digest(Buffer.from(canonicalJson(profileRecipe)))}` !== recipe.profile_sha256) {
    fail("invalid_capture_recipe", "Authority browser/profile digest does not match its exact launch, locale, DPR and font settings");
  }
  for (const side of [expected.before, expected.candidate]) {
    if (side.effective_runtime_sha256 !== expected.effective_runtime_sha256 || side.browser_base_layers_sha256 !== expected.browser_base_layers_sha256 || side.fixture_overlay_sha256 !== expected.fixture_overlay_sha256) {
      fail("invalid_expected_runtime", "Each source build must independently match the common audited base runtime and fixture overlay");
    }
  }
  if (!DIGEST.test(expected.browser_base_layers_sha256 || "")) fail("invalid_expected_runtime", "Authority must pin the common browser base-layer digest");
  return {
    recipeSha256: `sha256:${digest(Buffer.from(canonicalJson(commonRecipe(recipe))))}`,
    authoritySha256: `sha256:${digest(Buffer.from(canonicalJson(authority)))}`
  };
}

function loadAuthority(authorityPath) {
  if (!path.isAbsolute(authorityPath)) fail("invalid_authority_path", "--authority must be an absolute file path");
  const { absolute, bytes } = regularFile(authorityPath, MAX_AUTHORITY_BYTES, "Authority");
  const authority = parseJsonBytes(bytes, "Authority");
  const qualificationPath = authority.qualification?.path;
  if (typeof qualificationPath !== "string" || !path.isAbsolute(qualificationPath)) {
    fail("invalid_qualification_reference", "Authority must pin the Plan05 qualification with an absolute file path");
  }
  const qualificationFile = regularFile(qualificationPath, MAX_AUTHORITY_BYTES, "Plan05 qualification");
  const qualificationSha = `sha256:${digest(qualificationFile.bytes)}`;
  if (qualificationSha !== authority.qualification.sha256) fail("qualification_hash_mismatch", "Plan05 qualification file does not match the independently pinned hash");
  const record = parseJsonBytes(qualificationFile.bytes, "Plan05 qualification");
  const pinned = new Map((Array.isArray(record.pinned_files) ? record.pinned_files : []).map((item) => [item.path, item.sha256]));
  const loadPinned = (filePath, label) => {
    if (typeof filePath !== "string" || !path.isAbsolute(filePath) || !/^[a-f0-9]{64}$/.test(pinned.get(filePath) || "")) {
      fail("qualification_pin_missing", `Plan05 qualification does not independently pin ${label}`);
    }
    const file = regularFile(filePath, MAX_AUTHORITY_BYTES, label);
    if (digest(file.bytes) !== pinned.get(filePath)) fail("qualification_pin_mismatch", `Plan05 pinned ${label} bytes have changed`);
    let value;
    try { value = JSON.parse(file.bytes.toString("utf8")); }
    catch (error) { fail("invalid_qualification_metadata", `${label} is invalid JSON: ${error.message}`); }
    if (!value || typeof value !== "object") fail("invalid_qualification_metadata", `${label} must contain a JSON object or inspection array`);
    return { file, value };
  };
  const capture = loadPinned(authority.qualification.capture_path, "qualified before capture metadata");
  const inspection = loadPinned(authority.qualification.browser_inspection_path, "qualified browser image inspection");
  let inspectionValue;
  try { inspectionValue = JSON.parse(inspection.file.bytes.toString("utf8")); }
  catch (error) { fail("invalid_qualification_inspection", `Qualified browser image inspection is invalid JSON: ${error.message}`); }
  if (Array.isArray(capture.value) || digest(capture.file.bytes) !== record.actual_before_sha256 || capture.value.source?.source_sha !== record.source_sha ||
    !capture.value.environment || !Array.isArray(inspectionValue) || inspectionValue.length !== 1) {
    fail("qualification_pin_mismatch", "Pinned before capture or browser inspection does not match the qualification record");
  }
  const inspectedImage = inspectionValue[0];
  if (inspectedImage?.Id !== record.browser_runtime_equivalence.actual_image_id ||
    inspectedImage?.Config?.Labels?.["org.opencontainers.image.revision"] !== record.source_sha) {
    fail("qualification_browser_mismatch", "Pinned qualified browser inspection is not the actual image built from the qualified product source");
  }
  const buildAuthority = require("./ecommerce_build.cjs");
  const qualifiedRuntime = buildAuthority.phase185RuntimeIdentity({ inspectionPath: inspection.file.absolute, repoRoot: path.resolve(__dirname, "../..") });
  const normalized = { ...authority, qualification: { ...authority.qualification, path: qualificationFile.absolute, record,
    environment: capture.value.environment,
    browser_runtime: qualifiedRuntime } };
  validateAuthority(normalized);
  return { authority: normalized, authoritySha256: `sha256:${digest(bytes)}`, path: absolute };
}

function loadReceiptBundle(receiptPath, side, authority) {
  const receiptName = side === "before" ? BEFORE_RECEIPT_NAME : FULL_RECEIPT_NAME;
  if (!path.isAbsolute(receiptPath)) fail("invalid_receipt_path", `--${side} must be an absolute path to ${receiptName}`);
  const { absolute, bytes } = regularFile(receiptPath, MAX_RECEIPT_BYTES, `${side} receipt`);
  if (path.basename(absolute) !== receiptName) fail("invalid_receipt_path", `--${side} must name ${receiptName}`);
  const runRoot = fs.realpathSync(path.dirname(absolute));
  const canonicalReceipt = path.join(runRoot, receiptName);
  if (path.basename(absolute) !== receiptName || !fs.existsSync(canonicalReceipt)) fail("invalid_receipt_path", `--${side} receipt path must resolve to ${receiptName} within its run directory`);
  const independentSource = authority.expected[side];
  const sourceExpectation = {
    sourceSha: independentSource.product_source_sha,
    buildSourceSha: independentSource.build_source_sha,
    productTreeSha256: independentSource.product_tree_sha256,
    fixtureOverlaySha256: authority.expected.fixture_overlay_sha256,
    ...(side === "before" ? { qualificationSha256: authority.qualification.sha256 } : {})
  };
  const validation = side === "before"
    ? evidence.validateBeforeOnlyReceipt({ runDir: runRoot, expectedSource: sourceExpectation })
    : evidence.validateReceipt({
    runDir: runRoot,
    expectedSource: sourceExpectation
  });
  if (!validation.valid || !validation.eligible) {
    fail("invalid_run_receipt", `${side} run receipt is not independently recomputable and eligible: ${validation.reasons.map((reason) => `${reason.code}: ${reason.message}`).join("; ")}`);
  }
  const receipt = parseJsonBytes(bytes, `${side} receipt`);
  if (canonicalJson(receipt) !== canonicalJson(validation.receipt)) fail("receipt_read_mismatch", `${side} receipt bytes changed after validation`);
  const rawMembers = rawBundle.loadRunBundle(runRoot, receipt.preservation.raw_bundle.sha256);
  return { receipt, runRoot, rawMembers, receiptSha256: `sha256:${digest(bytes)}`, side, authority };
}

function validateReceiptSide(bundle, side, authority, recipeSha256) {
  const receipt = bundle.receipt;
  const expected = authority.expected[side];
  if (receipt?.eligibility?.eligible !== true) fail("ineligible_run_receipt", `${side} source receipt is not eligible`);
  if (receipt.source?.checkout_head !== expected.build_source_sha || receipt.source?.built_source_sha !== expected.build_source_sha ||
    receipt.preservation?.product_source_sha !== expected.product_source_sha || receipt.preservation?.build_source_sha !== expected.build_source_sha ||
    receipt.preservation?.product_tree_sha256 !== expected.product_tree_sha256 ||
    (side === "before" && receipt.source?.qualification_sha256 !== authority.qualification.sha256)) {
    fail("product_source_mismatch", `${side} receipt source OIDs do not match its independent product source, harness build source and product-tree identity`);
  }
  const expectedSchema = side === "before" ? "scrypath.ui-preservation-before-only.v1" : "scrypath.ui-preservation.v1";
  if (receipt.scope !== (side === "before" ? "before-only" : "full") || receipt.preservation?.schema !== expectedSchema) {
    fail("preservation_source_mismatch", `${side} receipt has the wrong execution scope or preservation schema`);
  }
  if (receipt.preservation?.fixture_overlay_sha256 !== authority.expected.fixture_overlay_sha256) {
    fail("fixture_overlay_mismatch", `${side} run does not use the independently expected test-only fixture overlay`);
  }
  if (receipt.images?.application?.runtime_id !== expected.application_image_id ||
    receipt.images?.standalone_ops?.runtime_id !== expected.standalone_ops_image_id ||
    receipt.images?.browser?.runtime_id !== expected.browser_image_id ||
    canonicalJson(receipt.browser) !== canonicalJson(authority.expected.recipe.browser)) {
    fail("runtime_or_browser_mismatch", `${side} run does not match its own independently inspected app, standalone and browser image IDs or the qualified executable browser`);
  }
  const cases = receipt.preservation.cases;
  const expectedIds = requiredCaseIds();
  if (!Array.isArray(cases)) fail("incomplete_preservation_pair", `${side} receipt must contain exactly ${expectedIds.length} preservation cases`);
  const byId = new Map();
  for (const item of cases) {
    if (!item || typeof item.id !== "string" || byId.has(item.id)) fail("duplicate_preservation_pair", `${side} receipt has a missing or duplicate case identity`);
    byId.set(item.id, item);
  }
  if (cases.length !== expectedIds.length) fail("incomplete_preservation_pair", `${side} receipt must contain exactly ${expectedIds.length} unique preservation cases`);
  if (expectedIds.some((id) => !byId.has(id)) || [...byId.keys()].some((id) => !expectedIds.includes(id))) {
    fail("incomplete_preservation_pair", `${side} receipt is missing or adds a held-out case identity`);
  }
  const artifacts = new Map((Array.isArray(receipt.artifacts) ? receipt.artifacts : []).map((artifact) => [artifact.path, artifact]));
  const raw = receipt.preservation?.raw_bundle;
  const packedArtifact = artifacts.get(rawBundle.BUNDLE_PATH);
  if (raw?.path !== rawBundle.BUNDLE_PATH || !packedArtifact?.present || packedArtifact.sha256 !== raw.sha256 || packedArtifact.copied !== true || packedArtifact.copy_status !== "success" || !Array.isArray(raw.members) || raw.members.length > rawBundle.LIMITS.members) fail("invalid_case_bundle", `${side} receipt lacks its hash-bound bounded raw PNG bundle`);
  const memberPaths = new Set();
  for (const member of raw.members) {
    try { rawBundle.memberPath(member.path); } catch (error) { fail("invalid_case_bundle", error.message); }
    if (memberPaths.has(member.path) || !/^[a-f0-9]{64}$/.test(member.sha256 || "") || !Number.isSafeInteger(member.size_bytes) || member.size_bytes < 1 || member.size_bytes > MAX_IMAGE_BYTES) fail("invalid_case_bundle", "Raw bundle member metadata is malformed or duplicated");
    memberPaths.add(member.path);
    artifacts.set(member.path, { ...member, present: true, copied: true, copy_status: "success", storage: "raw-bundle-member" });
  }

  const seenImagePaths = new Set();
  for (const required of evidence.preservationCases) {
    const item = byId.get(required.id);
    if (item.product_source_sha !== expected.product_source_sha || item.build_source_sha !== expected.build_source_sha || item.product_tree_sha256 !== expected.product_tree_sha256 ||
      item.fixture_overlay_sha256 !== authority.expected.fixture_overlay_sha256) {
      fail("case_source_mismatch", `${side} case ${required.id} is not bound to its expected source and fixture identities`);
    }
    if (item.recipe_sha256 !== recipeSha256 || item.runtime?.effective_runtime_sha256 !== expected.effective_runtime_sha256 ||
      item.runtime?.application_image_id !== expected.application_image_id || item.runtime?.standalone_ops_image_id !== expected.standalone_ops_image_id ||
      item.runtime?.browser_image_id !== expected.browser_image_id || item.runtime?.browser_source_layer_id !== expected.browser_source_layer_id ||
      item.runtime?.browser_base_layers_sha256 !== expected.browser_base_layers_sha256 ||
      canonicalJson(commonRecipe(item.clock_recipe)) !== canonicalJson(commonRecipe(authority.expected.recipe)) ||
      !Number.isFinite(item.clock_recipe?.browser_date?.timer_elapsed_ms) || item.clock_recipe.browser_date.timer_elapsed_ms <= 20 ||
      `sha256:${digest(Buffer.from(canonicalJson(item.data_recipe)))}` !== authority.expected.recipe.data_recipe_sha256) {
      fail("case_runtime_or_recipe_mismatch", `${side} case ${required.id} does not match its independently inspected build and common fixed browser recipe`);
    }
    if (typeof item.test_identity !== "string" || item.test_identity.trim() === "") fail("invalid_case_state", `${side} case ${required.id} has no successful test identity`);
    const matrix = required.category === "overflow" || required.category === "long-text"
      ? REQUIRED_THEMES.flatMap((theme) => REQUIRED_VIEWPORT_WIDTHS.map((width) => `${theme}|${width}`))
      : null;
    if (!Array.isArray(item.observations) || (matrix && item.observations.length !== matrix.length) || (!matrix && item.observations.length !== 1)) {
      fail("invalid_case_observation", `${side} case ${required.id} has an incomplete theme × viewport observation set`);
    }
    const byObservation = new Map();
    for (const observation of item.observations) {
      const key = `${observation?.theme}|${observation?.viewport?.width}`;
      if (!REQUIRED_THEMES.includes(observation?.theme) || !REQUIRED_VIEWPORT_WIDTHS.includes(observation?.viewport?.width) || byObservation.has(key) || (matrix && !matrix.includes(key))) {
        fail("invalid_case_observation", `${side} case ${required.id} has an invalid or duplicate theme × viewport observation`);
      }
      const state = observation.state;
      const expectedColorScheme = observation.theme === "light" ? "light" : "dark";
      const image = observation.image;
      const documentGeometry = observation.geometry?.find((entry) => entry?.name === `document-${observation.viewport.width}` && entry.viewport_width === observation.viewport.width);
      if (state?.element !== required.element || state?.category !== required.category || state?.theme !== observation.theme || state?.color_scheme !== expectedColorScheme ||
        observation.viewport?.height !== (observation.viewport?.width === 390 ? 844 : 900) || canonicalJson(state?.viewport) !== canonicalJson(observation.viewport) || !state?.focus?.name || !documentGeometry ||
        !Array.isArray(observation.visible_copy) || observation.visible_copy.length === 0 ||
        !isRecord(image) || image.viewport?.width !== observation.viewport.width || image.viewport?.height !== observation.viewport.height ||
        image.full_page_raster?.width !== observation.viewport.width || image.full_page_raster?.height !== documentGeometry?.height || image.capture !== "full-page-real-product-state") {
        fail("invalid_case_observation", `${side} case ${required.id} observation ${key} lacks matching state, focus, copy, geometry or raster metadata`);
      }
      const artifact = artifacts.get(image.path);
      if (!artifact?.present || artifact.sha256 !== image.sha256 || artifact.copied !== true || artifact.copy_status !== "success") {
        fail("invalid_case_artifact", `${side} case ${required.id} observation ${key} must have a copied raw image artifact`);
      }
      if (seenImagePaths.has(image.path)) fail("reused_case_artifact", `${side} receipt reuses a raw image artifact path across cases or observations`);
      seenImagePaths.add(image.path);
      byObservation.set(key, observation);
    }
    if (matrix && matrix.some((key) => !byObservation.has(key))) fail("invalid_case_observation", `${side} case ${required.id} is missing a required theme × viewport observation`);
    byId.set(required.id, { ...item, observations: byObservation });
  }
  if (seenImagePaths.size !== memberPaths.size || [...memberPaths].some((name) => !seenImagePaths.has(name))) fail("invalid_case_bundle", "Raw PNG bundle has members outside its exact case observation inventory");
  return byId;
}

function readBundledPng(bundle, item) {
  const relative = item.path;
  if (typeof relative !== "string" || !relative.startsWith(PRESERVATION_PREFIX) || relative.includes("\\") ||
    relative.split("/").some((part) => part === "" || part === "." || part === ".." || part.startsWith(".")) ||
    path.posix.extname(relative).toLowerCase() !== ".png") {
    fail("invalid_case_artifact", `Case ${item.id} image path is outside the held-out PNG bundle`);
  }
  const members = bundle.rawMembers || rawBundle.loadRunBundle(bundle.runRoot, bundle.receipt?.preservation?.raw_bundle?.sha256);
  const bytes = members.get(relative);
  if (!Buffer.isBuffer(bytes) || bytes.length <= 0 || bytes.length > MAX_IMAGE_BYTES) fail("invalid_case_artifact", `Case ${item.id} PNG is absent or exceeds its bounded image limit`);
  if (digest(bytes) !== item.sha256) fail("case_image_hash_mismatch", `Case ${item.id} PNG does not match its raw SHA-256 receipt`);
  try {
    const decoded = PNG.sync.read(bytes);
    if (decoded.width !== item.full_page_raster?.width || decoded.height !== item.full_page_raster?.height || decoded.width !== item.viewport?.width) {
      fail("case_image_dimensions_mismatch", `Case ${item.id} decoded raster dimensions do not match its observed viewport and full-page geometry`);
    }
  } catch (error) {
    if (error.code) throw error;
    fail("invalid_case_png", `Case ${item.id} artifact is not a readable PNG: ${error.message}`);
  }
  return bytes;
}

function comparePngExact(beforeBytes, candidateBytes, beforeMetadata = null, candidateMetadata = null, identicalDimensions = null) {
  let before;
  let candidate;
  const sameRawBytes = beforeBytes.equals(candidateBytes);
  try {
    const key = sameRawBytes && identicalDimensions ? digest(beforeBytes) : null;
    const prior = key ? identicalDimensions.get(key) : null;
    if (prior && !prior.bytes.equals(beforeBytes)) throw new Error("Equal raw image hashes have different bytes");
    before = prior?.dimensions || PNG.sync.read(beforeBytes);
    candidate = sameRawBytes ? before : PNG.sync.read(candidateBytes);
    if (key && !prior) identicalDimensions.set(key, { bytes: beforeBytes, dimensions: { width: before.width, height: before.height } });
  } catch (error) {
    fail("invalid_pair_png", `A paired raw artifact cannot be decoded as PNG: ${error.message}`);
  }
  if (beforeMetadata && (before.width !== beforeMetadata.full_page_raster?.width || before.height !== beforeMetadata.full_page_raster?.height || before.width !== beforeMetadata.viewport?.width)) {
    fail("before_image_dimensions_mismatch", "Before decoded PNG dimensions do not match its actual capture geometry");
  }
  if (candidateMetadata && (candidate.width !== candidateMetadata.full_page_raster?.width || candidate.height !== candidateMetadata.full_page_raster?.height || candidate.width !== candidateMetadata.viewport?.width)) {
    fail("candidate_image_dimensions_mismatch", "Candidate decoded PNG dimensions do not match its actual capture geometry");
  }
  return {
    equal: before.width === candidate.width && before.height === candidate.height && (sameRawBytes || before.data.equals(candidate.data)),
    before_width: before.width,
    before_height: before.height,
    candidate_width: candidate.width,
    candidate_height: candidate.height
  };
}

function compareValidatedBundles({ authority, before, candidate, readImage } = {}) {
  const { recipeSha256, authoritySha256 } = validateAuthority(authority);
  if (!before || !candidate || !before.eligibility || !candidate.eligibility) fail("invalid_bundle", "Both validated source-bound run receipts are required");
  if (typeof readImage !== "function") fail("missing_image_reader", "A verified run-bundle image reader is required");
  const beforeBundle = { receipt: before, runRoot: null };
  const candidateBundle = { receipt: candidate, runRoot: null };
  const beforeCases = validateReceiptSide(beforeBundle, "before", authority, recipeSha256);
  const candidateCases = validateReceiptSide(candidateBundle, "candidate", authority, recipeSha256);
  const comparisons = [];
  const identicalDimensions = new Map();
  const mismatches = [];
  for (const id of requiredCaseIds()) {
    const left = beforeCases.get(id);
    const right = candidateCases.get(id);
    const required = evidence.preservationCases.find((item) => item.id === id);
    const observationKeys = [...left.observations.keys()].sort();
    if (canonicalJson(observationKeys) !== canonicalJson([...right.observations.keys()].sort())) fail("unmatched_observations", `Before and candidate observation keys differ for ${id}`);
    const viewportComparisons = observationKeys.map((key) => {
      const leftObservation = left.observations.get(key);
      const rightObservation = right.observations.get(key);
      const leftImage = leftObservation.image;
      const rightImage = rightObservation.image;
      return { key, theme: leftObservation.theme, width: leftObservation.viewport.width,
        before_sha256: leftImage.sha256, candidate_sha256: rightImage.sha256,
        state_equal: canonicalJson(leftObservation.state) === canonicalJson(rightObservation.state),
        geometry_equal: canonicalJson(leftObservation.geometry) === canonicalJson(rightObservation.geometry),
        visible_copy_equal: canonicalJson(leftObservation.visible_copy) === canonicalJson(rightObservation.visible_copy),
        assertions_equal: canonicalJson(leftObservation.assertions) === canonicalJson(rightObservation.assertions),
        pixels: comparePngExact(readImage("before", { id, ...leftImage }, before), readImage("candidate", { id, ...rightImage }, candidate), leftImage, rightImage, identicalDimensions) };
    });
    const pixelsEqual = viewportComparisons.every((entry) => entry.pixels.equal);
    const stateEqual = viewportComparisons.every((entry) => entry.state_equal);
    const actionEqual = canonicalJson(left.actions) === canonicalJson(right.actions) && canonicalJson(left.transport_sequence) === canonicalJson(right.transport_sequence);
    const geometryEqual = viewportComparisons.every((entry) => entry.geometry_equal);
    const copyEqual = viewportComparisons.every((entry) => entry.visible_copy_equal);
    const assertionsEqual = viewportComparisons.every((entry) => entry.assertions_equal);
    const identityEqual = left.test_identity === right.test_identity;
    const passed = pixelsEqual && stateEqual && actionEqual && geometryEqual && copyEqual && assertionsEqual && identityEqual;
    if (!passed) mismatches.push({ id, pixels: pixelsEqual, state: stateEqual, actions_and_transport: actionEqual, geometry: geometryEqual, visible_copy: copyEqual, assertions: assertionsEqual, test_identity: identityEqual });
    comparisons.push({
      id,
      test_identity: left.test_identity,
      viewport_comparisons: viewportComparisons,
      pixels_equal: pixelsEqual,
      state_equal: stateEqual,
      actions_and_transport_equal: actionEqual,
      geometry_equal: geometryEqual,
      visible_copy_equal: copyEqual,
      assertions_equal: assertionsEqual,
      test_identity_equal: identityEqual,
      passed
    });
  }
  return {
    schema: PAIR_SCHEMA,
    authority_sha256: authoritySha256,
    qualified_before_source: authority.expected.before,
    candidate_source: authority.expected.candidate,
    fixture_overlay_sha256: authority.expected.fixture_overlay_sha256,
    effective_runtime_sha256: authority.expected.effective_runtime_sha256,
    browser_runtime_builds: { before: authority.expected.before.browser_image_id, candidate: authority.expected.candidate.browser_image_id },
    recipe_sha256: recipeSha256,
    qualified_recipe: authority.expected.recipe,
    cases_compared: comparisons.length,
    passed: mismatches.length === 0,
    status: mismatches.length === 0 ? "exact-match" : "mismatch",
    aesthetic_approval: "not-provided",
    mismatches,
    comparisons
  };
}

function loadAndCompare({ authorityPath, beforePath, candidatePath } = {}) {
  const loadedAuthority = loadAuthority(authorityPath);
  const before = loadReceiptBundle(beforePath, "before", loadedAuthority.authority);
  const candidate = loadReceiptBundle(candidatePath, "candidate", loadedAuthority.authority);
  const report = compareValidatedBundles({
    authority: loadedAuthority.authority,
    before: before.receipt,
    candidate: candidate.receipt,
    readImage: (side, item) => readBundledPng(side === "before" ? before : candidate, item)
  });
  report.authority_sha256 = loadedAuthority.authoritySha256;
  report.before_receipt_sha256 = before.receiptSha256;
  report.candidate_receipt_sha256 = candidate.receiptSha256;
  return report;
}

function ensureOutputDirectory(directory) {
  if (!path.isAbsolute(directory)) fail("invalid_output_path", "--output must be an absolute directory outside the checkout");
  const requested = path.resolve(directory);
  fs.mkdirSync(requested, { recursive: true });
  const output = fs.realpathSync(requested);
  const repositoryRoot = fs.realpathSync(path.resolve(__dirname, "../.."));
  if (output === repositoryRoot || output.startsWith(`${repositoryRoot}${path.sep}`)) fail("invalid_output_path", "Pair comparison output must be outside the checkout");
  return output;
}

function writeOutput(outputDirectory, report) {
  const directory = ensureOutputDirectory(outputDirectory);
  const target = path.join(directory, OUTPUT_NAME);
  const bytes = Buffer.from(`${JSON.stringify(report, null, 2)}\n`);
  if (fs.existsSync(target)) {
    const stat = fs.lstatSync(target);
    if (stat.isSymbolicLink() || !stat.isFile() || !fs.readFileSync(target).equals(bytes)) {
      fail("output_conflict", "Existing pair report differs from the deterministic recomputation; refusing to overwrite");
    }
    return target;
  }
  const temporary = path.join(directory, `.${OUTPUT_NAME}.${process.pid}.${crypto.randomBytes(8).toString("hex")}.tmp`);
  fs.writeFileSync(temporary, bytes, { flag: "wx", mode: 0o600 });
  try {
    fs.linkSync(temporary, target);
  } catch (error) {
    if (error.code !== "EEXIST") throw error;
    const stat = fs.lstatSync(target);
    if (stat.isSymbolicLink() || !stat.isFile() || !fs.readFileSync(target).equals(bytes)) {
      fail("output_conflict", "Concurrent pair report differs from the deterministic recomputation; refusing to overwrite");
    }
  } finally {
    if (fs.existsSync(temporary)) fs.unlinkSync(temporary);
  }
  return target;
}

function parseArgs(argv) {
  if (argv.length !== 9 || argv[0] !== "compare" || argv[1] !== "--authority" || argv[3] !== "--before" ||
    argv[5] !== "--candidate" || argv[7] !== "--output") {
    fail("invalid_arguments", "Usage: node scripts/ci/ui_state_pairs.cjs compare --authority FILE --before FILE --candidate FILE --output DIR");
  }
  return { authorityPath: argv[2], beforePath: argv[4], candidatePath: argv[6], outputDirectory: argv[8] };
}

function main(argv = process.argv.slice(2)) {
  const args = parseArgs(argv);
  const report = loadAndCompare(args);
  const output = writeOutput(args.outputDirectory, report);
  process.stdout.write(`${JSON.stringify({ status: report.status, passed: report.passed, cases_compared: report.cases_compared, output }, null, 2)}\n`);
  return report.passed ? 0 : 1;
}

if (require.main === module) {
  try {
    process.exitCode = main();
  } catch (error) {
    process.stderr.write(`ui-state-pairs: ${error.message}\n`);
    process.exitCode = 1;
  }
}

module.exports = { requiredCaseIds, compareValidatedBundles, comparePngExact, readBundledPng, validateAuthority, loadAuthority, loadReceiptBundle, loadAndCompare, parseArgs, writeOutput };
