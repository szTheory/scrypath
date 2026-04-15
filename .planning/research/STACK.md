# Stack Research: Scrypath

**Research date:** 2026-04-15
**Context:** Greenfield Elixir OSS library for Ecto-native search indexing and Phoenix-friendly search orchestration

## Recommended Stack

### Core library

- **Elixir**: support floor `1.17`, target current stable through `1.19`
- **OTP**: support floor `26`, test through `28`
- **Ecto**: primary integration surface
- **Telemetry**: first-class instrumentation from day one

### Search backend for v1

- **Meilisearch** as the public backend target for v1

Rationale:
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

The right long-term move is to keep backend-specific power available without pretending search engines are interchangeable. Internal adapter seams are worth building early. Public backend parity is not.
