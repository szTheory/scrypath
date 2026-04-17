# Sync Modes And Visibility

Scrypath makes sync mode explicit because search visibility is an operational concern, not hidden framework magic.

## The Contract

| Mode | What completed work means | What it does not mean |
|------|---------------------------|------------------------|
| `:inline` | Scrypath waited for terminal backend success | database and search writes are not atomic |
| `:manual` | the backend accepted work | the document may not be searchable yet |
| `:oban` | the enqueue is durable | the backend write has not happened yet |

Accepted work is not the same thing as search visibility.

## `:inline`

Use `:inline` when the write path should wait for terminal backend task success before it returns.

What you can see:

- backend success or failure before the caller continues
- `mix scrypath.status` for current backend visibility
- `mix scrypath.reconcile` when you suspect drift after a deployment or contract change

What can still fail:

- database and search writes are still not atomic
- later reads can still surface stale search hits if the contract changed

Recovery posture:

- retry explicit failed work if the original contract still holds
- backfill the live index when the index is still trustworthy
- reindex when mappings or settings changed and the live index should not be trusted

## `:oban`

Use `:oban` when durable enqueue matters more than immediate search visibility.

What you can see:

- the enqueue is durable
- queue backlog, retrying work, and failed jobs via `mix scrypath.status` and `mix scrypath.failed`
- report-first action guidance via `mix scrypath.reconcile`

What can still fail:

- the backend write may not have started yet
- retry exhaustion, discarded jobs, and stale deletes are operational cases, not surprises

Recovery posture:

- inspect retryable work first
- use `mix scrypath.retry` only with one explicit failed-work id
- move to backfill or reindex when the issue is larger than one queue replay

## `:manual`

Use `:manual` when operators or migration workflows should hold the next step explicitly.

What you can see:

- accepted backend work
- the current live/target index posture through `mix scrypath.reconcile`
- the same report-first guidance as the other modes

What can still fail:

- accepted work does not mean the document is searchable yet
- manual follow-up can drift from the source of truth if nobody closes the loop

Recovery posture:

- use status and reconcile to decide whether the live index is still sound
- prefer backfill when the contract is unchanged
- prefer reindex when the contract changed or rebuild visibility is already pointing at a target index

## Phoenix Implications

This wording matters in Phoenix because a controller response, JSON payload, or LiveView state update can easily over-promise what happened.

- A successful controller action can mean repo write succeeded while search visibility is still pending
- A LiveView update can reflect database state before async search work completes
- An Oban-backed flow means the durable enqueue succeeded, not that the search backend finished

The recommended boundary is still the same: let the context choose the mode, then let the controller or LiveView present the outcome honestly.

## Where To Put The Decision

Choose sync mode in the context that owns the feature. That keeps consistency and recovery tradeoffs close to the repo write and close to the operator workflow that will respond when drift appears.

## Recovery Still Matters

Retries, stale deletes, and drift are normal operator concerns. When the live index contract is still correct, backfill into the live index. When the contract changed or you do not trust the live index, rebuild into a target index and review before cutover.

The thin CLI wrappers in `guides/operator-mix-tasks.md` exist to make those checks easy from a terminal, but the real operator contract still lives on `Scrypath.*`.
