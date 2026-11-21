// A small, known-good website source tree for the static contract's planted and accept cases.
//
// The real website/src is red against the contract until the re-skin lands, so a planted case that
// mutated a build of it could not tell its own mutation from the existing defects. This fixture is
// built through the real build.mjs (via SCRYPATH_SITE_SRC), passes checkSource and checkBuilt with
// zero violations in both theme modes, and is what every planted case mutates a copy of. It is not a
// design: it only has to satisfy the contract, mirroring the markup contract the layout must meet.
import { mkdirSync, writeFileSync } from 'node:fs';
import path from 'node:path';

const LAYOUT = `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src 'self'; style-src 'self'; font-src 'self'; script-src 'self'; base-uri 'none'; form-action 'none'" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="{{THEME_COLOR}}" />
    <title>{{PAGE_TITLE}}</title>
    <meta name="description" content="{{DESCRIPTION}}" />
    <meta property="og:type" content="website" />
    <meta property="og:title" content="{{PAGE_TITLE}}" />
    <meta property="og:description" content="{{DESCRIPTION}}" />
    <meta property="og:url" content="{{SITE_URL}}{{PAGE_PATH}}" />
    <meta property="og:image" content="{{SITE_URL}}assets/scrypath-social-card-1280x640.png" />
    <meta property="og:image:width" content="{{SOCIAL_WIDTH}}" />
    <meta property="og:image:height" content="{{SOCIAL_HEIGHT}}" />
    <meta property="og:image:type" content="image/png" />
    <meta property="og:image:alt" content="The Scrypath lockup on a plain page" />
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content="{{PAGE_TITLE}}" />
    <meta name="twitter:description" content="{{DESCRIPTION}}" />
    <meta name="twitter:image" content="{{SITE_URL}}assets/scrypath-social-card-1280x640.png" />
    <meta name="twitter:image:alt" content="The Scrypath lockup on a plain page" />
    <link rel="canonical" href="{{SITE_URL}}{{PAGE_PATH}}" />
    <link rel="icon" href="{{BASE_PATH}}assets/favicon.ico" sizes="16x16 32x32" />
    <link rel="icon" type="image/svg+xml" sizes="any" href="{{BASE_PATH}}assets/favicon-light.svg" />
    <link rel="icon" type="image/svg+xml" sizes="any" media="(prefers-color-scheme: dark)" href="{{BASE_PATH}}assets/favicon-dark.svg" />
    <link rel="preload" href="{{BASE_PATH}}assets/fonts/ui.woff2" as="font" type="font/woff2" crossorigin />
    <link rel="preload" href="{{BASE_PATH}}assets/fonts/display.woff2" as="font" type="font/woff2" crossorigin />
    <link rel="stylesheet" href="{{BASE_PATH}}assets/tokens.css" />
    <link rel="stylesheet" href="{{BASE_PATH}}assets/styles.css" />
    {{THEME_SCRIPT}}
  </head>
  <body>
    <a class="skip-link" href="#content">Skip to content</a>
    <header class="site-header">
      <a class="brand" href="{{BASE_PATH}}index.html">
        <img class="lockup lockup-light" src="{{BASE_PATH}}assets/scrypath-lockup-light.svg" alt="Scrypath" width="136" height="29" />
        <img class="lockup lockup-dark" src="{{BASE_PATH}}assets/scrypath-lockup-dark.svg" alt="Scrypath" width="136" height="29" />
      </a>
      <nav aria-label="Primary">
        <a href="{{BASE_PATH}}index.html">Home</a>
        <a href="{{BASE_PATH}}docs/">Docs</a>
      </nav>
      <div class="header-actions">
        {{THEME_PICKER}}
        <a href="{{REPO_URL}}">Star</a>
      </div>
    </header>
    <main id="content">
      {{CONTENT}}
    </main>
    <footer class="site-footer">
      <p><a href="https://hex.pm/packages/scrypath">Hex package</a> <a href="https://hexdocs.pm/scrypath">HexDocs</a></p>
      <p>
        <a href="{{BASE_PATH}}assets/fonts/OFL-BricolageGrotesque.txt">Bricolage Grotesque license</a>
        <a href="{{BASE_PATH}}assets/fonts/OFL-HankenGrotesk.txt">Hanken Grotesk license</a>
        <a href="{{BASE_PATH}}assets/fonts/OFL-SometypeMono.txt">Sometype Mono license</a>
      </p>
    </footer>
  </body>
</html>
`;

const PICKER = `<div class="theme-picker" role="group" aria-label="Color theme" hidden>
  <button type="button" data-theme-choice="light" aria-pressed="false">Light</button>
  <button type="button" data-theme-choice="dark" aria-pressed="false">Dark</button>
  <button type="button" data-theme-choice="system" aria-pressed="false">System</button>
</div>
`;

const DIAGRAM = `<svg class="diagram" viewBox="0 0 120 60" aria-hidden="true">
  <rect class="dg-bg" width="120" height="60" />
  <text class="dg-title" x="6" y="22">Record to index</text>
</svg>
`;

// The page text uses the five allowed non-ASCII characters, written as escapes so this file is ASCII.
const PAGE_TEXT = '<p>Scrypath\u2019s \u201Cgolden\u201D page \u2014 start \u2192 here. It&#8217;s <code>fixture</code> text.</p>';

const PAGES = {
  'index.html': `<section><h1>Golden index</h1>${PAGE_TEXT}\n{{INLINE:diagram}}\n<a class="button-primary" href="#content">Read the guide</a></section>\n`,
  'docs.html': `<section><h1>Golden docs</h1>${PAGE_TEXT}</section>\n`,
  'operators.html': `<section><h1>Golden operators</h1>${PAGE_TEXT}</section>\n`,
  'evaluate.html': `<section><h1>Golden evaluate</h1>${PAGE_TEXT}</section>\n`
};

const ROBOTS = 'User-agent: *\nAllow: /\nSitemap: {{SITE_URL}}sitemap.xml\n';
const SITEMAP = `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n  <url><loc>{{SITE_URL}}</loc><lastmod>{{VERSION}}</lastmod></url>\n</urlset>\n`;

const BASE_CSS = `@font-face {
  font-family: "Bricolage Grotesque";
  src: url(fonts/display.woff2) format("woff2");
  font-weight: 600 800;
  font-style: normal;
  font-display: swap;
}
@font-face {
  font-family: "Hanken Grotesk";
  src: url(fonts/ui.woff2) format("woff2");
  font-weight: 400 700;
  font-style: normal;
  font-display: swap;
}
@font-face {
  font-family: "Sometype Mono";
  src: url(fonts/mono.woff2) format("woff2");
  font-weight: 400 500;
  font-style: normal;
  font-display: swap;
}
@font-face {
  font-family: "Hanken Grotesk Fallback";
  src: local("Arial"), local("Liberation Sans"), local("Arimo");
  size-adjust: 100%;
}
:root {
  font-synthesis: none;
  --display-weight: 700;
}
html {
  background: var(--page);
  color: var(--ink);
  font-family: "Hanken Grotesk", "Hanken Grotesk Fallback", system-ui, sans-serif;
}
body {
  margin: 0;
  font-size: 16px;
  line-height: 1.55;
  background: var(--page);
  color: var(--ink);
}
h1, h2 {
  font-family: "Bricolage Grotesque", system-ui, sans-serif;
  font-weight: var(--display-weight);
  letter-spacing: -0.02em;
}
code {
  font-family: "Sometype Mono", ui-monospace, monospace;
  font-size: 13px;
  background: var(--sunken);
  color: var(--code-text);
}
a { color: var(--link); }
.skip-link { position: absolute; left: -999px; }
.lockup { width: 8.5rem; height: auto; flex-shrink: 0; }
.lockup-dark { display: none; }
.button-primary {
  background: var(--link);
  color: var(--on-primary);
  border: 1px solid var(--link);
}
:focus-visible { outline: 2px solid var(--focus); outline-offset: 2px; }
.diagram .dg-bg { fill: var(--sunken); stroke: var(--control-edge); }
.diagram .dg-title { fill: var(--ink); }
@media print {
  .lockup-light { display: inline; }
  .lockup-dark { display: none; }
}
@media (prefers-reduced-motion: no-preference) {
  html { scroll-behavior: smooth; }
}
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { transition-duration: 0s !important; animation-duration: 0s !important; }
}
`;

const PICKER_CSS = `[hidden] { display: none !important; }
.theme-picker { display: inline-flex; gap: 4px; }
.theme-picker button {
  min-height: 2rem;
  border: 1px solid var(--control-edge);
  background: var(--panel);
  color: var(--ink);
}
.theme-picker button[aria-pressed="true"] { border-width: 2px; }
:root[data-theme="dark"] { --display-weight: 670; }
:root[data-theme="dark"] .lockup-light { display: none; }
:root[data-theme="dark"] .lockup-dark { display: inline; }
@media (prefers-color-scheme: dark) {
  :root[data-theme="system"] { --display-weight: 670; }
  :root[data-theme="system"] .lockup-light { display: none; }
  :root[data-theme="system"] .lockup-dark { display: inline; }
}
@media (forced-colors: active) {
  :root[data-theme] .lockup-light { display: inline; }
  :root[data-theme] .lockup-dark { display: none; }
}
@media (forced-colors: active) and (prefers-color-scheme: dark) {
  :root[data-theme] .lockup-light { display: none; }
  :root[data-theme] .lockup-dark { display: inline; }
}
@media print {
  :root[data-theme] .lockup-light { display: inline; }
  :root[data-theme] .lockup-dark { display: none; }
  .theme-picker { display: none; }
}
`;

const THEME_JS = `(function () {
  var K = 'scrypath-theme', root = document.documentElement;
  function read() {
    try { var v = localStorage.getItem(K); return v === 'dark' || v === 'system' ? v : 'light'; } catch (e) { return 'light'; }
  }
  function meta() {
    var m = document.querySelector('meta[name="theme-color"]');
    if (m) m.content = getComputedStyle(root).getPropertyValue('--page').trim();
  }
  function set(c) { root.setAttribute('data-theme', c); meta(); }
  set(read());
  matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function () { if (read() === 'system') meta(); });
  document.addEventListener('DOMContentLoaded', function () {
    var p = document.querySelector('.theme-picker'), b;
    try { localStorage.setItem('scrypath-probe', 1); localStorage.removeItem('scrypath-probe'); } catch (e) { return; }
    if (!p) return;
    b = p.querySelectorAll('[data-theme-choice]');
    function mark(c) { for (var i = 0; i < b.length; i++) b[i].setAttribute('aria-pressed', b[i].getAttribute('data-theme-choice') === c); }
    mark(read());
    p.hidden = false;
    p.addEventListener('click', function (e) {
      var t = e.target.closest('[data-theme-choice]'), c;
      if (!t) return;
      c = t.getAttribute('data-theme-choice');
      try { localStorage.setItem(K, c); } catch (x) { /* this page only */ }
      set(c);
      mark(c);
    });
    addEventListener('storage', function (e) { if (e.key === K) { set(read()); mark(read()); } });
  });
})();
`;

function write(file, contents) {
  mkdirSync(path.dirname(file), { recursive: true });
  writeFileSync(file, contents);
}

// Writes the fixture source tree under `dir`. `mode` is the theme mode the tree must satisfy.
export function writeGoldenSource(dir, mode) {
  write(path.join(dir, 'layout.html'), LAYOUT);
  for (const [name, contents] of Object.entries(PAGES)) write(path.join(dir, 'pages', name), contents);
  write(path.join(dir, 'partials', 'diagram.svg'), DIAGRAM);
  write(path.join(dir, 'robots.txt'), ROBOTS);
  write(path.join(dir, 'sitemap.xml'), SITEMAP);
  if (mode === 'picker') {
    write(path.join(dir, 'partials', 'theme-picker.html'), PICKER);
    write(path.join(dir, 'assets', 'theme.js'), THEME_JS);
    write(path.join(dir, 'assets', 'styles.css'), BASE_CSS + PICKER_CSS);
  } else {
    write(path.join(dir, 'assets', 'styles.css'), BASE_CSS);
  }
}
