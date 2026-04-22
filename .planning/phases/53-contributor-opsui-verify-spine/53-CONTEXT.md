# Phase 53: Contributor OPSUI verify spine - Context

**Gathered:** 2026-04-21  
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship **VRFY-03** and **VRFY-04** for **v1.12**: one documented **`mix …`** entry from **repository root** that runs the **OPSUI** (`scrypath_ops`) verification story the way contributors and **CI** expect; **README** and **CONTRIBUTING** surface that command **next to** other verify entry points (not buried); **`mix help`** and verify-matrix prose stay **aligned** with implementation and **`.github/workflows/ci.yml`**. No new product capabilities—docs, Mix task metadata, and **bounded** doc-contract tests only.

</domain>

<decisions>
## Implementation Decisions

### 1. README surfacing (**VRFY-04** vs Phase **51** doc roles)

- **D-01:** Add **one explicit sentence** (or tighten the existing operator / maintainer blurb) in **`README.md`** that includes the literal string **`mix verify.opsui`**, states it exercises the optional Phoenix operator app under **`scrypath_ops/`**, and **links** to the verify / CI section in **`CONTRIBUTING.md`** for the full matrix and job names.
- **D-02:** **Do not** paste the verify matrix into **README** (no duplicate table, no second manual). If the blurb is already crowded, allow a **tiny** trailing block (e.g. two bullets: default library verify + **`mix verify.opsui`**) still **without** copying **CONTRIBUTING** tables.
- **D-03:** **Do not** satisfy discoverability with link-only README text where the command never appears as visible monospace—**VRFY-04** requires the command to show in default contributor-facing docs readers actually scan.

### 2. Mix task metadata (`Mix.Tasks.Verify.Opsui`)

- **D-04:** **Remove `@moduledoc false`.** Today the task is **omitted from the public `mix help` task list** and **`mix help verify.opsui`** prints *no documentation*—unlike other root **`verify.*`** tasks. That violates contributor expectations and **VRFY-04** (“**`mix help`** … stays accurate”).
- **D-05:** Add a **short `@moduledoc`** (on the order of **10–25** lines, not a second **CONTRIBUTING**): purpose, **when** to run (touch **`scrypath_ops/`**, **`lib/`**, root **`mix.exs`**, locks, etc.—align wording with **CONTRIBUTING**), **what** it runs at a high level (`scrypath_ops`, **`mix deps.get`**, **`mix test`**, non-interactive **`CI=true`** behavior), **prerequisites in summary** (e.g. Postgres-backed tests, no Meilisearch service—match **CI**), **no arguments**, and **one link** to **`CONTRIBUTING.md`** for services, env, and job names.
- **D-06:** Keep the existing strong **`@shortdoc`**; it remains the line shown in **`mix help`** summaries once the task is visible again.

### 3. Doc-contract tests (**Phase 51** **D-01**, **D-04**)

- **D-07:** **Extend** **`test/scrypath/docs_contract_test.exs`** (or a small split module only if the file is already hard to navigate) with **1–2** focused tests—**not** manual review only for mechanical invariants.
- **D-08:** **CONTRIBUTING ↔ `ci.yml` parity** for the **`scrypath-ops`** job: same structural pattern as the Phase **51** **`phoenix-example-integration`** test—bounded tail after the job / table key, **`ordered?`** (or equivalent) for **`cd scrypath_ops`** → **`mix deps.get`** → **`mix test`** (or the documented equivalent), without embedding the full **`export CI=true; printf …`** script as a duplicated contract string.
- **D-09:** **Presence** checks that **`mix verify.opsui`** appears in **`CONTRIBUTING.md`** and in **`README.md`** after **D-01** lands (one canonical substring per invariant; avoid a “substring museum” of full paragraphs).
- **D-10:** **Optional** thin assertion against **`lib/mix/tasks/verify.opsui.ex`** for stable implementation markers (**`cd:`** **`ops_dir`**, **`mix test`**, no-args guard)—catches accidental gutting of the orchestrator without brittle **`Mix.shell().info`** prose.
- **D-11:** **Do not** add a parallel **shell-only** CI doc gate for the same prose; keep assertions in **ExUnit** per Phase **51**.

### 4. Prerequisites and “documented `cd`” (**VRFY-03**)

- **D-12:** **Canonical depth** for Postgres / no Meilisearch / env expectations: **`CONTRIBUTING.md`** (verify narrative + CI table). **`scrypath_ops/README.md`** may hold **app-specific** DB or config detail **only if** **`CONTRIBUTING`** links there explicitly—pick **one** place for version-level DB prose to avoid drift.
- **D-13:** **README** carries at most the **one-line router** from **D-01**, not a second copy of prerequisite tables.
- **D-14:** **`@moduledoc`** gives **`mix help verify.opsui`** a **summary + link**, not a fork of the full prerequisite story. The task already hides **`cd`** inside **`System.cmd`**—that is acceptable for **VRFY-03** as long as **CONTRIBUTING** (or linked ops README) still explains what runs and what services are required.

### Research synthesis (subagent consensus)

- **Ecosystem pattern:** Successful **Elixir / Hex** libraries often put **one or two high-signal, pre-push Mix entrypoints** in the **README** while keeping matrices in **CONTRIBUTING** (Oban, Phoenix, Ecto-style split: consumers first, clone contributors second, policy in **CONTRIBUTING**).
- **`@moduledoc false` footgun:** Per **`Mix.Task`** behavior, it **suppresses the task from the default `mix help` list**—confirmed in-repo for **`verify.opsui`** vs other **`verify.*`** tasks.
- **Doc tests:** Assert **relationships** (order of steps, stable identifiers), not marketing copy—matches **Phase 51** anti–substring-museum guidance.

### Claude's Discretion

- Exact README sentence and anchor slug for the **CONTRIBUTING** link.
- Whether **`scrypath_ops/README`** gains a short “Tests / Postgres” pointer vs keeping prerequisites only in **CONTRIBUTING**, as long as **D-12** single-source rule holds.
- Whether **D-10** ships in the same PR as **D-08**–**D-09** or follows in a tiny follow-up if the first PR is already large.

### Folded Todos

(None.)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **VRFY-03**, **VRFY-04**; out-of-scope table.
- `.planning/ROADMAP.md` — Phase **53** goal, dependency on Phase **51**.
- `.planning/PROJECT.md` — **v1.12** Tier **A2** verify spine vision.

### Prior phase context (do not regress doc roles)

- `.planning/phases/051-adoption-path-truth-and-discoverability/051-CONTEXT.md` — README vs **CONTRIBUTING** vs guides; **`mix verify.*`** as thin orchestrators; **CONTRIBUTING** ↔ **CI** honesty (**D-08**–**D-10**).
- `.planning/phases/52-actionable-errors-and-onboarding-pitfalls/52-CONTEXT.md` — README thinness; **CONTRIBUTING** link patterns.

### Implementation and contracts

- `lib/mix/tasks/verify.opsui.ex` — Root orchestrator; **`@moduledoc`** / **`@shortdoc`** changes.
- `mix.exs` — **`preferred_envs`** for **`verify.opsui`**.
- `README.md` — Consumer + maintainer wayfinding (**D-01**–**D-03**).
- `CONTRIBUTING.md` — Verify matrix and local ↔ CI mapping (**D-08**, **D-12**).
- `scrypath_ops/README.md` — Optional app-level prerequisite detail (**D-12**).
- `.github/workflows/ci.yml` — **`scrypath-ops`** job definition (**D-08**).
- `test/scrypath/docs_contract_test.exs` — Doc-contract extensions (**D-07**–**D-11**).
- `docs/releasing.md` — Already mentions **`mix verify.opsui`**; keep aligned if text changes.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`lib/mix/tasks/verify.opsui.ex`** — Implements root **`mix verify.opsui`**; needs **`@moduledoc`** so it appears in **`mix help`** like sibling **`Mix.Tasks.Verify.*`** modules.
- **`test/scrypath/docs_contract_test.exs`** — Existing **`ordered?`** / cross-file patterns for **CI** ↔ **CONTRIBUTING** (Phase **51** **`phoenix-example-integration`** test) to mirror for **`scrypath-ops`**.

### Established patterns

- Root **`mix verify.*`** tasks are thin shells; docs live in **markdown** + **Mix help**, not duplicated long-form in multiple places.

### Integration points

- **`.github/workflows/ci.yml`** **`scrypath-ops`** / **`scrypath-ops-path-check`** job(s) must stay the **byte-honest** reference for what **`verify.opsui`** approximates locally.

</code_context>

<specifics>
## Specific Ideas

- Subagent research (parallel): README one-liner + **CONTRIBUTING** link pattern; **`@moduledoc`** required for **`mix help`** visibility; bounded **`docs_contract_test`** for **CI** ↔ docs; prerequisites **CONTRIBUTING**-canonical with **README** router and **`mix help`** summary + link.

</specifics>

<deferred>
## Deferred Ideas

(None — discussion stayed within Phase **53** scope.)

### Reviewed Todos (not folded)

(None.)

</deferred>

---

*Phase: 53-contributor-opsui-verify-spine*  
*Context gathered: 2026-04-21*
