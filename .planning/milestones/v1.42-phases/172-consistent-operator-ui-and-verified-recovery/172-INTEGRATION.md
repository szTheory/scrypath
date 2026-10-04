## Integration Check Complete — Phase 172

**Verdict: PASS for product cross-module wiring and exercised E2E paths; one closeout gap remains in OPUX-08 tracking/publication.** This is a source-trace audit backed by already-run evidence; no test commands were rerun. Phase 172 is one phase, so plan-to-plan links below describe the integration boundaries, not separate requirement ownership.

### Counts

- **Connected named contracts:** 6/6 audited (shared UI, schema handoff, recovery observation, promotion gate, dialog lifecycle, browser proof lane).
- **Orphaned exports/routes:** 0 among these six contracts; no new Phase172 API route was expected for the LiveView-mediated user paths.
- **E2E flows:** 5/5 traced: shared controls across surfaces; schema handoff/back/refresh; retry-to-terminal-document recovery; guarded promotion; Playbooks file-dialog lifecycle. Product behavior is wired. The closeout/release identity subflow is **PARTIAL** pending publication and final exact-source attestation/receipt.
- **Sensitive operator mutations:** retry/delete and promotion paths revalidate allowlist/current selection and gate sensitive actions; no unprotected mutation found in the examined connections.

### Verified connections and flows

1. **Shared tokens/components → six surfaces — WIRED (OPUX-01/02/03/07).** `ScrypathOpsWeb.html_helpers/0` imports `ScrypathOpsWeb.OpsUi`; all six LiveViews use `ScrypathOpsWeb, :live_view`. Shared `ops_panel`, `ops_button`, `ops_badge`, schema selector and modal components are consumed by the surfaces; shared `text-ops-*`, spacing, radius, layer and control roles appear in rendered templates. The actual served stylesheet path is synchronized and content-versioned per Plan02. This is supported by the 48-export token contract, six-surface browser matrix, responsive widths and candidate hosted browser run 104/104. No orphan among the catalogued contracts.
2. **Schema selection → URL handoffs/back/refresh — WIRED (OPUX-03/04/06).** `OperatorSelection.resolve/2` canonicalizes only by comparison against the current allowlist and does not create atoms; `path/3` URI-encodes the canonical module name. Posture links to Failed Sync and Sync/Drift, while Failed Sync's selected-schema and recovery links use the same helper. Failed Sync and Sync/Drift resolve URL params and reject unavailable/removed schemas; generation changes invalidate stale contexts and guard mutation handlers. The rendered `operator.spec.ts` journey uses a non-first Variant schema, changes selection, retries, follows handoff, then exercises browser back, reload and invalid-target refusal. Mounted evidence 4/4 and candidate browser 104/104 are recorded.
3. **Retry acceptance → RecoveryObservation → DocumentObservation → rendered outcome — WIRED (OPUX-05/06).** Failed Sync calls `Scrypath.retry_sync_work/2`, constructs a receipt with original/replacement queue identity, attempt, schema, index and task UID, registers it with `RecoveryObservation`, and renders an accepted receipt plus handoff handle/generation. Sync/Drift validates receipt/context, accepted job and attempt, reads the exact backend task, then calls `DocumentObservation.check/3` with expected effect and document ID field. Only matching succeeded task plus observed expected document yields `:verified`; queue completion alone renders the explicit “backend evidence pending” state. Failure, timeout, malformed/missing correlation, transport error, stale generation, task mismatch and document mismatch reduce to failed/timed_out/unknown states, never verified. Browser proof asserts exact accepted job, backend task UID/index/type, active document and negative old-task/wrong-document probes. Prior failure remains visible by design.
4. **Promotion eligibility → UI/server guard → exact terminal task — WIRED (OPUX-05/06).** Sync/Drift renders eligibility from `PromotionEligibility.evaluate/1`; confirmation requires eligible/current selection/not already loading. The server `swap_live/1` independently fetches fresh reconcile and index-contract results and re-runs the same evaluator before `Meilisearch.swap_indexes/2`. It records the returned task UID and only emits completed when `Tasks.wait_for_task/2` returns that exact ID with `state: :succeeded`; mismatched task, timeout, failed/cancelled task, stale generation and observation error render unconfirmed/failed states. Automated promotion browser journey and eligibility unit coverage are recorded. This guards both rendered and direct event paths.
5. **File dialogs → hook focus/validation lifecycle — WIRED (OPUX-02/07).** Playbooks' generated upload input is linked to its label and hint, upload/paste route into decode/validate before preview, and rename/duplicate forms send change and submit events into server validation while retaining invalid user input/error. Shared `ops_modal` wires `phx-hook="OpsModal"`, `aria-modal`, labels/descriptions, initial-focus selector, cancel event and successor. `assets/js/app.js` registers that hook; it arbitrates overlays, queues initial focus after patch, traps Tab, handles Escape, closes on removal, and restores trigger/successor focus. Plan02 and Plan07 focused plus browser lifecycle evidence covers keyboard cycles, cancel/Escape, removed trigger and overlay conflict; candidate browser run passed.
6. **CI runner → named browser proof — WIRED (OPUX-06/07/08).** Root Mix alias `verify.ecommerce_mounted` calls the mounted verifier. `.github/workflows/ci.yml` runs that alias in required `ecommerce-mounted`; example `scripts/verify-e2e.sh` captures exact source SHA, starts isolated Compose browser project, runs Playwright and collects artifacts. Playwright config points at `e2e`, which includes named `operator.spec.ts` recovery/promotion journey and `admin_shell_chrome.spec.ts`. Candidate `135517b...` run `37178388184` passed required jobs, coverage, mounted 4/4 and browser 104/104; PR #91 merged as `3ad154a...`. Later release PR #92 was also merged at `8dd20e8966acd17a4ef5acec653c00dc31faab49` per task instruction. The remaining closeout path is publication/final tracking attestation, parent-owned and in progress; no product defect inferred.

### Findings

#### BLOCKER

- **None in the six product integration paths audited.** Every required named Phase172 product connection was traced through the consumer and resulting UI state.

#### WARNING / PARTIAL

- **OPUX-08 final delivery record not yet complete:** publication identity and final exact-source post-completion attestation/receipt remain parent-owned and in progress. Candidate and PR evidence must not be substituted for those final identities. This is a milestone bookkeeping/release boundary, not evidence of broken UI wiring.
- Preserve source-audit assumptions **A-03, A-04, A-06, A-07, A-08** as flagged manual edge-classification assumptions; the passing tests do not establish classifier completeness.
- Preserve the two descriptor-less prohibition fallbacks as **flagged-unverified**. No descriptor-based prohibition enforcement or human approval is claimed.
- No paid judge or human UAT was used. Contrast evidence reports AA zero failures with documented AAA advisories; non-contrast axe artifacts have their own disclosed findings/incomplete attachments.

### Requirements Integration Map

| Requirement | Integration path | Status | Issue |
|---|---|---|---|
| OPUX-01 | `OpsUi` roles → six LiveViews → rendered six-surface responsive matrix | WIRED | A-01 empty/setup and UTF-8 behavior resolved; AAA advisory findings remain documented. |
| OPUX-02 | `ops_schema_select` / Search controls and `ops_modal` → registered `OpsModal` hook → Playbooks upload/rename/delete handlers and restored focus | WIRED | Five-schema branch and lifecycle browser proof passed; no paid judge. |
| OPUX-03 | Control Room and Posture navigation → `OperatorSelection.path` → Failed Sync/Sync Drift and shared action hierarchy | WIRED | A-03 remains flagged; manual classifier completeness is not claimed. |
| OPUX-04 | allowlist resolution → encoded schema URL → LiveView params → back/reload and generation guards | WIRED | Journey evidence passes; A-04 remains flagged for completeness. |
| OPUX-05 | retry → accepted receipt → RecoveryObservation → DocumentObservation; PromotionEligibility → fresh server guard → exact task terminal result | WIRED | Unknown/stale/error paths do not claim success; A-05 resolved. |
| OPUX-06 | rendered Control Room→Posture→Failed Sync→Sync/Drift → exact queue/task/document assertions | WIRED | Deterministic journey passed; A-06 remains flagged beyond tested replay/stale cases. |
| OPUX-07 | source contracts → mounted/browser CI lane → artifacts/screenshots/contrast → hosted candidate | WIRED | Candidate proof passed; A-07 flagged; non-contrast axe notes remain disclosed. |
| OPUX-08 | evidence/source trace → candidate required CI → PR delivery/release publication → final exact-source attestation | PARTIAL | PR merges and candidate proof exist; publication/final tracking attestation receipt still pending. A-08 flagged. |

**Requirements with no cross-phase wiring:** None applicable. All OPUX requirements are assigned to this single Phase172; OPUX-01–07 have concrete internal module/runner connections. OPUX-08's remaining work is a downstream delivery/receipt connection, not a requirement with no integration touchpoint.

### Evidence boundary

This audit inspected source and the Phase172 summaries, draft verification, validation and evidence records in the requested worktree. It reused reported executions: product source `1b2287e`; corrected candidate `135517b` / run `37178388184` (hosted full 104, mounted 4, required jobs/coverage/attestation); PR #91 merge `3ad154a`; and supplied release PR #92 merge SHA. No tests were rerun. The verification draft appropriately remains non-final until parent-owned publication and final tracking attestation are recorded.

## Subsequent delivery reconciliation (parent, 2026-10-04)

The review above is preserved at its original cutoff. Release Please publication, live Hex/HexDocs/consumer checks and package/tag parity subsequently passed in run37181522723 at8dd20e8966acd17a4ef5acec653c00dc31faab49. All completion records are prepared before final source attestation; the final receipt stays external. This addendum supplies the later delivery facts without attributing them to the earlier independent reviewer.
