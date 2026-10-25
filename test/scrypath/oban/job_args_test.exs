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

  defmodule RelatedSchema do
    def __scrypath__(:fan_outs) do
      [comments: [target: SearchablePost, resolver: {__MODULE__, :resolve, []}]]
    end

    def __scrypath__(:document_id), do: :id
  end

  # Answers __scrypath__/1 but has no :fan_outs clause, so the lookup raises.
  defmodule NoFanOutSchema do
    def __scrypath__(:document_id), do: :id
  end

  @related_schema to_string(RelatedSchema)
  @fake_repo "Elixir.Scrypath.TestSupport.FakeRepo"

  defp related_args(overrides \\ %{}) do
    Map.merge(
      %{
        "schema" => @related_schema,
        "fan_out" => "comments",
        "document_ids" => [1, 2],
        "opts" => %{}
      },
      overrides
    )
  end

  defp related_opts(opts), do: related_args(%{"opts" => opts})

  describe "decode_related/1" do
    test "decodes a valid related job with every allowlisted opt" do
      args =
        related_opts(%{
          "index_prefix" => "tenant",
          "meilisearch_url" => "http://localhost:7700",
          "backend" => @full_backend,
          "otp_app" => "logger",
          "repo" => @fake_repo
        })

      assert {:ok, decoded} = JobArgs.decode_related(args)
      assert decoded.schema == RelatedSchema
      assert decoded.fan_out == :comments
      assert decoded.fan_out_config[:target] == SearchablePost
      assert decoded.document_ids == [1, 2]

      assert Enum.sort(decoded.opts) == [
               backend: FullBackend,
               index_prefix: "tenant",
               meilisearch_url: "http://localhost:7700",
               otp_app: :logger,
               repo: Scrypath.TestSupport.FakeRepo
             ]
    end

    test "nil and empty-string opts count as absent" do
      args =
        related_opts(%{
          "repo" => nil,
          "otp_app" => nil,
          "index_prefix" => nil,
          "backend" => "",
          "meilisearch_url" => ""
        })

      assert {:ok, %{opts: []}} = JobArgs.decode_related(args)
    end

    test "unknown opts keys are ignored, not cancelled" do
      assert {:ok, %{opts: opts}} =
               JobArgs.decode_related(related_opts(%{"future_key" => "x", "index_prefix" => "t"}))

      assert opts == [index_prefix: "t"]
    end

    for {label, args_fun, tag} <- [
          {"unknown schema", {:args, %{"schema" => "Elixir.Nope.Schema"}},
           {:unknown_schema, "Elixir.Nope.Schema"}},
          {"loaded module without __scrypath__/1", {:args, %{"schema" => "Elixir.String"}},
           {:unknown_schema, "Elixir.String"}},
          {"missing schema", {:drop, "schema"}, {:invalid_arg, "schema"}},
          {"fan_out that is not an existing atom", {:args, %{"fan_out" => "zz_never_an_atom_xq"}},
           {:unknown_fan_out, "zz_never_an_atom_xq"}},
          {"existing atom not configured as a fan_out", {:args, %{"fan_out" => "title"}},
           {:unknown_fan_out, "title"}},
          {"schema whose fan_outs lookup raises",
           {:args, %{"schema" => to_string(NoFanOutSchema)}}, {:unknown_fan_out, "comments"}},
          {"missing fan_out", {:drop, "fan_out"}, {:invalid_arg, "fan_out"}},
          {"missing document_ids", {:drop, "document_ids"}, {:invalid_arg, "document_ids"}},
          {"missing opts", {:drop, "opts"}, {:invalid_arg, "opts"}},
          {"non-map opts", {:args, %{"opts" => []}}, {:invalid_arg, "opts"}},
          {"unknown backend", {:opts, %{"backend" => "Elixir.Nope.Backend"}},
           {:unknown_backend, "Elixir.Nope.Backend"}},
          {"delete-only backend", {:opts, %{"backend" => @delete_backend}},
           {:unknown_backend, @delete_backend}},
          {"unknown repo", {:opts, %{"repo" => "Elixir.Nope.Repo"}},
           {:unknown_repo, "Elixir.Nope.Repo"}},
          {"repo without the Elixir. prefix",
           {:opts, %{"repo" => "Scrypath.TestSupport.FakeRepo"}},
           {:unknown_repo, "Scrypath.TestSupport.FakeRepo"}},
          {"otp_app that is not an atom", {:opts, %{"otp_app" => "zz_not_an_app_xq"}},
           {:unknown_otp_app, "zz_not_an_app_xq"}},
          {"otp_app that is an atom but not an app", {:opts, %{"otp_app" => "ok"}},
           {:unknown_otp_app, "ok"}}
        ] do
      test "returns #{inspect(tag)} for #{label}" do
        args =
          case unquote(Macro.escape(args_fun)) do
            {:args, overrides} -> related_args(overrides)
            {:opts, opts} -> related_opts(opts)
            {:drop, key} -> Map.delete(related_args(), key)
          end

        assert JobArgs.decode_related(args) == {:error, unquote(Macro.escape(tag))}
      end
    end
  end

  describe "atom safety" do
    test "decoding unknown names twice gives the same tag and creates no atoms" do
      fresh = fn -> "Elixir.Zz#{System.unique_integer([:positive])}" end

      jobs = [
        fn name -> JobArgs.decode_upsert(upsert_args(%{"schema" => name})) end,
        fn name -> JobArgs.decode_upsert(upsert_args(%{"backend" => name})) end,
        fn name -> JobArgs.decode_upsert(upsert_args(%{"repo" => name})) end,
        fn name -> JobArgs.decode_delete(delete_args(%{"schema" => name})) end,
        fn name -> JobArgs.decode_related(related_args(%{"schema" => name})) end,
        fn name -> JobArgs.decode_related(related_args(%{"fan_out" => name})) end,
        fn name -> JobArgs.decode_related(related_opts(%{"backend" => name})) end,
        fn name -> JobArgs.decode_related(related_opts(%{"repo" => name})) end,
        fn name -> JobArgs.decode_related(related_opts(%{"otp_app" => name})) end,
        fn name -> JobArgs.decode_related(related_opts(%{name => "value"})) end
      ]

      # Warm up once so module loading cannot add atoms during the measured decodes.
      Enum.each(jobs, & &1.(fresh.()))

      for decode <- jobs do
        name = fresh.()
        before = :erlang.system_info(:atom_count)
        first = decode.(name)
        second = decode.(name)
        after_count = :erlang.system_info(:atom_count)

        assert first == second
        assert after_count == before
      end
    end
  end

  # In a release a loaded BEAM adds only its full module atom to the atom table; the
  # bare alias segments exist only when some parsed source names them. This module is
  # built at runtime from strings, so neither segment ever appears as an atom in this
  # VM, matching what a release sees for an app's own schema, backend and repo.
  @segments ["Zq" <> "rel" <> "Seg", "Sch" <> "ema" <> "Vq"]

  setup_all do
    module = Module.concat(@segments)

    unless Code.ensure_loaded?(module) do
      contents =
        quote do
          def __scrypath__(:fan_outs), do: [comments: [target: SearchablePost]]
          def __scrypath__(:document_id), do: :id
          def upsert_documents(_schema, _documents, _config), do: {:ok, %{}}
          def delete_documents(_schema, _ids, _config), do: {:ok, %{}}
          def index_name(_schema, _config), do: "idx"
          def __adapter__, do: Ecto.Adapters.SQL
        end

      Module.create(module, contents, Macro.Env.location(__ENV__))
    end

    %{runtime_module: module, runtime_name: Atom.to_string(module)}
  end

  describe "module names whose alias segments are not atoms" do
    test "the alias segments really are not atoms" do
      for segment <- @segments do
        assert_raise ArgumentError, fn -> String.to_existing_atom(segment) end
      end
    end

    test "decode_upsert resolves schema, backend and repo", %{
      runtime_module: module,
      runtime_name: name
    } do
      args = upsert_args(%{"schema" => name, "backend" => name, "repo" => name})

      assert {:ok, decoded} = JobArgs.decode_upsert(args)
      assert decoded.schema == module
      assert decoded.backend == module
      assert decoded.opts[:repo] == module
    end

    test "decode_delete resolves schema and backend", %{
      runtime_module: module,
      runtime_name: name
    } do
      assert {:ok, decoded} =
               JobArgs.decode_delete(delete_args(%{"schema" => name, "backend" => name}))

      assert decoded.schema == module
      assert decoded.backend == module
    end

    test "decode_related resolves the schema and the backend and repo opts",
         %{runtime_module: module, runtime_name: name} do
      args = related_args(%{"schema" => name, "opts" => %{"backend" => name, "repo" => name}})

      assert {:ok, decoded} = JobArgs.decode_related(args)
      assert decoded.schema == module
      assert decoded.opts[:backend] == module
      assert decoded.opts[:repo] == module
    end

    test "decoding leaves the alias segments uncreated", %{runtime_name: name} do
      assert {:ok, _} = JobArgs.decode_upsert(upsert_args(%{"schema" => name}))

      for segment <- @segments do
        assert_raise ArgumentError, fn -> String.to_existing_atom(segment) end
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
