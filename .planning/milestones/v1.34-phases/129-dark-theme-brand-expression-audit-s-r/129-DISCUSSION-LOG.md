# Phase 129: Dark-theme brand-expression audit - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 129-dark-theme-brand-expression-audit
**Areas discussed:** Scoring dimension model, Substrate strategy, Ranking & severity model, Phase-routing column

> Calibration: technical owner, opinionated → `minimal_decisive`. Recommendations were
> grounded in in-repo artifacts (`120-AUDIT-BACKLOG.md` precedent + pre-seeded
> `128-CONTRAST-REPORT.md` + brand book), not external research, since those fully determine
> the audit methodology. All four areas locked to the recommended option in one pass.

---

## Scoring dimension model

| Option | Description | Selected |
|--------|-------------|----------|
| Fresh DD1–DD6 set, 0–3 | 6 dark-specific dimensions 1:1 with the brand rules (ramp, ratio, glow, ambient depth, path-glow restraint, AA); DD6 fed from 128; 0–3 scale like 120 | ✓ |
| Reuse 120's D1–D7 + dark lens | Keep 120's 7-dimension rubric, fold dark nuance into D5-brand | |

**User's choice:** Fresh DD1–DD6 set, 0–3
**Notes:** DARKAUDIT-01 enumerates exactly these six dark dimensions; a fresh DD-set keeps per-dimension dark scoring legible instead of collapsing into one D5 column. DD6 stays objective by reusing the 128 report.

---

## Substrate strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Promote 128 + brand overlay, both viewports incl. desktop | Promote 128's AA findings (→ DD6, scope/fix_class pre-seeded) as the objective spine; overlay DD1–DD5 from the 40 screenshots; read desktop too (AA passes but flatness visible) | ✓ |
| Fresh independent re-walk | Re-enumerate every dark surface from scratch, ignoring 128's pre-tagging | |

**User's choice:** Promote 128 + brand overlay, both viewports/desktop
**Notes:** 128 was explicitly built and pre-seeded to be promoted here. Brand-fidelity gaps are primarily a desktop visual concern, so a mobile-only walk (where the AA fails clustered) would miss most DD1–DD5 findings.

---

## Ranking & severity model

| Option | Description | Selected |
|--------|-------------|----------|
| AA-fail=blocker; brand by blast-radius; 120 buckets | AA-fail → auto-blocker; brand gaps systemic(≥3)=structural / single=polish; sort by severity→scope→score→dimension; #1B2230 lands #1 by construction | ✓ |
| Single combined 0–10 blast-radius score | Fuse AA + brand + reach into one number, rank by that | |

**User's choice:** AA-fail=blocker; brand by blast-radius; 120 buckets
**Notes:** Mirrors the 120 format the requirement mandates; objective AA drives blocker status while subjective brand scoring is ranked by reach, not a fragile combined number.

---

## Phase-routing column

| Option | Description | Selected |
|--------|-------------|----------|
| Both: Phase (130–135) + Req tag | Each finding carries a target Phase column AND a requirement tag (DARKTOKEN/GLOW/COPPER/A11Y-TOKEN/DARKMOTION/SCREEN-DARK); map already in REQUIREMENTS.md §13 | ✓ |
| Phase column only (like 120) | Just a Phase column mapping findings → 130–135 | |

**User's choice:** Both: Phase (130–135) + Req tag
**Notes:** The dual field makes the backlog genuinely "the single source for 130–135" — a planner can filter by either Phase or Req. The req→phase map already exists in REQUIREMENTS.md §13; honor 128's pre-mapped cluster routing as the starting point.

---

## Claude's Discretion

- Exact finding IDs/numbering scheme, the precise per-touchpoint enumeration list, the wording of `Proposed fix` cells, and whether to add a "Plan-hypothesis check" section like 120 did — left to the researcher/planner, provided the locked dimensions, scoring scale, ranking rule, routing fields, and finding-#1 anchor hold.

## Deferred Ideas

- Any actual fix (dark surface-2 ramp token, glow/copper recipes, AA remediation, motion, per-screen polish) — downstream phases 130–135.
- AAA-body remediation — milestone advisory target; phase-132 concern.
- Light-theme brand polish — v1.34 focus is dark; light near-misses tracked in 128, fixed in 132.
