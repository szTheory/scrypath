# Phase 42: Per-query tuning pipeline spec - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in **42-CONTEXT.md** — this log preserves alternatives considered.

**Date:** 2026-04-20
**Phase:** 42 — Per-query tuning pipeline spec
**Areas discussed:** Spec placement & discoverability; Precedence & option layering; Meilisearch mapping scope; Errors, telemetry & doc contracts

**Method:** User requested **all** gray areas in one shot with **parallel generalPurpose subagent research**, then principal-agent synthesis into a single coherent recommendation set.

---

## Spec placement & discoverability

| Option | Description | Selected |
|--------|-------------|----------|
| A | Single canonical **`guides/per-query-tuning-pipeline.md`** + README/golden path/overview/`mix.exs`/`@doc` pointers | ✓ |
| B | Split **`docs/`** (normative) + **`guides/`** (how-to) | |
| C | Giant **`@moduledoc`** as primary spec | |
| D | **`.planning/`**-only spec | |

**User's choice:** **A** — one published guide as normative home (extends Phase 41 single-source pattern; avoids Scout-style vagueness and Searchkick-style tribal knowledge).

**Notes:** ExDoc **`extras`** + Operations group; fixed H2 spine so the doc reads as both spec and manual.

---

## Precedence & option layering

| Option | Description | Selected |
|--------|-------------|----------|
| 1 | **Two-plane** declarative stack + search overlay (index truth + allowlisted per-query) | ✓ |
| 2 | Re-resolve schema settings on every search | |
| 3 | Strict allowlist (library keys) + documented escape hatch | ✓ (combined with 1) |
| 4 | Left-biased merge | |

**User's choice:** **1 + 3** — Plane A vs Plane B; right-biased keyword merge aligned with **`Config.resolve!/1`** and **`MultiSearch.Entries`**; shallow-default nested merge with **`:deep` opt-in**; normalize-on-entry (Phase 19 continuity).

---

## Meilisearch mapping scope

| Option | Description | Selected |
|--------|-------------|----------|
| A | Minimal closed set for Phase 43 | ✓ (as implementation slice) |
| B | Full SearchQuery catalog | |
| C | Principle-based categories + exemplars + links to vendor docs | ✓ (framing) |

**User's choice:** **C + A** — categories + explicit IN-SCOPE/DEFER; first slice centers **threshold / ranking score visibility** and prerequisite matrix; defer vector/hybrid/personalization unless milestone expands.

---

## Errors, telemetry & doc contracts

| Option | Description | Selected |
|--------|-------------|----------|
| Prescriptive only | Lock all message strings | |
| Principles only | No stable tags | |
| Hybrid | Normative tags + event names + metadata keys; non-normative prose | ✓ |

**User's choice:** **Hybrid** — semver on **tags**, **telemetry names**, **documented metadata keys**; **`{:validation, String.t()}`** messages non-normative; doc tests follow Phase 41 hygiene + structural anchors.

---

## Claude's Discretion

- Filename / minor editorial ordering within the guide spine.

## Deferred ideas

- OpenAPI-generated param matrix automation.
- Optional `docs/` split if maintainer-only appendix is needed later.
