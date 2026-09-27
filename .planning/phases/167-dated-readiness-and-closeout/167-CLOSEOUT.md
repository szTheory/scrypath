# Phase 167 closeout inventory

observed_at_utc: 2026-09-27T19:41:20Z
inspected_source_sha: 7714b3a7d53086b992982c9c174712fbbc287f40

This is a dated ownership observation, not final phase closeout. Presence and resource names alone do not establish task ownership. The selected source is the committed Plan 01 implementation; Plan 02 records are uncommitted at this observation, and Plan 03 plus normal GSD tracking and final exact-SHA attestation remain outstanding.

| Surface | Inspection/result | Ownership/debt disposition |
|---|---|---|
| branch/worktree | The existing `gsd/v1.38-cleanup-merged` checkout is used. `git worktree list` showed only the repository worktree; no Phase 167 worktree or branch was created. | Existing branch preserved; no task-owned branch/worktree cleanup. |
| generated outputs | Focused Python checks set `PYTHONDONTWRITEBYTECODE=1`; inspection found no Phase 167 generated repository output. | No plan-owned generated output remains. The pre-existing `.planning/research/.cache/` is unrelated and preserved. |
| temporary files | The task-owned RED harness and evidence files `/tmp/167-02-red.test.mjs`, `/tmp/167-02-red.out`, and `/tmp/167-02-tdd-red.json` were inspected and removed after recording the RED gate. | No identified Phase 167 temporary verification output remains. No other temporary path is claimed as task-owned. |
| services | No Phase 167 service or container was started. | No service cleanup is owned by this plan. |
| verification | Plan 01's 8 focused tests and complete evidence comparison passed; Plan 02's dated assessment/closeout checks are still pending at this observation. Plan 03 final tracking and exact-final-SHA attestation remain outstanding. | Open: Plan 02 validation and commit, later Plan 03 tracking, candidate/final source checks, and external attestation. No claim of phase closeout. |
| unrelated state | `.planning/research/.cache/` predates this phase. `.planning/milestone.lock` appeared after Plan 01 began and records the active Phase 167 GSD session. | Research cache preserved as unrelated. Active phase lock retained while the session runs. |

## Release and debt reconciliation

The release-reference mismatch is a bounded carry-forward, separate from accepted historical planning debt. At `mix.exs` the configured ExDoc `source_ref` is `v0.3.13`; the published GitHub release identity is `scrypath-v0.3.13`. `docs/releasing.md` describes Release Please creating `vX.Y.Z`, and its generic recovery references use the v-prefixed convention. ExDoc/source and recovery references therefore differ from the recorded published release tag. The publication and package parity receipts stand independently; this mismatch alone does not show publication failure. No source correction, retag, republish, or maintainer risk acceptance is recorded. Revisit with a release metadata/docs contract change or before a maintainer chooses to repair those references.

The three accepted archived planning debts remain separate and retained under the [v1.39 milestone audit](../../milestones/v1.39-MILESTONE-AUDIT.md#tech-debt-and-next-action): Phase 163's legacy `complete` status is NOT-VALIDATED under the current Nyquist contract; Phase 164 validation remains draft with `nyquist_compliant: false` and `wave_0_complete: false`; and Phase 164 summary frontmatter omits GATE-01/02/03 from `requirements_completed` despite archived verification and traceability. Their revisit triggers remain a separately scoped Nyquist reconciliation or an owner-led historical metadata reconciliation with fingerprint refresh. No archive is rewritten here.

Release identities remain distinct in the [evidence index](167-EVIDENCE.json): planning tag `v1.39`, its exact-SHA closeout receipt, public release `scrypath-v0.3.13`, and the Phase 166 local artifact each have separate sources and limits. The root Mint graph is fixed at 1.10.1, while the Phoenix consumer lock remains at affected Mint 1.9.3; the unresolved High advisory has no owner acceptance. These are evidence and disposition facts, not permission to alter dependencies within this phase.
