# API Coverage — Meilisearch adapter exercised by Phase 160

Phase 160 validates the existing package against the current Phoenix adopter flows. The matrix covers the Meilisearch endpoints exposed by `Scrypath.Meilisearch.Client`; it does not claim to add backend capabilities.

| capability | decision | reason |
|---|---|---|
| create index | INTEGRATE | The live Phoenix proof creates isolated indexes for the package-backed inline and Oban consumer scenarios. |
| update index settings | INTEGRATE | Existing schema settings are applied as part of preparing the consumer index. |
| add or update documents | INTEGRATE | Inline synchronization and Oban workers write projected Post and related-data documents. |
| search documents | INTEGRATE | The four live scenarios query indexed records and confirm hydrated results or updated related fields. |
| retrieve task status | INTEGRATE | Inline synchronization waits for Meilisearch task completion before reporting success. |
| delete index | INTEGRATE | Each live scenario removes its uniquely named test index during cleanup. |
| retrieve index settings | OPT-OUT | Settings drift inspection is outside the package-to-consumer proof scenarios. |
| swap indexes | OPT-OUT | Reindex cutover is an independent operational workflow and is not exercised by this phase. |
| delete documents | OPT-OUT | The scenarios validate upsert and search; they do not exercise document-level deletion. |
| list tasks | OPT-OUT | The proof observes task completion by UID and does not query task listings or filters. |
| facet search | OPT-OUT | Facet behavior is not part of the existing Phoenix package acceptance scenarios. |
| multi-search | OPT-OUT | Batched search behavior is not part of the existing Phoenix package acceptance scenarios. |
