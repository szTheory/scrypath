# ScrypathOps security notes

This document describes how the optional operator Phoenix surface should be run safely. It complements the library’s operational guidance in the parent repository.

## Development defaults

Local `MIX_ENV=dev` keeps the app easy to boot: `config/dev.exs` sets **`validate_opsui_auth_on_start`** to **`false`**, so **`OPSUI_AUTH_MODE`** is not required for **`mix phx.server`**. Treat dev as **trusted-operator workstations only**—do not infer safety from “localhost” inside shared containers without an explicit boundary (see production section).

`config/test.exs` also sets **`:validate_opsui_auth_on_start`** to **`false`** so **`mix test`** does not require **`OPSUI_AUTH_MODE`**.

## Production requirements

In **`MIX_ENV=prod`**, `config/prod.exs` sets **`validate_opsui_auth_on_start`** to **`true`**. The OTP application refuses to start unless **`OPSUI_AUTH_MODE`** is set to one of the documented modes implemented in **`ScrypathOps.Security`** (today: **`basic`** or **`proxy_headers`**). This fail-closed default prevents accidentally exposing `/ops` behind only stock Phoenix plugs.

## WebSocket and check_origin

LiveView uses the **`/live`** WebSocket. Configure **`check_origin`** on **`ScrypathOpsWeb.Endpoint`** for real hostnames in production, and document the upstream host list when TLS terminates at a reverse proxy. Prefer an explicit allow-list over `false` outside local development.

## Cookies and CSRF

The browser pipeline uses signed session cookies and CSRF protection for standard Phoenix forms and LiveView. Keep **`secret_key_base`** on a secure path (runtime env or secrets manager) and rotate with your incident response policy.

## Reverse proxy TLS vs in-app TLS

Either terminate TLS at a reverse proxy (common) or configure Phoenix/Bandit for native TLS. When TLS terminates in the proxy, ensure **`x-forwarded-proto`** and related headers are trustworthy and that Phoenix’s **`force_ssl`** / HSTS configuration matches your edge.

## Telemetry metadata

OPSUI telemetry must stay **low-cardinality**: prefer coarse events such as screen viewed or command outcome buckets. Do **not** attach raw search query text, full URLs with secrets, or per-record identifiers to metadata. Align with **`docs/search-backend-sre.md`** in the parent repo for operational expectations and cardinality discipline.

The **`validate_opsui_auth_on_start`** application environment is documented here so operators understand why tests and dev differ from production.
