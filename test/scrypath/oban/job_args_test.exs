defmodule Scrypath.Oban.JobArgsTest do
  # Not async: the atom-count assertion must not see atoms other tests create.
  use ExUnit.Case, async: false

  alias Scrypath.Oban.JobArgs

  defmodule FullBackend do
    def upsert_documents(_schema, _documents, _config), do: {:ok, %{}}
    def delete_documents(_schema, _ids, _config), do: {:ok, %{}}
    def index_name(_schema, _config), do: "idx"
  end

  defmodule DeleteOnlyBackend do
    def delete_documents(_schema, _ids, _config), do: {:ok, %{}}
    def index_name(_schema, _config), do: "idx"
  end

  @schema "Elixir.SearchablePost"
  @full_backend to_string(FullBackend)
  @delete_backend to_string(DeleteOnlyBackend)

  defp delete_args(overrides \\ %{}) do
    Map.merge(
      %{
        "schema" => @schema,
        "backend" => @delete_backend,
        "index" => "idx",
        "document_ids" => [1, 2],
        "document_count" => 2
      },
      overrides
    )
  end

  describe "decode_delete/1" do
    test "decodes a valid delete job" do
      assert {:ok, decoded} = JobArgs.decode_delete(delete_args())

      assert decoded == %{
               schema: SearchablePost,
               backend: DeleteOnlyBackend,
               index: "idx",
               document_ids: [1, 2],
               opts: []
             }
    end

    test "accepts a full backend and carries runtime opts" do
      args = delete_args(%{"backend" => @full_backend, "index_prefix" => "tenant"})

      assert {:ok, %{backend: FullBackend, opts: [index_prefix: "tenant"]}} =
               JobArgs.decode_delete(args)
    end

    test "ignores a repo on a delete job, even an unknown one" do
      assert {:ok, decoded} = JobArgs.decode_delete(delete_args(%{"repo" => "Elixir.Nope.Repo"}))
      refute Keyword.has_key?(decoded.opts, :repo)
    end

    for {label, overrides, drop, tag} <- [
          {"unknown schema", %{"schema" => "Elixir.Nope.Schema"}, nil,
           {:unknown_schema, "Elixir.Nope.Schema"}},
          {"loaded module without __scrypath__/1", %{"schema" => "Elixir.String"}, nil,
           {:unknown_schema, "Elixir.String"}},
          {"schema without the Elixir. prefix", %{"schema" => "SearchablePost"}, nil,
           {:unknown_schema, "SearchablePost"}},
          {"missing schema", %{}, "schema", {:invalid_arg, "schema"}},
          {"non-string schema", %{"schema" => 42}, nil, {:invalid_arg, "schema"}},
          {"unknown backend", %{"backend" => "Elixir.Nope.Backend"}, nil,
           {:unknown_backend, "Elixir.Nope.Backend"}},
          {"backend without delete_documents/3", %{"backend" => "Elixir.String"}, nil,
           {:unknown_backend, "Elixir.String"}},
          {"missing backend", %{}, "backend", {:invalid_arg, "backend"}},
          {"empty index", %{"index" => ""}, nil, {:invalid_arg, "index"}},
          {"missing index", %{}, "index", {:invalid_arg, "index"}},
          {"missing document_ids", %{}, "document_ids", {:invalid_arg, "document_ids"}},
          {"non-list document_ids", %{"document_ids" => "1,2"}, nil,
           {:invalid_arg, "document_ids"}},
          {"document_count mismatch", %{"document_count" => 3}, nil,
           {:invalid_arg, "document_count"}},
          {"missing document_count", %{}, "document_count", {:invalid_arg, "document_count"}}
        ] do
      test "returns #{inspect(tag)} for #{label}" do
        args = delete_args(unquote(Macro.escape(overrides)))
        args = if unquote(drop), do: Map.delete(args, unquote(drop)), else: args

        assert JobArgs.decode_delete(args) == {:error, unquote(Macro.escape(tag))}
      end
    end
  end

  defp upsert_args(overrides \\ %{}) do
    Map.merge(
      %{
        "schema" => @schema,
        "backend" => @full_backend,
        "index" => "idx",
        "document_ids" => [1, 2],
        "document_count" => 2
      },
      overrides
    )
  end

  describe "decode_upsert/1" do
    test "decodes a valid upsert job with a repo" do
      args = upsert_args(%{"repo" => to_string(Scrypath.TestSupport.FakeRepo)})

      assert {:ok, decoded} = JobArgs.decode_upsert(args)
      assert decoded.schema == SearchablePost
      assert decoded.backend == FullBackend
      assert decoded.index == "idx"
      assert decoded.document_ids == [1, 2]
      assert decoded.opts[:repo] == Scrypath.TestSupport.FakeRepo
    end

    test "an absent, nil or empty repo is the legacy path with no :repo" do
      for args <- [
            upsert_args(),
            upsert_args(%{"repo" => nil}),
            upsert_args(%{"repo" => ""})
          ] do
        assert {:ok, decoded} = JobArgs.decode_upsert(args)
        refute Keyword.has_key?(decoded.opts, :repo)
      end
    end

    for {label, overrides, drop, tag} <- [
          {"unknown schema", %{"schema" => "Elixir.Nope.Schema"}, nil,
           {:unknown_schema, "Elixir.Nope.Schema"}},
          {"missing schema", %{}, "schema", {:invalid_arg, "schema"}},
          {"unknown backend", %{"backend" => "Elixir.Nope.Backend"}, nil,
           {:unknown_backend, "Elixir.Nope.Backend"}},
          {"delete-only backend", %{"backend" => @delete_backend}, nil,
           {:unknown_backend, @delete_backend}},
          {"unknown repo", %{"repo" => "Elixir.Nope.Repo"}, nil,
           {:unknown_repo, "Elixir.Nope.Repo"}},
          {"loaded repo without __adapter__/0", %{"repo" => "Elixir.String"}, nil,
           {:unknown_repo, "Elixir.String"}},
          {"repo without the Elixir. prefix", %{"repo" => "Scrypath.TestSupport.FakeRepo"}, nil,
           {:unknown_repo, "Scrypath.TestSupport.FakeRepo"}},
          {"missing document_ids", %{}, "document_ids", {:invalid_arg, "document_ids"}},
          {"empty index", %{"index" => ""}, nil, {:invalid_arg, "index"}}
        ] do
      test "returns #{inspect(tag)} for #{label}" do
        args = upsert_args(unquote(Macro.escape(overrides)))
        args = if unquote(drop), do: Map.delete(args, unquote(drop)), else: args

        assert JobArgs.decode_upsert(args) == {:error, unquote(Macro.escape(tag))}
      end
    end
  end

  describe "resolve_config/1" do
    test "resolves a valid config" do
      assert {:ok, config} = JobArgs.resolve_config(backend: FullBackend, sync_mode: :manual)
      assert config[:backend] == FullBackend
    end

    test "turns a config ArgumentError into an invalid_config tag" do
      assert {:error, {:invalid_config, message}} =
               JobArgs.resolve_config(backend: FullBackend, sync_mode: :not_a_mode)

      assert is_binary(message)
    end
  end
end
