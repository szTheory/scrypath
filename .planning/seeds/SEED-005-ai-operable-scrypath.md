---
slug: ai-operable-scrypath
title: Let an AI or LLM agent diagnose and, behind explicit guards, repair Scrypath search problems through a CLI
status: scheduled
created: 2026-11-23
updated: 2026-11-23
trigger_when: the next milestone after v1.49 is being chosen; or the CLI, the operator API or the failure and recovery model is being changed; or an adopter asks how to hand a search incident to an agent or to automation; or a retro of a real incident shows the same manual diagnosis steps repeated
planted_during: v1.49 Catalog foundation (Pause 2)
---

# Seed: AI-operable Scrypath (diagnose first, repair behind guards, through a CLI)

## Decision (2026-11-25)

The maintainer made the first slice the milestone after v1.50 (v1.51): one read-only, versioned diagnosis report, as a Mix task plus a release-callable function. Actions, an MCP server and anything that writes stay out of that slice. See [v1.50 prep note D](../research/v1.50-prep/D-agent-cli.md).

## Trigger

Surface this when the next milestone is being chosen, when the CLI (`mix scrypath.*`), the operator API or the recovery model changes, when an adopter asks how an agent or automation can handle a search incident, or when a real incident retro shows the same manual steps run twice.

## Why it exists

The maintainer (2026-11-22), while looking at the ScrypathOps storybook, whose one persona so far is the paged on-call engineer (ROLE-OPS) doing JOB-03: search looks unhealthy or sync work failed, find the affected work, take a safe recovery step.

The idea: the same context that lets that engineer decide could be queryable by an AI or LLM agent, so the agent can debug most of these problems, and possibly take the safe recovery actions too (retries, reconciliation). The UI stays important, but AI and LLM use is very important as well and should be designed for, not retrofitted.

A CLI is probably the easiest route and easier than an MCP server: an agent already runs shell commands, output can be JSON, and the same command works everywhere. With it installed and configured, an agent could investigate production incidents, and the same path would serve staging, PR or preview environments, dev slots, local development, test mode, and CI results.

It ties to a principle the maintainer holds as important: automate the world, the devops and SRE mindset. Do retros, record lessons learned, and reduce toil. This extends the standing direction already in `PROJECT.md` ("Operator audience and automation direction", 2026-10-06): shift operational toil left and automate more as real adopter feedback shows what is safe, keep manual paths, and keep state and outcomes transparent.

This is an idea to remember and weigh later. It is not approved scope, not a shipped claim, and nothing here should be built or promised from this note alone.

## What already exists (verified 2026-11-23, so this need not be rediscovered)

- **CLI:** `mix scrypath.status`, `mix scrypath.failed` (has `--json`, one JSON document on stdout), `mix scrypath.retry` (retries one explicit failed-work entry by id), `mix scrypath.reconcile`, and the `mix scrypath.settings.*` tasks (read, diff, `hot_apply` behind an `--ack-live` flag). They run through `Scrypath.CLI.OperatorTask`.
- **Library operator API:** `Scrypath.failed_sync_work/2`, `Scrypath.retry_sync_work/2` and the reconciliation functions the tasks and ScrypathOps both call.
- **ScrypathOps pure view modules** (no LiveView, no database): the Search health posture builder, `FailedSyncView` and `RecoveryView`. They already turn raw operator data into the decisions a person reads (verdict, which rows failed, which are retryable, whether a recovery is verified or only completed). That decision layer is the part an agent would want too.
- **Fixtures:** `fixtures/scrypath_fixtures` has three fictional adopters and 11 named scenarios. They are a ready, realistic test bed for any agent-facing output and for evals.

## Shape of the idea (a sketch, not a design)

1. **Diagnosis context first.** One read-only command (or a small set) that prints what an agent needs to reason about an incident: posture and verdict, failed and retrying work with causes, document freshness, queue and backend task state, and what an action would do. Stable JSON with named fields and a schema version; the same decisions the UI shows, from the same view modules, so the UI and the agent cannot disagree.
2. **Actions second, behind guards.** Retry and reconcile are the first candidates. Each action names its consequence, needs an explicit target (an id, never "all"), runs a dry run first where one exists, and ends with a verification step that checks the outcome rather than trusting that dispatch was accepted (the product rule: accepted dispatch, a toast or a zero count is not completion).
3. **Environment awareness.** The same commands work against production, staging, preview and dev slots, local, test mode and CI results; production defaults to read-only until the operator opts into writes, and the environment is named in every output and every action record.
4. **A record of every action** (who or what, which environment, what was asked, what was verified), so retros and lessons learned have evidence and repeated manual work shows up as toil to remove.
5. **Evals, not vibes.** Check agent-facing output against the fixtures' named failure scenarios: does an agent given only this output pick the right next step, and refuse the wrong one.

## Open questions

- Which actions are safe enough to offer an agent at all, and which stay human-only (for example `hot_apply`, anything destructive, anything that changes settings)?
- Where does authority live: the host application's own credentials and configuration (likely), a separate token, or confirmation by a person for writes?
- Does a documented JSON contract (a schema per command) earn its maintenance cost now, or only after the first real adopter asks?
- How does this relate to the optional ScrypathOps mount: the CLI needs no browser, but both should share the view modules.
- Does an MCP wrapper ever earn its cost on top of the CLI, or is shell plus JSON enough? (Default: CLI first; an MCP server is a thin wrapper to decide later, not a prerequisite.)
- Privacy: agent output and action records must not leak adopter data or secrets; scrubbing rules belong in the contract from the start.

## Guardrails to carry forward

- Honest claims: say what the output establishes (observed state, not guaranteed state), and never imply an agent fixed something that was only dispatched.
- Keep manual paths and transparency; automation is added where real use shows it is safe, not assumed.
- Smaller and flatter wins: reuse the existing tasks and view modules; another small copy beats a new dependency.
- Respect recorded owner decisions and the Hex release rule: nothing here ships without the maintainer's explicit yes.

## Related

- [SEED-006](SEED-006-connected-cli-and-operator-api.md) (2026-11-25): the follow-on idea, a CLI that signs in to a deployed app's operator API.
- [v1.50 prep, note D](../research/v1.50-prep/D-agent-cli.md) (2026-11-25): what exists today, the release and Mix footgun, and a recommended read-only first slice.
- `PROJECT.md`, "Operator audience and automation direction" (2026-10-06).
- `reference/OPERATOR-UI-QUALITY.md` (roles, jobs and the internal-to-user language map).
- The v1.49 Pause 1 note, `research/storybook-catalog/PAUSE-1-PHASE-197.md` (findings F1 to F4 are about what the library can and cannot show, which an agent would hit as well).
