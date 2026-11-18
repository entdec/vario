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

    # A card with a title and icon, and the actions and tabs its block adds
    # (Vario::Card), else what the block gives
    #
    #   <%= vario_card :vario_settings, title: 'Settings', icon: 'fad fa-sliders' do |card| %>
    #     <% card.tab :shipping do %>
    #       ...
    #     <% end %>
    #   <% end %>
    def vario_card(name, title:, icon: nil, &block)
      card = Vario::Card.new(self)
      body = capture(card, &block)
      render 'vario/shared/card', name: name.to_s.parameterize(separator: '_'), title: title, icon: icon, card: card, body: body
    end
  end
end
