# Phase 167 closeout inventory

observed_at_utc: 2026-09-27T19:22:00Z  
inspected_source_sha: 8ed596a7ef2e6c63d175be3850db6fe3ad60ee66

This inventory is a dated ownership observation. It records the Phase 167 execution environment without treating presence or a resource name as ownership proof. The release-reference mismatch remains a bounded carry-forward: `mix.exs` and `docs/releasing.md` contain the identified disagreement, with no publication or compatibility failure established. Revisit if release metadata or adopter-facing instructions become decision-relevant. The accepted v1.39 planning metadata debt remains governed by the [v1.39 milestone audit](../../milestones/v1.39-MILESTONE-AUDIT.md); this record does not silently reopen or erase it.

| Surface | Inspection/result | Ownership/debt disposition |
|---|---|---|
| branch/worktree | `gsd/v1.38-cleanup-merged` is the existing checkout; `git worktree list` shows only the repository worktree. No Phase 167 worktree was created. | Existing branch preserved; no task-owned branch/worktree cleanup. |
| generated outputs | Focused Python checks use `PYTHONDONTWRITEBYTECODE=1`; no generated repository output was created by this plan. | No plan-owned generated output remains. The research cache is unrelated existing local state and is preserved. |
| temporary files | Test fixture directories self-clean. The temporary TDD RED harness and evidence under `/tmp/167-02-*` are Phase 167-owned and scheduled for removal after validation. | Temporary verification evidence is transient; remove after its RED gate has been recorded. |
| services | No Phase 167 service or container was started. | No service cleanup is owned by this plan. |
| verification | Plan 01 evidence checks passed. This first record still awaits Task 2's complete source review and final record checks; final tracking and exact-final-SHA attestation are later Phase 167 work. | Open: Task 2 reassessment and final-source attestation; no claim of phase closeout. |
| unrelated state | `.planning/research/.cache/` predates this plan. `.planning/milestone.lock` records the active Phase 167 session and remains in use. | Cache preserved as unrelated. Active phase lock retained until the GSD session closes. |

Release identities remain distinct: planning tag `v1.39`, its exact-SHA closeout receipt, public release `scrypath-v0.3.13`, and the Phase 166 local build artifact each retain their own canonical source in [the evidence index](167-EVIDENCE.json). The observed source/docs reference mismatch and the accepted archived planning debt are separate dispositions. No version bump, retag, publication, or historical edit is made here.
