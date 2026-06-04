# Phase 121 Plan: Design-system tightening — tokens

**Status:** Complete
**Requirements:** TOKEN-01

## Tasks

- Add `--ease-ops-exit` (crisp ease-in dismissal curve) to `app.css` `@theme`; document in `DESIGN-TOKENS.md`. Define only — wiring onto dismissals is Phase 123.
- Complete the status-tone set so `info`/`partial`/`running` are supported wherever `success`/`warning`/`error`/`neutral` are — especially `metric_tone_class/1`; add token-backed `.ops-metric-{info,partial,running}` classes and widen the `ops_metric` / `ops_intent_card` `kind` enums.
- Fix the raw Tailwind-step leaks flagged in the backlog (route to `-ops-` tokens): skip-link (drop `ring-2`), theme toggle (drop `brightness-200` magic), data-card / empty-state / upload-box / checkbox / modal raw steps, `.ops-object-item` CSS padding.
- `ops-preflight` 1→4-col jump: add an `sm:` 2-col intermediate (4-col only at `lg`).
- Confirm the shadow ladder (`shadow-ops-mid`) is used correctly — verify, no change.
- Keep `DESIGN-TOKENS.md` in lockstep with every `@theme` change.

## Verification

- `mix verify.opsui` green (129 tests / 0 failures baseline).
- ScrypathOps LiveView suite green.
- `examples/scrypath_ecommerce` compiles `--warnings-as-errors`.
- Re-screenshot the 40-shot matrix; confirm no regressions.

## Hard constraints

- Presentation/semantics only — no behavior change (mirrors v1.32 Phase 117).
- CSS architecture fixed: Tailwind v4 `@theme` + daisyUI + `.ops-*`. No `tailwind.config.js`, no BEM.
- Do NOT do the Triage/Probes→Recover/Explore rename (Phase 124). No motion wiring beyond defining the token (Phase 123).
