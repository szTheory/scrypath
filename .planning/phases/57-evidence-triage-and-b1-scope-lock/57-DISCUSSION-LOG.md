# Phase 57: Evidence triage and B1 scope lock - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`57-CONTEXT.md`**.

**Date:** 2026-04-21  
**Phase:** 57 — Evidence triage and B1 scope lock  
**Areas discussed:** EVID-01 artifact shape; LIB-01..03 triage; Core merge gate; B1 freeze recording  
**Mode:** `[--all]` — all gray areas selected; research synthesized from parallel subagent reports plus maintainer goals (**Scrypath** vision: Ecto-native search, evidence-led B1, honest ops boundary).

---

## 1. EVID-01 artifact shape and row IDs

| Option | Description | Selected |
|--------|-------------|----------|
| Single in-repo Markdown table (`.planning/`) | One SSOT file; diff-friendly; works offline | ✓ |
| Multi-file per row | Lower merge contention; higher structure cost | |
| GitHub issues as canonical | Great discussion; vendor lock; weak “frozen” semantics | |
| Hybrid (repo ledger + links) | Repo contract + issue threads as context only | ✓ (combined with single table) |

**User's choice:** Hybrid with **single canonical** **`.planning/EVID-01-b1-v1.14.md`**; IDs **`EVID-57-NN`**; append-only after freeze.  
**Notes:** Cross-ecosystem footguns avoided: no wiki-as-truth, no GitHub `#` as primary key. Elixir OSS norm: link planning from **CONTRIBUTING** + light **PR template** checkboxes.

---

## 2. LIB-01..03 triage rules

| Option | Description | Selected |
|--------|-------------|----------|
| Strict all-or-nothing | All three LIB must ship if any evidence | |
| Independent triage + Cut/Defer | Each LIB mapped, cut, or defer-with-target | ✓ |
| Flexible exceptions | “Small fixes” without rows | |

**User's choice:** **Independent** mapping; **Cut** vs **Defer** defined in **CONTEXT**; single-owner lock with async window.  
**Notes:** Aligns with SemVer + planning honesty; avoids evidence laundering across rows.

---

## 3. Core merge gate (definition + enforcement)

| Option | Description | Selected |
|--------|-------------|----------|
| Entire monorepo is “core” | Simple; over-blocks ops | |
| Hex lib + contract tests + template for normative docs | Semver truth + LIB doc paths | ✓ |
| CI regex only | Brittle without culture | Defer optional automation |

**User's choice:** **Core paths** = **`lib/scrypath/`** + **`test/scrypath/`**; **LIB doc/contract** PRs also cite **EVID** when touching **`guides/`**, **README**, **CONTRIBUTING**, **`docs_contract_test`**. **`scrypath_ops/`** excluded by default. **PR template + CODEOWNERS** first; CI token gate optional later.  
**Notes:** Rust **publish=false** / Go **`internal/`** analogy: ops = app/cmd tree; Hex tree = published contract.

---

## 4. Where “B1 frozen” is recorded

| Option | Description | Selected |
|--------|-------------|----------|
| STATE only | High churn; weak audit | Partial (mirror only) |
| REQUIREMENTS + evidence file | Milestone-auditable SSOT | ✓ |
| CHANGELOG as freeze record | Wrong layer pre-release | |

**User's choice:** **SSOT** = **REQUIREMENTS.md** (**EVID-01**) + **`.planning/EVID-01-b1-v1.14.md`**; **STATE** one-liner mirror; **ROADMAP** by reference only.  
**Notes:** Reduces split-brain vs duplicating full freeze text in three files.

---

## Claude's Discretion

- Exact **PR template** wording and optional **`paths-filter` CI** job naming left to implementation; **CONTEXT** names the token pattern and deferral of hard CI to if-needed.

## Deferred ideas (from research)

- Maintainer-only **skip** label for emergencies if CI gate is added later.  
- **`.github/core-paths.txt`** manifest if the workspace grows beyond one Hex package.
