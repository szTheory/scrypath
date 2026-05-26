## Summary

<!-- What does this PR change and why? -->

## Release Train

- [ ] PR title is the intended **squash commit title** for Release Please
- [ ] This is ordinary patch-train work (`fix:`) or I intentionally chose a different semver signal
- [ ] This work belongs on a PR branch and is not opportunistic direct-`main` milestone drift

## Evidence (v1.14 B1)

Pull requests that modify **`lib/scrypath/`** or ship **LIB-01**, **LIB-02**, or **LIB-03** work for **v1.14 B1** must cite the frozen evidence ledger.

Evidence:

**`EVID-57-NN`**

Replace **`NN`** with the matching row ID from **`.planning/EVID-01-b1-v1.14.md`** (for example **`EVID-57-01`**). Skip this section only for obvious typo-only or non-normative planning-only edits called out in **`.planning/phases/57-evidence-triage-and-b1-scope-lock/57-CONTEXT.md`**.

## Verification

- [ ] I ran the documented **`mix test`** / **`mix verify.*`** slice for the paths I touched
