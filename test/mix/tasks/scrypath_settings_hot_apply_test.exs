defmodule Mix.Tasks.Scrypath.Settings.HotApplyTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Scrypath.Settings.HotApply

  defmodule HotApplyAckSchema do
    use Ecto.Schema

    use Scrypath,
      fields: [:title],
      index_prefix: "hot_apply_ack_test"

    embedded_schema do
      field(:title, :string)
    end
  end

  test "missing --ack-live raises Mix.Error" do
    tmp =
      Path.join(
        System.tmp_dir!(),
        "scrypath-hot-apply-#{:erlang.unique_integer([:positive])}.json"
      )

    File.write!(tmp, Jason.encode!(%{"stopWords" => []}))

    on_exit(fn -> File.rm(tmp) end)

    assert_raise Mix.Error, ~r/--ack-live/i, fn ->
      HotApply.run([
        "Mix.Tasks.Scrypath.Settings.HotApplyTest.HotApplyAckSchema",
        "--settings-file",
        tmp
      ])
    end
  end

  test "missing --settings-file raises Mix.Error" do
    assert_raise Mix.Error, ~r/--settings-file/i, fn ->
      HotApply.run([
        "Mix.Tasks.Scrypath.Settings.HotApplyTest.HotApplyAckSchema",
        "--ack-live"
      ])
    end
  end
end
