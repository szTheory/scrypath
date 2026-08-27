# Core-path benchmarks

These benchmarks guard against speculative optimization. They measure stable,
pure transformations without network, database, or scheduler noise:

- projecting one Ecto record into a search document
- decoding a 250-hit backend response into `Scrypath.SearchResult`

Run the reproducible harness from the repository root:

```sh
MIX_ENV=dev mix deps.get
MIX_ENV=dev mix run bench/core_paths.exs
```

For a quick local comparison, set `BENCHMARK_TIME=1 BENCHMARK_WARMUP=1`.
Record the Elixir/OTP versions, operating system, CPU, git SHA, and complete
Benchee output whenever using a result to justify an optimization. Compare
before and after in the same process environment. These numbers are evidence,
not CI thresholds.
