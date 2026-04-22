defmodule ScrypathOpsWeb.PlaybookLive do
  @moduledoc """
  Operator playbook library at `/ops/playbooks`: import, preview, run, and (when configured)
  persist JSON playbooks under `:playbook_workspace_dir`.

  ## Delete confirmation

  Deleting a workspace file requires typing the exact basename into the confirmation
  field and submitting **Confirm delete** — see UI-SPEC destructive copy.
  """

  use ScrypathOpsWeb, :live_view

  alias ScrypathOps.Playbook.Runner
  alias ScrypathOps.Playbook.Store
  alias ScrypathOps.Playbook.V1
  alias ScrypathOps.Schemas
  alias Scrypath.MultiSearchResult
  alias Scrypath.SearchResult

  @max_import_bytes 256_000
  @guide_href "https://github.com/szTheory/scrypath/blob/main/guides/multi-index-search.md"

  @impl true
  def mount(_params, _session, socket) do
    workspace_root = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    examples_dir = examples_playbooks_dir()
    workspace_writable? = workspace_root != nil
    {files, examples_mode?} = list_workspace_files(workspace_root, examples_dir)

    socket =
      socket
      |> assign(:page_title, "Saved playbooks")
      |> assign(:workspace_root, workspace_root)
      |> assign(:examples_dir, examples_dir)
      |> assign(:workspace_writable?, workspace_writable?)
      |> assign(:examples_mode?, examples_mode?)
      |> assign(:workspace_files, files)
      |> assign(:schema_allowlist, Schemas.allowlist())
      |> assign(:scrypath_opts, Schemas.scrypath_opts())
      |> assign(:draft_playbook, nil)
      |> assign(:preview_json, nil)
      |> assign(:preview_marker, false)
      |> assign(:selected_basename, nil)
      |> assign(:run_result, nil)
      |> assign(:run_error, nil)
      |> assign(:delete_pending, nil)
      |> assign(:save_basename, "")
      |> assign(:guide_href, @guide_href)
      |> assign(:max_import_bytes, @max_import_bytes)
      |> allow_upload(:playbook_file,
        accept: ~w(.json),
        max_entries: 1,
        max_file_size: @max_import_bytes,
        auto_upload: false
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("import_paste", %{"json" => raw}, socket) do
    bin = raw |> to_string()

    if byte_size(bin) > @max_import_bytes do
      {:noreply, put_flash(socket, :error, "Paste exceeds the maximum import size.")}
    else
      {:noreply, apply_decoded(socket, bin, :paste)}
    end
  end

  def handle_event("import_upload", _params, socket) do
    consume_uploaded_entries(socket, :playbook_file, fn %{path: path}, _entry ->
      case File.read(path) do
        {:ok, bin} -> {:ok, bin}
        {:error, _} -> {:error, :read_failed}
      end
    end)
    |> case do
      {socket, []} ->
        {:noreply, put_flash(socket, :error, "Choose a JSON file first.")}

      {socket, [bin]} when is_binary(bin) ->
        {:noreply, apply_decoded(socket, bin, :upload)}

      {socket, [{:error, _}]} ->
        {:noreply, put_flash(socket, :error, "Could not read the uploaded file.")}

      {socket, _} ->
        {:noreply, put_flash(socket, :error, "Unexpected upload result.")}
    end
  end

  def handle_event("load", %{"name" => name}, socket) do
    name = to_string(name)

    cond do
      not Store.safe_basename?(name) ->
        {:noreply, put_flash(socket, :error, "Invalid playbook file name.")}

      socket.assigns.workspace_root ->
        case Store.read_workspace_file(socket.assigns.workspace_root, name) do
          {:ok, bin} ->
            socket =
              socket
              |> assign(:selected_basename, name)
              |> apply_decoded(bin, :load)

            {:noreply, socket}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Could not read that playbook file.")}
        end

      socket.assigns.examples_dir ->
        path = Path.join(socket.assigns.examples_dir, name)

        if Store.safe_basename?(name) and File.exists?(path) do
          {:ok, bin} = File.read(path)

          socket =
            socket
            |> assign(:selected_basename, name)
            |> apply_decoded(bin, :load)

          {:noreply, socket}
        else
          {:noreply, put_flash(socket, :error, "Could not read that example file.")}
        end

      true ->
        {:noreply, put_flash(socket, :error, "No playbook directory is configured.")}
    end
  end

  def handle_event("run", _params, socket) do
    case socket.assigns.draft_playbook do
      nil ->
        {:noreply, put_flash(socket, :error, "Import or load a playbook before running.")}

      map ->
        case Runner.run_validated(
               map,
               socket.assigns.schema_allowlist,
               socket.assigns.scrypath_opts
             ) do
          {:ok, res} ->
            {:noreply,
             socket
             |> assign(:run_result, res)
             |> assign(:run_error, nil)
             |> put_flash(:info, "Playbook run completed.")}

          {:error, reason} ->
            {:noreply,
             socket
             |> assign(:run_result, nil)
             |> assign(:run_error, reason)
             |> put_flash(:error, format_run_flash(reason))}
        end
    end
  end

  def handle_event("save", %{"basename" => basename}, socket) do
    basename = basename |> to_string() |> String.trim()
    root = socket.assigns.workspace_root

    cond do
      not socket.assigns.workspace_writable? ->
        {:noreply,
         put_flash(socket, :error, "Saving requires a configured playbook workspace directory.")}

      not Store.safe_basename?(basename) ->
        {:noreply, put_flash(socket, :error, "Filename must match *.json basename rules.")}

      socket.assigns.draft_playbook == nil ->
        {:noreply,
         put_flash(socket, :error, "Nothing to save — import or load a playbook first.")}

      true ->
        case V1.encode(socket.assigns.draft_playbook) do
          {:ok, json} ->
            case Store.save_workspace_file(root, basename, json <> "\n") do
              :ok ->
                {:ok, files} = Store.list_workspace_json(root)

                {:noreply,
                 socket
                 |> assign(:workspace_files, files)
                 |> assign(:save_basename, "")
                 |> put_flash(:info, "Saved #{basename}")}

              {:error, _} ->
                {:noreply,
                 put_flash(socket, :error, "Save failed — check directory permissions.")}
            end

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Could not encode playbook for saving.")}
        end
    end
  end

  def handle_event("request_delete", %{"name" => name}, socket) do
    name = to_string(name)

    if Store.safe_basename?(name) do
      {:noreply, assign(socket, :delete_pending, name)}
    else
      {:noreply, put_flash(socket, :error, "Invalid playbook file name.")}
    end
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, :delete_pending, nil)}
  end

  def handle_event("confirm_delete", %{"confirm" => typed}, socket) do
    pending = socket.assigns.delete_pending
    typed = typed |> to_string() |> String.trim()
    root = socket.assigns.workspace_root

    cond do
      pending == nil ->
        {:noreply, socket}

      not socket.assigns.workspace_writable? ->
        {:noreply, put_flash(socket, :error, "Delete is disabled for read-only examples.")}

      typed != pending ->
        {:noreply, put_flash(socket, :error, "Confirmation must match the filename exactly.")}

      true ->
        case Store.delete_workspace_file(root, pending) do
          :ok ->
            {:ok, files} = Store.list_workspace_json(root)

            socket =
              socket
              |> assign(:workspace_files, files)
              |> assign(:delete_pending, nil)

            socket =
              if socket.assigns.selected_basename == pending do
                socket
                |> assign(:selected_basename, nil)
                |> assign(:draft_playbook, nil)
                |> assign(:preview_json, nil)
                |> assign(:preview_marker, false)
                |> assign(:run_result, nil)
                |> assign(:run_error, nil)
              else
                socket
              end

            {:noreply, put_flash(socket, :info, "Deleted #{pending}")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Delete failed — check permissions.")}
        end
    end
  end

  def handle_event("refresh_list", _params, socket) do
    {files, _} = list_workspace_files(socket.assigns.workspace_root, socket.assigns.examples_dir)
    {:noreply, assign(socket, :workspace_files, files)}
  end

  defp apply_decoded(socket, bin, source) do
    case Jason.decode(bin) do
      {:ok, %{} = map} ->
        case V1.validate(map) do
          {:ok, validated} ->
            preview = Jason.encode!(validated, pretty: true)

            socket
            |> assign(:draft_playbook, validated)
            |> assign(:preview_json, preview)
            |> assign(:preview_marker, true)
            |> put_flash(:info, flash_for_import(source))

          {:error, {:invalid_playbook, reason}} ->
            socket
            |> assign(:draft_playbook, nil)
            |> assign(:preview_json, nil)
            |> assign(:preview_marker, false)
            |> put_flash(
              :error,
              "Playbook failed validation: #{format_validation_reason(reason)}"
            )
        end

      {:ok, _} ->
        put_flash(socket, :error, "This file is not valid playbook JSON.")

      {:error, _} ->
        put_flash(socket, :error, "This file is not valid playbook JSON.")
    end
  end

  defp flash_for_import(:paste), do: "Imported playbook from paste."
  defp flash_for_import(:upload), do: "Imported playbook from file."
  defp flash_for_import(:load), do: "Loaded playbook from disk."

  defp format_validation_reason(reason) do
    reason |> inspect() |> String.slice(0, 240)
  end

  defp format_run_flash({:page_size_out_of_range, n, max}),
    do: "Playbook run failed: page.size #{n} is outside 1..#{max}."

  defp format_run_flash({:config, :missing_backend}),
    do: "Playbook run failed: Scrypath backend is not configured."

  defp format_run_flash({:config, :empty_allowlist}),
    do: "Playbook run failed: schema allowlist is empty."

  defp format_run_flash({:config, :no_schema}),
    do: "Playbook run failed: schema is not on the configured allowlist."

  defp format_run_flash({:config, :invalid_query}),
    do: "Playbook run failed: query field is invalid."

  defp format_run_flash({:config, :invalid_entries}),
    do: "Playbook run failed: entries list is invalid."

  defp format_run_flash({:config, :invalid_entry_shape}),
    do: "Playbook run failed: an entry has an invalid shape."

  defp format_run_flash(other),
    do:
      "Playbook run failed: #{inspect(other)} — adjust entries or operator config, then run again."

  defp list_workspace_files(nil, examples_dir) do
    files =
      if examples_dir && File.dir?(examples_dir) do
        examples_dir
        |> File.ls!()
        |> Enum.filter(&Store.safe_basename?/1)
        |> Enum.sort()
      else
        []
      end

    {files, true}
  end

  defp list_workspace_files(root, _examples) when is_binary(root) do
    case Store.list_workspace_json(root) do
      {:ok, files} -> {files, false}
      {:error, _} -> {[], false}
    end
  end

  defp examples_playbooks_dir do
    Application.app_dir(:scrypath_ops, "priv/playbooks")
  end

  defp run_result_summary(%SearchResult{} = r), do: "Run finished — hits: #{length(r.hits)}"

  defp run_result_summary(%MultiSearchResult{} = r),
    do: "Run finished — #{length(r.ordered)} schema(s)."

  defp run_result_summary(_), do: "Run finished."

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} shell={@shell} ops_main_width={:wide}>
      <div class="space-y-6">
        <.ops_page_header title={@page_title} />

        <div
          id="playbook-honesty-panel"
          class="rounded-md border border-warning/40 bg-warning/10 px-sm py-sm text-sm text-base-content"
        >
          <strong>Non-production playbook workspace</strong>
          — exploratory runs use the same bounded search path as the playground and may be logged by backends or proxies.
          <strong>Do not</strong>
          paste production secrets or PII; keep <code class="text-xs">page.size</code>
          and schema lists within configured caps.
        </div>

        <div class="card bg-base-100 border border-base-300 rounded-lg p-4 md:p-6 space-y-6">
          <div class="flex flex-wrap items-center justify-between gap-sm">
            <h2 class="text-lg font-semibold">Workspace files</h2>
            <button type="button" phx-click="refresh_list" class="btn btn-sm btn-ghost">
              Reload list
            </button>
          </div>

          <p :if={@examples_mode?} class="text-sm text-base-content/80">
            Examples (read-only) — set <code class="text-sm">SCRYPATH_OPS_PLAYBOOK_DIR</code>
            to enable saving and deleting under a dedicated directory. See
            <.link class="link link-hover" navigate={~p"/ops/search"}>Search &amp; federation</.link>
            to export a playbook JSON, then use <strong>Import playbook JSON</strong>
            below.
          </p>

          <p :if={@workspace_files == []} class="text-base-content/80">
            <span class="text-heading font-semibold">No playbooks in this folder</span>
            — export a playbook from Search or import JSON to add a <code class="text-xs">.json</code>
            file. Schema reference: <a
              class="link link-hover"
              href="https://github.com/szTheory/scrypath/blob/main/scrypath_ops/docs/playbook-schema-v1.md"
            >
              playbook-schema-v1.md
            </a>.
          </p>

          <ul :if={@workspace_files != []} class="menu menu-sm bg-base-200 rounded-md max-w-xl">
            <li
              :for={name <- @workspace_files}
              class="flex flex-wrap items-center gap-2 justify-between"
            >
              <span class="font-mono text-xs">{name}</span>
              <span class="flex gap-1">
                <button
                  type="button"
                  phx-click="load"
                  phx-value-name={name}
                  class="btn btn-xs btn-ghost"
                >
                  Load
                </button>
                <button
                  :if={@workspace_writable?}
                  type="button"
                  phx-click="request_delete"
                  phx-value-name={name}
                  class="btn btn-xs btn-error btn-outline"
                >
                  Delete
                </button>
              </span>
            </li>
          </ul>

          <div class="divider" />

          <section class="space-y-md">
            <h2 class="text-lg font-semibold">Import playbook JSON</h2>
            <.form for={%{}} phx-submit="import_upload" class="space-y-sm max-w-xl">
              <label class="label">
                <span class="label-text text-sm font-semibold">
                  Upload (.json, max {@max_import_bytes} bytes)
                </span>
              </label>
              <.live_file_input
                upload={@uploads.playbook_file}
                class="file-input file-input-bordered w-full max-w-md"
              />
              <button type="submit" class="btn btn-primary btn-sm min-h-10">
                Import playbook JSON
              </button>
            </.form>

            <details class="max-w-xl">
              <summary class="cursor-pointer text-sm link link-hover">Or paste JSON</summary>
              <.form for={%{}} phx-submit="import_paste" class="mt-2 space-y-sm">
                <textarea
                  name="json"
                  class="textarea textarea-bordered w-full font-mono text-xs min-h-32"
                  placeholder="Paste playbook JSON"
                ></textarea>
                <button type="submit" class="btn btn-ghost btn-sm">Import from paste</button>
              </.form>
            </details>
          </section>

          <div :if={@draft_playbook} class="space-y-md">
            <div class="divider" />
            <h2 class="text-lg font-semibold">Preview</h2>
            <p
              :if={@preview_marker}
              class="text-xs text-base-content/70"
              data-testid="playbook-preview-marker"
            >
              Validated playbook preview
            </p>
            <pre
              :if={@preview_json}
              class="max-h-96 overflow-auto rounded-md bg-base-200 p-sm text-xs font-mono whitespace-pre-wrap break-words"
            ><%= @preview_json %></pre>

            <div class="flex flex-wrap gap-sm items-end">
              <button
                :if={@schema_allowlist != [] && Keyword.has_key?(@scrypath_opts, :backend)}
                type="button"
                phx-click="run"
                class="btn btn-primary min-h-10"
              >
                Run saved playbook
              </button>
              <p
                :if={@schema_allowlist == [] or !Keyword.has_key?(@scrypath_opts, :backend)}
                class="text-sm text-base-content/70"
              >
                Configure schema allowlist and Scrypath backend to enable runs (see README).
              </p>
            </div>

            <p :if={@run_error} class="alert alert-error text-sm">
              <strong>Playbook run failed:</strong>
              {format_run_flash(@run_error)} Next: adjust the playbook or operator config, then
              <strong>Run saved playbook</strong>
              again.
              <a :if={@draft_playbook["mode"] == "search_many"} class="link" href={@guide_href}>
                Multi-index guide
              </a>
            </p>

            <p :if={@run_result} class="alert alert-success text-sm">
              {run_result_summary(@run_result)}
            </p>

            <div :if={@workspace_writable?} class="space-y-sm max-w-md">
              <h3 class="text-sm font-semibold">Save playbook to disk</h3>
              <.form for={%{}} phx-submit="save" class="flex flex-wrap gap-2 items-end">
                <div>
                  <label class="label label-text text-xs" for="save_basename">Basename (.json)</label>
                  <input
                    id="save_basename"
                    type="text"
                    name="basename"
                    value={@save_basename}
                    class="input input-bordered input-sm w-64"
                    placeholder="my-playbook.json"
                  />
                </div>
                <button type="submit" class="btn btn-primary btn-sm min-h-10">
                  Save playbook to disk
                </button>
              </.form>
            </div>
          </div>

          <div :if={@delete_pending} class="modal modal-open">
            <div class="modal-box">
              <h3 class="font-bold text-lg">Delete playbook file</h3>
              <p class="py-4 text-sm">
                This permanently deletes <code class="font-mono text-xs">{@delete_pending}</code>
                from the playbook directory. This cannot be undone.
              </p>
              <.form for={%{}} phx-submit="confirm_delete" class="space-y-sm">
                <label class="label">
                  <span class="label-text">Type the filename to confirm</span>
                </label>
                <input
                  type="text"
                  name="confirm"
                  class="input input-bordered w-full font-mono text-sm"
                  autocomplete="off"
                />
                <div class="modal-action">
                  <button type="button" class="btn" phx-click="cancel_delete">Cancel</button>
                  <button type="submit" class="btn btn-error">Confirm delete</button>
                </div>
              </.form>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
