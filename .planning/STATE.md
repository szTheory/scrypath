---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: public-release-trust-and-operator-visibility
current_phase: not_started
current_phase_name: requirements-definition
current_plan: none
status: defining_requirements
stopped_at: Milestone v1.2 started
last_updated: "2026-04-16T20:05:00Z"
last_activity: 2026-04-16
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-16)

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Current focus:** milestone v1.2 requirements and roadmap definition

## Current Position

Phase: Not started (defining requirements)
Plan: None
Current Phase: Not started
Current Phase Name: requirements-definition
Current Plan: None
Status: Defining requirements
Last activity: 2026-04-16
Last Activity Description: Started milestone v1.2 Public Release Trust and Operator Visibility.

Progress: [----------] 0%

## Accumulated Context

### Decisions

- Public v1 backend target is Meilisearch.
- Internal architecture should preserve a future backend seam.
- Core architecture is Ecto-first and Phoenix-friendly.
- Sync modes for v1 are inline, Oban, and manual.
- Postgres-native search remains outside the v1 product boundary.
- [Phase 04]: Kept Oban on the existing Scrypath sync/delete verbs and surfaced queue acceptance through the established mode/status envelope.
- [Phase 04]: Defined worker args as pre-projected, string-keyed payload maps so future workers never need source-row reload logic.
- [Phase 04]: Kept queue durability on the existing Scrypath sync verbs and used Scrypath.Oban only for Ecto.Multi composition.
- [Phase 04]: Validated persisted worker args before schema/backend resolution and cancelled impossible jobs instead of retrying them forever.
- [Phase 04]: Kept public Scrypath telemetry low-cardinality around schema, backend, index, sync mode, and workflow counts.
- [Phase 04]: Put Meilisearch request and task-wait detail on explicit backend prefixes so task uid and poll counts never leak onto the common path.
- [Phase 04]: Documented sync_mode :oban as durable enqueue acceptance only, with one shared async lifecycle for operators.
- [Phase 06]: Kept ExDoc as the ordered public docs shell and grouped extras by learning path instead of expanding README further.
- [Phase 06]: Defined Phoenix example fixtures as plain compile-trustworthy modules in test support so guide examples can stay anchored without adding a full Phoenix app.
- [Phase 06]: Locked the context-first Phoenix boundary and sync visibility wording in docs contract tests before deeper copy work.
- [Phase 06]: Kept the README fast and practical by moving from installation to a real context-first path before audience qualification.
- [Phase 06]: Used the fixture modules as the source of truth for README and guide function names so Phoenix docs and tests keep teaching one boundary.
- [Phase 06]: Used Release Please's native elixir release type in manifest mode so versioning and changelog updates stay on the standard path.
- [Phase 06]: Kept the human release checklist short and pushed repeatable docs/package checks into CI and Mix commands.
- [Phase 06]: Included guides and the maintainer release note in Hex package metadata so the published tarball matches the docs quality bar.
- [Phase 06]: Moved Hex publish dry-run validation into maintainer-only release docs behind an explicit HEX_API_KEY requirement.
- [Phase 06]: Locked the Phoenix JSON page normalization contract in both public docs and fixture-backed tests so copied examples stay valid.
- [Phase 06]: Kept the always-on CI release gate auth-free by validating package metadata and unpack behavior instead of publish credentials.
- [Phase 09]: Narrowed the public install contract to the direct `:scrypath` dependency and kept Oban guidance optional.
- [Phase 09]: Replaced crash-prone JSON pagination parsing with non-raising normalization to page `1`.
- [Phase 09]: Aligned LiveView docs fixtures with realistic string-keyed nested attrs and added a narrow Plug-decoded request-shape smoke test.
- [Phase 10]: Kept mix verify.phase10 as the single auth-free release-confidence entrypoint and left publish validation manual behind HEX_API_KEY.
- [Phase 10]: Locked the maintainer runbook wording to mix verify.phase10 with docs contract assertions so the credential boundary stays explicit.
- [Phase 10]: Accepted the maintainer-owned Hex dry-run failure as valid manual evidence because the goal is traceable credential-boundary proof on the candidate commit, not a forced successful publish rehearsal.
- [Phase 10]: Added one explicit recorded-metadata sentence in 10-VERIFICATION.md so the checkpoint acceptance grep matches the documented evidence without changing the result.
- [Phase 10]: Kept Phase 08 and Phase 09 requirement ownership explicit in the v1.1 audit while using Phase 10 only as the verification and closeout layer.
- [Phase 10]: Updated the active planning files to reference the final evidence chain directly instead of relying on implicit milestone memory.

### Blockers/Concerns

- Phase 08's focused fast verification is green, but the live `mix verify.phase8` path still needs a reachable Meilisearch instance via `SCRYPATH_MEILISEARCH_URL`.
- Phase 10 evidence is complete, but a publisher-scoped `HEX_API_KEY` is still needed for a successful Hex dry-run retry.

### Deferred Items

| Category | Item | Status |
|----------|------|--------|
| verification | Live Phase 08 Meilisearch verification | Deferred until a reachable `SCRYPATH_MEILISEARCH_URL` is available |
| release | Hex publish dry-run retry with publisher-scoped key | Deferred until a publisher-scoped `HEX_API_KEY` is available |

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260416-if2 | fix mix.exs GitHub URLs add a GitHub Actions publish job gated on release creation use HEX_API_KEY only in that publish job | 2026-04-16 | 40c6398 | [260416-if2-fix-mix-exs-github-urls-add-a-github-act](./quick/260416-if2-fix-mix-exs-github-urls-add-a-github-act/) |

## Session Continuity

Last session: 2026-04-16T19:27:45.639Z
Stopped at: Completed 10-03-PLAN.md
Resume file: None

## Current Status

- v1.0 remains archived with the full Meilisearch-first core, search, Oban, reindex, docs, and release baseline shipped.
- v1.1 is archived with reliability hardening, docs-safety fixes, `mix verify.phase10`, and the milestone-close evidence chain.
- Milestone v1.2 is now open for release trust and operator visibility work.
- Fast docs verification passes locally; live Phase 08 verification still depends on a reachable Meilisearch endpoint.
- The release-confidence artifact records the failed manual Hex dry-run cleanly; a publisher-scoped key is still needed for a successful retry.
- The next roadmap should prioritize public release verification and operator primitives before backend breadth or richer backend-native search power.

## Next Command

- `$gsd-plan-phase 11`

---
*Last updated: 2026-04-16 after starting milestone v1.2*
