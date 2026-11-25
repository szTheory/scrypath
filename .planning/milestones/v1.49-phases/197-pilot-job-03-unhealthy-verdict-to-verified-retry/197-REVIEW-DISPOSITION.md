---
phase: 197
review: 197-REVIEW.md
recorded: 2026-11-22
---

# Phase 197 review dispositions

One row per finding in [197-REVIEW.md](197-REVIEW.md) (0 critical, 4 warning, 9 info). Status is `fixed`, `accepted` (kept on purpose, reason given) or `handed off` (recorded for the maintainer, not fixed here).

| Finding | Status | What happened |
|---------|--------|---------------|
| WR-01 serve task calls a stale or foreign catalog "ours" | fixed | `port_verdict/4` returns `:ours` only when the page's checkout and HEAD equal this checkout's; "unknown" on either side never matches; AGENTS.md "Port collision" corrected. Stale-HEAD, foreign-worktree and unknown plants each assert their cause text. Commit `48e887fe`. Uncommitted edits made after a catalog started are not detected (stated in the moduledoc and AGENTS.md). |
| WR-02 the served catalog endpoint is never tested | fixed | `catalog_endpoint_test.exs` dispatches through the real `ScrypathOps.Catalog.Endpoint` and router with `server: false`: landing, redirect, iframe story (also connected), static assets and font, only `/storybook/*` routes, `/ops` and `/admin` answer 404, no database query. Three planted regressions each fail it. Commit `8829e3c2`. |
| WR-03 "Mounted" provenance proof is the scenario id as a substring | handed off | Known limit of the plan's rule (the D3 variations use `Claim:` literals). Trigger to act: a variation's claim and its backing test drift apart, or the catalog grows past about 60 variations; then require a `Claim:` literal for every variation. |
| WR-04 seam tests rebuild the stories' data instead of loading a variation | handed off | One shared builder that both stories and seam tests call would remove the copy; `FailedSyncLive.load_schema/2` and the stories already differ on a plain list. Fold into Phase 198 if it runs, or the first phase that adds a story. |
| IN-01 `return_to_path/1` checks control characters only in the path | handed off | Raw CR/LF in the query passes through; the value is encoded when used. Tighten with the next change to `on_mount.ex`. |
| IN-02 `HtmlCanon` normalizes only `ops-time-N` counter ids | handed off | `ops_section` and `ops_empty_hero` also generate counter ids; parity runs were stable without it. |
| IN-03 catalog endpoint `check_origin: false`, committed dev keys, welcome page prints the checkout path | accepted | Loopback-only, dev-only, never compiled into prod (pinned by the boundary tests); the path is the point of the freshness check. |
| IN-04 `:not_checked` collapses to `:unavailable`; `schema_name` is `"nil"` with no schema | handed off | No reachable state shows it today. |
| IN-05 story helpers pasted into about seven stories | handed off | Another copy-paste is cheaper than a shared module until a third kind of story needs it (AGENTS.md house rule). |
| IN-06 JS preflight does not slice `--short=12` shas as Elixir does | handed off | Both sides compare full values in practice. |
| IN-07 welcome page hard-codes the frozen date beside a dynamic marker | handed off | Cosmetic. |
| IN-08 Search health row ages now fall back to the page snapshot instant, not the live clock | accepted | Intended "no clock in components" rule; a source with a time has a ref, so the fallback rarely fires. Recorded here as a deliberate behavior change the frozen-clock parity run could not see. |
| IN-09 selftest asserts inside an HTTP callback | handed off | Move the assertion after `checkStorybook` returns when the selftest is next touched. |
| Verifier: Failed-row error text key order depended on atom-table order | fixed | `Failures.inspect_stable/1` sorts map keys; the usual text is byte-identical; a unit test with a control fails on plain `inspect/1`. Commit `deec9a82`. |

Not run locally for the fix commits: the Docker lane `ecommerce-mounted` (no Docker, boundary script, dependency or lock change in the diff; the hosted lane runs on the exact head) and the full root `core` and `repository-contracts` suites (the root tests that read AGENTS.md and the ops tree ran: 176 tests, 0 failures).
