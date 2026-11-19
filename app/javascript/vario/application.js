// Entry point. It registers vario's controllers with the host app's Stimulus
// application (window.Stimulus), which it starts if nothing has yet.

import { Application } from "@hotwired/stimulus"

import RefinementsController from "vario/controllers/refinements_controller"
import SearchController from "vario/controllers/search_controller"
import SortableController from "vario/controllers/sortable_controller"
import TabsController from "vario/controllers/tabs_controller"
import TopicController from "vario/controllers/topic_controller"

window.Stimulus ||= Application.start()

window.Stimulus.register("vario--refinements", RefinementsController)
window.Stimulus.register("vario--search", SearchController)
window.Stimulus.register("vario--sortable", SortableController)
window.Stimulus.register("vario--tabs", TabsController)
window.Stimulus.register("vario--topic", TopicController)
