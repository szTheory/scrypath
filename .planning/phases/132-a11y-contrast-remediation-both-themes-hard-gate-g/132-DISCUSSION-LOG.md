# Phase 132: A11y contrast remediation — both themes (hard gate) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 132-a11y-contrast-remediation-both-themes-hard-gate-g
**Areas discussed:** Primary-violet AA fix, Muted-text re-tune approach, 132 vs 135 header-nav boundary, AAA-body gate posture
**Mode:** advisor (`minimal_decisive` tier, technical owner) — locked codebase-grounded per Phase 128–131 precedent, no external web research.

---

## ① Primary-violet AA fix

| Option | Description | Selected |
|--------|-------------|----------|
| Scoped strong variant | Add `--color-primary-strong` (~#5b4ad1) used only as bg of text-bearing interactive surfaces; brand #6c5ce7 untouched for decorative/accent uses | ✓ |
| Darken `--color-primary` globally | Change light `--color-primary` #6c5ce7 → darker; shifts every violet fill/border/ring/wash in light | |

**User's choice:** Scoped strong variant (recommended)
**Notes:** Light-only failure (cream-on-violet 4.3:1); dark `#5b4ad1` already passes. Surgical fix preserves brand violet during a brand-perfection milestone.

---

## ② Muted-text re-tune approach

| Option | Description | Selected |
|--------|-------------|----------|
| Named muted-floor token | AA-verified `--ops-text-muted` (themed); route all muted recipes to it; record floors in DESIGN-TOKENS.md | ✓ |
| Per-recipe alpha bumps | Raise each class's color-mix % in place (55% → ~70%) | |

**User's choice:** Named muted-floor token (recommended)
**Notes:** Matches Phase 130 named-elevation-token precedent; makes AA floor enforceable + documented. Second tier allowed only if one tier can't serve every site at AA.

---

## ③ 132 vs 135 header-nav boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Clean seam: 132=text, 135=chrome | 132 fixes AA text-contrast math (/60 muted text + violet); 135 (SHELL-DARK-01) handles chrome/depth | ✓ |
| Fold all header-nav into 132 | 132 takes full header-nav treatment now; overlaps 135's locked scope | |

**User's choice:** Clean seam (recommended)
**Notes:** A11Y-TOKEN-01 explicitly lists "header nav /60" → 132 owns the alpha/text-contrast; 135 owns the visual recipe.

---

## ④ AAA-body gate posture

| Option | Description | Selected |
|--------|-------------|----------|
| Advisory report, AA-only gate | Hard gate stays AA (harness default `gate=aa_fail`); report + attach base-content AAA status for DUALVERIFY-01 | ✓ |
| Hard-gate body AAA | Block phase close unless body text ≥7:1 | |

**User's choice:** Advisory report, AA-only gate (recommended)
**Notes:** Harness already treats AAA as advisory. Hard-gating risks over-darkening body text / fighting the brand palette. AAA stays a target feeding the Phase 136 milestone report.

## Claude's Discretion

- Exact final token values/alphas (WCAG-math to clear 4.5:1 on each real surface), the precise `--color-primary-strong` value, one-tier-vs-two for muted — all codebase-grounded by planner/executor.

## Deferred Ideas

- Header-nav chrome/depth, palette/flash ambient-shadow recipe, `.ops-shell` wash dark-tune → Phase 135 (SHELL-DARK-01).
- Hard-gating body-text AAA → not adopted; re-evaluable at DUALVERIFY-01 if desired.
