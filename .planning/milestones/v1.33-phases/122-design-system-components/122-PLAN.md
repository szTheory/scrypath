# Phase 122 Plan: Design-system tightening — components

**Status:** Complete
**Requirements:** COMP-01

## Tasks

- `ops_code_block` raw `rounded-md` / padding / surface → `-ops-` tokens.
- Consolidate `ops_notice` / `ops_status` near-duplicate tinted-surface internals into one shared partial (CSS class) so tone/padding/radius can't drift; keep both public component APIs identical.
- Add a restrained `ops_loading` skeleton/pulse primitive (opacity pulse, reduced-motion-safe). Define + make available; screen wiring is 125/126.
- Hover/press parity: give `ops_result_row` / `ops_object_item` the same `:hover`/`:active` vocabulary buttons/cards already have (transform/opacity only, subtle; static state styling, motion timing is 123).
- Sentence-case the shared empty-state copy in `ops_config_empty` ("No Schemas Configured"→"No schemas configured", "Runtime Not Configured"→"Runtime not configured"). Per-screen copy sweeps are 124's COPY-01.
- `ops_table` scroll affordance for dense tables; `ops-preflight` tablet step (delivered in 121).

## Verification

- `mix verify.opsui` green.
- ScrypathOps LiveView suite green.
- `examples/scrypath_ecommerce` compiles `--warnings-as-errors`.
- Re-screenshot the 40-shot matrix; confirm no regressions + fixes landed.

## Hard constraints

- Presentation/semantics only — no behavior change (mirrors v1.32 Phase 117).
- CSS architecture fixed: Tailwind v4 `@theme` + daisyUI + `.ops-*`.
- Do NOT do the Triage/Probes→Recover/Explore rename (124). No motion beyond static state styling (123).
