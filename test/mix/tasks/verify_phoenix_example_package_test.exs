defmodule Mix.Tasks.Verify.PhoenixExample.PackageTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "service preflight failure prevents package commands and redacts endpoint values" do
    secret_url = "http://user:secret@example.test:7700"
    original = System.get_env("SCRYPATH_MEILISEARCH_URL")
    System.put_env("SCRYPATH_MEILISEARCH_URL", secret_url)

    on_exit(fn ->
      if original,
        do: System.put_env("SCRYPATH_MEILISEARCH_URL", original),
        else: System.delete_env("SCRYPATH_MEILISEARCH_URL")
    end)

    runner = fn _, _, _ -> flunk("package command ran before service preflight") end

    output =
      capture_io(fn ->
        error =
          assert_raise Mix.Error, ~r/service stage: invalid SCRYPATH_MEILISEARCH_URL/, fn ->
            Mix.Tasks.Verify.PhoenixExample.Package.run(
              service_check: fn ->
                Mix.raise("invalid SCRYPATH_MEILISEARCH_URL: #{secret_url}")
              end,
              command_runner: runner
            )
          end

        Process.put(:package_preflight_error, error)
      end)

    error = Process.delete(:package_preflight_error)
    refute output =~ secret_url
    refute Exception.message(error) =~ secret_url
  end

  test "package proof module provides an explicit local artifact command" do
    source = File.read!("lib/mix/tasks/verify/phoenix_example/package.ex")
    assert source =~ ~s|"hex.build", "--unpack", "--output"|
    assert source =~ "SCRYPATH_EXAMPLE_INTEGRATION"
    assert source =~ "MIX_HOME"
  end

  test "artifact command failure reports status and removes the owned workspace" do
    runner = fn "mix", ["hex.build", "--unpack", "--output", artifact], _opts ->
      Process.put(:package_test_root, Path.dirname(artifact))
      {"artifact failed", 17}
    end

    assert_raise Mix.Error,
                 ~r/artifact stage: mix hex.build --unpack --output .* exited 17/,
                 fn ->
                   Mix.Tasks.Verify.PhoenixExample.Package.run(
                     service_check: fn -> :ok end,
                     command_runner: runner
                   )
                 end

    root = Process.delete(:package_test_root)
    refute File.exists?(root)
  end

  test "failed workspace retention is opt in" do
    runner = fn "mix", ["hex.build", "--unpack", "--output", artifact], _opts ->
      Process.put(:package_test_root, Path.dirname(artifact))
      {"synthetic build failure", 9}
    end

    output =
      capture_io(fn ->
        assert_raise Mix.Error, ~r/exited 9/, fn ->
          Mix.Tasks.Verify.PhoenixExample.Package.run(
            service_check: fn -> :ok end,
            command_runner: runner,
            keep_temp_on_failure: true
          )
        end
      end)

    root = Process.delete(:package_test_root)
    assert output =~ "Retained failed package proof workspace: #{root}"
    assert File.dir?(root)
    File.rm_rf!(root)
  end
end
