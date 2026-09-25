---
status: diagnosed
trigger: "Diagnose UAT gap G-160-9: 160-03-SUMMARY.md declares actuals.commits: 1 with plan_head_before 7931271abe53e83261d85a22077176f75898eb81, but its add commit precedes that base. Determine root cause and whether the blocker is warranted."
created: 2026-09-24T19:58:39Z
updated: 2026-09-24T20:02:35Z
---

## Current Focus
<!-- OVERWRITE on each update - reflects NOW -->

hypothesis: Confirmed: commit 16082ca rewrote `plan_head_before` from the original d7b499b base to 7931271 without reconciling the summary's creation-boundary accounting; 7931271 descends from the summary's creation commit 3b2cd31.
test: Compare the summary as created with its current form; inspect the complete ancestry and path presence at d7b499b, bc2bcc3, 3b2cd31, 7931271, and 16082ca.
expecting: The original metadata will name d7b499b and `git log --diff-filter=A d7b499b..3b2cd31 -- SUMMARY` will produce exactly 3b2cd31, while 7931271 will contain the summary and 16082ca will be only a modification.
next_action: Return the diagnosis: the gate is warranted for the current declared measurement, while the historical task-commit evidence is separately identifiable and must not be rewritten.
bug_class: bohrbug
candidate_causes:
  - "code/process: post-correction metadata refresh copied the corrected CI candidate into plan_head_before although that field must remain the plan execution baseline for summary-add accounting."
  - "data: the existing summary's `commits: 1` and task-commit record were retained while its base field was changed, creating an incompatible tuple."
and_gate: "no — changing the recorded plan base after the add commit alone makes the required post-base add measurement impossible; retained count metadata describes the inconsistency but is not independently required to trigger it."

## Symptoms
<!-- Written during gathering, then IMMUTABLE -->

expected: The 160-03 summary's declared commit count has one unambiguous SUMMARY-add boundary after its recorded plan base.
actual: The summary claims actuals.commits: 1 and records plan_head_before 7931271abe53e83261d85a22077176f75898eb81; the add-only path log from that base through HEAD returns no commit. The summary is present at the base; it was added in 3b2cd31244eab55440d36ee3c4fa6d77fb48b835 and later modified by 16082caf318cb99b45a4fb8571988bf169c548ae.
errors: "G-160-9: required add-only log after plan_head_before returns no add commit"
reproduction: "git log --reverse --diff-filter=A --format='%H' 7931271abe53e83261d85a22077176f75898eb81..HEAD -- .planning/phases/160-package-backed-phoenix-proof/160-03-SUMMARY.md"
started: "Historical record as of HEAD c630e053a02d2c653808a3e6ce8aadb522c9a794"

## Eliminated
<!-- APPEND only - prevents re-investigating -->

## Evidence
<!-- APPEND only - facts discovered -->

- timestamp: 2026-09-24T19:58:39Z
  checked: "add-only and follow history for 160-03-SUMMARY.md"
  found: "No add commit exists in 7931271..HEAD; the path was added in 3b2cd31 (parent bc2bcc3) and modified in 16082ca (parent 7931271)."
  implication: "The reported empty result is deterministic and can be explained by the recorded base being after the path's creation."
- timestamp: 2026-09-24T19:58:39Z
  checked: "knowledge-base and MemPalace availability"
  found: "No .planning/debug/knowledge-base.md existed; no prior matching local resolution was available."
  implication: "No known-pattern candidate applies; investigate the repository history directly."
- timestamp: 2026-09-24T19:58:39Z
  checked: "test-suite applicability"
  found: "This is a deterministic historical-artifact gate; no failing/passing executable test pair or per-test coverage applies."
  implication: "SBFL is skipped as inapplicable; git-history differential analysis is the routed Bohrbug technique."
- timestamp: 2026-09-24T20:02:11Z
  checked: "tree presence and ancestry across the original and rewritten bounds"
  found: "The summary is absent at bc2bcc3's parent and added by 3b2cd31. The original summary recorded plan_head_before d7b499b; d7b499b..3b2cd31 contains exactly bc2bcc3 then 3b2cd31, and the only SUMMARY add is 3b2cd31. 3b2cd31 is an ancestor of 7931271, so the summary is present at the current base."
  implication: "The original execution record had a unique add boundary after its original base; the later recorded base cannot serve that measurement."
- timestamp: 2026-09-24T20:02:11Z
  checked: "16082ca path diff and current summary metadata"
  found: "16082ca has parent 7931271 and modifies 160-03-SUMMARY.md (12 insertions, 10 deletions). Its diff changes plan_head_before from d7b499b to 7931271 but retains `actuals.commits: 1`, `commits: 1`, `key-files.created`, and the task commit bc2bcc3."
  implication: "The defect is a stale/incompatible measurement boundary introduced during the corrected-evidence refresh, not a missing task commit or an ambiguous graph."

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: "Commit 16082caf318cb99b45a4fb8571988bf169c548ae replaced 160-03-SUMMARY.md's original plan execution base (`d7b499b93d9ebcc4c84b16c316266fa524dfc61a`) with the later corrected CI candidate (`7931271abe53e83261d85a22077176f75898eb81`). Because 7931271 descends from the summary-add commit 3b2cd31244eab55440d36ee3c4fa6d77fb48b835, the current base already contains the summary, so its declared one-add-commit measurement has no possible post-base add boundary."
fix: "Diagnose only. Preserve the history; a subsequent reconciliation should restore a metadata model whose stated base and claimed count refer to the same bounded interval, with a mechanically auditable boundary."
verification: "Reproduced the required current-base add-only query: zero results. Independently established that 3b2cd31 is the unique add after the original recorded d7b499b base and that it precedes current base 7931271. The UAT blocker is warranted for the current declared truth, but it does not negate the separately recorded task commit bc2bcc3."
files_changed: []
