# Phase 60: Playbook LiveView and IA - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`60-CONTEXT.md`**.

**Date:** 2026-04-22  
**Phase:** 60-playbook-liveview-and-ia  
**Areas discussed:** Surface boundary (dedicated vs SearchLive), Import UX (upload vs paste), Playbook directory resolution, Preview vs inline edit, IA placement (synthesized with OPS-PB-04)

**Mode:** User selected **all** gray areas and requested **parallel subagent research** with one-shot cohesive recommendations; primary agent synthesized subagent outputs into **`60-CONTEXT.md`**.

---

## 1. Surface boundary — dedicated LiveView vs folded into SearchLive

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated `/ops/playbooks` | Own LiveView for catalog + run; shared dispatch components | ✓ |
| Folded into `SearchLive` | Drawers/panels on `/ops/search` | |
| Hybrid embed | Nested LiveViews / heavy coupling | |

**User's choice:** Locked per research synthesis — **dedicated route** (see **D-01..D-03** in CONTEXT).

**Notes:** Postman/Grafana analogues favor separating **artifact library** from **ad-hoc explorer**; Phoenix idiom one-mount-one-responsibility; avoids SearchLive state explosion and keeps OSS narrative “bounded ops shell.”

---

## 2. Import UX — upload vs paste

| Option | Description | Selected |
|--------|-------------|----------|
| Upload-primary only | `allow_upload` → decode → validate | Partial |
| Paste-primary only | Textarea submit path | Partial |
| Both (unified pipeline) | Upload prominent + secondary paste; same validate gate | ✓ |
| Staged upload+patch | Two sources of truth | |

**User's choice:** **Both** with **upload-primary** UI and **single** parse/validate pipeline (**D-04..D-06**).

**Notes:** Matches path-safety (no user path strings); Postman/Insomnia pattern file+clipboard; footguns: payload size, no phx-change decode on megabyte text, no logging raw JSON on error.

---

## 3. Playbook directory — list / save / delete

| Option | Description | Selected |
|--------|-------------|----------|
| Env-only workspace + runtime.exs | `SCRYPATH_OPS_PLAYBOOK_DIR` → absolute config | ✓ |
| Writable default under `priv/` in release | | ✗ (explicitly rejected) |
| In-UI directory picker | | ✗ (deferred) |

**User's choice:** **Env-driven writable root**; **read-only `priv` examples** when unset; **dev/test** may default tmp path; **basename-only** save/delete with prefix/realpath guard (**D-07..D-11**).

**Notes:** Grafana/Docker “single data path” admin model; 12-factor releases; symlink/traversal mitigations as in research.

---

## 4. Loaded playbook — preview vs inline edit

| Option | Description | Selected |
|--------|-------------|----------|
| Read-only preview + run | No textarea save-to-disk | ✓ |
| Simple textarea + save | | Deferred |
| Monaco / IDE | | Deferred |
| Edit external only | Copy path + docs | Optional nicety |

**User's choice:** **Read-only preview + run**; mutations only via **Import** or export-from-search round-trip (**D-12..D-14**).

**Notes:** Argo/K8s/Terraform analogues favor explicit gates over casual live JSON mutation; shrinks LiveView state and Phase 61 scope.

---

## 5. IA / nav placement (emerged from synthesis)

| Option | Description | Selected |
|--------|-------------|----------|
| Fifth nav item after `/ops/search` | Label **Saved playbooks**; triage block unchanged | ✓ |
| Insert before search | | (rejected — would break “search last” triage story) |

**Notes:** **D-15..D-16** in CONTEXT; **`operator-ia.md`** nav-contract JSON must gain the new row.

---

## Claude's Discretion

- Module naming, upload auto vs explicit submit, list UI table vs cards within UI-SPEC bounds.

## Deferred Ideas

- Inline JSON editor, Monaco, in-UI root picker, folding playbooks into SearchLive — see **`60-CONTEXT.md`** `<deferred>`.
