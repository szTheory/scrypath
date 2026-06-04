# ScrypathOps e-commerce demo — developer workflow.
#
# Two loops:
#   make dev    -> HOST Phoenix (MIX_ENV=dev) + dockerized Meilisearch + ops-CSS watcher.
#                  Seeded data IS visible in the browser (dev pool, no test sandbox).
#   make up     -> full containerized TEST stack on port WEB_PORT (what Playwright/CI use).
#
# Host-port lanes come from .env (see .env.example). Bump WEB_PORT/PG_PORT/MEILI_PORT to
# run several library demos at once without collisions.

-include .env
export

WEB_PORT   ?= 4002
PG_PORT    ?= 5432
MEILI_PORT ?= 7700
# Postgres host for the `dev` loop. Defaults to a native local Postgres; set to 127.0.0.1
# after `make infra-pg` if you'd rather run Postgres in Docker too.
PGHOST     ?= localhost

COMPOSE     := docker compose -f compose.yaml
COMPOSE_DEV := docker compose -f compose.yaml -f compose.dev.yaml
MEILI_URL   := http://127.0.0.1:$(MEILI_PORT)

.DEFAULT_GOAL := help
.PHONY: help dev infra infra-pg up down reset seed screenshots screenshots-matrix logs ps

help: ## List targets
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | sort | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

dev: infra ## Primary loop: host dev server + dockerized Meilisearch + ops-CSS watcher
	@echo "Starting ops-CSS watcher + dev server on http://127.0.0.1:$(WEB_PORT) (admin: /admin/search)"
	@cd ../../scrypath_ops && mix tailwind scrypath_ops --watch &
	# The router expands scrypath_ops's route macro at compile time; touch it so edits to
	# the ops routes (a path dep) re-expand here — the dev reloader won't do this for you.
	@touch lib/scrypath_ecommerce_web/router.ex
	@MIX_ENV=dev PORT=$(WEB_PORT) PGHOST=$(PGHOST) PGPORT=$(PG_PORT) \
	  SCRYPATH_MEILISEARCH_URL=$(MEILI_URL) \
	  mix do ecto.create, ecto.migrate, scrypath.demo.seed, phx.server

infra: ## Start just Meilisearch (loopback-published on MEILI_PORT)
	$(COMPOSE_DEV) up -d meilisearch

infra-pg: ## Also start Postgres in Docker (loopback PG_PORT); then run dev with PGHOST=127.0.0.1
	$(COMPOSE_DEV) up -d postgres meilisearch

up: ## Full containerized test stack (build + run) on WEB_PORT — Playwright/CI shape
	$(COMPOSE) up --build

down: ## Stop the stack (keep volumes)
	$(COMPOSE_DEV) down

reset: ## Stop and delete volumes (clean DB + Meilisearch)
	$(COMPOSE_DEV) down -v

seed: ## Re-seed the dev database (storefront + Ops Incident Lab signals)
	@MIX_ENV=dev PGHOST=$(PGHOST) PGPORT=$(PG_PORT) SCRYPATH_MEILISEARCH_URL=$(MEILI_URL) \
	  mix scrypath.demo.seed

screenshots: ## Capture admin-UI screenshots against the running dev server
	@ADMIN_SCREENSHOT_DIR=$${ADMIN_SCREENSHOT_DIR:-test-results/admin-screenshots} \
	  PLAYWRIGHT_BASE_URL=http://127.0.0.1:$(WEB_PORT) \
	  npm run test:e2e:admin-screens

screenshots-matrix: ## Capture the full theme×viewport×state admin screenshot matrix
	@ADMIN_SCREENSHOT_DIR=$${ADMIN_SCREENSHOT_DIR:-test-results/admin-screenshots} \
	  PLAYWRIGHT_BASE_URL=http://127.0.0.1:$(WEB_PORT) \
	  npm run test:e2e:admin-matrix

logs: ## Tail infra logs
	$(COMPOSE_DEV) logs -f

ps: ## Show this project's containers
	$(COMPOSE_DEV) ps
