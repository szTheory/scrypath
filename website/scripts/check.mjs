import { chromium } from 'playwright';
import { mkdir, rm } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const websiteDir = fileURLToPath(new URL('..', import.meta.url));
const artifactsDir = path.join(websiteDir, 'artifacts');
const port = 4173;
const baseUrl = `http://127.0.0.1:${port}`;

await rm(artifactsDir, { recursive: true, force: true });
await mkdir(artifactsDir, { recursive: true });

const server = spawn(process.execPath, ['scripts/serve.mjs', '--port', String(port)], {
  cwd: websiteDir,
  stdio: ['ignore', 'pipe', 'pipe']
});

const serverReady = new Promise((resolve, reject) => {
  let settled = false;
  server.stdout.on('data', chunk => {
    const text = String(chunk);
    process.stdout.write(text);
    if (!settled && text.includes(`http://127.0.0.1:${port}`)) {
      settled = true;
      resolve();
    }
  });
  server.stderr.on('data', chunk => {
    process.stderr.write(chunk);
  });
  server.on('exit', code => {
    if (!settled) {
      reject(new Error(`Preview server exited before becoming ready (code ${code ?? 'unknown'})`));
    }
  });
});

await serverReady;

const browser = await chromium.launch();
try {
await capture(browser, baseUrl, {
  path: path.join(artifactsDir, 'home-desktop.png'),
  heading: 'Search indexing that feels native to Ecto.',
  viewport: { width: 1440, height: 1800 }
});

await capture(browser, baseUrl, {
  path: path.join(artifactsDir, 'home-mobile.png'),
  heading: 'Search indexing that feels native to Ecto.',
  viewport: { width: 390, height: 1900 }
});

await capture(browser, `${baseUrl}/docs/`, {
  path: path.join(artifactsDir, 'docs-desktop.png'),
  heading: 'Find the guide for your next step.',
  viewport: { width: 1440, height: 1500 }
});

await capture(browser, `${baseUrl}/operators/`, {
  path: path.join(artifactsDir, 'operators-desktop.png'),
  heading: 'Recovery, verification, and drift should be boring.',
  viewport: { width: 1440, height: 1600 }
});

await capture(browser, `${baseUrl}/evaluate/`, {
  path: path.join(artifactsDir, 'evaluate-desktop.png'),
  heading: 'Should I use Scrypath?',
  viewport: { width: 1440, height: 1500 }
});
} finally {
  await browser.close();
  server.kill('SIGTERM');
}

async function capture(browser, url, { path: filePath, heading, viewport }) {
  const page = await browser.newPage({ viewport, colorScheme: 'dark' });
  await page.goto(url, { waitUntil: 'load' });
  await page.locator('h1').first().waitFor();
  const actualTitle = await page.locator('h1').first().textContent();
  if ((actualTitle ?? '').trim() !== heading.trim()) {
    throw new Error(`Unexpected hero title on ${url}: ${actualTitle}`);
  }

  await page.screenshot({ path: filePath, fullPage: true });
  await page.close();
}
