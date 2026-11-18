defmodule Mix.Tasks.Verify.PostgresTest do
  # Mutates SCRYPATH_POSTGRES_URL and the global Mix shell.
  use ExUnit.Case, async: false

  test "fails loudly naming SCRYPATH_POSTGRES_URL when the URL is unset" do
    previous = System.get_env("SCRYPATH_POSTGRES_URL")
    System.delete_env("SCRYPATH_POSTGRES_URL")

    on_exit(fn ->
      if previous, do: System.put_env("SCRYPATH_POSTGRES_URL", previous)
    end)

    error =
      assert_raise Mix.Error, ~r/SCRYPATH_POSTGRES_URL is required/, fn ->
        Mix.Task.reenable("verify.postgres")
        Mix.Task.run("verify.postgres", [])
      end

    assert error.message =~ "docker compose up -d postgres"
    assert error.message =~ "mix verify.postgres"
  end

  test "verify.backend runs the Meilisearch smoke before the Postgres loader suite" do
    previous_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(previous_shell) end)

    Mix.Tasks.Verify.Capability.run(:backend, ["--skip-integration"])

    messages = drain_shell_info([])

    meili_index =
      Enum.find_index(messages, &(&1 =~ "Skipping Meilisearch smoke (--skip-integration)"))

    postgres_index =
      Enum.find_index(messages, &(&1 =~ "Skipping Postgres loader suite (--skip-integration)"))

    assert is_integer(meili_index), "missing Meilisearch skip message in #{inspect(messages)}"
    assert is_integer(postgres_index), "missing Postgres skip message in #{inspect(messages)}"
    assert meili_index < postgres_index
  end

  defp drain_shell_info(acc) do
    receive do
      {:mix_shell, :info, [message]} -> drain_shell_info([message | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end
end
