import { defineConfig, devices } from "@playwright/test";
import path from "node:path";

const artifactDir = path.resolve(process.env.E2E_ARTIFACT_DIR || "test-results");

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: false,
  retries: 0,
  workers: 1,
  outputDir: path.join(artifactDir, "test-results"),
  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL || "http://127.0.0.1:4002",
    trace: "retain-on-failure"
  },
  reporter: [
    ["list"],
    ["html", { outputFolder: path.join(artifactDir, "playwright-report"), open: "never" }],
    ["json", { outputFile: path.join(artifactDir, "phase105-playwright.json") }]
  ],
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] }
    }
  ]
});
