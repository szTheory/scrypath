defmodule Scrypath.ProjectionTest do
  use ExUnit.Case, async: true

  defmodule CustomSearchablePost do
    use Ecto.Schema

    use Scrypath,
      fields: [:title],
      filterable: [:status],
      sortable: [:inserted_at]

    embedded_schema do
      field(:title, :string)
      field(:status, :string)
      field(:inserted_at, :utc_datetime)
    end

    def search_document(post) do
      %{
        id: "post:#{post.title}",
        title: String.upcase(post.title),
        summary: "#{post.status}-summary"
      }
    end
  end

  defmodule MissingFieldSearchablePost do
    use Ecto.Schema

    use Scrypath, fields: [:title, :body]

    embedded_schema do
      field(:title, :string)
    end
  end

  defmodule TenantFieldCustomPost do
    use Ecto.Schema

    use Scrypath,
      fields: [:title, :tenant_id],
      tenant_field: :tenant_id

    embedded_schema do
      field(:title, :string)
      field(:tenant_id, :integer)
    end

    def search_document(post) do
      %{title: String.upcase(post.title)}
    end
  end

  defmodule TenantFieldCustomPostAlreadyIncludes do
    use Ecto.Schema

    use Scrypath,
      fields: [:title, :tenant_id],
      tenant_field: :tenant_id

    embedded_schema do
      field(:title, :string)
      field(:tenant_id, :integer)
    end

    def search_document(post) do
      %{title: String.upcase(post.title), tenant_id: post.tenant_id}
    end
  end

  test "projects declared fields by default" do
    document =
      Scrypath.Projection.document(SearchablePost, %SearchablePost{
        id: 123,
        title: "Hello",
        body: "World",
        status: "published"
      })

    assert document == %Scrypath.Document{
             id: 123,
             data: %{title: "Hello", body: "World"},
             source: :fields
           }
  end

  test "uses search_document/1 when present" do
    document =
      Scrypath.Projection.document(CustomSearchablePost, %CustomSearchablePost{
        title: "Hello",
        status: "published"
      })

    assert document == %Scrypath.Document{
             id: "post:Hello",
             data: %{title: "HELLO", summary: "published-summary"},
             source: :custom
           }
  end

  test "document_source reports default and custom sources" do
    assert Scrypath.Projection.document_source(SearchablePost) == :fields
    assert Scrypath.Projection.document_source(CustomSearchablePost) == :custom
    assert Scrypath.document_source(CustomSearchablePost) == :custom
  end

  test "raises when a declared field is missing from the source record" do
    assert_raise ArgumentError, ~r/missing projected field :body/, fn ->
      Scrypath.Projection.document(MissingFieldSearchablePost, %MissingFieldSearchablePost{
        title: "Hello"
      })
    end
  end

  test "injects tenant_field into document when search_document/1 omits it" do
    document =
      Scrypath.Projection.document(TenantFieldCustomPost, %TenantFieldCustomPost{
        id: 1,
        title: "Hello",
        tenant_id: 42
      })

    assert document.data.tenant_id == 42
    assert document.source == :custom
  end

  test "does not overwrite tenant_field when search_document/1 already includes it" do
    document =
      Scrypath.Projection.document(
        TenantFieldCustomPostAlreadyIncludes,
        %TenantFieldCustomPostAlreadyIncludes{
          id: 1,
          title: "Hello",
          tenant_id: 42
        }
      )

    assert document.data.tenant_id == 42
    assert document.source == :custom
  end

  test "no-op when tenant_field not declared" do
    document =
      Scrypath.Projection.document(CustomSearchablePost, %CustomSearchablePost{
        title: "Hello",
        status: "published"
      })

    assert document.source == :custom
    refute Map.has_key?(document.data, :tenant_field)
  end
end
