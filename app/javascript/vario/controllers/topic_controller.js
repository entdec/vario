import { Controller } from "@hotwired/stimulus"

// A topic's form (topics/show): once something changed, its save bar says
// so and can cancel, and leaving the page asks first
export default class extends Controller {
  static targets = ["unsaved", "cancel"]

  connect() {
    this.beforeUnload = (event) => {
      if (this.dirty && !this.submitting) event.preventDefault()
    }
    window.addEventListener("beforeunload", this.beforeUnload)
    this.element.addEventListener("submit", () => (this.submitting = true))
  }

  disconnect() {
    window.removeEventListener("beforeunload", this.beforeUnload)
  }

  changed() {
    this.dirty = true
    this.unsavedTargets.forEach((target) => (target.hidden = false))
    this.cancelTargets.forEach((target) => (target.hidden = false))
  }
}
