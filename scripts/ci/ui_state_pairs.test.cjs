"use strict";

const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const fs = require("node:fs");
const rawBundle = require("./ui_preservation_bundle.cjs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");
const { describe } = test;
const evidence = require("./ecommerce_evidence.cjs");
const build = require("./ecommerce_build.cjs");
const pairs = require("./ui_state_pairs.cjs");
const { PNG } = require("../../examples/scrypath_ecommerce/node_modules/pngjs");

const BEFORE_SHA = "1".repeat(40);
const CANDIDATE_SHA = "2".repeat(40);
const BEFORE_BUILD_SHA = "3".repeat(40);
const CANDIDATE_BUILD_SHA = "4".repeat(40);
const BEFORE_TREE = `sha256:${"a".repeat(64)}`;
const CANDIDATE_TREE = `sha256:${"b".repeat(64)}`;
const FIXTURE = `sha256:${"c".repeat(64)}`;
const RUNTIME = `sha256:${"d".repeat(64)}`;
const BROWSER = `sha256:${"e".repeat(64)}`;
const BROWSER_CANDIDATE = `sha256:${"9".repeat(64)}`;
const APP_BEFORE = `sha256:${"f".repeat(64)}`;
const APP_CANDIDATE = `sha256:${"0".repeat(64)}`;
const OPS_BEFORE = `sha256:${"7".repeat(64)}`;
const OPS_CANDIDATE = `sha256:${"8".repeat(64)}`;
const BASE = `sha256:${"6".repeat(64)}`;
const BEFORE_SOURCE_LAYER = `sha256:${"5".repeat(64)}`;
const CANDIDATE_SOURCE_LAYER = `sha256:${"a".repeat(64)}`;
const CLOCK = `sha256:${"4".repeat(64)}`;
const REQUIRED_THEMES_FOR_TEST = ["light", "dark", "system-dark"];

function digest(bytes) {
  return crypto.createHash("sha256").update(bytes).digest("hex");
}

function canonical(value) {
  return Array.isArray(value)
    ? value.map(canonical)
    : value && typeof value === "object"
      ? Object.fromEntries(Object.keys(value).sort().map((key) => [key, canonical(value[key])]))
      : value;
}

const browser = { engine: "chromium", version: "140.0.0.0", package: "@playwright/test", package_version: "1.60.0" };
const dataRecipe = { protocol: "phase185-test-data-v1", fixture: "synthetic-unit-only" };
const dataRecipeSha = `sha256:${digest(Buffer.from(JSON.stringify(canonical(dataRecipe))))}`;
const profileRecipe = {
  browser,
  launch_args: ["--disable-partial-raster"],
  locale: "en-US",
  timezone: "UTC",
  device_scale_factor: 1,
  font_profile: {
    method: "retained-cdp-fixed-font-v1",
    fixed_font_family: "Liberation Mono",
    applied: "before-first-navigation",
    lifetime: "page-context"
  },
  font_profile_setup: { method: "retained-cdp-fixed-font-v1", font_families: { fixed: "Liberation Mono" }, applied: "before-first-navigation", lifetime: "page-context" }
};
const PROFILE = `sha256:${digest(Buffer.from(JSON.stringify(canonical(profileRecipe))))}`;
const recipe = {
  ...profileRecipe,
  browser_date: { fixed: true, timers_running: true, timer_elapsed_ms: 40, observed: "2026-10-31T23:41:34.668Z" },
  profile_sha256: PROFILE,
  clock_sha256: CLOCK,
  data_recipe_sha256: dataRecipeSha
};
const sharedRecipe = structuredClone(recipe);
delete sharedRecipe.browser_date.timer_elapsed_ms;
const recipeSha = `sha256:${digest(Buffer.from(JSON.stringify(canonical(sharedRecipe))))}`;

function authority() {
  return {
    schema: "scrypath.ui-state-pair-authority.v2",
    qualification: {
      path: "/private/tmp/plan05-qualification.json",
      sha256: `sha256:${"6".repeat(64)}`,
      environment: {
        browser_version: browser.version,
        browser_launch: { timeout: 30000, args: ["--disable-partial-raster"] },
        browser_font_profile: { method: "retained-cdp-fixed-font-v1", font_families: { fixed: "Liberation Mono" }, applied: "before-first-navigation", lifetime: "page-context" },
        clock: { utc: recipe.browser_date.observed, sha256: CLOCK.slice(7), timezone: "UTC", locale: "en-US", browser_mode: "fixed-date" }
      },
      browser_runtime: { browser_image_id: `sha256:${"b".repeat(64)}`, effective_runtime_sha256: RUNTIME, browser_base_layers_sha256: BASE, playwright_package_version: browser.package_version },
      record: {
        schema: "scrypath.phase185-before-qualification.v1",
        status: "qualified",
        source_sha: BEFORE_SHA,
        browser_runtime_equivalence: { rootfs_layers_equal: true, effective_config_equal: true, source_sha: BEFORE_SHA, actual_image_id: `sha256:${"b".repeat(64)}` }
      }
    },
    expected: {
      before: { product_source_sha: BEFORE_SHA, build_source_sha: BEFORE_BUILD_SHA, product_tree_sha256: BEFORE_TREE, fixture_overlay_sha256: FIXTURE,
        application_image_id: APP_BEFORE, standalone_ops_image_id: OPS_BEFORE, browser_image_id: BROWSER, browser_source_layer_id: BEFORE_SOURCE_LAYER,
        browser_base_layers_sha256: BASE, effective_runtime_sha256: RUNTIME },
      candidate: { product_source_sha: CANDIDATE_SHA, build_source_sha: CANDIDATE_BUILD_SHA, product_tree_sha256: CANDIDATE_TREE, fixture_overlay_sha256: FIXTURE,
        application_image_id: APP_CANDIDATE, standalone_ops_image_id: OPS_CANDIDATE, browser_image_id: BROWSER_CANDIDATE, browser_source_layer_id: CANDIDATE_SOURCE_LAYER,
        browser_base_layers_sha256: BASE, effective_runtime_sha256: RUNTIME },
      fixture_overlay_sha256: FIXTURE,
      effective_runtime_sha256: RUNTIME,
      browser_base_layers_sha256: BASE,
      recipe: structuredClone(recipe)
    }
  };
}

function png(width = 1440, height = 900, color = 20) {
  const image = new PNG({ width, height });
  for (let pixel = 0; pixel < image.data.length; pixel += 4) image.data.set([color, 30, 40, 255], pixel);
  return PNG.sync.write(image);
}

// One striped ink rectangle on a background. Stripes (2 px ink, 2 px background) keep every covered 16 px
// block non-uniform, so the structural check can see the rectangle; a solid-color raster is invisible to a
// check that is relative to each block's most common color, and would pass vacuously.
function layoutPng(width, height, { background, ink, blockX, blockY, blockW, blockH }) {
  const image = new PNG({ width, height });
  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      const inside = x >= blockX && x < blockX + blockW && y >= blockY && y < blockY + blockH;
      const color = inside && Math.floor((y - blockY) / 2) % 2 === 0 ? ink : background;
      image.data.set([color[0], color[1], color[2], 255], (y * width + x) * 4);
    }
  }
  return PNG.sync.write(image);
}

const LAYOUT = { background: [20, 30, 40], ink: [200, 180, 60], blockX: 40, blockY: 100, blockW: 128, blockH: 64 };
const LAYOUT_MOVED = { ...LAYOUT, blockX: 200 };
const LAYOUT_RECOLORED = { ...LAYOUT, background: [240, 232, 226], ink: [90, 30, 110] };

// A page of flat rectangles and striped ink, drawn by a callback. Flat regions are one color in both images of
// a pair, which is exactly what the per-block ink share cannot see; their boundaries are what the edge count sees.
function flatPage(draw, { width = 1440, height = 900, background = [20, 30, 40] } = {}) {
  const image = new PNG({ width, height });
  const paint = (x, y, color) => image.data.set([color[0], color[1], color[2], 255], (y * width + x) * 4);
  for (let y = 0; y < height; y += 1) for (let x = 0; x < width; x += 1) paint(x, y, background);
  draw({
    rect: (x, y, w, h, color) => {
      for (let yy = y; yy < y + h; yy += 1) for (let xx = x; xx < x + w; xx += 1) paint(xx, yy, color);
    },
    stripes: (x, y, w, h, color) => {
      for (let yy = y; yy < y + h; yy += 1) if (Math.floor((yy - y) / 2) % 2 === 0) for (let xx = x; xx < x + w; xx += 1) paint(xx, yy, color);
    }
  });
  return PNG.sync.write(image);
}

function runReceipt({ sourceSha, buildSha, productTreeSha, appImageId, opsImageId, browserImageId, sourceLayerId, imageColor = 20, hoverImageColor = imageColor, imageLayout, hoverImageLayout = imageLayout, mutateCase } = {}) {
  const beforeSide = sourceSha === BEFORE_SHA;
  buildSha ??= beforeSide ? BEFORE_BUILD_SHA : CANDIDATE_BUILD_SHA;
  productTreeSha ??= beforeSide ? BEFORE_TREE : CANDIDATE_TREE;
  appImageId ??= beforeSide ? APP_BEFORE : APP_CANDIDATE;
  opsImageId ??= beforeSide ? OPS_BEFORE : OPS_CANDIDATE;
  browserImageId ??= beforeSide ? BROWSER : BROWSER_CANDIDATE;
  sourceLayerId ??= beforeSide ? BEFORE_SOURCE_LAYER : CANDIDATE_SOURCE_LAYER;
  const imageBytesByDimensions = new Map();
  const hoverImageBytesByDimensions = new Map();
  const hoverImageBytesByPath = new Map();
  const sampledEntries = [];
  const cases = evidence.preservationCases.map((entry) => {
    const matrix = entry.category === "overflow" || entry.category === "long-text"
      ? ["light", "dark", "system-dark"].flatMap((theme) => [1440, 768, 390].map((width) => ({ theme, width })))
      : [{ theme: "light", width: 1440 }];
    const observations = matrix.map(({ theme, width }) => {
      const height = width === 390 ? 844 : 900;
      const imageKey = `${width}x${height}`;
      if (!imageBytesByDimensions.has(imageKey)) imageBytesByDimensions.set(imageKey, imageLayout ? layoutPng(width, height, imageLayout) : png(width, height, imageColor));
      const imageBytes = imageBytesByDimensions.get(imageKey);
      const image = {
        path: `ui-review-artifacts/iteration3-journeys/phase185-held-out/${entry.id.replaceAll(" ", "-").toLowerCase()}-${theme}-${width}.png`,
        sha256: digest(imageBytes),
        viewport: { width, height },
        full_page_raster: { width, height },
        capture: "full-page-real-product-state"
      };
      const copy = `Visible ${entry.id} ${theme} ${width}`;
      const interactionTarget = { tag: "button", role: "button", name: `control-${entry.id}-${theme}-${width}`, href: null };
      const focus = { name: interactionTarget.name, role: interactionTarget.role, tag: interactionTarget.tag, focus_visible: true, outline: { style: "solid", width: "2px", color: "rgb(0, 0, 0)" }, opacity: "1", document_has_focus: true };
      const primaryDomState = { schema: "scrypath.ui-capture-state.v1", body_text: copy, viewport: { width, height }, scroll: { x: 0, y: 0 }, focus, hover: [] };
      const hoverFocus = { ...focus, outline: { ...focus.outline, color: "rgb(20, 30, 40)" }, opacity: "0.95" };
      const hoverDomState = { ...primaryDomState, focus: hoverFocus, hover: [{ element: interactionTarget, rect: { x: 20, y: 30, width: 120, height: 32 } }] };
      const stateHash = (value) => digest(Buffer.from(JSON.stringify(canonical(value))));
      const primaryState = {
        element: entry.element,
        category: entry.category,
        route: entry.element === "E1" ? "/" : "/admin/search/search",
        theme,
        color_scheme: theme === "light" ? "light" : "dark",
        viewport: { width, height },
        scroll: { x: 0, y: 0 },
        focus,
        interaction_target: interactionTarget,
        hover: [],
        data_identity: `data-${entry.id}`,
        dom_state_sha256: stateHash(primaryDomState),
        clock: { browser_iso: recipe.browser_date.observed, server_iso: recipe.browser_date.observed, clock_sha256: CLOCK }
      };
      const hoverState = { ...primaryState, focus: hoverFocus, hover: hoverDomState.hover, dom_state_sha256: stateHash(hoverDomState) };
      const samplingFor = (captureImage, bytes, domState) => {
        const snapshotBytes = Buffer.from(JSON.stringify({ ...domState, before: domState, after: domState }, null, 2) + "\n");
        const samples = [0, 1].map((index) => {
          const samplePath = captureImage.path.replace(/\.png$/, `-sample-${index}.png`);
          const statePath = captureImage.path.replace(/\.png$/, `-sample-${index}.json`);
          sampledEntries.push({ path: samplePath, bytes }, { path: statePath, bytes: snapshotBytes });
          return { path: samplePath, state_path: statePath, sha256: digest(bytes), state_sha256: digest(snapshotBytes), elapsed_ms: 10 + index };
        });
        return { method: "consecutive-exact-v1", max_samples: 6, max_elapsed_ms: 10000, selected: 1, samples };
      };
      const primarySampling = samplingFor(image, imageBytes, primaryDomState);
      if (!hoverImageBytesByDimensions.has(imageKey)) hoverImageBytesByDimensions.set(imageKey, hoverImageLayout ? layoutPng(width, height, hoverImageLayout) : png(width, height, hoverImageColor));
      const hoverImageBytes = hoverImageBytesByDimensions.get(imageKey);
      const hoverImage = {
        path: image.path.replace(/\.png$/, "--hover.png"),
        sha256: digest(hoverImageBytes),
        viewport: { width, height },
        viewport_raster: { width, height },
        capture: "viewport-real-product-hover"
      };
      hoverImageBytesByPath.set(hoverImage.path, hoverImageBytes);
      const hoverSampling = samplingFor(hoverImage, hoverImageBytes, hoverDomState);
      const hoverAssertions = [{ name: "actual named control has pointer hover", status: "passed", actual: JSON.stringify({ interaction_target: interactionTarget, hover: hoverState.hover }) }];
      return {
        theme,
        viewport: { width, height },
        capture_profile: "fullpage-neutral-and-viewport-hover-v1",
        state: primaryState,
        interaction_target: interactionTarget,
        geometry: [
          { name: `element-${entry.element}`, x: 0, y: 0, width: 100, height: 20, viewport_width: width },
          { name: `document-${width}`, x: 0, y: 0, width, height, viewport_width: width }
        ],
        assertions: [{ name: `assert-${entry.id}-${theme}-${width}`, status: "passed", actual: `observed-${entry.id}` }],
        visible_copy: [{ text: copy, sha256: digest(Buffer.from(copy)) }],
        capture_sampling: primarySampling,
        image,
        hover_capture: { state: hoverState, image: hoverImage, capture_sampling: hoverSampling, assertions: hoverAssertions }
      };
    });
    const item = {
      id: entry.id,
      test_identity: JSON.stringify([entry.file, "chromium", [path.posix.basename(entry.file), `${entry.id} held-out assertion`], "shared"]),
      product_source_sha: sourceSha,
      build_source_sha: buildSha,
      product_tree_sha256: productTreeSha,
      fixture_overlay_sha256: FIXTURE,
      recipe_sha256: recipeSha,
      runtime: { application_image_id: appImageId, standalone_ops_image_id: opsImageId, browser_image_id: browserImageId, browser_source_layer_id: sourceLayerId, browser_base_layers_sha256: BASE, effective_runtime_sha256: RUNTIME },
      clock_recipe: recipe,
      data_recipe: structuredClone(dataRecipe),
      actions: ["navigate", "observe"],
      assertions: [{ name: "exact case semantics", status: "passed", actual: "0,1,5" }],
      transport_sequence: [{ operation: "liveview-connected", outcome: "connected" }],
      observations
    };
    return mutateCase?.(item) || item;
  });
  const rawEntries = cases.flatMap((item) => item.observations.flatMap(({ image, hover_capture: hoverCapture }) => [
    { path: image.path, bytes: imageBytesByDimensions.get(`${image.full_page_raster.width}x${image.full_page_raster.height}`) },
    { path: hoverCapture.image.path, bytes: hoverImageBytesByPath.get(hoverCapture.image.path) }
  ]));
  rawEntries.push(...sampledEntries);
  const packed = rawBundle.encodeBundle(rawEntries);
  const rawMetadata = { path: rawBundle.BUNDLE_PATH, sha256: digest(packed), size_bytes: packed.length, members: rawEntries.map((item) => ({ path: item.path, sha256: digest(item.bytes), size_bytes: item.bytes.length })) };
  return {
    eligibility: { eligible: true },
    scope: beforeSide ? "before-only" : "full",
    source: { checkout_head: buildSha, built_source_sha: buildSha, product_source_sha: sourceSha,
      ...(beforeSide ? { qualification_sha256: authority().qualification.sha256 } : {}) },
    images: { application: { runtime_id: appImageId }, standalone_ops: { runtime_id: opsImageId }, browser: { runtime_id: browserImageId } },
    browser: structuredClone(browser),
    artifacts: [{ path: rawBundle.BUNDLE_PATH, sha256: rawMetadata.sha256, size_bytes: packed.length, present: true, copied: true, copy_status: "success" }],
    preservation: {
      schema: beforeSide ? "scrypath.ui-preservation-before-only.v2" : "scrypath.ui-preservation.v2",
      product_source_sha: sourceSha,
      build_source_sha: buildSha,
      product_tree_sha256: productTreeSha,
      fixture_overlay_sha256: FIXTURE,
      raw_bundle: rawMetadata,
      cases
    },
    imageBytesByDimensions,
    hoverImageBytesByPath
  };
}

function compare(before = runReceipt({ sourceSha: BEFORE_SHA, buildSha: BEFORE_BUILD_SHA, productTreeSha: BEFORE_TREE, appImageId: APP_BEFORE, opsImageId: OPS_BEFORE, browserImageId: BROWSER, sourceLayerId: BEFORE_SOURCE_LAYER }),
  candidate = runReceipt({ sourceSha: CANDIDATE_SHA, buildSha: CANDIDATE_BUILD_SHA, productTreeSha: CANDIDATE_TREE, appImageId: APP_CANDIDATE, opsImageId: OPS_CANDIDATE, browserImageId: BROWSER_CANDIDATE, sourceLayerId: CANDIDATE_SOURCE_LAYER }),
  expectedAuthority = authority()) {
  return pairs.compareValidatedBundles({
    authority: expectedAuthority,
    before,
    candidate,
    readImage: (_side, item, receipt) => item.capture === "viewport-real-product-hover"
      ? receipt.hoverImageBytesByPath.get(item.path)
      : receipt.imageBytesByDimensions.get(`${item.viewport.width}x${item.viewport.height}`)
  });
}

test("source-paired comparator requires exact matched state receipt pairs", () => {
  assert.deepEqual(pairs.requiredCaseIds?.(), evidence.preservationCases.map(({ id }) => id));
  const report = compare();

  assert.equal(report.passed, true);
  assert.equal(report.comparisons.length, 61);
  assert.equal(report.comparisons.reduce((sum, item) => sum + item.viewport_comparisons.length, 0), 213);
  assert.equal(report.schema, "scrypath.ui-state-pair-comparison.v4");
  assert.equal(report.status, "structural-match", "a pass is a structural match, never worded as pixel-identical");
  assert.equal(report.pixel_comparison, "structural-recolor-tolerant-v1");
  assert.ok(report.comparisons.filter((item) => item.id.endsWith("overflow") || item.id.endsWith("long-text")).every((item) =>
    item.viewport_comparisons.length === 9 && REQUIRED_THEMES_FOR_TEST.every((theme) => [1440, 768, 390].every((width) => item.viewport_comparisons.some((observation) => observation.theme === theme && observation.width === width)))
  ));
  assert.equal(report.aesthetic_approval, "not-provided");
});

test("source-paired comparator reports the separate real viewport-hover raster", () => {
  const before = runReceipt({ sourceSha: BEFORE_SHA, productTreeSha: BEFORE_TREE, appImageId: APP_BEFORE });
  const candidate = runReceipt({ sourceSha: CANDIDATE_SHA, productTreeSha: CANDIDATE_TREE, appImageId: APP_CANDIDATE });
  const primary = before.preservation.cases[0].observations[0];
  assert.notDeepEqual(primary.state.focus, primary.hover_capture.state.focus);
  const report = compare(before, candidate);
  const observation = report.comparisons[0].viewport_comparisons[0];

  assert.equal(observation.hover_pixels.equal, true);
  assert.equal(report.comparisons[0].hover_pixels_equal, true);
});

test("a source pair requires independent neutral and hover captures with bounded raw inventories", () => {
  const before = runReceipt({ sourceSha: BEFORE_SHA, productTreeSha: BEFORE_TREE, appImageId: APP_BEFORE });
  const candidate = runReceipt({ sourceSha: CANDIDATE_SHA, productTreeSha: CANDIDATE_TREE, appImageId: APP_CANDIDATE });
  const observation = candidate.preservation.cases[0].observations[0];
  const expectedHover = observation.hover_capture;
  const candidateSchema = candidate.preservation.schema;
  candidate.preservation.schema = "scrypath.ui-preservation.v1";
  assert.throws(() => compare(before, candidate), /execution scope or preservation schema/i, "old single-capture receipt schema is not compatible");
  candidate.preservation.schema = candidateSchema;
  const checks = [
    ["missing hover capture", () => { delete observation.hover_capture; }, () => { observation.hover_capture = expectedHover; }],
    ["unknown capture profile", () => { observation.capture_profile = "single-image-v1"; }, () => { observation.capture_profile = "fullpage-neutral-and-viewport-hover-v1"; }],
    ["non-neutral primary state", () => { observation.state.hover = expectedHover.state.hover; }, () => { observation.state.hover = []; }],
    ["hover state for a different route", () => { expectedHover.state.route = "/admin/other"; }, () => { expectedHover.state.route = observation.state.route; }],
    ["hover image with an unsupported capture kind", () => { expectedHover.image.capture = "full-page-real-product-state"; }, () => { expectedHover.image.capture = "viewport-real-product-hover"; }],
    ["incorrect hover viewport raster", () => { expectedHover.image.viewport_raster.width += 1; }, () => { expectedHover.image.viewport_raster.width -= 1; }],
    ["unbounded hover sample proof", () => { expectedHover.capture_sampling.selected = 0; }, () => { expectedHover.capture_sampling.selected = 1; }]
  ];
  for (const [label, mutate, restore] of checks) {
    mutate();
    assert.throws(() => compare(before, candidate), /hover|sampling|capture|raster/i, label);
    restore();
  }

  const members = candidate.preservation.raw_bundle.members;
  candidate.preservation.raw_bundle.members = members.filter((member) => member.path !== expectedHover.image.path);
  assert.throws(() => compare(before, candidate), /hover|artifact|bundle/i, "missing hover image bundle member");
  candidate.preservation.raw_bundle.members = members;
  const imageMember = members.find((member) => member.path === expectedHover.image.path);
  const originalMemberHash = imageMember.sha256;
  imageMember.sha256 = "0".repeat(64);
  assert.throws(() => compare(before, candidate), /hover|artifact|hash/i, "altered hover image member hash");
  imageMember.sha256 = originalMemberHash;
});

test("hover state and assertions participate in the exact source-pair result", () => {
  const before = runReceipt({ sourceSha: BEFORE_SHA, productTreeSha: BEFORE_TREE, appImageId: APP_BEFORE });
  const candidate = runReceipt({ sourceSha: CANDIDATE_SHA, productTreeSha: CANDIDATE_TREE, appImageId: APP_CANDIDATE });
  const observation = candidate.preservation.cases[0].observations[0];
  observation.hover_capture.state.hover[0].rect.x += 1;
  observation.hover_capture.assertions[0].actual = "the actual pointer target and viewport were observed";

  const report = compare(before, candidate);
  const result = report.comparisons[0].viewport_comparisons[0];
  assert.equal(result.state_equal, true);
  assert.equal(result.hover_state_equal, false);
  assert.equal(result.assertions_equal, true);
  assert.equal(result.hover_assertions_equal, false);
  assert.equal(result.full_page_pixels.equal, true);
  assert.equal(result.hover_pixels.equal, true);
  assert.equal(report.comparisons[0].passed, false);
  assert.equal(report.passed, false);
});

// 186 verification finding 2: every other state mutation here changes the neutral and the hover state
// together, so dropping the neutral `stateEqual` term from the verdict stayed green. This one changes the
// neutral capture's state alone and leaves the hover capture's state untouched, so only the neutral term can
// reject it. The receipt validator makes the route, data, clock, scroll and focus identity of the two captures
// agree, so the one field a valid receipt may change on the neutral side only is the focus ring styling
// (outline and opacity), which the hover capture keeps as its own.
test("a neutral-only state change fails the pair while the hover state is unchanged", () => {
  const before = runReceipt({ sourceSha: BEFORE_SHA, productTreeSha: BEFORE_TREE, appImageId: APP_BEFORE });
  const candidate = runReceipt({ sourceSha: CANDIDATE_SHA, productTreeSha: CANDIDATE_TREE, appImageId: APP_CANDIDATE });
  const observation = candidate.preservation.cases[0].observations[0];
  const hoverFocus = structuredClone(observation.hover_capture.state.focus);
  observation.state.focus.opacity = "0.5";
  assert.deepEqual(observation.hover_capture.state.focus, hoverFocus, "the hover capture's state is untouched");

  const report = compare(before, candidate);
  const result = report.comparisons[0].viewport_comparisons[0];
  assert.equal(result.state_equal, false);
  assert.equal(result.hover_state_equal, true);
  assert.equal(result.assertions_equal, true);
  assert.equal(result.hover_assertions_equal, true);
  assert.equal(result.full_page_pixels.equal, true);
  assert.equal(result.hover_pixels.equal, true);
  assert.equal(report.comparisons[0].passed, false);
  assert.equal(report.passed, false);
  assert.equal(report.mismatches[0].state, false, "the neutral state term rejects the pair");
  assert.equal(report.mismatches[0].hover_state, true, "the hover state term is not what rejected it");
});

test("structural PNG comparison selects viewport raster dimensions only for the explicit hover capture kind", () => {
  const small = { background: [20, 30, 40], ink: [200, 180, 60], blockX: 0, blockY: 0, blockW: 32, blockH: 16 };
  const hoverBefore = layoutPng(64, 32, small);
  const hoverCandidate = layoutPng(64, 32, { ...small, blockX: 32, blockY: 16 });
  const metadata = {
    viewport: { width: 64, height: 32 },
    viewport_raster: { width: 64, height: 32 },
    capture: "viewport-real-product-hover"
  };
  const pixels = pairs.comparePngStructural(hoverBefore, hoverCandidate, metadata, metadata);
  assert.equal(pixels.equal, false);
  assert.ok(pixels.blocks_over > 0, "the moved block is seen by the structural grid");
  assert.equal(pixels.before_width, 64);
  assert.equal(pixels.before_height, 32);
  assert.throws(() => pairs.comparePngStructural(hoverBefore, hoverCandidate, {
    ...metadata, capture: "unsupported", full_page_raster: { width: 64, height: 33 }
  }, metadata), /dimensions/i);
});

test("a hover-only raster change fails while the neutral full-page raster still matches", () => {
  const before = runReceipt({ sourceSha: BEFORE_SHA, productTreeSha: BEFORE_TREE, appImageId: APP_BEFORE, imageLayout: LAYOUT });
  const candidate = runReceipt({ sourceSha: CANDIDATE_SHA, productTreeSha: CANDIDATE_TREE, appImageId: APP_CANDIDATE, imageLayout: LAYOUT, hoverImageLayout: LAYOUT_MOVED });
  const report = compare(before, candidate);
  const result = report.comparisons[0];

  assert.equal(result.full_page_pixels_equal, true);
  assert.equal(result.hover_pixels_equal, false);
  assert.equal(result.pixels_equal, false);
  assert.equal(result.passed, false);
  assert.equal(report.passed, false);
});

test("a source pair rejects missing, extra or duplicate preservation receipts", () => {
  const before = runReceipt({ sourceSha: BEFORE_SHA, productTreeSha: BEFORE_TREE, appImageId: APP_BEFORE });
  const candidate = runReceipt({ sourceSha: CANDIDATE_SHA, productTreeSha: CANDIDATE_TREE, appImageId: APP_CANDIDATE });
  candidate.preservation.cases.pop();
  assert.throws(() => compare(before, candidate), /exactly 61|missing.*case/i);

  candidate.preservation.cases = runReceipt({ sourceSha: CANDIDATE_SHA, productTreeSha: CANDIDATE_TREE, appImageId: APP_CANDIDATE }).preservation.cases;
  candidate.preservation.cases.push({ ...candidate.preservation.cases[0] });
  assert.throws(() => compare(before, candidate), /duplicate/i);
});

test("a source pair rejects independently mismatched source, fixture, runtime and recipe identities", () => {
  const mismatches = [
    (candidate) => { candidate.source.checkout_head = BEFORE_SHA; },
    (candidate) => { candidate.preservation.fixture_overlay_sha256 = `sha256:${"9".repeat(64)}`; },
    (candidate) => { candidate.preservation.cases[0].runtime.effective_runtime_sha256 = `sha256:${"9".repeat(64)}`; },
    (candidate) => { candidate.preservation.cases[0].recipe_sha256 = `sha256:${"9".repeat(64)}`; },
    (candidate) => { candidate.browser.version = "139.0.0.0"; }
  ];
  for (const mutate of mismatches) {
    const candidate = runReceipt({ sourceSha: CANDIDATE_SHA, productTreeSha: CANDIDATE_TREE, appImageId: APP_CANDIDATE });
    mutate(candidate);
    assert.throws(() => compare(undefined, candidate), /source|fixture|runtime|recipe|browser/i);
  }
  const unqualifiedRecipe = authority();
  unqualifiedRecipe.expected.recipe.font_profile.fixed_font_family = "Monospace";
  assert.throws(() => compare(undefined, undefined, unqualifiedRecipe), /qualified raster|font profile/);
});

test("a source pair fails structural pixels, geometry, state, copy and semantic assertions", () => {
  const changes = [
    (item) => { item.observations[0].geometry[0].width += 1; },
    (item) => {
      const observation = item.observations[0];
      const target = { ...observation.state.interaction_target, name: "different focus" };
      observation.state.focus.name = target.name;
      observation.state.interaction_target = target;
      observation.hover_capture.state.focus.name = target.name;
      observation.hover_capture.state.interaction_target = target;
      observation.hover_capture.state.hover[0].element = target;
      observation.interaction_target = target;
    },
    (item) => { item.observations[0].visible_copy[0].text = "different visible copy"; },
    (item) => { item.observations[0].assertions[0].actual = "different assertion"; },
    (item) => { item.assertions[0].actual = "0,1,4"; }
  ];
  for (const mutate of changes) {
    const candidate = runReceipt({ sourceSha: CANDIDATE_SHA, productTreeSha: CANDIDATE_TREE, appImageId: APP_CANDIDATE, mutateCase: mutate });
    const report = compare(undefined, candidate);
    assert.equal(report.passed, false);
  }

  // Each of these changes exactly one input and nothing else, so each fails only through its own term of the
  // verdict. Dropping `actionEqual` or `identityEqual` from `passed` turns the matching entry red.
  const isolated = [
    ["actions", "actions_and_transport", (item) => { item.actions[1] = "observe-changed"; }],
    ["transport_sequence", "actions_and_transport", (item) => { item.transport_sequence[0].outcome = "reconnected"; }],
    ["test_identity", "test_identity", (item) => { item.test_identity = `${item.test_identity} changed`; }]
  ];
  for (const [label, flag, mutate] of isolated) {
    const candidate = runReceipt({ sourceSha: CANDIDATE_SHA, productTreeSha: CANDIDATE_TREE, appImageId: APP_CANDIDATE, mutateCase: mutate });
    const report = compare(undefined, candidate);
    assert.equal(report.passed, false, `${label} change alone fails the pair`);
    assert.equal(report.mismatches[0][flag], false, `${label} change is reported through ${flag}`);
    assert.equal(report.mismatches[0].pixels, true, `${label} change leaves pixels equal`);
  }

  const layoutBefore = runReceipt({ sourceSha: BEFORE_SHA, productTreeSha: BEFORE_TREE, appImageId: APP_BEFORE, imageLayout: LAYOUT });
  const pixelChanged = runReceipt({ sourceSha: CANDIDATE_SHA, productTreeSha: CANDIDATE_TREE, appImageId: APP_CANDIDATE, imageLayout: LAYOUT_MOVED });
  assert.equal(compare(layoutBefore, pixelChanged).passed, false);
});

test("a recolor-only candidate passes the source pair when all other evidence matches", () => {
  const before = runReceipt({ sourceSha: BEFORE_SHA, productTreeSha: BEFORE_TREE, appImageId: APP_BEFORE, imageLayout: LAYOUT });
  const candidate = runReceipt({ sourceSha: CANDIDATE_SHA, productTreeSha: CANDIDATE_TREE, appImageId: APP_CANDIDATE, imageLayout: LAYOUT_RECOLORED });
  assert.ok(!before.imageBytesByDimensions.get("1440x900").equals(candidate.imageBytesByDimensions.get("1440x900")), "the candidate rasters really are recolored");

  const report = compare(before, candidate);
  assert.equal(report.passed, true);
  assert.deepEqual(report.mismatches, []);
  assert.ok(report.comparisons.every((item) => item.pixels_equal && item.full_page_pixels_equal && item.hover_pixels_equal));
});

test("real timer elapsed samples may differ while the shared fixed-clock recipe remains exact", () => {
  const before = runReceipt({ sourceSha: BEFORE_SHA, productTreeSha: BEFORE_TREE, appImageId: APP_BEFORE });
  before.preservation.cases[0].clock_recipe.browser_date.timer_elapsed_ms = 83;

  const report = compare(before);
  assert.equal(report.passed, true);
});

test("the declared viewport and full-page raster dimensions must match decoded PNG bytes", () => {
  const before = runReceipt({ sourceSha: BEFORE_SHA, productTreeSha: BEFORE_TREE, appImageId: APP_BEFORE });
  const bytes = png(1, 1);
  const image = before.preservation.cases[0].observations[0].image;
  const sampling = before.preservation.cases[0].observations[0].capture_sampling;
  const sha = digest(bytes);
  before.imageBytesByDimensions.set("1440x900", bytes);
  image.sha256 = sha;
  for (const sample of sampling.samples) sample.sha256 = sha;
  for (const member of before.preservation.raw_bundle.members) {
    if (member.path === image.path || sampling.samples.some((sample) => sample.path === member.path)) member.sha256 = sha;
  }

  assert.throws(() => compare(before), /raster|dimension|viewport/i);
});

test("raw image artifact paths cannot be reused across distinct preservation cases", () => {
  const before = runReceipt({ sourceSha: BEFORE_SHA, productTreeSha: BEFORE_TREE, appImageId: APP_BEFORE });
  before.preservation.cases[1].observations[0].image.path = before.preservation.cases[0].observations[0].image.path;

  assert.throws(() => compare(before), /reus|unique|artifact path/i);
});

test("overflow and long-text cases require every light, dark and system-dark viewport observation", () => {
  const before = runReceipt({ sourceSha: BEFORE_SHA, productTreeSha: BEFORE_TREE, appImageId: APP_BEFORE });
  const overflow = before.preservation.cases.find((item) => item.id === "E1 overflow");
  overflow.observations = [
    { theme: "light", viewport: { width: 1440, height: 900 } },
    { theme: "dark", viewport: { width: 1440, height: 900 } },
    { theme: "system-dark", viewport: { width: 1440, height: 900 } }
  ];

  assert.throws(() => compare(before), /observation|viewport|theme/i);
});

test("before-only and candidate full-run receipt filenames cannot be cross-used", () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "scrypath-pair-scope-"));
  try {
    const beforePath = path.join(directory, "phase185-before-only-evidence.json");
    const candidatePath = path.join(directory, "phase105-evidence.json");
    fs.writeFileSync(beforePath, JSON.stringify({ schema_version: 1 }));
    fs.writeFileSync(candidatePath, JSON.stringify({ schema_version: 1 }));

    assert.throws(() => pairs.loadReceiptBundle(beforePath, "candidate", authority()), /candidate.*phase105-evidence/i);
    assert.throws(() => pairs.loadReceiptBundle(candidatePath, "before", authority()), /before.*phase185-before-only-evidence/i);
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});

test("the fixed CLI accepts only the documented argv order", () => {
  assert.deepEqual(pairs.parseArgs([
    "compare", "--authority", "/tmp/authority.json", "--before", "/tmp/before/phase105-evidence.json",
    "--candidate", "/tmp/candidate/phase105-evidence.json", "--output", "/tmp/pair"
  ]), {
    authorityPath: "/tmp/authority.json",
    beforePath: "/tmp/before/phase105-evidence.json",
    candidatePath: "/tmp/candidate/phase105-evidence.json",
    outputDirectory: "/tmp/pair"
  });
  assert.throws(() => pairs.parseArgs(["compare", "--before", "/tmp/before.json"]), /Usage/);
});

test("authority loads only when its qualification bytes match the supplied digest", () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "scrypath-pair-authority-"));
  try {
    const value = authority();
    const repositoryRoot = path.resolve(__dirname, "../..");
    const inspectionPath = path.join(directory, "browser-inspection.json");
    const inspection = [{
      Id: value.qualification.browser_runtime.browser_image_id,
      RootFS: { Layers: ["sha256:1111111111111111111111111111111111111111111111111111111111111111", "sha256:2222222222222222222222222222222222222222222222222222222222222222", "sha256:5f70bf18a086007016e948b04aed3b82103a36bea41755b6cddfaf10ace3c6ef"] },
      Config: { WorkingDir: "/app/examples/scrypath_ecommerce", Labels: { "org.opencontainers.image.revision": BEFORE_SHA } },
      Architecture: "arm64", Os: "linux", DockerVersion: "27.0.0"
    }];
    fs.writeFileSync(inspectionPath, JSON.stringify(inspection));
    const qualifiedRuntime = build.phase185RuntimeIdentity({ inspectionPath, repoRoot: repositoryRoot });
    value.qualification.browser_runtime = qualifiedRuntime;
    value.expected.before.effective_runtime_sha256 = qualifiedRuntime.effective_runtime_sha256;
    value.expected.candidate.effective_runtime_sha256 = qualifiedRuntime.effective_runtime_sha256;
    value.expected.effective_runtime_sha256 = qualifiedRuntime.effective_runtime_sha256;
    value.expected.before.browser_base_layers_sha256 = qualifiedRuntime.browser_base_layers_sha256;
    value.expected.candidate.browser_base_layers_sha256 = qualifiedRuntime.browser_base_layers_sha256;
    value.expected.browser_base_layers_sha256 = qualifiedRuntime.browser_base_layers_sha256;
    value.qualification.browser_inspection_path = inspectionPath;
    value.qualification.capture_path = path.join(directory, "capture.json");
    const capture = {
      source: { source_sha: BEFORE_SHA },
      environment: structuredClone(value.qualification.environment)
    };
    const captureBytes = Buffer.from(JSON.stringify(capture));
    fs.writeFileSync(value.qualification.capture_path, captureBytes);
    const qualificationPath = path.join(directory, "qualification.json");
    value.qualification.record.actual_before_sha256 = digest(captureBytes);
    value.qualification.record.pinned_files = [
      { path: value.qualification.capture_path, sha256: digest(captureBytes) },
      { path: inspectionPath, sha256: digest(Buffer.from(JSON.stringify(inspection))) }
    ];
    const qualificationBytes = Buffer.from(`${JSON.stringify(value.qualification.record, null, 2)}\n`);
    fs.writeFileSync(qualificationPath, qualificationBytes);
    value.qualification.path = qualificationPath;
    value.qualification.sha256 = `sha256:${digest(qualificationBytes)}`;
    const authorityPath = path.join(directory, "authority.json");
    fs.writeFileSync(authorityPath, JSON.stringify(value));

    const loaded = pairs.loadAuthority(authorityPath);
    assert.equal(loaded.authority.expected.before.product_source_sha, BEFORE_SHA);
    assert.throws(() => pairs.loadAuthority(authorityPath.replace("authority.json", "missing.json")), /ENOENT/);

    value.qualification.sha256 = `sha256:${"9".repeat(64)}`;
    fs.writeFileSync(authorityPath, JSON.stringify(value));
    assert.throws(() => pairs.loadAuthority(authorityPath), /qualification file does not match/);
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});

test("receipt loading requires a complete recomputable evidence bundle", () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "scrypath-pair-receipt-"));
  try {
    const receiptPath = path.join(directory, "phase185-before-only-evidence.json");
    fs.writeFileSync(receiptPath, JSON.stringify({ schema_version: 1 }));
    assert.throws(() => pairs.loadReceiptBundle(receiptPath, "before", authority()), /not independently recomputable and eligible/);
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});

test("run PNG loading verifies path containment, raw hashes and decoded image bytes", () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "scrypath-pair-png-"));
  try {
    const relative = "ui-review-artifacts/iteration3-journeys/phase185-held-out/e1-empty.png";
    const absolute = path.join(directory, relative);
    fs.mkdirSync(path.dirname(absolute), { recursive: true });
    const bytes = png(1440, 900);
    fs.writeFileSync(absolute, bytes);
    const rawMembers = new Map([[relative, bytes]]);
    const item = { id: "E1 empty", path: relative, sha256: digest(bytes), viewport: { width: 1440, height: 900 }, full_page_raster: { width: 1440, height: 900 } };

    assert.deepEqual(pairs.readBundledPng({ runRoot: directory, rawMembers }, item), bytes);
    assert.throws(() => pairs.readBundledPng({ runRoot: directory, rawMembers }, { ...item, sha256: "1".repeat(64) }), /raw SHA-256/);
    assert.throws(() => pairs.readBundledPng({ runRoot: directory, rawMembers }, { ...item, path: "../outside.png" }), /outside the held-out PNG bundle/);

    const hoverRelative = "ui-review-artifacts/iteration3-journeys/phase185-held-out/e1-empty-hover.png";
    const hoverAbsolute = path.join(directory, hoverRelative);
    const hoverBytes = png(1440, 900, 21);
    fs.writeFileSync(hoverAbsolute, hoverBytes);
    rawMembers.set(hoverRelative, hoverBytes);
    const hoverItem = { id: "E1 empty", path: hoverRelative, sha256: digest(hoverBytes), capture: "viewport-real-product-hover", viewport: { width: 1440, height: 900 }, viewport_raster: { width: 1440, height: 900 } };
    assert.deepEqual(pairs.readBundledPng({ runRoot: directory, rawMembers }, hoverItem), hoverBytes);
    assert.throws(() => pairs.readBundledPng({ runRoot: directory, rawMembers }, { ...hoverItem, capture: "unknown", full_page_raster: { width: 1440, height: 899 } }), /dimensions/i);
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});

// Real v1.43 captures, cropped to whole rows and committed beside the tests (see PROVENANCE.md there), so the
// tests do not depend on the .planning archive. A missing fixture fails the test; it never skips.
const CALIBRATION_DIR = path.join(__dirname, "fixtures/ui-state-pairs");

function calibrationFixture(name) {
  const file = path.join(CALIBRATION_DIR, name);
  assert.ok(fs.existsSync(file), `calibration fixture is missing: ${file}`);
  const bytes = fs.readFileSync(file);
  const decoded = PNG.sync.read(bytes);
  assert.equal(decoded.width, 390, `${name} width`);
  assert.equal(decoded.height, 320, `${name} height`);
  return { bytes, decoded };
}

function shiftBand(decoded, firstRow, rows, dy) {
  const shifted = new PNG({ width: decoded.width, height: decoded.height });
  decoded.data.copy(shifted.data);
  const stride = decoded.width * 4;
  for (let row = firstRow + rows - 1; row >= firstRow; row -= 1) decoded.data.copy(shifted.data, (row + dy) * stride, row * stride, (row + 1) * stride);
  return PNG.sync.write(shifted);
}

describe("structural calibration on real captures", () => {
  test("calibration accepts a real recolor pair", () => {
    const before = calibrationFixture("recolor-before-dark-390x320.png");
    const after = calibrationFixture("recolor-after-dark-390x320.png");
    assert.ok(!before.decoded.data.equals(after.decoded.data), "the pair really is recolored, not the identical-bytes shortcut");

    const result = pairs.comparePngStructural(before.bytes, after.bytes);
    assert.equal(result.equal, true);
    assert.equal(result.blocks, 500);
    assert.equal(result.blocks_over, 0);
    assert.equal(result.edge_blocks_over, 0);
    assert.ok(result.worst_edge_delta <= 4, `a real recolor leaves the edge count nearly unchanged, saw ${result.worst_edge_delta}`);
  });

  test("calibration rejects a real state-change pair", () => {
    const before = calibrationFixture("state-before-dark-390x320.png");
    const after = calibrationFixture("state-after-dark-390x320.png");

    const result = pairs.comparePngStructural(before.bytes, after.bytes);
    assert.equal(result.equal, false);
    assert.ok(result.blocks_over / result.blocks > 0.1, `a real state change moves many blocks, saw ${result.blocks_over} of ${result.blocks}`);
    assert.ok(result.edge_blocks_over / result.blocks > 0.1, `the edge count sees it too, saw ${result.edge_blocks_over} of ${result.blocks}`);
  });

  test("calibration rejects a real capture with an 8 px band shift", () => {
    const before = calibrationFixture("recolor-before-dark-390x320.png");
    const after = calibrationFixture("recolor-after-dark-390x320.png");
    const shifted = shiftBand(after.decoded, 120, 100, 8);
    assert.equal(pairs.comparePngStructural(before.bytes, after.bytes).equal, true, "the unshifted recolor is accepted, so the shift alone is the cause");

    const result = pairs.comparePngStructural(before.bytes, shifted);
    assert.equal(result.equal, false);
    assert.ok(result.blocks_over > Math.floor(result.blocks * 0.0025), `the shift exceeds the 0.25 percent tolerance, saw ${result.blocks_over} of ${result.blocks}`);
    assert.ok(result.edge_blocks_over > Math.floor(result.blocks * 0.0025), `the edge count exceeds it too, saw ${result.edge_blocks_over} of ${result.blocks}`);
  });

  test("different image dimensions are never structurally equal", () => {
    const wide = layoutPng(64, 32, { ...LAYOUT, blockX: 0, blockY: 0, blockW: 32, blockH: 16 });
    const tall = layoutPng(64, 48, { ...LAYOUT, blockX: 0, blockY: 0, blockW: 32, blockH: 16 });
    const result = pairs.comparePngStructural(wide, tall);
    assert.equal(result.equal, false);
    assert.equal(result.blocks, null);
  });
});

// WR-05 (phase 186 review): the ink share alone is blind to flat regions (one color in both images), to 1-2 px
// lines and to a few whole new blocks under the percentage. Each case below was accepted by the share-only check
// at the size of a real capture; the edge count and the absolute block cap reject them. The recolor accept proves
// the extra signal does not reject a palette swap.
describe("structural check on flat, aligned and thin-line changes", () => {
  const BG = [20, 30, 40];
  const PANEL = [60, 70, 90];
  const RULE = [90, 100, 120];
  const INK = [200, 180, 60];
  const RED = [200, 60, 60];
  const base = ({ stripes }) => stripes(700, 700, 128, 64, INK);
  const before = flatPage(base);
  const overPercentage = (result, over) => over / result.blocks > 0.0025;

  const flatChanges = [
    ["a solid header bar added", ({ rect }) => rect(0, 0, 1440, 64, PANEL)],
    ["a solid sidebar added", ({ rect }) => rect(0, 0, 240, 900, PANEL)],
    ["a 1 px full-height rule added", ({ rect }) => rect(400, 0, 1, 900, RULE)],
    ["a card with a 1 px border added", ({ rect }) => { rect(600, 300, 400, 320, RULE); rect(601, 301, 398, 318, BG); }]
  ];
  for (const [name, draw] of flatChanges) {
    test(`${name} is rejected although the ink share cannot see it`, () => {
      const result = pairs.comparePngStructural(before, flatPage((d) => { base(d); draw(d); }));
      assert.ok(result.blocks_over / result.blocks <= 0.0025 && result.worst_step <= 8, "the share-only check would have accepted it");
      assert.ok(overPercentage(result, result.edge_blocks_over), `the edge count rejects it, saw ${result.edge_blocks_over} of ${result.blocks}`);
      assert.equal(result.equal, false);
    });
  }

  test("a full-height 1 px rule moved by 8 px is rejected", () => {
    const at = (x) => flatPage((d) => { base(d); d.rect(x, 0, 1, 900, RULE); });
    const result = pairs.comparePngStructural(at(400), at(408));
    assert.equal(result.blocks_over, 0, "the share is identical, so only the edge count can see the move");
    assert.equal(result.equal, false);
  });

  test("twelve new striped blocks are rejected although they are under 0.25 percent of the blocks", () => {
    const result = pairs.comparePngStructural(before, flatPage((d) => {
      base(d);
      for (let index = 0; index < 12; index += 1) d.stripes(304 + index * 32, 100, 16, 16, RED);
    }));
    assert.equal(result.blocks_over, 12);
    assert.ok(result.blocks_over / result.blocks <= 0.0025, "the share-only percentage would have accepted twelve blocks");
    assert.equal(result.equal, false);
  });

  test("the absolute block cap rejects a small new region on a large raster where the percentage would not", () => {
    const size = { width: 2000, height: 2000 };
    const sparse = (count) => flatPage((d) => { for (let index = 0; index < count; index += 1) d.stripes(48 + index * 64, 400, 16, 16, RED); }, size);
    const result = pairs.comparePngStructural(sparse(0), sparse(10));
    assert.equal(result.blocks, 15625);
    assert.ok(result.blocks_over / result.blocks <= 0.0025 && result.edge_blocks_over / result.blocks <= 0.0025, "both percentages are under 0.25 percent");
    assert.ok(result.blocks_over > 8, `ten new blocks are over the cap of 8, saw ${result.blocks_over}`);
    assert.equal(result.equal, false);
  });

  test("a palette swap of the same layout is accepted with no block over on either signal", () => {
    const layout = (colors) => flatPage((d) => {
      d.rect(0, 0, 240, 900, colors.side);
      d.rect(0, 0, 1440, 64, colors.header);
      d.rect(600, 300, 400, 320, colors.rule);
      d.rect(601, 301, 398, 318, colors.bg);
      d.rect(400, 0, 1, 900, colors.rule);
      d.stripes(700, 700, 128, 64, colors.ink);
    }, { background: colors.bg });
    const cool = layout({ bg: BG, side: [45, 55, 75], header: PANEL, rule: RULE, ink: INK });
    const plum = layout({ bg: [30, 18, 34], side: [55, 30, 62], header: [70, 40, 80], rule: [130, 100, 140], ink: [230, 140, 190] });

    const result = pairs.comparePngStructural(cool, plum);
    assert.equal(result.equal, true);
    assert.equal(result.blocks_over, 0);
    assert.equal(result.edge_blocks_over, 0);
  });

  // Documented limit (PROVENANCE.md): both signals are block counts, so an edge that moves by 1-2 px and stays in the
  // same 16 px block looks the same. The geometry and copy receipts are what catch that. If this starts failing,
  // the comparator got sharper: update the limit in PROVENANCE.md instead of loosening a threshold.
  test("a flat-region edge moved by 2 px inside one block is not seen (documented limit)", () => {
    const header = (height) => flatPage((d) => { base(d); d.rect(0, 0, 1440, height, PANEL); });
    assert.equal(pairs.comparePngStructural(header(56), header(58)).equal, true);
  });
});

test("pair output is atomic, deterministic and never overwritten by different bytes", () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "scrypath-pair-output-"));
  try {
    const outputDirectory = path.join(directory, "comparison");
    const report = { schema: "scrypath.ui-state-pair-comparison.v4", status: "structural-match", cases_compared: 61 };
    const outputPath = pairs.writeOutput(outputDirectory, report);
    const original = fs.readFileSync(outputPath);

    assert.equal(pairs.writeOutput(outputDirectory, report), outputPath);
    assert.deepEqual(fs.readFileSync(outputPath), original);
    assert.throws(() => pairs.writeOutput(outputDirectory, { ...report, status: "mismatch" }), /refusing to overwrite/);
    assert.deepEqual(fs.readFileSync(outputPath), original);
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});

// Phase 187 amendment of the preservation guard `assertPendingState`: while a refresh is in flight the
// page text must equal the text before it, except for the loading words the approved UI-SPEC copy-diff
// allowlist lists (`Refreshing…` where the refresh button read `Refresh`). These cases evaluate the
// guard's own allowlist block (between its two marker comments) and read the guard's wiring, so the
// tested code is the code Playwright runs.
describe("the pending-state guard ignores only the allowlisted loading words", () => {
  const guardPath = path.resolve(__dirname, "../../examples/scrypath_ecommerce/e2e/helpers/ui-preservation-states.ts");
  const guardSource = fs.readFileSync(guardPath, "utf8");
  const begin = "// loading-word-allowlist:begin";
  const end = "// loading-word-allowlist:end";

  function loadAllowlistBlock() {
    const start = guardSource.indexOf(begin);
    const stop = guardSource.indexOf(end);
    assert.ok(start >= 0 && stop > start, "the guard has its two loading-word-allowlist marker comments");
    const block = guardSource.slice(start, stop);
    // The block is TypeScript only by its `: string` annotations; removing them leaves plain JavaScript.
    const plain = block.replace(/:\s*string\b/g, "");
    return new Function(`${plain}\nreturn { ALLOWLISTED_LOADING_LINES, normalizeAllowlistedLoadingText };`)();
  }

  const { ALLOWLISTED_LOADING_LINES, normalizeAllowlistedLoadingText } = loadAllowlistBlock();
  const idle = ["Search health", "Refresh", "Checked 2026-10-06 12:00 UTC", "No failed work"].join("\n");
  const sameAsCompared = (current, prior) => normalizeAllowlistedLoadingText(current) === prior;

  test("the allowlist is exactly the refresh button label", () => {
    assert.deepEqual(ALLOWLISTED_LOADING_LINES, [{ busy: "Refreshing…", idle: "Refresh" }]);
  });

  test("a refresh button that reads Refreshing… while in flight is the same page", () => {
    const busy = idle.replace("\nRefresh\n", "\nRefreshing…\n");
    assert.notEqual(busy, idle);
    assert.equal(sameAsCompared(busy, idle), true);
    assert.equal(sameAsCompared(idle, idle), true, "the idle text is unchanged by the normalization");
  });

  test("planted: a non-allowlisted text change during loading still fails", () => {
    const withLoadingWord = idle.replace("\nRefresh\n", "\nRefreshing…\n");
    // Another line changes (with and without the loading word), and a lone change on its own.
    assert.equal(sameAsCompared(withLoadingWord.replace("No failed work", "Failed work found"), idle), false);
    assert.equal(sameAsCompared(idle.replace("No failed work", "Failed work found"), idle), false);
    // A line that was removed or added while the loading word is shown.
    assert.equal(sameAsCompared(withLoadingWord.replace("\nNo failed work", ""), idle), false);
    assert.equal(sameAsCompared(`${withLoadingWord}\nUnexpected banner`, idle), false);
    // The button label itself changing to a word that is not allowlisted.
    for (const word of ["Refreshed", "Loading…", "Running…", "Refreshing", "Refreshing… ", "Refreshing…done"]) {
      assert.equal(sameAsCompared(idle.replace("\nRefresh\n", `\n${word}\n`), idle), false, `"${word}" is not an allowlisted loading line`);
    }
  });

  test("planted: Refreshing… does not stand in for a line that was not there before", () => {
    const priorWithoutButton = ["Search health", "Checked 2026-10-06 12:00 UTC"].join("\n");
    const current = ["Search health", "Refreshing…", "Checked 2026-10-06 12:00 UTC"].join("\n");
    assert.equal(sameAsCompared(current, priorWithoutButton), false);
    // Only a whole line counts: the word inside a longer line is a text change.
    assert.equal(sameAsCompared(idle.replace("Checked", "Refreshing… Checked"), idle), false);
  });

  test("the guard still compares route, text and the busy class, and normalizes only the observed text", () => {
    const body = /async function assertPendingState\([\s\S]*?\n}\n/.exec(guardSource)?.[0] ?? "";
    assert.ok(body.length > 0, "assertPendingState is present");
    assert.match(body, /const currentText = normalizeAllowlistedLoadingText\(await page\.locator\("\[data-phx-main\]"\)\.innerText\(\)\);/);
    assert.match(body, /route !== priorRoute \|\| currentText !== priorText \|\| !busyClass\.split\(\/\\s\+\/\)\.includes\(expectedClass\)/);
    assert.doesNotMatch(body, /normalizeAllowlistedLoadingText\(priorText\)/, "the prior text is compared as observed");
    const uses = guardSource.match(/normalizeAllowlistedLoadingText\(/g) ?? [];
    assert.equal(uses.length, 2, "one definition and the one call in assertPendingState");
  });
});
