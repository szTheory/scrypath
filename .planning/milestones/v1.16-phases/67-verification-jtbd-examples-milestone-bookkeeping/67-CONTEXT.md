# Phase 67: Verification, JTBD examples, milestone bookkeeping - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the Phase 67 close-out slice for **OPS3-04**, **OPS3-05**, and **OPS3-06**: extend execution-surface verification so **`mix verify.opsui`** and bounded doc-contract checks catch drift; ship **two** operator-meaningful **`examples/playbooks/`** fixtures that align with docs; and prepare the **v1.16** milestone freeze / rolling traceability without claiming a Hex or planning close that did not actually happen.

**Explicitly not in this phase:** widening the runner contract beyond Phase 66; snapshot-testing all OPSUI copy; building a generalized contract-manifest system; introducing production-like golden workspace trees; changing **`mix.exs`** version / release narrative unless a real publish is in scope; or inventing durable run history, richer playbook transport, or deeper OPSUI capability.

</domain>

<decisions>
## Implementation Decisions

### Verification contract depth

- **D-01:** Use a **layered, bounded contract** for execution verification. Keep **`mix verify.opsui`** as the umbrella entrypoint only; do **not** turn the Mix task into a contract parser or a second source of truth.
- **D-02:** Put execution-surface contract tests in **`scrypath_ops`**, close to the code they protect:
  - a bounded **LiveView** contract test for stable execution selectors / phrases
  - a **`DocResolver`** contract test for path + fragment mapping and on-disk anchor existence
  - a fixture contract test that validates shipped playbooks and checks doc references
- **D-03:** Extend root **`test/scrypath/docs_contract_test.exs`** only for maintainer-facing contracts: contributor instructions, the presence of **`mix verify.opsui`**, the **`mix scrypath_ops.playbooks.validate examples/playbooks`** path, and the exact shipped example filenames referenced from docs.
- **D-04:** Freeze only the **bounded execution contract**, not all prose. Stable items for Phase 67:
  - running-state presence
  - success summary prefix **`Run finished`**
  - failure panel selector
  - **`Cancel run`**
  - **`Copy diagnostics`**
  - **`RunFailure`** response shape fields and **`DocResolver`** anchor mappings
- **D-05:** Leave flexible any support text that is not the operator contract: import/load flashes, helper configuration text, detailed success summaries after the stable prefix, and visual phrasing outside existing test ids / nav contracts.
- **D-06:** Do **not** freeze full absolute documentation URLs from **`DocResolver`**. Freeze relative doc paths + fragments and assert those anchors exist on disk; the base URL remains configurable.
- **D-07:** Do **not** duplicate Phase 66 runner semantics in Phase 67 docs tests. The raw tuple seam and reason identity are already locked; Phase 67 verifies the operator-facing execution surface above that seam.

### JTBD example fixture shape

- **D-08:** Ship **narrative JTBD fixtures** as the canonical **`examples/playbooks/`** examples for Phase 67. Do **not** rely on bare minimal schema envelopes as the main shipped examples, and do **not** escalate to a full production-like golden workspace.
- **D-09:** The two primary shipped fixtures should represent distinct operator jobs:
  - **single-search triage**
  - **multi-search / federation inspection**
- **D-10:** Use explicit, job-shaped filenames rather than transport-shaped filenames. Recommended names:
  - **`sync_triage_posts_recent.json`**
  - **`federation_inspect_posts_and_comments.json`**
- **D-11:** Each shipped fixture should include operator-meaningful metadata when supported by the current wire format:
  - **`title`**
  - **`description`**
  - optional **`tags`**
  - bounded, valid **`opts`**
  - filenames that describe the job being saved
- **D-12:** Keep the examples small, importable, and validation-friendly. They are **input fixtures**, not backend output snapshots, and they must remain cheap to validate through **`mix scrypath_ops.playbooks.validate examples/playbooks`**.
- **D-13:** Keep **`playbook-schema-v1.md`** as the wire-format authority with minimal structural snippets. Put the operator narrative around why to run these fixtures in operator / contributor docs, not in the schema spec itself.
- **D-14:** Keep the schema references illustrative and portable. Continue using bounded example modules such as **`MyApp.Post`** / **`MyApp.Comment`** unless a stronger canonical demo domain is intentionally introduced elsewhere.
- **D-15:** Avoid backend-specific or stub-hostile options in the primary shipped fixtures. The examples should teach operator intent, not force deeper backend semantics or special-case weighting behavior.

### Milestone bookkeeping discipline

- **D-16:** Phase 67 should **prepare the v1.16 freeze and update rolling traceability immediately**, but it should **not** claim a release, archive, or Hex narrative that is not actually happening in the same change.
- **D-17:** Update rolling planning truth when the work is complete:
  - **`.planning/REQUIREMENTS.md`** traceability for **OPS3-04**..**OPS3-06**
  - **`.planning/ROADMAP.md`** Phase 67 completion state
  - **`.planning/PROJECT.md`** and **`.planning/STATE.md`** current-state text
- **D-18:** Prepare the frozen milestone trio for **v1.16**:
  - **`milestones/v1.16-ROADMAP.md`**
  - **`milestones/v1.16-REQUIREMENTS.md`**
  - **`milestones/v1.16-MILESTONE-AUDIT.md`**
  These should reflect real status only. If the audit is not actually complete yet, do not label it as passed.
- **D-19:** Touch **`.planning/MILESTONES.md`** only when **v1.16** is genuinely closed. Until then, preserve the distinction between active milestone truth and historical shipped milestones.
- **D-20:** Do **not** touch **`mix.exs`** versioning, **`CHANGELOG.md`** release narrative, or Hex-facing claims unless a real publish is in scope for the same close.
- **D-21:** Maintain the repo’s existing separation between “milestone shipped / archived in planning” and “Hex package released.” Scrypath’s public package truth comes from the actual release path, not from planning closure alone.

### the agent's Discretion

- Exact test module names and placement inside **`scrypath_ops/test/`**, provided the layered split above is preserved.
- Whether the old minimal example filenames are replaced, retained as secondary schema-only examples, or redirected via docs, provided the two JTBD fixtures become the canonical shipped examples.
- Exact wording of bounded docs-contract assertions, provided they freeze the required filenames, commands, and honest execution anchors without snapshotting all prose.

</decisions>

<specifics>
## Specific Ideas

- The verification strategy should feel like Phoenix / ExUnit, not a frontend snapshot suite: behavioral tests for async LiveView flows plus a few stable phrases and selectors, with separate doc/path checks where needed.
- Good OSS precedent here is to freeze **honesty statements** and stable affordances, not every sentence. Scrypath should keep protecting the operator contract around running / failure / docs, while allowing copy polish to evolve.
- The example fixtures should read like “jobs an operator would save,” not “the smallest JSON that validates.”
- A clean maintainer answer to “what examples ship for playbooks?” should point to two named files that demonstrate real operator intent.
- A clean maintainer answer to “did v1.16 close?” should remain truthful even if Phase 67 only prepares the freeze artifacts and rolling traceability in this step.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope and planning truth

- `.planning/ROADMAP.md` — Phase 67 scope and observable success criteria.
- `.planning/REQUIREMENTS.md` — **OPS3-04** through **OPS3-06** requirement text and traceability table.
- `.planning/PROJECT.md` — project principles: operator honesty, DX, release quality, current milestone framing.
- `.planning/STATE.md` — current progress / next-step truth that Phase 67 must update.
- `.planning/MILESTONES.md` — historical milestone close pattern and wording discipline.

### Prior phase decisions

- `.planning/phases/65-playbook-run-lifecycle-opsui/65-CONTEXT.md` — locked execution lifecycle, structured failures, and two-hop doc expectations.
- `.planning/phases/66-runner-library-contract/66-CONTEXT.md` — locked raw runner seam, reason identity, and parity boundary.

### Verification and contributor contracts

- `lib/mix/tasks/verify.opsui.ex` — umbrella verify entrypoint shape; should stay orchestration-only.
- `test/scrypath/docs_contract_test.exs` — existing root docs-contract patterns for contributor / maintainer truth.
- `README.md` — maintainer-facing wayfinding for optional **`scrypath_ops`** verification.
- `CONTRIBUTING.md` — contributor verify matrix and playbook validation command contract.

### OPSUI execution surfaces

- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` — execution UI copy, selectors, and run lifecycle rendering.
- `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` — current execution-surface behavior coverage.
- `scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex` — stable failure-shape enrichment boundary.
- `scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex` — doc path / anchor mapping for operator-facing failures.

### Playbook docs and examples

- `scrypath_ops/docs/playbook-schema-v1.md` — wire-format authority and troubleshooting anchors.
- `scrypath_ops/docs/team-playbook-persistence.md` — examples directory, GitOps posture, validation command.
- `scrypath_ops/docs/operator-ia.md` — JTBD framing and `/ops/playbooks` operator story.
- `scrypath_ops/examples/playbooks/search_minimal.json` — existing minimal single-search example to replace or demote from primary status.
- `scrypath_ops/examples/playbooks/search_many_minimal.json` — existing minimal multi-search example to replace or demote from primary status.
- `scrypath_ops/test/fixtures/playbooks/README.md` — current fixture guidance about raw JSON ownership.
- `scrypath_ops/test/scrypath_ops/mix/playbooks_validate_test.exs` — current validation gate for **`examples/playbooks`**.

### Release and close discipline

- `docs/releasing.md` — release truth, Hex publish path, and separation from **`scrypath_ops`**.
- `mix.exs` — current package version / HexDocs truth; must stay untouched unless release is in scope.
- `.planning/milestones/v1.15-ROADMAP.md` — recent archive pattern for OPSUI milestone freezes.
- `.planning/milestones/v1.15-REQUIREMENTS.md` — recent requirements freeze format.
- `.planning/milestones/v1.15-MILESTONE-AUDIT.md` — recent audit structure and wording.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`mix verify.opsui`** already provides the right umbrella command shape; it should stay a thin orchestrator.
- **`PlaybookLiveTest`** already exercises async execution flows and stable execution-state phrases; Phase 67 can extend that style instead of inventing a new harness.
- **`RunFailure`** and **`DocResolver`** already centralize operator-facing failure metadata and docs links, which makes bounded contract tests straightforward.
- **`playbooks_validate_test.exs`** already proves the examples directory can be validated cheaply without backend services.

### Established Patterns

- Root **`docs_contract_test.exs`** is used for maintainer-facing narrative and command truth, not optional-app behavioral details.
- **`scrypath_ops`** keeps UI/runtime contracts near the optional Phoenix app rather than exporting them into the Hex package surface.
- Planning archives consistently separate in-repo milestone closure from Hex release claims.

### Integration Points

- Add new execution-surface contract tests under **`scrypath_ops/test/`** rather than enlarging the root docs suite into UI parsing.
- Update operator / contributor docs to reference the final JTBD fixture filenames directly.
- Prepare **`milestones/v1.16-*`** snapshots from current rolling planning files once traceability is complete.

</code_context>

<deferred>
## Deferred Ideas

- A centralized manifest file for strings / anchors / fixtures — over-engineered for this phase.
- Full snapshot-style freezing of PlaybookLive copy or HTML.
- Production-like golden workspace trees or deeper example catalogs.
- Any version bump, release note change, or Hex-publish narrative not backed by a real release event.
- Durable run history, richer playbook transport semantics, or broader OPSUI execution features beyond the bounded verification / examples / bookkeeping close.

</deferred>

---

*Phase: 67-verification-jtbd-examples-milestone-bookkeeping*
*Context gathered: 2026-04-22*
