# Phase 173 UI Audit Disposition

The independent audit remains source-bound to `185832d6c863b1c84c863e1f5f4e9e2c44dbfc18`, scored 17/24. This ledger records subsequent action; it does not rewrite that score or represent maintainer approval.

| Priority | Disposition | Evidence / rationale |
| --- | --- | --- |
| 1: Observational green badges | fixed | `ca0232d` renders observational backend/queue badges neutral and uses “no backend failures observed”; actual failures and unavailable observations retain explicit localized warning copy. Browser assertions check neutral badges. |
| 2: Theme labels at 12px | fixed | `4ab6fad` uses the existing 14px body/action role and retains 44px targets. The shell suite checks computed size for all three preference labels. |
| 3: Uneven expanded signal groups at 1279px | skipped | Nonblocking polish: approved contract requires readable, accessible exact evidence and no overlap/overflow, not equal-height sibling groups. Existing native disclosure wraps and remains keyboard/touch accessible; both boundary widths are covered. Preserve that evidence rather than add a new shared disclosure layout in this phase. |

Final browser proof and independent phase verification assess the corrected source separately. No human-only acceptance item is added.
