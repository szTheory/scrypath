#!/bin/sh

set -eu

until pg_isready -h "${PGHOST:-postgres}" -p "${PGPORT:-5432}" -U postgres >/dev/null 2>&1; do
  echo "Waiting for Phase 173 Postgres..."
  sleep 1
done

cd /app/scrypath_ops
echo "Preparing the isolated standalone Ops test database..."
mix ecto.create
mix ecto.migrate

echo "Building standalone Ops assets..."
mix assets.setup
mix assets.build

echo "Starting standalone Ops on internal port ${SCRYPATH_OPS_PORT:-4003}..."
exec env PHX_SERVER=true mix phx.server
