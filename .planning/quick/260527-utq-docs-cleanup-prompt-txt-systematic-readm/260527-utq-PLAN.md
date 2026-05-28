---
quick_id: 260527-utq
status: complete
created: 2026-05-28
---

# Quick Task 260527-utq: Reader-Facing Docs Cleanup

## Goal

Systematically sanity-check README, HexDocs source extras, website routing copy, and GitHub repository metadata from the perspective of Phoenix/Ecto adopters. Fix only low-hanging, evidence-backed documentation issues: broken or odd links, confusing route copy, internal development artifacts leaking into public docs, install/version/support wording drift, and obvious reader-flow papercuts.

## Tasks

1. [x] Audit reader-facing entrypoints.
   - Files: `README.md`, `guides/`, `docs/`, `website/src/`, `mix.exs`
   - Action: scan for GSD/milestone/phase leakage, stale release/support wording, broken local links, awkward microcopy, and docs organization problems.
   - Verify: record concrete findings before editing; leave planning/history artifacts alone unless they are exposed through HexDocs or README.
   - Done: prioritized low-risk fixes selected.

2. [x] Apply low-risk docs cleanup.
   - Files: only source docs or website files with concrete findings.
   - Action: tighten copy/linking without widening product claims or rewriting mature docs for taste.
   - Verify: diff stays small and adopter-facing.
   - Done: no unexplained scope churn.

3. [x] Verify docs and site surfaces.
   - Files: generated docs/site checks only as needed.
   - Action: run docs build, website checks if website changes, and targeted link/artifact scans.
   - Verify: relevant commands pass or failures are explained.
   - Done: summary and STATE quick-task row written, then commit.
