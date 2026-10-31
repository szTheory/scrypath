"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { scanTree } = require("./ui_literal_policy.cjs");

test("discovers exact UI literal rules from authored markup and CSS", (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "ui-literal-rules-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));

  const template = path.join(root, "scrypath_ops/lib/sample.html.heex");
  const stylesheet = path.join(root, "scrypath_ops/assets/css/sample.css");
  fs.mkdirSync(path.dirname(template), { recursive: true });
  fs.mkdirSync(path.dirname(stylesheet), { recursive: true });
  fs.writeFileSync(
    template,
    '<section id="filters"><button class="bg-[red] z-auto z-ops-header" style={if @active, do: "color: #fff", else: ""}>Apply</button></section>\n',
  );
  fs.writeFileSync(stylesheet, ".sample { color: #123456; }\n");

  const findings = scanTree(root).map(({ rule, path: file, context, value }) => ({
    rule,
    path: file,
    context,
    value,
  }));

  assert.deepEqual(findings.map(({ rule, value }) => [rule, value]).sort(), [
    ["arbitrary-value", "bg-[red]"],
    ["inline-style", "style"],
    ["literal-z", "z-auto"],
    ["raw-hex", "#123456"],
    ["raw-hex", "#fff"],
  ]);
  assert.ok(findings.every(({ context }) => typeof context === "string" && context.length > 0));
});
