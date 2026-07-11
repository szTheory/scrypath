# ScrypathOps e-commerce demo — developer workflow.
#
# Three loops:
#   make docker-dev -> fully Dockerized DEV loop with bind mounts + named build/deps volumes.
#   make dev        -> HOST Phoenix (MIX_ENV=dev) + dockerized Meilisearch + ops-CSS watcher.
#                      Seeded data IS visible in the browser (dev pool, no test sandbox).
#   make up         -> full containerized TEST stack on port WEB_PORT (what Playwright/CI use).
#
# Host-port lanes come from .env (see .env.example). Bump WEB_PORT when the
# browser UI collides. PG_PORT/MEILI_PORT are only published by host-tooling
# targets such as make dev, make infra, and make infra-pg.

-include .env
export

WEB_PORT   ?= 4002
PG_PORT    ?= 5432
MEILI_PORT ?= 7700
# Postgres host for the `dev` loop. Defaults to a native local Postgres; set to 127.0.0.1
# after `make infra-pg` if you'd rather run Postgres in Docker too.
PGHOST     ?= localhost

COMPOSE            := docker compose -f compose.yaml
COMPOSE_DOCKER_DEV := docker compose -f compose.yaml -f compose.dev.yaml
COMPOSE_HOST_PORTS := docker compose -f compose.yaml -f compose.host-ports.yaml
BASE_URL           := http://127.0.0.1:$(WEB_PORT)
ADMIN_URL          := $(BASE_URL)/admin/search
MEILI_URL          := http://127.0.0.1:$(MEILI_PORT)
ADMIN_SCREENSHOT_DIR ?= test-results/admin-screenshots
CONTRAST_REPORT_DIR  ?= test-results/contrast

.DEFAULT_GOAL := help
.PHONY: help docker-dev dev doctor urls infra infra-pg up down reset seed screenshots screenshots-matrix contrast contrast-matrix verify-path-motion verify-shell-wash logs ps

help: ## List targets
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | sort | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

docker-dev: ## Fully Dockerized dev loop with bind mounts; publishes only WEB_PORT
	@$(MAKE) --no-print-directory urls
	$(COMPOSE_DOCKER_DEV) up --build

dev: infra ## Primary loop: host dev server + dockerized Meilisearch + ops-CSS watcher
	@$(MAKE) --no-print-directory urls
	@echo "Starting ops-CSS watcher + host dev server..."
	@cd ../../scrypath_ops && mix tailwind scrypath_ops --watch &
	# The router expands scrypath_ops's route macro at compile time; touch it so edits to
	# the ops routes (a path dep) re-expand here — the dev reloader won't do this for you.
	@touch lib/scrypath_ecommerce_web/router.ex
	@MIX_ENV=dev PORT=$(WEB_PORT) PGHOST=$(PGHOST) PGPORT=$(PG_PORT) \
	  SCRYPATH_MEILISEARCH_URL=$(MEILI_URL) \
	  mix do ecto.create, ecto.migrate, scrypath.demo.seed, phx.server

doctor: ## Check Docker availability and common host-port conflicts
	@set -eu; \
	if ! docker compose version >/dev/null 2>&1; then \
	  echo "Docker Compose v2 is required. Install or start Docker Desktop, then retry."; \
	  exit 1; \
	fi; \
	echo "Docker Compose: $$(docker compose version --short 2>/dev/null || docker compose version)"; \
	conflict=0; \
	warning=0; \
	check_port() { \
	  port="$$1"; label="$$2"; hint="$$3"; mode="$$4"; \
	  if command -v lsof >/dev/null 2>&1; then \
	    if lsof -nP -iTCP:"$$port" -sTCP:LISTEN >/dev/null 2>&1; then \
	      echo ""; \
	      echo "Port $$port is already in use ($$label)."; \
	      lsof -nP -iTCP:"$$port" -sTCP:LISTEN; \
	      echo "Hint: $$hint"; \
	      if [ "$$mode" = "fatal" ]; then conflict=1; else warning=1; fi; \
	    else \
	      echo "Port $$port is free ($$label)."; \
	    fi; \
	  else \
	    echo "lsof not found; skipping $$label port check ($$port)."; \
	  fi; \
	}; \
	check_port "$(WEB_PORT)" "web UI" "set WEB_PORT=4012 or stop the process using $(WEB_PORT)" fatal; \
	check_port "$(PG_PORT)" "Postgres host-tooling overlay" "set PG_PORT=5442, or skip make dev/infra-pg" warn; \
	check_port "$(MEILI_PORT)" "Meilisearch host-tooling overlay" "set MEILI_PORT=7710, or skip make dev/infra" warn; \
	if [ "$$conflict" -ne 0 ]; then \
	  echo ""; \
	  echo "Blocking port conflicts found. Copy .env.example to .env and bump WEB_PORT, or stop the owner above."; \
	  exit 1; \
	fi; \
	if [ "$$warning" -ne 0 ]; then \
	  echo ""; \
	  echo "Host-tooling port warnings found. make docker-dev can still run because it does not publish PG_PORT or MEILI_PORT."; \
	fi; \
	echo ""; \
	echo "Docker DX checks passed."; \
	$(MAKE) --no-print-directory urls

urls: ## Print the important demo URLs and lane settings
	@echo ""
	@echo "Scrypath e-commerce demo"
	@echo "  Storefront        $(BASE_URL)"
	@echo "  Control room      $(ADMIN_URL)"
	@echo "  Posture           $(ADMIN_URL)/posture"
	@echo "  Failed sync       $(ADMIN_URL)/failed-sync"
	@echo "  Sync / drift      $(ADMIN_URL)/sync-drift"
	@echo "  Search playground $(ADMIN_URL)/search"
	@echo "  Playbooks         $(ADMIN_URL)/playbooks"
	@echo ""
	@echo "Current lane"
	@echo "  WEB_PORT=$(WEB_PORT)"
	@echo "  PG_PORT=$(PG_PORT)       (only published by host-tooling targets)"
	@echo "  MEILI_PORT=$(MEILI_PORT) (only published by host-tooling targets)"
	@echo ""
	@echo "Useful commands"
	@echo "  make docker-dev  # Docker-only dev loop"
	@echo "  make dev         # host Phoenix loop; publishes Meilisearch for host access"
	@echo "  make reset       # stop containers and delete this demo's volumes"
	@echo "  make logs        # follow container logs"
	@echo ""

infra: ## Start just Meilisearch (loopback-published on MEILI_PORT)
	$(COMPOSE_HOST_PORTS) up -d meilisearch

infra-pg: ## Also start Postgres in Docker (loopback PG_PORT); then run dev with PGHOST=127.0.0.1
	$(COMPOSE_HOST_PORTS) up -d postgres meilisearch

up: ## Full containerized test stack (build + run) on WEB_PORT — Playwright/CI shape
	@$(MAKE) --no-print-directory urls
	$(COMPOSE) up --build

down: ## Stop the stack (keep volumes)
	$(COMPOSE_DOCKER_DEV) down

reset: ## Stop and delete volumes (clean DB + Meilisearch)
	$(COMPOSE_DOCKER_DEV) down -v

seed: ## Re-seed the dev database (storefront + Ops Incident Lab signals)
	@MIX_ENV=dev PGHOST=$(PGHOST) PGPORT=$(PG_PORT) SCRYPATH_MEILISEARCH_URL=$(MEILI_URL) \
	  mix scrypath.demo.seed

screenshots: ## Capture admin-UI screenshots against the running dev server
	@ADMIN_SCREENSHOT_DIR=$${ADMIN_SCREENSHOT_DIR:-$(ADMIN_SCREENSHOT_DIR)} \
	  PLAYWRIGHT_BASE_URL=http://127.0.0.1:$(WEB_PORT) \
	  npm run test:e2e:admin-screens

screenshots-matrix: ## Capture the full theme×viewport×state admin screenshot matrix
	@ADMIN_SCREENSHOT_DIR=$${ADMIN_SCREENSHOT_DIR:-$(ADMIN_SCREENSHOT_DIR)} \
	  PLAYWRIGHT_BASE_URL=http://127.0.0.1:$(WEB_PORT) \
	  npm run test:e2e:admin-matrix

contrast: ## Run the fast token-pair contrast checker (no browser, <1s)
	@CONTRAST_REPORT_DIR=$${CONTRAST_REPORT_DIR:-$(CONTRAST_REPORT_DIR)} \
	  node contrast-checker.mjs

contrast-matrix: ## Run the full axe contrast matrix (browser required — server must be running)
	@CONTRAST_REPORT_DIR=$${CONTRAST_REPORT_DIR:-$(CONTRAST_REPORT_DIR)} \
	  PLAYWRIGHT_BASE_URL=http://127.0.0.1:$(WEB_PORT) \
	  npm run test:e2e:admin-contrast

verify-path-motion: ## One-command path-motion proof: boot test stack, run spec, tear down (no human UAT)
	@echo "Booting containerized test stack on http://127.0.0.1:$(WEB_PORT) (Playwright/CI shape)..."
	$(COMPOSE) up --build -d
	@echo "Waiting for app readiness on :$(WEB_PORT)..."
	@for _ in $$(seq 1 120); do \
	  if curl --silent --fail "http://127.0.0.1:$(WEB_PORT)" >/dev/null; then break; fi; \
	  sleep 1; \
	done
	@curl --silent --fail "http://127.0.0.1:$(WEB_PORT)" >/dev/null \
	  || { echo "App failed to become ready on :$(WEB_PORT)"; $(COMPOSE) logs web | tail -n 80; $(COMPOSE) down; exit 1; }
	@# Warm the route under test + the seed endpoint: MIX_ENV=test compiles routes lazily, so
	@# the very first request after boot can hang up the socket before Playwright's first seed.
	@curl --silent --max-time 30 "http://127.0.0.1:$(WEB_PORT)/admin/search" >/dev/null 2>&1 || true
	@echo "Running admin path-motion proof..."
	@# retries=1 mirrors CI (playwright.config retries: CI?1:0) so a one-off cold-start flake
	@# is absorbed rather than failing the proof.
	@PLAYWRIGHT_BASE_URL=http://127.0.0.1:$(WEB_PORT) npm run test:e2e:path-motion -- --retries=1; \
	  STATUS=$$?; \
	  $(COMPOSE) down; \
	  exit $$STATUS

verify-shell-wash: ## One-command shell chrome/wash proof; optional LLM judge via OPS_UI_LLM_JUDGE=1
	@echo "Booting containerized test stack on http://127.0.0.1:$(WEB_PORT) (Playwright/CI shape)..."
	$(COMPOSE) up --build -d
	@echo "Waiting for app readiness on :$(WEB_PORT)..."
	@for _ in $$(seq 1 120); do \
	  if curl --silent --fail "http://127.0.0.1:$(WEB_PORT)" >/dev/null; then break; fi; \
	  sleep 1; \
	done
	@curl --silent --fail "http://127.0.0.1:$(WEB_PORT)" >/dev/null \
	  || { echo "App failed to become ready on :$(WEB_PORT)"; $(COMPOSE) logs web | tail -n 80; $(COMPOSE) down; exit 1; }
	@curl --silent --max-time 30 "http://127.0.0.1:$(WEB_PORT)/admin/search" >/dev/null 2>&1 || true
	@echo "Running admin shell chrome proof..."
	@PLAYWRIGHT_BASE_URL=http://127.0.0.1:$(WEB_PORT) npm run test:e2e:admin-shell -- --retries=1; \
	  SHELL_STATUS=$$?; \
	  if [ "$$SHELL_STATUS" -eq 0 ]; then \
	    echo "Running deterministic shell wash visual gate..."; \
	    PLAYWRIGHT_BASE_URL=http://127.0.0.1:$(WEB_PORT) npm run test:e2e:admin-shell-wash -- --retries=1; \
	    WASH_STATUS=$$?; \
	  else \
	    WASH_STATUS=1; \
	  fi; \
	  JUDGE_STATUS=0; \
	  if [ "$${OPS_UI_LLM_JUDGE:-0}" = "1" ] || [ "$${OPS_UI_LLM_JUDGE_REQUIRED:-0}" = "1" ]; then \
	    echo "Capturing admin matrix for adversarial visual judge..."; \
	    ADMIN_SCREENSHOT_DIR=$${ADMIN_SCREENSHOT_DIR:-$(ADMIN_SCREENSHOT_DIR)} PLAYWRIGHT_BASE_URL=http://127.0.0.1:$(WEB_PORT) npm run test:e2e:admin-matrix -- --retries=1; \
	    MATRIX_STATUS=$$?; \
	    if [ "$$MATRIX_STATUS" -eq 0 ]; then \
	      ADMIN_SCREENSHOT_DIR=$${ADMIN_SCREENSHOT_DIR:-$(ADMIN_SCREENSHOT_DIR)} npm run test:e2e:ops-ui-visual-judge; \
	      JUDGE_STATUS=$$?; \
	    else \
	      JUDGE_STATUS=$$MATRIX_STATUS; \
	    fi; \
	  fi; \
	  $(COMPOSE) down; \
	  if [ "$$SHELL_STATUS" -eq 0 ] && [ "$$WASH_STATUS" -eq 0 ] && [ "$$JUDGE_STATUS" -eq 0 ]; then exit 0; fi; \
	  exit 1

logs: ## Tail infra logs
	$(COMPOSE_DOCKER_DEV) logs -f

ps: ## Show this project's containers
	$(COMPOSE_DOCKER_DEV) ps
