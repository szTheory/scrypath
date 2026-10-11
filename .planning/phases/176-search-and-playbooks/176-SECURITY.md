---
phase: "176"
slug: "search-and-playbooks"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-11"
verified: "2026-10-11"
---

# Phase 176 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Browser to LiveView | Search criteria, uploaded or pasted JSON, and Playbook mutation events are untrusted client input; host authorization and server validation remain authoritative. | Query strings, target IDs, file names, JSON bytes, action events |
| Search adapter to rendered Search results | Backend hits and diagnostic payloads are external data; HEEx escaping and closed, labeled disclosures constrain their presentation. | Result fields and optional raw evidence |
| LiveView to workspace Store | Search captures and Playbooks cross into local filesystem operations; the Store applies configured-root, basename, collision, and validation rules. | Serialized query criteria and Playbook JSON |
| Async task to LiveView result state | Delayed tasks may return after inputs or run identity change; captured run identity and callback guards preserve attribution. | Run ID, source, criteria, and per-target outcomes |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-176-01 | Tampering | queued Search criteria | high | mitigate | Capture mode, target, query, and page size at submit; LiveView and 38-test browser coverage verify queued edits cannot relabel results. | closed |
| T-176-02 | Information disclosure | rendered hits and raw evidence | medium | mitigate | Keep user-facing result summaries explicit, escape rendered data through HEEx, and put optional evidence in labeled closed disclosures; Ops UI tests pass. | closed |
| T-176-03 | Tampering | Search capture save | high | mitigate | Keep target allowlisting, Store basename validation, and occupied-name rejection on the server; collision and unchanged-file cases are tested. | closed |
| T-176-04 | Spoofing | selected Playbook provenance | medium | mitigate | Preserve workspace/example/imported origin independently from the selected draft and historical run; focused LiveView tests pass. | closed |
| T-176-05 | Tampering | Playbook workspace save | high | mitigate | Validate and serialize on the server; distinguish draft/run/save state and update persisted provenance only after a successful Store write; success and failure cases are tested. | closed |
| T-176-06 | Denial of service | bounded JSON import | high | mitigate | Retain the 256,000-byte ceiling for upload and paste, reject malformed/oversized inputs, and preserve the prior valid preview; boundary and browser tests pass. | closed |
| T-176-07 | Tampering | asynchronous run attribution | high | mitigate | Bind callbacks to captured run ID, source, and criteria; stale, late, cancelled, timed-out, superseded, and partial outcomes are covered by focused tests. | closed |
| T-176-08 | Elevation of privilege | Playbook file mutation handlers | high | mitigate | Recheck host authorization, configured root, safe basename/path, collisions, and exact typed-delete confirmation on every server event; forged-event and mutation tests pass. | closed |
| T-176-09 | Tampering | modal focus and row identity | medium | mitigate | Carry stable file identity and a visible logical successor through patches; reject hidden, removed, or reused targets and verify browser focus return. | closed |
| T-176-SC | Tampering | package installs | high | mitigate | No dependency manifests changed and no package installs occurred; any future install remains gated by the planned package legitimacy check and human checkpoint. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-11 | 10 | 10 | 0 | Codex — plan-time STRIDE register and implementation/test evidence, ASVS L1 |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-11

## Security Audit 2026-10-11

| Metric | Count |
|---|---|
| Threats found | 10 |
| Closed | 10 |
| Open | 0 |
