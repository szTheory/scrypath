// Static contract for the website: pure checks over a source directory (checkSource) and over a built
// output directory (checkBuilt). Each returns an array of violations
//
//   { code, file, detail, part?, scope? }
//
// and an empty array when the tree is clean. `scope: 'theme-picker'` marks a violation that exists
// only because of the picker or the dark theme (so the case that reports it carries the theme-picker
// tag); `part` says which block (light, dark, system, print) a token violation is about.
//
// Everything here is node built-ins only. The role-to-token table below is deliberately a second,
// independent copy of the one in build.mjs: two typed maps must agree, so a mistake in either fails.
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import path from 'node:path';
import { THEME_MODE } from '../theme-mode.mjs';

const PICKER = 'theme-picker';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

// Retired values that must never appear in website source or output (D-37). Assembled from two pieces
// so no guard source in this repository spells one whole.
export const CARVED_OUT_HEX = [['d08e', '54'], ['0c0f', '14'], ['9aa4', 'b6']].map(pieces => pieces.join(''));

// The only non-ASCII characters allowed in built HTML (D-16): left and right double quote, right
// single quote, em dash, right arrow. All five are present in all three pinned font subsets.
export const ALLOWED_NON_ASCII = new Set([0x201c, 0x201d, 0x2019, 0x2014, 0x2192]);

export const CSP_DIRECTIVES = [
  "default-src 'none'",
  "img-src 'self'",
  "style-src 'self'",
  "font-src 'self'",
  "script-src 'self'",
  "base-uri 'none'",
  "form-action 'none'"
];

// dist path -> repo-relative source path in brand.pin.json. Owned by the contract, independent of
// build.mjs.
export const PINNED_OUTPUTS = {
  'assets/fonts/display.woff2': 'scrypath_ops/priv/static/assets/fonts/display.woff2',
  'assets/fonts/ui.woff2': 'scrypath_ops/priv/static/assets/fonts/ui.woff2',
  'assets/fonts/mono.woff2': 'scrypath_ops/priv/static/assets/fonts/mono.woff2',
  'assets/fonts/OFL-BricolageGrotesque.txt': 'scrypath_ops/priv/static/assets/fonts/OFL-BricolageGrotesque.txt',
  'assets/fonts/OFL-HankenGrotesk.txt': 'scrypath_ops/priv/static/assets/fonts/OFL-HankenGrotesk.txt',
  'assets/fonts/OFL-SometypeMono.txt': 'scrypath_ops/priv/static/assets/fonts/OFL-SometypeMono.txt',
  'assets/scrypath-lockup-light.svg': 'brand/assets/logo/scrypath-lockup-light.svg',
  'assets/scrypath-lockup-dark.svg': 'brand/assets/logo/scrypath-lockup-dark.svg',
  'assets/favicon-light.svg': 'brand/assets/icon/favicon-light.svg',
  'assets/favicon-dark.svg': 'brand/assets/icon/favicon-dark.svg',
  'assets/favicon.ico': 'brand/assets/icon/favicon.ico',
  'assets/scrypath-social-card-1280x640.png': 'brand/assets/social/scrypath-social-card-1280x640.png'
};

export const CARD_FILE = 'scrypath-social-card-1280x640.png';

// The three web faces: pinned file -> family and the weight range the pinned subset axis covers.
export const FONT_FACES = {
  'display.woff2': { family: 'Bricolage Grotesque', range: [600, 800] },
  'ui.woff2': { family: 'Hanken Grotesk', range: [400, 700] },
  'mono.woff2': { family: 'Sometype Mono', range: [400, 500] }
};

// Independent role table: role -> [light token path, dark token path or a marker]. 'pair' means the
// dark `background` of brand.json contrastPairs selected-row and selected-status; 'sentence' means
// the hex printed in the Control Edge sentence. Neither is a literal here.
const CONTRACT_ROLES = {
  page: ['color.light.page', 'color.dark.night'],
  panel: ['color.light.panel', 'color.dark.night-panel'],
  ink: ['color.light.ink', 'color.dark.pale-ink'],
  muted: ['color.secondary.muted-ink', 'color.secondary.muted-pale'],
  link: ['color.light.plum', 'color.dark.orchid'],
  edge: ['color.light.hairline', 'color.dark.night-hairline'],
  'control-edge': ['color.secondary.control-edge', 'sentence'],
  sunken: ['color.secondary.sunken-page', 'color.code.background-dark'],
  selected: ['color.secondary.selected-page', 'pair'],
  'code-bg': ['color.code.background-light', 'color.code.background-dark'],
  'code-text': ['color.code.text-light', 'color.code.text-dark'],
  'status-failed': ['color.status.failed-text-light', 'color.status.failed-text-dark'],
  'status-retrying': ['color.status.retrying-text-light', 'color.status.retrying-text-dark'],
  'status-pending': ['color.status.pending-text-light', 'color.status.pending-text-dark'],
  'status-clear': ['color.status.clear-text-light', 'color.status.clear-text-dark'],
  focus: ['color.light.plum', 'color.dark.orchid'],
  'on-primary': ['color.light.panel', 'color.dark.night']
};

export const ROLE_NAMES = Object.keys(CONTRACT_ROLES);

// CSS Color 4 named colors (lowercase). `transparent` and `currentcolor` are deliberately absent:
// they are the two allowed non-literals.
const NAMED_COLORS = new Set(
  `aliceblue antiquewhite aqua aquamarine azure beige bisque black blanchedalmond blue blueviolet brown
  burlywood cadetblue chartreuse chocolate coral cornflowerblue cornsilk crimson cyan darkblue darkcyan
  darkgoldenrod darkgray darkgreen darkgrey darkkhaki darkmagenta darkolivegreen darkorange darkorchid
  darkred darksalmon darkseagreen darkslateblue darkslategray darkslategrey darkturquoise darkviolet
  deeppink deepskyblue dimgray dimgrey dodgerblue firebrick floralwhite forestgreen fuchsia gainsboro
  ghostwhite gold goldenrod gray green greenyellow grey honeydew hotpink indianred indigo ivory khaki
  lavender lavenderblush lawngreen lemonchiffon lightblue lightcoral lightcyan lightgoldenrodyellow
  lightgray lightgreen lightgrey lightpink lightsalmon lightseagreen lightskyblue lightslategray
  lightslategrey lightsteelblue lightyellow lime limegreen linen magenta maroon mediumaquamarine
  mediumblue mediumorchid mediumpurple mediumseagreen mediumslateblue mediumspringgreen mediumturquoise
  mediumvioletred midnightblue mintcream mistyrose moccasin navajowhite navy oldlace olive olivedrab
  orange orangered orchid palegoldenrod palegreen paleturquoise palevioletred papayawhip peachpuff peru
  pink plum powderblue purple rebeccapurple red rosybrown royalblue saddlebrown salmon sandybrown
  seagreen seashell sienna silver skyblue slateblue slategray slategrey snow springgreen steelblue tan
  teal thistle tomato turquoise violet wheat white whitesmoke yellow yellowgreen`
    .split(/\s+/)
    .filter(Boolean)
);

const COLOR_FUNCTION = /\b(?:rgba?|hsla?|hwb|lab|lch|oklab|oklch|color)\(/i;
const COLOR_ATTRIBUTES = new Set([
  'fill', 'stroke', 'stop-color', 'flood-color', 'lighting-color', 'color', 'bgcolor', 'text', 'link', 'vlink', 'alink'
]);
// Attributes whose values are identifiers or references, where `#abcdef` is an anchor, not a color.
const REFERENCE_ATTRIBUTES = new Set(['href', 'xlink:href', 'id', 'for', 'name', 'class', 'target', 'aria-controls', 'aria-labelledby', 'aria-describedby']);
const NON_COLOR_KEYWORDS = new Set(['none', 'inherit', 'initial', 'unset', 'revert', 'transparent', 'currentcolor']);

// ---------------------------------------------------------------------------
// File helpers
// ---------------------------------------------------------------------------

const TEXT_EXTENSIONS = new Set(['.css', '.html', '.js', '.svg', '.txt', '.xml', '.json', '.mjs']);

export function walk(dir, base = dir) {
  const files = [];
  for (const entry of readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...walk(full, base));
    } else if (entry.isFile()) {
      files.push(path.relative(base, full).split(path.sep).join('/'));
    }
  }
  return files;
}

const readText = file => readFileSync(file, 'utf8');
const extensionOf = file => path.extname(file).toLowerCase();
const violation = (code, file, detail, extra = {}) => ({ code, file, detail, ...extra });

function sha256(file) {
  return createHash('sha256').update(readFileSync(file)).digest('hex');
}

// ---------------------------------------------------------------------------
// CSS parsing (small, enough for rules, at-rules and declarations)
// ---------------------------------------------------------------------------

export function stripCssComments(css) {
  return css.replace(/\/\*[\s\S]*?\*\//g, '');
}

// Split `a: b; c: d` into declarations, ignoring `;` inside parentheses or strings.
function parseDeclarations(body) {
  const declarations = [];
  let depth = 0;
  let quote = null;
  let start = 0;
  const push = end => {
    const piece = body.slice(start, end).trim();
    const colon = piece.indexOf(':');
    if (colon > 0) {
      const prop = piece.slice(0, colon).trim();
      declarations.push({ prop: prop.startsWith('--') ? prop : prop.toLowerCase(), value: piece.slice(colon + 1).trim() });
    }
  };
  for (let i = 0; i < body.length; i += 1) {
    const ch = body[i];
    if (quote) {
      if (ch === '\\') i += 1;
      else if (ch === quote) quote = null;
    } else if (ch === '"' || ch === "'") quote = ch;
    else if (ch === '(') depth += 1;
    else if (ch === ')') depth -= 1;
    else if (ch === ';' && depth === 0) {
      push(i);
      start = i + 1;
    }
  }
  push(body.length);
  return declarations;
}

// Returns a flat list of { selector, media: [preludes], declarations: [{prop, value}] }. @font-face
// blocks have selector '@font-face'. Nested @media, @supports and @layer blocks add to `media`.
export function parseCss(source) {
  const text = stripCssComments(source);
  const rules = [];
  let pos = 0;

  const readPrelude = () => {
    const start = pos;
    let depth = 0;
    let quote = null;
    while (pos < text.length) {
      const ch = text[pos];
      if (quote) {
        if (ch === '\\') pos += 1;
        else if (ch === quote) quote = null;
      } else if (ch === '"' || ch === "'") quote = ch;
      else if (ch === '(') depth += 1;
      else if (ch === ')') depth -= 1;
      else if (depth === 0 && (ch === '{' || ch === ';' || ch === '}')) break;
      pos += 1;
    }
    return text.slice(start, pos).trim();
  };

  const readBody = () => {
    const start = pos;
    let depth = 1;
    let quote = null;
    while (pos < text.length && depth > 0) {
      const ch = text[pos];
      if (quote) {
        if (ch === '\\') pos += 1;
        else if (ch === quote) quote = null;
      } else if (ch === '"' || ch === "'") quote = ch;
      else if (ch === '{') depth += 1;
      else if (ch === '}') depth -= 1;
      pos += 1;
    }
    return text.slice(start, pos - 1);
  };

  const parseList = (media, untilBrace) => {
    while (pos < text.length) {
      while (pos < text.length && /\s/.test(text[pos])) pos += 1;
      if (pos >= text.length) return;
      if (text[pos] === '}') {
        pos += 1;
        if (untilBrace) return;
        continue;
      }
      const prelude = readPrelude();
      const stop = text[pos];
      if (stop === '{') {
        pos += 1;
        if (/^@(media|supports|layer|container)\b/i.test(prelude)) {
          parseList([...media, prelude.replace(/\s+/g, ' ')], true);
        } else {
          rules.push({ selector: prelude.replace(/\s+/g, ' '), media, declarations: parseDeclarations(readBody()) });
        }
      } else if (stop === ';') {
        pos += 1;
      } else {
        pos += 1;
      }
    }
  };

  parseList([], false);
  return rules;
}

function* cssDeclarations(css) {
  for (const rule of parseCss(css)) {
    for (const declaration of rule.declarations) {
      yield { ...declaration, selector: rule.selector, media: rule.media };
    }
  }
}

// Remove quoted strings and url(...) bodies so identifiers and hashes inside them are not read as colors.
function neutralizeValue(value) {
  return value
    .replace(/"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'/g, '""')
    .replace(/url\(\s*(?:"[^"]*"|'[^']*'|[^)]*)\)/gi, 'url()');
}

// ---------------------------------------------------------------------------
// Color literal scanning
// ---------------------------------------------------------------------------

const HEX_TOKEN = /#([0-9A-Fa-f]{8}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{4}|[0-9A-Fa-f]{3})(?![0-9A-Za-z_-])/g;
const LONG_HEX_TOKEN = /#([0-9A-Fa-f]{8}|[0-9A-Fa-f]{6})(?![0-9A-Za-z_-])/g;

// Color literals in a CSS value (a declaration value, a style attribute declaration, a color
// attribute). Returns the offending snippets.
export function colorLiteralsInValue(value) {
  const text = neutralizeValue(value);
  const found = [];
  for (const match of text.matchAll(HEX_TOKEN)) found.push(match[0]);
  const fn = COLOR_FUNCTION.exec(text);
  if (fn) found.push(`${fn[0]}...`);
  for (const match of text.matchAll(/(?<![\w-])[A-Za-z][A-Za-z-]*(?![\w-])/g)) {
    const word = match[0].toLowerCase();
    if (NAMED_COLORS.has(word)) found.push(match[0]);
  }
  return found;
}

export function colorLiteralsInCss(css) {
  const found = [];
  for (const declaration of cssDeclarations(css)) {
    for (const literal of colorLiteralsInValue(declaration.value)) {
      found.push({ literal, where: `${declaration.selector} { ${declaration.prop} }` });
    }
  }
  return found;
}

export function colorLiteralsInJs(js) {
  const found = [];
  for (const match of js.matchAll(LONG_HEX_TOKEN)) found.push({ literal: match[0], where: 'script' });
  for (const match of js.matchAll(/(['"`])#([0-9A-Fa-f]{3,4})\1/g)) found.push({ literal: `#${match[2]}`, where: 'script' });
  const fn = COLOR_FUNCTION.exec(js);
  if (fn) found.push({ literal: `${fn[0]}...`, where: 'script' });
  return found;
}

// ---------------------------------------------------------------------------
// HTML helpers
// ---------------------------------------------------------------------------

const stripHtmlComments = html => html.replace(/<!--[\s\S]*?-->/g, '');

const TAG_PATTERN = /<([a-zA-Z][\w:-]*)((?:\s+[^\s"'<>/=]+(?:\s*=\s*(?:"[^"]*"|'[^']*'|[^\s"'<>=`]+))?)*)\s*\/?>/g;
const ATTRIBUTE_PATTERN = /([^\s"'<>/=]+)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'<>=`]+)))?/g;

export function htmlTags(html) {
  const tags = [];
  for (const match of stripHtmlComments(html).matchAll(TAG_PATTERN)) {
    const attrs = {};
    for (const attribute of match[2].matchAll(ATTRIBUTE_PATTERN)) {
      attrs[attribute[1].toLowerCase()] = attribute[2] ?? attribute[3] ?? attribute[4] ?? '';
    }
    tags.push({ name: match[1].toLowerCase(), attrs, index: match.index, raw: match[0] });
  }
  return tags;
}

function headOf(html) {
  return /<head\b[^>]*>([\s\S]*?)<\/head>/i.exec(stripHtmlComments(html))?.[1] ?? '';
}

function metaContent(tags, key) {
  const meta = tags.find(tag => tag.name === 'meta' && (tag.attrs.property === key || tag.attrs.name === key));
  return meta?.attrs.content;
}

// Color literals in an HTML or SVG document: style attributes, <style> text, color attributes,
// and any six or eight digit hex in a non-reference attribute.
export function colorLiteralsInMarkup(markup) {
  const found = [];
  for (const tag of htmlTags(markup)) {
    for (const [name, value] of Object.entries(tag.attrs)) {
      if (name === 'style') {
        for (const declaration of parseDeclarations(value)) {
          for (const literal of colorLiteralsInValue(declaration.value)) {
            found.push({ literal, where: `<${tag.name} style>` });
          }
        }
        continue;
      }
      if (REFERENCE_ATTRIBUTES.has(name)) continue;
      const lowered = value.trim().toLowerCase();
      if (COLOR_ATTRIBUTES.has(name) || (name === 'content' && tag.attrs.name === 'theme-color')) {
        if (NON_COLOR_KEYWORDS.has(lowered) || lowered.startsWith('url(')) continue;
        for (const literal of colorLiteralsInValue(value)) found.push({ literal, where: `<${tag.name} ${name}>` });
        continue;
      }
      for (const match of value.matchAll(LONG_HEX_TOKEN)) found.push({ literal: match[0], where: `<${tag.name} ${name}>` });
      const fn = COLOR_FUNCTION.exec(value);
      if (fn) found.push({ literal: `${fn[0]}...`, where: `<${tag.name} ${name}>` });
    }
  }
  for (const match of stripHtmlComments(markup).matchAll(/<style\b[^>]*>([\s\S]*?)<\/style>/gi)) {
    for (const item of colorLiteralsInCss(match[1])) found.push(item);
  }
  return found;
}

function inlineScriptProblems(html) {
  const found = [];
  const clean = stripHtmlComments(html);
  for (const match of clean.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script>/gi)) {
    const attrs = htmlTags(`<script ${match[1]}>`)[0]?.attrs ?? {};
    if (attrs.src === undefined || match[2].trim() !== '') found.push('a <script> without src or with a body');
  }
  for (const tag of htmlTags(html)) {
    for (const name of Object.keys(tag.attrs)) {
      if (/^on[a-z]+$/.test(name)) found.push(`an ${name} event handler attribute on <${tag.name}>`);
    }
    for (const value of [tag.attrs.href, tag.attrs.src, tag.attrs.action]) {
      if (value !== undefined && /^\s*javascript:/i.test(value)) found.push('a javascript: URL');
    }
  }
  return found;
}

function inlineStyleProblems(html) {
  const found = [];
  for (const tag of htmlTags(html)) {
    if (tag.attrs.style !== undefined) found.push(`a style attribute on <${tag.name}>`);
  }
  if (/<style\b/i.test(stripHtmlComments(html))) found.push('a <style> element');
  return found;
}

// ---------------------------------------------------------------------------
// Source checks
// ---------------------------------------------------------------------------

// Repo-only task strings. The literal is assembled so this file does not name one whole.
const REPO_ONLY_TASK = ['mix ver', 'ify.'].join('');
const UNTHEMED_FAVICON = /(?<![\w-])favicon\.svg/;

export function checkSource(srcDir) {
  const violations = [];
  for (const file of walk(srcDir)) {
    const extension = extensionOf(file);
    if (!TEXT_EXTENSIONS.has(extension)) continue;
    const text = readText(path.join(srcDir, file));
    const lowered = text.toLowerCase();

    for (const hex of CARVED_OUT_HEX) {
      if (lowered.includes(hex)) violations.push(violation('carved-out-hex', file, `contains the retired value ${hex}`));
    }
    if (text.includes(REPO_ONLY_TASK)) {
      violations.push(violation('repo-only-task', file, `names a repo-only task (${REPO_ONLY_TASK}...), which the Hex package does not ship`));
    }
    if (['.css', '.html', '.js', '.svg'].includes(extension) && UNTHEMED_FAVICON.test(text)) {
      violations.push(violation('unthemed-favicon', file, 'references the unthemed favicon.svg, which renders black'));
    }

    let literals = [];
    if (extension === '.css') literals = colorLiteralsInCss(text);
    else if (extension === '.js') literals = colorLiteralsInJs(text);
    else if (extension === '.html' || extension === '.svg') literals = colorLiteralsInMarkup(text);
    for (const { literal, where } of literals) {
      violations.push(violation('color-literal', file, `${literal} in ${where}`));
    }

    if (extension === '.css') {
      for (const declaration of cssDeclarations(text)) {
        if (declaration.prop === 'text-transform' && /\buppercase\b/i.test(declaration.value)) {
          violations.push(violation('uppercase-transform', file, `text-transform: uppercase in ${declaration.selector}`));
        }
      }
    }
    if (extension === '.html') {
      for (const problem of inlineScriptProblems(text)) violations.push(violation('inline-script', file, problem));
      for (const problem of inlineStyleProblems(text)) violations.push(violation('inline-style', file, problem));
    }
  }
  return violations;
}

// ---------------------------------------------------------------------------
// Brand data (read from the brand directory the build used)
// ---------------------------------------------------------------------------

function tokenHex(tokens, tokenPath) {
  let node = tokens;
  for (const segment of tokenPath.split('.')) node = node?.[segment];
  return node?.$value?.hex?.toUpperCase();
}

function allTokenHexes(tokens, hexes = new Set()) {
  for (const value of Object.values(tokens)) {
    if (value && typeof value === 'object') {
      if (typeof value.$value?.hex === 'string') hexes.add(value.$value.hex.toUpperCase());
      else allTokenHexes(value, hexes);
    }
  }
  return hexes;
}

export function loadBrand(brandDir) {
  const tokens = JSON.parse(readText(path.join(brandDir, 'tokens.json')));
  const brand = JSON.parse(readText(path.join(brandDir, 'brand.json')));
  const pin = JSON.parse(readText(path.join(brandDir, 'brand.pin.json')));
  return { tokens, brand, pin };
}

function controlEdgeSentenceHex(brand) {
  const entry = (brand?.color?.secondary ?? []).find(candidate => candidate.name === 'Control Edge');
  return /Dark uses (#[0-9A-Fa-f]{6})/.exec(entry?.role ?? '')?.[1]?.toUpperCase();
}

function darkSelectedHex(brand) {
  const pairs = brand?.color?.contrastPairs ?? [];
  const values = ['selected-row', 'selected-status'].map(id => pairs.find(pair => pair.id === id)?.dark?.background?.toUpperCase());
  return values.every(value => value && value === values[0]) ? values[0] : undefined;
}

// Expected value of every role in both themes, from the brand files alone.
export function expectedRoles({ tokens, brand }) {
  const expected = {};
  for (const [role, [lightPath, darkPath]] of Object.entries(CONTRACT_ROLES)) {
    expected[role] = {
      light: tokenHex(tokens, lightPath),
      dark: darkPath === 'sentence' ? controlEdgeSentenceHex(brand) : darkPath === 'pair' ? darkSelectedHex(brand) : tokenHex(tokens, darkPath)
    };
  }
  return expected;
}

// The closed set of hexes a build may contain: every hex in tokens.json, every text and background
// hex in brand.json color.contrastPairs (where dark selected lives), and the Control Edge sentence hex.
export function closedHexSet({ tokens, brand }) {
  const set = allTokenHexes(tokens);
  for (const pair of brand?.color?.contrastPairs ?? []) {
    for (const theme of ['light', 'dark']) {
      for (const field of ['text', 'background']) {
        const hex = pair?.[theme]?.[field];
        if (typeof hex === 'string') set.add(hex.toUpperCase());
      }
    }
  }
  const sentence = controlEdgeSentenceHex(brand);
  if (sentence) set.add(sentence);
  return set;
}

function expandHex(hex) {
  const digits = hex.slice(1).toUpperCase();
  const expanded = digits.length <= 4 ? [...digits].map(digit => digit + digit).join('') : digits;
  return `#${expanded}`;
}

export function hexesIn(text, { includeShort = false } = {}) {
  const pattern = includeShort ? HEX_TOKEN : LONG_HEX_TOKEN;
  return [...text.matchAll(pattern)].map(match => expandHex(match[0]));
}

// ---------------------------------------------------------------------------
// Built output checks
// ---------------------------------------------------------------------------

function pngSize(buffer) {
  if (buffer.length < 24 || buffer.toString('latin1', 12, 16) !== 'IHDR') return undefined;
  return { width: buffer.readUInt32BE(16), height: buffer.readUInt32BE(20) };
}

function declarationMap(rule) {
  return new Map(rule.declarations.map(declaration => [declaration.prop, declaration.value.trim().toUpperCase()]));
}

function sameMap(a, b) {
  return a.size === b.size && [...a].every(([key, value]) => b.get(key) === value);
}

const hasMedia = (rule, pattern) => rule.media.some(prelude => pattern.test(prelude));
const isDarkMedia = rule => hasMedia(rule, /prefers-color-scheme:\s*dark/i);
const isForcedColors = rule => hasMedia(rule, /forced-colors/i);

function checkTokens(distDir, roles, mode, violations) {
  const file = 'assets/tokens.css';
  const full = path.join(distDir, file);
  if (!existsSync(full)) {
    violations.push(violation('token-mismatch', file, 'assets/tokens.css is missing', { part: 'light' }));
    return;
  }
  const rules = parseCss(readText(full));
  const light = rules.find(rule => rule.selector === ':root' && rule.media.length === 0);
  const dark = rules.find(rule => rule.selector === ':root[data-theme="dark"]' && rule.media.length === 0);
  const system = rules.find(rule => /^:root\[data-theme="system"\]$/.test(rule.selector) && isDarkMedia(rule));
  const print = rules.find(rule => hasMedia(rule, /^@media\s+print$/i) && /:root/.test(rule.selector));

  const compare = (rule, theme, part, scheme, extra = {}) => {
    if (!rule) {
      violations.push(violation('token-mismatch', file, `no ${part} block`, { part, ...extra }));
      return undefined;
    }
    const values = declarationMap(rule);
    const colorScheme = rule.declarations.find(declaration => declaration.prop === 'color-scheme')?.value;
    if (colorScheme !== scheme) {
      violations.push(violation('token-mismatch', file, `${part} block color-scheme is ${colorScheme ?? 'missing'}, expected ${scheme}`, { part, ...extra }));
    }
    for (const role of ROLE_NAMES) {
      const actual = rule.declarations.find(declaration => declaration.prop === `--${role}`)?.value.trim().toUpperCase();
      const want = roles[role][theme];
      if (!want) {
        violations.push(violation('token-mismatch', file, `the brand files give no ${theme} value for role ${role}`, { part, ...extra }));
      } else if (actual !== want) {
        violations.push(violation('token-mismatch', file, `--${role} in the ${part} block is ${actual ?? 'missing'}, brand says ${want}`, { part, ...extra }));
      }
    }
    return values;
  };

  compare(light, 'light', 'light', 'light');

  if (mode === 'picker') {
    const darkValues = compare(dark, 'dark', 'dark', 'dark', { scope: PICKER });
    const systemValues = compare(system, 'dark', 'system', 'dark', { scope: PICKER });
    const printValues = compare(print, 'light', 'print', 'light', { scope: PICKER });
    if (darkValues && systemValues && !sameMap(darkValues, systemValues)) {
      violations.push(violation('token-mismatch', file, 'the system media block is not the dark block verbatim', { part: 'system', scope: PICKER }));
    }
    const lightValues = light ? declarationMap(light) : undefined;
    if (lightValues && printValues && !sameMap(lightValues, printValues)) {
      violations.push(violation('token-mismatch', file, 'the print block is not the light block verbatim', { part: 'print', scope: PICKER }));
    }
  } else {
    for (const [part, rule] of [['dark', dark], ['system', system], ['print', print]]) {
      if (rule) violations.push(violation('token-mismatch', file, `light-only mode must not emit a ${part} block`, { part, scope: PICKER }));
    }
  }
}

function checkPinnedAssets(distDir, pin, violations) {
  const pinned = new Map((pin.assets ?? []).map(asset => [asset.path, asset.sha256]));
  for (const [output, source] of Object.entries(PINNED_OUTPUTS)) {
    const full = path.join(distDir, output);
    if (!existsSync(full)) {
      violations.push(violation('missing-asset', output, `missing from the build (pinned source ${source})`));
      continue;
    }
    const expected = pinned.get(source);
    if (!expected) {
      violations.push(violation('pin-hash-mismatch', output, `brand.pin.json has no entry for ${source}`));
    } else if (sha256(full) !== expected) {
      violations.push(violation('pin-hash-mismatch', output, `sha256 differs from the pinned ${source}`));
    }
  }
}

function checkBuiltCss(distDir, cssFiles, violations) {
  let faceCount = 0;
  let synthesisOk = false;
  const seenFaces = new Set();
  for (const file of cssFiles) {
    const css = readText(path.join(distDir, file));
    const rules = parseCss(css);
    const bare = stripCssComments(css);

    for (const match of bare.matchAll(/url\(\s*(["']?)([^)"']*)\1\s*\)/gi)) {
      const target = match[2].trim();
      if (/^\/(?!\/)/.test(target)) violations.push(violation('root-absolute-url', file, `url(${target}) is root-absolute and 404s under /scrypath/`));
    }
    for (const match of bare.matchAll(/(?:https?:)?\/\/[^\s)"';]+/gi)) {
      if (/^(?:https?:\/\/|\/\/[A-Za-z0-9])/.test(match[0])) violations.push(violation('external-url', file, `${match[0]} is an external URL in CSS`));
    }

    for (const rule of rules) {
      if (rule.selector === '@font-face') {
        const src = rule.declarations.find(declaration => declaration.prop === 'src')?.value ?? '';
        const woff = /url\(\s*["']?([^)"']*?([\w-]+\.woff2))["']?\s*\)/i.exec(src);
        if (!woff) continue; // a metric-compatible fallback face with local() sources
        faceCount += 1;
        const known = FONT_FACES[woff[2]];
        seenFaces.add(woff[2]);
        const get = prop => rule.declarations.find(declaration => declaration.prop === prop)?.value.trim();
        if (!known) {
          violations.push(violation('font-face', file, `unexpected web font ${woff[2]}`));
          continue;
        }
        if (get('font-display') !== 'swap') violations.push(violation('font-face', file, `${woff[2]} face lacks font-display: swap (found ${get('font-display') ?? 'none'})`));
        const family = (get('font-family') ?? '').replace(/["']/g, '');
        if (family !== known.family) violations.push(violation('font-face', file, `${woff[2]} face has font-family ${family || 'none'}, expected ${known.family}`));
        const range = /^(\d+)\s+(\d+)$/.exec(get('font-weight') ?? '');
        if (!range || Number(range[1]) !== known.range[0] || Number(range[2]) !== known.range[1]) {
          violations.push(violation('font-face', file, `${woff[2]} face font-weight is ${get('font-weight') ?? 'missing'}, the pinned axis is ${known.range.join(' ')}`));
        }
      }
      if (/(^|,)\s*:root\s*(,|$)/.test(rule.selector) && rule.media.length === 0) {
        if (rule.declarations.some(declaration => declaration.prop === 'font-synthesis' && declaration.value.trim() === 'none')) synthesisOk = true;
      }
    }
  }
  if (cssFiles.length > 0 && faceCount !== 3) {
    violations.push(violation('font-face', 'assets/styles.css', `${faceCount} web font faces declared, expected exactly 3`));
  }
  for (const known of Object.keys(FONT_FACES)) {
    if (cssFiles.length > 0 && faceCount > 0 && !seenFaces.has(known)) violations.push(violation('font-face', 'assets/styles.css', `no @font-face for ${known}`));
  }
  if (!synthesisOk) violations.push(violation('font-synthesis', 'assets/styles.css', 'font-synthesis: none is not set on :root'));
}

function checkDefaultState(distDir, htmlFiles, cssFiles, darkOnly, mode, violations) {
  for (const file of htmlFiles) {
    const html = readText(path.join(distDir, file));
    if (/data-theme\s*=/i.test(stripHtmlComments(html).replace(/data-theme-choice\s*=/gi, ''))) {
      violations.push(violation('default-state', file, 'the HTML hard-codes a data-theme attribute; the default state must be set by the stylesheet and theme.js only'));
    }
  }
  const rules = cssFiles.flatMap(file => parseCss(readText(path.join(distDir, file))).map(rule => ({ file, rule })));
  if (mode !== 'picker') {
    for (const { file, rule } of rules) {
      if (/data-theme/.test(rule.selector)) violations.push(violation('default-state', file, `light-only mode has a data-theme selector: ${rule.selector}`, { scope: PICKER }));
    }
    for (const file of htmlFiles) {
      if (/class\s*=\s*["'][^"']*\btheme-picker\b/.test(readText(path.join(distDir, file)))) {
        violations.push(violation('default-state', file, 'light-only mode ships a theme picker', { scope: PICKER }));
      }
    }
    return;
  }
  const stylesheet = rules.filter(({ file }) => file !== 'assets/tokens.css');
  const hiddenRule = stylesheet.find(({ rule }) => rule.selector === '[hidden]' && rule.declarations.some(declaration => declaration.prop === 'display' && /^none\s*!important$/i.test(declaration.value.trim())));
  if (!hiddenRule) violations.push(violation('default-state', 'assets/styles.css', 'no [hidden] { display: none !important } rule; an author display rule would override the hidden attribute', { scope: PICKER }));
  for (const file of htmlFiles) {
    const html = readText(path.join(distDir, file));
    const picker = htmlTags(html).find(tag => tag.attrs.class?.split(/\s+/).includes('theme-picker'));
    if (!picker) violations.push(violation('default-state', file, 'no .theme-picker element in picker mode', { scope: PICKER }));
    else if (picker.attrs.hidden === undefined) violations.push(violation('default-state', file, 'the picker is not hidden in the served markup', { scope: PICKER }));
  }
  for (const { file, rule } of rules) {
    const isDarkBlock = /\[data-theme="dark"\]/.test(rule.selector) || (isDarkMedia(rule) && /\[data-theme="system"\]/.test(rule.selector));
    if (isDarkMedia(rule) && !isForcedColors(rule) && !/\[data-theme="system"\]/.test(rule.selector)) {
      violations.push(violation('default-state', file, `a dark-device media rule without the data-theme="system" qualifier would make dark the default: ${rule.selector}`, { scope: PICKER }));
    }
    for (const declaration of rule.declarations) {
      const leaked = hexesIn(declaration.value).find(hex => darkOnly.has(hex));
      if (leaked && !isDarkBlock) {
        violations.push(violation('default-state', file, `dark color ${leaked} outside the dark and system selectors: ${rule.selector}`, { scope: PICKER }));
      }
    }
  }
}

function checkHtmlPages(distDir, htmlFiles, ctx, violations) {
  const { siteUrl, mode } = ctx;
  const card = existsSync(path.join(distDir, 'assets', CARD_FILE)) ? pngSize(readFileSync(path.join(distDir, 'assets', CARD_FILE))) : undefined;

  for (const file of htmlFiles) {
    const raw = readText(path.join(distDir, file));
    const html = stripHtmlComments(raw);
    const tags = htmlTags(raw);
    const dir = path.posix.dirname(file);

    // Inline script and style.
    for (const problem of inlineScriptProblems(raw)) violations.push(violation('inline-script', file, problem));
    for (const problem of inlineStyleProblems(raw)) violations.push(violation('inline-style', file, problem));

    // CSP: the first meta is the charset, the second is the policy, with exactly the D-15 directives.
    const metas = tags.filter(tag => tag.name === 'meta');
    const policies = metas.filter(tag => tag.attrs['http-equiv']?.toLowerCase() === 'content-security-policy');
    if (metas[0]?.attrs.charset === undefined) violations.push(violation('csp', file, 'the first <meta> is not the charset declaration'));
    if (policies.length !== 1) {
      violations.push(violation('csp', file, `${policies.length} Content-Security-Policy meta tags, expected exactly 1`));
    } else {
      if (metas[1] !== policies[0]) violations.push(violation('csp', file, 'the policy is not the first <meta> after charset; a meta policy governs only what follows it'));
      const directives = (policies[0].attrs.content ?? '').split(';').map(part => part.trim().replace(/\s+/g, ' ')).filter(Boolean);
      for (const directive of directives) {
        if (!CSP_DIRECTIVES.includes(directive)) violations.push(violation('csp', file, `unexpected directive: ${directive}`));
      }
      for (const directive of CSP_DIRECTIVES) {
        if (!directives.includes(directive)) violations.push(violation('csp', file, `missing directive: ${directive}`));
      }
      const policyText = policies[0].attrs.content ?? '';
      if (/unsafe-inline|unsafe-eval|\*|frame-ancestors/.test(policyText)) violations.push(violation('csp', file, 'the policy names unsafe-inline, unsafe-eval, * or frame-ancestors'));
    }

    // Root-absolute and external URLs in attributes.
    for (const tag of tags) {
      for (const name of ['href', 'src', 'srcset', 'poster', 'xlink:href']) {
        const value = tag.attrs[name];
        if (value !== undefined && /^\s*\/(?!\/)/.test(value)) violations.push(violation('root-absolute-url', file, `<${tag.name} ${name}="${value}"> is root-absolute and 404s under /scrypath/`));
      }
      if (tag.attrs.src !== undefined && /^\s*(?:https?:)?\/\/[A-Za-z0-9]/i.test(tag.attrs.src)) {
        violations.push(violation('external-url', file, `<${tag.name} src="${tag.attrs.src}"> is an external URL`));
      }
      if (tag.name === 'link') {
        const rel = (tag.attrs.rel ?? '').toLowerCase().split(/\s+/);
        const fetched = rel.some(token => ['stylesheet', 'preload', 'modulepreload', 'icon', 'shortcut', 'apple-touch-icon', 'manifest', 'prefetch', 'prerender', 'dns-prefetch', 'preconnect'].includes(token));
        if (fetched && /^\s*(?:https?:)?\/\/[A-Za-z0-9]/i.test(tag.attrs.href ?? '')) {
          violations.push(violation('external-url', file, `<link rel="${tag.attrs.rel}" href="${tag.attrs.href}"> fetches from another origin`));
        }
      }
    }

    // Non-ASCII subset.
    for (const character of new Set(raw)) {
      const code = character.codePointAt(0);
      if (code > 0x7f && !ALLOWED_NON_ASCII.has(code)) {
        violations.push(violation('non-ascii', file, `U+${code.toString(16).toUpperCase().padStart(4, '0')} is outside the allowed set of the three font subsets`));
      }
    }

    // Social image meta.
    const expectedImage = `${siteUrl}assets/${CARD_FILE}`;
    for (const key of ['og:image', 'twitter:image']) {
      const value = metaContent(tags, key);
      if (value !== expectedImage) violations.push(violation('og-image', file, `${key} is ${value ?? 'missing'}, expected ${expectedImage}`));
    }
    if (!card) {
      violations.push(violation('og-image', file, 'the social card is missing or not a PNG, so its size cannot be compared'));
    } else {
      if (metaContent(tags, 'og:image:width') !== String(card.width)) violations.push(violation('og-image', file, `og:image:width is ${metaContent(tags, 'og:image:width') ?? 'missing'}, the PNG is ${card.width}`));
      if (metaContent(tags, 'og:image:height') !== String(card.height)) violations.push(violation('og-image', file, `og:image:height is ${metaContent(tags, 'og:image:height') ?? 'missing'}, the PNG is ${card.height}`));
    }
    for (const key of ['og:image:alt', 'og:image:type', 'twitter:image:alt']) {
      if (!metaContent(tags, key)) violations.push(violation('og-image', file, `${key} is missing`));
    }

    // Icon links.
    const icons = tags.filter(tag => tag.name === 'link' && (tag.attrs.rel ?? '').toLowerCase().split(/\s+/).includes('icon'));
    const ico = icons.find(tag => /favicon\.ico$/.test(tag.attrs.href ?? ''));
    const lightIcon = icons.find(tag => /favicon-light\.svg$/.test(tag.attrs.href ?? ''));
    const darkIcon = icons.find(tag => /favicon-dark\.svg$/.test(tag.attrs.href ?? ''));
    if (!ico || ico.attrs.sizes !== '16x16 32x32') violations.push(violation('icon-links', file, 'favicon.ico is not declared with sizes="16x16 32x32"'));
    if (!lightIcon || lightIcon.attrs.sizes !== 'any' || lightIcon.attrs.type !== 'image/svg+xml' || lightIcon.attrs.media !== undefined) {
      violations.push(violation('icon-links', file, 'the light themed SVG icon is not declared unconditionally with type="image/svg+xml" sizes="any"'));
    }
    if (!darkIcon || darkIcon.attrs.sizes !== 'any' || !/prefers-color-scheme:\s*dark/.test(darkIcon.attrs.media ?? '')) {
      violations.push(violation('icon-links', file, 'the dark themed SVG icon is not declared only under media="(prefers-color-scheme: dark)"'));
    }
    for (const icon of icons) {
      const href = icon.attrs.href ?? '';
      if (!/^(?:https?:)?\/\//.test(href) && !existsSync(path.join(distDir, dir, href.split('#')[0].split('?')[0]))) {
        violations.push(violation('icon-links', file, `declared icon ${href} does not exist in the build`));
      }
    }

    // Font preloads: exactly ui and display, each with crossorigin.
    const preloads = tags.filter(tag => tag.name === 'link' && (tag.attrs.rel ?? '').toLowerCase().split(/\s+/).includes('preload'));
    const preloaded = preloads.map(tag => path.posix.basename(tag.attrs.href ?? '')).sort();
    if (preloads.length !== 2 || preloaded.join() !== ['display.woff2', 'ui.woff2'].join()) {
      violations.push(violation('preload', file, `preloads are [${preloaded.join(', ')}], expected exactly ui.woff2 and display.woff2`));
    }
    for (const tag of preloads) {
      if (tag.attrs.crossorigin === undefined) violations.push(violation('preload', file, `preload of ${tag.attrs.href} lacks crossorigin (a font preload without it is fetched twice)`));
      if (tag.attrs.as !== 'font') violations.push(violation('preload', file, `preload of ${tag.attrs.href} lacks as="font"`));
    }

    // Lockups: one light and one dark image, alt Scrypath, at least 136 px wide.
    const lockups = tags.filter(tag => tag.name === 'img' && /scrypath-lockup-(light|dark)\.svg$/.test(tag.attrs.src ?? ''));
    for (const variant of ['light', 'dark']) {
      const matches = lockups.filter(tag => tag.attrs.src.endsWith(`scrypath-lockup-${variant}.svg`));
      if (matches.length !== 1) {
        violations.push(violation('lockups', file, `${matches.length} ${variant} lockup images, expected exactly 1`));
        continue;
      }
      const image = matches[0];
      const before = html.slice(0, html.indexOf(image.raw));
      const anchorStart = before.lastIndexOf('<a ');
      const enclosing = anchorStart >= 0 && !before.slice(anchorStart).includes('</a>') ? htmlTags(before.slice(anchorStart) + '>')[0] : undefined;
      const named = image.attrs.alt === 'Scrypath' || (image.attrs.alt === '' && /^Scrypath\b/.test(enclosing?.attrs['aria-label'] ?? ''));
      if (!named) violations.push(violation('lockups', file, `the ${variant} lockup has alt="${image.attrs.alt ?? ''}", expected alt="Scrypath" (or a link labelled Scrypath)`));
      if (!(Number(image.attrs.width) >= 136)) violations.push(violation('lockups', file, `the ${variant} lockup width attribute is ${image.attrs.width ?? 'missing'}, expected at least 136`));
    }

    // Footer links to the three OFL texts.
    const footer = /<footer\b[\s\S]*?<\/footer>/i.exec(html)?.[0] ?? '';
    const footerHrefs = htmlTags(footer).filter(tag => tag.name === 'a').map(tag => tag.attrs.href ?? '');
    for (const name of ['OFL-BricolageGrotesque.txt', 'OFL-HankenGrotesk.txt', 'OFL-SometypeMono.txt']) {
      if (!footerHrefs.some(href => href.endsWith(`fonts/${name}`))) violations.push(violation('ofl-links', file, `the footer does not link ${name}`));
    }

    // Unthemed favicon and carved-out hexes in the output.
    if (UNTHEMED_FAVICON.test(raw)) violations.push(violation('unthemed-favicon', file, 'references the unthemed favicon.svg, which renders black'));
    for (const hex of CARVED_OUT_HEX) {
      if (raw.toLowerCase().includes(hex)) violations.push(violation('carved-out-hex', file, `contains the retired value ${hex}`));
    }

    // Theme script (picker mode) or its absence (light-only mode).
    const head = headOf(raw);
    const headScripts = htmlTags(head).filter(tag => tag.name === 'script');
    const themeScripts = headScripts.filter(tag => /(^|\/)theme\.js$/.test(tag.attrs.src ?? ''));
    const headEnd = html.toLowerCase().indexOf('</head>');
    const bodyThemeScript = headEnd >= 0 && htmlTags(html.slice(headEnd)).some(tag => tag.name === 'script' && /theme\.js$/.test(tag.attrs.src ?? ''));
    const pickerPresent = tags.some(tag => tag.attrs.class?.split(/\s+/).includes('theme-picker') || tag.attrs['data-theme-choice'] !== undefined);
    if (mode === 'picker') {
      if (themeScripts.length !== 1) violations.push(violation('theme-script', file, `${themeScripts.length} theme.js script elements in <head>, expected 1`, { scope: PICKER }));
      for (const tag of themeScripts) {
        for (const forbidden of ['async', 'defer', 'type', 'nomodule']) {
          if (tag.attrs[forbidden] !== undefined) violations.push(violation('theme-script', file, `theme.js has ${forbidden}, which reintroduces the wrong-theme flash; it must be a plain synchronous head script`, { scope: PICKER }));
        }
      }
      if (bodyThemeScript) violations.push(violation('theme-script', file, 'theme.js is also referenced after </head>', { scope: PICKER }));
    } else {
      if (themeScripts.length > 0 || bodyThemeScript) violations.push(violation('theme-script', file, 'light-only mode must not reference theme.js', { scope: PICKER }));
      if (pickerPresent) violations.push(violation('theme-script', file, 'light-only mode must not ship a theme picker', { scope: PICKER }));
    }
  }
}

export function checkBuilt(distDir, { brandDir, siteUrl = 'https://sztheory.github.io/scrypath/', mode = THEME_MODE } = {}) {
  const violations = [];
  const brandData = loadBrand(brandDir);
  const roles = expectedRoles(brandData);
  const closed = closedHexSet(brandData);
  const lightHexes = new Set(ROLE_NAMES.map(role => roles[role].light));
  const darkOnly = new Set(ROLE_NAMES.map(role => roles[role].dark).filter(hex => hex && !lightHexes.has(hex)));

  const files = walk(distDir);
  const htmlFiles = files.filter(file => extensionOf(file) === '.html');
  const cssFiles = files.filter(file => extensionOf(file) === '.css');

  checkPinnedAssets(distDir, brandData.pin, violations);
  checkTokens(distDir, roles, mode, violations);
  checkBuiltCss(distDir, cssFiles, violations);
  checkDefaultState(distDir, htmlFiles, cssFiles, darkOnly, mode, violations);
  checkHtmlPages(distDir, htmlFiles, { siteUrl, mode }, violations);

  // theme.js (picker mode): small, keyed, no color literal. Light-only: absent.
  const themeFile = 'assets/theme.js';
  if (mode === 'picker') {
    if (!existsSync(path.join(distDir, themeFile))) {
      violations.push(violation('theme-script', themeFile, 'assets/theme.js is missing in picker mode', { scope: PICKER }));
    } else {
      const js = readText(path.join(distDir, themeFile));
      if (statSync(path.join(distDir, themeFile)).size >= 2048) violations.push(violation('theme-script', themeFile, 'theme.js is 2048 bytes or larger', { scope: PICKER }));
      if (!js.includes('scrypath-theme')) violations.push(violation('theme-script', themeFile, 'theme.js does not use the scrypath-theme storage key', { scope: PICKER }));
      for (const { literal } of colorLiteralsInJs(js)) violations.push(violation('theme-script', themeFile, `theme.js contains the color literal ${literal}`, { scope: PICKER }));
    }
  } else if (existsSync(path.join(distDir, themeFile))) {
    violations.push(violation('theme-script', themeFile, 'light-only mode must not ship theme.js', { scope: PICKER }));
  }

  // Closed hex set over css, svg, js and HTML attributes.
  for (const file of files) {
    const extension = extensionOf(file);
    let found = [];
    if (extension === '.css') {
      for (const declaration of cssDeclarations(readText(path.join(distDir, file)))) found.push(...hexesIn(neutralizeValue(declaration.value), { includeShort: true }));
    } else if (extension === '.js') {
      found = hexesIn(readText(path.join(distDir, file)));
    } else if (extension === '.svg' || extension === '.html') {
      const markup = readText(path.join(distDir, file));
      for (const tag of htmlTags(markup)) {
        for (const [name, value] of Object.entries(tag.attrs)) {
          if (!REFERENCE_ATTRIBUTES.has(name)) found.push(...hexesIn(value, { includeShort: name === 'style' || COLOR_ATTRIBUTES.has(name) }));
        }
      }
      for (const match of stripHtmlComments(markup).matchAll(/<style\b[^>]*>([\s\S]*?)<\/style>/gi)) {
        for (const declaration of cssDeclarations(match[1])) found.push(...hexesIn(declaration.value, { includeShort: true }));
      }
    }
    for (const hex of new Set(found)) {
      if (!closed.has(hex)) violations.push(violation('hex-outside-brand-set', file, `${hex} is not a brand token, contrast-pair or Control Edge color`));
    }
    if (['.css', '.js', '.svg'].includes(extension)) {
      const text = readText(path.join(distDir, file));
      for (const hex of CARVED_OUT_HEX) {
        if (text.toLowerCase().includes(hex)) violations.push(violation('carved-out-hex', file, `contains the retired value ${hex}`));
      }
      if (extension !== '.svg' && UNTHEMED_FAVICON.test(text)) violations.push(violation('unthemed-favicon', file, 'references the unthemed favicon.svg, which renders black'));
    }
  }
  return violations;
}

export const codesOf = violations => [...new Set(violations.map(item => item.code))].sort();
