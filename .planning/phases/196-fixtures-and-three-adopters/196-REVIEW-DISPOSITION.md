---
phase: 196
review: 196-REVIEW.md
recorded: 2026-11-22
---

# Phase 196 review dispositions

One row per finding in [196-REVIEW.md](196-REVIEW.md) (0 critical, 9 warning, 5 info). Status is `fixed`, `accepted` (kept on purpose, reason given) or `handed off` (recorded for the maintainer, not fixed here).

| Finding | Status | What happened |
|---------|--------|---------------|
| WR-01 purity lint covered 8 tokens | fixed | `Check.impure_tokens/0` lists 33 documented tokens (wall clock, waiting, datetime literals, random and per-call values, operating system, file system, repository), each with a plant; false positives are kept out of recordings, the README and comments. Commit `bdb27063`. |
| WR-02 Trojan Source lint missed U+061C, U+2060-2064, U+180E | fixed | `Check.format_codepoints/0` adds them (and a few more invisible controls), written as code points; each class has a plant. Commit `bdb27063`. |
| WR-03 no Oban job shape or coherence invariant | fixed | New `:job_shape`, `:job_state_coherence` (six named rules) and `:job_time_order` invariants, each rule with its own cause-pinned plant. The older retryable and discarded plants were themselves impossible and were rebuilt. Commit `ee3dc87c`. |
| WR-04 Shopadelic task uids out of time order, no uid invariant | fixed | New `:task_uid_unique` and `:task_uid_order` invariants; the Shopadelic history was re-spaced so uid order matches enqueue order. Commit `3d553d1d`. |
| WR-05 a task with no `indexUid` raised in `Check.run` | fixed | Reported as `{:task_keys, uid}` with a plant and an explicit no-raise test. Commit `3d553d1d`. |
| WR-06 two path-guard plants could not fail their guard | fixed | Plants now resolve without their guard and are asserted rejected with it, with a positive control. Commit `053b718c`. |
| WR-07 prod image still carries `/app/fixtures/scrypath_fixtures` sources | handed off | Inert: the verify script proves the project is not compiled, not in the dependency list and not loadable in prod. Removing the sources from the prod `COPY` needs Docker-lane iterations (the lane failed four times locally on a shared VM). Trigger to act: the prod image is ever published, or a fixtures file starts to hold anything sensitive. |
| WR-08 `COPY` of the fixtures manifest in `runtime_prod` is unnecessary | handed off | Reproduced as unnecessary; pinned by a contract test. Bundled with WR-07: change both together under one Docker-lane run. |
| WR-09 `record.sh` deleted JSON in any directory before Docker started | fixed | Records into a staging directory, touches the output directory only after success, and refuses any directory other than a `meilisearch-v*` directory beside the script or a new or empty temp directory. Commit `ff68e4c0`. |
| IN-01 fake Oban inspector models schema scoping only (real one filters by queue, caps at 100) | handed off | Fidelity note for Phase 197: a screen that shows the 195-job deep queue through the real inspector would be capped. Check before the story claims the count. |
| IN-02 determinism test compares whole-page text through regexes | accepted | It compares two renders of the same page for time-only differences; the selector-based tests cover structure. Revisit if it becomes brittle. |
| IN-03 several functions have no callers | handed off | `states/0` (three adopters), `Meili.types/0`, `Meili.statuses/0`, `ObanJob.states/0`, `Bulk.max_rows/0`: Phase 197 stories are the expected callers; prune at Phase 197 close if still unused. |
| IN-04 `Meili.stamp/2` assumes a UTC `DateTime` | handed off | Builders only pass UTC values today. |
| IN-05 Shopadelic `settingsUpdate` echoes a hand-typed attribute list | handed off | Derive from `AppliedSettings` when the next adopter state touches it. |
