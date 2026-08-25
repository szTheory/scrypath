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

echo "Preparing the deterministic database and search indexes..."
mix e2e.prepare

echo "Building ecommerce assets..."
mix esbuild.install --if-missing
mix tailwind.install --if-missing
mix esbuild scrypath_ecommerce
mix tailwind scrypath_ecommerce

echo "Building mounted ScrypathOps assets..."
(
  cd /app/scrypath_ops
  mix assets.setup
  mix assets.build
)

echo "Seeding deterministic ecommerce/operator scenarios..."
mix scrypath.demo.seed

echo "Starting the persistent E2E server..."
exec env SCRYPATH_E2E_NO_SANDBOX=1 mix phx.server
