#!/bin/sh
set -eu

cd /app/scrypath_ops

until pg_isready -h "${PGHOST:-postgres}" -p "${PGPORT:-5432}" -U "${PGUSER:-postgres}" >/dev/null 2>&1; do
  echo "Waiting for the disposable Ops database..."
  sleep 1
done

export MIX_ENV=test
export SCRYPATH_OPS_TEST_DATABASE="${SCRYPATH_OPS_TEST_DATABASE:-scrypath_ops_phase173_test}"

echo "Checking the prebuilt standalone Ops assets..."
test -s priv/static/assets/css/app.css
test -s priv/static/assets/js/app.js

echo "Preparing the isolated standalone Ops database..."
PHX_SERVER=false mix ecto.create --quiet
PHX_SERVER=false mix ecto.migrate --quiet

echo "Starting standalone Ops on the Compose-only network..."
exec env PHX_SERVER=true SCRYPATH_OPS_PORT="${SCRYPATH_OPS_PORT:-4003}" mix phx.server
