---
phase: 190-wording-without-the-catalog
reviewed: 2026-11-20T21:55:00Z
depth: standard
files_reviewed: 49
files_reviewed_list:
  - .github/workflows/ci.yml
  - CONTRIBUTING.md
  - DESIGN.md
  - GLOSSARY.md
  - examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts
  - examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts
  - examples/scrypath_ecommerce/e2e/admin_screenshots.spec.ts
  - examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts
  - examples/scrypath_ecommerce/e2e/admin_shell_wash.spec.ts
  - examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts
  - examples/scrypath_ecommerce/e2e/helpers/ui-preservation-states.ts
  - examples/scrypath_ecommerce/e2e/operator.spec.ts
  - examples/scrypath_ecommerce/e2e/ops_reskin_contract.spec.ts
  - examples/scrypath_ecommerce/e2e/phase1_screens.spec.ts
  - examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs
  - examples/scrypath_ecommerce/e2e/ui_routes_preservation.spec.ts
  - examples/scrypath_ecommerce/lib/mix/tasks/scrypath.demo.seed.ex
  - examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/page_controller_test.exs
  - scripts/ci/ui_preservation.test.cjs
  - scrypath_ops/assets/css/DESIGN-TOKENS.md
  - scrypath_ops/assets/css/app.css
  - scrypath_ops/docs/operator-ia.md
  - scrypath_ops/lib/scrypath_ops/posture.ex
  - scrypath_ops/lib/scrypath_ops_web/components/layouts.ex
  - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
  - scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/help_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
  - scrypath_ops/test/scrypath_ops_web/copy_rules_contract_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/search_saved_searches_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/modal_focus_contract_test.exs
  - scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs
  - scrypath_ops/test/scrypath_ops_web/reskin_component_contract_test.exs
  - scrypath_ops/test/scrypath_ops_web/router_test.exs
  - scrypath_ops/test/support/copy_rules.ex
  - scrypath_ops/test/support/copy_rules.json
  - scrypath_ops/test/support/copy_stubs/control_room.ex
  - scrypath_ops/test/support/copy_stubs/failed_sync.ex
  - scrypath_ops/test/support/copy_stubs/oban_job.ex
  - scrypath_ops/test/support/copy_stubs/posture.ex
  - scrypath_ops/test/support/copy_stubs/sync_drift.ex
  - scrypath_ops/test/support/copy_surfaces.ex
  - test/mix/tasks/workflow_wiring_test.exs
findings:
  critical: 0
  warning: 5
  info: 3
  total: 8
  necessity: 1
status: issues_found
---

# Phase 190: Code Review Report

**Reviewed:** 2026-11-20T21:55:00Z
**Depth:** standard
**Files Reviewed:** 49
**Status:** issues_found

## Summary

Reviewed the phase 190 source diff against `origin/main` (HEAD `f7d59f1c`, `.planning/` excluded): the ScrypathOps wording changes, the "Control room" casing rename, the copy rules table with its helper, surfaces and stubs, the Cancel-focus pin, the `ops-ui-path` regex and its wiring test, and the ledger row. Cheap checks run locally: the whole `scrypath_ops` suite twice (546 tests plus 2 doctests, seeds random and 0, 0 failures), the new contract tests, the root `workflow_wiring_test.exs` (89 tests, 0 failures), `mix format --check-formatted` in `scrypath_ops` and for the wiring test, and a forced test-env compile of `scrypath_ops` with no warnings. I also rendered the retained, degraded and retry surfaces and probed the table helper with phrase variants (scratch files outside the repo). No source files were modified.

There are no critical findings. The rename is the one-word case change and nothing else in the renamed files (word-level diff of the e2e, demo, script, doc and CSS files: `Room` to `room` only, plus the one Cancel-focus line; the lib diffs read the same); the `layouts.ex` nav title, `ControlRoomLive` page title and the command-palette label agree, the `admin_shell_chrome.spec.ts` map key and surface name moved together, no snapshot baselines or manifests quote the label, and `git grep "Control Room"` outside `.planning/` now hits only the table's own forbidden literal. `test/support` is compiled only in `:test` (`elixirc_paths`), the namespace fence has no `Sigra.` references left in `scrypath_ops/test`, no test was dropped from the four refactored LiveView test files, and the stubs restore their environment in `after`.

The defects are in how the new strings read in one state, in the reach of the PR-time guard, and in how tight the table is. The most visible: a retained degraded observation on the Control room now reads "Last succeeded" above a failure headline and has lost its Failed word (WR-01). The table passes today but would not catch a reword of the retry flash, wrapped phrases, or several plain variants of the forbidden words (WR-03, WR-04), the `ops-ui-path` fix leaves the files that actually carry the label outside the pattern and the wiring test pins that (WR-02), and one refute that D-17 meant to remove survived as a vacuous assertion (WR-05).

Checked and found sound: the Cancel-focus line sits where D-21 puts it (after the dialog is visible and before the `close.focus()` Tab-order checks, with nothing between that moves focus, and Playwright retries it); the wiring test has a real negative control for the new alternatives; every `source_scope` glob matches tracked files (`unmatched_scopes`) and the empty-list case raises; the 17 promotion sentences are pinned against the rendered notice element only; the `/ops` shell test would fail if the nav title and page title diverged.

## Warnings

### WR-01: A retained degraded Control room observation reads "Last succeeded" above a failure and loses its Failed word

**File:** `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex:143-150`
**Issue:** D-06 sets `status` to `nil` whenever `@refresh_issue` is set, which hides every status word, not only the `Clear` the glossary rule is about. `complete_observation?/1` accepts `:degraded` summaries, so a first check that found failed work and a later refresh that fails keeps the degraded posture on screen. Rendered through the real LiveView (scratch probe):

- before the failed refresh: `Failed 1 Meilisearch task failed ScrypathOps.Test.OpsPostA ...`
- after: `Last succeeded 1 Meilisearch task failed ScrypathOps.Test.OpsPostA ... Last succeeded: <time>.` with `data-verdict-kind="error"` and no `[data-sync-status]`.

Two things follow. The label "Last succeeded" (previously "Last successful observation") no longer says what is retained, so it now sits directly above a failure headline and reads as if the failure was the last success. It is also not beside a time, which the new GLOSSARY entry says it must be (the time is in a paragraph below the action link). And the verdict keeps the Failed error rule but drops the Failed word, which `ops_sync_status/1` documents as the accessible text and the non-colour cue ("the status reads without color"). The new test (`control_room_live_test.exs`, "a retained or partial observation shows no status word") only covers the healthy retained case, so this passes.
**Fix:** Drop only `Clear` beside a retained observation, and name what is retained in the label:

```elixir
status={verdict_status(@posture, @refresh_issue)}
label={
  cond do
    @refresh_issue && @last_successful_posture -> "Last check that succeeded"
    ...
  end
}

defp verdict_status(%Posture{rows: rows}, nil), do: Posture.worst_status(rows)

defp verdict_status(%Posture{rows: rows}, _refresh_issue) do
  case Posture.worst_status(rows) do
    :clear -> nil
    status -> status
  end
end
```

Add a retained-degraded case beside the healthy one (a failed Meilisearch task in the first check, then `:unavailable`): the Failed word is still there, the label is not a bare "Last succeeded", and `Clear` is absent.

### WR-02: The `ops-ui-path` pattern leaves out most of the files the whole-tree scan reads, and the wiring test pins that

**File:** `.github/workflows/ci.yml:375`, `test/mix/tasks/workflow_wiring_test.exs:1643-1652`
**Issue:** The `control-room-casing` row scans every tracked file (`source_scope: ["**"]`) but the pattern only gains `GLOSSARY.md`, `DESIGN.md` and four demo subdirectories (`e2e`, `lib`, `test`, `scripts`). Tracked files that legitimately carry the label and are outside the pattern: `README.md`, `docs/local-demo-docker-dx.md`, `examples/scrypath_ecommerce/README.md`, `examples/scrypath_ecommerce/Makefile`, `examples/scrypath_ecommerce/docker-entrypoint.sh`, `examples/scrypath_ecommerce/docs/local-demo-docker-dx.md`. Also outside: `website/`, `guides/`, root `test/`, and every other `.github/workflows/*` file. A PR that edits any of these back to title case skips `ops-ui`, is squash-merged on green with no human, and fails on the push run to `main`. That is the failure D-18 says the regex exists to prevent, and the website refresh the owner has queued is a likely source (marketing headings are often title case). The wiring test does not just leave this uncovered: it asserts that `README.md` and `website/src/index.html` do NOT match (lines 1643-1644), so closing the gap means editing a test that reads as a requirement. Line 1652 (`assert pattern =~ new_alternatives`) also pins the exact spelling of the new alternatives, so any edit inside that group fails with a message that does not say why. The "what this does not prove" record accepts the partial coverage, but the cost argument (386 s) is made for the demo's `e2e` specs, and the demo's own README, Makefile and docs are in the same directory.
**Fix:** Cover the directories the label lives in, or move the whole-tree casing scan to a lane that always runs:

```
...|GLOSSARY\.md|DESIGN\.md|README\.md|docs/|guides/|website/|examples/scrypath_ecommerce/
```

Then change the "does not match" probe to a path that is genuinely irrelevant (for example `prompts/elixir-best-practices-deep-research.md`), and make the negative control derive the narrowed pattern from a list of the new alternatives rather than one concatenated string.

### WR-03: Table matching is single-space literal, so a wrapped phrase passes both the static scan and the rendered check

**File:** `scrypath_ops/test/support/copy_rules.ex:484-487` (`compile/1`), applied by `scan_source/3` and `evaluate_surface/3`
**Issue:** `literal` entries are `Regex.escape/1`d and matched against raw text; the static scan reads source with its line breaks and the rendered check reads raw HTML, where a HEEx text node keeps its newline and indentation. Probed with the real helper (all MISSED): `"Retry\n   accepted"` against `retry-queued-not-accepted`, `"Last\n  success"` against `last-succeeded`, `"Control\n Room"` against `control-room-casing`. Hand-wrapped HEEx text exists in this code base (`control_room_live.ex:159-161` splits a sentence across lines), so this is a normal edit, not a contrived one. A `required` phrase has the same problem in the other direction: a reflowed sentence fails the row for a reason that has nothing to do with the wording.
**Fix:** Collapse whitespace on both sides before matching, keeping a byte-offset map for the static scan's line numbers (or scan a whitespace-normalised copy and report the first line of the match):

```elixir
defp normalise(text), do: Regex.replace(~r/\s+/u, text, " ")
```

Apply it to `html` in `evaluate_surface/3` and `check_surface/4`, and to the text in `scan_source/3`. Add a planted case to the contract test (a forbidden phrase split by `"\n    "` is caught).

### WR-04: The forbidden lists are narrower than the glossary's own Avoid lists, and the retry flash is not positively pinned

**File:** `scrypath_ops/test/support/copy_rules.json:92-96, 146-152, 21-23`
**Issue:** Probed with the helper (all MISSED, so a copy edit using them passes every row):

- `pending-aggregate`: `"2 queued jobs"`, `"3 queued"`, `"2 jobs are queued"`, `"Nothing is queued"` (only `jobs? queued`, `Nothing queued` and `queued work` are listed). The glossary says queued is not for a count over a row or a schema.
- `retry-queued-not-accepted` (the static scan of lib; the rendered retry surfaces are covered by the broader `accept(ed|ance)` row): `"Queue accepted this retry"` (the literal needs a leading "The"), `"The retry was accepted"`, `"Accepted retry"`. "Retry sent", which the glossary lists under Avoid for Retry queued, is not forbidden anywhere.
- `searchable-observation-only`: lower-case `"not searchable"` (the literals are case-sensitive).
- Glossary Avoid entries `Healthy` and `All good` (for Clear) have no row.

Related: the Q-2 flash `Retry queued · queue job N` is not guarded by any positive assertion. The row's `required` `Retry queued` is also satisfied by the pre-existing receipt title (`failed_sync_live.ex:1137`), and `\bqueued\b` in `queued-host-queue-outcome` is satisfied by either. Rewording the flash to `Retry sent · queue job 991` in the rendered `failed_sync.after_retry` surface produces zero violations (scratch probe); the only pin for the real string is the `already queued` flash assertion in `failed_sync_live_test.exs`, which covers Q-1, not Q-2.
**Fix:** Make the forbidden entries regexes that cover the variants (`\bqueued\s+jobs?\b`, `\d+\s+queued\b`, `\b(the\s+)?queue\s+accepted\b`, `\baccepted\s+retry\b`, `\bretry\s+(was\s+)?(accepted|sent)\b`, case-insensitive `not\s+searchable`), and require the flash text itself on `failed_sync.after_retry` (add a `retry-queued-flash` row requiring `Retry queued · queue job \d+`). Keep each addition paired with a planted accept and reject case.

### WR-05: The "dash placeholder" refute in the posture test can never fail

**File:** `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs:631`
**Issue:** D-17 replaced vacuous old-string refutes with assert-new plus a refute of the new label with a dash placeholder. The surviving line is `refute failed_row =~ ~r/last succeeded<\/dt>\s*<dd>\s*—/`. Nothing renders a dash there: `ops_time/1` only calls `human_dt/2` (the one place that returns `"—"`) when `exact` is truthy, and the retained row's `<dd>` starts with `<span id="posture-time-retained-...">` directly. Rendered through the real route, the retained row contains no `—` at all (scratch probe: `DASH-IN-ROW: false`). The original `"Last success</dt><dd>—"` was vacuous for the same reason, so the rewrite kept a negative assertion that proves nothing, which is the pattern D-17 set out to remove. The two `assert ... last succeeded` lines above it do guard the new wording, so coverage of the string is intact; only this line is dead.
**Fix:** Delete the line, or replace it with something the page can actually violate, such as asserting the retained time element is present for both sources: `assert has_element?(lv, "#{row_selector} dt", "Meilisearch last succeeded")` followed by a check that the `<dd>` holds a `time` or the retained-text span.

## Info

### IN-01: The promotion block and the queue line say "pending" for a retrying-only queue, and the Pending word now repeats

**File:** `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1560, 1653`
**Issue:** `queue_pending?/1` in `promotion_eligibility.ex:135-138` returns true for pending OR retrying jobs, so a queue holding only scheduled retries is blocked with "Wait for pending sync work to finish." although Retrying is its own status word in the glossary and on Search health. This is the IN-01 case from the 187 review that D-08 consciously deferred; the new wording makes it slightly more visible. Separately, the queue line now renders as "Pending 1 job pending, 1 scheduled retry" (status word plus count, confirmed by render), which D-08 accepted as the literal result of the rule. Neither is a regression against the stated decisions.
**Fix:** When IN-01 is taken up: say "Wait for queued sync work to finish" only for the promotion block, or split `:queue_work_pending` into pending and retrying reasons; and let the count line drop its own "pending" suffix when the Pending status word precedes it.

### IN-02: `DESIGN-TOKENS.md` still says the Control room always derives its status from the worst row

**File:** `scrypath_ops/assets/css/DESIGN-TOKENS.md:225`
**Issue:** The `ops_verdict` row says the Control room and Search health "derive both from the worst row". After D-06 the Control room passes no status while a refresh issue is showing, so the doc and the code disagree. If WR-01 is applied the doc should say "except that a retained or partial observation never shows `Clear`".
**Fix:** Add that sentence to the row in the same change as the WR-01 fix.

### IN-03: Two table requirements cannot fail independently of another entry

**File:** `scrypath_ops/test/support/copy_rules.json:36-38, 185-195`
**Category:** necessity
**Issue:** The `searchable-settings-row` requirement `Not used for search` is contained in the required `Not used for search yet.` on the same surface, so the first can only fail when the second already fails. The `queued-host-queue-outcome` requirement `\bqueued\b` (case-insensitive) is contained in `Retry queued`, which `retry-queued-not-accepted` requires on the same two surfaces; on `sync_drift.recovery_queued` it is also satisfied by "observes the queued retry" in the always-visible section copy. Proven from the table itself, not judgment, but the `queued-host-queue-outcome` row has a purpose (the Status wording self-check needs a row that cites the Queued term), so this is not a removal request.
**Fix:** Drop the redundant `Not used for search` entry, and give `queued-host-queue-outcome` a requirement it alone carries (for example the flash pattern in WR-04) so it guards something the other row does not.

---

_Reviewed: 2026-11-20T21:55:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

---

## Fix disposition

**Fixed:** 2026-11-20, by the code fixer (`gsd-code-fixer`), directly in the main checkout on `gsd/phase-190-wording-without-the-catalog` (no worktree). In scope: WR-01, WR-03, WR-04, WR-05 and IN-02. Deferred: WR-02, IN-01 and IN-03. `190-VERIFICATION.md` had reproduced WR-01, WR-03, WR-04 and WR-05 independently. Every fix has a test that fails against the old code and passes against the new code; each red run was observed, not assumed.

| Finding | Status | Commit |
|---------|--------|--------|
| WR-01 | fixed | `ac177aaf` |
| IN-02 | fixed (same commit as WR-01, as the review asked) | `ac177aaf` |
| WR-03 | fixed | `ef5c6803` |
| WR-04 | fixed | `c4bee791` |
| WR-05 | fixed | `953e5dcf` |
| WR-02 | deferred, accepted trade (below) | none |
| IN-01 | deferred | none |
| IN-03 | deferred (necessity finding, outside the requested scope) | none |

### WR-01: fixed, requires human verification of the label call

`control_room_live.ex` now drops only the `Clear` word while a refresh issue is showing (`verdict_status/2`); `Failed`, `Retrying` and `Pending` still read. A retained degraded observation renders `Failed` in the error rule again. Test: `control_room_live_test.exs`, "a retained degraded observation keeps its Failed word and never reads Clear" (a failed Meilisearch task in the first check, then `:unavailable`); it failed on the second `Failed` assertion before the change. The copy table gained a surface `control_room.refresh_retained_degraded` (cited by `clear-needs-observation` and `last-succeeded`, so `Clear` stays forbidden and `Last succeeded` stays required there) and a row `clear-needs-observation--failed-word-kept` that requires the status word's own element (`ops-sync-status__word">Failed</span>`). The row keys on the element, not the bare word, because the nav link `Failed sync work` puts `Failed` on every page. Its planted accept and reject cases are in `copy_rules_contract_test.exs`. The degraded fixture moved from the LiveView test into `copy_stubs/control_room.ex` (`put_degraded_posture!/0`), so the test and the surface share one definition.

Label call: the label stays `Last succeeded` (the pre-seed wording; the glossary forbids only `Last success` and `Last successful`). It is not false in the degraded state: the retained observation is the last check that completed, and it found failed work. With the `Failed` word back on the headline line below it, it no longer reads as if the failure were the last success. The review's alternative, `Last check that succeeded`, is a one-string change plus the test pin if the maintainer prefers it; the paragraph below the verdict keeps `Last succeeded: <time>`, so the `last-succeeded` row would still be satisfied. The label is still not beside a time (the time is in the paragraph below the action link); that is also true of the healthy retained case and was not changed.

### IN-02: fixed

`DESIGN-TOKENS.md` (the `ops_verdict` row) now says the Control room and Search health derive status from the worst row, with one exception: while a refresh issue is showing, the Control room drops `Clear` and keeps `Failed`, `Retrying` and `Pending`.

### WR-03: fixed

`copy_rules.ex` collapses every run of whitespace (including newlines and tabs) to one space on the text and on `allowed_in` phrases before matching, for the static scan and the rendered check, and for the state-anchor check. The static scan maps each match back to the original file and reports the line where the match starts. Planted cases (source and rendered) for `Retry\n   accepted`, `Last\n  success` and `Control\n Room` fail before the change and pass after it, with accept cases for a reflowed required phrase, a wrapped `allowed_in` phrase, a tab and blank-line run, and words on one line that only look alike. The whole-tree scan and the lib scans found no false positive from collapsing whitespace.

### WR-04: fixed

Added to the forbidden lists (existing entries kept, nothing removed or loosened):

- `pending-aggregate`: `\bqueued\s+jobs?\b`, `\d+\s+queued\b`, `\bjobs?\s+(is|are|was|were)\s+queued\b`, `\bnothing\s+(is\s+)?queued\b`.
- `retry-queued-not-accepted`: `\bqueue\s+accepted\b`, `\baccepted\s+retry\b`, `\bretry\s+(was\s+|is\s+)?(accepted|sent)\b` (this also puts the glossary's own Avoid term `Retry sent` under a rule).
- `searchable-observation-only`: `\bnot\s+searchable\b` and `\bnot\s+searched\s+yet\b`, case-insensitive.
- New row `clear-not-healthy` (the glossary's Avoid terms for Clear): `\bHealthy\b` (case-sensitive) and `\ball\s+good\b`, scoped to `scrypath_ops/lib/**` and the surfaces where Clear is shown: new surface `control_room.healthy` (a healthy first check), `control_room.refresh_retained`, `posture.default` and `sync_drift.caught_up`.
- New row `retry-queued-not-accepted--flash`: requires `Retry queued · queue job \d+` on `failed_sync.after_retry`, so the Q-2 flash is pinned by a positive assertion. Mutation check: rewording the flash in `failed_sync_live.ex` to `Retry sent · queue job N` now fails three ways (static scan of `failed_sync_live.ex:351`, the forbidden `Retry sent` on the surface, and the missing flash text); the edit was reverted.

One variant legitimately occurs in the tree: `lib/scrypath_ops/recovery_observation.ex:3` says "an accepted retry" in a developer `@moduledoc`. `retry-queued-not-accepted` excuses that exact phrase with `allowed_in` (`correlation of an accepted retry with its own Meilisearch task`); a stray `accepted retry` elsewhere still fails, and a planted test proves both. Lower-case `healthy` is not forbidden: it appears in developer comments (`posture.ex`, `ops_ui.ex`) and in a fixture scenario value (`posture_live.ex:255`), so the table's `not_covered` list now says so. The helper reports a hit once when two entries match the same span or one span lies inside another (a literal and the regex that widens it), which the old planted tests needed once the lists overlapped. `Retry sent` was one of the existing test's expectations (only `required_missing`); it now also expects the forbidden hit.

The table is now 17 rows and 16 registered surfaces (it was 14 and 14).

### WR-05: fixed

The refute of a dash placeholder in `posture_live_test.exs` is replaced by two assertions that can fail: each retained `last succeeded` label (`Meilisearch last succeeded`, `Queue last succeeded`) sits beside the retained time element of its own source (`posture-time-retained-backend-...`, `posture-time-retained-queue-...`). Mutation check: renaming the element id in `posture_live.ex` makes the test fail; the edit was reverted. The old-label guard for this surface is the `last-succeeded--absence` table row, as before.

### WR-02: deferred (accepted trade, not fixed)

The `ops-ui-path` regex deliberately omits `README.md`, the root docs, `guides/`, `website/` and the demo's `README.md`, `Makefile` and `docs/`. This is the D-18 / D-19 economy: a docs-only PR skips `ops-ui` (the 386 s measurement in `CI-EFFICIENCY.md` finding 12), and the whole-tree `control-room-casing` scan still runs on every push to `main`. The cost: a PR that edits only an omitted path back to title case can merge on green and turn `main` red on the push run, which the wiring test also pins by asserting that `README.md` and the website index do not match. Widening the pattern would also change the wiring test's "does not match" probes, so it is a maintainer cost decision and not a code-fixer change. **Revisit trigger:** reconsider before the website refresh (SEED-004) starts, or the first time the push-to-`main` scan goes red for a docs-only change, whichever comes first. If it is reopened, the review's suggested alternatives are to add the directories the label lives in to the pattern, or to move the whole-tree casing scan to a lane that always runs.

### IN-01: deferred

Unchanged from D-08: a retrying-only queue reads "pending" in the promotion block and the Pending word repeats on the queue line. Fixing it means changing `promotion_eligibility.ex` or splitting `:queue_work_pending`, which is outside this phase's wording scope. Take it up with the 187 IN-01 item.

### IN-03: deferred

A necessity finding: two table requirements that cannot fail independently of another entry. Removing code is a scope decision for the maintainer, and the finding itself says it is not a removal request. Not applied. (The new `retry-queued-not-accepted--flash` row gives the retry surfaces a requirement of their own, but `queued-host-queue-outcome` was left as it is.)

### Checks run

Cheap checks only, in the main checkout (no worktree was created, so these numbers are reproducible from the tree you are looking at):

- `cd scrypath_ops && MIX_ENV=test mix test`, whole suite, run on a random seed and on `--seed 0`: 2 doctests, 553 tests (was 546; seven new tests), 0 failures both times.
- `MIX_ENV=test mix compile --warnings-as-errors --force` in `scrypath_ops`: exit 0, no warnings.
- `mix format --check-formatted` at the repository root and in `scrypath_ops`: clean.
- `mix test test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/verify_namespace_fence_test.exs` at the root: 92 tests, 0 failures.
- `git grep -o 'Control Room' -- . ':!.planning' ':!brand' ':!scrypath_ops/test/support/copy_rules.json'`: no output, exit 1.

Not run, by the orchestrator's decision: `mix verify.repository_contracts`, `mix verify.core`, the CI Node step, any Docker or Playwright lane. The four fix commits change files outside `.planning/`, so `190-GATE-RECEIPT.md` (which names `f6c78bd2`) no longer covers the branch head; the hosted required checks on the pushed head are the gate for this fix.
