defmodule Mix.Tasks.Verify.Brand do
  @moduledoc false
  use Mix.Task

  # Offline, merge-blocking check that the committed brand assets are exactly the
  # pinned ones (v1.46 D6). It never touches the network; the online re-download
  # check lives only in `mix brand.update`.

  @shortdoc "Verifies the committed brand assets against brand/brand.pin.json (offline)"

  alias Mix.Tasks.Brand.Update

  @pin_schema "scrypath.brand-pin.v1"
  @allowed_extensions ~w(.md .json .svg .png .ico .css .html .woff2 .txt)
  @max_total_bytes 400_000
  @scanned_extensions ~w(.svg .css .html)
  @hex64 ~r/\A[0-9a-f]{64}\z/

  # Active content refused in vendored SVG, CSS and HTML (T-186-04).
  @active_content [
    {~r/<script/i, "script element"},
    {~r/javascript:/i, "javascript: URL"},
    {~r/\son[a-z]+\s*=/i, "event handler attribute"},
    {~r/<foreignobject/i, "foreignObject element"},
    {~r/<iframe/i, "iframe element"},
    {~r/@import/i, "@import rule"},
    {~r/url\(\s*["']?\s*http/i, "remote url()"},
    {~r/(?:xlink:)?href\s*=\s*["']?\s*http/i, "remote href"}
  ]

  @impl true
  def run([]) do
    root = Path.dirname(Mix.Project.project_file())
    {count, bytes} = verify_tree!(root)
    Mix.shell().info("verify.brand: ok (#{count} assets, #{bytes} bytes)")
  end

  def run(args),
    do: Mix.raise("verify.brand does not accept arguments: #{Enum.join(args, " ")}")

  @doc false
  def check!(root) do
    verify_tree!(root)
    :ok
  end

  defp verify_tree!(root) do
    pin = read_pin!(root)
    assets = pin_assets!(pin)

    Enum.each(assets, &check_pinned_path!/1)
    check_total_size!(assets)
    check_allowlist!(assets)
    Enum.each(assets, &check_asset!(root, &1))
    check_closed_directories!(root, assets)

    {length(assets), assets |> Enum.map(& &1["size"]) |> Enum.sum()}
  end

  defp read_pin!(root) do
    path = Update.pin_path()

    with {:ok, contents} <- File.read(Path.join(root, path)),
         {:ok, %{} = pin} <- Jason.decode(contents) do
      validate_pin_header!(pin, path)
      pin
    else
      _error -> fail!("pin unreadable", path)
    end
  end

  defp validate_pin_header!(pin, path) do
    zip_sha256 = get_in(pin, ["source", "zip_sha256"])

    cond do
      pin["schema"] != @pin_schema ->
        fail!("pin schema invalid", path)

      not (is_binary(zip_sha256) and zip_sha256 =~ @hex64) ->
        fail!("pin zip sha256 invalid", path)

      pin["owned_directories"] != Update.owned_directories() ->
        fail!("pin owned directories differ", path)

      true ->
        :ok
    end
  end

  defp pin_assets!(pin) do
    case pin["assets"] do
      [_ | _] = assets ->
        Enum.each(assets, &check_asset_shape!/1)
        assets

      _other ->
        fail!("pin assets invalid", Update.pin_path())
    end
  end

  defp check_asset_shape!(%{"path" => path, "sha256" => sha256, "size" => size})
       when is_binary(path) and is_binary(sha256) and is_integer(size) and size >= 0 do
    if sha256 =~ @hex64, do: :ok, else: fail!("pin asset sha256 invalid", path)
  end

  defp check_asset_shape!(asset), do: fail!("pin asset entry invalid", inspect(asset))

  defp check_pinned_path!(%{"path" => path}) do
    owned? = Enum.any?(Update.owned_directories(), &String.starts_with?(path, &1 <> "/"))
    segments = Path.split(path)

    cond do
      Path.type(path) != :relative or ".." in segments or String.contains?(path, "\\") ->
        fail!("path escapes the owned directories", path)

      not owned? ->
        fail!("path is outside the owned directories", path)

      String.downcase(Path.extname(path)) not in @allowed_extensions ->
        fail!("extension not allowed", path)

      true ->
        :ok
    end
  end

  defp check_total_size!(assets) do
    total = assets |> Enum.map(& &1["size"]) |> Enum.sum()

    if total > @max_total_bytes do
      fail!("total size over ceiling", "#{total} > #{@max_total_bytes}")
    end
  end

  defp check_allowlist!(assets) do
    pinned = assets |> Enum.map(& &1["path"]) |> Enum.sort()
    adopted = Update.adopted_members() |> Enum.map(& &1.path) |> Enum.sort()

    if pinned != adopted do
      differing = (pinned -- adopted) ++ (adopted -- pinned)
      fail!("pinned paths differ from the adopted allowlist", Enum.join(differing, ", "))
    end
  end

  defp check_asset!(root, %{"path" => path, "size" => size, "sha256" => sha256}) do
    full = Path.join(root, path)

    case File.lstat(full) do
      {:ok, %File.Stat{type: :regular}} -> :ok
      {:ok, %File.Stat{type: :symlink}} -> fail!("symlink refused", path)
      {:ok, _other} -> fail!("not a regular file", path)
      {:error, _reason} -> fail!("missing pinned file", path)
    end

    contents = File.read!(full)

    if byte_size(contents) != size, do: fail!("size mismatch", path)
    if hex_sha256(contents) != sha256, do: fail!("sha256 mismatch", path)
    check_active_content!(path, contents)
  end

  defp check_active_content!(path, contents) do
    if String.downcase(Path.extname(path)) in @scanned_extensions do
      for {pattern, label} <- @active_content, Regex.match?(pattern, contents) do
        fail!("active content (#{label})", path)
      end
    end

    :ok
  end

  defp check_closed_directories!(root, assets) do
    allowed = MapSet.new([Update.pin_path() | Enum.map(assets, & &1["path"])])

    for directory <- Update.owned_directories(),
        found <- list_files!(root, directory),
        not MapSet.member?(allowed, found) do
      fail!("unpinned file", found)
    end

    :ok
  end

  # Recursive listing with dotfiles included; a symlink anywhere is refused.
  defp list_files!(root, relative) do
    full = Path.join(root, relative)

    case File.lstat(full) do
      {:ok, %File.Stat{type: :directory}} -> list_children!(root, relative, full)
      {:ok, %File.Stat{type: :symlink}} -> fail!("symlink refused", relative)
      {:ok, %File.Stat{type: :regular}} -> [relative]
      {:ok, _other} -> [relative]
      {:error, :enoent} -> []
      {:error, _reason} -> fail!("unreadable", relative)
    end
  end

  defp list_children!(root, relative, full) do
    case File.ls(full) do
      {:ok, names} ->
        names |> Enum.sort() |> Enum.flat_map(&list_files!(root, Path.join(relative, &1)))

      {:error, _reason} ->
        fail!("unreadable", relative)
    end
  end

  defp hex_sha256(contents), do: :crypto.hash(:sha256, contents) |> Base.encode16(case: :lower)

  defp fail!(reason, path), do: Mix.raise("verify.brand: #{reason}: #{path}")
end
