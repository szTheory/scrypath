export {OpsFieldValidation} from "./ops_validation"
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
      const save = document.getElementById("search-save-toggle")
      if (save) {
        save.disabled = changed
        save.title = changed ? "Run search to save the updated inputs" : "Save the inputs for these results"
      }
      const panel = document.getElementById("search-capture-form-panel")
      if (changed && panel) panel.style.display = "none"
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

export const OpsHelpAnchor = {
  mounted() {
    this.reveal = () => {
      const id = decodeURIComponent(location.hash.slice(1))
      const target = id && document.getElementById(id)
      if (target && this.el.contains(target)) target.scrollIntoView({block: "start"})
    }
    window.addEventListener("hashchange", this.reveal)
    // LiveView can replace the disconnected render after the browser's initial fragment scroll.
    requestAnimationFrame(this.reveal)
  },
  destroyed() { window.removeEventListener("hashchange", this.reveal) }
}
