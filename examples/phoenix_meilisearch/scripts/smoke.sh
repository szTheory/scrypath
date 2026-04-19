#!/usr/bin/env bash
# End-to-end smoke: Postgres (Ecto) + live Meilisearch + Scrypath path dependency.
# Default: tear down Compose on exit (CI-friendly). Use --keep-up to leave services running for local iteration.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

KEEP_UP=0
for arg in "$@"; do
  case "$arg" in
    --keep-up) KEEP_UP=1 ;;
    -h|--help)
      echo "Usage: $0 [--keep-up]"
      echo "  --keep-up  Do not run docker compose down on exit (you stop Compose manually)."
      exit 0
      ;;
    *)
      echo "Unknown option: $arg (try --help)" >&2
      exit 1
      ;;
  esac
done

export SCRYPATH_MEILISEARCH_URL="${SCRYPATH_MEILISEARCH_URL:-http://127.0.0.1:7700}"
export PGPORT="${PGPORT:-5433}"
export SCRYPATH_EXAMPLE_INTEGRATION=1

docker compose up -d

cleanup() {
  if [[ "$KEEP_UP" -eq 1 ]]; then
    echo "==> Leaving Docker Compose running (from $ROOT run: docker compose down when finished)"
  else
    docker compose down
  fi
}
trap cleanup EXIT

echo "==> Waiting for Postgres"
pg_ok=0
for _ in $(seq 1 60); do
  if docker compose exec -T postgres sh -c "pg_isready -U postgres" >/dev/null 2>&1; then
    pg_ok=1
    break
  fi
  sleep 1
done
if [[ "$pg_ok" -ne 1 ]]; then
  echo "Postgres did not become ready within 60s" >&2
  exit 1
fi

echo "==> Waiting for Meilisearch"
meili_ok=0
for _ in $(seq 1 60); do
  if curl --silent --fail "${SCRYPATH_MEILISEARCH_URL}/health" >/dev/null; then
    meili_ok=1
    break
  fi
  sleep 1
done
if [[ "$meili_ok" -ne 1 ]]; then
  echo "Meilisearch did not become healthy at ${SCRYPATH_MEILISEARCH_URL} within 60s" >&2
  exit 1
fi

echo "==> mix deps.get"
mix deps.get

echo "==> mix test (includes integration smoke when SCRYPATH_EXAMPLE_INTEGRATION=1)"
mix test

echo "==> Smoke OK"
