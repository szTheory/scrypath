# Phase 116 Plan: OPSUI Asset Contract and Design Tokens

**Status:** Active
**Requirements:** ASSET-01, TOKEN-01, BRAND-01

## Tasks

- Make mounted host apps explicitly load ScrypathOps assets under `/admin/search/*`.
- Fix ecommerce Tailwind source scanning.
- Replace Phoenix-default ops theme residue with Scrypath quiet-ops tokens.
- Remove misleading undefined utility assumptions and keep unprefixed daisyUI usage intentional.

## Verification

- Focused ops shell tests for asset links, labelled controls, and brand route.
- Ecommerce layout/router test proving `/admin/search/*` has ops asset hooks.
