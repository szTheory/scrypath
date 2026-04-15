# Phase 1: Core Contracts and API Shape - Discussion Log

**Gathered:** 2026-04-15
**Status:** Complete

## Areas Discussed

1. Schema declaration surface
2. Projection contract
3. Public module and API shape
4. Adapter boundary and escape hatches
5. Runtime configuration and dependency model

## Discussion Summary

The user asked to discuss all identified gray areas and explicitly requested research-backed recommendations using subagents, with emphasis on:

- pros and cons of each viable approach
- idiomatic Elixir, Plug, Ecto, and Phoenix design
- lessons from successful libraries in Elixir and other ecosystems
- footguns to avoid
- strong developer ergonomics and coherent architecture

The synthesized outcomes were:

### Schema declaration surface
- Preferred direction: small `use Scrypath` macro with generated reflection/helpers
- Rejected direction: heavy DSL or callback-heavy macro integration

### Projection contract
- Preferred direction: hybrid `fields: [...]` default plus explicit `search_document/1` override
- Rejected direction: fields-only or hook-only as the sole path

### Public module and API shape
- Preferred direction: one top-level `Scrypath` facade with deeper modules underneath
- Rejected direction: model-generated runtime API on user schema modules

### Adapter boundary and escape hatches
- Preferred direction: common happy path plus explicit backend-specific escape hatches
- Rejected direction: fake universal abstraction or backend-first fragmented surface

### Runtime configuration and dependency model
- Preferred direction: explicit runtime options as the canonical model, with limited convenience app config
- Rejected direction: implicit globals, mandatory integrations, or hidden supervision assumptions

## User Confirmation

After the synthesized recommendation set was presented, the user confirmed with: `sounds good`

---
*Phase: 01-core-contracts-and-api-shape*
*Discussion logged: 2026-04-15*
