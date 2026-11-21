# Phase 190 Discussion Log

**Date:** 2026-11-20. **Mode:** pre-seeded for `gsd-autonomous --only 190`; decisions come from the v1.47 prep notes (A to D), the gap-pass notes (E, F, H) and the glossary rulings in V1.46-PREP D10, all written on 2026-11-19 and 2026-11-20. There was no new discussion and no fan-out; the upstream one already ran every role lens with an adversarial pass.

## Decided from prep and gap-pass notes

All structure, scope, guards and delivery rules in 190-CONTEXT.md transcribe those notes: the glossary-first order, the protected `operator.spec.ts` strings, the 28-file rename list and its exceptions, the `copy_rules.json` table and its single `ops-ui` test, the Cancel-focus assertion in the required lane, the exact-head `ci.yml` dispatch with baseline run 44689855947, no preview refresh and no `ui:review`, and two plans with neither evidence-only. Prep A's "batched yes on visible copy" is superseded by AGENTS.md (2026-11-19): no yes, a non-draft PR, squash on green.

## Choices the pre-seeding pass made (maintainer may veto any of them)

The notes left these to "discuss". Each was settled with the stricter literal reading of the glossary rules, then the principle of least surprise. A veto changes strings and one or two test lines, not the plan structure.

1. **Searchable effect sentence: "Not used for search yet."** (declared "Used for search", live "Not used for search"; label "Searchable fields" kept). Why: it keeps today's row structure (the old effect "Not searched yet." also repeated the live cell with "yet"), it reuses the glossary phrase so the table can require it exactly, and it adds no new consequence sentence to argue about. Alternative considered: a consequence sentence such as "Searches don't use it yet."; rejected as a new copy choice with no rule behind it.
2. **Filterable and Sortable rows unchanged.** Why: COPY-01's rule names only Searchable, and advisory specs pin the strings (`ui_iteration3.spec.ts:146`, `ui-preservation-states.ts:466`). Aligning them is deferred.
3. **Last succeeded forms: label "Last succeeded", sentence "Last succeeded: <time>.", "Meilisearch last succeeded", "Queue last succeeded", and "Showing the check that last succeeded below."** Why: the glossary phrase, already used by `posture_live.ex:707` and the CLI, and it keeps the label-above and time-below structure of the Control room. "The last complete observation is retained below" and "No successful observation recorded." are not "Last success" forms and stay.
4. **Pending versus Queued: aggregates say Pending.** "N jobs queued" becomes "N jobs pending", "Nothing queued, retrying or failed" becomes "Nothing pending, retrying or failed", and the promotion reason becomes "wait for pending sync work to finish". Why: the stricter literal reading (a count over a schema's work is an aggregate), and Search health already says "No pending, retrying or failed jobs." for the same thing. Cost, accepted: the line now reads "Pending, 1 job pending" because the status word already precedes it. "waiting" (Meilisearch task counts) is not a rule term and is untouched.
5. **Queue outcomes say queued, not accepted** (flash messages, recovery status label and copy, the Sync and index refresh sentence, one Help sentence). Why: the rule reserves "accepted" for a Meilisearch task, and "Retry queued" already exists as the receipt title. "Index swap accepted" and the Help sentences about Meilisearch accepting a request already conform and stay.
6. **Clear beside a retained observation is fixed in this phase** (v1.46 review item IN-02, text from the review) because COPY-01 includes the rule; IN-01 (Pending for a retry-only queue) is deferred as a product question.
7. **`Clear` gets a glossary entry** (the six COPY-01 names plus Clear) so the Clear rule has something to cite.
8. **Table key is `surfaces` (a list).** REQUIREMENTS lists `surface` but its own failure condition says "empty `surfaces`".
9. **The ops-ui path regex is extended** (`GLOSSARY.md`, `DESIGN.md`, `examples/scrypath_ecommerce/(e2e|lib|test|scripts)/`) rather than limiting the scan. Why: with squash-on-green and no human merge, a skipped guard means a red `main` after the merge. Cost: about 386 s of `ops-ui` on PRs that touch only those paths.
10. **A new ledger row, not an extension.** Why: a check that rides an existing job still counts against the budget (playbook S26). The count is recomputed from `main` at the time, because Phase 189 also adds a row.
11. **The "third destructive dialog" is pinned as it exists.** Only two destructive dialogs are `ops_modal`s; the saved-search delete is an inline form in a sheet. COPY-04 is satisfied by pinning the `ops_modal` default, the two real dialogs and the delete form's Cancel and Escape behaviour, not by redesigning it.
12. **The Cancel assertion uses the existing locator** ("Cancel index swap"), not a new one named "Cancel".
13. **The `aria-current` and title test goes in `ops_shell_contract_test.exs`** beside the four existing route tests, which do not cover the Control room.
14. **Row split, helper module and surface ids in the table are specified at the minimum level** (CONTEXT D-14); the planner may split rows further.
15. **On a red dispatch, compare against a dispatch on `main` first** because baseline 44689855947 predates seven merges.

## Asked of the maintainer

None. No scope, authority, risk or cost question remained open. Nothing needs an answer before the run; vetoes can be applied afterwards.

## Deferred

See the Deferred Ideas section of 190-CONTEXT.md, and the Open contradictions section there for nine places where the upstream wording and the repository disagree, each with the default used.
