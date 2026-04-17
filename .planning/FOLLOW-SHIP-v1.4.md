# v1.4 ship — follow in order

**Status 2026-04-17:** Completed for **`scrypath 0.3.1`** (Hex + GitHub Actions). Keep this file as a template for the next release.

Do **step 1 → end** in order. Deep detail and failure recovery: **`docs/releasing.md`**.

**Replace `X.Y.Z`** below with the **semver only** (no `v`) of the release Release Please just produced — the same string as `@version` in `mix.exs` on the release tag.

---

## 1. Secrets (skip if already set)

- [ ] In the GitHub repo: **Settings → Secrets and variables → Actions**
- [ ] `HEX_API_KEY` exists and can publish **`scrypath`**

## 2. Push what is on your machine

```bash
cd /path/to/scrypath   # this repo
git status             # should be clean
git push origin main
```

- [ ] Push succeeded (CI green on `main` is normal before the release PR).

## 3. Optional local confidence (2 minutes)

```bash
mix verify.phase11
```

- [ ] Command finished without error (or you are comfortable trusting CI only).

## 4. Release Please PR

- [ ] On GitHub: **Pull requests** → find the **Release Please** release PR (version/changelog/manifest bump; not random feature PRs).
- [ ] Open it. In the diff, confirm **one** new version: `mix.exs`, `.release-please-manifest.json`, and `CHANGELOG.md` **top entry** all match **`X.Y.Z`** / **`vX.Y.Z`** consistently.

## 5. Merge the release PR

- [ ] **Merge** that PR to **`main`** (use the project’s normal merge policy).

## 6. Watch the publish workflow

GitHub runs **`.github/workflows/release-please.yml`**. When it creates a release, the **publish** job tags and runs **`mix hex.publish`**, then **`mix verify.release_publish`**, then **`mix verify.release_parity`** on the server.

```bash
gh run list --workflow release-please.yml --limit 5
# pick the latest run id, then:
gh run watch <RUN_ID>
```

- [ ] Workflow finished **green** (especially the **publish** / Hex job).

## 7. Record the version you actually shipped

After green:

```bash
git fetch origin --tags
git tag --sort=version:refname | tail -n 5
```

- [ ] You wrote down **`X.Y.Z`** = semver from the new **`vX.Y.Z`** tag (example: tag `v0.3.1` → **`X.Y.Z` = `0.3.1`**).

## 8. Quick sanity in the browser (optional but easy)

- [ ] Package: `https://hex.pm/packages/scrypath` shows **`X.Y.Z`**.
- [ ] Docs: `https://hexdocs.pm/scrypath/X.Y.Z` loads.

## 9. Tick planning checkboxes (only after step 6 is green)

Edit in this repo:

| File | What to change |
|------|----------------|
| **`.planning/ROADMAP.md`** | Line with **Phase 24** — change `- [ ]` to `- [x]` and add completion date if you want (match style of Phase 25/26). |
| **`.planning/REQUIREMENTS.md`** | **SHIP-01**, **SHIP-02**, **SHIP-03** bullets — change `- [ ]` to `- [x]`. |
| **`.planning/REQUIREMENTS.md`** | Traceability table (`SHIP-01` / `SHIP-02` / `SHIP-03` rows) — change **Pending** to **Complete** (or your house style). |

- [ ] All three edits saved and committed (example message: `docs: mark v1.4 SHIP complete after X.Y.Z publish`).

## 10. Close the milestone in GSD

In Cursor:

```text
/gsd-complete-milestone v1.4
```

- [ ] Command finished; milestone archived / `PROJECT.md` / roadmap updated per that workflow.

## 11. Push again if needed

```bash
git push origin main
```

- [ ] Remote has your bookkeeping commit(s).

---

## If something failed

Stop and read **`docs/releasing.md`** from **“Recovering Tag or Version Drift”** and **“Recovering a Failed Publish”** — do not hand-bump versions or invent a second publish path unless that doc tells you to.
