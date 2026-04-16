# Sync Modes And Visibility

Scrypath makes sync mode explicit because search visibility is an operational concern, not hidden framework magic.

## The Contract

| Mode | What completed work means | What it does not mean |
|------|---------------------------|------------------------|
| `:inline` | Scrypath waited for terminal backend success | database and search writes are not atomic |
| `:manual` | the backend accepted work | the document may not be searchable yet |
| `:oban` | the enqueue is durable | the backend write has not happened yet |

Accepted work is not the same thing as search visibility.

## Phoenix Implications

This wording matters in Phoenix because a controller response, JSON payload, or LiveView state update can easily over-promise what happened.

- A successful controller action can mean repo write succeeded while search visibility is still pending
- A LiveView update can reflect database state before async search work completes
- An Oban-backed flow means the durable enqueue succeeded, not that the search backend finished

## Where To Put The Decision

Choose sync mode in the context that owns the feature. That keeps consistency and recovery tradeoffs close to the repo write and close to the operator workflow that will respond when drift appears.

## Recovery Still Matters

Retries, stale deletes, and drift are normal operator concerns. When the live index contract is still correct, backfill into the live index. When the contract changed or you do not trust the live index, rebuild into a target index and review before cutover.
