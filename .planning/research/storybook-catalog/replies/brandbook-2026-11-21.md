# Reply from the brandbook session: fictional adopters for the catalog (2026-11-21)

**Provenance.** Pasted by the maintainer into the Scrypath session on 2026-11-21 from their brandbook LLM session (answer to prompt 4 in the paste prompts). This file is a **digest**: it keeps the analysis, the per-adopter facts and every rule, but not the roughly 100 proposed JSON records or the full per-adopter query lists (the pack is about 14k words). Those are specified here and will be regenerated, validated and committed as fixtures in the fixtures phase. The pack's own labels are kept: **canon** = a fact in a brand repository; **Proposed** = new material written for Scrypath, not validated by the repositories' validators. Facts here are another session's account, **not verified** by the Scrypath session except where marked "checked".

## The six adopters (the pack confirms: nothing newer exists)

Same six that fablebook pins in `brand_sources.lock.json`. All repos are `https://github.com/szTheory/<name>-brand`; each has `BRAND.md`, `brand.json`, `tokens.json`, `assets/`, `records/<name>/` with a validator (`node records/<name>/check-records.mjs` from the repo root) and a mapping guide.

| Adopter | Industry | Version, commit | Finish | Fonts (all OFL 1.1) |
|---|---|---|---|---|
| Logistify | Freight (console, shipper portal, driver app) | v1.0 `6189eb2` | owner-signed-off 2026-11-10; 35 cases, 4 flows | Archivo, Red Hat Mono |
| Chatly | Messaging | v0.3 `111b063` | light owner read | Parkinsans, Figtree, DM Mono, M PLUS 2 |
| Clinicly | Outpatient clinics | v0.3 `61aac2b` | owner scan, one fix | Rubik |
| Shopadelic | Shopping platform for makers | v0.3 `8f9d70e` | corrected after fablebook review | Bricolage Grotesque |
| Finanza | Personal finance (es-ES) | v0.2 `9748d49` | owner glance | **Space Grotesk** (reserved for Sigra) |
| Classwell | Learning platform | v0.2 `7b2c843` | owner read, one fix | Newsreader, Hanken Grotesk |

Not adopters: three tiny workflow test briefs (furniture restoration studio, "Cedar & Current", "Mewtell"); `fablebook-brand` v2.1 is a real product; Tasklane (Sigra) and Cadence (Accrue) are example hosts made inside those projects.

## Ranked fit for a search-ops UI (pack section G), one unique state each

1. **Shopadelic**, multi-tenant: drift in one store only (a half-applied catalog import while every other store is in sync); per-store drift, not a global number.
2. **Logistify**, high write rate: a growing backlog with nothing failed yet (about 6,000 status changes an hour at close-out; depth and lag rise, failure count stays 0).
3. **Clinicly**, PII plus Arabic RTL: failed work an operator may not read (ids, counts, error class; never names or note text).
4. **Chatly**, non-Latin (Japanese): reindex and promotion in progress (61M messages, 7 h 40 min; two indexes, progress, what promotion swaps).
5. **Classwell**, self-hosted district deployment: the backend is unreachable (last good sync, what waits, the fix is on the customer's side).
6. **Finanza**, runner-up: delete-and-replace (a pending row replaced by its posted copy; the delete fails and search shows a stale duplicate); also the only one with a built-in `connections`/`syncAttempts` model.

Fit with owner decision D3 (UI engine, 2026-10-25): the owner's examples there were a Slack clone, a language-learning app and a personal finance tool, which are Chatly, Classwell and Finanza. The six canon adopters are those profiles with real brandbooks; Wikily (empty install) remains Scrypath's own.

## Per-adopter facts worth keeping (all Proposed unless marked canon)

- **Logistify:** tenants are shippers (`shp-01` canon); ids `LGX-0417-DE` (canon), partial-id and hyphen matching; two people named M. Keller (driver and recipient, canon `sharedNames`); `null` address versus `[]` (canon `missingVersusEmpty`); a split shipment (near-duplicate rows); a 41-stop route and a 312-pallet shipment; DE/FR text (`Hafenstraße` against `hafenstrasse`). Sync: shipments `:oban` (about 45,000 updates a day, peak 6,000 an hour 16:00 to 18:00 CET), recipients `:manual` (nightly 02:00 import, about 30,000 rows), shippers `:inline`. Failures: 4,200 jobs queued and 11 minutes lag; 2,150 of 31,400 import rows fail on null `addressLines`; 03:00 purge hard-deletes 38 shipments that stay in the index; a 2.4M-document reindex (52 minutes) misses 1,900 updates; Meilisearch down 7 minutes exhausts 6,800 jobs; a shipper rename leaves 14,200 shipments stale for 3 hours.
- **Chatly:** shards as tenants (`t-jp-01`, `t-sg-02`); message text private, results filtered by conversation membership at query time; never index drafts, deleted text, attachments, phones, emails or per-person unread; unread cap 9,999+ (canon `case-inbox-huge-unread` 12,480); CJK, Arabic and emoji in one row; unnamed 1:1 conversation titled from the other member; same text in two conversations; a 4,096-member group (Proposed). Sync: messages `:oban` (1.4M a day, peak 40 a second), conversations `:inline`, people `:manual` for contact imports of up to 250,000 rows. Failures: 410,000 queued, 38 minutes behind; 1,900 jobs fail on documents over a size limit (pasted logs; **see Meilisearch check below**); 2,310 deleted-for-everyone messages still matching; 12,000 merged duplicate people left in the index.
- **Clinicly:** two clinics (`cl-01` New York, `cl-02` Chicago); patient ids `CLY-48xxxx`; two patients named Maria Santos with different ids (canon), a merged duplicate that must vanish; a 41-character surname; the 01:30 appointment that happens twice at the daylight-saving change (canon `apt-0049/0050`); statuses Scheduled, Completed, Canceled, Missed, Reminder Not sent. **Never index** visit-note text, date of birth, phone, email, insurance numbers, diagnoses, free-text reasons, reminder text; filter every query by the signed-in staff member's `clinic_id`; a denied search reveals nothing, not even a count; operator UI shows ids and error codes, not documents. Presented as a design rule, not a compliance claim. Failures: 3,100 appointment jobs 11 minutes late at 08:50; 212 rows of a 48,000 import arrive as question marks (Windows-1256 export); a restored 6-hour-old backup leaves the index with 1,204 extra patients; 37 documents missing `clinic_id` hide from every filter ("patient not found").
- **Shopadelic:** stores as tenants (`sto-0001` Maison Lavande canon, French); per-store currency and minor units (JPY has no decimals); soft-deleted near-duplicate sharing a SKU; `stock` versus `reserved` (1 on hand, 0 available; Low stock at 3 or fewer, canon `display.stockRule`); Draft/Archived/Published and a `null` price (canon `prd-0009`); merchant themes Lavande and Étoile (Étoile deliberately fails contrast; a failing theme is reported, not recolored); a store with `productCount` null while paused; 412,880-product store. Sync: products `:oban`, orders `:oban` (small queue), stores `:inline`, bulk imports `:manual`. Failures: a midnight promotion changes 2,300 prices and 640 products show last week's price for 11 minutes; an import of 58,000 rows with 1,900 "document too large"; a deleted store still returns 211 of 6,120 products; a 412,880-product reindex (47 minutes) held by a 3,000-document shortfall.
- **Finanza:** `user_id` filter applied server-side on every query; never index account numbers (only a 4-digit tail), balances, credentials, emails or phones; money as signed integer minor units plus currency, true minus U+2212 (canon `display.signConvention`); pending, posted and reversed copies of one payment; `null` payee with the text in the memo; bank descriptors over 80 characters; a USD charge keeping its original amount (canon `txn-0025`); a 1.8M-row business account (`acc-0107`). Sync: transactions `:oban`, accounts `:inline`, first-import and CSV `:manual`. Failures: a 4,300-row bank pull at 02:00 leaves about 900 payments unsearchable until 07:40; a delete that fails 3 times leaves a removed row visible for 6 hours; a worker pool starved for 40 minutes by one huge account.
- **Classwell:** orgs (`org-0001` Alder Hollow School District, `org-0002` Northmere Open University, both invented) plus `null` for the shared catalog; same title across owners (three "Your First Season with Bees"); a saved reading place pointing at a retired lesson (`les-0009`); a 36-character German compound; learner names first name plus initial only; "Jonas K." in two orgs (a missing `orgId` is a leak); enrollment 1,893,204; never index full names, emails, birth dates, guardian contacts, accommodation notes, answers, mastery, reading positions or IPs. Sync: lessons `:oban`, courses `:inline` on small installs, learners `:manual` for the term-start import (212,400 rows). Failures: 1,140 learner rows rejected because the school code `AH 2026/7B` is not a valid id (**checked-plausible**, see below); 14 retired lessons still showing after a failed delete; 48,206 lessons in the database against 47,950 indexed after a deploy dropped 256 queued updates; 37 withdrawn learners searchable 3 days after the request.

## Rules for fake data that feels real (pack section I)

1. Ids are stable, domain-shaped and never renumbered (a retired record keeps its id).
2. One fixed "now", every time in an explicit zone, with some times on a boundary (DST, midnight crossing).
3. Two things that look alike are different records keyed by id (same-name patients, M. Keller twice).
4. Unknown stays unknown: `null`, shown as missing, never a plausible guess; a missing value is a designed state.
5. Use the domain's words and money rules (signed minor units, a true minus, "shipment" not "package").
6. Each step's result is the next screen's starting state (flows carry an `outcome` per step).

## Reuse terms (pack section H) and what it means

- Fonts: OFL 1.1, keep the license text. Logistify photographs: CC BY 2.0 or 4.0, keep the credit.
- Logos, icons, tokens, books, records, brand data: **no license decided**; made for fablebook's demo catalog; the pack says the owner (szTheory) decides. It reports an owner statement on 2026-11-21 that the demo companies may be reused as scenarios in the OSS libraries, so dev and test storybook use is within that; ask before shipping them in a published Hex package or public docs. Names are uncleared (Clinicly, Shopadelic, Classwell collide with real products); label them "fictional" wherever they appear in public docs.
- The pack recommends **pinning, not copying** (repository URL, tag and full SHA in a lock file; shallow-fetch into a gitignored cache; verify HEAD equals the pin; CI cache keyed on the lock), as fablebook's `brand_sources.lock.json` and `bin/fetch_brand_sources` do.

## Gaps the pack found and what it would make first

Missing industries: help-center or knowledge-base SaaS, industrial parts distributor (millions of SKUs, `6204-2RS` versus `6204 2RS`, nightly manual feeds), job board (nightly expiries), media library, listings. If asked for two more: **a help-center SaaS** (per-tenant indexes, many locales including RTL, drafts that must never appear publicly, reindex-and-promote on language change) and **an industrial parts distributor** (the scale and import case). A job board third.

## Cautions recorded by the Scrypath session

- **Meilisearch realism is unchecked.** Several failures cite a "document over the 100 KB limit" or "document too large". Meilisearch's real limits differ (the default payload limit is 100 MB; there is no 100 KB document cap; ids must be alphanumeric, hyphen or underscore, which is why `AH 2026/7B` as an id is plausible; words past 65,535 per attribute are ignored). Before a failure story ships, check its error code and wording against the Meilisearch docs and the real `Scrypath` normalization code; invented error text is a contrived-data defect.
- **Font overlap (checked).** Scrypath's own brand tokens use Bricolage Grotesque and Hanken Grotesk (`brand/tokens.json`), the same faces as Shopadelic and Classwell, so stories themed as those two can look close to Scrypath chrome. Use it as a test that adopter theming and Scrypath chrome stay apart, and say so in the story. Finanza's Space Grotesk is reserved for Sigra: substitute an OFL face with tabular numerals (the pack suggests Inter) in any Finanza-themed story.
- Proposed records have not been run through the repositories' validators; run each validator once after pinning.
- Scrypath chrome stays Scrypath's: theme per adopter only where the screen shows host content or the story is about host theming (pack guidance).
