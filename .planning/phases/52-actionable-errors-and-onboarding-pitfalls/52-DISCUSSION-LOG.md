# Phase 52: Actionable errors and onboarding pitfalls - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`52-CONTEXT.md`**.

**Date:** 2026-04-21  
**Phase:** 52 — Actionable errors and onboarding pitfalls  
**Areas discussed:** Bounded error paths (ONBD-04); Error tuples vs raises (ONBD-04); Pitfalls doc placement (ONBD-05); `@moduledoc` / Mix task help (ONBD-06)

**Mode:** User selected **all** areas and requested parallel **subagent research** + one cohesive recommendation set (delegated locking).

---

## 1. Bounded error paths (ONBD-04)

| Approach | Description | Selected |
|----------|-------------|----------|
| Frequency × first-hour × honesty | Order: config → unknown schema → `search_many`/federation preflight → transport; defer unbounded HTTP and partial-merge contract churn | ✓ |
| README-heavy errors | Duplicate sync semantics in consumer README | |
| Guide-anchored pointers | `guides/...md#anchor` only where section exists; name env keys / tuple context | ✓ |

**User's choice:** Research-backed **D-01**–**D-03** in **`52-CONTEXT.md`** (bounded ordered list + deferrals + anchor discipline).

**Notes:** Ecosystem pattern: **strings for humans**, **tags for `case`/`with`**; other stacks (Scout, Searchkick, Prisma) reinforce **typed/stable signals + first actionable line**, avoid promising fixes the runtime cannot perform.

---

## 2. Error tuples, raises, semver

| Approach | Description | Selected |
|----------|-------------|----------|
| Keep tagged `{:error, _}` | Stable public vocabulary; improve inner messages / small context maps | ✓ |
| String-only errors | Easy to log; bad for programmatic handling | |
| Named exception for bang | Replace long-term `RuntimeError` + `inspect` for `search!` with domain exception + `message/1` | ✓ |
| Document ArgumentError vs tuple split | Narrow and document `search/3` validation paths | ✓ |

**User's choice:** **D-04**–**D-07** — tuples + documented split; named bang exception; optional `Scrypath.Error.message/1` at planner discretion.

**Notes:** Aligns with **Req** (exception message ergonomics), **Ecto** (changeset vs bang exceptions), **Oban** (simple stable job reasons).

---

## 3. Pitfalls slice (ONBD-05)

| Approach | Description | Selected |
|----------|-------------|----------|
| New `guides/common-mistakes.md` | Single canonical evidence-led guide (≥3, cap ~8) | ✓ |
| README subsection body | Violates Phase 51 thin README | |
| Golden-path “mistakes” chapter | Pollutes forward-only tutorial | |
| overview + CONTRIBUTING links | TOC and contributor discovery | ✓ |

**User's choice:** **D-08**–**D-11** — new guide + overview + CONTRIBUTING + optional README one-liner + doc-contract anchors + evidence gate.

**Notes:** Phoenix / Ecto / Oban pattern: tutorials ≠ troubleshooting; pitfalls indexed from overview and contributor paths.

---

## 4. `Scrypath` lobby + Mix help (ONBD-06)

| Approach | Description | Selected |
|----------|-------------|----------|
| Facade = product page | Narrative + golden path + sync authority; defer grammar to `Scrypath.Schema` | ✓ |
| Reflection-first moduledoc | Current shape; rejected as lobby | |
| Mix `@moduledoc` mirrors lobby | Same two-hop links on status/reconcile/retry/failed | ✓ |
| Golden path link order first | Then sync authority | ✓ |

**User's choice:** **D-12**–**D-15** — lobby moduledoc; link order; task list centered on **`scrypath.status`**.

**Notes:** Matches Hex/ExDoc culture: top module is first click after sidebar; **`@shortdoc`** for scan, **`@moduledoc`** for guardrail links.

---

## Claude's Discretion

Exception module naming; whether **`Scrypath.Error.message/1`** lands in **52**; exact **`#anchor`** strings once guides are edited.

## Deferred Ideas

See **`52-CONTEXT.md`** `<deferred>` — optional formatter helper, broad HTTP taxonomy, **`search_many`** partial-success reshaping.
