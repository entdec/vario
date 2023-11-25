# frozen_string_literal: true

module Vario
  class Setting < ApplicationRecord
    attr_reader :settable_setting, :type, :default, :description

    has_paper_trail if respond_to?(:has_paper_trail)

    belongs_to :settable, polymorphic: true, optional: true
    validates :name, uniqueness: { scope: %i[settable_type settable_id] }
    validate :validate_levels

    after_initialize :configure, :levels # pre-init the levels
    before_save :update_level_data

    scope :for_group, ->(group_name) { where('name ilike ?', "#{group_name}.%") }
    scope :without_group, -> { where.not('name ilike ?', "%.%") }

    def group_name
      return nil if name.blank?

      parts = name.split('.', 2)

      return nil if parts.size == 1

      parts.first
    end

    def setting_name
      return name if name.blank?

      name.split('.', 2).last || name
    end

    def title
      return "#{group_name.humanize}: #{setting_name.humanize}" if group_name.present?

      setting_name.humanize if setting_name.present?
    end

    def value_for(context)
      current_default = context.delete(:default)

      unless initialized?
        raise UnknownSetting, "Configuration key '#{name}' not initialized for #{settable_type}" if Vario.config.raise_on_undefined?(settable_type)
        return current_default unless Vario.config.create_on_request?(settable_type)

        # This is a new record, save it to the table since create_on_request? is true
        self.keys = Vario.config.default_keys?(settable_type)
        self.levels << Vario::Level.new(self, conditions: {}, value: current_default)
      end

      context = context.symbolize_keys
      update_context(context)
      validate_context(context)

      result = levels.find do |level|
        context >= level.conditions_hash
      end

      return parse_value(result.value) if result.present? && result.value_present?

      parse_value(current_default || default)
    end

    def configure
      self.keys ||= []

      @settable_setting = Vario.config.settable_setting(settable_type, name)
      return unless settable_setting

      @type = settable_setting[:type]
      self.keys = settable_setting[:keys]
      @default = settable_setting[:default]
      @description = settable_setting[:description]
    end

    def levels
      @levels ||= (attributes['levels'] || []).map { |level| Level.new(self, level) }
    end

    def uniq_levels
      selected = []

      levels.each do |level|
        next if selected.select { |uniq_level| uniq_level.conditions_hash == level.conditions_hash}.present?

        selected << level
      end

      selected
    end

    def uniq_levels!
      self.levels = uniq_levels.select { |l| l.value_present? }.map(&:to_h)
      @levels = nil
      save!
    end

    def update_level_data
      self.levels = levels.select { |l| l.value_present? }.map(&:to_h)
    end

    def move_level_up(level)
      index = levels.index(level)
      level = levels.delete(level)
      levels.insert(index - 1, level)
    end

    def move_level_down(level)
      index = levels.index(level)
      level = levels.delete(level)
      levels.insert(index + 1, level)
    end

    def initialized?
      return false if Vario.config.raise_on_undefined?(settable) && !persisted?
      settable_setting.present? || persisted?
    end

    def parse_value(value)
      return false if [0, '0', 'false', '', false].include?(value) && type == :boolean
      return true if [1, '1', 'true', true].include?(value) && type == :boolean
      return unless value.present?
      return parse_value_array(value) if type == :array
      return value unless value.is_a?(String)
      return YAML.load(value) if type == :hash
      return value.to_i if type == :integer

      value
    end

    def human_value(value)
      parsed_value = parse_value(value)
      return parsed_value if collection.blank?
      return parsed_value.map { |pv| find_in_collection(pv)&.first } if type == :array

      find_in_collection(parsed_value)&.first
    end

    def parse_value_array(value)
      values = value
      values = values.split(/,|\n/).map(&:strip) if values.is_a?(String)
      values = values.reject(&:blank?)

      # If a collection has been defined, and 'all' is in the selected values, return all id's from the colletion
      return collection.map(&:last) if (values.include?('all') || values.include?(:all)) && collection

      values
    end

    def collection
      return @collection if @collection
      return unless settable_setting

      collection = settable_setting[:collection]
      collection ||= settable_setting[:collection_proc] if settable_setting[:collection_proc]
      collection ||= []

      @collection = collection if collection.is_a?(Array)
      collection
    end

    def find_in_collection(value)
      if collection.is_a?(Array)
        collection.find { |entry| entry.last == value }
      elsif collection.is_a?(Proc)
        if collection.parameters.size == 1
          instance_exec(value, &collection)
        else
          instance_exec(&collection)
        end
      end
    end


    def new_level
      Level.new(self, {}, true)
    end

    private

    ###
    # Fill blank values for which we've got a value_proc
    #
    def update_context(context)
      keys.each do |key|
        key = key.to_sym
        key_data = Vario.config.key_data_for(key)
        context[key] ||= instance_exec(&key_data[:value_proc]) if key_data.key?(:value_proc)
      end
    end

    def validate_context(context)
      missing = keys.map(&:to_sym) - context.keys
      raise ArgumentError, "missing context '#{missing.join(', ')}''" if missing.present?
    end

    def validate_levels
      errors.add(:levels, I18n.t('errors.messages.taken')) if levels.map(&:conditions_hash).uniq.size != levels.size
    end
  end
end
