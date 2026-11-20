defmodule Mix.Tasks.UiTokensHelperTest do
  use ExUnit.Case, async: true

  alias Scrypath.TestSupport.UiTokens

  @root Path.expand("../../..", __DIR__)

  # Neutral fixture colors: nothing here belongs to the retired or the adopted identity.
  @css ~S"""
  @plugin "../vendor/daisyui-theme" {
    name: "dark";
    default: false;
    --ops-bg: #123456;
    --ops-surface-1: #234567;
  }

  @plugin "../vendor/daisyui-theme" {
    name: "light";
    default: true;
    --ops-bg: #abcdef;
    --ops-surface-1: #ffffff;
  }
  """

  describe "theme_value!/3" do
    test "reads the value from the named block, not the first match" do
      assert UiTokens.theme_value!(@css, "dark", "--ops-bg") == "#123456"
      assert UiTokens.theme_value!(@css, "light", "--ops-bg") == "#abcdef"
    end

    test "raises when the property or the block is missing" do
      assert_raise ArgumentError, ~r/--ops-missing is not declared in the dark theme block/, fn ->
        UiTokens.theme_value!(@css, "dark", "--ops-missing")
      end

      assert_raise ArgumentError, ~r/no sepia daisyUI theme block/, fn ->
        UiTokens.theme_value!(@css, "sepia", "--ops-bg")
      end
    end

    test "raises when the property is declared twice in the named block" do
      duplicated = UiTokens.duplicate_theme_declaration!(@css, "dark", "--ops-bg")

      assert_raise ArgumentError,
                   ~r/--ops-bg is declared more than once in the dark theme block/,
                   fn ->
                     UiTokens.theme_value!(duplicated, "dark", "--ops-bg")
                   end

      assert UiTokens.theme_value!(duplicated, "light", "--ops-bg") == "#abcdef"
    end

    test "reads both live theme blocks of the ScrypathOps stylesheet" do
      css = File.read!(Path.join(@root, "scrypath_ops/assets/css/app.css"))

      for mode <- ["light", "dark"],
          property <- ["--ops-bg", "--ops-surface-1", "--color-primary"] do
        assert UiTokens.theme_value!(css, mode, property) =~ ~r/\A#[0-9a-fA-F]{6}\z/
      end
    end
  end

  describe "replace_theme_value!/4" do
    test "changes only the named block" do
      changed = UiTokens.replace_theme_value!(@css, "light", "--ops-bg", "#010203")

      assert UiTokens.theme_value!(changed, "light", "--ops-bg") == "#010203"
      assert UiTokens.theme_value!(changed, "dark", "--ops-bg") == "#123456"
      assert UiTokens.theme_value!(changed, "light", "--ops-surface-1") == "#ffffff"
    end

    test "raises instead of silently changing nothing" do
      assert_raise ArgumentError, fn ->
        UiTokens.replace_theme_value!(@css, "dark", "--ops-missing", "#010203")
      end
    end
  end

  describe "color helpers" do
    test "bump_hex returns a different, valid, lowercase color" do
      for hex <- ["#123456", "#ABCDEF", "#ffffff", "#000000"] do
        bumped = UiTokens.bump_hex(hex)
        assert bumped =~ ~r/\A#[0-9a-f]{6}\z/
        refute bumped == String.downcase(hex)
      end

      assert UiTokens.bump_hex("#ff0000") == "#fe0000"
    end

    test "rgb_components and rgb_function agree with the hex" do
      assert UiTokens.rgb_components("#ff8000") == [1.0, 128 / 255, 0.0]
      assert UiTokens.rgb_function("#aabbcc") == "rgb(170 187 204)"
    end

    test "relative_luminance follows WCAG 2.x" do
      assert UiTokens.relative_luminance("#000000") == 0.0
      assert_in_delta UiTokens.relative_luminance("#ffffff"), 1.0, 1.0e-9
      assert_in_delta UiTokens.relative_luminance("#808080"), 0.2158605, 1.0e-6
      assert UiTokens.relative_luminance("#123456") < UiTokens.relative_luminance("#abcdef")
    end

    test "non-hex input is refused" do
      assert_raise ArgumentError, ~r/expected a #rrggbb color/, fn ->
        UiTokens.bump_hex("rgb(1 2 3)")
      end
    end
  end
end
