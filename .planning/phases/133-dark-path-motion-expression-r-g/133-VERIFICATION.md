---
phase: 133-dark-path-motion-expression-r-g
verified: 2026-06-24T00:00:00Z
status: human_needed
score: 4/6 must-haves verified
behavior_unverified: 2
overrides_applied: 0
behavior_unverified_items:
  - truth: "Honors v1.33 A3 precedent — no per-LiveView-patch re-firing reveals on result lists (SC2)"
    test: "Boot the seeded ops server (compose dev lane → :4002, current source) and run `npx playwright test e2e/admin_path_motion.spec.ts`. Drive Search single↔multi toggle and Playbook A→B selection."
    expected: "runningKeyframeAnimationCount stays 0 on .ops-path-trace and .ops-object-item-active across each push_patch; no opacity flash on the merge-trace region. (Structurally guaranteed — all .ops-path-* motion is pure CSS `transition`, zero `@keyframes` — but the patch-refire probe is the runtime proof.)"
    why_human: "A re-fire is a runtime DOM-patch behavior. Source inspection proves no @keyframes exist in the path-motion rules (necessary), but only the booted patch-refire probe exercises the actual LiveView re-render path (sufficient). No server was reachable during verification."
  - truth: "Reads deliberate/infrastructural in dark, does not regress light; reduced-motion + functional integrity confirmed via Playwright (SC3)"
    test: "With the seeded server booted, run admin_path_motion.spec.ts (7 tests: recommended card ×3 themes, merge-trace ×2, playbooks ×2) and review the 9 targeted screenshots in test-results/admin-path-motion/."
    expected: "All 7 tests green; under reducedMotion:'reduce' each anchor computes ≤0.02ms duration AND its active end state stays visible; screenshots read deliberate in dark and show no light regression."
    why_human: "Reduced-motion neutralization end-to-end and the subjective 'deliberate in dark / no light regression' read are runtime + visual properties. The CSS global reduced-motion rule and dark-only glow tokens are correct by inspection, but the Playwright proof and screenshot review require a booted server and human eyes."
human_verification:
  - test: "Boot seeded ops server (compose dev lane → :4002, current source) and run `cd examples/scrypath_ecommerce && npx playwright test e2e/admin_path_motion.spec.ts --reporter=line`."
    expected: "7 passed (recommended card light/dark/system-dark; search merge-trace light/dark; playbooks light/dark). Reduced-motion ≤0.02ms + active state visible; patch-refire count 0; evidence code blocks shimmer-off (count 0)."
    why_human: "Spec source is verified substantive and well-wired, but no server was reachable during verification — executor reported 7/7 green, which is a claim, not evidence the verifier observed."
  - test: "Review the 9 targeted screenshots in examples/scrypath_ecommerce/test-results/admin-path-motion/ (recommended card, merge-trace hover, active playbook A/B; dark + light + system-dark)."
    expected: "Path motion reads deliberate/infrastructural in dark; light surfaces are unchanged (no spurious glow — light glow tokens are `none`)."
    why_human: "Subjective visual read of the design intent ('deliberate, restrained, infrastructural') cannot be verified programmatically."
---

# Phase 133: Dark Path Motion Expression Verification Report

**Phase Goal:** Add the brand's directional path motion where it serves a JTBD (line-draw/reveal, active-path tracing, node pulse, code-block shimmer-on-hover), tuned for dark and restrained, via the existing motion tokens.
**Verified:** 2026-06-24
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | New motion is transform/opacity (+box-shadow glow) only, <300ms, no bounce | ✓ VERIFIED | `.ops-path-*` rules at app.css:1236-1303 use only `transform`/`opacity`/`box-shadow` end states; all durations are `var(--duration-ops-fast)` (≤240ms); no `cubic-bezier`/spring. Behaviorally enforced by `MotionContractTest` (3 tests, **green** — ran during verification) |
| 2 | Motion neutralized under `prefers-reduced-motion` | ✓ VERIFIED | Global rule app.css:1388-1396 snaps `transition-duration`/`animation-duration` to 0.01ms across `*, *::before, *::after`; all path motion lives on transitions/pseudo-elements covered by it. (Runtime end-to-end proof is the Playwright reduced-motion probe — see SC3.) |
| 3 | Tokenized (<300ms via existing `--duration-ops-*`), dual-dark-path glow | ✓ VERIFIED | `MotionContractTest` test 2 (token, no raw literal) + test 3 (dual-dark symmetry of `.ops-object-item-active` glow) **green**; dual paths at app.css:1495 + :1499 |
| 4 | `shimmer` opt-in, default OFF; evidence code blocks never shimmer | ✓ VERIFIED | `attr(:shimmer, :boolean, default: false)` ops_ui.ex:987; conditional class ops_ui.ex:1000; `grep shimmer search_live.ex` → none; spec asserts `.ops-code-block--shimmer` count 0 on results |
| 5 | Honors A3 precedent — no per-LiveView-patch re-firing reveals (SC2) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Zero `@keyframes`/`animation:` in any `.ops-path-*` rule (pure `transition`) — structurally cannot re-fire on patch. Runtime patch-refire probe exists in spec but could not be run (no server) — see Human Verification |
| 6 | Reads deliberate in dark, no light regression; reduced-motion + functional integrity confirmed via Playwright (SC3) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Spec source substantive (7 tests, real assertions); light glow tokens are `none` (no light regression by construction). Runtime Playwright proof + screenshot review require booted server — see Human Verification |

**Score:** 4/6 truths verified (2 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `scrypath_ops/assets/css/app.css` | `.ops-path-*` vocabulary | ✓ VERIFIED | `.ops-path-trace`/`::after` line-draw, `.ops-path-node[--copper]` glow, `.ops-code-block--shimmer` glint; tokens only; dual-dark active-item glow (1236-1303, 1495-1502) |
| `scrypath_ops/lib/.../components/ops_ui.ex` | `shimmer` attr | ✓ VERIFIED | `attr(:shimmer, :boolean, default: false)` :987; conditional `.ops-code-block--shimmer` :1000 |
| `scrypath_ops/assets/css/DESIGN-TOKENS.md` | Phase 133 vocab docs | ✓ VERIFIED | §283-320: class/token table, anchor surface, A3 restraint boundaries, extended Animate/Never table |
| `scrypath_ops/test/.../motion_contract_test.exs` | Static CSS contract | ✓ VERIFIED | 3 tests **green**; WR-01 fix applied (1.17-compatible `Enum.filter \|> MapSet.new`) |
| `examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts` | Focused Playwright proof | ⚠️ ORPHANED-RUNTIME | Source verified substantive (7 parameterized tests, real reduced-motion + patch-refire + shimmer-off assertions); not executed by verifier (no server) |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| search_live.ex | app.css | `class="ops-path-trace"` on merge-trace disclosure | ✓ WIRED | Two occurrences at search_live.ex:1021,1037 |
| playbook_live.ex | app.css | `.ops-object-item-active` → dual-dark glow | ✓ WIRED | Glow keyed off persistent server-state class (app.css:1495/1499); no new attr |
| control_room_live.ex | app.css | `.ops-intent-card--recommended` glow | ✓ WIRED | Recommended card glow predates Phase 133 (Phase 130 dark composition); no new rule needed |
| motion_contract_test.exs | app.css | `File.read!` + regex over `.ops-path-*` | ✓ WIRED | Contract reads and scans the live CSS; green |
| admin_path_motion.spec.ts | helpers/e2e.ts | imports `waitForLiveConnected`/`seedScenario` | ✓ WIRED | Imports present; every flow gated on live-connected + seeded |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Motion contract enforces discipline | `mix test motion_contract_test.exs` | 3 tests, 0 failures | ✓ PASS |
| Component compiles warnings-as-errors | `mix compile --warnings-as-errors` | clean | ✓ PASS |
| Playwright path-motion proof | `npx playwright test admin_path_motion.spec.ts` | no server reachable (:4002 → 000) | ? SKIP (→ human) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| DARKMOTION-01 | 133-01, 133-02, 133-03 | Restrained path-expression motion via existing tokens, transform/opacity only, reduced-motion-safe, dark-tuned, honors A3 no-re-fire | ✓ SATISFIED (static layer) / ⚠️ runtime pending | CSS + contract test green; runtime patch-refire + reduced-motion proof routes to human. REQUIREMENTS.md:98,103 marks Complete; single declared ID, fully accounted for across all 3 plans — no orphans |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| (none) | — | No TBD/FIXME/XXX in Phase 133 files; no stubs; no unwired data | — | Clean |

Pre-existing debt (NOT a Phase 133 regression): 4 `OpsShellContractTest` failures asserting the old `src="/ops/images/logo.svg"` — confirmed via test run to be the v1.35 brand inline-SVG header swap (commit fcb8fc7). None of Phase 133's 4 files touch the header/logo/layouts. Logged in deferred-items.md. Per phase context, not counted against the goal.

### Human Verification Required

1. **Run the Playwright path-motion proof** — boot the seeded ops server (compose dev lane → :4002, current source) and run `npx playwright test e2e/admin_path_motion.spec.ts`. Expect 7 passed; reduced-motion ≤0.02ms + active state visible; patch-refire count 0; evidence shimmer-off. (Spec source verified substantive; executor reported 7/7 green — a claim the verifier could not observe without a server.)
2. **Review the 9 targeted screenshots** in `test-results/admin-path-motion/` — confirm the motion reads deliberate/infrastructural in dark and light surfaces show no regression (light glow tokens are `none`).

### Gaps Summary

No blocking gaps. All static-verifiable must-haves PASS: the `.ops-path-*` vocabulary is transform/opacity/box-shadow-only, tokenized <300ms, dual-dark-pathed, reduced-motion-covered by the global rule, and the `shimmer` opt-in defaults off with evidence blocks never shimmering — all confirmed by reading the actual CSS/component and by the green `MotionContractTest`. The A3 no-re-fire property is structurally guaranteed (zero `@keyframes` in any path-motion rule; pure CSS transition).

Two truths (SC2 patch-refire, SC3 reduced-motion + dark-read) are behavior-dependent runtime invariants whose end-to-end proof is the `admin_path_motion.spec.ts` Playwright suite. That spec is verified substantive and well-wired, but no ops server was reachable during verification, so the runtime proof and screenshot review route to human verification. Status is `human_needed` (not `gaps_found`): the implementation is present, correct, and wired; only runtime observation remains.

The WR-01 review finding (1.18-only `MapSet.filter/2`) and IN-01 (unused `SeedScenario` import) were both fixed in commit 01d74a6, confirmed in the source.

---

_Verified: 2026-06-24_
_Verifier: Claude (gsd-verifier)_
