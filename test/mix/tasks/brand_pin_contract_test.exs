defmodule Mix.Tasks.BrandPinContractTest do
  # Gate 1 of the v1.46 gate budget: the offline brand pin. Deletion trigger,
  # expected churn per UI PR and the full ledger are recorded in CONTRIBUTING.md
  # (added in Plan 03 of phase 186). The online re-download check is deliberately
  # NOT run against the network here; it lives only in `mix brand.update`, and the
  # tests below drive it through Req.Test stubs.
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Brand.Update
  alias Mix.Tasks.Verify.Brand

  @root Path.expand("../../..", __DIR__)
  @fonts "scrypath_ops/priv/static/assets/fonts"
  @prefix "scrypath-brand/"

  # Test-owned constants. Editing brand/brand.pin.json alone must fail this file;
  # a refresh changes the pin and both constants in the same PR.
  #
  # @expected_zip_sha256 binds the archive. @expected_assets_digest binds the
  # vendored bytes: sha256 over the line "path:sha256\n" of every pinned asset,
  # sorted by path. Without it, a change that edits an asset together with its
  # pin entry would pass `mix verify.brand`, which can only trust the pin file.
  # With it, that change needs a second, reviewed edit here. The trade-off: one
  # more value to copy per refresh (the update task prints it), and a PR that
  # edits the pin, the asset and both constants together is still not caught
  # offline. The online check in `mix brand.update` closes that case by comparing
  # the upstream archive with the committed files.
  @expected_zip_sha256 "3fc6d80f597eb232b6c25d5929cbe9dbbe6503c346c1360456ea839f3334be88"
  @expected_assets_digest "361c8fc6bc42d734430b9c5f7bafc8fc24e5f577fc4f649ba975a0276069bdaf"

  describe "committed pin" do
    test "pin source fields equal the test-owned expectations" do
      source = read_pin!(@root)["source"]

      assert source["zip_sha256"] == @expected_zip_sha256
      assert source["zip_size"] == 6_729_996
      assert source["zip_entries"] == 108
      assert source["zip_uncompressed_bytes"] == 8_912_608
      assert source["repository_commit"] == "ced7c40e"
    end

    test "the pinned per-asset hashes equal the test-owned assets digest" do
      assert assets_digest(read_pin!(@root)) == @expected_assets_digest
    end

    test "verify.brand check!/1 accepts the committed tree" do
      assert Brand.check!(@root) == :ok
    end

    test "verify.brand run/1 reports the asset count and total bytes" do
      output = capture_io(fn -> Brand.run([]) end)

      assert output =~ "verify.brand: ok (44 assets, 326773 bytes)"
    end

    test "verify.brand run/1 rejects arguments" do
      assert_raise Mix.Error, ~r/does not accept arguments/, fn -> Brand.run(["--online"]) end
    end

    test "the adopted allowlist has 44 entries whose repo paths equal the pinned paths" do
      adopted = Update.adopted_members()
      pinned = read_pin!(@root)["assets"]

      assert length(adopted) == 44
      assert Enum.sort(Enum.map(adopted, & &1.path)) == Enum.sort(Enum.map(pinned, & &1["path"]))
    end
  end

  describe "offline verify tamper" do
    test "a pristine copy of the pinned tree passes" do
      assert Brand.check!(copy_pinned_tree!()) == :ok
    end

    test "an unpinned file fails" do
      tmp = copy_pinned_tree!()
      File.write!(Path.join(tmp, "brand/extra.md"), "unpinned")

      assert_raise Mix.Error, ~r/verify\.brand: unpinned file: brand\/extra\.md/, fn ->
        Brand.check!(tmp)
      end
    end

    test "a dotfile in a nested directory fails" do
      tmp = copy_pinned_tree!()
      File.write!(Path.join(tmp, "brand/assets/.hidden"), "")

      assert_raise Mix.Error, ~r/unpinned file: brand\/assets\/\.hidden/, fn ->
        Brand.check!(tmp)
      end
    end

    test "a dotfile in the fonts directory fails" do
      tmp = copy_pinned_tree!()
      File.write!(Path.join(tmp, @fonts <> "/.DS_Store"), "")

      assert_raise Mix.Error, ~r/unpinned file: .*\.DS_Store/, fn -> Brand.check!(tmp) end
    end

    test "one changed byte in a pinned brand file fails" do
      tmp = copy_pinned_tree!()
      flip_first_byte!(Path.join(tmp, "brand/tokens.json"))

      assert_raise Mix.Error, ~r/sha256 mismatch: brand\/tokens\.json/, fn ->
        Brand.check!(tmp)
      end
    end

    test "one changed byte in a pinned font fails" do
      tmp = copy_pinned_tree!()
      flip_first_byte!(Path.join(tmp, @fonts <> "/ui.woff2"))

      assert_raise Mix.Error, ~r/sha256 mismatch: .*ui\.woff2/, fn -> Brand.check!(tmp) end
    end

    test "a pinned file with a different size fails" do
      tmp = copy_pinned_tree!()
      File.write!(Path.join(tmp, "brand/BRAND.md"), "x", [:append])

      assert_raise Mix.Error, ~r/size mismatch: brand\/BRAND\.md/, fn -> Brand.check!(tmp) end
    end

    test "a deleted pinned file fails" do
      tmp = copy_pinned_tree!()
      File.rm!(Path.join(tmp, "brand/assets/README.md"))

      assert_raise Mix.Error, ~r/missing pinned file: brand\/assets\/README\.md/, fn ->
        Brand.check!(tmp)
      end
    end

    test "a symlink in place of a pinned file fails" do
      tmp = copy_pinned_tree!()
      target = Path.join(tmp, "brand/BRAND.md")
      File.rm!(target)
      File.ln_s!(Path.join(@root, "brand/BRAND.md"), target)

      assert_raise Mix.Error, ~r/symlink refused: brand\/BRAND\.md/, fn -> Brand.check!(tmp) end
    end

    test "a symlinked directory inside an owned directory fails" do
      tmp = copy_pinned_tree!()
      avatar = Path.join(tmp, "brand/assets/avatar")
      moved = Path.join(tmp, "moved-avatar")
      File.rename!(avatar, moved)
      File.ln_s!(moved, avatar)

      assert_raise Mix.Error, ~r/symlink refused: brand\/assets\/avatar/, fn ->
        Brand.check!(tmp)
      end
    end

    test "a pinned path removed from the pin and the tree fails the allowlist check" do
      tmp = copy_pinned_tree!()
      File.rm!(Path.join(tmp, "brand/assets/README.md"))

      rewrite_pin!(tmp, fn pin ->
        update_in(
          pin["assets"],
          &Enum.reject(&1, fn a -> a["path"] == "brand/assets/README.md" end)
        )
      end)

      assert_raise Mix.Error, ~r/pinned paths differ from the adopted allowlist/, fn ->
        Brand.check!(tmp)
      end
    end

    test "a disallowed extension added to both the pin and the tree fails" do
      tmp = copy_pinned_tree!()
      add_pinned_file!(tmp, "brand/assets/evil.pdf", "%PDF-1.7")

      assert_raise Mix.Error, ~r/extension not allowed: brand\/assets\/evil\.pdf/, fn ->
        Brand.check!(tmp)
      end
    end

    test "a pinned total over the ceiling fails" do
      tmp = copy_pinned_tree!()
      add_pinned_file!(tmp, "brand/assets/filler.txt", String.duplicate("a", 400_001))

      assert_raise Mix.Error, ~r/total size over ceiling/, fn -> Brand.check!(tmp) end
    end

    test "a pinned path that escapes the owned directories fails" do
      tmp = copy_pinned_tree!()
      add_pinned_file!(tmp, "brand/../outside.md", "x")

      assert_raise Mix.Error, ~r/path escapes the owned directories/, fn -> Brand.check!(tmp) end
    end

    svg = "brand/assets/logo/scrypath-symbol-dark.svg"

    for {{label, file, snippet}, index} <-
          Enum.with_index([
            {"script element", svg, "<script>x</script>"},
            {"javascript: URL", svg, "<text>javascript:void(0)</text>"},
            {"event handler attribute", svg, ~s(<g onclick="x"></g>)},
            {"foreignObject element", svg, ~s(<foreignObject width="1"></foreignObject>)},
            {"iframe element", "brand/assets/readme/header-snippet.html", "<iframe></iframe>"},
            {"@import rule", "brand/assets/docs/scrypath-exdoc.css", ~s(@import "x.css";)},
            {"remote url()", "brand/assets/docs/scrypath-exdoc.css",
             "a{background:url(https://example.test/a.png)}"},
            {"remote href", svg, ~s(<image href="https://example.test/a.png"/>)},
            {"remote href", svg, ~s(<image xlink:href="http://example.test/a.png"/>)}
          ]) do
      test "active content in a rehashed pinned file fails (#{index}): #{label}" do
        tmp = copy_pinned_tree!()
        file = unquote(file)
        File.write!(Path.join(tmp, file), unquote(snippet), [:append])
        repin_file!(tmp, file)

        error = assert_raise Mix.Error, fn -> Brand.check!(tmp) end
        assert error.message == "verify.brand: active content (#{unquote(label)}): #{file}"
      end
    end

    test "an asset edited together with its pin entry passes verify.brand but not the assets digest" do
      tmp = copy_pinned_tree!()
      file = "brand/assets/docs/scrypath-exdoc.css"
      File.write!(Path.join(tmp, file), "\n/* edited */\n", [:append])
      repin_file!(tmp, file)

      assert Brand.check!(tmp) == :ok
      refute assets_digest(read_pin!(tmp)) == @expected_assets_digest
    end

    test "update.ex and the test agree on the digest definition" do
      pairs = for asset <- read_pin!(@root)["assets"], do: {asset["path"], asset["sha256"]}

      assert Update.assets_digest(pairs) == @expected_assets_digest
      assert Update.assets_digest(Enum.reverse(pairs)) == @expected_assets_digest
    end

    test "local references in a pinned SVG are accepted" do
      tmp = copy_pinned_tree!()
      file = "brand/assets/logo/scrypath-symbol-dark.svg"
      File.write!(Path.join(tmp, file), ~s|<use href="#a"/><rect fill="url(#grad)"/>|, [:append])
      repin_file!(tmp, file)

      assert Brand.check!(tmp) == :ok
    end
  end

  describe "update archive refusals" do
    test "a wrong archive size is refused" do
      {bin, expected} = valid_archive()

      error = refusal(bin, %{expected | size: expected.size + 1})

      assert error =~
               "archive size #{byte_size(bin)} does not match expected #{expected.size + 1}"
    end

    test "a wrong archive sha256 is refused" do
      {bin, expected} = valid_archive()

      assert refusal(bin, %{expected | sha256: String.duplicate("0", 64)}) =~
               "archive sha256"
    end

    test "an archive over the size cap is refused before anything else" do
      bin = :binary.copy(<<0>>, 8_388_609)
      expected = %{sha256: sha256(bin), size: byte_size(bin), entries: 0, uncompressed: 0}

      error = refusal(bin, expected)
      assert error =~ "archive size 8388609 exceeds cap 8388608"
      refute error =~ "does not match expected"
    end

    test "an entry count that differs from the pin under the cap is a pin mismatch" do
      {bin, expected} = valid_archive()

      error = refusal(bin, %{expected | entries: expected.entries + 1})
      assert error =~ "entry count 44 does not match expected 45"
      refute error =~ "exceeds cap"
    end

    test "201 entries hit the entry cap, not the pin mismatch" do
      entries = for i <- 1..201, do: {@prefix <> "pad-#{i}.txt", "x"}
      bin = build_zip(entries)

      error = refusal(bin, expected_for(bin, entries))
      assert error =~ "entry count 201 exceeds cap 200"
      refute error =~ "does not match expected"
    end

    test "a declared uncompressed total that differs from the pin under the cap is a pin mismatch" do
      {bin, expected} = valid_archive()

      error = refusal(bin, %{expected | uncompressed: expected.uncompressed + 1})

      assert error =~
               "declared uncompressed total #{expected.uncompressed} does not match expected"

      refute error =~ "exceeds cap"
    end

    test "a declared uncompressed total over 16 MiB hits the cap, not the pin mismatch" do
      entries = [{@prefix <> "big.bin", :binary.copy(<<0>>, 17_000_000)}]
      bin = build_zip(entries)
      assert byte_size(bin) < 8_388_608

      error = refusal(bin, expected_for(bin, entries))
      assert error =~ "declared uncompressed total 17000000 exceeds cap 16777216"
      refute error =~ "does not match expected"
    end

    test "a missing allowlisted member is refused" do
      [{missing, _bytes} | rest] = adopted_entries()
      bin = build_zip(rest)

      assert refusal(bin, expected_for(bin, rest)) =~ "allowlisted member #{missing} is missing"
    end

    test "a duplicated allowlisted member is refused" do
      [first | _] = entries = adopted_entries()
      entries = entries ++ [first]
      bin = build_zip(entries)

      assert refusal(bin, expected_for(bin, entries)) =~ "appears 2 times"
    end

    test "an absolute entry name is refused" do
      entries = adopted_entries() ++ [{"Xevil-abs", "x"}]
      bin = entries |> build_zip() |> :binary.replace("Xevil-abs", "/evil-abs", [:global])

      assert refusal(bin, expected_for(bin, entries)) =~ "entry name is absolute"
    end

    test "an entry name with a .. segment is refused" do
      entries = adopted_entries() ++ [{@prefix <> "../evil.txt", "x"}]
      bin = build_zip(entries)

      assert refusal(bin, expected_for(bin, entries)) =~ "entry name has a .. segment"
    end

    test "an entry name with a backslash is refused" do
      entries = adopted_entries() ++ [{@prefix <> "dir\\evil.txt", "x"}]
      bin = build_zip(entries)

      assert refusal(bin, expected_for(bin, entries)) =~ "entry name has a backslash"
    end

    test "garbage bytes are refused" do
      bin = "this is not a zip archive"
      expected = %{sha256: sha256(bin), size: byte_size(bin), entries: 1, uncompressed: 1}

      assert refusal(bin, expected) =~ "archive could not be opened"
    end

    test "a truncated archive is refused" do
      {bin, _expected} = valid_archive()
      truncated = binary_part(bin, 0, byte_size(bin) - 10)

      expected = %{
        sha256: sha256(truncated),
        size: byte_size(truncated),
        entries: 44,
        uncompressed: 1
      }

      assert refusal(truncated, expected) =~ "archive could not be opened"
    end

    test "expected values are required, with no defaults" do
      {bin, expected} = valid_archive()

      assert_raise Mix.Error, ~r/expected value uncompressed is required/, fn ->
        Update.verify_archive!(bin, Map.delete(expected, :uncompressed))
      end
    end

    test "extra archive members never reach disk; only allowlisted paths are written" do
      extras = [
        {@prefix <> "evil.html", "<script>x</script>"},
        {@prefix <> "assets/index.html", "<script>x</script>"},
        {@prefix <> "preview/cover.jpg", "jpg"}
      ]

      entries = adopted_entries() ++ extras
      bin = build_zip(entries)
      expected = expected_for(bin, entries)

      extracted = Update.extract!(bin, expected)
      assert length(extracted) == 44

      tmp = tmp_root!()
      assert Update.write!(tmp, extracted, source_meta(expected)) == :ok

      written = relative_files(tmp)
      allowed = Enum.map(Update.adopted_members(), & &1.path) ++ ["brand/brand.pin.json"]

      assert written == Enum.sort(allowed)
      refute Enum.any?(written, &String.ends_with?(&1, "evil.html"))
      refute Enum.any?(written, &String.ends_with?(&1, "index.html"))
      refute Enum.any?(written, &String.ends_with?(&1, "cover.jpg"))
    end

    test "a tree written by the update task passes the offline verify" do
      entries = adopted_entries()
      bin = build_zip(entries)
      expected = expected_for(bin, entries)

      tmp = tmp_root!()
      Update.write!(tmp, Update.extract!(bin, expected), source_meta(expected))

      assert Brand.check!(tmp) == :ok
    end

    test "write! refuses an entry that is not on the allowlist" do
      # The escape target is the sandbox directory, so a failed guard stays inside
      # a throwaway tree and the assertion cannot see files left by earlier runs.
      sandbox = tmp_root!()
      root = Path.join(sandbox, "root")
      File.mkdir_p!(root)
      rogue = %{path: "../escape.txt", member: "x", kind: "doc", role: "x", license: "x"}
      meta = source_meta(%{sha256: sha256(""), size: 0, entries: 0, uncompressed: 0})

      assert_raise Mix.Error, ~r/outside the allowlist/, fn ->
        Update.write!(root, [{rogue, "x"}], meta)
      end

      refute File.exists?(Path.join(sandbox, "escape.txt"))
      assert File.ls!(root) == []
    end

    test "an uppercase --sha256 is stored lowercase and the written pin passes the offline verify" do
      entries = adopted_entries()
      bin = build_zip(entries)
      expected = expected_for(bin, entries)

      root = tmp_root!()
      zip_path = Path.join(root, "brand.zip")
      File.write!(zip_path, bin)
      target = Path.join(root, "target")
      File.mkdir_p!(target)
      opts = Keyword.put(refresh_opts(expected), :sha256, String.upcase(expected.sha256))

      output = capture_io(fn -> assert Update.refresh!(target, {:zip, zip_path}, opts) == :ok end)

      assert read_pin!(target)["source"]["zip_sha256"] == expected.sha256
      assert output =~ "@expected_zip_sha256 to #{expected.sha256}"
      assert output =~ "@expected_assets_digest to #{assets_digest(read_pin!(target))}"
      assert Brand.check!(target) == :ok
    end

    test "a --sha256 that is not 64 hex characters is refused before anything is written" do
      entries = adopted_entries()
      bin = build_zip(entries)
      expected = expected_for(bin, entries)

      root = tmp_root!()
      zip_path = Path.join(root, "brand.zip")
      File.write!(zip_path, bin)
      target = Path.join(root, "target")
      File.mkdir_p!(target)

      for bad <- [String.slice(expected.sha256, 0, 63), String.duplicate("g", 64), ""] do
        assert_raise Mix.Error, ~r/--sha256 must be 64 hex characters/, fn ->
          Update.refresh!(
            target,
            {:zip, zip_path},
            Keyword.put(refresh_opts(expected), :sha256, bad)
          )
        end
      end

      assert File.ls!(target) == []
    end

    test "the command line refuses unknown flags, refresh flags without a source and two sources" do
      assert_raise Mix.Error, ~r/unexpected arguments/, fn -> Update.run(["--bogus"]) end
      assert_raise Mix.Error, ~r/need a source/, fn -> Update.run(["--size", "1"]) end

      assert_raise Mix.Error, ~r/either --zip or --url/, fn ->
        Update.run(["--zip", "a.zip", "--url", "https://example.test/a.zip"])
      end

      assert_raise Mix.Error,
                   ~r/refresh requires --sha256 --size --entries --uncompressed --commit/,
                   fn ->
                     Update.run(["--zip", "a.zip"])
                   end
    end
  end

  describe "bounded extraction (members that lie about their size)" do
    test "a member that inflates past its declared size is refused while inflating" do
      {bin, expected} = lying_archive(declared: 10, actual: 20_000_000)
      assert byte_size(bin) < 8_388_608

      error = assert_raise Mix.Error, fn -> Update.extract!(bin, expected) end

      assert error.message ==
               "brand.update: member #{@prefix}BRAND.md inflates past its declared size 10"
    end

    test "a refresh from a lying archive writes nothing" do
      {bin, expected} = lying_archive(declared: 10, actual: 20_000_000)
      root = tmp_root!()
      zip_path = Path.join(root, "lying.zip")
      File.write!(zip_path, bin)
      target = Path.join(root, "target")
      File.mkdir_p!(target)

      assert_raise Mix.Error, ~r/inflates past its declared size 10/, fn ->
        Update.refresh!(target, {:zip, zip_path}, refresh_opts(expected))
      end

      assert File.ls!(target) == []
    end

    test "a local header that disagrees with the central directory is refused" do
      {bin, expected} = lying_archive(declared: 10, actual: 20_000_000, headers: [:central])

      error = assert_raise Mix.Error, fn -> Update.extract!(bin, expected) end

      assert error.message =~
               "local header of #{@prefix}BRAND.md disagrees with the central directory sizes"
    end

    test "a member that inflates to fewer bytes than declared is refused" do
      {bin, expected} = lying_archive(declared: 5_000, actual: 100)

      error = assert_raise Mix.Error, fn -> Update.extract!(bin, expected) end

      assert error.message ==
               "brand.update: member #{@prefix}BRAND.md extracted 100 bytes, declared 5000"
    end

    test "a member whose bytes fail the CRC-32 check is refused" do
      entries = adopted_entries()

      bin =
        entries |> build_zip() |> patch_local_header!(@prefix <> "BRAND.md", 14, <<0, 0, 0, 0>>)

      error = assert_raise Mix.Error, fn -> Update.extract!(bin, expected_for(bin, entries)) end

      assert error.message == "brand.update: member #{@prefix}BRAND.md fails its CRC-32 check"
    end

    test "an unsupported compression method is refused" do
      entries = adopted_entries()
      bin = entries |> build_zip() |> patch_local_header!(@prefix <> "BRAND.md", 8, <<9, 0>>)

      error = assert_raise Mix.Error, fn -> Update.extract!(bin, expected_for(bin, entries)) end

      assert error.message =~ "uses compression method 9"
    end

    test "a corrupt deflate stream is refused with a distinct message" do
      entries = [{@prefix <> "BRAND.md", :binary.copy("scrypath ", 400)} | tl(adopted_entries())]
      bin = build_zip(entries)
      data = member_data_offset!(bin, @prefix <> "BRAND.md")
      corrupt = patch_at!(bin, data, :binary.copy(<<255>>, 8))

      error =
        assert_raise Mix.Error, fn -> Update.extract!(corrupt, expected_for(corrupt, entries)) end

      assert error.message =~ "not a valid deflate stream"
    end

    test "honest members extract to exactly their declared sizes" do
      entries = adopted_entries()
      bin = build_zip(entries)

      extracted = Update.extract!(bin, expected_for(bin, entries))

      assert length(extracted) == 44

      for {entry, bytes} <- extracted do
        assert bytes == "fixture bytes for " <> entry.member
      end
    end
  end

  describe "online re-download check" do
    test "bytes that differ from the pin are refused" do
      Req.Test.stub(__MODULE__.DifferentBytes, fn conn ->
        Plug.Conn.send_resp(conn, 200, "not the brand archive")
      end)

      assert_raise Mix.Error, ~r/archive size 21 does not match expected 6729996/, fn ->
        Update.check_live!(@root, plug: {Req.Test, __MODULE__.DifferentBytes})
      end
    end

    test "a download over the cap halts early and is refused" do
      chunk = :binary.copy(<<0>>, 1_048_576)

      Req.Test.stub(__MODULE__.OverCap, fn conn ->
        conn = Plug.Conn.send_chunked(conn, 200)

        Enum.reduce(1..16, conn, fn _n, conn ->
          {:ok, conn} = Plug.Conn.chunk(conn, chunk)
          conn
        end)
      end)

      error =
        assert_raise Mix.Error, ~r/download exceeds cap 8388608 bytes/, fn ->
          Update.check_live!(@root, plug: {Req.Test, __MODULE__.OverCap})
        end

      [_, halted] = Regex.run(~r/halted after (\d+) bytes/, error.message)
      halted = String.to_integer(halted)
      assert halted > 8_388_608
      assert halted < 16 * 1_048_576
    end

    test "a 404 is refused" do
      Req.Test.stub(__MODULE__.NotFound, fn conn ->
        conn |> Plug.Conn.put_status(404) |> Plug.Conn.send_resp(404, "missing")
      end)

      assert_raise Mix.Error, ~r/HTTP status 404/, fn ->
        Update.check_live!(@root, plug: {Req.Test, __MODULE__.NotFound})
      end
    end

    test "a live archive that equals the pin passes" do
      entries = adopted_entries()
      bin = build_zip(entries)
      expected = expected_for(bin, entries)

      tmp = tmp_root!()
      Update.write!(tmp, Update.extract!(bin, expected), source_meta(expected))

      Req.Test.stub(__MODULE__.MatchingBytes, fn conn -> Plug.Conn.send_resp(conn, 200, bin) end)

      output =
        capture_io(fn ->
          assert Update.check_live!(tmp, plug: {Req.Test, __MODULE__.MatchingBytes}) == :ok
        end)

      assert output =~ "brand.update: live archive matches pin"
    end

    test "a redirect from https to http is refused before the downgraded request" do
      test_pid = self()

      Req.Test.stub(__MODULE__.Downgrade, fn conn ->
        send(test_pid, {:request, conn.scheme})

        conn
        |> Plug.Conn.put_resp_header("location", "http://example.test/scrypath-brand.zip")
        |> Plug.Conn.send_resp(302, "")
      end)

      assert_raise Mix.Error, ~r/refusing non-https hop http:\/\/example\.test/, fn ->
        Update.fetch!("https://example.test/scrypath-brand.zip",
          plug: {Req.Test, __MODULE__.Downgrade}
        )
      end

      assert_received {:request, :https}
      refute_received {:request, :http}
    end

    test "a redirect from https to https is still followed" do
      Req.Test.stub(__MODULE__.SameScheme, fn
        %Plug.Conn{request_path: "/a"} = conn ->
          conn
          |> Plug.Conn.put_resp_header("location", "https://example.test/b")
          |> Plug.Conn.send_resp(302, "")

        conn ->
          Plug.Conn.send_resp(conn, 200, "archive bytes")
      end)

      assert Update.fetch!("https://example.test/a", plug: {Req.Test, __MODULE__.SameScheme}) ==
               "archive bytes"
    end

    test "a live archive whose members differ from the edited pin entries is refused" do
      {bin, tmp} = live_fixture!()
      file = "brand/BRAND.md"
      File.write!(Path.join(tmp, file), "edited after the refresh", [:append])
      repin_file!(tmp, file)

      assert Brand.check!(tmp) == :ok

      Req.Test.stub(__MODULE__.EditedPin, fn conn -> Plug.Conn.send_resp(conn, 200, bin) end)

      assert_raise Mix.Error,
                   ~r/member BRAND\.md is \d+ bytes, the pin entry for brand\/BRAND\.md says \d+/,
                   fn -> Update.check_live!(tmp, plug: {Req.Test, __MODULE__.EditedPin}) end
    end

    test "a live archive whose member hash differs from the pin entry is refused" do
      {bin, tmp} = live_fixture!()
      file = "brand/BRAND.md"
      path = Path.join(tmp, file)
      <<first, rest::binary>> = File.read!(path)
      File.write!(path, <<Bitwise.bxor(first, 1), rest::binary>>)
      repin_file!(tmp, file)

      assert Brand.check!(tmp) == :ok

      Req.Test.stub(__MODULE__.EditedHash, fn conn -> Plug.Conn.send_resp(conn, 200, bin) end)

      assert_raise Mix.Error,
                   ~r/member BRAND\.md sha256 differs from the pin entry for brand\/BRAND\.md/,
                   fn -> Update.check_live!(tmp, plug: {Req.Test, __MODULE__.EditedHash}) end
    end

    test "a committed file that differs from the archive member is refused" do
      {bin, tmp} = live_fixture!()
      flip_first_byte!(Path.join(tmp, "brand/BRAND.md"))

      Req.Test.stub(__MODULE__.EditedFile, fn conn -> Plug.Conn.send_resp(conn, 200, bin) end)

      assert_raise Mix.Error,
                   ~r/committed file brand\/BRAND\.md differs from archive member BRAND\.md/,
                   fn -> Update.check_live!(tmp, plug: {Req.Test, __MODULE__.EditedFile}) end
    end

    test "plain http URLs are refused before any request" do
      assert_raise Mix.Error, ~r/only https URLs/, fn ->
        Update.fetch!("http://example.test/scrypath-brand.zip")
      end
    end
  end

  describe "Hex package files" do
    test "the package files list has no brand entry" do
      files = Scrypath.MixProject.project()[:package][:files]

      assert is_list(files) and files != []
      assert brand_entries(files) == []
    end

    test "the guard flags a planted brand entry and the retired directory name" do
      files = Scrypath.MixProject.project()[:package][:files]
      planted = files ++ ["brand", "brand" <> "book"]

      assert brand_entries(planted) == ["brand", "brandbook"]
    end
  end

  defp brand_entries(files), do: Enum.filter(files, &String.starts_with?(&1, "brand"))

  defp read_pin!(root) do
    root |> Path.join("brand/brand.pin.json") |> File.read!() |> Jason.decode!()
  end

  # Independent of Update.assets_digest/1 on purpose: the constant is checked
  # against this definition, and a test proves the two agree.
  defp assets_digest(pin) do
    pin["assets"]
    |> Enum.sort_by(& &1["path"])
    |> Enum.map_join(&"#{&1["path"]}:#{&1["sha256"]}\n")
    |> sha256()
  end

  # A fixture archive and a tree written from it, so the pin matches the archive.
  defp live_fixture! do
    entries = adopted_entries()
    bin = build_zip(entries)
    expected = expected_for(bin, entries)
    tmp = tmp_root!()
    Update.write!(tmp, Update.extract!(bin, expected), source_meta(expected))
    {bin, tmp}
  end

  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

  defp tmp_root! do
    tmp = Path.join(System.tmp_dir!(), "brand-pin-#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp)
    on_exit(fn -> File.rm_rf!(tmp) end)
    tmp
  end

  defp copy_pinned_tree! do
    tmp = tmp_root!()

    for dir <- ["brand", @fonts] do
      File.mkdir_p!(Path.join(tmp, dir))
      File.cp_r!(Path.join(@root, dir), Path.join(tmp, dir))
    end

    tmp
  end

  defp rewrite_pin!(tmp, fun) do
    path = Path.join(tmp, "brand/brand.pin.json")
    pin = path |> File.read!() |> Jason.decode!() |> fun.()
    File.write!(path, Jason.encode!(pin, pretty: true))
  end

  defp repin_file!(tmp, relative) do
    contents = File.read!(Path.join(tmp, relative))

    rewrite_pin!(tmp, fn pin ->
      update_in(pin["assets"], fn assets ->
        Enum.map(assets, fn
          %{"path" => ^relative} = asset ->
            %{asset | "sha256" => sha256(contents), "size" => byte_size(contents)}

          asset ->
            asset
        end)
      end)
    end)
  end

  defp add_pinned_file!(tmp, relative, contents) do
    full = tmp |> Path.join(relative) |> Path.expand()
    File.mkdir_p!(Path.dirname(full))
    File.write!(full, contents)

    asset = %{
      "path" => relative,
      "source_member" => "none",
      "sha256" => sha256(contents),
      "size" => byte_size(contents),
      "license" => "test",
      "role" => "test",
      "kind" => "doc"
    }

    rewrite_pin!(tmp, fn pin -> update_in(pin["assets"], &(&1 ++ [asset])) end)
  end

  defp flip_first_byte!(path) do
    <<first, rest::binary>> = File.read!(path)
    File.write!(path, <<Bitwise.bxor(first, 1), rest::binary>>)
  end

  defp relative_files(root) do
    root
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.filter(&File.regular?/1)
    |> Enum.map(&Path.relative_to(&1, root))
    |> Enum.sort()
  end

  defp adopted_entries do
    for entry <- Update.adopted_members() do
      {@prefix <> entry.member, "fixture bytes for " <> entry.member}
    end
  end

  defp build_zip(entries) do
    files = for {name, bytes} <- entries, do: {String.to_charlist(name), bytes}
    {:ok, {_name, bin}} = :zip.create(~c"brand.zip", files, [:memory])
    bin
  end

  defp expected_for(bin, entries) do
    %{
      sha256: sha256(bin),
      size: byte_size(bin),
      entries: length(entries),
      uncompressed: entries |> Enum.map(fn {_name, bytes} -> byte_size(bytes) end) |> Enum.sum()
    }
  end

  defp valid_archive do
    entries = adopted_entries()
    bin = build_zip(entries)
    {bin, expected_for(bin, entries)}
  end

  defp source_meta(expected) do
    %{
      url: "https://example.test/scrypath-brand.zip",
      repository_commit: "0000000",
      zip_sha256: expected.sha256,
      zip_size: expected.size,
      zip_entries: expected.entries,
      zip_uncompressed_bytes: expected.uncompressed
    }
  end

  # The zip-bomb shape: BRAND.md really holds `actual` zero bytes but the archive
  # declares `declared`. `headers` picks where the lie is written; the declared
  # total the pin expects follows the lie, so every cap and pin check passes and
  # only the member's own inflation can notice.
  defp lying_archive(options) do
    declared = Keyword.fetch!(options, :declared)
    actual = Keyword.fetch!(options, :actual)
    headers = Keyword.get(options, :headers, [:central, :local])
    name = @prefix <> "BRAND.md"

    entries = [{name, :binary.copy(<<0>>, actual)} | tl(adopted_entries())]
    bin = build_zip(entries)

    bin =
      if :central in headers,
        do: patch_central_header!(bin, name, 24, <<declared::32-little>>),
        else: bin

    bin =
      if :local in headers,
        do: patch_local_header!(bin, name, 22, <<declared::32-little>>),
        else: bin

    expected = expected_for(bin, entries)
    {bin, %{expected | uncompressed: expected.uncompressed - actual + declared}}
  end

  defp refresh_opts(expected) do
    [
      sha256: expected.sha256,
      size: expected.size,
      entries: expected.entries,
      uncompressed: expected.uncompressed,
      commit: "abc1234"
    ]
  end

  # Fixed-size parts of the zip headers, so the tests can falsify single fields.
  defp central_header!(bin, name) do
    {position, _length} =
      bin
      |> :binary.matches(<<0x50, 0x4B, 0x01, 0x02>>)
      |> Enum.find(fn {position, _length} ->
        <<_::binary-size(position), _fixed::binary-size(28), name_length::16-little, _::binary>> =
          bin

        binary_part(bin, position + 46, name_length) == name
      end)

    position
  end

  defp local_header!(bin, name) do
    position = central_header!(bin, name)
    <<_::binary-size(position + 42), offset::32-little, _::binary>> = bin
    {offset, byte_size(name)}
  end

  defp member_data_offset!(bin, name) do
    {offset, name_length} = local_header!(bin, name)
    <<_::binary-size(offset + 28), extra_length::16-little, _::binary>> = bin
    offset + 30 + name_length + extra_length
  end

  defp patch_central_header!(bin, name, field_offset, value) do
    patch_at!(bin, central_header!(bin, name) + field_offset, value)
  end

  defp patch_local_header!(bin, name, field_offset, value) do
    {offset, _name_length} = local_header!(bin, name)
    patch_at!(bin, offset + field_offset, value)
  end

  defp patch_at!(bin, position, value) do
    size = byte_size(value)
    <<before::binary-size(position), _old::binary-size(size), rest::binary>> = bin
    <<before::binary, value::binary, rest::binary>>
  end

  defp refusal(bin, expected) do
    error = assert_raise Mix.Error, fn -> Update.verify_archive!(bin, expected) end
    assert error.message =~ "brand.update:"
    error.message
  end
end
