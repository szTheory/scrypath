"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

const BOOTSTRAP_COMMIT = "767f368473f17fba43d7be4675c53ab65a87530c";
const POLICY_VERSION = 1;
const LEDGER_PATH = "scripts/ci/ui-literal-baseline.json";
const SOURCE_ROOTS = [
  "scrypath_ops/lib",
  "scrypath_ops/assets",
  "examples/scrypath_ecommerce/lib",
  "examples/scrypath_ecommerce/assets",
];
const SOURCE_EXTENSIONS = new Set([".heex", ".ex", ".css", ".js", ".jsx", ".mjs", ".cjs", ".ts", ".tsx"]);
const MAX_FILES = 12000;
const MAX_FILE_BYTES = 2 * 1024 * 1024;
const MAX_GIT_OUTPUT = 64 * 1024 * 1024;
const GIT_TIMEOUT_MS = 30000;
const RULES = new Set(["raw-hex", "arbitrary-value", "inline-style", "literal-z"]);

function fail(message) {
  const error = new Error(message);
  error.policy = true;
  throw error;
}

function gitEnvironment() {
  const clean = { GIT_TERMINAL_PROMPT: "0", GIT_CONFIG_NOSYSTEM: "1" };
  for (const key of ["PATH", "HOME", "USERPROFILE", "SYSTEMROOT", "COMSPEC", "TEMP", "TMP", "LANG", "LC_ALL"]) {
    if (process.env[key]) clean[key] = process.env[key];
  }
  return clean;
}

function git(repo, args, options = {}) {
  const result = spawnSync("git", args, {
    cwd: repo,
    env: gitEnvironment(),
    encoding: options.encoding === "buffer" ? undefined : "utf8",
    input: options.input,
    maxBuffer: options.maxBuffer || MAX_GIT_OUTPUT,
    timeout: options.timeout || GIT_TIMEOUT_MS,
    windowsHide: true,
  });
  if (result.error) fail(`git ${args[0]} failed: ${result.error.message}`);
  if (result.status !== 0) {
    const stderr = String(result.stderr || "").trim().slice(0, 4000);
    fail(`git ${args[0]} failed (${result.status}): ${stderr || "no diagnostic"}`);
  }
  return result.stdout;
}

function normalizedPath(value) {
  return value.split(path.sep).join("/");
}

function isSourcePath(file) {
  const normalized = normalizedPath(file);
  if (!SOURCE_ROOTS.some((root) => normalized === root || normalized.startsWith(`${root}/`))) return false;
  if (/(^|\/)(vendor|priv\/static|test|tests|fixture|fixtures|docs?)(\/|$)/i.test(normalized)) return false;
  return SOURCE_EXTENSIONS.has(path.extname(normalized).toLowerCase());
}

function discoverFiles(root) {
  const result = [];
  const visit = (relative) => {
    const absolute = path.join(root, relative);
    let entries;
    try {
      entries = fs.readdirSync(absolute, { withFileTypes: true });
    } catch (error) {
      if (error.code === "ENOENT") return;
      throw error;
    }
    entries.sort((a, b) => a.name.localeCompare(b.name));
    for (const entry of entries) {
      if (entry.name === ".git" || entry.name === "node_modules" || entry.name === "vendor" || entry.name === "priv") continue;
      const child = path.join(relative, entry.name);
      const full = path.join(root, child);
      if (entry.isSymbolicLink()) continue;
      if (entry.isDirectory()) visit(child);
      else if (entry.isFile() && isSourcePath(child)) {
        const stat = fs.statSync(full);
        if (stat.size > MAX_FILE_BYTES) fail(`source file exceeds ${MAX_FILE_BYTES} bytes: ${normalizedPath(child)}`);
        result.push(normalizedPath(child));
        if (result.length > MAX_FILES) fail(`source discovery exceeds ${MAX_FILES} files`);
      }
    }
  };
  for (const sourceRoot of SOURCE_ROOTS) visit(sourceRoot);
  return result.sort();
}

function locationAt(source, index) {
  const before = source.slice(0, index);
  const line = 1 + (before.match(/\n/g) || []).length;
  const lastNewline = before.lastIndexOf("\n");
  return { line, column: index - lastNewline };
}

function makeFinding(rule, file, context, value, source, index) {
  const { line, column } = locationAt(source, index);
  const repair = {
    "raw-hex": "Move the value into the approved token authority and reference that token.",
    "arbitrary-value": "Replace the one-off utility value with a named design token or component class.",
    "inline-style": "Move this declaration into the component stylesheet or a named utility.",
    "literal-z": "Use the named z-ops-* layer token instead of a literal z utility.",
  }[rule];
  return { rule, path: file, context, value, line, column, repair };
}

function stableContext(...parts) {
  return parts.filter(Boolean).join(" > ").replace(/\s+/g, " ").trim().slice(0, 400);
}

function scanUtilityString(value, file, source, baseIndex, context, findings) {
  const tokens = value.match(/[^\s"'`]+/g) || [];
  let searchFrom = 0;
  for (const token of tokens) {
    const tokenIndex = value.indexOf(token, searchFrom);
    searchFrom = tokenIndex + token.length;
    const base = utilityBase(token);
    if (/\[[^\]]+\]/.test(base)) {
      scanColorValue(base, file, source, baseIndex + tokenIndex + token.length - base.length, context, findings);
    }
    if (/(?:^|-)\[[^\]]+\]|-(?:\([^)]*\))/.test(base)) {
      findings.push(makeFinding("arbitrary-value", file, context, token, source, baseIndex + tokenIndex));
    }
    if (/^-?z-(?:auto|\d+|\[[^\]]+\]|\([^)]*\))$/.test(base) && !base.startsWith("z-ops-")) {
      findings.push(makeFinding("literal-z", file, context, token, source, baseIndex + tokenIndex));
    }
  }
}

function utilityBase(token) {
  let square = 0;
  let round = 0;
  let lastVariant = -1;
  for (let i = 0; i < token.length; i += 1) {
    if (token[i] === "[") square += 1;
    else if (token[i] === "]") square = Math.max(0, square - 1);
    else if (token[i] === "(") round += 1;
    else if (token[i] === ")") round = Math.max(0, round - 1);
    else if (token[i] === ":" && square === 0 && round === 0) lastVariant = i;
  }
  return token.slice(lastVariant + 1);
}

function scanColorValue(value, file, source, index, context, findings) {
  // Fragment identifiers are references, including inside arbitrary utilities.
  const visible = value.replace(/url\s*\([^)]*\)/gi, (match) => " ".repeat(match.length));
  for (const match of visible.matchAll(/#(?:[\da-fA-F]{8}|[\da-fA-F]{6}|[\da-fA-F]{4}|[\da-fA-F]{3})\b/g)) {
    findings.push(makeFinding("raw-hex", file, context, match[0], source, index + match.index));
  }
}

function readQuoted(source, start) {
  const quote = source[start];
  let i = start + 1;
  while (i < source.length) {
    if (source[i] === "\\") { i += 2; continue; }
    if (source[i] === quote) return { value: source.slice(start + 1, i), end: i + 1 };
    i += 1;
  }
  return { value: source.slice(start + 1), end: source.length };
}

function skipBalanced(source, start, open = "{", close = "}") {
  let depth = 0;
  let quote = null;
  for (let i = start; i < source.length; i += 1) {
    const char = source[i];
    if (quote) {
      if (char === "\\") i += 1;
      else if (char === quote) quote = null;
      continue;
    }
    if (char === '"' || char === "'" || char === "`") { quote = char; continue; }
    if (char === open) depth += 1;
    else if (char === close) {
      depth -= 1;
      if (depth === 0) return i + 1;
    }
  }
  return source.length;
}

function parseAttributes(source, start, end) {
  const attrs = [];
  let i = start;
  while (i < end) {
    while (i < end && /\s|\//.test(source[i])) i += 1;
    if (i >= end || source[i] === ">") break;
    const nameStart = i;
    while (i < end && !/[\s=/>]/.test(source[i])) i += 1;
    if (i === nameStart) { i += 1; continue; }
    const name = source.slice(nameStart, i).toLowerCase();
    while (i < end && /\s/.test(source[i])) i += 1;
    if (source[i] !== "=") { attrs.push({ name, value: "", index: nameStart, valueIndex: i }); continue; }
    i += 1;
    while (i < end && /\s/.test(source[i])) i += 1;
    const valueIndex = i;
    let value = "";
    if (source[i] === '"' || source[i] === "'") {
      const quoted = readQuoted(source, i);
      value = quoted.value;
      i = quoted.end;
    } else if (source[i] === "{") {
      const next = skipBalanced(source, i);
      value = source.slice(i, next);
      i = next;
    } else {
      while (i < end && !/[\s>]/.test(source[i])) i += 1;
      value = source.slice(valueIndex, i);
    }
    attrs.push({ name, value, index: nameStart, valueIndex });
  }
  return attrs;
}

function stripHtmlComments(source) {
  return source.replace(/<!--[\s\S]*?-->/g, (match) => match.replace(/[^\n]/g, " "));
}

function scanMarkup(source, file, findings, outerContext = "") {
  const visible = stripHtmlComments(source);
  const stack = [];
  let nextRoot = 1;
  let i = 0;
  while (i < visible.length) {
    const open = visible.indexOf("<", i);
    if (open < 0) break;
    if (visible.startsWith("<!--", open)) { i = (visible.indexOf("-->", open) + 3) || visible.length; continue; }
    let cursor = open + 1;
    const closing = visible[cursor] === "/";
    if (closing) cursor += 1;
    if (!/[A-Za-z]/.test(visible[cursor] || "")) { i = open + 1; continue; }
    const nameStart = cursor;
    while (cursor < visible.length && /[\w:-]/.test(visible[cursor])) cursor += 1;
    const tag = visible.slice(nameStart, cursor).toLowerCase();
    if (closing) {
      const prior = stack.findLastIndex((item) => item.tag === tag);
      if (prior >= 0) stack.length = prior;
      i = cursor;
      continue;
    }
    let quote = null;
    let end = cursor;
    let braceDepth = 0;
    while (end < visible.length) {
      const char = visible[end];
      if (quote) {
        if (char === "\\") end += 2;
        else { if (char === quote) quote = null; end += 1; }
      } else if (char === '"' || char === "'") { quote = char; end += 1; }
      else if (char === "{") { braceDepth += 1; end += 1; }
      else if (char === "}") { braceDepth = Math.max(0, braceDepth - 1); end += 1; }
      else if (char === ">" && braceDepth === 0) break;
      else end += 1;
    }
    const attrs = parseAttributes(visible, cursor, end);
    const semanticAttrs = attrs
      .filter((attr) => /^(id|name|role|aria-label|data-[\w-]+)$/.test(attr.name))
      .map((attr) => `${attr.name}=${normalizeAttr(attr.value)}`).sort();
    const siblingIndex = stack.length ? stack[stack.length - 1].nextChild++ : nextRoot++;
    const currentContext = stableContext(outerContext, ...stack.map((entry) => `${entry.tag}[${entry.index}]`), `${tag}[${siblingIndex}]`, ...semanticAttrs);
    for (const attr of attrs) {
      const index = attr.index;
      const valueSourceStart = attr.valueIndex + (source[attr.valueIndex] === '"' || source[attr.valueIndex] === "'" ? 1 : 0);
      if (attr.name === "style") {
        findings.push(makeFinding("inline-style", file, currentContext, styleIdentity(attr.value, file), source, index));
        for (const match of attr.value.matchAll(/#[\da-fA-F]{3,8}\b/g)) {
          const at = valueSourceStart + match.index;
          findings.push(makeFinding("raw-hex", file, currentContext, match[0], source, at));
        }
      }
      if (/^(?:fill|stroke|color|stop-color|flood-color|lighting-color|bgcolor)$/.test(attr.name)) {
        scanColorValue(attr.value, file, source, valueSourceStart, stableContext(currentContext, attr.name), findings);
      }
      if (attr.name === "class" || attr.name === "classname" || attr.name === "class:list" || attr.name.startsWith("class:")) {
        const literals = [...attr.value.matchAll(/"([^"\n]*)"|'([^'\n]*)'|([^{}"'`]+)/g)];
        if (!literals.length && attr.value && !attr.value.startsWith("{")) {
          scanUtilityString(attr.value, file, source, valueSourceStart, currentContext, findings);
        }
        for (const literal of literals) {
          const value = literal[1] ?? literal[2] ?? literal[3] ?? "";
          const tokenOffset = literal.index + (literal[1] != null || literal[2] != null ? 1 : 0);
          scanUtilityString(value, file, source, valueSourceStart + tokenOffset, currentContext, findings);
        }
      }
    }
    const selfClosing = visible.slice(cursor, end).trimEnd().endsWith("/") || new Set(["area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr"]).has(tag);
    if (!selfClosing) stack.push({ tag, index: siblingIndex, nextChild: 1 });
    i = Math.min(end + 1, visible.length);
  }
}

// Keep source values in the identity. Token boundaries and quoted contents are
// meaningful; whitespace and comments outside strings are formatting only.
function styleIdentity(value, file) {
  if (value.length > 8000) fail(`inline-style source exceeds the bounded reader limit: ${file}`);
  const tokens = [];
  const expression = value.startsWith("{");
  const javascript = /\.[cm]?[jt]sx?$/i.test(file);
  const word = /(?:[a-zA-Z_@-][\w@-]*|(?:\d*\.\d+|\d+)(?:[a-zA-Z%]+)?|[^\s])/y;
  for (let i = 0; i < value.length;) {
    if (/\s/.test(value[i])) { i += 1; continue; }
    if (value.startsWith("/*", i)) {
      const end = value.indexOf("*/", i + 2);
      if (end < 0) fail(`unterminated inline-style comment: ${file}`);
      i = end + 2; continue;
    }
    if (expression && ((javascript && value.startsWith("//", i)) || (!javascript && value[i] === "#"))) {
      const end = value.indexOf("\n", i);
      i = end < 0 ? value.length : end + 1; continue;
    }
    if (value[i] === '"' || value[i] === "'" || value[i] === "`") {
      const quoted = readQuoted(value, i);
      tokens.push(value.slice(i, quoted.end)); i = quoted.end;
    } else {
      word.lastIndex = i;
      const match = word.exec(value);
      if (!match) fail(`unsupported inline-style source: ${file}`);
      tokens.push(match[0]); i = word.lastIndex;
    }
  }
  const normalized = JSON.stringify(tokens);
  if (normalized.length > 500) fail(`inline-style value exceeds the ledger identity limit: ${file}`);
  return normalized;
}

function normalizeAttr(value) {
  return value.replace(/\s+/g, " ").trim().slice(0, 120);
}

function scanElixirTemplates(source, file, findings) {
  const pattern = /~H("""|'''|"|')/g;
  let match;
  while ((match = pattern.exec(source))) {
    if (!elixirCodeAt(source, match.index)) continue;
    const delimiter = match[1];
    const start = pattern.lastIndex;
    const close = delimiter.length === 3 ? source.indexOf(delimiter, start) : findQuotedEnd(source, start, delimiter);
    if (close < 0) continue;
    const template = source.slice(start, close);
    const preceding = source.slice(Math.max(0, match.index - 220), match.index);
    const fn = preceding.match(/(?:def|defp)\s+([a-zA-Z0-9_?!]+)/g)?.at(-1)?.replace(/.*\s/, "") || "template";
    scanMarkup(template, file, findings, `~H:${fn}`);
    pattern.lastIndex = close + delimiter.length;
  }
  // Static class literals outside HEEx templates, such as class: "..." in component APIs.
  for (const match of source.matchAll(/\bclass(?:Name)?\s*:\s*("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')/g)) {
    if (!elixirCodeAt(source, match.index)) continue;
    const quote = match[1][0];
    scanUtilityString(match[1].slice(1, -1), file, source, match.index + match[0].indexOf(quote) + 1, "Elixir static class option", findings);
  }
}

function elixirCodeAt(source, target) {
  let i = 0;
  while (i < target) {
    if (source[i] === "#") {
      const newline = source.indexOf("\n", i + 1);
      if (newline < 0 || newline >= target) return false;
      i = newline + 1;
      continue;
    }
    if (source[i] === '"' || source[i] === "'") {
      const quote = source[i];
      const delimiter = source.slice(i, i + 3) === quote.repeat(3) ? quote.repeat(3) : quote;
      const end = source.indexOf(delimiter, i + delimiter.length);
      if (end < 0 || end >= target) return false;
      i = end + delimiter.length;
      continue;
    }
    i += 1;
  }
  return i === target;
}

function findQuotedEnd(source, start, delimiter) {
  for (let i = start; i < source.length; i += 1) {
    if (source[i] === "\\") { i += 1; continue; }
    if (source[i] === delimiter) return i;
  }
  return -1;
}

function scanJsTs(source, file, findings) {
  const first = findings.length;
  const commentless = maskJsComments(source);
  const contexts = [
    /(?:\.\s*className\s*=|\b(?:className|class)\s*:)\s*("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`)/g,
    /\bsetAttribute\s*\(\s*["']class["']\s*,\s*("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`)/g,
  ];
  for (const regex of contexts) {
    for (const match of commentless.matchAll(regex)) {
      if (!jsCodeAt(commentless, match.index)) continue;
      const literal = match[1];
      scanUtilityString(literal.slice(1, -1), file, source, match.index + match[0].lastIndexOf(literal) + 1, stableContext("JS/TS class literal", jsEnclosingContext(commentless, match.index)), findings);
    }
  }
  for (const match of commentless.matchAll(/\bclassList\.(?:add|toggle|replace)\s*\(/g)) {
    if (!jsCodeAt(commentless, match.index)) continue;
    const start = match.index + match[0].length;
    const end = skipBalanced(commentless, start - 1, "(", ")") - 1;
    for (const literal of commentless.slice(start, end).matchAll(/"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`/g)) {
      scanUtilityString(literal[0].slice(1, -1), file, source, start + literal.index + 1, stableContext("JS/TS class literal", jsEnclosingContext(commentless, match.index)), findings);
    }
  }
  // Bounded static styling APIs: color property literals and bar-color maps.
  // Other strings (prose, selectors and fragment references) are not colors.
  for (const match of commentless.matchAll(/\b((?:[a-zA-Z]*[Cc]olor|color|fill|stroke|background|boxShadow|textShadow))\s*[:=]\s*(["'`])([^\n]*?)\2/g)) {
    if (!jsCodeAt(commentless, match.index)) continue;
    scanColorValue(match[3], file, source, match.index + match[0].indexOf(match[2]) + 1, stableContext(`JS/TS styling:${match[1]}`, jsEnclosingContext(commentless, match.index)), findings);
  }
  for (const match of commentless.matchAll(/\bbarColors\s*:\s*\{/g)) {
    if (!jsCodeAt(commentless, match.index)) continue;
    const open = match.index + match[0].length - 1;
    const end = skipBalanced(commentless, open);
    for (const literal of commentless.slice(open + 1, end - 1).matchAll(/(?:[\w.]+|"[^"\n]*"|'[^'\n]*')\s*:\s*(["'`])([^\n]*?)\1/g)) {
      const index = open + 1 + literal.index + literal[0].indexOf(literal[1], literal[0].indexOf(":")) + 1;
      scanColorValue(literal[2], file, source, index, stableContext("JS/TS styling:barColors", jsEnclosingContext(commentless, match.index)), findings);
    }
  }
  scanMarkup(commentless, file, findings, "JS/TS JSX");
  // A JSX style literal can also match a static JavaScript color property.
  // Count source occurrences, rather than overlapping reader paths.
  const seen = new Set();
  for (let i = findings.length - 1; i >= first; i -= 1) {
    const item = findings[i];
    const key = JSON.stringify([item.rule, item.line, item.column, item.value]);
    if (seen.has(key)) findings.splice(i, 1);
    else seen.add(key);
  }
}

function jsCodeAt(source, target) {
  for (let i = 0; i < target; i += 1) {
    if (source[i] === '"' || source[i] === "'" || source[i] === "`") {
      const end = readQuoted(source, i).end;
      if (end > target) return false;
      i = end - 1;
    }
  }
  return true;
}

function jsEnclosingContext(source, target) {
  const stack = [];
  for (let i = 0; i < target; i += 1) {
    if (source[i] === '"' || source[i] === "'" || source[i] === "`") { i = readQuoted(source, i).end - 1; continue; }
    if (source[i] === "{") {
      const prefix = source.slice(Math.max(0, i - 500), i);
      const named = /(?:function\s+([\w$]+)\s*\([^{}]*\)|([\w$]+)\s*[:=]\s*(?:async\s*)?(?:function\s*)?\([^{}]*\)\s*=>?|([\w$]+)\s*\([^{}]*\))\s*$/.exec(prefix);
      const name = named && (named[1] || named[2] || named[3]);
      stack.push(name && !/^(if|for|while|switch|catch|with)$/.test(name) ? `function:${name}` : "");
    } else if (source[i] === "}") stack.pop();
  }
  return stack.filter(Boolean).join(" > ");
}

function maskJsComments(source) {
  const chars = source.split("");
  for (let i = 0; i < source.length;) {
    if (source[i] === '"' || source[i] === "'" || source[i] === "`") { i = readQuoted(source, i).end; continue; }
    let end;
    if (source.startsWith("/*", i)) end = skipCssComment(source, i);
    else if (source.startsWith("//", i)) { end = source.indexOf("\n", i); if (end < 0) end = source.length; }
    else { i += 1; continue; }
    for (; i < end; i += 1) if (chars[i] !== "\n") chars[i] = " ";
  }
  return chars.join("");
}

function skipCssComment(source, index) {
  const close = source.indexOf("*/", index + 2);
  return close < 0 ? source.length : close + 2;
}

function skipCssString(source, index) {
  const quote = source[index];
  for (let i = index + 1; i < source.length; i += 1) {
    if (source[i] === "\\") { i += 1; continue; }
    if (source[i] === quote) return i + 1;
  }
  return source.length;
}

function cssTokenRanges(source, file) {
  const ranges = [];
  if (file !== "scrypath_ops/assets/css/app.css" && file !== "examples/scrypath_ecommerce/assets/css/app.css") return ranges;
  const findBlockEnd = (open) => {
    let depth = 1;
    for (let i = open + 1; i < source.length; i += 1) {
      if (source.startsWith("/*", i)) { i = skipCssComment(source, i) - 1; continue; }
      if (source[i] === '"' || source[i] === "'") { i = skipCssString(source, i) - 1; continue; }
      if (source[i] === "{") depth += 1;
      else if (source[i] === "}" && --depth === 0) return i + 1;
    }
    fail(`unterminated token authority: ${file}`);
  };
  let depth = 0;
  for (let i = 0; i < source.length; i += 1) {
    if (source.startsWith("/*", i)) { i = skipCssComment(source, i) - 1; continue; }
    if (source[i] === '"' || source[i] === "'") { i = skipCssString(source, i) - 1; continue; }
    if (depth === 0 && source[i] === "@") {
      const header = /^(?:@theme\s*\{|@plugin\s+["']\.\.\/vendor\/daisyui-theme["']\s*\{)/.exec(source.slice(i));
      if (header) {
        const open = i + header[0].length - 1;
        const end = findBlockEnd(open);
        const body = source.slice(open + 1, end - 1);
        if (header[0].startsWith("@theme") || namedThemeBody(body)) ranges.push([open, end]);
        i = end - 1; continue;
      }
    }
    if (source[i] === "{") depth += 1;
    else if (source[i] === "}") depth -= 1;
  }
  return ranges;
}

function namedThemeBody(body) {
  let start = 0;
  for (let i = 0; i < body.length; i += 1) {
    if (body.startsWith("/*", i)) { i = skipCssComment(body, i) - 1; continue; }
    if (body[i] === '"' || body[i] === "'") { i = skipCssString(body, i) - 1; continue; }
    if (body[i] === ";") {
      const declaration = body.slice(start, i).replace(/\/\*[\s\S]*?\*\//g, " ").trim();
      if (/^name\s*:\s*["'](?:light|dark)["']$/.test(declaration)) return true;
      start = i + 1;
    }
  }
  return false;
}

function isInsideRange(index, ranges) {
  return ranges.some(([start, end]) => index > start && index < end);
}

function scanCss(source, file, findings) {
  const ranges = cssTokenRanges(source, file);
  const blocks = [];
  let statementStart = 0;
  let i = 0;
  const parseDeclaration = (start, end) => {
    const raw = source.slice(start, end);
    const cleaned = raw.replace(/\/\*[\s\S]*?\*\//g, " ").trim();
    const declaration = /^([\w-]+)\s*:\s*([\s\S]*)$/.exec(cleaned);
    if (!declaration) {
      const apply = /^@apply\s+([\s\S]*)$/.exec(cleaned);
      if (apply) scanUtilityString(apply[1], file, source, start + raw.indexOf(apply[1]), stableContext(...blocks.map(normalizeCssHeader), "@apply"), findings);
      return;
    }
    const property = declaration[1].toLowerCase();
    const context = stableContext(...blocks.filter((item) => !item.startsWith("@charset")).map(normalizeCssHeader), property);
    const colon = raw.indexOf(":");
    const valueStart = colon < 0 ? start : start + colon + 1 + (raw.slice(colon + 1).match(/^\s*/)?.[0].length || 0);
    let value = source.slice(valueStart, end);
    value = value.replace(/\/\*[\s\S]*?\*\//g, (match) => match.replace(/[^\n]/g, " "));
    value = value.replace(/url\s*\([^)]*\)/gi, (match) => match.replace(/[^\n]/g, " "));
    value = value.replace(/"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'/g, (match) => match.replace(/[^\n]/g, " "));
    const colorProperty = /^(?:color|background(?:-.+)?|border(?:-.+)?|outline(?:-.+)?|box-shadow|text-shadow|filter|fill|stroke|caret-color|accent-color|mask(?:-.+)?|scrollbar-color|--[\w-]+)$/.test(property);
    if (!isInsideRange(start, ranges) && colorProperty) {
      for (const match of value.matchAll(/#[\da-fA-F]{3,8}\b/g)) {
        findings.push(makeFinding("raw-hex", file, context, match[0], source, valueStart + match.index));
      }
    }
  };
  while (i < source.length) {
    if (source.startsWith("/*", i)) { i = skipCssComment(source, i); continue; }
    if (source[i] === '"' || source[i] === "'") { i = skipCssString(source, i); continue; }
    if (source[i] === ";") {
      parseDeclaration(statementStart, i);
      statementStart = i + 1;
    } else if (source[i] === "{") {
      const header = source.slice(statementStart, i).replace(/\/\*[\s\S]*?\*\//g, " ").trim();
      if (header) blocks.push(header);
      statementStart = i + 1;
    } else if (source[i] === "}") {
      parseDeclaration(statementStart, i);
      if (blocks.length) blocks.pop();
      statementStart = i + 1;
    }
    i += 1;
  }
  parseDeclaration(statementStart, source.length);
}

function normalizeCssHeader(value) {
  return value.replace(/\s+/g, " ").trim().replace(/\s*([,:>+~])\s*/g, "$1").slice(0, 300);
}

function scanFile(source, file, findings) {
  const extension = path.extname(file).toLowerCase();
  if (extension === ".css") scanCss(source, file, findings);
  else if (extension === ".heex") scanMarkup(source, file, findings);
  else if (extension === ".ex") scanElixirTemplates(source, file, findings);
  else if ([".js", ".jsx", ".mjs", ".cjs", ".ts", ".tsx"].includes(extension)) scanJsTs(source, file, findings);
}

function sortFindings(findings) {
  return findings.sort((a, b) => compareText(`${a.path}\0${a.rule}\0${a.context}\0${a.value}\0${a.line}`, `${b.path}\0${b.rule}\0${b.context}\0${b.value}\0${b.line}`));
}

function compareText(left, right) { return left < right ? -1 : left > right ? 1 : 0; }

function scanTree(root) {
  const absoluteRoot = path.resolve(root);
  const findings = [];
  for (const file of discoverFiles(absoluteRoot)) {
    const source = fs.readFileSync(path.join(absoluteRoot, file), "utf8");
    scanFile(source, file, findings);
  }
  return sortFindings(findings);
}

function scanTreeAtCommit(repo, oid) {
  if (!isOid(oid)) fail(`invalid commit object id: ${oid}`);
  const listing = git(repo, ["ls-tree", "-rz", "--full-tree", oid], { maxBuffer: MAX_GIT_OUTPUT });
  const entries = String(listing).split("\0").filter(Boolean).map((entry) => {
    const separator = entry.indexOf("\t");
    if (separator < 0) fail("git ls-tree returned a malformed tree entry");
    const header = entry.slice(0, separator).split(" ");
    const file = entry.slice(separator + 1);
    return { mode: header[0], type: header[1], oid: header[2], file };
  }).filter((entry) => entry.type === "blob" && isSourcePath(entry.file));
  if (entries.length > MAX_FILES) fail(`Git tree source count exceeds ${MAX_FILES}`);
  const findings = [];
  for (const entry of entries) if (!isOid(entry.oid)) fail(`invalid blob object id for ${entry.file}`);
  if (entries.length === 0) return findings;
  const batch = git(repo, ["cat-file", "--batch"], {
    input: `${entries.map((entry) => entry.oid).join("\n")}\n`,
    encoding: "buffer",
    maxBuffer: MAX_GIT_OUTPUT,
  });
  let offset = 0;
  for (const entry of entries) {
    const newline = batch.indexOf(0x0a, offset);
    if (newline < 0) fail("git cat-file --batch returned a truncated header");
    const header = batch.toString("utf8", offset, newline).split(" ");
    if (header[0] !== entry.oid || header[1] !== "blob" || !/^\d+$/.test(header[2] || "")) fail(`git cat-file --batch returned an invalid blob header for ${entry.file}`);
    const size = Number(header[2]);
    if (!Number.isSafeInteger(size) || size > MAX_FILE_BYTES) fail(`source file exceeds ${MAX_FILE_BYTES} bytes: ${entry.file}`);
    const bodyStart = newline + 1;
    const bodyEnd = bodyStart + size;
    if (bodyEnd >= batch.length || batch[bodyEnd] !== 0x0a) fail(`git cat-file --batch returned a truncated blob for ${entry.file}`);
    const source = batch.toString("utf8", bodyStart, bodyEnd);
    scanFile(source, normalizedPath(entry.file), findings);
    offset = bodyEnd + 1;
  }
  return sortFindings(findings);
}

function identity(finding) {
  return JSON.stringify([finding.rule, finding.path, finding.context, finding.value]);
}

function multisetFromFindings(findings) {
  const map = new Map();
  for (const finding of findings) {
    if (!RULES.has(finding.rule)) fail(`unknown finding rule: ${finding.rule}`);
    const key = identity(finding);
    map.set(key, (map.get(key) || 0) + 1);
  }
  return map;
}

function multisetEntries(map) {
  return [...map.entries()].map(([key, count]) => {
    const [rule, file, context, value] = JSON.parse(key);
    return { rule, path: file, context, value, count };
  }).sort((a, b) => compareText(identity(a), identity(b)));
}

function validateRelativeSourcePath(file) {
  if (typeof file !== "string" || file.includes("\\") || file.startsWith("/") || file.split("/").some((part) => !part || part === "." || part === "..")) fail(`invalid finding path: ${file}`);
  if (!isSourcePath(file)) fail(`finding path is outside the authored UI source roots: ${file}`);
}

function parseLedgerText(text, label = "ledger") {
  let parsed;
  try { parsed = JSON.parse(text); } catch { fail(`${label} is not valid JSON`); }
  if (!parsed || Array.isArray(parsed) || typeof parsed !== "object") fail(`${label} must be a JSON object`);
  const keys = Object.keys(parsed).sort();
  if (JSON.stringify(keys) !== JSON.stringify(["bootstrap_commit", "findings", "version"])) fail(`${label} has missing or unknown metadata fields`);
  if (parsed.version !== POLICY_VERSION) fail(`${label} has unknown policy version: ${String(parsed.version)}`);
  if (parsed.bootstrap_commit !== BOOTSTRAP_COMMIT) fail(`${label} does not name the pinned bootstrap commit`);
  if (!Array.isArray(parsed.findings)) fail(`${label}.findings must be an array`);
  const map = new Map();
  let previous = "";
  for (const entry of parsed.findings) {
    if (!entry || Array.isArray(entry) || typeof entry !== "object") fail(`${label} has a malformed finding entry`);
    const fields = Object.keys(entry).sort();
    if (JSON.stringify(fields) !== JSON.stringify(["context", "count", "path", "rule", "value"])) fail(`${label} finding has unknown or missing fields`);
    if (!RULES.has(entry.rule)) fail(`${label} contains an unknown finding rule: ${String(entry.rule)}`);
    validateRelativeSourcePath(entry.path);
    if (typeof entry.context !== "string" || entry.context.length === 0 || entry.context.length > 400) fail(`${label} contains an invalid context`);
    if (typeof entry.value !== "string" || entry.value.length === 0 || entry.value.length > 500) fail(`${label} contains an invalid value`);
    if (!Number.isInteger(entry.count) || entry.count < 0) fail(`${label} counts must be non-negative integers`);
    const key = identity(entry);
    if (key <= previous) fail(`${label} entries must be unique and sorted`);
    previous = key;
    if (entry.count > 0) map.set(key, entry.count);
  }
  return { metadata: { version: parsed.version, bootstrap_commit: parsed.bootstrap_commit }, map };
}

function serializeLedger(map) {
  return `${JSON.stringify({ version: POLICY_VERSION, bootstrap_commit: BOOTSTRAP_COMMIT, findings: multisetEntries(map) }, null, 2)}\n`;
}

function ledgerFromRoot(root) {
  const file = path.join(root, LEDGER_PATH);
  try { return parseLedgerText(fs.readFileSync(file, "utf8"), LEDGER_PATH); }
  catch (error) {
    if (error.code === "ENOENT") fail(`required ledger is missing: ${LEDGER_PATH}`);
    throw error;
  }
}

function subset(candidate, authority) {
  for (const [key, count] of candidate) if (count > (authority.get(key) || 0)) return false;
  return true;
}

function sameMultiset(left, right) {
  if (left.size !== right.size) return false;
  for (const [key, count] of left) if (right.get(key) !== count) return false;
  return true;
}

function describeDelta(candidate, authority) {
  const extra = [];
  for (const [key, count] of candidate) {
    const allowed = authority.get(key) || 0;
    if (count > allowed) {
      const [rule, file, context, value] = JSON.parse(key);
      extra.push({ finding: { rule, path: file, context, value }, actual: count, allowed });
    }
  }
  return extra.slice(0, 8).map(({ finding, actual, allowed }) => `${finding.rule} ${finding.path} ${finding.value} count ${actual} exceeds ${allowed}`).join("; ");
}

function isOid(value) { return typeof value === "string" && /^[0-9a-f]{40}$/i.test(value); }

function maybeGit(repo, args, options = {}) {
  const result = spawnSync("git", args, {
    cwd: repo, env: gitEnvironment(), encoding: options.encoding === "buffer" ? undefined : "utf8",
    input: options.input, maxBuffer: options.maxBuffer || MAX_GIT_OUTPUT,
    timeout: options.timeout || GIT_TIMEOUT_MS, windowsHide: true,
  });
  if (result.error) fail(`git ${args[0]} failed: ${result.error.message}`);
  return result.status === 0 ? result.stdout : null;
}

function blobAt(repo, oid, file) {
  if (!isOid(oid)) fail(`invalid commit object id: ${oid}`);
  const result = maybeGit(repo, ["show", `${oid}:${file}`], { maxBuffer: MAX_FILE_BYTES + 1 });
  if (result == null) return null;
  if (Buffer.byteLength(String(result), "utf8") > MAX_FILE_BYTES) fail(`Git blob exceeds ${MAX_FILE_BYTES} bytes: ${file}`);
  return String(result);
}

function commitParents(repo, oid) {
  const output = git(repo, ["show", "-s", "--format=%H%x00%P", oid]).trim().split("\0");
  if (!isOid(output[0]) || output[0].toLowerCase() !== oid.toLowerCase()) fail(`Git returned a mismatched commit for ${oid}`);
  const parents = (output[1] || "").trim().split(/\s+/).filter(Boolean);
  if (parents.some((parent) => !isOid(parent))) fail(`invalid parent object id in ${oid}`);
  return parents;
}

function firstParentChain(repo, oid) {
  if (!isOid(oid)) fail(`invalid commit object id: ${oid}`);
  const output = String(git(repo, ["rev-list", "--first-parent", "--reverse", oid], { maxBuffer: 8 * 1024 * 1024 })).trim();
  const commits = output ? output.split(/\r?\n/) : [];
  if (!commits.length || commits.length > 100000 || commits.some((commit) => !isOid(commit))) fail(`invalid or oversized first-parent history for ${oid}`);
  return commits;
}

function verifyLedgerHistory(repo, oid, label) {
  const allCommits = firstParentChain(repo, oid);
  const changedOutput = String(git(repo, ["log", "--first-parent", "--reverse", "--format=%H", oid, "--", LEDGER_PATH], { maxBuffer: 8 * 1024 * 1024 })).trim();
  const commits = changedOutput ? changedOutput.split(/\r?\n/) : [];
  if (commits.some((commit) => !isOid(commit)) || commits.length > 10000) fail(`invalid or oversized ledger history for ${label}`);
  if (!commits.length || commits[commits.length - 1] !== oid) commits.push(oid);
  let introduced = false;
  let previous = null;
  let introduction = null;
  for (const commit of commits) {
    const text = blobAt(repo, commit, LEDGER_PATH);
    if (text == null) {
      if (introduced) fail(`${label} ledger was deleted after introduction at ${commit}`);
      continue;
    }
    const { map } = parseLedgerText(text, `${label} ledger at ${commit}`);
    if (!introduced) {
      introduced = true;
      introduction = commit;
      const bootstrap = multisetFromFindings(scanTreeAtCommit(repo, BOOTSTRAP_COMMIT));
      if (!sameMultiset(map, bootstrap)) fail(`${label} first ledger at ${commit} does not exactly match pinned bootstrap inventory`);
    } else {
      if (!subset(map, previous)) fail(`${label} ledger grew or reversed a cleanup at ${commit}: ${describeDelta(map, previous)}`);
    }
    const actual = multisetFromFindings(scanTreeAtCommit(repo, commit));
    if (!sameMultiset(actual, map)) fail(`${label} committed source scan differs from its ledger at ${commit}`);
    previous = map;
  }
  return { introduced, introduction, latest: previous, commits: allCommits };
}

function validateOrigin(repo) {
  const url = String(git(repo, ["remote", "get-url", "origin"])).trim();
  const canonical = (candidate) => {
    const normalized = candidate.replace(/\.git$/, "").replace(/\/$/, "");
    return /^(?:https:\/\/github\.com\/|git@github\.com:|ssh:\/\/git@github\.com\/)(?:szTheory\/scrypath)$/i.test(normalized);
  };
  if (canonical(url)) return { url, localMirror: false };
  fail(`origin repository identity is not szTheory/scrypath: ${url}`);
}

function validateBranch(repo, branch) {
  if (typeof branch !== "string" || !branch || branch.length > 200 || branch.startsWith("-") || /[\0\r\n]/.test(branch)) fail(`invalid event branch: ${String(branch)}`);
  const checked = maybeGit(repo, ["check-ref-format", "--branch", branch]);
  if (checked == null) fail(`invalid event branch: ${branch}`);
  return branch;
}

function requireCommit(repo, oid, label) {
  if (!isOid(oid) || /^0{40}$/.test(oid)) fail(`${label} must be a nonzero full 40-character commit id`);
  if (maybeGit(repo, ["cat-file", "-e", `${oid}^{commit}`]) == null) fail(`${label} commit is unavailable: ${oid}`);
  return oid.toLowerCase();
}

function fetchRef(repo, remote, sourceRef, targetRef) {
  if (!/^refs\/(?:heads|pull)\/[A-Za-z0-9._/-]+$/.test(sourceRef) || !/^refs\/scrypath-ui-policy\/[A-Za-z0-9._/-]+$/.test(targetRef)) fail("refused invalid policy fetch ref");
  git(repo, ["fetch", "--no-tags", "--force", remote, `+${sourceRef}:${targetRef}`]);
  const oid = String(git(repo, ["rev-parse", "--verify", targetRef])).trim();
  if (!isOid(oid)) fail(`fetched ref did not resolve to a full commit: ${targetRef}`);
  return oid.toLowerCase();
}

function eventFromEnvironment(env) {
  const eventName = env.GITHUB_EVENT_NAME;
  if (!eventName) return { kind: "local" };
  let payload = {};
  if (env.GITHUB_EVENT_PATH) {
    try { payload = JSON.parse(fs.readFileSync(env.GITHUB_EVENT_PATH, "utf8")); }
    catch { fail("GitHub event payload is missing or invalid JSON"); }
  }
  return { kind: eventName, payload, env };
}

function resolveTrustedComparison(repo, suppliedEvent = eventFromEnvironment(process.env), internalTestFixture = null) {
  const shallow = String(git(repo, ["rev-parse", "--is-shallow-repository"])).trim() === "true";
  if (shallow) fail("shallow history cannot establish the UI literal ceiling; run `git fetch --unshallow origin` and retry");
  // Tests may inject a local Git remote through the module API. The executable
  // never supplies this parameter and exposes no corresponding CLI option.
  const fixtureRemote = internalTestFixture?.trustedRemote;
  const remote = fixtureRemote
    ? (path.isAbsolute(fixtureRemote) ? { url: fixtureRemote, localMirror: true } : fail("test fixture remote must be an absolute local repository path"))
    : validateOrigin(repo);
  const event = suppliedEvent || { kind: "local" };
  const kind = event.kind || "local";
  const payload = event.payload || {};
  const env = event.env || {};
  if (env.GITHUB_REPOSITORY && env.GITHUB_REPOSITORY.toLowerCase() !== "sztheory/scrypath") {
    fail(`event repository is not szTheory/scrypath: ${env.GITHUB_REPOSITORY}`);
  }
  let candidateOid;
  let targetOid;
  let beforeOid = null;
  let candidateRef = null;
  const additionalComparisons = [];

  const fetchMain = () => fetchRef(repo, remote.url, "refs/heads/main", "refs/scrypath-ui-policy/target");
  if (kind === "local") {
    candidateOid = String(git(repo, ["rev-parse", "--verify", "HEAD"])).trim().toLowerCase();
    const main = fetchMain();
    targetOid = main === candidateOid ? commitParents(repo, candidateOid)[0] : main;
    if (!targetOid) fail("local candidate equals main but has no first parent for comparison");
  } else if (kind === "pull_request" || kind === "pull_request_target") {
    const base = payload.pull_request?.base;
    const repoName = base?.repo?.full_name;
    if (repoName !== "szTheory/scrypath") fail(`pull request base repository is not szTheory/scrypath: ${String(repoName)}`);
    const branch = validateBranch(repo, base.ref);
    const number = payload.pull_request?.number;
    if (!Number.isSafeInteger(number) || number < 1) fail("pull request number is missing or invalid");
    const head = payload.pull_request?.head?.sha;
    if (!isOid(head)) fail("pull request head SHA must be a full 40-character commit id");
    const fetchedHead = fetchRef(repo, remote.url, `refs/pull/${number}/head`, "refs/scrypath-ui-policy/candidate");
    if (fetchedHead !== head.toLowerCase()) fail(`fetched pull request head ${fetchedHead} differs from event head ${head}`);
    candidateOid = fetchedHead;
    targetOid = fetchRef(repo, remote.url, `refs/heads/${branch}`, "refs/scrypath-ui-policy/target");
    candidateRef = `refs/pull/${number}/head`;
  } else if (kind === "push") {
    candidateOid = payload.after || env.GITHUB_SHA;
    beforeOid = payload.before || env.GITHUB_EVENT_BEFORE;
    if (!isOid(candidateOid) || /^0{40}$/.test(candidateOid)) fail("push after SHA must be a nonzero full 40-character commit id");
    if (!isOid(beforeOid) || /^0{40}$/.test(beforeOid)) fail("push before SHA is zero, deleted, or invalid; a deleted branch cannot reset the UI literal ceiling");
    candidateOid = candidateOid.toLowerCase();
    beforeOid = beforeOid.toLowerCase();
    requireCommit(repo, candidateOid, "push after SHA");
    requireCommit(repo, beforeOid, "push before SHA");
    const branchRef = env.GITHUB_REF || "";
    if (branchRef === "refs/heads/main") {
      fetchMain();
      const ancestry = maybeGit(repo, ["merge-base", "--is-ancestor", beforeOid, candidateOid]);
      if (ancestry == null) fail(`main push before SHA ${beforeOid} is not an ancestor of ${candidateOid}`);
      targetOid = beforeOid;
    } else {
      targetOid = fetchMain();
      const ancestry = maybeGit(repo, ["merge-base", "--is-ancestor", beforeOid, candidateOid]);
      if (ancestry == null) fail(`push before SHA ${beforeOid} is not an ancestor of ${candidateOid}`);
    }
  } else if (kind === "schedule") {
    candidateOid = env.GITHUB_SHA;
    if (!isOid(candidateOid)) fail("scheduled workflow SHA must be a full commit id");
    candidateOid = candidateOid.toLowerCase();
    const main = fetchMain();
    if (env.GITHUB_REF !== "refs/heads/main") fail("scheduled workflow candidate is not on refs/heads/main");
    requireCommit(repo, candidateOid, "scheduled workflow SHA");
    const ancestry = maybeGit(repo, ["merge-base", "--is-ancestor", candidateOid, main]);
    if (ancestry == null) fail(`scheduled candidate ${candidateOid} is not on fetched main ${main}`);
    targetOid = commitParents(repo, candidateOid)[0];
    if (!targetOid) fail("scheduled candidate has no first parent for comparison");
    if (main !== candidateOid) additionalComparisons.push(main);
  } else if (kind === "workflow_dispatch") {
    candidateOid = env.GITHUB_SHA;
    if (!isOid(candidateOid)) fail("manual workflow SHA must be a full commit id");
    candidateOid = candidateOid.toLowerCase();
    requireCommit(repo, candidateOid, "manual workflow SHA");
    const main = fetchMain();
    const ref = env.GITHUB_REF || "";
    if (ref === "refs/heads/main") {
      targetOid = commitParents(repo, candidateOid)[0];
      if (!targetOid) fail("main dispatch candidate has no first parent for comparison");
      if (main !== candidateOid) additionalComparisons.push(main);
    } else targetOid = main;
  } else {
    fail(`unsupported GitHub event for UI literal policy: ${kind}`);
  }
  if (!isOid(candidateOid) || !isOid(targetOid)) fail("resolved candidate or target is not a full commit id");
  const candidateExists = maybeGit(repo, ["cat-file", "-e", `${candidateOid}^{commit}`]);
  if (candidateExists == null) fail(`candidate commit is unavailable: ${candidateOid}`);
  const targetExists = maybeGit(repo, ["cat-file", "-e", `${targetOid}^{commit}`]);
  if (targetExists == null) fail(`trusted target commit is unavailable: ${targetOid}`);
  const comparisons = new Set([targetOid, ...additionalComparisons]);
  return { kind, candidateOid, candidateRef, targetOid, beforeOid, comparisons: [...comparisons], policyVersion: POLICY_VERSION };
}

function verifyHistory(repo, suppliedEvent = eventFromEnvironment(process.env), internalTestFixture = null) {
  const resolution = resolveTrustedComparison(repo, suppliedEvent, internalTestFixture);
  const candidateHistory = verifyLedgerHistory(repo, resolution.candidateOid, "candidate first-parent");
  if (!candidateHistory.introduced || !candidateHistory.latest) fail(`candidate history has no committed ledger introduction: ${resolution.candidateOid}`);
  const candidateLedgerText = blobAt(repo, resolution.candidateOid, LEDGER_PATH);
  if (candidateLedgerText == null) fail(`candidate ledger is missing at ${resolution.candidateOid}`);
  const candidateLedger = parseLedgerText(candidateLedgerText, `candidate ledger ${resolution.candidateOid}`).map;
  if (!sameMultiset(candidateLedger, candidateHistory.latest)) fail("candidate ledger differs from its committed first-parent history");

  if (resolution.kind === "local") {
    const workingLedger = ledgerFromRoot(repo).map;
    const workingFindings = multisetFromFindings(scanTree(repo));
    if (!sameMultiset(workingFindings, workingLedger)) {
      fail(`working-tree source scan differs from its ledger: ${describeDelta(workingFindings, workingLedger) || describeDelta(workingLedger, workingFindings)}`);
    }
    if (!subset(workingLedger, candidateHistory.latest)) fail(`working-tree ledger is not a reduction of committed candidate history: ${describeDelta(workingLedger, candidateHistory.latest)}`);
  }

  const targetMaps = [];
  for (const targetOid of resolution.comparisons) {
    const targetHistory = verifyLedgerHistory(repo, targetOid, `trusted target ${targetOid}`);
    if (targetHistory.introduced && targetHistory.latest) targetMaps.push(targetHistory.latest);
    else targetMaps.push(multisetFromFindings(scanTreeAtCommit(repo, BOOTSTRAP_COMMIT)));
  }
  for (const targetMap of targetMaps) {
    if (!subset(candidateLedger, targetMap)) fail(`candidate ledger exceeds independent trusted target ${resolution.targetOid}: ${describeDelta(candidateLedger, targetMap)}`);
  }
  return { ...resolution, introduction: candidateHistory.introduction, findingCount: [...candidateLedger.values()].reduce((sum, value) => sum + value, 0) };
}

function diagnostic(error) {
  const detail = error && error.message ? error.message : String(error);
  return `UI literal policy: FAIL\n${detail}\n`;
}

function main(argv = process.argv.slice(2)) {
  if (argv.length !== 0) {
    process.stderr.write("UI literal policy: FAIL\nThis command accepts no arguments; the comparison authority is resolved from the repository and trusted event context.\n");
    return 2;
  }
  try {
    const repo = String(git(process.cwd(), ["rev-parse", "--show-toplevel"])).trim();
    const result = verifyHistory(repo);
    process.stdout.write(`UI literal policy: PASS\nPolicy version: ${result.policyVersion}\nCandidate: ${result.candidateOid}\nTrusted target: ${result.targetOid}\nTrusted comparisons: ${result.comparisons.join(",")}\nBefore: ${result.beforeOid || "not applicable"}\nBootstrap ledger introduction: ${result.introduction}\nFinding occurrences: ${result.findingCount}\n`);
    return 0;
  } catch (error) {
    process.stderr.write(diagnostic(error));
    return 1;
  }
}

if (require.main === module) process.exitCode = main();

module.exports = { scanTree, resolveTrustedComparison, verifyHistory };
