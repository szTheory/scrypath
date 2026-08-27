defmodule Scrypath.Bench.Post do
  use Ecto.Schema

  use Scrypath,
    fields: [:title, :body, :category, :price],
    filterable: [:category],
    sortable: [:price],
    faceting: [attributes: [:category]]

  schema "bench_posts" do
    field(:title, :string)
    field(:body, :string)
    field(:category, :string)
    field(:price, :integer)
  end
end

alias Scrypath.Bench.Post

record =
  struct!(Post,
    id: 42,
    title: "Declarative search",
    body: String.duplicate("Ecto-native indexing ", 20),
    category: "libraries",
    price: 1_299
  )

raw_result = %{
  "hits" =>
    for id <- 1..250 do
      %{
        "id" => id,
        "title" => "Result #{id}",
        "body" => String.duplicate("search ", 10),
        "category" => "libraries",
        "price" => id
      }
    end,
  "estimatedTotalHits" => 250,
  "processingTimeMs" => 2,
  "facetDistribution" => %{"category" => %{"libraries" => 250}},
  "facetStats" => %{"price" => %{"min" => 1, "max" => 250}}
}

query = Scrypath.Query.new("ecto", facets: [:category], page: [number: 1, size: 250])

time = System.get_env("BENCHMARK_TIME", "2") |> String.to_integer()
warmup = System.get_env("BENCHMARK_WARMUP", "1") |> String.to_integer()

Benchee.run(
  %{
    "projection.document/2" => fn -> Scrypath.Projection.document(Post, record) end,
    "search_result.new/4 (250 hits)" => fn ->
      Scrypath.SearchResult.new(query, raw_result, [], [])
    end
  },
  time: time,
  warmup: warmup,
  memory_time: time,
  reduction_time: time,
  print: [benchmarking: true, configuration: true, fast_warning: false]
)
