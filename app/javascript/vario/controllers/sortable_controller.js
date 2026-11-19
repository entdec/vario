import { Controller } from "@hotwired/stimulus"

// A list whose items are dragged by their handle to another place, with the
// browser's own drag and drop. Dropped, the list fires vario--sortable:sorted,
// for the form that saves the order (vario--refinements numbers them).
//
//   div data-controller="vario--sortable"
//     div data-vario--sortable-target="item"
//       button data-vario--sortable-target="handle"
export default class extends Controller {
  static targets = ["item", "handle"]

  connect() {
    this.element.addEventListener("dragover", this.dragOver)
    this.element.addEventListener("drop", this.drop)
  }

  disconnect() {
    this.element.removeEventListener("dragover", this.dragOver)
    this.element.removeEventListener("drop", this.drop)
  }

  // Only the handle starts a drag, so the item's fields stay usable
  handleTargetConnected(handle) {
    const item = this.itemTargets.find((item) => item.contains(handle))
    if (!item) return

    handle.addEventListener("mousedown", () => (item.draggable = true))
    item.addEventListener("dragstart", (event) => {
      this.dragged = item
      this.dropped = false
      this.origin = [item.parentNode, item.nextSibling]
      event.dataTransfer.effectAllowed = "move"
    })
    // Dropped elsewhere: back where it was
    item.addEventListener("dragend", () => {
      if (!this.dropped) this.origin[0].insertBefore(item, this.origin[1])
      item.draggable = false
      this.dragged = null
    })
  }

  dragOver = (event) => {
    if (!this.dragged) return

    event.preventDefault()
    const over = this.itemTargets.find((item) => item !== this.dragged && item.contains(event.target))
    if (!over) return

    const { top, height } = over.getBoundingClientRect()
    over.parentNode.insertBefore(this.dragged, event.clientY < top + height / 2 ? over : over.nextSibling)
  }

  drop = (event) => {
    if (!this.dragged) return

    event.preventDefault()
    this.dropped = true
    this.dispatch("sorted", { detail: { item: this.dragged } })
  }
}
