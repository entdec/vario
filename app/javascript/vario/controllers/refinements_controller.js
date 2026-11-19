import { Controller } from "@hotwired/stimulus"

// A setting's refinements (topics/_refinements): each opens from its line,
// and their priorities follow their order, after a drag, an add or a remove.
// The form then has unsaved changes (vario--topic).
export default class extends Controller {
  static targets = ["item", "position", "priority", "count"]

  connect() {
    this.renumber({ changed: false })
  }

  toggle(event) {
    const button = event.currentTarget
    const detail = button.closest("[data-vario--refinements-target='item']").querySelector(".vario-refinement__detail")
    detail.hidden = !detail.hidden
    button.setAttribute("aria-expanded", !detail.hidden)
  }

  renumber({ changed = true } = {}) {
    const items = this.itemTargets.filter((item) => item.style.display !== "none" && !item.closest("template"))
    items.forEach((item, index) => {
      item.querySelector("[data-vario--refinements-target='position']").value = index + 1
      item.querySelector("[data-vario--refinements-target='priority']").textContent = index + 1
    })
    this.countTargets.forEach((count) => (count.textContent = items.length))
    if (changed === true) this.element.dispatchEvent(new Event("change", { bubbles: true }))
  }
}
