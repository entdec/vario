import { Controller } from "@hotwired/stimulus"

// The topics' list (topics/_nav): only those whose keywords (title, the
// settings' labels and descriptions) have every word typed
export default class extends Controller {
  static targets = ["input", "item"]

  filter() {
    const words = this.inputTarget.value.toLowerCase().split(/\s+/).filter(Boolean)
    this.itemTargets.forEach((item) => {
      const keywords = item.dataset.keywords.toLowerCase()
      item.hidden = !words.every((word) => keywords.includes(word))
    })
  }
}
