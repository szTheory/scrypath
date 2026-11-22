# Meilisearch v1.15 recordings

Raw response bodies from a real Meilisearch server, recorded once and used by `ScrypathFixtures.Recordings` to check that the fixture builders and the fake client have the shapes the real server sends. Every value is Scrypath-owned and fictional: three invented adopter indexes (`logistify_shipment`, `shopadelic_product`, `wikily_page`, the last never created), one `__reindex` partner, and ids shaped `LSH-1001`. Nothing is copied from another product.

## Source

| Item | Value |
|------|-------|
| Image tag | `getmeili/meilisearch:v1.15` |
| Local image id | `sha256:edae2a6bb59ca587b68ad74b157a9008fba10085ff3c09a143d2051c8355dbec` |
| Repo digest | `getmeili/meilisearch@sha256:fe500cf9cca05cb9f027981583f28eccf17d35d94499c1f8b7b844e7418152fc` |
| `GET /version` body | `{"commitSha":"6b4d69996ce9c1e0d0b8d52af2fcea4a5750bfa7","commitDate":"2025-06-12T16:41:47.000000000Z","pkgVersion":"1.15.2"}` (file `01-version.json`) |
| Recorded (UTC) | 2026-11-22 |
| Server mode | `MEILI_ENV=development`, no master key (so no secret can appear in a body), `MEILI_NO_ANALYTICS=true` |

The image tag is the one the repository pins in `compose.yaml`, `examples/scrypath_ecommerce/compose.yaml` and `.github/workflows/ci.yml`.

## How it was recorded

```sh
bash fixtures/scrypath_fixtures/recordings/record.sh fixtures/scrypath_fixtures/recordings/meilisearch-v1.15
```

`record.sh` starts one container named `scrypath-p196-recording` (label `scrypath.task=p196-recording`) on a random loopback port with tmpfs data, sends the requests in the table below, writes each response body to a staging directory and removes the container on any exit. It touches the output directory only after every request has succeeded: it then copies the new files in and removes any `*.json` file it did not record, so a re-record leaves no stale file and a failed run (Docker down, a failed pull or request) leaves the committed recordings as they were. The output directory must be a `meilisearch-v*` directory beside the script or a new or empty directory under the system temporary directory; any other directory is refused before Docker starts, with nothing deleted. The JSON files are written by the script and never edited by hand.

Needs: Docker, `curl`, `node`, bash (not zsh). The 60,000-document load that makes a `processing` task visible goes through `--data-binary @file` from a temporary directory the script removes.

## Escaping

Bodies pass through a value-preserving escaper before they are written: every non-ASCII character in a response becomes its JSON unicode escape (a backslash, `u` and four hex digits; characters above U+FFFF become a surrogate pair). The result parses to exactly the string the server sent, and no raw zero-width character, bidirectional control, byte-order mark or right-to-left letter reaches the repository. The files are pure ASCII. Hostile text goes to the server as JSON escapes too, so the script source holds none either.

## Files

Task files are `GET /tasks/<uid>` responses taken after the task finished, except where the note says it was caught in flight. A file whose request failed carries its HTTP status in its name.

| File | Request | HTTP status |
|------|---------|-------------|
| `01-version.json` | `GET /version` | 200 |
| `02-enqueue-index-creation.json` | `POST /indexes` (enqueue summary: the key is taskUid, not uid) | 202 |
| `03-task-index-creation.json` | `GET /tasks/0` | 200 |
| `04-task-document-addition-succeeded.json` | `GET /tasks/1` | 200 |
| `05-task-failed-invalid-document-id-space-slash.json` | `GET /tasks/2` (id with a space and a slash) | 200 |
| `06-task-failed-invalid-document-id-512-bytes.json` | `GET /tasks/3` (512-byte id) | 200 |
| `07-task-document-addition-511-bytes-succeeded.json` | `GET /tasks/4` (511-byte id is accepted) | 200 |
| `08-task-failed-invalid-document-id-hostile.json` | `GET /tasks/5` (id sent as JSON escapes: U+202E, markup, CJK, Arabic, ZWJ emoji) | 200 |
| `09-task-failed-missing-document-id-markup.json` | `GET /tasks/6` (document with markup text and a non-Latin word) | 200 |
| `10-task-failed-document-deletion-index-not-found.json` | `GET /tasks/7` | 200 |
| `11-task-failed-primary-key-no-candidate.json` | `GET /tasks/8` | 200 |
| `12-task-document-addition-processing.json` | `GET /tasks/9` (60,000 documents in flight) | 200 |
| `13-task-document-addition-enqueued.json` | `GET /tasks/10` (waiting behind the bulk load) | 200 |
| `14-task-document-addition-canceled.json` | `GET /tasks/11` (canceled by task 12 while queued) | 200 |
| `15-task-document-deletion-succeeded.json` | `GET /tasks/13` | 200 |
| `16-settings-default.json` | `GET /indexes/shopadelic_product/settings` (default settings of a new index) | 200 |
| `17-task-settings-update.json` | `GET /tasks/15` (details echo the sent settings) | 200 |
| `18-settings-filterable-status.json` | `GET /indexes/shopadelic_product/settings` (after filterableAttributes was set to [status]) | 200 |
| `19-settings-unknown-index-404.json` | `GET /indexes/wikily_page/settings` (index never created) | 404 |
| `20-tasks-limit-invalid-400.json` | `GET /tasks?limit=abc` | 400 |
| `21-search-filter-not-filterable-400.json` | `POST /indexes/shopadelic_product/search` (colour is not a filterable attribute) | 400 |
| `22-list-page1-limit3.json` | `GET /tasks?indexUids=logistify_shipment&types=documentAdditionOrUpdate,documentDeletion&limit=3` | 200 |
| `23-list-page2-from-next.json` | `GET /tasks?indexUids=logistify_shipment&types=documentAdditionOrUpdate,documentDeletion&limit=3&from=9` (from is the next value of page 1) | 200 |
| `24-list-limit1000.json` | `GET /tasks?indexUids=logistify_shipment&types=documentAdditionOrUpdate,documentDeletion&limit=1000` | 200 |
| `25-list-unknown-index-empty.json` | `GET /tasks?indexUids=wikily_page&types=documentAdditionOrUpdate,documentDeletion&limit=1000` (an index that does not exist: an empty page, not an error) | 200 |
| `26-task-index-swap.json` | `GET /tasks/17` (indexUid is null) | 200 |
| `27-list-swap-live.json` | `GET /tasks?indexUids=logistify_shipment&types=indexSwap` (the swap is missing from an indexUids-filtered list) | 200 |
| `28-list-swap-partner.json` | `GET /tasks?indexUids=logistify_shipment__reindex&types=indexSwap` | 200 |
| `29-list-swap-unfiltered.json` | `GET /tasks?types=indexSwap` (no index filter) | 200 |
| `30-list-after-swap-live-documents.json` | `GET /tasks?indexUids=logistify_shipment&types=documentAdditionOrUpdate,documentDeletion&limit=1000` (document tasks under the live index after the swap) | 200 |
| `31-list-after-swap-partner-documents.json` | `GET /tasks?indexUids=logistify_shipment__reindex&types=documentAdditionOrUpdate,documentDeletion&limit=1000` (document tasks under the partner index after the swap) | 200 |

## What the recording showed

- The key sets of every body match the research bodies taken earlier in this phase: 12 task keys, 20 default settings keys, `message`/`code`/`type`/`link` in every error object, and `results`/`total`/`limit`/`from`/`next` in every list page.
- A 512-byte id is rejected with `invalid_document_id` and a 511-byte id is accepted, so the cap in the message is exact (files 06 and 07).
- Meilisearch echoes a rejected id back inside the message exactly as sent, including markup and a right-to-left override (file 08), and it echoes a whole document that has no `id` (file 09). Operator screens that show such a message therefore show text from a customer's own data.
- A `documentDeletion` on an index that does not exist is a failed task with `index_not_found` (file 10). `GET /tasks` filtered to an index that does not exist is an empty page, not an error (file 25).
- After a swap, `GET /tasks?indexUids=...&types=indexSwap` returns an empty `results` even though `total` counts the swap, for the live index and for the partner. Only the unfiltered list shows it, with a null `indexUid` (files 26 to 29). Scrypath always filters by `indexUids`, so it can never read a swap task.
- A swap also moves each index's task history to the other name: after it, the live name has no document tasks and the partner name holds all ten (files 30 and 31). A reader that follows an index by name sees the history of whatever content that name holds now.

## When to re-record

Re-record when the pinned image id changes or the server version moves (a new `pkgVersion` in `01-version.json`). Compare key sets and value types, never values: uids and timestamps differ on every run, and `ScrypathFixtures.Recordings` is written to compare nothing else.
