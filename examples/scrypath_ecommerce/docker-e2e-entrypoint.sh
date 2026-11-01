#!/bin/sh

set -eu

until pg_isready -h "${PGHOST:-postgres}" -p "${PGPORT:-5432}" -U postgres >/dev/null 2>&1; do
  echo "Waiting for Postgres..."
  sleep 1
done

until curl --silent --fail "${SCRYPATH_MEILISEARCH_URL:-http://meilisearch:7700}/health" >/dev/null; do
  echo "Waiting for Meilisearch..."
  sleep 1
done

cd /app/examples/scrypath_ecommerce

echo "Checking the prebuilt storefront and mounted Ops assets..."
for asset in \
  /app/scrypath_ops/priv/static/assets/js/app.js \
  /app/scrypath_ops/priv/static/assets/css/app.css \
  /app/examples/scrypath_ecommerce/priv/static/assets/js/app.js \
  /app/examples/scrypath_ecommerce/priv/static/assets/css/app.css; do
  if [ ! -s "$asset" ]; then
    echo "Required prebuilt asset is missing or empty: $asset" >&2
    exit 1
  fi
done

echo "Preparing the deterministic database and search indexes..."
PHX_SERVER=false mix e2e.prepare

echo "Seeding deterministic ecommerce/operator scenarios..."
PHX_SERVER=false mix scrypath.demo.seed

echo "Starting the persistent E2E server..."
exec env SCRYPATH_E2E_NO_SANDBOX=1 mix phx.server
