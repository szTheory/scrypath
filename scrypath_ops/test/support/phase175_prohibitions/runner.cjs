'use strict';

const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');

const root = path.resolve(__dirname, '../../..');
const cleanFixture = 'test/phase175_prohibitions/clean.json';
const elixirRunner = 'test/support/phase175_prohibitions/run.exs';

function runProhibition({ name, fixture, target, exunitName }) {
  const subjectPath = process.env.GSD_PROHIB_SUBJECT
    ? path.resolve(process.cwd(), process.env.GSD_PROHIB_SUBJECT)
    : path.join(root, cleanFixture);
  const subjectData = JSON.parse(fs.readFileSync(subjectPath, 'utf8'));
  const expectedKind = subjectData.kind;
  if (!['clean', 'mutation'].includes(expectedKind)) {
    throw new Error(`unsupported subject kind: ${expectedKind}`);
  }

  const env = {
    ...process.env,
    MIX_ENV: 'test',
    PHASE175_EXUNIT_TARGET: target,
    GSD_PROHIB_SUBJECT: subjectPath,
  };
  const result = spawnSync('mix', ['run', '--no-start', '--no-compile', elixirRunner], {
    cwd: root,
    env,
    encoding: 'utf8',
    timeout: 28000,
    maxBuffer: 4 * 1024 * 1024,
  });
  const output = `${result.stdout || ''}\n${result.stderr || ''}`;
  const evidenceDir = process.env.PHASE175_PROHIB_EVIDENCE_DIR;
  if (evidenceDir) {
    fs.mkdirSync(evidenceDir, { recursive: true });
    const evidenceName = `${path.basename(fixture)}.${path.basename(subjectPath)}.exunit.log`;
    fs.writeFileSync(path.join(evidenceDir, evidenceName), output);
  }
  const summary = output.match(/(\d+) tests?, (\d+) failures?/);
  const targetWasExecuted = output.includes(exunitName);

  // Do this validation before registering the named Node test. A crash, compile failure,
  // wrong line selector, or missing ExUnit summary becomes a file-load failure and cannot
  // be accepted as a non-vacuous behavioral RED by the producer.
  if (result.error) throw result.error;
  if (!summary) throw new Error(`ExUnit summary missing for ${name}:\n${output}`);
  if (Number(summary[1]) !== 1) throw new Error(`expected exactly one targeted ExUnit test, got ${summary[1]}: ${output}`);
  if (!targetWasExecuted) throw new Error(`expected named ExUnit assertion did not appear: ${exunitName}\n${output}`);
  if (expectedKind === 'mutation') {
    if (Number(summary[2]) !== 1 || result.status === 0) {
      throw new Error(`known-bad subject did not fail exactly the targeted assertion: ${output}`);
    }
    const failureStart = output.indexOf(`1) test ${exunitName}`);
    const failureText = failureStart >= 0 ? output.slice(failureStart, output.indexOf('Finished in', failureStart)) : '';
    const targetFile = target.replace(/:\d+$/, '');
    const assertionFailed = /Assertion with|Expected truthy, got false|Expected false or nil, got true|expected .*(?:but got|got none|received)/i.test(failureText);
    if (!failureText || !assertionFailed || !failureText.includes(targetFile)) {
      throw new Error(`ExUnit did not report the expected assertion failing at the targeted source line: ${output}`);
    }
  } else if (Number(summary[2]) !== 0 || result.status !== 0) {
    throw new Error(`clean control failed: ${output}`);
  }

  test(name, () => {
    assert.equal(result.status, 0, `the existing ExUnit behavioral assertion rejected the known-bad mutant:\n${output}`);
  });
}

module.exports = { runProhibition };
