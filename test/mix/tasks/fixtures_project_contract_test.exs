defmodule Scrypath.Mix.FixturesProjectContractTest do
  use ExUnit.Case, async: true

  # Pins the shape of the dev and test only fixtures project (ADR 0002, v1.49 Phase 196) and the decisions
  # its README records. Everything here is a pure function over file text or an AST, with planted inputs
  # that each assert their own cause, so no check can pass because something unrelated broke.

  @ops_manifest "scrypath_ops/mix.exs"
  @fixtures_manifest "fixtures/scrypath_fixtures/mix.exs"
  @fixtures_readme "fixtures/scrypath_fixtures/README.md"
  @check_task "scrypath_fixtures.check_fixtures"

  # The README must keep saying each of these (the exit rule, the second-consumer definition, the phase173
  # deletion trigger and the fictional-data statement). Each is removed once below and must be reported alone.
  @readme_phrases [
    "second consumer",
    "other than `scrypath_ops`",
    "Phase 197",
    "scrypath_ops/catalog/",
    "PRESERVATION_FIXTURE_FILES",
    "ops_reskin_contract.spec.ts",
    "ui_iteration3.spec.ts",
    "ui_followup.spec.ts",
    "ui_baseline.spec.ts",
    "fictional",
    "never ships"
  ]

  describe "check task wiring in scrypath_ops" do
    test "the check is the first step of the test alias and runs in the test environment" do
      assert alias_violations(@ops_manifest) == []
    end

    test "planted manifests are each rejected for their own cause" do
      tmp = tmp_dir!("fixtures-alias")
      steps = ["scrypath_ops.check_nav_contract", "ecto.create --quiet", "test"]

      compliant = ops_manifest!(tmp, "compliant.exs", [@check_task | steps], @check_task)

      second =
        ops_manifest!(
          tmp,
          "second.exs",
          ["scrypath_ops.check_nav_contract", @check_task, "test"],
          @check_task
        )

      missing = ops_manifest!(tmp, "missing.exs", steps, @check_task)
      wrong_env = ops_manifest!(tmp, "wrong_env.exs", [@check_task | steps], @check_task, ":dev")
      no_env = ops_manifest!(tmp, "no_env.exs", [@check_task | steps], "other.task")

      assert alias_violations(compliant) == []

      assert alias_violations(second) ==
               ["#{@check_task} must be the first step of the test alias, found it at position 2"]

      assert alias_violations(missing) ==
               ["the test alias must run #{@check_task}, but it does not"]

      assert alias_violations(wrong_env) ==
               ["cli/0 preferred_envs must map #{@check_task} to :test, got :dev"]

      assert alias_violations(no_env) ==
               ["cli/0 preferred_envs has no entry for #{@check_task}"]
    end
  end

  describe "fixtures project manifest" do
    test "depends only on scrypath by path, with no other option" do
      assert fixtures_manifest_violations(@fixtures_manifest) == []
    end

    test "planted manifests are each rejected for their own cause" do
      tmp = tmp_dir!("fixtures-manifest")

      compliant = deps_manifest!(tmp, "compliant.exs", ~s({:scrypath, path: "../.."}))

      only = deps_manifest!(tmp, "only.exs", ~s({:scrypath, path: "../..", only: [:dev, :test]}))

      second =
        deps_manifest!(tmp, "second.exs", ~s({:scrypath, path: "../.."}, {:jason, "~> 1.4"}))

      wrong_path = deps_manifest!(tmp, "wrong_path.exs", ~s({:scrypath, path: "../../.."}))
      hex = deps_manifest!(tmp, "hex.exs", ~s({:scrypath, "~> 0.3"}))
      none = deps_manifest!(tmp, "none.exs", ~s({:jason, "~> 1.4"}))

      assert fixtures_manifest_violations(compliant) == []

      assert fixtures_manifest_violations(only) ==
               [
                 "the :scrypath dependency must be exactly path: \"../..\", found extra option only: [:dev, :test]"
               ]

      assert fixtures_manifest_violations(second) ==
               ["the fixtures project must depend only on :scrypath, but also lists [:jason]"]

      assert fixtures_manifest_violations(wrong_path) ==
               ["the :scrypath dependency must use path: \"../..\", got \"../../..\""]

      assert fixtures_manifest_violations(hex) ==
               ["the :scrypath dependency must use path: \"../..\", got nil"]

      assert fixtures_manifest_violations(none) ==
               [
                 "the fixtures project must declare {:scrypath, path: \"../..\"}, but :scrypath is absent"
               ]
    end
  end

  describe "fixtures project tracked files" do
    test "no lock file and nothing under test/, config/ or priv/ is tracked" do
      {output, status} =
        System.cmd("git", ["ls-files", "fixtures/scrypath_fixtures"], stderr_to_stdout: true)

      assert status == 0, "git ls-files failed: #{output}"
      tracked = String.split(output, "\n", trim: true)

      assert "fixtures/scrypath_fixtures/mix.exs" in tracked,
             "the positive control is gone: mix.exs is not tracked, so the shape check read nothing"

      assert tracked_file_violations(tracked) == []
    end

    test "planted file lists are each rejected for their own cause" do
      root = "fixtures/scrypath_fixtures"
      clean = ["#{root}/mix.exs", "#{root}/lib/a.ex", "#{root}/recordings/x.json"]

      assert tracked_file_violations(clean) == []

      assert tracked_file_violations(clean ++ ["#{root}/mix.lock"]) ==
               [
                 "#{root}/mix.lock: the fixtures project has no Hex dependency, so it keeps no lock file"
               ]

      for dir <- ["test", "config", "priv"] do
        path = "#{root}/#{dir}/x.exs"

        assert tracked_file_violations(clean ++ [path]) ==
                 [
                   "#{path}: the fixtures project keeps no #{dir}/ directory (its tests live in scrypath_ops)"
                 ]
      end

      # A file whose name merely starts with a banned directory name is not a violation.
      assert tracked_file_violations(
               clean ++ ["#{root}/lib/test_helpers.ex", "#{root}/privacy.md"]
             ) == []
    end
  end

  describe "fixtures README" do
    test "records the exit rule, the second-consumer definition and the phase173 deletion trigger" do
      assert readme_violations(File.read!(@fixtures_readme)) == []
    end

    test "removing any required phrase is reported by that phrase alone" do
      readme = File.read!(@fixtures_readme)

      for phrase <- @readme_phrases do
        mutated = String.replace(readme, phrase, "")
        assert mutated != readme, "planted edit found nothing to remove: #{phrase}"

        assert readme_violations(mutated) == ["the README must say #{inspect(phrase)}"],
               "removing #{inspect(phrase)} was not reported as exactly that phrase"
      end
    end

    test "names none of the compliance-claim words, and the scan can find them" do
      assert claim_words(File.read!(@fixtures_readme)) == []

      assert claim_words("This sample is HIPAA compliant and a certified GDPR demo.") ==
               ["HIPAA", "compliant", "certified", "GDPR"]

      assert claim_words("Compliance is not a claim, and a pcie slot is not PCI.") == ["PCI"]
    end
  end

  defp alias_violations(manifest_path) do
    ast = read_ast!(manifest_path)
    steps = ast |> function_body!(:aliases) |> keyword_value(:test) |> List.wrap()
    envs = ast |> function_body!(:cli) |> keyword_value(:preferred_envs) |> List.wrap()

    List.flatten([alias_step_problem(steps), preferred_env_problem(envs)])
  end

  defp alias_step_problem(steps) do
    case Enum.find_index(steps, &(&1 == @check_task)) do
      0 ->
        []

      nil ->
        ["the test alias must run #{@check_task}, but it does not"]

      at ->
        [
          "#{@check_task} must be the first step of the test alias, found it at position #{at + 1}"
        ]
    end
  end

  defp preferred_env_problem(envs) do
    case List.keyfind(envs, String.to_atom(@check_task), 0) do
      {_task, :test} ->
        []

      {_task, other} ->
        ["cli/0 preferred_envs must map #{@check_task} to :test, got #{inspect(other)}"]

      nil ->
        ["cli/0 preferred_envs has no entry for #{@check_task}"]
    end
  end

  # The fixtures deps list must be exactly `[{:scrypath, path: "../.."}]`: any extra option, such as `only:`,
  # can make it diverge from scrypath_ops's own `{:scrypath, path: ".."}` and Mix refuses the graph.
  defp fixtures_manifest_violations(manifest_path) do
    deps = manifest_path |> read_ast!() |> deps_body!()

    case deps do
      [{:scrypath, [path: "../.."]}] -> []
      _ -> [fixtures_deps_problem(deps)]
    end
  end

  defp fixtures_deps_problem(deps) do
    names = Enum.flat_map(deps, &dependency_name/1)

    cond do
      :scrypath not in names ->
        "the fixtures project must declare {:scrypath, path: \"../..\"}, but :scrypath is absent"

      names != [:scrypath] ->
        "the fixtures project must depend only on :scrypath, but also lists #{inspect(names -- [:scrypath])}"

      true ->
        scrypath_option_problem(Enum.find_value(deps, &scrypath_options/1))
    end
  end

  defp scrypath_option_problem(options) do
    case Keyword.get(options, :path) do
      "../.." ->
        extras = Keyword.delete(options, :path)
        extra = Enum.map_join(extras, ", ", fn {key, value} -> "#{key}: #{inspect(value)}" end)
        "the :scrypath dependency must be exactly path: \"../..\", found extra option #{extra}"

      path ->
        "the :scrypath dependency must use path: \"../..\", got #{inspect(path)}"
    end
  end

  defp scrypath_options({:scrypath, options}) when is_list(options), do: options
  defp scrypath_options({:scrypath, requirement}) when is_binary(requirement), do: []
  defp scrypath_options({:{}, _, [:scrypath, _requirement, options]}), do: options
  defp scrypath_options(_dependency), do: nil

  defp tracked_file_violations(paths) do
    root = "fixtures/scrypath_fixtures/"

    for path <- paths, problem = tracked_file_problem(String.replace_prefix(path, root, "")) do
      "#{path}: #{problem}"
    end
  end

  defp tracked_file_problem("mix.lock"),
    do: "the fixtures project has no Hex dependency, so it keeps no lock file"

  defp tracked_file_problem(relative) do
    Enum.find_value(["test", "config", "priv"], fn dir ->
      if String.starts_with?(relative, dir <> "/") do
        "the fixtures project keeps no #{dir}/ directory (its tests live in scrypath_ops)"
      end
    end)
  end

  # The words the fictional adopters must never claim (compliance and certification), matched as whole words.
  defp claim_words(text) do
    ~r/\b(hipaa|gdpr|pci|sox|compliant|certified)\b/i
    |> Regex.scan(text)
    |> Enum.map(&hd/1)
  end

  defp readme_violations(text) do
    for phrase <- @readme_phrases, not String.contains?(text, phrase) do
      "the README must say #{inspect(phrase)}"
    end
  end

  defp tmp_dir!(prefix) do
    tmp = Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp)
    on_exit(fn -> File.rm_rf(tmp) end)
    tmp
  end

  defp ops_manifest!(tmp, name, test_alias, env_task, env \\ ":test") do
    path = Path.join(tmp, name)
    steps = Enum.map_join(test_alias, ", ", &inspect/1)

    File.write!(path, """
    defmodule Planted.MixProject do
      def cli, do: [preferred_envs: [precommit: :test, #{inspect(env_task)}: #{env}]]

      defp aliases do
        [setup: ["deps.get"], test: [#{steps}]]
      end
    end
    """)

    path
  end

  defp deps_manifest!(tmp, name, dependencies) do
    path = Path.join(tmp, name)

    File.write!(path, """
    defmodule Planted.MixProject do
      defp deps do
        [#{dependencies}]
      end
    end
    """)

    path
  end

  defp read_ast!(path), do: path |> File.read!() |> Code.string_to_quoted!(file: path)

  defp function_body!(ast, name) do
    {_ast, body} =
      Macro.prewalk(ast, nil, fn
        {visibility, _, [{^name, _, args}, body]} = node, nil
        when visibility in [:def, :defp] and args in [nil, []] ->
          {node, function_do_body(body)}

        node, body ->
          {node, body}
      end)

    if is_nil(body), do: flunk("expected project function #{name}/0"), else: body
  end

  defp function_do_body(do: body), do: body
  defp function_do_body(body), do: body

  defp deps_body!(ast), do: function_body!(ast, :deps)

  defp keyword_value(body, key) when is_list(body) do
    Enum.find_value(body, fn
      {^key, value} -> value
      _ -> nil
    end)
  end

  defp dependency_name({name, _options}) when is_atom(name), do: [name]
  defp dependency_name({:{}, _, [name | _]}) when is_atom(name), do: [name]
  defp dependency_name(_entry), do: []
end
