# Phase 103: E-Commerce Host App Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-30
**Phase:** 103-e-commerce-host-app-foundation
**Areas discussed:** Tenant Isolation Strategy, Variant Modeling, Seed Data Strategy

---

## Tenant Isolation Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Isolation | Should `tenant_id` be on every model (Product, Category, Variant) for strict isolation, or only on aggregate roots? | ✓ |

**User's choice:** The user deferred to a deep-research one-shot recommendation.
**Notes:** Research concluded `tenant_id` must be on EVERY model. It makes search projection trivial and maps perfectly to the shared-index model, while Ecto `prepare_query/3` provides foolproof isolation.

---

## Variant Modeling

| Option | Description | Selected |
|--------|-------------|----------|
| Modeling | Should Variant belong directly to Product with SKU/Price overrides? What attributes are necessary? | ✓ |

**User's choice:** The user deferred to a deep-research one-shot recommendation.
**Notes:** Research concluded Product is a logical container and Variant is the strictly sellable unit. Product Schema gets base info, Variant Schema gets sku, price_cents, inventory. Search document is Product but projects Variant SKUs and min/max prices.

---

## Seed Data Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Strategy | How will we populate the testbed for manual Operator UI testing and Playwright E2E tests (Mix tasks vs fixtures)? | ✓ |

**User's choice:** The user deferred to a deep-research one-shot recommendation.
**Notes:** Research concluded using pure Elixir function factories (`*Fixtures` modules) is best. A Mix task uses them for local dev. For Playwright E2E, a hidden `POST /dev/e2e/seed` endpoint uses them inside the `Phoenix.Ecto.SQL.Sandbox` isolated transaction.

---

## Claude's Discretion

The user specifically requested Claude to "think deeply one-shot a perfect set of recommendations so i dont have to think" based on deep research across all 3 areas.

## Deferred Ideas

None