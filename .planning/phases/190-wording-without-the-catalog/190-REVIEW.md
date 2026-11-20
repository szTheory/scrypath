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
