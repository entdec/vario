# Pins for the vario gem. The host app imports it with: import "vario"

pin "vario", to: "vario/application.js"
pin_all_from Vario::Engine.root.join("app/javascript/vario"), under: "vario", to: "vario"
