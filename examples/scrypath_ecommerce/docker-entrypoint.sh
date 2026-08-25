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

# Deps are baked into the image (see Dockerfile). Only refresh when running the dev
# override, where bind-mounted source may carry a newer mix.lock than the image.
if [ "${MIX_ENV:-test}" = "dev" ]; then
  (cd /app && mix deps.get)
  (cd /app/scrypath_ops && mix deps.get)
  (cd /app/examples/scrypath_ecommerce && mix deps.get)
fi

cd /app/examples/scrypath_ecommerce

mix ecto.create --quiet
mix ecto.migrate --quiet
mix scrypath.demo.seed

base_url="${DEMO_BASE_URL:-http://127.0.0.1:${PORT:-4002}}"
cat <<URLS

Scrypath e-commerce demo is ready.
  Storefront        ${base_url}
  Control room      ${base_url}/admin/search
  Posture           ${base_url}/admin/search/posture
  Failed sync       ${base_url}/admin/search/failed-sync
  Sync / drift      ${base_url}/admin/search/sync-drift
  Search playground ${base_url}/admin/search/search
  Playbooks         ${base_url}/admin/search/playbooks

URLS

exec mix phx.server
