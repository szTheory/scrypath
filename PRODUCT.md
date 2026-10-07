# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

- **Elixir, Phoenix, and Ecto engineers** integrate search into applications that already have schemas, contexts, and a database. They declare searchable data, choose when indexing work runs, and build the application's search experience.
- **Search owners and operators** keep that search useful after launch. Often the same engineers, they check health, investigate failed sync work or index drift, choose a safe repair, and verify the result. Platform and SRE teammates may share this job when they own the search service.
- **People using the host application's search** benefit from accurate, timely results, but Scrypath does not provide their end-user search interface.

## Product Purpose

Scrypath helps Elixir applications declare search documents from Ecto schemas, synchronize them to a search index, and query and hydrate results through app-owned contexts. It also gives teams a practical way to inspect and recover search over time. Success means teams can add search without building a separate indexing subsystem, understand what a sync result actually guarantees, and diagnose or repair drift when production state changes.

## Positioning

Scrypath is an Ecto-native search indexing and orchestration layer, not a search engine or merely an HTTP client. It keeps schema declaration, context-owned search, explicit sync choices, and operational visibility close to the Elixir application. Meilisearch is the public v1 target; the internal adapter seam is not a public promise of multi-backend support.

## Operating Context

- The application's database is the source of truth; the search index is derived data.
- App contexts own repo access and decide when successful database writes trigger search sync. Controllers and LiveViews can stay thin, and Phoenix integration is optional.
- Teams choose inline, Oban-backed, or manual sync. Accepted or durably queued work does not necessarily mean that a document is already searchable, and database and search writes are not one atomic transaction.
- Ongoing operation includes checking status and failed work, comparing declared and live index contracts, investigating drift, retrying eligible work, backfilling or reindexing, and verifying terminal backend work and resulting documents.
- Operators can reach Scrypath's supported operations through the library APIs, thin Mix tasks, and the Phoenix LiveView ScrypathOps UI. ScrypathOps is optional to mount and is not included in the Hex library package, but the maintainer expects a browser-based operator surface to be a practical need for most production adopters.
- Today, the host team operates Meilisearch and the host application, including service provisioning, capacity, backups, restores, credentials, and deployment. Scrypath provides integration, visibility, recovery workflows, and operational guidance; it does not yet automate those infrastructure jobs.
- Long-term direction: shift operational work left and reduce toil through automation as real adopter evidence shows where it helps. Preserve manual paths for work that cannot or should not be automated, and make system state, actions, and outcomes transparent. This is a north star, not a claim about current capabilities.

## Capabilities and Constraints

- Scrypath is an Elixir OSS library; the `web` platform label identifies its browser-based documentation and operator UI, not the library runtime.
- Searchable fields and index settings are declared against Ecto schemas. The common path covers search, repo-backed hydration, facets, multi-index search, synchronization, status and failed-work visibility, backfill, and managed reindexing.
- Supported v1 sync modes are `:inline`, `:oban`, and `:manual`. Their visibility and completion guarantees must remain explicit.
- Meilisearch is the supported public v1 backend target. Do not describe Scrypath as a public backend-agnostic facade or promise support for other engines without a deliberate product decision.
- Phoenix is an optional integration, not a core runtime requirement. Host applications own authorization, tenant policy, persistence, service deployment, and their end-user search interface.
- The operator UI, CLI, and library APIs should describe the same operation accurately. A task being accepted is not proof of terminal success or visible search results.
- Do not imply that Scrypath currently performs infrastructure backups, restores, capacity management, or scaling; those remain host-team responsibilities today. Future automation should be evidence-led and keep a clear manual path where needed.

## Brand Commitments

The product name is **Scrypath**. Logo assets exist under `brandbook/assets/`. The accompanying brand book was AI-generated and is exploratory rather than fully ratified; treat its detailed claims, voice, and direction as hypotheses, and preserve only what agrees with product facts and explicit maintainer guidance. Do not invent customer, adoption, or performance claims.

## Evidence on Hand

The repository contains the golden-path and integration guides, Phoenix + Meilisearch and multi-tenant e-commerce examples, the ScrypathOps UI, operational runbooks, and automated verification for the in-repository paths. These demonstrate the documented in-repo workflows; they are not independent adopter evidence. No customer testimonials or verified external-adoption claims are established here.

## Product Principles

1. Fit the existing Ecto and Phoenix application boundary and keep first adoption direct.
2. Make sync, visibility, failure, and recovery guarantees explicit instead of implying that indexing is automatic or atomic.
3. Treat ongoing operation as part of the product job. Keep UI, CLI, and API paths coherent so teams can inspect, recover, and verify search over time.
4. Shift operational toil left and automate where adopter evidence shows it is safe and useful; retain manual paths for work that cannot or should not be automated.
5. Keep current ownership and future direction clear: host teams own infrastructure today, while Scrypath's long-term direction is to automate more of the operational work without obscuring state or outcomes.
6. Prefer small dependencies and explicit seams; add abstractions only when real use demonstrates their value.
