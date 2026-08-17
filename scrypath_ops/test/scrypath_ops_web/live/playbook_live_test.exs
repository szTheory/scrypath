defmodule ScrypathOpsWeb.PlaybookLiveTest do
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB
  alias ScrypathOps.Test.SearchPlaygroundStubAdapter

  setup do
    prev_allow = Application.get_env(:scrypath_ops, :schema_allowlist)
    prev_backend = Application.get_env(:scrypath_ops, :backend)
    prev_sync = Application.get_env(:scrypath_ops, :sync_mode)
    prev_prefix = Application.get_env(:scrypath_ops, :index_prefix)
    prev_url = Application.get_env(:scrypath_ops, :meilisearch_url)
    prev_adapter = Application.get_env(:scrypath_ops, :search_playground_adapter)
    prev_stub_variant = Application.get_env(:scrypath_ops, :search_stub_variant)
    prev_sigra = Application.get_env(:scrypath_ops, :sigra)
    prev_opsui_auth_mode = System.get_env("OPSUI_AUTH_MODE")

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])
    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
    Application.put_env(:scrypath_ops, :sync_mode, :manual)
    Application.put_env(:scrypath_ops, :index_prefix, "pblv_test")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :search_playground_adapter, SearchPlaygroundStubAdapter)
    Application.put_env(:scrypath_ops, :search_stub_variant, :ok)

    Application.put_env(:scrypath_ops, :sigra,
      sudo_confirm_path: "/sudo/confirm",
      sudo_window: 300
    )

    System.put_env("OPSUI_AUTH_MODE", "sigra")

    on_exit(fn ->
      restore = fn k, v ->
        if v == nil,
          do: Application.delete_env(:scrypath_ops, k),
          else: Application.put_env(:scrypath_ops, k, v)
      end

      restore.(:schema_allowlist, prev_allow)
      restore.(:backend, prev_backend)
      restore.(:sync_mode, prev_sync)
      restore.(:index_prefix, prev_prefix)
      restore.(:meilisearch_url, prev_url)
      restore.(:search_playground_adapter, prev_adapter)
      restore.(:search_stub_variant, prev_stub_variant)
      restore.(:sigra, prev_sigra)

      if prev_opsui_auth_mode == nil,
        do: System.delete_env("OPSUI_AUTH_MODE"),
        else: System.put_env("OPSUI_AUTH_MODE", prev_opsui_auth_mode)
    end)

    :ok
  end

  test "mount shows honesty panel", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")
    html = render(view)
    assert html =~ "Non-production playbook workspace"

    assert html =~
             "Use saved, repeatable search checks: preview, run, import, or save the next one."
  end

  test "empty workspace shows the empty hero and import anchor", %{conn: conn} do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_playbooks_empty_#{:erlang.unique_integer([:positive])}"
      )

    :ok = File.mkdir_p!(dir)
    prev_workspace = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    Application.put_env(:scrypath_ops, :playbook_workspace_dir, dir)

    on_exit(fn ->
      File.rm_rf(dir)

      if prev_workspace == nil,
        do: Application.delete_env(:scrypath_ops, :playbook_workspace_dir),
        else: Application.put_env(:scrypath_ops, :playbook_workspace_dir, prev_workspace)
    end)

    {:ok, _view, html} = live(conn, ~p"/ops/playbooks")

    assert html =~ ~s(data-testid="playbooks-empty-hero")
    assert html =~ "No playbooks yet"
    assert html =~ ~s(href="#playbook-import")
  end

  test "paste import validates and shows preview marker", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    html =
      view
      |> form("form[phx-submit='import_paste']", %{json: json})
      |> render_submit()

    assert html =~ "data-testid=\"playbook-preview-marker\""
  end

  test "run with stub adapter shows explicit lifecycle transition to success", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    view
    |> form("form[phx-submit='import_paste']", %{json: json})
    |> render_submit()

    running_html = render_click(view, "run", %{})
    assert running_html =~ "Running playbook"
    assert running_html =~ "Cancel run"

    html = render_async(view)
    assert html =~ "Run finished"
    refute html =~ "data-testid=\"run-failure-panel\""
  end

  test "bounded execution contract keeps the stable lifecycle affordances", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    view
    |> form("form[phx-submit='import_paste']", %{json: json})
    |> render_submit()

    running_html = render_click(view, "run", %{})
    assert running_html =~ "Running playbook"
    assert running_html =~ "Cancel run"

    html = render_async(view)
    assert html =~ "Run finished"
    refute html =~ "data-testid=\"run-failure-panel\""
  end

  # OPS-PB-05: end-to-end proof on SearchPlaygroundStubAdapter (no Meilisearch).
  test "OPS-PB-05 stub path: paste → save → listed → load → run", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    view
    |> form("form[phx-submit='import_paste']", %{json: json})
    |> render_submit()

    basename = "ops-pb-05-#{:erlang.unique_integer([:positive])}.json"

    view
    |> form("form[phx-submit='save']", %{basename: basename})
    |> render_submit()

    listed = render(view)
    assert listed =~ basename
    assert listed =~ ~s(phx-value-name="#{basename}")

    render_click(view, "load", %{"name" => basename})
    render_click(view, "run", %{})
    ran = render_async(view)
    assert ran =~ "Run finished" || ran =~ "Playbook run completed"
  end

  test "search_many paste then run shows multi-schema summary on stub", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search_many",
        "entries" => [
          ["ScrypathOps.Test.OpsPostA", "a", %{}],
          ["ScrypathOps.Test.OpsPostB", "b", %{}]
        ],
        "opts" => %{}
      })

    view
    |> form("form[phx-submit='import_paste']", %{json: json})
    |> render_submit()

    render_click(view, "run", %{})
    html = render_async(view)
    assert html =~ "schema(s)"
  end

  test "forced failure shows anchored doc links and copyable diagnostics", %{conn: conn} do
    prev_variant = Application.get_env(:scrypath_ops, :search_stub_variant)
    Application.put_env(:scrypath_ops, :search_stub_variant, :hard_error)

    on_exit(fn ->
      if prev_variant == nil,
        do: Application.delete_env(:scrypath_ops, :search_stub_variant),
        else: Application.put_env(:scrypath_ops, :search_stub_variant, prev_variant)
    end)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search_many",
        "entries" => [
          ["ScrypathOps.Test.OpsPostA", "a", %{}],
          ["ScrypathOps.Test.OpsPostB", "b", %{}]
        ],
        "opts" => %{}
      })

    view
    |> form("form[phx-submit='import_paste']", %{json: json})
    |> render_submit()

    render_click(view, "run", %{})
    html = render_async(view)
    doc_links = playbook_doc_links(html)

    assert html =~ "data-testid=\"run-failure-panel\""
    assert html =~ "backend"
    assert html =~ "Search adapter returned a forced hard failure."
    assert html =~ "Copy diagnostics"

    assert doc_links in [
             [
               "https://github.com/szTheory/scrypath/blob/main/scrypath_ops/docs/playbook-schema-v1.md#troubleshooting",
               "https://github.com/szTheory/scrypath/blob/main/scrypath_ops/docs/team-playbook-persistence.md",
               "https://github.com/szTheory/scrypath/blob/main/guides/multi-index-search.md"
             ],
             [
               "https://github.com/szTheory/scrypath/blob/main/scrypath_ops/docs/playbook-schema-v1.md",
               "https://github.com/szTheory/scrypath/blob/main/scrypath_ops/docs/playbook-schema-v1.md#troubleshooting",
               "https://github.com/szTheory/scrypath/blob/main/scrypath_ops/docs/team-playbook-persistence.md",
               "https://github.com/szTheory/scrypath/blob/main/guides/multi-index-search.md"
             ]
           ]

    copied = render_click(view, "copy_run_diagnostics", %{})
    assert copied =~ "Copied diagnostics."
  end

  test "forced failure keeps raw run_error before enrichment formatting", %{conn: conn} do
    prev_variant = Application.get_env(:scrypath_ops, :search_stub_variant)
    Application.put_env(:scrypath_ops, :search_stub_variant, :hard_error)

    on_exit(fn ->
      if prev_variant == nil,
        do: Application.delete_env(:scrypath_ops, :search_stub_variant),
        else: Application.put_env(:scrypath_ops, :search_stub_variant, prev_variant)
    end)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search_many",
        "entries" => [
          ["ScrypathOps.Test.OpsPostA", "a", %{}],
          ["ScrypathOps.Test.OpsPostB", "b", %{}]
        ],
        "opts" => %{}
      })

    view
    |> form("form[phx-submit='import_paste']", %{json: json})
    |> render_submit()

    render_click(view, "run", %{})
    _html = render_async(view)
    assigns = :sys.get_state(view.pid).socket.assigns

    assert assigns.run_error == :stub_hard_failure
    assert %{reason: "stub_hard_failure", failure_class: "backend"} = assigns.run_failure_enriched
    assert assigns.run_failure_enriched.message =~ "forced hard failure"
  end

  test "playbook run emits telemetry start and stop for a completed run", %{conn: conn} do
    unique = System.unique_integer([:positive])
    start_handler_id = "playbook-live-start-#{unique}"
    stop_handler_id = "playbook-live-stop-#{unique}"
    parent = self()

    :telemetry.attach(
      start_handler_id,
      [:scrypath_ops, :playbook_run, :start],
      fn _event, measurements, metadata, _config ->
        send(parent, {:telemetry_start, measurements, metadata})
      end,
      nil
    )

    :telemetry.attach(
      stop_handler_id,
      [:scrypath_ops, :playbook_run, :stop],
      fn _event, measurements, metadata, _config ->
        send(parent, {:telemetry_stop, measurements, metadata})
      end,
      nil
    )

    on_exit(fn ->
      :telemetry.detach(start_handler_id)
      :telemetry.detach(stop_handler_id)
    end)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    view
    |> form("form[phx-submit='import_paste']", %{json: json})
    |> render_submit()

    render_click(view, "run", %{})
    render_async(view)

    assert_receive {:telemetry_start, %{system_time: system_time}, %{run_id: run_id}}

    assert is_integer(system_time)
    assert is_integer(run_id)

    assert_receive {:telemetry_stop, %{duration: duration}, %{run_id: ^run_id, result: :ok}}

    assert is_integer(duration)
    assert duration >= 0
  end

  test "catalog run_now shows explicit lifecycle and success state", %{conn: conn} do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_pb_run_now_#{:erlang.unique_integer([:positive])}"
      )

    :ok = File.mkdir_p!(dir)
    prev_ws = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    Application.put_env(:scrypath_ops, :playbook_workspace_dir, dir)

    on_exit(fn ->
      File.rm_rf(dir)

      if prev_ws == nil,
        do: Application.delete_env(:scrypath_ops, :playbook_workspace_dir),
        else: Application.put_env(:scrypath_ops, :playbook_workspace_dir, prev_ws)
    end)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    basename = "catalog-run-#{System.unique_integer([:positive])}.json"

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    view
    |> form("form[phx-submit='import_paste']", %{json: json})
    |> render_submit()

    view
    |> form("form[phx-submit='save']", %{basename: basename})
    |> render_submit()

    running_html = render_click(view, "run_now", %{"name" => basename})
    assert running_html =~ "Running playbook"

    html = render_async(view)

    assert html =~ "Run finished"
    assert html =~ basename
    refute html =~ "data-testid=\"run-failure-panel\""
  end

  test "loading a new playbook while running cancels and resets the active run", %{conn: conn} do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_pb_supersede_#{:erlang.unique_integer([:positive])}"
      )

    :ok = File.mkdir_p!(dir)
    prev_ws = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    prev_variant = Application.get_env(:scrypath_ops, :search_stub_variant)
    Application.put_env(:scrypath_ops, :playbook_workspace_dir, dir)
    Application.put_env(:scrypath_ops, :search_stub_variant, :slow_ok)

    on_exit(fn ->
      File.rm_rf(dir)

      if prev_ws == nil,
        do: Application.delete_env(:scrypath_ops, :playbook_workspace_dir),
        else: Application.put_env(:scrypath_ops, :playbook_workspace_dir, prev_ws)

      if prev_variant == nil,
        do: Application.delete_env(:scrypath_ops, :search_stub_variant),
        else: Application.put_env(:scrypath_ops, :search_stub_variant, prev_variant)
    end)

    one_json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "one",
        "opts" => %{}
      })

    two_json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "two",
        "opts" => %{}
      })

    File.write!(Path.join(dir, "one.json"), one_json)
    File.write!(Path.join(dir, "two.json"), two_json)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    render_click(view, "load", %{"name" => "one.json"})
    running_html = render_click(view, "run", %{})
    assert running_html =~ "Running playbook"

    load_html = render_click(view, "load", %{"name" => "two.json"})
    assert load_html =~ "Loaded playbook from disk."
    refute load_html =~ "Playbook run cancelled before a result was applied."
    refute render_async(view) =~ "Playbook run cancelled before a result was applied."
  end

  test "superseded run exit does not override the newer run result", %{conn: conn} do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_pb_supersede_result_#{:erlang.unique_integer([:positive])}"
      )

    :ok = File.mkdir_p!(dir)
    prev_ws = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    prev_variant = Application.get_env(:scrypath_ops, :search_stub_variant)
    Application.put_env(:scrypath_ops, :playbook_workspace_dir, dir)
    Application.put_env(:scrypath_ops, :search_stub_variant, :slow_ok)

    on_exit(fn ->
      File.rm_rf(dir)

      if prev_ws == nil,
        do: Application.delete_env(:scrypath_ops, :playbook_workspace_dir),
        else: Application.put_env(:scrypath_ops, :playbook_workspace_dir, prev_ws)

      if prev_variant == nil,
        do: Application.delete_env(:scrypath_ops, :search_stub_variant),
        else: Application.put_env(:scrypath_ops, :search_stub_variant, prev_variant)
    end)

    one_json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "one",
        "opts" => %{}
      })

    two_json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "two",
        "opts" => %{}
      })

    File.write!(Path.join(dir, "one.json"), one_json)
    File.write!(Path.join(dir, "two.json"), two_json)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    render_click(view, "load", %{"name" => "one.json"})
    assert render_click(view, "run", %{}) =~ "Running playbook"

    load_html = render_click(view, "load", %{"name" => "two.json"})
    assert load_html =~ "Loaded playbook from disk."

    assert render_click(view, "run", %{}) =~ "Running playbook"

    html = render_async(view)
    assert html =~ "Run finished"
    refute html =~ "Playbook run cancelled before a result was applied."
    refute html =~ "data-testid=\"run-failure-panel\""
  end

  test "legacy workspace JSON without title shows Untitled playbook", %{conn: conn} do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_pb_untitled_#{:erlang.unique_integer([:positive])}"
      )

    :ok = File.mkdir_p!(dir)
    prev_ws = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    Application.put_env(:scrypath_ops, :playbook_workspace_dir, dir)

    on_exit(fn ->
      File.rm_rf(dir)

      if prev_ws == nil,
        do: Application.delete_env(:scrypath_ops, :playbook_workspace_dir),
        else: Application.put_env(:scrypath_ops, :playbook_workspace_dir, prev_ws)
    end)

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    File.write!(Path.join(dir, "legacy.json"), json)

    {:ok, _view, html} = live(conn, ~p"/ops/playbooks")
    assert html =~ "Untitled playbook"
    assert html =~ "legacy.json"
  end

  test "duplicate flow writes suggested copy basename", %{conn: conn} do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_pb_dup_#{:erlang.unique_integer([:positive])}"
      )

    :ok = File.mkdir_p!(dir)
    prev_ws = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    Application.put_env(:scrypath_ops, :playbook_workspace_dir, dir)

    on_exit(fn ->
      File.rm_rf(dir)

      if prev_ws == nil,
        do: Application.delete_env(:scrypath_ops, :playbook_workspace_dir),
        else: Application.put_env(:scrypath_ops, :playbook_workspace_dir, prev_ws)
    end)

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    File.write!(Path.join(dir, "one.json"), json)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    render_click(view, "dup_open", %{"name" => "one.json"})

    view
    |> form("form[phx-submit='dup_submit']", %{"to_name" => "one-1.json"})
    |> render_submit()

    assert File.exists?(Path.join(dir, "one-1.json"))
  end

  test "delete confirmation mismatch shows flash and keeps file", %{conn: conn} do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_pb_delcfm_#{:erlang.unique_integer([:positive])}"
      )

    :ok = File.mkdir_p!(dir)
    prev_ws = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    Application.put_env(:scrypath_ops, :playbook_workspace_dir, dir)

    on_exit(fn ->
      File.rm_rf(dir)

      if prev_ws == nil,
        do: Application.delete_env(:scrypath_ops, :playbook_workspace_dir),
        else: Application.put_env(:scrypath_ops, :playbook_workspace_dir, prev_ws)
    end)

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    path = Path.join(dir, "todelete.json")
    File.write!(path, json)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    render_click(view, "request_delete", %{"name" => "todelete.json"})

    html =
      view
      |> form("form[phx-submit='confirm_delete']", %{"confirm" => "wrong-name.json"})
      |> render_submit()

    assert html =~ "Confirmation must match the filename exactly."
    assert File.exists?(path)
  end

  test "sigra confirm delete redirects stale sudo and keeps the workspace file", %{} do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_pb_sigra_del_#{:erlang.unique_integer([:positive])}"
      )

    :ok = File.mkdir_p!(dir)
    prev_ws = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    Application.put_env(:scrypath_ops, :playbook_workspace_dir, dir)

    on_exit(fn ->
      File.rm_rf(dir)

      if prev_ws == nil,
        do: Application.delete_env(:scrypath_ops, :playbook_workspace_dir),
        else: Application.put_env(:scrypath_ops, :playbook_workspace_dir, prev_ws)
    end)

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    path = Path.join(dir, "sigra-delete.json")
    File.write!(path, json)

    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        flash: %{},
        delete_pending: "sigra-delete.json",
        workspace_root: dir,
        workspace_writable?: true,
        selected_basename: "sigra-delete.json",
        operator_context: %ScrypathOps.Integrations.Sigra.OperatorContext{
          user_id: "user_123",
          active_org_id: "org_456",
          impersonator_user_id: nil,
          sudo_at: DateTime.add(DateTime.utc_now(), -600, :second)
        }
      },
      host_uri: URI.parse("https://scrypath.example/ops/playbooks")
    }

    {:noreply, result_socket} =
      ScrypathOpsWeb.PlaybookLive.handle_event(
        "confirm_delete",
        %{"confirm" => "sigra-delete.json"},
        socket
      )

    socket = result_socket
    assert inspect(socket.redirected) =~ "/sudo/confirm"
    assert inspect(socket.redirected) =~ "return_to=%2Fops%2Fplaybooks"
    assert File.exists?(path)
  end

  test "sigra confirm delete clears only the selected playbook state", %{conn: conn} do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_pb_sigra_delete_ok_#{:erlang.unique_integer([:positive])}"
      )

    :ok = File.mkdir_p!(dir)
    prev_ws = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    Application.put_env(:scrypath_ops, :playbook_workspace_dir, dir)

    on_exit(fn ->
      File.rm_rf(dir)

      if prev_ws == nil,
        do: Application.delete_env(:scrypath_ops, :playbook_workspace_dir),
        else: Application.put_env(:scrypath_ops, :playbook_workspace_dir, prev_ws)
    end)

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    path = Path.join(dir, "sigra-delete-ok.json")
    File.write!(path, json)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    render_click(view, "load", %{"name" => "sigra-delete-ok.json"})
    render_click(view, "request_delete", %{"name" => "sigra-delete-ok.json"})

    put_live_assigns(view,
      current_scope: %{user: %{id: "user_123"}, active_organization: %{id: "org_456"}},
      operator_context: %ScrypathOps.Integrations.Sigra.OperatorContext{
        user_id: "user_123",
        active_org_id: "org_456",
        impersonator_user_id: nil,
        sudo_at: DateTime.add(DateTime.utc_now(), -60, :second)
      }
    )

    html =
      view
      |> form("form[phx-submit='confirm_delete']", %{"confirm" => "sigra-delete-ok.json"})
      |> render_submit()

    assert html =~ "Deleted sigra-delete-ok.json"
    refute File.exists?(path)

    assigns = :sys.get_state(view.pid).socket.assigns
    assert assigns.delete_pending == nil
    assert assigns.selected_basename == nil
    assert assigns.draft_playbook == nil
    assert assigns.preview_json == nil
    assert assigns.preview_marker == false
    assert assigns.run_result == nil
    assert assigns.run_error == nil
  end

  test "rename collision shows in-use flash", %{conn: conn} do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_pb_ren_#{:erlang.unique_integer([:positive])}"
      )

    :ok = File.mkdir_p!(dir)
    prev_ws = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    Application.put_env(:scrypath_ops, :playbook_workspace_dir, dir)

    on_exit(fn ->
      File.rm_rf(dir)

      if prev_ws == nil,
        do: Application.delete_env(:scrypath_ops, :playbook_workspace_dir),
        else: Application.put_env(:scrypath_ops, :playbook_workspace_dir, prev_ws)
    end)

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    File.write!(Path.join(dir, "a.json"), json)
    File.write!(Path.join(dir, "b.json"), json)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    render_click(view, "rename_open", %{"name" => "a.json"})

    html =
      view
      |> form("form[phx-submit='rename_submit']", %{"new_name" => "b.json"})
      |> render_submit()

    assert html =~ "That playbook name is already in use"
  end

  defp playbook_doc_links(html) do
    Regex.scan(~r/href="(https:\/\/github\.com\/szTheory\/scrypath\/blob\/main\/[^"]+)"/, html)
    |> Enum.map(fn [_, href] -> href end)
    |> Enum.uniq()
  end

  defp put_live_assigns(view, assigns) do
    :sys.replace_state(view.pid, fn state ->
      socket =
        Enum.reduce(assigns, state.socket, fn {key, value}, socket ->
          Phoenix.Component.assign(socket, key, value)
        end)

      %{state | socket: socket}
    end)
  end
end
