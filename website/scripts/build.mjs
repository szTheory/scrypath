import { createHash } from 'node:crypto';
import { existsSync, realpathSync } from 'node:fs';
import { mkdir, readFile, rm, writeFile, cp } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { THEME_MODE } from './theme-mode.mjs';

// Options. A flag wins over its environment variable.
//   --out   <dir>  SCRYPATH_SITE_OUT   output directory (default website/dist)
//   --brand <dir>  SCRYPATH_BRAND_DIR  directory holding tokens.json, brand.json and brand.pin.json
//                                      (default <repo>/brand); lets the static contract build against
//                                      a mutated copy of those three files
//   --src   <dir>  SCRYPATH_SITE_SRC   website source directory (default website/src); lets the static
//                                      contract build a known-good fixture through this same pipeline
// Pinned asset files are always read from the repository, at the repo-relative paths the pin lists.
function option(name, envName) {
  const index = process.argv.indexOf(name);
  if (index >= 0) {
    const value = process.argv[index + 1];
    if (!value || value.startsWith('--')) {
      throw new Error(`${name} needs a value`);
    }
    return value;
  }
  return process.env[envName] || undefined;
}

const websiteDir = fileURLToPath(new URL('..', import.meta.url));
const repoRoot = path.resolve(websiteDir, '..');
const srcDir = path.resolve(option('--src', 'SCRYPATH_SITE_SRC') ?? path.join(websiteDir, 'src'));
const brandDir = path.resolve(option('--brand', 'SCRYPATH_BRAND_DIR') ?? path.join(repoRoot, 'brand'));
const outOption = option('--out', 'SCRYPATH_SITE_OUT');
const distDir = path.resolve(outOption ?? path.join(websiteDir, 'dist'));
const siteUrl = process.env.SCRYPATH_SITE_URL ?? 'https://sztheory.github.io/scrypath/';
const repoUrl = process.env.SCRYPATH_REPO_URL ?? 'https://github.com/szTheory/scrypath';
const buildDate = new Date().toISOString().slice(0, 10);

assertSafeOut(distDir);

// ---------------------------------------------------------------------------
// Role map (D-02). This is the only place in website/ where a color value may be named. Each role
// resolves, per theme, to a path in brand/tokens.json. Two dark roles have no token:
//   selected     the dark `background` of brand.json color.contrastPairs ids selected-row and
//                selected-status (both must agree);
//   control-edge the one literal below (D-56). The build asserts it equals the hex printed in the
//                brand's Control Edge sentence ("Dark uses #xxxxxx") in brand.json and tokens.json,
//                so a brand refresh that changes it fails loudly instead of drifting.
// ---------------------------------------------------------------------------
const DARK_CONTROL_EDGE_LITERAL = '#8F7F94';

const ROLE_MAP = {
  page: { light: 'color.light.page', dark: 'color.dark.night' },
  panel: { light: 'color.light.panel', dark: 'color.dark.night-panel' },
  ink: { light: 'color.light.ink', dark: 'color.dark.pale-ink' },
  muted: { light: 'color.secondary.muted-ink', dark: 'color.secondary.muted-pale' },
  link: { light: 'color.light.plum', dark: 'color.dark.orchid' },
  edge: { light: 'color.light.hairline', dark: 'color.dark.night-hairline' },
  'control-edge': { light: 'color.secondary.control-edge', dark: { literal: DARK_CONTROL_EDGE_LITERAL } },
  sunken: { light: 'color.secondary.sunken-page', dark: 'color.code.background-dark' },
  selected: {
    light: 'color.secondary.selected-page',
    dark: { contrastPairs: ['selected-row', 'selected-status'], field: 'background' }
  },
  'code-bg': { light: 'color.code.background-light', dark: 'color.code.background-dark' },
  'code-text': { light: 'color.code.text-light', dark: 'color.code.text-dark' },
  'status-failed': { light: 'color.status.failed-text-light', dark: 'color.status.failed-text-dark' },
  'status-retrying': { light: 'color.status.retrying-text-light', dark: 'color.status.retrying-text-dark' },
  'status-pending': { light: 'color.status.pending-text-light', dark: 'color.status.pending-text-dark' },
  'status-clear': { light: 'color.status.clear-text-light', dark: 'color.status.clear-text-dark' },
  focus: { light: 'color.light.plum', dark: 'color.dark.orchid' },
  'on-primary': { light: 'color.light.panel', dark: 'color.dark.night' }
};

const HEX = /^#[0-9A-Fa-f]{6}$/;

// Pinned brand files copied into the output, as [repo-relative source, output-relative path].
const BRAND_COPIES = [
  ['scrypath_ops/priv/static/assets/fonts/display.woff2', 'assets/fonts/display.woff2'],
  ['scrypath_ops/priv/static/assets/fonts/ui.woff2', 'assets/fonts/ui.woff2'],
  ['scrypath_ops/priv/static/assets/fonts/mono.woff2', 'assets/fonts/mono.woff2'],
  ['scrypath_ops/priv/static/assets/fonts/OFL-BricolageGrotesque.txt', 'assets/fonts/OFL-BricolageGrotesque.txt'],
  ['scrypath_ops/priv/static/assets/fonts/OFL-HankenGrotesk.txt', 'assets/fonts/OFL-HankenGrotesk.txt'],
  ['scrypath_ops/priv/static/assets/fonts/OFL-SometypeMono.txt', 'assets/fonts/OFL-SometypeMono.txt'],
  ['brand/assets/logo/scrypath-lockup-light.svg', 'assets/scrypath-lockup-light.svg'],
  ['brand/assets/logo/scrypath-lockup-dark.svg', 'assets/scrypath-lockup-dark.svg'],
  ['brand/assets/icon/favicon-light.svg', 'assets/favicon-light.svg'],
  ['brand/assets/icon/favicon-dark.svg', 'assets/favicon-dark.svg'],
  ['brand/assets/icon/favicon.ico', 'assets/favicon.ico'],
  ['brand/assets/social/scrypath-social-card-1280x640.png', 'assets/scrypath-social-card-1280x640.png']
  // brand/assets/icon/favicon.svg (unthemed) is never copied: it has no fill and renders black (D-13).
];

const SOCIAL_CARD_OUTPUT = 'assets/scrypath-social-card-1280x640.png';

const pages = [
  {
    input: 'index.html',
    output: 'index.html',
    title: 'Scrypath - Search indexing that feels native to Ecto',
    description:
      'Scrypath is an open-source Elixir library for declarative, Ecto-native search indexing and search orchestration for Phoenix and Ecto teams.',
    routePath: ''
  },
  {
    input: 'docs.html',
    output: path.join('docs', 'index.html'),
    title: 'Scrypath docs map - guides for Phoenix and Ecto search',
    description:
      'A compact map to the Scrypath guides, example app, Phoenix request-edge docs, multitenancy, and recovery material.',
    routePath: 'docs/'
  },
  {
    input: 'operators.html',
    output: path.join('operators', 'index.html'),
    title: 'Scrypath operator support - recovery, verification, and drift',
    description:
      'The operator path for verification commands, drift recovery, and observability around Scrypath.',
    routePath: 'operators/'
  },
  {
    input: 'evaluate.html',
    output: path.join('evaluate', 'index.html'),
    title: 'Should I use Scrypath? - evaluation and fit',
    description:
      'A blunt evaluation page for Phoenix and Ecto teams comparing Scrypath to other search approaches.',
    routePath: 'evaluate/'
  }
];

const mixExs = await readFile(path.join(repoRoot, 'mix.exs'), 'utf8');
const versionMatch = mixExs.match(/@version\s+"([^"]+)"/);

if (!versionMatch) {
  throw new Error('Could not locate @version in mix.exs');
}

const version = versionMatch[1];
const canonicalInstall = '{:scrypath, "~> 0.3"}';

// Resolve every role in both themes before touching the output directory: an unresolved role or a
// disagreeing Control Edge sentence must stop the build with nothing half-written.
const tokens = await readJson(path.join(brandDir, 'tokens.json'));
const brandJson = await readJson(path.join(brandDir, 'brand.json'));
const pin = await readJson(path.join(brandDir, 'brand.pin.json'));
const roles = resolveRoles(tokens, brandJson);
const pinnedHashes = new Map((pin.assets ?? []).map(asset => [asset.path, asset.sha256]));

await rm(distDir, { recursive: true, force: true });
await mkdir(distDir, { recursive: true });

await cp(path.join(srcDir, 'assets'), path.join(distDir, 'assets'), { recursive: true });
await writeFile(path.join(distDir, 'assets', 'tokens.css'), renderTokensCss(roles, THEME_MODE));

for (const [source, output] of BRAND_COPIES) {
  await copyPinned(source, output);
}

const card = await readFile(path.join(distDir, SOCIAL_CARD_OUTPUT));
const socialSize = readPngSize(card);

for (const page of pages) {
  const basePath = page.routePath === '' ? './' : '../';
  const template = await readFile(path.join(srcDir, 'layout.html'), 'utf8');
  const content = await readFile(path.join(srcDir, 'pages', page.input), 'utf8');
  const tokenValues = {
    BASE_PATH: basePath,
    BUILD_DATE: buildDate,
    CANONICAL_INSTALL: canonicalInstall,
    DESCRIPTION: page.description,
    GITHUB_URL: repoUrl,
    PAGE_PATH: page.routePath,
    PAGE_TITLE: page.title,
    REPO_URL: repoUrl,
    SITE_URL: siteUrl,
    SOCIAL_HEIGHT: socialSize.height,
    SOCIAL_WIDTH: socialSize.width,
    THEME_COLOR: roles.page.light,
    VERSION: version
  };
  const renderedContent = await render(content, tokenValues);
  const rendered = await render(template, {
    ...tokenValues,
    ...(await themeTokens(basePath, template)),
    CONTENT: renderedContent
  });

  const outputPath = path.join(distDir, page.output);
  await mkdir(path.dirname(outputPath), { recursive: true });
  await writeFile(outputPath, rendered);
}

await writeFile(
  path.join(distDir, 'robots.txt'),
  replaceTokens(await readFile(path.join(srcDir, 'robots.txt'), 'utf8'), {
    SITE_URL: siteUrl
  })
);

await writeFile(
  path.join(distDir, 'sitemap.xml'),
  replaceTokens(await readFile(path.join(srcDir, 'sitemap.xml'), 'utf8'), {
    SITE_URL: siteUrl,
    VERSION: version
  })
);

process.stdout.write(`Built website into ${distDir} (theme mode: ${THEME_MODE})\n`);

// ---------------------------------------------------------------------------

async function readJson(file) {
  return JSON.parse(await readFile(file, 'utf8'));
}

function isInside(child, parent) {
  const relative = path.relative(parent, child);
  return relative === '' || (!relative.startsWith('..') && !path.isAbsolute(relative));
}

// The absolute path of `target` with symlinks resolved in the part that exists, so a link cannot hide
// a protected directory from the comparison below.
function realPathOf(target) {
  const resolved = path.resolve(target);
  let existing = resolved;
  const rest = [];
  while (!existsSync(existing)) {
    const parent = path.dirname(existing);
    if (parent === existing) {
      return resolved;
    }
    rest.unshift(path.basename(existing));
    existing = parent;
  }
  return path.join(realpathSync(existing), ...rest);
}

// The build removes and recreates its output directory, so the output may not be a directory the build
// reads from or one that holds the project, in either direction:
//   - it may not be, or contain, the repository, the website directory, the source or brand directory,
//     the home directory or the filesystem root (the default website/dist is inside the website
//     directory, which is fine);
//   - it may not be, or sit inside, an input directory: the sources, the brand files (the one given and
//     the repository's own, which the pinned assets are always read from), the pinned fonts, the build
//     scripts, node_modules or .git.
function assertSafeOut(dir) {
  const out = realPathOf(dir);
  const containers = [repoRoot, websiteDir, srcDir, brandDir, os.homedir(), path.parse(out).root];
  for (const protectedPath of containers.map(realPathOf)) {
    if (isInside(protectedPath, out)) {
      throw new Error(`Refusing to build into ${out}: it is or contains ${protectedPath}`);
    }
  }
  const inputs = [
    srcDir,
    brandDir,
    path.join(repoRoot, 'brand'),
    path.join(repoRoot, 'scrypath_ops'),
    path.join(websiteDir, 'scripts'),
    path.join(websiteDir, 'node_modules'),
    path.join(repoRoot, '.git')
  ];
  for (const protectedPath of inputs.map(realPathOf)) {
    if (isInside(out, protectedPath)) {
      throw new Error(`Refusing to build into ${out}: it is or is inside ${protectedPath}`);
    }
  }
}

function tokenHex(tokenTree, tokenPath) {
  let node = tokenTree;
  for (const segment of tokenPath.split('.')) {
    node = node?.[segment];
  }
  return node?.$value?.hex;
}

function contrastPairHexes(brand, ids, theme, field) {
  const pairs = brand?.color?.contrastPairs;
  if (!Array.isArray(pairs)) {
    throw new Error('brand.json has no color.contrastPairs array');
  }
  return ids.map(id => {
    const pair = pairs.find(candidate => candidate.id === id);
    return { id, hex: pair?.[theme]?.[field] };
  });
}

// "Dark uses #8F7F94." is printed in the Control Edge role sentence of both brand files.
function controlEdgeSentenceHexes(tokenTree, brand) {
  const pattern = /Dark uses (#[0-9A-Fa-f]{6})/;
  const brandEntry = (brand?.color?.secondary ?? []).find(entry => entry.name === 'Control Edge');
  const found = [
    { source: 'brand.json color.secondary Control Edge role', text: brandEntry?.role },
    {
      source: 'tokens.json color.secondary.control-edge description',
      text: tokenTree?.color?.secondary?.['control-edge']?.$description
    }
  ];
  return found.map(({ source, text }) => ({ source, hex: pattern.exec(text ?? '')?.[1] }));
}

function resolveRoles(tokenTree, brand) {
  const resolved = {};
  for (const [role, themes] of Object.entries(ROLE_MAP)) {
    resolved[role] = {};
    for (const theme of ['light', 'dark']) {
      const spec = themes[theme];
      let hex;
      let from;
      if (typeof spec === 'string') {
        from = `token path ${spec}`;
        hex = tokenHex(tokenTree, spec);
      } else if (spec.contrastPairs) {
        from = `brand.json contrastPairs ${spec.contrastPairs.join(' and ')} ${theme} ${spec.field}`;
        const values = contrastPairHexes(brand, spec.contrastPairs, theme, spec.field);
        const missing = values.find(value => !HEX.test(value.hex ?? ''));
        if (missing) {
          throw new Error(`Role "${role}" (${theme}) resolves to nothing: ${from}; pair "${missing.id}" has no hex`);
        }
        const distinct = new Set(values.map(value => value.hex.toUpperCase()));
        if (distinct.size !== 1) {
          throw new Error(
            `Role "${role}" (${theme}) is ambiguous: ${values.map(value => `${value.id}=${value.hex}`).join(', ')}`
          );
        }
        hex = values[0].hex;
      } else {
        from = 'the role map literal';
        hex = spec.literal;
        const sentences = controlEdgeSentenceHexes(tokenTree, brand);
        for (const sentence of sentences) {
          if (!sentence.hex || sentence.hex.toUpperCase() !== hex.toUpperCase()) {
            throw new Error(
              `Role "${role}" (${theme}) literal ${hex} disagrees with ${sentence.source}, which prints ${sentence.hex ?? 'no hex'}`
            );
          }
        }
      }
      if (!HEX.test(hex ?? '')) {
        throw new Error(`Role "${role}" (${theme}) resolves to nothing: ${from}`);
      }
      resolved[role][theme] = hex.toUpperCase();
    }
  }
  return resolved;
}

function declarations(roleValues, theme, indent) {
  return Object.keys(ROLE_MAP)
    .map(role => `${indent}--${role}: ${roleValues[role][theme]};`)
    .join('\n');
}

function renderTokensCss(roleValues, mode) {
  const blocks = [
    '/* Generated by website/scripts/build.mjs from brand/tokens.json. Do not edit by hand. */',
    `:root {\n  color-scheme: light;\n${declarations(roleValues, 'light', '  ')}\n}`
  ];
  if (mode === 'picker') {
    blocks.push(
      `:root[data-theme="dark"] {\n  color-scheme: dark;\n${declarations(roleValues, 'dark', '  ')}\n}`,
      `@media (prefers-color-scheme: dark) {\n  :root[data-theme="system"] {\n    color-scheme: dark;\n${declarations(roleValues, 'dark', '    ')}\n  }\n}`,
      `@media print {\n  :root, :root[data-theme] {\n    color-scheme: light;\n${declarations(roleValues, 'light', '    ')}\n  }\n}`
    );
  }
  return `${blocks.join('\n\n')}\n`;
}

async function copyPinned(source, output) {
  const bytes = await readFile(path.join(repoRoot, source));
  const expected = pinnedHashes.get(source);
  if (!expected) {
    throw new Error(`No brand.pin.json entry for ${source}`);
  }
  const actual = createHash('sha256').update(bytes).digest('hex');
  if (actual !== expected) {
    throw new Error(`${source} does not match its brand.pin.json sha256 (pinned ${expected}, found ${actual})`);
  }
  const target = path.join(distDir, output);
  await mkdir(path.dirname(target), { recursive: true });
  await writeFile(target, bytes);
}

// PNG signature, then the IHDR chunk: width and height are big-endian uint32 at offsets 16 and 20.
function readPngSize(buffer) {
  const signature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  if (buffer.length < 24 || !signature.every((byte, index) => buffer[index] === byte) || buffer.toString('latin1', 12, 16) !== 'IHDR') {
    throw new Error(`${SOCIAL_CARD_OUTPUT} is not a PNG with an IHDR chunk`);
  }
  return { width: buffer.readUInt32BE(16), height: buffer.readUInt32BE(20) };
}

async function readPartial(name, extension) {
  if (!/^[a-z0-9-]+$/.test(name)) {
    throw new Error(`Invalid partial name "${name}"`);
  }
  const file = path.join(srcDir, 'partials', `${name}.${extension}`);
  try {
    return (await readFile(file, 'utf8')).trim();
  } catch (error) {
    if (error.code === 'ENOENT') {
      throw new Error(`Unknown partial "${name}": ${file} does not exist`);
    }
    throw error;
  }
}

// Layout slots that only exist in picker mode. In light-only mode both are empty strings.
// While the partial does not exist yet (the layout has not adopted the picker), the picker slot is empty.
async function themeTokens(basePath, template) {
  if (THEME_MODE !== 'picker') {
    return { THEME_PICKER: '', THEME_SCRIPT: '' };
  }
  let picker = '';
  try {
    picker = await readPartial('theme-picker', 'html');
  } catch (error) {
    if (!String(error.message).startsWith('Unknown partial')) {
      throw error;
    }
  }
  if (template.includes('{{THEME_SCRIPT}}')) {
    try {
      await readFile(path.join(srcDir, 'assets', 'theme.js'));
    } catch {
      throw new Error('The layout uses {{THEME_SCRIPT}} in picker mode but src/assets/theme.js does not exist');
    }
  }
  return {
    THEME_PICKER: picker,
    THEME_SCRIPT: `<script src="${basePath}assets/theme.js"></script>`
  };
}

// {{INLINE:<name>}} expands to website/src/partials/<name>.svg; an unknown name throws.
async function expandInline(input) {
  const pattern = /\{\{INLINE:([^}]*)\}\}/g;
  const names = [...new Set([...input.matchAll(pattern)].map(match => match[1]))];
  let output = input;
  for (const name of names) {
    output = output.split(`{{INLINE:${name}}}`).join(await readPartial(name, 'svg'));
  }
  return output;
}

async function render(input, tokenValues) {
  return replaceTokens(await expandInline(input), tokenValues);
}

function replaceTokens(input, tokenValues) {
  return Object.entries(tokenValues).reduce((output, [key, value]) => {
    return output.split(`{{${key}}}`).join(String(value));
  }, input);
}
