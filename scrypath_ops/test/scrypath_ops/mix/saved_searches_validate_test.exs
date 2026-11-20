defmodule ScrypathOps.Mix.SavedSearchesValidateTest do
  # Synchronous on purpose: the child `mix` process compiles into the same build directory as
  # this test run. On a fresh build (CI, `mix verify.ops_ui`) Mix sees the path dependency's
  # `.app` as older than this project's `.mix/compile.lock`, so the child recompiles the modules
  # that depend on `scrypath` at compile time and deletes their `.beam` files for a moment. An
  # async test that lazily loads one of them in that window (for example
  # `ScrypathOps.Phase173FixtureSource`) fails with "module is not available". ExUnit runs
  # synchronous modules alone, after every async module. The last test below keeps every child-mix
  # test synchronous.
  use ExUnit.Case, async: false

  @moduletag timeout: 120_000

  @test_root Path.expand("../..", __DIR__)
  @mix_child ~r/System\.cmd\(\s*"mix"/
  @async_true ~r/use\s+[\w.]+Case\s*,\s*(?:[^\n]*,\s*)?async:\s*true/

  test "mix scrypath_ops.saved_searches.validate succeeds on examples/saved_searches" do
    ops_root = Path.expand("../../..", __DIR__)
    {output, 0} = mix_validate(ops_root, ["examples/saved_searches"])
    assert output =~ "Validated"
  end

  test "mix scrypath_ops.saved_searches.validate fails on invalid saved search json" do
    ops_root = Path.expand("../../..", __DIR__)

    bad = %{
      "playbook_format" => 2,
      "mode" => "search",
      "schema" => "X",
      "q" => "q",
      "opts" => %{}
    }

    tmp =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_saved_searches_validate_#{:erlang.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp)

    on_exit(fn -> File.rm_rf(tmp) end)

    File.write!(Path.join(tmp, "bad.json"), Jason.encode!(bad))

    {output, 1} = mix_validate(ops_root, [tmp])
    assert output =~ "bad.json"
  end

  test "tests that run a child mix process in the shared build are not async" do
    child_mix_tests =
      @test_root
      |> Path.join("**/*.exs")
      |> Path.wildcard()
      |> Enum.filter(&Regex.match?(@mix_child, File.read!(&1)))

    assert Path.relative_to(__ENV__.file, @test_root) in Enum.map(
             child_mix_tests,
             &Path.relative_to(&1, @test_root)
           )

    async_offenders =
      child_mix_tests
      |> Enum.filter(&Regex.match?(@async_true, File.read!(&1)))
      |> Enum.map(&Path.relative_to(&1, @test_root))

    assert async_offenders == [],
           "these tests run a child `mix` in the shared build but are async: " <>
             inspect(async_offenders)
  end

  defp mix_validate(ops_root, extra_args) do
    args = ["scrypath_ops.saved_searches.validate"] ++ extra_args

    env =
      System.get_env()
      |> Map.put("MIX_ENV", "test")
      |> Map.to_list()

    System.cmd("mix", args, cd: ops_root, env: env, stderr_to_stdout: true)
  end
end
