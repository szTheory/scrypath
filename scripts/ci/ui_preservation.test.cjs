"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const preservation = fs.existsSync(path.join(__dirname, "ui_preservation.cjs"))
  ? require("./ui_preservation.cjs")
  : {};

test("disposable provenance rejects retained project, port, and volume even when disposable mode is selected", () => {
  const manifest = {
    mode: "disposable",
    source: { sha: "a".repeat(40), tree_sha256: "source-tree" },
    runtime: {
      compose_project: "scrypath_ecommerce",
      host_ports: ["127.0.0.1:4002->4002/tcp"],
      volumes: ["scrypath_ecommerce_postgres_data"],
      source_sha: "a".repeat(40),
      source_tree_sha256: "source-tree",
    },
  };
  const expected = {
    retained_project: "scrypath_ecommerce",
    retained_port: 4002,
    retained_volumes: ["scrypath_ecommerce_postgres_data"],
    source_sha: "a".repeat(40),
    source_tree_sha256: "source-tree",
  };
  const errors = typeof preservation.disposableProvenanceErrors === "function"
    ? preservation.disposableProvenanceErrors(manifest, expected)
    : [];

  assert.ok(errors.some((error) => error.includes("retained project")), "retained project must be rejected");
  assert.ok(errors.some((error) => error.includes("retained port")), "retained port must be rejected");
  assert.ok(errors.some((error) => error.includes("retained volume")), "retained volume must be rejected");
});
