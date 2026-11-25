---
phase: 195
review: 195-REVIEW.md
recorded: 2026-11-21
---

# Phase 195 review dispositions

One row per finding in [195-REVIEW.md](195-REVIEW.md) (0 critical, 3 warning, 6 info). Status is `fixed`, `accepted` (kept on purpose, reason given) or `handed off` (recorded for the maintainer, not fixed here).

| Finding | Status | What happened |
|---------|--------|---------------|
| WR-01 catalog flag read with untracked `get_env` | fixed | `optional_catalog_routes.ex` now reads the flag with `Application.compile_env(__CALLER__, ...)`; a changed value aborts the compile loudly instead of keeping a stale router. The root AST test accepts only the tracked read and has a fourth planted mutant for the old shape. Docker images were never exposed (they compile fresh). The standalone Ops entrypoint script exported `PHX_SERVER=false` for its ecto steps and would have tripped the new check, so it now exports `PHX_SERVER=true` once. Commits `1ed5e402`, `f72af5f5`. |
| WR-02 `[data-phx-error]` check can never fire | accepted | The server never emits that attribute (recorded in the 195-02 SUMMARY and GO-NO-GO). The real failure signals are the crash, empty-output and unknown-variation plants, each pinned by cause. The check stays as a cheap guard for a future LiveView version that does emit it; the criterion wording in ROADMAP and REQUIREMENTS is left as the maintainer adopted it. Revisit if the check is ever cited as evidence. |
| WR-03 bundle freshness test greps hook names only | handed off | A digest of the bundle inputs plus a single rebuild alias is more machinery than the risk earns today (the bundle rebuilds byte-identically now). Trigger to act: a hook change in `app.js` lands without a `storybook.js` rebuild, or the bundle gets a third consumer. |
| IN-01 malformed planted shell mutant | fixed | Mutant 1 is well-formed shell and every mutant runs through `bash -n`. Commit `a979b0d1`. |
| IN-02 tarball refutes guard directories that do not exist | accepted | Positive control (`lib` and `mix.exs` present) is recorded in the plan; the refutes are cheap insurance for a future `files:` change. |
| IN-03 dev-tool `storybook.js` ships in prod and test static trees | handed off | Inert, but nothing asserts it absent from the prod static tree. Revisit with the Phase 197 preview work. |
| IN-04 dev `live_reload` does not watch stories | handed off | Developer convenience for Phase 197 story authoring. |
| IN-05 `/storybook` 404 probes not in the script's completion marker | handed off | The hosted lane printed the 404 lines; the marker is a completeness aid only. |
| IN-06 hook-parity test subtracts `colocatedHooks` | handed off | A future colocated hook would be missed silently; revisit if one is added. |
