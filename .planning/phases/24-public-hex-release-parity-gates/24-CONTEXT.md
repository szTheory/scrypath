# Phase 24: Public Hex release & parity gates - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Cut the next **Hex** release so adopters receive the v1.3-era library surface (facets, relevance tuning, multi-index search, operator polish) through the normal package manager, with the **same mechanical trust chain** as `0.3.0`: Release Please → tag → publish, **SHIP-01..03** satisfied, and parity/verify gates aligned with `.planning/REQUIREMENTS.md` and roadmap success criteria. No new public product features (those are Phases 25–26).

</domain>

<decisions>
## Implementation Decisions

### Semver and Release Please (SHIP-01)

- **D-01:** Target **`0.3.1`** for the Phase 24 Hex release. REQUIREMENTS are **additive over `0.3.0`** with no breaking changes to `%SearchResult{}`, `%Query{}`, or `%FailedWork{}` `@enforce_keys`; under Hex’s pre-1.0 convention, **patch** best signals “same line, non-breaking upgrade” and reduces false “minor might break me” anxiety for teams who read Hex semver docs literally.
- **D-02:** **Align Release Please with D-01.** Default Conventional Commits + `release-type: elixir` often proposes **`0.4.0`** for `feat:` — unacceptable without an explicit policy flip. Prefer configuring **`release-please-config.json`** (or equivalent supported option) for **pre-1.0 patch bumps on minor features**, and document use of **`Release-As:`** when a one-off override is needed. Planner MUST verify option names against the pinned **release-please** / **release-please-action** version in use.
- **D-03:** **CHANGELOG** carries one crisp line above the fold: non-breaking additive release; public struct contracts per REQUIREMENTS unchanged. If maintainers **ever** consciously ship **`0.4.0`** instead, treat it as a **documented exception** with extra release-note emphasis (Hex minor on `0.x` reads as breaking to many readers).

### Repo hygiene before release (SHIP-01, parity gates)

- **D-04:** **No exceptions** for “docs-only” or “small” uncommitted work under packaged paths. Every byte that ships in the tarball (`lib/`, `test/`, `guides/`, `docs/`, plus `mix.exs`, top-level packaged `.md` per `verify.workspace_clean` pathspec rules) must be **committed, reviewed, and merged** to the branch Release Please tags (typically `main`) before the release PR merge / publish. Last-minute prose fixes use a **tiny follow-up PR**, not a dirty working tree — same lesson as `.planning/milestones/v1.2-MILESTONE-AUDIT.md` and Phase 18 **D-04** (no escape hatch).
- **D-05:** **`.planning/`** churn does not satisfy **`workspace_clean`** pathspecs by default; it is not license for parallel uncommitted **`lib/`** / **`guides/`** / **`test/`** work (see `.planning/STATE.md` warning).

### SHIP-02 — “No dangling `0.3.0` pointers”

- **D-06:** **Narrow definition:** “Dangling” applies only to **adopter-facing “current release”** surfaces and **release-automation pins** — not repo-wide substring elimination.
- **D-07:** **MUST update** in the release PR: `mix.exs` **`@version`** / **`@source_ref`** (and ExDoc **`source_ref`** / related links so version **N** docs point at the **tag for N**), **README** install snippet and any “current release” lines, **CHANGELOG** with a **new** `## [x.y.z]` section at the top, and tests that assert **current** manifest/version expectations (e.g. `test/mix/tasks/workflow_wiring_test.exs`, `.release-please-manifest.json` as exercised by those tests).
- **D-08:** **MUST NOT rewrite** for SHIP-02: prior **CHANGELOG** section bodies/headers, **`.planning/`** historical narratives, compatibility or parity examples that **name a shipped artifact** (e.g. `mix verify.release_parity 0.3.0` in moduledocs), or research notes where `0.3.0` is a **time-indexed fact**.
- **D-09 (optional hardening):** A **small targeted** check (test or Mix task) that README / key ExDoc extras’ dependency guidance stays **consistent** with `@version` is welcome; a **global ban** on the substring `0.3.0` is **out of scope** and harmful.

### Verify matrix and workflows (SHIP-03, roadmap success criteria)

- **D-10:** **Keep the publish workflows thin:** `mix verify.workspace_clean`, version alignment check, **`mix verify.phase11`**, Hex dry-run + publish, **`mix verify.release_publish "<version>"`** with existing retry env — **do not** duplicate the full **`ci.yml` `quality`** matrix (`phase13`, `phase14`, `phase20`, `phase22`, …) onto publish. Deep regression signal stays on **every PR / push to `main`** (idiomatic Elixir OSS: Oban/Req-style split).
- **D-11:** Add **`mix verify.release_parity "<version>"`** to **`release-please.yml`** `publish-hex` **after** a successful **`mix hex.publish`** (and after the tarball is visible — reuse **`SCRYPATH_RELEASE_VERIFY_ATTEMPTS`** / **`SCRYPATH_RELEASE_VERIFY_SLEEP_MS`** parity with **`verify.release_publish`**). Mirror the same step on **`.github/workflows/publish-hex.yml`** so manual recovery has **symmetric** post-publish parity to the canonical path. This closes the gap between roadmap SHIP-03 / success criteria (“release pipeline”) and today’s docs, which only mention scheduled **`verify-published-release.yml`** for **`release_parity`**.
- **D-12:** Update **`docs/releasing.md`** so the “Canonical Release Flow” / parity sections state that **`release_parity`** runs **post-publish** on Release Please + manual recovery, not only on the scheduled workflow.

### Claude's Discretion

- Exact **release-please** JSON keys for pre-1.0 bump behavior once verified against upstream schema.
- Ordering of **`release_publish`** vs **`release_parity`** when both need retries (likely **publish visibility first**, then **parity**; share env knobs).
- Whether **`confirm_creation`**-style maintainer checklist gets a one-line `mix verify.release_parity` reminder in README contributor section (only if it stays short).

### Folded Todos

None — `gsd-sdk query todo.match-phase` is unavailable in this environment; no automated todo fold.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and requirements

- `.planning/ROADMAP.md` — § Phase 24: Public Hex release & parity gates (goal, success criteria, SHIP-01..03)
- `.planning/REQUIREMENTS.md` — § Release & Hex parity (SHIP-01..03), § Out of Scope (v1.4)
- `.planning/PROJECT.md` — Current milestone, Hex parity goal, constraints

### Prior phase release machinery

- `.planning/phases/18-release-parity-gate-node-20-ci-cleanup/18-CONTEXT.md` — `workspace_clean`, `release_parity`, workflow wiring, exit codes, no escape hatch, CDN retry inheritance
- `.planning/milestones/v1.2-MILESTONE-AUDIT.md` — tag/main vs expectations narrative (historical; do not “fix” version strings for SHIP-02)

### Maintainer docs and automation config

- `docs/releasing.md` — Canonical release flow, recovery, parity gate narrative (update per **D-12**)
- `release-please-config.json` — Release Please package config (extend per **D-02**)
- `.release-please-manifest.json` — Current version pin (advances with release PR)
- `.github/workflows/release-please.yml` — Canonical publish path (extend per **D-11**)
- `.github/workflows/publish-hex.yml` — Manual recovery publish path (extend per **D-11**)
- `.github/workflows/ci.yml` — PR/`main` quality gate (keep broad `verify.*` here per **D-10**)
- `.github/workflows/verify-published-release.yml` — Scheduled/dispatch ongoing verification (existing **`release_parity`**; remains complementary)

### Implementation touchpoints

- `mix.exs` — `@version`, `@source_ref`, `docs/0`, `package`, `extras`
- `lib/mix/tasks/verify.release_parity.ex` — behavior, retries, exit codes
- `lib/mix/tasks/verify.release_publish.ex` — retry env pattern to mirror
- `test/mix/tasks/workflow_wiring_test.exs` — manifest / `@version` contract assertions (**D-07**)

### External (verify against current docs when editing Release Please)

- [Hex.pm publish / semver](https://hex.pm/docs/publish) — pre-1.0 minor vs patch expectations
- [Release Please Elixir / config](https://github.com/googleapis/release-please) — schema and bump rules

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`mix verify.workspace_clean`** / **`mix verify.release_parity`** / **`mix verify.release_publish`** — already implemented; Phase 24 mostly **wires** `release_parity` into publish workflows and updates docs/config.
- **`mix verify.phase11`** — release contract gate; already on publish jobs.

### Established patterns

- **Publish path** (`release-please.yml`): checkout **tag**, `workspace_clean` → version grep → `phase11` → Hex dry-run → publish → `release_publish`.
- **PR CI** (`ci.yml` `quality`): broad **`verify.phase*`** coverage — keep regression ownership here.

### Integration points

- **`docs/releasing.md`** “Release parity gate” section must stay consistent with actual workflow steps after **D-11** / **D-12**.
- **`release-please-config.json`** is the natural home for pre-1.0 bump policy (**D-02**).

</code_context>

<specifics>
## Specific Ideas

- Discussion + research subagents (2026-04-17) locked **0.3.1**, merge-first hygiene, narrow SHIP-02 sweep, thin publish + **post-publish `release_parity`** on both publish workflows.
- Cohesion with Scrypath vision: operational honesty, least surprise on semver, boring publish UX, no second full CI on the credential-bearing job.

</specifics>

<deferred>
## Deferred Ideas

- Optional mechanical test that README dep snippet matches `@version` / allowed `~>` (**D-09**) — low priority if time-constrained.
- Any expansion of publish-time integration (e.g. live Meilisearch) — **explicitly rejected** for Phase 24 (**D-10**).

### Reviewed Todos (not folded)

None recorded (tooling unavailable).

</deferred>

---

*Phase: 24-public-hex-release-parity-gates*
*Context gathered: 2026-04-17*
