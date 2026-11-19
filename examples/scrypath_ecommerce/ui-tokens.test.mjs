// Token parity and retired-identity guard (Phase 186, TOK-01 and TOK-02).
//
// Part 1, token parity for the ScrypathOps theme blocks. What it proves, in plain terms:
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
// Part 2, the retired-identity deny-list. One scan of `git ls-files` (tracked plus
// untracked-but-not-ignored, so an uncommitted reintroduction is caught too) for
// hex values (hash, percent-encoded, 0x and quoted bare forms), rgb or rgba
// triplets (integer, decimal or percent channels), color(srgb ...) and the retired
// brand directory string of the old identity. UTF-16 files are decoded, never
// skipped; a text file with an unreadable encoding fails the scan. A shrink-only
// allowlist with phase tags covers the files that still hold old values. It is
// path-level, but each entry also carries max_hits, the number of retired-value
// occurrences in the files it covers: more than that fails (a listed file cannot
// gain a retired value), fewer fails until the ceiling is lowered, and a test-owned
// HITS_CEILING must equal the sum, so any change to the counts is a two-file edit.
// Prefix entries (whole directories) must be retire-last. A stale or missing entry
// fails. Planted failures and the accept cases run through the same scan on a temp
// git tree. The guard never contains a retired value: the deny set is stored
// without its leading hash and the directory string is joined at runtime.
//
// Gate budget (v1.46): this is gate 2 (token parity plus the retired-identity
// deny-list, one mechanism). Deletion trigger: ScrypathOps stops carrying its own
// theme blocks, or the theme blocks are generated from brand/tokens.json. Expected
// churn per UI PR: one token-map row flip per adopted property, and a lower ceiling.
// It runs through the ExUnit wrapper in test/mix/tasks/ui_contrast_contract_test.exs,
// so it rides the existing core and repository-contracts jobs with no new CI step.
//
// Raising a ceiling below, or an entry's max_hits together with HITS_CEILING, is a visible
// source edit; that is the second key.

import { test, after } from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { readThemeProperties } from "./contrast-checker.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, "../..");
const APP_CSS = path.join(ROOT, "scrypath_ops/assets/css/app.css");
const BUILT_CSS = path.join(ROOT, "scrypath_ops/priv/static/assets/css/app.css");
const TOKEN_MAP = path.join(ROOT, "scrypath_ops/assets/css/token-map.json");
const BRAND_TOKENS = path.join(ROOT, "brand/tokens.json");

// Exact ceilings. Each one fails when the live count is above it (growth) and when the live
// count is below it (the ceiling must be lowered, with the printed number), so none can keep
// unused room. Phase 187 lowers them as rows flip to applied and the retired properties are
// deleted.
const PENDING_CEILING = 2;
const HEX_OUTSIDE_CEILING = 0;
// Allowlist entries (paths and prefixes). A new entry means a new retired value landed in a
// new file, which is the thing this guard exists to stop.
// Growth inside a listed file is stopped by each entry's max_hits (see HITS_CEILING).
const ALLOWLIST_CEILING = 15;
// The sum of every entry's max_hits in the allowlist file. Each entry's max_hits must equal
// the live count, so a retired value added to a listed file needs a max_hits edit there and
// this edit here: the second key. A drop in hits needs both edits too.
const HITS_CEILING = 252;
// The checks take these as a parameter so the planted and accept cases can use
// their own limits and never depend on how far the live ceilings have shrunk.
const LIMITS = { pending: PENDING_CEILING, hexOutside: HEX_OUTSIDE_CEILING, allowlist: ALLOWLIST_CEILING, hits: HITS_CEILING };
const NO_LIMITS = { pending: Infinity, hexOutside: Infinity, allowlist: Infinity, hits: Infinity };

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

function checkApplied(themes, map, brandTokens, limits = LIMITS) {
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
  if (pending > limits.pending) {
    failures.push(`pending count ${pending} exceeds PENDING_CEILING ${limits.pending} (shrink-only)`);
  } else if (Number.isFinite(limits.pending) && pending < limits.pending) {
    failures.push(`PENDING_CEILING is ${limits.pending} but only ${pending} cells are pending: lower it to ${pending}`);
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

/** Theme-block hex values that are neither a brand token nor a declared derive or local target. */
function countHexOutside(themes, map, brandTokens) {
  const allowed = allowedHexSet(map, brandTokens);
  let outside = 0;
  for (const mode of MODES) {
    for (const value of Object.values(themes[mode])) {
      if (HEX.test(value) && !allowed.has(lower(value))) outside += 1;
    }
  }
  return outside;
}

function checkHexAllowlist(themes, map, brandTokens, limits = LIMITS) {
  const failures = [];
  const allowed = allowedHexSet(map, brandTokens);
  for (const { row, mode, cell } of mapCells(map)) {
    if (cell.applied !== true || cell.disposition === "keep-platform") continue;
    const value = themes[mode]?.[String(row.property).replace(/^--/, "")];
    if (typeof value === "string" && HEX.test(value) && !allowed.has(lower(value))) {
      failures.push(`applied ${row.property} (${mode}) holds ${value}, which is not a brand token or declared target`);
    }
  }
  const outside = countHexOutside(themes, map, brandTokens);
  if (outside > limits.hexOutside) {
    failures.push(`theme-block hex values outside the brand set: ${outside} exceeds HEX_OUTSIDE_CEILING ${limits.hexOutside} (shrink-only)`);
  } else if (Number.isFinite(limits.hexOutside) && outside < limits.hexOutside) {
    failures.push(`HEX_OUTSIDE_CEILING is ${limits.hexOutside} but only ${outside} theme-block hex values sit outside the brand set: lower it to ${outside}`);
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
// Planted failures and the accept case (in-memory, nothing on disk)
//
// The fixtures are small synthetic ones, not copies of the live files: a planted or
// accept case must keep meaning the same thing whatever state the live theme blocks,
// the token map and the built CSS are in. Phase 187 flips rows, recolors the blocks
// and rebuilds the CSS; none of that may fail a planted case for a wrong reason.
// ---------------------------------------------------------------------------

const MUTED_MIX = "color-mix(in oklch, var(--color-base-content) 64%, transparent)";
const brandToken = (hex) => ({ $type: "color", $value: { colorSpace: "srgb", hex } });

function syntheticTheme(base100, base200, primary, selection) {
  return {
    "color-base-100": base100,
    "color-base-200": base200,
    "color-primary": primary,
    "color-primary-strong": primary,
    "color-info": "#334455",
    "ops-selection": selection,
    "ops-text-muted": MUTED_MIX,
    "radius-box": "0.5rem",
  };
}

function syntheticBuiltCss(themes) {
  const declare = (mode, indent) =>
    Object.entries(themes[mode])
      .map(([key, value]) =>
        key === "ops-text-muted"
          ? [
              `${indent}--ops-text-muted: var(--color-base-content);`,
              `${indent}@supports (color: color-mix(in lab, red, red)) {`,
              `${indent}  --ops-text-muted: ${value};`,
              `${indent}}`,
            ].join("\n")
          : `${indent}--${key}: ${value};`,
      )
      .join("\n");
  return [
    "@layer base {",
    "  @media (prefers-color-scheme: dark) {",
    "    :root {",
    "      color-scheme: dark;",
    declare("dark", "      "),
    "    }",
    '    html:not([data-theme="light"]) .unrelated-rule { color: red; }',
    "  }",
    "}",
    "@layer base {",
    '  :root:has(input.theme-controller[value=dark]:checked),[data-theme="dark"] {',
    "    color-scheme: dark;",
    declare("dark", "    "),
    "  }",
    "}",
    "@layer base {",
    '  :where(:root),:root:has(input.theme-controller[value=light]:checked),[data-theme="light"] {',
    "    color-scheme: light;",
    declare("light", "    "),
    "  }",
    "}",
    "",
  ].join("\n");
}

function fixtures() {
  const themes = {
    light: syntheticTheme("#ffffff", "#fafafa", "#222222", "#eeeeee"),
    dark: syntheticTheme("#101010", "#080808", "#dddddd", "#202020"),
  };
  const brandTokens = {
    color: {
      light: { panel: brandToken("#FFFFFF"), page: brandToken("#FAFAFA"), plum: brandToken("#333333"), selected: brandToken("#EEEEEE"), muted: brandToken("#444444") },
      dark: { panel: brandToken("#101010"), night: brandToken("#080808"), orchid: brandToken("#EEEEEE"), muted: brandToken("#CCCCCC") },
    },
  };
  const adopt = (source, applied) => ({ disposition: "adopt", source, applied });
  const kept = (disposition, extra) => ({ disposition, reason: "fixture", ...extra });
  const row = (property, light, dark) => ({ property, light, dark });
  const map = {
    schema: "scrypath.token-map.v1",
    brand_tokens: "brand/tokens.json",
    rows: [
      row("--color-base-100", adopt("color.light.panel", true), adopt("color.dark.panel", true)),
      row("--color-base-200", adopt("color.light.page", true), adopt("color.dark.night", true)),
      // Pending: the live value differs from the brand token.
      row("--color-primary", adopt("color.light.plum", false), adopt("color.dark.orchid", false)),
      row("--color-primary-strong", kept("retire", { applied: false }), kept("retire", { applied: false })),
      row("--color-info", kept("local", { target: "#334455", applied: true }), kept("local", { target: "#334455", applied: true })),
      row("--ops-selection", adopt("color.light.selected", true), kept("derive", { target: "#202020", applied: true })),
      row("--ops-text-muted", adopt("color.light.muted", false), adopt("color.dark.muted", false)),
      row("--radius-box", kept("keep-platform", { value: "0.5rem", applied: true }), kept("keep-platform", { value: "0.5rem", applied: true })),
    ],
  };
  return { themes, map, brandTokens, builtCss: syntheticBuiltCss(themes) };
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

test("planted ceiling breaches fail", () => {
  // The shrink-only counters fail when the measured count exceeds the limit.
  const { themes, map, brandTokens } = fixtures();
  const pending = countPending(map);
  assert.ok(pending > 0, "fixture has pending cells");
  assert.deepEqual(checkApplied(themes, map, brandTokens, { ...NO_LIMITS, pending }), []);
  assert.ok(
    anyFailure(checkApplied(themes, map, brandTokens, { ...NO_LIMITS, pending: pending - 1 }), /pending count .* exceeds PENDING_CEILING/),
  );
  assert.ok(anyFailure(checkHexAllowlist(themes, map, brandTokens, { ...NO_LIMITS, hexOutside: 0 }), /exceeds HEX_OUTSIDE_CEILING 0/));
});

// 186 verification IN-06: only HITS_CEILING used to fail when the live count dropped below it. Every
// ceiling is exact now: a ceiling above the live count fails and prints the number to use.
test("planted ceiling above live count fails: pending cells", () => {
  const { themes, map, brandTokens } = fixtures();
  const pending = countPending(map);
  assert.deepEqual(checkApplied(themes, map, brandTokens, { ...NO_LIMITS, pending }), []);
  assert.ok(
    anyFailure(
      checkApplied(themes, map, brandTokens, { ...NO_LIMITS, pending: pending + 1 }),
      new RegExp(`PENDING_CEILING is ${pending + 1} but only ${pending} cells are pending: lower it to ${pending}`),
    ),
  );
});

test("planted ceiling above live count fails: hex values outside the brand set", () => {
  const { themes, map, brandTokens } = fixtures();
  const outside = countHexOutside(themes, map, brandTokens);
  assert.deepEqual(checkHexAllowlist(themes, map, brandTokens, { ...NO_LIMITS, hexOutside: outside }), []);
  assert.ok(
    anyFailure(
      checkHexAllowlist(themes, map, brandTokens, { ...NO_LIMITS, hexOutside: outside + 1 }),
      new RegExp(`HEX_OUTSIDE_CEILING is ${outside + 1} but only ${outside} theme-block hex values .*: lower it to ${outside}`),
    ),
  );
});

test("valid fixtures pass", () => {
  const { themes, map, brandTokens, builtCss } = fixtures();
  assert.deepEqual(checkParity(themes, map), []);
  assert.deepEqual(checkApplied(themes, map, brandTokens, NO_LIMITS), []);
  assert.deepEqual(checkBuiltEmissions(themes, builtCss), []);
  assert.deepEqual(checkHexAllowlist(themes, map, brandTokens, NO_LIMITS), []);
});

// ---------------------------------------------------------------------------
// Font URLs (Phase 187, SKIN-02; the font half of N-10)
//
// The built stylesheet declares four @font-face blocks, two of which load a file. Each file URL
// must be CSS-relative (`../fonts/<file>?v=<sha256>`, so it resolves against
// `<mount>/assets/css/app.css` at any mount prefix) and its `?v=` must equal the sha256 of the
// named file under scrypath_ops/priv/static/assets/fonts. AssetPlug sends the immutable cache
// header only when the two match, so a stale hash silently loses caching and a root-absolute
// URL breaks every host that is not mounted at the root.
// ---------------------------------------------------------------------------

const FONT_DIR = path.join(ROOT, "scrypath_ops/priv/static/assets/fonts");
const FONT_FACE_BLOCK = /@font-face\s*\{[^}]*\}/g;
const FONT_URL = /url\(\s*(["']?)([^"')]+)\1\s*\)/g;
const RELATIVE_FONT_URL = /^\.\.\/fonts\/([A-Za-z0-9._-]+)\?v=([0-9a-f]{64})$/;

function fontSha256(fileName) {
  return crypto.createHash("sha256").update(fs.readFileSync(path.join(FONT_DIR, fileName))).digest("hex");
}

/** Failures for the font URLs of a stylesheet. `sha256Of(fileName)` returns the file's hex sha256. */
function checkFontUrls(css, sha256Of) {
  const failures = [];
  const faces = css.match(FONT_FACE_BLOCK) ?? [];
  if (faces.length !== 4) {
    failures.push(`expected 4 @font-face blocks (two files and two local fallbacks), found ${faces.length}`);
  }
  const urls = faces.flatMap((face) => [...face.matchAll(FONT_URL)].map((match) => match[2]));
  if (urls.length !== 2) {
    failures.push(`expected 2 font file URLs (one per brand family), found ${urls.length}`);
  }
  for (const url of urls) {
    const parsed = RELATIVE_FONT_URL.exec(url);
    if (!parsed) {
      failures.push(`font URL ${url} must look like ../fonts/<file>?v=<64 hex>: relative to the stylesheet, never root-absolute`);
      continue;
    }
    const [, fileName, pinned] = parsed;
    const actual = sha256Of(fileName);
    if (actual !== pinned) {
      failures.push(`font URL for ${fileName} pins ?v=${pinned} but the file's sha256 is ${actual}`);
    }
  }
  return failures;
}

test("live font URLs are relative and hash-pinned", () => {
  const builtCss = fs.readFileSync(BUILT_CSS, "utf8");
  assert.deepEqual(checkFontUrls(builtCss, fontSha256), []);
  // The source stylesheet is the authored copy; the built one must not drift from it.
  assert.deepEqual(checkFontUrls(fs.readFileSync(APP_CSS, "utf8"), fontSha256), []);
});

const PLANTED_HASH = "a".repeat(64);
const plantedFontCss = (uiUrl) =>
  [
    `@font-face { font-family: "Hanken Grotesk"; src: url("${uiUrl}") format("woff2"); }`,
    `@font-face { font-family: "Sometype Mono"; src: url("../fonts/mono.woff2?v=${PLANTED_HASH}") format("woff2"); }`,
    `@font-face { font-family: "Hanken Grotesk Fallback"; src: local("Arial"); }`,
    `@font-face { font-family: "Sometype Mono Fallback"; src: local("Courier New"); }`,
  ].join("\n");
const plantedSha256 = () => PLANTED_HASH;

test("planted font hash mismatch fails", () => {
  assert.deepEqual(checkFontUrls(plantedFontCss(`../fonts/ui.woff2?v=${PLANTED_HASH}`), plantedSha256), []);
  const failures = checkFontUrls(plantedFontCss(`../fonts/ui.woff2?v=${"b".repeat(64)}`), plantedSha256);
  assert.ok(failures.some((failure) => /ui\.woff2 .*pins \?v=b{64} but the file's sha256 is a{64}/.test(failure)), failures.join("\n"));
});

test("planted root-absolute font URL fails", () => {
  const failures = checkFontUrls(plantedFontCss(`/assets/fonts/ui.woff2?v=${PLANTED_HASH}`), plantedSha256);
  assert.ok(failures.some((failure) => /\/assets\/fonts\/ui\.woff2.*never root-absolute/.test(failure)), failures.join("\n"));
});

// ---------------------------------------------------------------------------
// Retired-identity deny-list (TOK-02)
// ---------------------------------------------------------------------------

const ALLOWLIST_RELATIVE = "examples/scrypath_ecommerce/retired-identity-allowlist.json";
const ALLOWLIST_PATH = path.join(ROOT, ALLOWLIST_RELATIVE);
const ALLOWLIST_SCHEMA = "scrypath.retired-identity-allowlist.v1";
const ALLOWLIST_TAGS = new Set(["p186", "p187", "p188", "p189", "retire-last"]);

// Bare six-digit hex values of the retired identity, without the leading hash and in one
// unquoted list (a quoted bare token such as the JSON form is itself scanned), so this file
// never contains one. Sources: the CONTEXT list (13), the live values the
// CONTEXT list missed (5), and the warm-paper and old-ramp tier from the research (12).
// The tier-4 semantic fills stay off this list until Phase 187 decides their fate.
const DENY_HEX = `
  191e25 353d48 f1f2f4 dce2e9 f3f5f8 edf1f5 202124
  2a3446 302b4c eeebff a85d2e 111419 222831
  5b4ad1 aaa0ff 6c5ce7 c17a3e 141923
  fffdf8 faf7f2 f4f1ea ded8ce 1b2230 475066
  6b7388 7f8aa3 b3bdcf d7d0c4 e0b487 f2eee7
`.trim().split(/\s+/);
// The retired brand directory, joined at runtime for the same reason.
const RETIRED_DIR = ["brand", "book/"].join("");

const EXEMPT_PREFIXES = [".planning/"];
// Hash-pinned brand prose that prints two retired values, and the allowlist itself.
const EXEMPT_PATHS = new Set(["brand/BRAND.md", "brand/brand.json", ALLOWLIST_RELATIVE]);
const MAX_SCAN_BYTES = 8 * 1024 * 1024;
const NUL_SNIFF_BYTES = 8192;

// Linear patterns: no nested quantifiers, separators are alternatives not overlaps.
// A hex value is written with a hash, percent-encoded (%23, the form inside url("data:image/svg+xml,...")),
// as a JS literal (0x), or as a quoted bare token ("abc123" in JSON or YAML).
const HEX_PATTERN = /(?:#|%23|0x)([0-9a-f]{6})(?:[0-9a-f]{2})?(?![0-9a-f])/gi;
const QUOTED_HEX_PATTERN = /["']([0-9a-f]{6})(?:[0-9a-f]{2})?["']/gi;
// rgb() and rgba() with integer, decimal or percent channels.
const RGB_PATTERN = /rgba?\(\s*(\d{1,3}(?:\.\d{1,6})?%?)(?:\s*,\s*|\s+)(\d{1,3}(?:\.\d{1,6})?%?)(?:\s*,\s*|\s+)(\d{1,3}(?:\.\d{1,6})?%?)/gi;
// color(srgb r g b): channels from 0 to 1, or percent.
const SRGB_PATTERN = /color\(\s*srgb\s+(\d*\.?\d+%?)\s+(\d*\.?\d+%?)\s+(\d*\.?\d+%?)/gi;
// Extensions that are binary by nature (skipped without reading) and text extensions where a NUL byte
// means the file cannot be scanned (an encoding the scan does not understand), not that it is binary.
const BINARY_EXTENSIONS = new Set([
  ".png", ".jpg", ".jpeg", ".gif", ".webp", ".avif", ".bmp", ".ico", ".woff", ".woff2", ".ttf", ".otf",
  ".eot", ".pdf", ".zip", ".gz", ".tgz", ".tar", ".wasm", ".mp3", ".mp4", ".wav", ".ogg", ".mov", ".webm",
  ".beam", ".ez", ".sqlite", ".db",
]);
const TEXT_EXTENSIONS = new Set([
  ".css", ".scss", ".less", ".svg", ".html", ".htm", ".xml", ".js", ".mjs", ".cjs", ".ts", ".tsx", ".jsx",
  ".json", ".md", ".markdown", ".txt", ".csv", ".yml", ".yaml", ".toml", ".sh", ".ex", ".exs", ".eex", ".heex",
]);

function hexTriplet(hex) {
  const value = Number.parseInt(hex, 16);
  return [(value >> 16) & 255, (value >> 8) & 255, value & 255].join(",");
}

function buildDeny(hexes = DENY_HEX) {
  return {
    hexes: new Set(hexes.map(lower)),
    triplets: new Set(hexes.map(hexTriplet)),
    directory: RETIRED_DIR,
  };
}

function isExempt(relativePath) {
  return EXEMPT_PATHS.has(relativePath) || EXEMPT_PREFIXES.some((prefix) => relativePath.startsWith(prefix));
}

/** Tracked plus untracked-but-not-ignored files, NUL-separated, no shell. */
function listRepoFiles(root) {
  const output = execFileSync("git", ["ls-files", "-z", "--cached", "--others", "--exclude-standard"], {
    cwd: root,
    maxBuffer: 256 * 1024 * 1024,
  });
  return [...new Set(output.toString("utf8").split("\0").filter(Boolean))].sort();
}

/** A color channel from an rgb() token: a number 0 to 255, or a percent of 255. */
function rgbChannel(token) {
  return token.endsWith("%") ? Math.round(Number.parseFloat(token) * 2.55) : Math.round(Number.parseFloat(token));
}

/** A color channel from a color(srgb ...) token: a number 0 to 1, or a percent. */
function srgbChannel(token) {
  return token.endsWith("%") ? Math.round(Number.parseFloat(token) * 2.55) : Math.round(Number.parseFloat(token) * 255);
}

/** The distinct denied values in a text and how many times any of them occurs. */
function scanText(text, deny) {
  const values = new Set();
  let count = 0;
  const note = (value) => {
    values.add(value);
    count += 1;
  };
  for (const pattern of [HEX_PATTERN, QUOTED_HEX_PATTERN]) {
    for (const match of text.matchAll(pattern)) {
      const hex = match[1].toLowerCase();
      if (deny.hexes.has(hex)) note(`#${hex}`);
    }
  }
  for (const [pattern, channel] of [[RGB_PATTERN, rgbChannel], [SRGB_PATTERN, srgbChannel]]) {
    for (const match of text.matchAll(pattern)) {
      const triplet = [match[1], match[2], match[3]].map(channel).join(",");
      if (deny.triplets.has(triplet)) note(`rgb(${triplet})`);
    }
  }
  const lowered = text.toLowerCase();
  for (let at = lowered.indexOf(deny.directory); at !== -1; at = lowered.indexOf(deny.directory, at + deny.directory.length)) {
    note(deny.directory);
  }
  return { values, count };
}

/** The first bytes of a file, for the encoding check. */
function readHead(absolute, size) {
  const head = Buffer.alloc(Math.min(NUL_SNIFF_BYTES, size));
  const fd = fs.openSync(absolute, "r");
  try {
    fs.readSync(fd, head, 0, head.length, 0);
  } finally {
    fs.closeSync(fd);
  }
  return head;
}

/**
 * UTF-16 without a byte-order mark: a quarter or more of the bytes are NUL and nearly all of them sit at
 * the same parity. Returns "utf16le", "utf16be" or null. A lone planted NUL or a binary does not qualify.
 */
function wideEncoding(head) {
  let even = 0;
  let odd = 0;
  for (let index = 0; index < head.length; index += 1) {
    if (head[index] === 0) {
      if (index % 2 === 0) even += 1;
      else odd += 1;
    }
  }
  const total = even + odd;
  if (total < head.length * 0.25 || total === 0) return null;
  if (odd >= total * 0.9) return "utf16le";
  if (even >= total * 0.9) return "utf16be";
  return null;
}

/**
 * How to read a file: "skip" (a binary), "utf8", "utf16le" or "utf16be" (a byte-order mark or the wide-encoding
 * heuristic). A NUL byte in a file with a text extension that is not recognizably UTF-16 throws: the scan
 * cannot read it, and silently skipping it would hide a retired value.
 */
function classifyFile(head, relativePath) {
  const extension = path.extname(relativePath).toLowerCase();
  if (BINARY_EXTENSIONS.has(extension)) return "skip";
  if (head[0] === 0xff && head[1] === 0xfe) return "utf16le";
  if (head[0] === 0xfe && head[1] === 0xff) return "utf16be";
  if (!head.includes(0)) return "utf8";
  const wide = wideEncoding(head);
  if (wide !== null) return wide;
  if (TEXT_EXTENSIONS.has(extension)) {
    throw new Error(`${relativePath} is a text file with a NUL byte in an unknown encoding and cannot be scanned`);
  }
  return "skip";
}

function decodeFile(bytes, encoding) {
  if (encoding === "utf8") return bytes.toString("utf8");
  const body = bytes[0] === 0xff && bytes[1] === 0xfe || bytes[0] === 0xfe && bytes[1] === 0xff ? bytes.subarray(2) : bytes;
  const even = body.subarray(0, body.length - (body.length % 2));
  return (encoding === "utf16be" ? Buffer.from(even).swap16() : even).toString("utf16le");
}

/**
 * Scan files for denied values. Skips exempt paths, files missing from the working
 * tree, anything that is not a regular file (symlinks are never followed) and
 * binaries (known binary extensions, or a NUL byte in a file that is not text).
 * UTF-16 text is decoded first. A text file over 8 MiB, or a text file with an
 * unreadable encoding, throws.
 */
function scanFiles(root, files, deny) {
  const hits = new Map();
  for (const relativePath of files) {
    if (isExempt(relativePath)) continue;
    const absolute = path.join(root, relativePath);
    let stat;
    try {
      stat = fs.lstatSync(absolute);
    } catch (error) {
      if (error.code === "ENOENT") continue;
      throw error;
    }
    if (!stat.isFile()) continue;
    const encoding = classifyFile(readHead(absolute, stat.size), relativePath);
    if (encoding === "skip") continue;
    if (stat.size > MAX_SCAN_BYTES) {
      throw new Error(`${relativePath} is ${stat.size} bytes, over the ${MAX_SCAN_BYTES} byte scan limit`);
    }
    const found = scanText(decodeFile(fs.readFileSync(absolute), encoding), deny);
    if (found.count > 0) hits.set(relativePath, found);
  }
  return hits;
}

function entryMatches(entry, relativePath) {
  return entry.path === undefined ? relativePath.startsWith(entry.prefix) : relativePath === entry.path;
}

function entryTarget(entry) {
  return entry.path ?? entry.prefix;
}

/**
 * Failures for the allowlist against a scan. Messages start with a category:
 * "unlisted" (a retired value nobody listed, in a new file or in more places than an
 * entry allows) or "allowlist" (the list itself is wrong or out of date).
 *
 * Each entry carries `max_hits`, the number of retired-value occurrences in the files it
 * covers. More than that is unlisted growth; fewer means the ceiling must be lowered, so a
 * file already on the list can neither gain a retired value nor keep unused room for one.
 */
function checkAllowlist(hits, allowlist, files, limits = LIMITS) {
  const failures = [];
  if (allowlist.schema !== ALLOWLIST_SCHEMA) failures.push(`allowlist schema is ${String(allowlist.schema)}`);
  if (!Array.isArray(allowlist.entries)) return [...failures, "allowlist has no entries list"];
  const entries = allowlist.entries;
  if (entries.length > limits.allowlist) {
    failures.push(`allowlist has ${entries.length} entries, over ALLOWLIST_CEILING ${limits.allowlist} (shrink-only)`);
  } else if (Number.isFinite(limits.allowlist) && entries.length < limits.allowlist) {
    failures.push(`ALLOWLIST_CEILING is ${limits.allowlist} but the allowlist has only ${entries.length} entries: lower it to ${entries.length}`);
  }

  const seen = new Set();
  const usable = [];
  for (const entry of entries) {
    const hasPath = typeof entry.path === "string" && entry.path !== "";
    const hasPrefix = typeof entry.prefix === "string" && entry.prefix.endsWith("/");
    if (hasPath === hasPrefix) {
      failures.push(`allowlist entry needs exactly one of path or a prefix ending in a slash: ${JSON.stringify(entry)}`);
      continue;
    }
    const target = entryTarget(entry);
    if (seen.has(target)) failures.push(`allowlist entry ${target} is listed twice`);
    seen.add(target);
    if (!ALLOWLIST_TAGS.has(entry.tag)) failures.push(`allowlist entry ${target} has unknown tag ${String(entry.tag)}`);
    if (hasPrefix && entry.tag !== "retire-last") {
      failures.push(`allowlist prefix entry ${target} covers a whole directory and must be tagged retire-last`);
    }
    if (typeof entry.reason !== "string" || entry.reason.trim() === "") {
      failures.push(`allowlist entry ${target} needs a reason`);
    } else if (entry.tag === "retire-last" && !entry.reason.includes("owner: ")) {
      failures.push(`allowlist entry ${target} is retire-last and its reason must name an owner ("owner: ...")`);
    }
    if (EXEMPT_PATHS.has(target) || EXEMPT_PREFIXES.some((prefix) => target.startsWith(prefix))) {
      failures.push(`allowlist entry ${target} sits under an exempt path and must be removed`);
    }
    usable.push(entry);
  }

  for (const [relativePath, found] of hits) {
    if (!usable.some((entry) => entryMatches(entry, relativePath))) {
      failures.push(`unlisted retired identity value in ${relativePath}: ${[...found.values].sort().join(" ")}`);
    }
  }
  for (const entry of usable) {
    const target = entryTarget(entry);
    const covered = files.filter((file) => entryMatches(entry, file));
    const total = covered.reduce((sum, file) => sum + (hits.get(file)?.count ?? 0), 0);
    if (covered.length === 0) {
      failures.push(`allowlist entry ${target} names a missing path`);
    } else if (total === 0) {
      failures.push(`stale allowlist entry ${target}: no file it covers holds a retired value any more`);
    } else if (!Number.isInteger(entry.max_hits) || entry.max_hits < 1) {
      failures.push(`allowlist entry ${target} needs max_hits, a positive integer (the files it covers hold ${total})`);
    } else if (total > entry.max_hits) {
      failures.push(`unlisted retired identity values in allowlisted entry ${target}: ${total} found, max_hits is ${entry.max_hits} (remove the new values; do not raise the ceiling)`);
    } else if (total < entry.max_hits) {
      failures.push(`allowlist entry ${target} holds ${total} retired values, under its max_hits ${entry.max_hits}: lower max_hits to ${total}`);
    }
  }

  const ceiling = usable.reduce((sum, entry) => sum + (Number.isInteger(entry.max_hits) ? entry.max_hits : 0), 0);
  if (Number.isFinite(limits.hits)) {
    if (ceiling > limits.hits) {
      failures.push(`allowlist max_hits add up to ${ceiling}, over HITS_CEILING ${limits.hits} (shrink-only)`);
    } else if (ceiling < limits.hits) {
      failures.push(`allowlist max_hits add up to ${ceiling}, under HITS_CEILING ${limits.hits}: lower HITS_CEILING to ${ceiling}`);
    }
  }
  return failures;
}

/** The allowlist file may hold paths and prose, never a color. */
function allowlistTextFailures(text) {
  const failures = [];
  if (/#[0-9a-f]{3,8}(?![0-9a-f])/i.test(text)) failures.push("allowlist file holds a hex color pattern");
  if (/rgba?\(/i.test(text)) failures.push("allowlist file holds an rgb( pattern");
  return failures;
}

function liveScan() {
  const files = listRepoFiles(ROOT);
  const hits = scanFiles(ROOT, files, buildDeny());
  return { files, hits, allowlist: readJson(ALLOWLIST_PATH) };
}

test("live deny-list scan finds no unlisted retired value", () => {
  const { files, hits, allowlist } = liveScan();
  const unlisted = checkAllowlist(hits, allowlist, files).filter((failure) => failure.startsWith("unlisted"));
  assert.deepEqual(unlisted, []);
});

test("live allowlist entries are current and tagged", () => {
  const { files, hits, allowlist } = liveScan();
  const listProblems = checkAllowlist(hits, allowlist, files).filter((failure) => !failure.startsWith("unlisted"));
  assert.deepEqual(listProblems, []);
  assert.deepEqual(allowlistTextFailures(fs.readFileSync(ALLOWLIST_PATH, "utf8")), []);
  console.log(`retired-identity allowlist entries: ${allowlist.entries.length} of ${ALLOWLIST_CEILING}`);
});

test("deny set and new set are disjoint", () => {
  const { map, brandTokens } = loadLive();
  const deny = buildDeny();
  assert.equal(new Set(DENY_HEX).size, DENY_HEX.length, "deny hexes are unique");
  assert.ok(DENY_HEX.every((hex) => /^[0-9a-f]{6}$/.test(hex)), "deny hexes are bare six-digit values");
  const fresh = allowedHexSet(map, brandTokens);
  assert.deepEqual([...fresh].filter((hex) => deny.hexes.has(hex)), [], "a new value is also denied");
  assert.deepEqual(
    [...fresh].map(hexTriplet).filter((triplet) => deny.triplets.has(triplet)),
    [],
    "a new value shares an rgb triplet with a denied one",
  );
});

// Planted failures and accept cases run through the same listRepoFiles, scanFiles
// and checkAllowlist on a throwaway git tree. Retired values are assembled here.

const treeRoots = [];
after(() => {
  for (const dir of treeRoots) fs.rmSync(dir, { recursive: true, force: true });
});

function makeTree(fileContents) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "scrypath-ui-tokens-"));
  treeRoots.push(dir);
  execFileSync("git", ["init", "-q"], { cwd: dir });
  for (const [relativePath, content] of Object.entries(fileContents)) {
    const absolute = path.join(dir, relativePath);
    fs.mkdirSync(path.dirname(absolute), { recursive: true });
    fs.writeFileSync(absolute, content);
  }
  execFileSync("git", ["add", "-A"], { cwd: dir });
  return dir;
}

function scanTree(dir, entries = []) {
  const files = listRepoFiles(dir);
  const hits = scanFiles(dir, files, buildDeny());
  return checkAllowlist(hits, { schema: ALLOWLIST_SCHEMA, entries }, files, NO_LIMITS);
}

const retired = `#${DENY_HEX[0]}`;
const retiredTriplet = hexTriplet(DENY_HEX[5]).split(",");
const brandPanel = () => resolveBrandHex(readJson(BRAND_TOKENS), "color.light.panel");
const entry = (target, tag = "p187", maxHits = 1) => ({ path: target, tag, reason: "planted fixture entry", max_hits: maxHits });

test("planted retired hex fails", () => {
  const dir = makeTree({ "src/theme.css": `a { color: ${retired}; }\n` });
  assert.ok(anyFailure(scanTree(dir), /unlisted retired identity value in src\/theme\.css/));
});

test("planted retired rgb triplet fails", () => {
  const dir = makeTree({ "src/glow.css": `a { box-shadow: 0 0 4px rgba(${retiredTriplet.join(", ")}, 0.3); }\n` });
  assert.ok(anyFailure(scanTree(dir), /unlisted retired identity value in src\/glow\.css/));
  const spaced = makeTree({ "src/modern.css": `a { color: rgb(${retiredTriplet.join(" ")} / 50%); }\n` });
  assert.ok(anyFailure(scanTree(spaced), /unlisted retired identity value in src\/modern\.css/));
});

test("planted uppercase retired hex fails", () => {
  const dir = makeTree({ "src/Theme.css": `a { color: #${DENY_HEX[3].toUpperCase()}; }\n` });
  assert.ok(anyFailure(scanTree(dir), /unlisted retired identity value in src\/Theme\.css/));
  const alpha = makeTree({ "src/alpha.css": `a { color: ${retired}cc; }\n` });
  assert.ok(anyFailure(scanTree(alpha), /unlisted retired identity value in src\/alpha\.css/));
});

// Forms the first scan missed (phase 186 review WR-07): percent-encoded in a data URI, decimal and percent rgb
// channels, color(srgb), a quoted bare token, a JS literal, and UTF-16 files.
const percentChannels = retiredTriplet.map((channel) => `${((Number(channel) / 255) * 100).toFixed(2)}%`);
const unitChannels = retiredTriplet.map((channel) => (Number(channel) / 255).toFixed(4));

const plantedForms = [
  ["a percent-encoded hash in a data URI", "src/icon.css", `a { background: url("data:image/svg+xml,%3Csvg fill='%23${DENY_HEX[0]}'/%3E"); }\n`],
  ["decimal rgb channels", "src/decimal.css", `a { color: rgb(${retiredTriplet.map((channel) => `${channel}.0`).join(" ")}); }\n`],
  ["percent rgb channels", "src/percent.css", `a { color: rgb(${percentChannels.join(" ")}); }\n`],
  ["color(srgb) channels", "src/srgb.css", `a { color: color(srgb ${unitChannels.join(" ")}); }\n`],
  ["a quoted bare token in JSON", "src/tokens.json", `{"fill": "${DENY_HEX[0].toUpperCase()}"}\n`],
  ["a hex literal in JS", "src/colors.js", `export const old = 0x${DENY_HEX[0]};\n`],
];
for (const [label, file, content] of plantedForms) {
  test(`planted retired value as ${label} fails`, () => {
    const dir = makeTree({ [file]: content });
    assert.ok(anyFailure(scanTree(dir), new RegExp(`unlisted retired identity value in ${file.replace(".", "\\.")}`)));
  });
}

test("planted retired value in UTF-16 files fails instead of being skipped", () => {
  const css = `a { color: ${retired}; }\n`;
  const little = Buffer.from(css, "utf16le");
  const files = {
    "src/le-bom.css": Buffer.concat([Buffer.from([0xff, 0xfe]), little]),
    "src/be-bom.css": Buffer.concat([Buffer.from([0xfe, 0xff]), Buffer.from(little).swap16()]),
    "src/le-no-bom.css": little,
    "src/be-no-bom.css": Buffer.from(little).swap16(),
  };
  const failures = scanTree(makeTree(files));
  for (const file of Object.keys(files)) {
    assert.ok(anyFailure(failures, new RegExp(`unlisted retired identity value in ${file.replace(".", "\\.")}`)), file);
  }
});

test("a NUL byte in a text file that is not UTF-16 is a failure to scan, not a skip", () => {
  const dir = makeTree({ "src/planted.css": Buffer.from(`a { color: ${retired}; }\n/* \0 */\n`) });
  assert.throws(() => scanTree(dir), /src\/planted\.css is a text file with a NUL byte .* cannot be scanned/);
});

test("accept binaries by extension and unknown binaries with a NUL byte", () => {
  const dir = makeTree({
    "src/pic.png": Buffer.concat([Buffer.from([0x89, 0x50, 0, 0]), Buffer.from(retired)]),
    "src/font.woff2": Buffer.concat([Buffer.from([0, 1, 0, 0]), Buffer.from(retired)]),
    "src/blob.dat": Buffer.concat([Buffer.from([0, 1, 2, 3, 0, 5]), Buffer.from(retired)]),
  });
  assert.deepEqual(scanTree(dir), []);
});

test("accept new-identity values in every scanned encoding", () => {
  const brand = brandPanel();
  const channels = [1, 3, 5].map((offset) => Number.parseInt(brand.slice(offset, offset + 2), 16));
  const dir = makeTree({
    "src/new.css": [
      `a { color: ${brand}; background: url("data:image/svg+xml,%3Csvg fill='%23${brand.slice(1)}'/%3E"); }`,
      `b { color: rgb(${channels.map((channel) => `${channel}.0`).join(" ")}); }`,
      `c { color: color(srgb ${channels.map((channel) => (channel / 255).toFixed(4)).join(" ")}); }`,
    ].join("\n"),
    "src/new.json": `{"fill": "${brand.slice(1)}"}\n`,
    "src/new.js": `export const fresh = 0x${brand.slice(1)};\n`,
    "src/new-utf16.css": Buffer.concat([Buffer.from([0xff, 0xfe]), Buffer.from(`a { color: ${brand}; }\n`, "utf16le")]),
  });
  assert.deepEqual(scanTree(dir), []);
});

test("planted retired directory string fails", () => {
  const dir = makeTree({ "docs/guide.md": `See ${RETIRED_DIR}tokens/tokens.css for the old values.\n` });
  assert.ok(anyFailure(scanTree(dir), /unlisted retired identity value in docs\/guide\.md/));
});

test("planted stale allowlist entry fails", () => {
  const dir = makeTree({ "src/clean.css": `a { color: ${brandPanel()}; }\n` });
  assert.ok(anyFailure(scanTree(dir, [entry("src/clean.css")]), /stale allowlist entry src\/clean\.css/));
});

test("planted missing allowlist path fails", () => {
  const dir = makeTree({ "src/clean.css": `a { color: ${brandPanel()}; }\n` });
  assert.ok(anyFailure(scanTree(dir, [entry("src/gone.css")]), /allowlist entry src\/gone\.css names a missing path/));
});

test("planted allowlist ceiling breach fails", () => {
  const dir = makeTree({ "src/a.css": `a { color: ${retired}; }\n`, "src/b.css": `b { color: ${retired}; }\n` });
  const files = listRepoFiles(dir);
  const hits = scanFiles(dir, files, buildDeny());
  const allowlist = { schema: ALLOWLIST_SCHEMA, entries: [entry("src/a.css"), entry("src/b.css")] };
  assert.deepEqual(checkAllowlist(hits, allowlist, files, { ...NO_LIMITS, allowlist: 2 }), []);
  assert.ok(anyFailure(checkAllowlist(hits, allowlist, files, { ...NO_LIMITS, allowlist: 1 }), /over ALLOWLIST_CEILING 1/));
});

test("planted ceiling above live count fails: allowlist entries", () => {
  const dir = makeTree({ "src/a.css": `a { color: ${retired}; }\n`, "src/b.css": `b { color: ${retired}; }\n` });
  const files = listRepoFiles(dir);
  const hits = scanFiles(dir, files, buildDeny());
  const allowlist = { schema: ALLOWLIST_SCHEMA, entries: [entry("src/a.css"), entry("src/b.css")] };
  assert.ok(
    anyFailure(
      checkAllowlist(hits, allowlist, files, { ...NO_LIMITS, allowlist: 3 }),
      /ALLOWLIST_CEILING is 3 but the allowlist has only 2 entries: lower it to 2/,
    ),
  );
});

test("accept brand-only tree", () => {
  const dir = makeTree({
    "src/theme.css": `a { color: ${brandPanel()}; background: rgb(17 17 17); }\n`,
    "src/notes.md": "No retired identity values here.\n",
    "src/blob.bin": Buffer.from([0, 1, 2, 3]),
  });
  assert.deepEqual(scanTree(dir), []);
});

test("accept exempt planning file", () => {
  const dir = makeTree({
    ".planning/notes.md": `Old values ${retired} and ${RETIRED_DIR} live here as a record.\n`,
    "brand/BRAND.md": `The retired lead color was ${retired}.\n`,
    "brand/brand.json": `{"legacy": "${retired}"}\n`,
  });
  assert.deepEqual(scanTree(dir), []);
});

test("accept allowlisted file with hits", () => {
  const dir = makeTree({
    "src/legacy.css": `a { color: ${retired}; }\n`,
    [`${RETIRED_DIR}tokens/x.css`]: `a { color: ${retired}; }\n`,
  });
  const entries = [entry("src/legacy.css"), { prefix: RETIRED_DIR, tag: "retire-last", reason: "owner: a later phase deletes it", max_hits: 1 }];
  assert.deepEqual(scanTree(dir, entries), []);
});

// WR-08 (phase 186 review): the allowlist is path-level, so a retired value added to a file that is already
// listed used to pass. Each entry now carries max_hits, the count of occurrences in the files it covers.
test("planted growth in an already-allowlisted file fails", () => {
  const dir = makeTree({ "src/legacy.css": `a { color: ${retired}; }\nb { color: ${retired}; }\n` });
  assert.deepEqual(scanTree(dir, [entry("src/legacy.css", "p187", 2)]), []);
  assert.ok(
    anyFailure(scanTree(dir, [entry("src/legacy.css", "p187", 1)]), /unlisted retired identity values in allowlisted entry src\/legacy\.css: 2 found, max_hits is 1/),
  );
});

test("planted growth through a different form in a listed file fails", () => {
  const dir = makeTree({ "src/legacy.css": `a { color: ${retired}; background: rgb(${retiredTriplet.join(", ")}); }\n` });
  assert.ok(anyFailure(scanTree(dir, [entry("src/legacy.css", "p187", 1)]), /2 found, max_hits is 1/));
});

test("planted growth inside a prefix entry fails", () => {
  const prefix = { prefix: RETIRED_DIR, tag: "retire-last", reason: "owner: a later phase deletes it", max_hits: 1 };
  const dir = makeTree({
    [`${RETIRED_DIR}a.css`]: `a { color: ${retired}; }\n`,
    [`${RETIRED_DIR}b.css`]: `b { color: ${retired}; }\n`,
  });
  assert.ok(anyFailure(scanTree(dir, [prefix]), /allowlisted entry .* 2 found, max_hits is 1/));
  assert.deepEqual(scanTree(dir, [{ ...prefix, max_hits: 2 }]), []);
});

test("planted hit drop below the ceiling fails until the ceiling is lowered", () => {
  const dir = makeTree({ "src/legacy.css": `a { color: ${retired}; }\nb { color: ${retired}; }\n` });
  assert.ok(
    anyFailure(scanTree(dir, [entry("src/legacy.css", "p187", 3)]), /src\/legacy\.css holds 2 retired values, under its max_hits 3: lower max_hits to 2/),
  );
});

test("planted missing or invalid max_hits fails", () => {
  const dir = makeTree({ "src/legacy.css": `a { color: ${retired}; }\n` });
  const { max_hits: _omitted, ...withoutCeiling } = entry("src/legacy.css");
  assert.ok(anyFailure(scanTree(dir, [withoutCeiling]), /src\/legacy\.css needs max_hits, a positive integer/));
  for (const bad of [0, -1, 1.5, "1", null]) {
    assert.ok(anyFailure(scanTree(dir, [{ ...withoutCeiling, max_hits: bad }]), /needs max_hits/), String(bad));
  }
});

test("planted prefix entry that is not retire-last fails", () => {
  const dir = makeTree({ "src/legacy.css": `a { color: ${retired}; }\n` });
  const failures = scanTree(dir, [{ prefix: "src/", tag: "p187", reason: "planted fixture entry", max_hits: 1 }]);
  assert.ok(anyFailure(failures, /allowlist prefix entry src\/ covers a whole directory and must be tagged retire-last/));
});

test("planted hits ceiling must equal the sum of max_hits", () => {
  const dir = makeTree({ "src/a.css": `a { color: ${retired}; }\n`, "src/b.css": `b { color: ${retired}; }\n` });
  const files = listRepoFiles(dir);
  const hits = scanFiles(dir, files, buildDeny());
  const allowlist = { schema: ALLOWLIST_SCHEMA, entries: [entry("src/a.css"), entry("src/b.css")] };
  assert.deepEqual(checkAllowlist(hits, allowlist, files, { ...NO_LIMITS, hits: 2 }), []);
  assert.ok(anyFailure(checkAllowlist(hits, allowlist, files, { ...NO_LIMITS, hits: 1 }), /add up to 2, over HITS_CEILING 1/));
  assert.ok(anyFailure(checkAllowlist(hits, allowlist, files, { ...NO_LIMITS, hits: 3 }), /under HITS_CEILING 3: lower HITS_CEILING to 2/));
});

// Part 3, N-09 (A11Y-02): focused elements scroll to a position below the sticky header.
//
// What this proves, in plain terms: the stylesheet gives the page a scroll padding that is the
// sticky header's height plus 1rem, and the header height is one variable (4rem, 7rem at 640px
// and below, where the header wraps to two rows), so a keyboard user's focused control is never
// hidden behind the header. The Help page's two old scroll-margin rules are gone, because they
// duplicated that job with hard-coded numbers. The browser measurement of the real header (P-10)
// is a separate check; this one stops the rule from being deleted or hard-coded again.
function stripCssComments(css) {
  return css.replace(/\/\*[\s\S]*?\*\//g, "");
}

// The text inside the braces of every `@media (<query>) {` block, with nested braces matched.
function mediaBlocks(css, query) {
  const blocks = [];
  const opener = new RegExp(`@media\\s*\\(${query}\\)\\s*\\{`, "g");
  let match;
  while ((match = opener.exec(css))) {
    let depth = 1;
    let index = opener.lastIndex;
    while (index < css.length && depth > 0) {
      if (css[index] === "{") depth += 1;
      else if (css[index] === "}") depth -= 1;
      index += 1;
    }
    blocks.push(css.slice(opener.lastIndex, index - 1));
  }
  return blocks;
}

// Flat rules (declaration blocks with no nested braces) whose selector satisfies `selectorTest`.
function flatRules(css, selectorTest) {
  const rules = [];
  for (const match of css.matchAll(/([^{}]+)\{([^{}]*)\}/g)) {
    const selector = match[1].trim().split("\n").map((line) => line.trim()).join(" ");
    if (selectorTest(selector)) rules.push({ selector, body: match[2] });
  }
  return rules;
}

function scrollPaddingFailures(source) {
  const css = stripCssComments(source);
  const failures = [];
  const htmlRules = flatRules(css, (selector) => /^html\b/.test(selector));

  if (!htmlRules.some((rule) => /scroll-padding-top:\s*calc\(\s*var\(--ops-header-h\)\s*\+\s*1rem\s*\)/.test(rule.body))) {
    failures.push("no html rule sets scroll-padding-top to calc(var(--ops-header-h) + 1rem)");
  }
  if (!htmlRules.some((rule) => /--ops-header-h:\s*4rem\b/.test(rule.body))) {
    failures.push("no html rule declares --ops-header-h as 4rem");
  }
  const narrow = mediaBlocks(css, "max-width:\\s*640px");
  const narrowHtml = narrow.flatMap((block) => flatRules(block, (selector) => /^html\b/.test(selector)));
  if (!narrowHtml.some((rule) => /--ops-header-h:\s*7rem\b/.test(rule.body))) {
    failures.push("no html rule inside @media (max-width: 640px) declares --ops-header-h as 7rem");
  }
  if (!flatRules(css, (selector) => selector === ".ops-header").some((rule) => /min-height:\s*var\(--ops-header-h\b/.test(rule.body))) {
    failures.push(".ops-header does not take its min-height from --ops-header-h");
  }
  for (const rule of flatRules(css, (selector) => /\.ops-help/.test(selector))) {
    if (/scroll-margin-top\s*:/.test(rule.body)) failures.push(`${rule.selector} still declares a scroll margin`);
  }
  return failures;
}

const SCROLL_PADDING_FIXTURE = `
html:has(.ops-shell) { --ops-header-h: 4rem; scroll-padding-top: calc(var(--ops-header-h) + 1rem); }
@media (max-width: 640px) { html:has(.ops-shell) { --ops-header-h: 7rem; } }
.ops-header { min-height: var(--ops-header-h, 4rem); }
`;

test("live scroll padding clears the sticky header", () => {
  const failures = scrollPaddingFailures(fs.readFileSync(APP_CSS, "utf8"));
  assert.deepEqual(failures, []);
});

test("planted missing scroll padding fails", () => {
  assert.deepEqual(scrollPaddingFailures(SCROLL_PADDING_FIXTURE), []);

  const noPadding = SCROLL_PADDING_FIXTURE.replace(/scroll-padding-top:[^;]*;/, "");
  assert.ok(scrollPaddingFailures(noPadding).some((message) => /no html rule sets scroll-padding-top/.test(message)));

  const hardCoded = SCROLL_PADDING_FIXTURE.replace("calc(var(--ops-header-h) + 1rem)", "5rem");
  assert.ok(scrollPaddingFailures(hardCoded).some((message) => /no html rule sets scroll-padding-top/.test(message)));

  const noNarrow = SCROLL_PADDING_FIXTURE.replace("7rem", "4rem");
  assert.ok(scrollPaddingFailures(noNarrow).some((message) => /7rem/.test(message)));

  const detached = SCROLL_PADDING_FIXTURE.replace("var(--ops-header-h, 4rem)", "4rem");
  assert.ok(scrollPaddingFailures(detached).some((message) => /min-height from --ops-header-h/.test(message)));

  const helpMargin = `${SCROLL_PADDING_FIXTURE}\n.ops-help-content [id] { scroll-margin-top: 7rem; }\n`;
  assert.ok(scrollPaddingFailures(helpMargin).some((message) => /still declares a scroll margin/.test(message)));

  assert.ok(scrollPaddingFailures("/* html { scroll-padding-top: calc(var(--ops-header-h) + 1rem); } */").length > 0);
});
