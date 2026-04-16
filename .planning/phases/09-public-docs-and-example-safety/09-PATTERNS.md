# Phase 09: public-docs-and-example-safety - Pattern Map

**Mapped:** 2026-04-16
**Files analyzed:** 8
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `README.md` | docs | static-reference | `README.md` | exact |
| `guides/getting-started.md` | docs | static-reference | `guides/getting-started.md` | exact |
| `guides/phoenix-controllers-and-json.md` | docs | request-response | `guides/phoenix-controllers-and-json.md` | exact |
| `guides/phoenix-liveview.md` | docs | event-driven | `guides/phoenix-liveview.md` | exact |
| `test/scrypath/docs_contract_test.exs` | test | contract | `test/scrypath/docs_contract_test.exs` | exact |
| `test/support/docs/phoenix_example_case.ex` | fixture | request-response | `test/support/docs/phoenix_example_case.ex` | exact |
| `test/support/docs/phoenix_examples_test.exs` | test | contract | `test/support/docs/phoenix_examples_test.exs` | exact |
| `test/support/docs/phoenix_request_shape_smoke_test.exs` | test | request-response | `test/support/docs/phoenix_examples_test.exs` | close |

## Pattern Assignments

### `README.md` (docs, static-reference)

**Analog:** `README.md`

**Section ordering pattern** ([README.md:5](/Users/jon/projects/scrypath/README.md#L5)):
```md
## Installation
...
## Quick Path
...
## When Scrypath Fits
```

**Dependency snippet pattern** ([README.md:9](/Users/jon/projects/scrypath/README.md#L9)):
```elixir
def deps do
  [
    {:scrypath, "~> 0.1.0"}
  ]
end
```

Use the README itself as the canonical consumer contract. Keep setup prose short and move optional/runtime detail below the install fence.

---

### `guides/getting-started.md` (docs, static-reference)

**Analog:** `guides/getting-started.md`

**Three-piece setup pattern** ([guides/getting-started.md:5](/Users/jon/projects/scrypath/guides/getting-started.md#L5)):
```md
1. A schema that declares search metadata with `use Scrypath`
2. A context that owns repo persistence plus `Scrypath.*` orchestration
3. A backend configuration that keeps sync mode explicit
```

Keep this guide install-adjacent but architecture-oriented. It should reinforce README decisions, not redefine them.

---

### `guides/phoenix-controllers-and-json.md` (docs, request-response)

**Analog:** `guides/phoenix-controllers-and-json.md`

**Controller boundary pattern** ([guides/phoenix-controllers-and-json.md:3](/Users/jon/projects/scrypath/guides/phoenix-controllers-and-json.md#L3)):
```md
Phoenix controllers should translate request params into a context call, then render HTML or JSON from the result.
```

**Request-normalization pattern** ([guides/phoenix-controllers-and-json.md:24](/Users/jon/projects/scrypath/guides/phoenix-controllers-and-json.md#L24)):
```elixir
page_number =
  params
  |> Map.get("page", 1)
  |> normalize_page()
```

Update the helper implementation in place rather than restructuring the guide.

---

### `guides/phoenix-liveview.md` (docs, event-driven)

**Analog:** `guides/phoenix-liveview.md`

**Event payload pattern** ([guides/phoenix-liveview.md:35](/Users/jon/projects/scrypath/guides/phoenix-liveview.md#L35)):
```elixir
def handle_event("publish", %{"id" => id, "post" => attrs}, socket) do
  post = load_post!(id)
  {:ok, _post} = Content.publish_post(post, attrs)
```

Preserve the context-first boundary and make the fixture match the string-keyed payload shape already shown here.

---

### `test/scrypath/docs_contract_test.exs` (test, contract)

**Analog:** `test/scrypath/docs_contract_test.exs`

**Ordered shell contract pattern** ([test/scrypath/docs_contract_test.exs:24](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs#L24)):
```elixir
assert ordered?(@readme, "## Installation", "## When Scrypath Fits")
assert ordered?(@readme, "## Quick Path", "## When Scrypath Fits")
```

**Snippet presence pattern** ([test/scrypath/docs_contract_test.exs:127](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs#L127)):
```elixir
assert_contains_all(@guides["guides/phoenix-controllers-and-json.md"], [
  "page_number =",
  "normalize_page()",
  "page: [number: page_number, size: 20]"
])
```

Extend this file with exact-string assertions and refutations for the install and JSON safety contract.

---

### `test/support/docs/phoenix_example_case.ex` (fixture, request-response)

**Analog:** `test/support/docs/phoenix_example_case.ex`

**Fixture context boundary pattern** ([test/support/docs/phoenix_example_case.ex:11](/Users/jon/projects/scrypath/test/support/docs/phoenix_example_case.ex#L11)):
```elixir
def search_posts(query, opts \\ []) do
  ...
end

def publish_post(%Post{} = post, attrs) when is_map(attrs) do
  ...
end
```

**JSON controller fixture pattern** ([test/support/docs/phoenix_example_case.ex:42](/Users/jon/projects/scrypath/test/support/docs/phoenix_example_case.ex#L42)):
```elixir
def index(params) do
  query = Map.get(params, "q", "")
  page_number = params |> Map.get("page", 1) |> normalize_page()
```

Keep this file as the source of truth for executable docs snippets and tighten behavior in place.

---

### `test/support/docs/phoenix_examples_test.exs` (test, contract)

**Analog:** `test/support/docs/phoenix_examples_test.exs`

**Behavior assertion pattern** ([test/support/docs/phoenix_examples_test.exs:39](/Users/jon/projects/scrypath/test/support/docs/phoenix_examples_test.exs#L39)):
```elixir
response = ApiPostController.index(%{"q" => "ecto", "page" => "2"})
assert response.page == %{number: 2, size: 20}
```

**Fixture source inspection pattern** ([test/support/docs/phoenix_examples_test.exs:47](/Users/jon/projects/scrypath/test/support/docs/phoenix_examples_test.exs#L47)):
```elixir
api_section = module_section("PostController", "Api")
assert api_section =~ "page_number = params |> Map.get(\"page\", 1) |> normalize_page()"
```

Continue using this mix of behavioral checks and fixture-source assertions for docs safety.

---

### `test/support/docs/phoenix_request_shape_smoke_test.exs` (test, request-response)

**Analog:** `test/support/docs/phoenix_examples_test.exs`

Add this as a narrow complementary test file, not a replacement. It should verify realistic nested string-key params, ideally via `Plug.Conn.Query.decode/1`, while staying framework-light.
