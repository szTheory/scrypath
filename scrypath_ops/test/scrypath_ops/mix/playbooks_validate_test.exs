defmodule ScrypathOps.Mix.PlaybooksValidateTest do
  use ExUnit.Case, async: true

  @moduletag timeout: 120_000

  test "mix scrypath_ops.playbooks.validate succeeds on examples/playbooks" do
    ops_root = Path.expand("../../..", __DIR__)
    {output, 0} = mix_validate(ops_root, ["examples/playbooks"])
    assert output =~ "Validated"
  end

  test "mix scrypath_ops.playbooks.validate fails on invalid playbook json" do
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
        "scrypath_ops_playbooks_validate_#{:erlang.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp)

    on_exit(fn -> File.rm_rf(tmp) end)

    File.write!(Path.join(tmp, "bad.json"), Jason.encode!(bad))

    {output, 1} = mix_validate(ops_root, [tmp])
    assert output =~ "bad.json"
  end

  defp mix_validate(ops_root, extra_args) do
    args = ["scrypath_ops.playbooks.validate"] ++ extra_args

    env =
      System.get_env()
      |> Map.put("MIX_ENV", "test")
      |> Map.to_list()

    System.cmd("mix", args, cd: ops_root, env: env, stderr_to_stdout: true)
  end
end
