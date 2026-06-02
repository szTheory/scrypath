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

exec mix phx.server
