defmodule Mix.Tasks.Scrypath.Settings.ReadTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Scrypath.Settings.Read

  defmodule Read404Schema do
    use Ecto.Schema

    use Scrypath,
      fields: [:title],
      index_prefix: "missing"

    embedded_schema do
      field(:title, :string)
    end
  end

  setup do
    orig = Application.get_env(:scrypath, :defaults)

    stub = Module.concat(__MODULE__, ReadSettingsReqStub)

    Req.Test.stub(stub, fn conn ->
      case {conn.method, conn.request_path} do
        {"GET", "/indexes/scrypath_searchable_post/settings"} ->
          Req.Test.json(conn, %{
            "rankingRules" => ["words", "typo"],
            "synonyms" => %{"nyc" => ["new york"]}
          })

        {"GET", "/indexes/missing_read404_schema/settings"} ->
          conn |> Plug.Conn.put_status(404) |> Req.Test.json(%{"message" => "nope"})

        _ ->
          Req.Test.json(conn, %{})
      end
    end)

    Application.put_env(:scrypath, :defaults,
      backend: Scrypath.Meilisearch,
      meilisearch_url: "http://localhost:7700",
      req_options: [plug: {Req.Test, stub}]
    )

    on_exit(fn ->
      if orig,
        do: Application.put_env(:scrypath, :defaults, orig),
        else: Application.delete_env(:scrypath, :defaults)
    end)

    :ok
  end

  test "prints pretty settings map on success" do
    out =
      capture_io(fn ->
        Read.run(["SearchablePost"])
      end)

    assert out =~ "rankingRules"
    assert out =~ "synonyms"
    assert out =~ "words"
    assert out =~ "new york"
  end

  test "404 raises Mix.Error" do
    assert_raise Mix.Error, ~r/index not found/i, fn ->
      Read.run(["Mix.Tasks.Scrypath.Settings.ReadTest.Read404Schema"])
    end
  end
end
