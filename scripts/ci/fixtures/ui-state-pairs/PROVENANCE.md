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

The check divides each image into 16 px blocks and runs two signals per block.

1. **Ink share.** The share of pixels that differ from the block's most common color (rounded to 16 steps);
   a block is over when its step differs by more than 2. Accept needs a worst step of at most 8.
2. **Edge count** (added after the Phase 186 review, WR-05). The number of horizontally and vertically
   adjacent pixel pairs whose RGBA differs, attributed to the block of the first pixel; a block is over when
   the count moves by more than 12. A palette swap that keeps neighbouring regions distinct leaves it
   unchanged; a new boundary, border, rule or moved edge does not.

Accept needs, on each signal, at most 0.25 percent of blocks over **and** at most 8 blocks over (the
absolute cap, because 0.25 percent of a 1440 x 900 capture is 12 blocks), and identical dimensions.
`blocks_over / blocks` and `edge_blocks_over / blocks` below are measured with the module's own
`comparePngStructural`. The share-only results are the Plan 03 calibration and did not change.

| Case | Full capture (ink share) | Committed crop (ink share) | Committed crop (edge count) |
|------|--------------|----------------|----------------|
| Recolor accept (173 cool vs warm, dark, 390) | 0 of 5100 over, worst step 1 | 0 of 500 over, worst step 0 | 0 of 500 over, worst delta 1 |
| State-change reject (176 initial vs invalid, dark, 390) | 322 of 1725 over (18.7 percent), worst step 12 | 179 of 500 over (35.8 percent), worst step 8 | 333 of 500 over, worst delta 231 |
| Layout reject (warm capture, band of 100 rows shifted down 8 px, against cool) | 20 of 5100 over (0.39 percent), worst step 6 (rows 600-699) | 71 of 500 over (14.2 percent), worst step 7 (rows 120-219) | 60 of 500 over, worst delta 167 |

Edge count on the full real captures (not committed; sources above and under `.planning/milestones/v1.43-phases/`):
the four recolor pairs (173 cool vs warm, light and dark, 390 and 1440) are 0 blocks over with a worst delta of
5, 2, 7 and 2, so the delta threshold of 12 has at least 1.7 times the largest real recolor movement. The two
real state-change pairs measured (176 dark 390 and light 1440) are 568 of 1725 and 816 of 6210 blocks over.

Other real pairs measured when the thresholds were chosen: 173 cool vs warm light 390 gives 0 of 5100 over;
173 cool vs warm dark 1440 gives 0 of 9630 over (worst step 1); 176 initial vs invalid light 1440 gives
487 of 6210 over (rejected).

Block size 8 and 32 were also measured on the full captures (recolor accepted at both with 0 over; state
reject 1237 of 6762 and 59 of 455; shift reject 82 of 19992 and 4 of 1326), so 16 px is a calibration choice,
not the only value that separates the cases.

## Synthetic cases the ink share alone accepted

The Phase 186 review reproduced these on 1440 x 900 pages: an added full-width solid header bar, an added solid
sidebar, a full-height 1 px rule moved by 8 px, a 400 x 320 card with a 1 px border, and 12 whole new striped
blocks. Flat regions are one color in both images, so their ink share is 0 in both; 1-2 px lines are under the
step tolerance; 12 blocks is under 0.25 percent of 5130. The edge count rejects the first four (each leaves 90
to 112 blocks over, against a limit of 12 on that raster) and the absolute cap rejects the fifth. They are
planted in `ui_state_pairs.test.cjs` ("structural check on flat, aligned and thin-line changes"), together with
a palette swap of the same layout that is accepted with 0 blocks over on both signals.

## Limits

- A single 16-40 px band shifted by 1-8 px stays under the ink-share tolerance.
- An edge that moves by 1-2 px and stays inside one 16 px block looks the same to both signals (both are block
  counts; planted as "a flat-region edge moved by 2 px inside one block is not seen").
- Neither signal is font-invariant: a font change moves glyph edges and ink and is expected to be rejected, not
  accepted as a recolor.
- A recolor that makes two previously identical neighbouring surfaces distinct (or merges two distinct ones)
  changes the edge count in the blocks along that boundary. A few such blocks are inside the tolerance (8 at
  most); a long new border is rejected on purpose. The four real recolors measured here did not do this.
- The thresholds (12 pairs, 8 blocks, 0.25 percent) were calibrated on one real recolor family (the Phase 173
  cool-to-warm change). Retuning needs a new real capture pair in this directory, not a looser number.

The structural check is a coarse backstop for whole-region changes; the geometry, state, copy and semantic
receipts it runs beside (and the action, transport and identity checks, which stay exact) are what catch
small layout moves.
