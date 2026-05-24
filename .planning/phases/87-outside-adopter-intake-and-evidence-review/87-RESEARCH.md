# Phase 87: Outside-Adopter Intake And Evidence Review - Research

**Researched:** 2026-05-24 [VERIFIED: local system date]
**Domain:** OSS adopter-intake contract, evidence review workflow, and branch-tip support-proof governance for Scrypath [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`]
**Confidence:** HIGH [VERIFIED: repo branch-tip files plus official GitHub documentation were sufficient for the core decisions]

<user_constraints>
## User Constraints (from CONTEXT.md)

Source for all copied text in this section: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md` [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`]

### Locked Decisions
- **D-01:** Add exactly one new canonical intake guide for this phase. Do not turn `README.md` or `CONTRIBUTING.md` into a second intake authority.
- **D-02:** Keep support truth and intake truth separate:
  - `guides/support-and-compatibility.md` owns what Scrypath currently defends.
  - the new outside-adopter intake guide owns how an adopter should attempt, capture, and submit evidence.
  - `examples/phoenix_meilisearch/README.md` remains the authoritative live Phoenix + Meilisearch runbook.
- **D-03:** `README.md` stays the public front door and should route to the intake guide when a reader wants to try the defended real-app path or report outside-adopter evidence.
- **D-04:** `CONTRIBUTING.md` stays maintainer-facing and should only map the proof-command family, CI parity, and maintainer review workflow. It should not duplicate the intake checklist or live runbook.
- **D-05:** The new intake guide should be calm and contract-shaped, not marketing copy. It should explain the defended path, proof command family, required evidence bundle, admissibility classes, finding buckets, and review/closeout rubric.

### Canonical proof path and runtime posture
- **D-06:** The canonical proof command family remains `mix verify.adopter` and `mix verify.adopter --live`.
- **D-07:** The defended outside-adopter path for admissible evidence is explicitly the current Phoenix + Meilisearch repo-clone path, not a generic Hex-only story.
- **D-08:** The intake surface must state the repo-clone versus Hex-package boundary plainly so outside adopters know when they are on the defended path versus a near-path or off-path attempt.
- **D-09:** The intake guide should name the runtime assumptions that matter for review: Elixir/OTP, Phoenix/Ecto when applicable, Meilisearch version, sync mode, and whether the example app or host app path is under test.

### Required evidence package
- **D-10:** The canonical evidence package should be a repo-owned guided checklist/template, not a freeform report and not a GitHub form as the only authority.
- **D-11:** Each adopter attempt must include a small command-output bundle in addition to the template so maintainers can distinguish product truth from anecdote.
- **D-12:** Required evidence for an admissible attempt is:
  - adopter context and goal
  - environment matrix
  - exact Scrypath ref or Hex version
  - chosen proof path and sync mode
  - exact commands run in order
  - expected versus actual outcome
  - first failure/confusion point
  - supporting logs or failing output
  - maintainer review block
- **D-13:** Screenshots should be optional and only requested when docs navigation or UI confusion matters. Raw archives should not be the only required payload.
- **D-14:** The maintainer review block must classify each reviewed finding as exactly one of:
  - docs/onboarding gap
  - support-truth drift
  - product gap
  - env/setup papercut

### Admissibility and evidence classes
- **D-15:** Use a tiered evidence-bucket policy rather than a strict-only or broad-anecdotal policy.
- **D-16:** Evidence classes are:
  - **Class A: defended evidence** — current repo clone, current docs, documented versions, canonical example path, required artifacts present
  - **Class B: near-path evidence** — same product shape with one bounded deviation, such as Hex install or adjacent minor versions
  - **Class C: off-path evidence** — multiple deviations, unsupported topology/backend/runtime mix, or partial artifacts
  - **Class D: non-evidence** — missing repro steps, versions, logs, or only opinion
- **D-17:** Only Class A evidence can change defended support/readiness conclusions or strongly influence the "stop soon vs reopen one wedge" verdict.
- **D-18:** Class B evidence can justify docs/onboarding/setup follow-up and may motivate reproduction on the defended path, but it cannot widen current support claims by itself.
- **D-19:** Class C evidence is directional only. It may inform backlog ranking or future research, but it cannot count against branch-tip support/readiness truth.
- **D-20:** Class D should be logged as intake noise, not treated as reviewed evidence.

### Review rubric and milestone-close decision rule
- **D-21:** Use a JTBD-gated severity/frequency rubric tied to the already locked next-pull ranking instead of a loose qualitative call or a pseudo-precise weighted matrix.
- **D-22:** Review every finding in this order:
  1. classify into one of the four finding buckets
  2. if it is a product gap, map it to the concrete adopter job it blocks or degrades
  3. score only `severity` (`blocker`, `painful workaround`, `minor`) and `frequency` (`one adopter`, `repeated`)
  4. apply the locked ranking as tie-breaker and scope guard
- **D-23:** The common gate for any non-stop verdict is:
  - the signal comes from reviewed outside-adopter evidence on the defended path
  - the issue survives triage as a product gap
  - the issue blocks or seriously degrades a concrete adopter job
  - Phase 88 cannot clear it with a bounded papercut fix
  - the verdict memo names the winning evidence and why higher-ranked alternatives did not win
- **D-24:** `stop soon` remains the default if reviewed failures are mostly docs/support/env issues, or if any remaining product gaps are single-adopter, niche, or clearly below the locked ranking.
- **D-25:** Reopen **related-data propagation** only when reviewed evidence shows repeated correctness/trust failures caused by associated-data changes, denormalized projections, or unclear dependency-triggered reindexing.
- **D-26:** Reopen **tenant-safe access** only when reviewed evidence shows a real shared-index SaaS boundary failure and related-data did not meet its threshold more strongly.
- **D-27:** High-cardinality facet-value search may be recorded as later evidence, but it must not displace `stop soon`, `related-data propagation`, or `tenant-safe access` in Phase 87/88.

### Workflow preference for this phase and adjacent planning
- **D-28:** For this phase, and for downstream planning unless a branch is truly high-impact, prefer research-first synthesis over iterative questioning.
- **D-29:** Ask the user again only on materially consequential forks that cannot be resolved from repo truth, prompt research, or reviewed evidence. Small implementation-shape choices should be decided by the agent and documented clearly.
- **D-30:** Keep recommendations cohesive with Scrypath's established posture: small explicit public surfaces, low magic, one authority per concern, operational honesty, and high developer trust.

### the agent's Discretion
- Exact filename and placement of the new intake guide and evidence template.
- Whether the optional structured submission transport is a GitHub issue form, discussion template, or plain markdown file, as long as the repo-owned guide/template remains canonical.
- Exact wording of the admissibility examples and verdict memo format.
- How much of the command-output bundle is pasted inline versus linked as attachments, as long as required facts remain reviewable without guesswork.

### Deferred Ideas (OUT OF SCOPE)
- Treating GitHub issue forms or other submission tooling as the canonical intake authority.
- Broadening support claims beyond the defended Phoenix + Meilisearch path during this phase.
- Reopening generic ergonomics work, SearchModule recovery, backend expansion, or deeper Phoenix helper breadth.
- Letting high-cardinality facet-value search displace related-data propagation or tenant-safe access in the current decision hierarchy.
- Making a global GSD workflow-profile change beyond the scope of this phase; the preference is captured here for this phase and adjacent planning first.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADOPT-01 | The repo ships one current outside-adopter intake and evidence-review path that tells adopters which proof command, runtime versions, sync mode, example path, and artifacts to supply. [VERIFIED: `.planning/REQUIREMENTS.md`] | Use one new canonical intake guide plus one repo-owned evidence template; route to it from `README.md`; keep `guides/support-and-compatibility.md` as support-truth authority and `examples/phoenix_meilisearch/README.md` as the live runbook. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [VERIFIED: `README.md`] [VERIFIED: `guides/support-and-compatibility.md`] [VERIFIED: `examples/phoenix_meilisearch/README.md`] |
| ADOPT-02 | Maintainers review at least two real outside-adopter attempts against current checkout truth and classify each issue as docs/onboarding gap, support-truth drift, product gap, or env/setup papercut. [VERIFIED: `.planning/REQUIREMENTS.md`] | Store each reviewed attempt in a repo-visible artifact with one evidence-class decision, one finding table, and one maintainer verdict block per attempt; the repo currently lacks any branch-tip intake artifact or public adopter-report inventory, so sourcing the two attempts is a planning dependency. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [VERIFIED: local `find` under `.planning/phases/87-outside-adopter-intake-and-evidence-review`] [VERIFIED: local `find` under `.github/ISSUE_TEMPLATE`] [VERIFIED: https://github.com/szTheory/scrypath/issues] [VERIFIED: https://github.com/szTheory/scrypath/discussions] |
| ADOPT-03 | The Phoenix + Meilisearch proof story stays defended and current, including explicit repo-clone boundaries, example assumptions, and current support scope for the core library path. [VERIFIED: `.planning/REQUIREMENTS.md`] | Keep the defended path anchored to `mix verify.adopter` and `mix verify.adopter --live`, CI’s `phoenix-example-integration` job contract, the repo-clone `path:` dependency, and the current support guide’s Elixir/OTP/Meilisearch/sync-mode posture. [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: `.github/workflows/ci.yml`] [VERIFIED: `examples/phoenix_meilisearch/README.md`] [VERIFIED: `guides/support-and-compatibility.md`] [VERIFIED: `mix.exs`] |
</phase_requirements>

## Summary

Phase 87 is a documentation-and-review phase, not a product-surface phase. The branch tip already has a defended proof spine: `guides/support-and-compatibility.md` owns support truth, `README.md` is the front door, `CONTRIBUTING.md` is maintainer-facing, `examples/phoenix_meilisearch/README.md` owns the live runbook, and `mix verify.adopter` / `mix verify.adopter --live` define the executable proof command family. The missing piece is a canonical intake contract and evidence-review artifact shape that converts real adopter attempts into reviewable, branch-tip-grounded evidence. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [VERIFIED: `README.md`] [VERIFIED: `CONTRIBUTING.md`] [VERIFIED: `guides/support-and-compatibility.md`] [VERIFIED: `examples/phoenix_meilisearch/README.md`] [VERIFIED: `lib/mix/tasks/verify.adopter.ex`]

The strongest plan shape is three bounded slices only: add one canonical intake guide plus one repo-owned evidence template, review two real adopter attempts into durable repo artifacts using the locked Class A-D and finding-bucket rubric, then update rolling planning truth with one explicit verdict memo. The repo does not currently expose a public outside-adopter intake path: `.github/ISSUE_TEMPLATE` contains only a release-parity drift template, the GitHub issues list is empty, the GitHub discussions URL is not enabled, and the phase directory has only `87-CONTEXT.md`. That means Phase 87 planning must explicitly account for how the two required real attempts will be sourced and stored. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [VERIFIED: local `find` under `.github/ISSUE_TEMPLATE`] [VERIFIED: `.github/ISSUE_TEMPLATE/release-parity-drift.md`] [VERIFIED: https://github.com/szTheory/scrypath/issues] [VERIFIED: https://github.com/szTheory/scrypath/discussions] [VERIFIED: local `find` under `.planning/phases/87-outside-adopter-intake-and-evidence-review`]

The repo-native pattern should stay dominant: one authority per concern, thin routing from public surfaces, executable truth for defended paths, and optional GitHub submission transport as a convenience mirror rather than the canonical contract. GitHub issue forms and discussion category forms both exist as platform features, but discussions are not currently enabled on this repository and the phase context explicitly forbids making transport the sole authority. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms?apiVersion=2022-11-28] [CITED: https://docs.github.com/discussions/managing-discussions-for-your-community/syntax-for-discussion-category-forms] [VERIFIED: https://github.com/szTheory/scrypath/discussions]

**Primary recommendation:** Use a repo-owned markdown intake guide plus a repo-owned evidence template as the canonical contract, optionally mirror the template into a GitHub issue form later, and treat “two real adopter attempts available for review” as the only material execution dependency the planner must surface early. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms?apiVersion=2022-11-28]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Outside-adopter intake contract | CDN / Static | Database / Storage | The intake guide and evidence template should live as versioned repo docs, while reviewed evidence artifacts should persist under `.planning/` or another durable repo path. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [VERIFIED: `README.md`] |
| Defended proof command execution | API / Backend | Database / Storage | `mix verify.adopter` and `mix verify.adopter --live` are backend-side CLI/test flows, and live proof depends on Postgres + Meilisearch state. [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: `.github/workflows/ci.yml`] |
| Live Phoenix example proof | API / Backend | Database / Storage | The example app runs `mix test` against Postgres 16 and Meilisearch v1.15 with explicit env vars. [VERIFIED: `examples/phoenix_meilisearch/README.md`] [VERIFIED: `.github/workflows/ci.yml`] |
| Evidence review and verdict memo | Database / Storage | API / Backend | The durable output is a stored review artifact and planning-truth update; maintainers perform the review using repo truth plus proof-command output. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `.planning/STATE.md`] |

## Standard Stack

### Core
| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Repo-owned markdown guide + template | n/a | Canonical intake authority and evidence package | The phase context requires one repo-owned intake guide and one repo-owned evidence template, while keeping transport optional. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] |
| `mix verify.adopter` / `mix verify.adopter --live` | branch-tip task contract | Defended proof-command family | These commands already define the fast/live proof spine and should remain the intake guide’s executable anchor. [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: `CONTRIBUTING.md`] [VERIFIED: `guides/support-and-compatibility.md`] |
| ExUnit contract tests | Elixir 1.19.5 locally; CI verifies 1.17.3 and 1.19.0 [VERIFIED: local command `mix run -e 'IO.puts(System.version()); IO.puts(System.otp_release())'`] [VERIFIED: `.github/workflows/ci.yml`] | Protect routing, command-family truth, and intake-surface drift | The repo already uses focused doc/task contract tests and an adopter verify job instead of broad prose-freezing. [VERIFIED: `test/scrypath/readiness_contract_test.exs`] [VERIFIED: `test/mix/tasks/verify_adopter_test.exs`] [VERIFIED: `.github/workflows/ci.yml`] |

### Supporting
| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| GitHub issue forms | platform feature [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms?apiVersion=2022-11-28] | Optional structured submission transport | Use only as a convenience mirror after the repo-owned guide/template exist; do not make it the sole authority. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] |
| GitHub discussion category forms | platform feature [CITED: https://docs.github.com/discussions/managing-discussions-for-your-community/syntax-for-discussion-category-forms] | Optional conversational intake surface | Use only if discussions are enabled later; the repository’s discussions URL is not enabled today. [VERIFIED: https://github.com/szTheory/scrypath/discussions] |
| GitHub Actions `phoenix-example-integration` job | branch-tip workflow | CI parity reference for live proof assumptions | Use as the source of truth for live env vars, service versions, and run order when writing the intake contract. [VERIFIED: `.github/workflows/ci.yml`] [VERIFIED: `examples/phoenix_meilisearch/README.md`] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Repo-owned markdown template | GitHub issue form only | Faster submission UX, but it violates the locked requirement that the canonical evidence package live in the repo rather than in platform transport alone. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms?apiVersion=2022-11-28] |
| Markdown guide + template | GitHub discussions | Better conversation threading, but the repo’s discussions surface is not enabled and discussion threads are weaker as canonical review artifacts. [VERIFIED: https://github.com/szTheory/scrypath/discussions] [CITED: https://docs.github.com/discussions/managing-discussions-for-your-community/syntax-for-discussion-category-forms] |
| JTBD-gated severity/frequency rubric | Weighted score matrix | More pseudo-precision, less consistency with the locked milestone rule that ranking and bounded evidence should dominate the verdict. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [VERIFIED: `docs/jtbd-gap-map.md`] |

**Execution spine:**
```bash
mix verify.adopter
SCRYPATH_EXAMPLE_INTEGRATION=1 PGPORT=5433 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix verify.adopter --live
```
Source: current repo task and maintainer docs. [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: `CONTRIBUTING.md`] [VERIFIED: `examples/phoenix_meilisearch/README.md`]

## Architecture Patterns

### System Architecture Diagram

```text
Outside adopter
  -> README.md route
  -> canonical intake guide
  -> chooses proof path
     -> Class A defended repo-clone path
        -> mix verify.adopter (fast) OR mix verify.adopter --live
        -> example runbook + env matrix + command-output bundle
        -> repo-owned evidence template
        -> maintainer review artifact
        -> finding classification + severity/frequency + verdict memo
        -> STATE.md / planning truth update
     -> Class B/C/D path
        -> evidence-class decision
        -> directional notes or intake noise log
        -> no widening of defended support truth
```
This flow matches the locked authority split and evidence-class policy. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`]

### Recommended Project Structure
```text
guides/
├── outside-adopter-intake.md      # Canonical intake contract and admissibility rules

docs/
├── templates/
│   └── adopter-evidence.md        # Canonical evidence bundle and maintainer review block

.github/
├── ISSUE_TEMPLATE/
│   └── outside-adopter-evidence.yml   # Optional mirror only, if added

.planning/phases/87-outside-adopter-intake-and-evidence-review/
├── 87-CONTEXT.md
├── 87-RESEARCH.md
├── 87-attempt-01-review.md        # Reviewed real adopter attempt
└── 87-attempt-02-review.md        # Reviewed real adopter attempt
```
The exact filenames are discretionary, but this split preserves one authority per concern and keeps reviewed evidence durable and repo-visible. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [VERIFIED: `README.md`] [VERIFIED: `CONTRIBUTING.md`] [VERIFIED: `guides/support-and-compatibility.md`]

### Pattern 1: One authority per concern
**What:** Keep support truth in `guides/support-and-compatibility.md`, live operational steps in `examples/phoenix_meilisearch/README.md`, maintainer proof wiring in `CONTRIBUTING.md`, and outside-adopter evidence intake in one new guide. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [VERIFIED: `README.md`] [VERIFIED: `CONTRIBUTING.md`] [VERIFIED: `guides/support-and-compatibility.md`] [VERIFIED: `examples/phoenix_meilisearch/README.md`]

**When to use:** Use this whenever a new public-facing concern is added around proof, support, or evidence intake. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`]

**Example:**
```markdown
## Need the defended path?
Use `guides/support-and-compatibility.md` for what Scrypath currently defends.

## Want to attempt the path and submit evidence?
Use `guides/outside-adopter-intake.md`.
```
Source pattern: existing README-to-guide routing style. [VERIFIED: `README.md`] [VERIFIED: `guides/support-and-compatibility.md`]

### Pattern 2: Evidence-class gate before triage
**What:** Decide Class A/B/C/D first, then classify each finding into the four locked buckets, then apply severity/frequency only to product-gap findings. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`]

**When to use:** Use on every adopter report before it is allowed to influence support truth or milestone-direction decisions. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`]

**Example:**
```markdown
Evidence class: A
Finding bucket: docs/onboarding gap
Blocked JTBD: n/a
Severity: minor
Frequency: one adopter
Verdict effect: no support widening; papercut candidate only
```
Source pattern: locked evidence and rubric rules. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`]

### Pattern 3: Repo-owned template with optional GitHub mirror
**What:** Write the canonical evidence checklist in a normal markdown file first, then optionally mirror the same fields into `.github/ISSUE_TEMPLATE/*.yml`. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms?apiVersion=2022-11-28]

**When to use:** Use when maintainers want lower-friction public submissions without making GitHub’s UI the only source of truth. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms?apiVersion=2022-11-28]

**Example:**
```yaml
name: Outside adopter evidence
body:
  - type: textarea
    id: commands_run
    attributes:
      label: Exact commands run in order
```
Source: GitHub issue-form field model. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms?apiVersion=2022-11-28]

### Anti-Patterns to Avoid
- **Duplicate intake authority:** Do not restate the checklist in `README.md` or `CONTRIBUTING.md`; that recreates the drift Phase 86 just removed. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-RESEARCH.md`]
- **Anecdote-first review:** Do not classify product gaps before deciding whether the report is Class A/B/C/D evidence. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`]
- **Hex-only defended proof claim:** Do not imply the packaged Hex artifact is the defended real-app path; the current example uses a repo-clone `path:` dependency and the support guide calls that boundary out explicitly. [VERIFIED: `guides/support-and-compatibility.md`] [VERIFIED: `examples/phoenix_meilisearch/README.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Public evidence intake | Custom web intake portal | Repo-owned markdown guide/template, optionally mirrored into a GitHub issue form | Lower maintenance, versioned with the repo, and consistent with the locked “repo-owned authority” rule. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms?apiVersion=2022-11-28] |
| Verdict scoring | Weighted decision spreadsheet | Locked JTBD + severity/frequency rubric | The milestone already fixed the ranking order and default `stop soon` posture; more scoring machinery adds noise, not signal. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [VERIFIED: `docs/jtbd-gap-map.md`] |
| Live proof instructions | Second runbook outside the example README | Route to `examples/phoenix_meilisearch/README.md` | The example README already owns env vars, service versions, CI parity, and local smoke details. [VERIFIED: `examples/phoenix_meilisearch/README.md`] [VERIFIED: `CONTRIBUTING.md`] |

**Key insight:** Phase 87 should add classification discipline and durable evidence artifacts, not another operational surface. The repo already has the defended proof path; what it lacks is a canonical intake contract and reviewed external evidence. [VERIFIED: `guides/support-and-compatibility.md`] [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: `.planning/REQUIREMENTS.md`]

## Common Pitfalls

### Pitfall 1: Mixing support truth with intake truth
**What goes wrong:** README or CONTRIBUTING accumulates checklist detail, live-runbook steps, and support claims in parallel, creating another drift triangle. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [VERIFIED: `README.md`] [VERIFIED: `CONTRIBUTING.md`]
**Why it happens:** Intake work feels documentation-shaped, so maintainers are tempted to append it to existing front-door docs instead of creating a new authority. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`]
**How to avoid:** Keep one intake guide and route to it. Support truth stays in `guides/support-and-compatibility.md`; live steps stay in the example README. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [VERIFIED: `guides/support-and-compatibility.md`] [VERIFIED: `examples/phoenix_meilisearch/README.md`]
**Warning signs:** New evidence checklist bullets appear in `README.md` or `CONTRIBUTING.md`. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`]

### Pitfall 2: Treating near-path evidence as defended support failure
**What goes wrong:** A Hex-only or version-deviant attempt is allowed to count against branch-tip support truth. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [VERIFIED: `guides/support-and-compatibility.md`]
**Why it happens:** The repo already publishes on Hex, so reviewers may blur package-install convenience with the defended repo-clone proof path. [VERIFIED: `README.md`] [VERIFIED: `guides/support-and-compatibility.md`] [VERIFIED: `examples/phoenix_meilisearch/README.md`]
**How to avoid:** Classify evidence before findings, and state the repo-clone versus Hex boundary plainly in the intake guide and review artifact. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`]
**Warning signs:** Reports omit the exact ref/path used or name only `{:scrypath, "~> 0.3"}` without the example path or branch ref. [VERIFIED: `README.md`] [VERIFIED: `examples/phoenix_meilisearch/README.md`]

### Pitfall 3: Collecting logs without reviewable structure
**What goes wrong:** Maintainers receive screenshots, raw archives, or “it failed” text that cannot be mapped to JTBD, finding bucket, or branch-tip truth. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`]
**Why it happens:** GitHub issues and ad hoc chat encourage narrative reports without required fields. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms?apiVersion=2022-11-28]
**How to avoid:** Require adopter context, env matrix, exact commands, expected/actual output, first failure point, and a maintainer review block in the canonical template. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`]
**Warning signs:** A report lacks command order, version matrix, or first confusion point. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`]

## Code Examples

Verified patterns from official or branch-tip sources:

### Canonical live-proof contract
```elixir
@required_live_envs [
  "SCRYPATH_EXAMPLE_INTEGRATION",
  "PGPORT",
  "SCRYPATH_MEILISEARCH_URL"
]
```
Source: current `verify.adopter` task. [VERIFIED: `lib/mix/tasks/verify.adopter.ex`]

### Minimal issue-form mirror field
```yaml
- type: textarea
  id: expected_vs_actual
  attributes:
    label: Expected versus actual outcome
```
Source: GitHub issue-form syntax supports structured fields in YAML. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms?apiVersion=2022-11-28]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Freeform issue or chat report | Structured repo-owned evidence template, optionally mirrored into issue forms | Current GitHub docs support YAML issue forms and discussion category forms as structured transport. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms?apiVersion=2022-11-28] [CITED: https://docs.github.com/discussions/managing-discussions-for-your-community/syntax-for-discussion-category-forms] | Structured reports make admissibility and finding-class review consistent. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] |
| “Any adopter complaint can move roadmap priority” | Only Class A defended evidence can strongly move support/readiness or the stop-soon verdict | Locked in Phase 87 context on 2026-05-24. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] | Prevents one vivid anecdote from reopening broad feature work. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] |
| One more support/proof doc whenever needed | One canonical authority per concern with thin routing | Reinforced by Phase 85 and 86 docs architecture and current repo surfaces. [VERIFIED: `.planning/phases/85-real-app-proof-and-drift-gates/85-CONTEXT.md`] [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-RESEARCH.md`] [VERIFIED: `README.md`] | Keeps phase work bounded and reduces drift recurrence. [VERIFIED: `test/scrypath/readiness_contract_test.exs`] |

**Deprecated/outdated:**
- Treating GitHub transport as canonical intake authority is outdated for this phase; the locked context requires repo-owned authority first. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`]
- Treating “outside-adopter evidence” as already existing is outdated; the current repo only defends in-repo proof and still needs reviewed external attempts. [VERIFIED: `guides/support-and-compatibility.md`] [VERIFIED: `.planning/STATE.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | At least two real outside-adopter attempts exist or can be obtained during Phase 87 execution, even though none are visible today in repo files, GitHub issues, or GitHub discussions. [ASSUMED] | Summary; Open Questions; Validation Architecture | If wrong, Plan 87-02 becomes execution-blocked and the phase needs a sourcing step or user-provided attempts before review can happen. |

## Open Questions

1. **Where will the two real outside-adopter attempts come from?**
   - What we know: The repo currently shows no branch-tip intake artifact, no public adopter-report template, no GitHub discussions surface, and an empty issues list. [VERIFIED: local `find` under `.planning/phases/87-outside-adopter-intake-and-evidence-review`] [VERIFIED: local `find` under `.github/ISSUE_TEMPLATE`] [VERIFIED: https://github.com/szTheory/scrypath/issues] [VERIFIED: https://github.com/szTheory/scrypath/discussions]
   - What's unclear: Whether the maintainers already have two off-repo adopter attempts, or whether Phase 87 must first solicit them. [ASSUMED]
   - Recommendation: Make sourcing explicit in the plan. If attempts already exist, normalize them into the canonical template before review. If not, add a bounded “obtain two attempts” step before classification work. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`]

2. **Where should reviewed attempt artifacts live?**
   - What we know: The phase directory is empty apart from context, and `.planning/` already holds rolling truth artifacts. [VERIFIED: local `find` under `.planning/phases/87-outside-adopter-intake-and-evidence-review`] [VERIFIED: `.planning/STATE.md`]
   - What's unclear: Whether the project prefers reviewed adopter reports under the phase directory, under `docs/`, or as issue links mirrored back into planning. [ASSUMED]
   - Recommendation: Keep the canonical review artifacts in the phase directory so planning and milestone-close work can consume them without relying on GitHub UI state. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix tasks, ExUnit, docs/tests | ✓ [VERIFIED: local command `elixir -e 'IO.puts(System.version())'`] | 1.19.5 [VERIFIED: local command `elixir -e 'IO.puts(System.version())'`] | — |
| OTP / BEAM | Mix task runtime | ✓ [VERIFIED: local command `mix run -e 'IO.puts(System.version()); IO.puts(System.otp_release())'`] | 28 [VERIFIED: local command `mix run -e 'IO.puts(System.version()); IO.puts(System.otp_release())'`] | — |
| `mix` | `mix verify.adopter`, tests, docs | ✓ [VERIFIED: local command `mix run -e 'IO.puts(System.version()); IO.puts(System.otp_release())'`] | tied to Elixir 1.19.5 [VERIFIED: local command `mix run -e 'IO.puts(System.version()); IO.puts(System.otp_release())'`] | — |
| Docker Engine | Live proof path for Phoenix example | ✓ [VERIFIED: local command `docker --version`] [VERIFIED: local command `docker info`] | 29.4.1 [VERIFIED: local command `docker --version`] | No full fallback; fast path only if Docker is unavailable. [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] |
| Docker Compose | Example service startup | ✓ [VERIFIED: local command `docker compose version`] | v5.1.3 [VERIFIED: local command `docker compose version`] | Use existing running services if already provisioned. [VERIFIED: `examples/phoenix_meilisearch/README.md`] |
| `git` | Exact ref capture in evidence bundle | ✓ [VERIFIED: local command `git --version`] | 2.41.0 [VERIFIED: local command `git --version`] | Record a tarball or detached ref manually if needed. [ASSUMED] |

**Missing dependencies with no fallback:**
- None on this machine for research or live-proof execution. [VERIFIED: local environment commands above]

**Missing dependencies with fallback:**
- None. [VERIFIED: local environment commands above]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit under Mix / Elixir [VERIFIED: `test/` tree and `mix test` usage in repo docs] |
| Config file | `mix.exs` alias + CLI registration; no standalone `test.exs` config file is required for this phase gate. [VERIFIED: `mix.exs`] |
| Quick run command | `mix verify.adopter` [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: `.github/workflows/ci.yml`] |
| Full suite command | `mix test --exclude integration --exclude docs_contract --include requires_clean_workspace` [VERIFIED: `.github/workflows/ci.yml`] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADOPT-01 | Intake routing, proof-command family, and support-truth boundaries stay branch-tip-true | docs-contract / unit | `mix verify.adopter` plus a new narrow intake-contract test file or bounded additions to `test/scrypath/readiness_contract_test.exs` [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: `test/scrypath/readiness_contract_test.exs`] | ❌ Wave 0 for the new intake surface |
| ADOPT-02 | Two real attempts are reviewed with evidence class and finding bucket output | manual review artifact check | No existing automated command; review is artifact-driven. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: local `find` under `.planning/phases/87-outside-adopter-intake-and-evidence-review`] | ❌ Wave 0 |
| ADOPT-03 | Defended Phoenix + Meilisearch proof story remains current | docs-contract + live integration | `mix verify.adopter` and, when env/services are present, `SCRYPATH_EXAMPLE_INTEGRATION=1 PGPORT=5433 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix verify.adopter --live` [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: `examples/phoenix_meilisearch/README.md`] | ✅ existing |

### Sampling Rate
- **Per task commit:** `mix verify.adopter` [VERIFIED: `lib/mix/tasks/verify.adopter.ex`]
- **Per wave merge:** `mix test --exclude integration --exclude docs_contract --include requires_clean_workspace` [VERIFIED: `.github/workflows/ci.yml`]
- **Phase gate:** Fast contract green plus at least one successful evidence-artifact review pass; run live proof when intake/runtime wording changes. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `lib/mix/tasks/verify.adopter.ex`]

### Wave 0 Gaps
- [ ] Add a bounded regression seam for the new intake guide/template routing and required fields. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `test/scrypath/readiness_contract_test.exs`]
- [ ] Decide and codify the canonical file path for reviewed adopter-attempt artifacts. [VERIFIED: local `find` under `.planning/phases/87-outside-adopter-intake-and-evidence-review`]
- [ ] Obtain or confirm availability of two real outside-adopter attempts before executing Plan 87-02. [ASSUMED]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope is docs/review, not auth changes] | — |
| V3 Session Management | no [VERIFIED: phase scope is docs/review, not session changes] | — |
| V4 Access Control | no [VERIFIED: no access-control runtime work is in ADOPT-01..03] | — |
| V5 Input Validation | yes [VERIFIED: evidence intake requires structured, reviewable fields] | Repo-owned template with required fields; optional issue-form field validation if mirrored to GitHub. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms?apiVersion=2022-11-28] |
| V6 Cryptography | no [VERIFIED: no crypto surface is introduced by this phase] | — |

### Known Threat Patterns for this phase
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Secrets pasted into logs or env dumps | Information Disclosure | Tell adopters to include required command output but redact secrets; prefer exact env names and versions over full secret-bearing `.env` files. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [VERIFIED: `examples/phoenix_meilisearch/README.md`] |
| Unsupported path reported as defended support failure | Tampering | Force Class A/B/C/D classification before verdict and state the repo-clone boundary explicitly. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [VERIFIED: `guides/support-and-compatibility.md`] |
| Anecdotal report changes roadmap priority | Repudiation | Require exact commands, runtime matrix, first failure point, and a durable maintainer review block before product-gap ranking changes. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md` - locked phase decisions, evidence classes, rubric, and authority split. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`]
- `.planning/REQUIREMENTS.md` - `ADOPT-01` through `ADOPT-03`. [VERIFIED: `.planning/REQUIREMENTS.md`]
- `.planning/STATE.md` - current milestone posture and “stop soon unless evidence proves one wedge” framing. [VERIFIED: `.planning/STATE.md`]
- `README.md` - front-door routing and repo-clone/support wayfinding. [VERIFIED: `README.md`]
- `CONTRIBUTING.md` - maintainer proof-command family, CI parity, and verify matrix. [VERIFIED: `CONTRIBUTING.md`]
- `guides/support-and-compatibility.md` - defended support truth and clone-vs-Hex boundary. [VERIFIED: `guides/support-and-compatibility.md`]
- `examples/phoenix_meilisearch/README.md` - live proof runbook, env vars, and service/runtime assumptions. [VERIFIED: `examples/phoenix_meilisearch/README.md`]
- `lib/mix/tasks/verify.adopter.ex` - fast/live command contract and required live env vars. [VERIFIED: `lib/mix/tasks/verify.adopter.ex`]
- `test/scrypath/readiness_contract_test.exs` - existing narrow drift gate pattern. [VERIFIED: `test/scrypath/readiness_contract_test.exs`]
- `mix.exs` and `.github/workflows/ci.yml` - Elixir floor, CI versions, and `phoenix-example-integration` contract. [VERIFIED: `mix.exs`] [VERIFIED: `.github/workflows/ci.yml`]
- Official GitHub Docs issue-form syntax - structured issue transport. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms?apiVersion=2022-11-28]
- Official GitHub Docs discussion category forms - structured discussion transport. [CITED: https://docs.github.com/discussions/managing-discussions-for-your-community/syntax-for-discussion-category-forms]

### Secondary (MEDIUM confidence)
- `docs/jtbd-gap-map.md` - current locked leverage ranking and diminishing-returns framing. [VERIFIED: `docs/jtbd-gap-map.md`]
- `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-RESEARCH.md` - recent repair-phase lessons about one authority per concern and executable-truth-first verification. [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-RESEARCH.md`]
- `.planning/phases/85-real-app-proof-and-drift-gates/85-CONTEXT.md` - prior docs-architecture posture that Phase 87 should preserve. [VERIFIED: `.planning/phases/85-real-app-proof-and-drift-gates/85-CONTEXT.md`]

### Tertiary (LOW confidence)
- None. All recommendations above are grounded in branch-tip repo files or official GitHub documentation. [VERIFIED: source list above]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - The phase relies mostly on branch-tip repo files and two official GitHub documentation pages, not on unstable third-party ecosystem guesses. [VERIFIED: source list above]
- Architecture: HIGH - The authority split, evidence classes, and verdict rules are already locked in `87-CONTEXT.md`. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`]
- Pitfalls: HIGH - The likely failure modes are direct extensions of current repo structure, current lack of intake surfaces, and explicit rules from the phase context. [VERIFIED: `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-CONTEXT.md`] [VERIFIED: local `find` under `.github/ISSUE_TEMPLATE`] [VERIFIED: local `find` under `.planning/phases/87-outside-adopter-intake-and-evidence-review`]

**Research date:** 2026-05-24 [VERIFIED: local system date]
**Valid until:** 2026-06-23 for repo-local findings; re-check GitHub platform docs and repo public issue/discussion state if planning slips past 30 days. [VERIFIED: local system date] [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms?apiVersion=2022-11-28] [CITED: https://docs.github.com/discussions/managing-discussions-for-your-community/syntax-for-discussion-category-forms]
