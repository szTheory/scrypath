#!/bin/sh
set -eu

cd /app/scrypath_ops

until pg_isready -h "${PGHOST:-postgres}" -p "${PGPORT:-5432}" -U "${PGUSER:-postgres}" >/dev/null 2>&1; do
  echo "Waiting for the disposable Ops database..."
  sleep 1
done

export MIX_ENV=test
# The test image compiles Ops with PHX_SERVER=true, which turns the /storybook catalog route flag off.
# Mix tracks that flag as a compile-time value, so every mix call here must see the same PHX_SERVER or
# it aborts. The finite ecto tasks below start only the repo, never the endpoint, so true is safe.
export PHX_SERVER=true
export SCRYPATH_OPS_TEST_DATABASE="${SCRYPATH_OPS_TEST_DATABASE:-scrypath_ops_phase173_test}"

echo "Checking the prebuilt standalone Ops assets..."
test -s priv/static/assets/css/app.css
test -s priv/static/assets/js/app.js

echo "Preparing the isolated standalone Ops database..."
mix ecto.create --quiet
mix ecto.migrate --quiet

echo "Starting standalone Ops on the Compose-only network..."
exec env PHX_SERVER=true SCRYPATH_OPS_PORT="${SCRYPATH_OPS_PORT:-4003}" mix phx.server
