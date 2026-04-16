# Phase 7: Verification Backfill and Milestone Traceability Repair - Research

**Researched:** 2026-04-16 [VERIFIED: current session date]  
**Domain:** Milestone audit repair, verification artifact backfill, and requirements traceability for an Elixir OSS library [VERIFIED: roadmap + milestone audit]  
**Confidence:** HIGH [VERIFIED: codebase inspection + focused ExUnit run]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCMA-01 | Developer can declare a searchable Ecto schema with a small, explicit `use Scrypath` configuration. [VERIFIED: `.planning/REQUIREMENTS.md`] | Backfill Phase 1 verification from `test/scrypath/schema_test.exs`, `test/support/searchable_post.ex`, and `lib/scrypath/schema.ex`. [VERIFIED: codebase grep + file read] |
| SCMA-02 | Developer can define how a source record is projected into a search document. [VERIFIED: `.planning/REQUIREMENTS.md`] | Backfill Phase 1 verification from `test/scrypath/projection_test.exs` and `lib/scrypath/projection.ex`. [VERIFIED: codebase grep + file read] |
| SCMA-03 | Developer can inspect declared search metadata for a schema at runtime. [VERIFIED: `.planning/REQUIREMENTS.md`] | Backfill Phase 1 verification from `test/scrypath/schema_test.exs` and `lib/scrypath.ex` reflection helpers. [VERIFIED: codebase grep + file read] |
| BACK-02 | The internal architecture preserves a path to future backend support without forcing a premature public abstraction. [VERIFIED: `.planning/REQUIREMENTS.md`] | Backfill Phase 1 verification from `lib/scrypath/backend.ex`, `test/scrypath/backend_test.exs`, `README.md`, and `ARCHITECTURE.md`. [VERIFIED: codebase grep + file read] |
| SRCH-01 | Developer can execute a search against a searchable schema using a small, consistent API. [VERIFIED: `.planning/REQUIREMENTS.md`] | Backfill Phase 3 verification from `lib/scrypath.ex`, `lib/scrypath/search.ex`, and `test/scrypath/search_test.exs`. [VERIFIED: codebase grep + file read] |
| SRCH-02 | Developer can filter search results using declared filterable fields. [VERIFIED: `.planning/REQUIREMENTS.md`] | Backfill Phase 3 verification from `Scrypath.Options.validate_search_filter/2` behavior exercised in `test/scrypath/search_test.exs` and Meilisearch translation checks in `test/scrypath/meilisearch_test.exs`. [VERIFIED: file read + focused ExUnit run] |
| SRCH-03 | Developer can sort search results using declared sortable fields. [VERIFIED: `.planning/REQUIREMENTS.md`] | Backfill Phase 3 verification from `test/scrypath/search_test.exs` and `test/scrypath/meilisearch_test.exs`. [VERIFIED: file read + focused ExUnit run] |
| SRCH-04 | Developer can paginate search results. [VERIFIED: `.planning/REQUIREMENTS.md`] | Backfill Phase 3 verification from `lib/scrypath/query.ex`, `lib/scrypath/search_result.ex`, and pagination tests in `test/scrypath/search_test.exs`. [VERIFIED: file read + focused ExUnit run] |
| SRCH-05 | Developer can access raw backend hit metadata when needed. [VERIFIED: `.planning/REQUIREMENTS.md`] | Backfill Phase 3 verification from `lib/scrypath/search_result.ex` and `test/scrypath/search_test.exs`. [VERIFIED: file read + focused ExUnit run] |
| SRCH-06 | Developer can hydrate search hits back into Ecto records. [VERIFIED: `.planning/REQUIREMENTS.md`] | Backfill Phase 3 verification from `lib/scrypath/hydration.ex`, `test/scrypath/hydration_test.exs`, and `test/scrypath/search_test.exs`. [VERIFIED: file read + focused ExUnit run] |
</phase_requirements>

## Summary

The codebase already implements the missing Phase 1 and Phase 3 behaviors; the audit failure is primarily an evidence problem, not an implementation problem. [VERIFIED: `.planning/v1.0-MILESTONE-AUDIT.md` + source/tests + focused ExUnit run] Phase 1 and Phase 3 both have plans and summaries on disk, but neither phase has a `VERIFICATION.md` artifact, and the milestone audit explicitly marks their requirement sets as orphaned for that reason. [VERIFIED: phase file listing + `.planning/v1.0-MILESTONE-AUDIT.md`]

The traceability problem is broader than only adding two missing verification files. [VERIFIED: milestone audit + planning file read] `.planning/REQUIREMENTS.md` still leaves all Phase 1, Phase 3, and Phase 5 requirement rows unchecked or pending, while `.planning/ROADMAP.md` still reports `Total phases: 6` even though it now contains a Phase 7 section, and `.planning/STATE.md` still reports `current_phase: 06` with `total_phases: 6`. [VERIFIED: `.planning/REQUIREMENTS.md` + `.planning/ROADMAP.md` + `.planning/STATE.md`]

The plan should therefore treat this as an artifact-repair phase with a strict order: first recreate Phase 1 and Phase 3 verification reports from current code and focused test runs, then repair requirements and roadmap bookkeeping to point back to the original shipped phases rather than pretending Phase 7 implemented those requirements, and finally refresh milestone-facing evidence so audit output distinguishes missing history from real runtime risk. [VERIFIED: milestone audit recommendation + existing verification report patterns]

**Primary recommendation:** Write `01-VERIFICATION.md` and `03-VERIFICATION.md` first, using the Phase 2/5/6 verification format as the template, then update `REQUIREMENTS.md`, `ROADMAP.md`, and likely `STATE.md` to reflect the already-shipped v1.0 state accurately. [VERIFIED: existing verification files + milestone audit + planning file drift]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Phase 1 evidence backfill | Planning artifacts | Test/runtime evidence | Verification files are written under `.planning/phases/...`, but their truth comes from live source and tests. [VERIFIED: repo layout + existing verification files] |
| Phase 3 evidence backfill | Planning artifacts | Test/runtime evidence | Same pattern as other verified phases: docs artifact backed by code references and command results. [VERIFIED: `02-VERIFICATION.md`, `05-VERIFICATION.md`, `06-VERIFICATION.md`] |
| Requirement closure repair | Planning artifacts | — | Requirement checkboxes and traceability rows live only in `.planning/REQUIREMENTS.md`. [VERIFIED: `.planning/REQUIREMENTS.md`] |
| Roadmap bookkeeping repair | Planning artifacts | State metadata | Phase count and milestone bookkeeping are declared in `.planning/ROADMAP.md` and partially echoed in `.planning/STATE.md`. [VERIFIED: `.planning/ROADMAP.md` + `.planning/STATE.md`] |
| Audit gap triage | Planning artifacts | Code/test evidence | The milestone audit uses verification presence and requirements traceability to score the milestone. [VERIFIED: `.planning/v1.0-MILESTONE-AUDIT.md`] |

## Standard Stack

### Core
| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `~> 1.17` repo floor; local `1.19.5` [VERIFIED: `mix.exs` + `elixir --version`] | Primary implementation and test runtime. [VERIFIED: `mix.exs`] | All shipped verification evidence is already expressed as ExUnit tests and Elixir source references. [VERIFIED: repo file listing] |
| Mix | local `1.19.5` [VERIFIED: `mix --version`] | Runs focused verification commands. [VERIFIED: environment audit] | Existing verification reports cite `mix test` and `mix docs` command outputs, so Phase 7 should reuse the same mechanism. [VERIFIED: `02-VERIFICATION.md`, `05-VERIFICATION.md`, `06-VERIFICATION.md`] |
| ExUnit | bundled with Elixir/Mix [ASSUMED] | Repo-native test harness for proof gathering. [VERIFIED: test files + `mix test` output] | The missing Phase 1 and 3 evidence is already covered by passing targeted ExUnit tests. [VERIFIED: focused ExUnit run] |
| Markdown verification reports under `.planning/phases/*/*-VERIFICATION.md` | repo convention [VERIFIED: repo file listing] | Canonical artifact shape for milestone evidence. [VERIFIED: existing verification files] | Milestone audit treats verification artifacts as the source of truth for requirement satisfaction. [VERIFIED: `.planning/v1.0-MILESTONE-AUDIT.md`] |

### Supporting
| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `rg` / file reads | local shell tools [VERIFIED: current session usage] | Cross-check artifact presence, stale headings, and requirement mappings. [VERIFIED: current session commands] | Use for bookkeeping drift and file-presence checks. [VERIFIED: current session commands] |
| Existing phase verification format | repo convention [VERIFIED: `02-VERIFICATION.md`, `05-VERIFICATION.md`, `06-VERIFICATION.md`] | Template for new Phase 1 and 3 reports. [VERIFIED: file read] | Use instead of inventing a new evidence schema. [VERIFIED: repo file read] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Repo-native verification reports | Ad hoc audit notes in Phase 7 only | This would not satisfy the milestone audit, which explicitly keys off per-phase verification artifacts. [VERIFIED: `.planning/v1.0-MILESTONE-AUDIT.md`] |
| Focused `mix test` commands | Narrative-only backfill from summaries | Summaries are already present and were insufficient for audit closure. [VERIFIED: phase summaries + milestone audit] |
| Restoring original phase ownership in `REQUIREMENTS.md` | Marking orphaned requirements as "done by Phase 7" | That would misstate shipped history because the code landed in Phases 1 and 3, not Phase 7. [VERIFIED: roadmap phase definitions + milestone audit gap descriptions] |

**Installation:**
```bash
mix deps.get
```

**Version verification:** The repo declares Elixir `~> 1.17` and is currently runnable on Elixir/Mix `1.19.5` in this environment. [VERIFIED: `mix.exs` + `elixir --version` + `mix --version`]

## Architecture Patterns

### System Architecture Diagram
```text
Current source/tests
    |
    v
Focused evidence collection (`mix test`, file references)
    |
    +--> Phase 1 verification report (`01-VERIFICATION.md`)
    |
    +--> Phase 3 verification report (`03-VERIFICATION.md`)
              |
              v
Requirement status repair (`REQUIREMENTS.md`)
              |
              v
Roadmap/state bookkeeping repair (`ROADMAP.md`, likely `STATE.md`)
              |
              v
Milestone audit rerun / audit evidence refresh
```

### Recommended Project Structure
```text
.planning/
├── REQUIREMENTS.md   # Checkbox truth and requirement-to-phase traceability
├── ROADMAP.md        # Milestone phase inventory and success criteria
├── STATE.md          # Current milestone/workflow bookkeeping that should not contradict roadmap
├── v1.0-MILESTONE-AUDIT.md  # Audit input/output for final closure
└── phases/
    ├── 01-core-contracts-and-api-shape/
    │   └── 01-VERIFICATION.md
    └── 03-search-query-api-and-hydration/
        └── 03-VERIFICATION.md
```

### Pattern 1: Backfill Verification From Live Artifacts
**What:** Build the missing verification files from current source, tests, and focused command results, not from old summaries. [VERIFIED: milestone audit + existing verification files]  
**When to use:** First, before changing any requirement status rows. [VERIFIED: milestone audit recommendation]  
**Example:**
```text
mix test test/scrypath/schema_test.exs \
         test/scrypath/projection_test.exs \
         test/scrypath/backend_test.exs \
         test/scrypath/search_test.exs \
         test/scrypath/hydration_test.exs \
         test/scrypath/meilisearch_test.exs
```
Source: current repo verification workflow and focused run result (`41 tests, 0 failures`). [VERIFIED: focused ExUnit run]

### Pattern 2: Preserve Historical Ownership In Traceability
**What:** Close `SCMA-*`, `BACK-02`, and `SRCH-*` under their original phases once verification exists, while treating Phase 7 as repair work rather than feature delivery. [VERIFIED: roadmap phase definitions + milestone audit]  
**When to use:** When updating `REQUIREMENTS.md` and any roadmap trace tables. [VERIFIED: `.planning/REQUIREMENTS.md` + `.planning/ROADMAP.md`]  
**Example:**
```text
SCMA-01 | Phase 1 | Complete
SRCH-01 | Phase 3 | Complete
```
Source: original phase requirement ownership in `.planning/ROADMAP.md`. [VERIFIED: file read]

### Pattern 3: Separate Runtime Gaps From Evidence Gaps
**What:** Keep milestone outputs explicit about what is actually broken in runtime behavior versus what was only missing verification history. [VERIFIED: Phase 7 goal + milestone audit summary]  
**When to use:** In the repaired milestone audit and any phase review/update notes. [VERIFIED: `.planning/v1.0-MILESTONE-AUDIT.md`]  
**Example:**
```text
Implemented in code and passing tests -> evidence gap only
No code/test support or failing flow     -> runtime gap
```
Source: milestone audit distinguishes orphaned requirements from tech-debt advisories and intact integration flows. [VERIFIED: `.planning/v1.0-MILESTONE-AUDIT.md`]

### Anti-Patterns to Avoid
- **Using summaries as proof:** The milestone audit already rejected summaries without verification artifacts. [VERIFIED: `.planning/v1.0-MILESTONE-AUDIT.md`]
- **Reassigning shipped requirements to Phase 7:** This repairs history; it does not move feature ownership. [VERIFIED: roadmap + requirements traceability drift]
- **Updating checkboxes before creating evidence:** That recreates the same trust problem the audit flagged. [VERIFIED: milestone audit]
- **Ignoring `STATE.md`:** `STATE.md` still says Phase 06 is current and total phases are 6, which conflicts with the roadmap now containing Phase 7. [VERIFIED: `.planning/STATE.md` + `.planning/ROADMAP.md`] |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Verification format | A new one-off Phase 7 note format | Existing `*-VERIFICATION.md` structure from Phases 2, 5, and 6 | The audit already recognizes that structure as canonical evidence. [VERIFIED: existing verification files + milestone audit] |
| Evidence generation | Manual prose disconnected from tests | Focused `mix test` commands plus code references | Current tests already prove the behaviors and are reproducible. [VERIFIED: focused ExUnit run + file read] |
| Requirement traceability repair | New parallel tracking file | `.planning/REQUIREMENTS.md` traceability table and checkboxes | That is the file the audit flags as stale. [VERIFIED: `.planning/v1.0-MILESTONE-AUDIT.md`] |

**Key insight:** The shortest path is to reuse the repo's existing evidence machinery, because the gap is missing provenance on disk, not missing product behavior. [VERIFIED: milestone audit + focused ExUnit run]

## Common Pitfalls

### Pitfall 1: Closing requirements before the per-phase verification files exist
**What goes wrong:** The repo appears green in bookkeeping but still fails audit. [VERIFIED: milestone audit rules]  
**Why it happens:** The audit treats requirements without any verification artifact as orphaned. [VERIFIED: `.planning/v1.0-MILESTONE-AUDIT.md`]  
**How to avoid:** Create `01-VERIFICATION.md` and `03-VERIFICATION.md` before editing requirement status rows. [VERIFIED: milestone audit recommendation]  
**Warning signs:** Requirement row says `Complete`, but no matching phase verification file exists on disk. [VERIFIED: current repo state]

### Pitfall 2: Treating Phase 7 as a feature-delivery phase
**What goes wrong:** Requirement ownership gets rewritten to Phase 7, which obscures when the code actually shipped. [VERIFIED: roadmap + requirements drift]  
**Why it happens:** The orphaned requirements are currently mapped to Phase 7 in `.planning/REQUIREMENTS.md`. [VERIFIED: `.planning/REQUIREMENTS.md`]  
**How to avoid:** Keep Phase 7 scoped to repair artifacts and bookkeeping only. [VERIFIED: Phase 7 roadmap goal]  
**Warning signs:** Traceability rows for `SCMA-*` or `SRCH-*` still point to Phase 7 after verification backfill. [VERIFIED: current repo state]

### Pitfall 3: Repairing only `REQUIREMENTS.md`
**What goes wrong:** Milestone metadata remains self-contradictory. [VERIFIED: current repo state]  
**Why it happens:** `ROADMAP.md` and `STATE.md` both still report six phases while Phase 7 now exists. [VERIFIED: `.planning/ROADMAP.md` + `.planning/STATE.md`]  
**How to avoid:** Audit all milestone-facing planning files together after the verification docs are added. [VERIFIED: current file drift]  
**Warning signs:** `ROADMAP.md` says `Total phases: 6` or `STATE.md` says `current_phase: 06` after Phase 7 planning artifacts exist. [VERIFIED: current repo state]

## Code Examples

Verified repo patterns:

### Phase 1 Evidence Anchor
```elixir
assert SearchablePost.__scrypath__(:config) == %{
  fields: [:title, :body],
  filterable: [:status],
  sortable: [:inserted_at],
  settings: %{},
  document_id: :id,
  document_source: :fields,
  index_prefix: nil,
  backend: nil
}
```
Source: `test/scrypath/schema_test.exs`. [VERIFIED: file read]

### Phase 3 Evidence Anchor
```elixir
assert {:ok,
        %SearchResult{
          records: [%QueryablePost{id: 2}, %QueryablePost{id: 1}],
          missing_ids: [3]
        }} =
         Scrypath.search(QueryablePost, "ecto",
           backend: HydrationBackend,
           repo: FakeRepo
         )
```
Source: `test/scrypath/search_test.exs`. [VERIFIED: file read]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Summaries as indirect proof of completed work | Per-phase `VERIFICATION.md` artifacts with truths, artifacts, spot-checks, and requirements coverage | Present by at least Phases 2, 5, and 6. [VERIFIED: repo file listing] | Milestone audit can only close requirements backed by verification artifacts. [VERIFIED: milestone audit] |
| Traceability rows left stale after implementation | Traceability repaired to original shipping phase after verification exists | Needed now in Phase 7. [VERIFIED: current drift] | Archival stops failing on bookkeeping drift. [VERIFIED: Phase 7 success criteria + milestone audit] |

**Deprecated/outdated:**
- `SCMA-*` and `SRCH-*` mapped as `Phase 7 / Pending` in `REQUIREMENTS.md` is outdated bookkeeping, not an accurate shipping history. [VERIFIED: `.planning/REQUIREMENTS.md` + `.planning/ROADMAP.md` + milestone audit]
- `ROADMAP.md` header `Total phases: 6` is outdated now that the file contains Phase 7. [VERIFIED: `.planning/ROADMAP.md`] 

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | ExUnit is treated as part of the default Elixir/Mix toolchain rather than a separately versioned dependency in this repo. [ASSUMED] | Standard Stack | Low; affects wording only, not the plan. |

## Open Questions (RESOLVED)

1. **Should `STATE.md` be repaired in this phase even though the success criteria only name `REQUIREMENTS.md` and `ROADMAP.md`?**
   - What we know: `STATE.md` still says `current_phase: 06` and `total_phases: 6`, which now contradicts the roadmap. [VERIFIED: `.planning/STATE.md` + `.planning/ROADMAP.md`]
   - Resolution: **Yes.** `STATE.md` should be repaired in Phase 7 because it is milestone-facing workflow metadata and currently contradicts the roadmap after the Phase 7 insertion. Keeping it stale would preserve the same bookkeeping trust problem the phase is meant to repair. [RESOLVED: 2026-04-16 from current repo drift + Phase 7 goal]

2. **Should Phase 6 review warnings be folded into this repair phase?**
   - What we know: The milestone audit marks them as tech debt, not as the blocker for audit closure. [VERIFIED: `.planning/v1.0-MILESTONE-AUDIT.md`]
   - Resolution: **No, not in the critical path.** Keep the Phase 6 warnings out of Phase 7 unless a later archival workflow explicitly requires warning-free review state, because they are advisory and distinct from the evidence and traceability repair needed to close the current milestone audit failure. [RESOLVED: 2026-04-16 from milestone audit recommendation]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Focused verification commands and any planning-file validation scripts | ✓ [VERIFIED: environment audit] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Mix | Running `mix test` evidence commands | ✓ [VERIFIED: environment audit] | `1.19.5` [VERIFIED: `mix --version`] | — |

**Missing dependencies with no fallback:**
- None identified for planning or execution of this phase. [VERIFIED: environment audit]

**Missing dependencies with fallback:**
- None. [VERIFIED: environment audit]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir/Mix [VERIFIED: `mix.exs` + `mix test` output] |
| Config file | `test/test_helper.exs` [VERIFIED: repo file listing] |
| Quick run command | `mix test test/scrypath/schema_test.exs test/scrypath/projection_test.exs test/scrypath/backend_test.exs test/scrypath/search_test.exs test/scrypath/hydration_test.exs test/scrypath/meilisearch_test.exs` [VERIFIED: focused ExUnit run] |
| Full suite command | `mix test` [VERIFIED: repo convention] |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCMA-01 | searchable schema declaration via `use Scrypath` | unit | `mix test test/scrypath/schema_test.exs` | ✅ [VERIFIED: file listing] |
| SCMA-02 | projection contract and custom hook precedence | unit | `mix test test/scrypath/projection_test.exs` | ✅ [VERIFIED: file listing] |
| SCMA-03 | runtime metadata reflection helpers | unit | `mix test test/scrypath/schema_test.exs` | ✅ [VERIFIED: file listing] |
| BACK-02 | internal backend seam remains narrow and behavior-based | unit | `mix test test/scrypath/backend_test.exs` | ✅ [VERIFIED: file listing] |
| SRCH-01 | common search API | unit | `mix test test/scrypath/search_test.exs` | ✅ [VERIFIED: file listing] |
| SRCH-02 | declared filter validation and translation | unit | `mix test test/scrypath/search_test.exs test/scrypath/meilisearch_test.exs` | ✅ [VERIFIED: file listing] |
| SRCH-03 | declared sort validation and translation | unit | `mix test test/scrypath/search_test.exs test/scrypath/meilisearch_test.exs` | ✅ [VERIFIED: file listing] |
| SRCH-04 | pagination normalization and result page metadata | unit | `mix test test/scrypath/search_test.exs` | ✅ [VERIFIED: file listing] |
| SRCH-05 | raw-hit access through stable result envelope | unit | `mix test test/scrypath/search_test.exs` | ✅ [VERIFIED: file listing] |
| SRCH-06 | explicit repo-backed hydration with missing-id visibility | unit | `mix test test/scrypath/search_test.exs test/scrypath/hydration_test.exs` | ✅ [VERIFIED: file listing] |

### Sampling Rate
- **Per task commit:** run the quick command above after each verification-document or bookkeeping edit that changes evidence claims. [VERIFIED: focused ExUnit run + existing verification practice]
- **Per wave merge:** `mix test`. [VERIFIED: repo convention]
- **Phase gate:** `mix test` plus artifact-presence check for `01-VERIFICATION.md` and `03-VERIFICATION.md`, followed by requirements/roadmap consistency review. [VERIFIED: milestone audit gaps]

### Wave 0 Gaps
- None in test infrastructure; the gap is missing verification documents and stale planning metadata, not missing tests. [VERIFIED: focused ExUnit run + repo file listing]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope] | — |
| V3 Session Management | no [VERIFIED: phase scope] | — |
| V4 Access Control | no [VERIFIED: phase scope] | — |
| V5 Input Validation | yes [VERIFIED: shipped search/schema option validation] | `Scrypath.Options` validation on schema and search inputs. [VERIFIED: `lib/scrypath/options.ex` + tests] |
| V6 Cryptography | no [VERIFIED: phase scope] | — |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Raw backend filter/string leakage onto the common API | Tampering | Validate `filter:` and `sort:` against declared metadata and reject raw strings/lists on the common path. [VERIFIED: `test/scrypath/search_test.exs`] |
| Silent hydration drift hiding stale search hits | Repudiation | Surface `missing_ids` in `SearchResult` instead of dropping missing rows silently. [VERIFIED: `lib/scrypath/search_result.ex` + `test/scrypath/search_test.exs`] |
| Audit evidence spoofing through unchecked bookkeeping edits | Repudiation | Tie every requirement closure to a concrete verification file and reproducible `mix test` commands. [VERIFIED: milestone audit rules + existing verification format] |

## Sources

### Primary (HIGH confidence)
- `.planning/v1.0-MILESTONE-AUDIT.md` - exact audit failure mode, orphaned requirements, and repair recommendation. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - current requirement checkbox and traceability drift. [VERIFIED: file read]
- `.planning/ROADMAP.md` - phase ownership, success criteria, and stale total-phase header. [VERIFIED: file read]
- `.planning/STATE.md` - current workflow metadata drift relative to the roadmap. [VERIFIED: file read]
- `lib/scrypath/schema.ex`, `lib/scrypath/projection.ex`, `lib/scrypath/backend.ex`, `lib/scrypath/search.ex`, `lib/scrypath/query.ex`, `lib/scrypath/search_result.ex`, `lib/scrypath/hydration.ex`, `lib/scrypath/meilisearch.ex` - live implementation surface for Phase 1 and Phase 3 claims. [VERIFIED: file read]
- `test/scrypath/schema_test.exs`, `test/scrypath/projection_test.exs`, `test/scrypath/backend_test.exs`, `test/scrypath/search_test.exs`, `test/scrypath/hydration_test.exs`, `test/scrypath/meilisearch_test.exs` - current behavioral proof points. [VERIFIED: file read]
- Focused verification run: `mix test test/scrypath/schema_test.exs test/scrypath/projection_test.exs test/scrypath/backend_test.exs test/scrypath/search_test.exs test/scrypath/hydration_test.exs test/scrypath/meilisearch_test.exs` -> `41 tests, 0 failures`. [VERIFIED: current session]
- Existing verification artifacts: `02-VERIFICATION.md`, `05-VERIFICATION.md`, `06-VERIFICATION.md`. [VERIFIED: file read]

### Secondary (MEDIUM confidence)
- None. [VERIFIED: research scope stayed inside repo and local environment]

### Tertiary (LOW confidence)
- None. [VERIFIED: all substantive claims were grounded in repo files or current commands]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - phase work reuses repo-native Elixir/Mix/ExUnit and established verification artifact patterns. [VERIFIED: `mix.exs` + file listing + current commands]
- Architecture: HIGH - the milestone audit and current planning files explicitly define the missing evidence and stale bookkeeping boundaries. [VERIFIED: audit + roadmap + requirements + state]
- Pitfalls: HIGH - each pitfall is already visible in the current failing milestone state. [VERIFIED: current repo state]

**Research date:** 2026-04-16 [VERIFIED: current session date]  
**Valid until:** 2026-05-16 [INFERENCE from repo-stable planning domain]
