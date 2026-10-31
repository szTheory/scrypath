import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { test } from "node:test";
import { captureDisposableMatrix, captureSurface, configureDisposableFontProfile, launchDisposableBrowser, captureStableImage, captureUiStateInPage, captureViewportImage, cleanGitEnvironment, dimensions, disposableClockErrors, entryFixtureErrors, isCanonicalOrigin, prepareCaptureStateInPage, previewSourceErrors, reviewArtifactRoot, reviewErrors, reviewTemplate, standaloneRoutes, surfaces, themes, viewports } from "./ui-review.mjs";

const require = createRequire(import.meta.url);
const { domStateErrors } = require("../../../scripts/ci/ui_preservation.cjs");

test("disposable captures require a valid fixed browser clock before launching Chromium", async () => {
  const utc = "2026-10-31T12:00:00.000Z";
  const { createHash } = await import("node:crypto");
  const clock = { utc, sha256: createHash("sha256").update(`${utc}\n`).digest("hex"), timezone: "UTC", locale: "en-US", browser_mode: "fixed-date" };
  assert.deepEqual(disposableClockErrors(clock), []);
  for (const invalid of [undefined, { ...clock, sha256: "0".repeat(64) }, { ...clock, timezone: "America/New_York" }, { ...clock, utc: "2026-10-31T99:00:00.000Z" }]) {
    assert.ok(disposableClockErrors(invalid).length);
    await assert.rejects(captureDisposableMatrix({ hostUrl: "http://web:4002", standaloneUrl: "http://standalone_ops:4003", output: "/artifacts", dataIdentity: "fixture", clock: invalid, allowComposeNetwork: true }), /clock/i);
  }
});

test("standalone saved-search capture follows the canonical search route", () => {
  assert.equal(standaloneRoutes["saved-searches"], "/ops/search?saved=manage");
});

test("Playwright output cleanup preserves UI review evidence", async () => {
  const demoRoot = fileURLToPath(new URL("../", import.meta.url));
  const temporaryDemo = await mkdtemp(path.join(tmpdir(), "scrypath-ui-review-output-"));
  const reviewDirectory = path.join(temporaryDemo, path.relative(demoRoot, reviewArtifactRoot));
  const phase185Directory = path.join(reviewDirectory, "phase185");
  const legacyCleanupDirectory = path.join(reviewDirectory, "iteration3-journeys");
  const playwrightDirectory = path.join(temporaryDemo, "test-results");
  try {
    await mkdir(phase185Directory, { recursive: true });
    await mkdir(legacyCleanupDirectory, { recursive: true });
    await mkdir(playwrightDirectory, { recursive: true });
    const evidence = path.join(phase185Directory, "capture.json");
    await writeFile(evidence, "preserve this review");
    await writeFile(path.join(legacyCleanupDirectory, "old-output.json"), "legacy output");
    await rm(playwrightDirectory, { recursive: true, force: true });
    await rm(legacyCleanupDirectory, { recursive: true, force: true });
    assert.equal(await readFile(evidence, "utf8"), "preserve this review");
  } finally {
    await rm(temporaryDemo, { recursive: true, force: true });
  }
});

function fixture() {
  const source = { tree_sha256: "current" };
  const captures = surfaces.flatMap(({ id: surface }) => themes.flatMap((theme) => viewports.map(({ width }) => ({ id: `${surface}--${theme}--${width}`, surface, checks: [], files: { "viewport.png": {}, "full.png": {}, "copy.json": {} } }))));
  const manifest = { source, runtime: { source_match: true, main_included: true }, captures };
  const review = reviewTemplate(manifest, "capture-digest");
  review.status = "reviewed";
  for (const row of review.surfaces) Object.assign(row, { verdict: "acceptable", rationale: "Fixture only, never a product review.", evidence: captures.filter(({ surface }) => surface === row.id).map(({ id }) => id) });
  for (const row of review.dimensions) Object.assign(row, { verdict: "acceptable", rationale: "Fixture only.", evidence: [captures[0].id] });
  review.coverage = { verdict: "supported", rationale: "Test fixture only.", evidence: ["isolated-test-receipt"] };
  return { source, manifest, review };
}

function stableStateFixture(bodyText = "Help entry", { hover = true, focus = true } = {}) {
  const rect = { x: 1, y: 2, width: 40, height: 24 };
  const element = { tag: "button", role: "button", name: "Choose dark theme", href: null };
  const anchor = {
    rect: { x: 0, y: 0, width: 1280, height: 900 },
    position: "static", display: "block",
    inset: { top: "auto", right: "auto", bottom: "auto", left: "auto" },
    margin: { top: "0px", right: "0px", bottom: "0px", left: "0px" }
  };
  return {
    schema: "scrypath.ui-capture-state.v1",
    body_text: bodyText,
    controls: [{ ...element, value: null, checked: null, selected: true, disabled: false, expanded: null, pressed: "true", rect }],
    focus: {
      element: focus ? element : null,
      rect: focus ? rect : null,
      focus_visible: focus,
      outline: focus ? { style: "solid", width: "2px", color: "rgb(0, 0, 0)" } : null,
      opacity: focus ? "1" : null
    },
    hover: hover ? [{ element, rect }] : [],
    document_has_focus: true,
    layout: { shell: anchor, shell_content: anchor, header: anchor, header_inner: anchor, main: anchor, main_inner: anchor, primary_article: anchor },
    viewport: { inner: { width: 1280, height: 900 }, client: { width: 1280, height: 900 }, document: { width: 1280, height: 900 }, scroll: { x: 0, y: 0 }, dpr: 1, scale: 1 },
    theme: { preference: "dark", effective: "dark", data_theme: "dark", system_dark: true }
  };
}

function deferred() {
  let resolve;
  let reject;
  const promise = new Promise((yes, no) => { resolve = yes; reject = no; });
  return { promise, resolve, reject };
}

function installReadinessDocument(animation, events) {
  const originals = new Map();
  for (const key of ["document", "requestAnimationFrame"]) originals.set(key, Object.getOwnPropertyDescriptor(globalThis, key));
  const animationObserved = deferred();
  const fontsObserved = deferred();
  const fontsReady = deferred();
  let frameSignal = deferred();
  const frames = [];
  const document = {
    getAnimations: () => {
      events.push("scan-animations");
      animationObserved.resolve();
      return animation.playState === "finished" ? [] : [animation];
    },
    fonts: {
      status: "loaded",
      get ready() {
        events.push("await-fonts");
        fontsObserved.resolve();
        return fontsReady.promise;
      }
    }
  };
  Object.defineProperty(globalThis, "document", { configurable: true, writable: true, value: document });
  Object.defineProperty(globalThis, "requestAnimationFrame", {
    configurable: true,
    writable: true,
    value: callback => {
      events.push("request-frame");
      frames.push(callback);
      frameSignal.resolve();
    }
  });
  return {
    animationObserved: animationObserved.promise,
    fontsObserved: fontsObserved.promise,
    resolveFonts: () => fontsReady.resolve(),
    async runNextFrame() {
      while (!frames.length) await frameSignal.promise;
      const callback = frames.shift();
      frameSignal = deferred();
      events.push("run-frame");
      callback(0);
    },
    restore() {
      for (const [key, descriptor] of originals) {
        if (descriptor) Object.defineProperty(globalThis, key, descriptor);
        else delete globalThis[key];
      }
    }
  };
}

function installAnimationVisibilityDocument(animations, events) {
  const originals = new Map();
  for (const key of ["document", "requestAnimationFrame"]) originals.set(key, Object.getOwnPropertyDescriptor(globalThis, key));
  const animationObserved = deferred();
  const document = {
    getAnimations: () => {
      events.push("scan-animations");
      animationObserved.resolve();
      return animations;
    },
    fonts: {
      status: "loaded",
      ready: Promise.resolve().then(() => events.push("fonts-ready"))
    }
  };
  Object.defineProperty(globalThis, "document", { configurable: true, writable: true, value: document });
  Object.defineProperty(globalThis, "requestAnimationFrame", {
    configurable: true,
    writable: true,
    value: callback => {
      events.push("request-frame");
      queueMicrotask(() => {
        events.push("run-frame");
        callback(0);
      });
    }
  });
  return {
    animationObserved: animationObserved.promise,
    restore() {
      for (const [key, descriptor] of originals) {
        if (descriptor) Object.defineProperty(globalThis, key, descriptor);
        else delete globalThis[key];
      }
    }
  };
}

function controllableEntryAnimation({ id, target = null, events }) {
  const finished = deferred();
  let isFinished = false;
  return {
    animation: {
      effect: { target, getComputedTiming: () => ({ endTime: 100 }) },
      pending: false,
      get playState() { return isFinished ? "finished" : "running"; },
      get finished() {
        events.push(`await-finished:${id}`);
        return finished.promise;
      }
    },
    finish() {
      isFinished = true;
      finished.resolve();
    },
    cancel(error) {
      finished.reject(error);
    }
  };
}

function installFakeDOM({ surface = "help", theme = "system-dark", focusVisible = true, activeBody = false, focusStyle = { style: "solid", width: "2px", color: "rgb(0, 0, 0)", opacity: "1" } } = {}) {
  const originals = new Map();
  const remember = (key) => originals.set(key, Object.getOwnPropertyDescriptor(globalThis, key));
  class FakeElement {
    constructor(tag, { text = "", attrs = {}, rect = { x: 0, y: 0, width: 100, height: 24 }, visible = true, focusVisible = false, ...properties } = {}) {
      this.tagName = tag.toUpperCase();
      this.attrs = attrs;
      this.innerText = text;
      this.bounds = rect;
      this.visible = visible;
      this.focusVisible = focusVisible;
      this.labels = [];
      Object.assign(this, properties);
    }
    getAttribute(name) { return Object.hasOwn(this.attrs, name) ? this.attrs[name] : null; }
    getBoundingClientRect() { return this.bounds; }
    getClientRects() { return this.visible ? [this.bounds] : []; }
    matches(selector) { return selector === ":focus-visible" && this.focusVisible; }
  }
  const element = (tag, values) => new FakeElement(tag, values);
  const root = element("html", { attrs: { "data-theme": theme === "system-dark" ? "dark" : theme === "light" || theme === "dark" ? theme : null }, rect: { x: 0, y: 0, width: 1440, height: 900 } });
  root.dataset = theme === "system-dark" ? { themePreference: "system", themeEffective: "dark" }
    : { themePreference: theme, themeEffective: theme };
  root.clientWidth = 1440;
  root.clientHeight = 900;
  root.scrollWidth = 1440;
  root.scrollHeight = 900;
  const body = element("body", { text: "Scrypath interface Help entry", rect: { x: 0, y: 0, width: 1440, height: 900 } });
  const header = element("header", { text: "Scrypath" });
  const headerInner = element("div", { text: "Scrypath navigation" });
  const main = element("main", { text: "Help entry" });
  const mainInner = element("div", { text: "Help entry" });
  const article = element("article", { text: "Help entry" });
  const shell = element("div", { text: "Scrypath Help entry" });
  const shellContent = element("div", { text: "Help entry" });
  const themeButton = element("button", { text: "Dark theme", attrs: { "aria-label": "Dark theme", "aria-pressed": "true", "data-theme-selected": "true" }, focusVisible });
  const mixedButton = element("button", { text: "Mixed state", attrs: { "aria-label": "Mixed state", "aria-pressed": "mixed" } });
  const mixedCheckbox = element("div", { text: "Indeterminate option", attrs: { role: "checkbox", "aria-label": "Indeterminate option", "aria-checked": "mixed" } });
  const selectedOption = element("div", { text: "Beta category", attrs: { role: "option", "aria-label": "Beta category", "aria-selected": "true" } });
  const multi = element("select", { attrs: { "aria-label": "Categories" }, value: "alpha", multiple: true, selectedOptions: [{ value: "alpha" }, { value: "beta" }] });
  const input = element("input", { attrs: { "aria-label": "Search" }, type: "search", value: "sample query" });
  const link = element("a", { text: "Open details", attrs: { href: "/ops/help" } });
  const controls = surface === "storefront" ? [input, link] : [themeButton, mixedButton, mixedCheckbox, selectedOption, multi, link];
  const hoverTarget = surface === "storefront" ? link : themeButton;
  const selectorMap = surface === "storefront" ? {
    body,
    header,
    "header > div": headerInner,
    main,
    "main > div": mainInner
  } : {
    body,
    ".ops-shell-frame": shell,
    ".ops-shell-content": shellContent,
    ".ops-header": header,
    ".ops-header__inner": headerInner,
    "#ops-main": main,
    "#ops-main > div": mainInner,
    ".ops-help-content": article,
    "main article": article,
    main,
    "main > div": mainInner,
    header,
    "header > div": headerInner
  };
  const document = {
    documentElement: root,
    body,
    activeElement: surface === "storefront" || activeBody ? body : themeButton,
    hasFocus: () => true,
    getElementById: () => null,
    querySelector: (selector) => selectorMap[selector] || null,
    querySelectorAll: (selector) => selector === ":hover" ? [root, body, element("div", { text: body.innerText, rect: { x: 0, y: 0, width: 0, height: 0 } }), main, hoverTarget]
      : selector.startsWith("a,button,input,select,textarea,") ? controls : [],
  };
  const properties = {
    Element: FakeElement,
    document,
    window: {
      innerWidth: 1440, innerHeight: 900, devicePixelRatio: 1, scrollX: 0, scrollY: 0,
      visualViewport: { scale: 1 },
      matchMedia: () => ({ matches: theme === "system-dark" })
    },
    getComputedStyle: (node) => ({
      visibility: "visible", position: "static", display: "block", top: "auto", right: "auto", bottom: "auto", left: "auto",
      marginTop: "0px", marginRight: "0px", marginBottom: "0px", marginLeft: "0px",
      outlineStyle: node === themeButton ? focusStyle.style : "none",
      outlineWidth: node === themeButton ? focusStyle.width : "0px",
      outlineColor: node === themeButton ? focusStyle.color : "rgba(0, 0, 0, 0)",
      opacity: node === themeButton ? focusStyle.opacity : "1"
    })
  };
  for (const [key, value] of Object.entries(properties)) {
    remember(key);
    Object.defineProperty(globalThis, key, { configurable: true, writable: true, value });
  }
  const restore = () => {
    for (const key of Object.keys(properties)) {
      const descriptor = originals.get(key);
      if (descriptor) Object.defineProperty(globalThis, key, descriptor);
      else delete globalThis[key];
    }
  };
  restore.target = surface === "storefront" ? link : themeButton;
  return restore;
}

test("a capture is pending until all review dimensions and state evidence are supplied", () => {
  const { source, manifest } = fixture();
  const errors = reviewErrors(reviewTemplate(manifest, "capture-digest"), manifest, "capture-digest", source);
  assert.ok(errors.some((error) => error.includes("pending")));
  assert.ok(errors.some((error) => error.includes("Journey/state")));
});

test("the in-page DOM state producer emits values accepted by the capture validator", () => {
  const wrap = (snapshot) => ({ ...snapshot, before: snapshot, after: snapshot });
  const restoreOps = installFakeDOM({ surface: "help", theme: "system-dark" });
  try {
    const ops = captureUiStateInPage();
    assert.equal(ops.hover.length, 1, "hover evidence describes the actual visible control, excluding non-painting wrappers and layout ancestors");
    const opsSidecar = wrap(ops);
    const interactionTarget = captureUiStateInPage(restoreOps.target);
    const opsCapture = { surface: "help", theme: "system-dark", viewport: { width: 1440, height: 900 }, interaction_target: interactionTarget };
    assert.deepEqual(domStateErrors(opsSidecar, opsCapture, "hover", "ops hover"), []);
    assert.deepEqual(domStateErrors(opsSidecar, opsCapture, "focus", "ops focus"), []);
    assert.deepEqual(interactionTarget, ops.focus.element, "locator identity comes from the same semantic reader as focus state");
    assert.equal(ops.theme.preference, "system");
    assert.equal(ops.theme.effective, "dark");
    assert.equal(ops.theme.data_theme, "dark");
    assert.equal(ops.controls.find(({ name }) => name === "Mixed state").pressed, "mixed");
    assert.equal(ops.controls.find(({ name }) => name === "Indeterminate option").checked, "mixed");
    assert.equal(ops.controls.find(({ name }) => name === "Beta category").selected, true);
    assert.deepEqual(ops.controls.find(({ name }) => name === "Search")?.value, undefined);
    assert.deepEqual(ops.controls.find(({ name }) => name === "Categories").value, ["alpha", "beta"]);
    assert.deepEqual(ops.focus.element, { tag: "button", role: "button", name: "Dark theme", href: null });
    assert.deepEqual(ops.focus.outline, { style: "solid", width: "2px", color: "rgb(0, 0, 0)" });
    assert.equal(ops.focus.opacity, "1");
    assert.ok(ops.layout.shell && ops.layout.primary_article);
  } finally {
    restoreOps();
  }

  const wrongTarget = { surface: "help", theme: "system-dark", viewport: { width: 1440, height: 900 }, interaction_target: { tag: "button", role: "button", name: "Mixed state", href: null } };
  const goodTarget = installFakeDOM({ surface: "help", theme: "system-dark" });
  try {
    const focused = wrap(captureUiStateInPage());
    assert.ok(domStateErrors(focused, wrongTarget, "focus", "wrong target").some((error) => /target|focus|control/i.test(error)));
  } finally {
    goodTarget();
  }

  const bodyFocus = installFakeDOM({ surface: "help", theme: "system-dark", activeBody: true });
  try {
    const focused = wrap(captureUiStateInPage());
    const target = captureUiStateInPage(bodyFocus.target);
    assert.notDeepEqual(focused.focus.element, target);
    assert.ok(domStateErrors(focused, { ...wrongTarget, interaction_target: target }, "focus", "body focus").length > 0);
  } finally {
    bodyFocus();
  }

  const keyboardFocusMissing = installFakeDOM({ surface: "help", theme: "system-dark", focusVisible: false });
  try {
    const focused = wrap(captureUiStateInPage());
    const target = captureUiStateInPage(keyboardFocusMissing.target);
    assert.ok(domStateErrors(focused, { ...wrongTarget, interaction_target: target }, "focus", "non-keyboard focus").length > 0);
  } finally {
    keyboardFocusMissing();
  }

  const transparentFocus = installFakeDOM({
    surface: "help", theme: "system-dark",
    focusStyle: { style: "solid", width: "0px", color: "rgba(0, 0, 0, 0)", opacity: "0" }
  });
  try {
    const focused = wrap(captureUiStateInPage());
    const target = captureUiStateInPage(transparentFocus.target);
    assert.ok(domStateErrors(focused, { ...wrongTarget, interaction_target: target }, "focus", "transparent focus outline").length > 0);
  } finally {
    transparentFocus();
  }

  const restoreLight = installFakeDOM({ surface: "help", theme: "light" });
  try {
    const light = { ...captureUiStateInPage(), before: null, after: null };
    light.before = Object.fromEntries(Object.keys(light).filter((key) => key !== "before" && key !== "after").map((key) => [key, light[key]]));
    light.after = light.before;
    const target = captureUiStateInPage(restoreLight.target);
    assert.deepEqual(domStateErrors(light, { surface: "help", theme: "light", viewport: { width: 1440, height: 900 }, interaction_target: target }, "viewport", "light theme"), []);
  } finally {
    restoreLight();
  }

  for (const theme of ["light", "dark", "system-dark"]) {
    const restoreStorefront = installFakeDOM({ surface: "storefront", theme });
    try {
      const storefront = captureUiStateInPage();
      const sidecar = wrap(storefront);
      const target = captureUiStateInPage(restoreStorefront.target);
      assert.deepEqual(domStateErrors(sidecar, { surface: "storefront", theme, viewport: { width: 1440, height: 900 }, interaction_target: target }, "viewport", `storefront ${theme}`), []);
      assert.ok(Object.values(storefront.layout).some(Boolean), "storefront has a generic measured layout anchor");
      assert.equal(storefront.theme.preference, theme === "system-dark" ? "system" : theme);
      assert.equal(storefront.theme.effective, theme === "light" ? "light" : "dark");
    } finally {
      restoreStorefront();
    }
  }
});

test("a different preview worktree or omitted main commits cannot masquerade as latest", () => {
  assert.deepEqual(previewSourceErrors("/current", "/current", true), []);
  assert.equal(previewSourceErrors("/current", "/old", false).length, 2);
  assert.equal(previewSourceErrors("/current", "/current", true, false).length, 1);
  assert.ok(previewSourceErrors("/current", "/current", true, true, false).some((error) => error.includes("stale against the remote")));
  const { source, manifest, review } = fixture();
  manifest.runtime.source_match = false;
  assert.ok(reviewErrors(review, manifest, "capture-digest", source).some((error) => error.includes("provenance")));
});

test("disposable captures cannot target retained loopback or arbitrary network hosts", async () => {
  await assert.rejects(captureDisposableMatrix({ hostUrl: "http://127.0.0.1:4002", standaloneUrl: "http://127.0.0.1:4003", output: "/tmp/evidence", dataIdentity: "digest" }), /retained-preview targets are not accepted/);
  await assert.rejects(captureDisposableMatrix({ hostUrl: "http://example.com:4002", standaloneUrl: "http://standalone_ops:4003", output: "/tmp/evidence", dataIdentity: "digest", allowComposeNetwork: true }), /exact owned Compose service routes/);
});

test("disposable entry fixtures distinguish host incident data from standalone empty allowlists", () => {
  const incidentSummary = "Control Room 3 sync jobs failed";
  const incidentFailures = "3 failed, 2 retrying Product Invalid data Meilisearch rejected it Unknown cause";
  const standaloneSummary = "No search schemas configured. Configure the host application's schema allowlist";
  const standaloneFailures = "No schemas configured. Add allowlisted schema modules with schema_allowlist in :scrypath_ops";
  assert.deepEqual(entryFixtureErrors("host", "control-room", incidentSummary), []);
  assert.deepEqual(entryFixtureErrors("host", "failed-sync", incidentFailures), []);
  assert.deepEqual(entryFixtureErrors("standalone", "control-room", standaloneSummary), []);
  assert.deepEqual(entryFixtureErrors("standalone", "failed-sync", standaloneFailures), []);
  assert.ok(entryFixtureErrors("host", "failed-sync", "No failures" ).length > 0);
  assert.ok(entryFixtureErrors("standalone", "control-room", incidentSummary).length > 0);
});

test("UI review Git reads ignore inherited repository redirects and require canonical origin", () => {
  assert.deepEqual(cleanGitEnvironment({ PATH: "/usr/bin", GIT_DIR: "/tmp/forged.git", GIT_WORK_TREE: "/tmp/forged" }), {
    PATH: "/usr/bin", GIT_CONFIG_NOSYSTEM: "1", GIT_CONFIG_GLOBAL: "/dev/null"
  });
  assert.equal(isCanonicalOrigin("https://github.com/szTheory/scrypath.git"), true);
  assert.equal(isCanonicalOrigin("git@github.com:szTheory/scrypath.git"), true);
  assert.equal(isCanonicalOrigin("https://example.com/szTheory/scrypath.git"), false);
});

test("reviewing reported screens alone cannot omit the rest of the inventory", () => {
  const { source, manifest, review } = fixture();
  assert.deepEqual(reviewErrors(review, manifest, "capture-digest", source), []);
  review.surfaces = review.surfaces.filter(({ id }) => id !== "saved-searches");
  review.dimensions = review.dimensions.filter(({ id }) => id !== dimensions.at(-1));
  const errors = reviewErrors(review, manifest, "capture-digest", source);
  assert.ok(errors.some((error) => error.startsWith("saved-searches:")));
  assert.ok(errors.some((error) => error.startsWith("unreported-problems:")));
});

test("a stale source, tampered capture binding, or incomplete matrix cannot pass", () => {
  const { source, manifest, review } = fixture();
  review.capture_sha256 = "other-capture";
  manifest.captures.pop();
  const errors = reviewErrors(review, manifest, "capture-digest", { tree_sha256: `${source.tree_sha256}-changed` });
  assert.ok(errors.some((error) => error.includes("Source changed")));
  assert.ok(errors.some((error) => error.includes("different capture")));
  assert.ok(errors.some((error) => error.includes("missing")));
});

test("a needs-work verdict, mechanical failure, or open finding remains visible", () => {
  const { source, manifest, review } = fixture();
  review.surfaces[0].verdict = "needs-work";
  manifest.captures[0].checks.push({ rule: "page-overflow" });
  review.findings.push({ disposition: "open", evidence: [manifest.captures[0].id], rationale: "Observed overflow." });
  const errors = reviewErrors(review, manifest, "capture-digest", source);
  assert.ok(errors.some((error) => error.includes("needs work")));
  assert.ok(errors.some((error) => error.includes("Mechanical")));
  assert.ok(errors.some((error) => error.includes("open")));
});

test("a pass cannot cite nonexistent screenshots or omit a theme/width", () => {
  const { source, manifest, review } = fixture();
  review.surfaces[0].evidence = ["not-a-capture"];
  delete manifest.captures[0].files["full.png"];
  const errors = reviewErrors(review, manifest, "capture-digest", source);
  assert.ok(errors.some((error) => error.includes("unknown capture")));
  assert.ok(errors.some((error) => error.includes("not every theme/width")));
  assert.ok(errors.some((error) => error.includes("artifact is missing")));
});


test("viewport captures use the exact document clip without changing layout", async () => {
  const geometry = { width: 390, height: 844, dpr: 1, scale: 1, scrollX: 0, scrollY: 0, documentWidth: 390, documentHeight: 959 };
  const original = Buffer.from("unchanged raw screenshot bytes");
  let options;
  const page = { evaluate: async () => ({ ...geometry }), screenshot: async value => { options = value; return original; } };
  assert.equal(await captureViewportImage(page, { width: 390, height: 844 }), original);
  assert.equal(options.fullPage, true, "viewport images must use the document capture path");
  assert.deepEqual(options.clip, { x: 0, y: 0, width: 390, height: 844 });
  assert.equal(options.animations, "disabled");
});

test("viewport document captures reject zoom, scroll and changed layout", async () => {
  const geometry = { width: 390, height: 844, dpr: 1, scale: 1, scrollX: 0, scrollY: 0, documentWidth: 390, documentHeight: 959 };
  for (const change of [{ width: 391 }, { height: 845 }, { dpr: 2 }, { scale: 1.25 }, { scrollX: 1 }, { scrollY: 1 }]) {
    let shots = 0;
    await assert.rejects(captureViewportImage({ evaluate: async () => ({ ...geometry, ...change }), screenshot: async () => { shots += 1; return Buffer.alloc(0); } }, { width: 390, height: 844 }), /viewport/i);
    assert.equal(shots, 0);
  }
  const measurements = [undefined, geometry, { ...geometry, documentHeight: 960 }];
  await assert.rejects(captureViewportImage({ evaluate: async () => measurements.shift(), screenshot: async () => Buffer.alloc(0) }, { width: 390, height: 844 }), /layout/i);
  const failure = new Error("actual screenshot failed");
  await assert.rejects(captureViewportImage({ evaluate: async () => geometry, screenshot: async () => { throw failure; } }, { width: 390, height: 844 }), error => error === failure);
});

test("stable entry capture keeps all samples and selects the final consecutive exact pair", async () => {
  const outputs = [Buffer.from("A"), Buffer.from("B"), Buffer.from("B")];
  const saved = [];
  let frameCount = 0;
  const interactionTarget = stableStateFixture().focus.element;
  const result = await captureStableImage({
    page: {}, id: "help--dark--1280", kind: "viewport.png",
    prepareState: async () => {},
    captureImage: async ({ timeout }) => {
      assert.ok(Number.isFinite(timeout) && timeout > 0 && timeout <= 10_000);
      return outputs.shift();
    },
    saveSample: async (sample) => { saved.push(sample); },
    readState: async () => stableStateFixture(),
    waitForFrames: async (_page, timeout) => { assert.ok(timeout > 0); frameCount += 1; }
  });
  assert.deepEqual(result.image, Buffer.from("B"));
  assert.equal(result.stability.method, "consecutive-exact-v1");
  assert.equal(result.stability.selected, 2);
  assert.equal(result.stability.samples.length, 3);
  assert.equal(frameCount, 3, "a two-frame barrier runs before every sample");
  assert.deepEqual(saved.map(({ path }) => path), [0, 1, 2].map(index => `help--dark--1280--viewport-sample-${index}.png`));
  assert.deepEqual(saved.map(({ state_path }) => state_path), [0, 1, 2].map(index => `help--dark--1280--viewport-sample-${index}.json`));
  assert.ok(result.stability.samples.every(({ elapsed_ms }) => Number.isFinite(elapsed_ms) && elapsed_ms <= 10_000));
  for (const sample of saved) {
    const sidecar = JSON.parse(sample.state_bytes.toString("utf8"));
    assert.deepEqual(sidecar, { ...sidecar.after, before: sidecar.before, after: sidecar.after });
    assert.deepEqual(domStateErrors(sidecar, { surface: "help", theme: "dark", viewport: { width: 1280, height: 900 }, interaction_target: interactionTarget }, "viewport", "saved stable sample"), []);
  }
});

test("default entry preparation waits for active animation, fonts, and two real animation frames", async () => {
  const events = [];
  const animationFinished = deferred();
  let isAnimationFinished = false;
  const animation = {
    get playState() { return isAnimationFinished ? "finished" : "running"; },
    pending: false,
    effect: { getComputedTiming: () => ({ endTime: 100 }) },
    finished: animationFinished.promise
  };
  const readiness = installReadinessDocument(animation, events);
  let reads = 0;
  const outcome = captureStableImage({
    page: { evaluate: (fn, argument) => fn(argument) },
    id: "entry-barrier", kind: "viewport",
    captureImage: async () => Buffer.from("same"),
    saveSample: async () => {},
    readState: async () => { events.push("read-state"); reads += 1; return stableStateFixture(); },
    waitForFrames: async () => {}
  }).then(value => ({ value }), error => ({ error }));
  const surfaceOutcome = outcome.then(({ error }) => {
    if (error) throw error;
    throw new Error("Capture completed before the readiness event being awaited.");
  });
  try {
    await Promise.race([readiness.animationObserved, surfaceOutcome]);
    assert.equal(reads, 0, "the state anchor must wait for the finite animation");
    isAnimationFinished = true;
    animationFinished.resolve();
    await Promise.race([readiness.fontsObserved, surfaceOutcome]);
    assert.equal(reads, 0, "the state anchor must wait for document.fonts.ready");
    readiness.resolveFonts();
    await Promise.race([readiness.runNextFrame(), surfaceOutcome]);
    await Promise.race([readiness.runNextFrame(), surfaceOutcome]);
    const result = await outcome;
    if (result.error) throw result.error;
    assert.equal(result.value.stability.selected, 1);
    assert.ok(events.indexOf("await-fonts") < events.indexOf("read-state"));
    assert.equal(events.filter(event => event === "run-frame").length, 2);
    assert.ok(events.lastIndexOf("scan-animations") < events.indexOf("read-state"));
  } finally {
    isAnimationFinished = true;
    animationFinished.resolve();
    readiness.resolveFonts();
    readiness.restore();
  }
});

test("native-invisible finite animation does not block entry preparation on its unresolved finished promise", async () => {
  const events = [];
  const checkArguments = [];
  const hidden = controllableEntryAnimation({
    id: "hidden-scrollbar-transition",
    target: { checkVisibility(...args) { checkArguments.push(args); return false; } },
    events
  });
  const readiness = installAnimationVisibilityDocument([hidden.animation], events);
  const preparation = prepareCaptureStateInPage();
  try {
    await readiness.animationObserved;
    await Promise.resolve();
    assert.deepEqual(checkArguments, [[]], "use only native checkVisibility() default options");
    assert.equal(events.includes("await-finished:hidden-scrollbar-transition"), false, "native-invisible transition remains unresolved and is not awaited");
    await preparation;
    assert.ok(events.filter((event) => event === "run-frame").length >= 2, "font and two-frame settlement still run");
  } finally {
    hidden.finish();
    await preparation.catch(() => {});
    readiness.restore();
  }
});

test("visible and unknown finite entry animations remain awaited, including opacity-zero and offscreen targets", async () => {
  const events = [];
  let visibilityCalls = 0;
  const offscreenOpacityZeroTarget = {
    opacity: 0,
    rect: { x: 5000, y: 0, width: 20, height: 20 },
    checkVisibility(...args) {
      visibilityCalls += 1;
      assert.deepEqual(args, [], "default checkVisibility does not opt into opacity or viewport checks");
      return true;
    }
  };
  const targetUnavailable = {};
  const targetThrows = { checkVisibility() { throw new Error("visibility API read failed"); } };
  const visible = controllableEntryAnimation({ id: "visible-opacity-zero-offscreen", target: offscreenOpacityZeroTarget, events });
  const missing = controllableEntryAnimation({ id: "missing-target", target: null, events });
  const unavailable = controllableEntryAnimation({ id: "missing-api", target: targetUnavailable, events });
  const throws = controllableEntryAnimation({ id: "throwing-api", target: targetThrows, events });
  const readiness = installAnimationVisibilityDocument([visible.animation, missing.animation, unavailable.animation, throws.animation], events);
  let settled = false;
  const preparation = prepareCaptureStateInPage().then(() => { settled = true; });
  try {
    await readiness.animationObserved;
    await Promise.resolve();
    assert.equal(visibilityCalls, 1, "native visibility is queried only for an API-bearing target");
    assert.deepEqual(events.filter((event) => event.startsWith("await-finished:")), [
      "await-finished:visible-opacity-zero-offscreen",
      "await-finished:missing-target",
      "await-finished:missing-api",
      "await-finished:throwing-api"
    ], "true, missing, unavailable, and throwing visibility results all fail closed to awaiting");
    assert.equal(settled, false, "preparation waits for all still-running animations");
    visible.finish();
    missing.finish();
    unavailable.finish();
    throws.finish();
    await preparation;
    assert.equal(settled, true);
  } finally {
    visible.finish();
    missing.finish();
    unavailable.finish();
    throws.finish();
    await preparation.catch(() => {});
    readiness.restore();
  }
});

test("cancelled finite entry animation fails before the first state anchor", async () => {
  const events = [];
  const animationFinished = deferred();
  const animation = {
    playState: "running", pending: true,
    effect: { target: { checkVisibility: () => true }, getComputedTiming: () => ({ endTime: 100 }) },
    finished: animationFinished.promise
  };
  const readiness = installReadinessDocument(animation, events);
  let reads = 0;
  const cancelError = new Error("entry animation was cancelled");
  const outcome = captureStableImage({
    page: { evaluate: (fn, argument) => fn(argument) },
    id: "entry-cancelled", kind: "viewport",
    captureImage: async () => Buffer.from("same"), saveSample: async () => {},
    readState: async () => { reads += 1; return stableStateFixture(); },
    waitForFrames: async () => {}
  });
  try {
    await readiness.animationObserved;
    animationFinished.reject(cancelError);
    await assert.rejects(outcome, error => error === cancelError);
    assert.equal(reads, 0);
  } finally {
    readiness.restore();
  }
});

test("stable entry capture settles readiness before its first state anchor", async () => {
  const events = [];
  let settled = false;
  let releaseAnimation;
  let announcePreparation;
  let announceFirstRead;
  const animationFinished = new Promise(resolve => { releaseAnimation = resolve; });
  const preparationStarted = new Promise(resolve => { announcePreparation = resolve; });
  const firstReadStarted = new Promise(resolve => { announceFirstRead = resolve; });
  const outcome = captureStableImage({
    page: {}, id: "entry-ready", kind: "viewport",
    prepareState: async (_page, timeout) => {
      assert.ok(Number.isFinite(timeout) && timeout > 0 && timeout <= 10_000);
      events.push("prepare");
      announcePreparation();
      await animationFinished;
      settled = true;
      events.push("settled");
    },
    captureImage: async () => Buffer.from("same"),
    saveSample: async () => {},
    readState: async () => {
      events.push("read");
      announceFirstRead();
      assert.equal(settled, true, "the first state anchor must follow natural animation completion");
      return { schema: "scrypath.ui-capture-state.v1", body_text: "entry" };
    },
    waitForFrames: async () => {}
  }).then(value => ({ value }), error => ({ error }));

  const first = await Promise.race([
    preparationStarted.then(() => "prepare"),
    firstReadStarted.then(() => "read")
  ]);
  assert.equal(first, "prepare", "entry readiness must begin before the first state read");
  assert.deepEqual(events, ["prepare"]);
  releaseAnimation();
  const result = await outcome;
  if (result.error) throw result.error;
  assert.deepEqual(events.slice(0, 2), ["prepare", "settled"]);
  assert.equal(result.value.stability.selected, 1);
});

test("stable capture rejects persistent image instability after the configured sample bound", async () => {
  const outputs = ["A", "B", "A", "B", "A", "B"].map(value => Buffer.from(value));
  const saved = [];
  await assert.rejects(captureStableImage({
    page: {}, id: "unstable", kind: "focus",
    prepareState: async () => {},
    captureImage: async () => outputs.shift(),
    saveSample: async sample => { saved.push(sample); },
    readState: async () => stableStateFixture(),
    waitForFrames: async () => {},
    maxSamples: 6
  }), error => {
    assert.match(error.message, /did not produce two consecutive byte-equal images/);
    assert.equal(error.captureStability.samples.length, 6);
    assert.equal(error.captureStability.selected, null);
    return true;
  });
  assert.equal(saved.length, 6);
});

test("stable capture retains and rejects a DOM change around the screenshot", async () => {
  const saved = [];
  let reads = 0;
  await assert.rejects(captureStableImage({
    page: {}, id: "changing", kind: "hover",
    prepareState: async () => {},
    captureImage: async () => Buffer.from("sample"),
    saveSample: async sample => { saved.push(sample); },
    readState: async () => ++reads === 1 ? stableStateFixture() : stableStateFixture("Updated help text"),
    waitForFrames: async () => {}
  }), error => {
    assert.match(error.message, /state changed around the screenshot/);
    assert.equal(error.captureStability.samples.length, 1);
    return true;
  });
  const sidecar = JSON.parse(saved[0].state_bytes.toString("utf8"));
  assert.equal(sidecar.before.body_text, "Help entry");
  assert.equal(sidecar.after.body_text, "Updated help text");
});

test("stable capture preserves screenshot and sample IO errors while retaining evidence when available", async () => {
  const screenshotError = new Error("screenshot backend failed");
  const failedArtifacts = [];
  await assert.rejects(captureStableImage({
    page: {}, id: "screenshot-failure", kind: "viewport",
    prepareState: async () => {},
    captureImage: async () => { throw screenshotError; },
    saveSample: async sample => { failedArtifacts.push(sample); },
    readState: async () => stableStateFixture(),
    waitForFrames: async () => {}
  }), error => {
    assert.equal(error, screenshotError);
    assert.equal(error.captureStability.failed_attempt.phase, "screenshot");
    assert.equal(error.captureStability.failed_attempt.path, null);
    return true;
  });
  assert.equal(failedArtifacts.length, 1);
  const failedSidecar = JSON.parse(failedArtifacts[0].state_bytes.toString("utf8"));
  assert.deepEqual(failedSidecar.before, stableStateFixture());
  assert.equal(failedSidecar.after, null);

  const ioError = new Error("exclusive evidence write failed");
  await assert.rejects(captureStableImage({
    page: {}, id: "io-failure", kind: "viewport",
    prepareState: async () => {},
    captureImage: async () => Buffer.from("image"),
    saveSample: async () => { throw ioError; },
    readState: async () => stableStateFixture(),
    waitForFrames: async () => {}
  }), error => error === ioError);
});

test("stable capture enforces hard sample and elapsed-time caps", async () => {
  const options = { page: {}, id: "bounded", kind: "viewport", captureImage: async () => Buffer.from("image"), saveSample: async () => {}, prepareState: async () => {}, readState: async () => stableStateFixture(), waitForFrames: async () => {} };
  await assert.rejects(captureStableImage({ ...options, maxSamples: 7 }), /configured sample and time caps/);
  await assert.rejects(captureStableImage({ ...options, maxElapsedMs: 10_001 }), /configured sample and time caps/);
  await assert.rejects(captureStableImage({
    ...options, maxElapsedMs: 20,
    waitForFrames: () => new Promise(() => {})
  }), /time budget/);
});


test("disposable browser launch pins full rasterization without replacing other defaults", async () => {
  const original = {};
  let received;
  const result = await launchDisposableBrowser({ launch: async options => { received = structuredClone(options); return original; } });
  assert.equal(result.browser, original);
  assert.deepEqual(result.launchOptions, received);
  assert.equal(received.args?.includes("--disable-partial-raster"), true, "the actual launch call must pin full rasterization");
  assert.deepEqual(received.args, ["--disable-partial-raster"]);
  assert.equal(received.timeout, 30_000);
  assert.equal(Object.hasOwn(received, "ignoreDefaultArgs"), false);
});

function fakeFontProfileBrowser({ failureAt = null, requireProfileBeforeNavigation = true } = {}) {
  const events = [];
  const failure = failureAt ? new Error(`synthetic CDP failure at ${failureAt}`) : null;
  const navigationStop = new Error("test stopped after the first navigation boundary");
  let profileAcknowledged = false;
  let contextClosed = false;
  let gotoCalled = false;
  let detachCalls = 0;
  let session;
  const page = {
    setDefaultTimeout: () => events.push("default-timeout"),
    on: event => events.push(`listen-${event}`),
    goto: async route => {
      gotoCalled = true;
      events.push(`goto-${route}`);
      if (requireProfileBeforeNavigation) assert.equal(profileAcknowledged, true, "Page.setFontFamilies must be acknowledged before page.goto");
      throw navigationStop;
    }
  };
  const context = {
    addInitScript: async () => { events.push("init-script"); },
    newPage: async () => {
      events.push("new-page");
      if (failureAt === "new-page") throw failure;
      return page;
    },
    newCDPSession: async actualPage => {
      events.push("new-cdp-session");
      assert.equal(actualPage, page);
      if (failureAt === "new-cdp-session") throw failure;
      session = {
        send: async (method, params) => {
          events.push(method);
          if (method === failureAt) throw failure;
          if (method === "Page.enable") return {};
          assert.equal(method, "Page.setFontFamilies");
          assert.deepEqual(params, { fontFamilies: { fixed: "Liberation Mono" } });
          profileAcknowledged = true;
          return {};
        },
        detach: async () => { detachCalls += 1; }
      };
      return session;
    },
    close: async () => { contextClosed = true; events.push("close-context"); }
  };
  return {
    browser: { newContext: async () => { events.push("new-context"); return context; } },
    context, page, events, failure, navigationStop, get contextClosed() { return contextClosed; },
    get gotoCalled() { return gotoCalled; }, get detachCalls() { return detachCalls; }, get session() { return session; }
  };
}

test("font profile setup waits for exact CDP acknowledgements and returns the live session separately", async () => {
  const events = [];
  const page = {};
  const session = { send: async (method, params) => { events.push([method, params]); return {}; } };
  const setup = await configureDisposableFontProfile({ newCDPSession: async actualPage => { assert.equal(actualPage, page); events.push(["newCDPSession", actualPage]); return session; } }, page);
  const expectedProfile = {
    method: "retained-cdp-fixed-font-v1",
    font_families: { fixed: "Liberation Mono" },
    applied: "before-first-navigation",
    lifetime: "page-context"
  };
  assert.deepEqual(setup.profile, expectedProfile);
  assert.equal(setup.session, session, "the live CDP session must be retained separately from serializable profile metadata");
  assert.deepEqual(events.map(([method]) => method), ["newCDPSession", "Page.enable", "Page.setFontFamilies"]);
  assert.deepEqual(events[2][1], { fontFamilies: { fixed: "Liberation Mono" } });
  assert.deepEqual(JSON.parse(JSON.stringify({ browser_font_profile: setup.profile })), { browser_font_profile: expectedProfile });
});

test("disposable surface waits for font-profile acknowledgement before navigation and holds the session through context close", async () => {
  const fake = fakeFontProfileBrowser();
  const capture = await captureSurface(fake.browser, { id: "control-room", route: "/admin/search/" }, "light", { width: 1440, height: 900 }, "/tmp/font-profile-boundary", { deployment: "host", baseURL: "http://web:4002" });
  const expectedProfile = {
    method: "retained-cdp-fixed-font-v1",
    font_families: { fixed: "Liberation Mono" },
    applied: "before-first-navigation",
    lifetime: "page-context"
  };
  assert.equal(capture.error, fake.navigationStop.message);
  assert.deepEqual(capture.browser_font_profile, expectedProfile);
  assert.deepEqual(fake.events, ["new-context", "init-script", "new-page", "new-cdp-session", "Page.enable", "Page.setFontFamilies", "default-timeout", "listen-pageerror", "goto-/admin/search/", "close-context"]);
  assert.equal(fake.contextClosed, true);
  assert.equal(fake.detachCalls, 0, "the CDP session remains attached until BrowserContext closes");
});

test("partial disposable page and CDP setup failures close context and do not publish a profile", async () => {
  for (const failureAt of ["new-page", "Page.setFontFamilies"]) {
    const fake = fakeFontProfileBrowser({ failureAt });
    const capture = await captureSurface(fake.browser, { id: "control-room", route: "/admin/search/" }, "light", { width: 1440, height: 900 }, "/tmp/font-profile-failure", { deployment: "host", baseURL: "http://web:4002" });
    assert.equal(capture.error, fake.failure.message);
    assert.equal(Object.hasOwn(capture, "browser_font_profile"), false);
    assert.equal(fake.gotoCalled, false);
    assert.equal(fake.contextClosed, true, `BrowserContext must close after ${failureAt} fails`);
    assert.equal(fake.detachCalls, 0);
  }
});

test("retained capture path does not create a CDP font profile", async () => {
  const fake = fakeFontProfileBrowser({ requireProfileBeforeNavigation: false });
  const capture = await captureSurface(fake.browser, { id: "control-room", route: "/admin/search/" }, "light", { width: 1440, height: 900 }, "/tmp/font-profile-retained");
  assert.equal(capture.error, fake.navigationStop.message);
  assert.equal(Object.hasOwn(capture, "browser_font_profile"), false);
  assert.equal(fake.events.includes("new-cdp-session"), false);
  assert.equal(fake.contextClosed, true);
});

test("disposable capture matrix stops and closes after its first capture error", async () => {
  const { chromium } = await import("@playwright/test");
  const originalLaunch = chromium.launch;
  const originalOwnLaunch = Object.getOwnPropertyDescriptor(chromium, "launch");
  const navigationError = new Error("injected first navigation failure");
  let contextCount = 0;
  let contextCloseCount = 0;
  let browserCloseCount = 0;
  const browser = {
    version: () => "stub-browser",
    newContext: async () => {
      contextCount += 1;
      const page = {
        clock: { setFixedTime: async () => {} },
        setDefaultTimeout: () => {},
        on: () => {},
        goto: async () => { throw navigationError; }
      };
      return {
        addInitScript: async () => {},
        newPage: async () => page,
        newCDPSession: async () => ({ send: async () => ({}) }),
        close: async () => { contextCloseCount += 1; }
      };
    },
    close: async () => { browserCloseCount += 1; }
  };
  const utc = "2026-10-31T12:00:00.000Z";
  const { createHash } = await import("node:crypto");
  const clock = { utc, sha256: createHash("sha256").update(`${utc}\n`).digest("hex"), timezone: "UTC", locale: "en-US", browser_mode: "fixed-date" };
  chromium.launch = async () => browser;
  let outcome;
  try {
    outcome = await captureDisposableMatrix({
      hostUrl: "http://web:4002", standaloneUrl: "http://standalone_ops:4003",
      output: "/artifacts", dataIdentity: "test-data-identity", clock, allowComposeNetwork: true
    }).then(value => ({ value }), error => ({ error }));
  } finally {
    if (originalOwnLaunch) Object.defineProperty(chromium, "launch", originalOwnLaunch);
    else delete chromium.launch;
  }
  assert.deepEqual({
    rejected: Boolean(outcome.error),
    error: outcome.error?.message ?? null,
    new_contexts: contextCount,
    returned_captures: outcome.value?.captures.length ?? null,
    first_capture_error: outcome.value?.captures[0]?.error ?? null,
    closed_contexts: contextCloseCount,
    closed_browsers: browserCloseCount
  }, {
    rejected: true,
    error: `Disposable capture host--storefront--light--1440 failed: ${navigationError.message}`,
    new_contexts: 1,
    returned_captures: null,
    first_capture_error: null,
    closed_contexts: 1,
    closed_browsers: 1
  }, "the matrix must stop after the first failed entry and close its page context and browser");
});

test("disposable surface acknowledges the retained native font profile before first navigation", async () => {
  const events = [];
  const expectedProfile = {
    method: "retained-cdp-fixed-font-v1",
    font_families: { fixed: "Liberation Mono" },
    applied: "before-first-navigation",
    lifetime: "page-context"
  };
  const navigationStop = new Error("test stopped after the first navigation boundary");
  let profileAcknowledged = false;
  let contextClosed = false;
  let detachCalls = 0;
  const browser = {
    newContext: async () => {
      events.push("new-context");
      return {
        addInitScript: async () => { events.push("init-script"); },
        newPage: async () => {
          events.push("new-page");
          return {
            setDefaultTimeout: () => events.push("default-timeout"),
            on: event => events.push(`listen-${event}`),
            goto: async route => {
              events.push(`goto-${route}`);
              assert.equal(profileAcknowledged, true, "Page.setFontFamilies must be acknowledged before page.goto");
              throw navigationStop;
            }
          };
        },
        newCDPSession: async () => {
          events.push("new-cdp-session");
          return {
            send: async (method, params) => {
              events.push(method);
              if (method === "Page.enable") return {};
              assert.equal(method, "Page.setFontFamilies");
              assert.deepEqual(params, { fontFamilies: { fixed: "Liberation Mono" } });
              profileAcknowledged = true;
              return {};
            },
            detach: async () => { detachCalls += 1; }
          };
        },
        close: async () => { contextClosed = true; events.push("close-context"); }
      };
    }
  };

  const capture = await captureSurface(browser, { id: "control-room", route: "/admin/search/" }, "light", { width: 1440, height: 900 }, "/tmp/font-profile-boundary", {
    deployment: "host",
    baseURL: "http://web:4002"
  });

  assert.equal(capture.error, navigationStop.message);
  assert.deepEqual(capture.browser_font_profile, expectedProfile);
  assert.deepEqual(events, ["new-context", "init-script", "new-page", "new-cdp-session", "Page.enable", "Page.setFontFamilies", "default-timeout", "listen-pageerror", "goto-/admin/search/", "close-context"]);
  assert.equal(contextClosed, true);
  assert.equal(detachCalls, 0, "the CDP session stays attached until its BrowserContext closes");
});
