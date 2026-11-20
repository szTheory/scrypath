// Static contract for the website (dependency-free: node built-ins only, no npm ci).
//
// Case names start with `live`, `planted` or `accept`; test/mix/tasks/website_contract_test.exs reads
// them and needs every name to be unique and free of `#` and backslashes (TAP escapes both).
//
//   live     runs against the real website/src and the real pinned brand files. Expected RED against the
//            old site until the re-skin lands; never weaken or skip one.
//   planted  mutates a copy of a known-good fixture (lib/golden.mjs, built through the real build.mjs)
//            and asserts the exact violation code, so each guard is shown to be able to fail.
//   accept   shows a legitimate input passes, or pins a helper to the brand's published numbers.
//
// A case that exists only because of the picker or the dark theme carries the exact tag `theme-picker`
// in its name (the D-25 decision rule runs --test-name-pattern=theme-picker). Each such case also has a
// light-only form driven by THEME_MODE, so switching the mode needs no edit here.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { cpSync, existsSync, mkdtempSync, readFileSync, rmSync, symlinkSync, writeFileSync } from 'node:fs';
import http from 'node:http';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { CARVED_OUT_HEX, checkBuilt, checkSource, closedHexSet, codesOf, expectedRoles, hexesIn, loadBrand, PINNED_OUTPUTS } from './lib/contract.mjs';
import { writeGoldenSource } from './lib/golden.mjs';
import { startServer } from './lib/server.mjs';
import { runSmoke } from './smoke.mjs';
import { THEME_MODE } from './theme-mode.mjs';
import { compositeOver, contrastRatio, contrastRatioRaw, hexToColor, parseCssColor, roundRatio, toHex } from './lib/wcag.mjs';

const scriptsDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(scriptsDir, '..', '..');
const buildScript = path.join(scriptsDir, 'build.mjs');
const websiteSrc = path.join(repoRoot, 'website', 'src');
const brandDir = path.join(repoRoot, 'brand');
const SITE_URL = 'https://site.test/scrypath/';
const MIN_THEME_PICKER_CASES = 6;
const PICKER_MODE = THEME_MODE === 'picker';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const tempDirs = [];
process.on('exit', () => {
  for (const dir of tempDirs) rmSync(dir, { recursive: true, force: true });
});

function tempDir(prefix) {
  const dir = mkdtempSync(path.join(os.tmpdir(), prefix));
  tempDirs.push(dir);
  return dir;
}

function readPin(sourcePath) {
  const pin = JSON.parse(readFileSync(path.join(brandDir, 'brand.pin.json'), 'utf8'));
  const entry = pin.assets.find(asset => asset.path === sourcePath);
  assert.ok(entry, `brand.pin.json has an entry for ${sourcePath}`);
  return entry.sha256;
}

function runBuild({ out, src, brand, siteUrl = SITE_URL }) {
  const args = [buildScript, '--out', out];
  if (src) args.push('--src', src);
  if (brand) args.push('--brand', brand);
  return spawnSync(process.execPath, args, { encoding: 'utf8', env: { ...process.env, SCRYPATH_SITE_URL: siteUrl } });
}

const brandData = loadBrand(brandDir);
const roles = expectedRoles(brandData);
const built = dist => checkBuilt(dist, { brandDir, siteUrl: SITE_URL });

// The known-good fixture: source and a real build of it, memoized. Planted cases copy from it.
let goldenFixture;
function golden() {
  if (!goldenFixture) {
    const root = tempDir('scrypath-golden-');
    const src = path.join(root, 'src');
    const dist = path.join(root, 'dist');
    writeGoldenSource(src, THEME_MODE);
    const result = runBuild({ out: dist, src });
    assert.equal(result.status, 0, result.stderr);
    goldenFixture = { root, src, dist };
  }
  return goldenFixture;
}

// The real website: source violations plus violations in a build of it, memoized.
let liveFixture;
function live() {
  if (!liveFixture) {
    const dist = path.join(tempDir('scrypath-live-'), 'dist');
    const result = runBuild({ out: dist });
    assert.equal(result.status, 0, result.stderr);
    liveFixture = { dist, violations: [...checkSource(websiteSrc), ...built(dist)] };
  }
  return liveFixture;
}

function assertNoLive(code, scoped) {
  const found = live().violations.filter(item => item.code === code && (scoped === undefined || Boolean(item.scope) === scoped));
  const sample = found.slice(0, 6).map(item => `  ${item.file}: ${item.detail}`).join('\n');
  assert.equal(found.length, 0, `${found.length} ${code} violation(s) in the live website:\n${sample}`);
}

function copyOf(dir, prefix) {
  const copy = tempDir(prefix);
  cpSync(dir, copy, { recursive: true });
  return copy;
}

const builtCopy = () => copyOf(golden().dist, 'scrypath-built-');
const sourceCopy = () => copyOf(golden().src, 'scrypath-src-');

// Rewrite a file in a copy; a mutation that changes nothing would "fail" nothing, so it throws.
function edit(dir, relative, transform) {
  const file = path.join(dir, relative);
  const before = readFileSync(file, 'utf8');
  const after = transform(before);
  assert.notEqual(after, before, `the mutation of ${relative} changed nothing`);
  writeFileSync(file, after);
}

const pages = ['index.html', 'docs/index.html', 'operators/index.html', 'evaluate/index.html'];

function assertCodes(violations, expected, label) {
  const sample = JSON.stringify(violations.slice(0, 4));
  assert.deepEqual(codesOf(violations), [...expected].sort(), `${label}: got ${sample}`);
}

// Brand directory copy holding only the three JSON files the build reads.
function brandCopy() {
  const dir = tempDir('scrypath-brand-');
  for (const name of ['tokens.json', 'brand.json', 'brand.pin.json']) cpSync(path.join(brandDir, name), path.join(dir, name));
  return dir;
}

function editJson(dir, name, transform) {
  const file = path.join(dir, name);
  const data = JSON.parse(readFileSync(file, 'utf8'));
  transform(data);
  writeFileSync(file, JSON.stringify(data));
}

const tag = (...parts) => parts.join('');

// ---------------------------------------------------------------------------
// Live: the real website
// ---------------------------------------------------------------------------

// Ordering for every case that needs a server: the server first (it reads files per request, so the
// directory may still be empty), then the build with the local site URL. No network, no fixed port.
test('live tracer: the build serves tokens.css and a pinned font under /scrypath/ and 404s at the root', async () => {
  const dir = tempDir('scrypath-site-tracer-');
  const server = await startServer({ dir, base: '/scrypath/' });
  try {
    const result = runBuild({ out: dir, siteUrl: server.baseUrl });
    assert.equal(result.status, 0, result.stderr);

    const css = await fetch(`${server.baseUrl}assets/tokens.css`);
    assert.equal(css.status, 200);
    const cssText = await css.text();
    assert.match(cssText, /--page:/);
    assert.match(cssText, /data-theme="dark"/);

    const font = await fetch(`${server.baseUrl}assets/fonts/ui.woff2`);
    assert.equal(font.status, 200);
    assert.equal(font.headers.get('content-type'), 'font/woff2');
    const fontHash = createHash('sha256').update(Buffer.from(await font.arrayBuffer())).digest('hex');
    assert.equal(fontHash, readPin('scrypath_ops/priv/static/assets/fonts/ui.woff2'));

    const root = await fetch(`${server.origin}/`);
    assert.equal(root.status, 404);
  } finally {
    await server.stop();
  }
});

test('live color-literal: website/src holds no color literal, every color is a role variable', () => {
  assertNoLive('color-literal');
});

test('live repo-only-task: no website page names a repo-only mix task', () => {
  assertNoLive('repo-only-task');
});

test('live carved-out-hex: no retired hex survives in source or output', () => {
  assertNoLive('carved-out-hex');
});

test('live uppercase-transform: no stylesheet rule uppercases text', () => {
  assertNoLive('uppercase-transform');
});

test('live unthemed-favicon: nothing references the unthemed favicon', () => {
  assertNoLive('unthemed-favicon');
});

test('live inline-script: no page carries an inline script or event handler', () => {
  assertNoLive('inline-script');
});

test('live inline-style: no page carries a style attribute or style element', () => {
  assertNoLive('inline-style');
});

test('live pin-hash-mismatch: every copied brand file is byte-identical to its pin', () => {
  assertNoLive('pin-hash-mismatch');
});

test('live missing-asset: every font, license, lockup, favicon and the card is in the build', () => {
  assertNoLive('missing-asset');
});

test('live token-mismatch light: tokens.css light values equal brand/tokens.json for every role', () => {
  assertNoLive('token-mismatch', false);
});

test('live token-mismatch dark system print theme-picker: the dark, system and print blocks match the brand', () => {
  assertNoLive('token-mismatch', true);
});

test('live hex-outside-brand-set: every hex in the build belongs to the closed brand set', () => {
  assertNoLive('hex-outside-brand-set');
});

test('live font-face: three swap faces with the pinned weight axes', () => {
  assertNoLive('font-face');
});

test('live font-synthesis: font-synthesis is none on the root', () => {
  assertNoLive('font-synthesis');
});

test('live root-absolute-url: no href, src or css url starts with a single slash', () => {
  assertNoLive('root-absolute-url');
});

test('live external-url: no css url, src or fetched link leaves the origin', () => {
  assertNoLive('external-url');
});

test('live csp: the built head carries the D-15 policy first after charset', () => {
  assertNoLive('csp');
});

test('live theme-script theme-picker: theme.js is a small keyed classic head script with no color literal', () => {
  assertNoLive('theme-script');
});

test('live default-state: no built page hard-codes a data-theme attribute', () => {
  assertNoLive('default-state', false);
});

test('live default-state theme-picker: hidden picker, hidden rule and dark colors only under the dark selectors', () => {
  assertNoLive('default-state', true);
});

test('live non-ascii: built HTML uses only the five characters the font subsets cover', () => {
  assertNoLive('non-ascii');
});

test('live og-image: og and twitter images are absolute card URLs with the PNG size and alt text', () => {
  assertNoLive('og-image');
});

test('live icon-links: the ico, light svg and dark svg icons are declared and exist', () => {
  assertNoLive('icon-links');
});

test('live preload: exactly the ui and display fonts are preloaded with crossorigin', () => {
  assertNoLive('preload');
});

test('live lockups: a light and a dark lockup image with alt Scrypath and width of at least 136', () => {
  assertNoLive('lockups');
});

test('live ofl-links: the footer links all three font license texts', () => {
  assertNoLive('ofl-links');
});

// ---------------------------------------------------------------------------
// Planted: each guard fails on its own defect (mutations of the known-good fixture)
// ---------------------------------------------------------------------------

test('planted baseline: the known-good fixture itself is clean, so each planted code is its own', () => {
  assertCodes(checkSource(golden().src), [], 'fixture source');
  assertCodes(built(golden().dist), [], 'fixture build');
});

test('planted hex-outside-brand-set: an off-set hex in built css', () => {
  const dir = builtCopy();
  edit(dir, 'assets/styles.css', css => `${css}\n.planted { border-color: #${'123456'}; }\n`);
  assertCodes(built(dir), ['hex-outside-brand-set'], 'off-set hex');
});

test('planted color-literal: an rgba value in a source copy', () => {
  const dir = sourceCopy();
  edit(dir, 'assets/styles.css', css => `${css}\n.planted { box-shadow: 0 0 0 1px rgba(1, 2, 3, 0.5); }\n`);
  assertCodes(checkSource(dir), ['color-literal'], 'rgba in source');
});

test('planted color-literal: a named color in a source copy', () => {
  const dir = sourceCopy();
  edit(dir, 'assets/styles.css', css => `${css}\n.planted { border: 1px solid white; }\n`);
  assertCodes(checkSource(dir), ['color-literal'], 'named color in source');
});

test('planted theme-picker color-literal: a hex literal inside a copy of theme.js', () => {
  const dir = sourceCopy();
  const file = path.join(dir, 'assets', 'theme.js');
  const before = existsSync(file) ? readFileSync(file, 'utf8') : '';
  writeFileSync(file, `${before}\nvar planted = '#${'123456'}';\n`);
  assertCodes(checkSource(dir), ['color-literal'], 'hex in theme.js');
});

test('planted theme-picker theme-script: a hex literal or a missing picker setup in the built output', () => {
  const dir = builtCopy();
  if (PICKER_MODE) {
    edit(dir, 'assets/theme.js', js => `${js}\nvar planted = '#${'123456'}';\n`);
    assertCodes(built(dir), ['hex-outside-brand-set', 'theme-script'], 'hex in built theme.js');
  } else {
    writeFileSync(path.join(dir, 'assets', 'theme.js'), 'var planted = 1;\n');
    assertCodes(built(dir), ['theme-script'], 'theme.js shipped in light-only mode');
  }
});

test('planted missing-asset: a deleted font license text', () => {
  const dir = builtCopy();
  rmSync(path.join(dir, 'assets', 'fonts', 'OFL-HankenGrotesk.txt'));
  assertCodes(built(dir), ['missing-asset'], 'deleted OFL file');
});

test('planted pin-hash-mismatch: one flipped byte in a font', () => {
  const dir = builtCopy();
  const file = path.join(dir, 'assets', 'fonts', 'ui.woff2');
  const bytes = readFileSync(file);
  bytes[bytes.length >> 1] ^= 0xff;
  writeFileSync(file, bytes);
  assertCodes(built(dir), ['pin-hash-mismatch'], 'flipped font byte');
});

test('planted font-face: font-display block instead of swap', () => {
  const dir = builtCopy();
  edit(dir, 'assets/styles.css', css => css.replace('font-display: swap', 'font-display: block'));
  assertCodes(built(dir), ['font-face'], 'font-display block');
});

test('planted font-face: a weight range that is not the pinned axis', () => {
  const dir = builtCopy();
  edit(dir, 'assets/styles.css', css => css.replace('font-weight: 600 800', 'font-weight: 400 900'));
  assertCodes(built(dir), ['font-face'], 'wrong weight axis');
});

test('planted font-synthesis: the root no longer turns synthesis off', () => {
  const dir = builtCopy();
  edit(dir, 'assets/styles.css', css => css.replace('font-synthesis: none;', ''));
  assertCodes(built(dir), ['font-synthesis'], 'synthesis allowed');
});

test('planted inline-script: an inline script in a built page', () => {
  const dir = builtCopy();
  edit(dir, 'index.html', html => html.replace('</body>', '<script>var planted = 1;</script></body>'));
  assertCodes(built(dir), ['inline-script'], 'inline script');
});

test('planted inline-style: a style attribute in a built page', () => {
  const dir = builtCopy();
  edit(dir, 'index.html', html => html.replace('<main id="content">', '<main id="content" style="margin: 0">'));
  assertCodes(built(dir), ['inline-style'], 'style attribute');
});

test('planted root-absolute-url: a root-absolute href', () => {
  const dir = builtCopy();
  edit(dir, 'index.html', html => html.replace('<main id="content">', '<main id="content"><a href="/docs/">planted</a>'));
  assertCodes(built(dir), ['root-absolute-url'], 'root-absolute href');
});

test('planted root-absolute-url: a root-absolute css url', () => {
  const dir = builtCopy();
  edit(dir, 'assets/styles.css', css => `${css}\n.planted { background: url(/assets/planted.png); }\n`);
  assertCodes(built(dir), ['root-absolute-url'], 'root-absolute css url');
});

test('planted root-absolute-url: a root-absolute css import written as a string', () => {
  for (const statement of ['@import "/assets/planted.css";', "@import '/assets/planted.css' screen;"]) {
    const dir = builtCopy();
    edit(dir, 'assets/styles.css', css => `${statement}\n${css}`);
    assertCodes(built(dir), ['root-absolute-url'], `root-absolute import ${statement}`);
  }
});

test('planted root-absolute-url: a srcset whose second candidate is root-absolute', () => {
  const dir = builtCopy();
  edit(dir, 'index.html', html => html.replace('<main id="content">', '<main id="content"><img srcset="./assets/planted.png 1x, /assets/planted-2x.png 2x" alt="" />'));
  assertCodes(built(dir), ['root-absolute-url'], 'root-absolute srcset candidate');
});

test('planted root-absolute-url: a meta refresh to a root-absolute url', () => {
  for (const content of ['0;url=/', "0; URL='/docs/'", '5;/docs/']) {
    const dir = builtCopy();
    edit(dir, 'index.html', html => html.replace('</head>', `<meta http-equiv="refresh" content="${content}" /></head>`));
    assertCodes(built(dir), ['root-absolute-url'], `root-absolute meta refresh ${content}`);
  }
});

test('planted external-url: an http url in built css', () => {
  const dir = builtCopy();
  edit(dir, 'assets/styles.css', css => `${css}\n.planted { background: url(http://example.test/planted.png); }\n`);
  assertCodes(built(dir), ['external-url'], 'http in css');
});

test('planted csp: a policy that allows unsafe-inline styles', () => {
  const dir = builtCopy();
  edit(dir, 'index.html', html => html.replace("style-src 'self'", "style-src 'self' 'unsafe-inline'"));
  assertCodes(built(dir), ['csp'], 'unsafe-inline');
});

test('planted csp: a policy that allows any image source with a star', () => {
  const dir = builtCopy();
  edit(dir, 'index.html', html => html.replace("img-src 'self'", "img-src 'self' *"));
  assertCodes(built(dir), ['csp'], 'star source');
});

test('planted csp: a policy that is not the first meta after charset', () => {
  const dir = builtCopy();
  edit(dir, 'index.html', html => {
    const policy = /\s*<meta http-equiv="Content-Security-Policy"[^>]*>/.exec(html)[0];
    return html.replace(policy, '').replace(/(<meta name="viewport"[^>]*>)/, `$1${policy}`);
  });
  assertCodes(built(dir), ['csp'], 'policy not second');
});

test('planted theme-picker theme-script: a theme script with async', () => {
  const dir = builtCopy();
  if (PICKER_MODE) {
    edit(dir, 'index.html', html => html.replace('<script src=', '<script async src='));
  } else {
    edit(dir, 'index.html', html => html.replace('</head>', '<script src="./assets/theme.js"></script></head>'));
  }
  assertCodes(built(dir), ['theme-script'], 'async theme script');
});

test('planted non-ascii: a middle dot in built HTML', () => {
  const dir = builtCopy();
  edit(dir, 'index.html', html => html.replace('<main id="content">', `<main id="content">a${String.fromCodePoint(0xb7)}b`));
  assertCodes(built(dir), ['non-ascii'], 'middle dot');
});

test('planted unthemed-favicon: a reference to the unthemed favicon', () => {
  const dir = builtCopy();
  edit(dir, 'index.html', html => html.replace('</head>', '<link rel="apple-touch-icon" href="assets/favicon.svg" /></head>'));
  assertCodes(built(dir), ['unthemed-favicon'], 'unthemed favicon');
});

test('planted og-image: a social image meta with the wrong width', () => {
  const dir = builtCopy();
  edit(dir, 'index.html', html => html.replace('property="og:image:width" content="1280"', 'property="og:image:width" content="1200"'));
  assertCodes(built(dir), ['og-image'], 'wrong og width');
});

test('planted icon-links: a declared icon that is not in the build', () => {
  const dir = builtCopy();
  rmSync(path.join(dir, 'assets', 'favicon-dark.svg'));
  assertCodes(built(dir), ['icon-links', 'missing-asset'], 'missing declared icon');
});

test('planted preload: a font preload without crossorigin', () => {
  const dir = builtCopy();
  edit(dir, 'index.html', html => html.replace('href="./assets/fonts/ui.woff2" as="font" type="font/woff2" crossorigin', 'href="./assets/fonts/ui.woff2" as="font" type="font/woff2"'));
  assertCodes(built(dir), ['preload'], 'preload without crossorigin');
});

test('planted lockups: a lockup image without alt text', () => {
  const dir = builtCopy();
  edit(dir, 'index.html', html => html.replace('class="lockup lockup-light" src="./assets/scrypath-lockup-light.svg" alt="Scrypath"', 'class="lockup lockup-light" src="./assets/scrypath-lockup-light.svg" alt=""'));
  assertCodes(built(dir), ['lockups'], 'lockup without alt');
});

test('planted ofl-links: a footer that drops a font license link', () => {
  const dir = builtCopy();
  edit(dir, 'index.html', html => html.replace(/<a href="[^"]*OFL-SometypeMono\.txt">[^<]*<\/a>/, ''));
  assertCodes(built(dir), ['ofl-links'], 'missing OFL link');
});

test('planted default-state: a page that hard-codes data-theme', () => {
  const dir = builtCopy();
  edit(dir, 'index.html', html => html.replace('<html lang="en">', '<html lang="en" data-theme="dark">'));
  assertCodes(built(dir), ['default-state'], 'hard-coded data-theme');
});

test('planted theme-picker default-state: a picker that is visible in the served markup', () => {
  const dir = builtCopy();
  if (PICKER_MODE) {
    edit(dir, 'index.html', html => html.replace(' aria-label="Color theme" hidden>', ' aria-label="Color theme">'));
  } else {
    edit(dir, 'index.html', html => html.replace('<main id="content">', '<main id="content"><div class="theme-picker"></div>'));
  }
  assertCodes(built(dir), ['default-state', ...(PICKER_MODE ? [] : ['theme-script'])], 'picker not hidden');
});

test('planted theme-picker default-state: a dark color outside the dark selectors', () => {
  const dir = builtCopy();
  if (PICKER_MODE) {
    edit(dir, 'assets/styles.css', css => `${css}\n.planted { color: ${roles.page.dark}; }\n`);
  } else {
    edit(dir, 'assets/styles.css', css => `${css}\n:root[data-theme="dark"] { color: var(--ink); }\n`);
  }
  assertCodes(built(dir), ['default-state'], 'dark color outside dark selectors');
});

test('planted token-mismatch: a light role value that differs from tokens.json', () => {
  const dir = builtCopy();
  edit(dir, 'assets/tokens.css', css => css.replace(`--ink: ${roles.ink.light};`, `--ink: ${roles.page.light};`));
  assertCodes(built(dir), ['token-mismatch'], 'changed light ink');
});

test('planted theme-picker token-mismatch: a tokens.css whose system block was changed', () => {
  const dir = builtCopy();
  if (PICKER_MODE) {
    edit(dir, 'assets/tokens.css', css => css.replace(/(:root\[data-theme="system"\] \{[\s\S]*?--page: )#[0-9A-F]{6}/, `$1${roles.page.light}`));
    assertCodes(built(dir), ['token-mismatch'], 'changed system block');
  } else {
    edit(dir, 'assets/tokens.css', css => `${css}\n@media (prefers-color-scheme: dark) {\n  :root[data-theme="system"] {\n    color-scheme: dark;\n  }\n}\n`);
    assertCodes(built(dir), ['token-mismatch', 'default-state'], 'system block emitted in light-only mode');
  }
});

test('planted theme-picker token-mismatch: a print block that is not the light block', () => {
  const dir = builtCopy();
  if (PICKER_MODE) {
    edit(dir, 'assets/tokens.css', css => css.replace(/(@media print \{[\s\S]*?--ink: )#[0-9A-F]{6}/, `$1${roles.page.light}`));
    assertCodes(built(dir), ['token-mismatch'], 'changed print block');
  } else {
    edit(dir, 'assets/tokens.css', css => `${css}\n@media print {\n  :root {\n    color-scheme: light;\n  }\n}\n`);
    assertCodes(built(dir), ['token-mismatch'], 'print block emitted in light-only mode');
  }
});

test('planted carved-out-hex: a retired hex in a source copy', () => {
  const dir = sourceCopy();
  edit(dir, 'assets/styles.css', css => `${css}\n/* ${CARVED_OUT_HEX[0]} */\n`);
  assertCodes(checkSource(dir), ['carved-out-hex'], 'carved-out hex');
});

test('planted repo-only-task: a repo-only mix task named in a source page', () => {
  const dir = sourceCopy();
  edit(dir, 'pages/docs.html', html => html.replace('</section>', `<p>Run <code>${tag('mix ve', 'rify.adopter')}</code>.</p></section>`));
  assertCodes(checkSource(dir), ['repo-only-task'], 'repo-only task');
});

test('planted uppercase-transform: a rule that uppercases text', () => {
  const dir = sourceCopy();
  edit(dir, 'assets/styles.css', css => `${css}\n.planted { text-transform: uppercase; }\n`);
  assertCodes(checkSource(dir), ['uppercase-transform'], 'uppercase');
});

test('planted unthemed-favicon: the unthemed favicon named in a source copy', () => {
  const dir = sourceCopy();
  edit(dir, 'layout.html', html => html.replace('</head>', '<link rel="apple-touch-icon" href="{{BASE_PATH}}assets/favicon.svg" /></head>'));
  assertCodes(checkSource(dir), ['unthemed-favicon'], 'unthemed favicon in source');
});

test('planted build: a tokens.json copy with one role token removed exits non-zero and names the role', () => {
  const brand = brandCopy();
  editJson(brand, 'tokens.json', data => {
    delete data.color.light.plum;
  });
  const out = path.join(tempDir('scrypath-out-'), 'dist');
  const result = runBuild({ out, src: golden().src, brand });
  assert.notEqual(result.status, 0, 'the build must fail when a role resolves to nothing');
  assert.match(result.stderr, /Role "link" \(light\) resolves to nothing/);
  assert.equal(existsSync(out), false, 'a failed build must not leave a half-written output');
});

test('planted build: a brand.json copy whose Control Edge sentence names another hex exits non-zero', () => {
  const brand = brandCopy();
  const changed = `#${'8F7F95'}`;
  editJson(brand, 'brand.json', data => {
    const entry = data.color.secondary.find(item => item.name === 'Control Edge');
    entry.role = entry.role.replace(/Dark uses #[0-9A-Fa-f]{6}/, `Dark uses ${changed}`);
  });
  const result = runBuild({ out: path.join(tempDir('scrypath-out-'), 'dist'), src: golden().src, brand });
  assert.notEqual(result.status, 0, 'the build must fail when the sentence and the role map disagree');
  assert.match(result.stderr, /control-edge/);
  assert.match(result.stderr, new RegExp(changed));
});

test('planted build: a pin entry that no longer matches a pinned font stops the build', () => {
  const brand = brandCopy();
  editJson(brand, 'brand.pin.json', data => {
    const entry = data.assets.find(asset => asset.path === 'scrypath_ops/priv/static/assets/fonts/ui.woff2');
    entry.sha256 = '0'.repeat(64);
  });
  const result = runBuild({ out: path.join(tempDir('scrypath-out-'), 'dist'), src: golden().src, brand });
  assert.notEqual(result.status, 0, 'the build must fail when a pinned file does not match its pin');
  assert.match(result.stderr, /ui\.woff2 does not match its brand\.pin\.json sha256/);
});

test('planted build: an output directory that contains the brand directory is refused', () => {
  // Safe by construction: the directory the build is told to wipe is a scratch directory that holds
  // the brand copy, so a broken guard would delete scratch files, never the repository.
  const scratch = tempDir('scrypath-guard-');
  const brand = path.join(scratch, 'brand');
  cpSync(brandCopy(), brand, { recursive: true });
  const result = runBuild({ out: scratch, src: golden().src, brand });
  assert.notEqual(result.status, 0, 'the build must refuse an output directory that contains its inputs');
  assert.match(result.stderr, /Refusing to build into/);
  assert.equal(existsSync(path.join(brand, 'tokens.json')), true, 'the brand copy must survive');
});

// The build deletes its output directory before it writes, so the guard has to refuse an output that
// sits INSIDE a directory the build reads or that holds the project, not only one that contains it.
// Each case is safe by construction: it either works on a scratch copy of the inputs or names a path
// that does not exist yet inside the real directory, so a broken guard deletes nothing that matters
// and the case removes whatever it created.
function assertRefusedOut({ out, src, brand }, expectation, label) {
  const result = runBuild({ out, src, brand });
  assert.notEqual(result.status, 0, `${label}: the build must refuse this output directory`);
  assert.match(result.stderr, /Refusing to build into/, label);
  assert.match(result.stderr, expectation, label);
  assert.equal(existsSync(out), false, `${label}: a refused build must not create its output`);
}

test('planted build: an output directory inside the source directory is refused', () => {
  const src = path.join(tempDir('scrypath-guard-src-'), 'src');
  cpSync(golden().src, src, { recursive: true });
  const out = path.join(src, 'planted-out');
  assertRefusedOut({ out, src }, /is or is inside/, 'inside the source directory');
  assert.equal(existsSync(path.join(src, 'layout.html')), true, 'the source copy must survive');
});

test('planted build: an output directory that is a subdirectory of the source directory is refused', () => {
  const src = path.join(tempDir('scrypath-guard-pages-'), 'src');
  cpSync(golden().src, src, { recursive: true });
  const result = runBuild({ out: path.join(src, 'pages'), src });
  assert.notEqual(result.status, 0, 'the build must refuse an output that is a source subdirectory');
  assert.match(result.stderr, /Refusing to build into/);
  assert.equal(existsSync(path.join(src, 'pages', 'index.html')), true, 'the source pages must survive');
});

test('planted build: an output directory inside the brand directory is refused', () => {
  const brand = brandCopy();
  const out = path.join(brand, 'planted-out');
  assertRefusedOut({ out, src: golden().src, brand }, /is or is inside/, 'inside the brand directory');
  assert.equal(existsSync(path.join(brand, 'tokens.json')), true, 'the brand copy must survive');
});

test('planted build: an output directory inside the real pinned-source and script directories is refused', () => {
  for (const relative of ['brand/assets/planted-out', 'scrypath_ops/priv/static/assets/fonts/planted-out', 'website/scripts/planted-out']) {
    const out = path.join(repoRoot, relative);
    try {
      assertRefusedOut({ out, src: golden().src }, /is or is inside/, relative);
    } finally {
      rmSync(out, { recursive: true, force: true });
    }
  }
});

test('planted build: an output directory reached through a symlink into the source directory is refused', () => {
  const scratch = tempDir('scrypath-guard-link-');
  const src = path.join(scratch, 'src');
  cpSync(golden().src, src, { recursive: true });
  symlinkSync(src, path.join(scratch, 'link'), 'dir');
  const result = runBuild({ out: path.join(scratch, 'link', 'pages'), src });
  assert.notEqual(result.status, 0, 'a symlink must not hide the source directory from the guard');
  assert.match(result.stderr, /Refusing to build into/);
  assert.equal(existsSync(path.join(src, 'pages', 'index.html')), true, 'the source pages must survive');
});

// ---------------------------------------------------------------------------
// Accept: legitimate input passes, helpers match the brand's published numbers
// ---------------------------------------------------------------------------

test('accept the known-good fixture source and build have no violations in the current theme mode', () => {
  assertCodes(checkSource(golden().src), [], 'fixture source');
  assertCodes(built(golden().dist), [], 'fixture build');
});

test('accept an html entity and a fragment link produce no color-literal', () => {
  const dir = sourceCopy();
  edit(dir, 'pages/docs.html', html => html.replace('</section>', '<p>It&#8217;s issue #123 &#x2014; <a href="#content">jump</a> or <a href="#decade">there</a>.</p></section>'));
  assertCodes(checkSource(dir), [], 'entities and fragments');
});

test('accept transparent and currentColor in css produce no color-literal', () => {
  const dir = sourceCopy();
  edit(dir, 'assets/styles.css', css => `${css}\n.ok { border-color: transparent; color: currentColor; background: none; box-shadow: 0 0 0 1px color-mix(in srgb, var(--ink) 20%, transparent); }\n`);
  assertCodes(checkSource(dir), [], 'transparent and currentColor');
});

test('accept relative css imports, srcset candidates and meta refresh targets produce no root-absolute-url', () => {
  const dir = builtCopy();
  edit(dir, 'assets/styles.css', css => `@import "./planted.css";\n@import url(./planted-2.css);\n${css}`);
  edit(dir, 'index.html', html =>
    html
      .replace('<main id="content">', '<main id="content"><img srcset="./assets/a.png 1x, ../assets/b.png 2x, https://example.test/c.png 3x" alt="" />')
      .replace('</head>', '<meta http-equiv="refresh" content="0; url=./docs/" /></head>')
  );
  assert.equal(
    built(dir).filter(violation => violation.code === 'root-absolute-url').length,
    0,
    'relative and absolute-URL forms are not root-absolute'
  );
});

test('accept the five allowed non-ascii characters produce no non-ascii violation', () => {
  const dir = builtCopy();
  edit(dir, 'index.html', html => html.replace('<main id="content">', `<main id="content">${[0x201c, 0x201d, 0x2019, 0x2014, 0x2192].map(code => String.fromCodePoint(code)).join('')}`));
  assertCodes(built(dir), [], 'allowed characters');
});

test('accept the copied wcag function reproduces brand.json contrast for the six site pair ids in both themes', () => {
  const pairs = brandData.brand.color.contrastPairs;
  for (const id of ['body', 'descriptor', 'caption', 'link', 'focus', 'button']) {
    const pair = pairs.find(candidate => candidate.id === id);
    assert.ok(pair, `brand.json has pair ${id}`);
    for (const theme of ['light', 'dark']) {
      const { text, background, contrast } = pair[theme];
      assert.equal(roundRatio(contrastRatioRaw(text, background)), contrast, `${id} ${theme} ${text} on ${background}`);
    }
  }
  const byId = id => pairs.find(candidate => candidate.id === id);
  assert.equal(byId('link').light.contrast, 8.64);
  assert.equal(byId('link').dark.contrast, 6.92);
  assert.equal(byId('button').light.contrast, 8.64);
  assert.equal(byId('button').dark.contrast, 7.49);
});

test('accept parseCssColor reads the rgb and color(srgb) forms of one color to equal channels', () => {
  const plum = hexToColor(roles.link.light);
  const asRgb = parseCssColor(`rgb(${plum.r}, ${plum.g}, ${plum.b})`);
  const asSpaced = parseCssColor(`rgb(${plum.r} ${plum.g} ${plum.b} / 1)`);
  const asSrgb = parseCssColor(`color(srgb ${plum.r / 255} ${plum.g / 255} ${plum.b / 255})`);
  for (const parsed of [asSpaced, asSrgb]) {
    assert.ok(Math.abs(parsed.r - asRgb.r) < 0.01 && Math.abs(parsed.g - asRgb.g) < 0.01 && Math.abs(parsed.b - asRgb.b) < 0.01);
    assert.equal(parsed.a, 1);
  }
  assert.equal(toHex(asSrgb), roles.link.light);
  assert.equal(parseCssColor('rgba(0, 0, 0, 0.5)').a, 0.5);
  assert.equal(parseCssColor('color(srgb 0 0 0 / 0.5)').a, 0.5);
  assert.throws(() => parseCssColor('hsl(10 20% 30%)'), /Unsupported computed color form/);
});

test('accept a translucent text surface composites to the hand-computed ratio 5.32', () => {
  // Black at 50 percent alpha over white paints a mid grey (127.5 rounds to 128); black text on that
  // grey is (L + 0.05) / 0.05 with L about 0.2159, which is 5.32 to two decimals.
  const surface = compositeOver(parseCssColor('rgba(0, 0, 0, 0.5)'), hexToColor('#FFFFFF'));
  assert.equal(toHex(surface), '#808080');
  const text = parseCssColor('rgb(0, 0, 0)');
  assert.equal(roundRatio(contrastRatio(text, surface)), 5.32);
  const mixed = compositeOver(parseCssColor('color(srgb 0 0 0 / 0.5)'), hexToColor('#FFFFFF'));
  assert.equal(roundRatio(contrastRatio(text, mixed)), 5.32);
});

test('accept the lockup svg hexes and dark selected are in the closed set and a stray hex is not', () => {
  const closed = closedHexSet(brandData);
  for (const name of ['scrypath-lockup-light.svg', 'scrypath-lockup-dark.svg']) {
    const hexes = hexesIn(readFileSync(path.join(golden().dist, 'assets', name), 'utf8'));
    assert.ok(hexes.length > 0, `${name} carries hex colors`);
    for (const hex of hexes) assert.ok(closed.has(hex), `${name} hex ${hex} is in the closed set`);
  }
  const pairs = brandData.brand.color.contrastPairs;
  const darkSelected = pairs.find(pair => pair.id === 'selected-row').dark.background.toUpperCase();
  assert.equal(roles.selected.dark, darkSelected);
  assert.ok(closed.has(darkSelected), 'dark selected comes from contrastPairs, not tokens.json');
  assert.ok(closed.has(roles['control-edge'].dark), 'the Control Edge sentence hex is in the set');
  assert.equal(closed.has(`#${'123456'}`), false);
  assert.ok(Object.keys(PINNED_OUTPUTS).length === 12);
});

test('accept the preview server 404s outside the base, serves real mime types and refuses a path escape', async () => {
  const server = await startServer({ dir: golden().dist, base: '/scrypath/' });
  try {
    const get = async (suffix, base = server.origin) => fetch(`${base}${suffix}`, { redirect: 'manual' });
    assert.equal((await get('/')).status, 404);
    assert.equal((await get('/other/')).status, 404);
    assert.equal((await get('/scrypath/')).status, 200);
    assert.equal((await get('/scrypath/docs/')).status, 200);

    const redirect = await get('/scrypath/docs');
    assert.equal(redirect.status, 301);
    assert.equal(redirect.headers.get('location'), '/scrypath/docs/');

    assert.equal((await get('/scrypath/assets/fonts/ui.woff2')).headers.get('content-type'), 'font/woff2');
    assert.equal((await get('/scrypath/assets/scrypath-social-card-1280x640.png')).headers.get('content-type'), 'image/png');
    assert.equal((await get('/scrypath/assets/favicon.ico')).headers.get('content-type'), 'image/x-icon');

    assert.ok([403, 404].includes((await get('/scrypath/..%2f..%2fpackage.json')).status), 'an encoded path escape must be refused');
    assert.ok([403, 404].includes((await get('/scrypath//etc/hosts')).status), 'a doubled slash must not reach the filesystem root');

    await server.flush();
    const statuses = new Map(server.requests.map(request => [request.path, request.status]));
    assert.equal(statuses.get('/'), 404);
    assert.equal(statuses.get('/scrypath/'), 200);
  } finally {
    await server.stop();
  }
});

// Smoke cases (scripts/smoke.mjs): the server starts first on an empty temp directory, then the real
// website is built into it with the local site URL, so og:image and the canonical URLs resolve to the
// local server under /scrypath/. No network and no fixed port. Planted cases run the smoke with a
// single attempt so a planted 404 does not wait out the retry delay.
async function withServedSite(run) {
  const dir = tempDir('scrypath-smoke-');
  const server = await startServer({ dir, base: '/scrypath/' });
  try {
    const result = runBuild({ out: dir, siteUrl: server.baseUrl });
    assert.equal(result.status, 0, result.stderr);
    return await run({ dir, server });
  } finally {
    await server.stop();
  }
}

const SMOKE_ONCE = { attempts: 1, retryDelayMs: 0 };
const failedCodes = results => results.filter(result => !result.ok).map(result => result.code);

test('accept smoke passes against the built site served under /scrypath/', async () => {
  await withServedSite(async ({ server }) => {
    const { ok, results } = await runSmoke(server.baseUrl, SMOKE_ONCE);
    assert.deepEqual(failedCodes(results), [], JSON.stringify(results.filter(result => !result.ok)));
    assert.equal(ok, true);
    // `script` appears only when the page declares a script, which light-only mode does not.
    assert.deepEqual(
      [...new Set(results.map(result => result.code))].sort(),
      ['base-path', 'card', 'favicon', 'font', 'home', 'lockups', ...(PICKER_MODE ? ['script'] : []), 'stylesheet']
    );

    // Every URL the smoke asked for is under the base path: nothing reached the origin root.
    await server.flush();
    const outside = server.requests.filter(request => !request.path.startsWith('/scrypath/') && !request.path.startsWith('/__flush_'));
    assert.deepEqual(outside, [], 'the smoke must not request anything outside /scrypath/');
    assert.ok(server.requests.some(request => request.path === '/scrypath/assets/fonts/ui.woff2' && request.status === 200));
  });
});

test('accept smoke command line exits 0 against the served site and 1 with a message when no base URL is set', async () => {
  const smokeScript = path.join(scriptsDir, 'smoke.mjs');
  const env = { ...process.env };
  delete env.SCRYPATH_SMOKE_URL;
  delete env.SCRYPATH_SITE_URL;

  const missing = spawnSync(process.execPath, [smokeScript], { encoding: 'utf8', env });
  assert.equal(missing.status, 1);
  assert.match(missing.stderr, /SCRYPATH_SMOKE_URL/);

  await withServedSite(async ({ server }) => {
    const served = spawnSync(process.execPath, [smokeScript], { encoding: 'utf8', env: { ...env, SCRYPATH_SMOKE_URL: server.baseUrl } });
    assert.equal(served.status, 0, `${served.stdout}${served.stderr}`);
    assert.match(served.stdout, /^ok - the ui font answers 200 as font\/woff2 with its pinned hash$/m);
    assert.match(served.stdout, /smoke passed/);
  });
});

test('planted smoke still runs and exits 1 with its message when started through a symlinked path', () => {
  // Node resolves symlinks for the main module, so a guard that compares the raw argv path with
  // import.meta.url sees two different paths and silently runs nothing: no output, exit 0.
  const env = { ...process.env };
  delete env.SCRYPATH_SMOKE_URL;
  delete env.SCRYPATH_SITE_URL;
  const link = path.join(tempDir('scrypath-symlink-'), 'website-link');
  symlinkSync(path.join(repoRoot, 'website'), link, 'dir');

  const viaLink = spawnSync(process.execPath, [path.join(link, 'scripts', 'smoke.mjs')], { encoding: 'utf8', env });
  assert.equal(viaLink.status, 1, `exit ${viaLink.status}, stdout ${JSON.stringify(viaLink.stdout)}, stderr ${JSON.stringify(viaLink.stderr)}`);
  assert.match(viaLink.stderr, /SCRYPATH_SMOKE_URL/);
});

test('planted smoke fails when a pinned font is missing from the served tree', async () => {
  await withServedSite(async ({ dir, server }) => {
    rmSync(path.join(dir, 'assets', 'fonts', 'ui.woff2'));
    const { ok, results } = await runSmoke(server.baseUrl, SMOKE_ONCE);
    assert.equal(ok, false, 'a missing font must fail the smoke');
    assert.deepEqual(failedCodes(results), ['font']);
  });
});

test('planted smoke fails when the stylesheet is missing from the served tree', async () => {
  await withServedSite(async ({ dir, server }) => {
    rmSync(path.join(dir, 'assets', 'styles.css'));
    const { ok, results } = await runSmoke(server.baseUrl, SMOKE_ONCE);
    assert.equal(ok, false, 'a page whose stylesheet 404s must fail the smoke');
    assert.deepEqual(failedCodes(results), ['stylesheet']);
    assert.match(results.find(result => !result.ok).detail, /assets\/styles\.css: status 404/);
  });
});

test('planted smoke fails when tokens.css is missing from the served tree', async () => {
  await withServedSite(async ({ dir, server }) => {
    rmSync(path.join(dir, 'assets', 'tokens.css'));
    const { ok, results } = await runSmoke(server.baseUrl, SMOKE_ONCE);
    assert.equal(ok, false, 'a page without its role variables must fail the smoke');
    assert.deepEqual(failedCodes(results), ['stylesheet']);
    assert.match(results.find(result => !result.ok).detail, /assets\/tokens\.css: status 404/);
  });
});

test('planted theme-picker smoke fails when theme.js is missing from the served tree', async () => {
  await withServedSite(async ({ dir, server }) => {
    if (PICKER_MODE) {
      rmSync(path.join(dir, 'assets', 'theme.js'));
      const { ok, results } = await runSmoke(server.baseUrl, SMOKE_ONCE);
      assert.equal(ok, false, 'a page whose theme script 404s must fail the smoke');
      assert.deepEqual(failedCodes(results), ['script']);
      assert.match(results.find(result => !result.ok).detail, /assets\/theme\.js: status 404/);
    } else {
      assert.equal(existsSync(path.join(dir, 'assets', 'theme.js')), false, 'light-only mode ships no theme.js');
      const { ok, results } = await runSmoke(server.baseUrl, SMOKE_ONCE);
      assert.deepEqual(failedCodes(results), []);
      assert.equal(ok, true);
    }
  });
});

test('planted smoke fails when a declared stylesheet or script is served as plain text', async () => {
  await withServedSite(async ({ dir, server }) => {
    writeFileSync(path.join(dir, 'assets', 'planted.txt'), 'body { color: inherit; }\n');
    edit(dir, 'index.html', html =>
      html.replace('</head>', '<link rel="stylesheet" href="./assets/planted.txt" /><script src="./assets/planted.txt"></script></head>')
    );
    const { ok, results } = await runSmoke(server.baseUrl, SMOKE_ONCE);
    assert.equal(ok, false, 'a stylesheet or script with a text/plain content type must fail the smoke');
    assert.deepEqual(failedCodes(results).sort(), ['script', 'stylesheet']);
    assert.match(results.find(result => result.code === 'stylesheet' && !result.ok).detail, /content-type is "text\/plain/);
    assert.match(results.find(result => result.code === 'script' && !result.ok).detail, /content-type is "text\/plain/);
  });
});

test('planted smoke fails when og:image resolves outside the base path', async () => {
  await withServedSite(async ({ dir, server }) => {
    edit(dir, 'index.html', html =>
      html.replace(`${server.baseUrl}assets/scrypath-social-card-1280x640.png`, `${server.origin}/assets/scrypath-social-card-1280x640.png`)
    );
    const { ok, results } = await runSmoke(server.baseUrl, SMOKE_ONCE);
    assert.equal(ok, false, 'an og:image outside /scrypath/ must fail the smoke');
    assert.deepEqual(failedCodes(results), ['base-path', 'card']);
    assert.match(results.find(result => result.code === 'base-path').detail, /og:image .* outside /);

    // The out-of-base URL is reported and never fetched.
    await server.flush();
    assert.equal(
      server.requests.some(request => request.path === '/assets/scrypath-social-card-1280x640.png'),
      false,
      'the smoke must not fetch a URL outside the base path'
    );
  });
});

// A server that accepts the request and then stalls: before the response (the headers never come) or
// after it (the headers come, the body does not finish). Open sockets are destroyed on the way out so
// the case cannot leave the process waiting.
async function withStalledServer(handler, run) {
  const sockets = new Set();
  const server = http.createServer(handler);
  server.on('connection', socket => {
    sockets.add(socket);
    socket.on('close', () => sockets.delete(socket));
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  try {
    return await run(`http://127.0.0.1:${server.address().port}/scrypath/`);
  } finally {
    for (const socket of sockets) socket.destroy();
    await new Promise(resolve => server.close(resolve));
  }
}

test('planted smoke fails within its request timeout when the server never answers or never finishes the body', { timeout: 20000 }, async () => {
  const cases = [
    ['headers never arrive', () => {}],
    [
      'the body never finishes',
      (request, response) => {
        response.writeHead(200, { 'content-type': 'text/html', 'content-length': '4096' });
        response.write('<!doctype html>');
      }
    ]
  ];
  for (const [label, handler] of cases) {
    let hits = 0;
    await withStalledServer(
      (request, response) => {
        hits += 1;
        handler(request, response);
      },
      async baseUrl => {
        const started = Date.now();
        const { ok, results } = await runSmoke(baseUrl, { attempts: 2, retryDelayMs: 0, timeoutMs: 250 });
        assert.equal(ok, false, `${label}: a stalled server must fail the smoke`);
        assert.deepEqual(failedCodes(results), ['home'], label);
        assert.match(results[0].detail, /network error/, label);
        assert.ok(Date.now() - started < 10000, `${label}: the smoke must give up after its timeout instead of waiting out the platform default`);
        assert.equal(hits, 2, `${label}: a timeout counts as a network error and is retried once under attempts: 2`);
      }
    );
  }
});

test('accept theme-picker tagged cases are not vacuous', () => {
  const source = readFileSync(fileURLToPath(import.meta.url), 'utf8');
  const names = [...source.matchAll(/^test\('((?:[^'\\]|\\.)+)',/gm)].map(match => match[1]);
  const tagged = names.filter(name => name.includes('theme-picker') && name !== 'accept theme-picker tagged cases are not vacuous');
  assert.ok(
    tagged.length >= MIN_THEME_PICKER_CASES,
    `only ${tagged.length} cases carry the theme-picker tag, the floor is ${MIN_THEME_PICKER_CASES}: --test-name-pattern=theme-picker could pass with nothing run`
  );
  assert.equal(new Set(names).size, names.length, 'case names must be unique');
  for (const name of names) {
    assert.match(name, /^(live|planted|accept) /, `case name must start with live, planted or accept: ${name}`);
    assert.equal(/[#\\]/.test(name), false, `case name must not contain # or a backslash (TAP escapes them): ${name}`);
  }
});
