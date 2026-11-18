---
phase: 180-oban-worker-telemetry
review: 180-REVIEW.md
updated: 2026-10-25
---

# Phase 180 — Code Review Disposition

Review: 0 critical, 5 warning, 8 info. Fix report: 180-REVIEW-FIX.md (161c92f5). Post-fix gate re-run by the orchestrator: `mix test --exclude integration` 1000/0, docs_contract 74/0, compile `--warnings-as-errors`, format, `credo --strict`, `docs --warnings-as-errors` all clean.

| Finding | Severity | Disposition | Evidence |
|---------|----------|-------------|----------|
| WR-01 | warning | fixed | f4044779 — worker span `index` is `job.index`, not a recomputed `index_name/2`; regression fixture backend that ignores `:index_name` (fails on old code). |
| WR-02 | warning | fixed (docs) | d177d945, eb58d9bc — final-attempt recipe covers worker `:stop` (outcome != :ok) and `:exception` at `attempt == max_attempts`, backed by `[:oban, :job, :exception]` `state: :discard` (verified against Oban 2.23 telemetry; `:exhausted` is internal only). |
| WR-03 | warning | fixed (docs) | 2514305d — boundedness claim scoped to worker spans; unbounded keys named; `schema` no longer recommended as a tag (FailedWork moduledoc). |
| WR-04 | warning | fixed | a488287a — `upserted_count` is the distinct written-id count on loaded and legacy paths; duplicate-row regression test (fails on old code). |
| WR-05 | warning | fixed (docs) | 5e091f48 — decode/config failures emit no Scrypath event; count Oban `[:oban, :job, :stop]` `state: :cancelled`; `failed_work.observed` documented as per-call, not a counter. |
| IN-01 | info | fixed (docs) | 4d208c1a — `cancel_reason` removed from the delete row; `:cancel` documented as upsert-only. Contract test green. |
| IN-02 | info | fixed | 495fcbd0 — guide says distinct ids; related resolve span uses distinct count; new test. |
| IN-03 | info | fixed | b02d0d75 — shared `Telemetry.job_start_metadata/5` replaces duplicated `start_metadata/3`. |
| IN-04 | info | fixed | 7a2b9e0d — derived `@event_count - 1`. |
| IN-05 | info | fixed (docs) | b24fc8e5 — guide states only the three worker rows are key-checked; extending key checks to the other 14 events is out of D-17 scope. |
| IN-06 | info | accepted | Intended effect of D-18 (no response body in the cancel reason). 401/403/408/429 still classify `:transport`; other 4xx related cancels classify `:unknown`. No pinning test (needs a related-job row through `failed_sync_work/2`). |
| IN-07 | info | fixed (docs) | 5c5a30e8 — `:noop`-ratio and `verify_skipped` alert-fatigue bullets restored in the SRE doc. |
| IN-08 | info | fixed | e92d425f — `TelemetryCapture` documents its global handler and `async: false` requirement. |
