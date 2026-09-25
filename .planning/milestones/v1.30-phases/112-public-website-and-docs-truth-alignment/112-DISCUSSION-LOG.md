# Phase 112: Public Website and Docs Truth Alignment - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-01
**Phase:** 112-Public Website and Docs Truth Alignment
**Areas discussed:** Public claim boundary and copy vocabulary, Website route-map depth versus second-docs risk, Scope-guard and feature-lane reopen policy placement, Verification shape for public truth alignment

---

## Public Claim Boundary and Copy Vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| Strict canonical descriptor everywhere | Maximum consistency and lowest scope drift, but can feel repetitive and flat. | |
| Softer marketing copy plus disclaimers | More emotional top-level copy, but high risk that disclaimers are skipped and claims drift. | |
| Page-specific positioning within a fixed claim envelope | Canonical first mention everywhere, with page-specific supporting copy inside controlled vocabulary. | ✓ |

**User's choice:** Discuss all areas with subagent-backed research and one cohesive recommendation set.
**Notes:** Advisor research recommended the fixed claim envelope as the strongest balance. It preserves exact OSS library positioning while letting homepage, README, guide, and Evaluate copy serve different jobs without changing the product claim.

---

## Website Route-Map Depth Versus Second-Docs Risk

| Option | Description | Selected |
|--------|-------------|----------|
| Ultra-thin link directory | Lowest drift risk, but weak onboarding and evaluator guidance. | |
| Curated journey pages with short summaries | Route map plus what/when blurbs and deep links to canonical docs. | ✓ |
| Rich standalone website docs | Polished in-site reading experience, but highest drift and duplication risk. | |

**User's choice:** Discuss all areas with subagent-backed research and one cohesive recommendation set.
**Notes:** Advisor research recommended curated journey pages. This keeps `website/` useful as a front door while preserving README, guides, examples, Hex, and GitHub as the durable authorities.

---

## Scope-Guard and Feature-Lane Reopen Policy Placement

| Option | Description | Selected |
|--------|-------------|----------|
| Homepage/evaluate explicit non-fit blocks as primary policy location | Fast expectation-setting, but can feel defensive and drift from canonical docs. | |
| README/guides as canonical-only policy location | Strong versioned OSS authority, but too late for website-first evaluators. | |
| Dedicated scope/roadmap policy doc linked from website, README, and guides | One canonical policy authority plus concise public fit/non-fit routing. | ✓ |

**User's choice:** Discuss all areas with subagent-backed research and one cohesive recommendation set.
**Notes:** Advisor research recommended adding one canonical policy guide, likely `guides/scope-and-reopen-policy.md`, with short website and README links. This preserves evidence-gated reopen rules without turning the homepage into a policy wall.

---

## Verification Shape for Public Truth Alignment

| Option | Description | Selected |
|--------|-------------|----------|
| Focused `phase112_contract_test.exs` plus `mix verify.phase112` | Matches Phase 110/111 patterns and keeps proof service-free and targeted. | ✓ |
| Broad docs lint / negative-token scanner | Wider coverage, but higher false positives and exception drift. | |
| Manual checklist in docs only | Lowest overhead, but no automated drift prevention. | |

**User's choice:** Discuss all areas with subagent-backed research and one cohesive recommendation set.
**Notes:** Advisor research recommended the focused contract-test path. The test should assert required public route/claim tokens and refute misleading hosted, AI, magic callback, public multi-backend v1, and immediate async visibility claims on targeted public surfaces.

---

## the agent's Discretion

- Exact wording, file organization, and contract-test token choices are left to the planner/executor.
- Planner may decide whether `mix verify.phase112` remains standalone or is also wired into an existing lean truth gate.
- Planner may make bounded copy edits to current website pages where needed, but broad website redesign is out of scope.

## Deferred Ideas

- Rich standalone website docs.
- Broad repo-wide public-claim scanner.
- Website visual redesign or new marketing information architecture.
- New product breadth: hosted search, AI/vector/hybrid positioning, autocomplete/suggestions as a first-class product surface, public multi-backend v1 support, magic callback runtime, and new public runtime APIs.
