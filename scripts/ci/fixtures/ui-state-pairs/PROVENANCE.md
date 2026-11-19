# Calibration fixtures for the structural pair check (TOK-04)

These four PNGs are what `scripts/ci/ui_state_pairs.test.cjs` reads to prove that `comparePngStructural`
(`scripts/ci/ui_state_pairs.cjs`) accepts a real recolor and rejects a real state change and a real layout
move. They are committed so that pruning the `.planning/` milestone archive cannot break the tests.

**Crop method.** Each file is a band of whole rows copied out of a real v1.43 capture (no resampling, no
color change) and written with pngjs `PNG.sync.write` and default options, so the bytes are reproducible
from the sources below with the same pngjs version (7.0.0, locked in `examples/scrypath_ecommerce`).

Sources are under `.planning/milestones/v1.43-phases/`. All four files are 390 x 320 px.

| File | Source | Rows | Bytes | sha256 |
|------|--------|------|-------|--------|
| `recolor-before-dark-390x320.png` | `173-shared-visual-foundation-and-operational-time/173-cool-dark-390.png` (390 x 3261, sha256 `784cee5b0652888a60990851b0c0041aaf85871983c9338b63cf73dd238acb9c`) | 640-959 | 21213 | `88dbf84a7c393082f94640e9c4b10b035061f2c70eea74e95e01a9a461f02a05` |
| `recolor-after-dark-390x320.png` | `173-shared-visual-foundation-and-operational-time/173-warm-dark-390.png` (390 x 3261, sha256 `83f261b2d46ebf30b0c15710adcbf9a76c61e71affbdf740c4f276ddc0306d55`) | 640-959 | 21127 | `df96b7746d4887b66c7169dc330f57bd95fc35c8fb5bb7944e78e25eb58e7753` |
| `state-before-dark-390x320.png` | `176-search-and-playbooks/176-playbooks-delete-dialog-initial-dark-390.png` (390 x 1100, sha256 `cc56b810e1a54b9134de432db2959ab7d16e9b9dd5f3decbc343ad2ce557d823`) | 320-639 | 41914 | `25649f00cb9d92650335f9f7d3a7d6382f2b4236d87088dc281ce44af34a35e9` |
| `state-after-dark-390x320.png` | `176-search-and-playbooks/176-playbooks-delete-dialog-invalid-dark-390.png` (390 x 1100, sha256 `8b17d2193314e5f95e2f9795ee27b79423c0b7e8854276747478522319dd9fa6`) | 320-639 | 50358 | `001be9ffdc686775cc2cc5fb899d1ed83eb38e898cec68f9c8fb6b5a0ab014af` |

The recolor pair is the same page before and after the Phase 173 cool-to-warm recolor. The state pair is the
Phase 176 delete dialog before and after an invalid submit (a real state change, same palette).

## Measured results

The check divides each image into 16 px blocks, takes per block the share of pixels that differ from the
block's most common color (rounded to 16 steps), and counts blocks whose step differs by more than 2.
Accept needs at most 0.25 percent of blocks over and a worst step of at most 8, with identical dimensions.
`blocks_over / blocks` below is measured with the module's own `comparePngStructural`.

| Case | Full capture | Committed crop |
|------|--------------|----------------|
| Recolor accept (173 cool vs warm, dark, 390) | 0 of 5100 over, worst step 1 | 0 of 500 over, worst step 0 |
| State-change reject (176 initial vs invalid, dark, 390) | 322 of 1725 over (18.7 percent), worst step 12 | 179 of 500 over (35.8 percent), worst step 8 |
| Layout reject (warm capture, band of 100 rows shifted down 8 px, against cool) | 20 of 5100 over (0.39 percent), worst step 6 (rows 600-699) | 71 of 500 over (14.2 percent), worst step 7 (rows 120-219) |

Other real pairs measured when the thresholds were chosen: 173 cool vs warm light 390 gives 0 of 5100 over;
173 cool vs warm dark 1440 gives 0 of 9630 over (worst step 1); 176 initial vs invalid light 1440 gives
487 of 6210 over (rejected).

Block size 8 and 32 were also measured on the full captures (recolor accepted at both with 0 over; state
reject 1237 of 6762 and 59 of 455; shift reject 82 of 19992 and 4 of 1326), so 16 px is a calibration choice,
not the only value that separates the cases.

## Limits

A single 16-40 px band shifted by 1-8 px stays under the tolerance. The structural check is a coarse
backstop for whole-region changes; the geometry, state, copy and semantic receipts it runs beside are what
catch small layout moves.
