# v1.50 prep D: agent-operable CLI (SEED-005)

2026-11-25. Static reading and official docs; nothing was run.

## Recommendation

**Build the first slice as the milestone after v1.50 (v1.51): one read-only diagnosis report that works inside a release. Pull the CLI truth fixes into v1.50, ahead of 0.3.21.** Confidence: read-only first 0.85; fixes now 0.9; this placement 0.7.

## What exists, and what is wrong today

Present: tasks for status, failed, retry, reconcile, settings read/diff/hot_apply and contract drift; matching `Scrypath.*` functions; 11 fixture scenarios.

1. **Queue false-clear (most serious).** The CLI never supplies `oban_inspector` outside `MIX_ENV=test` (`lib/scrypath/cli/operator_task.ex:11-36,82-88`). It is not a runtime option (`lib/scrypath/options.ex:65,703-711`), so app defaults cannot carry it. Without one the queue "read" returns `[]` (`lib/scrypath/oban/inspect.ex:7-13`) and Oban mode marks it observed (`lib/scrypath/operator/status.ex:84-118`). So `mix scrypath.status` should print "Queue observed: yes, failed: 0" without reading the queue.
2. **CLI retry looks unable to succeed in an adopter app.** Meilisearch rows are never retryable (`operator/failed_work/translation.ex:21`) and Oban rows never arrive. Tests inject the inspector, hiding this. `guides/sync-modes-and-visibility.md:85` promises queue visibility. The demo sets an inspector only for ScrypathOps, so UI and CLI would disagree.
3. `--id` ignores the source; the first match wins, Meilisearch rows first (`operator_task.ex:107-112`, `failed_work.ex:135-143`).
4. Reconcile offers `reindex` while one is pending (`operator/reconcile.ex:217-227`). `--action backfill|reindex` takes no acknowledgement (`scrypath.reconcile.ex:45-58`); `hot_apply` does.
5. `settings.diff` tells the user to run `mix scrypath.reindex`, which does not exist (`scrypath.settings.diff.ex:124`; a test pins the string).
6. Only `failed`, `settings.diff` and `contract_drift` have `--json`. `failed --json` has no top-level version, environment, observation state, timestamps or cause text (`operator_task.ex:172-202`), so an unread queue looks like `entries: []`.
7. Task history over 1,000 returns only an error (`meilisearch/tasks.ex:12,81`; finding F1), likely during a big incident.
8. SEED-005 says to reuse the ScrypathOps view modules. Hex users cannot: `scrypath_ops` is not packaged (`mix.exs:321`). Shared verdict logic must move into core.

## Production: Mix is not there

[Mix release docs](https://mix.hexdocs.pm/Mix.Tasks.Release.html): "Mix is a build tool and it is not available inside releases." No `mix scrypath.*` command works in a normal release. [Phoenix](https://phoenix.hexdocs.pm/releases.html) generates a `Release` module run by `bin/app eval`; for Ecto migrations it loads the app and starts only what it needs. [Oban's API](https://oban.hexdocs.pm/Oban.html) documents retry and queue functions, no production CLI; `check_queue` sees only queues running on the local node.

- `eval` is a new VM with nothing started. Start Req and the repo only. `ensure_all_started(:my_app)`, as in `guides/relevance-tuning.md:106`, can boot a second set of queue consumers.
- `rpc` runs in the live node. **A `System.halt` reached through `rpc` stops production**; two current tasks halt with exit 2. Core must return `{exit_code, output}`; only an `eval` or Mix wrapper may halt.
- `rpc`, `eval` and `remote` are arbitrary code execution. Interpolating agent input into the expression is code injection.

## The smallest valuable slice

`mix scrypath.diagnose Schema --json`, plus a copy-paste `MyApp.Release.scrypath_diagnose/0` over the same Mix-free function. Report only.

- **Queue reader:** a built-in read through the configured repo (the demo inspector is about 40 lines). Do not copy its limit of 100 over all states, which can hide old failures; filter by state and report truncation.
- **Per source:** `observed | not_observed | not_used | truncated | error`. Never `clear` unless every required source was observed.
- **Contract:** one stdout document: `format_version`, library version, `observed_at`, mode, sources, verdict, failed work keyed `oban:601`, eligibility, and next checks as closed codes with consequences, no ready-to-run write commands. Start at `0.x`; follow [Terraform's rule](https://developer.hashicorp.com/terraform/internals/json-format) (ignore unknown fields, reject unknown majors). Golden files and key-set tests; no schema dependency.
- **Exit codes:** 0 clear, 2 problems, 3 incomplete observation, 1 tool error, also reported as JSON. Logs must not pollute stdout.
- **Environment:** an explicit name (`SCRYPATH_ENVIRONMENT`), echoed with index prefix and backend host (no userinfo). Unset means `unknown`, treated as production. Never infer from `MIX_ENV`.
- **Read-only, honestly:** the command calls no write. It cannot constrain an agent with a shell. Document a fixed host wrapper with an allowlisted schema, a [Meilisearch key](https://www.meilisearch.com/docs/reference/api/keys) limited to `tasks.get` and `settings.get`, and a read-only database role. [OWASP](https://genai.owasp.org/llmrisk/llm062025-excessive-agency/) says to enforce authorization downstream, not in the model; [Supabase](https://supabase.com/docs/guides/getting-started/mcp) likewise pairs diagnostics with a read-only user and says result wrapping is not foolproof.
- **Leakage and injection:** allowlist serialization, never struct dumps (retry references hold whole job args, `translation.ex:74-84`; old jobs may hold documents). Omit error text and record ids by default. Opt-in text is length-bounded, stripped of control and bidi characters, under `untrusted_text`. Backend messages are unbounded (`translation.ex:112-118`) and can echo indexed content; human output prints them raw (`operator_task.ex:164-167`), so a newline can forge a row. Labelling reduces injection risk; only powerless credentials contain it. No API keys in output; steer users off `--meilisearch-api-key` (`operator_task.ex:29`). Drift reports key names, not synonym values.

**Actions later, not in this milestone.** First candidate: retry one Oban job. Plan, then apply with a plan id that is refused if state changed (compare Terraform's [saved plan](https://developer.hashicorp.com/terraform/cli/commands/plan)), environment echoed, separate credentials, a person confirming in production, and a stdout/telemetry action record. Report only `accepted` until verified: job to backend task to document correlation lives in ScrypathOps memory with a 10-minute lifetime (`recovery_observation.ex:15`), so core cannot prove recovery yet. Today's "Retried failed work" wording overclaims. Reindex, backfill, settings and anything bulk stay human-only. No MCP server: [MCP](https://modelcontextprotocol.io/specification/2025-06-18/server/tools) says a human should be able to deny calls and treats annotations from untrusted servers as untrusted; wrap the CLI only when someone has no shell.

**Evals.** Required, deterministic: each scenario yields the expected verdict, source states and eligible refs; sentinel secrets and hostile strings never appear by default. Add unread queue, pending reindex, id collision and an error message carrying instructions (current hostile strings test rendering). Run from `scrypath_ops`; fixtures already depend on `scrypath`. Advisory, repeated: a model sees only the output; score correct next step and refusal of wrong ones. Check one real release in the clean-consumer smoke.

## Shape and placement

**v1.50 additions (about 2 plans):** items 1 and 3 to 6 above (for 6, only report queue observation), the guide's `eval` example, each with a test that fails first. Item 1: no inspector means `observed?: false`, and ship the reader so retry works. Extend the consumer walk with one incident leg in a release; record what an agent gets wrong as the baseline.

**v1.51 (about 5 to 7 plans):** (a) diagnosis builder, F1 partial result, shared verdict; (b) Mix and release entry points plus contract; (c) evals and an incident guide.

| Option | Verdict |
|---|---|
| Inside v1.50 | Roughly doubles it, delays the testing guide and release, and rushes a public contract |
| **After v1.50** | Fixes ship early; walk evidence shapes the contract |
| Replace v1.50 | Drops the adopter's testing need with no outside evidence for either |

## Recorded decisions this touches (needs your yes)

- **v1.50:** order kept; scope grows by the fixes, including root `lib/` behavior (ask-first in the v1.49 run).
- **v1.51 Catalog breadth would move to v1.52**, and Announce-ready after it. Its condition is met (Phase 198 was cut), so this reorders an adopted line; storybook coverage is deferred, not dropped. The fixtures-folding revisit stays due at v1.51.
- **Scope guard** (`PROJECT.md`): a new command and JSON contract is new public surface. Record it as a deliberate strategic decision; consider 0.4.0.
- SEED-005 "reuse the view modules" becomes "move the logic into core".

## Lenses and adversarial pass

- Security: the real boundary is host credentials. Product/adopter: truthful status matters without any AI; demand is unproven. Architecture: one pure builder, three thin callers (UI, Mix, release). DevOps/SRE: partial results beat errors mid-incident. Maintainer: each contract field is upkeep. UX/accessibility: human output uses the UI's words, status never by colour alone.
- "An agent can just use `rpc`." It can, with full power. The report gives a narrow, allowlistable, bounded path.
- "You say it is very important, then wait." The unsafe parts today are fixed first; waiting costs about one small milestone.
- "Fixes are enough." Possibly. If the walk's agent diagnoses correctly with fixed tasks, shrink v1.51 to JSON plus release entry.
- "Read-only is theatre." Yes, if the agent has an unrestricted shell. Say so.
- "No users for the contract." Hence `0.x` and a small field set.

## What would change this

- You want agent use ahead of the testing guide: make diagnosis phase one of v1.50 and move highlight/paging out.
- An adopter incident or request: bring v1.51 forward.
- A failing test disproves items 1 and 2: confidence in "fixes now" drops; the release gap remains.
- No release users, or the walk finds nothing: shrink.

## Not verified

Items 1 to 5 are code reading (high confidence), not reproduced. Also unchecked: `eval`/`rpc` exit status and stdout cleanliness, what a second concurrent reindex does, and any agent's behaviour.
