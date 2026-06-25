# Deferred Items — Phase 133

Out-of-scope discoveries logged during execution (not caused by Phase 133 changes).

## Pre-existing OpsShellContractTest failures (logo.svg → inline SVG drift)

- **Discovered during:** Plan 01 verification (`mix verify.opsui`).
- **Symptom:** 4 failures in `test/scrypath_ops_web/ops_shell_contract_test.exs` asserting
  `assert html =~ ~s(src="/ops/images/logo.svg")` on `/ops`, `/ops/posture`, `/ops/sync-drift`,
  and one more shell route.
- **Root cause:** the v1.35 brand-adoption commit `fcb8fc7` ("v1.35 brand system & scry/path
  logo + adoption") replaced the `<img src="/ops/images/logo.svg">` header mark with an **inline
  `<svg>` brand mark** in `layouts.ex` (line ~157), but did not update this shell-contract test.
  The test still expects the old `<img src>` path.
- **Why deferred / out of scope:** Phase 133's 4 changed files are `app.css`, `DESIGN-TOKENS.md`,
  `ops_ui.ex` (shimmer attr), and `search_live.ex` (merge-trace class) — none touch the header,
  logo, or layouts. Per the executor Scope Boundary, only issues directly caused by the current
  task's changes are auto-fixed. These failures pre-date Phase 133.
- **Suggested owner:** a v1.35 brand-test follow-up (or the next ops-shell-touching phase) should
  update the contract assertion to match the inline-SVG brand mark.
- **Note:** the v1.35 milestone was built directly (not through GSD plan/execute), so its phase
  dirs/SUMMARYs don't exist on disk; this test drift is part of that known bookkeeping gap.
