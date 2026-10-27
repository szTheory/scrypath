"use strict";

const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const {
  chmodSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const repositoryRoot = path.resolve(__dirname, "../..");
const verifierSource = path.join(
  repositoryRoot,
  "examples/scrypath_ecommerce/scripts/verify-e2e.sh",
);

function makeTempDirectory(t) {
  const directory = mkdtempSync(path.join(os.tmpdir(), "scrypath-ecommerce-build-"));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  return directory;
}

function runPrebuiltVerifier(t) {
  const root = makeTempDirectory(t);
  const exampleDirectory = path.join(root, "examples/scrypath_ecommerce");
  const scriptDirectory = path.join(exampleDirectory, "scripts");
  const ciDirectory = path.join(root, "scripts/ci");
  const binDirectory = path.join(root, "bin");
  mkdirSync(scriptDirectory, { recursive: true });
  mkdirSync(ciDirectory, { recursive: true });
  mkdirSync(binDirectory, { recursive: true });

  const verifierPath = path.join(scriptDirectory, "verify-e2e.sh");
  const dockerLog = path.join(root, "docker.jsonl");
  const helperLog = path.join(root, "helper.jsonl");
  const dockerPath = path.join(binDirectory, "docker");
  const gitPath = path.join(binDirectory, "git");
  const manifestPath = path.join(root, "image-handoff.json");
  const overridePath = path.join(root, "image-override.json");

  writeFileSync(verifierPath, readFileSync(verifierSource));
  writeFileSync(manifestPath, JSON.stringify({ schema_version: 1 }));
  writeFileSync(overridePath, JSON.stringify({ services: {} }));
  writeFileSync(
    path.join(ciDirectory, "ecommerce_build.cjs"),
    `"use strict";
const fs = require("node:fs");
fs.appendFileSync(process.env.FAKE_HELPER_LOG, JSON.stringify({args:process.argv.slice(2),hasRuntimeToken:Boolean(process.env.ACTIONS_RUNTIME_TOKEN)}) + "\\n");
`,
  );
  writeFileSync(
    dockerPath,
    `#!/usr/bin/env node
const fs = require("node:fs");
const args = process.argv.slice(2);
fs.appendFileSync(process.env.FAKE_DOCKER_LOG, JSON.stringify(args) + "\\n");
if (args[0] === "compose" && args[1] === "version") process.stdout.write("Docker Compose version v2\\n");
if (args[0] === "compose" && args.includes("config") && !args.includes("--quiet")) process.stdout.write("{\\"services\\":{}}\\n");
if (args[0] === "compose" && args.includes("ps") && args.includes("-aq")) process.stdout.write("");
`,
  );
  writeFileSync(
    gitPath,
    `#!/usr/bin/env node
const args = process.argv.slice(2).join(" ");
if (args === "rev-parse --short=8 HEAD") process.stdout.write("deadbeef\\n");
else if (args === "rev-parse HEAD") process.stdout.write("deadbeef00000000000000000000000000000000\\n");
else if (args === "branch --show-current") process.stdout.write("worktree-agent-test\\n");
else if (args === "status --porcelain --untracked-files=all") process.stdout.write("");
else process.exit(2);
`,
  );
  chmodSync(dockerPath, 0o755);
  chmodSync(gitPath, 0o755);

  const result = spawnSync("bash", [verifierPath, "focused"], {
    cwd: exampleDirectory,
    encoding: "utf8",
    env: {
      ...process.env,
      PATH: `${binDirectory}${path.delimiter}${process.env.PATH}`,
      FAKE_DOCKER_LOG: dockerLog,
      FAKE_HELPER_LOG: helperLog,
      E2E_RUN_ID: "prebuilt-test-run",
      E2E_PROJECT_NAME: "scrypath-e2e-prebuilt-test",
      E2E_PREBUILT_MANIFEST: manifestPath,
      E2E_IMAGE_OVERRIDE: overridePath,
      E2E_DOCKER_TIMEOUT_SECONDS: "20",
      E2E_FINALIZE_TIMEOUT_SECONDS: "10",
      E2E_FINALIZATION_MARGIN_SECONDS: "0",
      E2E_DEADLINE_EPOCH: String(Math.floor(Date.now() / 1000) + 120),
    },
  });
  const calls = existsSync(dockerLog)
    ? readFileSync(dockerLog, "utf8").trim().split("\n").filter(Boolean).map(JSON.parse)
    : [];
  const helperCalls = existsSync(helperLog)
    ? readFileSync(helperLog, "utf8").trim().split("\n").filter(Boolean).map(JSON.parse)
    : [];
  return { ...result, calls, helperCalls, overridePath };
}

test("prebuilt verification uses the checked image override without a Compose build", (t) => {
  const result = runPrebuiltVerifier(t);
  assert.equal(result.status, 0, `prebuilt verifier failed:\n${result.stdout}\n${result.stderr}`);
  const up = result.calls.find((call) => call[0] === "compose" && call.includes("up"));
  assert.ok(up, "expected one canonical Compose up invocation");
  assert.ok(up.includes("--no-build"), "prebuilt verification must start Compose with --no-build");
  assert.ok(up.includes("--pull") && up[up.indexOf("--pull") + 1] === "never");
  assert.ok(up.includes(result.overridePath), "Compose must include the checked image override file");
  assert.equal(result.helperCalls.length, 2, "verify-handoff must run before Compose up and after runtime starts");
  assert.ok(result.helperCalls.every((call) => call.args[0] === "verify-handoff"));
  assert.ok(result.helperCalls.every((call) => call.hasRuntimeToken === false));
});
