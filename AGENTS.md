# Working preferences

## Communication and workflow preferences

- Speak to the user as a software engineer and colleague. Use plain, direct language. Keep necessary technical terms and explain unfamiliar workflow language through its practical consequence.
- End with the actual outcome, what remains broken or blocked, and the next useful action. Usually one short paragraph or at most three short bullets is enough. State clearly when no user action is needed.
- Keep hashes, internal task and threat IDs, exhaustive test counts, audit history, and workflow metadata in linked artifacts unless they are needed for a real decision or explicitly requested. Say what the checks establish in ordinary language.
- Give progress updates when there is new information. When a required update interval arrives during a long wait, use one brief factual line; do not repeat the whole plan or invent progress.
- Ask for user input only when the answer changes scope, authority, risk, cost, an irreversible action, or a required phase/milestone boundary. Explain the concrete choice and why it matters. Continue routine authorized work and bookkeeping without asking for acknowledgments or exact phrases.
- Preserve an existing safety stop automatically when its cause remains unresolved. A confirmation merely to keep work stopped is unnecessary. Removing redundant confirmation does not authorize live tests, accept risk, renew a budget/window, or start another phase.
- Record explicit user corrections in durable instructions. Apply these preferences to OpenGSD planning, execution, reviews, progress updates, and final summaries. Keep detailed evidence available without making the user translate process records into takeaways.
- When authorized work remains and no user action is needed, keep working. Carry planning through implementation, tests and review within the selected phase; stop for a real decision or phase/milestone boundary. Removing an unnecessary confirmation is not a reason to leave the task idle.
- At every pause or handoff, state in chat what is happening, the concrete blocker and consequence, your recommended next step, and exactly who acts next. Explicitly say when waiting for the user versus continuing work.
- Summarize every risk or decision in plain language before asking; make linked documents optional detail. When the user has no strong preference, recommend a concrete path. An uninformed or indifferent response is not risk acceptance.
- Prefer the least disruptive evidence-supported remedy. For stuck project tests, inspect attributable processes and consider targeted cleanup first; recommend a whole-machine restart only when its necessity and impact are established.

--- project-doc ---

<!-- GSD:project-start source:PROJECT.md -->
## Project

**Scrypath**

Scrypath is an open-source Elixir library for declarative, Ecto-native search indexing and search orchestration. It helps Phoenix and Ecto teams add search to existing schemas with a small amount of code while handling synchronization, reindexing, and operational workflows in a way that feels native to the Elixir ecosystem.

**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

**Local reference material:** Consult relevant files under `prompts/` during discuss, planning, and execution whenever decisions touch search-library architecture, Elixir or Ecto or Phoenix best practices, OSS release engineering, or brand and positioning tradeoffs.

### Constraints

- **Tech stack**: Elixir OSS library with Ecto-first APIs and Phoenix-friendly integrations - the ecosystem fit is central to adoption.
- **Backend strategy**: Public v1 should target Meilisearch first, while preserving an internal adapter seam - avoid premature public abstraction without causing API damage later.
- **Write-path support**: v1 should support inline, Oban-backed, and manual synchronization flows - different apps need different consistency and operational tradeoffs.
- **Developer experience**: Minimal setup and great Phoenix ergonomics are the top priority, with correctness close behind - product decisions should optimize for low friction without hiding reality.
- **Operational clarity**: Eventual consistency, delete semantics, backfills, and reindex workflows must be explicit - search sync failures are operational issues, not minor edge cases.
- **Release quality**: The library should not be released publicly until it feels complete - roadmap and documentation should reflect a high quality bar rather than a rush to ship.
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Recommended Stack
### Core library
- **Elixir**: support floor `1.17`, target current stable through `1.19`
- **OTP**: support floor `26`, test through `28`
- **Ecto**: primary integration surface
- **Telemetry**: first-class instrumentation from day one
### Search backend for v1
- **Meilisearch** as the public backend target for v1
- Bigger ecosystem gap in Elixir than Typesense
- Clear precedent in `meilisearch-rails` for product shape
- Lets Scrypath own a sharper category message instead of entering a partially-covered space
### Sync and job execution
- **Oban** as the recommended production async path
- Support **inline** sync for local development and low-complexity apps
- Support **manual** sync for migrations, imports, and advanced operator control
### HTTP and adapter layer
- Keep an **internal adapter boundary** from day one
- Do **not** promise a public backend-agnostic abstraction in v1
- Prefer a boring, explicit behavior-based seam over a large facade
### OSS and release operations
- **GitHub Actions**
- **erlef/setup-beam**
- **Release Please**
- **Hex publishing**
- **ExDoc**
- **Credo**
- **Dialyxir**
- **Req.Test**, **Mox**, **StreamData**
## Recommended Choices
| Area | Choice | Why | Confidence |
|------|--------|-----|------------|
| Core API shape | Ecto-first, function-heavy API with one schema macro | Matches idiomatic Elixir and least surprise | High |
| Backend v1 | Meilisearch | Stronger ecosystem gap and cleaner positioning | High |
| Queue path | Oban-native optional integration | Fits Phoenix/Ecto teams and production needs | High |
| Observability | Telemetry spans and stable metadata | Required for operational trust | High |
| Release automation | GitHub Actions + Release Please + Hex | Strong OSS ergonomics with low maintenance | High |
## What Not to Use
- **Public multi-backend facade in v1** - too much abstraction pressure before the core product is solid
- **Phoenix-only architecture** - would weaken Ecto-first reuse and make the library less composable
- **Mandatory supervision in the core path** - too heavy for a library whose base path should be mostly functions
- **Postgres-native search as part of the same initial product promise** - dilutes the product identity
## Notes
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to `.codex/skills/` or `.agents/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## Repository workflow

**Contributors:** follow **[CONTRIBUTING.md](CONTRIBUTING.md)** for verify tasks, CI, and release gates. When **`.planning/`** is present, it holds milestone context for maintainers.

**Automated coding agents:** honor the constraints in this file; keep edits focused, run the checks **CONTRIBUTING** names for your change, and update **`.planning/PROJECT.md`** when you intentionally change product scope or shipped claims.

When `.planning/STATE.md` says `Awaiting next milestone`, the root `.planning/ROADMAP.md` is an index of shipped milestones, not an active phase roadmap. OpenGSD may report `roadmap.analyze` with `scope: unscoped` because the archived milestone version in STATE has no active milestone section in that index. Its `init.progress` inventory may also surface historical phase directories as `current_phase` or `has_work_in_progress`; these are not active while STATE says no phase is active. Treat this as the expected idle state: use STATE and the roadmap's Current Posture, do not route into historical phase directories, and do not present the scope result as missing or corrupt planning data.

Agents should default to the repo's **green-main release train** posture:

- keep `main` green on the lean required gates
- prefer **PR-first** execution for serious milestone or feature-depth work
- shift verification left: completion must be backed by executable tests or exact-SHA hosted evidence, never post-implementation human verification or pending UAT
- resolve subjective choices before implementation or keep them nonblocking; do not simulate a reviewer identity or silently auto-approve a trust gate
- avoid speculative milestone reopening when no active milestone, release follow-up, or concrete bug/adopter evidence exists
- when the release train is idle and there is no approved work item, say so plainly instead of inventing work

Maintainers who use the separate GSD toolkit should follow that tool’s docs so planning artifacts stay consistent; this file does not duplicate those slash-commands for OSS readers.
<!-- GSD:workflow-end -->

## Worktree continuity

Read [.planning/reference/UI-WORKTREE-LEARNINGS.md](.planning/reference/UI-WORKTREE-LEARNINGS.md) before a worktree handoff or retained-preview work. Dirty edits belong to their checkout: inventory intended source changes and checkpoint them in an owned commit or a scoped patch before branching, then verify their disposition in the destination. Preserve unrelated edits; never transfer an older file wholesale over newer behavior without reconciliation. Use an explicit absolute working directory for edits and commands. After a squash merge, verify the actual merged ref and relevant file-tree parity before calling the preview latest; commit SHA differences alone do not prove missing work.

## UI work

For the retained maintainer preview, read `.planning/UI-PREVIEW.json` first and use its named checkout. Verify the container bind mount, URL, branch, and inclusion of current `main` before editing or collecting UI evidence. Never assume the shell's starting checkout is the running app. Preserve pending local work and reconcile it explicitly before changing worktrees. The UI capture command rejects a mismatched preview source/port or omitted merged-main baseline.

Run `npm run ui:preflight` from that checkout's demo directory before editing or restarting its preview. It reads source/branch/dirty-work and Docker provenance without launching a browser or writing artifacts, and rejects a stale local main ref by comparing it with remote main. Refresh and reconcile main when it refuses; if the remote cannot be verified, do not claim the preview is latest. Keep review evidence in `ui-review-artifacts/`, outside Playwright cleanup, and preserve existing preview data with the documented seed-disabled Compose override.

For storefront or ScrypathOps changes, follow [examples/scrypath_ecommerce/e2e/UI-REVIEW.md](examples/scrypath_ecommerce/e2e/UI-REVIEW.md). Review the full current screen and journey inventory before narrowing to maintainer feedback. Use the maintained roles/jobs and internal-to-user language map, inspect rendered screenshots and actual copy, record unreported problems and coverage gaps, batch coherent repairs, and confirm once. Run `npm run ui:review` from the demo in the checkout actually mounted by the preview. Captures and passing code tests alone are not a design pass; never auto-update an unreviewed visual baseline or claim independent review when none occurred. Keep the existing lean CI posture and preserve retained preview data.



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run the GSD profile workflow to generate your developer profile.
> This section is managed by GSD -- do not edit manually.
<!-- GSD:profile-end -->
