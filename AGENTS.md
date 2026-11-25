# Working preferences

## Communication and workflow preferences

- Speak to the user as a software engineer and colleague. Use plain, direct language. Keep necessary technical terms and explain unfamiliar workflow language through its practical consequence.
- End with the actual outcome, what remains broken or blocked, and the next useful action. Usually one short paragraph or at most three short bullets is enough. State clearly when no user action is needed.
- Keep hashes, internal task and threat IDs, exhaustive test counts, audit history, and workflow metadata in linked artifacts unless they are needed for a real decision or explicitly requested. Say what the checks establish in ordinary language.
- Give progress updates when there is new information. When a required update interval arrives during a long wait, use one brief factual line; do not repeat the whole plan or invent progress.
- Ask for user input only when the answer changes scope, authority, risk, cost, an irreversible action, or a required phase/milestone boundary. Explain the concrete choice and why it matters. Continue routine authorized work and bookkeeping without asking for acknowledgments or exact phrases.
- Preserve an existing safety stop automatically when its cause remains unresolved. A confirmation merely to keep work stopped is unnecessary. Removing redundant confirmation does not authorize live tests, accept risk, renew a budget/window, or start another phase.
- Call a screen a screen (maintainer correction, 2026-11-25): do not write "surface" for a screen or page in the UI, the storybook, the glossary or new notes. The storybook tiers are Primitives, Patterns, Areas, Screens and Flows; `JOB-*` ids still name the persona's job. "Surface" for a background layer in the design tokens is a different, existing term.
- Record explicit user corrections in durable instructions. Apply these preferences to OpenGSD planning, execution, reviews, progress updates, and final summaries. Keep detailed evidence available without making the user translate process records into takeaways.
- When authorized work remains and no user action is needed, keep working. Carry planning through implementation, tests and review within the selected phase; stop for a real decision or phase/milestone boundary. Removing an unnecessary confirmation is not a reason to leave the task idle.
- At every pause or handoff, state in chat what is happening, the concrete blocker and consequence, your recommended next step, and exactly who acts next. Explicitly say when waiting for the user versus continuing work.
- Summarize every risk or decision in plain language before asking; make linked documents optional detail. When the user has no strong preference, recommend a concrete path. An uninformed or indifferent response is not risk acceptance.
- Guiding principle (maintainer, 2026-11-20): pursue value to the point of diminishing returns. Rules, CI/CD, gates and contract tests serve outcomes; change or delete one that no longer earns its cost, with the reason and a revisit trigger recorded, instead of contorting work around it. Sanity-check that effort is producing value before repeating an approach. Never weaken what a check actually proves just to go green.
- Never put the maintainer's account name or absolute home paths (`/Users/<name>/...`) in the storybook, committed files, commit messages or PR text (maintainer correction, 2026-11-23). Show the home directory as `~` or use repo-relative paths, and say so when a tool needs the full path locally. Older tracked files that already carry one are a known cleanup, not a precedent.
- Prefer the least disruptive evidence-supported remedy. For stuck project tests, inspect attributable processes and consider targeted cleanup first; recommend a whole-machine restart only when its necessity and impact are established.
- For lightweight delegated work in Codex, prefer GPT-6 Luna (`gpt-6-luna`) with extra-high (`xhigh`) reasoning effort for cost efficiency. Delegate only when authorized; reserve stronger-model synthesis or review for consequential tradeoffs.
- Approval of a task or phase includes its required local builds, tests, CI, reviews, fixes and bounded retests within the approved scope and limits. Runtime length alone is not an approval gate. Do not turn each plan step or verification command into another permission request.
- Apply an already approved compatibility policy through its concrete fields, version changes, tests and documentation without asking again for each implementation slice. Ask only for a materially new consequence outside that policy. Preserve explicit user stops, exact resource limits and specific no-retry instructions; investigate failures and resolve their cause before retrying.
- When repeated approvals expose workflow friction, investigate the cause, implement low-risk efficiency improvements, and record the lesson in durable instructions. Prefer measured critical-path and duplicate-work reductions over adding caches, concurrency or dependencies by default.

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

Approved phase verification includes the Git metadata and Docker access its canonical commands need. For a known fetch-dependent gate such as `mix verify.repository_contracts`, use the tool's `require_escalated` permission on the first invocation; a sandbox run that cannot write its worktree `FETCH_HEAD` only repeats the full suite without valid trusted-history evidence. Use the same first-run access for canonical Docker builds that write Buildx metadata. Keep Buildx metadata in the task's external writable directory when the existing runner supports `BUILDX_CONFIG`. Do not ask the user again for these already authorized verification steps, weaken the gate, or treat permission failures as behavioral RED.

Some repository contracts build a clean Git snapshot. Before rerunning one after a fix, check whether it reads committed HEAD or the working tree. Run the affected focused check, checkpoint the owned fix when that check is green, then run the snapshot-based gate against that commit. An uncommitted fix cannot repair a clean-copy test of the previous commit; avoid spending another full run on the same stale input.

Agents should default to the repo's **green-main release train** posture:

- keep `main` green on the lean required gates
- squash-merge a PR yourself once the work is done and its required checks are green on the exact head, including visible-UI PRs; advisory reds such as `deep-quality` do not block (maintainer standing instruction, 2026-11-19). Do not wait for a separate merge yes. Hex releases and release-please PRs still need the maintainer's explicit yes
- prefer **PR-first** execution for serious milestone or feature-depth work
- shift verification left: completion must be backed by executable tests or exact-SHA hosted evidence, never post-implementation human verification or pending UAT
- resolve subjective choices before implementation or keep them nonblocking; do not simulate a reviewer identity or silently auto-approve a trust gate
- avoid speculative milestone reopening when no active milestone, release follow-up, or concrete bug/adopter evidence exists
- when the release train is idle and there is no approved work item, say so plainly instead of inventing work

Maintainers who use the separate GSD toolkit should follow that tool’s docs so planning artifacts stay consistent; this file does not duplicate those slash-commands for OSS readers.
<!-- GSD:workflow-end -->

## Docker resource cleanup

For Docker-backed work, use task-scoped resource names or labels and clean up temporary containers, images, networks, and owned build cache when the task finishes or fails. Remove per-iteration and candidate images as soon as their comparison is complete; do not leave unbounded snapshots behind. Before handing off, check `docker system df` and confirm task-scoped resources are gone. Never prune another project's resources or volumes without a clear task-specific reason; volumes may contain data and must be reviewed separately.

## Worktree continuity

Read [.planning/reference/UI-WORKTREE-LEARNINGS.md](.planning/reference/UI-WORKTREE-LEARNINGS.md) before a worktree handoff or retained-preview work. Dirty edits belong to their checkout: inventory intended source changes and checkpoint them in an owned commit or a scoped patch before branching, then verify their disposition in the destination. Preserve unrelated edits; never transfer an older file wholesale over newer behavior without reconciliation. Use an explicit absolute working directory for edits and commands. After a squash merge, verify the actual merged ref and relevant file-tree parity before calling the preview latest; commit SHA differences alone do not prove missing work.

## Milestone preparation (standing maintainer instruction, 2026-11-18)

At every milestone boundary, do the upstream prep before asking what is next: fan out subagents per open decision point, each through the relevant role lenses (security, product, architecture, devops and CI, design and UX, accessibility, OSS maintainer and adopter), weigh patterns, anti-patterns and footguns, prefer primary sources (specs, official docs, source code) over blog posts, run an adversarial pass against each recommendation, and synthesize one recommended option per decision with its confidence and what would change it. Continue until returns diminish. Then present a recommended next milestone and update `.planning/reference/ROLLING-ROADMAP.md` in the same change, so the maintainer chooses from prepared options. The prep feeds, and does not replace, the downstream OpenGSD discuss, plan, execute and verify workflow: write recommendations and research notes, not phase plans. House preferences apply: another copy-paste is better than another dependency, keep dependency trees small and flat, run cheap consistency checks before long suites, and never claim more than the automated evidence proves.

## Phase workflow defaults (standing maintainer instruction, 2026-11-18)

**Discuss phases.** Apply the same fan-out as milestone preparation to every phase's decision points: one subagent per decision (context-window efficiency), each through all relevant role lenses (security, product, architecture, devops, rendering, language and framework specialists, UI and UX where it applies), with pros, cons, tradeoffs, patterns, anti-patterns, footguns and lessons from other products and ecosystems, preferring reputable primary sources. Keep fanning out until returns diminish, run an adversarial pass, then synthesize one coherent recommended set and follow it without asking, unless a choice changes scope, authority, risk or cost. Prefer a small copy-paste over a new dependency; smaller, flatter dependency trees are more secure. For UI work, weigh existing patterns, least surprise and conventions.

**Verify phases.** Automate verification and shift it left: integration, end-to-end, smoke and seam tests, moved onto CI only when the check has recurring value. The goal is zero human verification or UAT. Take verification as far as you can without the maintainer, but only where it yields useful feedback, and never box the work in. Throwaway local verification is fine; not everything belongs in CI. Hand off only what is genuinely impossible to automate, and record that exception. When an item was automated or ruled out, record it in the phase artifacts so it is never re-litigated.

**Cheap checks first.** Where the design allows, run a cheap consistency check before the long suite. When a run is slow or stuck, find the bottleneck and the low-hanging fruit instead of retrying the same thing.

**CI and release efficiency.** (Full rule and ledger: "CI and CD efficiency" below.) Whenever a CI or release run is in progress or finishes, look for low-hanging speed, iteration-time and cost wins (cache keys, duplicated work, path filters, lane timeouts, cold-cache cost) without weakening what the checks prove. Record measured findings in `.planning/` and apply low-risk ones in the next CI change.

## CI and CD efficiency (standing maintainer instruction, first recorded 2026-11-18, restated 2026-11-20)

Applies to every CI run, release run, deploy and Dependabot or release PR, whether in progress or finished. Pointless waiting costs the maintainer time and GitHub Actions money; the checks' quality is never the thing to trade.

- **Evaluate every run.** While a run is in progress and when it finishes, look for low-hanging wins in speed, iteration time and cost: duplicated work, jobs that run when their inputs did not change (path-scoped `if` classifiers like `ops-ui-path`), cache keys and cold-cache cost, serial steps that could run in parallel, advisory lanes that always fail or never gate anything, matrix size, install time, and the strict "branch must be up to date" serialization on bot PRs. Measure first (`gh run view <id> --json jobs`), then change. Never weaken what a required check proves; a skipped job still has to report so the required context passes.
- **Record it.** Put measured findings, candidates and decisions in [.planning/reference/CI-EFFICIENCY.md](.planning/reference/CI-EFFICIENCY.md) (that file is the ledger; keep it current), apply low-risk wins in the next CI change, and mention the biggest one in the handoff only when it changes a decision. The short form under "Phase workflow defaults" above points here.
- **Pre-push confidence is a principle (maintainer, 2026-11-20).** Before pushing, be able to say why hosted CI will most likely pass: run locally as much of each required lane as is practical (the lane's own command, or the closest runnable equivalent, on the exact commit you are about to push), and say plainly which part you could not run and why. A hosted red you could have caught locally costs about 16 minutes and real money, so a push is not how you find out. This holds for every commit that changes behavior, including review fixes made after a verification pass, and for OpenGSD planning and execution: a plan's verify step lists the local commands that mirror each required lane, an executor runs them before the commit leaves the machine, and a skipped local run needs a recorded reason (service not available, too slow for its value) and is a known risk, not an assumption. Prefer making the local run cheaper (cheap consistency checks first, a faster mirror of the lane) over skipping it. Flaky checks that only a hosted run exposes are fixed at the cause, not rerun.
- **Check locally before waiting on hosted CI.** Run the cheap consistency check and the focused test first (`mix format --check-formatted`, the single test file you changed, `node --test` for the token and pair tests, `mix verify.package` for package changes). For workflow wiring and the cheap jobs, use `act` (installed at `/opt/homebrew/bin/act`; `act -l -W .github/workflows/ci.yml` lists the jobs, verified 2026-11-20; on Apple silicon pass `--container-architecture linux/amd64` and pin a runner image with a working Beam/OpenSSL stack, per `docs/releasing.md` "Local CI Reproduction"). The Docker-in-Docker browser lanes (`ecommerce-mounted`, `ecommerce-e2e`) are not `act` candidates: use the repository's own Docker wrappers and the task-scoped Docker cleanup rules above. Run the whole CI Node step locally when a plan changes anything the verifier fixture copies.
- **Release and deploy (CD).** The same rule covers the Release Please run, the release PR's CI, the publish job, `verify-published-release` and the website deploy: look at their timings, retries and manual steps, and write down what could be removed. Hex releases still need the maintainer's explicit yes; a release PR authored by the bot has no CI until a human-authored event (push to its branch, `gh pr update-branch`, or close and reopen).
- **Merge rule.** Squash-merge a green PR yourself (see the release-train list above); do not leave a green PR waiting.

## Brand and UI re-skin knowledge

Before brand adoption, UI re-skinning, storybook or copy-catalog work, read [.planning/reference/BRAND-ADOPTION-PLAYBOOK.md](.planning/reference/BRAND-ADOPTION-PLAYBOOK.md). It holds evidence-graded rules with provenance from this repo and sibling projects. When a phase proves, breaks or refines a rule, update the playbook in the same change, keep the provenance, and record contested points beside their resolution. The maintainer wants this to stay reusable for future rebrands.

## Milestone-end review (standing maintainer instruction, 2026-11-21)

At the end of every milestone, after its last phase and before the milestone audit, complete and cleanup steps run, stop and give the maintainer the chance to look over the UI and give feedback. Until the component catalog (storybook) exists, that means the retained maintainer preview: follow "UI work" below (read `.planning/UI-PREVIEW.json`, run `npm run ui:preflight` from the mounted checkout's demo directory, refresh the preview to current `main` first, preserve its data), say plainly what UI changed in the milestone (or that nothing did), give the URL and the screens or states worth a look, and wait. Apply this to `/gsd-autonomous` runs too: an unattended run pauses here instead of running the lifecycle, and resumes it after the feedback is recorded. Record the feedback in a dated note under `.planning/research/` and fold what is actionable into the next milestone's input before starting it. A milestone with no UI change still offers the review; the maintainer may answer in one word. When the catalog ships, "the preview" becomes the storybook: once its first screen story exists, the milestone-end review and any mid-milestone UI feedback session run on the storybook (stable seeded server, one port, refreshed to current `main`), with each feedback row mapped to a catalog entry, state, viewport and theme.

## Recorded owner decisions (standing maintainer correction, 2026-11-21)

A recorded maintainer decision (an ADR, `OWNER-INTENT`, a roadmap line the maintainer adopted) outranks a later prep note's own judgment. Never defer, shrink, reorder or drop one on the strength of "no outside evidence" or a research recommendation without asking the maintainer first; a prep note may recommend a sequence, not reverse a decision. The v1.49 prep deferred the phoenix_storybook catalog that the maintainer had adopted on 2026-10-25, and the maintainer called it a huge miss. Before recommending a scope cut, search `.planning/adr/`, `.planning/research/*/OWNER-INTENT.md` and the rolling roadmap for a recorded decision that it would override, and say so in the recommendation.

## UI work

The storybook is the UI review surface. It serves the component catalog on 127.0.0.1:4003; the `storybook` block of `.planning/UI-PREVIEW.json` names its checkout, port, `start` and `stop` commands, and `CATALOG_PORT` overrides the port. The retained preview on port 4002 stays the mounted-behavior surface. Stories are static renders of the real components over fictional fixture data with the clock frozen, so buttons do nothing in them: judge behavior in the 4002 preview and the journey test, and judge looks in the storybook. It needs no database, and its first page, `/storybook/welcome`, prints `main@sha`, the served HEAD, a dirty flag and the checkout path.

- **Start:** `mix scrypath_ops.catalog.serve` from the named checkout's `scrypath_ops` directory (the block's `start` command runs it in the background and writes `tmp/catalog.pid`).
- **Status:** `npm run ui:preflight`, which checks the 4002 preview and the storybook independently and reports both.
- **Refresh:** fetch, fast-forward the named checkout to `origin/main`, stop and restart the storybook on the same port with the block's commands, then run the preflight.
- **Port collision:** another project's process may hold 4003. Never stop or signal it: start with `CATALOG_PORT=<free port>` and record the port and the holder in the block's `deviation` field. The serve task refuses a held port and names the holder. It exits quietly only when the holder is a catalog of this checkout at this commit (the checkout and HEAD on its welcome page match; uncommitted edits made after it started are not compared). A catalog from another checkout or an older commit is refused like any other holder, and the message gives the checkout and HEAD it prints.

For the retained maintainer preview, read `.planning/UI-PREVIEW.json` first and use its named checkout. Verify the container bind mount, URL, branch, and inclusion of current `main` before editing or collecting UI evidence. Never assume the shell's starting checkout is the running app. Preserve pending local work and reconcile it explicitly before changing worktrees. The UI capture command rejects a mismatched preview source/port or omitted merged-main baseline.

Run `npm run ui:preflight` from that checkout's demo directory before editing or restarting its preview. It reads source/branch/dirty-work and Docker provenance without launching a browser or writing artifacts, and rejects a stale local main ref by comparing it with remote main. It also fetches the storybook's landing page (loopback only) and refuses a storybook that serves another checkout, an old `main@sha` or a different HEAD than the checkout. Refresh and reconcile main when it refuses; if the remote cannot be verified, do not claim the preview is latest. Keep review evidence in `ui-review-artifacts/`, outside Playwright cleanup, and preserve existing preview data with the documented seed-disabled Compose override.

For storefront or ScrypathOps changes, follow [examples/scrypath_ecommerce/e2e/UI-REVIEW.md](examples/scrypath_ecommerce/e2e/UI-REVIEW.md). Review the full current screen and journey inventory before narrowing to maintainer feedback. Use the maintained roles/jobs and internal-to-user language map, inspect rendered screenshots and actual copy, record unreported problems and coverage gaps, batch coherent repairs, and confirm once. Run `npm run ui:review` from the demo in the checkout actually mounted by the preview. Captures and passing code tests alone are not a design pass; never auto-update an unreviewed visual baseline or claim independent review when none occurred. Keep the existing lean CI posture and preserve retained preview data.



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run the GSD profile workflow to generate your developer profile.
> This section is managed by GSD -- do not edit manually.
<!-- GSD:profile-end -->

## Phase 185 verification correction

The maintainer approved replacing Plans 08/09 verification-backstop annotations with planned automated test obligations, preserving all 61 coverage pairs. These annotations are not passing evidence. Gate preservation on automated matched image/copy comparisons and held-out tests; keep subjective rendered critique nonblocking and explicitly scoped. Missing automated evidence and demonstrated regressions still block completion. Do not infer independent or maintainer aesthetic approval.
