import { Controller } from "@hotwired/stimulus"

// A topic's form (topics/show): once something changed, its save bar says
// so and can cancel, and leaving the page asks first, also by a Turbo visit
// (which doesn't unload it). Cancel leaves without asking.
export default class extends Controller {
  static targets = ["unsaved", "cancel"]
  static values = { confirm: String }

  connect() {
    this.beforeUnload = (event) => {
      if (this.leaving()) event.preventDefault()
    }
    this.beforeVisit = (event) => {
      if (this.leaving() && !window.confirm(this.confirmValue)) event.preventDefault()
    }
    window.addEventListener("beforeunload", this.beforeUnload)
    document.addEventListener("turbo:before-visit", this.beforeVisit)
    this.element.addEventListener("submit", () => (this.submitting = true))
  }

  disconnect() {
    window.removeEventListener("beforeunload", this.beforeUnload)
    document.removeEventListener("turbo:before-visit", this.beforeVisit)
  }

  changed() {
    this.dirty = true
    this.unsavedTargets.forEach((target) => (target.hidden = false))
    this.cancelTargets.forEach((target) => (target.hidden = false))
  }

  discard() {
    this.dirty = false
  }

  leaving() {
    return this.dirty && !this.submitting
  }
}
