# Phase 192 Pin Inventory

Audit trail for success criterion 2 (TRUTH-01, TRUTH-02, README-01): every test assertion that pins `mix verify.adopter`, another repo-only task name, or shipped-docs wording; whether it pins a claim or wiring; where the intent lives after the phase. No pin is deleted without a stronger or equal replacement recorded in the Fate log.

Built in Plan 01 from `192-RESEARCH.md` tables A to D and re-verified against the repository at HEAD `1d7573e5` (plan 01 start; docs and tests unchanged since research HEAD `37018235`). Line numbers below are current as of that HEAD; Plans 02 to 04 shift them, so re-locate by the quoted token before editing.

## Legend and reproduction

- **claim**: asserts what a doc says. **wiring**: asserts that a task, file, workflow or `mix.exs` entry is hooked up.
- Fate vocabulary: `stays`, `stays (allowlisted)`, `kept, qualified in place`, `rewrite`, `replace by invariant`, `split`, `re-point`, `retire (owner pin exists)`, `move claim to owner`.

Reproduce (toolchain: `export ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5`):

```bash
# Scanner probe: unqualified mentions in the real shipped files (zero after Plan 01 Task 3)
MIX_ENV=test mix run --no-start -r test/support/release/package_contract.ex -r test/support/release/shipped_docs.ex -e 'v = Scrypath.Release.ShippedDocs.violations(); Enum.each(v, &IO.inspect/1); IO.puts("violations=#{length(v)}")'

# Every unit that names a repo-only task, qualified (Q) or not (U), outside the allowlist and exemptions
MIX_ENV=test mix run --no-start -r test/support/release/package_contract.ex -r test/support/release/shipped_docs.ex -e 'alias Scrypath.Release.ShippedDocs, as: SD; n = SD.repo_only_tasks(); for p <- SD.shipped_files(), p not in SD.allowlist() ++ Map.keys(SD.exempt()), u <- SD.units(File.read!(p)), h = SD.mentions(u.text, n), h != [], do: IO.puts("#{p}:#{u.line} #{if SD.unit_qualified?(u), do: "Q", else: "U"} #{Enum.join(h, ",")}")'

# Tests that pin the adopter task string, and tests that read README.md
grep -rln 'verify\.adopter' test
grep -rn '@readme' test/scrypath test/release test/mix/tasks
grep -rln 'README.md' test/scrypath test/release test/mix/tasks
```

Scanner facts (`Scrypath.Release.ShippedDocs`, `test/support/release/shipped_docs.ex`): 60 repo-only names derived from `dev/mix/tasks/`, `scrypath_ops/lib/mix/tasks/` and `examples/*/lib/mix/tasks/` minus the shipped `lib/` tasks; 133 text files expanded from the `mix.exs` package `files:` (`.md`, `.ex`, `.exs`; `LICENSE` has no extension and is left out on purpose, it is license text and cannot name a task).

### Named exemptions (outside the locked allowlist `CONTRIBUTING.md`, `docs/releasing.md`)

| Path | Scope | Reason | Revisit trigger |
|------|-------|--------|-----------------|
| `CHANGELOG.md` | whole file | Generated release history owned by release-please; `workflow_wiring_test` requires two historical task mentions in it (`mix verify.workspace_clean`, `mix verify.release_parity`), so the file cannot be edited to green. | When the release-please changelog configuration changes, when a hand-written CHANGELOG entry starts telling adopters to run a command, or when the `workflow_wiring_test` two-mention requirement is removed. |
| `mix.exs` | only lines matching `@registration_line` (a double-quoted dotted task name followed by `: :test`, alone on its line; 55 lines today) | Code that registers task environments in `preferred_envs`, not adopter instructions. Any other `mix.exs` mention is scanned. The unquoted entries (`verify: :test`, `credo: :test`, `dialyzer: :test`) are not blanked; they are not reported because they carry no `mix ` prefix and credo and dialyzer are dependency tasks. | When task-environment registration moves out of `cli/0` `preferred_envs`, or when `mix.exs` gains a docstring or comment that names a repo-only task (that line is scanned and fails today). |

## Table A: pins on the task's own behavior or wiring (STAY unchanged)

| # | Where | What it asserts | Type | Fate |
|---|-------|-----------------|------|------|
| A1 | `test/mix/tasks/verify_adopter_test.exs:12-27,58-72,79-110` | argument errors, live prerequisites, `@fast_tests` file names, `mix help verify.adopter` output (`:86-100`), progress marker (`:104`) | behavior | stays: tests the task, not the docs |
| A2 | `test/scrypath/readiness_contract_test.exs:46-61` | `mix help verify.adopter` output contains the three test paths, env names, `cd examples/phoenix_meilisearch` | behavior | stays |
| A3 | `test/scrypath/docs_contract_test.exs:336-343` | `@verify_adopter` task source names the readiness/phase110/verify_adopter test files, the three env vars, `mix verify.adopter --live` | wiring (task source) | stays |
| A4 | `test/scrypath/phase99_contract_test.exs:73-87` (research cited `:50-62`; moved) | `mix deps.get --check-locked` before `mix test` inside the task's `--live` docs | wiring | stays |
| A5 | `phase99_contract_test.exs:86-110`, `workflow_wiring_test.exs:1195-1236`, `phase108_contract_test.exs:79-102` | `mix.exs` `"verify.phaseNN": :test` registrations and CONTRIBUTING gate rows | wiring in allowlisted or exempt files | stays (CONTRIBUTING allowlisted, `mix.exs` exempt) |
| A6 | `workflow_wiring_test.exs:1461-1462` | `CHANGELOG.md` contains `mix verify.workspace_clean` and `mix verify.release_parity` | wiring (history) | stays; forces the `CHANGELOG.md` exemption |
| A7 | `workflow_wiring_test.exs:1431-1438`, `:1390-1402` | `docs/releasing.md` headings `### \`mix verify.workspace_clean\``, `mix verify.release_parity`; CONTRIBUTING and ci.yml must not mention `verify.phase100`/`phase101` | claim in allowlisted file | stays |
| A8 | `test/release/consumer_smoke_test.exs:206-215` | in a real consumer, `mix verify.package` gives `The task "verify.package" could not be found` | behavior | stays; executable proof of the contract premise "not runnable from the Hex package" |
| A9 | `test/release/package_contents_test.exs:253-275`, `:277-297` | no `verify*` file under `lib/mix/tasks`; no extra or lib file contains `Mix.Tasks.Verify` | narrower cousin of the invariant (module names only) | stays; the invariant generalizes it to task names across all shipped files |
| A10 | `phase99_contract_test.exs:28-33`, `phase98_contract_test.exs:24-30`, `readiness_contract_test.exs:66-67` | CONTRIBUTING contains `mix verify.adopter`, `mix verify.adopter --live` (and env tokens in phase98) | claim in allowlisted file | stays (allowlisted) |
| A11 | `docs_contract_test.exs:883`, `:886-900`, `:871-875` | CONTRIBUTING names `mix scrypath_ops.saved_searches.validate`, `mix verify.ops_ui`, `mix verify.phoenix_example` rows | claim in allowlisted file | stays (allowlisted) |

## Table B: pins that demand a repo-only task string in a shipped doc (the TRUTH-01 inventory)

Replacement design: (i) the invariant (`test/release/shipped_docs_contract_test.exs`); (ii) for each owner guide that documents the fast/live split (support guide, intake guide, operator-support) one positive assertion that the mention exists and is qualified; (iii) the CONTRIBUTING pins stay as they are.

| # | Pin (file:line) | Reads | Asserts | Type | Proposed fate |
|---|-----------------|-------|---------|------|---------------|
| B1 | `readiness_contract_test.exs:41` | support guide | contains `mix verify.adopter` | claim ("guide documents the fast/live split") | rewrite: at least one unit of the support guide mentions `verify.adopter` and every such unit passes the qualifier (equal or stronger) |
| B2 | `readiness_contract_test.exs:64-65` | README | contains `mix verify.adopter`, `mix verify.adopter --live` | claim | replace by invariant (README must not name it unqualified); the CONTRIBUTING half `:66-67` stays (A10) |
| B3 | `docs_contract_test.exs:316-319` | README | `guides/support-and-compatibility.md` + `mix verify.adopter` | claim | split: route token re-pointed to the README contract test (HexDocs URL form, Plan 04); task token covered by the invariant |
| B4 | `phase98_contract_test.exs:11-14` | README | `mix verify.adopter`, `mix verify.adopter --live` | claim | replace by invariant (as B2) |
| B5 | `phase98_contract_test.exs:16-22` | support guide | `mix verify.adopter`, `--live`, `SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT`, `SCRYPATH_MEILISEARCH_URL` | claim | env tokens stay; task tokens become the B1 positive qualified assertion |
| B6 | `phase99_contract_test.exs:21-26` | README | `guides/support-and-compatibility.md`, `guides/outside-adopter-intake.md`, `mix verify.adopter`, `--live` | claim | split as B3: task half by invariant; the `guides/...md` route substrings re-pointed in Plan 04 |
| B7 | `phase99_contract_test.exs:35-39` | support guide | `mix verify.adopter`, `--live`, `examples/phoenix_meilisearch/README.md` | claim | B1 for the task tokens; the example path still appears inside an absolute GitHub URL |
| B8 | `phase99_contract_test.exs:41-46` | intake guide | `README.md`, `guides/support-and-compatibility.md`, `mix verify.adopter`, `--live` | claim | B1 for the task tokens (the intake guide's two bullets are qualified in Plan 01) |
| B9 | `docs_contract_test.exs:510` | README | `mix verify.phase11` (inside the "Versioning and upgrades" pin group `:505-517`) | claim | removed with the README trim; replaced by a positive assertion that CONTRIBUTING's verify matrix names it (Plan 04) |
| B10 | `docs_contract_test.exs:879` | README | `mix verify.ops_ui` ("README surfaces canonical ops verification", Phase 53) | claim | replace: README states the operator UI lives in the source checkout and is not part of the Hex package; `mix verify.ops_ui` stays demanded in CONTRIBUTING by `:886-900` (A11) (Plan 04) |
| B11 | `docs_contract_test.exs:1231-1236` | `docs/operator-support.md` | `mix verify.phase14`, `20`, `26`, `28`, `11` | claim (only place these gates are documented; CONTRIBUTING has no phase14/20/26/28 row) | kept, qualified in place (Plan 01): the pin keeps passing, the invariant is satisfied |
| B12 | `docs_contract_test.exs:633` | `guides/operator-mix-tasks.md` | `mix scrypath_ops.saved_searches.validate` | claim | kept, qualified in place (Plan 01); the derivation includes `scrypath_ops/lib/mix/tasks` |
| B13 | `test/mix/tasks/dependency_boundary_contract_test.exs:238` | support guide | exact link `[ScrypathOps production runbook](../scrypath_ops/README.md#production)` (dead `readme.html#production` on HexDocs) | claim (a broken link form) | rewrite together with the link fix (absolute GitHub URL), keeping "the support guide links the runbook" (Plan 03) |

Also read, not demanded: `docs_contract_test.exs:723-736` (golden path: `phoenix-example`, `postgres:16-alpine`, `getmeili/meilisearch:v1.15`) does not pin `mix verify.phoenix_example`, so qualifying the golden-path CI bullet keeps it green.

## Table C: README pin ledger (every test that reads `README.md`)

Absolute HexDocs links remove every `guides/<name>.md` substring from the README. Tokens marked "only README" have no other owner today (checked against `guides/*.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md`, `docs/*`, example README). All rows are handled by Plans 02 and 04; none is edited in Plan 01.

**C1. Route-index pins** (the README stops being the route index; owner is the HexDocs sidebar, Phase 193 regroup):

| # | Pin | Tokens | Proposed fate |
|---|-----|--------|---------------|
| C1.1 | `docs_contract_test.exs:133-137` | `guides/jtbd-and-user-flows.md`, `jobs and adoption path` | re-point to `mix.exs` extras membership of that guide (the sidebar is the route) |
| C1.2 | `docs_contract_test.exs:153-168` (README half `:163-166`) | `guides/request-edge-search.md`, `Request-edge search` | same |
| C1.3 | `docs_contract_test.exs:177-200` (README half `:197-200`) | `guides/composing-real-app-search.md`, `real-app composition` | same |
| C1.4 | `docs_contract_test.exs:243-269` | `## Choose a route` plus 21 guide, example and ops-readme path tokens | delete the README half only after the extras-membership replacement exists; the jtbd-guide half (`:271-291`) stays |
| C1.5 | `docs_contract_test.exs:443-458` | opener, `## Installation` before `## Choose a route` before `## Quick Path`, `~> 0.3`, no `{:req, "~> 0.5"}`, no `{:scrypath, path: "../scrypath"}`, `Scrypath owns its internal transport dependency`, `Add Oban only when you choose`, `field :status, :string`, `guides/golden-path.md` | rewrite ordering to `## Installation` before `## Quick Path`; keep the rest by keeping the tokens (see C3) |
| C1.6 | `docs_contract_test.exs:489-517` | `**Start here:**`, `guides/golden-path.md`, `## Versioning and upgrades`, `mix verify.phase11`, `docs/releasing.md`, `Choose **\`:inline\`**`, `guides/sync-modes-and-visibility.md`; orders `## Sync modes` < `## Search`, `## Versioning and upgrades` < `## Search` | re-point: golden path to the README contract test (HexDocs URL), sync modes to the one-line replacement, versioning to the owner-map decision (one sentence, changelog URL; release process owned by `docs/releasing.md`) |
| C1.7 | `docs_contract_test.exs:838-841` | `](guides/sync-modes-and-visibility.md)`, regex `exact return contract, lifecycle, and recovery guidance` | re-point to the new onward link (HexDocs URL) and keep the phrase in the one-line sync-modes replacement, or move the phrase pin to the sync guide |
| C1.8 | `docs_contract_test.exs:705-712` | README contains `cd examples/phoenix_meilisearch` (or the smoke path) and order `cd examples/phoenix_meilisearch` < `./scripts/smoke.sh` | the Integration smoke section is removed; the same pins already hold for CONTRIBUTING (`:714-721`) and `./scripts/smoke.sh` is in `guides/golden-path.md`; drop the README half, recorded |
| C1.9 | `readiness_contract_test.exs:12,19`; `phase99_contract_test.exs:186,202`; `phase110_contract_test.exs:33`; `docs_contract_test.exs:317` | `guides/support-and-compatibility.md`, `guides/outside-adopter-intake.md`, `support-and-compatibility.md` | normative-routing pins ("non-owner surfaces route to the support authority"): the README keeps linking to the support guide as one onward link; accept the HexDocs form `https://hexdocs.pm/scrypath/support-and-compatibility.html` through one small helper (Plan 04); the `outside-adopter-intake` route may move to the support guide's own pin (`readiness_contract_test.exs:21`) |

**C2. Claims that only the README carries** (need an owner before the trim; README-03):

| # | Token(s) | Pin | Today's other owner | Proposed disposition |
|---|----------|-----|---------------------|----------------------|
| C2.1 | `Use backfill when` | `docs_contract_test.exs:122-130` (token `:126`) | none (`Use managed reindex when` is also in `guides/meilisearch-concepts.md`) | move 1 sentence into `guides/drift-recovery.md`, re-point pin (Plan 02) |
| C2.2 | `does not heal anything by default`, `retry, backfill, or reindex deliberately` | `docs_contract_test.exs:531-538` | none in guides (ARCHITECTURE has "Reconcile is not an auto-heal button", pinned at `:520-529`) | move the sentence into `guides/drift-recovery.md` or retire the README half with a recorded pointer to ARCHITECTURE (Plan 02) |
| C2.3 | `Detect drift before deciding`, `stale search hits whose hydrated records are now missing`, `failed or discarded sync work` | `docs_contract_test.exs:551-559` (`document-count mismatches` and `stale deletes` also in ARCHITECTURE) | none | move the drift bullets into `guides/drift-recovery.md`, re-point (Plan 02) |
| C2.4 | `They do not create a second operator product surface.` | `docs_contract_test.exs:1216-1229` (README token `:1222`) | ARCHITECTURE has the equivalent sentence, pinned in the same test | retire the README half, recorded (Plan 02) |
| C2.5 | `accepted work may not yet be visible in search` | `docs_contract_test.exs:847-851` | sync guide has `Accepted work is not the same thing as search visibility.` | keep the sentence in the quick-path eventual-consistency line (README-02 text anyway) (Plan 04) |
| C2.6 | `Scrypath owns its internal transport dependency`, `Add Oban only when you choose` | `docs_contract_test.exs:453-454` | `guides/getting-started.md` says "Scrypath also owns its internal transport dependency" | keep one sentence in Installation, or re-point to getting-started (Plan 04) |
| C2.7 | `result.omitted` | `backfill_contract_docs_test.exs:45-47` | `guides/sync-modes-and-visibility.md` is pinned for `omitted` at `:50-58` | retire the README half, recorded (the owner pin exists) (Plan 02) |
| C2.8 | `Meilisearch-first in v1` | `telemetry_test.exs:329` (the test begins `:313`) | none | keep in the "when it does not fit" line (cheapest) (Plan 04) |

**C3. Tokens that stay valid if the new README keeps them** (cheap; Plan 04 keeps them): opener `Scrypath, the Ecto-native search indexing library` (`docs_contract_test.exs:444`, `phase112_contract_test.exs:55`); `{:scrypath, "~> 0.3"}` and the absence of `{:scrypath, "~> 1.0"}`, `{:req, "~> 0.5"}`, `{:scrypath, path: "../scrypath"}` (`docs_contract_test.exs:350,447-449`, `phase99_contract_test.exs:155`); `field :status, :string` (`docs_contract_test.exs:485`); lowercase `release-backed guidance` and `main may contain unreleased changes` (`phase99_contract_test.exs:178-179`); `scope-and-reopen-policy.md`, `concrete production bug`, `reviewed outside-adopter evidence`, `deliberate strategic product decision` (`phase112_contract_test.exs:55-59`, one sentence); README must NOT contain the lifecycle chain `requested -> enqueued -> processing -> ...` (`docs_contract_test.exs:460-466`); README must NOT contain the tuple literals `1.17.3`, `26.2.5`, `1.19.0`, `28.1` as substrings (`phase110_contract_test.exs:22,36`, `phase99_contract_test.exs:196-212`); misleading patterns absent (`phase112_contract_test.exs:43-51`, for example `immediately searchable`, `always current`); no internal-ID patterns (`docs_contract_test.exs:94-119`); elixir fences must parse (`docs_contract_test.exs:1244-1252`); no telemetry event table rows (`telemetry_contract_test.exs:275-282`).

**C4. Structural README pin (the header pin, preserved verbatim by the trim):** `test/release/package_metadata_test.exs` module `Scrypath.Release.BuiltDocsBrandTest`: `:290-331` (README header uses commit-pinned raw URLs whose bytes match the committed files), `:261-266` (built `readme.html` carries the exact `srcset` and `src`), `:358-362` (retired brand directory name absent), `:423` (sidebar logo). Consequence: README lines 1-7 stay byte-identical, no other ` src="` or ` srcset="` anywhere in the README (even in a fence), badges stay markdown images. `test/mix/tasks/brand_pin_contract_test.exs` does not read the root README.

## Table D: contract text (TRUTH-02)

`.planning/PROJECT.md:68-86` "Canonical Adopter Contract", "Support and proof policy", lines 75-76 today:

- "`mix verify.adopter` is the canonical adopter proof spine."
- "Since Phase 183, repository-only `mix verify*` tasks (including `mix verify.adopter`) run from a source checkout. They live in `dev/mix/tasks/`, compile only under `MIX_ENV=test`, and are not part of the Hex package built from this source, which ships only the public `mix scrypath.*` operator tasks. The published 0.3.17 still contains them until a separate maintainer-confirmed release."

The "published 0.3.17" sentence is stale: `CHANGELOG.md` (0.3.18, 2026-11-19) records that the repository-only `mix verify*` maintainer tasks are no longer shipped in the Hex package. No test reads these bullets today. Tests that read PROJECT.md pin only other tokens, which the Plan 02 edit must keep: `AUDT-01` (`docs_contract_test.exs:1307`), `97-SCOPE-GUARD.md` (`:1372`), `maintenance-and-evidence mode`, `outside-adopter evidence`, `concrete production bug`, `tenant-preserving ecommerce readiness regression proof`, `aligned roadmap/JTBD truth` (`phase108_contract_test.exs:46-60`), and `no path-scoped required promotion` (`phase111_contract_test.exs:30,71,79`). Handled by Plan 02 (contract text, in the same commit as the pin rewrites).

## Mention inventory

Unit = sentence of a plain paragraph, list item, heading, table row, or fenced block judged with the sentence directly above it. Q = qualified, U = unqualified at HEAD `1d7573e5` (probe: `violations=28` before Plan 01 edits; the sentence rule reports each operator-support table row and gate line separately, so it is higher than the research's block count of 21). "Action taken" is filled in as Tasks 2 and 3 execute.

| File:line | Name(s) | Q/U at HEAD | Planned action | Plan | Action taken |
|-----------|---------|-------------|----------------|------|--------------|
| `README.md:31` | `verify.adopter` | Q | keep; removed later by the README trim | 04 | |
| `README.md:36` | `verify.ops_ui`, family `verify.*` | U | qualify inside the bullet; removed by the trim | 01 task 2, 04 | |
| `README.md:118` | `verify.phase11` | U | qualify in the first sentence of the versioning paragraph; removed by the trim | 01 task 2, 04 | |
| `README.md:198` | `verify.meilisearch_smoke` (fence) | Q (lead-in at `:196`) | keep; removed by the trim | 04 | |
| `README.md:204` | `verify.meilisearch_smoke` | U | qualify inside the sentence; removed by the trim | 01 task 2, 04 | |
| `guides/support-and-compatibility.md:123` | qualifier sentence only | n/a | exists; it does not qualify a sibling sentence | - | |
| `guides/support-and-compatibility.md:125` | family `verify.*` | U | qualify in the same sentence, no reflow (Pitfall 7) | 01 task 2 | |
| `guides/support-and-compatibility.md:131,132` | `verify.adopter` (two bullets) | U | qualify each bullet | 01 task 2 | |
| `guides/outside-adopter-intake.md:28` | qualifier sentence only | n/a | exists; a sibling does not count | - | |
| `guides/outside-adopter-intake.md:32,33` | `verify.adopter` (two bullets) | U | qualify each bullet | 01 task 2 | |
| `guides/golden-path.md:137` | `verify.phoenix_example` | U | qualify inside the CI bullet; keep pinned env names and image tag | 01 task 2 | |
| `guides/operator-mix-tasks.md:98` | `scrypath_ops.saved_searches.validate` (heading) | U | qualify inside the heading text | 01 task 2 | |
| `guides/operator-mix-tasks.md:102` | `scrypath_ops.saved_searches.validate` (fence, command at `:104`) | U | qualify through the sentence directly above (end of line 100) | 01 task 2 | |
| `docs/operator-support.md:7` | `verify.adopter` | Q | keep | - | |
| `docs/operator-support.md:13,14,15` | `verify.phase14`, `verify.phase28`, `verify.phase11` | U | qualify each numbered item | 01 task 3 | |
| `docs/operator-support.md:56` | five gate names (fence, commands `:57-61`) | U | add a lead-in whose last sentence is qualified | 01 task 3 | |
| `docs/operator-support.md:66-70` | `verify.phase14`, `20`, `26`, `28`, `11` (table rows) | U | qualified sentence directly above the table | 01 task 3 | |
| `docs/operator-support.md:72` | `verify.phase11` | U | qualify inside the sentence | 01 task 3 | |
| `docs/search-backend-sre.md:76` | `verify.phase13` | U | qualify inside the bullet | 01 task 3 | |
| `docs/jtbd-gap-map.md:78` | `verify.adopter` | Q | keep | - | |
| `docs/jtbd-gap-map.md:121` | `verify.phase108` | U | reword (history line) or qualify; keep phase112 reopen-trigger phrases | 01 task 3 | |
| `CHANGELOG.md` | 23 history units | n/a | exempt (named exemption) | - | |
| `mix.exs` | `preferred_envs` registrations | n/a | exempt for registration lines only | - | |
| `CONTRIBUTING.md` (53 units), `docs/releasing.md` (24 units) | many | n/a | allowlisted by the locked decision | - | |
| `lib/**`, `ARCHITECTURE.md`, `SECURITY.md`, `docs/local-demo-docker-dx.md`, 20 other guides | none | clean | none | - | |

The CONTEXT list ("five files, README line 31 qualified") understated the surface: it missed `README.md:36,118,204`, `docs/operator-support.md:13-72`, `docs/search-backend-sre.md:76`, `docs/jtbd-gap-map.md:121`, `guides/golden-path.md:137`, `guides/support-and-compatibility.md:125` and, once the derivation includes `scrypath_ops/lib/mix/tasks`, `guides/operator-mix-tasks.md:98,102`.

## Fate log

One row per pin. Columns: pin, type, fate, owner of the intent afterwards, replaced by, plan, commit. The commit column is filled as each plan lands (no amend). Plan 01 edits no pin: every row below is either `stays` or owned by a later plan.

| Pin | Type | Fate | Owner of the intent afterwards | Replaced by | Plan | Commit |
|-----|------|------|--------------------------------|-------------|------|--------|
| A1 verify_adopter_test.exs | behavior | stays | task tests | unchanged | - | |
| A2 readiness_contract_test.exs:46-61 | behavior | stays | task help output | unchanged | - | |
| A3 docs_contract_test.exs:336-343 | wiring | stays | task source | unchanged | - | |
| A4 phase99_contract_test.exs:73-87 | wiring | stays | task docs | unchanged | - | |
| A5 mix.exs registrations and CONTRIBUTING gate rows | wiring | stays | CONTRIBUTING, `mix.exs` | unchanged | - | |
| A6 workflow_wiring_test.exs:1461-1462 | wiring (history) | stays | CHANGELOG (exempt) | unchanged | - | |
| A7 releasing.md and phase100/101 guards | claim | stays | `docs/releasing.md`, CONTRIBUTING | unchanged | - | |
| A8 consumer_smoke_test.exs:206-215 | behavior | stays | consumer smoke | unchanged | - | |
| A9 package_contents_test.exs:253-297 | wiring | stays | package contents test | unchanged; the invariant generalizes it | - | |
| A10 CONTRIBUTING halves (phase98, phase99, readiness) | claim | stays (allowlisted) | CONTRIBUTING | unchanged | - | |
| A11 CONTRIBUTING task rows (docs_contract) | claim | stays (allowlisted) | CONTRIBUTING | unchanged | - | |
| B1 readiness_contract_test.exs:41 | claim | rewrite | support guide | qualified-mention assertion via `ShippedDocs` | 02 | |
| B2 readiness_contract_test.exs:64-65 | claim | replace by invariant | CONTRIBUTING (A10) | `shipped_docs_contract_test.exs` | 02 | |
| B3 docs_contract_test.exs:316-319 | claim | split | README contract test (route), invariant (task) | `readme_contract_test.exs`, `shipped_docs_contract_test.exs` | 04 | |
| B4 phase98_contract_test.exs:11-14 | claim | replace by invariant | CONTRIBUTING (A10) | `shipped_docs_contract_test.exs` | 02 | |
| B5 phase98_contract_test.exs:16-22 | claim | rewrite (env tokens stay) | support guide | qualified-mention assertion | 02 | |
| B6 phase99_contract_test.exs:21-26 | claim | split | invariant (task half); README contract test (route half) | `shipped_docs_contract_test.exs`, `readme_contract_test.exs` | 02, 04 | |
| B7 phase99_contract_test.exs:35-39 | claim | rewrite | support guide | qualified-mention assertion | 02 | |
| B8 phase99_contract_test.exs:41-46 | claim | rewrite | intake guide | qualified-mention assertion | 02 | |
| B9 docs_contract_test.exs:510 | claim | replace (positive CONTRIBUTING assertion) | CONTRIBUTING verify matrix | new assertion | 04 | |
| B10 docs_contract_test.exs:879 | claim | replace (claim kept, task name dropped) | README one-liner, CONTRIBUTING (A11) | README contract test | 04 | |
| B11 docs_contract_test.exs:1231-1236 | claim | kept, qualified in place | `docs/operator-support.md` | the invariant now covers the qualification | 01 task 3 | |
| B12 docs_contract_test.exs:633 | claim | kept, qualified in place | `guides/operator-mix-tasks.md` | the invariant now covers the qualification | 01 task 2 | |
| B13 dependency_boundary_contract_test.exs:238 | claim | rewrite with link fix | support guide | absolute GitHub URL assertion | 03 | |
| C1.1 to C1.9 route-index pins | claim | re-point | HexDocs sidebar (`mix.exs` extras), README onward links | README contract test, extras membership | 02 (owner map), 04 | |
| C2.1 to C2.4, C2.7 README-only claims | claim | move claim to owner or retire with owner pin | `guides/drift-recovery.md`, concepts guide, ARCHITECTURE, sync guide | owner pins | 02 | |
| C2.5, C2.6, C2.8 kept README lines | claim | kept in the trimmed README | README | README contract test | 04 | |
| C3 stay-valid tokens | claim | kept | README | existing pins | 04 | |
| C4 header pin | wiring | stays | README lines 1-7 | unchanged | 04 | |
| D contract text (PROJECT.md) | claim | rewrite with agreement test | PROJECT.md, `shipped_docs_contract_test.exs` | agreement test | 02 | |
