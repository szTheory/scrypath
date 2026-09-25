# Phase 133: Dark/path motion expression `[R] [G]` - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 133-Dark/path motion expression `[R] [G]`
**Areas discussed:** target boundary, primitive shape, code-block shimmer boundary, verification depth

---

## Target Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Route mark only | Honors DK-19 literally with minimal risk but under-delivers DARKMOTION-01 and creates little design-system dividend. | |
| Small opt-in JTBD anchor set | Applies path motion to stable operator-flow anchors such as route mark, Control Room recommended intent card, Search federation/merge trace, Playbook active item, and possibly breadcrumb/current path. | yes |
| Broad path motion across UI | Stronger brand visibility but too noisy for an incident/admin tool and expensive to verify. | |
| Future-diagram primitive only | Keeps current screens quiet but leaves Phase 133 mostly preparatory and weakly visible. | |

**User's choice:** Approved recommendation after subagent-backed research.
**Notes:** Path motion should serve operator flow and design-system reuse, not become generic animation.

---

## Motion Primitive Shape

| Option | Description | Selected |
|--------|-------------|----------|
| CSS-only opt-in classes/keyframes | Simple, tokenized, reduced-motion-friendly, but weaker semantic guardrails. | |
| HEEx component primitives | Idiomatic Phoenix DX where the DOM has reusable meaning, but risks over-componentizing polish. | |
| JS hooks / LiveView JS commands | Useful for lifecycle-gated motion, but too much patch/refire risk for a visual-only phase. | |
| CSS-first hybrid | CSS vocabulary by default, HEEx primitives only for reusable path/node structure, no new JS hooks unless unavoidable. | yes |

**User's choice:** Approved recommendation after subagent-backed research.
**Notes:** Preserve the Phase 123 precedent: CSS plus existing transition mechanisms, no behavior change, no decorative patch-triggered motion.

---

## Code-Block Shimmer Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Skip shimmer | Maximum trust/readability but leaves a named brand-book motion pattern unexpressed. | |
| Subtle hover overlay/border shimmer | Expresses brand as an inspectable-surface glint without moving payload text; explicit opt-in only. | yes |
| Animated text/background shimmer | Literal but damages evidence readability and likely violates transform/opacity constraints. | |
| Per-screen only | Lets non-critical preview surfaces opt in but needs a clear rulebook. | |

**User's choice:** Approved recommendation after subagent-backed research.
**Notes:** Shimmer must never be default on operational evidence panes, failed-sync reasons, raw result payloads, JSON/log text, or mount-time states.

---

## Verification Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal static proof | Cheap but insufficient for real motion and LiveView patch risk. | |
| Browser reduced-motion/hover interaction proof | Proves the actual interaction and reduced-motion behavior. | yes |
| Targeted screenshot matrix | Useful endpoint evidence for changed dark-first surfaces without duplicating Phase 136. | yes |
| Full 40-shot recapture | Strong broad proof but duplicates Phase 136 and does not prove transient motion well. | |
| Contrast/light pixel gates | Useful only when color-bearing shimmer/glow endpoints change. | conditional |

**User's choice:** Approved recommendation after subagent-backed research.
**Notes:** Lock a motion-specific proof bundle and defer full milestone verification/gallery to Phase 136.

---

## Agent Discretion

- Exact class names and HEEx primitive names.
- Exact count of anchors, as long as the final set remains small and JTBD-backed.
- Exact Playwright spec/helper organization.

## Deferred Ideas

- Full 40-shot recapture, before/after gallery, milestone audit, and human UAT remain Phase 136.
- Broad per-screen polish remains Phase 134.
- Shell chrome-wide polish remains Phase 135.
- Marketing/docs hero shimmer and richer public-site diagrams are outside this ScrypathOps phase.
