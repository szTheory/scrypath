const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const {
  cpSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { randomUUID } = require("node:crypto");
const { test } = require("node:test");
const { assertBundles, assertMountedStylesheetOrder } = require("./ui_bundle_contract.cjs");

const repositoryRoot = path.resolve(__dirname, "../..");
const representativeUtilities = [
  "bg-red-500",
  "text-blue-500",
  "bg-black",
  "text-black",
  "bg-white",
  "text-white",
  "bg-primary",
  "text-base-content",
  "p-4",
  "gap-8",
  "text-sm",
  "font-semibold",
].join(" ");

function copyBuildContext(destination) {
  const excludedDirectories = new Set([
    ".agents",
    ".claude",
    ".codex",
    ".git",
    ".planning",
    "_build",
    "deps",
    "node_modules",
    "ui-review-artifacts",
  ]);
  const excludedOutputs = new Set([
    "examples/scrypath_ecommerce/priv/static/assets",
    "scrypath_ops/priv/static/assets",
  ]);

  cpSync(repositoryRoot, destination, {
    recursive: true,
    filter(source) {
      const relative = path.relative(repositoryRoot, source).split(path.sep).join("/");
      if (!relative) return true;
      if (excludedDirectories.has(relative.split("/")[0])) return false;
      if ([...excludedOutputs].some((output) => relative === output || relative.startsWith(`${output}/`))) {
        return false;
      }
      return relative !== "examples/scrypath_ecommerce/priv/static/cache_manifest.json" &&
        relative !== "scrypath_ops/priv/static/cache_manifest.json";
    },
  });

  for (const stylesheet of [
    "scrypath_ops/assets/css/app.css",
    "examples/scrypath_ecommerce/assets/css/app.css",
  ]) {
    const target = path.join(destination, stylesheet);
    const original = readFileSync(target, "utf8");
    writeFileSync(target, `${original}\n@source inline("${representativeUtilities}");\n`);
  }
}

function runDocker(args, options = {}) {
  const result = spawnSync("docker", args, {
    encoding: "utf8",
    maxBuffer: 10 * 1024 * 1024,
    timeout: 20 * 60 * 1000,
    env: {
      ...process.env,
      BUILDX_CONFIG: path.join(os.tmpdir(), `scrypath-phase185-buildx-${process.pid}`),
    },
    ...options,
  });
  assert.equal(result.error, undefined, result.error?.message);
  return result;
}

function extractBundle(container, source, destination) {
  mkdirSync(path.dirname(destination), { recursive: true });
  const result = runDocker(["cp", `${container}:${source}`, destination]);
  assert.equal(result.status, 0, result.stderr || result.stdout);
  assert.ok(existsSync(destination), `Docker did not extract ${source}`);
  return readFileSync(destination, "utf8");
}

function fixtureCss({ palette = false, utilities = true, semantic = false } = {}) {
  return [
    palette && ".bg-red-500{background-color:var(--color-red-500)}.text-blue-500{color:var(--color-blue-500)}",
    utilities && [
      ".bg-black{background-color:var(--color-black)}",
      ".text-black{color:var(--color-black)}",
      ".bg-white{background-color:var(--color-white)}",
      ".text-white{color:var(--color-white)}",
      ".p-4{padding:calc(var(--spacing)*4)}",
      ".gap-8{gap:calc(var(--spacing)*8)}",
      ".text-sm{font-size:var(--text-sm)}",
      ".font-semibold{font-weight:var(--font-weight-semibold)}",
    ].join(""),
    semantic && ".bg-primary{background-color:var(--color-primary)}.text-base-content{color:var(--color-base-content)}",
  ].filter(Boolean).join("");
}

test("forced default palette utilities are rejected independently in either output", () => {
  const goodOps = fixtureCss({ semantic: true });
  const goodHost = fixtureCss();
  assert.doesNotThrow(() => assertBundles({ standaloneCss: goodOps, hostCss: goodHost }));
  assert.throws(() => assertBundles({ standaloneCss: fixtureCss({ palette: true, semantic: true }), hostCss: goodHost }), /standalone Ops.*default palette/);
  assert.throws(() => assertBundles({ standaloneCss: goodOps, hostCss: fixtureCss({ palette: true }) }), /mounted host.*default palette/);
});

test("black, white, spacing, typography, semantic utilities, and both outputs are required", () => {
  const goodOps = fixtureCss({ semantic: true });
  const goodHost = fixtureCss();
  const missing = [
    ["black", (css) => css.replace(".bg-black{background-color:var(--color-black)}", "")],
    ["white", (css) => css.replace(".text-white{color:var(--color-white)}", "")],
    ["spacing", () => fixtureCss({ utilities: false })],
    ["typography", (css) => css.replace(".font-semibold{font-weight:var(--font-weight-semibold)}", "")],
  ];
  for (const [output, standalone] of [["standalone Ops", true], ["mounted host", false]]) {
    for (const [label, remove] of missing) {
      const current = standalone ? goodOps : goodHost;
      const invalid = remove(current);
      assert.throws(
        () => assertBundles({ standaloneCss: standalone ? invalid : goodOps, hostCss: standalone ? goodHost : invalid }),
        new RegExp(output),
        `${output} must reject missing ${label}`,
      );
    }
  }
  assert.throws(() => assertBundles({ standaloneCss: goodOps.replace(".text-base-content{color:var(--color-base-content)}", ""), hostCss: goodHost }), /standalone Ops.*text-base-content/);
  assert.throws(() => assertBundles({ standaloneCss: goodOps, hostCss: "" }), /mounted host.*missing or empty/);
  assert.throws(() => assertBundles({ standaloneCss: undefined, hostCss: goodHost }), /standalone Ops.*missing or empty/);
});

test("mounted stylesheet contract requires host CSS before independent Ops CSS", () => {
  assert.doesNotThrow(() => assertMountedStylesheetOrder('<link rel="stylesheet" href="/assets/css/app.css"><link rel="stylesheet" href="/admin/search/assets/css/app.css?v=abc">'));
  assert.throws(() => assertMountedStylesheetOrder('<link rel="stylesheet" href="/admin/search/assets/css/app.css"><link rel="stylesheet" href="/assets/css/app.css">'), /host CSS before Ops CSS/);
  assert.throws(() => assertMountedStylesheetOrder('<link rel="stylesheet" href="/assets/css/app.css">'), /missing the independently served Ops stylesheet/);
});

test("CLI fails closed for a missing output file", (t) => {
  const absent = path.join(os.tmpdir(), `scrypath-missing-bundle-${randomUUID()}.css`);
  const result = spawnSync(process.execPath, [path.join(__dirname, "ui_bundle_contract.cjs"), "--standalone", absent, "--host", absent], { encoding: "utf8" });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /standalone Ops output file is missing/);
});

test("both configured Tailwind profiles remove forced default palette utilities", { timeout: 20 * 60 * 1000 }, (t) => {
  const runId = randomUUID().replaceAll("-", "");
  const image = `scrypath-ui-bundle-contract-${process.pid}-${runId}`;
  const context = mkdtempSync(path.join(os.tmpdir(), `scrypath-ui-bundle-context-${runId}-`));
  const artifactRoot = process.env.SCRYPATH_UI_BUNDLE_ARTIFACT_DIR || path.join(os.tmpdir(), "scrypath-phase185-ui-bundle");
  const artifacts = path.join(artifactRoot, runId);
  const buildxConfig = path.join(os.tmpdir(), `scrypath-phase185-buildx-${process.pid}`);
  mkdirSync(artifacts, { recursive: true });
  t.after(() => rmSync(context, { recursive: true, force: true }));
  t.after(() => rmSync(buildxConfig, { recursive: true, force: true }));

  copyBuildContext(context);
  const buildLog = path.join(artifacts, "asset-builder.log");
  const build = runDocker(
    ["build", "--file", path.join(context, "examples/scrypath_ecommerce/Dockerfile"), "--target", "asset_builder", "--tag", image, context],
    { cwd: context },
  );
  writeFileSync(buildLog, `${build.stdout || ""}${build.stderr || ""}`);
  assert.equal(build.status, 0, `source-pinned asset-builder failed; see ${buildLog}\n${build.stderr || build.stdout}`);

  let container = "";
  try {
    const created = runDocker(["create", image]);
    assert.equal(created.status, 0, created.stderr || created.stdout);
    container = created.stdout.trim();
    assert.ok(container, "Docker did not return the disposable asset-builder container ID");

    const bundles = [
      ["standalone", "/app/scrypath_ops/priv/static/assets/css/app.css", "standalone.css"],
      ["mounted host", "/app/examples/scrypath_ecommerce/priv/static/assets/css/app.css", "host.css"],
    ];
    const outputs = [];
    for (const [label, source, filename] of bundles) {
      const css = extractBundle(container, source, path.join(artifacts, filename));
      assert.ok(css.length > 0, `${label} output must not be empty`);
      outputs.push([label, css]);
    }
    assertBundles({ standaloneCss: outputs[0][1], hostCss: outputs[1][1] });
  } finally {
    if (container) {
      const removed = runDocker(["rm", "--force", container]);
      assert.equal(removed.status, 0, `could not remove disposable asset-builder container ${container}: ${removed.stderr}`);
    }
    const removedImage = runDocker(["image", "rm", "--force", image]);
    if (removedImage.status !== 0 && !/No such image/i.test(removedImage.stderr)) {
      assert.equal(removedImage.status, 0, `could not remove disposable asset-builder image ${image}: ${removedImage.stderr}`);
    }
  }
});
