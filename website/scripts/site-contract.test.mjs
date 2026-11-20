// Static contract for the website (dependency-free: node built-ins only, no npm ci).
//
// Case names start with `live`, `planted` or `accept`; test/mix/tasks/website_contract_test.exs reads
// them. A `live` case runs against the real website/src and the real pinned brand files.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { startServer } from './lib/server.mjs';

const scriptsDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(scriptsDir, '..', '..');
const buildScript = path.join(scriptsDir, 'build.mjs');

async function readPin(sourcePath) {
  const pin = JSON.parse(await readFile(path.join(repoRoot, 'brand', 'brand.pin.json'), 'utf8'));
  const entry = pin.assets.find(asset => asset.path === sourcePath);
  assert.ok(entry, `brand.pin.json has an entry for ${sourcePath}`);
  return entry.sha256;
}

function runBuild({ out, siteUrl, env = {} }) {
  return spawnSync(process.execPath, [buildScript, '--out', out], {
    encoding: 'utf8',
    env: { ...process.env, SCRYPATH_SITE_URL: siteUrl, ...env }
  });
}

// Ordering for every case that needs a server: the server first (it reads files per request, so the
// directory may be empty), then the build with the local site URL. No network, no fixed port.
test('live tracer: the build serves tokens.css and a pinned font under /scrypath/ and 404s at the root', async () => {
  const dir = await mkdtemp(path.join(os.tmpdir(), 'scrypath-site-tracer-'));
  const server = await startServer({ dir, base: '/scrypath/' });
  try {
    const built = runBuild({ out: dir, siteUrl: server.baseUrl });
    assert.equal(built.status, 0, built.stderr);

    const css = await fetch(`${server.baseUrl}assets/tokens.css`);
    assert.equal(css.status, 200);
    const cssText = await css.text();
    assert.match(cssText, /--page:/);
    assert.match(cssText, /data-theme="dark"/);

    const font = await fetch(`${server.baseUrl}assets/fonts/ui.woff2`);
    assert.equal(font.status, 200);
    assert.equal(font.headers.get('content-type'), 'font/woff2');
    const fontHash = createHash('sha256').update(Buffer.from(await font.arrayBuffer())).digest('hex');
    assert.equal(fontHash, await readPin('scrypath_ops/priv/static/assets/fonts/ui.woff2'));

    const root = await fetch(`${server.origin}/`);
    assert.equal(root.status, 404);
  } finally {
    await server.stop();
    await rm(dir, { recursive: true, force: true });
  }
});
