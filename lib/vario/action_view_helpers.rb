# frozen_string_literal: true

module Vario
  module ActionViewHelpers
    def render_vario_settings(settable, *setting_names, **context)
      Vario.config.pre_create_settings(settable)
      settings = settable.settings.where(name: setting_names)
      render partial: 'vario/settings/settings', locals: {
        settings: settings, context: context
      }
    end
  end
end
