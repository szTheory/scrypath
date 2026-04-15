# Pitfalls Research: Scrypath

**Research date:** 2026-04-15

## Pitfalls

### 1. Pretending search is strongly consistent

- **Why it hurts:** users build incorrect expectations and production bugs become confusing
- **Warning signs:** docs imply instant consistency; tests assume queued writes are immediate
- **Prevention:** document eventual consistency clearly, support explicit sync modes, provide test helpers
- **Phase:** Phase 1 and Phase 2

### 2. Over-abstracting multiple backends too early

- **Why it hurts:** the public API gets shaped around the lowest common denominator and becomes awkward
- **Warning signs:** adapter layer starts dictating user-facing APIs before one backend is deeply supported
- **Prevention:** keep the seam internal in v1 and document the future-extensibility intent
- **Phase:** Phase 1

### 3. Hiding side effects in magical callbacks

- **Why it hurts:** users cannot reason about writes, jobs, or failure modes
- **Warning signs:** schema macro begins injecting repo-aware or process-aware behavior
- **Prevention:** keep macros metadata-only and expose explicit runtime orchestration functions
- **Phase:** Phase 1 and Phase 2

### 4. Broken delete semantics in async flows

- **Why it hurts:** deleting source rows before job execution creates drift and noisy failures
- **Warning signs:** delete jobs try to reload missing records from the database
- **Prevention:** carry stable document identity in the job payload and delete directly from the index
- **Phase:** Phase 2

### 5. Reindex workflows that reset or lose settings

- **Why it hurts:** rebuilds can silently degrade production search quality
- **Warning signs:** reindex code treats settings as incidental metadata
- **Prevention:** make settings application part of reindex orchestration and document cutover behavior
- **Phase:** Phase 3

### 6. N+1 explosions during backfill and hydration

- **Why it hurts:** performance falls off quickly on real datasets
- **Warning signs:** backfill loops or hydration paths query one record at a time without planning
- **Prevention:** design batch-oriented APIs, preload intentionally, and test on realistic workloads
- **Phase:** Phase 2 and Phase 3

### 7. Phoenix support treated as an afterthought

- **Why it hurts:** the main adopter audience sees the library as generic and awkward
- **Warning signs:** docs only show generic REPL usage and skip Plug, controller, or LiveView examples
- **Prevention:** dedicate roadmap work to Phoenix-facing docs and ergonomic patterns
- **Phase:** Phase 4
