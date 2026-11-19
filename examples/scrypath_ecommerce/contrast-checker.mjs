// contrast-checker.mjs
//
// Fast, dependency-free token-pair contrast checker for ScrypathOps.
// Reads scrypath_ops/assets/css/app.css, derives semantic pairs by a fixed
// rule table, composites muted alphas (from contrast-pairs.mjs) in sRGB,
// evaluates WCAG AA/AAA ratios, and exits non-zero iff summary.aa_fail > 0.
//
// Usage:
//   node contrast-checker.mjs           # full check, writes report
//   node contrast-checker.mjs --self-test # gate-liveness proof, exits 0 or 1
//
// Report output: CONTRAST_REPORT_DIR env (default: test-results/contrast/)
//   contrast-report.token.json   — machine source of truth (gitignored)
//   contrast-report.token.md     — generated human view (gitignored)
// WR-04: the filename is producer-namespaced (.token.) so this fast checker's report
// never clobbers the axe matrix's contrast-report.axe.<scenario>.{json,md} in the shared
// CONTRAST_REPORT_DIR.
//
// D-16: lives in examples/scrypath_ecommerce Node lane; scrypath_ops stays Node-free.
// T-128-03: CSS content is parsed as text ONLY (regex/string ops on static text).
//           NO eval() or execution of any CSS content.

import { readFile, mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

// ─── PATHS ────────────────────────────────────────────────────────────────────

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// D-16: read app.css from the cross-workspace path
const APP_CSS_PATH = path.resolve(__dirname, "../../scrypath_ops/assets/css/app.css");
// D-11: muted-alpha manifest beside DESIGN-TOKENS.md
const PAIRS_PATH = path.resolve(__dirname, "../../scrypath_ops/assets/css/contrast-pairs.mjs");
// Phase 187: the pinned brand sources the opaque muted guard and the published-pair check read
const BRAND_TOKENS_PATH = path.resolve(__dirname, "../../brand/tokens.json");
const BRAND_JSON_PATH = path.resolve(__dirname, "../../brand/brand.json");
// D-17: report output (mirrors ADMIN_SCREENSHOT_DIR convention)
const REPORT_DIR = process.env.CONTRAST_REPORT_DIR || "test-results/contrast";

// ─── WCAG MATH (~30 lines, D-13) ─────────────────────────────────────────────

// D-12: composite in sRGB (matches axe-core): out = fg·α + bg·(1−α) per channel
// Input: hex strings like "#abcdef", alpha as 0–1
function compositeAlpha(fgHex, alpha, bgHex) {
  const parse = (h) => [
    parseInt(h.slice(1, 3), 16),
    parseInt(h.slice(3, 5), 16),
    parseInt(h.slice(5, 7), 16),
  ];
  const fg = parse(fgHex);
  const bg = parse(bgHex);
  const out = fg.map((f, i) => Math.round(f * alpha + bg[i] * (1 - alpha)));
  return "#" + out.map((c) => c.toString(16).padStart(2, "0")).join("");
}

// sRGB channel → linear (IEC 61966-2-1)
function toLinear(c) {
  return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}

// Hex color → relative luminance (WCAG 2.x)
function relativeLuminance(hex) {
  const r = parseInt(hex.slice(1, 3), 16) / 255;
  const g = parseInt(hex.slice(3, 5), 16) / 255;
  const b = parseInt(hex.slice(5, 7), 16) / 255;
  return 0.2126 * toLinear(r) + 0.7152 * toLinear(g) + 0.0722 * toLinear(b);
}

// WCAG contrast ratio at FULL precision (no rounding). WR-01: the AA/AAA threshold
// comparison must use this un-rounded value so a boundary ratio (e.g. 4.497) is not
// rounded UP to 4.50 and mis-classified as a pass — axe-core compares the un-rounded
// ratio, and the harness must render one verdict with it.
function contrastRatioRaw(fg, bg) {
  const L1 = relativeLuminance(fg);
  const L2 = relativeLuminance(bg);
  const lighter = Math.max(L1, L2);
  const darker = Math.min(L1, L2);
  return (lighter + 0.05) / (darker + 0.05);
}

// WCAG contrast ratio rounded to 2 decimal places — DISPLAY ONLY (report fields,
// console). Never use the rounded value for a threshold comparison (see WR-01).
function contrastRatio(fg, bg) {
  return Math.round(contrastRatioRaw(fg, bg) * 100) / 100;
}

// D-13 golden self-test: contrastRatio("#000000", "#ffffff") === 21.00

// ─── RULE TABLES (D-10 / D-14) ───────────────────────────────────────────────

// 11 semantic pair rules: fg ↔ bg, role for threshold routing
// base-content against each base surface, and each semantic X-content against X
const PAIR_RULES = [
  { fg: "base-content",       bg: "base-100",   role: "text" },
  { fg: "base-content",       bg: "base-200",   role: "text" },
  { fg: "base-content",       bg: "base-300",   role: "text" },
  { fg: "primary-content",    bg: "primary",    role: "text" }, // ordinary button labels require 4.5
  { fg: "secondary-content",  bg: "secondary",  role: "text" },
  { fg: "accent-content",     bg: "accent",     role: "text" },
  { fg: "neutral-content",    bg: "neutral",    role: "text" },
  { fg: "info-content",       bg: "info",       role: "text" },
  { fg: "success-content",    bg: "success",    role: "text" },
  { fg: "warning-content",    bg: "warning",    role: "text" },
  { fg: "error-content",      bg: "error",      role: "text" },
];

// D-14: role → AA / AAA thresholds
const THRESHOLDS = {
  text:  { aa: 4.5, aaa: 7.0 },
  large: { aa: 3.0, aaa: 4.5 },
  ui:    { aa: 3.0, aaa: 4.5 },
};

// ─── CSS PARSE (D-10) ─────────────────────────────────────────────────────────

// Locate top-level daisyUI theme at-rules lexically. Quoted declaration values
// and comments are inert here, even when they contain plugin-like text/braces.
function cssCommentEnd(source, start) {
  const close = source.indexOf("*/", start + 2);
  return close < 0 ? source.length : close + 2;
}

function cssStringEnd(source, start) {
  const quote = source[start];
  for (let i = start + 1; i < source.length; i += 1) {
    if (source[i] === "\\") { i += 1; continue; }
    if (source[i] === quote) return i + 1;
  }
  return source.length;
}

function skipCssTrivia(source, start) {
  let i = start;
  while (i < source.length) {
    if (/\s/.test(source[i])) { i += 1; continue; }
    if (source.startsWith("/*", i)) { i = cssCommentEnd(source, i); continue; }
    break;
  }
  return i;
}

function onlyCssTrivia(source, start, end) {
  return skipCssTrivia(source.slice(0, end), start) === end;
}

function readCssString(source, start) {
  const quote = source[start];
  let value = "";
  for (let i = start + 1; i < source.length; i += 1) {
    if (source[i] === "\\") {
      if (i + 1 < source.length) value += source[++i];
      continue;
    }
    if (source[i] === quote) return { value, end: i + 1 };
    value += source[i];
  }
  return null;
}

function cssBlockEnd(source, open) {
  let depth = 1;
  for (let i = open + 1; i < source.length; i += 1) {
    if (source.startsWith("/*", i)) { i = cssCommentEnd(source, i) - 1; continue; }
    if (source[i] === "\"" || source[i] === "'") { i = cssStringEnd(source, i) - 1; continue; }
    if (source[i] === "{") depth += 1;
    else if (source[i] === "}" && --depth === 0) return i;
  }
  throw new Error("Unterminated daisyUI theme block");
}

function stripCssComments(source) {
  let result = "";
  for (let i = 0; i < source.length;) {
    if (source.startsWith("/*", i)) {
      const end = cssCommentEnd(source, i);
      result += source.slice(i, end).replace(/[^\n]/g, " ");
      i = end;
    } else if (source[i] === "\"" || source[i] === "'") {
      const end = cssStringEnd(source, i);
      result += source.slice(i, end);
      i = end;
    } else {
      result += source[i++];
    }
  }
  return result;
}

function cssDeclarations(body) {
  const declarations = [];
  let start = 0;
  for (let i = 0; i < body.length; i += 1) {
    if (body.startsWith("/*", i)) { i = cssCommentEnd(body, i) - 1; continue; }
    if (body[i] === "\"" || body[i] === "'") { i = cssStringEnd(body, i) - 1; continue; }
    if (body[i] === ";") {
      declarations.push(stripCssComments(body.slice(start, i)).trim());
      start = i + 1;
    }
  }
  declarations.push(stripCssComments(body.slice(start)).trim());
  return declarations.filter(Boolean);
}

function themePluginBodies(cssText) {
  const bodies = [];
  let depth = 0;
  let statementStart = 0;
  for (let i = 0; i < cssText.length;) {
    if (cssText.startsWith("/*", i)) { i = cssCommentEnd(cssText, i); continue; }
    if (cssText[i] === "\"" || cssText[i] === "'") { i = cssStringEnd(cssText, i); continue; }

    if (depth === 0 && cssText.startsWith("@plugin", i) && onlyCssTrivia(cssText, statementStart, i)) {
      const afterKeyword = i + "@plugin".length;
      if (afterKeyword === cssText.length || !/[\w-]/.test(cssText[afterKeyword])) {
        const pathStart = skipCssTrivia(cssText, afterKeyword);
        const pluginPath = cssText[pathStart] === "\"" || cssText[pathStart] === "'"
          ? readCssString(cssText, pathStart)
          : null;
        if (pluginPath && pluginPath.value.includes("daisyui-theme")) {
          const open = skipCssTrivia(cssText, pluginPath.end);
          if (cssText[open] === "{") {
            const close = cssBlockEnd(cssText, open);
            bodies.push(cssText.slice(open + 1, close));
            i = close + 1;
            statementStart = i;
            continue;
          }
        }
      }
    }

    if (cssText[i] === "{") depth += 1;
    else if (cssText[i] === "}") {
      depth = Math.max(0, depth - 1);
      if (depth === 0) statementStart = i + 1;
    } else if (cssText[i] === ";" && depth === 0) statementStart = i + 1;
    i += 1;
  }
  return bodies;
}

function parseThemeBlocks(cssText) {
  const blocks = {};
  for (const body of themePluginBodies(cssText)) {
    const declarations = cssDeclarations(body);
    const nameMatch = declarations.map((declaration) => /^name:\s*"([^"]+)"$/.exec(declaration)).find(Boolean);
    if (!nameMatch) continue;
    const name = nameMatch[1];
    if (blocks[name]) throw new Error(`Duplicate theme ${name}`);
    blocks[name] = {};
    for (const declaration of declarations) {
      const token = /^--color-([\w-]+):\s*(#[0-9a-fA-F]{6})$/.exec(declaration);
      if (token) blocks[name][token[1]] = token[2];
    }
  }
  return blocks;
}

// ─── REPORT BUILDING (D-17 / D-18 / D-21) ────────────────────────────────────

// Build summary from a findings array.
// summary.aa_fail  — count of severity:"aa-fail" findings
// summary.aaa_advisory — count of severity:"aaa-body-advisory" findings
// D-21: exit non-zero iff summary.aa_fail > 0; advisory findings NEVER affect exit code.
function buildSummary(findings) {
  const aa_fail = findings.filter((f) => f.severity === "aa-fail").length;
  const aaa_advisory = findings.filter((f) => f.severity === "aaa-body-advisory").length;
  return { aa_fail, aaa_advisory, total: findings.length };
}

// Construct the full report object in scrypath.contrast.v1 schema (D-17/D-18)
function buildReport(findings) {
  const summary = buildSummary(findings);
  return {
    schema: "scrypath.contrast.v1",
    producer: "token",
    generated: new Date().toISOString(),
    summary,
    findings,
  };
}

// Build a human-readable markdown report
function buildMarkdownReport(report) {
  const { summary, findings } = report;
  const verdict = summary.aa_fail === 0 ? "PASS" : "FAIL";
  const lines = [
    `# Contrast Report — ${verdict}`,
    ``,
    `Generated: ${report.generated}`,
    `Producer: ${report.producer}`,
    ``,
    `## Summary`,
    ``,
    `| Metric | Count |`,
    `|--------|-------|`,
    `| AA failures (gate) | ${summary.aa_fail} |`,
    `| AAA advisory | ${summary.aaa_advisory} |`,
    `| Total findings | ${summary.total} |`,
    ``,
  ];

  const aaFails = findings.filter((f) => f.severity === "aa-fail");
  if (aaFails.length > 0) {
    lines.push(`## AA Failures (${aaFails.length})`);
    lines.push(``);
    lines.push(`| Theme | Selector / Pair | Actual | Required | Role |`);
    lines.push(`|-------|----------------|--------|----------|------|`);
    for (const f of aaFails) {
      const label = f.selector || f.token_pair || "";
      lines.push(`| ${f.theme} | ${label} | ${f.actual_ratio} | ${f.required_ratio} | ${f.element_role} |`);
    }
    lines.push(``);
  }

  const advisory = findings.filter((f) => f.severity === "aaa-body-advisory");
  if (advisory.length > 0) {
    lines.push(`## AAA Advisory (${advisory.length})`);
    lines.push(``);
    lines.push(`| Theme | Selector / Pair | Actual | AAA Target | Role |`);
    lines.push(`|-------|----------------|--------|------------|------|`);
    for (const f of advisory) {
      const label = f.selector || f.token_pair || "";
      lines.push(`| ${f.theme} | ${label} | ${f.actual_ratio} | ${f.aaa_required} | ${f.element_role} |`);
    }
    lines.push(``);
  }

  return lines.join("\n");
}

// ─── SELF-TEST MODE ───────────────────────────────────────────────────────────
// --self-test: gate-liveness proof. Exits 0 if all assertions pass; exits 1 with
// the failing assertion name + actual value if any fail.
// Run BEFORE main() so it never touches the filesystem or network.

if (process.argv.includes("--self-test")) {
  let failed = false;

  function assert(name, condition, actual) {
    if (!condition) {
      console.error(`FAILED: ${name} (actual: ${JSON.stringify(actual)})`);
      failed = true;
    }
  }

  // ── A. WCAG MATH UNIT ASSERTIONS ──────────────────────────────────────────

  // D-13: golden test — black on white must be exactly 21.00
  // D-12: sRGB compositing matches axe-core; see DESIGN-TOKENS.md for algorithm note.
  const golden = contrastRatio("#000000", "#ffffff");
  assert("golden test: contrastRatio('#000000','#ffffff') === 21.00", golden === 21.00, golden);

  // Proof 1: known-fail pair — #777777 on white is 4.48:1 (below AA 4.5)
  // Note: #767676 on white computes to 4.54:1 with strict WCAG sRGB gamma (passes AA by a
  // thin margin); #777777 is the correct "known borderline fail" example at 4.48:1.
  // Both #767676 and #595959 are included in the file as the reference pair names from the
  // validation spec; #767676 verifies the near-boundary behavior (4.54 < 5.0 guard below).
  const r777777 = contrastRatio("#777777", "#ffffff");
  assert("known-fail: contrastRatio('#777777','#ffffff') < 4.5", r777777 < 4.5, r777777);

  // #767676 reference value check — must be < 5.0 (near-boundary; actual ≈ 4.54:1)
  const r767676 = contrastRatio("#767676", "#ffffff");
  assert("near-boundary: contrastRatio('#767676','#ffffff') < 5.0", r767676 < 5.0, r767676);

  // Proof 2: known-pass pair — #595959 on white is ~7.0:1 (passes AA 4.5)
  const r595959 = contrastRatio("#595959", "#ffffff");
  assert("known-pass: contrastRatio('#595959','#ffffff') >= 4.5", r595959 >= 4.5, r595959);

  // Proof 5 structural: AA and AAA thresholds are distinct
  assert("THRESHOLDS.text.aa === 4.5", THRESHOLDS.text.aa === 4.5, THRESHOLDS.text.aa);
  assert("THRESHOLDS.text.aaa === 7.0", THRESHOLDS.text.aaa === 7.0, THRESHOLDS.text.aaa);

  // ── B. BEHAVIORAL END-TO-END SUB-PROOF (gate-liveness — the load-bearing proof) ─

  // Failing fixture: a known AA-fail finding
  const failingFindings = [
    {
      severity: "aa-fail",
      selector: ".self-test",
      fg: "#767676",
      bg: "#ffffff",
      actual_ratio: 4.48,
      required_ratio: 4.5,
      screen: "self-test",
      theme: "light",
      viewport: "desktop",
      element_role: "text",
      producer: "token",
      token_pair: "base-content/base-100",
    },
  ];

  const failReport = buildReport(failingFindings);
  // (a) summary.aa_fail must be 1
  assert(
    "failing fixture: summary.aa_fail === 1",
    failReport.summary.aa_fail === 1,
    failReport.summary.aa_fail
  );
  // (b) exit code must be 1 (aa_fail > 0 → exit 1)
  const failExitCode = failReport.summary.aa_fail > 0 ? 1 : 0;
  assert("failing fixture: exit code === 1", failExitCode === 1, failExitCode);

  // Passing fixture: an AAA-body advisory finding (does NOT increment aa_fail)
  const advisoryFindings = [
    {
      severity: "aaa-body-advisory",
      selector: ".self-test",
      fg: "#595959",
      bg: "#ffffff",
      actual_ratio: 7.0,
      required_ratio: 4.5,
      aaa_required: 7.0,
      screen: "self-test",
      theme: "light",
      viewport: "desktop",
      element_role: "text",
      producer: "token",
      token_pair: "base-content/base-100",
    },
  ];

  const passReport = buildReport(advisoryFindings);
  // (a) summary.aa_fail must be 0 — advisory finding does NOT increment aa_fail
  assert(
    "advisory fixture: summary.aa_fail === 0",
    passReport.summary.aa_fail === 0,
    passReport.summary.aa_fail
  );
  // (b) summary.aaa_advisory must be 1
  assert(
    "advisory fixture: summary.aaa_advisory === 1",
    passReport.summary.aaa_advisory === 1,
    passReport.summary.aaa_advisory
  );
  // (c) exit code must be 0
  const passExitCode = passReport.summary.aa_fail > 0 ? 1 : 0;
  assert("advisory fixture: exit code === 0", passExitCode === 0, passExitCode);

  // ── C. D-15 GUARD 2 STRUCTURAL FIXTURES (CR-01 / WR-02 / WR-03 regression locks) ─

  // CR-01: a single-line muted rule (color: mid-line, selector on the same line) MUST be
  // detected and validated against the manifest. Before the fix the `^\s*color:` anchor
  // skipped these entirely (false negative). Manifest matches → guard must NOT throw.
  const singleLineCss = `@layer ops {
  .ops-fixture-meta  { font-size: 12px; color: color-mix(in oklch, var(--color-base-content) 55%, transparent); }
}`;
  const singleLineManifest = [
    { selector: ".ops-fixture-meta", alpha: 0.55, fg_token: "base-content", bg_token: "base-100", role: "text" },
  ];
  let singleLineDetected = true;
  try {
    assertNoUntrackedMutedTokens(singleLineCss, singleLineManifest);
  } catch (err) {
    // Should NOT throw — the entry is tracked. A throw here means either it was not
    // detected (and reverse-check flagged the manifest entry as stale) or mis-attributed.
    singleLineDetected = false;
  }
  assert(
    "CR-01: single-line muted rule is detected & matched against manifest",
    singleLineDetected,
    singleLineDetected
  );

  // CR-01 (negative): an UNTRACKED single-line muted rule MUST throw (proves the guard
  // actually scans the line, not just that it tolerates it).
  let singleLineUntrackedThrew = false;
  try {
    assertNoUntrackedMutedTokens(singleLineCss, []);
  } catch (err) {
    singleLineUntrackedThrew = true;
  }
  assert(
    "CR-01: untracked single-line muted rule throws (guard scans the line)",
    singleLineUntrackedThrew,
    singleLineUntrackedThrew
  );

  // WR-02: a stale manifest entry (no corresponding app.css rule) MUST throw via the
  // reverse check, even when every CSS occurrence is tracked.
  let staleManifestThrew = false;
  try {
    assertNoUntrackedMutedTokens(singleLineCss, [
      ...singleLineManifest,
      { selector: ".ops-fixture-removed", alpha: 0.6, fg_token: "base-content", bg_token: "base-100", role: "text" },
    ]);
  } catch (err) {
    staleManifestThrew = true;
  }
  assert(
    "WR-02: stale manifest entry with no CSS hit throws (reverse lockstep)",
    staleManifestThrew,
    staleManifestThrew
  );

  // WR-03: a muted color: nested directly inside an @media block (no inner selector)
  // MUST fail loudly rather than silently bind to an outer selector.
  const nestedAtRuleCss = `@layer ops {
  @media (min-width: 800px) {
    color: color-mix(in oklch, var(--color-base-content) 55%, transparent);
  }
}`;
  let nestedAtRuleThrew = false;
  try {
    assertNoUntrackedMutedTokens(nestedAtRuleCss, []);
  } catch (err) {
    nestedAtRuleThrew = true;
  }
  assert(
    "WR-03: muted color: nested directly in @media fails loudly (no mis-attribution)",
    nestedAtRuleThrew,
    nestedAtRuleThrew
  );

  // WR-03: a muted color: inside a real selector that is itself nested in an @media block
  // MUST attribute to the inner selector, not the @media wrapper.
  const nestedSelectorCss = `@layer ops {
  @media (min-width: 800px) {
    .ops-fixture-nested { color: color-mix(in oklch, var(--color-base-content) 60%, transparent); }
  }
}`;
  let nestedSelectorOk = true;
  try {
    assertNoUntrackedMutedTokens(nestedSelectorCss, [
      { selector: ".ops-fixture-nested", alpha: 0.6, fg_token: "base-content", bg_token: "base-100", role: "text" },
    ]);
  } catch (err) {
    nestedSelectorOk = false;
  }
  assert(
    "WR-03: muted color: in a selector nested in @media attributes to the inner selector",
    nestedSelectorOk,
    nestedSelectorOk
  );

  // Phase 187: the theme blocks declare exactly daisyUI's 20 --color-* variables; the old second
  // primary tier (primary-strong) is gone. The fixture is built from the name list so it holds one
  // plain brand value and no retired identity literal (the deny-list scan in ui-tokens.test.mjs
  // reads this file).
  const COLOR_VARIABLES = [
    "base-100", "base-200", "base-300", "base-content",
    "primary", "primary-content", "secondary", "secondary-content",
    "accent", "accent-content", "neutral", "neutral-content",
    "info", "info-content", "success", "success-content",
    "warning", "warning-content", "error", "error-content",
  ];
  const themeBlockFixture = (names) => parseThemeBlocks(`@plugin "../vendor/daisyui-theme" {
    name: "light";
${names.map((name) => `    --color-${name}: #1e1220;`).join("\n")}
  }`);
  assert("Phase 187: the self-test fixture lists 20 --color-* variables", COLOR_VARIABLES.length === 20, COLOR_VARIABLES.length);

  let twentyTokensOk = true;
  try {
    assertTokenCount(themeBlockFixture(COLOR_VARIABLES));
  } catch (err) {
    twentyTokensOk = false;
  }
  assert("Phase 187: token guard accepts exactly 20 --color-* tokens", twentyTokensOk, twentyTokensOk);

  let twentyFirstThrew = false;
  try {
    assertTokenCount(themeBlockFixture([...COLOR_VARIABLES, "primary-strong"]));
  } catch (err) {
    twentyFirstThrew = true;
  }
  assert("Phase 187: token guard rejects a planted 21st --color-* token", twentyFirstThrew, twentyFirstThrew);

  let nineteenThrew = false;
  try {
    assertTokenCount(themeBlockFixture(COLOR_VARIABLES.filter((name) => name !== "info")));
  } catch (err) {
    nineteenThrew = true;
  }
  assert("Phase 187: token guard rejects a theme block with a missing --color-* token", nineteenThrew, nineteenThrew);

  // Phase 187: --ops-text-muted is opaque Muted Ink (light) and Muted Pale (dark), read from the
  // pinned brand tokens. A named alpha mix, a wrong hex or an eight-digit hex on it must fail.
  const mutedBrandFixture = {
    color: {
      secondary: {
        "muted-ink": { $value: { hex: "#5E5360" } },
        "muted-pale": { $value: { hex: "#BBAAC0" } },
      },
    },
  };
  const mutedThemesFixture = (light, dark) => ({
    light: { "ops-text-muted": light },
    dark: { "ops-text-muted": dark },
  });
  const expectMutedThrow = (label, themes) => {
    let threw = false;
    try {
      assertOpaqueMutedToken(themes, mutedBrandFixture);
    } catch (err) {
      threw = /D-15 Guard 2/.test(err.message);
    }
    assert(label, threw, threw);
  };

  let opaqueMutedOk = true;
  try {
    assertOpaqueMutedToken(mutedThemesFixture("#5e5360", "#bbaac0"), mutedBrandFixture);
  } catch (err) {
    opaqueMutedOk = false;
  }
  assert("Phase 187: opaque muted token accepts the Muted Ink and Muted Pale hexes", opaqueMutedOk, opaqueMutedOk);
  expectMutedThrow(
    "Phase 187: a planted alpha mix on --ops-text-muted fails the opaque guard",
    mutedThemesFixture("color-mix(in oklch, var(--color-base-content) 64%, transparent)", "#bbaac0")
  );
  expectMutedThrow(
    "Phase 187: a muted hex that is not the brand Muted Pale fails the opaque guard",
    mutedThemesFixture("#5e5360", "#bbaac1")
  );
  expectMutedThrow(
    "Phase 187: an eight-digit (alpha) hex on --ops-text-muted fails the opaque guard",
    mutedThemesFixture("#5e5360cc", "#bbaac0")
  );

  // WR-01: the threshold compare must use the UN-ROUNDED ratio. No discrete 6-hex
  // grayscale pair lands in the (4.495, 4.5) round-up window (confirmed empirically), so
  // we lock the two load-bearing invariants directly:
  //   (1) contrastRatioRaw returns full precision (NOT pre-rounded to 2 decimals).
  //   (2) evaluatePair classifies #777777/#ffffff (raw ≈ 4.478, rounds to 4.48) as
  //       aa-fail — and its DISPLAY actual_ratio is the rounded 4.48.
  const rawPrecision = contrastRatioRaw("#777777", "#ffffff");
  assert(
    "WR-01: contrastRatioRaw is full-precision (not pre-rounded)",
    Math.abs(rawPrecision - Math.round(rawPrecision * 100) / 100) > 0,
    rawPrecision
  );
  const wr01Finding = evaluatePair({
    fg: "#777777",
    bg: "#ffffff",
    role: "text",
    selector: ".wr01",
    theme: "light",
    tokenPair: "x",
  });
  assert(
    "WR-01: sub-4.5 raw ratio classified aa-fail; display value is rounded",
    wr01Finding.severity === "aa-fail" && wr01Finding.actual_ratio === 4.48,
    { severity: wr01Finding.severity, actual: wr01Finding.actual_ratio }
  );

  // ── D. PHASE 187 BRAND PAIR CHECKS (N-03, N-04, N-05): synthetic themes, planted failures ──
  // The themes below are small synthetic stand-ins (brand values, but written here so the cases never
  // depend on the live stylesheet). The accept case must pass; each planted defect must fail with a
  // message that names what broke.

  const brandLightFixture = {
    "color-base-100": "#ffffff",
    "color-base-200": "#f8f4f2",
    "color-base-content": "#1e1220",
    "color-primary": "#7b2d6b",
    "color-primary-content": "#ffffff",
    "ops-sunken": "#f0e9e6",
    "ops-selected": "#ebdfe7",
    "ops-text-muted": "#5e5360",
    "ops-control-edge": "#8a7a8e",
    "ops-status-failed": "#b0360b",
    "ops-status-retrying": "#8a5a00",
    "ops-status-pending": "#615765",
    "ops-status-clear": "#1d6b3c",
  };
  const brandDarkFixture = {
    "color-base-100": "#201624",
    "color-base-200": "#160e19",
    "color-base-content": "#f4edf3",
    "color-primary": "#d58bc4",
    "color-primary-content": "#160e19",
    "ops-sunken": "#110a14",
    "ops-selected": "#2b2130",
    "ops-text-muted": "#bbaac0",
    "ops-control-edge": "#8f7f94",
    "ops-status-failed": "#ff9a6b",
    "ops-status-retrying": "#e3b25c",
    "ops-status-pending": "#ab9bb0",
    "ops-status-clear": "#7fcb9a",
  };
  const brandThemes = () => ({ light: { ...brandLightFixture }, dark: { ...brandDarkFixture } });
  const fixtureBackdrops = ["color-base-200", "color-base-100", "ops-sunken", "ops-selected"];
  const brandMatrixFixture = {
    text: {
      min: 4.5,
      roles: ["color-base-content", "ops-text-muted", "color-primary", "ops-status-failed", "ops-status-retrying", "ops-status-pending", "ops-status-clear"],
      backdrops: fixtureBackdrops,
    },
    controlEdge: { property: "ops-control-edge", min: 3.0, backdrops: fixtureBackdrops, overlay: "color-base-100" },
    primaryNonText: { property: "color-primary", min: 3.0, backdrops: fixtureBackdrops },
    buttonLabels: {
      min: 4.5,
      pairs: [
        { fg: "color-primary-content", bg: "color-primary" },
        { fg: "color-base-content", bg: "color-base-100" },
      ],
    },
    statusHue: { failed: "ops-status-failed", retrying: "ops-status-retrying", minDegrees: 25 },
  };
  const bothThemes = (fg, bg) => ({ light: { fg, bg }, dark: { fg, bg } });
  const bindingsFixture = {
    body: bothThemes("color-base-content", "color-base-200"),
    caption: bothThemes("ops-text-muted", "color-base-100"),
    button: bothThemes("color-primary-content", "color-primary"),
  };
  // The fixture "book" prints exactly what the fixture bindings compute, so the accept case holds by
  // construction and any binding or color change that moves a ratio shows up as a mismatch.
  const publishedFixture = (themes, bindings) => ({
    color: {
      contrastPairs: Object.entries(bindings).map(([id, bound]) => ({
        id,
        minimum: 4.5,
        light: { contrast: Math.round(propertyRatio(themes.light, bound.light.fg, bound.light.bg) * 100) / 100 },
        dark: { contrast: Math.round(propertyRatio(themes.dark, bound.dark.fg, bound.dark.bg) * 100) / 100 },
      })),
    },
  });
  const expectFailure = (label, failures, pattern) => {
    const hit = failures.some((message) => pattern.test(message));
    assert(label, hit, failures);
  };

  // Accept cases: the unmodified synthetic themes pass every check.
  const acceptReport = {};
  assert("N-03: accept case has no failures", checkBrandTextPairs(brandThemes(), brandMatrixFixture.text, acceptReport).length === 0, null);
  assert("N-03: accept case computes 56 text pairs", acceptReport.pairs === 56, acceptReport.pairs);
  assert("N-04: accept case has no failures", checkNonTextPairs(brandThemes(), brandMatrixFixture).length === 0, null);
  assert(
    "N-05: accept case has no published-pair failures",
    checkPublishedPairs(brandThemes(), publishedFixture(brandThemes(), bindingsFixture), bindingsFixture).length === 0,
    null
  );
  const acceptHue = {};
  assert("N-05: accept case has no hue-gap failures", checkStatusHueGap(brandThemes(), brandMatrixFixture.statusHue, acceptHue).length === 0, null);
  assert("N-05: accept case hue gaps are at least 25 degrees", acceptHue.gaps.light >= 25 && acceptHue.gaps.dark >= 25, acceptHue.gaps);

  // Planted 1: one text role nudged below 4.5 on one backdrop.
  const weakText = brandThemes();
  weakText.light["ops-status-retrying"] = "#c9a24a";
  expectFailure(
    "N-03 planted: a text role below 4.5 fails and names the role, backdrop and theme",
    checkBrandTextPairs(weakText, brandMatrixFixture.text),
    /N-03 text pair ops-status-retrying on ops-selected \(light\)/
  );

  // Planted 2: Control Edge nudged below 3.0.
  const weakEdge = brandThemes();
  weakEdge.dark["ops-control-edge"] = "#4a3a4e";
  expectFailure(
    "N-04 planted: a Control Edge below 3.0 fails and names the control edge and theme",
    checkNonTextPairs(weakEdge, brandMatrixFixture),
    /N-04 control edge ops-control-edge on color-base-200 \(dark\)/
  );

  // Planted 3: a binding pointed at the wrong custom property, so the recomputed value differs.
  const wrongBinding = structuredClone(bindingsFixture);
  wrongBinding.caption.light.bg = "color-base-200";
  expectFailure(
    "N-05 planted: a binding on the wrong custom property fails because the pair value differs",
    checkPublishedPairs(brandThemes(), publishedFixture(brandThemes(), bindingsFixture), wrongBinding),
    /N-05 pair caption \(light\).*the book publishes/
  );

  // Planted 4: a published pair that has no binding.
  const unboundBook = publishedFixture(brandThemes(), bindingsFixture);
  unboundBook.color.contrastPairs.push({ id: "extra-pair", minimum: 4.5, light: { contrast: 7 }, dark: { contrast: 7 } });
  expectFailure(
    "N-05 planted: a published pair with no binding fails",
    checkPublishedPairs(brandThemes(), unboundBook, bindingsFixture),
    /N-05 published pair extra-pair has no binding/
  );

  // Planted 5: Retrying rotated to within 25 degrees of Failed.
  const closeHue = brandThemes();
  closeHue.light["ops-status-retrying"] = "#a8450c";
  const closeHueReport = {};
  expectFailure(
    "N-05 planted: a Retrying hue within 25 degrees of Failed fails and names the theme",
    checkStatusHueGap(closeHue, brandMatrixFixture.statusHue, closeHueReport),
    /N-05 status hue gap between ops-status-failed and ops-status-retrying \(light\)/
  );
  assert("N-05 planted: the rotated hue gap is under 25 degrees", closeHueReport.gaps.light < 25, closeHueReport.gaps);

  // ── E. PHASE 187 STYLESHEET BANS (N-12): synthetic stylesheets, planted failures ──
  // The accept stylesheet holds every kept use of alpha (container border, shadow, scrim, scroll-edge
  // gradient) plus a commented-out tint, and must pass. Each planted tint must fail with a message
  // that names the line it sits on.

  const keptAlphaCss = `@layer components {
  .ops-fixture-border { border: 1px solid color-mix(in oklch, var(--color-base-content) 10%, transparent); }
  .ops-fixture-shadow { box-shadow: 0 1px 2px color-mix(in oklch, var(--color-base-content) 8%, transparent); }
  .ops-fixture-scrim { background: color-mix(in oklch, var(--color-black) 50%, transparent); }
  .ops-fixture-edge { background: linear-gradient(to right, color-mix(in oklch, var(--color-base-100) 94%, transparent), transparent); }
  /* A comment may name color-mix(in oklch, var(--color-primary) 14%, transparent) without failing. */
}`;
  assert(
    "N-12: base-color mixes (borders, shadows, scrims, gradients) and a commented tint pass",
    checkRetiredColorMixes(keptAlphaCss).length === 0,
    checkRetiredColorMixes(keptAlphaCss)
  );

  expectFailure(
    "N-12 planted: a primary tint fails and names its line",
    checkRetiredColorMixes(`@layer components {
  .ops-fixture-tint { background: color-mix(in oklch, var(--color-primary) 14%, transparent); }
}`),
    /N-12 color-mix at app\.css line 2 mixes a primary, secondary or status color/
  );
  expectFailure(
    "N-12 planted: a status mix split over several lines fails",
    checkRetiredColorMixes(`.ops-fixture-border {
  border-color: color-mix(
    in oklch,
    var(--color-error) 48%,
    var(--color-base-content) 10%
  );
}`),
    /N-12 color-mix at app\.css line 2 /
  );
  expectFailure(
    "N-12 planted: a tint of a status text token fails",
    checkRetiredColorMixes(".ops-fixture-tint { background: color-mix(in oklch, var(--ops-status-failed) 12%, transparent); }"),
    /N-12 color-mix at app\.css line 1 /
  );
  expectFailure(
    "N-12 planted: a tint nested inside another mix fails",
    checkRetiredColorMixes(".ops-fixture-tint { background: color-mix(in oklch, color-mix(in oklch, var(--color-warning) 20%, white) 50%, transparent); }"),
    /N-12 color-mix at app\.css line 1 /
  );
  expectFailure(
    "N-12 planted: a relative-color tint of the primary fails",
    checkRetiredColorMixes(".ops-fixture-tint { background: rgb(from var(--color-primary) r g b / 14%); }"),
    /N-12 relative color at app\.css line 1 /
  );

  if (failed) {
    process.exit(1);
  }
  console.log("self-test passed");
  process.exit(0);
}

// ─── D-15 LOCKSTEP GUARDS ─────────────────────────────────────────────────────

// Guard 1 — Token count assertion
// daisyUI requires exactly 20 --color-* variables per theme (4 base + 16 semantic). Phase 187
// locks the count at 20 and drops the old second primary tier (primary-strong), so a 21st
// variable fails here just as a missing one does. The vendor daisyui-theme plugin injects
// non-color tokens (--radius-*, --size-*, --border, --depth, --noise, etc.) that are NOT
// --color-* prefixed and are not counted.
function assertTokenCount(blocks) {
  for (const [theme, tokens] of Object.entries(blocks)) {
    const count = Object.keys(tokens).length;
    if (count !== 20) {
      throw new Error(
        `D-15 Guard 1: expected 20 --color-* tokens in "${theme}" theme block, got ${count}.\n` +
          `Tokens found: ${Object.keys(tokens).join(", ")}\n` +
          `Note: the lock is 20 (daisyUI's color variables); --radius-*, ` +
          `--size-*, --border, --depth, --noise are non-color tokens injected by the ` +
          `daisyui-theme plugin and are NOT --color-* prefixed.`
      );
    }
  }
}

// Guard 2 (named token) — --ops-text-muted is opaque
// Phase 187: `var(--ops-text-muted)` is plain text color, not an alpha mix. In each theme the
// property must be a six-digit hex equal to the pinned brand token (Muted Ink on light, Muted Pale on
// dark), so the N-03 muted pairs on four backdrops are computed from real, opaque colors.
function brandHexAt(brandTokens, tokenPath) {
  let node = brandTokens;
  for (const segment of tokenPath.split(".")) {
    if (node === null || typeof node !== "object" || !Object.hasOwn(node, segment)) {
      throw new Error(`Unknown brand token path: ${tokenPath}`);
    }
    node = node[segment];
  }
  const hex = node?.$value?.hex;
  if (typeof hex !== "string" || !/^#[0-9a-f]{6}$/i.test(hex)) throw new Error(`Brand token ${tokenPath} has no $value.hex`);
  return hex.toLowerCase();
}

function assertOpaqueMutedToken(themes, brandTokens) {
  // Local on purpose: the --self-test block runs before module-level consts are initialized.
  const brandPaths = { light: "color.secondary.muted-ink", dark: "color.secondary.muted-pale" };
  for (const [theme, tokenPath] of Object.entries(brandPaths)) {
    const value = themes[theme]?.["ops-text-muted"];
    if (typeof value !== "string" || !/^#[0-9a-f]{6}$/i.test(value)) {
      throw new Error(
        `D-15 Guard 2: --ops-text-muted in the "${theme}" theme must be an opaque six-digit hex, got ${String(value)}.\n` +
          `  Text never uses alpha (no color-mix, rgba or eight-digit hex).`
      );
    }
    const expected = brandHexAt(brandTokens, tokenPath);
    if (value.toLowerCase() !== expected) {
      throw new Error(
        `D-15 Guard 2: --ops-text-muted in the "${theme}" theme is ${value}, expected ${expected} (${tokenPath} in brand/tokens.json).`
      );
    }
  }
}

// Guard 2 (direct mixes) — Untracked muted text check
// Find all `color:` properties in app.css that use color-mix(in oklch, var(--color-base-content) NN%, transparent).
// Only the `color:` CSS property is checked — NOT border-color, background, box-shadow, --shadow-*, fill.
// Fail if any (selector, alpha) pair is NOT present in the MUTED_PAIRS manifest. Plan 08 converts the
// remaining direct declarations and retires the manifest.
function assertNoUntrackedMutedTokens(cssText, mutedPairs) {
  // Find all color-mix muted text patterns in the form:
  //   color: color-mix(in oklch, var(--color-base-content) NN%, transparent)
  // Strategy: line-by-line scan. Track the most recent selector line.
  // A selector line is one that ends with `{` and is not a @-rule or comment.
  const lines = cssText.split("\n");
  // CR-01: match `color: color-mix(...)` ANYWHERE on the line, not just at line start.
  // The leading `(?:^\s*|[{;]\s*)` group requires the property to be either at the start
  // of the line (with optional indentation — the common multi-line declaration case) OR
  // immediately after a `{` (single-line rule like
  // `.ops-text-meta { ...; color: color-mix(...); }`) or a `;` (multiple decls on one
  // line). The `[{;]` boundary (and the `\b`-less start anchor) excludes
  // `border-color:`/`background-color:` because those have a word char (`r`/`d`)
  // immediately before `color:`, not start-of-line, `{`, or `;`.
  const colorMixRe = /(?:^\s*|[{;]\s*)color:\s*color-mix\(in oklch,\s*var\(--color-base-content\)\s*(\d+)%,\s*transparent\)/;
  // We need to find the selector for each match. Walk backwards from the match line.
  // Allow leading whitespace (CSS is often indented within @layer blocks).
  // Must start with an alphanumeric, dot, hash, colon, or bracket — NOT @, /, or *
  const selectorRe = /^\s*([\.\#\:\[\&][^@{]*|[a-zA-Z][^@{]*)\s*\{/;
  // CR-01: detect a selector declared on the SAME line as the muted `color:` (single-line
  // rule). Capture the text before the first `{`, excluding @-rules (which start with `@`).
  const sameLineSelectorRe = /^\s*([^{}@]+?)\s*\{/;

  const found = [];

  for (let i = 0; i < lines.length; i++) {
    const colorMatch = colorMixRe.exec(lines[i]);
    if (!colorMatch) continue;

    const alphaPercent = parseInt(colorMatch[1], 10);
    const alpha = alphaPercent / 100;

    // CR-01: if the matching line itself opens a rule (contains a `{` before the match),
    // the selector is on this line — use it directly instead of walking backwards.
    let selector = null;
    const braceIdx = lines[i].indexOf("{");
    const colorIdx = lines[i].indexOf("color:");
    if (braceIdx !== -1 && braceIdx < colorIdx) {
      const sameLineMatch = sameLineSelectorRe.exec(lines[i]);
      if (sameLineMatch) {
        selector = sameLineMatch[1].trim();
      }
    }

    // Otherwise, find the nearest enclosing selector by walking backwards.
    // WR-03: track brace depth so the walk binds to the INNERMOST still-open rule and
    // does not mis-attribute a muted color nested inside an @media (or other at-rule)
    // wrapper. We count `}` (closing a sibling/inner rule we've already passed) and `{`
    // while scanning upward; the owning selector is the first selector-opening line we
    // reach once depth returns to the level of the match.
    if (!selector) {
      let depth = 0;
      for (let j = i - 1; j >= 0; j--) {
        const line = lines[j];
        // Count braces on this line (closing braces seen on the way up mean we passed an
        // already-closed inner block; opening braces mean we've stepped out of one).
        const opens = (line.match(/\{/g) || []).length;
        const closes = (line.match(/\}/g) || []).length;

        // A line that opens a rule at the current depth level is the owning selector,
        // but only if we are not currently "inside" a deeper sibling block (depth > 0).
        if (depth === 0) {
          const selectorMatch = selectorRe.exec(line);
          // WR-03: reject at-rule wrappers (@media/@supports/@layer). If the nearest
          // open block at depth 0 is an at-rule rather than a real selector, the simple
          // walk cannot attribute the muted color — fail loudly rather than bind it to
          // the wrong (outer) selector.
          const atRuleMatch = /^\s*@[\w-]+[^{}]*\{/.test(line);
          if (atRuleMatch && opens > closes) {
            throw new Error(
              `D-15 Guard 2: muted color: at app.css line ${i + 1} is nested directly ` +
                `inside an at-rule block (e.g. @media) at line ${j + 1}; the selector ` +
                `walk cannot attribute it. Refactor so the muted rule has an explicit ` +
                `selector, or extend the guard to resolve into at-rule wrappers.`
            );
          }
          if (selectorMatch && opens > closes) {
            selector = selectorMatch[1].trim();
            break;
          }
        }

        // Update depth for the next line up: each `}` we passed opened a level going up,
        // each `{` closed one. (We move upward, so braces invert relative to top-down.)
        depth += closes - opens;
        if (depth < 0) depth = 0;
      }
    }

    if (!selector) {
      throw new Error(
        `D-15 Guard 2: found untracked muted color: pattern at line ${i + 1} ` +
          `(alpha ${alphaPercent}%) but could not determine its selector.`
      );
    }

    found.push({ selector, alpha, lineNumber: i + 1 });
  }

  // Check each found (selector, alpha) pair is in the manifest
  for (const { selector, alpha, lineNumber } of found) {
    const inManifest = mutedPairs.some(
      (pair) => pair.selector === selector && pair.alpha === alpha
    );
    if (!inManifest) {
      throw new Error(
        `D-15 Guard 2: untracked muted text token!\n` +
          `  Selector: "${selector}" at app.css line ${lineNumber}\n` +
          `  Alpha: ${alpha} (${Math.round(alpha * 100)}%)\n` +
          `  This (selector, alpha) pair is NOT present in contrast-pairs.mjs.\n` +
          `  Add an entry for "${selector}" with alpha: ${alpha} to scrypath_ops/assets/css/contrast-pairs.mjs.\n` +
          `  (D-15: the lockstep guard ensures all muted text tokens are contrast-gated.)`
      );
    }
  }

  // WR-02: reverse lockstep — every non-decorative manifest entry must correspond to an
  // actual `color: color-mix(...)` occurrence found in app.css (at the exact alpha
  // tolerance). This catches stale/renamed/removed manifest entries that no longer match
  // any CSS rule, which the forward (css→manifest) scan above cannot detect.
  for (const pair of mutedPairs) {
    if (pair.role === "decorative") continue;
    const hasCssHit = found.some(
      (f) => f.selector === pair.selector && f.alpha === pair.alpha
    );
    if (!hasCssHit) {
      throw new Error(
        `D-15 Guard 2 (reverse): stale manifest entry!\n` +
          `  Selector: "${pair.selector}" alpha: ${pair.alpha} (${Math.round(pair.alpha * 100)}%)\n` +
          `  This entry is in contrast-pairs.mjs but no matching ` +
          `color: color-mix(in oklch, var(--color-base-content) ${Math.round(pair.alpha * 100)}%, transparent) rule exists in app.css.\n` +
          `  Remove the stale entry from scrypath_ops/assets/css/contrast-pairs.mjs, or ` +
          `restore the corresponding rule in app.css.\n` +
          `  (D-15: the lockstep guard is bidirectional — manifest and CSS must agree both ways.)`
      );
    }
  }
}

// ─── PAIR EVALUATION ──────────────────────────────────────────────────────────

function passesAA(raw, role) {
  if (!THRESHOLDS[role] || !Number.isFinite(raw) || raw < 1 || raw > 21) throw new Error("Invalid contrast ratio or role");
  return raw >= THRESHOLDS[role].aa;
}

// Evaluate a single pair and return a finding object (D-18 schema)
function evaluatePair({ fg, bg, role, selector, theme, tokenPair }) {
  const thresholds = THRESHOLDS[role];
  if (!thresholds) throw new Error(`Invalid contrast role ${role}`);
  // WR-01: compare the UN-ROUNDED ratio against the threshold; round only for display.
  const raw = contrastRatioRaw(fg, bg);
  const passAA = passesAA(raw, role);
  const passAAA = raw >= thresholds.aaa;
  const actual = Math.round(raw * 100) / 100; // display value only

  let severity;
  if (!passAA) {
    severity = "aa-fail";
  } else if (role === "text" && !passAAA) {
    severity = "aaa-body-advisory";
  } else {
    severity = "pass";
  }

  return {
    severity,
    producer: "token",
    theme,
    selector: selector || null,
    token_pair: tokenPair,
    fg,
    bg,
    actual_ratio: actual,
    raw_ratio: raw,
    required_ratio: thresholds.aa,
    aaa_required: thresholds.aaa,
    pass_aa: passAA,
    aaa_body_status: role === "text" && !passAAA ? "advisory" : "pass",
    element_role: role,
    screen: "token-check",
    viewport: "n/a",
    state: "static",
    shot: null,
    fix_class: "token",
    scope: "systemic", // token-checker findings are systemic by definition (D-19)
    evidence: `contrastRatio(${fg}, ${bg}) = ${actual}`,
  };
}

// ─── PHASE 187 BRAND PAIR CHECKS (A11Y-01: N-03, N-04, N-05) ─────────────────
//
// Each check reads the two theme blocks' custom properties (the shape readThemeProperties returns:
// { light: { "color-base-100": "#ffffff", ... }, dark: { ... } }) and returns a list of failure
// strings; an empty list is a pass. Ratios are compared unrounded with `>=`, so a ratio of 4.4996
// never passes as 4.50. Pair names come from contrast-pairs.mjs as custom property names, never as
// hex, so a recolor changes the verdict. These are function declarations that use only their own
// arguments, because the --self-test block runs before module-level constants are initialized.

function resolveThemeColor(properties, name) {
  return colorValue(`var(--${name})`, properties);
}

function propertyRatio(properties, fgName, bgName) {
  return contrastRatioRaw(resolveThemeColor(properties, fgName), resolveThemeColor(properties, bgName));
}

// N-03: every text role on every backdrop in both themes (7 x 4 x 2 = 56 pairs) at 4.5:1 or better.
// `report` (optional) receives { pairs, thinnest } so the normal run can print the thinnest pair.
function checkBrandTextPairs(themes, spec, report = {}) {
  const failures = [];
  let pairs = 0;
  let thinnest = null;
  for (const [theme, properties] of Object.entries(themes)) {
    for (const backdrop of spec.backdrops) {
      for (const role of spec.roles) {
        const raw = propertyRatio(properties, role, backdrop);
        pairs += 1;
        if (!thinnest || raw < thinnest.raw) thinnest = { raw, role, backdrop, theme };
        if (!(raw >= spec.min)) {
          failures.push(`N-03 text pair ${role} on ${backdrop} (${theme}) is ${raw.toFixed(4)}, below ${spec.min}`);
        }
      }
    }
  }
  if (pairs !== 56) failures.push(`N-03 expected 56 text pairs (7 roles x 4 backdrops x 2 themes), computed ${pairs}`);
  report.pairs = pairs;
  report.thinnest = thinnest;
  return failures;
}

// N-04: Control Edge on the four backdrops and the overlay surface at 3:1, the primary on the four
// backdrops at 3:1 (focus ring, selection line, link), and the button labels at 4.5:1.
function checkNonTextPairs(themes, matrix, report = {}) {
  const failures = [];
  let pairs = 0;
  const check = (label, theme, properties, fg, bg, min) => {
    const raw = propertyRatio(properties, fg, bg);
    pairs += 1;
    if (!(raw >= min)) failures.push(`N-04 ${label} ${fg} on ${bg} (${theme}) is ${raw.toFixed(4)}, below ${min}`);
  };
  for (const [theme, properties] of Object.entries(themes)) {
    const edge = matrix.controlEdge;
    for (const bg of [...edge.backdrops, edge.overlay]) check("control edge", theme, properties, edge.property, bg, edge.min);
    const primary = matrix.primaryNonText;
    for (const bg of primary.backdrops) check("primary", theme, properties, primary.property, bg, primary.min);
    for (const { fg, bg } of matrix.buttonLabels.pairs) check("button label", theme, properties, fg, bg, matrix.buttonLabels.min);
  }
  report.pairs = pairs;
  return failures;
}

// N-05: the pairs published in brand/brand.json (color.contrastPairs), by pair id. Each published
// pair must have exactly one binding naming the custom properties that carry its two colors in each
// theme; the ratio recomputed from those resolved properties must equal the book's two-decimal value
// and meet the pair's own minimum. A binding that names no published pair fails as well.
function checkPublishedPairs(themes, brandJson, bindings, report = {}) {
  const published = brandJson?.color?.contrastPairs;
  if (!Array.isArray(published) || published.length === 0) return ["N-05 brand/brand.json has no color.contrastPairs"];
  const failures = [];
  const ids = published.map((pair) => pair.id);
  if (new Set(ids).size !== ids.length) failures.push("N-05 brand/brand.json repeats a contrast pair id");
  for (const id of Object.keys(bindings)) {
    if (!ids.includes(id)) failures.push(`N-05 binding ${id} names no pair published in brand/brand.json`);
  }
  let pairs = 0;
  for (const pair of published) {
    const binding = bindings[pair.id];
    if (!binding) {
      failures.push(`N-05 published pair ${pair.id} has no binding in PUBLISHED_PAIR_BINDINGS`);
      continue;
    }
    for (const [theme, properties] of Object.entries(themes)) {
      const bound = binding[theme];
      const book = pair[theme];
      if (!bound || !book || !Number.isFinite(book.contrast)) {
        failures.push(`N-05 pair ${pair.id} (${theme}) has no binding or no published ratio`);
        continue;
      }
      const raw = propertyRatio(properties, bound.fg, bound.bg);
      const rounded = Math.round(raw * 100) / 100;
      pairs += 1;
      if (rounded !== book.contrast) {
        failures.push(`N-05 pair ${pair.id} (${theme}): ${bound.fg} on ${bound.bg} is ${rounded}, the book publishes ${book.contrast}`);
      }
      if (Number.isFinite(pair.minimum) && !(raw >= pair.minimum)) {
        failures.push(`N-05 pair ${pair.id} (${theme}) is ${raw.toFixed(4)}, below its published minimum ${pair.minimum}`);
      }
    }
  }
  report.pairs = pairs;
  report.published = published.length;
  return failures;
}

// CIELAB hue angle in degrees [0, 360) of a six-digit hex (sRGB, D65 white).
function labHueDegrees(hex) {
  const [r, g, b] = [1, 3, 5].map((i) => toLinear(parseInt(hex.slice(i, i + 2), 16) / 255));
  const x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047;
  const y = 0.2126729 * r + 0.7151522 * g + 0.072175 * b;
  const z = (0.0193339 * r + 0.119192 * g + 0.9503041 * b) / 1.08883;
  const f = (t) => (t > 216 / 24389 ? Math.cbrt(t) : (24389 / 27 * t + 16) / 116);
  const a = 500 * (f(x) - f(y));
  const bStar = 200 * (f(y) - f(z));
  const degrees = (Math.atan2(bStar, a) * 180) / Math.PI;
  return degrees < 0 ? degrees + 360 : degrees;
}

// N-05: the Failed and Retrying text colors stay at least `minDegrees` apart in CIELAB hue angle in
// each theme, so the pair never collapses into one color for anyone who cannot rely on the word and
// the icon shape alone.
function checkStatusHueGap(themes, spec, report = {}) {
  const failures = [];
  report.gaps = {};
  for (const [theme, properties] of Object.entries(themes)) {
    const failed = labHueDegrees(resolveThemeColor(properties, spec.failed));
    const retrying = labHueDegrees(resolveThemeColor(properties, spec.retrying));
    const raw = Math.abs(failed - retrying);
    const gap = Math.min(raw, 360 - raw);
    report.gaps[theme] = gap;
    if (!(gap >= spec.minDegrees)) {
      failures.push(
        `N-05 status hue gap between ${spec.failed} and ${spec.retrying} (${theme}) is ${gap.toFixed(1)} degrees, below ${spec.minDegrees}`
      );
    }
  }
  return failures;
}

// ─── PHASE 187 STYLESHEET BANS (A11Y-01, SKIN-05: N-12) ──────────────────────
//
// These read stylesheet text only and return failure strings (an empty list is a pass). They are
// function declarations that use only their own arguments, because the --self-test block runs
// before module-level constants are initialized.

function oneLine(text) {
  return text.replace(/\s+/g, " ").trim();
}

function lineOf(css, index) {
  return css.slice(0, index).split("\n").length;
}

// Every call of one of `names` with its balanced parentheses: [{ text, index }]. Nested calls are
// reported separately, so a tint hidden inside another function is still found.
function cssFunctionCalls(css, names) {
  const calls = [];
  const opener = new RegExp(`(?<![\\w-])(?:${names.join("|")})\\(`, "g");
  let match;
  while ((match = opener.exec(css))) {
    let depth = 1;
    let end = match.index + match[0].length;
    for (; end < css.length && depth > 0; end += 1) {
      if (css[end] === "(") depth += 1;
      else if (css[end] === ")") depth -= 1;
    }
    calls.push({ text: css.slice(match.index, end), index: match.index });
  }
  return calls;
}

// N-12: no color expression mixes the primary, the secondary or a status color. Those mixes were the
// Plum and status tints (fills, borders, glows) the re-skin retires: a tinted fill is `--ops-selected`
// or `--ops-sunken`, a tinted border is `--ops-control-edge` or `--color-base-300`. A mix of the base
// colors (container borders, shadows, scrims, scroll-edge gradients) carries no retired color and
// passes. Relative color syntax (`rgb(from var(--color-primary) r g b / 14%)`) is the same tint
// written another way, so it is held to the same rule.
function checkRetiredColorMixes(cssText) {
  const css = stripCssComments(cssText);
  const retired = /var\(\s*--(?:color-(?:primary|secondary|info|success|warning|error)(?:-content)?|ops-status-(?:failed|retrying|pending|clear)|ops-(?:warning|error)-text)\s*[,)]/;
  const failures = [];
  for (const call of cssFunctionCalls(css, ["color-mix"])) {
    if (retired.test(call.text)) {
      failures.push(`N-12 color-mix at app.css line ${lineOf(css, call.index)} mixes a primary, secondary or status color: ${oneLine(call.text)}`);
    }
  }
  for (const call of cssFunctionCalls(css, ["rgb", "hsl", "hwb", "lab", "lch", "oklab", "oklch", "color"])) {
    if (/^[\w-]+\(\s*from\s/.test(call.text) && retired.test(call.text)) {
      failures.push(`N-12 relative color at app.css line ${lineOf(css, call.index)} derives a tint from a primary, secondary or status color: ${oneLine(call.text)}`);
    }
  }
  return failures;
}

// ─── MAIN FUNCTION ────────────────────────────────────────────────────────────

// Bounded source reader: declarations are data, never evaluated as code.
function readThemeProperties(css) {
  const themes = {};
  for (const body of themePluginBodies(css)) {
    const declarations = cssDeclarations(body);
    const name = declarations.map((declaration) => /^name:\s*"(light|dark)"$/.exec(declaration)?.[1]).find(Boolean);
    if (!name || themes[name]) throw new Error("Missing, duplicate or unsupported theme name");
    const props = {};
    for (const declaration of declarations) {
      const entry = declaration.match(/^(--[\w-]+)\s*:\s*(.+)$/);
      if (!entry) continue;
      const key = entry[1].slice(2);
      if (Object.hasOwn(props, key)) throw new Error(`Duplicate ${name} token ${key}`);
      props[key] = entry[2].trim();
    }
    for (const [key, value] of Object.entries(props)) {
      if (key.startsWith("color-") && !/^#[0-9a-f]{6}$/i.test(value)) throw new Error(`Unsupported ${name} color ${key}: ${value}`);
    }
    themes[name] = props;
  }
  if (Object.keys(themes).sort().join(",") !== "dark,light") throw new Error("Both light and dark themes are required");
  return themes;
}

function colorValue(expression, properties, background, seen = []) {
  if (typeof expression !== "string") throw new Error(`Missing required color ${seen.join(" -> ")}`);
  if (/^#[0-9a-f]{6}$/i.test(expression)) return expression;
  const reference = expression.match(/^var\(--([\w-]+)\)$/);
  if (reference) {
    const key = reference[1];
    if (seen.includes(key) || seen.length >= 16) throw new Error(`Cyclic color reference ${key}`);
    return colorValue(properties[key], properties, background, [...seen, key]);
  }
  const alpha = expression.match(/^color-mix\(in (?:oklch|srgb),\s*var\(--([\w-]+)\)\s*(\d+(?:\.\d+)?)%,\s*transparent\)$/);
  if (alpha && background && Number(alpha[2]) <= 100) {
    return compositeAlpha(colorValue(`var(--${alpha[1]})`, properties, background, seen), Number(alpha[2]) / 100, background);
  }
  throw new Error(`Unsupported or unresolved color: ${expression}`);
}

function sourceRules(css) {
  return [...css.replace(/\/\*[\s\S]*?\*\//g, "").matchAll(/([^{}]+)\{([^{}]*)\}/g)].map(match => {
    const declarations = {};
    for (const text of match[2].split(";")) {
      const entry = text.match(/^\s*([\w-]+)\s*:\s*(.*?)\s*$/s);
      if (!entry) continue;
      if (Object.hasOwn(declarations, entry[1]) && /^(?:outline(?:-[\w-]+)?|box-shadow|background(?:-color)?)$/.test(entry[1])) throw new Error(`Duplicate declaration ${entry[1]} in ${match[1].trim()}`);
      declarations[entry[1]] = entry[2].replace(/\s+/g, " ");
    }
    return { selector: match[1].trim().replace(/\s+/g, " "), declarations };
  });
}

function evaluateLiveBindings(css, themes, focusBindings, surfaceBindings) {
  if (!Array.isArray(focusBindings) || !focusBindings.length || !Array.isArray(surfaceBindings) || !surfaceBindings.length) throw new Error("Required focus/surface bindings are empty");
  const rules = sourceRules(css);
  const actual = rules.filter(r => r.selector.includes(":focus") && Object.keys(r.declarations).some(k => /^(?:outline(?:-color|-width|-style)?|box-shadow)$/.test(k)));
  const expected = new Map(focusBindings.map(b => [b.selector, b]));
  if (expected.size !== focusBindings.length || actual.length !== expected.size || new Set(actual.map(r => r.selector)).size !== actual.length) throw new Error("Stale or duplicate focus binding inventory");
  for (const rule of actual) {
    const binding = expected.get(rule.selector);
    if (!binding) throw new Error(`Unbound focus declaration ${rule.selector}`);
    const d = rule.declarations;
    const suppressedSelectors = [".ops-cmdk__input:focus", ".ops-sheet__panel:focus", ".ops-sheet__header h2:focus"];
    if (Boolean(binding.suppressed) !== suppressedSelectors.includes(rule.selector)) throw new Error(`Invalid focus role ${rule.selector}`);
    if (binding.suppressed) {
      if (d.outline !== "none" || d["box-shadow"]) throw new Error(`Changed focus suppression ${rule.selector}`);
    } else if (d.outline !== "2px solid var(--color-primary)" || d["outline-offset"] !== binding.offset || d["box-shadow"] || d["outline-color"] || d["outline-style"] || d["outline-width"]) {
      throw new Error(`Stale focus binding ${rule.selector}: ${JSON.stringify(d)}`);
    }
  }
  for (const binding of surfaceBindings) {
    const matching = rules.filter(r => r.selector === binding.selector && (r.declarations.background || r.declarations["background-color"]));
    const property = binding.property || "background";
    const otherProperty = property === "background" ? "background-color" : "background";
    if (matching.length !== 1 || matching[0].declarations[property] !== (binding.expression || `var(--${binding.background})`) || matching[0].declarations[otherProperty]) throw new Error(`Stale focus background binding ${binding.selector}`);
  }
  const findings = [];
  // Opaque shell floors and actual resting/selected/menu fills. Each theme's
  // live token values are resolved; the muted floor is not applied to base-300,
  // where the theme toggle uses full base-content, not muted text.
  const surfaces = ["ops-bg", "ops-surface-1", "ops-sunken", "ops-selected", "ops-selection", "ops-theme-selection", "color-base-100", "color-base-200"];
  for (const [theme, properties] of Object.entries(themes)) {
    for (const surface of [...surfaces, "color-base-300"]) {
      const bg = colorValue(`var(--${surface})`, properties);
      for (const binding of focusBindings.filter(b => !b.suppressed)) {
        findings.push(evaluatePair({fg: colorValue("var(--color-primary)", properties), bg, role: "ui", selector: binding.selector, theme, tokenPair: `focus/${surface}`}));
      }
      for (const foreground of ["color-base-content", ...(surfaces.includes(surface) ? ["ops-text-muted", "ops-warning-text", "ops-error-text"] : [])]) {
        findings.push(evaluatePair({fg: colorValue(`var(--${foreground})`, properties, bg), bg, role: "text", selector: null, theme, tokenPair: `${foreground}/${surface}`}));
      }
    }
  }
  return findings.filter(f => f.severity !== "pass");
}

async function main() {
  // Load app.css
  let cssText;
  try {
    cssText = await readFile(APP_CSS_PATH, "utf8");
  } catch (err) {
    throw new Error(`Could not read app.css at ${APP_CSS_PATH}: ${err.message}`);
  }

  // Load contrast-pairs.mjs manifest (D-11)
  let mutedPairs;
  let focusBindings;
  let surfaceBindings;
  let pairMatrix;
  let publishedBindings;
  try {
    const manifest = await import(PAIRS_PATH);
    mutedPairs = manifest.MUTED_PAIRS;
    focusBindings = manifest.FOCUS_BINDINGS;
    surfaceBindings = manifest.SURFACE_BINDINGS;
    pairMatrix = manifest.BRAND_PAIR_MATRIX;
    publishedBindings = manifest.PUBLISHED_PAIR_BINDINGS;
    if (!Array.isArray(mutedPairs)) {
      throw new Error("MUTED_PAIRS export is not an array");
    }
    if (!pairMatrix || typeof pairMatrix !== "object" || !publishedBindings || typeof publishedBindings !== "object") {
      throw new Error("BRAND_PAIR_MATRIX and PUBLISHED_PAIR_BINDINGS exports are required");
    }
  } catch (err) {
    throw new Error(`Could not load contrast-pairs.mjs at ${PAIRS_PATH}: ${err.message}`);
  }

  const properties = readThemeProperties(cssText);
  if (new Set(mutedPairs.map(p => p.selector)).size !== mutedPairs.length) throw new Error("Duplicate muted pair selector");
  if (!mutedPairs.length) throw new Error("Required muted pairs are empty");
  for (const pair of mutedPairs) {
    if (pair.fg_token !== "base-content" || (pair.selector === ".ops-trail__sep" ? pair.role !== "decorative" : pair.role !== "text") || !["text", "large", "ui", "decorative"].includes(pair.role) || !Number.isFinite(pair.alpha) || pair.alpha < 0 || pair.alpha > 1 || typeof pair.selector !== "string") throw new Error("Malformed muted pair role/alpha/selector");
  }

  // (a) Parse theme blocks
  const blocks = parseThemeBlocks(cssText);
  const themeNames = Object.keys(blocks);
  if (themeNames.length === 0) {
    throw new Error("No daisyUI theme blocks found in app.css");
  }

  // (b) D-15 guards
  assertTokenCount(blocks);
  let brandTokens;
  try {
    brandTokens = JSON.parse(await readFile(BRAND_TOKENS_PATH, "utf8"));
  } catch (err) {
    throw new Error(`Could not read the pinned brand tokens at ${BRAND_TOKENS_PATH}: ${err.message}`);
  }
  assertOpaqueMutedToken(properties, brandTokens);
  assertNoUntrackedMutedTokens(cssText, mutedPairs);

  // (c) + (d) Evaluate pairs for both themes
  const findings = evaluateLiveBindings(cssText, properties, focusBindings, surfaceBindings);

  for (const [theme, tokens] of Object.entries(blocks)) {
    // (c) Evaluate PAIR_RULES (semantic token pairs)
    for (const rule of PAIR_RULES) {
      const fgHex = tokens[rule.fg];
      const bgHex = tokens[rule.bg];
      if (!fgHex || !bgHex) {
        throw new Error(`Missing required token ${rule.fg}/${rule.bg} in ${theme}`);
      }
      const finding = evaluatePair({
        fg: fgHex,
        bg: bgHex,
        role: rule.role,
        selector: null,
        theme,
        tokenPair: `${rule.fg}/${rule.bg}`,
      });
      // Only include non-passing findings (aa-fail and aaa-body-advisory)
      if (finding.severity !== "pass") {
        findings.push(finding);
      }
    }

    // (d) Evaluate MUTED_PAIRS (skip role === "decorative")
    for (const pair of mutedPairs) {
      if (pair.role === "decorative") continue;

      const fgTokenHex = tokens[pair.fg_token];
      const bgTokenHex = tokens[pair.bg_token];
      if (!fgTokenHex || !bgTokenHex) {
        throw new Error(`Missing required muted token ${pair.fg_token}/${pair.bg_token} in ${theme}`);
      }

      // Composite the alpha in sRGB (D-12)
      const compositedFg = compositeAlpha(fgTokenHex, pair.alpha, bgTokenHex);

      const finding = evaluatePair({
        fg: compositedFg,
        bg: bgTokenHex,
        role: pair.role,
        selector: pair.selector,
        theme,
        tokenPair: `${pair.fg_token}@${Math.round(pair.alpha * 100)}%/${pair.bg_token}`,
      });
      if (finding.severity !== "pass") {
        findings.push(finding);
      }
    }
  }

  // (d2) Phase 187 brand pairs, all computed from the stylesheet's custom properties: N-03 text roles
  // on four backdrops, N-04 control edge, primary and button labels, N-05 the book's published pairs
  // and the Failed/Retrying hue gap. Any failure is an AA failure (exit non-zero).
  let brandJson;
  try {
    brandJson = JSON.parse(await readFile(BRAND_JSON_PATH, "utf8"));
  } catch (err) {
    throw new Error(`Could not read the pinned brand book at ${BRAND_JSON_PATH}: ${err.message}`);
  }
  const brandReport = { text: {}, nonText: {}, published: {}, hue: {} };
  const brandFailures = [
    ...checkBrandTextPairs(properties, pairMatrix.text, brandReport.text),
    ...checkNonTextPairs(properties, pairMatrix, brandReport.nonText),
    ...checkPublishedPairs(properties, brandJson, publishedBindings, brandReport.published),
    ...checkStatusHueGap(properties, pairMatrix.statusHue, brandReport.hue),
  ];
  // N-12: the stylesheet bans. Each failure names the line it sits on, and counts as an AA failure.
  const banFailures = [...checkRetiredColorMixes(cssText)];
  const failureFinding = (message, elementRole) => ({
    severity: "aa-fail",
    producer: "token",
    theme: "both",
    selector: null,
    token_pair: message,
    fg: null,
    bg: null,
    actual_ratio: null,
    required_ratio: null,
    element_role: elementRole,
    screen: "token-check",
    viewport: "n/a",
    state: "static",
    shot: null,
    fix_class: "token",
    scope: "systemic",
    evidence: message,
  });
  for (const message of brandFailures) findings.push(failureFinding(message, "brand-pair"));
  for (const message of banFailures) findings.push(failureFinding(message, "stylesheet-ban"));

  // (e) Build report in scrypath.contrast.v1 schema (D-17)
  const report = buildReport(findings);

  // (f) D-21: write report BEFORE deciding exit
  await mkdir(REPORT_DIR, { recursive: true });
  // WR-04: producer-namespaced filename so the token checker's report does not clobber
  // the axe matrix's contrast-report.axe.<scenario>.{json,md} in the shared report dir.
  await writeFile(
    path.join(REPORT_DIR, "contrast-report.token.json"),
    JSON.stringify(report, null, 2)
  );
  await writeFile(
    path.join(REPORT_DIR, "contrast-report.token.md"),
    buildMarkdownReport(report)
  );

  // (g) CI: append markdown to $GITHUB_STEP_SUMMARY (no-op locally)
  if (process.env.GITHUB_STEP_SUMMARY) {
    try {
      const { appendFileSync } = await import("node:fs");
      appendFileSync(process.env.GITHUB_STEP_SUMMARY, "\n" + buildMarkdownReport(report));
    } catch {
      // Non-fatal: CI summary append failure should not mask the actual contrast result
    }
  }

  // (h) CI: emit one ::warning annotation per systemic cluster (no-op locally)
  if (process.env.GITHUB_ACTIONS === "true") {
    const systemicFails = findings.filter(
      (f) => f.severity === "aa-fail" && f.scope === "systemic"
    );
    const seen = new Set();
    for (const f of systemicFails) {
      const key = f.selector || f.token_pair;
      if (key && !seen.has(key)) {
        seen.add(key);
        console.log(
          `::warning file=contrast-report.token.md,title=ContrastCluster::${key}`
        );
      }
    }
  }

  // Console output: verdict line + AA table
  const verdict = report.summary.aa_fail === 0 ? "PASS" : "FAIL";
  console.log(`\nContrast check: ${verdict}`);
  console.log(`  AA failures:  ${report.summary.aa_fail}`);
  console.log(`  AAA advisory: ${report.summary.aaa_advisory}`);
  console.log(`  Report: ${path.join(REPORT_DIR, "contrast-report.token.json")}`);
  const thinnest = brandReport.text.thinnest;
  if (thinnest) {
    console.log(
      `  Brand pairs: ${brandReport.text.pairs} text, ${brandReport.nonText.pairs} non-text, ` +
        `${brandReport.published.pairs} published (${brandReport.published.published} pairs), ` +
        `Failed/Retrying hue gap ${Object.entries(brandReport.hue.gaps).map(([theme, gap]) => `${theme} ${gap.toFixed(1)}`).join(", ")} degrees`
    );
    console.log(
      `  Thinnest text pair: ${thinnest.role} on ${thinnest.backdrop} (${thinnest.theme}) ${(Math.round(thinnest.raw * 100) / 100).toFixed(2)}`
    );
  }

  if (report.summary.aa_fail > 0) {
    console.log(`\nAA Failures:`);
    for (const f of findings.filter((f) => f.severity === "aa-fail")) {
      const label = f.selector || f.token_pair;
      console.log(
        f.element_role === "brand-pair" || f.element_role === "stylesheet-ban"
          ? `  ${label}`
          : `  [${f.theme}] ${label}: ${f.actual_ratio} (required: ${f.required_ratio}, role: ${f.element_role})`
      );
    }
  }

  // (i) D-21: exit non-zero iff summary.aa_fail > 0
  process.exit(report.summary.aa_fail > 0 ? 1 : 0);
}

export { contrastRatioRaw, evaluatePair, passesAA, readThemeProperties };

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error("contrast-checker error:", err.message);
    process.exit(2);
  });
}
