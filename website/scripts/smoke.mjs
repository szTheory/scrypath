import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Live-URL smoke for the deployed (or locally served) site. Dependency-free: Node built-ins and the
// global fetch only. The base URL comes from SCRYPATH_SMOKE_URL (the deploy job passes the Pages
// page_url), falling back to SCRYPATH_SITE_URL; with neither the script fails with a message.
//
// It fetches the home page and checks, each as an `ok` or `not ok` line (exit 1 on any `not ok`):
//
//   home       the home page answers 200
//   base-path  every asset URL the page declares (stylesheets, scripts, font preloads, lockups, icons,
//              og and twitter images) resolves to the base URL's origin and path prefix, and none is
//              written root-absolute; a URL outside the base is reported and never fetched
//   stylesheet styles.css and tokens.css are declared, and every declared stylesheet answers 200 as
//              text/css with a body (a page that loses either one still answers 200 but looks broken)
//   script     every declared script (theme.js) answers 200 as JavaScript with a body
//   font       the preloaded ui font answers 200 as font/woff2 with the sha256 pinned in
//              brand/brand.pin.json
//   lockups    the light and the dark lockup answer 200 with an image content type
//   card       the social card (og:image) answers 200, starts with the PNG signature and matches its pin
//   favicon    the declared favicon.ico answers 200
//
// Every request carries a ?smoke=<run id or timestamp> query to step around the edge cache (Pages
// answers max-age=600). A request is retried (at most `attempts` tries, `retryDelayMs` apart) only for
// a network error, a 404 or a 5xx, which is what propagation right after a deploy looks like. A
// response that arrives and is wrong (a 200 with the wrong hash, say) is final: no loop.
//
// Each request, headers and body together, is abandoned after `timeoutMs` (20 seconds by default), so a
// host that accepts the connection and then stalls cannot hold the deploy job for the platform default
// of minutes per request. An abandoned request is a network error and is retried like one.

const scriptsDir = path.dirname(fileURLToPath(import.meta.url));
const defaultRepoRoot = path.resolve(scriptsDir, '..', '..');

const FONT_PIN = 'scrypath_ops/priv/static/assets/fonts/ui.woff2';
const CARD_PIN = 'brand/assets/social/scrypath-social-card-1280x640.png';
const PNG_SIGNATURE = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

const sha256 = buffer => createHash('sha256').update(buffer).digest('hex');
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

function loadPins(repoRoot) {
  const pin = JSON.parse(readFileSync(path.join(repoRoot, 'brand', 'brand.pin.json'), 'utf8'));
  const byPath = new Map(pin.assets.map(asset => [asset.path, asset.sha256]));
  return {
    font: byPath.get(FONT_PIN),
    card: byPath.get(CARD_PIN)
  };
}

// Tags and attributes of the built HTML, which is generated and double-quoted. A regex is enough here
// and keeps the script free of dependencies.
function tagsOf(html, names) {
  const wanted = new RegExp(`<(${names.join('|')})\\b([^>]*)>`, 'gi');
  const tags = [];
  for (const match of html.matchAll(wanted)) {
    const attributes = {};
    for (const attribute of match[2].matchAll(/([a-zA-Z][\w:-]*)\s*=\s*(?:"([^"]*)"|'([^']*)')/g)) {
      attributes[attribute[1].toLowerCase()] = attribute[2] ?? attribute[3];
    }
    tags.push({ name: match[1].toLowerCase(), attributes });
  }
  return tags;
}

// One GET with the cache-busting query and the retry policy described above.
async function request(url, { attempts, retryDelayMs, timeoutMs, token }) {
  const target = new URL(url);
  target.searchParams.set('smoke', token);
  let last;
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      const response = await fetch(target, { redirect: 'follow', signal: AbortSignal.timeout(timeoutMs) });
      const body = Buffer.from(await response.arrayBuffer());
      last = {
        status: response.status,
        contentType: response.headers.get('content-type') ?? '',
        finalUrl: response.url,
        body
      };
      if (response.status !== 404 && response.status < 500) {
        return last;
      }
    } catch (error) {
      last = { status: 0, contentType: '', finalUrl: String(target), body: Buffer.alloc(0), error: String(error?.message ?? error) };
    }
    if (attempt < attempts) {
      await sleep(retryDelayMs);
    }
  }
  return last;
}

function describe(response) {
  return response.error ? `network error: ${response.error}` : `status ${response.status}`;
}

// Runs every check and resolves with { ok, results: [{ code, ok, name, detail }] }. Never throws for a
// failed check; a problem reading the pins is itself reported as a failed check.
export async function runSmoke(baseUrl, { attempts = 3, retryDelayMs = 10000, timeoutMs = 20000, repoRoot = defaultRepoRoot, token } = {}) {
  const results = [];
  const record = (code, ok, name, detail = '') => results.push({ code, ok, name, detail });
  const finish = () => ({ ok: results.every(result => result.ok), results });

  const base = new URL(baseUrl);
  if (!base.pathname.endsWith('/')) {
    base.pathname = `${base.pathname}/`;
  }
  base.search = '';
  base.hash = '';
  const basePath = base.pathname;
  const runToken = token ?? process.env.GITHUB_RUN_ID ?? String(Date.now());
  const options = { attempts, retryDelayMs, timeoutMs, token: runToken };

  let pins;
  try {
    pins = loadPins(repoRoot);
  } catch (error) {
    record('pins', false, 'brand/brand.pin.json is readable', String(error.message));
    return finish();
  }
  if (!pins.font || !pins.card) {
    record('pins', false, 'brand.pin.json pins the ui font and the social card', `font=${pins.font ?? 'missing'} card=${pins.card ?? 'missing'}`);
    return finish();
  }

  const home = await request(base.href, options);
  if (home.status !== 200) {
    record('home', false, `home page ${base.href} answers 200`, describe(home));
    return finish();
  }
  record('home', true, `home page ${base.href} answers 200`);

  const html = home.body.toString('utf8');
  const tags = tagsOf(html, ['link', 'meta', 'img', 'script']);
  const attr = (tag, name) => tag.attributes[name];
  const metaContent = property =>
    tags.find(tag => tag.name === 'meta' && (attr(tag, 'property') === property || attr(tag, 'name') === property))?.attributes.content;

  const preloads = tags.filter(tag => tag.name === 'link' && attr(tag, 'rel') === 'preload' && attr(tag, 'as') === 'font');
  const lockupImages = tags.filter(tag => tag.name === 'img' && /scrypath-lockup-(light|dark)\.svg$/.test(attr(tag, 'src') ?? ''));
  const iconLinks = tags.filter(tag => tag.name === 'link' && /(^|\s)icon(\s|$)/.test(attr(tag, 'rel') ?? ''));
  const stylesheets = tags.filter(tag => tag.name === 'link' && /(^|\s)stylesheet(\s|$)/i.test(attr(tag, 'rel') ?? ''));
  const scripts = tags.filter(tag => tag.name === 'script' && attr(tag, 'src') !== undefined);

  // Every declared asset URL: where it came from, its raw value and where it resolves.
  const declared = [
    ...stylesheets.map(tag => ['stylesheet', attr(tag, 'href')]),
    ...scripts.map(tag => ['script', attr(tag, 'src')]),
    ...preloads.map(tag => ['font preload', attr(tag, 'href')]),
    ...lockupImages.map(tag => ['lockup image', attr(tag, 'src')]),
    ...iconLinks.map(tag => ['icon link', attr(tag, 'href')]),
    ['og:image', metaContent('og:image')],
    ['twitter:image', metaContent('twitter:image')]
  ];
  const problems = [];
  const resolved = new Map();
  for (const [label, raw] of declared) {
    if (!raw) {
      problems.push(`${label} is missing`);
      continue;
    }
    let url;
    try {
      url = new URL(raw, base);
    } catch {
      problems.push(`${label} ${raw} is not a URL`);
      continue;
    }
    if (basePath !== '/' && /^\/(?!\/)/.test(raw)) {
      problems.push(`${label} ${raw} is root-absolute`);
    }
    if (url.origin !== base.origin || !url.pathname.startsWith(basePath)) {
      problems.push(`${label} ${raw} resolves to ${url.href}, outside ${base.origin}${basePath}`);
      continue;
    }
    resolved.set(`${label}\u0000${raw}`, url);
  }
  record('base-path', problems.length === 0, `every declared asset URL stays under ${base.origin}${basePath}`, problems.join('; '));

  // The URL of a declared asset only when it stayed inside the base; an outside URL is never fetched.
  const inside = (label, raw) => (raw ? resolved.get(`${label}\u0000${raw}`) : undefined);
  const check = async (code, name, url, verify) => {
    if (!url) {
      record(code, false, name, 'not declared by the page, or outside the base path, so it was not fetched');
      return;
    }
    const response = await request(url.href, options);
    if (response.status !== 200) {
      record(code, false, name, `${url.pathname}: ${describe(response)}`);
      return;
    }
    const failure = verify(response, url);
    record(code, !failure, name, failure ? `${url.pathname}: ${failure}` : '');
  };

  const hasBody = response => (response.body.length > 0 ? '' : 'the body is empty');
  const asType = (pattern, expected) => response =>
    pattern.test(response.contentType) ? hasBody(response) : `content-type is ${JSON.stringify(response.contentType)}, expected ${expected}`;

  for (const name of ['styles.css', 'tokens.css']) {
    const declaredHere = stylesheets.some(tag => (attr(tag, 'href') ?? '').split(/[?#]/)[0].endsWith(`/${name}`));
    if (!declaredHere) {
      record('stylesheet', false, `the page declares ${name}`, `no <link rel="stylesheet"> names ${name}`);
    }
  }
  for (const link of stylesheets) {
    const href = attr(link, 'href');
    await check('stylesheet', `stylesheet ${href} answers 200 as CSS`, inside('stylesheet', href), asType(/^text\/css\b/i, 'text/css'));
  }
  for (const script of scripts) {
    const src = attr(script, 'src');
    await check('script', `script ${src} answers 200 as JavaScript`, inside('script', src), asType(/^(?:text|application)\/(?:x-)?(?:javascript|ecmascript)\b/i, 'a JavaScript type'));
  }

  const uiPreload = preloads.find(tag => /\/ui\.woff2$/.test(attr(tag, 'href') ?? ''));
  await check('font', 'the ui font answers 200 as font/woff2 with its pinned hash', inside('font preload', uiPreload && attr(uiPreload, 'href')), response => {
    if (!/^font\/woff2\b/.test(response.contentType)) {
      return `content-type is ${JSON.stringify(response.contentType)}, expected font/woff2`;
    }
    const actual = sha256(response.body);
    return actual === pins.font ? '' : `sha256 ${actual} differs from the pinned ${pins.font}`;
  });

  for (const theme of ['light', 'dark']) {
    const image = lockupImages.find(tag => attr(tag, 'src').endsWith(`scrypath-lockup-${theme}.svg`));
    await check('lockups', `the ${theme} lockup answers 200 as an image`, inside('lockup image', image && attr(image, 'src')), response =>
      /^image\//.test(response.contentType) ? '' : `content-type is ${JSON.stringify(response.contentType)}, expected an image type`
    );
  }

  await check('card', 'the social card answers 200 as the pinned PNG', inside('og:image', metaContent('og:image')), response => {
    if (!response.body.subarray(0, PNG_SIGNATURE.length).equals(PNG_SIGNATURE)) {
      return 'the body does not start with the PNG signature';
    }
    const actual = sha256(response.body);
    return actual === pins.card ? '' : `sha256 ${actual} differs from the pinned ${pins.card}`;
  });

  const ico = iconLinks.find(tag => /\/favicon\.ico$/.test(attr(tag, 'href') ?? ''));
  await check('favicon', 'favicon.ico answers 200', inside('icon link', ico && attr(ico, 'href')), () => '');

  return finish();
}

function resolveBaseUrl() {
  const value = process.env.SCRYPATH_SMOKE_URL || process.env.SCRYPATH_SITE_URL;
  if (!value) {
    console.error('smoke needs a base URL: set SCRYPATH_SMOKE_URL (or SCRYPATH_SITE_URL) to the site URL, for example https://sztheory.github.io/scrypath/');
    process.exit(1);
  }
  return value;
}

async function main() {
  const baseUrl = resolveBaseUrl();
  console.log(`smoke: ${baseUrl}`);
  const { ok, results } = await runSmoke(baseUrl);
  for (const result of results) {
    console.log(`${result.ok ? 'ok' : 'not ok'} - ${result.name}${result.ok || !result.detail ? '' : ` (${result.detail})`}`);
  }
  console.log(ok ? `smoke passed (${results.length} checks)` : 'smoke FAILED');
  process.exit(ok ? 0 : 1);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  await main();
}
