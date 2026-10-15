// Compare actual native form values with the submitted run, including unsent edits.
export const OpsSearchDraft = {
  mounted() {
    this.syncDraft = () => {
      const context = document.getElementById("search-run-attribution")
      if (!context) return
      const data = new FormData(this.el)
      const mode = this.el.dataset.searchMode
      const schemas = mode === "multi" ? data.getAll("schemas[]").map(String).sort() : [String(data.get("schema") || "")]
      const submitted = JSON.parse(context.dataset.schemas)
      const changed = mode !== context.dataset.mode || String(data.get("q") || "").trim() !== context.dataset.query || Number(data.get("page_size")) !== Number(context.dataset.limit) || JSON.stringify(schemas) !== JSON.stringify(submitted.sort())
      context.hidden = !changed
    }
    this.el.addEventListener("input", this.syncDraft)
    this.el.addEventListener("change", this.syncDraft)
    this.syncDraft()
  },
  updated() { this.syncDraft() },
  destroyed() {
    this.el.removeEventListener("input", this.syncDraft)
    this.el.removeEventListener("change", this.syncDraft)
  }
}
