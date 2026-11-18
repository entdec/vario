import { Controller } from "@hotwired/stimulus"

// The tabs of a card (shared/_card): one panel at a time
//
//   div data-controller="vario--tabs"
//     button data-vario--tabs-target="tab" data-action="vario--tabs#select"
//     div data-vario--tabs-target="panel"
export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    this.show(this.tabTargets.indexOf(event.currentTarget))
  }

  show(index) {
    this.tabTargets.forEach((tab, i) => tab.setAttribute("aria-selected", i === index))
    this.panelTargets.forEach((panel, i) => (panel.hidden = i !== index))
  }
}
