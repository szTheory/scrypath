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

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, or `.github/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## Repository workflow

**Contributors:** follow **[CONTRIBUTING.md](CONTRIBUTING.md)** for verify tasks, CI, and release gates. When **`.planning/`** is present, it holds milestone context for maintainers.

**Automated coding agents:** honor the constraints in this file; keep edits focused, run the checks **CONTRIBUTING** names for your change, and update **`.planning/PROJECT.md`** when you intentionally change product scope or shipped claims.

Agents should default to the repo's **green-main release train** posture:

- keep `main` green on the lean required gates
- prefer **PR-first** execution for serious milestone or feature-depth work
- avoid speculative milestone reopening when no active milestone, release follow-up, or concrete bug/adopter evidence exists
- when the release train is idle and there is no approved work item, say so plainly instead of inventing work

Maintainers who use the separate GSD toolkit should follow that tool’s docs so planning artifacts stay consistent; this file does not duplicate those slash-commands for OSS readers.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
