# Phase 196: Fixtures and three adopters - Research

**Researched:** 2026-11-21
**Domain:** a dev/test-only Mix path dependency (`fixtures/scrypath_fixtures`) that emits raw Meilisearch task maps and Oban job maps for three fictional adopters, consumed by `scrypath_ops` tests; its Mix, Docker, CI-classifier and package-boundary footprint; real Meilisearch payload recording
**Confidence:** HIGH for dependency/graph behaviour, builder shapes, the fake-client contract, the DB-free check task and the rendered-posture tracer (every one of these ran in a scratch copy this session); MEDIUM for hosted CI cost (derived from the cache-key code and Phase 195's measurements, not measured for this change)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Recorded maintainer decisions (adopted 2026-11-21; not re-opened here)
- ADR 0002: a top-level `fixtures/scrypath_fixtures` Mix project, `scrypath_ops` takes it as a path dependency with `only: [:dev, :test]`, it depends only on `scrypath`; the root package `files:` allowlist keeps it out of the tarball — **Reversibility:** costly — ADR 0002; undoing means moving modules and touching the ops lock, CI path classifier and Docker COPY stages
- Exit rule (recorded in the plan and in the project README): fold the project into `scrypath_ops/catalog/` if no second consumer appears by Phase 197; module names stay stable so folding is a rename
- Three adopters only (Shopadelic, Logistify, Wikily); Clinicly and Chatly sets are Phase 198; nothing is copied from the six sibling brand repos (Scrypath-owned data in the adopters' shapes)
- Tracer bullet first: the Logistify builder through the fake client to a rendered posture with a deep queue and nothing failed, before any other builder exists
- The host's `phase173` fixtures and their `?scenario=` branches stay (four host e2e specs use them) with a recorded deletion trigger
- Findings F1 (task history truncated at 1,000), F2, D2 and the test hygiene items are handed to the maintainer, not fixed; no root `lib/` change; PR titles `docs`, `chore`, `test` or `ci`; never stage `.planning/config.json`, `.planning/state.json`, `.impeccable/config.json`
- Realism rules from prep note B section D4 (verified against Meilisearch docs and Scrypath source): no per-tenant drift, no "N minutes of lag", no per-document size limit, no out-of-order replay overwrite on the Oban path, no failure the library cannot produce

#### Builder contract (prep note B D2, D6)
- Pure: no `DateTime.utc_now`, `Date.utc_today`, `:rand`, `System.*`, no Repo; every time is `now` minus an offset; one pinned preview epoch lives in one function
- Closed enums with raw wire shapes only (task `type` and `status` from the documented lists, Oban job states and the real worker modules `Scrypath.Oban.UpsertWorker` / `DeleteWorker` / `Sync.RelatedWorker`); unknown values raise `FunctionClauseError`; builders never construct `State` or `FailedWork`
- Defaults from Scrypath config and `Scrypath.Meilisearch.index_name/2`, not literals; the fake client honors `limit`, orders newest first and sets `next`
- Failure strings come from a closed table; each entry carries `source:` pointing at a real Meilisearch error code (from the once-recorded payloads) or a Scrypath path
- Hostile text is stored as escapes (bidi override, ZWJ emoji, NFC vs NFD, CJK, Arabic, a 511-byte id, an unbroken 200-character token, markup text); a lint test fails on raw format characters in fixture source
- Realistic ordinary data first; stress cases are separate named variations

#### Verification shape
- `check_fixtures` is DB-free, runs first in the `test` alias of each consumer, and has a planted failing case; two renders with different `now` differ only in time-derived text
- Normalizer round trip: every scenario passes through `Scrypath.sync_status/2`, `failed_sync_work/2` and `Posture.summary/3` and returns `{:ok, _}` or a designed error tag; wire guard through `Scrypath.Meilisearch.TaskPayload.normalize/2`
- `package_metadata_test` asserts `fixtures/` never ships (already refuted for the tarball files list in Phase 195; extend to the new top-level directory); the CI path classifier and `package_contents_test` decisions for the new directory are made and recorded; add `fixtures/` to the namespace fence scope if it scans paths

#### Decided autonomously
- [Plan split] Q: "How many plans?" -> Selected: "Up to four per the roadmap estimate: (1) project, tracer bullet Logistify, fake client, check task, package refute; (2) recorded Meilisearch payloads and the closed failure table; (3) Shopadelic and Wikily; (4) hostile text, bulk generator digest, provenance labels, path classifier and package decisions" — plan boundaries are planning metadata and cheap to re-cut
- [Recording method] Q: "How are real payloads recorded?" -> Selected: "A task-scoped Meilisearch Docker container run once, raw JSON committed as small files, container and image removed afterward per AGENTS.md" — the recording is a one-time artifact, easy to redo
- [Bulk generator] Q: "How is bulk data generated?" -> Selected: "A tiny deterministic pick function over `:erlang.phash2` with a golden digest; no Faker or StreamData dependency" — copy over dependency, small and local
- [Ordinary data content] Q: "What are the adopters' ordinary records?" -> Selected: "Plausible product, shipment and wiki-page records in each adopter's domain, labelled fictional" — data content is cheap to edit

### Claude's Discretion
- Module and file names under `ScrypathFixtures.*`, exact scenario ids, which Phase 173 posture scenarios migrate in this phase versus later, and where the recorded Meilisearch JSON lives

### Deferred Ideas (OUT OF SCOPE)
- Clinicly (real denials only) and Chatly (reindex swap, CJK) sets: Phase 198
- Migrating all 16 Phase 173 posture scenarios and deleting the host copies: later, with the recorded deletion trigger
- Findings F1, F2, D2 and the dashboard_routes guard defect: handed to the maintainer
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FIX-01 | `fixtures/scrypath_fixtures` project; pure builders taking `now`; real `Status`/`FailedWork`/`Posture` do the normalizing; Logistify tracer first; recorded exit rule | N1-N5 (path-dep behaviour), N10 (exact raw shapes), N13 (what the builders need), tracer run and `Status` numbers in "Tracer bullet" |
| FIX-02 | Real Meilisearch payloads recorded once from a task-scoped Docker run; closed failure table with `source:`; hostile text as escapes; nothing the library cannot produce | "Recorded Meilisearch v1.15.2 payloads" (recording ran this session), "Closed failure table", N11 (indexSwap invisibility), N17 (recording cleanup) |
| FIX-03 | Shopadelic, Logistify, Wikily with named states, ordinary data first, stress separate, nothing copied from sibling repos | "Adopter states that the real code can produce" (drift proven through `index_contract_drift/2`), N12 (settings injection), N18 (empty-index reachability) |
| FIX-04 | DB-free `check_fixtures` first in the consumer `test` alias with a planted failure; two renders differ only in time text; fixtures never ship; classifier and package decisions recorded; phase173 stays with a deletion trigger | N7-N9 (classifiers, package, phase173 identity hashing), N15 (render determinism), N16 (check task placement and ordering), "Validation Architecture" |
| FLOW-01..04 | Standing: no release/PR-title rule, plan caps, no staged config files and pre-push mirror, findings recorded not fixed | "Project Constraints", "Validation Architecture" lane mirrors, new finding F3 (indexSwap) for the maintainer |
</phase_requirements>

## Project Constraints (from AGENTS.md)

Root `AGENTS.md` and `scrypath_ops/AGENTS.md` (there is no `CLAUDE.md`) directives that bind this phase:

- **Pre-push confidence:** run the local mirror of each required lane on the exact commit before a push; say which part could not run. Several root contracts clone committed `HEAD` (including `test/release/ops_dependency_boundary_test.exs`, see N2), so commit the `fixtures/` tree before running them.
- **Cheap checks first:** format, the one changed test file, `node --test` for the classifier files, then the long suites. Never weaken what a check proves; every new check ships with a planted failing case that asserts its own cause (Pitfall 5 shows why).
- **Docker:** task-scoped names and labels; remove what the task created; never remove another project's resources. The pinned Meilisearch image already exists locally and backs the maintainer's retained preview, so it is not the task's to remove (N17).
- **Never stage** `.planning/config.json`, `.planning/state.json`, `.impeccable/config.json`; commit with explicit paths; PR titles `docs|chore|test|ci`; squash-merge a green PR without asking; no Hex release.
- **Copy over dependency:** no Faker, no StreamData, no new Hex package. This phase installs no external package.
- **Zero human UAT:** every success criterion has an executable check.
- **Recorded owner decisions outrank prep notes:** ADR 0002 and the three-adopter cut are not re-opened.
- `scrypath_ops/AGENTS.md`: `mix precommit` when done; `start_supervised!/1` for processes; no `Process.sleep/1`; **one module per file**; prefer `element/2`/`has_element?` and `LazyHTML` over raw-HTML assertions.

## Summary

The project shape works as ADR 0002 and prep note B recommended, and the research closed every unknown the prep notes flagged. A path dependency `{:scrypath_fixtures, path: "../fixtures/scrypath_fixtures", only: [:dev, :test]}` in `scrypath_ops/mix.exs` adds no lock entry (the three lock files are byte-identical after `deps.get`), converges with the existing `{:scrypath, path: ".."}` despite fixtures declaring `{:scrypath, path: "../.."}`, compiles in 0.58 s (cold full ops graph 27.2 s with it versus 26.5 s without), and is absent from every direct prod graph, mounted test and prod consumer, and the host graph in dev, test and prod (deps listing, `_build`, `.app` applications list, loadable modules). A task defined in the fixtures dependency runs first in the ops `test` alias with no database (0.54 s warm, verified with Postgres unreachable) and without compiling the ops app, and it sees edited fixture code.

The prep notes missed seven things that change the plan. (1) The direct cases of `test/release/ops_dependency_boundary_test.exs` archive a fixed path list from `HEAD` (`["mix.exs", "mix.lock", "lib", "priv", "scrypath_ops"]`, line 294), so without `"fixtures"` in it the direct dev and test builds fail at compile with `the dependency is not available`, while `deps.get --check-locked` still exits 0. (2) The existing `dependency_options!/2` reader returns `[]` for a path dependency's keyword options, so a boundary row for `only: [:dev, :test]` needs a new reader. (3) `scrypath_ops/mix.exs` is in the `manifests` of the `ops` and `ecommerce` BEAM cache graphs, so the one edit that adds the dependency cold-misses both caches even with no lock change (the Phase 195 +135 s mechanism); only the root graph is spared. (4) The Phase 173 fixture sources are identity-hashed into the Phase 185 preservation receipts (`scripts/ci/ecommerce_evidence.cjs:80-81`), so neither copy may be edited in this phase. (5) `index_contract_drift/2` accepts no operator-only injection keys, so a settings-drift scenario needs a per-state fake client module that carries its own applied settings. (6) The real Meilisearch v1.15.2 omits `indexSwap` tasks from every `indexUids`-filtered task list (recorded; results empty while `total` counts it), so Scrypath can never show a swap row: new finding F3 for the maintainer and a hard constraint on Phase 198's Chatly set. (7) Rendered pages carry per-render randomness (LiveView ids and tokens, plus `System.unique_integer` DOM ids at `ops_ui.ex:135,749,1340`), so the "two renders differ only in time text" test needs a normalizer, and its planted failure must assert its specific cause because the first version of the plant passed for the wrong reason.

A task-scoped Meilisearch recording ran (container `scrypath-p196-recording`, random loopback port, tmpfs data, image `getmeili/meilisearch:v1.15` resolving to 1.15.2) and was removed; `docker system df` is identical before and after. The recorded payloads, a working Logistify tracer through the real `Scrypath.sync_status/2` to a LiveViewTest-rendered `/ops/health`, and a Shopadelic drift report through the real `Scrypath.index_contract_drift/2` are in this document.

**Primary recommendation:** Plan 1 makes the single edit to `scrypath_ops/mix.exs` (dependency, `scrypath_fixtures.check` as the first `test` alias step, `preferred_envs`), adds the project with the Logistify tracer and the root boundary/classifier/formatter/archive edits listed in N1-N9, and proves the tracer with `FixtureEnv` plus the test clock file through `/ops/health`; later plans never touch `scrypath_ops/mix.exs` again, so only one PR cold-misses the BEAM caches.

## Architectural Responsibility Map

This is a Mix/Phoenix tooling phase, so tiers are the layers that own each capability.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Raw wire-shape builders (task and job maps), closed enums, hostile text, bulk pick | `fixtures/scrypath_fixtures` `lib/` | none | Pure data; depends only on `scrypath` (ADR 0002), so layering stops fixtures from referencing `ScrypathOps.*` |
| Fake Meilisearch client and Oban inspector | `fixtures/scrypath_fixtures` `lib/` | recorded JSON (conformance) | They are what the real `Scrypath` code calls through `meilisearch_client` and `oban_inspector` |
| Normalizing to `State`, `FailedWork`, `Posture` | root `lib/scrypath` and `scrypath_ops/lib` | none | Fixtures never construct these; that is the reachable-states guarantee |
| DB-free invariant check | Mix task inside the fixtures dependency | ops `test` alias (first step) | Runs without Repo and without compiling ops (N16) |
| Posture round trip and rendered tracer | `scrypath_ops` ExUnit (`LiveViewTest`) | `test/support/fixture_env.ex` | `Posture.summary` needs the started ops app (`ScrypathOps.TaskSupervisor`); fixtures cannot call it |
| Prod-graph absence, archive list, script lists | root `test/release` and `test/mix/tasks` | Docker boundary script | Lock absence is vacuous for a path dep; the proof is `.app`, `_build`, `mix deps`, loadable modules |
| Package exclusion | root `mix.exs` `files:` allowlist | `package_metadata_test`, `package_contents_test` | Explicit allowlist; `allowed_top_level` is derived from it |
| Path classification | `scripts/ci/*classifier*.cjs` and `ci.yml` | `compat_path_classifier.test.cjs` inventory | A new tracked top-level directory must pick a side (N7) |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `scrypath` (path `../..`) | 0.3.20 | The only dependency of the fixtures project; its `Status`, `FailedWork`, `Config`, `index_name/2` do the normalizing | ADR 0002; verified converging with ops's `{:scrypath, path: ".."}` [VERIFIED: scratch `deps.get` in dev, test and prod, no divergence message] |
| ExUnit, `Phoenix.LiveViewTest` | Elixir 1.19.0, OTP 28.5 locally (CI 1.19.0 / 28.1) | Round trip, tracer, determinism tests in `scrypath_ops` | Already the ops test stack [VERIFIED: `scrypath_ops/mix.exs`, scratch run] |
| `LazyHTML` | `>= 0.1.0`, `only: :test` (`scrypath_ops/mix.exs:60`) | DOM projection for the determinism comparison | Already present; `scrypath_ops/AGENTS.md` prefers it over raw-HTML matching |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Jason` (transitive via scrypath) | resolved in `scrypath_ops/mix.lock` | Decode recorded JSON at compile time | Recordings are embedded with `@external_resource` |
| `Calendar.strftime/2`, `DateTime.add/3` (stdlib) | 1.19.0 | Meilisearch-style timestamps (nine fractional digits, `Z`) | Builders; `DateTime.from_iso8601/1` accepts nine fractional digits and truncates to microseconds [VERIFIED: ran, returns `~U[2026-11-22 00:25:17.182220Z]`] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Task module in the fixtures dependency | Task in `scrypath_ops/lib/mix/tasks` (the `check_nav_contract` precedent) | The nav-contract task runs `Mix.Task.run("compile")` (compiles all of ops) and a task in ops `lib/` that names `ScrypathFixtures.*` fails the prod compile (`--warnings-as-errors` in the Dockerfile) because the module is absent there. Rejected |
| Fixture tests inside the fixtures project | Tests in `scrypath_ops/test` | A standalone fixtures test dir needs its own `mix.lock` (all of scrypath's deps), a Dependabot entry and a lane. Tests live in ops; the fixtures project has no `test/` and no lock |
| Faker / StreamData | `:erlang.phash2` pick function | Locked decision (copy over dependency) |

**Installation:** none. No Hex package is added, removed or upgraded; `scrypath_ops/mix.lock`, root `mix.lock` and `examples/scrypath_ecommerce/mix.lock` are byte-identical to `HEAD` after the change [VERIFIED: `diff` against the pre-edit copies in scratch; host `deps.get --check-locked` exit 0 in dev, test, prod].

**Version verification:** not applicable (no package). Toolchain: `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5` [VERIFIED: `mix --version`].

## Package Legitimacy Audit

No external package is installed by this phase, so the `gsd-tools package-legitimacy check` seam was not run (it supports only npm, pypi, crates and has no Hex mode, as Phase 195 also found).

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `scrypath_fixtures` | none (path dependency in this repository) | new | n/a | this repository | n/a | Approved: ADR 0002 |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none. No `checkpoint:human-verify` is required.

## Architecture Patterns

### System Architecture Diagram

```
 raw wire shapes (this phase)                       real code (unchanged, root lib/ and scrypath_ops/lib)
 ----------------------------                       ------------------------------------------------------
 ScrypathFixtures.Epoch.preview() --now--+
                                         v
  Logistify | Shopadelic | Wikily  --builders--> %Scenario{allowlist, scrypath_opts, now}
        |  Meili.task(%{type, status, ...})  (string keys, closed enums, FunctionClauseError otherwise)
        |  ObanJob.job(%{state, worker, ...}) (atom keys, string worker/queue/state, DateTime stamps)
        |  Failures.get(id) (closed table, each entry has source:)
        v
  scrypath_opts = [backend, sync_mode, oban_queue, index_prefix, meilisearch_url,
                   meilisearch_client: FakeMeilisearchClient(+per-state variants), meilisearch_tasks: [raw maps],
                   oban_inspector: FakeObanInspector,  oban_jobs: [raw maps]]
        |
        +--> mix scrypath_fixtures.check (DB-free, first in ops `test` alias, no ops compile)
        |       invariants (time order, attempts, index names, key sets vs recordings, source lint, digest)
        |       -> TaskPayload.normalize/2 (wire guard) -> Scrypath.sync_status/2 -> failed_sync_work/2 -> index_contract_drift/2
        |
        +--> ops ExUnit (DB sandbox; app started):  FixtureEnv.put(scenario) + test clock file
                -> ScrypathOps.Posture.summary(allowlist, opts, now)  /  LiveViewTest live(conn, ~p"/ops/health")
                -> assertions + two-renders-differ-only-in-time test (+ planted failure)

 packaging and graph boundary
 ----------------------------
  scrypath_ops/mix.exs: {:scrypath_fixtures, path: ..., only: [:dev, :test]}  (no lock entry)
    direct dev/test graph: present      direct prod graph: absent      mounted consumer / host graph: absent (any env)
  root mix.exs files: allowlist -> fixtures/ never ships;  Docker COPY . . copies it (inert in prod image, absent from prod graph)
```

### Recommended Project Structure
```
fixtures/scrypath_fixtures/
├── .formatter.exs                      # inputs: mix.exs + lib (so `mix format` works if run in place)
├── .gitignore                          # /_build/ /deps/ /erl_crash.dump (root .gitignore anchors /_build/ and /deps/ to the root)
├── README.md                           # exit rule, "fictional adopters", how to re-record, denylist words
├── mix.exs                             # app :scrypath_fixtures; deps: [{:scrypath, path: "../.."}] exactly; no lock, no test/
├── recordings/meilisearch-v1.15/       # raw JSON + PROVENANCE.md (NOT priv/: cannot leak into a release)
└── lib/
    ├── scrypath_fixtures.ex            # moduledoc only (a real module for the prod-absence probes)
    ├── scrypath_fixtures/epoch.ex      # the one pinned preview epoch
    ├── scrypath_fixtures/{meili,oban_job,scenario,scenarios,failures,hostile,bulk,check}.ex
    ├── scrypath_fixtures/{fake_meilisearch_client,fake_oban_inspector}.ex
    ├── scrypath_fixtures/{logistify,shopadelic,wikily}.ex  + one schema module per file under each adopter dir
    └── mix/tasks/scrypath_fixtures.check.ex
scrypath_ops/test/support/fixture_env.ex          # app-env + clock-file injection (restores on exit)
scrypath_ops/test/scrypath_ops/fixtures_*_test.exs, test/scrypath_ops_web/live/fixtures_*_test.exs
```
One module per file (`scrypath_ops/AGENTS.md`).

### Pattern 1: Builders emit wire shapes only (closed enums)
**What:** `Meili.task/1` and `ObanJob.job/1` pattern-match `type`/`status`/`state`/`worker` against closed lists in the function head; anything else raises `FunctionClauseError`. They return plain maps, never `State` or `FailedWork`.
**When to use:** every scenario. Statuses are the five documented ones; types are the five Scrypath reads. Oban states are exactly the seven `State.normalize_queue_state/1` knows.
**Example:** see "Code Examples" (ran in scratch).

### Pattern 2: Scenario = data; app env is the test's business
**What:** a scenario is `%Scenario{id, adopter, now, allowlist, scrypath_opts}` where `scrypath_opts` uses only keys `ScrypathOps.Schemas.scrypath_opts/0` forwards (`@scrypath_opt_keys`, `schemas.ex:10-14`: `backend repo meilisearch_url index_prefix sync_mode oban oban_queue meilisearch_api_key meilisearch_client oban_inspector meilisearch_tasks oban_jobs`). `test/support/fixture_env.ex` puts them into `:scrypath_ops` app env and writes a clock file. Fixtures never touch app env (Phase 197's per-session injection can then reuse `scrypath_opts` unchanged).

### Pattern 3: One fake client module per applied-settings state
`Scrypath.index_contract_drift/2` validates its options through `Config.resolve!` and rejects operator-only keys (`ArgumentError: unknown options [:applied_settings]`, verified), and `ScrypathOps.Schemas.runtime_opts/1` drops them (`schemas.ex:16-18`). So the only scenario-carrying channels are the client module, `meilisearch_url`, `meilisearch_api_key` and `index_prefix`. Use a small `__using__` macro (about 15 lines) that generates `tasks/2` (reads `config[:meilisearch_tasks]`) and `get_settings/2` (returns a module-level applied-settings map derived from the recorded default settings with `Map.merge/2`), and define one module per distinct state (for example `Shopadelic.AlignedClient`, `Shopadelic.DriftedClient`). No Agent, no global state (the existing `copy_stubs` use an Agent, which makes concurrent iframes race).

### Pattern 4: The check is a function, the Mix task is a shell
`ScrypathFixtures.Check.run/1` returns `{:ok, summary}` or `{:error, [problem_tuple]}` and takes `:scenarios`, `:now` and `:source_problems` overrides so tests can plant failures without a special mode; `Mix.Tasks.ScrypathFixtures.Check.run/1` is ten lines that print or `Mix.raise`.

### Anti-Patterns to Avoid
- **Lock-based absence checks for a path dependency:** a path dependency is never in any lock, so `Map.has_key?(lock, :scrypath_fixtures)` is vacuous (the mounted probe's `@forbidden_apps` lock check proves nothing for it). Use `.app`, `_build`, `mix deps`, `:code.which/1`.
- **Reusing `dependency_options!/2` for the path dependency** (N4).
- **A planted failure that only asserts "not equal"** (Pitfall 5).
- **Referencing `Scrypath.Oban.UpsertWorker` as a module:** it exists only `if Code.ensure_loaded?(Oban.Worker) and Code.ensure_loaded?(Oban.Job)` and Oban is not in the ops graph; use the strings.
- **A task in `scrypath_ops/lib/mix/tasks` that names fixtures modules** (prod compile break).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Normalizing raw maps to operator state | A fixture-side `State`/`FailedWork` constructor | `Scrypath.sync_status/2`, `failed_sync_work/2`, `index_contract_drift/2`, `ScrypathOps.Posture.summary/3` | The point of ADR 0002: only reachable states exist |
| Applied-settings payload | A hand-typed 20-key settings map | `recordings/.../settings_default.json` decoded, then `Map.merge/2` the few keys a state changes | The real default has 20 keys including nested `typoTolerance`, `faceting`, `pagination`; hand typing drifts |
| Posture DOM comparison | Regex over whole HTML | `LazyHTML` text projection plus a list of `data-*`/ISO attribute values, with a normalizer for ids | Already a test dependency; matches `scrypath_ops/AGENTS.md` |
| Time injection into a rendered LiveView | A new clock seam | `ScrypathOps.Clock` + `:test_clock_file` (existing, test builds only) | `clock.ex:9` reads `Application.fetch_env(:scrypath_ops, :test_clock_file)` at runtime; verified |
| Generating bulk rows | Faker/StreamData | `Enum.at(list, :erlang.phash2({seed, n, tag}, length(list)))` plus a golden digest of the picked output | Locked decision; the digest over the *output* catches any `phash2` drift on an OTP bump |
| Recording Meilisearch payloads | Paraphrasing docs | One task-scoped container run, raw JSON committed | Docs omit the `indexSwap`/`indexUids` behaviour entirely (N11) |

**Key insight:** every shape in a fixture must be copied from a recorded payload or a Scrypath source line, never typed from memory. The recording found four things no document states (swap visibility, empty-index list behaviour, the `invalid_search_filter` wording, `primary_key` inference error code).

## What the prep notes do not settle (read first)

Numbered N1-N18. Each was exercised this session unless tagged.

**N1. Dependency graph behaviour (resolves H's "U: Mix `only:` for a nested path dep").** [VERIFIED: scratch copy of tracked HEAD plus the dependency, `ASDF_ELIXIR_VERSION=1.19.0-otp-28`]
- `MIX_ENV=dev|test|prod mix deps.get` and `--check-locked` in `scrypath_ops` exit 0 and leave `mix.lock` byte-identical; root and host locks unchanged; host `deps.get --check-locked` exit 0 in dev, test, prod and `mix deps` there lists `scrypath_fixtures` 0 times in all three.
- Nested `{:scrypath, path: "../.."}` (fixtures) and `{:scrypath, path: ".."}` (ops) converge with no divergence message; keep the fixtures declaration exactly `{:scrypath, path: "../.."}` (any extra option such as `only:` could diverge).
- `mix deps` lists `* scrypath_fixtures (../fixtures/scrypath_fixtures) (mix)` in dev and test and not in prod; `_build/test/lib/scrypath_fixtures` exists, `_build/prod/lib/scrypath_fixtures` does not; `scrypath_ops.app` lists `scrypath_fixtures` in test and not in prod (`grep -o` of the `.app`).
- A mounted consumer (`{:scrypath_ops, path: ...}` through a bridge, the shape `create_consumer!/3` builds) in `test` and in `prod`: not in `mix deps`, no `_build` entry, `.app` of `scrypath_ops` lacks it, `Code.ensure_loaded?(ScrypathFixtures)` is `false`, `:code.which/1` is `:non_existing`, `:code.lib_dir(:scrypath_fixtures)` is `{:error, :bad_name}`. This holds even when `../fixtures/scrypath_fixtures` does not exist on disk (compile succeeds).
- Compile cost: `mix deps.compile scrypath_fixtures` 0.58 s (11 small files); cold full ops compile in an isolated build dir 27.2 s with versus 26.5 s without the dependency. `mix deps.unlock --check-unused` exit 0.

**N2. A missing path-dependency directory fails late, in two different places.** [VERIFIED]
- `mix deps.get --check-locked` exits 0 in dev, test **and prod** with `warning: missing dependency scrypath_fixtures (../fixtures/scrypath_fixtures)`.
- Direct `MIX_ENV=test mix compile` then fails: `Unchecked dependencies for environment test: * scrypath_fixtures (../fixtures/scrypath_fixtures) the dependency is not available` / `** (Mix) Can't continue due to errors on dependencies` (exit 1).
- **Consequence 1:** `archive_tracked_source!/3` in `test/release/ops_dependency_boundary_test.exs:293-294` archives `["mix.exs", "mix.lock", "lib", "priv", "scrypath_ops"]` from `HEAD` (filtered by `git ls-tree`). Add `"fixtures"`, or the direct dev/test cases fail at `compile` although `deps.get --check-locked` passed. The mounted cases use the working tree (`ops_source = repo/scrypath_ops`) and need nothing. Because it reads `HEAD`, the `fixtures/` tree must be committed before running `--include integration`.
- **Consequence 2 (Docker):** in `examples/scrypath_ecommerce/Dockerfile` the early blocks copy only `mix.exs` files (lines 16-17, 58-59, 96-97) and run `deps.get --check-locked` (lines 25-27, 64-66, 102-104); `COPY . .` (line 29) and `COPY --exclude=**/config/dev.exs . .` (lines 68, 106) precede every compile, and `.dockerignore` does not exclude `fixtures/`. So no Docker change is *required* for correctness. Recommended anyway (J): add `COPY fixtures/scrypath_fixtures/mix.exs ./fixtures/scrypath_fixtures/` to the three early blocks, so `deps.get` sees the manifest (no warning; a future Hex dependency in fixtures would otherwise break the lane at compile with "Unchecked dependencies"). The Docker builder stage (`MIX_ENV=dev`, line 14) and the `runtime_test` stage need the sources, so `.dockerignore` must **not** exclude `fixtures/`; add `fixtures/*/_build` and `fixtures/*/deps` next to the existing `examples/*/_build` lines for hygiene. The sources are inert in the prod image, the same decision Phase 195 recorded for `scrypath_ops/storybook` and `scrypath_ops/catalog` (GO-NO-GO "`.dockerignore` skipped"); the proof of absence is the prod graph, not the file tree. `verify-dependency-boundaries.sh` pins `COPY --exclude=**/config/dev.exs . .` (line 127), so do not alter that line.

**N3. Cache keys: one `scrypath_ops/mix.exs` edit cold-misses two BEAM caches (hosted cost).** [VERIFIED: `scripts/ci/beam_cache.cjs:14-32,100-120`; mechanism measured in Phase 195 GO-NO-GO; this change's hosted number is MEDIUM]
- `ops` and `ecommerce` graphs list `scrypath_ops/mix.exs` in `manifests`; `hashPaths` of it enters `manifests_digest`, which enters `compatibleDigest`, which prefixes **both** the downloads key and the resolved key with no fallback to an older digest. So the first `ops-ui` run and the first `ecommerce-mounted` run after the edit miss both caches, with or without a lock change. The `root` graph (`core`, `package`, `repository-contracts`, `backend`, `compat`, `deep-quality`, `coverage`) lists only root `mix.exs`, so it is unaffected.
- Phase 195 measured that mechanism at about +135 s inside `verify.ops_ui` (cold 517 s on the PR, 620 s on the first main run, warm 378 s). Expect the same shape for this phase's first PR run and first main run (see "Hosted cost" below). Do all `scrypath_ops/mix.exs` edits in plan 1.
- Compile cost of the dependency itself is below noise (N1). The ADR 0002 / prep note B exit ("if measured above about 60 s of cold CI time, fold") cannot be read from a cold number because the cache miss dominates it; evaluate the **warm rerun against a same-day control** (the Phase 195 method), and attribute the cold excess to CI-EFFICIENCY finding 26.

**N4. `dependency_options!/2` cannot read a path dependency's options.** [VERIFIED: ran the clause order on the real AST]
`test/mix/tasks/dependency_boundary_contract_test.exs:1151-1160`: the first clause `{^dependency, _version} -> []` matches `{:scrypath_fixtures, [path: "../fixtures/scrypath_fixtures", only: [:dev, :test]]}` (a literal 2-tuple whose second element is a keyword list) and returns `[]`; the 4th clause `{:{}, _, [^dependency, options]}` is dead (2-tuples are literals in the AST). Verified result on the real shape: `[]`. A fixtures row needs a reader that matches `{^dep, opts} when is_list(opts)` before the 2-tuple clause. Existing callers use 3-tuples (`{:esbuild, "~> 0.10", only: :dev, ...}`), so they are unaffected. Add the new reader and a planted manifest (unrestricted, `only: :dev`, `only: [:dev, :test, :prod]`, absent) in the same file, mirroring `storybook_dependency_violation/1` (lines 801-819).

**N5. Direct and mounted probes: what to add and what is vacuous.** `test/release/ops_dependency_boundary_test.exs`:
- Direct probe (lines ~480-490): `(:phoenix_storybook in applications) == storybook?` is the pattern to copy: `(:scrypath_fixtures in applications) == (env in ["dev", "test"])` and `module_available?(ScrypathFixtures) == (env in ["dev", "test"])`, with the module written as `Module.concat(["ScrypathFixtures"])` (the file avoids compile-time references to dev/test-only modules).
- Mounted probe: add `:scrypath_fixtures` to the forbidden-apps list **only** for the loaded/started check (`assert_absent_runtime_apps!`, `.app` check); the lock check is vacuous for it. Add `Module.concat(["ScrypathFixtures"])` to `@absent_modules` (it feeds `__ABSENT_MODULES__`).
- `ScrypathFixtures` must be a real module in `lib/scrypath_fixtures.ex` (moduledoc only) so a "present in dev/test" probe has something to find.
- Add a root `lib/` guard like `storybook_mentions/1` (lines 797-799): `lib/**` never mentions `ScrypathFixtures` or `scrypath_fixtures`.

**N6. Script and test coupling.** `examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh:658-663` builds `forbidden_deps` (`esbuild tailwind phoenix_live_dashboard telemetry_metrics telemetry_poller`, then `phoenix_storybook mdex mdex_native` when `"$environment" == "prod" || "$project_dir" == "/app/examples/scrypath_ecommerce"`), and line 697 has `forbidden_modules = [..., :telemetry_poller, PhoenixStorybook, MDEx]`. The test `"the Docker boundary script forbids the catalog in prod and host graphs and requires a 404"` (`dependency_boundary_contract_test.exs:739-775`) pins the literal `forbidden_deps="$forbidden_deps phoenix_storybook mdex mdex_native"` as a mutant source. Add the fixtures name as **a separate assignment inside the same `if`** (`forbidden_deps="$forbidden_deps scrypath_fixtures"`) so those mutants still apply, and append `ScrypathFixtures` to line 697. The `mix deps` line format `* scrypath_fixtures (../fixtures/scrypath_fixtures) (mix)` matches the script's `grep -Eq "^[*] $forbidden_dep[[:space:]]"` [VERIFIED: direct dev output]. Optional, prod only: `test ! -e /app/scrypath_ops/_build/prod/lib/scrypath_fixtures` next to the esbuild/tailwind check at lines 646-650 (`_build/test/lib/scrypath_fixtures` legitimately exists in the test image).

**N7. Classifier decisions (FIX-04), with evidence.**
- `scripts/ci/compat_path_classifier.test.cjs:140-196` (`IRRELEVANT_ENTRIES` at line 149) **fails** the moment a tracked top-level `fixtures/` exists: `unclassified: ['fixtures']` [VERIFIED: ran in a scratch git index with `fixtures/` added; 24 pass, 1 fail; baseline in the real repo 25 pass]. Fix: add `fixtures: "separate Mix project (dev and test only), compiled and tested through scrypath_ops"` to `IRRELEVANT_ENTRIES`. It is correct: root `mix test` never compiles it, so the advisory compat matrix skips a fixtures-only PR (`classify` returns `{run:false, reason:"no-relevant-path"}` [VERIFIED]).
- `ops-ui-path` already lists `fixtures/` (`.github/workflows/ci.yml:440`) and `test/mix/tasks/workflow_wiring_test.exs:1993` pins it (`~w(scrypath_ops/ lib/ dev/ brand/ language/ fixtures/ scripts/ci/ test/release/)`). Decision: keep, no edit.
- `scripts/ci/ecommerce_path_classifier.cjs` is an allowlist (`^(\.planning/|docs/|[^/]+\.md$)`): a fixtures-only PR returns `{run:true, reason:"non-allowlisted-path"}` [VERIFIED], so the Docker lanes run. Correct: the Docker build copies `fixtures/` and compiles it in two stages. Decision: keep.
- `scripts/ci/ui_literal_policy.cjs:10-15` roots (`scrypath_ops/lib`, `scrypath_ops/assets`, host `lib` and `assets`) do not include `fixtures/`; `.github/dependabot.yml` needs no entry (no own lock); `release-please-config.json` has no `exclude-paths`, so the title rule (FLOW-01) is what keeps a fixtures change from opening a release PR.
- Namespace fence: `dev/mix/tasks/verify.namespace_fence.ex` scans three fixed trees and `test/mix/tasks/verify_namespace_fence_test.exs:43` pins `scanned_dirs == ["lib/scrypath/", "scrypath_ops/lib/", "scrypath_ops/test/"]`. CONTEXT says add `fixtures/` if the fence scans paths; it does, so add `{"fixtures/", []}` to `@fence_rules` and update line 43 (two small edits). `scrypath_ops/test/support/fixture_env.ex` is already inside the scanned `scrypath_ops/test/`.
- Formatter: root `.formatter.exs` inputs list `scrypath_ops/{catalog,storybook}/**` (added by Phase 195) but not `fixtures/`; `mix format --check-formatted` in `core` would silently skip the new tree. Add `"fixtures/scrypath_fixtures/{lib}/**/*.{ex,exs}"` and `"fixtures/scrypath_fixtures/mix.exs"`. Credo (`.credo.exs` included `lib/ dev/ test/ mix.exs`) does not cover `scrypath_ops` either; no change.

**N8. Package and tarball decisions.** `test/release/package_metadata_test.exs:135-136` already has `refute "fixtures" in package_files` and `refute "storybook" in package_files` (added in Phase 195; the prep notes' "missing refute" is stale). `test/release/package_contents_test.exs:157-166` derives `allowed_top_level` from the first segments of `package[:files]`, so `fixtures` can never be allowed and `package_contents_test` needs **no** change (decision recorded). The literal refute is vacuous if the directory is renamed; strengthen with one test that `File.dir?("fixtures/scrypath_fixtures")` and that no `package[:files]` entry equals `"."`, `"fixtures"` or is a path prefix of `"fixtures/scrypath_fixtures"`. The shipped `.formatter.exs` already references paths absent from the tarball (`scrypath_ops`, `dev`, `test`), so the new input is harmless.

**N9. The Phase 173 fixture sources are identity-hashed; do not edit either copy.** `scripts/ci/ecommerce_evidence.cjs:65-81` `PRESERVATION_FIXTURE_FILES` includes `examples/scrypath_ecommerce/test/support/phase173_fixture_source.ex` (line 80) and `scrypath_ops/test/support/phase173_fixture_source.ex` (line 81); `fixtureOverlayDigest` (line 189) hashes them into the Phase 185 preservation receipts (`fixture_overlay_sha256`, line 806 mismatch reason `preservation_fixture_mismatch`). An edit or deletion changes that identity (AGENTS.md "Phase 185 verification correction"). Phase 196 therefore leaves both files and the `PostureLive` `:phase173_fixture` branches byte-identical and records the deletion trigger: "delete when the four host specs (`ops_reskin_contract.spec.ts:67-68`, `ui_iteration3.spec.ts:129`, `ui_followup.spec.ts:63`, `ui_baseline.spec.ts:72`) are ported to catalog scenarios or retired, and `PRESERVATION_FIXTURE_FILES` plus its receipts are updated in the same change".

**N10. Exact raw shapes.** (verbatim, from Scrypath source and the recording)
- **Meilisearch task map (string keys, 12 keys in v1.15.2):** `uid, batchUid, indexUid, status, type, canceledBy, details, error, duration, enqueuedAt, startedAt, finishedAt`. `TaskPayload.normalize/2` (`lib/scrypath/meilisearch/task_payload.ex:7-28`) requires an integer `"uid"` (or `"taskUid"`) and a status; `normalize_status` (lines 45-54) accepts `"enqueued"`, `"processing"`, `"queued"`, `"succeeded"`, `"failed"`, `"canceled"`, `"cancelled"` and treats anything else as `:unknown` (error). `State.from_backend_task/1` reads `"finishedAt"` only (`state.ex` `task_time_details/1`); `Translation.backend_attrs/3` reads `"error"` (`%{"message" => m}` else `%{"code" => c}` else the literal `"backend task failed"`, `translation.ex:112-120`) and `error["type"]` (`"invalid_request"` -> `:validation`, `"internal"` -> `:backend_rejected`, `"auth"` -> `:transport`, else `:unknown`, lines 181-188), plus `"type"` (`"documentAdditionOrUpdate"` -> `:upsert`, `"documentDeletion"` -> `:delete`, lines 89-91).
- **Closed task lists.** Statuses (docs, [CITED: meilisearch.com/docs/reference/api/tasks]): `enqueued`, `processing`, `succeeded`, `failed`, `canceled` (single l; Oban uses `cancelled`). Types Scrypath reads (`tasks.ex:14-32`): `documentAdditionOrUpdate`, `documentDeletion` (sync) plus `indexCreation`, `settingsUpdate`, `indexSwap` (index tasks). The docs list many more types; the builder list stays the five.
- **Task list response (what `GET /tasks` returns, and what the fake must return):** `{"results" => [...], "total" => n, "limit" => n, "from" => uid | nil, "next" => uid | nil}`, newest first. Scrypath calls `client.tasks(filters, config)` with `filters = [index_uids: [index], types: [...], limit: remaining]` plus `from: uid` only on a continuation (`tasks.ex:39-48`); the real client encodes `index_uids` as `indexUids`, `types`, `limit`, `from` (`client.ex:210-228`). `tasks.ex:69-87`: `next == nil` -> done; `observed >= limit` with a `next` -> `{:error, {:task_history_truncated, %{index_uid:, limit:, observed:, next:}}}`; default limit 1000 (`@default_task_history_limit 1_000`, line 12). Because Scrypath asks for the whole limit in one request, the `from` continuation branch is effectively unreachable against real Meilisearch; the fake still honors `from`.
- **Oban job map** as the repository's one real inspector builds it from `Oban.Job` (`examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex:7-33`): atom keys `id, state, worker, queue, args, errors, attempt, max_attempts, completed_at, scheduled_at, attempted_at`; `state`, `worker`, `queue` strings; `args` and `errors` string-keyed (JSON); the three timestamps `DateTime` or `nil`. `State.from_queue_job/1` maps `"available"`/`"scheduled"`/`"executing"` -> `:queued`, `"retryable"` -> `:retrying`, `"discarded"`/`"cancelled"` -> `:failed`, `"completed"` -> `:completed` (`state.ex:83-91`) and reads `completed_at` only for time; `Translation.queue_attrs/3` reads `attempted_at` (failed_at), `scheduled_at` (retryable next attempt), `attempt`, `max_attempts`, `args["operation"]` (`"upsert"`/`"delete"`, else the worker string), `args["document_ids"]` (list required for a retry action) and the last `errors` entry's `"error"` text (bounded to 500 characters, `@max_queue_reason_length 500`).
- **Oban args** (`lib/scrypath/oban/payload.ex:6-10,62-65`): `"operation"`, `"schema"` (`Atom.to_string(schema)`, so `"Elixir.Mod"`), `"backend"` (`"Elixir.Scrypath.Meilisearch"`), `"index"` (`backend.index_name/2`), `"sync_mode"` (`"oban"`), `"document_ids"`, `"document_count"`, optional `"meilisearch_url"`, `"index_prefix"`, `"repo"`. Worker strings (`lib/scrypath/oban/enqueue.ex:13-14`): `"Scrypath.Oban.UpsertWorker"`, `"Scrypath.Oban.DeleteWorker"`; related fan-out: `Scrypath.Sync.RelatedWorker` (`lib/scrypath/sync/related_worker.ex:2`).
- **Oban error entries** (Oban 2.24.2, `lib/oban/job.ex:582-590`, `lib/oban/exceptions.ex:27-31`): `%{"attempt" => n, "at" => iso8601, "error" => Exception.format(...)}` where the first line is `"** (Oban.PerformError) Scrypath.Oban.UpsertWorker failed with {:error, ...}"` followed by stacktrace lines.
- **State invariants** [VERIFIED: Oban 2.24.2 `lib/oban/queues/executor.ex:152-153` (`{:cancel, _reason}` sets state `:cancelled` and `error:`) and `:184-187` (`normalize_state/1`: `:failure` with `job.attempt >= job.max_attempts` becomes `:exhausted`)]: `{:cancel, reason}` yields state `cancelled` **with** an error entry, at whatever attempt the worker returned it (resolves B's "U: cancelled attempt counts"); a failure with `attempt >= max_attempts` is `exhausted` -> `discarded`; a failure below it is `retryable`. So: `retryable` implies `attempt < max_attempts` and `scheduled_at` in the future; `discarded` (exhausted) implies `attempt == max_attempts`; `cancelled` carries one error entry for its final attempt.
- **Defaults (corrects prep note B):** `oban_max_attempts` defaults to `8` in `Scrypath.Options` (`lib/scrypath/options.ex:109-113`, `default: 8`), readable as `Scrypath.Config.oban_max_attempts/1`. There is **no** default queue: `oban_queue` defaults to `nil` (line 104-108) and is required when `sync_mode: :oban`; the worker modules' `queue: :scrypath` is only their compile-time default. The fixture's queue name is an adopter-level constant with a `source:` comment, not a Scrypath default.

**N11. New finding F3 for the maintainer (not fixed): Scrypath can never show an `indexSwap` task.** [VERIFIED: recorded v1.15.2]
After a real `POST /swap-indexes`, `GET /tasks?indexUids=<live>&types=indexSwap` returned `{"results":[],"total":1,...}`, the same for the `__reindex` partner and for both indexes together; with Scrypath's full `list_index_tasks` type list and the live index filter the page held the other tasks (uids 11 and 10, `"total":3`) and no swap row; only an unfiltered `GET /tasks?types=indexSwap` (or `?uids=12`) returned it (`"indexUid":null`). `total` counted the swap while `results` omitted it, an inconsistency in v1.15.2 that the fake need not model (Scrypath does not read `total`). The docs say `indexUid` is `null` only for "global tasks such as `dumpCreation` or `taskDeletion`" and are silent on swap and `indexUids` [CITED: meilisearch.com/docs/reference/api/tasks]. Scrypath always filters `indexUids` (`tasks.ex:41`), so no swap row can reach `State` or the ops UI. **Constraints:** (a) the builder's `indexSwap` task takes `indexUid: nil`, and the fake client excludes `nil`-index tasks from any `index_uids` filter exactly like the server; (b) Phase 198's Chatly "cutover" story must derive from `__reindex` index tasks (`indexCreation`, `documentAdditionOrUpdate` on the partner), not from a swap row, unless the maintainer resolves F3 (root `lib/`, so ask-first). Record F3 in the phase findings note.

**N12. Drift injection.** (see Pattern 3). Proven: a Shopadelic-shaped schema (`filterable: [:status, :storeId]`) against applied settings = recorded default merged with `filterableAttributes: ["status"]` through the real `Scrypath.index_contract_drift/2` returned `filterable_attributes: %{match: false, details: [only_declared: "storeId"]}` and `settings: match: false, details: [%{key: "filterableAttributes", applied: ["status"], declared: ["status", "storeId"]}]`, other dimensions `match: true`. `client.get_settings/2` returns `{:ok, map}` or `{:error, {:http_error, 404, body}}` (`index_contract_drift.ex` `build_meilisearch/2`: 404 -> `{:error, :index_not_found}`).

**N13. What cannot be a module.** `Scrypath.Oban.UpsertWorker`, `DeleteWorker` and `Sync.RelatedWorker` are defined only when Oban loads; Oban is not in the `scrypath_ops` graph (the `oban` in `scrypath_ops/mix.lock` appears only inside sigra's optional dependency list), and `test/support/copy_stubs/oban_job.ex` defines a stub `Oban.Job` for the whole test env. Builders use the strings. `Config.ensure_oban_ready!/1` is not on any read path (`Status.fetch` and `Retrieval.fetch` only call the injected inspector or the `oban_jobs` list, `inspect.ex`).

**N14. Oban reachability for the failure table.** A Meilisearch-side failure inside a job returns `{:error, {:task_failed, %Scrypath.Operations.Task{...}}}` (`tasks.ex:144-147`, `IndexingAck.await/3`), so the stored Oban error text embeds an `inspect` of the whole task struct including its raw map (and therefore the echoed document for `missing_document_id`). It is long and gets truncated at 500 characters by `bound_queue_reason/1`. Treat that row as an `errors` entry whose text is truncated by the real code, not by the builder: the table stores the untruncated text and the real `Translation` truncates it, which also exercises F2.

**N15. Render determinism.** [VERIFIED: LiveViewTest on `/ops/health`, two renders 3 days apart]
- Time reaches the page through `ScrypathOps.Clock.utc_now/0` (`posture_live.ex` non-fixture `posture_summary/1`); in test builds it reads `Application.fetch_env(:scrypath_ops, :test_clock_file)` at runtime (`clock.ex:8-12`), a path to a file holding one UTC ISO8601 timestamp ending in `Z`, at most 128 bytes. A helper writes that file from `scenario.now`.
- Time-derived text that moves with `now`: the "Checked" line (`Nov 20, 2026 at 14:00:00 UTC`), "last succeeded" lines, `data-ops-timestamp-copy`, `datetime`, and `title` attributes carrying ISO timestamps. Relative ages ("13 hrs ago") do **not** move when every offset is `now`-relative, which is the property the test protects.
- Per-render randomness a comparison must normalize: LiveView ids and `data-phx-*` tokens, the csrf meta tag in the full document (use `render(lv)`, not the `live/2` document), and DOM ids built from `System.unique_integer([:positive])` at `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:135` (`ops-section-N`), `:749` (`ops-empty-hero-heading-N`) and `:1340` (`ops-time-N`). Without normalizing `ops-time-N` the "equal after normalization" assertion fails (observed `ops-time-707` versus `ops-time-1027`).
- The planted failure: pin one task list to a literal `now` while the scenario `now` moves. After normalization the relative age moves (`["13 hrs ago"]` versus `["3 days ago"]`) and the equality fails. The first draft of this plant used `refute normalize(a) == normalize(b)` and passed **for the wrong reason** (random session ids); the plant must assert the relative-age difference itself (Pitfall 5).

**N16. The check task: placement, order, cost.** [VERIFIED]
- A task module in the fixtures dependency (`lib/mix/tasks/scrypath_fixtures.check.ex`) is found through `Mix.Task.run/1`'s "compile and load dependencies" step: with the dependency's build dir deleted, running it printed `==> scrypath_fixtures / Compiling 11 files` then `==> scrypath_ops` and the result, with **no ops files compiled**; touching an ops file did not make the check recompile ops; a **content** edit to a fixtures file recompiled just that file and the check saw it (a planted `index <> "_PLANTED"` produced `{:logistify_deep_queue, {:job_index, 5001}}` and a `Mix.raise`).
- DB-free: with `PGPORT=1`, `mix scrypath_fixtures.check` printed `Fixtures OK: 1 scenario(s)` in 0.54 s wall (warm); `mix test ...` with `PGPORT=1` and the alias `["scrypath_fixtures.check", "scrypath_ops.check_nav_contract", "ecto.create --quiet", "ecto.migrate --quiet", "test"]` printed `Fixtures OK`, then `Nav contract OK`, then failed at `ecto.create` (`econnrefused`): the check runs first and independently of the database.
- Dev env would build the dev graph (storybook, esbuild, tailwind, dashboard): add `"scrypath_fixtures.check": :test` to `cli/0` `preferred_envs` in `scrypath_ops/mix.exs` (the `precommit: :test` precedent, `mix.exs:28-36`) so plain `mix scrypath_fixtures.check` uses the test build. The existing `opsui.test_a11y` alias is a function alias that does not use the `test` alias; leave it.
- The task cannot call `Posture.summary/3` (no ops app started, and fixtures must not reference ops). The posture round trip is an ops ExUnit test.

**N17. Docker recording: done, cleaned, evidence kept out of the repo.** Pinned image: `getmeili/meilisearch:v1.15` (`compose.yaml:17`, `examples/scrypath_ecommerce/compose.yaml:20`, `.github/workflows/ci.yml:257,406`, asserted by `test/scrypath/docs_contract_test.exs:823-851`); local image id `edae2a6bb59c`, `sha256:fe500cf9cca05cb9f027981583f28eccf17d35d94499c1f8b7b844e7418152fc`, 139 MB; the server reported `{"commitSha":"6b4d69996ce9c1e0d0b8d52af2fcea4a5750bfa7","commitDate":"2025-06-12T16:41:47.000000000Z","pkgVersion":"1.15.2"}`. Two containers named `scrypath-p196-recording` ran in turn (`--rm`, label `scrypath.task=p196-recording`, `-p 127.0.0.1::7700` random host port, `--tmpfs /meili_data`, `MEILI_NO_ANALYTICS=true`, `MEILI_ENV=development`); neither created a named volume or a network (tmpfs data, the default bridge). After `docker stop` (which removes a `--rm` container) `docker ps -a --filter name=scrypath-p196` printed nothing, and `docker system df` was identical before and after (Containers 56/18 active, Images 246, Local Volumes 195, Build Cache 260). **The image was not removed:** it pre-existed and backs `scrypath_ecommerce-meilisearch-1` (the maintainer's retained preview); AGENTS.md forbids touching other resources, and `docker rmi` of an in-use image fails anyway. The executor should `docker rmi` only an image it pulled itself. The recorded files stayed in the scratchpad (not the repo).

**N18. Empty-install reachability (Wikily).** Meilisearch returns an **empty page, not an error,** for a task list filtered to an index that does not exist (`{"results":[],"total":0,"limit":1000,"from":null,"next":null}`, recorded), so `Status.fetch` for a never-created index yields an empty, clear status. `index_not_found` is reachable on exactly two paths: a failed `documentDeletion` task (recorded: `"code":"index_not_found"`, `details: {providedIds, deletedDocuments, originalFilter}`) and `get_settings` 404, which `index_contract_drift/2` turns into `{:error, :index_not_found}`. Wikily's states are therefore: allowlist `[]` (`Posture` `:unconfigured`, headline "Not configured"), no `:backend` key (`:missing_backend`, headline "Broken"), allowlisted with an empty task list and a drift `{:error, :index_not_found}`, and optionally one delete task failed with `index_not_found`.

## Tracer bullet (Logistify) that ran

Scratch result through the **real** code (builder -> `FakeMeilisearchClient` / `FakeObanInspector` -> `Scrypath.sync_status/2`): index `"logistify_shipment"` (`Scrypath.Meilisearch.index_name/2` with `index_prefix: "logistify"`), mode `:oban`, backend pending 7 (enqueued tasks), backend failed 0, queue observed `true`, queue pending 195 (180 `available` + 12 `scheduled` + 3 `executing`), queue retrying 0, queue failed 0, `failed_sync_work` rows 0. The same scenario with 1,200 succeeded tasks returned `{:error, {:task_history_truncated, %{next: 200, limit: 1000, index_uid: "logistify_shipment", observed: 1000}}}` (finding F1 reproduced against a faithful fake). All 647 task maps pass `TaskPayload.normalize(&1, :poll)`.

Rendered through `live(conn, ~p"/ops/health")` with `FixtureEnv.put/1`: the page contains `"No sync failures found"`, `.ops-verdict[data-verdict-kind='neutral'] [data-sync-status='pending']`, and no `[data-sync-status='failed']` [VERIFIED: passing ExUnit in scratch, 0.1 s]. `Posture.summary/3` is what the LiveView calls (`posture_live.ex` `posture_summary/1` passes `Clock.utc_now()`), so asserting through LiveViewTest covers `Posture.summary/3` plus the component render; asserting `Posture.summary/3` alone is the cheaper unit check. **Recommend LiveViewTest** for the tracer (about 20 lines of helper) and `Posture.summary/3` direct for the per-scenario round trip.

For a realistic deep queue keep task history below 1,000 (647 here); a history over 1,000 is finding F1 and may only appear as an explicitly named stress variation (Open Question 3).

## Recorded Meilisearch v1.15.2 payloads (this session)

Commit these as small files under `fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/` with a `PROVENANCE.md` (image tag, id/digest above, `GET /version` body, date, the commands). All below are exact bodies from the run (unique ids such as `SHP-20481` and the school-code-like value `AH 2026/7B` are examples; the executor re-records with Scrypath-owned values, and must not reuse sibling-brand canon ids).

Full task, `succeeded` (`documentAdditionOrUpdate`):
```json
{"uid":1,"batchUid":1,"indexUid":"p196_shipment","status":"succeeded","type":"documentAdditionOrUpdate","canceledBy":null,"details":{"receivedDocuments":2,"indexedDocuments":2},"error":null,"duration":"PT0.177497S","enqueuedAt":"2026-11-22T00:25:17.004648507Z","startedAt":"2026-11-22T00:25:17.004723798Z","finishedAt":"2026-11-22T00:25:17.182220798Z"}
```
`enqueued` (full task; `batchUid`, `startedAt`, `finishedAt`, `duration` null; `indexedDocuments` null): `{"uid":9,"batchUid":null,"indexUid":"p196_shipment","status":"enqueued","type":"documentAdditionOrUpdate","canceledBy":null,"details":{"receivedDocuments":1,"indexedDocuments":null},"error":null,"duration":null,"enqueuedAt":"...","startedAt":null,"finishedAt":null}`.
`processing` (`batchUid` and `startedAt` set, `finishedAt` and `duration` null): `{"uid":8,"batchUid":7,...,"status":"processing",...,"details":{"receivedDocuments":60000,"indexedDocuments":null},"error":null,"duration":null,"enqueuedAt":"...","startedAt":"...","finishedAt":null}`.
`canceled` (`canceledBy` = the `taskCancelation` uid, `error` null, times set): `{"uid":6,"batchUid":6,...,"status":"canceled","type":"documentAdditionOrUpdate","canceledBy":7,"details":{"receivedDocuments":1,"indexedDocuments":0},"error":null,...}`.

Failed tasks (`status: "failed"`, `details: {"receivedDocuments":1,"indexedDocuments":0}`), the four `error` objects, each with a `link` of the form `https://docs.meilisearch.com/errors#<code>`:
- `{"message":"Document identifier `\"AH 2026/7B\"` is invalid. A document identifier can be of type integer or string, only composed of alphanumeric characters (a-z A-Z 0-9), hyphens (-) and underscores (_), and can not be more than 511 bytes.","code":"invalid_document_id","type":"invalid_request",...}` (echoes the id value)
- `{"message":"Document doesn't have a `id` attribute: `{\"title\":\"Record with no id\",\"carrier\":\"Nordlicht\"}`.","code":"missing_document_id","type":"invalid_request",...}` (echoes the whole document: the F2 evidence)
- `documentDeletion` on an unknown index: `{"message":"Index `p196_nope` not found.","code":"index_not_found","type":"invalid_request",...}` with `details: {"providedIds":1,"deletedDocuments":0,"originalFilter":null}`
- `{"message":"The primary key inference failed as the engine did not find any field ending with `id` in its name. Please specify the primary key manually using the `primaryKey` query parameter.","code":"index_primary_key_no_candidate_found","type":"invalid_request",...}`

`indexSwap` (`indexUid` null, `details.swaps`): `{"uid":12,"batchUid":11,"indexUid":null,"status":"succeeded","type":"indexSwap","canceledBy":null,"details":{"swaps":[{"indexes":["p196_shipment","p196_shipment__reindex"]}]},"error":null,...}`.
`indexCreation` `details: {"primaryKey":"id"}`; `settingsUpdate` `details` echoes the sent settings; `documentDeletion` succeeded `details: {"providedIds":1,"deletedDocuments":1,"originalFilter":null}`.

List page (`GET /tasks?indexUids=p196_shipment&types=documentAdditionOrUpdate,documentDeletion&limit=3`): `results` uids `[9, 8, 6]`, `"total":7,"limit":3,"from":9,"next":5`; the continuation `&from=5` returned uids `[5, 3, 2]`, `"from":5,"next":1`; with `limit=1000` uids `[9,8,6,5,3,2,1]`, `"next":null`. The docs agree: results descending by uid, `from` "The first task uid returned", `next` "Value to pass as `from` parameter to get the next page", null when none [CITED: meilisearch.com/docs/reference/api/tasks].

Synchronous responses: enqueue summary `{"taskUid":0,"indexUid":"p196_shipment","status":"enqueued","type":"indexCreation","enqueuedAt":"..."}` (key is `taskUid`, not `uid`; `TaskPayload` accepts both); `GET /indexes/<unknown>/settings` -> `404 {"message":"Index `p196_nope` not found.","code":"index_not_found","type":"invalid_request","link":"https://docs.meilisearch.com/errors#index_not_found"}`; `GET /tasks?limit=abc` -> `400 ... "code":"invalid_task_limit"`; a search on a non-filterable attribute -> `{"message":"Index `p196_product`: Attribute `colour` is not filterable. Available filterable attribute patterns are: `status`, `storeId`.\n1:7 colour = red","code":"invalid_search_filter","type":"invalid_request",...}` (resolves B's "U: exact `invalid_search_filter` wording").

Settings (`GET /indexes/<uid>/settings`, 20 keys, default): `displayedAttributes ["*"], searchableAttributes ["*"], filterableAttributes [], sortableAttributes [], rankingRules ["words","typo","proximity","attribute","sort","exactness"], stopWords [], nonSeparatorTokens [], separatorTokens [], dictionary [], synonyms {}, distinctAttribute null, proximityPrecision "byWord", typoTolerance {enabled, minWordSizeForTypos{oneTypo 5, twoTypos 9}, disableOnWords, disableOnAttributes, disableOnNumbers}, faceting {maxValuesPerFacet 100, sortFacetValuesBy {"*":"alpha"}}, pagination {maxTotalHits 1000}, embedders {}, searchCutoffMs null, localizedAttributes null, facetSearch true, prefixSearch "indexingTime"`.

Recording commands (the executor's script; bash, not zsh, because `$J` word-splitting differs):
```bash
docker run -d --rm --name scrypath-p196-recording --label scrypath.task=p196-recording \
  -p 127.0.0.1::7700 --tmpfs /meili_data -e MEILI_NO_ANALYTICS=true -e MEILI_ENV=development getmeili/meilisearch:v1.15
PORT=$(docker port scrypath-p196-recording 7700/tcp | head -1 | sed 's/.*://')
post() { curl -s -X POST "http://127.0.0.1:$PORT$1" -H 'Content-Type: application/json' -d "$2"; }
post /indexes '{"uid":"p196_shipment","primaryKey":"id"}'
post /indexes/p196_shipment/documents '[{"id":"SHP-20481","title":"Pallet of ceramic tiles"}]'            # succeeded
post /indexes/p196_shipment/documents '[{"id":"AH 2026/7B","title":"x"}]'                                  # invalid_document_id
post /indexes/p196_shipment/documents '[{"title":"no id"}]'                                                # missing_document_id
post /indexes/p196_nope/documents/delete-batch '["SHP-1"]'                                                  # index_not_found (task)
post /indexes/p196_noprimary/documents '[{"title":"no id-like field"}]'                                    # primary key inference
# processing / enqueued: POST a 60,000-document file with --data-binary @file, then GET /tasks?statuses=processing and ?statuses=enqueued while it runs
# canceled: POST /tasks/cancel?uids=<queued uid> while it waits behind the bulk load
post /indexes '{"uid":"p196_shipment__reindex","primaryKey":"id"}'; post /swap-indexes '[{"indexes":["p196_shipment","p196_shipment__reindex"]}]'
curl -s "http://127.0.0.1:$PORT/tasks?indexUids=p196_shipment&types=documentAdditionOrUpdate,documentDeletion&limit=3"
docker stop scrypath-p196-recording      # --rm removes it; confirm with docker ps -a --filter name=scrypath-p196 and docker system df
```
Pitfalls hit: a 60,000-document body must go through `--data-binary @file` (`Argument list too long` otherwise); a `processing` window of 2 s is easy to catch by polling every 20 ms; the `canceled` payload needs a task queued behind the bulk load.

## Closed failure table (proposed shape and entries)

Each entry: `%{id:, surface: :meilisearch_task | :oban_error, code | text, type, source:}`. A check asserts every failure string in any scenario equals a table entry (after template substitution of the id or document) and that every `source:` resolves (a recording file that exists, or a repository path that exists). Reachability notes are why an entry is allowed.

| id | text or code | Reaches the UI as | source |
|----|--------------|-------------------|--------|
| `invalid_document_id` | recorded message template with the id echoed; `code "invalid_document_id"`, `type "invalid_request"` | backend failed row, reason class `:validation` | recording `task_failed_invalid_document_id.json`; classifier `translation.ex:181-188` |
| `missing_document_id` | recorded message echoing the document; `"missing_document_id"` | `:validation`; copyable text (finding F2) | recording; `translation.ex:112-117` |
| `index_not_found_task` | `"Index `<uid>` not found."`; `"index_not_found"` | delete failed row | recording `task_failed_index_not_found.json` |
| `primary_key_no_candidate` | recorded message; `"index_primary_key_no_candidate_found"` | `:validation` | recording |
| `oban_transport` | `"** (Oban.PerformError) Scrypath.Oban.UpsertWorker failed with {:error, {:transport_error, %Req.TransportError{reason: :econnrefused}}}"` | retryable, then discarded; class `:transport` (matches `"req.transporterror"`, `translation.ex:252-257`) | `lib/scrypath/meilisearch/client.ex:190-192` (`{:error, {:transport_error, exception}}`) and Oban `exceptions.ex:27-31` |
| `oban_task_failed` | `"... failed with {:error, {:task_failed, %Scrypath.Operations.Task{...}}}"` (long; real code truncates to 500) | discarded; class `:unknown` -> `:queue_exhausted` when no signal (`translation.ex:201-207`) | `lib/scrypath/meilisearch/tasks.ex:144-147` |
| `oban_cancel_invalid_job` | `"... failed with {:cancel, {:invalid_job, {:unknown_schema, \"Elixir.<Mod>\"}}}"` | cancelled row | `lib/scrypath/oban/upsert_worker.ex` (`{:cancel, {:invalid_job, tag}}`), Oban executor `:152-153` |

Stack-trace lines that real `Exception.format/3` appends are not reproduced (Assumption A3). Out of the table on purpose (cannot be produced or not displayable): per-document size limits, "N minutes of lag", per-tenant drift, price-as-string rejection, out-of-order overwrite on the Oban path, `payload_too_large` as a task. `database_size_limit_reached` / `no_space_left_on_device` have error `type "system"` in Meilisearch and would classify `:unknown`, not `:backend_rejected` (the type map at `translation.ex:181-188` has no `"system"` arm), so they are excluded rather than mislabelled [ASSUMED type string; not recorded].

## Adopter states that the real code can produce (proposed, planner may rename)

| Adopter / index | State id | Kind | What the real code reports | Basis |
|-----------------|----------|------|-----------------------------|-------|
| Logistify / `logistify_shipment`, `:oban` | `deep_queue` | ordinary | queue pending 195, backend pending 7, nothing failed; posture `:ok`, neutral verdict, status word `pending` | ran (tracer) |
| Logistify | `steady` | ordinary | empty queue and clear history; `:clear` | `Posture.row_status/1` (`posture.ex:207-215`) |
| Logistify | `history_over_limit` | stress, optional | `{:error, {:task_history_truncated, ...}}` rendered as "Not checked" (finding F1) | ran; Open Question 3 |
| Shopadelic / `shopadelic_product`, `:oban` | `settings_aligned` | ordinary | drift report all `match: true` | N12 |
| Shopadelic | `settings_drift` | ordinary, named | `filterable_attributes` `only_declared: "storeId"` | ran |
| Shopadelic | `failed_journey` | ordinary, named (JOB-03 entry) | backend failed task `invalid_document_id`; discarded upsert (`attempt == max_attempts`, class `:transport`), one `retryable` (`attempt < max_attempts`, `scheduled_at` ahead), one `cancelled` invalid job, one discarded delete; posture `:degraded` | N10, N14, closed table |
| Shopadelic | `hostile_ids` | stress | the failed task's echoed id carries the hostile strings (bidi override, ZWJ emoji, NFC/NFD, CJK, Arabic, 511-byte id, unbroken 200-char token, markup text). Reachable: Meilisearch rejects such ids with `invalid_document_id` and echoes them | recording shape |
| Wikily / `wikily_page` | `unconfigured` | ordinary | allowlist `[]`: headline "Not configured" | `posture.ex:354-361` |
| Wikily | `missing_backend` | ordinary | no `:backend`: headline "Broken" | `posture.ex:363-370` |
| Wikily | `index_not_created` | ordinary | empty task list plus `{:error, :index_not_found}` from drift | N18 |

Every title and label carries "(fictional)"; the denylist words (`HIPAA`, `GDPR`, `PCI`, `SOX`, `compliant`, `certified`) fail in fixtures (B D7). Hostile strings are written only as Elixir escapes in source; the lint test scans `fixtures/**/*.ex` for raw U+200B-200F, U+202A-202E, U+2066-2069 and U+FEFF and has a planted temp file that must fail.

## Common Pitfalls

### Pitfall 1: Direct dev/test boundary cases fail at compile after the dependency lands
**What goes wrong:** `ops_dependency_boundary_test` direct cases archive only `["mix.exs", "mix.lock", "lib", "priv", "scrypath_ops"]` from `HEAD`.
**Why it happens:** the path dependency lives outside `scrypath_ops/`, and `deps.get --check-locked` tolerates a missing path directory (exit 0, warning), so the failure appears at `compile`.
**How to avoid:** add `"fixtures"` to the list (N2); commit the tree before running `--include integration`.
**Warning signs:** `the dependency is not available`, or a boundary test green locally on uncommitted files.

### Pitfall 2: A boundary row that reads `only:` of the path dependency returns nothing
**What goes wrong:** `dependency_options!/2` returns `[]` for `{:scrypath_fixtures, path: ..., only: [...]}` (N4), so a naive row asserts on `nil`.
**How to avoid:** a path-dependency-aware reader first; planted manifests for each loosening.

### Pitfall 3: Lock-based absence is vacuous
**What goes wrong:** a path dependency is in no lock, so "absent from the lock" passes in dev too.
**How to avoid:** `.app` applications list, `_build/<env>/lib`, `mix deps`, `:code.which/1`, and `Code.ensure_loaded?/1` (N1, N5).

### Pitfall 4: Fixture timestamps that do not parse
**What goes wrong:** `State.datetime_and_source_iso/1` returns `{nil, nil}` for an unparsable string, silently dropping "last succeeded".
**How to avoid:** Meilisearch-shaped stamps (`Calendar.strftime` plus nine fractional digits and `Z`); `DateTime.from_iso8601/1` accepts them [VERIFIED]; the check asserts every `finishedAt` parses and every `completed_at` is a `DateTime`.

### Pitfall 5: A planted failure that passes for the wrong reason
**What goes wrong:** `refute normalize(a) == normalize(b)` passed because LiveView session ids differ, not because the relative age moved (N15). The same class: a plant that raises in the builder instead of reaching the check.
**How to avoid:** every plant asserts its own cause (the relative-age pair, the exact problem tag such as `{:wire_guard, uid}` or `{:time_order, uid}`), and has a positive control in the same file. This is the Phase 195 lesson ("pinning the cause per plant").

### Pitfall 6: Global app env in tests
**What goes wrong:** `Application.put_env(:scrypath_ops, ...)` is global; an async test sees another's scenario, and a missed restore leaks into the next module.
**How to avoid:** `async: false`, `FixtureEnv.put/1` returns a restore function used in `on_exit`, and a leak test that the keys equal their prior values afterwards. Phase 197 needs per-session injection; keep `scrypath_opts` plain data so it can move there.

### Pitfall 7: Spelling split `canceled` / `cancelled`
**What goes wrong:** Meilisearch status is `"canceled"`, Oban state is `"cancelled"`; `TaskPayload` maps both to `:cancelled`.
**How to avoid:** separate closed lists per surface; the check asserts a Meilisearch task never carries `"cancelled"`.

### Pitfall 8: A task in `scrypath_ops/lib` names fixtures modules
**What goes wrong:** the Docker prod compile (`mix compile --warnings-as-errors`, Dockerfile) warns about an undefined module and fails.
**How to avoid:** the task lives in the fixtures dependency (N16); only the alias string appears in `scrypath_ops/mix.exs`.

### Pitfall 9: `mix scrypath_fixtures.check` in the dev env
**What goes wrong:** the dev graph (storybook, esbuild, tailwind, dashboard) compiles first.
**How to avoid:** `preferred_envs` entry; document `MIX_ENV=test` in the README.

### Pitfall 10: `index_contract_drift/2` options
**What goes wrong:** passing `:applied_settings`, `:meilisearch_tasks` or other operator keys raises `ArgumentError`.
**How to avoid:** Pattern 3 (state in the client module).

### Pitfall 11: Re-recording churn
**What goes wrong:** the recorded timestamps and uids differ every run, so re-recording makes noisy diffs and the key-set check is the only stable comparison.
**How to avoid:** compare key sets and value *types* (nil / string / integer / map), never values; commit `PROVENANCE.md` with the image id.

## Code Examples

All of the following ran in the scratch copy (`.../scratchpad/p196/repo`, not part of the repository).

### Meilisearch task builder (closed enums, string keys, recorded key set)
```elixir
defmodule ScrypathFixtures.Meili do
  @moduledoc false
  @types ~w(documentAdditionOrUpdate documentDeletion indexCreation settingsUpdate indexSwap)
  @statuses ~w(enqueued processing succeeded failed canceled)
  @keys ~w(uid batchUid indexUid status type canceledBy details error duration enqueuedAt startedAt finishedAt)

  def keys, do: @keys

  def task(%{type: type, status: status} = attrs) when type in @types and status in @statuses do
    now = Map.fetch!(attrs, :now)
    enqueued = Map.fetch!(attrs, :enqueued_ago)
    started? = status != "enqueued"
    finished? = status in ["succeeded", "failed", "canceled"]

    %{
      "uid" => Map.fetch!(attrs, :uid),
      "batchUid" => if(started?, do: Map.get(attrs, :batch_uid, Map.fetch!(attrs, :uid))),
      "indexUid" => Map.fetch!(attrs, :index_uid),          # nil only for "indexSwap"
      "status" => status,
      "type" => type,
      "canceledBy" => Map.get(attrs, :canceled_by),
      "details" => Map.get(attrs, :details, %{}),
      "error" => Map.get(attrs, :error),                    # %{"message","code","type","link"} from the closed table
      "duration" => if(finished?, do: "PT0.1S"),
      "enqueuedAt" => stamp(now, enqueued),
      "startedAt" => if(started?, do: stamp(now, enqueued - 1)),
      "finishedAt" => if(finished?, do: stamp(now, enqueued - 2))
    }
  end

  def stamp(%DateTime{} = now, seconds_ago),
    do: Calendar.strftime(DateTime.add(now, -seconds_ago, :second), "%Y-%m-%dT%H:%M:%S") <> ".123456789Z"
end
```

### Oban job builder (shape of the repository's real inspector)
```elixir
defmodule ScrypathFixtures.ObanJob do
  @moduledoc false
  @states ~w(available scheduled executing retryable completed discarded cancelled)
  @workers %{upsert: "Scrypath.Oban.UpsertWorker", delete: "Scrypath.Oban.DeleteWorker", related: "Scrypath.Sync.RelatedWorker"}

  def job(%{state: state, worker: worker} = attrs) when state in @states and is_map_key(@workers, worker) do
    now = Map.fetch!(attrs, :now)
    ago = Map.fetch!(attrs, :ago)
    attempt = Map.get(attrs, :attempt, 0)

    %{
      id: Map.fetch!(attrs, :id), state: state, worker: Map.fetch!(@workers, worker),
      queue: Map.get(attrs, :queue, "scrypath"), args: Map.fetch!(attrs, :args),
      errors: Map.get(attrs, :errors, []), attempt: attempt,
      max_attempts: Map.get(attrs, :max_attempts, 8),        # source: Scrypath.Config.oban_max_attempts/1 default
      attempted_at: if(attempt > 0, do: DateTime.add(now, -ago, :second)),
      scheduled_at: DateTime.add(now, Map.get(attrs, :scheduled_in, -ago), :second),
      completed_at: if(state == "completed", do: DateTime.add(now, -ago + 2, :second))
    }
  end
end
```

### Fake Meilisearch client `tasks/2` (limit, order, next, from; nil index never matches)
```elixir
def tasks(filters, config) do
  case Keyword.get(config, :meilisearch_tasks, []) do
    {:error, _reason} = error -> error
    tasks when is_list(tasks) ->
      uids = Keyword.get(filters, :index_uids)
      types = Keyword.get(filters, :types)
      limit = Keyword.get(filters, :limit, 20)
      from = Keyword.get(filters, :from)

      matching =
        tasks
        |> Enum.filter(&(is_nil(uids) or &1["indexUid"] in uids))   # a nil indexUid (indexSwap) is never in a list
        |> Enum.filter(&(is_nil(types) or &1["type"] in types))
        |> Enum.sort_by(& &1["uid"], :desc)

      window = if from, do: Enum.filter(matching, &(&1["uid"] <= from)), else: matching
      {page, rest} = Enum.split(window, limit)

      {:ok, %{"results" => page, "total" => length(matching), "limit" => limit,
              "from" => page |> List.first() |> then(&(&1 && &1["uid"])),
              "next" => rest |> List.first() |> then(&(&1 && &1["uid"]))}}
  end
end
```
Conformance test: feed the recorded task set to the fake and assert `limit: 3` yields the recorded `from`/`next`/uid order of `15-list-page1-limit3.json`, and that the key set of every builder output equals the recorded key set for its type and status.

### Mix task shell and alias (single edit to `scrypath_ops/mix.exs`)
```elixir
# fixtures/scrypath_fixtures/lib/mix/tasks/scrypath_fixtures.check.ex
defmodule Mix.Tasks.ScrypathFixtures.Check do
  @shortdoc "Checks every Scrypath fixture scenario (no database)"
  @moduledoc false
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    case ScrypathFixtures.Check.run() do
      {:ok, summary} -> Mix.shell().info("Fixtures OK: #{summary.scenarios} scenario(s)")
      {:error, problems} -> Mix.raise("Fixture check failed:\n" <> Enum.map_join(problems, "\n", &"  #{inspect(&1)}"))
    end
  end
end

# scrypath_ops/mix.exs
{:scrypath_fixtures, path: "../fixtures/scrypath_fixtures", only: [:dev, :test]},        # in deps/0
test: ["scrypath_fixtures.check", "scrypath_ops.check_nav_contract", "ecto.create --quiet", "ecto.migrate --quiet", "test"],
# cli/0 preferred_envs:  "scrypath_fixtures.check": :test
```

### Test helper and tracer (ops `test/support`)
```elixir
defmodule ScrypathOps.Test.FixtureEnv do
  @moduledoc false
  @keys ~w(schema_allowlist backend sync_mode oban oban_queue index_prefix meilisearch_url meilisearch_client
           meilisearch_tasks oban_inspector oban_jobs test_clock_file)a

  def put(%ScrypathFixtures.Scenario{} = scenario) do
    previous = Map.new(@keys, &{&1, Application.fetch_env(:scrypath_ops, &1)})
    clock = Path.join(System.tmp_dir!(), "p196-clock-#{System.unique_integer([:positive])}.txt")
    File.write!(clock, DateTime.to_iso8601(scenario.now) <> "\n")     # ends in Z, under 128 bytes
    Application.put_env(:scrypath_ops, :schema_allowlist, scenario.allowlist)
    for {k, v} <- scenario.scrypath_opts, do: Application.put_env(:scrypath_ops, k, v)
    Application.put_env(:scrypath_ops, :test_clock_file, clock)

    fn ->
      File.rm(clock)
      for {k, r} <- previous do
        case r do
          {:ok, v} -> Application.put_env(:scrypath_ops, k, v)
          :error -> Application.delete_env(:scrypath_ops, k)
        end
      end
    end
  end
end

# test (async: false, ConnCase): assertions use element selectors, not substring matching of raw HTML
{:ok, lv, _document} = live(conn, ~p"/ops/health")
assert has_element?(lv, ".ops-verdict[data-verdict-kind='neutral'] [data-sync-status='pending']")
refute has_element?(lv, "[data-sync-status='failed']")
```
Determinism normalizer (verified): drop ` data-phx-*="..."` and ` id="phx-..."`, replace `ops-(time|section|empty-hero-heading)-N` ids, replace `Mon D, YYYY at HH:MM:SS UTC` and ISO timestamps; keep relative-age text. Prefer building it over a `LazyHTML` projection per `scrypath_ops/AGENTS.md`.

### Path-dependency-aware reader (root boundary test)
```elixir
defp path_dependency_options!(path, dependency) do
  path |> read_ast!() |> find_deps_body!()
  |> Enum.find_value(fn
    {^dependency, opts} when is_list(opts) -> opts            # must precede the generic 2-tuple clause
    {:{}, _, [^dependency, _requirement, opts]} when is_list(opts) -> opts
    _ -> nil
  end) || flunk("#{path}: expected direct dependency #{dependency}")
end
```
Row: `Keyword.get(opts, :path) == "../fixtures/scrypath_fixtures"` and `Enum.sort(List.wrap(Keyword.get(opts, :only))) == [:dev, :test]`; planted manifests: no `only`, `only: :dev`, `only: [:dev, :test, :prod]`, absent dependency.

### Bulk pick (copy, no dependency)
```elixir
def pick(list, seed, n, tag), do: Enum.at(list, :erlang.phash2({seed, n, tag}, length(list)))
# golden: sha256 over :erlang.term_to_binary(sample, [:deterministic, {:minor_version, 2}]) of the PICKED rows
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Two drifting `phase173_fixture_source.ex` copies with invented worker names (`ScrypathOps.Phase173FixtureWorker`), `-04:00` string times, invented failure text | Wire-shape builders from recorded payloads and the real inspector shape | this phase | Only reachable states; `now`-relative |
| Prep note B: "no `refute "fixtures"` in package test" | Present at `package_metadata_test.exs:135-136` | Phase 195 | ADR 0002's claim is now asserted |
| Prep note B: Oban queue and `max_attempts` "from `Scrypath.Config` defaults" | Only `max_attempts` (8) has a default; queue is nil until configured | verified here | Queue is an adopter constant |
| Prep note B: "`indexSwap` may appear under both indexes' `indexUids` (U)" | It appears under neither | recorded 2026-11-22 UTC | Finding F3; constrains Phase 198 |

**Deprecated/outdated:** the "`Mix` only: for a nested path dep is unknown" open item in note H (resolved, N1); the prep D2 sketch `ScrypathFixtures.Scenarios.get/2` with a `documents` field (no code reads fake index contents in this phase; add only when a consumer exists).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `:erlang.phash2/2` gives the same value across OTP 28.1 (CI) and 28.5 (local) and across later bumps. Official doc text not re-read this session; a 2019 erlang-questions thread has an OTP maintainer saying list/map hashing is intended stable, while an Elixir library's docs claim it is not guaranteed across majors | Don't Hand-Roll, Code Examples | Golden digest changes after an OTP bump; the digest is over the picked output, so the failure is loud and the fix is a deliberate update |
| A2 | Hosted first-run cost for this change is about Phase 195's +135 s cache-miss shape on `ops-ui` and similar on `ecommerce-mounted`; inferred from `beam_cache.cjs` key construction, not measured for a `mix.exs`-only change | N3 | Trigger-style language ("60 s") misread against a cold number; mitigation is the warm-versus-control method |
| A3 | Real Oban errors append stacktrace lines after the first line; the fixture text keeps only the first line | Closed failure table | A copy/UI test that assumed multi-line text finds one line; negligible for classification (it reads substrings) |
| A4 | Adding three `COPY fixtures/scrypath_fixtures/mix.exs` lines to the Dockerfile is harmless to `verify-dependency-boundaries.sh --static-contract-only` (the script counts specific `COPY --from=asset_builder` lines and the `COPY --exclude=...` line, lines 118-133, none of which move). The hosted/local Docker lane was not run | N2 | One extra Docker iteration (about 15 min) |
| A5 | Meilisearch error `type` for `database_size_limit_reached`/`no_space_left_on_device` is `"system"` | Closed failure table | Entry excluded either way |
| A6 | The fixtures source lint reading files through a compile-time `__DIR__` works wherever the check runs (dev/test checkouts; not releases) | N16 | None in this repository's lanes (the task only runs in a source checkout) |

## Open Questions (RESOLVED)

1. **What counts as the "second consumer" for the ADR 0002 exit rule by Phase 197?** RESOLVED (orchestrator ruling 1): a Mix project other than `scrypath_ops` that lists `scrypath_fixtures` in its deps; the fold decision is evaluated at the start of Phase 197 planning. Recorded in the fixtures README and pinned by `fixtures_project_contract_test.exs` (196-02 Task 3).
   - What we know: ADR 0002 text says `scrypath_ops` and the demo host both use it; CONTEXT and prep note B say only `scrypath_ops` consumes it in v1.49 and the host does not; Phase 197's catalog lives inside `scrypath_ops`.
   - What's unclear: whether the 197 catalog (same Mix project) counts. If it does, the exit never triggers.
   - Recommendation: record in the plan and the fixtures README: "a second consumer is a Mix project **other than** `scrypath_ops` that lists `scrypath_fixtures` in its deps (candidate: the demo host replacing its phase173 copy)"; otherwise fold at Phase 197's start. Host adoption would add its own Dockerfile and boundary work, so default to the fold if none is planned.
2. **Task name.** RESOLVED (orchestrator ruling 2): `scrypath_fixtures.check_fixtures`, module `Mix.Tasks.ScrypathFixtures.CheckFixtures`, with a `preferred_envs` entry, first in the `scrypath_ops` `test` alias (196-01 Task 1). Original note: recommend `scrypath_fixtures.check` (module `Mix.Tasks.ScrypathFixtures.Check`); the requirement text says "`check_fixtures`". If the literal is wanted, `Mix.Tasks.ScrypathFixtures.CheckFixtures` gives `scrypath_fixtures.check_fixtures`. Planner discretion (names are in Claude's Discretion).
3. **Include the `history_over_limit` (finding F1) stress variation?** RESOLVED (orchestrator ruling 3): yes, as `:logistify_history_over_limit_f1`, kind `:stress`, labelled as the F1 reproduction so no story can mistake it for ordinary data; the `stress_unmarked` invariant enforces the label (196-04 Tasks 2 and 3). It is a real library state (reproduced) but it renders a defect as a scenario; if included, label it "F1 reproduction" and keep it out of ordinary data. Planner/maintainer call.
4. **Dockerfile COPY lines:** add (recommended, N2) or leave (correct either way)? Cost is one Docker iteration. RESOLVED (orchestrator ruling 4): add the three `COPY fixtures/scrypath_fixtures/mix.exs` lines plus the script-list and `.dockerignore` edits, proven by the root static contract with mutants and `bash -n` (196-02 Task 2); the Docker lane runs locally in 196-05 Task 3 or gets a recorded skip reason. Note: the fixtures script entry goes in a separate `if` block, because the existing storybook regex requires its line to stand alone.
5. **Plan 1 size.** RESOLVED (orchestrator ruling 5): five plans, each under 15 files and about 80k tokens: 196-01 project, tracer, the single `scrypath_ops/mix.exs` edit and the check skeleton; 196-02 root accounting and README; 196-03 recordings, failure table, determinism; 196-04 Shopadelic, Wikily, Logistify states and the planted invariants; 196-05 hostile text, bulk, provenance, lints and the ship. Original note: CONTEXT's plan 1 holds project, tracer, fake client, check task and package refute; this research adds the ops wiring, boundary rows, classifier inventory, formatter, namespace fence and archive-list edits. H's early warning is "more than one plan before an adopter reaches `Posture.summary`". Suggest plan 1 = project + Logistify tracer + ops wiring and the `mix.exs` edit; the root contract/classifier/formatter/fence/Docker edits as its own early task, still inside plan 1, so the tracer is not delayed by a second plan.
6. **F3 acknowledgement.** The maintainer should know a swap row cannot be shown; record it in the findings note (FLOW-04). No action needed from the maintainer for Phase 196. RESOLVED (orchestrator ruling 6): recorded in `196-FINDINGS.md` (196-03 Task 3), not fixed; Phase 198's Chatly cutover must derive from `__reindex` index tasks. F1, F2, D2 and the `dashboard_routes` defect stay in the 195 GO-NO-GO findings.

**Resolved during research** (marked RESOLVED because they were proven, not assumed): (RESOLVED) nested path dependency convergence and `only:` behaviour (N1); (RESOLVED) whether Docker needs `fixtures/` copied early (N2); (RESOLVED) rendered-posture route: LiveViewTest on `/ops/health` plus the test clock file (N15); (RESOLVED) where the check lives and that it runs first and DB-free (N16); (RESOLVED) note B's three "U" realism items: `invalid_search_filter` wording, `indexSwap` visibility, Oban cancelled attempt counts (N10, N11, recording).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP via asdf | all `mix` | yes (needs `export ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5`) | 1.19.0 / OTP 28.5 (CI 28.1) | none needed |
| Postgres | ops `mix test` (alias runs `ecto.create`), `verify.ops_ui` | yes, `localhost:5432` and `/tmp:5432`, user `postgres` / password `postgres` | accepting connections | use a task-scoped `SCRYPATH_OPS_TEST_DATABASE` (the scratch used `scrypath_ops_p196_scratch` and dropped it) |
| Docker | the one-time Meilisearch recording, `ecommerce-mounted` mirror | yes, engine 29.5.2 | image `getmeili/meilisearch:v1.15` already local | none needed (no pull) |
| Node | classifier tests, `ui_literal_policy` | yes, v26.10.0; `node --test scripts/ci/compat_path_classifier.test.cjs` 25 pass | | none |
| `act`, `gh`, `actionlint` | wiring and hosted timings | yes (`/opt/homebrew/bin`) | | none |

**Missing dependencies with no fallback:** none.

## Validation Architecture

`workflow.nyquist_validation` is `true` in `.planning/config.json`.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19) with `Phoenix.LiveViewTest` and `LazyHTML` in `scrypath_ops`; ExUnit at the root; `node --test` for CI scripts |
| Config file | `scrypath_ops/test/test_helper.exs` (sandbox mode manual); root `test/test_helper.exs` |
| Quick run (check, no DB) | `cd scrypath_ops && MIX_ENV=test mix scrypath_fixtures.check` (0.54 s warm; works with `PGPORT=1`) |
| Quick run (ops tests) | `cd scrypath_ops && mix test test/scrypath_ops/fixtures_*_test.exs test/scrypath_ops_web/live/fixtures_*_test.exs` (needs Postgres) |
| Quick run (root contracts) | `mix test test/mix/tasks/dependency_boundary_contract_test.exs test/release/package_metadata_test.exs test/mix/tasks/verify_namespace_fence_test.exs` and `node --test scripts/ci/compat_path_classifier.test.cjs` |
| Full suite | `mix verify.ops_ui` from the repo root (about 6 to 8 min; needs Postgres) |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FIX-01 | Logistify builders -> fake client -> real `Status`/`Posture` -> rendered `/ops/health`, deep queue, nothing failed | ops LiveViewTest | `cd scrypath_ops && mix test test/scrypath_ops_web/live/fixtures_tracer_test.exs` | Wave 0 (prototype ran) |
| FIX-01 | Builders raise `FunctionClauseError` on an unknown status/state/worker | ops unit | `mix test test/scrypath_ops/fixtures_builders_test.exs` | Wave 0 |
| FIX-01 | Exit rule and "fictional" provenance present in `fixtures/scrypath_fixtures/README.md` | root static | `mix test test/mix/tasks/fixtures_project_contract_test.exs` (README text, one row) | Wave 0 |
| FIX-02 | Builder key sets and value types equal the recorded payloads; fake client list contract equals the recorded page | `check` + ops unit | `MIX_ENV=test mix scrypath_fixtures.check` and `mix test test/scrypath_ops/fixtures_recordings_test.exs` | Wave 0 |
| FIX-02 | Every failure string is a closed-table entry with a resolving `source:`; no table entry is on the cannot-produce list | `check` | same | Wave 0 |
| FIX-02 | Hostile text only as escapes; raw format-char lint with a planted file | `check` + ops unit | same | Wave 0 |
| FIX-03 | Every scenario round-trips `sync_status/2`, `failed_sync_work/2`, `index_contract_drift/2` (check) and `Posture.summary/3` (ops) to `{:ok, _}` or a designed tag (`:task_history_truncated`, `:index_not_found`) | `check` + ops unit | `MIX_ENV=test mix scrypath_fixtures.check`; `mix test test/scrypath_ops/fixtures_round_trip_test.exs` | Wave 0 |
| FIX-03 | Adopter labels contain "(fictional)"; denylist words absent | ops unit | `mix test test/scrypath_ops/fixtures_provenance_test.exs` | Wave 0 |
| FIX-04 | Check runs first in the ops `test` alias (AST), DB-free (child `mix` with `PGPORT=1`, positive control `ecto.create` fails there) | root contract + ops unit (child mix, sync) | `mix test test/mix/tasks/fixtures_project_contract_test.exs`; `mix test test/scrypath_ops/fixtures_check_task_test.exs` | Wave 0 |
| FIX-04 | One planted failure per invariant, each asserting its problem tag; positive control `{:ok, _}` | ops unit | `mix test test/scrypath_ops/fixtures_check_test.exs` | Wave 0 |
| FIX-04 | Two renders with different `now` differ only in time-derived text; the planted pinned-time scenario fails on the relative age | ops LiveViewTest | `mix test test/scrypath_ops_web/live/fixtures_determinism_test.exs` | Wave 0 (prototype ran) |
| FIX-04 | `fixtures/` never ships: literal refutes (exist) plus directory-exists and no-prefix assertion | root unit | `mix test test/release/package_metadata_test.exs` and `mix verify.package` | edit existing (lines 135-136 exist) |
| FIX-04 | Classifier decisions: compat inventory lists `fixtures`; ops-ui path pins `fixtures/` (exists); ecommerce lanes run for `fixtures/` | node + root | `node --test scripts/ci/compat_path_classifier.test.cjs scripts/ci/ecommerce_path_classifier.test.cjs`; `mix test test/mix/tasks/workflow_wiring_test.exs` | edit existing |
| FIX-04 | Dependency absent from mounted test/prod, direct prod, host; present in dev/test; archive list includes `fixtures`; script lists include it; `lib/` never mentions it | root integration + unit | `mix test test/release/ops_dependency_boundary_test.exs --include integration --warnings-as-errors` (commit first); `mix test test/mix/tasks/dependency_boundary_contract_test.exs` | edit existing |
| FIX-04 | Namespace fence scans `fixtures/` | root unit | `mix test test/mix/tasks/verify_namespace_fence_test.exs` | edit existing (line 43) |
| FIX-04 | phase173 sources and `PostureLive` branches unchanged; deletion trigger recorded | root static | `git diff --exit-code origin/main -- scrypath_ops/test/support/phase173_fixture_source.ex examples/scrypath_ecommerce/test/support/phase173_fixture_source.ex scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` plus a README/plan text row | Wave 0 |
| FLOW-03 | No config file staged | pre-commit | `git diff --cached --name-only \| grep -E '^(\.planning/(config\|state)\.json\|\.impeccable/config\.json)$'` prints nothing | n/a |

### Sampling Rate
- **Per task commit:** `mix format --check-formatted`, `MIX_ENV=test mix scrypath_fixtures.check`, the one changed test file, and for root edits `node --test scripts/ci/compat_path_classifier.test.cjs`.
- **Per wave merge:** the root contract set and the ops fixtures tests above, plus `scripts/ci/pre_push.sh` (about a minute warm).
- **Phase gate:** local mirror of every required lane on the committed head (below), then hosted CI green on the exact PR head.

### Local mirror of each required CI lane (run on the committed head before any push)
Measured hosted costs are from Phase 195's GO-NO-GO (run 44955813968, head f9af18d4, PR cold) and the CI-EFFICIENCY mirror table.

| Lane | Mirror | Hosted cost (195) | Notes for this phase |
|------|--------|-------------------|----------------------|
| `core (required)` | `scripts/ci/pre_push.sh` (format, `deps.get --check-locked` in root, `scrypath_ops`, host; warnings-as-errors compile; Credo; workspace clean; wiring and fence tests; Node tests for both classifiers) then the root contract set above; full `mix verify.core --exclude integration --exclude docs_contract` about 6 min | 471 s | Root graph cache is not invalidated by this phase (N3). Format covers `fixtures/` only after the `.formatter.exs` input is added (N7) |
| `package (required)` | `mix verify.package` | 103 s | No `files:` change; the strengthened refute and the existing `allowed_top_level` drift guard are the proof |
| `repository-contracts (required)` | `mix verify.repository_contracts` plus the Node half (`scripts/ci/*.test.cjs`) | 595 s | Nested contracts clone committed `HEAD`: commit first. The compat inventory test is in the Node half |
| `ops-ui (path-scoped)` | `mix verify.ops_ui` (boundary integration test, then `deps.get` and `mix test` in `scrypath_ops` with isolated scratch dirs) | 517 s cold PR, 620 s cold main, 378 s warm | The first run after the `scrypath_ops/mix.exs` edit cold-misses the BEAM caches (N3); judge cost by warm rerun versus a same-day control. This lane runs every fixtures ExUnit test and the alias-first check |
| `ecommerce-mounted (required)` | `mix verify.ecommerce_mounted` (Docker, 15 to 20 min); at minimum `bash -n examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh` and the root static contract test with its mutants | 955 s (bake 292 s) | Dockerfile COPY lines and script-list edits are first proven hosted unless the Docker lane is run locally: record "Docker lane not run locally; static contract and `bash -n` ran" if so, and treat as a known risk |
| `backend (required)` | not affected (no root `lib/`) | 59 s | record "not affected" |
| After the `mix.exs` edit | `mix deps.get --check-locked` in root, `scrypath_ops/`, `examples/scrypath_ecommerce/` | seconds | Locks unchanged (N1) |
| New files in `scrypath_ops/test` | `mix test test/mix/tasks/verify_namespace_fence_test.exs` | 1 s | CI-EFFICIENCY item 9 |

### Hosted cost expectation
- **Compile/dependency:** negligible (+0.58 s dep, +0.7 s cold graph locally). No lock entry changes, no new Hex download, no NIF.
- **Cache:** the single `scrypath_ops/mix.exs` change invalidates the `ops` and `ecommerce` BEAM caches (both key prefixes), so expect the PR's first `ops-ui` and `ecommerce-mounted` runs and the first main push run after the merge to be cold, by the Phase 195 shape (517 s / 620 s against 378 s warm). It is not an ADR 0001 trigger (no storybook dependency changes); the ADR 0002 fold threshold (about 60 s) is read from the warm rerun delta against a same-day control, as Phase 195 did.
- **CI-EFFICIENCY:** record the PR cold, the warm rerun, the control and the first main run in `.planning/reference/CI-EFFICIENCY.md`; finding 26 (prefix fallback for the resolved key) is the candidate that removes the avoidable part.

### Wave 0 Gaps
- [ ] `fixtures/scrypath_fixtures/{mix.exs,.formatter.exs,.gitignore,README.md,recordings/...,lib/...}`
- [ ] `scrypath_ops/mix.exs` (dependency, alias, `preferred_envs`), `scrypath_ops/test/support/fixture_env.ex`
- [ ] ops tests: `fixtures_tracer_test.exs`, `fixtures_determinism_test.exs`, `fixtures_builders_test.exs`, `fixtures_recordings_test.exs`, `fixtures_round_trip_test.exs`, `fixtures_provenance_test.exs`, `fixtures_check_test.exs`, `fixtures_check_task_test.exs` (child mix: keep it synchronous, `saved_searches_validate_test.exs` guards that rule)
- [ ] root: path-dependency reader and rows in `dependency_boundary_contract_test.exs`; `"fixtures"` in `archive_tracked_source!` and probe additions in `ops_dependency_boundary_test.exs`; `fixtures` in `compat_path_classifier.test.cjs` `IRRELEVANT_ENTRIES`; `.formatter.exs`; namespace fence rule and test line 43; `.dockerignore` and (optional) Dockerfile COPY lines; script `forbidden_deps`/`forbidden_modules`; strengthened `package_metadata_test`; `fixtures_project_contract_test.exs`
- [ ] Framework install: none

## Security Domain

`security_enforcement` is not set to `false`, so this section applies.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V1/V14 Architecture, Configuration | yes | `only: [:dev, :test]`, prod-graph absence proven by `.app`/`_build`/`mix deps`/module probes in direct and mounted graphs and the Docker script; no route, no runtime code |
| V5 Input Validation / output encoding | yes | Hostile fixture text (markup, bidi, 511-byte id, 200-character token) must render escaped by HEEx; the determinism/hostile tests assert the escaped form and no raw `<script>` element in the rendered DOM |
| V8 Data Protection | yes | Fixture data is synthetic and labelled fictional; Meilisearch `missing_document_id` echoes whole documents, so no fixture document carries personal data (finding F2 stays a finding) |
| V10 Malicious Code / supply chain | yes | No new Hex package; Trojan Source class handled by the raw-format-character lint; recordings are plain JSON read at compile time, never evaluated |
| V2/V3/V4/V6 | no | no auth, session, access control or cryptography added |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Bidirectional or zero-width characters hidden in fixture source (Trojan Source) | Tampering | Strings stored as escapes; lint test over `fixtures/**/*.ex` with a planted raw-character temp file that must fail |
| Dev/test fixtures compiled into a production release | Elevation / Information disclosure | `only: [:dev, :test]`; absence probes in direct prod and mounted prod; Docker `mix deps` forbid list; root `lib/` never mentions it |
| Stored markup in fixture text executing in a rendered page | Tampering / XSS | HEEx escaping; a hostile-text render test asserts escaped text and absence of a script element |
| Recording container reachable from the network | Information disclosure | `127.0.0.1` random-port publish only, `--tmpfs` data, `--rm`, removed after use |

## Sources

### Primary (HIGH confidence)
- Repository files read this session with line citations above: `lib/scrypath/operator/{status,state,failed_work,failed_work/translation,failed_work/retrieval,index_contract_drift}.ex`, `lib/scrypath/meilisearch/{task_payload,tasks,client,naming}.ex`, `lib/scrypath/oban/{enqueue,payload,job_args,inspect,upsert_worker,delete_worker}.ex`, `lib/scrypath/options.ex`, `scrypath_ops/{mix.exs,lib/scrypath_ops/{schemas,posture,clock,application}.ex,lib/scrypath_ops_web/live/posture_live.ex,test/support/**,config/*.exs}`, `examples/scrypath_ecommerce/{Dockerfile,compose*.yaml,lib/.../e2e_controller.ex,scripts/verify-dependency-boundaries.sh}`, `test/release/{ops_dependency_boundary,package_metadata,package_contents}_test.exs`, `test/mix/tasks/{dependency_boundary_contract,workflow_wiring,verify_namespace_fence}_test.exs`, `scripts/ci/{beam_cache,compat_path_classifier,ecommerce_path_classifier,ecommerce_evidence,ui_literal_policy}.cjs`, `.github/workflows/ci.yml`, `.dockerignore`, `.formatter.exs`, `.credo.exs`.
- Oban 2.24.2 source in `deps/oban` (`lib/oban/queues/executor.ex`, `lib/oban/job.ex`, `lib/oban/exceptions.ex`).
- Scratch experiments under `/private/tmp/claude-501/-Users-jon-projects-scrypath/afd5559e-efb4-4bb2-8341-eb9df5900f61/scratchpad/p196` (a tracked-HEAD copy plus the dependency; not part of the repository): graph/lock/compile behaviour in dev, test, prod; mounted consumer; host; missing-directory behaviour; check-task placement, ordering and staleness; tracer; determinism; drift; classifier inventory failure.
- Task-scoped Meilisearch v1.15.2 recording (two `scrypath-p196-recording` containers, removed).
- Phase 195 artifacts: `195-RESEARCH.md`, `GO-NO-GO.md` (timings, cache-miss attribution, `.dockerignore` decision).
- Prep notes B and H and SYNTHESIS (treated as established where H marks CONFIRMED; corrected where this research found otherwise: N10 queue default, N8 refute, N11 swap).

### Secondary (MEDIUM confidence)
- [CITED: https://www.meilisearch.com/docs/reference/api/tasks] statuses, task object fields, list fields `total`/`limit`/`from`/`next`, descending order; silent on `indexSwap` under `indexUids`.
- `.planning/reference/CI-EFFICIENCY.md` lane-mirror table and findings 26 (candidate), items 8-10.

### Tertiary (LOW confidence)
- `:erlang.phash2/2` portability: erlang-questions threads (2019) and an Elixir library's note disagree; official doc text not re-read (A1).
- Hosted cost for this exact change (A2).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, no new package; path-dependency behaviour ran in dev, test, prod and mounted/host graphs.
- Architecture: HIGH for builders, fake client, check task placement/order/cost, tracer and determinism (all ran); MEDIUM for the Dockerfile COPY recommendation (text-level reasoning plus `deps.get` exit codes; Docker lane not run).
- Pitfalls: HIGH, each reproduced as a failure or a vacuous pass (N2, N4, N15 plant).
- Hosted cost: MEDIUM until the phase PR runs.

**Research date:** 2026-11-21
**Valid until:** 2026-12-05 (the Meilisearch image tag `v1.15` is a moving patch tag; re-record and re-check `PROVENANCE.md` if the image id changes, and re-check the `indexSwap` behaviour at any server bump)
