# frozen_string_literal: true

require 'rails/generators'

module Vario
  module Generators
    # Topics (app/settings/) and their texts (config/locales/) from the 1.x
    # settings in the app's config (config/initializers/vario.rb), to trim:
    #
    #   bin/rails g vario:topics_from_config [--locale=en]
    #
    # A topic per group, its context the keys its settings use (location_id
    # is location, a drop or the model; other keys plain values); choices
    # from a collection, or from a collection_proc that only builds a list
    # (those that look at the setting or Current are left as a TODO).
    class TopicsFromConfigGenerator < Rails::Generators::Base
      class_option :locale, type: :string, default: 'en', desc: 'The locale of the 1.x descriptions'

      def create_topics
        topics.each do |topic|
          create_file "app/settings/#{topic[:class_name].underscore}.rb", topic_source(topic)
        end
      end

      def create_locale
        texts = topics.each_with_object({}) do |topic, hash|
          hash[topic[:key]] ||= { 'title' => topic[:key].humanize, 'settings' => {} }
          topic[:settings].each do |setting|
            hash[topic[:key]]['settings'][setting[:key]] = { 'label' => setting[:key].humanize, 'description' => setting[:description] }.compact
          end
        end

        create_file "config/locales/vario.#{options[:locale]}.yml", { options[:locale] => { 'vario' => { 'topics' => texts } } }.to_yaml(line_width: -1)
      end

      def show_notes
        notes = []
        value_proc_keys = topics.flat_map { |topic| topic[:keys] }.uniq.select { |key| Vario.config.key_data_for(key)[:value_proc] }
        value_proc_keys.each do |key|
          notes << "#{key} had a value_proc: add config.context_default :#{key.to_s.delete_suffix('_id')}, -> { ... }"
        end
        Vario.config.instance_variable_get(:@show_group_if).each_key do |group|
          notes << "#{group} had show_group_if: add a #{group.camelize}SettingsPolicy < Vario::TopicPolicy (show?)"
        end
        notes << 'TODOs left in the topics: choices that need the settable (choices: ->(settable) { ... }) or are records (setting :x, ShippingMethod)' if topics.any? { |topic| topic[:settings].any? { |setting| setting[:todo] } }

        notes.each { |note| say_status :note, note, :yellow }
      end

      private

      def topics
        @topics ||= begin
          class_names = []
          Vario.config.settable_settings.flat_map do |settable_type, settings|
            settings.group_by { |name, _options| name.include?('.') ? name.split('.', 2).first : 'general' }.map do |group, group_settings|
              class_name = "#{group.camelize}Settings"
              class_name = "#{settable_type}#{class_name}" if class_names.include?(class_name)
              class_names << class_name

              build_topic(settable_type, group, class_name, group_settings)
            end
          end
        end
      end

      def build_topic(settable_type, group, class_name, group_settings)
        settings = group_settings.map { |name, options| build_setting(group, name, options) }
        keys = settings.flat_map { |setting| setting[:keys] }.uniq

        settings.each do |setting|
          setting[:context] = setting[:keys].map { |key| root_for(key) } unless setting[:keys] == keys
        end

        { settable_type: settable_type, key: group, class_name: class_name, custom_key: class_name != "#{group.camelize}Settings",
          keys: keys, context: keys.to_h { |key| [root_for(key), root_type_for(key)] }, settings: settings }
      end

      def build_setting(group, name, options)
        key = name.include?('.') ? name.split('.', 2).last : name
        type = type_for(options)
        choices, todo = choices_for(options, type)

        { key: key, name: (name unless name.include?('.')), type: type, default: default_for(options, type),
          choices: choices, todo: todo, keys: Array(options[:keys]).map(&:to_sym), description: description_for(options) }
      end

      # Not the one 1.x makes up without one
      def description_for(options)
        options[:description] unless options[:description].to_s.start_with?('Configuration for ')
      end

      def type_for(options)
        case options[:type]
        when :symbol, :select then :string
        when :string then options[:default].to_s.match?(/\A\d{1,2}:\d{2}\z/) ? :time : :string
        else options[:type]
        end
      end

      def default_for(options, type)
        default = options[:default]
        return if default.nil? || (default.respond_to?(:empty?) && default.empty?)

        default = default.map(&:to_s) if type == :array
        default.is_a?(Symbol) ? default.to_s : default
      end

      # [source, todo]
      def choices_for(options, type)
        if options[:collection]
          [options[:collection].map { |label, value| [label.to_s, value.to_s] }.inspect, nil]
        elsif options[:collection_proc]
          source = proc_source(options[:collection_proc])
          return [nil, "choices, from 1.x's collection_proc: #{proc_location(options[:collection_proc])}"] unless source
          return [nil, "choices, from 1.x's collection_proc: #{source}"] if source.match?(/@setting|account_for|Current\./)

          # Records by id: a record picker
          model = source[/\A->\s*\{\s*([A-Z]\w*(?:::[A-Z]\w*)*)\./, 1]
          return [source, "#{model} records? setting :x, #{model}"] if model && source.match?(/\.id\]/)

          [source, nil]
        end
      end

      # The lambda's source, when it's on its line as "collection_proc: -> { ... }"
      def proc_source(block)
        file, line = block.source_location
        return unless file && File.exist?(file)

        text = File.readlines(file)[line - 1].to_s
        start = text.index('collection_proc:')
        return unless start

        text = text[(start + 'collection_proc:'.length)..].lstrip
        return unless text.start_with?('->')

        depth = 0
        text.each_char.with_index do |char, index|
          depth += 1 if char == '{'
          depth -= 1 if char == '}'
          return text[0..index] if char == '}' && depth.zero?
        end
        nil
      end

      def proc_location(block)
        block.source_location&.join(':')
      end

      # location for location_id, when there is a drop or a model for it;
      # else the key
      def root_for(key)
        model_root_type(key) ? key.to_s.delete_suffix('_id') : key.to_s
      end

      def root_type_for(key)
        model_root_type(key) || (Vario.config.key_data_for(key)[:type] == :boolean ? ':boolean' : ':string')
      end

      def model_root_type(key)
        return unless key.to_s.end_with?('_id')

        name = key.to_s.delete_suffix('_id').camelize
        return "#{name}Drop" if "#{name}Drop".safe_constantize
        name if name.safe_constantize.is_a?(Class)
      end

      def topic_source(topic)
        lines = ['# frozen_string_literal: true', '', "class #{topic[:class_name]} < Vario::Topic", "  settable #{topic[:settable_type]}"]
        lines << "  key '#{topic[:key]}'" if topic[:custom_key]
        lines << "  context #{topic[:context].map { |root, type| "#{root}: #{type}" }.join(', ')}" if topic[:context].any?
        lines << ''

        topic[:settings].each do |setting|
          lines << "  # TODO: #{setting[:todo]}" if setting[:todo]
          arguments = [":#{setting[:key]}", ":#{setting[:type]}"]
          arguments << "default: #{setting[:default].inspect}" unless setting[:default].nil?
          arguments << "choices: #{setting[:choices]}" if setting[:choices]
          arguments << "context: %i[#{setting[:context].join(' ')}]" if setting[:context]
          arguments << "name: '#{setting[:name]}'" if setting[:name]
          lines << "  setting #{arguments.join(', ')}"
        end

        (lines << 'end').join("\n") + "\n"
      end
    end
  end
end
