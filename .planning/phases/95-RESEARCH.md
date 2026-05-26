# Phase 95: API Contract and Execution - Research

## Architecture Decisions
1. **Scrypath Facade**: Add `Scrypath.search_facet_values/4` and `Scrypath.search_facet_values!/4`.
   - Delegates to `Scrypath.Search.search_facet_values/4`.
   - Bang variant should raise if `{:error, reason}` is returned.
2. **Search Layer**: Add `Scrypath.Search.search_facet_values/4`.
   - Needs to validate options, extract index name, and call backend.
3. **Backend Callback**: Add `@callback search_facet_values/5` to `Scrypath.Backend`.
   - Signature: `(module(), String.t(), String.t(), keyword(), keyword()) :: {:ok, map()} | {:error, term()}`.
4. **Meilisearch Client**: Implement `facet_search` in `Scrypath.Meilisearch.Client`.
   - Endpoint: `POST /indexes/:index_name/facet-search`
   - Payload must contain `"facetName"` and `"facetQuery"`.
5. **Response Struct**: Introduce `Scrypath.FacetSearchResult`.
   - E.g., `defstruct facet_hits: [], facet_query: "", processing_time_ms: 0`

## Known Patterns
- `Scrypath` facade delegates to `Scrypath.Search`.
- `Scrypath.Search` handles option parsing and dispatching to `schema.__scrypath__(:backend)`.
- Backend implementations translate generic opts to provider-specific formats.

## Conclusion
The implementation is straightforward and follows the established `search/3` pattern but targeting a specialized endpoint and returning a specialized struct.
