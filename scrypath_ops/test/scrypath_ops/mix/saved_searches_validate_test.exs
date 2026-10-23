defmodule ScrypathOps.Mix.SavedSearchesValidateTest do
  use ExUnit.Case, async: true

  @moduletag timeout: 120_000

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

  defp mix_validate(ops_root, extra_args) do
    args = ["scrypath_ops.saved_searches.validate"] ++ extra_args

    env =
      System.get_env()
      |> Map.put("MIX_ENV", "test")
      |> Map.to_list()

    System.cmd("mix", args, cd: ops_root, env: env, stderr_to_stdout: true)
  end
end
