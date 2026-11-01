"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const { scanTree, resolveTrustedComparison, verifyHistory } = require("./ui_literal_policy.cjs");

const REPO = path.resolve(__dirname, "../..");
const BOOTSTRAP = "767f368473f17fba43d7be4675c53ab65a87530c";

function run(command, args, cwd) {
  return spawnSync(command, args, { cwd, encoding: "utf8", timeout: 30000, maxBuffer: 8 * 1024 * 1024 });
}

function git(cwd, args) {
  const result = run("git", args, cwd);
  assert.equal(result.status, 0, `git ${args[0]} failed: ${result.stderr}`);
  return result.stdout.trim();
}

function cloneRepo(t, source = REPO) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "ui-literal-history-"));
  const repo = path.join(root, "repo");
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const cloned = run("git", ["clone", "--quiet", "--shared", source, repo], root);
  assert.equal(cloned.status, 0, `git clone failed: ${cloned.stderr}`);
  git(repo, ["config", "user.name", "UI literal tests"]);
  git(repo, ["config", "user.email", "ui-literal-tests@example.invalid"]);
  return repo;
}

function targetAtCurrentHead(t) {
  const repo = cloneRepo(t);
  const head = git(repo, ["rev-parse", "HEAD"]);
  git(repo, ["branch", "--force", "main", head]);
  git(repo, ["switch", "main"]);
  git(repo, ["config", "remote.origin.url", "https://github.com/szTheory/scrypath.git"]);
  return { repo, head, parent: git(repo, ["rev-parse", `${head}^`]) };
}

function findingEntries(findings) {
  const counts = new Map();
  for (const { rule, path: file, context, value } of findings) {
    const key = JSON.stringify([rule, file, context, value]);
    counts.set(key, (counts.get(key) || 0) + 1);
  }
  return [...counts].map(([key, count]) => {
    const [rule, file, context, value] = JSON.parse(key);
    return { rule, path: file, context, value, count };
  }).sort((left, right) => {
    const a = JSON.stringify([left.rule, left.path, left.context, left.value]);
    const b = JSON.stringify([right.rule, right.path, right.context, right.value]);
    return a < b ? -1 : a > b ? 1 : 0;
  });
}

function sortLedger(ledger) {
  ledger.findings.sort((left, right) => {
    const a = JSON.stringify([left.rule, left.path, left.context, left.value]);
    const b = JSON.stringify([right.rule, right.path, right.context, right.value]);
    return a < b ? -1 : a > b ? 1 : 0;
  });
  return ledger;
}

function writeLedger(repo, findings) {
  const ledger = { version: 1, bootstrap_commit: BOOTSTRAP, findings: findingEntries(findings) };
  fs.writeFileSync(path.join(repo, "scripts/ci/ui-literal-baseline.json"), `${JSON.stringify(ledger, null, 2)}\n`);
}

function insertLiteralZSentinel(repo) {
  const sourcePath = "scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex";
  const sourceFile = path.join(repo, sourcePath);
  const source = fs.readFileSync(sourceFile, "utf8");
  assert.equal(source.split("</body>").length - 1, 1, "maintained root layout has one closing body tag");
  fs.writeFileSync(sourceFile, source.replace("</body>", '<div class="z-60"></div>\n  </body>'));
  return sourcePath;
}

function commit(repo, message, files) {
  git(repo, ["add", ...files]);
  git(repo, ["commit", "-m", message]);
}

function runPolicy(repo, args = []) {
  return run(process.execPath, [path.join(repo, "scripts/ci/ui_literal_policy.cjs"), ...args], repo);
}

function policyResult(repo, event = { kind: "local" }, trustedRemote = REPO) {
  try {
    return { ok: true, result: verifyHistory(repo, event, { trustedRemote }) };
  } catch (error) {
    return { ok: false, error: error.message };
  }
}

test("discovers the four rules only in authored UI sources and keeps stable identities", (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "ui-literal-rules-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));

  const template = path.join(root, "scrypath_ops/lib/sample.html.heex");
  const stylesheet = path.join(root, "scrypath_ops/assets/css/app.css");
  fs.mkdirSync(path.dirname(template), { recursive: true });
  fs.mkdirSync(path.dirname(stylesheet), { recursive: true });
  fs.writeFileSync(template, [
    '<!-- <button class="text-[purple]" style="color:#0f0"> -->',
    '<section id="filters">',
    '  <button class="bg-[red] z-auto z-auto z-ops-header z-[var(--z-layer)] [&:nth-child(2)]:block" style={if @active, do: "color: #fff", else: ""}>Apply</button>',
    '</section>',
  ].join("\n"));
  fs.writeFileSync(stylesheet, [
    "/* .ignored { color: #123456; } */",
    "#fff { color: #abcdef; }",
    ".sample { color: #123456; background-image: url(data:image/svg+xml,#fff); }",
    "@theme { --color-primary: #fedcba; }",
    '@plugin "../vendor/daisyui-theme" { name: "light"; --color-primary: #fedcba; }',
    ".untrusted { --surface: #abc; }",
    "@apply z-20 bg-(--surface);",
  ].join("\n"));
  fs.writeFileSync(path.join(root, "scrypath_ops/lib/sample.jsx"), '<div className="text-[length:var(--ops-size)] z-30" style={{ color: "#fff" }} />\n');
  fs.mkdirSync(path.join(root, "scrypath_ops/assets/js"), { recursive: true });
  fs.writeFileSync(path.join(root, "scrypath_ops/assets/js/sample.js"), 'element.classList.add("top-[-2px] z-40");\n');
  fs.mkdirSync(path.join(root, "scrypath_ops/assets/vendor"), { recursive: true });
  fs.writeFileSync(path.join(root, "scrypath_ops/assets/vendor/ignored.css"), ".ignored { color: #aabbcc; }");
  fs.mkdirSync(path.join(root, "scrypath_ops/priv/static"), { recursive: true });
  fs.writeFileSync(path.join(root, "scrypath_ops/priv/static/ignored.css"), ".ignored { color: #aabbcc; }");
  fs.mkdirSync(path.join(root, "scrypath_ops/test/fixtures"), { recursive: true });
  fs.writeFileSync(path.join(root, "scrypath_ops/test/fixtures/ignored.heex"), '<div class="z-50"></div>');

  const findings = scanTree(root);
  assert.deepEqual(findings.map(({ rule, value }) => [rule, rule === "inline-style" ? "inline-source" : value]).sort(), [
    ["arbitrary-value", "bg-(--surface)"],
    ["arbitrary-value", "bg-[red]"],
    ["arbitrary-value", "text-[length:var(--ops-size)]"],
    ["arbitrary-value", "top-[-2px]"],
    ["arbitrary-value", "z-[var(--z-layer)]"],
    ["inline-style", "inline-source"],
    ["inline-style", "inline-source"],
    ["literal-z", "z-20"],
    ["literal-z", "z-30"],
    ["literal-z", "z-40"],
    ["literal-z", "z-[var(--z-layer)]"],
    ["literal-z", "z-auto"],
    ["literal-z", "z-auto"],
    ["raw-hex", "#123456"],
    ["raw-hex", "#abc"],
    ["raw-hex", "#abcdef"],
    ["raw-hex", "#fff"],
    ["raw-hex", "#fff"],
  ]);
  const repeatedZ = findings.filter(({ rule, value }) => rule === "literal-z" && value === "z-auto");
  assert.equal(repeatedZ.length, 2);
  assert.equal(repeatedZ[0].context, repeatedZ[1].context, "identical occurrences retain multiplicity within one structural context");
  assert.ok(findings.every(({ context, line, column, repair }) => context.length > 0 && Number.isInteger(line) && Number.isInteger(column) && repair.length > 0));
  assert.ok(findings.every(({ path: file }) => !file.includes("ignored")));

  const identities = findings.map(({ rule, path: file, context, value }) => [rule, file, context, value]);
  fs.writeFileSync(template, `\n\n<!-- harmless comment -->\n${fs.readFileSync(template, "utf8").replace(/\s+/g, " ")}\n`);
  fs.writeFileSync(stylesheet, `/* harmless comment */\n${fs.readFileSync(stylesheet, "utf8").replace(/\n/g, "\n\n")}`);
  const moved = scanTree(root).map(({ rule, path: file, context, value }) => [rule, file, context, value]);
  assert.deepEqual(moved, identities, "comments and line movement do not change finding identity");
});

test("the committed bootstrap ledger is the exact pinned-source multiset", (t) => {
  const repo = cloneRepo(t);
  const { ok, result } = policyResult(repo);
  assert.equal(ok, true);
  assert.equal(result.policyVersion, 1);
  assert.equal(result.introduction, git(repo, ["log", "--first-parent", "--reverse", "--format=%H", "--", "scripts/ci/ui-literal-baseline.json"]).split("\n")[0]);
  const introductionLedger = JSON.parse(git(repo, ["show", `${result.introduction}:scripts/ci/ui-literal-baseline.json`]));
  assert.equal(introductionLedger.bootstrap_commit, BOOTSTRAP);
  assert.equal(introductionLedger.findings.reduce((total, item) => total + item.count, 0), 45,
    "the immutable introduction retains the original 45 pinned findings");
  assert.equal(result.findingCount, scanTree(repo).length,
    "current findings follow actual source cleanup while bootstrap history stays pinned");
});

test("a candidate cannot bless a newly introduced finding by editing its ledger", (t) => {
  const repo = cloneRepo(t);
  const sourcePath = insertLiteralZSentinel(repo);
  writeLedger(repo, scanTree(repo));
  commit(repo, "candidate adds a violation and matching ledger row", [sourcePath, "scripts/ci/ui-literal-baseline.json"]);

  const result = policyResult(repo);
  assert.equal(result.ok, false);
  assert.match(result.error, /candidate first-parent ledger grew or reversed/);
  assert.match(result.error, /literal-z/);
});

test("a valid reduction passes, a first-parent reversal fails, and deletion cannot reset history", (t) => {
  const repo = cloneRepo(t);
  const sourcePath = "scrypath_ops/assets/css/app.css";
  const sourceFile = path.join(repo, sourcePath);
  const initialSource = fs.readFileSync(sourceFile, "utf8");
  const initialLedger = JSON.parse(fs.readFileSync(path.join(repo, "scripts/ci/ui-literal-baseline.json"), "utf8"));
  fs.writeFileSync(sourceFile, initialSource.replace("var(--color-neutral, #000)", "var(--color-neutral, var(--ops-bg))"));
  const reduced = initialLedger.findings.map((item) => item.rule === "raw-hex" && item.path === sourcePath && item.value === "#000" ? { ...item, count: 0 } : item);
  fs.writeFileSync(path.join(repo, "scripts/ci/ui-literal-baseline.json"), `${JSON.stringify({ ...initialLedger, findings: reduced }, null, 2)}\n`);
  commit(repo, "reduce one existing literal", [sourcePath, "scripts/ci/ui-literal-baseline.json"]);
  assert.equal(policyResult(repo).ok, true, "a matching source-and-ledger reduction passes");

  fs.writeFileSync(sourceFile, initialSource);
  fs.writeFileSync(path.join(repo, "scripts/ci/ui-literal-baseline.json"), `${JSON.stringify(initialLedger, null, 2)}\n`);
  commit(repo, "restore a cleaned literal", [sourcePath, "scripts/ci/ui-literal-baseline.json"]);
  const reversal = policyResult(repo);
  assert.equal(reversal.ok, false);
  assert.match(reversal.error, /candidate first-parent ledger grew or reversed/);

  const deletedRepo = cloneRepo(t);
  git(deletedRepo, ["rm", "scripts/ci/ui-literal-baseline.json"]);
  git(deletedRepo, ["commit", "-m", "delete the ledger"]);
  const deletion = policyResult(deletedRepo);
  assert.equal(deletion.ok, false);
  assert.match(deletion.error, /ledger was deleted after introduction/);
});

test("malformed ledger metadata and non-integer multiplicities fail closed", (t) => {
  const cases = [
    { label: "unknown version", mutate: (ledger) => ({ ...ledger, version: 99 }), diagnostic: /unknown policy version/ },
    { label: "empty reset", mutate: (ledger) => ({ ...ledger, findings: [] }), diagnostic: /source scan differs/ },
    { label: "string count", mutate: (ledger) => ({ ...ledger, findings: [{ ...ledger.findings[0], count: "1" }, ...ledger.findings.slice(1)] }), diagnostic: /counts must be non-negative integers/ },
    { label: "fraction count", mutate: (ledger) => ({ ...ledger, findings: [{ ...ledger.findings[0], count: 1.5 }, ...ledger.findings.slice(1)] }), diagnostic: /counts must be non-negative integers/ },
    { label: "negative count", mutate: (ledger) => ({ ...ledger, findings: [{ ...ledger.findings[0], count: -1 }, ...ledger.findings.slice(1)] }), diagnostic: /counts must be non-negative integers/ },
    { label: "same-count swap", mutate: (ledger) => {
      const next = { ...ledger, findings: ledger.findings.map((entry) => ({ ...entry })) };
      const indexes = next.findings.map((entry, index) => entry.rule === "raw-hex" ? index : -1).filter((index) => index >= 0).slice(0, 2);
      const first = next.findings[indexes[0]];
      const second = next.findings[indexes[1]];
      [first.value, second.value] = [second.value, first.value];
      return sortLedger(next);
    }, diagnostic: /candidate first-parent ledger grew or reversed|source scan differs/ },
    { label: "path move", mutate: (ledger) => {
      const next = { ...ledger, findings: ledger.findings.map((entry) => ({ ...entry })) };
      next.findings[0].path = "scrypath_ops/assets/css/app.css";
      return sortLedger(next);
    }, diagnostic: /candidate first-parent ledger grew or reversed|source scan differs/ },
  ];
  for (const item of cases) {
    const repo = cloneRepo(t);
    const ledgerPath = path.join(repo, "scripts/ci/ui-literal-baseline.json");
    const original = JSON.parse(fs.readFileSync(ledgerPath, "utf8"));
    fs.writeFileSync(ledgerPath, `${JSON.stringify(item.mutate(original), null, 2)}\n`);
    commit(repo, `tamper with ledger: ${item.label}`, ["scripts/ci/ui-literal-baseline.json"]);
    const result = policyResult(repo);
    assert.equal(result.ok, false);
    assert.match(result.error, item.diagnostic);
  }
});

test("trusted target cleanup remains binding when a candidate branch is stale", (t) => {
  const target = cloneRepo(t);
  const head = git(target, ["rev-parse", "HEAD"]);
  git(target, ["branch", "--force", "main", head]);
  git(target, ["switch", "main"]);
  git(target, ["config", "remote.origin.url", "https://github.com/szTheory/scrypath.git"]);
  const sourcePath = "scrypath_ops/assets/css/app.css";
  const sourceFile = path.join(target, sourcePath);
  fs.writeFileSync(sourceFile, fs.readFileSync(sourceFile, "utf8").replace("var(--color-neutral, #000)", "var(--color-neutral, var(--ops-bg))"));
  const ledgerFile = path.join(target, "scripts/ci/ui-literal-baseline.json");
  const ledger = JSON.parse(fs.readFileSync(ledgerFile, "utf8"));
  ledger.findings = ledger.findings.filter((item) => !(item.rule === "raw-hex" && item.path === sourcePath && item.value === "#000"));
  fs.writeFileSync(ledgerFile, `${JSON.stringify(ledger, null, 2)}\n`);
  commit(target, "trusted main cleans one literal", [sourcePath, "scripts/ci/ui-literal-baseline.json"]);

  const candidate = cloneRepo(t);
  git(candidate, ["remote", "set-url", "origin", target]);
  const result = policyResult(candidate, { kind: "local" }, target);
  assert.equal(result.ok, false);
  assert.match(result.error, /independent trusted target/);
  assert.match(result.error, /#000/);

  const deletedTarget = targetAtCurrentHead(t);
  git(deletedTarget.repo, ["rm", "scripts/ci/ui-literal-baseline.json"]);
  git(deletedTarget.repo, ["commit", "-m", "trusted target deletes ledger"]);
  const stale = cloneRepo(t);
  const deleted = policyResult(stale, { kind: "local" }, deletedTarget.repo);
  assert.equal(deleted.ok, false);
  assert.match(deleted.error, /trusted target .* ledger was deleted after introduction/);
});

test("event resolution pins local, PR, push, schedule and dispatch authorities", (t) => {
  const repo = cloneRepo(t);
  const head = git(repo, ["rev-parse", "HEAD"]);
  const before = git(repo, ["rev-parse", `${head}^`]);
  const target = targetAtCurrentHead(t);
  const local = resolveTrustedComparison(repo, { kind: "local" }, { trustedRemote: target.repo });
  assert.equal(local.candidateOid, head);
  assert.equal(local.targetOid, target.parent, "when local HEAD is fetched main, compare against its first parent");
  assert.equal(local.policyVersion, 1);

  git(target.repo, ["update-ref", "refs/pull/17/head", head]);
  const pullRequest = resolveTrustedComparison(repo, {
    kind: "pull_request",
    payload: {
      pull_request: {
        number: 17,
        base: { ref: "main", repo: { full_name: "szTheory/scrypath" } },
        head: { sha: head },
      },
    },
  }, { trustedRemote: target.repo });
  assert.equal(pullRequest.candidateOid, head, "PR scans the exact pull head, not a merge result");
  assert.equal(pullRequest.targetOid, head, "PR target uses the freshly fetched base branch tip");
  assert.equal(pullRequest.candidateRef, "refs/pull/17/head");
  assert.throws(() => resolveTrustedComparison(repo, {
    kind: "pull_request",
    payload: { pull_request: { number: 17, base: { ref: "main", repo: { full_name: "attacker/scrypath" } }, head: { sha: head } } },
  }, { trustedRemote: target.repo }), /base repository is not szTheory\/scrypath/);

  const push = resolveTrustedComparison(repo, {
    kind: "push",
    payload: { before, after: head },
    env: { GITHUB_REF: "refs/heads/feature/ui-policy" },
  }, { trustedRemote: REPO });
  assert.equal(push.candidateOid, head);
  assert.equal(push.beforeOid, before);
  assert.ok(push.targetOid !== head);

  const mainPush = resolveTrustedComparison(repo, {
    kind: "push",
    payload: { before: target.parent, after: target.head },
    env: { GITHUB_REF: "refs/heads/main" },
  }, { trustedRemote: target.repo });
  assert.equal(mainPush.candidateOid, target.head);
  assert.equal(mainPush.targetOid, target.parent);

  const scheduled = resolveTrustedComparison(repo, {
    kind: "schedule",
    payload: {},
    env: { GITHUB_REF: "refs/heads/main", GITHUB_SHA: target.head },
  }, { trustedRemote: target.repo });
  assert.equal(scheduled.targetOid, target.parent);

  const scheduledStale = resolveTrustedComparison(repo, {
    kind: "schedule",
    payload: {},
    env: { GITHUB_REF: "refs/heads/main", GITHUB_SHA: target.parent },
  }, { trustedRemote: target.repo });
  assert.equal(scheduledStale.targetOid, git(repo, ["rev-parse", `${target.parent}^`]));
  assert.ok(scheduledStale.comparisons.includes(target.head), "scheduled workflow also compares newer main");

  const dispatchFeature = resolveTrustedComparison(repo, {
    kind: "workflow_dispatch",
    payload: {},
    env: { GITHUB_REF: "refs/heads/feature/ui-policy", GITHUB_SHA: head },
  }, { trustedRemote: target.repo });
  assert.equal(dispatchFeature.targetOid, target.head);

  const dispatchMain = resolveTrustedComparison(repo, {
    kind: "workflow_dispatch",
    payload: {},
    env: { GITHUB_REF: "refs/heads/main", GITHUB_SHA: target.parent },
  }, { trustedRemote: target.repo });
  assert.equal(dispatchMain.targetOid, git(repo, ["rev-parse", `${target.parent}^`]));
  assert.ok(dispatchMain.comparisons.includes(target.head), "main dispatch checks the candidate parent and newer main");

  assert.throws(() => resolveTrustedComparison(repo, {
    kind: "push",
    payload: { before: "0000000000000000000000000000000000000000", after: head },
    env: { GITHUB_REF: "refs/heads/feature/ui-policy" },
  }, { trustedRemote: REPO }), /before SHA is zero/);
  assert.throws(() => resolveTrustedComparison(repo, {
    kind: "push",
    payload: { before: before, after: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" },
    env: { GITHUB_REF: "refs/heads/feature/ui-policy" },
  }, { trustedRemote: REPO }), /after SHA commit is unavailable/);
  const cli = runPolicy(repo, ["--baseline", "elsewhere.json"]);
  assert.equal(cli.status, 2);
  assert.match(cli.stderr, /accepts no arguments/);
});

test("shallow and missing trusted histories fail with explicit diagnostics", (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "ui-literal-shallow-"));
  const shallow = path.join(root, "repo");
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const cloned = run("git", ["clone", "--quiet", "--depth=1", `file://${REPO}`, shallow], root);
  assert.equal(cloned.status, 0, cloned.stderr);
  assert.throws(() => resolveTrustedComparison(shallow, { kind: "local" }, { trustedRemote: REPO }), /shallow history.*git fetch --unshallow origin/);

  const normal = cloneRepo(t);
  const emptyRemote = path.join(root, "empty.git");
  git(root, ["init", "--bare", emptyRemote]);
  assert.throws(() => resolveTrustedComparison(normal, { kind: "local" }, { trustedRemote: emptyRemote }), /git fetch failed/);
  assert.throws(() => resolveTrustedComparison(normal, {
    kind: "push",
    payload: { before: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", after: git(normal, ["rev-parse", "HEAD"]) },
    env: { GITHUB_REF: "refs/heads/feature/ui-policy" },
  }, { trustedRemote: REPO }), /before SHA commit is unavailable/);
});

test("a side-branch merge cannot hide a first-parent ledger increase", (t) => {
  const repo = cloneRepo(t);
  const originalBranch = git(repo, ["branch", "--show-current"]);
  const sourcePath = insertLiteralZSentinel(repo);
  git(repo, ["switch", "-c", "side-with-new-literal"]);
  writeLedger(repo, scanTree(repo));
  commit(repo, "side branch adds matching literal", [sourcePath, "scripts/ci/ui-literal-baseline.json"]);
  git(repo, ["switch", originalBranch]);
  git(repo, ["merge", "--no-ff", "side-with-new-literal", "-m", "merge side literal"]);

  const result = policyResult(repo);
  assert.equal(result.ok, false);
  assert.match(result.error, /candidate first-parent ledger grew or reversed/);
  assert.match(result.error, /literal-z/);
});

test("production CLI rejects a local mirror as an untrusted origin", (t) => {
  const repo = cloneRepo(t);
  const result = runPolicy(repo);
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /origin repository identity is not szTheory\/scrypath/);
});


test("inline style identities retain changed source values while ignoring formatting", (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "ui-style-value-review-"));
  t.after(() => fs.rmSync(root, {recursive:true, force:true}));
  const file = path.join(root, "scrypath_ops/lib/value.html.heex");
  fs.mkdirSync(path.dirname(file), {recursive:true});
  const identities = attribute => {
    fs.writeFileSync(file, `<div id="proof" ${attribute}></div>`);
    return scanTree(root).filter(f => f.rule === "inline-style").map(({rule, path, context, value}) => ({rule, path, context, value}));
  };
  const first = identities('style="width: 1px"');
  assert.notDeepEqual(identities('style="width: 2px"'), first);
  assert.deepEqual(identities('style=" width :  1px /* format only */ "'), first);
  const dynamic = identities('style={if @active, do: "content: a b", else: ""}');
  assert.deepEqual(identities('style={ if   @active,\n do: "content: a b", else: "" }'), dynamic);
  assert.notDeepEqual(identities('style={if @active, do: "content: ab", else: ""}'), dynamic);
  assert.notDeepEqual(identities('style={@different_source}'), dynamic);
});

test("presentation colors and JavaScript styling literals cannot escape source discovery", (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "ui-color-context-review-"));
  t.after(() => fs.rmSync(root, {recursive:true, force:true}));
  const html = path.join(root, "scrypath_ops/lib/colors.heex");
  const js = path.join(root, "scrypath_ops/assets/js/colors.js");
  fs.mkdirSync(path.dirname(html), {recursive:true});fs.mkdirSync(path.dirname(js), {recursive:true});
  fs.writeFileSync(html, '<svg><path fill="#ABCDEF" stroke="#123"/><path fill="url(#abc)"/></svg><a href="#fff" id="fff">#abc prose</a><div class="bg-[#aabbcc] [&_#def]:block bg-[url(#fed)]"></div>');
  fs.writeFileSync(js, 'topbar.config({barColors: {0: "#29d"}, shadowColor: "#010203"});\nconst prose = "#bada55";');
  assert.deepEqual(scanTree(root).filter(f => f.rule === "raw-hex").map(f=>f.value).sort(), ['#010203','#123','#29d','#ABCDEF','#aabbcc'].sort());
});

test("commented and quoted theme syntax cannot create a token authority", (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "ui-theme-authority-review-"));
  t.after(() => fs.rmSync(root, {recursive:true, force:true}));
  const css = path.join(root, "scrypath_ops/assets/css/app.css");fs.mkdirSync(path.dirname(css),{recursive:true});
  for (const prefix of ['/* @theme { */\n', '.caption { content: "@theme {"; }\n']) {
    fs.writeFileSync(css, prefix+'.ordinary { color: #abcdef; }');
    assert.deepEqual(scanTree(root).filter(f=>f.rule==='raw-hex').map(f=>f.value), ['#abcdef']);
  }
});


test("static JS class APIs preserve every argument and enclosing function", (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "ui-js-class-review-"));
  t.after(() => fs.rmSync(root, {recursive:true, force:true}));
  const js = path.join(root, "scrypath_ops/assets/js/classes.js");
  fs.mkdirSync(path.dirname(js), {recursive:true});
  fs.writeFileSync(js, [
    `const prose = 'color: "#abc"'; // classList.add("z-80")`,
    'function first() { el.classList.add("z-10", "bg-[url(https://site/a)]"); el.classList.replace("z-20", "z-30"); }',
    'function second() { el.className = "z-10"; const config = {className: "z-40"}; }',
  ].join("\n"));
  const findings = scanTree(root);
  assert.deepEqual(findings.filter(f=>f.rule==='literal-z').map(f=>f.value).sort(), ['z-10','z-10','z-20','z-30','z-40']);
  assert.equal(findings.filter(f=>f.rule==='raw-hex').length, 0);
  assert.equal(findings.filter(f=>f.rule==='arbitrary-value').length, 1, 'comment-like text in strings is preserved');
  const anchors = findings.filter(f=>f.value==='z-10').map(f=>f.context);
  assert.equal(new Set(anchors).size, 2);
  assert.ok(anchors.some(c=>c.includes('function:first')) && anchors.some(c=>c.includes('function:second')));
  const identities = findingEntries(findings);
  fs.writeFileSync(js, '\n/* formatting only */\n'+fs.readFileSync(js,'utf8').replace('function first()', 'function first ( )'));
  assert.deepEqual(findingEntries(scanTree(root)), identities);
});
