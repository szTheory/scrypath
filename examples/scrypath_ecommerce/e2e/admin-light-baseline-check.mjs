#!/usr/bin/env node

import { mkdir, mkdtemp, readFile, readdir, rm, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { PNG } from "pngjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DEFAULT_MANIFEST = path.join(__dirname, "admin-light-baseline.json");
const DEFAULT_FRESH_DIR = process.env.ADMIN_SCREENSHOT_DIR || path.resolve(__dirname, "../test-results/admin-screenshots");
const DEFAULT_REPORT = process.env.ADMIN_LIGHT_PARITY_REPORT || path.resolve(__dirname, "../test-results/admin-light-parity.json");

function argValue(name, fallback) {
  const index = process.argv.indexOf(name);
  return index >= 0 && process.argv[index + 1] ? process.argv[index + 1] : fallback;
}

async function pngDimensions(file) {
  const data = await readFile(file);
  const png = PNG.sync.read(data);
  return { width: png.width, height: png.height };
}

async function writeReport(reportPath, report) {
  await mkdir(path.dirname(reportPath), { recursive: true });
  await writeFile(reportPath, `${JSON.stringify(report, null, 2)}\n`);
}

async function checkLightParity({ manifestPath, freshDir, reportPath }) {
  const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
  const expected = new Map(manifest.files.map((entry) => [entry.file, entry]));
  const actualLightFiles = (await readdir(freshDir))
    .filter((file) => file.includes("--light--") && file.endsWith(".png"))
    .sort();
  const actualSet = new Set(actualLightFiles);

  const missing = [];
  const width_mismatches = [];
  const checked = [];

  for (const [file, expectedEntry] of expected.entries()) {
    const filePath = path.join(freshDir, file);
    if (!actualSet.has(file)) {
      missing.push(file);
      continue;
    }

    const actualDimensions = await pngDimensions(filePath);
    checked.push(file);
    if (actualDimensions.width !== expectedEntry.width) {
      width_mismatches.push({
        file,
        expected_width: expectedEntry.width,
        actual_width: actualDimensions.width,
        actual_height: actualDimensions.height
      });
    }
  }

  const extra = actualLightFiles.filter((file) => !expected.has(file));
  const status = missing.length === 0 && width_mismatches.length === 0 && extra.length === 0 ? "pass" : "fail";
  const report = {
    schema: "scrypath.admin-light-parity.v1",
    status,
    baseline_manifest: path.relative(process.cwd(), manifestPath),
    fresh_dir: path.relative(process.cwd(), freshDir),
    expected_count: expected.size,
    checked_count: checked.length,
    missing,
    width_mismatches,
    extra,
    generated_at_utc: new Date().toISOString()
  };

  await writeReport(reportPath, report);
  return report;
}

async function selfTest() {
  const dir = await mkdtemp(path.join(os.tmpdir(), "scrypath-light-parity-"));
  try {
    const freshDir = path.join(dir, "fresh");
    await mkdir(freshDir);
    const imageName = "00-control-room--light--desktop--incident.png";
    const imagePath = path.join(freshDir, imageName);
    const png = new PNG({ width: 2, height: 3 });
    await writeFile(imagePath, PNG.sync.write(png));
    const manifestPath = path.join(dir, "manifest.json");
    const reportPath = path.join(dir, "report.json");
    await writeFile(
      manifestPath,
      JSON.stringify({
        schema: "scrypath.admin-light-baseline.v1",
        files: [{ file: imageName, width: 2 }]
      })
    );

    const report = await checkLightParity({ manifestPath, freshDir, reportPath });
    if (report.status !== "pass" || report.checked_count !== 1) {
      throw new Error(`self-test expected pass, got ${JSON.stringify(report)}`);
    }

    const changedPng = new PNG({ width: 3, height: 3 });
    await writeFile(imagePath, PNG.sync.write(changedPng));
    const failReport = await checkLightParity({ manifestPath, freshDir, reportPath });
    if (failReport.status !== "fail" || failReport.width_mismatches.length !== 1) {
      throw new Error(`self-test expected one mismatch, got ${JSON.stringify(failReport)}`);
    }

    console.log("admin-light-baseline-check self-test: pass");
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

if (process.argv.includes("--self-test")) {
  await selfTest();
  process.exit(0);
}

const manifestPath = path.resolve(argValue("--manifest", DEFAULT_MANIFEST));
const freshDir = path.resolve(argValue("--fresh-dir", DEFAULT_FRESH_DIR));
const reportPath = path.resolve(argValue("--report", DEFAULT_REPORT));

try {
  const report = await checkLightParity({ manifestPath, freshDir, reportPath });
  console.log(`admin-light-baseline-check: ${report.status.toUpperCase()} (${report.checked_count}/${report.expected_count} checked)`);
  if (report.status !== "pass") {
    console.error(`Wrote ${reportPath}`);
    process.exit(1);
  }
} catch (error) {
  const report = {
    schema: "scrypath.admin-light-parity.v1",
    status: "fail",
    baseline_manifest: path.relative(process.cwd(), manifestPath),
    fresh_dir: path.relative(process.cwd(), freshDir),
    error: error instanceof Error ? error.message : String(error),
    generated_at_utc: new Date().toISOString()
  };
  await writeReport(reportPath, report);
  console.error(`admin-light-baseline-check: FAIL (${report.error})`);
  process.exit(1);
}
