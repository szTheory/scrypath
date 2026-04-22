# Phase 57: Evidence triage and B1 scope lock - Context

**Gathered:** 2026-04-21  
**Status:** Ready for planning

<domain>
## Phase Boundary

Freeze **EVID-01**: a committed, in-repo evidence ledger with **≥2** concrete rows and stable row IDs. Triage **LIB-01..LIB-03** so each requirement is **mapped** to at least one evidence row, **cut** for v1.14 with written rationale, or **deferred** to a named future milestone with reason. Record that **B1** is frozen for v1.14 without expanding B2/playbook scope. Downstream Phase 58 implements **LIB-*** only against this locked picture.

</domain>

<decisions>
## Implementation Decisions

### EVID-01 artifact shape and row IDs

- **D-01:** **Canonical hybrid** — one **authoritative** in-repo Markdown file under **`.planning/`** holds the frozen table. GitHub issues, forum threads, or Slack are **non-authoritative**; they may appear only as **links inside evidence cells**, never as the sole record of a row.
- **D-02:** **Stable row IDs** use the form **`EVID-57-01`**, **`EVID-57-02`**, … (phase-scoped, two-digit sequence). Do **not** use GitHub `#NN` or UUIDs as primary keys. Optional secondary link column is fine.
- **D-03:** **Minimum columns** per row: **ID** | **Claim** (what is wrong / what we believe) | **Evidence** (URL or repo path + **short quoted excerpt** or reproduction pointer) | **LIB mapping** (empty until Phase 58; then `LIB-01` etc. or `—`).
- **D-04:** **Canonical file path:** **`.planning/EVID-01-b1-v1.14.md`**. First line after an optional title: **freeze date** and **“append-only after freeze”** rule (errata = new rows or explicit supersede flags; no silent edits to frozen rows).
- **D-05:** **Discoverability:** Add a **one-line** pointer from **`CONTRIBUTING.md`** (maintainer section) to this file; optional **PR template** checkbox for **LIB-*** PRs: “Cites **`EVID-57-*`** row(s).”

### LIB-01..03 triage rules

- **D-06:** **Independence** — Evidence for **LIB-01** does **not** obligate **LIB-02** or **LIB-03**. Each line is triaged on its own.
- **D-07:** **Cut (v1.14)** — No qualifying evidence **or** evidence does not match that REQ’s **kind** of work (e.g. only error-message pain → no obligation to ship **LIB-03** doc-contract work). One sentence **why** in the traceability table or triage note.
- **D-08:** **Defer (v1.15+)** — Evidence exists and intent is real, but work slides; must record **target milestone** + **reason** in **`.planning/REQUIREMENTS.md`** traceability (and optional backlog pointer). **Not** silent omission.
- **D-09:** **Governance** — **Single maintainer owner** publishes the locked list after a short **async review window (48–72h)** on the planning PR; “team agrees” means **written** agreement in **REQUIREMENTS** + **STATE** mirror, not a meeting vote.

### “No core merges without list membership” — definition and enforcement

- **D-10:** **Core (path-based, semver-sensitive):** changes under **`lib/scrypath/`** and **`test/scrypath/`** — these always require a valid **`EVID-57-*`** reference in the PR when the PR is part of **v1.14 B1** work (and **LIB-*** row in description or body). **`scrypath_ops/`** is **out of this gate** by default (B2).
- **D-11:** **B1 doc / contract surfaces (human-gated):** PRs that implement **LIB-01**, **LIB-02**, or **LIB-03** against normative docs must cite **`EVID-57-*`** even if touched paths are **`guides/`**, root **`README.md`**, **`CONTRIBUTING.md`**, or **`test/scrypath/docs_contract_test.exs`**. **Typo-only** or **obvious non-normative** edits (e.g. `.planning/` roadmap wording, comment typos in private modules) do **not** require evidence IDs — use maintainer judgment; optional maintainer-only **`skip-b1-evidence`**-style label if you add CI later.
- **D-12:** **Enforcement stack (pragmatic):** (1) **`.github/pull_request_template.md`** explains the **`Evidence: EVID-57-NN`** (or equivalent) token for B1 PRs. (2) **`CODEOWNERS`** on **`lib/scrypath/`** (and optionally **`test/scrypath/`**) for review quality. (3) **Defer full CI regex gate** unless pain appears — path-filter + token validation is a **Phase 58+** optional hardening, not a Phase 57 deliverable.

### Where “B1 frozen” is recorded (single source of truth)

- **D-13:** **Normative SSOT:** **`.planning/REQUIREMENTS.md`** — **EVID-01** row checked / wording updated to point at **`.planning/EVID-01-b1-v1.14.md`** and the freeze date. This is what auditors and `/gsd-complete-milestone` traceability should trust.
- **D-14:** **Operational mirror:** **`.planning/STATE.md`** → **Decisions**: one dated line, e.g. *B1 scope frozen &lt;date&gt; — see EVID-01 and `.planning/EVID-01-b1-v1.14.md`.* No duplicate of the full evidence table in STATE.
- **D-15:** **`.planning/ROADMAP.md`** — Phase 57 stays **behavioral** (success criteria); link **EVID-01** by ID; do **not** restate the full freeze prose in a third place.
- **D-16:** **`CHANGELOG.md`** — Use for **shipped** user-visible outcomes in release notes, **not** as the internal “freeze” record pre-release.

### Claude's Discretion

- **D-17:** If **CI token validation** is added later, prefer **`Evidence: EVID-57-NN`** in PR body over brittle natural-language parsing. Exact workflow file for `paths-filter` is left to implementers in Phase 58+.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements

- `.planning/REQUIREMENTS.md` — **EVID-01**, **LIB-01..03**, traceability table; normative B1 gate wording.
- `.planning/ROADMAP.md` — Phase **57** success criteria and phase boundary (v1.14 section with `### Phase 57` heading).
- `.planning/PROJECT.md` — v1.14 vision, B1 vs B2 boundaries, out-of-scope items.

### Evidence and research

- `.planning/research/SUMMARY.md` — Why evidence list locks B1 confidence; sequencing B1 before B2.
- `.planning/research/PITFALLS.md` — Speculative API churn; supports evidence-only LIB-02.
- `.planning/milestone-candidates.md` — B1 / B2 ranking context.

### Operator / verify context (out of Phase 57 scope but adjacent)

- `scrypath_ops/lib/scrypath_ops/search_playground.ex` — Bounded-playground discipline for later playbook phases.
- `milestones/v1.12-REQUIREMENTS.md` — Prior **ONBD-*** / **VRFY-*** patterns referenced by **LIB-01** / **LIB-03** evidence in **REQUIREMENTS.md**.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`test/scrypath/docs_contract_test.exs`** — Doc-contract pattern **LIB-03** will extend; Phase 57 does not modify it but planners should cite it when mapping evidence to anchors.
- **Root `lib/scrypath/`** + **`test/scrypath/`** — Default **“core”** path set for the merge-discipline decision.

### Established patterns

- **Monorepo split:** Hex **`scrypath`** at repo root vs **`scrypath_ops/`** Phoenix app — B1 gate applies to the **library and its normative docs/contracts**; ops work follows later **OPS-PB-*** phases.

### Integration points

- **CONTRIBUTING / PR template** — Primary contributor-facing enforcement surface for evidence citations (to be updated in Phase 57 or start of Phase 58 per plan).

</code_context>

<specifics>
## Specific Ideas

- Row ID prefix **`EVID-57-*`** ties evidence visibly to **Phase 57** and greps cleanly in **`git log`** and GitHub search.
- **Append-only freeze** mirrors mature OSS “locked RFC” semantics without adopting full ADR ceremony for a small evidence table.

</specifics>

<deferred>
## Deferred Ideas

- **Automated CI gate** parsing `Evidence: EVID-57-*` when `lib/scrypath/**` changes — optional hardening after templates prove insufficient.
- **Explicit `core-paths.txt` manifest** — revisit if the repo adds more publishable packages beside **`scrypath`**.

</deferred>

---

*Phase: 57-evidence-triage-and-b1-scope-lock*  
*Context gathered: 2026-04-21*
