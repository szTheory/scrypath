# Phase 185 local verification limit

The maintainer answered “yes” to the pending proposal to allow 25 minutes total for Phase 185 local full browser runs, including the five-minute cleanup reserve. This is 1500 seconds total, 300 seconds reserved for finalization, and at most 900 seconds per Docker operation. Apply it only to new invocations; never extend an existing or failed deadline. Retests require a diagnosed cause and a bounded remedy.

The already running before-only r2 invocation retains its original 900-second deadline and 300-second reserve. Hosted verification retains its 30-minute job limit and 900-second operation cap. Retained-preview, release, merge and inherited-risk boundaries remain unchanged.

The asynchronous answer was also delivered explicitly on 2026-11-01: “Approve 25 minutes total (Recommended).” This confirms the same previously recorded scope and limits; it does not renew failed deadlines or authorize unrelated runs. The accepted refreshed candidate completed in 1206.58 seconds total, including finalization, within that bound.
