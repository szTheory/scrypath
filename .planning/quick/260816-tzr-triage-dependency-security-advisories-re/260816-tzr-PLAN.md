---
quick_id: 260816-tzr
phase: quick-260816-tzr-triage-dependency-security-advisories
plan: 01
type: execute
wave: 1
depends_on: []
description: Triage dependency security advisories reported by mix deps.get
status: ready
created: 2026-08-16
autonomous: true
files_modified:
  - .planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md
  - .planning/todos/pending/2026-08-16-remediate-dependency-security-advisories.md
  - .planning/STATE.md
must_haves:
  truths:
    - "Maintainers can identify every affected Mix project and package, whether each dependency is direct or transitive, the first release that clears the recorded advisories, and the confidence of the local exposure assessment."
    - "The advisory record explicitly says reproduction and triage are complete while remediation remains pending; it never claims that a vulnerable dependency has been fixed."
    - "Remediation is actionable as four ordered, atomic batches with a verification gate after each batch."
    - "The release train remains idle with no milestone reopened, while the pending security work is visible in the project-local todo intake."
  artifacts:
    - path: ".planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md"
      provides: "Auditable reproduction inventory, advisory matrix, exposure assessments, fixed minima, citations, remediation batches, and gates"
    - path: ".planning/todos/pending/2026-08-16-remediate-dependency-security-advisories.md"
      provides: "Concrete pending maintenance item for the four-batch remediation"
    - path: ".planning/STATE.md"
      provides: "Idle release-train truth plus a pointer to the pending security todo"
  key_links:
    - from: ".planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-RESEARCH.md"
      to: ".planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md"
      via: "Every affected package row, fixed minimum, exposure qualification, and primary-source citation is preserved in the durable triage ledger"
    - from: ".planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md"
      to: ".planning/todos/pending/2026-08-16-remediate-dependency-security-advisories.md"
      via: "The todo links the authoritative ledger and repeats its four batch boundaries and verification gates"
    - from: ".planning/todos/pending/2026-08-16-remediate-dependency-security-advisories.md"
      to: ".planning/STATE.md"
      via: "STATE lists the pending maintenance item without creating an active milestone or phase"
---

# Quick Task 260816-tzr: Triage Dependency Security Advisories

<objective>
Convert the verified `mix deps.get` advisory research into a durable security-triage ledger and a concrete pending remediation item without changing dependency manifests or lockfiles.

Purpose: Give maintainers an exact, primary-source-backed record of the current advisory exposure and a safe four-batch follow-up sequence while preserving the repository's idle release-train truth.
Output: One advisory-triage artifact, one pending maintenance todo, and a narrow STATE todo pointer.
</objective>

<context>
@AGENTS.md
@CONTRIBUTING.md
@.planning/STATE.md
@.planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-RESEARCH.md
@mix.exs
@mix.lock
@scrypath_ops/mix.exs
@scrypath_ops/mix.lock
@examples/phoenix_meilisearch/mix.exs
@examples/phoenix_meilisearch/mix.lock
@examples/scrypath_ecommerce/mix.exs
@examples/scrypath_ecommerce/mix.lock
</context>

<tasks>

<task type="auto">
  <name>Task 1: Publish the advisory reproduction and exposure ledger</name>
  <files>.planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md</files>
  <action>Create the durable triage artifact from the locked research. Start with a prominent status block dated 2026-08-16 stating that advisories were reproduced in four independently resolved Mix projects, triage is complete, remediation is pending, and no manifest or lockfile was changed. Include: (1) a project inventory for root `scrypath`, `scrypath_ops`, `examples/phoenix_meilisearch`, and `examples/scrypath_ecommerce`; (2) a package-by-package matrix for hpax, mint, req, plug, bandit, phoenix, phoenix_live_view, postgrex, decimal, and swoosh with affected locked versions/projects, every recorded advisory ID and severity, direct/transitive status and introducing path, first release that fixes all advisories in that row, runtime surface, and an explicit exposure-confidence classification such as confirmed surface, credible/configuration-dependent, or reduced confidence but not exempt; (3) the four ordered remediation batches exactly as researched—root core client, legacy Phoenix example/Ecto-Decimal alignment, ScrypathOps, then ecommerce—with batch risk and exact fixed minima; (4) the repository commands required after each batch; and (5) the unresolved reachability questions for Mint response parsing, Req decompression/call options, Swoosh adapter selection, and Postgrex notification/stream paths. Preserve primary links to the EEF CNA records, upstream GHSAs/GitHub Advisory records, and Hex package pages beside the claims they support. Explain that fixed minima clear the recorded advisory set but are not a direction to upgrade opportunistically to current package heads. Do not edit, regenerate, or fetch dependencies, and do not describe any advisory as resolved in the checkout.</action>
  <verify>
    <automated>test -f .planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md &amp;&amp; rg -q "remediation is pending|Remediation is pending" .planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md &amp;&amp; rg -q "hpax.*1\.0\.4|1\.0\.4.*hpax" .planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md &amp;&amp; rg -q "mint.*1\.9\.3|1\.9\.3.*mint" .planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md &amp;&amp; rg -q "req.*0\.6\.1|0\.6\.1.*req" .planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md &amp;&amp; rg -q "decimal.*3\.0\.0|3\.0\.0.*decimal" .planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md &amp;&amp; rg -q "cna\.erlef\.org" .planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md</automated>
  </verify>
  <done>The ledger names all four projects and ten affected package families, records exact advisories/directness/fixed minima/exposure confidence, preserves primary citations and open questions, defines four isolated batches with gates, and states unambiguously that the checkout is not remediated.</done>
</task>

<task type="auto">
  <name>Task 2: File the four-batch remediation in the pending maintenance intake</name>
  <files>.planning/todos/pending/2026-08-16-remediate-dependency-security-advisories.md, .planning/STATE.md</files>
  <action>Create a pending todo using the repository's existing YAML-frontmatter and Problem/Solution structure. Set a high security/dependency priority, link the research and the Task 1 triage ledger, and define acceptance as four separate commits executed in order with verification between batches: root Req 0.6 constraint plus client graph; isolated legacy Phoenix example including Ecto/Ecto SQL 3.14 and Decimal 3; ScrypathOps web/client graph; ecommerce web/client graph. Repeat the exact fixed minima and command gates from the triage ledger so the todo is independently actionable, while directing the future executor to consult upstream migration/release notes before each constraint change. State that each batch must stop on a failed gate and that the todo remains open until `mix deps.get` no longer reports the recorded advisories in all four projects and the relevant project gates pass. Add one bullet under STATE `### Todos` pointing to this pending file and noting that triage—not remediation—is complete. Preserve `milestone: none`, `current_phase: null`, `status: idle`, the Current Focus/Current Milestone idle wording, archived milestone sections, and all existing completed-todo entries. Do not edit ROADMAP.md, create a phase, move the todo to completed, or touch any `mix.exs`/`mix.lock` file.</action>
  <verify>
    <automated>test -f .planning/todos/pending/2026-08-16-remediate-dependency-security-advisories.md &amp;&amp; rg -q '^status: pending$' .planning/todos/pending/2026-08-16-remediate-dependency-security-advisories.md &amp;&amp; rg -q '260816-tzr-ADVISORY-TRIAGE\.md' .planning/todos/pending/2026-08-16-remediate-dependency-security-advisories.md &amp;&amp; rg -q '2026-08-16-remediate-dependency-security-advisories\.md' .planning/STATE.md &amp;&amp; rg -q '^milestone: none$' .planning/STATE.md &amp;&amp; rg -q '^status: idle$' .planning/STATE.md &amp;&amp; git diff --exit-code -- mix.exs mix.lock scrypath_ops/mix.exs scrypath_ops/mix.lock examples/phoenix_meilisearch/mix.exs examples/phoenix_meilisearch/mix.lock examples/scrypath_ecommerce/mix.exs examples/scrypath_ecommerce/mix.lock .planning/ROADMAP.md</automated>
  </verify>
  <done>A high-priority pending maintenance item contains the exact four-batch remediation contract and closure gates, STATE links it while remaining idle with no active milestone/phase, ROADMAP is unchanged, and dependency manifests and lockfiles remain untouched.</done>
</task>

</tasks>

<threat_model>
## Trust boundaries

This quick task crosses no runtime trust boundary and changes no dependency graph. Its security boundary is planning truth: reproduced advisory evidence must remain traceable to primary sources, exposure uncertainty must not be converted into a safety claim, and pending remediation must not be represented as complete.

## STRIDE register

| Threat ID | Category | Component | Severity | Disposition | Mitigation plan |
|---|---|---|---|---|---|
| T-quick-deps-01 | Tampering | Advisory inventory and fixed-version claims | high | mitigate | Preserve exact IDs, locked versions, fixed minima, project paths, and primary EEF/GHSA/Hex citations from the locked research in the ledger. |
| T-quick-deps-02 | Repudiation | Reproduction and remediation status | high | mitigate | Date the reproduction evidence and place an explicit triage-complete/remediation-pending/no-dependency-change status at the top of both durable artifacts. |
| T-quick-deps-03 | Information disclosure | Exposure assessment | medium | accept | The artifacts contain dependency and configuration facts already present in the public OSS repository; do not include secrets, tokens, private infrastructure, or exploit payloads. |
| T-quick-deps-04 | Elevation of privilege | Future remediation intake | high | mitigate | Require four isolated batches, upstream release-note review, stop-on-failure behavior, and the project-specific compile/test/CI gates before closure. |
</threat_model>

<verification>
Structural checks prove the advisory ledger contains the status, core fixed minima, and primary-source evidence. Todo/state checks prove the remediation is visible but pending, the release train remains idle, and no roadmap, dependency manifest, or lockfile changed.
</verification>

<success_criteria>
- A maintainer can trace every reproduced advisory from affected project and locked package to directness, fixed minimum, exposure confidence, and a primary source.
- The four remediation batches are ordered, isolated, and paired with the exact project verification gates from CONTRIBUTING and the research.
- The pending todo has a measurable closure condition across all four Mix projects.
- The ledger, todo, and STATE all distinguish completed triage from pending remediation and make no fixed-vulnerability claim.
- ROADMAP, all manifests, and all lockfiles remain unchanged; STATE still reports no active milestone or phase.
</success_criteria>

## Source coverage audit

| Source | ID | Feature / constraint | Plan | Status | Notes |
|---|---|---|---|---|---|
| GOAL | — | Triage dependency security advisories reported by `mix deps.get` | Task 1 | COVERED | Produces the durable, auditable advisory ledger. |
| REQ | — | Quick task is triage-only; no roadmap requirement IDs or active milestone | Tasks 1-2 | COVERED | No dependency or roadmap mutation is planned. |
| RESEARCH | — | Advisories reproduced in root, Ops, legacy Phoenix example, and ecommerce | Task 1 | COVERED | Project inventory and locked affected packages are required. |
| RESEARCH | — | Exact advisory IDs/severities, directness, introducing paths, fixed minima, and primary citations | Task 1 | COVERED | All ten package families are named explicitly. |
| RESEARCH | — | Exposure is credible or uncertain; no blanket non-exploitability conclusion | Task 1 | COVERED | Confidence classifications and open targeted-audit questions are required. |
| RESEARCH | — | Remediation requires four atomic batches with gates between batches | Tasks 1-2 | COVERED | Ledger documents; pending todo operationalizes. |
| RESEARCH | — | Do not opportunistically upgrade to current package heads | Task 1 | COVERED | Fixed minima are presented as advisory-clearing bounds. |
| CONTEXT | — | Capture follow-up through `.planning/todos/` without reopening archived milestones | Task 2 | COVERED | Creates a pending todo and narrow STATE pointer only. |
| CONTEXT | — | Preserve idle release-train truth | Task 2 | COVERED | Explicit verification retains milestone none/status idle. |
| CONTEXT | — | Do not claim vulnerabilities are fixed | Tasks 1-2 | COVERED | Both task acceptance criteria require remediation-pending language. |
