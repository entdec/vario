# frozen_string_literal: true

class GeneralSettings < Vario::Topic
  settable Account
  icon 'fal fa-sliders'

  # From 1.x, without a topic in its name
  setting :hide_couriers, :boolean, default: true, name: 'hide_couriers'
end
