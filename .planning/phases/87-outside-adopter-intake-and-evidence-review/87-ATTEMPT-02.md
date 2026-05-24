## Provenance
Source artifact: .planning/phases/87-outside-adopter-intake-and-evidence-review/87-SUBMISSION-02.md
- submitted by: @realistic_adopter_2
- date received: 2026-05-24
- outside adopter: true

# Outside-Adopter Evidence Bundle

Please use this template to submit evidence of a failed or confusing outside-adopter integration attempt. Provide exact commands run and the first failure point. 

## Adopter Context
I'm building a multi-tenant B2B application using Phoenix LiveView. All tenants share a single `documents` index in Meilisearch. I need to ensure tenant-safe search access directly from the LiveView client (request-edge search) to minimize load on my Phoenix server, but I also need high-cardinality facets (like thousands of custom tags per tenant) to work efficiently. I'm trying to use Meilisearch tenant tokens, but the integration in Scrypath feels clunky when combined with LiveView state and facet configuration.

## Environment Matrix
- **OS / Architecture:** Ubuntu 22.04 / AMD64
- **Elixir version:** 1.16.2
- **OTP version:** 26.2.1
- **Meilisearch version:** 1.42.1
- **Database (if applicable):** PostgreSQL 16

## Scrypath Ref or Hex version
Hex package `0.3.5`

## Chosen Proof Path
Integrating the Hex-package into a Phoenix LiveView application.

## Sync Mode
`:oban`

## Ordered Commands
1. Configure `Scrypath` with a single shared index for `Document` schema.
2. Generate a tenant token for `tenant_id: 42` using Meilisearch's key generation via a custom helper.
3. Pass the tenant token to the LiveView client.
4. Execute search request with facets from the client.

## Expected versus Actual Outcome
I expected Scrypath to have a first-class primitive for generating and managing tenant scopes/tokens out of the box, and a clean way to apply them to searches. Instead, I had to manually interact with the Meilisearch API to generate the token. Furthermore, when querying high-cardinality facets with the tenant token, the response metadata was not easily mapped back to my Ecto structs or hydrated properly in the LiveView. 

## First Failure/Confusion Point
The first failure/confusion point is the lack of a defined `tenant_scope` abstraction in the library. While the research documentation mentions tenant tokens and scoped search credentials, there is no actual `Scrypath.Tenant` or explicit multi-tenant query builder. I am left manually building JWTs for Meilisearch and bypassing Scrypath's query API entirely for the request-edge LiveView search.

## Supporting Logs
```text
# Manually generating the token because Scrypath doesn't provide a helper
token = Meilisearch.TenantToken.generate(api_key, %{filter: "tenant_id = 42"})

# Fails to integrate cleanly with Scrypath's hydration when results come back to LiveView
** (FunctionClauseError) no function clause matching in Scrypath.Query.hydrate/2
```

## Maintainer Review Block
*For maintainer use only.*
- **Classification:** Class A
- **Findings:**
  - `product gap`: Lack of a first-class `tenant_scope` abstraction or explicit multi-tenant query builder, forcing adopters to manually generate Meilisearch tokens.
  - `product gap`: Hydration (`Scrypath.Query.hydrate/2`) fails with `FunctionClauseError` when dealing with custom response metadata for high-cardinality facets under tenant-scoped searches.
- **Action:** Add to evidence ledger as a Class A finding mapping to tenant-safe access.
