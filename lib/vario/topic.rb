# frozen_string_literal: true

module Vario
  # The settings of one settings page, for one kind of settable, with what
  # their refinements may look at. One class per topic, in app/settings/ of
  # the app or an engine, with its texts in the locale files:
  #
  #   class ShippingSettings < Vario::Topic
  #     settable Account
  #     icon 'fal fa-truck'
  #     context order: OrderDrop, location: LocationDrop, order_type: :string
  #
  #     setting :cutoff_time, :time, default: '13:00'
  #     setting :default_shipping_method, ShippingMethod, context: %i[location]
  #   end
  #
  #   nl:
  #     vario:
  #       topics:
  #         shipping:
  #           title: Verzending
  #           description: Hoe en wanneer orders de deur uit gaan.
  #           settings:
  #             cutoff_time:
  #               label: Uiterste allocatietijd
  #               description: ...
  #
  # The topic's key is its class name without Settings (shipping), a
  # setting's name its key after the topic's (shipping.cutoff_time).
  class Topic
    TYPES = %i[boolean integer decimal string text time array hash].freeze

    # A setting as a topic defines it
    class Definition
      attr_reader :topic, :key, :name, :type, :default, :choices

      def initialize(topic, key, type, default: nil, choices: nil, context: nil, name: nil)
        unless TYPES.include?(type) || type.is_a?(Class)
          raise ArgumentError, "Unknown type #{type.inspect} for setting #{key} of #{topic.name}, one of #{TYPES.join(', ')} or a model"
        end

        @topic = topic
        @key = key.to_s
        @name = name&.to_s || "#{topic.key}.#{@key}"
        @type = type
        @default = default
        @choices = choices
        @context = context&.map(&:to_s)
      end

      # A model whose records are the setting's values (stored by id)
      def model
        type if type.is_a?(Class)
      end

      # A value as the setting's type, from a form, the database or 1.x; nil
      # for nothing (the default applies)
      def cast(value)
        value_type.cast(value) unless Types.blank?(value)
      end

      # As stored, in jsonb: decimals as text, so they stay exact
      def serialize(value)
        value = cast(value)
        value.is_a?(BigDecimal) ? value.to_s : value
      end

      # A stored value as the setting's. 1.x's "all" of an array with
      # choices is all of them, as they are now; the block gives the
      # settable, for choices that depend on it.
      def read(value, &settable)
        value = cast(value)
        return choice_values(settable&.call) if type == :array && choices && value&.any? { |element| element.to_s == 'all' }

        value
      end

      def default_value
        cast(default)
      end

      # The choices, a list of values or of [label, value]; a lambda gets the
      # settable when it takes an argument
      def choices_for(settable = nil)
        list = choices.respond_to?(:call) ? (choices.arity.zero? ? choices.call : choices.call(settable)) : choices
        Array(list)
      end

      def choice_values(settable = nil)
        choices_for(settable).map { |choice| choice.is_a?(Array) ? choice.last : choice }
      end

      def value_type
        @value_type ||= case type
                        when :boolean then ActiveModel::Type::Boolean.new
                        when :integer then ActiveModel::Type::Integer.new
                        when :decimal then ActiveModel::Type::Decimal.new
                        when :string, :text then ActiveModel::Type::String.new
                        when :time then Types::TimeOfDay.new
                        when :array then Types::List.new
                        when :hash then Types::Map.new
                        else Types::Reference.new(type)
                        end
      end

      # What its refinements may look at: the topic's context, or the part
      # of it the setting names
      def context
        @context ? topic.context.slice(*@context) : topic.context
      end

      # 1.x's keys it takes: for its context roots the root (order_type) or,
      # for a drop or a model, its id (location_id), and the legacy keys of
      # variables in those roots (customer_id)
      def legacy_keys
        keys = context.map { |root, type| type.is_a?(Symbol) ? root : "#{root}_id" }
        keys + Vario.config.legacy_keys.select { |_key, variable| context.key?(variable.split('.').first) }.keys
      end

      # The variable a 1.x key is now: a legacy key's (config.legacy_key),
      # location for location_id when location is a root, else the key
      def variable_for(key)
        key = key.to_s
        root = key.delete_suffix('_id')
        Vario.config.legacy_keys[key] || (key.end_with?('_id') && context.key?(root) ? root : key)
      end

      def label
        I18n.t(:label, scope: i18n_scope, default: key.humanize)
      end

      def description
        I18n.t(:description, scope: i18n_scope, default: nil)
      end

      private

      def i18n_scope
        [:vario, :topics, topic.key, :settings, key]
      end
    end

    class << self
      # Every topic subclass, as they are loaded (see Vario::Engine)
      def registered
        Vario::Topic.instance_variable_get(:@registered) || Vario::Topic.instance_variable_set(:@registered, [])
      end

      def inherited(subclass)
        super
        registered << subclass
      end

      # Drops the topics a reload replaced, and loads those in app/settings/
      # of the app and its engines, which register themselves as they load
      def load!
        @loading = true
        registered.select! { |topic| topic.name && topic.name.safe_constantize.equal?(topic) }
        ([Rails.application] + Rails::Engine.subclasses.map(&:instance)).uniq.each do |engine|
          directory = engine.root.join('app/settings')
          Rails.autoloaders.main.eager_load_dir(directory) if directory.directory?
        end
        @loading = false
        @loaded = true
        @when_loaded.shift.call while @when_loaded&.any?
      ensure
        @loading = false
      end

      # Runs the block once the topics are loaded: now, or when they are (a
      # model may load before them, or while they load: a topic may name it)
      def when_loaded(&block)
        return yield if @loaded && !@loading

        (@when_loaded ||= []) << block
      end

      # The topics of a settable, a record or its class (or all of them),
      # by title
      def for(settable = nil)
        topics_of(settable).sort_by(&:title)
      end

      # A settable's topic by its key
      def find(settable, key)
        topics_of(settable).find { |topic| topic.key == key.to_s }
      end

      # A settable's setting by its name (shipping.cutoff_time)
      def definition(settable, name)
        topics_of(settable).each do |topic|
          definition = topic.definitions[name.to_s]
          return definition if definition
        end
        nil
      end

      # DSL

      def settable(klass = nil)
        @settable = klass.to_s if klass
        @settable
      end

      def icon(icon = nil)
        @icon = icon if icon
        @icon
      end

      # The roots refinements may look at: drops (order: OrderDrop) or plain
      # values (order_type: :string)
      def context(roots = nil)
        @context = roots.to_h { |name, root| [name.to_s, root] } if roots
        @context || {}
      end

      def key(key = nil)
        @key = key.to_s if key
        @key || name.to_s.demodulize.delete_suffix('Settings').underscore
      end

      # type: one of TYPES, or a model; name: for a setting whose name isn't
      # the topic's key and its own (from 1.x, hide_couriers)
      def setting(key, type, **options)
        definition = Definition.new(self, key, type, **options)
        definitions[definition.name] = definition
      end

      # Its settings by name, in the order they are defined
      def definitions
        @definitions ||= {}
      end

      def settable_class
        settable&.safe_constantize
      end

      def title
        I18n.t(:title, scope: [:vario, :topics, key], default: key.humanize)
      end

      def description
        I18n.t(:description, scope: [:vario, :topics, key], default: nil)
      end

      private

      def topics_of(settable)
        topics = registered.select(&:settable_class)
        return topics unless settable

        klass = settable.is_a?(Class) ? settable : settable.class
        topics.select { |topic| klass <= topic.settable_class }
      end
    end
  end
end
