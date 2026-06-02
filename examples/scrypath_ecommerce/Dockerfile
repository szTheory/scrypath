# syntax=docker/dockerfile:1
FROM hexpm/elixir:1.19.0-erlang-28.1-debian-bookworm-20260518

RUN apt-get update -qq \
  && apt-get install -y --no-install-recommends build-essential git curl postgresql-client npm \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV=test \
    PHX_SERVER=true \
    PORT=4002 \
    PGPORT=5432 \
    SCRYPATH_MEILISEARCH_URL=http://meilisearch:7700

COPY mix.exs mix.lock ./
COPY scrypath_ops/mix.exs scrypath_ops/mix.lock ./scrypath_ops/
COPY examples/scrypath_ecommerce/mix.exs examples/scrypath_ecommerce/mix.lock ./examples/scrypath_ecommerce/

# One layer, with a BuildKit cache mount for the hex package + rebar download caches.
# A mix.lock change re-resolves but only re-downloads changed archives; a later source /
# CSS change (COPY . . below) never re-runs this layer at all. NOTE: do not mount /root/.mix
# here — that would shadow the hex/rebar archives installed above and break deps.get.
RUN --mount=type=cache,target=/root/.hex \
    --mount=type=cache,target=/root/.cache/rebar3 \
    mix deps.get \
 && (cd scrypath_ops && mix deps.get) \
 && (cd examples/scrypath_ecommerce && mix deps.get)

COPY . .

WORKDIR /app/examples/scrypath_ecommerce

EXPOSE 4002

CMD ["sh", "./docker-entrypoint.sh"]
