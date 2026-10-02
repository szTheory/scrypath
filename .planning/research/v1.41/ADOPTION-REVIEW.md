# v1.41 adopter and readiness review

**Date:** 2026-09-28. **Disposition:** Finalize the roadmap after the required clarifications below. This is a source review, not readiness certification. No tests, CI dispatches, or delivery actions were performed.

## Adopter outcomes

| Persona and job | Existing route and evidence | v1.41 outcome |
|---|---|---|
| Phoenix SaaS engineer: add one searchable schema and get hydrated records | README Quick Path → `guides/golden-path.md`; context-owned writes/search; existing path/package consumer proof | Preserve a short first-result path while correcting dependencies and delivery claims. |
| Catalog engineer: compose browser filters/facets and propagate related changes | JTBD flows; `guides/request-edge-search.md`, `guides/related-data-and-reindexing.md`; Phase 165/166 selected scenarios | Retain job-specific routes; do not turn a documentation cleanup into new capabilities. |
| Multi-tenant platform engineer: authorize a search without crossing tenant boundaries | Phase 166 persisted-membership scenario and public tenant tests | Reuse evidence after relevant-source comparison; explicitly retain host authentication/membership and database-scoping ownership. |
| On-call engineer: diagnose stale search, repair selected records, observe completion | Sync/recovery guides; Phase 166 selected-ID repair-to-visible-search and reused C-09 delete receipt | Keep acceptance, task completion, search visibility, and recovery choices distinct. Synthetic proof does not certify arbitrary production recovery. |

These match the five jobs in `prompts/search-lib-use-cases-deep-research.md`. Its speculative API/backend suggestions are superseded by current project scope. The current ratchet prompt supports bounded maintenance and permits an idle release train; no brand or interface redesign follows from these findings.

## Documentation: confirmed defects versus useful repetition

**Confirmed:** README declares that it does not restate the sync guide, then repeats the mode matrix, result statuses, lifecycle chain, recovery framing, and several authority instructions. `guides/jtbd-and-user-flows.md` contains two “What Scrypath is opinionated about” sections and two next-reading lists. The second lists contain some unique destinations; merge them rather than deleting blindly.

**Preserve:** README installation/schema example, one context-owned first-result route, and a short consistency warning; the golden path's inline-only tutorial; JTBD's six jobs and adoption progression. These serve different reading contexts. “One authority” does not require making readers follow a link for every essential caveat.

**Precision issue:** the sync guide labels its mode table “What completed work means” while manual/Oban rows describe acceptance. Rename that heading to describe the return boundary. Its canonical operational text also does not currently document the literal `:status` result keys shown in README. Those keys are documented in `lib/scrypath.ex` and implemented in `lib/scrypath/sync.ex`; preserve access through the API reference or a concise canonical-guide link if removing README detail. No runtime defect is established.

| Claim | Canonical authority | Entry-page responsibility |
|---|---|---|
| Installation, supported versions, published versus checkout truth | `guides/support-and-compatibility.md`, backed by package/source receipts | Show the approved install snippet and route to support. |
| Return structure | `Scrypath.sync_record/3` documentation in `lib/scrypath.ex` | Link to the contract. |
| Sync semantics, lifecycle, operational caveats | `guides/sync-modes-and-visibility.md` | Brief mode-selection summary and acceptance warning. |
| First implementation | `guides/golden-path.md` | Direct start link and small schema example. |
| Jobs and feature navigation | `guides/jtbd-and-user-flows.md` | One merged set of job routes. |
| Public scope reopening | `guides/scope-and-reopen-policy.md` | Preserve the policy route and current boundaries. |
| Readiness to begin later operator UI work | `.planning/reference/PRE-OPERATOR-UI-READINESS.md` plus dated evidence | Keep distinct from adopter compatibility/support readiness. |

There is no demonstrated incompatibility between “effectively done for its stated v1 mission” in scope policy and NOT READY for additional operator UI investment. They answer different questions. Clarifying that distinction is optional if wording is touched.

**Checks constrain the edit:** `test/scrypath/docs_contract_test.exs:408` requires the full lifecycle in both README and guide; line 798 requires README's literal `:status`/`:accepted`; line 785 checks proximity of authority wording and the guide link; line 464 checks section ordering. These are phrase assertions, not evidence that duplication improves adoption. Amend only assertions superseded by the approved consolidation, retaining routes and operational semantics at their owners. `telemetry_test.exs:291` already checks lifecycle in the guide and the mode matrix in ARCHITECTURE, not README.

`CONTRIBUTING.md` names `mix docs --warnings-as-errors`, `mix verify.phase112`, and the applicable adopter/support checks. The broad docs-contract suite is optional and excluded from default CI/release. DOC-01 should name the intended checks and permit focused updates to obsolete copy assertions; “existing checks pass” must not freeze accidental duplication or silently reinstate an expensive gate.

## Scoped alternatives

| Alternative | Example | Benefits / costs |
|---|---|---|
| **Recommended: concise summaries plus canonical links** | “Start inline; consider Oban for durable queueing or manual sync for controlled workflows. Acceptance does not establish visibility. See the sync contract.” Merge JTBD's unique routes once. | Keeps first-hour context, reduces conflicting authority, narrow review. Requires small assertion updates. |
| Links only for README sync | One link replaces the entire sync section; JTBD duplicates merged. | Lowest maintenance surface, but hides a critical consistency warning and adds navigation friction. Too aggressive for the stated adoption priority. |
| Keep a compact mode table | Three rows and one canonical link; remove lifecycle/status detail and redundant JTBD blocks. | Fast comparison; retains a second semantic summary to keep aligned. Acceptable if the owner prefers scanning, but less consistent with DOC-01's current wording. |

Two primary-source lessons support the first alternative. Ecto's [getting-started guide](https://ecto.hexdocs.pm/getting-started.html) advances through setup, schema, insertion, and querying while linking deeper reference material: preserve Scrypath's linear golden path. Searchkick's [README](https://github.com/ankane/searchkick#readme) gets readers to declaration/index/query before its strategy and association sections: retain a short first result and explicit operational limitations without copying its callbacks or backend breadth. These are documentation-structure inferences, not evidence to add features.

## Bound the gate and terminate closeout

**Required: fix live authority drift.** The readiness reference currently says no follow-up is approved and Phase 167 is still completing, conflicting with approved v1.41 PROJECT/REQUIREMENTS. Its current evidence links use old `../phases/167-...` paths. Update the live header, current-evidence links, and current-approved-scope section to archived locations/current scope. Preserve the entire historical section beginning “Phase 164 dated assessment — 2026-09-26,” its cleanup inventory, and the archived Phase 167 assessment. Add migration navigation outside immutable history if necessary.

**Required: finite evidence scope.** Reuse the seven dimensions/24-claim baseline and named adopter workflows; classify changes since their recorded sources and inspect new concrete evidence. Record each relevant invalidator. Condition 3 needs a declared finite set of important workflows and appropriately bounded claims; its Phase 167 PASS disclaimer that it does not prove “every important workflow” otherwise leaves ambiguous coverage. Condition 4 needs green evidence for the assessed source, not merely unchanged CI topology. Condition 5 disposes the observed inventory at a cutoff; it does not require proving no imaginable improvement exists.

Keep three categories distinct:

- **Defect:** a reproducible contradiction, affected dependency, broken path, or incorrect behavior. The parallel security review's refreshed advisories must determine actual graph/version scope; the original Phoenix-only finding cannot bound the final gate.
- **Missing evidence:** a named claim lacks sufficient current proof. Reuse, narrow the claim, or execute the smallest discriminating check; do not automatically invent runtime work.
- **Owner decision:** risk acceptance, scope expansion, merge trust, or later UI timing. Record actual decisions; automation cannot manufacture approval. Descriptor-less probes and accepted archive metadata limits are not new defects by themselves.

**Required: settle the final-receipt protocol before execution.** Phase 164 and Phase 167 both assessed before final tracking/attestation, leaving condition 6 UNKNOWN after later successful receipts. Repeating that ordering guarantees another follow-up.

Use the existing candidate/final stages as a finite protocol: prepare and attest the candidate; commit all final tracking, assessment inputs, and cleanup dispositions; attest that final SHA; then issue a separately timestamped terminal readiness decision outside tracked source that joins those immutable inputs to the final receipt and required post-merge evidence. No READY claim precedes the required receipt. The live authority must identify this terminal decision/receipt as the current decision source; its discoverable location and retention must be settled during planning. Do not modify tracked files afterward solely to record success, weaken exact-SHA requirements, or backdate historical rows. If the existing receipt cannot express the terminal decision, choose its minimal external representation during planning rather than create another milestone. Failure leaves NOT READY with a specific blocker.

## Minimal requirement and ordering changes

- **DOC-01 — required:** preserve first-hour summary/caveat, consolidate duplicate detail/routes, retain unique return-contract access, and allow focused updates to superseded documentation assertions.
- **GATE-01 — required:** add finite claim inventory, source invalidators, live-authority reconciliation, and a post-final-receipt terminal decision; historical outcomes remain immutable.
- **CLOSE-01 — required:** define the last tracked-write boundary and authoritative external final receipt; distinguish candidate, final branch, merged-main, and published-package identities. Explicit disposition of historical low-value debt can satisfy transparency; it cannot waive security findings or fabricate acceptance.
- **Phase order — required dependency clarification:** preserve 168→169→170 overall, but do docs changes before the last delivery/main verification, then freeze tracking, attest, and decide. Phase 169's earlier green-main receipt cannot attest later Phase 170 docs. One milestone may conclude NOT READY; no automatic successor milestone or UI start follows.
- **Optional:** simplify remaining README navigation later only if this narrow edit still leaves demonstrable confusion. No broad documentation audit, additional required CI lane, or new UX research is necessary now.
