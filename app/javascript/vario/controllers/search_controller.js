import { Controller } from "@hotwired/stimulus"

// The topics' list (topics/_nav), searched: the topics whose title has every
// word typed, and under their topic the settings whose label or description
// does, each word matching the start of a word. Without words, all topics,
// with the current one's settings. What matches is highlighted.
export default class extends Controller {
  static targets = ["input", "topic", "setting", "label", "none"]

  connect() {
    this.labelTargets.forEach((label) => (label.dataset.text = label.textContent.trim()))
  }

  filter() {
    const words = this.inputTarget.value.toLowerCase().split(/\s+/).filter(Boolean)
    const patterns = words.map((word) => new RegExp(`(^|[^\\p{L}\\p{N}])${escape(word)}`, "iu"))
    const matches = (element) => patterns.every((pattern) => pattern.test(element.dataset.keywords))

    let found = 0
    this.topicTargets.forEach((topic) => {
      const settings = this.settingTargets.filter((setting) => topic.contains(setting))
      settings.forEach((setting) => {
        setting.hidden = words.length === 0 ? !("current" in topic.dataset) : !matches(setting)
      })
      const shown = words.length === 0 || matches(topic) || settings.some((setting) => !setting.hidden)
      topic.hidden = !shown
      if (shown) found++
    })
    this.noneTargets.forEach((none) => (none.hidden = found > 0))
    this.labelTargets.forEach((label) => highlight(label, words))
  }

  clear() {
    this.inputTarget.value = ""
    this.filter()
  }
}

function escape(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
}

// The label's text with the words, where they start a word, in a <mark>
function highlight(label, words) {
  const text = label.dataset.text
  label.replaceChildren()
  if (words.length === 0) {
    label.textContent = text
    return
  }

  const pattern = new RegExp(`(^|[^\\p{L}\\p{N}])(${words.map(escape).join("|")})`, "giu")
  let last = 0
  for (const match of text.matchAll(pattern)) {
    const start = match.index + match[1].length
    label.append(text.slice(last, start))
    const mark = document.createElement("mark")
    mark.textContent = match[2]
    label.append(mark)
    last = start + match[2].length
  }
  label.append(text.slice(last))
}
