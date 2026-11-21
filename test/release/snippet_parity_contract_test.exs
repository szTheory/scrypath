defmodule Scrypath.Release.SnippetParityContractTest do
  # Deliberately untagged: drift between the README and golden path snippets fails the default
  # `mix test` and the `core` lane. It reads files only (no network, no docs build).
  #
  # This file proves the parity check can fail and can pass. The planted cases are in-memory
  # strings only; no shipped file is edited to prove a check. The last test reads the real README
  # and golden path so the check cannot go vacuous (the parity assertions themselves live in
  # test/scrypath/readme_contract_test.exs, which calls the same module).
  use ExUnit.Case, async: true

  alias Scrypath.Release.SnippetParity

  @schema "defmodule A do\n  use Scrypath,\n    fields: [:title]\nend"
  @other "defmodule A do\n  use Scrypath,\n    fields: [:title, :body]\nend"
  @marker "<!-- scrypath:snippet-intentionally-differs: shorter on purpose -->"

  # A small markdown document: a heading, an optional line (a marker) and one elixir fence.
  defp doc(body, above \\ nil) do
    ["# Title", "", above, "```elixir", body, "```", ""]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end

  describe "schema snippet parity" do
    test "identical snippets pass" do
      assert SnippetParity.check(doc(@schema), doc(@schema), :schema) == :identical
    end

    test "different snippets without a marker fail" do
      assert SnippetParity.check(doc(@schema), doc(@other), :schema) == {:error, :differs}
    end

    test "a marker with a reason above either snippet lets them differ" do
      assert SnippetParity.check(doc(@schema, @marker), doc(@other), :schema) ==
               {:marked, :readme, "shorter on purpose"}

      assert SnippetParity.check(doc(@schema), doc(@other, @marker), :schema) ==
               {:marked, :golden, "shorter on purpose"}
    end

    test "a marker without a reason fails, including the old bare form" do
      bare = "<!-- scrypath:snippet-intentionally-differs -->"
      colon = "<!-- scrypath:snippet-intentionally-differs: -->"
      blank = "<!-- scrypath:snippet-intentionally-differs:    -->"

      for marker <- [bare, colon, blank] do
        assert SnippetParity.check(doc(@schema, marker), doc(@other), :schema) ==
                 {:error, :empty_reason}

        assert SnippetParity.check(doc(@schema), doc(@other, marker), :schema) ==
                 {:error, :empty_reason}

        # A malformed marker is an error even when the bodies match.
        assert SnippetParity.check(doc(@schema, marker), doc(@schema), :schema) ==
                 {:error, :empty_reason}
      end
    end

    test "a blank line between the marker and the fence still counts" do
      readme = "# Title\n\n#{@marker}\n\n\n```elixir\n#{@schema}\n```\n"

      assert SnippetParity.check(readme, doc(@other), :schema) ==
               {:marked, :readme, "shorter on purpose"}
    end

    test "a marker that is not the last thing before the fence does not count" do
      readme = "# Title\n\n#{@marker}\n\nSome sentence.\n\n```elixir\n#{@schema}\n```\n"

      assert SnippetParity.check(readme, doc(@other), :schema) == {:error, :differs}
    end

    test "a fence without use Scrypath, is not the schema snippet" do
      ecto = "defmodule A do\n  use Ecto.Schema\nend"
      no_comma = "defmodule A do\n  use Scrypath\nend"

      text =
        "```elixir\n#{ecto}\n```\n\n```elixir\n#{no_comma}\n```\n\n```elixir\n#{@schema}\n```\n"

      assert %{body: body} = SnippetParity.schema_fence(text)
      assert body == @schema <> "\n"

      assert SnippetParity.schema_fence("```elixir\n#{ecto}\n```\n```elixir\n#{no_comma}\n```\n") ==
               nil
    end

    test "a missing schema snippet on either side fails" do
      without = "# Title\n\n```elixir\nIO.puts(:hi)\n```\n"

      assert SnippetParity.check(without, doc(@schema), :schema) ==
               {:error, {:missing_fence, :readme}}

      assert SnippetParity.check(doc(@schema), without, :schema) ==
               {:error, {:missing_fence, :golden}}
    end
  end

  describe "config snippet parity" do
    @config "import Config\n\nconfig :scrypath, :defaults, backend: Scrypath.Meilisearch"

    test "the config fence is the first elixir fence with config :scrypath" do
      text = doc(@schema) <> "\n" <> doc(@config)

      assert %{body: body} = SnippetParity.config_fence(text)
      assert body == @config <> "\n"
      assert SnippetParity.check(doc(@config), doc(@config), :config) == :identical

      assert SnippetParity.check(doc(@config), doc(@config <> "\n# more"), :config) ==
               {:error, :differs}

      assert SnippetParity.check(doc(@schema), doc(@config), :config) ==
               {:error, {:missing_fence, :readme}}
    end
  end

  describe "fences and prose" do
    test "fences reports language, body and offsets, and prose removes fenced code" do
      text = "Before.\n\n```elixir\nx = 1\n```\n\n```sh\nls\n```\n\nAfter.\n"

      assert [%{lang: "elixir", body: "x = 1\n"} = first, %{lang: "sh", body: "ls\n"}] =
               SnippetParity.fences(text)

      assert binary_part(text, first.start, first.stop - first.start) ==
               "```elixir\nx = 1\n```"

      assert [%{lang: "elixir"}] = SnippetParity.elixir_fences(text)

      prose = SnippetParity.prose(text)
      assert prose =~ "Before."
      assert prose =~ "After."
      refute prose =~ "x = 1"
      refute prose =~ "ls"
    end

    test "marker reads the text directly above a fence" do
      text = "# T\n\n#{@marker}\n\n```elixir\nx\n```\n\n```elixir\ny\n```\n"
      [first, second] = SnippetParity.fences(text)

      assert SnippetParity.marker(text, first) == {:ok, "shorter on purpose"}
      assert SnippetParity.marker(text, second) == :none
    end
  end

  describe "the real files" do
    test "the real README and golden path each resolve a schema and a config snippet" do
      for path <- ["README.md", "guides/golden-path.md"] do
        text = File.read!(path)

        schema = SnippetParity.schema_fence(text)
        config = SnippetParity.config_fence(text)

        assert schema, "#{path} has no elixir fence containing `use Scrypath,`"
        assert config, "#{path} has no elixir fence containing `config :scrypath`"
        assert schema.body =~ "use Scrypath,"
        assert String.trim(config.body) != ""
      end
    end
  end
end
