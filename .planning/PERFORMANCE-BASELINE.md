# Performance Baseline

**Captured:** 2026-08-26

**Code state:** benchmark harness committed in `e0a930f`; measured architecture
state subsequently committed in `4f0f354`

**Environment:** macOS, Apple M5 Pro, 18 available cores, 64 GB memory,
Elixir 1.19.5, Erlang/OTP 28.4.1, JIT enabled

Command:

```sh
BENCHMARK_TIME=1 BENCHMARK_WARMUP=1 MIX_ENV=dev mix run bench/core_paths.exs
```

| Pure path | Throughput | Average | Median | Memory | Reductions |
|-----------|-----------:|--------:|-------:|-------:|-----------:|
| `Projection.document/2` | 8.13 M ips | 122.93 ns | 84 ns | 0.33 KB | 44 |
| `SearchResult.new/4` with 250 hits | 1.91 M ips | 523.40 ns | 416 ns | 1.29 KB | 224 |

The one-second run is a smoke baseline, not publication-grade statistics. A
change must be compared before and after on the same machine with the default
longer harness before performance can justify implementation churn.

## Disposition

No optimization is accepted in this phase. Both paths are sub-microsecond in
the captured environment, while real search latency is dominated by backend
and network work. Refactoring either path for speed would be speculative and
has reached the milestone's diminishing-return boundary. The reproducible
harness remains available for future evidence-led changes.
