---
phase: 121-design-system-tokens
verified: 2026-06-03
status: passed
score: 1/1 requirement verified (TOKEN-01)
note: "Verification ran across the combined 121+122 pass (owner-approved single pass); screenshot evidence shared with 122-VERIFICATION.md."
---

# Phase 121 Verification: Design-system tightening — tokens

**Phase Goal:** Land the systemic token fixes (exit easing, tone-map completeness, shadow ladder, raw-step leaks) so every screen inherits the dividend; `DESIGN-TOKENS.md` in lockstep.
**Status:** passed

## Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `--ease-ops-exit` defined in `@theme` + documented | ✓ | `app.css` `@theme` line + `DESIGN-TOKENS.md` motion table; `ease-ops-exit` emitted in compiled CSS. Not wired to any close animation (correct — that's Phase 123). |
| 2 | Status-tone set complete (info/partial/running supported wherever success/warning/error/neutral are) | ✓ | `metric_tone_class/1` now has info/partial/running clauses; `.ops-metric-{info,partial,running}` in compiled CSS; `ops_metric`/`ops_intent_card` enums widened to the full set. |
| 3 | Raw Tailwind-step leaks routed to `-ops-` tokens | ✓ | skip-link (ring-2 dropped), theme toggle (brightness-200 dropped), empty-state/upload-box/checkbox/data-card/modal/object-item all token-routed; new `focus:rounded-ops-control`, `p-ops-5`, `rounded-ops-sm`, `right-ops-3` etc. emit in CSS. |
| 4 | `ops-preflight` 1→4-col jump given an `sm:` 2-col step | ✓ | `@media (min-width:640px)` 2-col + `@media (min-width:1024px)` 4-col in CSS; sync-drift desktop shot shows the 4-col row; tablet now 2-col. |
| 5 | Shadow ladder (`shadow-ops-mid`) confirmed correct | ✓ | Used on segmented-selected; intent-card hover uses `shadow-ops-raised`. No change needed (matches backlog CONFIRMED-already-correct). |
| 6 | `DESIGN-TOKENS.md` in lockstep | ✓ | Exit-ease row + complete-tone-set note added in the same commit. |

**Score:** 1/1 requirement (TOKEN-01) satisfied.

## Behavioral Spot-Checks

| Behavior | Command | Result |
| --- | --- | --- |
| OPSUI contract gate | `mix verify.opsui` | 2 doctests, 129 tests, 0 failures ✓ |
| ScrypathOps LiveView suite | `cd scrypath_ops && mix test` | 2 doctests, 129 tests, 0 failures ✓ |
| Host compile | `examples/scrypath_ecommerce` `mix compile --warnings-as-errors` | clean ✓ |
| CSS build | `cd scrypath_ops && mix assets.build` | tailwind v4 + daisyUI build clean; new utilities + `.ops-metric-*` emit ✓ |

## Screenshot Evidence

Shared with `122-VERIFICATION.md` (combined pass): dev stack booted on :4002 against the seeded incident DB + live Meilisearch; 40-shot matrix re-captured into `/tmp/p122-screenshots`, filenames match the baseline 40 exactly, no layout/contrast regression in either theme. See `122-VERIFICATION.md` § Screenshot comparison.

## Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| TOKEN-01 | ✓ SATISFIED | Exit easing token + complete tone coverage + raw-step-leak removal + preflight step, `DESIGN-TOKENS.md` in lockstep, all gates green. |

## Gaps

None.

## Deferred (correctly out of Phase 121 scope)

- Wiring `--ease-ops-exit` onto modal/palette/flash close → Phase 123 (motion).
- Per-screen Title-Case copy (search/failed-sync inline empty-state strings) → Phase 124 (COPY-01).
