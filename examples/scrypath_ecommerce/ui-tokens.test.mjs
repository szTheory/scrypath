// Token parity guard for the ScrypathOps theme blocks (Phase 186, TOK-01).
//
// What it proves, in plain terms:
//   - every property in the two daisyUI theme blocks has exactly one row in
//     scrypath_ops/assets/css/token-map.json, and every row names a live property
//   - a row marked applied resolves to the pinned brand hex; a pending row does not
//     (a stale claim in either direction fails), and the pending count only shrinks
//   - the three theme emissions in the tracked built CSS hold the same token values
//     as the source blocks (token level, not byte level: a fresh Tailwind build is
//     not byte-identical to the tracked file today)
//   - theme-block hex values outside the brand tokens and the declared derive or
//     local targets only shrink
//
// It verifies, it never generates: the map is hand-maintained data.
//
// Gate budget (v1.46): this is gate 2 (token parity plus the retired-identity
// deny-list, one mechanism). Deletion trigger: ScrypathOps stops carrying its own
// theme blocks, or the theme blocks are generated from brand/tokens.json. Expected
// churn per UI PR: one token-map row flip per adopted property, and a lower ceiling.
// It runs through the ExUnit wrapper in test/mix/tasks/ui_contrast_contract_test.exs,
// so it rides the existing core and repository-contracts jobs with no new CI step.
//
// Raising a ceiling below is a visible source edit; that is the second key.

import { test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { readThemeProperties } from "./contrast-checker.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, "../..");
const APP_CSS = path.join(ROOT, "scrypath_ops/assets/css/app.css");
const BUILT_CSS = path.join(ROOT, "scrypath_ops/priv/static/assets/css/app.css");
const TOKEN_MAP = path.join(ROOT, "scrypath_ops/assets/css/token-map.json");
const BRAND_TOKENS = path.join(ROOT, "brand/tokens.json");

// Shrink-only ceilings. Phase 187 lowers them as rows flip to applied and the
// retired properties are deleted.
const PENDING_CEILING = 38;
const HEX_OUTSIDE_CEILING = 34;

const MODES = ["light", "dark"];
const DISPOSITIONS = new Set(["adopt", "derive", "keep-platform", "retire", "local"]);
const NEEDS_REASON = new Set(["derive", "keep-platform", "retire", "local"]);
const HEX = /^#[0-9a-f]{6}$/i;
const TOKEN_KEY = /^(color|ops)-/;

// ---------------------------------------------------------------------------
// Data readers and small helpers
// ---------------------------------------------------------------------------

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function lower(value) {
  return String(value).trim().toLowerCase();
}

function normalizeValue(value) {
  return String(value).trim().replace(/\s+/g, " ").toLowerCase();
}

/** Resolve a dotted brand token path such as color.light.panel to its $value.hex. */
function resolveBrandHex(brandTokens, tokenPath) {
  if (typeof tokenPath !== "string" || tokenPath === "") {
    throw new Error(`Unknown brand token path: ${String(tokenPath)}`);
  }
  let node = brandTokens;
  for (const segment of tokenPath.split(".")) {
    if (node === null || typeof node !== "object" || !Object.hasOwn(node, segment)) {
      throw new Error(`Unknown brand token path: ${tokenPath}`);
    }
    node = node[segment];
  }
  const hex = node?.$value?.hex;
  if (typeof hex !== "string" || !HEX.test(hex)) {
    throw new Error(`Brand token ${tokenPath} has no $value.hex`);
  }
  return hex;
}

/** Every $value.hex in the brand tokens, lowercased. */
function brandHexes(brandTokens) {
  const found = new Set();
  const walk = (node) => {
    if (node === null || typeof node !== "object") return;
    const hex = node.$value?.hex;
    if (typeof hex === "string" && HEX.test(hex)) found.add(lower(hex));
    for (const [key, child] of Object.entries(node)) {
      if (!key.startsWith("$")) walk(child);
    }
  };
  walk(brandTokens);
  return found;
}

function mapCells(map) {
  const cells = [];
  for (const row of map.rows ?? []) {
    for (const mode of MODES) {
      if (row[mode]) cells.push({ row, mode, cell: row[mode] });
    }
  }
  return cells;
}

/** Derive and local targets: values the brand tokens do not carry but the map declares. */
function declaredTargets(map) {
  const targets = new Set();
  for (const { cell } of mapCells(map)) {
    if ((cell.disposition === "derive" || cell.disposition === "local") && HEX.test(cell.target ?? "")) {
      targets.add(lower(cell.target));
    }
  }
  return targets;
}

/** The new-identity set: brand token hexes plus declared derive and local targets. */
function allowedHexSet(map, brandTokens) {
  return new Set([...brandHexes(brandTokens), ...declaredTargets(map)]);
}

function countPending(map) {
  return mapCells(map).filter(({ cell }) => cell.applied === false).length;
}

function loadLive() {
  const css = fs.readFileSync(APP_CSS, "utf8");
  return {
    themes: readThemeProperties(css),
    map: readJson(TOKEN_MAP),
    brandTokens: readJson(BRAND_TOKENS),
    builtCss: fs.readFileSync(BUILT_CSS, "utf8"),
  };
}

// ---------------------------------------------------------------------------
// Built CSS emission reader (token level)
// ---------------------------------------------------------------------------

/**
 * A small brace-aware CSS block tree. Comments are dropped, strings are kept
 * whole, and braces or semicolons inside parentheses (url(data:...)) are data.
 */
function parseCssBlocks(css) {
  const root = { head: "", decls: [], children: [], parent: null, bodyStart: 0, bodyEnd: css.length };
  let node = root;
  let buffer = "";
  let parens = 0;
  let i = 0;
  const flush = () => {
    const text = buffer.trim();
    if (text) node.decls.push(text);
    buffer = "";
  };
  while (i < css.length) {
    const c = css[i];
    if (c === "/" && css[i + 1] === "*") {
      const end = css.indexOf("*/", i + 2);
      i = end === -1 ? css.length : end + 2;
      continue;
    }
    if (c === '"' || c === "'") {
      let j = i + 1;
      while (j < css.length && css[j] !== c) {
        if (css[j] === "\\") j += 1;
        j += 1;
      }
      buffer += css.slice(i, j + 1);
      i = j + 1;
      continue;
    }
    if (c === "(") {
      parens += 1;
    } else if (c === ")") {
      parens = Math.max(0, parens - 1);
    } else if (parens === 0 && c === "{") {
      const child = { head: buffer.trim(), decls: [], children: [], parent: node, bodyStart: i + 1, bodyEnd: -1 };
      node.children.push(child);
      node = child;
      buffer = "";
      i += 1;
      continue;
    } else if (parens === 0 && c === ";") {
      flush();
      i += 1;
      continue;
    } else if (parens === 0 && c === "}") {
      flush();
      node.bodyEnd = i;
      node = node.parent ?? node;
      i += 1;
      continue;
    }
    buffer += c;
    i += 1;
  }
  return root;
}

function declarationMap(decls) {
  const props = {};
  for (const text of decls) {
    const entry = /^(--[\w-]+)\s*:\s*([\s\S]+)$/.exec(text);
    if (entry) props[entry[1].slice(2)] = entry[2].trim();
  }
  return props;
}

function collectEmissions(node, ancestors, out) {
  const props = declarationMap(node.decls);
  if (Object.hasOwn(props, "color-base-100")) {
    const supports = {};
    for (const child of node.children) {
      if (/^@supports\b/.test(child.head)) Object.assign(supports, declarationMap(child.decls));
    }
    out.push({ head: node.head, ancestors, props, supports, bodyStart: node.bodyStart, bodyEnd: node.bodyEnd });
  }
  for (const child of node.children) collectEmissions(child, [...ancestors, node.head], out);
}

const EMISSIONS = [
  { label: "system-dark", mode: "dark" },
  { label: "explicit dark", mode: "dark" },
  { label: "light", mode: "light" },
];

function selectsEmission(label, emission) {
  const selectors = emission.head.split(",").map((s) => s.trim());
  if (label === "system-dark") {
    return emission.head === ":root" && emission.ancestors.some((h) => /^@media \(prefers-color-scheme: dark\)$/.test(h));
  }
  if (label === "explicit dark") return selectors.includes('[data-theme="dark"]');
  return selectors.includes('[data-theme="light"]');
}

/**
 * Read the three theme emissions out of the built CSS: the system-dark :root
 * inside the dark media query, the explicit dark selector, and the light selector.
 * The nested @supports re-declaration is kept apart in `supports`.
 */
function readBuiltEmissions(builtCss) {
  const found = [];
  collectEmissions(parseCssBlocks(builtCss), [], found);
  const byLabel = {};
  for (const { label } of EMISSIONS) {
    const matches = found.filter((emission) => selectsEmission(label, emission));
    if (matches.length !== 1) {
      throw new Error(`built CSS has ${matches.length} ${label} theme emissions, expected 1`);
    }
    byLabel[label] = matches[0];
  }
  return byLabel;
}

// ---------------------------------------------------------------------------
// Pure checks: each takes parsed inputs and returns a list of failure strings
// ---------------------------------------------------------------------------

function checkParity(themes, map) {
  const failures = [];
  if (map.schema !== "scrypath.token-map.v1") failures.push(`token map schema is ${String(map.schema)}`);
  if (!Array.isArray(map.rows)) return [...failures, "token map has no rows list"];

  const lightKeys = new Set(Object.keys(themes.light).map((key) => `--${key}`));
  const darkKeys = new Set(Object.keys(themes.dark).map((key) => `--${key}`));
  const live = new Set([...lightKeys, ...darkKeys]);

  for (const property of live) {
    if (!lightKeys.has(property)) failures.push(`${property} is declared in the dark theme only`);
    if (!darkKeys.has(property)) failures.push(`${property} is declared in the light theme only`);
  }

  const seen = new Set();
  for (const row of map.rows) {
    if (seen.has(row.property)) failures.push(`duplicate token row for ${row.property}`);
    seen.add(row.property);
    if (!live.has(row.property)) failures.push(`orphan token row ${row.property} names no live property`);
  }
  for (const property of live) {
    if (!seen.has(property)) failures.push(`missing token row for ${property}`);
  }
  return failures;
}

function checkApplied(themes, map, brandTokens) {
  const failures = [];
  for (const row of map.rows ?? []) {
    const key = String(row.property).replace(/^--/, "");
    for (const mode of MODES) {
      const where = `${row.property} (${mode})`;
      const cell = row[mode];
      if (!cell || typeof cell !== "object") {
        failures.push(`${where}: row has no ${mode} cell`);
        continue;
      }
      if (!DISPOSITIONS.has(cell.disposition)) {
        failures.push(`${where}: unknown disposition ${String(cell.disposition)}`);
        continue;
      }
      if (typeof cell.applied !== "boolean") failures.push(`${where}: applied must be true or false`);
      if (NEEDS_REASON.has(cell.disposition) && !(typeof cell.reason === "string" && cell.reason.trim())) {
        failures.push(`${where}: ${cell.disposition} rows need a reason`);
      }
      const liveValue = themes[mode]?.[key];
      if (liveValue === undefined) continue; // parity reports the missing property

      if (cell.disposition === "retire") {
        if (cell.applied !== false) failures.push(`${where}: retire row marked applied while the property is still declared`);
        continue;
      }
      if (cell.disposition === "keep-platform") {
        if (typeof cell.value !== "string") {
          failures.push(`${where}: keep-platform rows need a value`);
        } else if (liveValue !== cell.value) {
          failures.push(`${where}: keep-platform value ${cell.value} differs from CSS ${liveValue}`);
        }
        if (cell.applied !== true) failures.push(`${where}: keep-platform rows are always applied`);
        continue;
      }

      let expected;
      if (cell.disposition === "adopt") {
        try {
          expected = resolveBrandHex(brandTokens, cell.source);
        } catch (error) {
          failures.push(`${where}: ${error.message}`);
          continue;
        }
      } else if (HEX.test(cell.target ?? "") && lower(cell.target) === cell.target) {
        expected = cell.target;
      } else {
        failures.push(`${where}: ${cell.disposition} rows need a lowercase #rrggbb target`);
        continue;
      }
      const equal = lower(liveValue) === lower(expected);
      if (cell.applied === true && !equal) {
        failures.push(`resolved-hex mismatch: ${where} is marked applied but CSS has ${liveValue}, expected ${expected}`);
      }
      if (cell.applied === false && equal) {
        failures.push(`stale pending claim: ${where} already equals ${expected} but is marked pending`);
      }
    }
  }
  const pending = countPending(map);
  if (pending > PENDING_CEILING) {
    failures.push(`pending count ${pending} exceeds PENDING_CEILING ${PENDING_CEILING} (shrink-only)`);
  }
  return failures;
}

function mutedFallbackOk(expected, emission) {
  // The source declares an alpha mix; the build emits a plain fallback plus a
  // nested @supports re-declaration of the same mix.
  return (
    normalizeValue(emission.props["ops-text-muted"] ?? "") === "var(--color-base-content)" &&
    normalizeValue(emission.supports["ops-text-muted"] ?? "") === normalizeValue(expected)
  );
}

function checkBuiltEmissions(themes, builtCss) {
  let emissions;
  try {
    emissions = readBuiltEmissions(builtCss);
  } catch (error) {
    return [error.message];
  }
  const failures = [];
  for (const { label, mode } of EMISSIONS) {
    const emission = emissions[label];
    const source = themes[mode];
    const sourceKeys = Object.keys(source).filter((key) => TOKEN_KEY.test(key));
    for (const key of sourceKeys) {
      const expected = source[key];
      const built = emission.props[key];
      const muteMix = key === "ops-text-muted" && /^color-mix\(/i.test(expected);
      const ok = muteMix ? mutedFallbackOk(expected, emission) : built !== undefined && normalizeValue(built) === normalizeValue(expected);
      if (!ok) {
        failures.push(`stale built CSS: ${label} emission --${key} is ${String(built)}, source ${mode} block has ${expected}`);
      }
    }
    for (const key of Object.keys(emission.props)) {
      if (TOKEN_KEY.test(key) && !sourceKeys.includes(key)) {
        failures.push(`stale built CSS: ${label} emission declares --${key}, the source ${mode} block does not`);
      }
    }
  }
  return failures;
}

function checkHexAllowlist(themes, map, brandTokens) {
  const failures = [];
  const allowed = allowedHexSet(map, brandTokens);
  for (const { row, mode, cell } of mapCells(map)) {
    if (cell.applied !== true || cell.disposition === "keep-platform") continue;
    const value = themes[mode]?.[String(row.property).replace(/^--/, "")];
    if (typeof value === "string" && HEX.test(value) && !allowed.has(lower(value))) {
      failures.push(`applied ${row.property} (${mode}) holds ${value}, which is not a brand token or declared target`);
    }
  }
  let outside = 0;
  for (const mode of MODES) {
    for (const value of Object.values(themes[mode])) {
      if (HEX.test(value) && !allowed.has(lower(value))) outside += 1;
    }
  }
  if (outside > HEX_OUTSIDE_CEILING) {
    failures.push(`theme-block hex values outside the brand set: ${outside} exceeds HEX_OUTSIDE_CEILING ${HEX_OUTSIDE_CEILING} (shrink-only)`);
  }
  return failures;
}

// ---------------------------------------------------------------------------
// Live tests
// ---------------------------------------------------------------------------

test("live token map parity both directions", () => {
  const { themes, map } = loadLive();
  assert.deepEqual(checkParity(themes, map), []);
  assert.equal(map.rows.length, Object.keys(themes.light).length);
});

test("live applied rows equal pinned brand hex and pending rows differ", () => {
  const { themes, map, brandTokens } = loadLive();
  assert.deepEqual(checkApplied(themes, map, brandTokens), []);
  console.log(`token map pending cells: ${countPending(map)} of ${mapCells(map).length}`);
});

test("live built CSS emissions equal source theme blocks", () => {
  const { themes, builtCss } = loadLive();
  assert.deepEqual(checkBuiltEmissions(themes, builtCss), []);
});

test("live hex allowlist holds", () => {
  const { themes, map, brandTokens } = loadLive();
  assert.deepEqual(checkHexAllowlist(themes, map, brandTokens), []);
});

test("brand token paths resolve and unknown paths throw", () => {
  const { brandTokens } = loadLive();
  assert.match(resolveBrandHex(brandTokens, "color.light.panel"), HEX);
  assert.throws(() => resolveBrandHex(brandTokens, "color.light.no-such-token"), /Unknown brand token path/);
  assert.throws(() => resolveBrandHex(brandTokens, "color.light"), /no \$value\.hex/);
});

// ---------------------------------------------------------------------------
// Planted failures and the accept case (in-memory copies, nothing on disk)
// ---------------------------------------------------------------------------

function fixtures() {
  return structuredClone(loadLive());
}

function rowFor(map, property) {
  const row = map.rows.find((candidate) => candidate.property === property);
  assert.ok(row, `fixture row ${property} exists`);
  return row;
}

function anyFailure(failures, pattern) {
  return failures.some((failure) => pattern.test(failure));
}

/** Replace one declaration inside one emission's own body (not its nested @supports). */
function plantEmissionValue(builtCss, label, key, value) {
  const emission = readBuiltEmissions(builtCss)[label];
  const body = builtCss.slice(emission.bodyStart, emission.bodyEnd);
  const pattern = new RegExp(`(--${key}:\\s*)[^;]+;`);
  assert.match(body, pattern, `${label} emission declares --${key}`);
  const changed = body.replace(pattern, `$1${value};`);
  assert.notEqual(changed, body);
  return builtCss.slice(0, emission.bodyStart) + changed + builtCss.slice(emission.bodyEnd);
}

test("planted missing token row fails", () => {
  const { themes, map } = fixtures();
  map.rows = map.rows.filter((row) => row.property !== "--color-base-100");
  assert.ok(anyFailure(checkParity(themes, map), /missing token row for --color-base-100/));
});

test("planted orphan row fails", () => {
  const { themes, map } = fixtures();
  const template = rowFor(map, "--color-base-100");
  map.rows.push({ ...structuredClone(template), property: "--color-not-a-live-property" });
  assert.ok(anyFailure(checkParity(themes, map), /orphan token row --color-not-a-live-property/));
});

test("planted resolved-hex mismatch fails", () => {
  // A pending row claimed as applied.
  const claimed = fixtures();
  rowFor(claimed.map, "--color-primary").light.applied = true;
  assert.ok(anyFailure(checkApplied(claimed.themes, claimed.map, claimed.brandTokens), /resolved-hex mismatch: --color-primary \(light\)/));

  // A brand token hex changed under an applied row.
  const drifted = fixtures();
  assert.equal(rowFor(drifted.map, "--color-base-100").light.applied, true, "fixture row starts applied");
  drifted.brandTokens.color.light.panel.$value.hex = "#FFFFFE";
  assert.ok(anyFailure(checkApplied(drifted.themes, drifted.map, drifted.brandTokens), /resolved-hex mismatch: --color-base-100 \(light\)/));
});

test("planted stale pending claim fails", () => {
  // The CSS already equals the pinned brand hex but the row still says pending.
  const { themes, map, brandTokens } = fixtures();
  const cell = rowFor(map, "--color-base-100").light;
  assert.equal(cell.applied, true, "fixture row starts applied");
  cell.applied = false;
  assert.ok(anyFailure(checkApplied(themes, map, brandTokens), /stale pending claim: --color-base-100 \(light\)/));
});

test("planted stale built CSS fails", () => {
  const { themes, builtCss } = fixtures();
  for (const { label } of EMISSIONS) {
    const stale = plantEmissionValue(builtCss, label, "color-primary", "#010203");
    assert.ok(
      anyFailure(checkBuiltEmissions(themes, stale), new RegExp(`stale built CSS: ${label} emission --color-primary`)),
      `${label} emission change is caught`,
    );
  }
  // The nested @supports re-declaration of the muted mix is part of the emission.
  const emission = readBuiltEmissions(builtCss)["system-dark"];
  assert.ok(emission.supports["ops-text-muted"], "fixture emission has a @supports muted re-declaration");
  const body = builtCss.slice(emission.bodyStart, emission.bodyEnd);
  const changed = body.replace(emission.supports["ops-text-muted"], "#010203");
  assert.notEqual(changed, body);
  const drifted = builtCss.slice(0, emission.bodyStart) + changed + builtCss.slice(emission.bodyEnd);
  assert.ok(anyFailure(checkBuiltEmissions(themes, drifted), /stale built CSS: system-dark emission --ops-text-muted/));
});

test("valid fixtures pass", () => {
  const { themes, map, brandTokens, builtCss } = fixtures();
  assert.deepEqual(checkParity(themes, map), []);
  assert.deepEqual(checkApplied(themes, map, brandTokens), []);
  assert.deepEqual(checkBuiltEmissions(themes, builtCss), []);
  assert.deepEqual(checkHexAllowlist(themes, map, brandTokens), []);
});
