#!/usr/bin/env bash
# Records raw Meilisearch v1.15 payloads for the Scrypath fixtures (ADR 0002, v1.49 Phase 196).
#
#   bash fixtures/scrypath_fixtures/recordings/record.sh fixtures/scrypath_fixtures/recordings/meilisearch-v1.15
#
# It starts one task-scoped container on a random loopback port with tmpfs data and no master key
# (so no secret can appear in a body), sends the requests below, writes each response body to
# <NN>-<what>.json (or <NN>-<what>-<status>.json for a non-2xx body), prints a markdown table of
# the files for PROVENANCE.md, and stops the container on any exit. The JSON files are written by
# this script and never edited by hand.
#
# Every value is Scrypath-owned and fictional: indexes logistify_shipment, shopadelic_product and
# wikily_page (never created) plus the logistify_shipment__reindex partner, ids shaped LSH-1001.
#
# Hostile text goes to the server as JSON escapes and comes back through a value-preserving escaper:
# every non-ASCII character in a response (this includes the zero-width, bidirectional-control and
# byte-order-mark characters U+200B-U+200F, U+202A-U+202E, U+2066-U+2069 and U+FEFF) is rewritten
# as its \uXXXX JSON escape, which parses to the same string, so no raw format character, and no
# raw right-to-left letter, reaches the repository. This script is bash, not zsh: zsh splits
# unquoted words differently.

set -euo pipefail

out_dir="${1:?usage: record.sh <output-dir>}"
mkdir -p "$out_dir"
out_dir=$(cd "$out_dir" && pwd)
rm -f "$out_dir"/*.json

# One backslash, so hostile text below can be written as ${bs}uXXXX without a raw character.
bs=$'\134'
name=scrypath-p196-recording
image=getmeili/meilisearch:v1.15
work=$(mktemp -d)
manifest="$work/manifest.md"
raw="$work/last.raw"
: >"$manifest"

cleanup() {
  docker stop "$name" >/dev/null 2>&1 || true
  rm -rf "$work"
}
trap cleanup EXIT

docker run -d --rm --name "$name" --label scrypath.task=p196-recording \
  -p 127.0.0.1::7700 --tmpfs /meili_data \
  -e MEILI_NO_ANALYTICS=true -e MEILI_ENV=development "$image" >/dev/null

port=$(docker port "$name" 7700/tcp | head -1 | sed 's/.*://')
base="http://127.0.0.1:$port"

for _ in $(seq 1 150); do
  if curl -fsS "$base/health" >/dev/null 2>&1; then break; fi
  sleep 0.2
done
curl -fsS "$base/health" >/dev/null

# -- helpers ----------------------------------------------------------------------------------

escape() {
  node -e '
    let s = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", (c) => (s += c));
    process.stdin.on("end", () => {
      process.stdout.write(
        s.replace(/[^\u0000-\u007F]/g, (c) =>
          "\\u" + c.charCodeAt(0).toString(16).padStart(4, "0")
        )
      );
    });
  '
}

# Prints one top-level field of a JSON document read from stdin ("null" for a JSON null).
json_get() {
  node -e 'const v = JSON.parse(require("fs").readFileSync(0, "utf8"))[process.argv[1]]; console.log(v === null ? "null" : v)' "$1"
}

LAST_STATUS=""
LAST_REQUEST=""

# request METHOD PATH [DATA]  (DATA may be @file; an empty DATA sends no body)
request() {
  local method=$1 path=$2 data=${3-}
  LAST_REQUEST="$method $path"
  if [ -n "$data" ]; then
    LAST_STATUS=$(curl -sS -o "$raw" -w '%{http_code}' -X "$method" "$base$path" \
      -H 'Content-Type: application/json' --data-binary "$data")
  else
    LAST_STATUS=$(curl -sS -o "$raw" -w '%{http_code}' -X "$method" "$base$path")
  fi
}

# save STEM NOTE: write the last body as STEM.json (or STEM-<status>.json) and add a table row.
save() {
  local stem=$1 note=$2 file
  case $LAST_STATUS in
    2??) file="$stem.json" ;;
    *) file="$stem-$LAST_STATUS.json" ;;
  esac
  escape <"$raw" >"$out_dir/$file"
  printf '\n' >>"$out_dir/$file"
  printf '| `%s` | `%s`%s | %s |\n' "$file" "$LAST_REQUEST" "$note" "$LAST_STATUS" >>"$manifest"
}

# enqueue METHOD PATH [DATA]: send a write and set TASK_UID from the enqueue summary.
TASK_UID=""
enqueue() {
  request "$@"
  case $LAST_STATUS in
    2??) ;;
    *)
      echo "enqueue failed ($LAST_STATUS): $*" >&2
      cat "$raw" >&2
      exit 1
      ;;
  esac
  TASK_UID=$(json_get taskUid <"$raw")
}

wait_task() {
  local uid=$1 status
  for _ in $(seq 1 600); do
    status=$(curl -fsS "$base/tasks/$uid" | json_get status)
    case $status in succeeded | failed | canceled) return 0 ;; esac
    sleep 0.1
  done
  echo "task $uid did not finish" >&2
  exit 1
}

# record_task STEM UID NOTE: wait for the task to finish, then save GET /tasks/UID.
record_task() {
  wait_task "$2"
  request GET "/tasks/$2"
  save "$1" "$3"
}

# -- requests ---------------------------------------------------------------------------------

request GET /version
save 01-version ""

enqueue POST /indexes '{"uid":"logistify_shipment","primaryKey":"id"}'
save 02-enqueue-index-creation " (enqueue summary: the key is taskUid, not uid)"
record_task 03-task-index-creation "$TASK_UID" ""

enqueue POST /indexes/logistify_shipment/documents \
  '[{"id":"LSH-1001","title":"Pallet of ceramic tiles (fictional)"}]'
record_task 04-task-document-addition-succeeded "$TASK_UID" ""

# invalid_document_id, three ways: a space and a slash, one byte over the 511-byte cap, and a
# hostile id sent as JSON escapes (bidi override, markup, CJK, Arabic, a ZWJ emoji sequence).
enqueue POST /indexes/logistify_shipment/documents \
  '[{"id":"LSH 2026/04","title":"Record with an invalid id (fictional)"}]'
record_task 05-task-failed-invalid-document-id-space-slash "$TASK_UID" " (id with a space and a slash)"

long=$(printf 'a%.0s' $(seq 1 508))
enqueue POST /indexes/logistify_shipment/documents \
  "[{\"id\":\"LSH-$long\",\"title\":\"Record with a 512-byte id (fictional)\"}]"
record_task 06-task-failed-invalid-document-id-512-bytes "$TASK_UID" " (512-byte id)"

long=$(printf 'a%.0s' $(seq 1 507))
enqueue POST /indexes/logistify_shipment/documents \
  "[{\"id\":\"LSH-$long\",\"title\":\"Record with a 511-byte id (fictional)\"}]"
record_task 07-task-document-addition-511-bytes-succeeded "$TASK_UID" " (511-byte id is accepted)"

enqueue POST /indexes/logistify_shipment/documents \
  "[{\"id\":\"LSH${bs}u202e<b>7</b>${bs}u4e2d${bs}u0627${bs}ud83d${bs}udc69${bs}u200d${bs}ud83d${bs}udcbb\",\"title\":\"Record with a hostile id (fictional)\"}]"
record_task 08-task-failed-invalid-document-id-hostile "$TASK_UID" " (id sent as JSON escapes: U+202E, markup, CJK, Arabic, ZWJ emoji)"

# missing_document_id echoes the whole document: markup text and a non-Latin word show how.
enqueue POST /indexes/logistify_shipment/documents \
  "[{\"title\":\"<em>fragile</em> ${bs}u8d27${bs}u7269 (fictional)\",\"carrier\":\"Logistify fictional carrier\"}]"
record_task 09-task-failed-missing-document-id-markup "$TASK_UID" " (document with markup text and a non-Latin word)"

# a delete on an index that does not exist is a failed task, not an error response
enqueue POST /indexes/logistify_unknown/documents/delete-batch '["LSH-1001"]'
record_task 10-task-failed-document-deletion-index-not-found "$TASK_UID" ""

# primary key inference on a fresh index with no id-like field
enqueue POST /indexes/shopadelic_noprimary/documents \
  '[{"title":"Product with no id-like field (fictional)"}]'
record_task 11-task-failed-primary-key-no-candidate "$TASK_UID" ""

# processing, enqueued and canceled, caught behind a 60,000-document load
node -e '
  const docs = [];
  for (let n = 0; n < 60000; n++) {
    docs.push({ id: "LSH-" + (100000 + n), title: "Bulk shipment " + n + " (fictional)" });
  }
  process.stdout.write(JSON.stringify(docs));
' >"$work/bulk.json"

enqueue POST /indexes/logistify_shipment/documents "@$work/bulk.json"
bulk=$TASK_UID
enqueue POST /indexes/logistify_shipment/documents \
  '[{"id":"LSH-2001","title":"Record queued behind the bulk load (fictional)"}]'
queued=$TASK_UID
enqueue POST /indexes/logistify_shipment/documents \
  '[{"id":"LSH-2002","title":"Record canceled while queued (fictional)"}]'
doomed=$TASK_UID
enqueue POST "/tasks/cancel?uids=$doomed"
cancel=$TASK_UID

caught=no
for _ in $(seq 1 3000); do
  request GET "/tasks/$bulk"
  state=$(json_get status <"$raw")
  if [ "$state" = processing ]; then
    save 12-task-document-addition-processing " (60,000 documents in flight)"
    request GET "/tasks/$queued"
    state=$(json_get status <"$raw")
    if [ "$state" != enqueued ]; then
      echo "queued task was $state, not enqueued, when the bulk load was processing" >&2
      exit 1
    fi
    save 13-task-document-addition-enqueued " (waiting behind the bulk load)"
    caught=yes
    break
  fi
  if [ "$state" != enqueued ]; then
    echo "bulk load was $state before a processing snapshot was taken" >&2
    exit 1
  fi
  sleep 0.02
done
if [ "$caught" != yes ]; then
  echo "never saw the bulk load processing" >&2
  exit 1
fi

wait_task "$bulk"
wait_task "$cancel"
wait_task "$queued"
record_task 14-task-document-addition-canceled "$doomed" " (canceled by task $cancel while queued)"

enqueue POST /indexes/logistify_shipment/documents/delete-batch '["LSH-1001"]'
record_task 15-task-document-deletion-succeeded "$TASK_UID" ""

# settings on a second adopter index: default, then filterableAttributes narrowed to status
enqueue POST /indexes '{"uid":"shopadelic_product","primaryKey":"id"}'
wait_task "$TASK_UID"
request GET /indexes/shopadelic_product/settings
save 16-settings-default " (default settings of a new index)"

enqueue PATCH /indexes/shopadelic_product/settings '{"filterableAttributes":["status"]}'
record_task 17-task-settings-update "$TASK_UID" " (details echo the sent settings)"
request GET /indexes/shopadelic_product/settings
save 18-settings-filterable-status " (after filterableAttributes was set to [status])"

# error bodies Scrypath can meet outside a task
request GET /indexes/wikily_page/settings
save 19-settings-unknown-index " (index never created)"
request GET '/tasks?limit=abc'
save 20-tasks-limit-invalid ""
request POST /indexes/shopadelic_product/search '{"q":"","filter":"colour = red"}'
save 21-search-filter-not-filterable " (colour is not a filterable attribute)"

# list pages the way Scrypath asks for them: indexUids, types, limit, then from. They are taken
# before the swap because a swap moves each index's task history to the other index.
types='documentAdditionOrUpdate,documentDeletion'
request GET "/tasks?indexUids=logistify_shipment&types=$types&limit=3"
save 22-list-page1-limit3 ""
next=$(json_get next <"$raw")
if [ "$next" = null ]; then
  echo "page 1 had no next value, so there is no continuation to record" >&2
  exit 1
fi
request GET "/tasks?indexUids=logistify_shipment&types=$types&limit=3&from=$next"
save 23-list-page2-from-next " (from is the next value of page 1)"
request GET "/tasks?indexUids=logistify_shipment&types=$types&limit=1000"
save 24-list-limit1000 ""
request GET "/tasks?indexUids=wikily_page&types=$types&limit=1000"
save 25-list-unknown-index-empty " (an index that does not exist: an empty page, not an error)"

# swap: create the partner, swap, then list swap tasks three ways and the document tasks per index
enqueue POST /indexes '{"uid":"logistify_shipment__reindex","primaryKey":"id"}'
wait_task "$TASK_UID"
enqueue POST /swap-indexes '[{"indexes":["logistify_shipment","logistify_shipment__reindex"]}]'
record_task 26-task-index-swap "$TASK_UID" " (indexUid is null)"
request GET '/tasks?indexUids=logistify_shipment&types=indexSwap'
save 27-list-swap-live " (the swap is missing from an indexUids-filtered list)"
request GET '/tasks?indexUids=logistify_shipment__reindex&types=indexSwap'
save 28-list-swap-partner ""
request GET '/tasks?types=indexSwap'
save 29-list-swap-unfiltered " (no index filter)"
request GET "/tasks?indexUids=logistify_shipment&types=$types&limit=1000"
save 30-list-after-swap-live-documents " (document tasks under the live index after the swap)"
request GET "/tasks?indexUids=logistify_shipment__reindex&types=$types&limit=1000"
save 31-list-after-swap-partner-documents " (document tasks under the partner index after the swap)"

echo "Recorded $(ls "$out_dir"/*.json | wc -l | tr -d ' ') files from $image into $out_dir" >&2
echo "Image: $(docker image inspect "$image" --format '{{.Id}}')" >&2
echo >&2
cat "$manifest"
