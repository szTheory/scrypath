# Phase 128: Contrast gate harness + dark seed coverage - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 128-contrast-gate-harness-dark-seed-coverage-s-g
**Areas discussed:** Matrix coverage shape, System-dark drive mechanism, Token-pair checker, Report/triage output

**Mode:** Advisor (USER-PROFILE present) · technical owner · `vendor_philosophy: opinionated` → `minimal_decisive`. Owner requested per-area parallel research (pros/cons/tradeoffs, ecosystem-idiomatic, DX, lessons from comparable libs/a11y gates, brand/design-system coherence) and a single coherent one-shot recommendation set.

---

## Matrix coverage shape

| Option | Description | Selected |
|--------|-------------|----------|
| A) Full cross-product | 6 screens × 3 scenarios × 3 modes (~54+ axe runs); max observability but degenerate combos + slow + flaky | |
| B) Curated mapping as-is | ~9 page-states × 3 modes (~27); fast, proven, but misses dark-risky states → under-coverage defeats the phase | |
| C) Hybrid (refined) | Curated 9 baseline + ~3–4 dark-risk states; 3 modes; both viewports | ✓ |

**User's choice:** C (Hybrid) — with an explicit override on viewport gating (see below).
**Notes:** axe contrast is viewport-sensitive (reflow flips violation↔incomplete); gate strictly on `violations[]`, never `incomplete`; scope axe to `withRules(['color-contrast'])`. Research recommended desktop=gate / mobile=advisory; **owner overrode to hard-gate AA on BOTH viewports** (max coverage), made safe by gating on `violations` only.

## System-dark drive mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| A) colorScheme:"dark" + skip phx:theme write | Exercises the real OS path; no runtime guard | |
| B) write phx:theme="dark" as "system" | REJECTED — re-tests explicit `[data-theme=dark]` path under a false name | |
| C) A + runtime invariants | colorScheme:"dark", skip phx:theme write, assert no `data-theme` + `prefers-color-scheme` matches + `data-theme-effective=dark` | ✓ |

**User's choice:** C (folded into the all-areas one-shot lock).
**Notes:** Confirmed in `app.css` a system-only `prefers-color-scheme` `select` chevron branch → distinct cascade, must be tested separately. No `system-light` row (redundant). Theme-mode modeled as a discriminated union so B can't be reintroduced.

## Token-pair checker

| Option | Description | Selected |
|--------|-------------|----------|
| A) Parse app.css (semantic pairs) + tiny muted-alpha manifest | Single source of truth for values; explicit intent for muted-over-surface cases | ✓ |
| B) Fully hand-maintained manifest | REJECTED — duplicates token values → the A11Y-TOKEN-01 drift footgun | |
| C) Auto-derive + auto-extract every color-mix | REJECTED — "which surface is this translucent token on" is unanswerable without a DOM | |

**User's choice:** A.
**Notes:** sRGB alpha composite (oklch mix is a no-op for opacity-only mixes; matches axe-core); hand-rolled ~30-line WCAG math, zero deps + golden test; roles→thresholds per pair; lockstep guards (token-count + untracked-muted-token grep). Lives in `examples/scrypath_ecommerce` Node lane; `make contrast` <1s, runs before the axe matrix.

## Report / triage output

| Option | Description | Selected |
|--------|-------------|----------|
| A) Console only | REJECTED as sole output — ephemeral; 129/132 can't consume | |
| B) Committed artifact only | Partial — commit curated summary, not raw run JSON | |
| C) Hybrid: console + canonical JSON (gitignored) + curated committed markdown | ✓ | ✓ |

**User's choice:** C.
**Notes:** One unified `scrypath.contrast.v1` schema both producers emit; gitignore `test-results/contrast/`, commit `128-CONTRAST-REPORT.md` into the phase dir (v1.33 `120-AUDIT-BACKLOG.md` precedent). `scope`/`fix_class` pre-seed phase 129. AAA-body via explicit `BODY_SELECTORS` allowlist, separate section, never gates. Exit non-zero iff `aa_fail>0`; write report before deciding exit; `$GITHUB_STEP_SUMMARY` + per-cluster annotations + upload-artifact.

## Claude's Discretion

- Exact slug/field naming within the agreed schema, the precise dark-risk supplement state list (within intent), and the internal structure of the `.mjs` checker.

## Deferred Ideas

- Promote/narrow mobile gate severity in future (owner hard-gated mobile now).
- A `system-light` row only if a future light-specific `prefers-color-scheme` rule is added.
- Actual contrast/token fixes (`#1B2230` ramp, muted alphas, glow/copper) — phases 130/132, not here.
