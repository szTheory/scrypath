---
phase: 197-pilot-job-03-unhealthy-verdict-to-verified-retry
reviewed: 2026-11-22T12:45:00Z
depth: deep
files_reviewed: 52
files_reviewed_list:
  - scrypath_ops/lib/scrypath_ops/failed_sync_view.ex
  - scrypath_ops/lib/scrypath_ops/failed_sync_view/row.ex
  - scrypath_ops/lib/scrypath_ops/posture.ex
  - scrypath_ops/lib/scrypath_ops/recovery_view.ex
  - scrypath_ops/lib/scrypath_ops/recovery_view/document.ex
  - scrypath_ops/lib/scrypath_ops_web/components/failed_sync.ex
  - scrypath_ops/lib/scrypath_ops_web/components/recovery.ex
  - scrypath_ops/lib/scrypath_ops_web/components/search_health.ex
  - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex
  - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
  - scrypath_ops/catalog/lib/mix/tasks/scrypath_ops.catalog.serve.ex
  - scrypath_ops/catalog/lib/scrypath_ops/catalog/endpoint.ex
  - scrypath_ops/catalog/lib/scrypath_ops/catalog/router.ex
  - scrypath_ops/config/dev.exs
  - scrypath_ops/assets/js/storybook.js
  - scrypath_ops/storybook/_start.index.exs
  - scrypath_ops/storybook/welcome.story.exs
  - scrypath_ops/storybook/areas/document_freshness.story.exs
  - scrypath_ops/storybook/areas/failed_row.story.exs
  - scrypath_ops/storybook/areas/failed_summary.story.exs
  - scrypath_ops/storybook/areas/health_schema_row.story.exs
  - scrypath_ops/storybook/areas/health_verdict.story.exs
  - scrypath_ops/storybook/areas/recovery_status.story.exs
  - scrypath_ops/storybook/jobs/job_03_on_call_recovers_failed_sync.story.exs
  - scrypath_ops/storybook/patterns/delete_confirmation.story.exs
  - scrypath_ops/storybook/patterns/failed_filters.story.exs
  - scrypath_ops/storybook/patterns/retry_receipt.story.exs
  - scrypath_ops/storybook/surfaces/failed_sync.story.exs
  - scrypath_ops/storybook/surfaces/search_health.story.exs
  - scrypath_ops/test/support/catalog_checks.ex
  - scrypath_ops/test/support/catalog_render_all.ex
  - scrypath_ops/test/support/copy_surfaces.ex
  - scrypath_ops/test/support/copy_rules.json
  - scrypath_ops/test/support/html_canon.ex
  - scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/operator_ia_contract_test.exs
  - scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs
  - fixtures/scrypath_fixtures/lib/scrypath_fixtures/shopadelic/product.ex
  - examples/scrypath_ecommerce/e2e/ui-review.mjs
  - examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs
  - examples/scrypath_ecommerce/e2e/catalog-fidelity-probe.mjs
  - examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh
  - test/mix/tasks/dependency_boundary_contract_test.exs
  - test/release/ops_dependency_boundary_test.exs
  - test/release/shipped_docs_contract_test.exs
  - test/support/release/shipped_docs.ex
findings:
  critical: 0
  warning: 4
  info: 9
  total: 13
  necessity: 0
status: issues_found
---

# Phase 197: Code Review Report

**Reviewed:** 2026-11-22T12:45:00Z
**Depth:** deep
**Files Reviewed:** 52
**Status:** issues_found

## Summary

Scope was the diff `84afaba0..33aac70f` (PR #177), source, test, script and storybook files only. Generated bundles (`priv/static/assets/js/storybook.js`, built CSS) were checked only for tracking and parity with their source. Docs (`AGENTS.md`, `CONTRIBUTING.md`, `GLOSSARY.md`, `UI-REVIEW.md`) were read for obvious errors only.

No structural findings block (fallow) was supplied, so there is no Structural section. No external reviewer evidence was supplied. Necessity (category 4): read the rubric; no finding met its evidence rule (the one candidate, `RecoveryView`'s `:evidence_without_status` refusal, is a deliberate contract of a pure builder that stories also call, so it is a test seam, not an impossible-state guard).

**Verified empirically, not assumed:** on the reviewed tree, `mix format --check-formatted` is clean, `MIX_ENV=test mix compile --force --warnings-as-errors` is clean, the full `scrypath_ops` suite passes (804 tests, 2 doctests, 0 failures at seed 4242), and the catalog contract plus Failed sync tests pass at seed 0. The Postgres `too_many_connections` noise during the run comes from the shared local server, not from these tests.

**What holds up under adversarial reading:**

- **D3 (unresolved handoff never raises).** I probed `RecoveryView.for_page/1` over unknown status, partial evidence (each key missing), `nil` schema, and every refused combination. It is total. `{:error, :job_running}` and `{:error, :queue_only_completed}` in the observer's `else` branches look like a downgrade risk (bare `:running` carries no evidence and would now render "could not be checked"), but `validate_recovery_job/2` never returns them, so no real state is downgraded.
- **D1 (stale-sudo `return_to`).** Path-only open-redirect guard works for `//`, backslash, tab and CRLF in the path (probed). `SearchLive` still wins because its own assign runs after the hook. The value is `URI.encode_query`-encoded by `Gating`. See IN-01 for the query-side gap.
- **LiveView refactors.** `FailedSyncView` and `Posture.build/3` are line-for-line moves of the old helpers (compared against `84afaba0:failed_sync_live.ex`). The visibility predicate for the two recovery areas is identical to the old template condition. `Layouts.app` call sites are unchanged. The one silent change is IN-08.
- **Loopback bind.** `ScrypathOps.Catalog.Endpoint` is configured only in `config/dev.exs` with `ip: {127,0,0,1}`; `runtime.exs` and `test.exs` never configure it (grep-verified), the task `put`s only the port, `lsof` arguments use a validated integer, and the new boundary tests pin the bind and the dev/test-only module lists. Not reachable from a prod build.
- **Hostile text.** No `raw/1`, `{:safe, _}` or `<script>` in the new components. Row ids, reasons, document ids and the checkout path all pass through HEEx escaping.

The four warnings are about checks and tests claiming more than they prove, plus one dev-tool behavior that can mislead a reviewer into judging a stale storybook.

## Warnings

### WR-01: Serve task reports a stale or foreign-checkout catalog as "this catalog" and exits 0

**File:** `scrypath_ops/catalog/lib/mix/tasks/scrypath_ops.catalog.serve.ex:36-43, 67-74` (also `AGENTS.md`, "Port collision" bullet)
**Issue:** `port_verdict/3` returns `:ours` whenever the listener's landing page contains `data-catalog-main-sha="`. That marker proves "some catalog", not "the catalog of this checkout at this commit". If an old catalog from another worktree, or from this checkout before a `git pull`, still holds 4003, `mix scrypath_ops.catalog.serve` prints "This catalog is already serving ... Nothing was started or stopped." and exits 0. The `start` command documented in `AGENTS.md` then reports success while the maintainer reviews old stories. Only the later `npm run ui:preflight` notices, so a flow that stops after "start succeeded" is unprotected. `AGENTS.md` repeats the overstatement: "it exits quietly when the holder is this catalog".
**Fix:** Compare what the running page prints against the current checkout's `build_info/1` before answering `:ours`. For example, read `data-catalog-checkout` and `data-catalog-head-sha` from the body, and return `:ours` only when both match; otherwise return `{:held, " by a catalog from #{checkout} at #{head}"}` so the task raises with the existing "Nothing was stopped" message.

```elixir
defp ours?(body, %{checkout: checkout, head_sha: head}) when is_binary(body) do
  attr = fn name ->
    case Regex.run(~r/#{name}="([^"]*)"/, body) do
      [_, v] -> v
      _ -> nil
    end
  end

  attr.("data-catalog-checkout") == checkout and attr.("data-catalog-head-sha") == head
end
```

(Compare against the unescaped value, as `parseCatalogMarkers` does on the JS side.)

### WR-02: The endpoint that actually serves the review surface is never started by any test

**File:** `scrypath_ops/catalog/lib/scrypath_ops/catalog/endpoint.ex:8-27`, `scrypath_ops/catalog/lib/scrypath_ops/catalog/router.ex:9-15`, `scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs:140-146, 1146`
**Issue:** `ScrypathOps.Catalog.Endpoint` and `Router` are what 127.0.0.1:4003 runs, but every render in the contract test goes through `ScrypathOpsWeb.Endpoint` (the main dev router's storybook mount), and the planted tests use `ScrypathOps.Catalog.PlantedEndpoint`, a hand-copy of the real endpoint with a narrower `Plug.Static` (`only: ~w(assets)` versus `ScrypathOpsWeb.static_paths()`). The real module appears in tests only inside boundary-list assertions and a config read of the bind address. A regression there (plug order, session key, socket path, `Plug.Static` scope so fonts 404, a router edit that drops `storybook_assets()`) stays green in CI and is found by eye, which is the situation the phase's preflight is meant to avoid. The `PlantedEndpoint` precedent shows a boot-and-dispatch test needs only a `config/test.exs` entry (`secret_key_base`, `live_view: [signing_salt: ...]`, `server: false`).
**Fix:** Add one test that dispatches against the real endpoint without binding a port, and asserts what only that endpoint owns:

```elixir
test "the catalog endpoint serves the welcome page and its fonts" do
  start_supervised!(ScrypathOps.Catalog.Endpoint)
  conn = Phoenix.ConnTest.dispatch(build_conn(), ScrypathOps.Catalog.Endpoint, :get, "/storybook/welcome")
  assert conn.status == 200
  assert conn.resp_body =~ ~s(data-catalog-main-sha=")
  font = Phoenix.ConnTest.dispatch(build_conn(), ScrypathOps.Catalog.Endpoint, :get, "/assets/fonts/ui.woff2")
  assert font.status == 200
end
```

(plus a `config :scrypath_ops, ScrypathOps.Catalog.Endpoint, server: false, secret_key_base: ..., live_view: [...]` block in `config/test.exs`; the existing `read_catalog_endpoint_config!(..., "[:server]")` assertion already allows `nil`/`false`).

### WR-03: The "Mounted" provenance proof is satisfied by any file that merely names the scenario

**File:** `scrypath_ops/test/support/catalog_checks.ex:255-282` (needle choice at 257-261, `scenario_prefix/2`); consumers in `scrypath_ops/storybook/**` (every `Proof: Mounted ...` variation)
**Issue:** For a `Mounted <path>` proof with no `Claim:`, the needle is the longest registered scenario id that the variation id starts with, and the check is `String.contains?(file_text, needle)`. Every Shopadelic variation starts with `shopadelic_failed_journey`, and the cited files mention that string 2 (journey test), 9 (`failed_sync_live_test.exs`) and 3 (`posture_live_test.exs`) times. So `shopadelic_failed_journey_ineligible_task` ("no Retry on the failed Meilisearch task"), `..._retry_queued` ("receipt names job 991, original retained") and `..._verified` ("Recovery verified") all pass on a file that uses the scenario in a setup block, whether or not any assertion backs the claim. The doc comment says the test "cannot claim more than the linked test mentions", which is accurate, but the label shown to reviewers is `Proof: Mounted <test>`, which reads as "this test asserts it". Only the two D3 variations carry a `Claim:`, so only those have a claim-specific needle.
**Fix:** Make the needle claim-specific for every `Mounted` label, not just D3. Cheapest: require the full variation id to appear in the cited file, as a one-line marker next to the assertion that backs it (`# story: shopadelic_failed_journey_retry_queued`), or require a `Claim:` literal for every `Mounted` proof and drop the scenario-prefix fallback so `{:proof_without_needle, id}` fires instead. At minimum, rename the label to `Mentioned in` so it stops reading as a proof.

### WR-04: "Story output equals production output" is tested against test-owned copies of the story pipeline, so a story can drift unnoticed

**File:** `scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs:1337-1375` (`journey_loads`, `journey_view`, `view_scope`), `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs` (seam describes), `scrypath_ops/storybook/areas/health_verdict.story.exs`, `areas/health_schema_row.story.exs`, `surfaces/search_health.story.exs`, and `Posture.summary/4`
**Issue:** The seam tests mount the real page, then compare it to the shared component rendered with the page's own assigns. That proves the LiveView passes its state through, which is useful. But the test code never loads a story: the only references to `story.variations()` are in `catalog_contract_test.exs`, and the failed sync seams rebuild the story's data in the test itself ("built the way the story builds them"). Meanwhile the three-way Posture input (`:unconfigured` / `:missing_backend` / rows) is hand-copied into three stories and `Posture.summary/4`, and the retry receipt map is hand-built in `failed_row`, `retry_receipt` and the Job story to mimic `FailedSyncLive.accepted_receipt/5`.

The copies have already diverged in a small way: `FailedSyncLive.load_schema/2` accepts both `{:ok, %FailedSyncWorkInspection{}}` and `{:ok, rows} when is_list(rows)` and wraps the call in `rescue`/`catch`, while the stories match only the struct. `failed_row`, `retry_receipt`, `delete_confirmation` and the Job story also match only `{:ok, _}`, where `failed_summary` and the Failed sync surface handle `{:error, _}`. If `accepted_receipt/5` gains a key the component starts reading, or `Posture.summary/4` gains a branch, the page and its seam stay green and the story renders something the page no longer produces. The catalog's value is that a story is the page.
**Fix:** One builder, two callers. Put the story-side derivations in a dev/test module under `catalog/lib` (for example `ScrypathOps.Catalog.Builders.failed_sync_view(scenario_id)`, `.posture(scenario_id)`, `.receipt(row)`), have the stories call it, and have the seam tests call the same functions. Better still for `Posture`, extract the pure `input(allowlist, opts)` cond from `summary/4` into `Posture` and call it from `summary/4` and the stories. Alternatively, make one seam per story load `story.variations()` and assert the component output for the variation's `attributes` equals the mounted page for the same scenario.

## Info

### IN-01: `return_to_path/1` validates control characters and `//` on the path only, and keeps a stale `:return_to` when the new URL is rejected

**File:** `scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex:31-42, 55-77`
**Issue:** Probe output (`return_to_path/1` run directly):

```
"https://h/ops/x?a=1\r\nX: y"   -> "/ops/x?a=1\r\nX: y"     (raw CR/LF kept in the query)
"http://h//ops"                  -> nil
"http://h/\t/x"                  -> nil
```

The moduledoc says a control character "gives `nil`", which is true only for the path. `Gating` percent-encodes the value, so the redirect URL is safe today, and a real browser percent-encodes CR/LF in URLs, so this is not exploitable here. But `assigns.return_to` is also readable by host apps, and the promise in the doc is wider than the code. Separately, when `return_to_path/1` returns `nil` the hook leaves any earlier `:return_to` from a previous patch in place, so an unsafe patched URL can send the operator back to an older page after the sudo check.
**Fix:** Run `control?/1` over `query` as well (a query containing a control character gives `nil`), and in the `nil` branch assign `:return_to` to `nil` (or the bare mount path) so Gating falls back to its default instead of a stale value. Adjust the moduledoc to say "path and query".

### IN-02: `HtmlCanon` normalizes one generated-id family, but the components generate three

**File:** `scrypath_ops/test/support/html_canon.ex:71`; generators at `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:135` (`ops-section-N`), `:749` (`ops-empty-hero-heading-N`), `:1340` (`ops-time-N`)
**Issue:** Only `ops-time-\d+` is replaced. A story or page whose `ops_section` or `ops_empty_hero` has no explicit id renders a different `id` and `aria-labelledby` on every render. Two consequences: `identical_variations/1` would silently miss two same-state variations built on such a component (their digests differ), and a seam test comparing mounted to component output would go red for a reason unrelated to the code under test. Nothing is affected today because the Failed sync, Search health and Recovery components all pass explicit ids, which is why this is Info.
**Fix:** Normalize all three with one pattern, for example `Regex.replace(~r/\b(ops-(?:time|section|empty-hero-heading))-\d+/, value, "\\1-N")`, and add the planted-pair assertion for `ops-section-N` that the `ops-time` case already has.

### IN-03: Catalog endpoint copies the main dev endpoint's loose settings (`check_origin: false`, `debug_errors: true`, fixed keys), and the welcome page prints the local checkout path

**File:** `scrypath_ops/config/dev.exs:86-96`, `scrypath_ops/storybook/welcome.story.exs:59-62`
**Issue:** The bind is loopback and the data is fictional, and the choices match `ScrypathOpsWeb.Endpoint` in the same file, so this is consistency rather than a defect. Still, with `check_origin: false` and no host check, a page the developer visits could reach the endpoint by DNS rebinding and read `/storybook/welcome`, which prints the absolute checkout path (the home directory and user name) and the commit shas, and the story source tab. The `secret_key_base` and the LiveView and session salts are committed constants.
**Fix:** Optional hardening: `check_origin: ["//127.0.0.1:*", "//localhost:*"]` on the catalog endpoint, and a `url: [host: "localhost"]` so a rebinding host fails the origin check. If the path is only needed for the preflight comparison, consider printing it in the marker attribute but not in visible text (it is currently both).

### IN-04: `RecoveryView.status/1` collapses an explicit `:not_checked`; `schema_name` is the string `"nil"` with no schema

**File:** `scrypath_ops/lib/scrypath_ops/recovery_view.ex:176-196, 198-202`; `scrypath_ops/lib/scrypath_ops/operator_selection.ex:5-9`
**Issue:** Probe: `build(%{status: :not_checked, evidence: full, ...})` gives `status: :unavailable`, not `:not_checked`, because only `nil` maps to `:not_checked`. `RecoveryView.statuses/0` and the moduledoc list `:not_checked` as a member of the closed set. A story author who passes it gets the "could not be checked" copy. The `:evidence_without_status` refusal is reachable only through `nil`, which is not obvious from the type. Also, `fields/4` calls `OperatorSelection.canonical(nil)`; `nil` is an atom, so it matches the `is_atom/1` clause and returns the string `"nil"`. `schema_name` is therefore `"nil"` when `schema` is `nil`, contradicting the `String.t() | nil` typespec (probe: `{"nil", false}`). Unreachable in the page (`visible?` requires a schema), so cosmetic.
**Fix:** `defp status(s) when s in [nil, :not_checked], do: :not_checked`, and `schema_name: schema && OperatorSelection.canonical(schema)`.

### IN-05: The same story helpers are pasted into seven or more stories

**File:** `scrypath_ops/storybook/areas/failed_row.story.exs`, `areas/failed_summary.story.exs`, `patterns/delete_confirmation.story.exs`, `patterns/failed_filters.story.exs`, `patterns/retry_receipt.story.exs`, `surfaces/failed_sync.story.exs`, `jobs/job_03_on_call_recovers_failed_sync.story.exs` (the loads block, the scope map, and `receipt/1`); `areas/health_verdict.story.exs`, `areas/health_schema_row.story.exs` and `surfaces/search_health.story.exs` (`posture/2`)
**Issue:** The house preference for copy over a dependency is about dependencies, not about repeating one derivation seven times inside the repo. The cost shows up in WR-04: there is no single place to keep the pipeline honest.
**Fix:** Same module as WR-04's fix; stories call it.

### IN-06: JS preflight does not slice `git rev-parse --short=12` output, while the Elixir side does

**File:** `examples/scrypath_ecommerce/e2e/ui-review.mjs:857-858` (versus `catalog/lib/mix/tasks/scrypath_ops.catalog.serve.ex:112-118`, whose test covers a longer abbreviation)
**Issue:** `--short=12` is a minimum. If git ever prints more than 12 characters (only when the abbreviation is ambiguous, which needs a very large object count), the page prints the first 12 and the preflight compares the full string, so it reports a spurious "differs from origin/main" and a spurious stale remote. Fail-closed, so low risk.
**Fix:** `.trim().slice(0, 12)` on both reads, as the task and `storybookErrors` already do for the remote.

### IN-07: Welcome copy hard-codes the frozen time next to a marker that prints it dynamically

**File:** `scrypath_ops/storybook/welcome.story.exs:80` (versus `:63-66` and `info/0`)
**Issue:** The bullet says "Time is frozen at 2026-11-20 14:00 UTC" as literal text while the same page prints `ScrypathFixtures.preview_epoch()` in `data-catalog-epoch`. The contract test asserts the literal. If the epoch is advanced, the page contradicts itself and only that one assertion changes.
**Fix:** Interpolate the epoch (`{@info.epoch}` formatted) into the sentence, and assert the formatted value in the test.

### IN-08: Search health row ages now fall back to the last refresh, where they used to fall back to the live clock; parity could not see it

**File:** `scrypath_ops/lib/scrypath_ops_web/components/search_health.ex:142, 163, 215, 272, 322` (old: `84afaba0:posture_live.ex:376, 397, 449, 506`)
**Issue:** The old template passed `snapshot_at={source_ref(...)[:checked_at]}`; `ops_time` then used `ScrypathOps.Clock.utc_now()` when it was `nil`. The component now passes `... || @now`, so the tooltip age is measured against the page's snapshot instant. That is the intended "no clock in components" rule and is arguably more correct for a page that does not auto-refresh, and in practice a source has a ref whenever it has a success time, so the fallback rarely fires. It is still a silent behavior change, and the 54-capture parity run could not detect it because the preview clock is frozen. Worth one line in the phase notes.
**Fix:** None needed in code; record it as an intentional change, or add a seam case with a non-frozen clock if it should be pinned.

### IN-09: Self-test asserts inside an HTTP server callback

**File:** `examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs:469`
**Issue:** `assert.equal(request.url, "/storybook/welcome")` runs inside the `createServer` handler. A mismatch throws in the request callback, which Node reports as an uncaught exception that can abort the whole test run instead of failing the one test, and it hides which assertion failed.
**Fix:** Record `request.url` in a local array inside the handler and assert on it after `checkStorybook` returns.

---

_Reviewed: 2026-11-22T12:45:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
