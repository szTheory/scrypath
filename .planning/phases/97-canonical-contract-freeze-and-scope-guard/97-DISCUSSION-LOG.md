# Phase 97: Canonical Contract Freeze and Scope Guard - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `97-CONTEXT.md`; this log preserves alternatives considered.

**Date:** 2026-05-27
**Phase:** 97-canonical-contract-freeze-and-scope-guard
**Areas discussed:** canonical wording authority, install/version truth wording, scope guard enforcement, traceability freeze format

---

## Canonical Wording Source-of-Truth

| Option | Description | Selected |
|--------|-------------|----------|
| Single canonical support guide authority | `guides/support-and-compatibility.md` owns normative adopter contract text; other surfaces reference anchors | ✓ |
| Planning-first authority | Planning artifacts own wording and docs mirror it | |
| Machine-readable manifest source | Canonical yaml/json drives generated snippets | |
| Split contract/support authority docs | Separate contract page plus support guide | |

**User direction captured:** discuss all areas and provide one coherent recommendation set using deep research and ecosystem lessons.
**Outcome:** selected single canonical support-guide authority with planning files as governance authority, not adopter-facing wording authority.

---

## Install/Version Truth Wording

| Option | Description | Selected |
|--------|-------------|----------|
| Repeat full install snippet across all surfaces | Every surface contains full version snippet | |
| Single-source authority with references | Support guide owns policy text; other docs link | |
| Dual-track release-vs-main policy plus authority discipline | Release-backed default guidance + explicit `main` unreleased caveat + exact version/ref evidence requirements | ✓ |
| Generic “install latest” wording | Avoid explicit version snippets | |

**Notable evidence:** existing drift (`~> 0.3` vs `~> 1.0`) across surfaces.
**Outcome:** selected dual-track policy with support-guide authority to minimize adopter confusion and preserve release truth.

---

## Scope Guard / Non-goal Enforcement

| Option | Description | Selected |
|--------|-------------|----------|
| Narrative-only scope guard | General prose warning only | |
| Explicit banned-capability list | Enumerated non-goals and rationale | |
| Requirement-tagged scope table | Requirement IDs with must-not/allowed-change boundaries | ✓ |
| Must-not matrix wired to verify checks | Full test/gate coupling in this phase | |

**Tradeoff chosen:** adopt requirement-tagged table now (phase 97), wire drift checks in phase 99 (not full brittle enforcement immediately).
**Outcome:** selected explicit capability-class non-goals plus evidence-gated reopening rule.

---

## Traceability Freeze Format

| Option | Description | Selected |
|--------|-------------|----------|
| Roadmap-only table | Keep mapping only in roadmap | |
| Requirements x surface matrix | Requirement-to-surface mapping table | |
| Contract statement IDs + verify anchors | Canonical statement IDs mapped to surfaces/tests | |
| Hybrid ledger (requirements x statements x surfaces x verify) | Single freeze ledger with requirement IDs, statement IDs, surface anchors, and planned checks | ✓ |

**Outcome:** selected hybrid ledger model to support phase 98 reconciliation and phase 99 gate automation with manageable contributor overhead.

---

## Ecosystem Synthesis Applied

- Elixir/Phoenix/Ecto idiom: concise README, guide authority for depth, explicit operational semantics, least-surprise contracts.
- Cross-ecosystem positive patterns: Searchkick/Scout onboarding clarity, explicit proof modes, release-backed trust signals.
- Cross-ecosystem footguns avoided: duplicated policy prose, ambiguous `main` vs release truth, over-broad abstraction promises, brittle prose snapshot enforcement.

## Claude's Discretion Used

- Selected coherent recommendations across all areas without additional interactive round-trips, based on explicit user instruction for one-shot decisions.
- Kept recommendations bounded to phase 97 contract hardening and deferred runtime/product breadth discussion.

## Deferred Ideas

- Generated contract manifest automation (possible future hardening, not required in phase 97).
- Any runtime feature-breadth expansion requests remain deferred under SCOPE-01 evidence gate.

