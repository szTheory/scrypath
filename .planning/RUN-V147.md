# Run book: execute milestone v1.47 Brand completion end to end

Written 2026-11-20 so one pasted prompt can drive the whole milestone after a context clear. The maintainer approved following the recommendations below ("follow your recommendations on all of those", 2026-11-20). Everything here is already authorized; do not ask for acknowledgements. Stop only at the stop conditions.

Why this exists: `gsd-autonomous` runs discuss, plan and execute but never opens or merges a PR (it does not call ship or `gh`). So the orchestrator (you) runs it one phase at a time with `--only N` and does the ship and merge steps between phases. Spawn work through the GSD skills; do the shipping yourself.

## Order

1. Phase 188.1 CI path classifier (plain PR; carries the unpushed planning commits).
2. Phase 189 Website re-skin.
3. Phase 190 Wording that does not need the catalog.
4. Phase 191 Cleanup.
5. Milestone close: audit, complete, then milestone preparation for the next milestone. Stop there.

## Standing approvals and decisions (already made; do not re-ask)

- Squash-merge each PR once its required checks are green on the exact head (AGENTS.md). Phase 189 additionally needs website `build-and-check` green on the exact head, verified with `gh api repos/szTheory/scrypath/commits/<head>/check-runs`.
- Non-draft PRs. Squash titles `chore(...)` or `docs(...)`, never `feat` or `fix`.
- The SITE-02 light-only fallback is pre-authorized: if the picker, `theme.js`, dark tokens and their assertions are not green by the end of plan 189-02, ship light-only, amend SITE-02, flag it in the handoff, and continue. No pause.
- The wording calls in `190-CONTEXT.md` marked `[pre-seed call]` stand ("Used for search" / "Not used for search", "Last succeeded", "N jobs pending", "Retry queued" replacing "accepted"). The maintainer may veto later.
- The pre-seeded `189/190/191-CONTEXT.md` and `-RESEARCH.md` are the discuss and research outputs. Do not run a fresh discuss or ask preference questions; if a workflow asks, answer from the CONTEXT decisions and record that.
- Guiding principle (AGENTS.md): value over procedure. If a gate, test or CI step does not earn its cost, change or drop it with the reason and a revisit trigger recorded; never weaken what a check actually proves just to go green; stop a loop that is not converging.
- No Hex release, no push of a `v1.47` tag, no branch-protection change, no human UAT, no preview refresh or `ui:review`, no aesthetic or independent-review claims.

## Stop conditions (surface to the maintainer, then wait)

- The milestone audit returns `gaps_found`, or a success criterion cannot be made an executable check.
- A required check stays red after two fix cycles and the cause is not understood.
- Something would need a new required gate beyond the budget of 12, a branch-protection change, a Hex release, or any irreversible or outward action outside the approvals above.
- The working tree or `origin/main` is in a state this book does not cover.

## Pre-flight (once, at the start)

1. `git status` and `git log --oneline origin/main..main`: expect about 10 local planning commits ahead of `origin/main` and only `.planning/config.json` and `.planning/state.json` dirty. Never stage those two files (the maintainer's local edits and tool settings). Check `gh auth status` and that Docker is running.
2. Toolchain: `export ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5` before `mix`.
3. `.planning/config.json` was set for this run: `mode: yolo`, `git.branching_strategy: phase`, confirm gates off, `workflow.ui_phase: false` (the brand book plus `brand/tokens.json` is the design contract). Restore `workflow.ui_phase: true` when the milestone closes.

## Per-phase loop (188.1, 189, 190, 191)

1. Start from the right base: 188.1 from local `main` (so the planning commits ride its PR); every later phase from fresh `origin/main` after the previous squash merge.
2. Run `/gsd-autonomous --only <N>` (discuss is skipped by the pre-seeded context; plan, execute and verify run). Plans contain executable assertions only: no `<human-check>` blocks and no `verification: backstop` truths. If the verifier routes to `human_needed`, convert the item to a test and re-verify; never choose "continue without validation".
3. Ship with `/gsd-ship <N>`: decline the optional code-review prompt (the GSD review already ran) and do not push the ship-note commit to the PR branch (it moves the head after verification and costs another full CI run); fold the STATE update into the next phase's first commit.
4. Run focused local checks first, commit, then the gates (GATE-02: one full gate run per commit SHA; a fix to a snapshot gate is committed before the gate reruns; first `mix verify.repository_contracts` uses the escalated permission for `FETCH_HEAD`; run the long gates with `run_in_background`).
5. Wait for the required checks on the exact head (`core`, `package`, `repository-contracts`, `backend`, `ecommerce-mounted`, `ops-ui (path-scoped)`), then `gh pr merge --squash`. `deep-quality` red is the known advisory.
6. After the merge, verify the content landed, then refresh local `main`: `git fetch origin`, check `git diff --stat <phase-branch> origin/main` is empty, then `git switch -C main origin/main` (never `reset --hard`; it would discard the two dirty files). Delete the merged branch.
7. Update STATE.md (phase complete, next action) and carry on to the next phase without asking.

## Phase-specific notes

- **188.1:** the classifier is an allowlist (`^(\.planning/|docs/|[^/]+\.md$)`); relax the `upload-artifact` SHA pin in `workflow_wiring_test` to a pattern; then `gh pr update-branch 132` and merge #132 on green, and re-run #129 on the re-skinned base (merge if green, otherwise leave open and record the real cause). Ledger entry in `reference/CI-EFFICIENCY.md`.
- **189:** merging deploys the website. Wait for `build-and-check` green on the exact head (checked with `gh api`), merge, watch the post-merge `deploy` run to success and its smoke step; rollback is `workflow_dispatch` with a `ref` (documented in `docs/releasing.md`). The picker fallback rule above applies. Draft the upstream favicon issue text in the phase record; do not file it. SITE-06 replaces every `mix verify.adopter` mention in website source; the two Hex-shipped guides that name it are a recorded follow-up, not changed here.
- **190:** first dispatch `ci.yml` on current `main` to get a clean `ecommerce-e2e` baseline (the 11-20 nightly predates seven merges), then dispatch it on the exact PR head and record both run ids. No preview refresh or `ui:review`; the phase record says no design pass was done. Docker work follows the AGENTS.md cleanup rules (task-scoped names, external `BUILDX_CONFIG`, remove containers and images, check `docker system df`).
- **191:** three commits in order (demo favicon, readers, data), recomputing the allowlist ceilings from merged `main` (expected 5 entries and 197 hits after 189, ending at 0 and 0); focused checks, commit, then `mix verify.repository_contracts` once per committed state. Docs never spell the retired directory path. Fix `test/release/package_contents_test.exs` with the readers commit.

## Milestone close (after 191 merges)

1. `/gsd-audit-milestone`; `tech_debt` is acceptable (known cause: `deep-quality` via optional sigra); `gaps_found` is a stop condition.
2. One read-only cross-phase check of merged `main` at the final SHA in a fresh context (a check, not independent or aesthetic approval) covering the other consumers of every changed asset.
3. `/gsd-complete-milestone v1.47`; do not push the `v1.47` tag. Answer "skip" to the quick-tasks archive question; approve the phase archive prune only if it lists v1.46 and v1.47 phase directories.
4. Restore `workflow.ui_phase: true` in `.planning/config.json`.
5. Milestone preparation (AGENTS.md): fan out per open decision for the next milestone, update `reference/ROLLING-ROADMAP.md`, and present a recommendation. The maintainer's open slot decision: the discovery and onboarding milestone (`reference/DISCOVERY-AND-ONBOARDING-JOURNEY.md`, SEED-004, the README todo) versus the catalog milestone. Do not start the next milestone.

## Final handoff (plain language, short)

What shipped and is live (including the website deploy), what is still open (Dependabot, the Hex-shipped guides that name `verify.adopter`, the upstream favicon issue draft, the first-nightly read), any fallback taken (picker), and the one recommended next step with who acts next.
