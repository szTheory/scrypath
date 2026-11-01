"use strict";

const fs = require("node:fs");

const requiredUtilities = [
  ["bg-black", /background-color:\s*var\(--color-black\)/],
  ["text-black", /color:\s*var\(--color-black\)/],
  ["bg-white", /background-color:\s*var\(--color-white\)/],
  ["text-white", /color:\s*var\(--color-white\)/],
  ["p-4", /padding:\s*calc\(var\(--spacing\)\s*\*\s*4\)/],
  ["gap-8", /gap:\s*calc\(var\(--spacing\)\s*\*\s*8\)/],
  ["text-sm", /font-size:\s*var\(--text-sm\)/],
  ["font-semibold", /font-weight:\s*var\(--font-weight-semibold\)/],
];

function selectorsFor(css, utility) {
  const escaped = utility.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const expression = new RegExp(`\\.${escaped}\\s*\\{([^{}]*)\\}`, "g");
  return [...css.matchAll(expression)].map((match) => match[1]);
}

function assertUtility(css, utility, declaration, label) {
  const rules = selectorsFor(css, utility);
  if (rules.length === 0) {
    throw new Error(`${label} is missing forced utility .${utility}`);
  }
  if (declaration && !rules.some((body) => declaration.test(body))) {
    throw new Error(`${label} .${utility} does not retain its expected declaration`);
  }
}

function assertOutput(css, label, { semantic = false } = {}) {
  if (typeof css !== "string" || css.trim() === "") {
    throw new Error(`${label} generated CSS output is missing or empty`);
  }

  for (const utility of ["bg-red-500", "text-blue-500"]) {
    if (selectorsFor(css, utility).length > 0) {
      throw new Error(`${label} still contains forced default palette utility .${utility}`);
    }
  }

  for (const [utility, declaration] of requiredUtilities) {
    assertUtility(css, utility, declaration, label);
  }

  if (semantic) {
    assertUtility(css, "bg-primary", /background-color:\s*var\(--color-primary\)/, label);
    assertUtility(css, "text-base-content", /color:\s*var\(--color-base-content\)/, label);
  }
}

function assertBundles({ standaloneCss, hostCss }) {
  assertOutput(standaloneCss, "standalone Ops", { semantic: true });
  assertOutput(hostCss, "mounted host");
}

function assertMountedStylesheetOrder(html) {
  if (typeof html !== "string" || html.trim() === "") {
    throw new Error("mounted Ops response is missing or empty");
  }

  const stylesheets = [...html.matchAll(/<link\b[^>]*>/gi)].map((match) => match[0])
    .filter((tag) => /\brel\s*=\s*["']?stylesheet\b/i.test(tag))
    .map((tag) => {
      const href = tag.match(/\bhref\s*=\s*(["'])(.*?)\1/i);
      return href?.[2] ?? "";
    });
  const hostIndex = stylesheets.findIndex((href) => /^\/assets\/css\/app(?:-[a-f0-9]{8,64})?\.css(?:\?.*)?$/i.test(href));
  const opsIndex = stylesheets.findIndex((href) => /^\/admin\/search\/assets\/css\/app(?:-[a-f0-9]{8,64})?\.css(?:\?.*)?$/i.test(href));

  if (hostIndex < 0) throw new Error("mounted Ops response is missing the host stylesheet");
  if (opsIndex < 0) throw new Error("mounted Ops response is missing the independently served Ops stylesheet");
  if (hostIndex >= opsIndex) throw new Error("mounted Ops response must load host CSS before Ops CSS");
}

function parseArgs(args) {
  const options = {};
  for (let index = 0; index < args.length; index += 2) {
    const key = args[index];
    const value = args[index + 1];
    if (!["--standalone", "--host", "--mounted-html"].includes(key) || !value || value.startsWith("--")) {
      throw new Error("Usage: ui_bundle_contract.cjs --standalone <css> --host <css> [--mounted-html <html>]");
    }
    if (Object.hasOwn(options, key)) throw new Error(`duplicate option: ${key}`);
    options[key] = value;
  }
  if (!options["--standalone"] || !options["--host"]) {
    throw new Error("Usage: ui_bundle_contract.cjs --standalone <css> --host <css> [--mounted-html <html>]");
  }
  return options;
}

function validateFiles(args) {
  const options = parseArgs(args);
  const readRequired = (option, label) => {
    const file = options[option];
    if (!file || !fs.existsSync(file)) throw new Error(`${label} output file is missing: ${file || "<not provided>"}`);
    return fs.readFileSync(file, "utf8");
  };

  assertBundles({
    standaloneCss: readRequired("--standalone", "standalone Ops"),
    hostCss: readRequired("--host", "mounted host"),
  });
  if (options["--mounted-html"]) {
    assertMountedStylesheetOrder(readRequired("--mounted-html", "mounted Ops response"));
  }
}

if (require.main === module) {
  try {
    validateFiles(process.argv.slice(2));
    process.stdout.write("Both forced utility bundles and mounted stylesheet composition passed.\n");
  } catch (error) {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 1;
  }
}

module.exports = { assertBundles, assertMountedStylesheetOrder, assertOutput, validateFiles };
