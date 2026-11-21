# Phase 192: Docs truth and README - Research

**Researched:** 2026-11-20
**Domain:** Shipped-doc truth invariant (Hex `package.files`), contract-pin migration, README trim, ExDoc built-docs link scan, CI lane planning. No runtime code changes.
**Confidence:** HIGH for in-repo facts (every file below was opened this session, scans were run); MEDIUM for the scan design (a prototype was run in Python and the derivation in Elixir; the Elixir scanner is not yet written); LOW only where tagged `[ASSUMED]`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Invariant and contract (TRUTH-01, TRUTH-02)**
- One invariant test replaces the old `verify.adopter` pins. It derives the repo-only task list from `dev/mix/tasks/` (task names present there and absent from the shipped `lib/mix/tasks/`), scans every file in `package.files` from `mix.exs`, and allows a mention only in the allowlist (`CONTRIBUTING.md`, `docs/releasing.md`) or in a sentence that says it runs from a source checkout and is not in the Hex package. — **Reversibility:** costly — it replaces several contract tests and the `PROJECT.md` contract wording, so undoing it means re-pinning each of them.
- The plan starts with an inventory of every assertion that pins `verify.adopter` or the shipped-docs wording (`readiness_contract_test`, `docs_contract_test`, `phase98`/`phase99_contract_test`, `verify_adopter_test`, and any `phase108`/`110`/`112` tests), recording for each whether it pins a claim or wiring and where its intent now lives. Tests that pin the task's own behavior (`verify_adopter_test.exs`, the `mix help verify.adopter` output) stay: they test the task, not the docs. Doc-substring pins that demand the string in a shipped guide move to the invariant plus a positive source-checkout assertion. No pin is deleted without a stronger replacement. — **Reversibility:** costly — the inventory is the audit trail for success criterion 2.
- `PROJECT.md` "Canonical Adopter Contract" is edited in the same commit as the pin change: the adopter proof spine is a maintainer task that runs from a source checkout and is not runnable from the Hex package. — **Reversibility:** costly — the contract text and the check must not disagree at any commit.
- Planted-violation cases live in the test itself (an unqualified `mix verify.adopter` guide line fails; a source-checkout-qualified line passes), run against in-memory strings, not by editing a shipped file.
- The qualifier is a small, explicit sentence pattern (a source checkout, and not in the Hex package, within the same sentence or list item), kept as data in the test so it is reviewable.

**README shape (README-01, README-02)**
- README keeps: header and badges (the header pin test stays green), one-sentence what-it-is, when it fits and does not fit, installation, one quick path, and at most three onward links after the quick path. Removed: the "Choose a route" block, the Public Surface, Sync modes (replaced by one line), Search, Backfill And Reindex, Drift, Integration smoke, Example and Architecture sections; each already has a guide or the HexDocs sidebar as its home. — **Reversibility:** costly — content leaves the README, so each removed claim must have a recorded owner in the owner map first.
- Word cap: 600 to 800 words, recorded as a chosen cap from the owner map (not a measured optimum). The test enforces an upper bound near the top of that range so a small edit does not trip it. — **Reversibility:** reversible — one constant in a test.
- The quick path states the Meilisearch prerequisite and eventual consistency before its first code block, and ends in a `Scrypath.search/3` call with its result. The schema snippet is textually identical to the one in `guides/golden-path.md` or carries an explicit "intentionally different" marker that the Phase 193 parity guard reads.
- Time-promise phrases ("in five minutes", "in minutes", "quickly", and similar) fail a test; the list is data in the test.
- Repo paths in the README are absolute GitHub URLs; guide links are absolute HexDocs URLs for the Phase 193 sidebar to resolve, consistently one style. No `mix verify.*` string outside a source-checkout qualifier.
- Voice follows `brand/BRAND.md` and the glossary ("queued", "searchable"); copy is written with the ux-writing skill and checked against the forbidden-phrase list, not taste. No claims of speed, comparison or adoption without evidence.

**Built-docs scan (TRUTH-03)**
- Extend `test/release/package_metadata_test.exs` or a sibling file: run `mix docs` output through a scan for self-links (a link whose target is the page it sits on, such as the old `readme.html` case) and unresolved extras links, with a planted failing case. The scan reads the built HTML, so it runs only where docs are built and is skipped, with a stated reason, where they are not.
- Link checking is limited to what a build can prove (extras, anchors, relative targets). Live hex.pm and hexdocs.pm checks are not in CI; they are recorded once at the Phase 193 checkpoint.

**Owner map note (README-03)**
- One short reference note, `.planning/reference/CLAIM-OWNER-MAP.md`: for each claim (what it is, fit and non-fit, install line, sync modes, support policy, operator UI status) the owning surface (README, HexDocs guide or website) and where the others link. It is written before the README is trimmed and is the input to Phase 193 and the Phase 194 decision. — **Reversibility:** reversible — a planning note.

**Delivery**
- Plans: (1) inventory, invariant and contract text; (2) README trim, quick path and README tests, the owner map written first; (3) built-docs scan and checks. Squash-merge each green PR per the standing instruction; PRs that touch `guides/`, `test/` or `mix.exs` pay the full lane cost, so batch where the order allows.
- No Hex release in this phase. The release PR for 0.3.20 needs the maintainer's explicit yes and is raised after the phase lands.

**Decided autonomously (recorded in CONTEXT)**
- Repo-only task list: derived from dev/mix/tasks/ minus lib/mix/tasks/, not hand-kept. Files scanned: every path in package.files, expanded from mix.exs. Planted cases: inline strings in the test. README tests: one small test file, no network. Guide link style: absolute HexDocs URLs. Docs scan placement: sibling of package_metadata_test. Owner map: .planning/reference/CLAIM-OWNER-MAP.md.

### Claude's Discretion
- Exact README wording, section order within the fixed shape, and the specific time-promise phrase list.
- Exact qualifier sentence pattern, so long as the planted qualified line passes and the unqualified one fails.

### Deferred Ideas (OUT OF SCOPE)
- HexDocs `groups_for_extras` regroup, `guides/overview.md` fate, link and snippet parity guards: Phase 193.
- Website Home, Evaluate, Operate content and IA: Phase 194, decided at the checkpoint.
- Hex 0.3.20 release: after this phase, with the maintainer's explicit yes.
- Adding `guides/` to the CI classifier allowlist: a measured candidate for `CI-EFFICIENCY.md`, not part of this phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TRUTH-01 | No `package.files` file tells an adopter to run a repo-only task; one derived invariant with planted cases | Section "Repo-only task derivation" (55 derived names, verified run), "Mention inventory" (21 unqualified blocks in 7 non-allowlisted files, 18 outside the README, plus 2 structural exemptions), "Pin inventory" tables A and B |
| TRUTH-02 | `PROJECT.md` Canonical Adopter Contract and the invariant agree | "Contract text" (lines 68-86 quoted; no test reads it today; a contract-vs-check test is recommended; the "published 0.3.17" sentence is stale) |
| TRUTH-03 | Built docs scanned for self-links and unresolved extras links; README links resolve; header pin stays green | "Built-docs scan" (real build: 3 unresolved, 2 dead anchors, 0 extras self-links, 16 wrong-target links), "README tests" (header pin mechanics) |
| README-01 | README one job, word cap, at most three onward links, absolute URLs, no unqualified `mix verify.*` | "README pin ledger" (about 25 README pins in 9 test files must be moved or re-pointed), word-count method, link rules |
| README-02 | Quick path ends in `Scrypath.search/3` result, prerequisite and eventual consistency first, no time promises | "Quick path" (real API and config shape verified in `lib/`; the golden-path config snippet is not read by `Scrypath.Config`) |
| README-03 | Owner map note, one owner per claim | "Owner-map inputs" (10 README-only claim tokens with no other owner today) |
</phase_requirements>

## Summary

The phase is bigger and more entangled than CONTEXT assumed, in four specific ways. (1) The repo-only mention surface is wider than "five files": the derived set is 55 task names, and 21 blocks across 7 non-allowlisted shipped files are unqualified at the paragraph/list-item/table-row level (`docs/operator-support.md` alone has 10, `README.md` 3, `guides/support-and-compatibility.md` 3, `guides/outside-adopter-intake.md` 2, `docs/search-backend-sre.md`, `docs/jtbd-gap-map.md`, `guides/golden-path.md` one each; 18 of them are outside the README, which the trim rewrites). Two shipped files that cannot be edited to green must be exempted: `CHANGELOG.md` (23 history mentions; `workflow_wiring_test.exs:1461-1462` requires two of them) and `mix.exs` (`preferred_envs` registers every verifier). A third class is invisible to a `dev/mix/tasks`-only derivation: `guides/operator-mix-tasks.md:98-104` tells adopters to run `mix scrypath_ops.saved_searches.validate`, a task that lives in `scrypath_ops/` and is pinned by `docs_contract_test.exs:633`.

(2) The README trim breaks about 25 README pins in 9 test files, mostly `String.contains?` checks for `guides/<name>.md` route substrings that the chosen absolute-HexDocs link style removes, and 10 pinned README claims have no other owner anywhere today. Pins must be re-pointed to the owning surface, not deleted. `docs_contract_test.exs` is tagged `:docs_contract`, so it is excluded from the `core` lane and from `scripts/ci/pre_push.sh`; it runs only in the hosted `package` lane, so it must be run locally by hand.

(3) The built docs are not clean today. `mix docs --warnings-as-errors` passes while the extras pages carry 3 unresolved links (`contributing.html`: `.github/workflows/ci.yml` twice, `compose.yaml`), 2 dead anchors (`readme.html#production`, `readme.html#mounted-host-app-assets`), and 16 repo-path links in shipped markdown that ExDoc silently maps to the Scrypath README page (basename collision on `README.md`). The old self-link defect itself is already fixed (0 self-links on extras pages), so a self-link-only scan would pass on day one and prove little. A regex scan is adequate (no Floki in `mix.lock`), costs about 1 second, and fits inside the one existing docs build in `Scrypath.Release.BuiltDocsBrandTest`.

(4) Nothing here needs a new dependency, a new CI job or a new gate-ledger row; all new tests ride the `core` lane (untagged) and, for the docs scan, the `package` lane.

**Primary recommendation:** Build one pure scanner (`scan(files, repo_only, qualifier)` over in-memory `{path, text}` pairs) in a new untagged `test/release/shipped_docs_contract_test.exs`, derive the repo-only set with the existing `Scrypath.Release.PackageContract.collect_task_modules/1`, qualify the 18 non-README mentions in place (so old pins keep passing), exempt `CHANGELOG.md` and `mix.exs` by named, reasoned constants, and put the built-docs scan as new tests inside `BuiltDocsBrandTest` (one docs build, no async race). Run the 8-file doc-pin set locally (2.6 s measured) before every push.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| "No shipped doc names a repo-only task" | Test layer, `core` lane (untagged ExUnit file) | `package` lane via none (not needed) | Pure file reads; runs on every `mix test`; needs no history, so shallow checkout is fine |
| Derive repo-only task set | Test support (`PackageContract.collect_task_modules/1`, AST based) | `dev/mix/tasks/**`, `lib/**` source trees | Path-independent, already drift-guarded by `package_contents_test.exs:157-180` |
| Contract text agrees with the check | Planning file (`.planning/PROJECT.md`) read by a test | `core` lane | Other tests already read PROJECT.md (`phase108_contract_test.exs:14`, `docs_contract_test.exs:1276`) |
| README does one job | README.md + one README contract test (`core` lane) | HexDocs sidebar (Phase 193) | The README is GitHub front page, hex.pm page and HexDocs `main: "readme"` (`mix.exs`) |
| Built-docs link integrity | ExDoc build output scanned in `BuiltDocsBrandTest` (`core` and `package` lanes) | Source-level link rule (shipped markdown) | Only the build shows what ExDoc did to a link; the source rule catches the basename-collision class the build cannot |
| Claim ownership | Planning note `.planning/reference/CLAIM-OWNER-MAP.md` | Optional tiny table-shape test | Feeds Phase 193 and 194 |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ExUnit (Elixir 1.19.0 / OTP 28.5 locally) | stdlib | Contract tests | Whole repo uses it; `elixir --version` printed `Elixir 1.19.0 (compiled with Erlang/OTP 28)` [VERIFIED: run] |
| ExDoc | 0.40.4 | Built-docs source for the scan | `mix.lock:16` `"ex_doc": {:hex, :ex_doc, "0.40.4", ...`; built HTML carries `content="ExDoc v0.40.4"` [VERIFIED: mix.lock:16, built readme.html] |
| `Scrypath.Release.PackageContract.collect_task_modules/1` | in repo | AST-based `Mix.Tasks.*` name discovery from `{path, source}` pairs | `test/support/release/package_contract.ex`; already used by `package_contents_test.exs:169-179` and `:253-275` |
| `Scrypath.RepoTooling` | in repo | `@tasks_root "dev/mix/tasks"` single location of the verifier tree | `test/support/repo_tooling.ex:7` [VERIFIED] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Regex`, `Path`, `File` | stdlib | Scan built HTML and markdown | `BuiltDocsBrandTest` already scans built HTML with regexes (`local_refs/1`, `html_attribute_values/2`, `package_metadata_test.exs:828-858`) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Regex over built HTML | Floki or `lazy_html` | Neither is in `mix.lock` (`grep -c "floki\|lazy_html\|html5ever" mix.lock` printed `0`) [VERIFIED: run]. House rule: copy-paste over a new dependency. ExDoc output is machine generated and regexes are already the established method here |

**Installation:** none. No package is installed or added by this phase.
**Version verification:** no new package; ExDoc 0.40.4 read from `mix.lock`.

## Package Legitimacy Audit

No external packages are installed or recommended by this phase. Nothing to audit. `Packages removed due to [SLOP] verdict:` none. `Packages flagged as suspicious [SUS]:` none.

## Architecture Patterns

### System Architecture Diagram

```
mix.exs  package.files  ---------------------------------------------+
  (plain entries: 2 dirs lib, guides + files)                         |
        | expand (dir -> recursive regular files; keep .md .ex .exs)  v
        +--------------------------------------------------> SHIPPED FILE SET  (136 files measured)
                                                                      |
dev/mix/tasks/**/*.ex ---+                                            |
scrypath_ops/lib/mix/tasks/**/*.ex  (recommended, see Open Q1) --+   |
examples/*/lib/mix/tasks/**/*.ex    (recommended, see Open Q1) --+   |
        | collect_task_modules (AST)                              |   |
        v                                                         |   |
   names A  ---- minus ----  names B (lib/**/*.ex = 8 public tasks)   |
        |                                                             |
        v                                                             |
   REPO-ONLY NAMES (55 from dev/) -> mention regex (data)             |
                                                                      v
 file text -> blocks (paragraph | list item | table row | fenced block + lead-in)
        -> block mentions a repo-only name?
              no  -> ok
              yes -> file in allowlist/exempt?  yes -> ok
                     block matches qualifier (data)? yes -> ok / no -> VIOLATION {file, line, name}
 planted in-memory cases prove the scanner can fail and can pass

ExDoc build (in-process, tmp dir, --warnings-as-errors)  [existing setup_all, package_metadata_test.exs:243-259]
        -> extras pages only (data-type="extras") -> hrefs -> external? skip
              relative: file exists in build? no -> UNRESOLVED
                        path == own page and no fragment? -> SELF-LINK
                        fragment: id="frag" exists in target page? no -> DEAD ANCHOR
 planted in-memory page strings prove each of the three can fail
```

### Recommended Project Structure
```
test/release/shipped_docs_contract_test.exs   # TRUTH-01/02 invariant + planted cases (untagged -> core lane)
test/release/package_metadata_test.exs        # add TRUTH-03 built-docs link tests to BuiltDocsBrandTest (one docs build)
test/scrypath/readme_contract_test.exs        # README-01/02 + owner-map shape (untagged -> core lane, no network)
.planning/reference/CLAIM-OWNER-MAP.md        # README-03, written before the README is trimmed
.planning/phases/192-.../192-PIN-INVENTORY.md # the inventory (tables A-D below are its draft)
```
Placement note: any change under `test/release/` or to `mix.exs` also triggers the required `ops-ui (path-scoped)` lane (regex quoted in "CI lanes"); `test/scrypath/` does not. That costs compute, not wall time (ops-ui runs in parallel and is shorter than `ecommerce-mounted`).

### Pattern 1: Derived repo-only set (verified run)
**What:** Reuse the AST collector; never hand-keep a list.
```elixir
# Source: test/support/release/package_contract.ex (collect_task_modules/1); output verified by running it
alias Scrypath.Release.PackageContract

names = fn glob ->
  glob |> Path.wildcard() |> Enum.map(&{&1, File.read!(&1)})
  |> PackageContract.collect_task_modules() |> Enum.map(&elem(&1, 0))
end

shipped = names.("lib/**/*.ex")   # 8: scrypath.failed, scrypath.index.contract_drift, scrypath.reconcile,
                                  #    scrypath.retry, scrypath.settings.diff, scrypath.settings.hot_apply,
                                  #    scrypath.settings.read, scrypath.status
repo_only =
  (names.("dev/mix/tasks/**/*.ex") ++
     names.("scrypath_ops/lib/mix/tasks/**/*.ex") ++ names.("examples/*/lib/mix/tasks/**/*.ex"))
  |> Enum.uniq() |> Kernel.--(shipped) |> Enum.sort()
```
Measured: `dev/mix/tasks/**` yields 55 names (nested `verify/*.ex`, `verify/phoenix_example/*.ex` and `brand/update.ex` included; overlap with lib is `[]`); `scrypath_ops/lib/mix/tasks/**` adds `scrypath_ops.check_nav_contract`, `scrypath_ops.saved_searches.validate`; `examples/*/lib/mix/tasks/**` adds `e2e.prepare_search`, `scrypath.demo.seed`, `scrypath.seed` [VERIFIED: run]. Add non-vacuity guards: `"verify.adopter" in repo_only`, `length(repo_only) >= 50`, `"scrypath.status" not in repo_only`.

### Pattern 2: Package file expansion (verified definition, expansion run)
`mix.exs:315-316` [VERIFIED]: `files:` then `~w(lib .formatter.exs mix.exs README.md CONTRIBUTING.md ARCHITECTURE.md CHANGELOG.md LICENSE SECURITY.md guides docs/jtbd-gap-map.md docs/releasing.md docs/operator-support.md docs/search-backend-sre.md docs/local-demo-docker-dx.md)`. Plain entries, no globs; `lib` and `guides` are directories. `package_contents_test.exs:494` (`copy_packaged_files!/1`) copies each entry with `File.cp_r!`, and `:157-167` compares first path segments. Expand the same way:
```elixir
for entry <- Scrypath.MixProject.project()[:package][:files],
    path <- Path.wildcard(entry, match_dot: true),
    file <- (if File.dir?(path), do: Path.wildcard(Path.join(path, "**/*"), match_dot: true), else: [path]),
    File.regular?(file), Path.extname(file) in ~w(.md .ex .exs),
    do: file
```
Footgun: `lib/.DS_Store` exists locally (git-ignored via `.gitignore:8`) and is not in CI; filter by extension (or `String.valid?/1`) so a local-only binary cannot crash the scan [VERIFIED: `git check-ignore -v lib/.DS_Store`]. Measured 136 files before the extension filter.

### Pattern 3: Block unit + qualifier as data
Prototype (Python, run in scratchpad; port to Elixir untested): split text on blank lines; inside a block, each list item (`-`, `*`, `N.`) and each table row (`|`) is its own unit; a fenced code block is judged together with the block immediately before it (the lead-in paragraph); a unit "mentions" if the mention regex matches; it is "qualified" if it contains `source checkout` and `Hex package` and `\bnot\b` (case-insensitive). Keep all three as data. Existing qualified phrasings all satisfy this: `docs/operator-support.md:7`, `docs/jtbd-gap-map.md:78`, `README.md:31`, `guides/support-and-compatibility.md:123`, `guides/outside-adopter-intake.md:28` [VERIFIED: scan].
Mention regex that worked with zero false positives on the shipped set: dotted repo-only names bounded by `(?<![\w.])(?:mix\s+)?NAME(?![\w]|\.[\w*])`, plus `mix\s+verify(?![\w]|\.\w)` for the bare `verify` task, plus the family forms `mix verify.*` / `` `verify.*` ``. The bare word "verify" must require the `mix ` prefix: my first scan without that rule produced 27 false positives (`verify` in ordinary prose) [VERIFIED: run].

### Pattern 4: Built-docs link scan (prototype run on real builds)
Scope to extras pages: the built HTML marks them `data-type="extras"` (module pages carry `data-type="modules"`) [VERIFIED: built readme.html, golden-path.html vs Scrypath.html]. Module pages legitimately self-link (ExDoc autolinks a module name inside its own docs: `Scrypath.Metadata.html`, `Scrypath.Schema.html` x2, `Scrypath.Composition.html` = 4 hits), so scanning them would false-positive. Per extras page: collect `<a ... href="...">` (regex `~r/<a\s[^>]*?\bhref="([^"]*)"/`), skip `http(s):`, `//`, `mailto:`, `data:`; resolve the rest against the page directory; flag UNRESOLVED if the file is missing in the build, SELF-LINK if the resolved file is the page itself and there is no fragment, DEAD-ANCHOR if the fragment is not an `id="..."` in the target page. Count of extras pages measured: 35 (test-env build); assert `>= length(docs[:extras])` as a vacuity guard. Planted cases are in-memory strings: a copy of `readme.html` text with `<a href="readme.html">x</a>` appended (self-link), `href="no-such-page.html"` (unresolved), `href="golden-path.html#no-such-id"` (dead anchor); control: the real build returns `[]` after the source fixes below.

### Pattern 5: README contract test (plain file reads, no network)
One untagged file reads `README.md`, `guides/golden-path.md`, `mix.exs` data, and asserts: header block unchanged (delegated to the existing pin test), word cap, onward-link count, host allowlist for absolute URLs, repo-path links are `https://github.com/szTheory/scrypath/blob/main/...` and the path exists in the working tree, guide links are `https://hexdocs.pm/scrypath/<slug>.html` where `<slug>` is an extras basename, prerequisite and eventual-consistency text precedes the first fenced code block, last elixir fence contains `Scrypath.search(` and a result line, schema snippet equals the golden-path one, time-promise list absent. Untagged on purpose (precedent: `backfill_contract_docs_test.exs:2-3` "Not tagged :docs_contract on purpose, so drift fails the default `mix test`").

### Anti-Patterns to Avoid
- **Hand-kept repo-only list:** goes stale; locked decision says derive.
- **Deleting a pin to reach green:** the named failure in prep note D section 2; every pin below has a fate and a stronger or equal replacement.
- **Scanning module pages for self-links:** 4 legitimate ExDoc autolinks would fail the scan.
- **A self-link-only scan:** passes today (0 extras self-links) and misses the 16 wrong-target links.
- **A second concurrent `Mix.Tasks.Docs.run` in the same VM:** see Pitfall 8.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Repo-only task names | A literal list or a filename parser | `PackageContract.collect_task_modules/1` + `Mix.Task.task_name/1` | Module names map to task names (`Mix.Tasks.Verify.PhoenixExample.LockGraph` is `verify.phoenix_example.lock_graph`); nested dirs and `__MODULE__`-relative names are already handled and tested (`package_contents_test.exs:80-155`) |
| Shipped file set | A second copy of the package file list | `Scrypath.MixProject.project()[:package][:files]` | One data source shared with `package_contents_test.exs` (locked decision) |
| HTML parsing | Floki / a DOM library | Regex scoped by `data-type="extras"` | No new dependency; the module already does this for `src`/`srcset` |
| Docs build in tests | A second `mix docs` subprocess | The existing `setup_all` in `BuiltDocsBrandTest` | One build per run; avoids a concurrency hazard |
| Markdown parser | A full CommonMark parser | The block splitter described in Pattern 3 | The check needs blocks, not an AST |

**Key insight:** every piece of machinery this phase needs already exists in `test/`; the work is composing it and migrating the pins.

## Pin inventory (TRUTH-01 / TRUTH-02 / README-01)

Legend: claim = asserts what a doc says; wiring = asserts that a task/file/workflow is hooked up. Lines are current as of this session.

### Table A: pins on the task's own behavior or wiring (STAY unchanged)
| Where | What it asserts | Type | Fate |
|-------|-----------------|------|------|
| `test/mix/tasks/verify_adopter_test.exs:12-27,58-72,79-110` | argument errors, live prerequisites, `@fast_tests` file names (`~S\|"test/scrypath/readiness_contract_test.exs"\|` etc., `:79-84`), `mix help verify.adopter` output (`:86-100`), progress marker | behavior | Stays. Tests the task, not the docs |
| `test/scrypath/readiness_contract_test.exs:46-61` | `mix help verify.adopter` output contains the three test paths, env names, `cd examples/phoenix_meilisearch` | behavior | Stays |
| `test/scrypath/docs_contract_test.exs:336-343` | `@verify_adopter` task source names the readiness/phase110/verify_adopter test files, the three env vars, `mix verify.adopter --live` | wiring (task source) | Stays |
| `test/scrypath/phase99_contract_test.exs:50-62` | order `mix deps.get --check-locked` < `mix test` inside the task's `--live` docs | wiring | Stays |
| `phase99_contract_test.exs:88-110`, `workflow_wiring_test.exs:1195-1225`, `phase108_contract_test.exs:79-102` | `mix.exs` `"verify.phase9x": :test` registrations and CONTRIBUTING gate rows | wiring in allowlisted/exempt files | Stays (CONTRIBUTING allowlisted, `mix.exs` exempt) |
| `workflow_wiring_test.exs:1461-1462` | `CHANGELOG.md` contains `mix verify.workspace_clean` and `mix verify.release_parity` | wiring (history) | Stays. **Forces the `CHANGELOG.md` exemption** |
| `workflow_wiring_test.exs:1431-1438` | `docs/releasing.md` contains `### \`mix verify.workspace_clean\``, `mix verify.release_parity` | claim in allowlisted file | Stays |
| `test/release/consumer_smoke_test.exs:206-215` | in a real consumer, `mix verify.package` gives `The task "verify.package" could not be found` | behavior | Stays. It is the executable proof of the contract premise "not runnable from the Hex package" |
| `test/release/package_contents_test.exs:253-275`, `:277-297` | no `verify*` file under `lib/mix/tasks`; no extra or lib file contains `Mix.Tasks.Verify` | narrower cousin of the new invariant (module names only) | Stays; the invariant generalizes it to task names across all shipped files |

### Table B: pins that demand a repo-only task string in a shipped doc (the TRUTH-01 inventory)
| # | Pin (file:line) | Reads | Asserts | Type | Proposed fate |
|---|-----------------|-------|---------|------|---------------|
| B1 | `readiness_contract_test.exs:41` | support guide | contains `mix verify.adopter` | claim ("guide documents the fast/live split") | REWRITE into: at least one block of the support guide mentions `verify.adopter` and every such block passes the qualifier. Equal-or-stronger (adds the qualifier) |
| B2 | `readiness_contract_test.exs:64-65` | README | contains `mix verify.adopter`, `mix verify.adopter --live` | claim | REPLACE by the invariant (README must not name it unqualified). The CONTRIBUTING half `:66-67` stays (allowlisted). Intent moves: the proof path is documented where maintainers read it |
| B3 | `docs_contract_test.exs:316-319` | README | `guides/support-and-compatibility.md` + `mix verify.adopter` | claim | SPLIT: route token re-pointed to the README contract test (HexDocs URL form); task token covered by the invariant |
| B4 | `phase98_contract_test.exs:11-14` | README | `mix verify.adopter`, `--live` | claim | REPLACE by the invariant (same as B2) |
| B5 | `phase98_contract_test.exs:16-22` | support guide | `mix verify.adopter`, `--live`, `SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT`, `SCRYPATH_MEILISEARCH_URL` | claim | Env tokens stay; task tokens become the B1 positive qualified assertion |
| B6 | `phase99_contract_test.exs:21-26` | README | `guides/support-and-compatibility.md`, `guides/outside-adopter-intake.md`, `mix verify.adopter`, `--live` | claim | SPLIT as B3; the `guides/...md` route substrings are re-pointed (see Table C) |
| B7 | `phase99_contract_test.exs:28-32` | support guide | `mix verify.adopter`, `--live`, `examples/phoenix_meilisearch/README.md` | claim | B1 for the task tokens; the example path still appears inside an absolute GitHub URL |
| B8 | `phase99_contract_test.exs:34-39` | intake guide | `README.md`, `guides/support-and-compatibility.md`, `mix verify.adopter`, `--live` | claim | B1 for the task tokens (the intake guide's two bullets need qualifying) |
| B9 | `docs_contract_test.exs:510` | README | `mix verify.phase11` (inside the "Versioning and upgrades" pin group) | claim | Removed with the README trim; covered by the invariant. Not demanded anywhere else |
| B10 | `docs_contract_test.exs:879` | README | `mix verify.ops_ui` ("README surfaces canonical ops verification", Phase 53) | claim | REPLACE: README states the operator UI is in the checkout and not part of the Hex package (claim kept, task name dropped); `mix verify.ops_ui` stays demanded in CONTRIBUTING by `:886-900` (stays) |
| B11 | `docs_contract_test.exs:1231-1235` | `docs/operator-support.md` | `mix verify.phase14`, `20`, `26`, `28`, `11` | claim (only place these gates are documented: CONTRIBUTING has 0 mentions of phase14/20/26/28) | KEEP the pin; qualify the 10 blocks in place so it still passes and the invariant is satisfied |
| B12 | `docs_contract_test.exs:633` | `guides/operator-mix-tasks.md` | `mix scrypath_ops.saved_searches.validate` | claim | KEEP; qualify the section if the derivation includes `scrypath_ops/lib/mix/tasks` (Open Q1) |
| B13 | `test/mix/tasks/dependency_boundary_contract_test.exs:238` | support guide | exact link `[ScrypathOps production runbook](../scrypath_ops/README.md#production)` | claim (a broken link form: dead `readme.html#production` on HexDocs) | REWRITE together with the link fix (absolute GitHub URL), keeping "the support guide links the runbook" |

Replacement design, so "stronger" is literal: (i) the invariant, (ii) for each owner guide that documents the fast/live split (support guide, intake guide, operator-support) one positive assertion that the mention exists and is qualified, (iii) the old CONTRIBUTING pins stay as they are.

### Table C: README pin ledger (every test that reads `README.md`)
Absolute HexDocs links remove every `guides/<name>.md` substring from the README. Tokens below marked "only README" have no other owner today (checked against `guides/*.md`, ARCHITECTURE, CONTRIBUTING, docs/*, example README) [VERIFIED: scan script].

**C1. Route-index pins (the README stops being the route index; owner is the HexDocs sidebar, Phase 193 regroup):**
| Pin | Tokens | Proposed fate |
|-----|--------|---------------|
| `docs_contract_test.exs:133-137` | `guides/jtbd-and-user-flows.md`, `jobs and adoption path` | Re-point to `mix.exs` extras membership of that guide (the sidebar is the route) |
| `docs_contract_test.exs:153-168` (README half `:163-166`) | `guides/request-edge-search.md`, `Request-edge search` | same |
| `docs_contract_test.exs:177-200` (README half `:197-200`) | `guides/composing-real-app-search.md`, `real-app composition` | same |
| `docs_contract_test.exs:243-269` | `## Choose a route` plus 21 guide/example/ops-readme path tokens | Delete the README half only after the extras-membership replacement exists; the jtbd-guide half (`:271-291`) stays |
| `docs_contract_test.exs:443-458` | opener, `## Installation` < `## Choose a route` < `## Quick Path`, `~> 0.3`, no `{:req, "~> 0.5"}`, no `{:scrypath, path: "../scrypath"}`, `Scrypath owns its internal transport dependency`, `Add Oban only when you choose`, `field :status, :string`, `guides/golden-path.md` | Rewrite ordering to `## Installation` < `## Quick Path`; keep the rest by keeping the tokens (see C3) |
| `docs_contract_test.exs:489-517` | `**Start here:**`, `guides/golden-path.md`, `## Versioning and upgrades`, `mix verify.phase11`, `docs/releasing.md`, `Choose **\`:inline\`**`, `guides/sync-modes-and-visibility.md`; orders `## Sync modes` < `## Search`, `## Versioning and upgrades` < `## Search` | Re-point: golden path to the README contract test (HexDocs URL), sync modes to the one-line replacement, versioning to the owner map decision (Open Q5) |
| `docs_contract_test.exs:838-841` | `](guides/sync-modes-and-visibility.md)`, regex `exact return contract, lifecycle, and recovery guidance` | Re-point to the new onward link (HexDocs URL) and keep the phrase in the one-line sync-modes replacement, or move the phrase pin to the sync guide |
| `docs_contract_test.exs:705-712` | README contains `cd examples/phoenix_meilisearch` (or the smoke path) and order `cd examples/phoenix_meilisearch` < `./scripts/smoke.sh` | The Integration smoke section is removed; the same pins already hold for CONTRIBUTING (`:714-721`) and `./scripts/smoke.sh` is in `guides/golden-path.md`. Drop the README half, recorded |
| `readiness_contract_test.exs:12,19`; `phase99_contract_test.exs:185,201,205`; `phase110_contract_test.exs:32-36`; `docs_contract_test.exs:317` | `guides/support-and-compatibility.md`, `guides/outside-adopter-intake.md`, `support-and-compatibility.md` | Normative-routing pins ("non-owner surfaces route to the support authority"). Keep README linking to the support guide as one of the three onward links and accept the HexDocs form `https://hexdocs.pm/scrypath/support-and-compatibility.html` via one small helper; `outside-adopter-intake` route may move to the support guide's own pin (it already links it, `readiness_contract_test.exs:21`) |

**C2. Claims that only the README carries (need an owner before the trim; README-03):**
| Token(s) | Pin | Today's other owner | Proposed disposition |
|----------|-----|---------------------|----------------------|
| `Use backfill when` | `docs_contract_test.exs:122-130` | none (`Use managed reindex when` is also in `guides/meilisearch-concepts.md`) | Move 1 sentence into `guides/drift-recovery.md`, re-point pin |
| `does not heal anything by default`, `retry, backfill, or reindex deliberately` | `:531-538` | none in guides (ARCHITECTURE has "Reconcile is not an auto-heal button", pinned at `:520-529`) | Move the sentence into `guides/drift-recovery.md` or retire the README half with a recorded pointer to ARCHITECTURE |
| `Detect drift before deciding`, `stale search hits whose hydrated records are now missing`, `failed or discarded sync work` | `:551-559` (`document-count mismatches` and `stale deletes` also in ARCHITECTURE) | none | Move the drift bullets into `guides/drift-recovery.md`, re-point |
| `They do not create a second operator product surface.` | `:1216-1229` | ARCHITECTURE has the equivalent sentence, pinned in the same test | Retire the README half, recorded |
| `accepted work may not yet be visible in search` | `:847-851` | sync guide has `Accepted work is not the same thing as search visibility.` | Keep the sentence in the quick-path eventual-consistency line (it is README-02 text anyway) |
| `Scrypath owns its internal transport dependency`, `Add Oban only when you choose` | `:443-458` | `guides/getting-started.md` says "Scrypath also owns its internal transport dependency" | Keep one sentence in Installation, or re-point to getting-started |
| `result.omitted` | `backfill_contract_docs_test.exs:45-47` | `guides/sync-modes-and-visibility.md` is pinned for `omitted` at `:50-58` | Retire the README half, recorded (the owner pin exists) |
| `Meilisearch-first in v1` | `telemetry_test.exs:314-324` | none | Keep in the "when it does not fit" line (cheapest) |

**C3. Tokens that stay valid if the new README keeps them (cheap):** opener `Scrypath, the Ecto-native search indexing library` (`docs_contract_test.exs:444`, `phase112_contract_test.exs:54-59`); `{:scrypath, "~> 0.3"}` and absence of `{:scrypath, "~> 1.0"}`, `{:req, "~> 0.5"}`, `{:scrypath, path: "../scrypath"}` (`docs_contract_test.exs:350,447-449`, `phase99_contract_test.exs:152,155`); `field :status, :string` (`:485`); lowercase `release-backed guidance` and `main may contain unreleased changes` (`phase99_contract_test.exs:176-179`); `scope-and-reopen-policy.md`, `concrete production bug`, `reviewed outside-adopter evidence`, `deliberate strategic product decision` (`phase112_contract_test.exs:54-67`, one sentence); README must NOT contain the lifecycle chain `requested -> enqueued -> processing -> ...` (`:460-466`); README must NOT contain the tuple literals `1.17.3`, `26.2.5`, `1.19.0`, `28.1` as substrings (`phase110_contract_test.exs:19,36`, `phase99_contract_test.exs:205-212`); misleading patterns absent (`phase112_contract_test.exs:42-50` e.g. `immediately searchable`, `always current`); no internal-ID patterns (`docs_contract_test.exs:94-119`); elixir fences must parse (`:1244-1252`); no telemetry event table rows (`telemetry_contract_test.exs:279`).

**C4. Structural README pins to preserve verbatim (the header pin):** see "README tests" below.

### Table D: contract text (TRUTH-02)
`.planning/PROJECT.md:68-86` "Canonical Adopter Contract" says (verbatim, lines 75-76): "`mix verify.adopter` is the canonical adopter proof spine." and "Since Phase 183, repository-only `mix verify*` tasks (including `mix verify.adopter`) run from a source checkout. They live in `dev/mix/tasks/`, compile only under `MIX_ENV=test`, and are not part of the Hex package built from this source, which ships only the public `mix scrypath.*` operator tasks. The published 0.3.17 still contains them until a separate maintainer-confirmed release." [VERIFIED: PROJECT.md:75-76].
- The "published 0.3.17" sentence is stale: `CHANGELOG.md:18` (0.3.18, 2026-11-19) and `:45` ("The repository-only `mix verify*` maintainer tasks are no longer shipped in the Hex package; only the public `mix scrypath.*` operator tasks are.") record the packaging change, and hex.pm lists 0.3.19 (2026-11-20), 0.3.18 (2026-11-19), 0.3.17 (2026-10-25) [VERIFIED: CHANGELOG.md, hex.pm API].
- No test reads these bullets. Tests that read PROJECT.md pin only other tokens, which the edit must keep: `AUDT-01` (`docs_contract_test.exs:1307`), `97-SCOPE-GUARD.md` (`:1372`), `maintenance-and-evidence mode`, `outside-adopter evidence`, `concrete production bug`, `tenant-preserving ecommerce readiness regression proof`, `aligned roadmap/JTBD truth` (`phase108_contract_test.exs:55-61`), and `phase111_contract_test.exs:69` (concatenated check for `no path-scoped required promotion`).
- Recommendation `[ASSUMED]`: add one executable agreement test. Read the `## Canonical Adopter Contract` section and assert that the block naming `verify.adopter` passes the same qualifier data the invariant uses, so the contract and the check cannot disagree silently (TRUTH-02 as a check, not a promise). Draft contract bullet: "`mix verify.adopter` is the canonical adopter proof spine for maintainers. It is a repository-only task: it runs from a source checkout (`dev/mix/tasks/`, compiled only under `MIX_ENV=test`) and is not runnable from the Hex package, which has shipped only the public `mix scrypath.*` operator tasks since 0.3.18. Hex-shipped files name a repository-only task only in a sentence that says so, or in `CONTRIBUTING.md` and `docs/releasing.md`; `CHANGELOG.md` (release history) and `mix.exs` (`preferred_envs`) are named exemptions. `test/release/shipped_docs_contract_test.exs` enforces this." Also fix `PROJECT.md:146` only if its wording ("pinned by `mix verify.adopter`") conflicts; it does not.

## Mention inventory (every shipped mention of a repo-only task, qualified or not)

Unit = paragraph, list item, table row, or fenced block judged with its lead-in. Q = qualified, U = unqualified. [VERIFIED: scan run over the 136 shipped files; allowlisted files excluded]
| File:line | Mention | Q/U | Action |
|-----------|---------|-----|--------|
| `README.md:31` | `mix verify.adopter`, `--live` | Q | removed by the trim |
| `README.md:36` | `mix verify.ops_ui`, "`mix verify.*` map" | U | qualify in Plan 1 (README is shipped and the invariant scans it); removed by the trim in Plan 2 |
| `README.md:118` | `mix verify.phase11` | U | same |
| `README.md:196-200`, `:204` | `mix verify.meilisearch_smoke` (fence qualified by `:196`; `:204` bare) | Q / U | same |
| `guides/support-and-compatibility.md:123` | qualifier sentence ("These verification commands run from a source checkout ... not part of the Hex package.") | - | exists |
| `guides/support-and-compatibility.md:125` | "Other root `mix verify.*` capabilities are repository-maintainer commands, not Hex APIs." | U (no "source checkout") | qualify |
| `guides/support-and-compatibility.md:131-132` | `mix verify.adopter`, `--live` bullets | U | qualify each bullet |
| `guides/outside-adopter-intake.md:28` | qualifier sentence | - | exists |
| `guides/outside-adopter-intake.md:32-33` | `mix verify.adopter`, `--live` bullets | U | qualify each bullet |
| `guides/golden-path.md:137` | `mix verify.phoenix_example` in the CI bullet | U | qualify (golden-path pins at `docs_contract_test.exs:723-736` keep passing) |
| `guides/operator-mix-tasks.md:98,104` | `mix scrypath_ops.saved_searches.validate` | U, and only visible if the derivation includes `scrypath_ops/` | qualify (Open Q1) |
| `docs/operator-support.md:7` | `mix verify.adopter` x2 | Q | keep |
| `docs/operator-support.md:13,14,15` | `mix verify.phase14`, `phase28`, `phase11` list items | U | qualify |
| `docs/operator-support.md:56-61` | bash fence of 5 gates | U (lead-in is `## Verification` heading + "Before merge or release handoff, run:") | add a qualified lead-in sentence |
| `docs/operator-support.md:66-70`, `:72` | 5 table rows, closing sentence | U | qualify (header cell or lead-in; each row is a unit under the recommended rule) |
| `docs/search-backend-sre.md:76` | `mix verify.phase13` | U (heading says "From the repo root (maintainer checks)") | qualify |
| `docs/jtbd-gap-map.md:78` | `mix verify.adopter` | Q | keep |
| `docs/jtbd-gap-map.md:121` | `closes TRUTH-01 through \`mix verify.phase108\`` | U | reword (history line) or qualify |
| `CHANGELOG.md` | 23 history mentions | n/a | exempt (release-please owned; D-19 precedent `package_contents_test.exs:278-283`; `workflow_wiring_test.exs:1461-1462`) |
| `mix.exs:49-101` | `preferred_envs` registrations | n/a | exempt (code) |
| `CONTRIBUTING.md`, `docs/releasing.md` | many | n/a | allowlisted by the locked decision |
| `lib/**`, `ARCHITECTURE.md`, `SECURITY.md`, `docs/local-demo-docker-dx.md`, 20 other guides | 0 | - | clean |
Net: 18 non-README unqualified blocks in 6 files to qualify (operator-support 10, support 3, intake 2, SRE 1, jtbd-gap-map 1, golden-path 1) plus `operator-mix-tasks.md` under Open Q1. The CONTEXT list (5 files, "README line 31 qualified") understates this: it missed `README.md:36,118,204`, `docs/operator-support.md:13-72`, `docs/search-backend-sre.md:76`, `docs/jtbd-gap-map.md:121`, `guides/golden-path.md:137`, `guides/support-and-compatibility.md:125`.

Sequencing consequence: README is in `package.files`, so a Plan 1 invariant is red on `README.md:36,118,204` unless Plan 1 qualifies them in place (cheap, keeps pins B9/B10 green) before Plan 2 rewrites the README. The alternative is to land the README PR first.

## README tests

**Header pin (what a rewrite must preserve).** `test/release/package_metadata_test.exs` module `Scrypath.Release.BuiltDocsBrandTest`:
- `:290-331` "README.md header uses commit-pinned raw URLs whose bytes match the committed files": reads `README.md`, extracts every `src` and `srcset` attribute value with `~r/\s#{name}="([^"]*)"/` (so any ` src="` or ` srcset="` anywhere in the file counts, including inside fenced code); requires both `@header_dark` and `@header_light` (pin `8beb3ed0f6f0b59f62df28ac60349c6dc9adf1a1`, `:228-233`) present, no `github.io`, and every value must match `~r/^https:\/\/raw\.githubusercontent\.com\/szTheory\/scrypath\/[0-9a-f]{40}\/brand\/assets\/readme\//`; then `git merge-base --is-ancestor` and byte equality at the pin, skipped on a shallow clone that lacks the commit (`:305-330`).
- `:261-266`: built `readme.html` must contain `srcset="<dark url>"` and `src="<light url>"` exactly, so keep the `<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset=...><img src=... alt="scrypath" width="260"></picture></p>` block byte-for-byte (current `README.md:1-7`).
- `:358-362`: README must not contain the retired brand directory name; `:423`: built `readme.html` contains `src="assets/logo.svg"` (ExDoc sidebar logo, unaffected).
- Consequence: no other `<img src=...>` anywhere in the README. Badges must stay markdown images.
`test/mix/tasks/brand_pin_contract_test.exs` does not read the root README at all (only `brand/assets/readme/header-snippet.html` and `brand/assets/README.md`, `:129,159-164,204-223`); CONTEXT's "header pin is covered by both" is half right.

**Every other test that reads `README.md`** (9 files): `docs_contract_test.exs` (33 `@readme` uses), `readiness_contract_test.exs`, `phase98_contract_test.exs`, `phase99_contract_test.exs`, `phase110_contract_test.exs`, `phase112_contract_test.exs`, `backfill_contract_docs_test.exs:45-47`, `telemetry_test.exs:314-324`, `telemetry_contract_test.exs:279`, plus `package_metadata_test.exs`. All accounted for in Tables B and C. `scrypath_ops/test/...` files mention `scrypath_ops/README.md` only in messages. No `website/` script reads the root README (grep).

**Word-count method (recommended, `[ASSUMED]`).** Count whitespace-separated tokens of `README.md` after removing the `<p align="center">...</p>` header block; keep prose, links (a `[text](url)` link is 2 tokens, so absolute URLs do not inflate) and code blocks (code costs reader attention). Baseline today: raw 1,479; prose-only 1,374; without header and fences 1,361 [VERIFIED: measured]. Enforce an upper bound near the top of the chosen range (CONTEXT: 800) plus a floor (for example 400) so an accidental stub fails; record "chosen, not measured" next to the constant. Also cap fenced-code lines (for example 60) so the cap cannot be gamed by moving prose into a code block.

**Link rules (data in the test).** Zero relative links. Allowed hosts: `github.com/szTheory/scrypath`, `hexdocs.pm/scrypath`, `hex.pm/packages/scrypath`, `img.shields.io`, `raw.githubusercontent.com/szTheory/scrypath`, `sztheory.github.io/scrypath` (hosts are inferred from the current README, `[ASSUMED]` as a reasonable allowlist). A repo-path link must be `https://github.com/szTheory/scrypath/blob/main/<path>` and the path must exist in the working tree (offline check). A guide link must be `https://hexdocs.pm/scrypath/<slug>.html` with `<slug>` a lowercased basename of a `docs[:extras]` entry (offline check). "Onward links after the quick path": count markdown links after the last quick-path fence heading; assert `<= 3`.

**Time-promise and forbidden phrases (data, `[ASSUMED]` list).** Start from `brand/BRAND.md:113` "Do not say" (verbatim): "Magic, effortless, "it just stays in sync", real-time (unless you measured it), federated, hydration, playbook, or "AI-powered"." Add the README-02 time promises: `in five minutes`, `in 5 minutes`, `in minutes`, `in a few minutes`, `in seconds`, `quickly`, `instantly`, `in no time`, `under five minutes`, `just works`. Match on word boundaries, case-insensitive; keep the list as one module attribute. The current README violates the brand list itself (`hydration` in "repo-backed hydration" and "Hydration is explicit and repo-backed"; the quoted `"it just stays in sync somehow"` in the non-fit list), so the trim must remove or rephrase them. Note `phase112_contract_test.exs:155-171` already strips a fixed set of allowed negation phrases before its misleading-pattern check; a new list should not silently depend on that.

## Built-docs scan (TRUTH-03)

- **Build cost.** `MIX_ENV=test mix docs --output <tmp>` took 1.18 s real (warm); `MIX_ENV=dev` 3.17 s including a small dep compile [VERIFIED: run, output in the scratchpad]. 107 HTML pages in the test build (79 in dev; test also documents the `Mix.Tasks.Verify.*` modules), 35 extras pages.
- **Where built docs come from in CI today.** One place: `setup_all` of `BuiltDocsBrandTest` (`package_metadata_test.exs:243-259`) runs `Mix.Tasks.Docs.run(["--output", out, "--warnings-as-errors"])` into `System.tmp_dir!()` with `System.pid()`/unique-integer naming and cleanup. That file runs in `core` (untagged, via `mix verify.core ... --exclude docs_contract`) and in `package` (`Verify.Phase11` runs `test/release/package_metadata_test.exs`, `dev/mix/tasks/verify.phase11.ex:30`). Separately `mix verify`, `verify.phase11` and others call `Mix.Task.run("docs", ["--warnings-as-errors"])`, which only proves warnings, not link integrity. The module's own comment says it "adds no gate: it runs in `core`" (`:175-176`).
- **The old case in HTML.** A repo-path `README.md` link becomes `<a href="readme.html">` because ExDoc maps any `README.md` basename to the main page [VERIFIED: built `golden-path.html` shows `<a href="readme.html">` for `../examples/phoenix_meilisearch/README.md`; prep note D row 2 saw the same live]. On `readme.html` itself that is a self-link.
- **Current build, extras pages only** [VERIFIED: prototype scan of both dev and test builds, identical]: 3 hrefs, 0 self-links; unresolved: `contributing.html` -> `.github/workflows/ci.yml` (x2), `compose.yaml`; dead anchors: `local-demo-docker-dx.html` -> `readme.html#mounted-host-app-assets`, `support-and-compatibility.html` -> `readme.html#production`. `mix docs --warnings-as-errors` passes with all of these today, which is the argument for the scan.
- **Wrong-target class (invisible to a build-only scan).** 16 relative links in shipped markdown point at repo paths outside the package and resolve silently to `readme.html` (the Scrypath README) or 404: `CONTRIBUTING.md` x6 (`.github/workflows/ci.yml` x2, `compose.yaml`, `examples/phoenix_meilisearch/README.md` x2, `examples/scrypath_ecommerce/README.md`), `docs/local-demo-docker-dx.md:78`, `guides/golden-path.md` x2 (`:38,136`), `guides/outside-adopter-intake.md:35`, `guides/overview.md:44` x2, `guides/request-edge-search.md:107`, `guides/support-and-compatibility.md` x3 (`:77,146,170`) [VERIFIED: markdown link scan]. Recommended source-level rule in the same test file: in every shipped markdown extra, a relative link target must resolve to another shipped extra; anything else must be an absolute `https://github.com/szTheory/scrypath/blob/main/...` URL. Fixing all 16 is one find-and-replace and also satisfies the unresolved/dead-anchor findings; update pin B13 in the same commit. If the planner scopes this to Phase 193 (GUARD-01 owns the broad link check), Phase 192 must still fix the 3 unresolved and 2 dead anchors (6 of the 16) or the scan cannot be green.
- **Placement and the concurrency footgun.** Recommended: add the TRUTH-03 tests to `BuiltDocsBrandTest` (zero extra builds, shares `out`). CONTEXT decided "sibling of package_metadata_test"; if a sibling is kept, set `async: false` (ExUnit runs sync modules after the async ones) because two async modules each calling `Mix.Tasks.Docs.run/1` in one VM can race on compile and Mix task state; cost is one extra build of about 1-3 s per lane `[ASSUMED]` (race not reproduced here).
- **Skip rule.** The scan always has the build available where it runs (it builds in `setup_all`), so "skipped, with a stated reason" only applies if docs cannot build; do not add an environment gate that could silently skip in `core`/`package`.
- **HTML parser:** regex is adequate (see Alternatives). Parsing `href` only on `<a ` tags avoids `<link href=...>` assets that `BuiltDocsBrandTest` already covers.
- **Not provable offline:** live hex.pm/HexDocs rendering of the README, external link liveness, version-skew of unversioned `hexdocs.pm/scrypath/...` links (Phase 193 checkpoint records these).

## Quick path (README-02)

- **Schema snippet:** the README fence (`README.md:46-60`) is byte-identical to the golden-path fence (`guides/golden-path.md:59-75`) [VERIFIED: extracted and compared, `identical: True`]. Keep identical; the README test can assert equality now (cheap precursor of the Phase 193 guard).
- **Real API and signatures** [VERIFIED: lib/scrypath.ex]: `@spec search(module(), String.t(), keyword()) :: {:ok, term()} | {:error, term()}` (`:258-259`); `@spec sync_record(module(), struct() | map(), keyword()) :: {:ok, term()} | {:error, term()}` (`:187-188`). Result struct `defstruct [:query, :hits, :records, :raw, :missing_ids, :page, :facets]` (`lib/scrypath/search_result.ex:9`).
- **Required runtime options** [VERIFIED: lib/scrypath/options.ex]: `backend:` is `required: true`; `meilisearch_url:` defaults to `nil` and `Config.fetch_meilisearch_url!/1` does `Keyword.fetch!(config, :meilisearch_url)` (`config.ex:61-64`), so the URL must come from configuration. `sync_mode` defaults to `:inline`; `repo:` is optional but needed for hydrated `result.records`.
- **Config that actually resolves** [VERIFIED: lib/scrypath/config.ex:11-35; used by `search/single.ex:14`, `sync.ex:24`]: `Application.get_env(:scrypath, :defaults, [])` merged under per-repo `config :my_app, MyApp.Repo, scrypath: [...]`, merged under call options. So the quick path should show `config :scrypath, :defaults, backend: Scrypath.Meilisearch, meilisearch_url: "http://127.0.0.1:7700", repo: MyApp.Repo` (also documented at `guides/per-query-tuning-pipeline.md:33`, `guides/related-data-and-reindexing.md:266`).
- **Doc defect to decide on:** `guides/golden-path.md:49-50` shows `config :my_app, :scrypath, meilisearch_url: ...`. Nothing in `lib/` reads `Application.get_env(:my_app, :scrypath)`; only `config.ex:14` and `:26` read app env. As written the golden path's context snippet (which passes `backend:` and `repo:` per call but never `meilisearch_url:`) cannot search. Fixing it is a one-snippet edit in a file Plan 1 already touches (`guides/golden-path.md:137`); the `docs_contract_test.exs:489-500` golden-path pins (`SCRYPATH_MEILISEARCH_URL`, `docker compose up -d`, etc.) stay satisfiable. Recorded as Open Q3.
- **Prerequisite text:** Meilisearch image used by the repo is `getmeili/meilisearch:v1.15`, default URL `http://127.0.0.1:7700` (`compose.yaml:17`, `guides/golden-path.md:29`). `brand/BRAND.md:95` supplies the approved eventual-consistency wording: "Meilisearch is eventually consistent, so a record can take a moment to show up in search after you save it. Scrypath never says a record is searchable before Meilisearch has indexed it."
- **Minimum shape** (sketch, `[ASSUMED]` wording): prerequisite + eventual-consistency sentences; install fence (existing); config fence; `Scrypath.sync_record(MyApp.Blog.Post, post, sync_mode: :inline)` after a successful repo write; `{:ok, result} = Scrypath.search(MyApp.Blog.Post, "ecto")` then `result.records`. Avoid `filter:`/`sort:` in the first call: filterable/sortable attributes need Meilisearch settings applied first (`filterable: [:status]` is declared on the schema), which the quick path should not teach.
- **Strict reading of README-02:** "before the first code block" can mean the README's first fence (the Installation `deps` block precedes the quick path today) or the quick path's first fence. Putting one prerequisite sentence in the opening paragraph satisfies both (Open Q4).
- **Proof limit:** there is no automated live run of the README snippet; the example smoke script (`examples/phoenix_meilisearch/scripts/smoke.sh`) proves the example path only. State this in the phase record's "what this does not prove".

## CI lanes (item 6)

**Required checks** (`CONTRIBUTING.md:247`): `core`, `package`, `repository-contracts`, `backend`, `ecommerce-mounted`, `ops-ui (path-scoped)`. Advisory: `compatibility`, `deep-quality`, `phoenix-example`, scheduled `ecommerce-e2e`, `coverage`.

| Changed path | core | package | repository-contracts | backend | ecommerce-mounted | ops-ui | compatibility (adv) | Website workflow (not required) |
|--------------|------|---------|----------------------|---------|-------------------|--------|---------------------|-----------------|
| `README.md` only | runs | runs | Mix half runs; Node steps skipped | runs | skipped | skipped | skipped | runs (`website.yml` paths include `README.md`) |
| `.planning/` only | runs | runs | Mix half; Node skipped | runs | skipped | skipped | skipped | no |
| `docs/` only | runs | runs | Mix half; Node skipped | runs | skipped | skipped | skipped | runs |
| `guides/` | runs | runs | full | runs | runs (guides not in allowlist) | skipped | skipped | runs |
| `test/scrypath/` | runs | runs | full | runs | runs | skipped | runs | no |
| `test/release/` | runs | runs | full | runs | runs | **runs** | runs | no |
| `mix.exs` | runs | runs | full | runs | runs | **runs** | runs | runs |
Sources [VERIFIED]: ecommerce skip allowlist `scripts/ci/ecommerce_path_classifier.cjs:23` `const SKIPPABLE_PATTERN = new RegExp(String.raw\`^(\.planning/|docs/|[^/]+\.md$)\`);`; ops-ui regex `ci.yml:440` `'^(scrypath_ops/|lib/|dev/|config/|priv/|brand/|language/|fixtures/|scripts/ci/|test/release/|mix\.exs|mix\.lock|\.github/workflows/ci\.yml|GLOSSARY\.md|DESIGN\.md|examples/scrypath_ecommerce/(e2e|lib|test|scripts|assets)/)'`; compat `scripts/ci/compat_path_classifier.cjs:33-35` `^(lib/|dev/|test/|config/|priv/|scripts/|mix\.exs$|mix\.lock$|\.github/workflows/ci\.yml$)`. Wall time per PR: about 7 min README-only, about 19 min when `guides/`, `test/` or `mix.exs` is touched (ROADMAP guardrails, `.planning/ROADMAP.md:37`). Every Phase 192 plan touches `test/`, so each PR pays about 19 min; two PRs instead of three is the main lever (Plan 1 and Plan 3 both edit `guides/` and CONTRIBUTING; Plan 2 must carry its pin edits with the README).

**Which lane runs which doc test** [VERIFIED: `dev/mix/tasks/verify/capability.ex`, `verify.ex`, `verify.phase11.ex:30-33`, `verify.phase99.ex:7-18`, `ci.yml:98`]:
- `core` = `mix verify.core --exclude integration --exclude docs_contract` = `mix verify` (format check, workspace_clean, compile warnings-as-errors, `credo --strict`, `mix test --warnings-as-errors ...`, `mix docs --warnings-as-errors`) then `verify.no_optional_deps`. Runs every untagged test: `readiness_contract_test`, `phase98`, `phase110`, `phase112`, `backfill_contract_docs_test`, `package_metadata_test` (incl. the docs build), `phase99` (tag `:phase99_contract` is not excluded), and any new untagged file. Does NOT run `docs_contract_test.exs` (`@moduletag :docs_contract`, line 3).
- `package` = `mix verify.package` = `Verify.Phase11.run_without_docs`: `package_metadata_test`, `package_contents_test`, `consumer_smoke_test`, `docs_contract_test` + release workflow greps + `hex.build --unpack`. Shallow checkout (CI-EFFICIENCY item 7).
- `repository-contracts` = `Verify.Phase99.run_without_docs`: `phase99_contract_test`, `phase111`, `no_human_gates`, `verify.phase99_test`, `ui_contrast`, `website_contract`, `ui_literal`, `dependency_boundary_contract_test`, `workflow_wiring_test`, `ci_monitor_test` (+ Node steps when not skipped). So `dependency_boundary_contract_test.exs:238` (pin B13) and `phase99` README pins fail here, not in `package`.
- `docs_contract_test.exs` fails only in `package` (hosted) and when run by hand. That is why a README or guide edit can pass `core` and `scripts/ci/pre_push.sh` and still go red hosted.

**Local mirrors** (commands from `.planning/reference/CI-EFFICIENCY.md` "Why hosted CI should pass" table, `scripts/ci/pre_push.sh`, and `CONTRIBUTING.md`; run on the committed head, several gates clone `HEAD`):
1. Cheap first: `export ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5` then `scripts/ci/pre_push.sh` (about 1 min warm; format, compile, credo, workspace_clean, wiring tests, Node classifier tests; exits 2 on any SKIPPED).
2. **The doc-pin set, by hand (2.6 s for 8 files, 135 tests, 0 failures measured today):** `mix test test/scrypath/docs_contract_test.exs test/scrypath/readiness_contract_test.exs test/scrypath/phase98_contract_test.exs test/scrypath/phase99_contract_test.exs test/scrypath/phase110_contract_test.exs test/scrypath/phase112_contract_test.exs test/scrypath/backfill_contract_docs_test.exs test/release/package_metadata_test.exs`, plus `test/scrypath/telemetry_test.exs test/scrypath/telemetry_contract_test.exs test/mix/tasks/dependency_boundary_contract_test.exs` and the two new files.
3. `mix docs --warnings-as-errors` (about 1-3 s).
4. `core`: `mix verify.core --exclude integration --exclude docs_contract` (about 6 min; needs a committed tree).
5. `package`: `mix verify.package` (hosted 110 s; not measured locally; local clone has history so a shallow-only failure is invisible).
6. `repository-contracts`: `mix verify.repository_contracts` (about 6 min) and, when its Node half is not skipped, the five `scripts/ci/*.test.cjs` files after `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm ci --ignore-scripts --prefix examples/scrypath_ecommerce` (587 s measured earlier; `examples/scrypath_ecommerce/node_modules` is present now).
7. `backend`: `docker compose up -d --wait postgres meilisearch` then `SCRYPATH_INTEGRATION=1 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 SCRYPATH_POSTGRES_URL=postgres://postgres:postgres@127.0.0.1:5434 mix verify.backend`, then `docker compose down -v` (task-scoped project name `-p`, AGENTS.md cleanup rule). A docs/test-only change cannot affect it; run it or record why not.
8. `ecommerce-mounted`: `mix verify.ecommerce_mounted` (Docker, hosted 270 s bake + 522 s proof). A change that touches only README/docs/guides/test files cannot affect it; record "not run: no input in this lane changed" and the classifier check `GITHUB_EVENT_NAME=pull_request GITHUB_BASE_REF=main node scripts/ci/ecommerce_path_classifier.cjs --head <ref>` for README-only plans.
9. `ops-ui (path-scoped)`: `mix verify.ops_ui` (hosted 386-419 s, Postgres on `PGPORT`) only if the diff touches `test/release/` or `mix.exs`.
10. Website (not required): `cd website && npm ci && npm run build && npm run check` if README/guides/docs change (about 64 s hosted); it also redeploys the site on merge to `main`.
Each plan's verify step should list rows 1-3 always, 4-6 before the push, and say which of 7-10 it did not run and why.

**Gate budget.** `CONTRIBUTING.md:266` reads "Budget used: 10 of 12."; `workflow_wiring_test.exs:1326` fails if the ledger table lists more than 12 rows or a row lacks a trigger or churn cell. The ledger counts named required gates, not tests: new tests inside `core`/`package` add no row (`BuiltDocsBrandTest` states "It adds no gate", `:175`). Recommendation `[ASSUMED]`: add no row; record "no gate added" in the phase notes. If the planner wants a row for the invariant, it needs a deletion trigger and brings the count to 11 of 12.

## Common Pitfalls

### Pitfall 1: Invariant red on its own PR (ordering)
**What goes wrong:** the scan covers `README.md`, which still has 3 unqualified mentions when Plan 1 lands. **Avoid:** qualify them in place in Plan 1 (pins B9/B10 stay green), or land the README PR first. **Warning sign:** the new test fails on `README.md:36,118,204` first.

### Pitfall 2: A "scan every package.files file" rule that cannot pass
`CHANGELOG.md` (23 mentions, one pinned by `workflow_wiring_test.exs:1461-1462`) and `mix.exs` (51 lines) are in `package.files`. The locked allowlist names only CONTRIBUTING and `docs/releasing.md`. Add the two exemptions as named constants with a reason string, assert every exempt/allowlisted path is in `package.files` (stale entries fail), and assert the exempt set size so it cannot grow silently (Assumption A2).

### Pitfall 3: Bare-word false positives
`verify` is both a task and an English word (`docs/search-backend-sre.md:55` "Settings verify skipped"). Require `mix ` for the bare name; dotted names are specific enough. Keep planted cases for it (prose "verify" passes).

### Pitfall 4: Qualifier unit
The locked rule says "same sentence or list item". Existing qualifiers sit in a lead-in paragraph above bullets (`support-and-compatibility.md:123`, `outside-adopter-intake.md:28`) and tables/fences cannot hold a sentence. The recommended unit (list item, table row, paragraph; fence judged with its lead-in) requires the 18 edits above; a strict per-sentence unit would add more. Pick one, document it in the test, and cover fence, table-row and list-item planted cases.

### Pitfall 5: `docs_contract_test` blind spot
Tagged `:docs_contract`; excluded from `core` and from `pre_push.sh`; runs hosted only in `package`. Run it by hand every time (command above).

### Pitfall 6: Absolute HexDocs URLs delete route substrings
`readiness_contract_test.exs:12,19`, `phase99_contract_test.exs:21,185,201,205`, `phase110_contract_test.exs:32`, `docs_contract_test.exs:134,163,197,246,317,458,838` all look for `guides/<name>.md`. Decide the replacement shape once (a helper that accepts the HexDocs form) rather than editing each literal differently.

### Pitfall 7: Support-guide multi-line pins
`dependency_boundary_contract_test.exs:223-236` pins strings with embedded newlines (`"does not change the root\nlibrary's Elixir 1.17 floor ..."`, `"Dependency\nand support changes become Hex-package claims only after a release"`) and `phase99_contract_test.exs:194,216-224` parses `extract_support_ci_tuples` after the line "GitHub Actions CI evidence currently exercises these explicit tuples:". Do not reflow or re-wrap `guides/support-and-compatibility.md`; edit only lines 77, 125, 131-132, 146, 170.

### Pitfall 8: Concurrent docs builds
Two `async: true` modules each running `Mix.Tasks.Docs.run/1` in one VM. Put the scan in `BuiltDocsBrandTest` or make the sibling `async: false`.

### Pitfall 9: Local-only files in the expansion
`lib/.DS_Store` (git-ignored) is local noise; filter by extension. The repo root also holds untracked artifacts (`erl_crash.dump`, `scrypath-0.3.*` directories, `tmp_phx`) that are not in `package.files` and must not be read.

### Pitfall 10: README tokens that look like tuple literals
README and CONTRIBUTING/intake must not contain `1.17.3`, `26.2.5`, `1.19.0`, `28.1` as substrings (`phase99_contract_test.exs:200-212`, `phase110_contract_test.exs:19`). A new "requires Elixir ..." line or a version in a URL can trip it; use `1.17+` style text if a version is needed. `[ASSUMED]` that a version line is wanted at all.

### Pitfall 11: Header pin collateral
Any ` src="` or ` srcset="` substring in the README outside the pinned header fails `package_metadata_test.exs:297-303`, even inside a code fence.

### Pitfall 12: Credo strict and format on new tests
`.credo.exs:6` includes `test/` and `.formatter.exs` includes `{config,lib,dev,test}/**/*`. Cheap checks: `mix format --check-formatted <files>` and `MIX_ENV=test mix credo --strict <files>`. Keep helper functions small (nesting/complexity checks).

### Pitfall 13: ExDoc basename collision recurs
Any new relative link to an example or ops README from a guide silently becomes `readme.html`. The source-level rule in the scan is the only mechanical guard.

## Code Examples

### README word count (method sketch, `[ASSUMED]`)
```elixir
words =
  "README.md"
  |> File.read!()
  |> String.replace(~r/<p align="center">.*?<\/p>/s, "")
  |> String.split(~r/\s+/, trim: true)
  |> length()
# measured on the current file with the header block kept: 1479 (wc -w); cap constant is a chosen number, not a measured optimum
```

### Planted cases for the invariant (in-memory, per locked decision)
```elixir
# Source: sketch; strings only, no shipped file edited
@bad  "Run `mix verify.adopter` before you ship."
@good "From a source checkout (this task is not part of the Hex package), run `mix verify.adopter`."
@prose "Settings verify skipped is a temporary flag."

assert [{"guides/x.md", 1, "verify.adopter"}] = scan([{"guides/x.md", @bad}], repo_only, qualifier)
assert [] = scan([{"guides/x.md", @good}], repo_only, qualifier)
assert [] = scan([{"guides/x.md", @prose}], repo_only, qualifier)
assert [] = scan([{"CONTRIBUTING.md", @bad}], repo_only, qualifier)   # allowlisted
```

### Built-docs planted cases
```elixir
html = File.read!(Path.join(out, "readme.html"))
assert [{"readme.html", "readme.html", :self_link}] = link_problems(out, "readme.html", html <> ~s(<a href="readme.html">x</a>))
assert [{_, "no-such-page.html", :unresolved}] = link_problems(out, "readme.html", ~s(<a href="no-such-page.html">x</a>))
assert [{_, "golden-path.html#nope", :dead_anchor}] = link_problems(out, "readme.html", ~s(<a href="golden-path.html#nope">x</a>))
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Verifier tasks shipped in `lib/mix/tasks` | Verifiers in `dev/mix/tasks`, compiled only under `MIX_ENV=test` | Phase 183; shipped docs say 0.3.18 | Docs that tell adopters to run them are false; `PROJECT.md:76` still says 0.3.17 |
| README repo-path links relative (`HexDocs` self-links) | Absolute GitHub URLs for the three example/ops links | PR #158 | 0 extras self-links today; 16 wrong-target links remain in guides/CONTRIBUTING |
| README header relative asset paths | Commit-pinned `raw.githubusercontent.com` URLs | 0.3.19 | Header pin test governs the first 7 lines |

**Deprecated/outdated:** the "published 0.3.17 still contains them" sentence; the CONTEXT claim that only README line 31 is the README's task mention.

## Runtime State Inventory

Not applicable: no rename, refactor or migration. Docs and test files only. Stored data, live service config, OS-registered state, secrets and build artifacts: none touched (verified by scope: edits are to tracked markdown, tests and planning notes). The website redeploys from `main` on merge because `website.yml` watches `README.md`, `guides/**`, `docs/**` and `mix.exs`; it publishes the same site content.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP via asdf env vars | all `mix` commands | yes | 1.19.0 / OTP 28 | none needed |
| `mix docs` (ExDoc 0.40.4 in `_build/dev`, `_build/test`) | TRUTH-03 | yes | 0.40.4 | none needed |
| Node | `scripts/ci/pre_push.sh` Node tests | yes | v26.10.0 locally (CI uses 22 for website) | pre_push reports SKIPPED if missing |
| `actionlint`, `act`, `docker`, `gh` | pre-push lint, optional `act`, `backend`/`ecommerce-mounted` mirrors, merge | yes (`/opt/homebrew/bin/actionlint`, `/opt/homebrew/bin/act`, `/usr/local/bin/docker`, `/opt/homebrew/bin/gh`) | not probed for versions | row skipped with a recorded reason |
| `examples/scrypath_ecommerce/node_modules/pngjs` | pre_push UI token/state-pair node tests | yes | - | `npm ci --ignore-scripts --prefix examples/scrypath_ecommerce` |
| Network to hex.pm / hexdocs.pm | live README link behavior | not needed in CI (locked) | - | Phase 193 checkpoint |
**Missing dependencies with no fallback:** none. **With fallback:** none.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.0), `async: true` contract files |
| Config file | `test/test_helper.exs` (excludes `:integration`, `:requires_clean_workspace`, `:postgres` by default) |
| Quick run command | `mix test test/release/shipped_docs_contract_test.exs test/scrypath/readme_contract_test.exs` |
| Full suite command | `mix verify.core --exclude integration --exclude docs_contract` plus `mix verify.package` and `mix verify.repository_contracts` |

### Phase Requirements to Test Map
| Req / success criterion | Behavior | Test type | Automated command (cheapest) | File exists? |
|-------------------------|----------|-----------|------------------------------|--------------|
| SC1 / TRUTH-01 | Planted unqualified `mix verify.adopter` guide line fails; qualified passes; list derived from `dev/` (and optionally `scrypath_ops/`, `examples/`) minus `lib/`; real shipped files clean | unit, in-memory strings + real file scan | `mix test test/release/shipped_docs_contract_test.exs` (about 1-2 s) | Wave 0 |
| SC2 / TRUTH-01, TRUTH-02 | Every old pin accounted for; contract text changed in the same commit; contract block passes the same qualifier | inventory doc + agreement test + pin set | the 11-file doc-pin set (command in "CI lanes" item 2); inventory at `192-PIN-INVENTORY.md` | Wave 0 |
| SC3 / TRUTH-03 | No self-link, unresolved extras link or dead anchor in built docs; planted cases fail; header pin green | built-docs scan | `mix test test/release/package_metadata_test.exs` (docs build included, about 1-3 s) | extend existing |
| SC4 / README-01, README-02 | Word cap, at most 3 onward links, no "Choose a route", prerequisite before first fence, quick path ends in `Scrypath.search` result, schema snippet equals golden path, time-promise phrases fail, absolute URL rules | unit, plain file reads | `mix test test/scrypath/readme_contract_test.exs` (under 1 s) | Wave 0 |
| SC5 / README-03 | Owner map exists with one owner per required claim | tiny table-shape test (optional) | same README test file | Wave 0 |
| GATE-03 | squash title, no new gate row, local mirrors run | process + `workflow_wiring_test` | `mix test test/mix/tasks/workflow_wiring_test.exs` (also in `pre_push.sh`) | exists |

### What each check does NOT prove
- SC1: that no doc outside the detected forms instructs a repo task (for example a task spelled in prose, or in a file outside `package.files`); that a qualifier sentence is itself accurate; any rendered output.
- SC2: that the inventory is complete beyond what grep and the scan found (it is reproducible: the scan and the `grep` commands are in this note); that `PROJECT.md` prose reads well.
- SC3: live hex.pm and hexdocs.pm behavior, external link liveness, the wrong-target class unless the source-level rule is added, version skew of unversioned HexDocs links.
- SC4: that the README reads better, time to first search, that the quick path runs against a live Meilisearch (no live run exists), brand fit.
- SC5: that the owner assignments are the right ones.

### Sampling Rate
- **Per task commit:** the two new test files plus `mix format --check-formatted` on touched files.
- **Per wave / before each push:** `scripts/ci/pre_push.sh`, the doc-pin set (about 3 s), `mix docs --warnings-as-errors`; then `mix verify.core ...`, `mix verify.package`, `mix verify.repository_contracts` on the committed head.
- **Phase gate:** all required hosted lanes green on the exact head SHA before squash-merge; no human UAT.

### Wave 0 Gaps
- [ ] `test/release/shipped_docs_contract_test.exs` — covers TRUTH-01/02 (invariant, planted cases, contract agreement)
- [ ] `test/scrypath/readme_contract_test.exs` — covers README-01/02/03
- [ ] TRUTH-03 tests added to `test/release/package_metadata_test.exs` (`BuiltDocsBrandTest`)
- [ ] `.planning/phases/192-docs-truth-and-readme/192-PIN-INVENTORY.md` — tables A-D plus mention inventory, finalized
- [ ] `.planning/reference/CLAIM-OWNER-MAP.md` — written before the README trim
- Framework install: none.

## Security Domain

`security_enforcement` is absent in `.planning/config.json` (treated as enabled). The phase edits static documentation and tests; no input handling, auth, sessions, crypto or network access is added.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication / V3 Session / V4 Access Control | no | - |
| V5 Input Validation | marginal | Scanner reads repo files only; bound file reads to `package.files` expansion; no shelling out |
| V6 Cryptography | no | The README header pin is an integrity pin on image bytes (existing test), not crypto |
| V14 Configuration / supply chain | yes | No new dependency; README test pins an allowlist of absolute-URL hosts so an edit cannot introduce an arbitrary external link |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Shipped docs instruct adopters to run a task that does not exist (or a different task of the same name) | Tampering / Spoofing of guidance | The invariant plus `consumer_smoke_test.exs:206-215` proving the task is absent in a consumer |
| Link to an attacker-controlled host from the README or guides | Spoofing | Host allowlist in the README test; repo links pinned to `github.com/szTheory/scrypath` |
| Image URL swapped after review | Tampering | Existing commit-pinned header URLs and byte equality at the pin (`package_metadata_test.exs:290-331`) |
| Scan reads untracked local files (`lib/.DS_Store`, crash dumps) and behaves differently locally vs CI | Repudiation (flaky evidence) | Extension filter; assert the file count is stable relative to tracked files `[ASSUMED]` |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Extend the derivation sources beyond `dev/mix/tasks` to `scrypath_ops/lib/mix/tasks` and `examples/*/lib/mix/tasks` so `guides/operator-mix-tasks.md:98-104` is covered | Pattern 1, Mention inventory | The locked decision names only `dev/` minus `lib/`; if declined, the guide keeps instructing a task adopters cannot run, but the criterion "no Hex-shipped doc instructs an adopter to run a repo-only task" is then literally unmet for that line |
| A2 | `CHANGELOG.md` and `mix.exs` are named structural exemptions in addition to the locked allowlist | Pitfall 2 | If declined, the invariant cannot pass: 23 CHANGELOG mentions (two required by `workflow_wiring_test.exs:1461-1462`) and 51 `mix.exs` lines |
| A3 | Qualifier unit = list item / table row / paragraph, fence judged with its lead-in (not strictly "sentence") | Pattern 3, Pitfall 4 | A stricter unit means more doc edits; a looser one (section scope) means fewer edits but a weaker invariant |
| A4 | Satisfy README-02 for both readings by putting one prerequisite sentence before the README's first code block | Quick path | If the maintainer meant only the quick path's first block, the extra sentence is harmless |
| A5 | Word counting method and the floor/line caps; time-promise phrase list; allowed URL hosts | README tests | Constants in a test; reversible |
| A6 | Add a PROJECT.md contract-vs-check agreement test | Table D | A small extra test; skip if the maintainer prefers prose only |
| A7 | Add no gate-ledger row | CI lanes | If a row is wanted it needs a deletion trigger and uses 11 of 12 |
| A8 | Two docs builds racing in one VM is a real hazard | Built-docs scan | If not real, a sibling file is fine at no extra risk; cost is one build either way |
| A9 | Version-literal advice (avoid `1.17.3`, `26.2.5`, `1.19.0`, `28.1` in README text) | Pitfall 10 | Only matters if the README mentions versions |
| A10 | Golden-path config snippet is non-functional (`config :my_app, :scrypath`) | Quick path | Verified by reading `lib/scrypath/config.ex`; not executed against a live Meilisearch |

## Open Questions

1. **Extend the derivation to `scrypath_ops/` and `examples/` tasks (A1)?**
   - Known: `guides/operator-mix-tasks.md:98-104` (shipped, pinned by `docs_contract_test.exs:633`) says to run `mix scrypath_ops.saved_searches.validate` "from `scrypath_ops/`"; the task lives in `scrypath_ops/lib/mix/tasks/scrypath_ops/saved_searches/validate.ex`. No shipped doc mentions the three example tasks.
   - Unclear: whether the maintainer counts it as in scope of "repo-only task".
   - Recommendation: include it (still derived, not hand-kept); one qualifier sentence fixes it and the pin keeps passing.
2. **Where do the 16 wrong-target `README.md` links get fixed?**
   - Known: only 6 are needed for TRUTH-03 to be green (3 unresolved + 2 dead anchors from 3 files, plus pin B13); all 16 are one find-and-replace to absolute GitHub URLs.
   - Recommendation: fix all 16 with the source-level rule in Plan 3 (or in the same PR as Plan 1's guide edits to avoid editing a file twice).
3. **Fix `guides/golden-path.md:49-50` (config snippet) now or hand to Phase 193?**
   - Recommendation: fix now in the same edit as `:137` (docs truth is this phase's job; the README quick path needs the corrected form anyway).
4. **README-02 "first code block": README-wide or quick-path-only?** Recommendation: satisfy both (A4).
5. **"Versioning and upgrades" is neither in CONTEXT's keep list nor its removal list.** It currently carries `mix verify.phase11`, `docs/releasing.md` and a semver statement (`README.md:112-118`); pinned at `docs_contract_test.exs:504-517`. The owner map must assign the semver claim (candidates: one README line + CHANGELOG, or `docs/releasing.md`).
6. **Do the 10 README-only claims move into guides or retire with a recorded pointer (Table C2)?** Recommendation: move at most the drift and backfill sentences (3 short additions to `guides/drift-recovery.md`), retire the rest with pointers to the pinned ARCHITECTURE and sync-guide equivalents.
7. **Batching:** Plan 1 and Plan 3 both edit `guides/` and CONTRIBUTING and both pay about 19 min of CI; Plan 2 must carry its pin edits. Two PRs (1+3, 2) or three; trade-off is review size against one fewer 19-minute cycle.

## Sources

### Primary (HIGH confidence, opened or run this session)
- Repo files: `.planning/phases/192-docs-truth-and-readme/192-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md` (Phase 192, guardrails), `.planning/PROJECT.md:60-90`, `.planning/research/v1.48-prep/A` and `D`, `.planning/reference/CI-EFFICIENCY.md` (local mirrors), `AGENTS.md`
- `mix.exs` (package files, docs extras, preferred_envs), `test/release/package_metadata_test.exs`, `test/release/package_contents_test.exs`, `test/release/consumer_smoke_test.exs:196-218`, `test/support/release/package_contract.ex`, `test/support/repo_tooling.ex`
- Doc-pin tests: `test/scrypath/{docs_contract,readiness_contract,phase98_contract,phase99_contract,phase108_contract,phase110_contract,phase111_contract,phase112_contract,backfill_contract_docs}_test.exs`, `test/scrypath/telemetry_test.exs:305-330`, `telemetry_contract_test.exs:268-283`, `test/mix/tasks/{verify_adopter,dependency_boundary_contract,workflow_wiring}_test.exs`
- Task tree and lanes: `dev/mix/tasks/**`, `dev/mix/tasks/verify/{capability,core,package}.ex`, `verify.ex`, `verify.phase11.ex`, `verify.phase99.ex`, `verify.adopter.ex`
- CI: `.github/workflows/{ci,website}.yml`, `scripts/ci/{ecommerce_path_classifier,compat_path_classifier}.cjs`, `scripts/ci/pre_push.sh`, `CONTRIBUTING.md:225-266`
- Shipped docs: `README.md`, `guides/{golden-path,support-and-compatibility,outside-adopter-intake,operator-mix-tasks,getting-started}.md`, `docs/{operator-support,search-backend-sre,jtbd-gap-map}.md`, `CHANGELOG.md:1-50`, `brand/BRAND.md:80-120`
- Library API: `lib/scrypath.ex`, `lib/scrypath/{config,options,search_result}.ex`, `lib/scrypath/search/single.ex`
- Runs: `mix docs` in `MIX_ENV=dev` and `MIX_ENV=test` into the scratchpad; derivation and mention scans (Elixir and Python) in the scratchpad; 8-file doc-pin test run (135 tests, 0 failures, 2.6 s); hex.pm API (`/api/packages/scrypath`) release dates

### Secondary / Tertiary
- Prep notes A and D claims about live HexDocs/hex.pm were not re-fetched (marked `[CITED]` where used: D row 2 self-links; this session reproduced the mechanism locally instead).
- ExDoc README-basename mapping rule: observed in built output only; ExDoc source/docs were not consulted (`[ASSUMED]` that it is intended behavior rather than a version quirk).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new packages; helpers and versions read from the repo.
- Architecture: HIGH for derivation, pin inventory and lanes (all read and run); MEDIUM for the Elixir scanner (prototype in Python, not yet ported).
- Pitfalls: HIGH where tied to a quoted file:line; MEDIUM for the concurrency hazard (A8, not reproduced).

**Research date:** 2026-11-20
**Valid until:** 2026-12-04 (pins and README text move quickly; re-run the scan commands before planning if `README.md`, `guides/` or `test/scrypath/` changed on `main`)
