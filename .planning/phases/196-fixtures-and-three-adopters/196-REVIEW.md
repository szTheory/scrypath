---
phase: 196-fixtures-and-three-adopters
reviewed: 2026-11-22T05:10:43Z
depth: standard
files_reviewed: 48
files_reviewed_list:
  - .dockerignore
  - .formatter.exs
  - dev/mix/tasks/verify.namespace_fence.ex
  - examples/scrypath_ecommerce/Dockerfile
  - examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh
  - fixtures/scrypath_fixtures/.formatter.exs
  - fixtures/scrypath_fixtures/.gitignore
  - fixtures/scrypath_fixtures/README.md
  - fixtures/scrypath_fixtures/mix.exs
  - fixtures/scrypath_fixtures/lib/mix/tasks/scrypath_fixtures.check_fixtures.ex
  - fixtures/scrypath_fixtures/lib/scrypath_fixtures.ex
  - fixtures/scrypath_fixtures/lib/scrypath_fixtures/applied_settings.ex
  - fixtures/scrypath_fixtures/lib/scrypath_fixtures/bulk.ex
  - fixtures/scrypath_fixtures/lib/scrypath_fixtures/check.ex
  - fixtures/scrypath_fixtures/lib/scrypath_fixtures/failures.ex
  - fixtures/scrypath_fixtures/lib/scrypath_fixtures/fake_meilisearch_client.ex
  - fixtures/scrypath_fixtures/lib/scrypath_fixtures/fake_oban_inspector.ex
  - fixtures/scrypath_fixtures/lib/scrypath_fixtures/hostile.ex
  - fixtures/scrypath_fixtures/lib/scrypath_fixtures/logistify.ex
  - fixtures/scrypath_fixtures/lib/scrypath_fixtures/logistify/shipment.ex
  - fixtures/scrypath_fixtures/lib/scrypath_fixtures/meili.ex
  - fixtures/scrypath_fixtures/lib/scrypath_fixtures/oban_job.ex
  - fixtures/scrypath_fixtures/lib/scrypath_fixtures/recordings.ex
  - fixtures/scrypath_fixtures/lib/scrypath_fixtures/scenario.ex
  - fixtures/scrypath_fixtures/lib/scrypath_fixtures/scenarios.ex
  - fixtures/scrypath_fixtures/lib/scrypath_fixtures/shopadelic.ex
  - fixtures/scrypath_fixtures/lib/scrypath_fixtures/shopadelic/product.ex
  - fixtures/scrypath_fixtures/lib/scrypath_fixtures/wikily.ex
  - fixtures/scrypath_fixtures/lib/scrypath_fixtures/wikily/page.ex
  - fixtures/scrypath_fixtures/recordings/record.sh
  - fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/PROVENANCE.md
  - scripts/ci/compat_path_classifier.test.cjs
  - scrypath_ops/mix.exs
  - scrypath_ops/test/scrypath_ops/fixtures_check_task_test.exs
  - scrypath_ops/test/scrypath_ops/fixtures_check_test.exs
  - scrypath_ops/test/scrypath_ops/fixtures_provenance_test.exs
  - scrypath_ops/test/scrypath_ops/fixtures_recordings_test.exs
  - scrypath_ops/test/scrypath_ops/fixtures_round_trip_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/fixtures_determinism_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/fixtures_hostile_render_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/fixtures_tracer_test.exs
  - scrypath_ops/test/support/fixture_env.ex
  - test/mix/tasks/dependency_boundary_contract_test.exs
  - test/mix/tasks/fixtures_project_contract_test.exs
  - test/mix/tasks/verify_namespace_fence_test.exs
  - test/release/ops_dependency_boundary_test.exs
  - test/release/package_metadata_test.exs
  - test/support/release/shipped_docs.ex
findings:
  critical: 0
  warning: 9
  info: 5
  total: 14
  necessity: 1
status: issues_found
---

# Phase 196: Code Review Report

**Reviewed:** 2026-11-22T05:10:43Z
**Depth:** standard
**Files Reviewed:** 48 (the 31 recorded JSON payloads were scanned for secrets and personal data only)
**Status:** issues_found

## Summary

The phase adds the `fixtures/scrypath_fixtures` Mix project, three fictional adopters, a DB-free check task wired first into the ops `test` alias, and the root accounting that keeps the project out of the Hex tarball and the prod dependency graph. I read every non-planning file in `6fff5f00..HEAD`, ran the check task and every new test file locally (146 ops tests, 85 root tests, the two Node classifier suites, `bash -n` on the verify script, `mix format --check-formatted`), and probed the check with planted inputs of my own.

What holds up: the dependency-graph boundary is real. `mix deps` lists `scrypath_fixtures` in the ops dev and test graphs only, never in the prod graph and never in the host project in any environment. The Hex `files:` list cannot reach `fixtures/`. The recordings are pure ASCII, contain no secret or personal data, and the hostile text is written as escapes everywhere I looked (the only raw non-ASCII in the diff is two lines that predate this phase). Builders take no wall clock and no random source, and the hostile strings sit only where Meilisearch can echo them. Hostile rendering is asserted through LazyHTML selectors and `reasons =~ Hostile.markup()` fails for an unescaped page, so that test is not vacuous. The shell edits are syntactically correct for both the test and prod stages. Hosted CI for PR #174 shows `ops-ui`, `repository-contracts` and `ecommerce-mounted` green.

No critical defect. The weaknesses are in the check that the project's high-stakes promises rest on: its lint lists and invariants are narrower than the documentation says, one shipped scenario family violates a Meilisearch invariant the check does not test, and two plants cannot fail for the cause they name. There is also a gap between "never reaches the prod image" and what the Docker proof actually asserts.

Already recorded and not re-reported: F1, F2, F3, F4, D2, the `dashboard_routes` guard defect, and Phase 195's dispositions.

## Warnings

### WR-01: The purity lint covers eight tokens, but the README says no wall clock, random source, OS or repository access

**File:** `fixtures/scrypath_fixtures/lib/scrypath_fixtures/check.ex:242-253` (token list), `fixtures/scrypath_fixtures/README.md:79` (claim)
**Issue:** `impure_tokens/0` flags only `DateTime.utc_now`, `NaiveDateTime.utc_now`, `Date.utc_today`, `:rand.`, `System.`, `:os.`, `Repo.` and `~U[`. The README states "`lib/` source never reads the wall clock, a random source, the operating system or a repository (`:impure_source`)". I planted each of these as an in-memory `lib/` source file against a clean scenario and `Check.run` returned `{:ok, ...}` for all of them: `Enum.random`, `Enum.shuffle`, `Time.utc_now`, `DateTime.now!`, `:erlang.system_time`, `:erlang.unique_integer`, `:crypto.strong_rand_bytes`, `Ecto.UUID.generate`, `~N[...]`, `File.read!`, `Process.sleep`. Two mitigations exist (the 3-day relative-time shift and the bulk digest would catch most of these in emitted data), but they do not see a nondeterministic source that is not on a currently emitted path, and the provenance test pins only the eight listed tokens, so the narrower list looks complete.
**Fix:** Extend `impure_tokens/0` with the missing families and add one plant per added token in `fixtures_provenance_test.exs` (the existing `calls` table is the right place):
```elixir
"Enum" <> ".random", "Enum" <> ".shuffle", "Time" <> ".utc_now", "DateTime" <> ".now",
":erlang" <> ".system_time", ":erlang" <> ".unique_integer", ":erlang" <> ".monotonic_time",
":crypto" <> ".strong_rand_bytes", "UUID" <> ".generate", "~N" <> "[", "~D" <> "[", "File" <> "."
```
If a narrower list is intentional, change the README sentence to name exactly what is enforced.

### WR-02: The Trojan Source lint omits the Arabic letter mark (U+061C) and the invisible word joiners

**File:** `fixtures/scrypath_fixtures/lib/scrypath_fixtures/check.ex:191-193`, `fixtures/scrypath_fixtures/README.md:50`
**Issue:** `@format_codepoints` covers U+200B-200F, U+202A-202E, U+2066-2069 and U+FEFF. U+061C ARABIC LETTER MARK is a bidirectional control (UAX 9) and is missing, as are U+2060-2064 (word joiner and invisible operators) and U+180E. The README and moduledoc promise "no raw bidirectional control, zero-width character or byte-order mark". Probe: `Check.run(source_files: [{path, "a" <> <<0x061C::utf8>> <> "b"}])` returned `{:ok, ...}`; so did U+2060, U+180E, U+00AD and U+E0001. The project's own hostile data includes Arabic text, so U+061C is the likeliest bidi control to turn up in a pasted fixture.
**Fix:** Add `0x061C`, `0x2060..0x2064`, `0x180E` (and optionally `0x00AD`, `0xFE00..0xFE0F`, `0xE0000..0xE007F`) to `@format_codepoints`, and add 0x061C and 0x2060 to the `for codepoint <- [...]` plant in `fixtures_provenance_test.exs:67`.

### WR-03: `Check` has no shape or coherence invariant for Oban jobs; impossible jobs pass

**File:** `fixtures/scrypath_fixtures/lib/scrypath_fixtures/check.ex:58-85` (invariant list), `check.ex:665-716` (`job_problems`)
**Issue:** Tasks get `:task_keys`, `:task_shape` and `:details_keys`; jobs get only index, schema, failure text, retryable/discarded attempt rules and a future-time rule. Everything else is enforced only by `ObanJob.job/1`, so a hand-built or later-edited scenario (the check is designed to take arbitrary `:scenarios`, and every plant relies on that) is unchecked. I planted each of the following into the real deep-queue scenario and `Check.run` returned `{:ok, ...}`: state `"exhausted"` (not an Oban state), worker `"Some.Other"`, a job with no `:attempt` key, `executing` at attempt 0, `completed` with no `completed_at`, `retryable` with no `errors`, `discarded` with no `errors`. Oban's executor always records an error for a retryable or discarded job and increments `attempt` before `executing`, so none of these can occur.
**Fix:** Add a `:job_shape` invariant (exact 11 atom keys, `state` in `ObanJob.states/0`, `worker` in `ObanJob.workers/0` values, `errors` a list, stamp fields `DateTime | nil`) and a `:job_state_coherence` invariant (`executing`/`completed`/`retryable`/`discarded` require `attempt >= 1`; `retryable`/`discarded` require `errors != []`; `completed` requires `completed_at`). Add one plant each in `fixtures_check_test.exs`; the coverage test will then force them.

### WR-04: Two shipped scenarios violate Meilisearch's uid ordering, and `Check` cannot see it

**File:** `fixtures/scrypath_fixtures/lib/scrypath_fixtures/shopadelic.ex:224` and `:251-260` (the offending tasks), `fixtures/scrypath_fixtures/lib/scrypath_fixtures/check.ex:544-558` (no ordering or identity invariant)
**Issue:** Meilisearch assigns task uids in enqueue order, so a higher uid is never enqueued earlier than a lower one. In `shopadelic_failed_journey` the failed task has uid 43 and `enqueued_ago: 5_400`, while uids 40, 41 and 42 were enqueued 3,200, 1,590 and 1,580 seconds ago. In `shopadelic_hostile_ids` uids 43-52 use `5_400 - n * 10` (about 4,900 seconds ago) while uid 42 is 1,580 seconds ago. Running every registered scenario through a uid-versus-`enqueuedAt` probe reports one adjacent inversion in each of those two scenarios (`{42, 13:33:40}` then `{43, 12:30:00}` and `{42, 13:33:40}` then `{43, 12:37:10}`), none elsewhere. The README (lines 5 and 54) and the phase brief promise that only states the library can produce appear. The same gap lets duplicate uids pass: I duplicated a uid in the deep queue and `Check.run` returned `{:ok, ...}`. The same defect exists in the test helper `with_failures/1` (uid 900 enqueued 100 seconds ago, newer uids 641-647 enqueued 30 to 210 seconds ago), which is why no test noticed.
**Fix:** Order the failed tasks after the history in time. For example, give the history `enqueued_ago` values at least 6,000 seconds larger (`43_200 - n * 1_000` becomes `49_200 - n * 1_000`, and the deletes `7_000 - n * 10`), or give the failed tasks `enqueued_ago` below 1,580. Then add two invariants to `Check`: `:task_uid_unique` and `:task_uid_order` (tasks sorted by uid have non-decreasing `enqueuedAt`), with plants in `fixtures_check_test.exs`.

### WR-05: A task with no `"indexUid"` key crashes the check instead of reporting `:task_keys`

**File:** `fixtures/scrypath_fixtures/lib/scrypath_fixtures/check.ex:620-624`
**Issue:** `task_index/3` has a clause for `%{"type" => "indexSwap", "indexUid" => nil}` and one for `%{"indexUid" => value}`, and no fallback. `task_problems/3` builds the list with `List.flatten([wire_guard(...), task_keys(...), ..., task_index(...), ...])`, so the call is evaluated eagerly and a task map without the key raises. Probe: deleting `"indexUid"` from the first deep-queue task made `Check.run` raise `FunctionClauseError ... ScrypathFixtures.Check.task_index/3`, so `mix test` dies with a stack trace and the `{:task_keys, uid}` problem that should name the cause is never reported. The `:task_keys` plant deletes `"duration"` only, which is why the suite never meets this.
**Fix:**
```elixir
defp task_index(%{"indexUid" => value}, uid, indexes) do
  if value in indexes, do: [], else: [{:index_uid, uid, value}]
end

defp task_index(_task, _uid, _indexes), do: []   # a missing key is :task_keys' problem
```
and add a `:task_keys` plant that deletes `"indexUid"`.

### WR-06: Two `failure_source_missing` plants resolve to nothing whether or not the guard exists

**File:** `scrypath_ops/test/scrypath_ops/fixtures_recordings_test.exs:595-601`, guard at `fixtures/scrypath_fixtures/lib/scrypath_fixtures/check.ex:505-509`
**Issue:** The test claims to prove that traversal and absolute spellings are rejected, using `"../../etc/hosts"` and `"/etc/hosts"`. `source_resolves?/1` does `Path.join(@repo_root, source)`. `Path.join` turns the absolute spelling into `<root>/etc/hosts`, which does not exist, and the traversal spelling lands two levels above the repo (`/Users/jon/etc/hosts` here, `/home/runner/work/etc/hosts` in CI), which does not exist either. I checked: removing either guard leaves both plants reported as missing. So neither guard can fail its own test. (A spelling that would resolve without the guards, `lib/../mix.exs`, is rejected today only because of the `..` guard; I confirmed it by running it.)
**Fix:** Replace the two plants with spellings that exist when the guard is absent:
```elixir
"lib/../mix.exs",                              # needs the ".." guard
"/lib/scrypath/meilisearch/client.ex"          # absolute spelling that Path.join would re-root; needs the :relative guard
```

### WR-07: The prod image still carries the fixtures sources and recordings; the Docker proof only checks compiled output

**File:** `examples/scrypath_ecommerce/Dockerfile:70`, `.dockerignore:18-19`, `examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh:654-656`
**Issue:** The phase's stated requirement (the review brief; the README says the project "never ships in the Hex package or in a release") is that the fixtures project never reaches the prod image. `runtime_prod` runs `COPY --exclude=**/config/dev.exs . .` and `.dockerignore` deliberately keeps `fixtures/` (the dev and test stages compile it), so `/app/fixtures/scrypath_fixtures/` (lib, 31 recordings, README, `record.sh`) ships in the prod image. The verify script asserts only that `_build/prod/lib/scrypath_fixtures` is absent, that `mix deps` does not list it, and that the `ScrypathFixtures` module does not load, all of which are true. Nothing asserts that the directory is absent, so the claim is stronger than the evidence. It is inert data, and `scrypath_ops/catalog` has the same precedent, but this is a separate top-level tree whose stated purpose is to stay out.
**Fix:** In the `runtime_prod` stage only, exclude the tree and assert it:
```dockerfile
COPY --exclude=**/config/dev.exs --exclude=fixtures . .
```
```sh
test ! -e /app/fixtures || { echo "fixtures sources were copied into the prod image" >&2; exit 1; }   # inside the MIX_ENV=prod branch
```
Add the matching mutant to `fixtures_script_violations/1` in `dependency_boundary_contract_test.exs`. If the exclusion is rejected as not worth the cost, state the claim as "never compiled into the prod image" wherever the requirement is written.

### WR-08: Phantom requirement: the `runtime_prod` stage copies a manifest the prod resolution never reads

**File:** `examples/scrypath_ecommerce/Dockerfile:61`, pinned by `test/mix/tasks/dependency_boundary_contract_test.exs:945-1000` and `:1268-1295`
**Category:** necessity
**Issue:** The contract test requires the fixtures manifest `COPY` in every stage that copies the Ops manifest, on the stated ground that "a missing one only fails later at compile ('the dependency is not available')". That holds for `asset_builder` (dev) and `runtime_test`, where the dependency is in the graph. It does not hold for `runtime_prod`: the dependency is declared `only: [:dev, :test]`, so Mix never looks for it under `MIX_ENV=prod`. I reproduced both halves in a scratch tree holding only the root and ops `mix.exs` and no `fixtures/`: `MIX_ENV=test mix deps` printed `* scrypath_fixtures ... the dependency is not available`, and `MIX_ENV=prod mix deps` mentioned `scrypath_fixtures` nowhere. The line therefore guards a failure that cannot occur in that stage, and the test cements it for all three stages, which also puts a fixtures file into a stage whose job is to exclude them.
**Fix:** Drop the `COPY` from `runtime_prod` and make `fixtures_dockerfile_violations/1` iterate only the stages that resolve the dependency (`asset_builder`, `runtime_test`), with the plant loop narrowed to match. Together with WR-07 this leaves the prod stage with no fixtures path at all.

### WR-09: `record.sh` deletes files before it knows the recording will succeed, in whatever directory it is given

**File:** `fixtures/scrypath_fixtures/recordings/record.sh:24-27`
**Issue:** `rm -f "$out_dir"/*.json` runs at line 27, before Docker is started, before the image is pulled and before any request is made. If Docker is down, the pull fails or any later step exits (the script is `set -e`), the committed recordings are already gone and `ScrypathFixtures.Recordings` then raises `CompileError: no recordings found` for the whole project until `git checkout` restores them. The directory is an arbitrary argument: `bash record.sh .` from the repository root removes `package.json` and every other `*.json` there, tracked or not.
**Fix:** Record into the scratch directory and move at the end, and refuse a directory that is not the pinned one:
```bash
case "$(basename "$out_dir")" in meilisearch-v*) ;; *) echo "refusing to clean $out_dir" >&2; exit 2 ;; esac
stage="$work/out"; mkdir -p "$stage"            # write every save() into $stage
# ... after the last request:
rm -f "$out_dir"/*.json && cp "$stage"/*.json "$out_dir"/
```

## Info

### IN-01: `FakeObanInspector` says it scopes jobs "the way the repository's real inspector scopes them" but drops two of its three constraints

**File:** `fixtures/scrypath_fixtures/lib/scrypath_fixtures/fake_oban_inspector.ex:6-9,16-19` against `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex:7-35`
**Issue:** The real inspector filters by queue and by schema, orders by `id` descending and caps the result at 100 rows. The fake filters by schema only, so it returns every job in insertion order. `logistify_deep_queue` therefore serves 195 jobs, which the repository's own inspector can never return (an adopter with an uncapped inspector could). The ops tests pass either way.
**Fix:** Reword the moduledoc to say it models schema scoping only, or apply the queue filter, the descending order and a configurable `:limit` (default 100) and give `deep_queue` a note that its depth exceeds the demo host's cap.

### IN-02: The determinism test compares whole-page text through regexes over rebuilt attribute strings

**File:** `scrypath_ops/test/scrypath_ops_web/live/fixtures_determinism_test.exs:112-149`
**Issue:** `AGENTS.md` and `scrypath_ops/AGENTS.md` say never to test raw HTML, to prefer `element/2`/`has_element/2`, and to favour key elements over text. This test parses with LazyHTML, but it then re-serialises every start tag as `<tag name="value">` and applies regexes (`data-phx-*`, `id="phx-..."`, `ops-(time|section|...)-N`, and the UI's own date and "N hrs ago" wording) to those strings. It is deliberate and it has a live positive control, so I did not rate it higher; the cost is that any markup or copy change in `OpsUI` breaks it for reasons unrelated to determinism.
**Fix:** If the whole-page comparison stays, record why `element/2` cannot express it in the module comment. Otherwise assert on the relevant elements only: the `data-testid` time cells (absolute time moves, relative-age text does not) via `LazyHTML.query/2`.

### IN-03: Unused public functions in the fixtures API

**File:** `fixtures/scrypath_fixtures/lib/scrypath_fixtures/logistify.ex:49`, `shopadelic.ex:55`, `wikily.ex:43` (`states/0`), `meili.ex:26,30` (`types/0`, `statuses/0`), `oban_job.ex:26` (`states/0`), `bulk.ex:73` (`max_rows/0`)
**Issue:** Nothing in `fixtures/`, `scrypath_ops/` or `test/` calls any of them (grep over all three trees finds only the definitions; `Bulk.max_rows/0` is referenced only by its own definition). They add public surface and doc lines to a dev-only project whose rule is that module names stay stable for a later fold. This is dead code, not a necessity finding.
**Fix:** Delete them, or call them from the places that currently repeat the lists (`Meili.task/1` guards already use the same attributes; the registry test could use `states/0`).

### IN-04: `Meili.stamp/2` assumes a UTC `DateTime` and silently mislabels any other zone

**File:** `fixtures/scrypath_fixtures/lib/scrypath_fixtures/meili.ex:122-128`
**Issue:** The stamp is `Calendar.strftime(... "%Y-%m-%dT%H:%M:%S") <> ".123456789Z"`. A `now` in another zone keeps its wall-clock fields, so the string claims UTC for a different instant. `Scenarios.get!/2` and every builder accept any `%DateTime{}`, and a later preview that passes a local `now` would produce offset stamps that parse cleanly and pass the check (the relative-time check only compares the two builds with each other). Both current callers use the UTC preview epoch.
**Fix:** Guard the head: `def stamp(%DateTime{time_zone: "Etc/UTC"} = now, seconds_ago) ...`, or convert with `DateTime.shift_zone!(now, "Etc/UTC")` first.

### IN-05: Shopadelic's settings task echoes a hand-typed list and no longer follows the schema

**File:** `fixtures/scrypath_fixtures/lib/scrypath_fixtures/shopadelic.ex:182,213-214` against `fixtures/scrypath_fixtures/lib/scrypath_fixtures/applied_settings.ex:65-71`
**Issue:** `AppliedSettings.aligned/1` derives the applied settings from the schema ("no settings key is typed by hand", README), but the `settingsUpdate` task in the history echoes `["status"]` or `["status", "storeId"]` from literals in `applied_filterable/1`. `settingsUpdate` details are exempt from the key check (`Recordings.details_keys("settingsUpdate") == :any`), so if `Product`'s `filterable:` list changes, the served settings change and the task history does not. The echoed details also omit the searchable and sortable keys that the same applied settings contain.
**Fix:** Build the details from `AppliedSettings.fetch/2` for the scenario's URL (`{:ok, settings} = ...; Map.take(settings, ["filterableAttributes", ...])`) so the history and the served settings cannot diverge.

---

_Reviewed: 2026-11-22T05:10:43Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
