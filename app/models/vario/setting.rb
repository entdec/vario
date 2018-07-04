module Vario
  class Setting < ApplicationRecord
    has_paper_trail if respond_to?(:has_paper_trail)

    belongs_to :settable, polymorphic: true, optional: true

    after_initialize :levels # pre-init the levels
    before_save :update_level_data

    def value_for(context)
      context.stringify_keys!

      validate_context(context)

      result = levels.find do |level|
        context >= level.conditions_hash
      end

      parse_value(result.value)
    end

    def levels
      @levels ||= attributes['levels'].map { |level| Level.new(self, level) }
    end

    def update_level_data
      self.levels = levels.map(&:to_h)
    end

    private

    def validate_context(context)
      missing = keys - context.keys
      raise ArgumentError, "missing context '#{missing.join(', ')}''" if missing.present?
    end

    def parse_value(value)
      return unless value.present?
      return value unless value.is_a?(String)
      return value.to_i if value.to_i.to_s == value.to_s
      return false if value == 'false'
      return true if value == 'true'
      return value.split(/,\s*/) if value.match?(/,/)
      value
    end
  end
end
