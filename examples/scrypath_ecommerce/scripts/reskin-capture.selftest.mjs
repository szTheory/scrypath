// Self-test for scripts/reskin-capture.mjs (Phase 187, SKIN-08): the parts that need no browser and no
// stack (the one network read is a stand-in HTTP server on loopback). What it proves: the inventory
// check accepts a complete set and names whatever is missing, altered or extra; the dirty-tree refusal
// fires for any change outside `.planning/`, tracked or untracked (review WR-02); the manifest's
// `clean` is derived, not a literal; the served ops stylesheet is found, hashed and compared with
// HEAD, a mismatch is refused unless `--allow-stale-source` is passed, and both the hashes and the
// flag are recorded and re-checked by `--check`.
//
//   node --test scripts/reskin-capture.selftest.mjs

import { test, after } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, unlinkSync, writeFileSync } from "node:fs";
import { createServer } from "node:http";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  MANIFEST_NAME,
  OPS_STYLESHEET_PATH,
  SCENARIO,
  SCHEMA,
  assertCleanTree,
  assessStylesheet,
  checkInventory,
  checkProvenance,
  expectedFiles,
  fetchServedStylesheet,
  findOpsStylesheetHref,
  headStylesheetSha256,
  inspectTree,
  parseArgs,
  sha256,
} from "./reskin-capture.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SCRIPT = path.join(HERE, "reskin-capture.mjs");

const roots = [];
after(() => {
  for (const dir of roots) rmSync(dir, { recursive: true, force: true });
});

/** A complete capture directory: 12 distinct stand-in PNGs and a manifest that matches them. */
function makeCaptureDir() {
  const dir = mkdtempSync(path.join(os.tmpdir(), "reskin-capture-selftest-"));
  roots.push(dir);
  const files = expectedFiles().map((name) => {
    const bytes = Buffer.from(`not a real png: ${name}`);
    writeFileSync(path.join(dir, name), bytes);
    return { name, sha256: sha256(bytes) };
  });
  const manifest = { schema: SCHEMA, label: "before", source_sha: "0".repeat(40), clean: true, git_status: [], files };
  writeFileSync(path.join(dir, MANIFEST_NAME), `${JSON.stringify(manifest, null, 2)}\n`);
  return dir;
}

test("expected inventory is three screens, light and dark, 1280 and 390", () => {
  const names = expectedFiles();
  assert.equal(names.length, 12);
  assert.equal(new Set(names).size, 12);
  for (const screen of ["control-room", "search-health", "failed-sync"]) {
    for (const theme of ["light", "dark"]) {
      for (const width of [1280, 390]) assert.ok(names.includes(`${screen}-${theme}-${width}.png`), `${screen}-${theme}-${width}`);
    }
  }
});

test("the capture scenario is the all-statuses fixture", () => {
  assert.equal(SCENARIO, "all-statuses");
  assert.match(readFileSync(SCRIPT, "utf8"), /phase173\/health\?scenario=\$\{SCENARIO\}/);
});

test("inventory check passes on a complete set with a matching manifest", () => {
  const result = checkInventory(makeCaptureDir());
  assert.deepEqual(result.errors, []);
  assert.equal(result.ok, true);
  assert.equal(result.count, 12);
});

test("inventory check fails naming the file when one PNG is removed", () => {
  const dir = makeCaptureDir();
  const gone = "search-health-dark-390.png";
  unlinkSync(path.join(dir, gone));
  const result = checkInventory(dir);
  assert.equal(result.ok, false);
  assert.equal(result.count, 11);
  assert.ok(result.errors.some((error) => error.includes(gone)), result.errors.join("\n"));
});

test("inventory check fails when a hash differs from the manifest", () => {
  const dir = makeCaptureDir();
  const altered = "control-room-light-1280.png";
  writeFileSync(path.join(dir, altered), "changed after the manifest was written");
  const result = checkInventory(dir);
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((error) => error.includes("hash mismatch") && error.includes(altered)), result.errors.join("\n"));
});

test("inventory check fails when the manifest is missing", () => {
  const dir = makeCaptureDir();
  unlinkSync(path.join(dir, MANIFEST_NAME));
  const result = checkInventory(dir);
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((error) => error.includes(MANIFEST_NAME)), result.errors.join("\n"));
});

test("inventory check fails when a file is not listed in the manifest or an extra file is present", () => {
  const dir = makeCaptureDir();
  const manifestPath = path.join(dir, MANIFEST_NAME);
  const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
  manifest.files = manifest.files.filter((entry) => entry.name !== "failed-sync-dark-1280.png");
  writeFileSync(manifestPath, JSON.stringify(manifest));
  assert.ok(checkInventory(dir).errors.some((error) => error.includes("failed-sync-dark-1280.png is not listed")));

  const clean = makeCaptureDir();
  writeFileSync(path.join(clean, "contact-sheet.png"), "derivative");
  assert.ok(checkInventory(clean).errors.some((error) => error.includes("contact-sheet.png")));
});

test("inventory check fails on a missing directory", () => {
  const result = checkInventory(path.join(os.tmpdir(), "reskin-capture-selftest-does-not-exist"));
  assert.equal(result.ok, false);
});

test("the --check command prints the inventory count and exits non-zero when incomplete", () => {
  const good = spawnSync(process.execPath, [SCRIPT, "--check", makeCaptureDir()], { encoding: "utf8" });
  assert.equal(good.status, 0, good.stderr);
  assert.match(good.stdout, /capture inventory: 12\/12/);

  const dir = makeCaptureDir();
  unlinkSync(path.join(dir, "control-room-dark-390.png"));
  const bad = spawnSync(process.execPath, [SCRIPT, "--check", dir], { encoding: "utf8" });
  assert.notEqual(bad.status, 0);
  assert.match(bad.stderr, /control-room-dark-390\.png/);
  assert.doesNotMatch(bad.stdout, /capture inventory: 12\/12/);
});

test("clean-tree refusal throws on a tracked change outside .planning", () => {
  assert.throws(() => assertCleanTree(" M scrypath_ops/assets/css/app.css\n"), /dirty tree.*scrypath_ops\/assets\/css\/app\.css/);
  assert.throws(() => assertCleanTree("M  examples/scrypath_ecommerce/e2e/ui-review.mjs\n"), /ui-review\.mjs/);
  assert.throws(() => assertCleanTree(" M .planning/UI-PREVIEW.json\n D lib/scrypath.ex\n"), /lib\/scrypath\.ex/);
  assert.throws(() => assertCleanTree("R  .planning/old.md -> docs/new.md\n"), /docs\/new\.md/);
});

test("clean-tree refusal throws on an untracked file or directory outside .planning (WR-02)", () => {
  // A new source file under a bind-mounted dev stack is compiled whatever git thinks of it.
  assert.throws(() => assertCleanTree("?? scrypath_ops/lib/new.ex\n"), /dirty tree.*scrypath_ops\/lib\/new\.ex \(untracked\)/);
  assert.throws(() => assertCleanTree("?? scrypath_ops/lib/scrypath_ops_web/live/new_live.heex\n"), /new_live\.heex/);
  assert.throws(() => assertCleanTree("?? examples/scrypath_ecommerce/assets/css/extra.css\n"), /extra\.css/);
  assert.throws(() => assertCleanTree("?? scrypath_ops/assets/js/new_hook.js\n"), /new_hook\.js/);
  assert.throws(() => assertCleanTree("?? examples/scrypath_ecommerce/priv/playbooks/my-search.json\n"), /my-search\.json/);
  // An untracked directory is listed as the directory itself.
  assert.throws(() => assertCleanTree("?? scrypath_ops/lib/new_feature/\n"), /new_feature\//);
  // A quoted path (spaces) is unquoted, and an untracked entry beside .planning ones still counts.
  assert.throws(() => assertCleanTree('?? ".planning/ok.md"\n?? "lib/with space.ex"\n'), /with space\.ex/);
});

test("clean-tree refusal accepts a status that only lists .planning paths, ignored files, or nothing", () => {
  assert.doesNotThrow(() => assertCleanTree(""));
  assert.doesNotThrow(() => assertCleanTree(" M .planning/UI-PREVIEW.json\n?? .planning/notes.md\n?? .planning/phases/187/new.md\n"));
  assert.doesNotThrow(() => assertCleanTree("!! node_modules/\n!! examples/scrypath_ecommerce/ui-review-artifacts/\n"));
});

test("the tree inspection reports cleanliness and the offending paths, and the manifest value comes from it", () => {
  assert.deepEqual(inspectTree(""), { clean: true, offending: [] });
  assert.deepEqual(inspectTree(" M .planning/STATE.md\n"), { clean: true, offending: [] });
  assert.deepEqual(inspectTree(" M lib/a.ex\n?? lib/b.ex\n"), { clean: false, offending: ["lib/a.ex", "lib/b.ex (untracked)"] });
  assert.deepEqual(assertCleanTree(" M .planning/STATE.md\n"), { clean: true, offending: [] });

  // The script no longer writes `clean: true` as a literal and no longer hides untracked files from
  // the check; the manifest value and the status read both come from the check itself.
  const source = readFileSync(SCRIPT, "utf8");
  assert.doesNotMatch(source, /clean:\s*true/);
  assert.doesNotMatch(source, /--untracked-files/);
  assert.match(source, /clean:\s*tree\.clean/);
});

test("inventory check flags a nested directory as unexpected", () => {
  const dir = makeCaptureDir();
  mkdirSync(path.join(dir, "nested"), { recursive: true });
  assert.ok(checkInventory(dir).errors.some((error) => error.includes("nested")));
});

// ── Provenance of the stack that rendered the images (WR-02) ─────────────────────────────────

const HEAD_SHA = "a".repeat(64);
const OTHER_SHA = "b".repeat(64);

test("the ops stylesheet link is found among a host's own links, preferring the mounted one", () => {
  const html = `<html><head>
    <link rel="stylesheet" href="/assets/css/app.css?vsn=d">
    <link rel="icon" href="/favicon.svg">
    <link rel="stylesheet" href="/admin/search/assets/css/app.css?v=abc&amp;x=1" />
  </head></html>`;
  assert.equal(findOpsStylesheetHref(html, "/admin/search"), "/admin/search/assets/css/app.css?v=abc&x=1");
  // Without a mounted link the single candidate is used.
  assert.equal(findOpsStylesheetHref('<link rel="stylesheet" href="/ops/assets/css/app.css">', "/admin/search"), "/ops/assets/css/app.css");
  // Attribute order and quote style do not matter.
  assert.equal(findOpsStylesheetHref("<link href='/admin/search/assets/css/app.css' rel='stylesheet'>", "/admin/search"), "/admin/search/assets/css/app.css");
});

test("the ops stylesheet link is refused when it is missing or ambiguous", () => {
  assert.throws(() => findOpsStylesheetHref("<html><head></head></html>"), /exactly one ops stylesheet link.*found 0/);
  assert.throws(() => findOpsStylesheetHref('<link rel="icon" href="/admin/search/assets/css/app.css">'), /found 0/);
  assert.throws(
    () => findOpsStylesheetHref('<link rel="stylesheet" href="/admin/search/assets/css/app.css?v=1"><link rel="stylesheet" href="/admin/search/assets/css/app.css?v=2">'),
    /found 2/,
  );
  assert.throws(() => findOpsStylesheetHref('<link rel="stylesheet" href="/other.css">'), /found 0/);
});

test("a served stylesheet that equals HEAD passes; one that differs is refused unless the flag is passed", () => {
  assert.deepEqual(assessStylesheet({ servedSha256: HEAD_SHA, headSha256: HEAD_SHA }), { matches: true, allowStale: false });
  assert.deepEqual(assessStylesheet({ servedSha256: HEAD_SHA, headSha256: HEAD_SHA, allowStale: true }), { matches: true, allowStale: true });
  assert.throws(
    () => assessStylesheet({ servedSha256: OTHER_SHA, headSha256: HEAD_SHA }),
    (error) => error.message.includes(OTHER_SHA) && error.message.includes(HEAD_SHA) && error.message.includes("--allow-stale-source"),
  );
  assert.deepEqual(assessStylesheet({ servedSha256: OTHER_SHA, headSha256: HEAD_SHA, allowStale: true }), { matches: false, allowStale: true });
});

test("--allow-stale-source is an explicit flag that defaults to off", () => {
  assert.equal(parseArgs(["--label", "before", "--base-url", "http://127.0.0.1:1/", "--out", "x"]).allowStaleSource, false);
  const args = parseArgs(["--label", "after", "--base-url", "http://127.0.0.1:1/", "--out", "x", "--allow-stale-source"]);
  assert.equal(args.allowStaleSource, true);
  assert.equal(args.baseUrl, "http://127.0.0.1:1");
  assert.throws(() => parseArgs(["--allow-stale"]), /unknown argument --allow-stale/);
});

/** A loopback stand-in for the demo: `/admin/search` links a stylesheet whose bytes the caller chooses. */
async function withStack(css, run, { sheetStatus = 200, linkHref = "/admin/search/assets/css/app.css?v=stand-in" } = {}) {
  const server = createServer((request, response) => {
    if (request.url === "/admin/search") {
      response.writeHead(200, { "content-type": "text/html" });
      response.end(`<html><head><link rel="stylesheet" href="${linkHref}"></head><body></body></html>`);
    } else if (request.url.startsWith("/admin/search/assets/css/app.css")) {
      response.writeHead(sheetStatus, { "content-type": "text/css" });
      response.end(css);
    } else {
      response.writeHead(404);
      response.end();
    }
  });
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  try {
    return await run(`http://127.0.0.1:${server.address().port}`);
  } finally {
    await new Promise((resolve) => {
      server.close(() => resolve());
      server.closeAllConnections();
    });
  }
}

test("the served stylesheet is fetched from the page's own link and hashed", async () => {
  const css = ":root{--color-primary:#7b2d6b}\n";
  const served = await withStack(css, (baseUrl) => fetchServedStylesheet(baseUrl));
  assert.equal(served.sha256, sha256(Buffer.from(css)));
  assert.equal(served.url, "/admin/search/assets/css/app.css?v=stand-in");
});

test("a stack serving different bytes than HEAD is refused, and the flag lets it through with the match recorded as false", async () => {
  const headCss = ":root{--color-primary:#7b2d6b}\n";
  const staleCss = ":root{--color-primary:#d58bc4}\n";
  await withStack(staleCss, async (baseUrl) => {
    const served = await fetchServedStylesheet(baseUrl);
    const headSha256 = sha256(Buffer.from(headCss));
    assert.throws(() => assessStylesheet({ servedSha256: served.sha256, headSha256 }), /serves a different ops stylesheet than HEAD/);
    assert.deepEqual(assessStylesheet({ servedSha256: served.sha256, headSha256, allowStale: true }), { matches: false, allowStale: true });
  });
  await withStack(headCss, async (baseUrl) => {
    const served = await fetchServedStylesheet(baseUrl);
    assert.equal(assessStylesheet({ servedSha256: served.sha256, headSha256: sha256(Buffer.from(headCss)) }).matches, true);
  });
});

test("an unreachable page, a missing stylesheet and a page with no ops link each fail with a reason", async () => {
  await assert.rejects(() => fetchServedStylesheet("http://127.0.0.1:1"), /could not read http:\/\/127\.0\.0\.1:1\/admin\/search/);
  await assert.rejects(() => withStack("x", (baseUrl) => fetchServedStylesheet(baseUrl), { sheetStatus: 404 }), /returned HTTP 404/);
  await assert.rejects(() => withStack("x", (baseUrl) => fetchServedStylesheet(baseUrl), { linkHref: "/somewhere/else.css" }), /found 0/);
});

test("HEAD's stylesheet is read from git, not from the working tree", () => {
  assert.match(headStylesheetSha256(), /^[0-9a-f]{64}$/);
  assert.equal(OPS_STYLESHEET_PATH, "scrypath_ops/priv/static/assets/css/app.css");
  // The capture compares served bytes with `git show HEAD:<path>`; a working-tree read would let an
  // uncommitted CSS edit pass for HEAD.
  assert.match(readFileSync(SCRIPT, "utf8"), /"show", `HEAD:\$\{OPS_STYLESHEET_PATH\}`/);
});

/** A capture directory whose manifest carries the given provenance fields. */
function makeProvenanceDir(fields) {
  const dir = makeCaptureDir();
  const manifestPath = path.join(dir, MANIFEST_NAME);
  const manifest = { ...JSON.parse(readFileSync(manifestPath, "utf8")), ...fields };
  writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
  return dir;
}

test("--check accepts a manifest from before the stylesheet check and one that records a matching or allowed-stale stack", () => {
  assert.equal(checkInventory(makeCaptureDir()).ok, true);
  const matching = { served_css_sha256: HEAD_SHA, head_css_sha256: HEAD_SHA, served_css_matches_head: true, allow_stale_source: false };
  assert.deepEqual(checkInventory(makeProvenanceDir(matching)).errors, []);
  const allowed = { served_css_sha256: OTHER_SHA, head_css_sha256: HEAD_SHA, served_css_matches_head: false, allow_stale_source: true };
  assert.deepEqual(checkInventory(makeProvenanceDir(allowed)).errors, []);
});

test("--check fails a manifest that claims a dirty tree, an unflagged mismatch, or a match its hashes contradict", () => {
  const dirty = checkInventory(makeProvenanceDir({ clean: false }));
  assert.equal(dirty.ok, false);
  assert.ok(dirty.errors.some((error) => error.includes("dirty tree")), dirty.errors.join("\n"));

  const unflagged = checkInventory(
    makeProvenanceDir({ served_css_sha256: OTHER_SHA, head_css_sha256: HEAD_SHA, served_css_matches_head: false, allow_stale_source: false }),
  );
  assert.ok(unflagged.errors.some((error) => error.includes("without allow_stale_source")), unflagged.errors.join("\n"));

  const lying = checkInventory(
    makeProvenanceDir({ served_css_sha256: OTHER_SHA, head_css_sha256: HEAD_SHA, served_css_matches_head: true, allow_stale_source: false }),
  );
  assert.ok(lying.errors.some((error) => error.includes("its two hashes say false")), lying.errors.join("\n"));

  const half = checkInventory(makeProvenanceDir({ served_css_sha256: HEAD_SHA }));
  assert.ok(half.errors.some((error) => error.includes("without both")), half.errors.join("\n"));
});

test("provenance fields are written into the manifest from the checks, not constants", () => {
  const source = readFileSync(SCRIPT, "utf8");
  for (const field of ["served_css_url", "served_css_sha256", "head_css_path", "head_css_sha256", "served_css_matches_head", "allow_stale_source"]) {
    assert.match(source, new RegExp(`${field}:`), `${field} is part of the manifest`);
  }
  assert.match(source, /served_css_matches_head:\s*stylesheet\.matches/);
  assert.match(source, /allow_stale_source:\s*stylesheet\.allowStale/);
  // The stylesheet is checked before any capture state is created.
  assert.ok(source.indexOf("assessStylesheet({") < source.indexOf("const scratch ="), "the check runs before the scratch directory exists");
  assert.deepEqual(checkProvenance({ clean: true }), []);
});
