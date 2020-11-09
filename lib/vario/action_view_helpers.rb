# frozen_string_literal: true

module Vario
  module ActionViewHelpers
    def render_vario_settings(*args)
      settings_with_contexts = []

      args = [args] unless args.first.is_a?(Array)
      args.each do |argument_set|
        settable = argument_set.first

        if argument_set.last.is_a?(Hash)
          setting_names = argument_set[1..-2]
          context       = argument_set.last
        else
          setting_names = argument_set[1..-1]
          context       = {}
        end

        Vario.config.pre_create_settings(settable)
        settable.settings.where(name: setting_names).each do |setting|
          settings_with_contexts << { setting: setting, context: context }
        end
      end

      render partial: 'vario/settings/settings', locals: {
        settings_with_contexts: settings_with_contexts
      }
    end
  end
end
