#!/usr/bin/env bash
set -euo pipefail

IMAGE="${SCRYPATH_RELEASE_VERIFY_IMAGE:-elixir:1.19-otp-28}"

docker run --rm \
  -v "$PWD:/app" \
  -w /app \
  "$IMAGE" \
  bash -lc '
    mix local.hex --force
    mix local.rebar --force
    mix deps.get
    mix verify.phase11
  '
