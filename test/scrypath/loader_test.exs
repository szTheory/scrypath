defmodule Scrypath.LoaderTest do
  use ExUnit.Case, async: true

  alias Scrypath.Loader
  alias Scrypath.TestSupport.FakeRepo

  defmodule CustomLoaderPost do
    use Ecto.Schema

    use Scrypath, fields: [:title]

    schema "loader_custom_posts" do
      field(:title, :string)
    end

    # Omits 2 and 4, returns 3 with a string id, and adds an out-of-batch
    # extra (99) that must never be prepared for indexing.
    def search_records(ids, context) do
      send(self(), {:search_records, ids, context})

      loaded =
        ids
        |> Enum.reject(&(&1 in [2, 4]))
        |> Enum.map(fn
          3 -> %__MODULE__{id: "3", title: "Loaded 3"}
          id -> %__MODULE__{id: id, title: "Loaded #{id}"}
        end)

      Enum.reverse([%__MODULE__{id: 99, title: "Out of batch"} | loaded])
    end
  end

  defmodule CustomIdPost do
    use Ecto.Schema

    use Scrypath, fields: [:title]

    schema "loader_custom_id_posts" do
      field(:slug, :string)
      field(:title, :string)
    end

    def search_document_id(post), do: post.slug
  end

  defmodule PreloadPost do
    use Ecto.Schema

    use Scrypath, fields: [:title], preload: [:author]

    schema "loader_preload_posts" do
      field(:title, :string)
      belongs_to(:author, QueryableAuthor)
    end
  end

  defmodule PreloadRepo do
    def preload(records, preload, opts) do
      send(self(), {:preload, records, preload, opts})
      Enum.map(records, &%{&1 | author: %QueryableAuthor{id: &1.author_id, name: "A"}})
    end
  end

  setup do
    FakeRepo.reset()
    :ok
  end

  test "prepare_records/3 returns rows unchanged without touching the repo when no preload is declared" do
    rows = [%QueryablePost{id: 1, title: "One"}, %QueryablePost{id: 2, title: "Two"}]

    assert {:ok, ^rows, []} = Loader.prepare_records(QueryablePost, rows, repo: FakeRepo)

    refute_received {:fake_repo_all, _}
  end

  test "prepare_records/3 force-preloads the declared preload on the default path" do
    rows = [%PreloadPost{id: 1, title: "One", author_id: 7}]

    assert {:ok, [%PreloadPost{author: %QueryableAuthor{id: 7}}], []} =
             Loader.prepare_records(PreloadPost, rows, repo: PreloadRepo)

    assert_received {:preload, ^rows, [:author], [force: true]}
  end

  test "prepare_records/3 routes a custom loader through search_records/2 and keeps only batch records" do
    rows = Enum.map(1..4, &%CustomLoaderPost{id: &1, title: "Row #{&1}"})

    assert {:ok, records, omitted} =
             Loader.prepare_records(CustomLoaderPost, rows, repo: FakeRepo)

    assert_received {:search_records, [1, 2, 3, 4], %{repo: FakeRepo}}
    assert records |> Enum.map(&to_string(&1.id)) |> Enum.sort() == ["1", "3"]
    assert Enum.all?(records, &String.starts_with?(&1.title, "Loaded"))
    refute Enum.any?(records, &(&1.id == 99))
    assert omitted == [2, 4]
  end

  test "prepare_records/3 with no rows calls no loader" do
    assert {:ok, [], []} = Loader.prepare_records(CustomLoaderPost, [], repo: FakeRepo)
    assert {:ok, [], []} = Loader.prepare_records(QueryablePost, [], repo: FakeRepo)

    refute_received {:search_records, _, _}
    refute_received {:fake_repo_all, _}
  end

  test "prepare_records/3 keeps search_document_id/1 schemas without search_records/2 working" do
    rows = [%CustomIdPost{id: 1, slug: "first", title: "First"}]

    assert {:ok, ^rows, []} = Loader.prepare_records(CustomIdPost, rows, repo: FakeRepo)
  end
end
