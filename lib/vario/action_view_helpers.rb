# frozen_string_literal: true

module Vario
  module ActionViewHelpers
    # The settings topics the user may see, as items of the host's menu
    # (Menus::Builder's, with config.layout = :host): their settings'
    # labels and descriptions as the link's keywords, for its search.
    #
    #   m.group :settings do
    #     vario_menu_items(m)
    #   end
    def vario_menu_items(menu, settable = Vario.config.current_settable)
      return unless settable

      SettableTopic.visible(settable, SettableTopic.user_of(controller)).each do |topic|
        keywords = topic.topic.definitions.values.flat_map { |definition| [definition.label, definition.description] }.compact.join(' ')
        menu.item :"vario_#{topic.key}", label: topic.title, icon: topic.topic.icon, link: vario.topic_path(topic.key),
                                         link_attributes: { data: { keywords: keywords } }
      end
    end

    # Settings on a page of the host's, as 1.x's: those of a settable, with
    # a context, the values on exactly that (customer_id: 5, as the API's),
    # else its own values. A form per settable, back to the page when saved.
    #
    #   <%= render_vario_settings(Current.account, 'allocation.auto_allocate', 'shipping.partial_shipping', { customer_id: @customer.id }) %>
    #   <%= render_vario_settings([account, 'hide_couriers'], [account, 'print_node.api_key']) %>
    def render_vario_settings(*args)
      args = [args] unless args.first.is_a?(Array)

      safe_join(args.map do |settable, *names|
        context = names.last.is_a?(Hash) ? names.pop : {}
        context = context.to_h { |key, value| [key.to_s, value.to_s] }
        definitions = names.map do |name|
          definition = Topic.definition(settable, name)
          raise UnknownSetting, "Setting '#{name}' is not defined for #{settable.class.name}" unless definition

          unknown = context.keys - definition.legacy_keys
          raise ArgumentError, "Setting '#{name}' doesn't take #{unknown.join(', ')}" if unknown.any?

          definition
        end

        render 'vario/values/form', settable: settable, definitions: definitions, context: context
      end)
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

    # A refinement in a line, for when it's closed: "Product is Apple and
    # environment is test → 10"
    def vario_refinement_summary(refinement, definition, settable, variables)
      conditions = refinement.conditions.to_h.stringify_keys
      rules = Array(conditions['rules']).map do |rule|
        rule = rule.to_h.stringify_keys
        label, type = variables.describe(rule['variable'])
        value = case rule['operator']
                when 'is_empty', 'isnt_empty' then nil
                when 'between' then "#{rule['value']} – #{rule['value_to']}"
                else type == 'object' ? vario_record_label(variables.model(rule['variable']), rule['value']) : rule['value']
                end
        [label, t("entdec.conditions.operators.#{rule['operator']}"), value].compact.join(' ')
      end
      match = conditions['match'] == 'any' ? 'any' : 'all'
      text = rules.any? ? rules.join(" #{t("vario.pages.refinement.#{match}")} ") : t('vario.pages.refinement.always')
      value = definition.human(refinement.value, settable)
      "#{text} → #{value.presence || t('vario.pages.refinement.no_value')}"
    end

    def vario_record_label(model, id)
      record = model&.find_by(model.primary_key => id) if id.present?
      record ? Topic.label_of(record) : id
    end

    # The conditions editor for a refinement (EntDec::Conditions, records
    # from the setting's context)
    def vario_conditions(form, definition, settable, variables, variables_url:, records_url:)
      conditions = form.object.conditions.to_h.stringify_keys
      records = lambda do |path|
        model = variables.model(path)
        model ? Topic.records_of(model, settable).map { |record| [Topic.label_of(record), record.id] } : []
      end

      entdec_conditions(name: "#{form.object_name}[conditions]", match: conditions['match'], rules: Array(conditions['rules']),
                        variables_url: variables_url, describe: ->(path) { variables.describe(path) }, records_url: records_url, records: records)
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
