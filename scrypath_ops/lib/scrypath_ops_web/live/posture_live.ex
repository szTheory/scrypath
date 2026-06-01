defmodule ScrypathOpsWeb.PostureLive do
  @moduledoc """
  Read-only fleet posture over `Scrypath.sync_status/2` for allowlisted schemas.

  Uses bounded `Task.async_stream/3` per refresh. **Manual refresh** is primary;
  optional auto-refresh is reserved (assign defaults to `false`; see README).
  """

  use ScrypathOpsWeb, :live_view

  alias ScrypathOps.Integrations.Sigra.Gating
  alias Scrypath.Meilisearch.Tasks

  @meilisearch_ops_guide "https://github.com/szTheory/scrypath/blob/main/guides/meilisearch-operations.md"

  @impl true
  def mount(_params, _session, socket) do
    allowlist = ScrypathOps.Schemas.allowlist()
    scrypath_opts = ScrypathOps.Schemas.scrypath_opts()

    socket =
      socket
      |> assign(:page_title, "Posture / health")
      |> assign(:schema_allowlist, allowlist)
      |> assign(:scrypath_opts, scrypath_opts)
      |> assign(:auto_refresh, false)
      |> assign(:posture_rows, [])
      |> assign(:aggregate_error_count, 0)
      |> assign(:last_refresh_at, nil)
      |> assign(:posture_headline, "—")
      |> assign(:posture_evidence, "")
      |> assign(:next_checks, [])

    {:ok, load_posture(socket)}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    start_ms = System.monotonic_time(:millisecond)
    socket = load_posture(socket)
    duration_ms = System.monotonic_time(:millisecond) - start_ms

    # Low-cardinality telemetry: no per-schema labels (CONTEXT D-08).
    :telemetry.execute(
      [:scrypath_ops, :posture, :refresh],
      %{duration_ms: duration_ms, schema_count: length(socket.assigns.schema_allowlist)},
      %{outcome: if(socket.assigns.aggregate_error_count > 0, do: :degraded, else: :ok)}
    )

    {:noreply, socket}
  end

  def handle_event("swap_live", %{"schema" => mod_str}, socket) do
    case mod_from_allowlist(mod_str, socket.assigns.schema_allowlist) do
      {:ok, mod} ->
        {:noreply, swap_live(socket, mod)}

      :error ->
        {:noreply, put_flash(socket, :error, "Select an allowlisted schema.")}
    end
  end

  defp load_posture(socket) do
    allowlist = socket.assigns.schema_allowlist
    opts = socket.assigns.scrypath_opts

    cond do
      allowlist == [] ->
        socket
        |> assign(:posture_rows, :empty_allowlist)
        |> assign(:aggregate_error_count, 0)
        |> assign(:last_refresh_at, DateTime.utc_now())
        |> assign_jtbd_summary()

      not Keyword.has_key?(opts, :backend) ->
        socket
        |> assign(:posture_rows, :missing_backend)
        |> assign(:aggregate_error_count, 0)
        |> assign(:last_refresh_at, DateTime.utc_now())
        |> assign_jtbd_summary()

      true ->
        rows =
          allowlist
          |> Task.async_stream(
            fn mod ->
              {mod, Scrypath.sync_status(mod, opts)}
            end,
            max_concurrency: 3,
            timeout: 15_000,
            on_timeout: :kill_task
          )
          |> Enum.map(fn
            {:ok, {mod, res}} -> {mod, res}
            {:exit, reason} -> {:posture_stream, {:error, {:async_stream, reason}}}
          end)
          |> sort_rows()

        err_count = Enum.count(rows, fn {_m, r} -> match?({:error, _}, r) end)

        socket
        |> assign(:posture_rows, {:ok, rows})
        |> assign(:aggregate_error_count, err_count)
        |> assign(:last_refresh_at, DateTime.utc_now())
        |> assign_jtbd_summary()
    end
  end

  defp assign_jtbd_summary(socket) do
    rows = socket.assigns.posture_rows
    err_count = socket.assigns.aggregate_error_count

    {headline, evidence, checks} = jtbd_state(rows, err_count, socket.assigns.mount_path)

    socket
    |> assign(:posture_headline, headline)
    |> assign(:posture_evidence, evidence)
    |> assign(:next_checks, Enum.take(checks, 5))
  end

  defp swap_live(socket, mod) do
    Gating.gate_sensitive_action(socket, :swap_live, fn ->
      scrypath_opts = socket.assigns.scrypath_opts
      wait_opts = task_wait_opts(scrypath_opts)

      case Scrypath.Meilisearch.swap_indexes(mod, scrypath_opts) do
        {:ok, %{task: task}} ->
          case Tasks.wait_for_task(task, wait_opts) do
            {:ok, _waited} ->
              socket
              |> load_posture()
              |> put_flash(:info, "Swap live index completed")

            {:error, reason} ->
              put_flash(socket, :error, "Swap live failed: #{inspect(reason)}")
          end

        {:error, reason} ->
          put_flash(socket, :error, "Swap live failed: #{inspect(reason)}")
      end
    end)
  end

  defp task_wait_opts(opts) do
    opts
    |> Keyword.put_new(:inline_poll_interval, 50)
    |> Keyword.put_new(:inline_timeout, 15_000)
  end

  defp jtbd_state(:empty_allowlist, _, _mount_path) do
    checks = [
      %{
        text:
          "Add schemas to the OPSUI allowlist in :scrypath_ops config or SCRYPATH_OPS_SCHEMAS.",
        href: "https://github.com/szTheory/scrypath/blob/main/scrypath_ops/README.md"
      }
    ]

    {"Not configured",
     "No schemas are allowlisted for posture — configure schema_allowlist or SCRYPATH_OPS_SCHEMAS (see scrypath_ops README).",
     checks}
  end

  defp jtbd_state(:missing_backend, _, _mount_path) do
    checks = [
      %{
        text: "Wire :backend and related :scrypath_ops options so sync_status can run.",
        href: "https://github.com/szTheory/scrypath/blob/main/scrypath_ops/README.md"
      }
    ]

    {"Broken",
     "Scrypath runtime is missing :backend under :scrypath_ops — posture cannot query sync status.",
     checks}
  end

  defp jtbd_state({:ok, _rows}, err_count, mount_path) when err_count > 0 do
    checks =
      [
        %{
          text: "Open failed sync work to triage fetch and queue errors first.",
          navigate: "#{mount_path}/failed-sync"
        },
        %{
          text: "Review read-only sync and drift signals before changing indexes.",
          navigate: "#{mount_path}/sync-drift"
        },
        %{
          text: "Walk Meilisearch operations expectations for the search backend.",
          href: @meilisearch_ops_guide
        }
      ]
      |> maybe_append_mix_status()

    {"Degraded",
     "#{err_count} schema(s) report fetch or sync errors on this refresh — treat as incident triage, not green.",
     checks}
  end

  defp jtbd_state({:ok, _rows}, 0, mount_path) do
    checks =
      [
        %{
          text: "Scan failed sync work periodically even when posture is green.",
          navigate: "#{mount_path}/failed-sync"
        },
        %{
          text: "Confirm drift and queue visibility when changing sync modes.",
          navigate: "#{mount_path}/sync-drift"
        },
        %{
          text: "Use search playground only after triage surfaces are quiet.",
          navigate: "#{mount_path}/search"
        }
      ]
      |> maybe_append_mix_status()

    {"Healthy", "No fetch errors on this refresh — continue spot-checking failed work and drift.",
     checks}
  end

  defp operator_mix_guide_path do
    Path.expand("../../../guides/operator-mix-tasks.md", __DIR__)
  end

  defp maybe_append_mix_status(checks) do
    path = operator_mix_guide_path()

    if File.exists?(path) and String.contains?(File.read!(path), "mix scrypath.status") do
      checks ++
        [
          %{
            text: "Snapshot a schema from the CLI when you need raw sync_status output.",
            mix: "mix scrypath.status"
          }
        ]
    else
      checks
    end
  end

  defp module_flat_name(mod) when is_atom(mod) do
    mod |> Atom.to_string() |> String.replace_prefix("Elixir.", "")
  end

  defp mod_from_allowlist(str, allowlist) when is_binary(str) do
    name = String.trim(str)

    case Enum.find(allowlist, &(module_flat_name(&1) == name)) do
      nil -> :error
      mod -> {:ok, mod}
    end
  end

  defp sort_rows(rows) do
    Enum.sort_by(
      rows,
      fn
        {_m, {:error, _}} -> 0
        _ -> 1
      end
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      mount_path={@mount_path}
      flash={@flash}
      shell={@shell}
      page_title={@page_title}
      ops_main_width={:wide}
    >
      <.ops_toolbar class="items-end gap-4">
        <.ops_page_header
          title={@page_title}
          subtitle="Refresh allowlisted schemas, inspect queue/backend posture, and promote a prepared index only when the signals are quiet."
        />
        <.ops_button phx-click="refresh" variant={:primary}>
          Refresh posture
        </.ops_button>
      </.ops_toolbar>

      <.ops_panel :if={@next_checks != []}>
        <section
          data-testid="posture-next-checks"
          aria-labelledby="posture-jtbd-heading"
          class={posture_next_checks_class(@posture_headline)}
        >
          <h2 id="posture-jtbd-heading" class="text-lg font-semibold text-base-content">
            {@posture_headline}
          </h2>
          <p class="mt-1 text-sm text-base-content/80">{@posture_evidence}</p>
          <ol class="mt-3 list-decimal list-inside space-y-2 text-sm text-base-content/90">
            <li :for={check <- @next_checks} class="pl-1">
              <span>{check.text}</span>
              <span :if={check[:navigate]} class="ml-2">
                <.link navigate={check.navigate} class="link link-primary">Open in OPSUI</.link>
              </span>
              <span :if={check[:href]} class="ml-2">
                <a href={check.href} class="link link-primary">Open guide</a>
              </span>
              <span :if={check[:mix]} class="mt-1 block font-mono text-xs text-base-content/70">
                {check.mix}
              </span>
            </li>
          </ol>
        </section>
      </.ops_panel>

      <p :if={@auto_refresh} class="mt-2 text-sm text-base-content/70">
        Auto-refresh is not enabled by default; only manual refresh runs in this build.
      </p>

      <.ops_empty_state
        :if={@posture_rows == :empty_allowlist}
        title="No Schemas Configured"
        class="mt-4"
      >
        No schemas configured for OPSUI. Set <code class="text-sm">schema_allowlist</code>
        under <code class="text-sm">:scrypath_ops</code>
        or use <code class="text-sm">SCRYPATH_OPS_SCHEMAS</code>
        — see <code class="text-sm">scrypath_ops/README.md</code>.
      </.ops_empty_state>

      <.ops_empty_state
        :if={@posture_rows == :missing_backend}
        title="Runtime Not Configured"
        class="mt-4"
      >
        Scrypath runtime is not configured (missing <code class="text-sm">:backend</code> and related
        options under <code class="text-sm">:scrypath_ops</code>). See <code class="text-sm">scrypath_ops/README.md</code>.
      </.ops_empty_state>

      <.ops_panel :if={match?({:ok, _}, @posture_rows)}>
        <section aria-labelledby="posture-fleet-heading">
          <h2 id="posture-fleet-heading" class="text-base font-semibold text-base-content">
            Per-schema signals
          </h2>
          <p class="mt-2 text-sm text-base-content/80">
            <span class="font-medium">{@aggregate_error_count}</span>
            schema(s) with fetch errors · refreshed
            <span class="font-mono text-xs tabular-nums">{format_dt(@last_refresh_at)}</span>
          </p>

          <.ops_table zebra class="mt-3">
            <thead>
              <tr>
                <th scope="col">Schema</th>
                <th scope="col">Index</th>
                <th scope="col">sync_mode</th>
                <th scope="col">Backend pending</th>
                <th scope="col">Backend failed</th>
                <th scope="col">Backend last OK</th>
                <th scope="col">Queue observed</th>
                <th scope="col">Queue pending</th>
                <th scope="col">Queue retrying</th>
                <th scope="col">Queue failed</th>
                <th scope="col">Queue last OK</th>
                <th scope="col">Actions</th>
              </tr>
            </thead>
            <tbody class="text-sm leading-snug tabular-nums">
              <%= for {mod, row} <- elem(@posture_rows, 1) do %>
                <tr data-testid="posture-row" id={"posture-#{inspect(mod)}"}>
                  <%= case row do %>
                    <% {:ok, status} -> %>
                      <td class="font-mono text-xs">{inspect(mod)}</td>
                      <td class="font-mono text-xs">{status.index}</td>
                      <td>{status.mode}</td>
                      <td>{length(status.backend.pending)}</td>
                      <td>{length(status.backend.failed)}</td>
                      <td>{format_state_ts(status.backend.last_succeeded)}</td>
                      <td>
                        <%= if status.queue.observed? do %>
                          true
                        <% else %>
                          <span class="text-warning">queue not observed</span>
                        <% end %>
                      </td>
                      <td>{length(status.queue.pending)}</td>
                      <td>{length(status.queue.retrying)}</td>
                      <td>{length(status.queue.failed)}</td>
                      <td>{format_state_ts(status.queue.last_succeeded)}</td>
                      <td>
                        <p class="mb-2 max-w-xs text-xs text-base-content/70">
                          Swaps the prepared target index into the live alias for this schema.
                        </p>
                        <.ops_button
                          phx-click="swap_live"
                          phx-value-schema={module_flat_name(mod)}
                          phx-disable-with="Swapping..."
                          size={:xs}
                        >
                          Swap live index
                        </.ops_button>
                      </td>
                    <% {:error, reason} -> %>
                      <td class="font-mono text-xs">{inspect(mod)}</td>
                      <td colspan="11" class="text-error">
                        fetch error: {inspect(reason)}
                      </td>
                  <% end %>
                </tr>
              <% end %>
            </tbody>
          </.ops_table>
        </section>
      </.ops_panel>
    </Layouts.app>
    """
  end

  defp posture_next_checks_class("Degraded"),
    do: "rounded-md border border-warning/40 bg-warning/10 p-3"

  defp posture_next_checks_class("Broken"),
    do: "rounded-md border border-error/40 bg-error/10 p-3"

  defp posture_next_checks_class("Not configured"),
    do: "rounded-md border border-warning/40 bg-warning/10 p-3"

  defp posture_next_checks_class(_),
    do: "ops-muted-panel p-3"

  defp format_dt(nil), do: "—"

  defp format_dt(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M:%SZ")
  end

  defp format_state_ts(nil), do: "—"
  defp format_state_ts(%Scrypath.Operator.State{} = s), do: format_dt(s.at)
end
