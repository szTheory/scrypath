---
phase: 176-search-and-playbooks
reviewed: 2026-10-11T22:26:43Z
reviewed_sha: 3cc55bd
depth: standard
files_reviewed: 18
files_reviewed_list:
  - examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts
  - scrypath_ops/assets/css/app.css
  - scrypath_ops/assets/js/ops_hooks.js
  - scrypath_ops/lib/scrypath_ops/playbook/runner.ex
  - scrypath_ops/lib/scrypath_ops/playbook/store.ex
  - scrypath_ops/lib/scrypath_ops/playbook/v1.ex
  - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
  - scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
  - scrypath_ops/priv/static/assets/css/app.css
  - scrypath_ops/priv/static/assets/js/app.js
  - scrypath_ops/test/scrypath_ops/playbook/runner_test.exs
  - scrypath_ops/test/scrypath_ops/playbook/store_test.exs
  - scrypath_ops/test/scrypath_ops/playbook/v1_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs
  - scrypath_ops/test/support/ops_schemas.ex
  - scrypath_ops/test/support/search_playground_stub_adapter.ex
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 176: Code Review Report

**Reviewed:** 2026-10-11T22:26:43Z  
**Reviewed SHA:** `3cc55bd`  
**Depth:** standard  
**Files Reviewed:** 18  
**Status:** clean

## Summary

Re-reviewed the exact committed Phase 176 source at `3cc55bd`, including Store root validation, temporary replacement creation and cleanup, overwrite replacement, rename locking, and the LiveView unsupported-filesystem message. The temporary disclosure race is resolved: the sibling directory is chmodded to `0700` before the replacement inode is created or written, and the complete file is closed and assigned its final mode before it is renamed into the workspace root. A retained descriptor to the initially empty directory does not grant access to later entries after its mode is restricted. No current findings remain. Exact-SHA orchestrator validation passed: the focused Store/Search/Playbooks suite completed with 75 tests and 0 failures, and `mix verify.ops_ui` completed with 2 doctests and 301 tests, all passing. My standalone `mix test test/scrypath_ops/playbook/store_test.exs` attempt did not reach tests because the project alias failed with `The task "scrypath_ops.check_nav_contract" could not be found`.

## Resolved Findings

- **CR-01 — Nested hit fields can crash Search rendering: RESOLVED.** Hit values use bounded formatting; Search tests cover nested values.
- **CR-02 — Concurrent Search captures can overwrite a playbook: RESOLVED.** Search capture uses Store exclusive creation; concurrent creation is covered by tests.
- **CR-03 — Static hard links bypass the workspace boundary: RESOLVED.** Path and descriptor metadata require one link; tests cover read, save, list, delete, and rename. Saves replace the old inode.
- **CR-04 — Concurrent renames can overwrite an existing playbook: RESOLVED.** Destination creation is no-replace, and same-source operations are serialized with `:global.trans/2`.
- **CR-05 — A symlinked or swapped workspace ancestor bypasses the boundary: RESOLVED within the documented trust model.** A symlink root is rejected, static ancestor symlinks are resolved, and writable directory chains are checked. The module documents that the root and parent still must be controlled by the service account against same-account or privileged races.
- **WR-01 — Fractional ranking thresholds are dropped: RESOLVED.** V1 validation and capture serialization preserve non-negative numeric thresholds; the runner passes fractional values through.
- **WR-02 — Malformed LiveView event values can crash the socket process: RESOLVED.** Event text values are normalized and malformed paste input is rejected.
- **WR-03 — Unsupported hard-link errors show a generic rename failure: RESOLVED.** `:eperm` joins the unsupported-filesystem mapping and PlaybookLive presents the duplicate-then-delete workaround.
- **WR-04 — A concurrent hard-link addition can make a successful rename disappear: RESOLVED within the documented trust model.** Same-source Store renames are serialized, and rename checks the expected two-link intermediate state before deleting the source.
- **WR-05 — Saving a restricted playbook widens its final permissions: RESOLVED.** Source mode bits are applied to the replacement inode, and the test verifies a saved `0600` file remains `0600`.
- **WR-06 — Rename error paths leave an untracked hard link: RESOLVED.** Mismatch and source-removal failure branches now clean up the destination link by its observed identity.
- **WR-07 — The writable-root check accepts a sticky writable workspace root: RESOLVED.** The chain now identifies the configured root by its final index, and a `01777` root test verifies rejection.
- **CR-06 — A local reader can open the temporary file before its initial mode is restricted: RESOLVED.** The replacement is now created inside a unique sibling directory that is changed to `0700` before the file is created; data is written, closed, and chmodded before the rename exposes it at the workspace root.

## Narrative Findings (AI reviewer)

No current findings.

---

_Reviewed: 2026-10-11T22:26:43Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
