const assert = require("node:assert/strict");
const path = require("node:path");
const { readFileSync } = require("node:fs");
const { pathToFileURL } = require("node:url");
const test = require("node:test");

const verificationTargetPath = pathToFileURL(
  path.resolve(__dirname, "../../examples/scrypath_ecommerce/e2e/helpers/verification-target.mjs"),
).href;
const verificationTarget = import(verificationTargetPath);

const followupSource = path.resolve(
  __dirname,
  "../../examples/scrypath_ecommerce/e2e/ui_followup.spec.ts",
);
const iteration3Source = path.resolve(
  __dirname,
  "../../examples/scrypath_ecommerce/e2e/ui_iteration3.spec.ts",
);

test("verification target accepts Docker and explicitly isolated local hosts", async () => {
  const { previewRefusalReason } = await verificationTarget;

  assert.equal(previewRefusalReason("http://web:4002"), null);
  assert.equal(previewRefusalReason("http://localhost:4014"), null);
  assert.equal(previewRefusalReason("http://127.0.0.1:4014"), null);
});

test("verification target refuses the retained preview and missing or malformed URLs", async () => {
  const { previewRefusalReason } = await verificationTarget;

  assert.match(previewRefusalReason("http://localhost:4002"), /retained preview/i);
  assert.match(previewRefusalReason("http://127.0.0.1:4002"), /retained preview/i);
  assert.match(previewRefusalReason(undefined), /valid.*URL/i);
  assert.match(previewRefusalReason("not a URL"), /valid.*URL/i);
});

test("verification target refusal callback runs before any guarded mutation", async () => {
  const { guardVerificationTarget } = await verificationTarget;

  for (const baseURL of ["http://localhost:4002", "http://127.0.0.1:4002", undefined, "not a URL"]) {
    const events = [];
    await guardVerificationTarget(
      baseURL,
      (reason) => events.push(["refused", reason]),
      async () => events.push(["mutated"]),
    );

    assert.equal(events.length, 1, `refused target ${String(baseURL)} cannot reach the mutator`);
    assert.equal(events[0][0], "refused");
  }
});

test("follow-up and iteration-3 suites guard before setup and retain all selected cases", async () => {
  const followup = readFileSync(followupSource, "utf8");
  const iteration3 = readFileSync(iteration3Source, "utf8");

  const followupGuard = followup.indexOf("await guardVerificationTarget(");
  const followupCases = followup.indexOf("for (const [name, url]");
  assert.ok(followupGuard > 0 && followupGuard < followupCases);

  const iteration3Guard = iteration3.indexOf("await guardVerificationTarget(");
  const iteration3Setup = iteration3.indexOf("await mkdir(artifacts");
  const iteration3Cases = iteration3.indexOf("test(\"");
  assert.ok(iteration3Guard > 0 && iteration3Guard < iteration3Setup);
  assert.ok(iteration3Setup < iteration3Cases);
  assert.doesNotMatch(followup, /new URL\(baseURL\)\.port/);
  assert.doesNotMatch(iteration3, /new URL\(baseURL\)\.port/);
});


test("all loopback spellings refuse the retained preview before mutation", async () => {
  const { guardVerificationTarget, previewRefusalReason } = await verificationTarget;
  for (const host of ["[::1]", "[0:0:0:0:0:0:0:1]", "127.0.0.2", "127.1", "[::ffff:127.0.0.1]", "localhost."]) {
    const events = [];
    await guardVerificationTarget(`http://${host}:4002`, () => events.push("refused"), () => events.push("mutated"));
    assert.deepEqual(events, ["refused"], host);
    assert.equal(previewRefusalReason(`http://${host}:4014`), null);
  }
});
