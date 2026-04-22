# Requirements: Scrypath

**Defined:** 2026-04-22  
**Milestone:** v1.13 — Public polish & narrative coherence  
**Core value:** (from **`.planning/PROJECT.md`**) Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## Scope decisions (this milestone)

- **Hex publish:** **Not required** for **v1.13** — **Hex `scrypath 0.3.4`** is already the latest published line; this arc is narrative + doc polish unless a semver-worthy code change lands and follows **`docs/releasing.md`** separately.
- **OPSUI “second slice”** (**OPSUI-FUT-*** saved playbooks / vendor panels): **Out of scope** — remains in **`milestones/v1.10-REQUIREMENTS.md`** § v2+ until promoted.

## v1.13 requirements

### Documentation voice and contracts

- [x] **POLISH-01**: Adopter-facing **`guides/`** contain no internal planning phase identifiers (e.g. “Phase 43”); **`guides/per-query-tuning-pipeline.md`** describes behavior in API / guide / release language.
- [x] **POLISH-05**: **`guides/common-mistakes.md`** retains **≥3** grounded pitfalls (symptom, wrong model, fix, authority, evidence); new entries only when tied to shipped tests and an authority guide.

### Version and planning truth

- [x] **POLISH-02**: **`.planning/PROJECT.md`**, **`.planning/MILESTONES.md`**, and **`.planning/ROADMAP.md`** (where they state “current Hex” / latest line) align with **Hex `scrypath 0.3.4`** and root **`mix.exs`** **`@version`**; **README** points readers to Hex for “latest published” vs checkout **`mix.exs`**.

### Contributor entry

- [x] **POLISH-03**: **`AGENTS.md`** keeps project constraints for agents but replaces GSD slash-command lists as normative OSS onboarding with contributor-first pointers (**CONTRIBUTING**, **`.planning/`**).
- [x] **POLISH-04**: **`.planning/milestone-candidates.md`** reflects **v1.12** closure (**Tier A** done), **v1.13** theme, and next pulls (**B1** evidence-led QoL, **B2+** still deferred).

## Future requirements (evidence-backed QoL — not v1.13 unless promoted)

Track **Tier B1** candidates here; implement only when tied to a concrete issue, dogfood note, or contract gap.

| ID | Idea | Evidence hook |
| --- | --- | --- |
| **QOL-FUT-01** | Small API affordances or clearer errors from real adopter confusion | GitHub issue or reproducible thread |
| **QOL-FUT-02** | Additional **`guides/common-mistakes.md`** sections | Same: symptom + test anchor + authority guide |

## Out of scope (v1.13)

| Item | Reason |
| --- | --- |
| **OPSUI-FUT-01 / OPSUI-FUT-02** | Operator product depth; defer until milestone explicitly owns OPSUI expansion |
| **Real Meilisearch in `scrypath_ops` CI**, **Playwright / E2E default gates** | Heavy CI; adopt only after a proven miss from stubs + contracts |
| **GSD SDK `milestone.complete` / phases archive automation** | Maintainer tooling; see **`.planning/RETROSPECTIVE.md`** — does not block library polish |
| **Public multi-backend**, **vectors / hybrid / personalization** | **PROJECT.md** *Out of Scope* until adoption pressure |

## Traceability

| Requirement | Phase | Status |
| --- | --- | --- |
| POLISH-01 | Phase 54 | Complete |
| POLISH-05 | Phase 54 | Complete |
| POLISH-02 | Phase 55 | Complete |
| POLISH-03 | Phase 56 | Complete |
| POLISH-04 | Phase 56 | Complete |

**Coverage:** v1.13 requirements: **5** total · Mapped: **5** · Unmapped: **0**

## Historical traceability (Nyquist invariants)

Doc-contract tests require these rows to remain present (carry-forward from **Phase 32** / **gap closure 33**):

| Requirement | Phase | Status |
| --- | --- | --- |
| AUDT-01 | Phase 32; gap closure 33 | **Complete** |

---
*Requirements defined: 2026-04-22 for milestone **v1.13***  
*Last updated: 2026-04-22 — phases **54–56** delivered in-repo*
