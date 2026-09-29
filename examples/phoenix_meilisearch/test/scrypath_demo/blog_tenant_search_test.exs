defmodule ScrypathDemo.BlogTenantSearchTest do
  use ScrypathDemo.DataCase, async: false

  alias ScrypathDemo.Blog

  test "exposes the host-owned tenant search entrypoint" do
    assert function_exported?(Blog, :search_posts, 4)
  end
end
