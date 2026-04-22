# Phase 59: Playbook schema and persistence MVP - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`59-CONTEXT.md`**.

**Date:** 2026-04-22  
**Phase:** 59 — Playbook schema and persistence MVP  
**Areas discussed:** Persistence fork (OPS-PB-03); Payload envelope & versioning (OPS-PB-01); Federation / `search_many` scope in v1; Documentation home for schema v1  

**Mode:** User selected **all** areas and requested **parallel subagent research** with autonomous synthesis into one coherent recommendation set (no per-area interactive Q&A).

---

## 1. Persistence fork (OPS-PB-03)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Portable export/import | JSON on disk; git/ticket sharing; no DB migrations | ✓ |
| B — Ecto + Postgres/SQLite | Shared list; migrations; CI DB services | |
| Hybrid “dir catalog” | Env-scanned playbook dir — still file-backed; compatible with A | ✓ (compatible extension) |

**User's choice:** Research synthesis + explicit user ask for export-first, least surprise, great DX.  
**Notes:** Subagent compared Slack/PR attachment workflows vs shared DB truth; flagged LFI on arbitrary paths, Postgres authz footguns, CI without DB. **Locked:** **D-01–D-05** in CONTEXT.

---

## 2. Payload envelope & versioning (OPS-PB-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Integer `playbook_format` | Simple breaking-bump story | ✓ |
| Semver string on document | Comparison / parsing pain | |
| Strict unknown-key rejection | Deterministic CI + operator errors | ✓ |
| Silent clamp page/entry count | Hides intent | |

**User's choice:** Synthesis — strict JSON, **`playbook_format: 1`**, **`mode`**, shapes per CONTEXT **D-06–D-12**.  
**Notes:** NimbleOptions vs Ecto embeds left to planner (**Claude's Discretion**).

---

## 3. Federation / `search_many` in v1

| Option | Description | Selected |
|--------|-------------|----------|
| Dispatch-input-only payload | Mirrors `search_many` args; no response blobs | ✓ |
| Include weights + `:all` + shared rails | Within library-accepted options | ✓ |
| Store merge traces / hits | Engine-coupled; large | |

**User's choice:** Synthesis — **D-13–D-15** in CONTEXT (IN vs OUT list).

---

## 4. Documentation home

| Option | Description | Selected |
|--------|-------------|----------|
| A — `scrypath_ops/docs/*.md` | Normative spec beside operator IA | ✓ (primary) |
| B — Root `guides/` only | Risks Hex-adjacent promise for app-only format | |
| C — `@moduledoc` only | Weak for SRE review | |
| D — Hybrid | **`playbook-schema-v1.md` + deep `@moduledoc`** | ✓ |

**User's choice:** Synthesis — **D-16–D-18** in CONTEXT.

---

## Claude's Discretion

- Module naming, Ecto vs manual validation depth, fixture layout — see CONTEXT **Claude's Discretion** block.

## Deferred Ideas

- DB-backed playbooks, YAML wire format, JSON Schema publication, response-capture playbooks — see CONTEXT `<deferred>`.
