import { chromium } from 'playwright';
import { createHash } from 'node:crypto';
import { existsSync } from 'node:fs';
import { mkdir, rm } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { FONT_FACES, expectedRoles, loadBrand, PINNED_OUTPUTS } from './lib/contract.mjs';
import { startServer } from './lib/server.mjs';
import { compositeOver, contrastRatio, contrastRatioRaw, hexToColor, parseCssColor, roundRatio, toHex } from './lib/wcag.mjs';
import { THEME_MODE } from './theme-mode.mjs';

// Browser assertions for the built website, run at http://127.0.0.1:<port>/scrypath/ (the production
// URL shape: GitHub Pages serves the site under /scrypath/ and 404s at the origin root). Written to
// the final expectations of D-29, D-30 and D-31, so the old identity is red and the re-skin turns it
// green. Groups: production-shape, resolver, contrast, identity, theme-picker, motion.
//
//   node scripts/check.mjs [--groups a,b] [--no-screenshots] [--dir <dist>]
//
// Output: one `ok <group> - <name>` or `not ok <group> - <name>: <reason>` line per assertion and
// exactly one final `check-summary: ran=<n> failed=<groups or none>` line (a crash prints none, which
// callers treat as failure). Exit 1 when any selected assertion fails or a selected group ran fewer
// assertions than its floor, so a group filter can never pass vacuously.
//
// Chromium only. SCRYPATH_BROWSER_CHANNEL (for example `chrome`) launches an installed browser; if that
// launch throws the check warns and falls back to the default Chromium once.

const websiteDir = fileURLToPath(new URL('..', import.meta.url));
const repoRoot = path.resolve(websiteDir, '..');
const artifactsDir = path.join(websiteDir, 'artifacts');
const BASE = '/scrypath/';
const THEME_KEY = 'scrypath-theme';
const HERO_SHIFT_TOLERANCE_PX = 12;
const PAGES = ['', 'docs/', 'operators/', 'evaluate/'];
const ALL_GROUPS = ['production-shape', 'resolver', 'contrast', 'identity', 'theme-picker', 'motion'];
const FLOORS = { 'theme-picker': 10, contrast: 12, identity: 8 };
const PICKER_MODE = THEME_MODE === 'picker';

const args = process.argv.slice(2);
const valueOf = name => {
  const index = args.indexOf(name);
  return index >= 0 ? args[index + 1] : undefined;
};
const selected = new Set((valueOf('--groups') ?? ALL_GROUPS.join(',')).split(',').map(group => group.trim()).filter(Boolean));
for (const group of selected) {
  if (!ALL_GROUPS.includes(group)) throw new Error(`Unknown group "${group}" (known: ${ALL_GROUPS.join(', ')})`);
}
const wants = (...groups) => groups.some(group => selected.has(group));
const distDir = path.resolve(valueOf('--dir') ?? path.join(websiteDir, 'dist'));

const brandDir = path.join(repoRoot, 'brand');
const brandData = loadBrand(brandDir);
const roles = expectedRoles(brandData);
const pairs = brandData.brand.color.contrastPairs;
const pinned = new Map(brandData.pin.assets.map(asset => [asset.path, asset.sha256]));
const fontPin = name => pinned.get(PINNED_OUTPUTS[`assets/fonts/${name}`]);

// ---------------------------------------------------------------------------
// Assertion runner
// ---------------------------------------------------------------------------

const results = [];

async function check(groups, name, fn) {
  const list = [].concat(groups);
  if (!wants(...list)) return;
  const label = list.join('+');
  try {
    const note = await fn();
    results.push({ groups: list, ok: true });
    console.log(`ok ${label} - ${name}${note ? ` (${note})` : ''}`);
  } catch (error) {
    const reason = String(error?.message ?? error).replace(/\s+/g, ' ').trim();
    results.push({ groups: list, ok: false });
    console.log(`not ok ${label} - ${name}: ${reason}`);
  }
}

// A group body that throws outside a check() (for example the page failed to load) is itself a failure.
async function runGroup(group, body) {
  try {
    await body();
  } catch (error) {
    const reason = String(error?.message ?? error).replace(/\s+/g, ' ').trim();
    results.push({ groups: [group], ok: false });
    console.log(`not ok ${group} - group setup: ${reason}`);
  }
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function equal(actual, expected, what) {
  if (actual !== expected) throw new Error(`${what}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
}

const rgbString = hex => {
  const color = hexToColor(hex);
  return `rgb(${color.r}, ${color.g}, ${color.b})`;
};

// ---------------------------------------------------------------------------
// Browser helpers
// ---------------------------------------------------------------------------

async function launchBrowser() {
  const channel = process.env.SCRYPATH_BROWSER_CHANNEL || undefined;
  if (channel) {
    try {
      return await chromium.launch({ channel });
    } catch (error) {
      console.warn(`warning: launching the "${channel}" browser channel failed (${String(error.message).split('\n')[0]}); falling back to the default Chromium`);
    }
  }
  return chromium.launch();
}

// Runs fn(context) in a fresh browser context, with init scripts applied first, and always closes it.
async function withContext(browser, options, init, fn) {
  const context = await browser.newContext(options);
  try {
    for (const script of init) await context.addInitScript(script.fn, script.arg);
    return await fn(context);
  } finally {
    await context.close();
  }
}

const storeTheme = value => ({
  fn: ([key, stored]) => {
    try {
      window.localStorage.setItem(key, stored);
    } catch (error) {
      /* storage unavailable */
    }
  },
  arg: [THEME_KEY, value]
});

const collectSignals = {
  fn: () => {
    window.__cspViolations = [];
    document.addEventListener('securitypolicyviolation', event => {
      window.__cspViolations.push(`${event.violatedDirective} ${event.blockedURI}`);
    }, true);
  }
};

// Console errors, page errors, off-origin requests and (via the init script) CSP violations.
function listen(page, origin, bucket) {
  page.on('console', message => {
    if (message.type() === 'error') bucket.errors.push(`console: ${message.text()}`);
  });
  page.on('pageerror', error => bucket.errors.push(`pageerror: ${error.message}`));
  page.on('request', request => {
    const url = request.url();
    if (/^(data|blob|about):/.test(url)) return;
    if (new URL(url).origin !== origin) bucket.offOrigin.push(url);
  });
}

async function settle(page) {
  await page.evaluate(() => document.fonts.ready);
  await page.waitForLoadState('networkidle');
}

async function open(context, url, bucket, origin) {
  const page = await context.newPage();
  if (bucket) listen(page, origin, bucket);
  await page.goto(url, { waitUntil: 'load' });
  await settle(page);
  return page;
}

// Computed color and the chain of ancestor backgrounds, outermost first. Chromium serializes colors as
// rgb(), rgba() or color(srgb ...); wcag.mjs parses all three and composites alpha in Node.
async function measure(page, selector) {
  const measured = await page.evaluate(sel => {
    const element = document.querySelector(sel);
    if (!element) return null;
    const chain = [];
    for (let node = element; node; node = node.parentElement) {
      const style = getComputedStyle(node);
      chain.unshift({ color: style.backgroundColor, image: style.backgroundImage });
    }
    const style = getComputedStyle(element);
    return {
      color: style.color,
      chain,
      outlineColor: style.outlineColor,
      outlineWidth: style.outlineWidth,
      outlineStyle: style.outlineStyle,
      outlineOffset: style.outlineOffset
    };
  }, selector);
  if (!measured) throw new Error(`selector not found: ${selector}`);
  return measured;
}

function resolveSurface(chain) {
  let surface = { r: 255, g: 255, b: 255, a: 1 };
  for (const layer of chain) {
    if (layer.image && layer.image !== 'none') throw new Error(`a background image sits under the text (${layer.image.slice(0, 40)}), so the surface cannot be resolved from colors`);
    const color = parseCssColor(layer.color);
    if (color.a === 0) continue;
    surface = compositeOver(color, surface);
  }
  return surface;
}

const forms = new Set();
function noteForm(value) {
  forms.add(/^[a-z-]+\(/.exec(value)?.[0] ?? value);
}

async function pageHex(page) {
  const measured = await measure(page, 'body');
  for (const layer of measured.chain) noteForm(layer.color);
  return toHex(resolveSurface(measured.chain));
}

async function visibleLockups(page) {
  return page.$$eval('img', images =>
    images
      .filter(image => /scrypath-lockup/.test(image.getAttribute('src') ?? ''))
      .map(image => {
        const style = getComputedStyle(image);
        const box = image.getBoundingClientRect();
        return {
          src: image.getAttribute('src'),
          visible: style.display !== 'none' && style.visibility !== 'hidden' && box.width > 0 && box.height > 0,
          naturalWidth: image.naturalWidth,
          width: box.width
        };
      })
      .filter(image => image.visible)
  );
}

const pressedChoices = page =>
  page.$$eval('.theme-picker [data-theme-choice]', buttons => buttons.filter(button => button.getAttribute('aria-pressed') === 'true').map(button => button.getAttribute('data-theme-choice')));

async function pickerVisible(page) {
  return page.locator('.theme-picker').first().isVisible();
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

if (!existsSync(path.join(distDir, 'index.html'))) {
  throw new Error(`${distDir} has no index.html: run npm run build first`);
}

const server = await startServer({ dir: distDir, base: BASE, log: true });
const origin = server.origin;
const baseUrl = server.baseUrl;
const url = suffix => `${baseUrl}${suffix}`;
let browser;

try {
  browser = await launchBrowser();
  console.log(`check: theme mode ${THEME_MODE}, serving ${distDir} at ${baseUrl}`);

  // -------------------------------------------------------------------------
  // production-shape
  // -------------------------------------------------------------------------
  if (wants('production-shape')) {
    await runGroup('production-shape', async () => {
      await check('production-shape', 'the origin root answers 404', async () => {
        equal((await fetch(`${origin}/`)).status, 404, 'GET /');
      });
      await check('production-shape', '/index.html at the origin root answers 404', async () => {
        equal((await fetch(`${origin}/index.html`)).status, 404, 'GET /index.html');
      });
      for (const page of PAGES) {
        await check('production-shape', `${BASE}${page} answers 200`, async () => {
          equal((await fetch(url(page))).status, 200, `GET ${BASE}${page}`);
        });
      }
      await withContext(browser, { reducedMotion: 'reduce' }, [], async context => {
        for (const pagePath of PAGES) {
          await check('production-shape', `${BASE}${pagePath} has no root-absolute href, src or css url`, async () => {
            const page = await open(context, url(pagePath));
            try {
              const attributes = await page.$$eval('[href], [src]', elements => elements.map(element => element.getAttribute('href') ?? element.getAttribute('src')));
              const rootAbsolute = attributes.filter(value => /^\/(?!\/)/.test(value ?? ''));
              assert(rootAbsolute.length === 0, `root-absolute values in the DOM: ${rootAbsolute.join(', ')}`);
              const sheets = await page.$$eval('link[rel~="stylesheet"]', links => links.map(link => link.href));
              for (const sheet of sheets) {
                const css = await (await fetch(sheet)).text();
                const bad = [...css.matchAll(/url\(\s*["']?(\/(?!\/)[^)"']*)/g)].map(match => match[1]);
                assert(bad.length === 0, `root-absolute url() in ${sheet}: ${bad.join(', ')}`);
              }
            } finally {
              await page.close();
            }
          });
        }
      });
    });
  }

  // -------------------------------------------------------------------------
  // resolver: proves the contrast resolver on planted translucent surfaces (no site involved)
  // -------------------------------------------------------------------------
  if (wants('resolver')) {
    await runGroup('resolver', async () => {
      await withContext(browser, {}, [], async context => {
        const page = await context.newPage();
        const planted = async (surface, text) => {
          await page.setContent(`<body style="margin:0;background:#FFFFFF"><div id="s" style="background:${surface}"><span id="t" style="color:${text}">sample</span></div></body>`);
          const measured = await measure(page, '#t');
          const background = resolveSurface((await measure(page, '#s')).chain);
          return { measured, background, ratio: contrastRatio(parseCssColor(measured.color), background), forms: [...(await measure(page, '#s')).chain.map(layer => layer.color), measured.color] };
        };
        await check('resolver', 'text over a black 50 percent rgba surface over white resolves to the hand-computed 5.32', async () => {
          const result = await planted('rgba(0, 0, 0, 0.5)', 'black');
          result.forms.forEach(noteForm);
          equal(toHex(result.background), '#808080', 'composited surface');
          equal(roundRatio(result.ratio), 5.32, 'ratio');
          return `computed ${result.forms.join(' / ')}`;
        });
        await check('resolver', 'the same surface written with color-mix in srgb resolves to the same 5.32', async () => {
          const result = await planted('color-mix(in srgb, black 50%, transparent)', 'black');
          result.forms.forEach(noteForm);
          equal(toHex(result.background), '#808080', 'composited surface');
          equal(roundRatio(result.ratio), 5.32, 'ratio');
          return `computed ${result.forms.join(' / ')}`;
        });
        await check('resolver', 'translucent text over an opaque surface is composited before the ratio', async () => {
          const result = await planted('#FFFFFF', 'rgba(0, 0, 0, 0.5)');
          result.forms.forEach(noteForm);
          equal(roundRatio(result.ratio), roundRatio(contrastRatioRaw('#808080', '#FFFFFF')), 'ratio');
          equal(roundRatio(result.ratio), 3.95, 'ratio');
        });
        await check('resolver', 'an opaque black on white surface resolves to 21', async () => {
          const result = await planted('#FFFFFF', 'black');
          equal(roundRatio(result.ratio), 21, 'ratio');
        });
        await check('resolver', 'a background image under text makes the surface unresolvable instead of guessing', async () => {
          await page.setContent('<body style="margin:0;background:#FFFFFF"><div id="s" style="background-image:linear-gradient(#FFFFFF,#000000)"><span id="t">x</span></div></body>');
          let threw = false;
          try {
            resolveSurface((await measure(page, '#t')).chain);
          } catch {
            threw = true;
          }
          assert(threw, 'resolveSurface accepted a gradient surface');
        });
        await page.close();
      });
    });
  }

  // -------------------------------------------------------------------------
  // contrast: the six brand pair ids, from computed colors through the resolver
  // -------------------------------------------------------------------------
  if (wants('contrast', 'theme-picker')) {
    await runGroup('contrast', async () => {
      const pair = id => pairs.find(candidate => candidate.id === id);
      const themes = PICKER_MODE ? ['light', 'dark'] : ['light'];
      const surfaceGroups = theme => (theme === 'dark' ? ['contrast', 'theme-picker'] : ['contrast']);

      for (const theme of themes) {
        const groups = surfaceGroups(theme);
        if (!wants(...groups)) continue;
        const init = theme === 'dark' ? [storeTheme('dark')] : [];
        await withContext(browser, { reducedMotion: 'reduce', viewport: { width: 1280, height: 900 } }, init, async context => {
          const page = await open(context, url(''));
          try {
            const targets = {
              body: { text: 'body', surface: 'body' },
              descriptor: { text: '.hero-copy .lede', surface: '.hero-copy .lede' },
              caption: { text: '.hero-visual .panel-kicker > span:first-child', surface: '.hero-visual .panel-kicker > span:first-child' },
              link: { text: '.route-item strong', surface: '.route-item strong' }
            };
            // Each pair is two assertions: the resolved background is the stated one, and the ratio
            // from the resolver reaches the minimum and rounds to the published value.
            const checkPair = async (id, state, selector, prepare) => {
              const stated = pair(id)[theme];
              const label = `${id} ${theme}${state ? ` ${state}` : ''}`;
              const read = async () => {
                if (prepare) await prepare();
                const measured = await measure(page, selector);
                measured.chain.forEach(layer => noteForm(layer.color));
                noteForm(measured.color);
                return { measured, surface: resolveSurface(measured.chain) };
              };
              await check(groups, `${label}: ${selector} sits on the stated background`, async () => {
                const { surface } = await read();
                equal(toHex(surface), stated.background.toUpperCase(), 'resolved background');
                return toHex(surface);
              });
              await check(groups, `${label}: ${selector} reaches the published ratio`, async () => {
                const { measured, surface } = await read();
                const foreground = parseCssColor(measured.color);
                const raw = contrastRatio(foreground, surface);
                assert(raw >= pair(id).minimum, `ratio ${raw.toFixed(3)} is below the ${pair(id).minimum} minimum`);
                equal(roundRatio(raw), stated.contrast, 'ratio');
                return `${toHex(foreground)} on ${toHex(surface)} = ${roundRatio(raw)}`;
              });
            };
            for (const [id, target] of Object.entries(targets)) {
              await checkPair(id, '', target.text);
            }

            const primary = '.button-primary';
            const focusButton = async () => {
              await page.mouse.move(0, 0);
              await page.locator(primary).first().focus();
              const visible = await page.$eval(primary, element => element.matches(':focus-visible'));
              if (!visible) {
                await page.evaluate(() => document.activeElement?.blur());
                for (let presses = 0; presses < 60; presses += 1) {
                  await page.keyboard.press('Tab');
                  if (await page.$eval(primary, element => element === document.activeElement)) break;
                }
              }
              assert(await page.$eval(primary, element => element.matches(':focus-visible')), `${primary} does not match :focus-visible after keyboard focus`);
            };

            await check(groups, `focus ${theme}: the ring on ${primary} reaches the published ratio against the page`, async () => {
              await focusButton();
              const ring = await measure(page, primary);
              const body = await measure(page, 'body');
              const surface = resolveSurface(body.chain);
              const stated = pair('focus')[theme];
              equal(toHex(surface), stated.background.toUpperCase(), 'focus resolved page background');
              equal(ring.outlineStyle, 'solid', 'focus outline style');
              const raw = contrastRatio(parseCssColor(ring.outlineColor), surface);
              noteForm(ring.outlineColor);
              assert(raw >= pair('focus').minimum, `focus ratio ${raw.toFixed(3)} is below ${pair('focus').minimum}`);
              equal(roundRatio(raw), stated.contrast, 'focus ratio');
              return `${toHex(parseCssColor(ring.outlineColor))} on ${toHex(surface)} = ${roundRatio(raw)}`;
            });
            await check(groups, `focus ${theme}: the ring is at least 2 px wide and the filled button's outline-offset is at least 2 px`, async () => {
              await focusButton();
              const ring = await measure(page, primary);
              assert(parseFloat(ring.outlineWidth) >= 2, `outline width is ${ring.outlineWidth}`);
              assert(parseFloat(ring.outlineOffset) >= 2, `outline-offset is ${ring.outlineOffset}`);
            });

            await page.mouse.move(0, 0);
            await page.evaluate(() => document.activeElement?.blur());
            for (const state of ['rest', 'hover', 'focus-visible']) {
              await checkPair('button', state, primary, async () => {
                if (state === 'hover') {
                  await page.evaluate(() => document.activeElement?.blur());
                  await page.locator(primary).first().hover();
                } else if (state === 'focus-visible') {
                  await focusButton();
                } else {
                  await page.mouse.move(0, 0);
                  await page.evaluate(() => document.activeElement?.blur());
                }
              });
            }
          } finally {
            await page.close();
          }
        });
      }
    });
  }

  // -------------------------------------------------------------------------
  // identity
  // -------------------------------------------------------------------------
  if (wants('identity')) {
    await runGroup('identity', async () => {
      const signals = { errors: [], offOrigin: [], csp: [] };
      const fontBytes = async responses => {
        const out = [];
        for (const response of responses) {
          out.push({ url: response.url(), status: response.status(), type: response.headers()['content-type'], sha: createHash('sha256').update(await response.body()).digest('hex') });
        }
        return out;
      };

      // Fonts per page: home exactly the pinned three, every page a subset, each 200 with its pinned bytes.
      await withContext(browser, { reducedMotion: 'reduce', viewport: { width: 1280, height: 900 } }, [collectSignals], async context => {
        for (const pagePath of PAGES) {
          const page = await context.newPage();
          listen(page, origin, signals);
          const responses = [];
          page.on('response', response => {
            if (/\.woff2(\?|$)/.test(response.url())) responses.push(response);
          });
          await page.goto(url(pagePath), { waitUntil: 'load' });
          await settle(page);
          signals.csp.push(...(await page.evaluate(() => window.__cspViolations)));
          const fonts = await fontBytes(responses);
          const names = [...new Set(fonts.map(font => path.posix.basename(new URL(font.url).pathname)))].sort();
          await check('identity', `${BASE}${pagePath} loads ${pagePath === '' ? 'exactly the three' : 'a subset of the'} pinned same-origin woff2 files`, async () => {
            const allowed = Object.keys(FONT_FACES).sort();
            assert(fonts.every(font => new URL(font.url).origin === origin), 'a font came from another origin');
            if (pagePath === '') equal(names.join(), allowed.join(), 'woff2 files loaded after document.fonts.ready');
            else assert(names.length > 0 && names.every(name => allowed.includes(name)), `woff2 files loaded: ${names.join(', ') || 'none'}`);
            return names.join(', ');
          });
          await check('identity', `${BASE}${pagePath} fonts are 200, font/woff2 and byte-identical to their pins`, async () => {
            assert(fonts.length > 0, 'no font was requested');
            for (const font of fonts) {
              const name = path.posix.basename(new URL(font.url).pathname);
              equal(font.status, 200, `${name} status`);
              equal(font.type, 'font/woff2', `${name} content-type`);
              equal(font.sha, fontPin(name), `${name} sha256`);
            }
          });

          await check('identity', `${BASE}${pagePath} declared icons resolve with 200`, async () => {
            const icons = await page.$$eval('link[rel~="icon"]', links => links.map(link => link.href));
            assert(icons.length > 0, 'no icon link is declared');
            for (const icon of icons) equal((await fetch(icon)).status, 200, `GET ${icon}`);
            return `${icons.length} icons`;
          });

          if (pagePath === '') {
            await check('identity', 'computed families: Bricolage Grotesque for h1 and h2, Hanken Grotesk for body, Sometype Mono for code', async () => {
              const first = selector =>
                page.$eval(selector, element => getComputedStyle(element).fontFamily.split(',')[0].trim().replace(/["']/g, ''));
              equal(await first('h1'), 'Bricolage Grotesque', 'h1 family');
              equal(await first('h2'), 'Bricolage Grotesque', 'h2 family');
              equal(await first('body'), 'Hanken Grotesk', 'body family');
              equal(await first('code'), 'Sometype Mono', 'code family');
            });
            await check('identity', 'light theme: exactly one lockup is visible, the light one, loaded and at least 136 px wide', async () => {
              const shown = await visibleLockups(page);
              equal(shown.length, 1, 'visible lockup count');
              assert(/lockup-light/.test(shown[0].src), `the visible lockup is ${shown[0].src}`);
              assert(shown[0].naturalWidth > 0, 'the lockup did not load (naturalWidth 0)');
              assert(shown[0].width >= 136, `the lockup renders ${shown[0].width}px wide`);
            });
            await check('identity', 'light theme: the h1 display weight is 700', async () => {
              equal(await page.$eval('h1', element => getComputedStyle(element).fontWeight), '700', 'h1 font-weight');
            });
            await check('identity', 'the skip link is the first focusable element after one Tab', async () => {
              await page.evaluate(() => document.activeElement?.blur());
              await page.keyboard.press('Tab');
              assert(await page.evaluate(() => document.activeElement?.classList.contains('skip-link') === true), 'the first Tab stop is not the skip link');
            });
          }

          await check('identity', `${BASE}${pagePath} has no element under 12 px or with text-transform uppercase`, async () => {
            const offenders = await page.evaluate(() => {
              const found = [];
              for (const element of document.querySelectorAll('body *')) {
                const hasText = [...element.childNodes].some(node => node.nodeType === 3 && node.textContent.trim() !== '');
                if (!hasText) continue;
                const style = getComputedStyle(element);
                if (style.display === 'none') continue;
                if (parseFloat(style.fontSize) < 12) found.push(`${element.tagName.toLowerCase()}.${element.className} font-size ${style.fontSize}`);
                if (style.textTransform === 'uppercase') found.push(`${element.tagName.toLowerCase()}.${element.className} uppercase`);
              }
              return found;
            });
            assert(offenders.length === 0, offenders.slice(0, 5).join('; '));
          });
          await page.close();
        }
      });

      await check('identity', 'every page loads without a console error or page error', async () => {
        assert(signals.errors.length === 0, signals.errors.slice(0, 4).join('; '));
      });
      await check('identity', 'no securitypolicyviolation event fires on any page', async () => {
        assert(signals.csp.length === 0, signals.csp.slice(0, 4).join('; '));
      });
      await check('identity', 'no request leaves the server origin', async () => {
        assert(signals.offOrigin.length === 0, signals.offOrigin.slice(0, 4).join(', '));
      });

      // Dark theme (picker mode): the dark lockup is the one visible, and the display weight is 670.
      if (PICKER_MODE) {
        await withContext(browser, { reducedMotion: 'reduce', viewport: { width: 1280, height: 900 } }, [storeTheme('dark')], async context => {
          const page = await open(context, url(''));
          try {
            await check(['identity', 'theme-picker'], 'dark theme: exactly one lockup is visible, the dark one, loaded and at least 136 px wide', async () => {
              const shown = await visibleLockups(page);
              equal(shown.length, 1, 'visible lockup count');
              assert(/lockup-dark/.test(shown[0].src), `the visible lockup is ${shown[0].src}`);
              assert(shown[0].naturalWidth > 0, 'the lockup did not load (naturalWidth 0)');
              assert(shown[0].width >= 136, `the lockup renders ${shown[0].width}px wide`);
            });
            await check(['identity', 'theme-picker'], 'dark theme: the h1 display weight is the single dark weight 670', async () => {
              equal(await page.$eval('h1', element => getComputedStyle(element).fontWeight), '670', 'h1 font-weight');
            });
          } finally {
            await page.close();
          }
        });
      }

      // 320 px: no horizontal overflow on any page.
      await withContext(browser, { reducedMotion: 'reduce', viewport: { width: 320, height: 800 } }, [], async context => {
        for (const pagePath of PAGES) {
          await check('identity', `${BASE}${pagePath} has no horizontal overflow at 320 px`, async () => {
            const page = await open(context, url(pagePath));
            try {
              const [scrollWidth, clientWidth] = await page.evaluate(() => [document.documentElement.scrollWidth, document.documentElement.clientWidth]);
              assert(scrollWidth <= clientWidth, `scrollWidth ${scrollWidth} exceeds clientWidth ${clientWidth}`);
            } finally {
              await page.close();
            }
          });
        }
      });

      // Fonts blocked versus loaded: the h1 and the hero keep their height (the fallback faces match).
      for (const width of [390, 1440]) {
        await check('identity', `h1 and hero height at ${width} px differ by at most ${HERO_SHIFT_TOLERANCE_PX} px with fonts blocked versus loaded`, async () => {
          const heights = async blocked =>
            withContext(browser, { reducedMotion: 'reduce', viewport: { width, height: 900 } }, [], async context => {
              if (blocked) await context.route('**/*.woff2', route => route.abort());
              const page = await open(context, url(''));
              try {
                return await page.evaluate(() => ({
                  h1: document.querySelector('h1').getBoundingClientRect().height,
                  hero: document.querySelector('.hero').getBoundingClientRect().height
                }));
              } finally {
                await page.close();
              }
            });
          const loaded = await heights(false);
          const blocked = await heights(true);
          const dh1 = Math.abs(loaded.h1 - blocked.h1);
          const dhero = Math.abs(loaded.hero - blocked.hero);
          assert(dh1 <= HERO_SHIFT_TOLERANCE_PX && dhero <= HERO_SHIFT_TOLERANCE_PX, `h1 moves ${dh1.toFixed(1)} px and hero ${dhero.toFixed(1)} px (tolerance ${HERO_SHIFT_TOLERANCE_PX})`);
          return `h1 ${dh1.toFixed(1)} px, hero ${dhero.toFixed(1)} px`;
        });
      }
    });
  }

  // -------------------------------------------------------------------------
  // theme-picker (D-29): the picker's behavior, or in light-only mode its absence
  // -------------------------------------------------------------------------
  if (wants('theme-picker')) {
    await runGroup('theme-picker', async () => {
      const light = roles.page.light;
      const dark = roles.page.dark;
      const device = scheme => ({ reducedMotion: 'reduce', colorScheme: scheme, viewport: { width: 1280, height: 900 } });

      if (!PICKER_MODE) {
        // Light-only form: no picker, no theme.js, and a dark device still gets the light page.
        await withContext(browser, device('dark'), [], async context => {
          for (const pagePath of PAGES) {
            const page = await open(context, url(pagePath));
            try {
              await check('theme-picker', `${BASE}${pagePath} ships no theme picker`, async () => {
                equal(await page.locator('.theme-picker, [data-theme-choice]').count(), 0, 'picker elements');
              });
              await check('theme-picker', `${BASE}${pagePath} does not reference theme.js`, async () => {
                equal(await page.locator('script[src*="theme.js"]').count(), 0, 'theme.js script elements');
              });
              if (pagePath === '' || pagePath === 'docs/') {
                await check('theme-picker', `${BASE}${pagePath} on an emulated dark device is the light page`, async () => {
                  equal(await pageHex(page), light, 'page background');
                });
              }
            } finally {
              await page.close();
            }
          }
        });
        await withContext(browser, device('dark'), [], async context => {
          const page = await open(context, url(''));
          try {
            await check('theme-picker', 'print media on a dark device computes the light ink and shows the light lockup', async () => {
              await page.emulateMedia({ media: 'print' });
              equal(await page.$eval('body', element => getComputedStyle(element).color), rgbString(roles.ink.light), 'print ink');
              const shown = await visibleLockups(page);
              assert(shown.length === 1 && /lockup-light/.test(shown[0].src), `visible lockups in print: ${shown.map(item => item.src).join(', ')}`);
            });
          } finally {
            await page.close();
          }
        });
        return;
      }

      // JS off with an emulated dark device: light page, hidden picker.
      await withContext(browser, { ...device('dark'), javaScriptEnabled: false }, [], async context => {
        const page = await open(context, url('')).catch(async () => {
          const fallback = await context.newPage();
          await fallback.goto(url(''), { waitUntil: 'load' });
          return fallback;
        });
        try {
          await check('theme-picker', 'JavaScript off on a dark device: the page is the light page', async () => {
            equal(await pageHex(page), light, 'page background');
          });
          await check('theme-picker', 'JavaScript off: the picker is in the markup but not visible', async () => {
            equal(await page.locator('.theme-picker').count(), 1, 'picker elements in the markup');
            assert(!(await pickerVisible(page)), 'the picker is visible without JavaScript');
          });
        } finally {
          await page.close();
        }
      });

      // Empty storage on a dark device, then Dark, Light and System clicks, reload, and device changes.
      await withContext(browser, device('dark'), [], async context => {
        const page = await open(context, url(''));
        try {
          await check('theme-picker', 'empty storage on an emulated dark device computes the light page token', async () => {
            equal(await pageHex(page), light, 'page background');
          });
          await page.locator('.theme-picker').first().waitFor({ state: 'visible', timeout: 5000 }).catch(() => {});
          const choose = async (choice, expectedHex) => {
            await page.locator(`[data-theme-choice="${choice}"]`).click({ timeout: 5000 });
            equal(await pageHex(page), expectedHex, `page background after ${choice}`);
            equal(JSON.stringify(await pressedChoices(page)), JSON.stringify([choice]), `aria-pressed after ${choice}`);
          };
          await check('theme-picker', 'choosing Dark changes the background and sets aria-pressed on that button only', async () => {
            await choose('dark', dark);
          });
          await check('theme-picker', 'the Dark choice survives a reload', async () => {
            await page.reload({ waitUntil: 'load' });
            await settle(page);
            equal(await pageHex(page), dark, 'page background after reload');
            equal(JSON.stringify(await pressedChoices(page)), JSON.stringify(['dark']), 'aria-pressed after reload');
          });
          await check('theme-picker', 'choosing Light changes the background back and sets aria-pressed on that button only', async () => {
            await choose('light', light);
          });
          await check('theme-picker', 'choosing System on a dark device changes the background and sets aria-pressed on that button only', async () => {
            await choose('system', dark);
          });
          await check('theme-picker', 'System follows the emulated device scheme to light', async () => {
            await page.emulateMedia({ colorScheme: 'light' });
            equal(await pageHex(page), light, 'page background on a light device');
          });
          await check('theme-picker', 'System follows the emulated device scheme back to dark', async () => {
            await page.emulateMedia({ colorScheme: 'dark' });
            equal(await pageHex(page), dark, 'page background on a dark device');
          });
        } finally {
          await page.close();
        }
      });

      // Blocked storage: a throwing localStorage getter (Playwright has no switch for it).
      await withContext(
        browser,
        device('dark'),
        [
          {
            fn: () => {
              Object.defineProperty(window, 'localStorage', {
                get() {
                  throw new Error('storage blocked');
                }
              });
            }
          }
        ],
        async context => {
          const bucket = { errors: [], offOrigin: [] };
          const page = await open(context, url(''), bucket, origin);
          try {
            await check('theme-picker', 'blocked storage gives the light page', async () => {
              equal(await pageHex(page), light, 'page background');
              assert(bucket.errors.length === 0, `errors with blocked storage: ${bucket.errors.join('; ')}`);
            });
            await check('theme-picker', 'blocked storage leaves the picker in the markup but hidden', async () => {
              equal(await page.locator('.theme-picker').count(), 1, 'picker elements in the markup');
              assert(!(await pickerVisible(page)), 'the picker is visible although storage is blocked');
            });
          } finally {
            await page.close();
          }
        }
      );

      // Stored dark paints dark at DOMContentLoaded (read in an init-script listener, never paint timing).
      await withContext(
        browser,
        device('light'),
        [
          storeTheme('dark'),
          {
            fn: () => {
              document.addEventListener('DOMContentLoaded', () => {
                window.__dclBackground = getComputedStyle(document.body).backgroundColor;
                window.__dclHtmlBackground = getComputedStyle(document.documentElement).backgroundColor;
              });
            }
          }
        ],
        async context => {
          const page = await open(context, url(''));
          try {
            await check('theme-picker', 'stored dark computes the dark page background at DOMContentLoaded', async () => {
              const [body, html] = await page.evaluate(() => [window.__dclBackground, window.__dclHtmlBackground]);
              const wanted = rgbString(dark);
              assert(body === wanted || html === wanted, `body ${body}, html ${html} at DOMContentLoaded, expected ${wanted}`);
            });
          } finally {
            await page.close();
          }
        }
      );

      // A stored invalid value is light.
      await withContext(browser, device('dark'), [storeTheme('purple')], async context => {
        const page = await open(context, url(''));
        try {
          await check('theme-picker', 'a stored invalid value is treated as light', async () => {
            equal(await pageHex(page), light, 'page background');
          });
        } finally {
          await page.close();
        }
      });

      // A second page in the same context follows a pick made in the first (storage event).
      await withContext(browser, device('light'), [], async context => {
        const first = await open(context, url(''));
        const second = await open(context, url('docs/'));
        try {
          await check('theme-picker', 'a second page in the same context follows a pick made in the first', async () => {
            await first.locator('[data-theme-choice="dark"]').click({ timeout: 5000 });
            await second.waitForFunction(wanted => getComputedStyle(document.body).backgroundColor === wanted || getComputedStyle(document.documentElement).backgroundColor === wanted, rgbString(dark), { timeout: 5000 });
          });
        } finally {
          await first.close();
          await second.close();
        }
      });

      // Forced colors: one lockup that follows prefers-color-scheme, and a non-color pressed indicator.
      for (const [scheme, stored, wantedLockup] of [['dark', 'light', 'lockup-dark'], ['light', 'dark', 'lockup-light']]) {
        await withContext(browser, { ...device(scheme), forcedColors: 'active' }, [storeTheme(stored)], async context => {
          const page = await open(context, url(''));
          try {
            await check('theme-picker', `forced colors on a ${scheme} device with ${stored} chosen shows the one ${wantedLockup} lockup`, async () => {
              const shown = await visibleLockups(page);
              assert(shown.length === 1 && shown[0].src.includes(wantedLockup), `visible lockups: ${shown.map(item => item.src).join(', ') || 'none'}`);
            });
            if (scheme === 'dark') {
              await check('theme-picker', 'forced colors: the pressed picker button differs from the others in border-top-width', async () => {
                const widths = await page.$$eval('.theme-picker [data-theme-choice]', buttons =>
                  buttons.map(button => ({ pressed: button.getAttribute('aria-pressed') === 'true', width: getComputedStyle(button).borderTopWidth })));
                const pressed = widths.filter(item => item.pressed);
                const others = widths.filter(item => !item.pressed);
                assert(pressed.length === 1 && others.length === 2, `pressed buttons: ${JSON.stringify(widths)}`);
                assert(others.every(item => item.width !== pressed[0].width), `border-top-width is ${pressed[0].width} on the pressed button and ${others.map(item => item.width).join('/')} on the others`);
              });
            }
          } finally {
            await page.close();
          }
        });
      }

      // Print: stored dark prints the light ink and the light lockup.
      await withContext(browser, device('dark'), [storeTheme('dark')], async context => {
        const page = await open(context, url(''));
        try {
          await check('theme-picker', 'print media with stored dark computes the light ink', async () => {
            await page.emulateMedia({ media: 'print' });
            equal(await page.$eval('body', element => getComputedStyle(element).color), rgbString(roles.ink.light), 'print ink');
          });
          await check('theme-picker', 'print media with stored dark shows the light lockup only', async () => {
            await page.emulateMedia({ media: 'print' });
            const shown = await visibleLockups(page);
            assert(shown.length === 1 && /lockup-light/.test(shown[0].src), `visible lockups in print: ${shown.map(item => item.src).join(', ') || 'none'}`);
          });
        } finally {
          await page.close();
        }
      });
    });
  }

  // -------------------------------------------------------------------------
  // motion (D-24)
  // -------------------------------------------------------------------------
  if (wants('motion')) {
    await runGroup('motion', async () => {
      await withContext(browser, { reducedMotion: 'no-preference' }, [], async context => {
        const page = await open(context, url(''));
        try {
          await check('motion', 'without a reduced-motion preference the root scroll-behavior is smooth', async () => {
            equal(await page.evaluate(() => getComputedStyle(document.documentElement).scrollBehavior), 'smooth', 'scroll-behavior');
          });
        } finally {
          await page.close();
        }
      });
      await withContext(browser, { reducedMotion: 'reduce' }, [], async context => {
        const page = await open(context, url(''));
        try {
          await check('motion', 'with reduced motion the root scroll-behavior is not smooth', async () => {
            const value = await page.evaluate(() => getComputedStyle(document.documentElement).scrollBehavior);
            assert(value !== 'smooth', `scroll-behavior is ${value}`);
          });
          await check('motion', 'with reduced motion every element transition-duration computes to 0s', async () => {
            const offenders = await page.evaluate(() => {
              const found = [];
              for (const element of document.querySelectorAll('*')) {
                const durations = getComputedStyle(element).transitionDuration.split(',').map(value => value.trim());
                if (!durations.every(value => value === '0s')) found.push(`${element.tagName.toLowerCase()}.${element.className} ${durations.join(' ')}`);
              }
              return found;
            });
            assert(offenders.length === 0, `${offenders.length} elements keep a transition: ${offenders.slice(0, 5).join('; ')}`);
          });
        } finally {
          await page.close();
        }
      });
    });
  }

  // -------------------------------------------------------------------------
  // production-shape, late: the request log of the whole run
  // -------------------------------------------------------------------------
  if (wants('production-shape')) {
    await server.flush();
    await check('production-shape', 'the request log has no root /favicon.ico request and no 404 under /scrypath/', async () => {
      const rootFavicon = server.requests.filter(request => request.path === '/favicon.ico');
      const missing = server.requests.filter(request => request.status === 404 && request.path.startsWith(BASE));
      assert(rootFavicon.length === 0, `requests to the root /favicon.ico: ${rootFavicon.length}`);
      assert(missing.length === 0, `404s under ${BASE}: ${[...new Set(missing.map(request => request.path))].join(', ')}`);
      return `${server.requests.length} requests logged`;
    });
  }

  // -------------------------------------------------------------------------
  // Review screenshots (never gate): a failure here is logged and does not end the run, because every
  // assertion above has already been reported and a red job blocks the deploy behind it.
  // -------------------------------------------------------------------------
  try {
    await captureScreenshots(browser);
  } catch (error) {
    console.log(`screenshots: failed, ${String(error?.message ?? error).split('\n')[0]}; they do not gate`);
  }
} finally {
  await browser?.close();
  await server.stop();
}

if (forms.size > 0) {
  console.log(`check: computed color forms seen: ${[...forms].sort().join(', ')}`);
}

const failedGroups = new Set();
for (const result of results) {
  if (!result.ok) result.groups.forEach(group => failedGroups.add(group));
}
for (const group of selected) {
  const ran = results.filter(result => result.groups.includes(group)).length;
  const floor = FLOORS[group] ?? 1;
  if (ran < floor) {
    failedGroups.add(group);
    console.log(`not ok ${group} - floor: only ${ran} assertions ran, the floor is ${floor}, so the group did not really run`);
  }
}
console.log(`check-summary: ran=${results.length} failed=${failedGroups.size === 0 ? 'none' : [...failedGroups].sort().join(',')}`);
process.exit(failedGroups.size === 0 ? 0 : 1);

// ---------------------------------------------------------------------------

function uncommittedOutsidePlanning() {
  const status = spawnSync('git', ['status', '--porcelain'], { cwd: websiteDir, encoding: 'utf8' });
  if (status.status !== 0) return [];
  return status.stdout
    .split('\n')
    .filter(Boolean)
    .map(line => line.slice(3))
    .filter(file => !file.startsWith('.planning/'));
}

async function captureScreenshots(browserInstance) {
  if (args.includes('--no-screenshots')) {
    console.log('screenshots: skipped (--no-screenshots)');
    return;
  }
  const dirty = uncommittedOutsidePlanning();
  if (dirty.length > 0) {
    console.log(`screenshots: skipped, the tree has uncommitted changes outside .planning/ (${dirty.slice(0, 3).join(', ')}); no capture from a dirty tree`);
    return;
  }
  try {
    await rm(artifactsDir, { recursive: true, force: true });
    await mkdir(artifactsDir, { recursive: true });
  } catch (error) {
    if (!process.env.CI) {
      console.log(`screenshots: skipped, ${artifactsDir} is not writable (${error.message})`);
      return;
    }
    // Under CI an unwritable directory is reported as a failed capture by the caller, which logs it and
    // carries on: the artifact upload step already tolerates an empty directory.
    throw error;
  }
  const themes = PICKER_MODE ? ['light', 'dark'] : ['light'];
  for (const theme of themes) {
    for (const width of [1440, 390]) {
      await withContext(browserInstance, { reducedMotion: 'reduce', viewport: { width, height: 1000 } }, theme === 'dark' ? [storeTheme('dark')] : [], async context => {
        for (const pagePath of PAGES) {
          const page = await open(context, url(pagePath));
          const name = `${pagePath === '' ? 'home' : pagePath.replace('/', '')}-${theme}-${width}.png`;
          await page.screenshot({ path: path.join(artifactsDir, name), fullPage: true });
          await page.close();
        }
      });
    }
  }
  console.log(`screenshots: written to ${artifactsDir} for review only; they do not gate`);
}

