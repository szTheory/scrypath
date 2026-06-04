// light-pixel-diff.mjs
//
// Disposable Wave 0 pixel-identity gate for Phase 130 (DARKTOKEN-01-c).
// Diffs the 20 light-only admin PNGs from the Jun-3 baseline against a fresh
// set of PNGs using pixelmatch, and exits non-zero if any pair has > 0 diff
// pixels.
//
// Usage (from examples/scrypath_ecommerce/):
//   node e2e/light-pixel-diff.mjs
//
// Env overrides:
//   PIXEL_DIFF_FRESH_DIR  — directory containing freshly-shot light PNGs
//                           (default: test-results/pixel-diff-fresh)
//   PIXEL_DIFF_DIFF_DIR   — directory where diff PNGs are written for failing pairs
//                           (default: test-results/pixel-diff-out)
//
// Requires: pixelmatch, pngjs (devDependencies in package.json)
// Phase 136 owns the full 40-shot re-capture; this script is light-only and disposable.

import pixelmatch from "pixelmatch";
import { PNG } from "pngjs";
import { readFile, readdir, mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

// ─── PATHS ─────────────────────────────────────────────────────────────────────

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Baseline: the Jun-3 light screenshots stored in .tmp/admin-screenshots/
const BASELINE_DIR = path.resolve(__dirname, "../.tmp/admin-screenshots");
// Fresh shots: caller must place re-shot light PNGs here before running this script
const FRESH_DIR =
  process.env.PIXEL_DIFF_FRESH_DIR ??
  path.resolve(__dirname, "../.tmp/pixel-diff-fresh");
// Diff output: write side-by-side diff PNGs for any failing pair
const DIFF_DIR =
  process.env.PIXEL_DIFF_DIFF_DIR ??
  path.resolve(__dirname, "../.tmp/pixel-diff-out");

// ─── MAIN ──────────────────────────────────────────────────────────────────────

async function main() {
  // 1. Discover baseline light PNGs
  let allFiles;
  try {
    allFiles = await readdir(BASELINE_DIR);
  } catch (err) {
    console.error(
      `light-pixel-diff: cannot read BASELINE_DIR: ${BASELINE_DIR}`
    );
    console.error(`  ${err.message}`);
    process.exit(2);
  }

  const lightFiles = allFiles
    .filter((f) => f.includes("--light--") && f.endsWith(".png"))
    .sort();

  if (lightFiles.length === 0) {
    console.error(
      `light-pixel-diff: no light PNG files found in ${BASELINE_DIR}`
    );
    console.error(
      `  Expected files matching *--light--*.png — run the admin screenshot matrix first.`
    );
    process.exit(2);
  }

  console.log(`Baseline: ${BASELINE_DIR}`);
  console.log(`Fresh:    ${FRESH_DIR}`);
  console.log(`Diff out: ${DIFF_DIR}`);
  console.log(`Light PNGs to diff: ${lightFiles.length}\n`);

  // 2. Ensure output dirs exist
  await mkdir(DIFF_DIR, { recursive: true });

  // 3. pixelmatch loop
  let totalFail = 0;

  for (const filename of lightFiles) {
    const baselinePath = path.join(BASELINE_DIR, filename);
    const freshPath = path.join(FRESH_DIR, filename);

    // Check fresh PNG exists
    let freshData;
    try {
      freshData = await readFile(freshPath);
    } catch (_err) {
      console.error(`SKIP: ${filename} (fresh PNG not found at ${freshPath})`);
      totalFail++;
      continue;
    }

    // Read both PNGs
    const baselineData = await readFile(baselinePath);
    const baseline = PNG.sync.read(baselineData);
    const fresh = PNG.sync.read(freshData);

    // Dimension guard
    if (baseline.width !== fresh.width || baseline.height !== fresh.height) {
      console.error(
        `DIFF: ${filename} — dimension mismatch ` +
          `(baseline ${baseline.width}×${baseline.height} vs fresh ${fresh.width}×${fresh.height})`
      );
      totalFail++;
      continue;
    }

    const { width, height } = baseline;
    const diff = new PNG({ width, height });

    const diffCount = pixelmatch(
      baseline.data,
      fresh.data,
      diff.data,
      width,
      height,
      { threshold: 0 }
    );

    if (diffCount > 0) {
      totalFail++;
      // Write diff PNG to DIFF_DIR for inspection
      const diffPath = path.join(DIFF_DIR, filename);
      await writeFile(diffPath, PNG.sync.write(diff));
      console.error(`DIFF: ${filename} — ${diffCount} px differ`);
    } else {
      console.log(`OK:   ${filename}`);
    }
  }

  // 4. Summary and exit
  console.log(`\nLight pixel-diff: ${totalFail === 0 ? "PASS" : "FAIL"}`);
  console.log(`  Failed pairs: ${totalFail} / ${lightFiles.length}`);
  process.exit(totalFail > 0 ? 1 : 0);
}

main().catch((err) => {
  console.error("light-pixel-diff error:", err.message);
  process.exit(2);
});
