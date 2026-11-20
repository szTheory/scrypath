# Scrypath

The shared language for Scrypath and its operator UI, ScrypathOps. User-facing terms come first. UI copy, docs, stories and the copy lint all use these words. Scrypath's audience is working Elixir/Phoenix engineers, so a precise technical term is right when it names the thing the person must act on.

## People and fixtures

**Operator persona**:
A named, fictional person who opens ScrypathOps for a job. Each one is defined by a trigger, skill level, device and habits, and maps onto the `ROLE-*`/`JOB-*` ids.
_Avoid_: persona (on its own), user, profile

**Adopter twin**:
A fictional product whose data Scrypath indexes (for example a team-chat app or a language-learning app). It is used as realistic fixture data.
_Avoid_: digital twin, profile, persona (on its own), tenant

**Story**:
One rendered UI situation in the ScrypathOps storybook. Each variation cites an adopter twin, an operator persona and a `JOB-*`.
_Avoid_: example, demo, fixture page

**Primitive** / **Pattern** / **Area** / **Surface** / **Job** (story levels):
The levels of the story tree, from smallest to largest:
- **Primitive:** a single component.
- **Pattern:** a small group of components that work together.
- **Area:** one region of a surface.
- **Surface:** a whole screen.
- **Job:** a whole page in one persona's `JOB-*` situation.

_Avoid_: section (for surface), page (for job)

## Surfaces

**Control room**:
The ScrypathOps home: overall status, plus a way into each surface.

**Search health**:
The per-schema view of whether search is usable right now.

**Failed sync work**:
The list of sync work that didn't complete, with its evidence and any recovery the operator is allowed to take.

**Sync and index**:
The surface for comparing index settings, promoting an index and checking document visibility.
_Avoid_: Sync and drift (former name)

**Search**:
The surface for running a bounded query against selected schemas and inspecting per-schema results. Saved searches live here.

**Saved search**:
A stored search definition that can be rerun. It may hold several schema/query entries. It is not a stored result, a pass/fail test, a scheduled job or a completed run.
_Avoid_: Playbook (except as the API and file-format name), saved check

**Per-schema results**:
The results of one search, kept separate for each selected schema. There is no merged index and no combined relevance score.
_Avoid_: federated results, merged results

**Record loading**:
The app-side lookup of matching Ecto records after a search returns. It is not a Meilisearch operation.
_Avoid_: hydration (in UI copy)

**Help**:
The surface explaining how to use ScrypathOps and where to go next.

## Sync and evidence

**Schema**:
An Ecto schema that Scrypath indexes. The selected schema sets the scope of evidence and recovery.
_Avoid_: collection, model

**Sync work**:
Work in the host application's queue that carries record changes to the search index. In Oban mode it is a queue job.
_Avoid_: Meilisearch task, backend task (for this concept)

**Queue job**:
One unit of sync work in the host application's queue.
_Avoid_: task

**Meilisearch task**:
An asynchronous operation that Meilisearch has accepted. Being accepted doesn't mean it's complete.
_Avoid_: job, sync work

**Backend task**:
The implementation-neutral name for a Meilisearch task, used only where the backend isn't the point.

**Sync mode**:
How writes reach the index: inline, background (Oban) or manual. It describes the write path, not completion or freshness.

**Index settings**:
The searchable, filterable and ranking configuration of an index. Declared and live settings matching doesn't prove that documents are fresh or visible.
_Avoid_: contract (outside advanced detail)

**Document visibility**:
Whether specific documents can be found in the active index at an observed time.
_Avoid_: freshness (when no observation was made), synced

**Configured schemas**:
The schemas this ScrypathOps installation is allowed to act on.
_Avoid_: allowlist (outside setup and access errors)

**Storage folder**:
The server-side folder where saved searches are kept as files.
_Avoid_: workspace (as a team or account concept)

## Status wording

The words ScrypathOps screens use to report sync state. Screen copy follows these entries, and `scrypath_ops/test/support/copy_rules.json` enforces them.

**Searchable**:
A label for one record's or update's state, used only together with the time it was observed: that record could be found in the active index at that time. It is never a setting value. The settings row for fields is "Searchable fields", and its values are "Used for search" and "Not used for search".
_Avoid_: Searchable (as a setting value, or without an observation time), Not searchable, Not searched yet

**Pending**:
Sync work that has not finished, counted for a row or a schema: "2 pending", or the Pending status word beside such a count. It is an aggregate, not the state of one update.
_Avoid_: queued (for a count over a row or a schema)

**Queued**:
The step one update is in once the host application's queue holds it, and the outcome shown after a retry hands work to that queue. It is not a count over a row or a schema; that is Pending.
_Avoid_: Pending (for one update's step), accepted (for the host queue)

**Retry queued**:
What the operator sees after retrying failed sync work: the host application's queue now holds the retry job. It says nothing about Meilisearch and does not confirm recovery.
_Avoid_: Retry accepted, Retry sent, resubmitted

**Accepted**:
Reserved for a Meilisearch task that Meilisearch has taken (see Meilisearch task). "Index swap accepted" is correct. Work in the host application's queue is queued, never accepted.
_Avoid_: accepted (for sync work, a queue job or a retry)

**Last succeeded**:
The time of the most recent success, written "Last succeeded" or "<source> last succeeded" beside a time.
_Avoid_: Last success, Last successful

**Clear**:
The status word for a source that was observed with nothing pending, retrying or failed. It needs an observation, and it is not shown beside an earlier observation that a failed refresh left on screen. It does not mean documents are searchable.
_Avoid_: Healthy, All good, Searchable (as a synonym for Clear)
