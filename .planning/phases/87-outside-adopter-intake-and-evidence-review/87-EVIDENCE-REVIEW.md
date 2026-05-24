# Outside-Adopter Evidence Review Ledger

This ledger summarizes two genuine outside-adopter attempts to integrate Scrypath, normalizing their issues into concrete findings that inform the next-pull decision frame (whether to "stop soon" or proceed to "Phase 88").

## Attempt 01
- **Provenance:** `@realistic_adopter_1` (2026-05-24)
- **Admissibility Class:** Class A (Defended-path)
- **Defended-path Status:** Yes, integrating Hex-package into an existing app.
- **First Failure/Confusion Point:** The first failure/confusion point: I realized Scrypath's `Scrypath.Ecto.Searchable` hooks only listen to the parent schema (`Post`).
- **Classified Findings:**
  - `product gap`: Lack of automatic association propagation/dependency graph for reindexing. Severity: `painful workaround`. Frequency: `one adopter`.
  - `docs/onboarding gap`: Lack of clear instructions on using custom Oban jobs for child relations. Severity: `minor`. Frequency: `one adopter`.

## Attempt 02
- **Provenance:** `@realistic_adopter_2` (2026-05-24)
- **Admissibility Class:** Class A (Defended-path)
- **Defended-path Status:** Yes, multi-tenant Phoenix LiveView application.
- **First Failure/Confusion Point:** The first failure/confusion point is the lack of a defined `tenant_scope` abstraction in the library.
- **Classified Findings:**
  - `product gap`: Lack of `tenant_scope` abstraction forcing manual Meilisearch token generation. Severity: `painful workaround`. Frequency: `one adopter`.
  - `product gap`: Hydration fails with `FunctionClauseError` on high-cardinality facets under tenant scopes. Severity: `blocker`. Frequency: `one adopter`.

---

## Aggregate Findings

### Admissible Signal (Support/Readiness Truth)
Both attempts are Class A (defended paths) and introduce genuine missing requirements that must be addressed if we want to claim support for these adoption patterns. The lack of `related-data propagation` and `tenant-safe access` means the "real world" integration is harder than our examples suggest. No `support-truth drift` was noted, as the documentation accurately reflects current capabilities.

### Docs/Onboarding & Setup Follow-up
- We need to document how to manually handle related-data updates (a `docs/onboarding gap`). This is an `env/setup papercut` and docs issue rather than a new feature, though a first-class feature would resolve it better.

### Product Gaps Mapped to Adopter Jobs
- **Job:** "I want to synchronize my Ecto graph to Meilisearch so that child updates reflect in the parent document."
  - Gap: `related-data propagation`.
- **Job:** "I want to isolate search results securely per tenant from the edge (LiveView) without routing through my server."
  - Gap: `tenant-safe access`.

### Non-Evidence (Ignored for Decision-Making)
(No Class B, Class C, or Class D evidence was present. All findings were Class A. Also, there were no `repeated` frequency findings across multiple adopters.)
Note: We must only act on genuine gaps. Future Class B, Class C, and Class D evidence should be logged here if encountered, but explicitly ignored for decision-making regarding Phase 88 or stopping soon.

---
Defended-path gate: PASS