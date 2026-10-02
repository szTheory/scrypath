---
phase: 170
phase_name: "documentation-and-readiness-closeout"
project: "Scrypath"
generated: "2026-10-01"
counts:
  decisions: 2
  lessons: 3
  patterns: 2
  surprises: 2
missing_artifacts:
  - "170-UAT.md"
---

# Phase 170 Learnings: documentation-and-readiness-closeout

## Decisions

### Keep evidence collection separate from readiness judgment
The validator may establish that supplied inputs are structurally and factually valid, but it does not assign any of the six semantic condition judgments or approve publication.

**Rationale:** The actual maintainer owns semantic judgments and the exact durable record; automation must preserve that boundary.
**Source:** 170-06-SUMMARY.md; 170-08-PLAN.md

---

### Freeze a finite, clean-main-based source snapshot
Build the evidence ref from refreshed public `main`, transport an explicit planning-file allowlist, keep final byte digests in an external manifest, and stop tracked writes after the freeze.

**Rationale:** This keeps unrelated local history out of the public evidence ref and prevents later bookkeeping from changing the attested source.
**Source:** 170-07-PLAN.md; 170-CLOSEOUT.md

---

## Lessons

### Derive the snapshot from the validator's full dependency closure
The initial plan-based inventory did not include every validator input. Comparing the validator's required historical inputs against refreshed public `main` exposed additional Phase 168/169 records that had to be transported.

**Context:** Before freezing, enumerate every validator `tracked_inputs` and `preserved_history` path, then compare each path and expected source against the refreshed public base. Do not infer completeness from plan `files_modified` lists alone.
**Source:** 170-07-SUMMARY.md; 170-CLOSEOUT.md

---

### Scan the complete exact candidate before making history immutable
Current files can be clean while byte-pinned history still contains machine-specific path references. Decide whether to preserve or redact those references before publishing; if redacting, update the source bytes and all affected history pins before the final digest and hosted run.

**Context:** The full snapshot scan found three such references in two pinned files after unpinned files had already been normalized. The maintainer chose redaction and refreshed pins before publication.
**Source:** 170-07-SUMMARY.md; 170-CLOSEOUT.md

---

### A source anchor can make preserved history independently resolvable
When a historical pin points to an unavailable source commit and required files are absent from public `main`, create a clean-main-rooted anchor containing only the exact allowlisted history files and point the pins to that reachable source.

**Context:** This preserves the pinned-byte contract while making the history available to hosted validation without importing unrelated local history.
**Source:** 170-07-SUMMARY.md; 170-CLOSEOUT.md

---

## Patterns

### Readiness closeout preflight
Before push or hosted attestation: refresh the public base; compute the union of plan outputs and validator dependency closure; compare all required inputs against that base; scan the exact full candidate for local paths and other private values; resolve any history redaction and rebuild pins; verify every pin resolves; then compute digests, transport the finite snapshot, and compare bytes plus non-planning tree parity.

**When to use:** Any evidence branch that publishes planning records, preserves byte-pinned history, or relies on a validator's transitive tracked inputs.
**Source:** 170-07-PLAN.md; 170-07-SUMMARY.md; 170-CLOSEOUT.md

---

### Keep evidence identities and limits explicit
Record required exact-source CI, path-scoped skips, prior full E2E runs, local package checks, published package state, and release gates as distinct facts. Reuse prior evidence only after a relevant-path comparison and state the scope it supports.

**When to use:** Reconciling release, package, integration, or readiness evidence across multiple commits and environments.
**Source:** 170-06-SUMMARY.md; 170-VERIFICATION.md

---

## Surprises

### Worktree isolation fell back to sequential execution
The execution workflow could not resolve `origin/HEAD` and degraded to sequential execution on the maintainer checkout.

**Impact:** The final evidence ref had to be established independently from explicitly refreshed public `main`; the maintainer checkout's history could not be treated as the delivery base.
**Source:** 170-07-SUMMARY.md

---

### The preserved-history source was unavailable from GitHub
The original history source commit was not fetchable from GitHub, and several validator-required files were absent from public `main`.

**Impact:** The evidence snapshot needed an allowlist-only source anchor and a larger dependency-closed inventory before hosted validation could resolve all pins.
**Source:** 170-07-SUMMARY.md; 170-CLOSEOUT.md
