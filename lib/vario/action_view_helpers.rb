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

    # The control for a setting's own value, or a refinement's, by the
    # setting's type (form's object is the Setting or the Refinement). Empty is
    # nothing (the default applies), so a boolean is a select, not a switch.
    def vario_value_field(form, definition, settable, label: definition.label, hint: true)
      value = form.object.value
      default = definition.human(definition.default_value, settable)
      options = { label: label, hide_label: true }
      options[:description] = t('vario.pages.setting.default', value: default) if hint && default.present?
      choices = definition.choices_for(settable).map { |choice| choice.is_a?(Array) ? [choice.first, choice.last.to_s] : [choice.to_s, choice.to_s] }

      case definition.type
      when :boolean
        form.select :value, [[t('vario.values.on'), 'true'], [t('vario.values.off'), 'false']], { include_blank: t('vario.pages.setting.use_default'), selected: value.nil? ? '' : value.to_s, **options }
      when :integer then form.text_field :value, type: 'number', step: 1, **options
      when :decimal then form.text_field :value, type: 'number', step: 'any', **options
      when :time then form.text_field :value, type: 'time', **options
      when :text then form.text_area :value, rows: 3, **options
      when :hash then form.text_area :value, value: (definition.human(value) if value), rows: 4, **options
      when :array
        if choices.any?
          form.collection_check_boxes :value, choices, :last, :first, { checked: Array(value).map(&:to_s), **options }
        else
          form.text_area :value, value: Array(value).join("\n"), rows: 3, **options
        end
      else
        choices = definition.records(settable).map { |record| [Topic.label_of(record), record.id.to_s] } if definition.model
        if choices.any? || definition.model
          form.select :value, choices, { include_blank: t('vario.pages.setting.use_default'), selected: value.to_s, **options }
        else
          form.text_field :value, **options
        end
      end
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
