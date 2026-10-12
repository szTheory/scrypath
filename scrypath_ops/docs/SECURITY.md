# ScrypathOps security boundary

`ScrypathOps` provides an optional Phoenix and LiveView operator interface. It does not provide authentication for `/ops`; the host application owns that boundary. Protect both ordinary HTTP requests and LiveView WebSocket connections before exposing the routes to a network.

## What `OPSUI_AUTH_MODE` does

The application validates `OPSUI_AUTH_MODE` at startup against the string allow-list `basic`, `proxy_headers`, and `sigra`. If unset, it defaults to `basic`. Selecting an allowed value does **not** install Basic authentication, trusted proxy-header handling, or Sigra authorization. The validator checks configuration only; it is not a route guard or a fail-closed exposure check.

The `sigra` value additionally requires `:sudo_confirm_path`. It does not automatically attach `ScrypathOps.Integrations.Sigra.OnMount` to the routes created by `scrypath_ops_routes/2`. That macro installs the ScrypathOps shell hook only. Do not infer that choosing `sigra` enables action authorization or audit behavior.

## Protecting the operator routes

Before exposing `/ops`, configure a trusted edge or host boundary that authenticates and authorizes both the initial HTTP request and the LiveView WebSocket upgrade. A localhost bind, Phoenix's ordinary browser pipeline, signed cookies, CSRF protection, `check_origin`, and `OPSUI_AUTH_MODE` do not establish operator authorization on their own.

If authentication is performed inside Phoenix, ensure the host's route and LiveView design runs its authentication and authorization checks for every LiveView mount and sensitive event. The `scrypath_ops_routes/2` helper owns its `live_session` and currently does not accept a host `on_mount` option; use a host-controlled routing arrangement that composes the required checks, or enforce authentication at a trusted edge.

## LiveView origin and transport

LiveView uses the `/live` WebSocket. Configure `check_origin` on `ScrypathOpsWeb.Endpoint` for real hostnames in production, and document the upstream host list when TLS terminates at a reverse proxy. Prefer an explicit allow-list over `false` outside local development. Origin checking protects the WebSocket origin boundary; it is not authentication.

Either terminate TLS at a reverse proxy or configure Phoenix/Bandit for native TLS. When TLS terminates at the proxy, ensure forwarded scheme and identity headers are trusted only from that proxy, and align Phoenix `force_ssl` / HSTS settings with the edge.

## Secrets and telemetry

Keep `secret_key_base` on a secure path (runtime environment or a secrets manager) and rotate it according to the host application's incident policy.

OPSUI telemetry must stay low-cardinality: prefer coarse events such as screen viewed or command outcome buckets. Do not attach raw search query text, full URLs with secrets, or per-record identifiers to metadata. See `../../docs/search-backend-sre.md` for operational expectations and cardinality discipline.
