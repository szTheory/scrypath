# Phase 69: Adopter verify spine - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **INTG-02** by adding one root maintainer-facing verify path that proves Scrypath's canonical adopter surfaces still agree:

- root docs and contributor wayfinding
- the support / compatibility contract
- the Phoenix example as the canonical real-app proof
- the documented distinction between a fast no-services check and a live Postgres + Meilisearch proof

This phase is about **verify ergonomics, truth alignment, and CI parity**. It is **not** a search-surface phase, not a broader repo-wide verify cleanup, and not an excuse to widen the live verification story beyond the adopter-confidence slice.

</domain>

<decisions>
## Implementation Decisions

### Command surface

- **D-01:** Add one durable semantic root task named **`mix verify.adopter`**. Do **not** use **`mix verify.integration`** and do **not** make Phase 69's public outcome another phase-numbered task such as **`mix verify.phase69`**.
- **D-02:** The task name should reflect the maintainer job to be done, not milestone bookkeeping. Phase-numbered tasks remain historical/focused gates; the new command is a long-lived maintainer affordance.
- **D-03:** The task must ship with a real **`@shortdoc`** and **`@moduledoc`** and be surfaced from **README** and **CONTRIBUTING** so the Scrypath-specific noun **`adopter`** does not feel opaque.

### Fast mode contents

- **D-04:** **`mix verify.adopter`** with no flags is the **fast** default. It must stay **auth-free** and **service-free**.
- **D-05:** Fast mode must be stronger than docs contracts alone. It should verify:
  - README / CONTRIBUTING / support guide / example README adopter wayfinding
  - the canonical example proof surface for **`:inline`**, **`:manual`**, and **`:oban`**
  - the documented fast vs live distinction
  - the command-shape contract between docs and CI for the live adopter proof
- **D-06:** Fast mode must **not** run the example app's real service-backed test path. Calling a live-ish example run "fast" would violate least surprise and operational honesty.
- **D-07:** Fast mode should stay narrowly about **adopter truth**. Do **not** turn it into generic repo hygiene by absorbing unrelated release, quality, or operator verification work.

### Live mode shape

- **D-08:** Live verification should be exposed as **`mix verify.adopter --live`**, not as a separate top-level task such as **`mix verify.adopter_live`**.
- **D-09:** Flag-based mode selection is the right fit because this is one maintainer workflow with two explicit depths:
  - **fast** = bounded no-services confidence
  - **live** = real example proof
- **D-10:** **`--live`** must keep the real adopter proof path visible. It should run the example's canonical CI-shaped path:
  - **`cd examples/phoenix_meilisearch`**
  - **`mix deps.get`**
  - **`mix test`**
  with the documented env for the example/integration run.
- **D-11:** **`--live`** must **not** hide behind **`./scripts/smoke.sh`**. That script remains the local convenience harness, not the canonical CI proof path.
- **D-12:** **`--live`** must fail loudly when required env/services are missing. No silent downgrade from live to fast, and no partial-pass ambiguity.

### CI alignment style

- **D-13:** Use a **hybrid parity** model:
  - maintainers learn one root command family
  - CI keeps separate jobs with explicit service boundaries
  - CI uses the same command family where appropriate
- **D-14:** The non-service adopter gate should call **`mix verify.adopter`** (or **`mix verify.adopter --fast`** if an explicit flag is added for clarity).
- **D-15:** The service-backed adopter job should call **`mix verify.adopter --live`** while still relying on GitHub Actions for service provisioning, env setup, and job isolation.
- **D-16:** The Mix task should stay **orchestration-only**. Do **not** move service boot, readiness waits, or broader CI workflow logic into the task itself.
- **D-17:** Contract tests should pin the mapping between:
  - README / CONTRIBUTING guidance
  - the adopter verify task help and mode wording
  - the example README's canonical live path
  - the CI job that runs the live adopter proof

### Ecosystem and DX stance

- **D-18:** Follow the Elixir ecosystem pattern of **semantic durable tasks** for long-lived maintainer workflows, similar to Phoenix / Ecto / Oban command naming, instead of exposing milestone IDs as the public interface.
- **D-19:** Keep the contributor experience aligned with the repo's existing strengths:
  - one obvious root command for the common path
  - heavier live proof as an explicit opt-in
  - clear task help
  - no hidden service assumptions
- **D-20:** Preserve Scrypath's broader product posture of **operational honesty**:
  - passing fast mode does **not** mean live search behavior was proven
  - live mode is the defended proof for the real Phoenix + Postgres + Meilisearch path

### the agent's Discretion

- Whether fast mode needs its own focused ExUnit file or should extend **`test/scrypath/docs_contract_test.exs`** plus a small supporting maintainer-facing test.
- Whether to support an explicit **`--fast`** flag in addition to the default no-flag path, provided the default remains fast.
- Exact wording and output formatting of the Mix task help text, provided it clearly states what fast mode proves, what live mode proves, and what prerequisites live mode requires.

</decisions>

<specifics>
## Specific Ideas

- The command family should feel like **`mix verify.opsui`** in spirit: one obvious root maintainer affordance with transparent downstream behavior.
- The best command shape is:
  - **`mix verify.adopter`**
  - **`mix verify.adopter --live`**
- The best fast-mode shape is **docs contracts plus focused example-contract assertions**, not docs-only and not a service-backed example run.
- The best live-mode shape is the **exact example CI path**, not a hand-picked subset of tests and not the local smoke script.
- Successful precedents to learn from:
  - **Phoenix / Ecto / Oban**: semantic commands, good help text, obvious common path, heavier paths explicit
  - **Searchkick**: strong happy-path DX and explicit multi-mode sync thinking
  - **Laravel Scout**: one concept with explicit modes/behaviors, not scattered command sprawl
  - **meilisearch-rails**: compatibility and testing clarity near the top, but avoid hidden callback magic as the default mental model
- Footguns to avoid:
  - naming the command **`verify.integration`** and inviting endless scope creep
  - making fast mode so weak that it only proves doc strings
  - making fast mode so broad that contributors stop using it
  - hiding live verification behind **`smoke.sh`** or a silently reduced fallback path
  - turning the Mix task into CI orchestration glue

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone scope

- `.planning/ROADMAP.md` — Phase 69 scope and success criteria for the adopter verify spine.
- `.planning/REQUIREMENTS.md` — **INTG-02** requirement text and traceability.
- `.planning/PROJECT.md` — v1.17 goal, product posture, and operational-honesty constraints.
- `.planning/STATE.md` — current milestone position and next-phase framing.
- `.planning/phases/68-example-proof-and-support-contract/68-CONTEXT.md` — canonical-proof, support-contract, and docs-contract decisions that Phase 69 must preserve.

### Current maintainer and adopter surfaces

- `README.md` — current maintainer/adopter wayfinding and root verify mentions.
- `CONTRIBUTING.md` — contributor verify matrix and CI job mapping.
- `guides/support-and-compatibility.md` — canonical support contract that the new verify path must protect.
- `examples/phoenix_meilisearch/README.md` — canonical real-app adopter proof and live command/env contract.
- `test/scrypath/docs_contract_test.exs` — existing bounded docs-contract suite and maintainer truth style.

### Existing verify-task patterns

- `lib/mix/tasks/verify.opsui.ex` — precedent for a semantic root maintainer task that mirrors CI behavior.
- `lib/mix/tasks/verify.phase5.ex` — precedent for explicit integration/live flag handling.
- `lib/mix/tasks/verify.phase41.ex` — precedent for a narrow fast docs-contract verify slice.
- `lib/mix/tasks/verify.phase43.ex` — precedent for a narrow fast verify slice that combines docs contracts with focused tests.
- `mix.exs` — current preferred-env and task-registration landscape.

### CI truth

- `.github/workflows/ci.yml` — current job split, service-backed example proof, and where the adopter verify path must align with automation.

### Local research prompts relevant to the decision

- `prompts/elixir-best-practices-deep-research.md` — idiomatic Elixir API and task-shape guidance.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — OSS library ergonomics and maintainer-surface guidance.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — ecosystem fit and least-surprise guidance for Elixir/Phoenix systems.
- `prompts/elixir-search-lib-deep-research.md` — search-library product and operational framing.
- `prompts/search-lib-use-cases-deep-research.md` — adopter/JTBD framing for search-library UX.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`test/scrypath/docs_contract_test.exs`** already protects maintainer-facing truth across docs, verify tasks, and CI references; it is the natural home for much of the fast adopter verify contract.
- **`lib/mix/tasks/verify.opsui.ex`** already demonstrates the desired style for a semantic root task that transparently mirrors a deeper path.
- **`lib/mix/tasks/verify.phase5.ex`** already demonstrates explicit optional integration/live behavior via flags.
- **`examples/phoenix_meilisearch/README.md`** and the example app's **`mix test`** path are already the canonical live adopter proof and should be reused rather than reinterpreted.

### Established Patterns

- Root semantic verify tasks exist for durable maintainer jobs; phase-numbered verify tasks are narrower historical slices.
- Scrypath prefers **bounded contract tests** over prose snapshots or meta-framework indirection.
- CI jobs are intentionally split by dependency and service shape; the repo does not currently force one mega-command across every gate.
- The example README already distinguishes the CI-shaped proof path from the local smoke harness; Phase 69 should preserve that honesty.

### Integration Points

- The new adopter verify task should integrate with:
  - root docs contract tests
  - example README / CI command contracts
  - contributor docs
  - the existing GitHub Actions job split
- The live adopter path should connect directly to **`examples/phoenix_meilisearch`** instead of inventing a second proof mechanism.

</code_context>

<deferred>
## Deferred Ideas

- Unifying every root/service-backed verify story in the repo behind one giant command — out of scope and likely harmful.
- Broader cleanup or retirement of older **`mix verify.phase*`** tasks beyond what Phase 69 needs for the new maintainer path.
- Extending the adopter verify spine into OPSUI, release, or unrelated Meilisearch smoke coverage.
- Heavy browser/E2E or additional service-backed verification breadth — remains outside this phase unless Phase 70 evidence says otherwise.

</deferred>

---

*Phase: 69-adopter-verify-spine*
*Context gathered: 2026-04-22*
