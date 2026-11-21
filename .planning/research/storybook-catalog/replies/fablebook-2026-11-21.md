# Reply from the fablebook session (2026-11-21)

**Provenance.** Pasted by the maintainer from the fablebook project's own LLM session (answer to prompt 3). The session says it read fablebook's checkout, history and the exact-pinned local brand caches, did not inspect Scrypath, and changed nothing. This is a digest; the per-adopter search-block JSON is summarized (field configuration plus rules), and its real fixture ids are in the pinned record files, not copied here. Labels: VERIFIED (read by that session) and PROPOSED (design suggestion, not a fablebook feature). Not re-verified by the Scrypath session.

## Reuse rights (contests the brandbook reply)

- VERIFIED: the six brand repos are pinned at Logistify 6189eb2, Chatly 111b063, Clinicly 61aac2b, Shopadelic 8f9d70e, Finanza 9748d49, Classwell 7b2c843 (`brand_sources.lock.json:5-10`). No repository-level LICENSE, COPYING or NOTICE exists in them. Their mapping guides say the license for records, tokens, books and brand data is undecided and that the files do not grant redistribution outside fablebook's demo (e.g. Logistify guide `FABLEBOOK-MAPPING-GUIDE.md:142`). Font licenses are separate.
- VERIFIED: fablebook's owner authorized only a minimal, cited **Logistify** subset for a reviewed fablebook demo PR (`INT-20261121-01:24`), **not general reuse by Scrypath**. Omitting logos does not resolve the records, copy or token rights.
- PROPOSED: do not copy the 8 to 12 records per entity yet. Get an explicit written grant from each brand source's rightsholder. Recommended terms: CC BY 4.0 for named records, text and token data (attribute repository, tag, commit and changed files); license images, fonts and marks separately; no implied endorsement. The rightsholder decides what to license; the Scrypath maintainer decides whether to include it.
- **Conflict.** The brandbook reply reports an owner statement (2026-11-21) allowing reuse of the demo companies as scenarios in the OSS libraries. The fablebook session finds only the narrower Logistify authorization. Both sessions say the owner decides. The maintainer is the owner of all these repos, so this is a one-line decision for them; see the milestone context.

## Other adopters and corrections

- VERIFIED: the six pins are the six adopters. `docs/research/TWINS.md:9-13` lists five showcase twins (Chatly, Logistify, Finanza, Shopadelic, Clinicly); **Classwell is pinned but absent from that list**, and its `BRAND.md:5` says the edition has no application pages, records or flows while its mapping guide (`:21,:36`) describes records, cases and flows: a source-handoff inconsistency, not a settled sixth twin. No pinned job-board adopter exists; "Doxosaurus Rex" was an old brainstorming name for a docs/knowledge-base idea, never delivered; Shopadelic is a small-shop admin and merchant storefront, not a multi-vendor marketplace; mailglass, accrue, Scrypath and Threadline are real dogfood targets, not twins.
- **Correction to earlier Scrypath notes:** "10 to 44 rows per collection" is not true of every collection. The pinned records hold 61 Shopadelic cases, 84 Clinicly cases, 60 Classwell cases, 35 Logistify and 27 Chatly cases (`FABLEBOOK-MAPPING-GUIDE.md:36-37`). Each pinned tree has `brand.json`, `tokens.json`, `records/<brand>/<brand>-records.json` and `check-records.mjs`; that confirms presence only, not that the session ran all six validators. Chatly's two records JSON copies are byte-identical.
- VERIFIED: Logistify's hand-drawn pictures have three recorded conflicts with its records (the records are the data). Finanza's guide says its numbers are not claimed realistic and lists missing banking concepts (holds, fees, split transactions, many currencies).

## Search blocks (PROPOSED, expected hits are test targets, not ranking guarantees)

The records describe entities, cases and flows, not Meilisearch settings; fablebook's import/export contract is not built (Chatly records README:112); its command-K decision is catalog navigation, not an adopter's index (ADR 0013:9).

| Adopter | searchable | filterable | sortable | never index |
|---|---|---|---|---|
| Logistify | id, routeText, status, toCity, fromDepotId, driverId, pallets, weightKg | shipperId, fromDepotId, driverId, status | statusSince, deliveryWindow.start, weightKg | recipients.name/address, users.name, credentials, session tokens, API keys |
| Shopadelic | product id/name/description/publication, order number/status | storeId, publication, stockStatus, currency, order.status | priceCents, stock, placedAt | shopper name/email, addresses, payments, credentials, tokens |
| Chatly | message id/text, conversation name | conversationId, senderId, delivery | sentAt | people name/memberIds, contact details, credentials, reset codes, tokens |
| Clinicly | ref, status, clinicId, clinicianId | clinicId, clinicianId, status | start | patients.*, visit-note text, reminders, phone, email, credentials, recovery codes, tokens |

Ten queries, five zero-result queries (each with a reason) and three typo cases per adopter use real fixture ids (for example `LGX-0417-DE`, `prd-0001`, `m-0002`, `apt-0042`). Rules worth keeping: do not fuzzy-correct identifiers (`LGX-0417-DX` returns nothing); allow typo correction only inside the already-authorized clinic scope; Chatly queries must always be filtered by current conversation membership.

## Tenant keys, deletion, staleness

- PROPOSED tenant/scope filters: Logistify shipperId plus fromDepotId; Shopadelic storeId (merchantId if the model grows); Chatly conversationId as a per-conversation ACL boundary (not a global tenant); Clinicly clinicId.
- VERIFIED: **no fixture has a soft-delete or tombstone field.** Shopadelic Archived is a publication status, Clinicly Canceled is an appointment status; do not reinterpret them as deletion. The soft-deleted rows in the brandbook reply are Proposed; add a distinct deletion event for sync and removal.
- PROPOSED: the fixtures have no monotonic version field; business timestamps (events[].at, statusSince, stock entries, sentAt, lastMessageId, unread counts, appointment start/status, note writtenAt) are stale-update candidates, but add an explicit version for sync ordering instead of trusting them.

## Bulk generator

VERIFIED: fablebook has an N-scenario load generator for catalog rendering (ADR 0020:24), not a high-volume twin-record generator, and no plan for one. PROPOSED invariants: the same seed gives byte-stable ids, ordering and references; ids never reused; foreign keys resolve; timestamps monotonic where the workflow needs it and keep explicit offsets; closed enums; `null` is missing and `[]` is known-empty; tenant and ACL boundaries never mix; expansions preserve real case classes, not random permutations.

## Proposed sync failures (four per adopter, operational scale)

Logistify: a 40,000-shipment import rejects 312 rows (unknown status or missing shipperId); a removed shipper leaves 1,800 documents searchable; a replay of 2,400 delayed events lets an old "In transit" overwrite a newer "Failed"; an alias switches to a reindex missing 3% of fields. Shopadelic: a 25,000-product import rejects 140 prices serialized as formatted strings; a deleted store leaves 900 documents queryable; reordered stock updates make an out-of-stock product look available; an index swap publishes products before stock projections finish (600 stale listings). Chatly: a 500,000-message backfill rejects 860 records; a removed member can still find 1,200 messages because ACL cleanup lagged; reconnect replay applies 30,000 messages out of order; a partial reindex after a CJK configuration change leaves Japanese messages missing from the active alias. Clinicly: 67 of 80,000 appointments with malformed UTC offsets; a removed clinic leaves 500 documents visible; a delayed "Scheduled" overwrites a newer "Canceled"; a notes-removal reindex fails before the alias swap and leaves old note documents searchable.

**Scrypath realism check required (recorded by the Scrypath session):** the out-of-order replay failures (an old event overwriting a newer status) presuppose that the sync writes the event's payload. Scrypath's Oban sync loads the current record at job time (library change merged as PR 108, 2026-10), so check each such story against what Scrypath can actually produce before it ships; the same applies to invented error wording against real Meilisearch behavior (see the brandbook digest).

## phoenix_storybook rejection

VERIFIED: fablebook's research records older-version security issues, host CSS and hook interference, complex-attr and slot string round-tripping, private LiveView API upgrade risk and dev/CI friction (`LESSONS-LEARNED.md:26,32,33,35`); ADR 0003 chose a same-origin iframe using the host pipeline (`ADR 0003:13`). **No fablebook benchmark of phoenix_storybook exists**: the "6s vs 58s" and "388 kB vs 14.3 MB" numbers are Ladle versus Storybook, and the issue and star counts are a dated snapshot. So Scrypath's spike numbers are the first measurement. For a dev-only dependency the production-closure concerns shrink, but unsafe template evaluation, CSS and hook fidelity, mount-scope behavior and upgrade friction remain; fablebook's dependency policy favors shallow trees and copy-paste (ADR 0018:8,22).

## Pin and verify

VERIFIED: lock schema `fablebook-brand-sources/v1`; full-SHA detached checkouts, clean-cache checks and explicit reviewed updates; the Logistify verifier binds an approved excerpt manifest to source commit, path, original-file hash and excerpt bytes (`08-01-PLAN.md:106,131`); the current check is Logistify-specific and each source's `check-records.mjs` validates its own format. No stability promise exists and fablebook's active phase is incomplete (`STATE.md:53`). PROPOSED: copy the pin, hash and explicit-update pattern with Scrypath-owned schemas and validators; do not depend on fablebook's cache or copy brand validators or data without a license.

## Five realism rules (overlap with the brandbook pack)

1. Model the job and product language, not random records (a dispatcher recovering one failed shipment). 2. Equivalence classes, not permutations (`OWNER-DNA.md:117`). 3. Deterministic and internally consistent: stable ids, ordered events, closed enums, no lorem ipsum, no orphan references (`OWNER-DNA.md:119`). 4. Missing, empty and unknown are different (`null`, `[]`, never a guess). 5. Keep illustrative claims within the source (Logistify's bulk case says 12 reassigned shipments without naming them; keep the gap explicit).
