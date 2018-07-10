module Vario
  class Setting < ApplicationRecord
    attr_reader :settable_setting, :type, :default, :description

    has_paper_trail if respond_to?(:has_paper_trail)

    belongs_to :settable, polymorphic: true, optional: true
    validates :name, uniqueness: { scope: %i[settable_type settable_id] }

    after_initialize :configure, :levels # pre-init the levels
    before_save :update_level_data

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

      parse_value(result&.value || current_default || default)
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

    def update_level_data
      self.levels = levels.select { |l| l.value.present? }.map(&:to_h)
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
      return unless value.present?
      return value unless value.is_a?(String)

      return value.to_i if type == :integer
      return false if value == '0' && type == :boolean
      return true if value == '1' && type == :boolean
      return value.split(/,|\n/).map(&:strip) if type == :array
      value
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
  end
end
