import { Controller } from "@hotwired/stimulus"

// The topics' list (topics/_nav), searched: the topics whose title has every
// word typed, and under their topic the settings whose label or description
// does. Without words, the topics only.
export default class extends Controller {
  static targets = ["input", "topic", "setting", "none"]

  filter() {
    const words = this.inputTarget.value.toLowerCase().split(/\s+/).filter(Boolean)
    const matches = (element) => {
      const keywords = element.dataset.keywords.toLowerCase()
      return words.every((word) => keywords.includes(word))
    }

    let found = 0
    this.topicTargets.forEach((topic) => {
      const settings = this.settingTargets.filter((setting) => topic.contains(setting))
      settings.forEach((setting) => (setting.hidden = words.length === 0 || !matches(setting)))
      const shown = words.length === 0 || matches(topic) || settings.some((setting) => !setting.hidden)
      topic.hidden = !shown
      if (shown) found++
    })
    this.noneTargets.forEach((none) => (none.hidden = found > 0))
  }
}
