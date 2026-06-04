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
//   contrast-report.json   — machine source of truth (gitignored)
//   contrast-report.md     — generated human view (gitignored)
//
// D-16: lives in examples/scrypath_ecommerce Node lane; scrypath_ops stays Node-free.
// T-128-03: CSS content is parsed as text ONLY (regex/string ops on static text).
//           NO eval() or execution of any CSS content.

import { readFile, mkdir, writeFile, appendFile } from "node:fs/promises";
import { createWriteStream } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

// ─── PATHS ────────────────────────────────────────────────────────────────────

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// D-16: read app.css from the cross-workspace path
const APP_CSS_PATH = path.resolve(__dirname, "../../scrypath_ops/assets/css/app.css");
// D-11: muted-alpha manifest beside DESIGN-TOKENS.md
const PAIRS_PATH = path.resolve(__dirname, "../../scrypath_ops/assets/css/contrast-pairs.mjs");
// D-17: report output (mirrors ADMIN_SCREENSHOT_DIR convention)
const REPORT_DIR = process.env.CONTRAST_REPORT_DIR || "test-results/contrast";

// ─── WCAG MATH (~30 lines, D-13) ─────────────────────────────────────────────

// D-12: composite in sRGB (matches axe-core): out = fg·α + bg·(1−α) per channel
// Input: hex strings like "#141923", alpha as 0–1
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
  { fg: "primary-content",    bg: "primary",    role: "ui"   }, // button pairs → 3.0 threshold
  { fg: "secondary-content",  bg: "secondary",  role: "ui"   },
  { fg: "accent-content",     bg: "accent",     role: "ui"   },
  { fg: "neutral-content",    bg: "neutral",    role: "ui"   },
  { fg: "info-content",       bg: "info",       role: "ui"   },
  { fg: "success-content",    bg: "success",    role: "ui"   },
  { fg: "warning-content",    bg: "warning",    role: "ui"   },
  { fg: "error-content",      bg: "error",      role: "ui"   },
];

// D-14: role → AA / AAA thresholds
const THRESHOLDS = {
  text:  { aa: 4.5, aaa: 7.0 },
  large: { aa: 3.0, aaa: 4.5 },
  ui:    { aa: 3.0, aaa: 4.5 },
};

// ─── CSS PARSE (D-10) ─────────────────────────────────────────────────────────

// Parse the two daisyUI theme blocks from app.css.
// Returns { dark: { "base-100": "#141923", ... }, light: { ... } }
// Regex: /@plugin[^{]*daisyui-theme[^{]*\{([^}]+)\}/g extracts each theme block body.
// T-128-03: text ONLY — regex extraction of hex values; NO eval() or CSS execution.
function parseThemeBlocks(cssText) {
  const blocks = {};
  const blockRe = /@plugin[^{]*daisyui-theme[^{]*\{([^}]+)\}/g;
  let m;
  while ((m = blockRe.exec(cssText)) !== null) {
    const body = m[1];
    const nameMatch = body.match(/name:\s*"([^"]+)"/);
    if (!nameMatch) continue;
    const name = nameMatch[1];
    blocks[name] = {};
    const tokenRe = /--color-([\w-]+):\s*(#[0-9a-fA-F]{6})/g;
    let t;
    while ((t = tokenRe.exec(body)) !== null) {
      blocks[name][t[1]] = t[2];
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

  if (failed) {
    process.exit(1);
  }
  console.log("self-test passed");
  process.exit(0);
}

// ─── D-15 LOCKSTEP GUARDS ─────────────────────────────────────────────────────

// Guard 1 — Token count assertion
// D-10 says "22 semantic --color-* values"; direct parse of app.css shows 20
// explicit declarations per theme block (4 base + 16 semantic = 20). The vendor
// daisyui-theme plugin injects non-color tokens (--radius-*, --size-*, --border,
// --depth, --noise, etc.) that are NOT --color-* prefixed. Lock assertion to 20.
function assertTokenCount(blocks) {
  for (const [theme, tokens] of Object.entries(blocks)) {
    const count = Object.keys(tokens).length;
    if (count !== 20) {
      throw new Error(
        `D-15 Guard 1: expected 20 --color-* tokens in "${theme}" theme block, got ${count}.\n` +
          `Tokens found: ${Object.keys(tokens).join(", ")}\n` +
          `Note: lock is 20 (not 22) because --radius-*, --size-*, --border, --depth, --noise ` +
          `are non-color tokens injected by the daisyui-theme plugin and are NOT --color-* prefixed.`
      );
    }
  }
}

// Guard 2 — Untracked muted token check
// Find all `color:` properties in app.css that use color-mix(in oklch, var(--color-base-content) NN%, transparent).
// Only the `color:` CSS property is checked — NOT border-color, background, box-shadow, --shadow-*, fill.
// Fail if any (selector, alpha) pair is NOT present in the MUTED_PAIRS manifest.
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
      (pair) => pair.selector === selector && Math.abs(pair.alpha - alpha) <= 0.01
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
  // actual `color: color-mix(...)` occurrence found in app.css (within 0.01 alpha
  // tolerance). This catches stale/renamed/removed manifest entries that no longer match
  // any CSS rule, which the forward (css→manifest) scan above cannot detect.
  for (const pair of mutedPairs) {
    if (pair.role === "decorative") continue;
    const hasCssHit = found.some(
      (f) => f.selector === pair.selector && Math.abs(f.alpha - pair.alpha) <= 0.01
    );
    if (!hasCssHit) {
      throw new Error(
        `D-15 Guard 2 (reverse): stale manifest entry!\n` +
          `  Selector: "${pair.selector}" alpha: ${pair.alpha} (${Math.round(pair.alpha * 100)}%)\n` +
          `  This entry is in contrast-pairs.mjs but no matching ` +
          `color: color-mix(in oklch, var(--color-base-content) ${Math.round(pair.alpha * 100)}%, transparent) ` +
          `rule exists in app.css.\n` +
          `  Remove the stale entry from scrypath_ops/assets/css/contrast-pairs.mjs, or ` +
          `restore the corresponding rule in app.css.\n` +
          `  (D-15: the lockstep guard is bidirectional — manifest and CSS must agree both ways.)`
      );
    }
  }
}

// ─── PAIR EVALUATION ──────────────────────────────────────────────────────────

// Evaluate a single pair and return a finding object (D-18 schema)
function evaluatePair({ fg, bg, role, selector, theme, tokenPair }) {
  const thresholds = THRESHOLDS[role] || THRESHOLDS.text;
  // WR-01: compare the UN-ROUNDED ratio against the threshold; round only for display.
  const raw = contrastRatioRaw(fg, bg);
  const passAA = raw >= thresholds.aa;
  const passAAA = raw >= thresholds.aaa;
  const actual = Math.round(raw * 100) / 100; // display value only

  let severity;
  if (!passAA) {
    severity = "aa-fail";
  } else if (!passAAA) {
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
    required_ratio: thresholds.aa,
    aaa_required: thresholds.aaa,
    pass_aa: passAA,
    aaa_body_status: passAAA ? "pass" : "advisory",
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

// ─── MAIN FUNCTION ────────────────────────────────────────────────────────────

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
  try {
    const manifest = await import(PAIRS_PATH);
    mutedPairs = manifest.MUTED_PAIRS;
    if (!Array.isArray(mutedPairs)) {
      throw new Error("MUTED_PAIRS export is not an array");
    }
  } catch (err) {
    throw new Error(`Could not load contrast-pairs.mjs at ${PAIRS_PATH}: ${err.message}`);
  }

  // (a) Parse theme blocks
  const blocks = parseThemeBlocks(cssText);
  const themeNames = Object.keys(blocks);
  if (themeNames.length === 0) {
    throw new Error("No daisyUI theme blocks found in app.css");
  }

  // (b) D-15 guards
  assertTokenCount(blocks);
  assertNoUntrackedMutedTokens(cssText, mutedPairs);

  // (c) + (d) Evaluate pairs for both themes
  const findings = [];

  for (const [theme, tokens] of Object.entries(blocks)) {
    // (c) Evaluate PAIR_RULES (semantic token pairs)
    for (const rule of PAIR_RULES) {
      const fgHex = tokens[rule.fg];
      const bgHex = tokens[rule.bg];
      if (!fgHex || !bgHex) {
        console.warn(`Warning: token ${rule.fg} or ${rule.bg} not found in theme "${theme}" — skipping`);
        continue;
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
        console.warn(
          `Warning: token ${pair.fg_token} or ${pair.bg_token} not found in theme "${theme}" — skipping ${pair.selector}`
        );
        continue;
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

  // (e) Build report in scrypath.contrast.v1 schema (D-17)
  const report = buildReport(findings);

  // (f) D-21: write report BEFORE deciding exit
  await mkdir(REPORT_DIR, { recursive: true });
  await writeFile(
    path.join(REPORT_DIR, "contrast-report.json"),
    JSON.stringify(report, null, 2)
  );
  await writeFile(
    path.join(REPORT_DIR, "contrast-report.md"),
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
          `::warning file=contrast-report.md,title=ContrastCluster::${key}`
        );
      }
    }
  }

  // Console output: verdict line + AA table
  const verdict = report.summary.aa_fail === 0 ? "PASS" : "FAIL";
  console.log(`\nContrast check: ${verdict}`);
  console.log(`  AA failures:  ${report.summary.aa_fail}`);
  console.log(`  AAA advisory: ${report.summary.aaa_advisory}`);
  console.log(`  Report: ${path.join(REPORT_DIR, "contrast-report.json")}`);

  if (report.summary.aa_fail > 0) {
    console.log(`\nAA Failures:`);
    for (const f of findings.filter((f) => f.severity === "aa-fail")) {
      const label = f.selector || f.token_pair;
      console.log(
        `  [${f.theme}] ${label}: ${f.actual_ratio} (required: ${f.required_ratio}, role: ${f.element_role})`
      );
    }
  }

  // (i) D-21: exit non-zero iff summary.aa_fail > 0
  process.exit(report.summary.aa_fail > 0 ? 1 : 0);
}

main().catch((err) => {
  console.error("contrast-checker error:", err.message);
  process.exit(2);
});
