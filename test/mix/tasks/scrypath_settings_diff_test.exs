defmodule Mix.Tasks.Scrypath.Settings.DiffTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Scrypath.Settings.Diff
  alias Scrypath.Meilisearch.Settings

  describe "compute/2 (pure, reuses Settings.compute_drift/2)" do
    test "returns :parity on declared-subset-of-applied" do
      assert :parity ==
               Diff.compute(
                 %{"synonyms" => %{}},
                 %{"synonyms" => %{}, "rankingRules" => ["words"]}
               )
    end

    test "returns {:drift, list} when values diverge" do
      assert {:drift, drift} =
               Diff.compute(
                 %{"rankingRules" => ["words", "typo"]},
                 %{"rankingRules" => ["typo"]}
               )

      assert [{"rankingRules", ["words", "typo"], ["typo"]}] == drift
    end

    test "returns {:drift, list} with :not_present when declared key missing from applied" do
      assert {:drift, drift} =
               Diff.compute(
                 %{"synonyms" => %{"nyc" => ["new york"]}},
                 %{}
               )

      assert [{"synonyms", %{"nyc" => ["new york"]}, :not_present}] == drift
    end
  end

  describe "render_json/7 (stable field order)" do
    test "parity shape decodes to expected map (no error key)" do
      json = Diff.render_json(SearchablePost, "posts", :parity, %{}, %{}, [])
      decoded = Jason.decode!(json)

      assert decoded["schema"] == "SearchablePost"
      assert decoded["index"] == "posts"
      assert decoded["status"] == "parity"
      assert decoded["declared"] == %{}
      assert decoded["applied"] == %{}
      assert decoded["drift"] == []
      refute Map.has_key?(decoded, "error")
    end

    test "stable key order: schema < index < status < declared < applied < drift" do
      json = Diff.render_json(SearchablePost, "posts", :parity, %{}, %{}, [])

      keys = [
        "\"schema\":",
        "\"index\":",
        "\"status\":",
        "\"declared\":",
        "\"applied\":",
        "\"drift\":"
      ]

      positions = Enum.map(keys, fn k -> :binary.match(json, k) |> elem(0) end)
      pairs = Enum.zip(positions, Enum.drop(positions, 1))
      assert Enum.all?(pairs, fn {a, b} -> a < b end)
    end

    test "drift shape" do
      drift = [{"rankingRules", ["words"], ["typo"]}]
      json = Diff.render_json(SearchablePost, "posts", :drift, %{}, %{}, drift)
      decoded = Jason.decode!(json)

      assert decoded["status"] == "drift"
      assert [%{"key" => "rankingRules"} | _] = decoded["drift"]
    end

    test "error shape" do
      json = Diff.render_json(SearchablePost, "posts", :error, %{}, %{}, [], "Index not found")
      decoded = Jason.decode!(json)

      assert decoded["status"] == "error"
      assert decoded["error"] == "Index not found"
      assert decoded["drift"] == []
    end
  end

  describe "render_table/5" do
    test "parity returns single-line 'No drift detected' message" do
      output = Diff.render_table(SearchablePost, "posts", %{}, %{}, [])
      assert output =~ "No drift detected for"
      assert output =~ "SearchablePost"
    end

    test "drift includes DRIFT header and declared/applied labels and reindex pointer" do
      drift = [{"rankingRules", ["words", "typo"], ["typo"]}]
      output = Diff.render_table(SearchablePost, "posts", %{}, %{}, drift)

      assert output =~ "DRIFT for"
      assert output =~ "rankingRules"
      assert output =~ "declared:"
      assert output =~ "applied:"
      assert output =~ "mix scrypath.reindex"
    end
  end

  defmodule StubDiffClient do
    def get_settings(_index, _config) do
      Application.fetch_env!(:scrypath, :settings_diff_stub_response)
    end

    def update_settings(_, _, _), do: {:ok, %{"taskUid" => 1}}
  end

  describe "run/1 integration" do
    setup do
      orig = Application.get_env(:scrypath, :defaults)

      Application.put_env(:scrypath, :defaults,
        backend: Scrypath.Meilisearch,
        meilisearch_url: "http://localhost:7700",
        meilisearch_client: StubDiffClient
      )

      on_exit(fn ->
        if orig,
          do: Application.put_env(:scrypath, :defaults, orig),
          else: Application.delete_env(:scrypath, :defaults)

        Application.delete_env(:scrypath, :settings_diff_stub_response)
      end)

      :ok
    end

    test "parity path prints 'No drift detected' and returns normally" do
      full =
        Scrypath.Config.resolve!(
          backend: Scrypath.Meilisearch,
          meilisearch_url: "http://localhost:7700",
          meilisearch_client: StubDiffClient
        )

      wire =
        SearchablePost
        |> Settings.resolve(full)
        |> Settings.translate_settings()

      Application.put_env(:scrypath, :settings_diff_stub_response, {:ok, wire})

      out =
        capture_io(fn ->
          assert :ok == Diff.run(["SearchablePost"])
        end)

      assert out =~ "No drift detected"
    end

    test "index-not-found raises Mix.Error" do
      Application.put_env(
        :scrypath,
        :settings_diff_stub_response,
        {:error, {:http_error, 404, "x"}}
      )

      assert_raise Mix.Error, ~r/index not found/i, fn ->
        Diff.run(["SearchablePost"])
      end
    end

    test "--json flag switches output format on parity" do
      full =
        Scrypath.Config.resolve!(
          backend: Scrypath.Meilisearch,
          meilisearch_url: "http://localhost:7700",
          meilisearch_client: StubDiffClient
        )

      wire =
        SearchablePost
        |> Settings.resolve(full)
        |> Settings.translate_settings()

      Application.put_env(:scrypath, :settings_diff_stub_response, {:ok, wire})

      out =
        capture_io(fn ->
          Diff.run(["SearchablePost", "--json"])
        end)

      assert %{"status" => "parity"} = Jason.decode!(out)
    end
  end
end
