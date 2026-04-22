# Phase 63: Bounded team persistence and security posture - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **63-CONTEXT.md**.

**Date:** 2026-04-22  
**Phase:** 63 — Bounded team persistence and security posture  
**Areas discussed:** Team persistence fork (A vs B); Authority & precedence; Security & scrub; Operational / DX package  
**Method:** User selected **all** areas and requested parallel subagent research + one-shot synthesized recommendations; facilitator captured convergent outputs as locked decisions in CONTEXT.

---

## 1. Team persistence fork (OPS2-04)

| Option | Description | Selected |
|--------|-------------|----------|
| **(A) File + env + GitOps/docs** | Single filesystem workspace authority; strengthen docs, examples, optional CI validation task | ✓ |
| **(B) Optional Ecto catalog** | DB-backed catalog behind config; migrations, exclusive mode, higher operational load | |
| **Hybrid without clear SSOT** | Two live writers or merged authority | ✗ (explicitly rejected — violates OPS2-04) |

**User's choice:** Research-synthesized lock: **(A) only** for Phase 63; **(B) deferred** with conditions documented in CONTEXT.  
**Notes:** Subagents converged on lowest surprise for OSS contributors, **`mix verify.opsui`** hygiene, diffable/PR-reviewed playbooks, avoiding Terraform-style dual authority.

---

## 2. Authority & precedence

| Option | Description | Selected |
|--------|-------------|----------|
| **Single mode / SSOT per deploy** | One mutating store; config + docs state authority clearly | ✓ |
| **Union catalog (file ∪ DB)** | Merged listings with precedence rules | ✗ |
| **Read-through cache (steady state)** | Secondary store without strict migration window | ✗ |

**User's choice:** **Single filesystem authority**; document `SCRYPATH_OPS_PLAYBOOK_DIR` / `Path.expand` behavior and CI absolute paths.  
**Notes:** If **(B)** ever returns: exclusive `xor` mode + boot validation + explicit import/export only.

---

## 3. Security & scrub (OPS2-07)

| Option | Description | Selected |
|--------|-------------|----------|
| **Reject (fail closed)** | Canonical `V1.validate/1` rejects unknown/banned | ✓ |
| **Silent redact on default path** | Strip keys and continue without user awareness | ✗ |
| **Named sanitize + warnings** | Separate tool/API with explicit confirmation | (defer unless built) |

**User's choice:** Keep **reject** on canonical path; optional future sanitize is **non-default** and explicit.  
**Notes:** Expand stub tests for deep banned keys, unknown top-level, delete confirmation; add doc slices for threat model, `/ops` host auth, git/CI secret hygiene.

---

## 4. Operational shape & DX

| Option | Description | Selected |
|--------|-------------|----------|
| **Golden GitOps doc + examples + optional Mix validate** | Primary deliverable bundle for (A) | ✓ |
| **Full Ecto surface in 63** | Schema, UI dual listing, migrations | ✗ |

**User's choice:** Ship documentation package + examples + optional validation entrypoint; update persistence section of **`playbook-schema-v1.md`** for v1.15 truth.  
**Notes:** Cross-language patterns (Grafana JSON, Argo desired state) reinforce file-first trust.

---

## Claude's Discretion

- Exact paths for example playbooks and doc section naming.  
- Fixture corpus depth and whether to codegen banned-key tables from module attributes in this phase vs later.

## Deferred Ideas

- Optional Ecto catalog with exclusive mode and import/export (future phase).  
- Sanitize/repair playbook tool as explicit secondary flow.
