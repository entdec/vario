# frozen_string_literal: true

module Vario
  # The ActiveModel types of the setting types Rails has none for (see
  # Topic::Definition#value_type). Each casts what a form sends, what is
  # stored, and what 1.x stored (strings), to the setting's value.
  module Types
    # Nothing, a value whose setting uses its default
    def self.blank?(value)
      value.nil? || (value.respond_to?(:empty?) && (value.is_a?(String) ? value.strip.empty? : value.empty?))
    end

    # A time of day as "13:00", as 1.x stored it and Boxture reads it
    class TimeOfDay < ActiveModel::Type::Value
      def type = :time_of_day

      def cast(value)
        case value
        when Time, DateTime, ActiveSupport::TimeWithZone then value.strftime('%H:%M')
        when String
          hours, minutes = value.strip.match(/\A(\d{1,2})[:.](\d{2})(?::\d{2})?\z/)&.captures&.map(&:to_i)
          format('%02d:%02d', hours, minutes) if hours && hours < 24 && minutes < 60
        end
      end
    end

    # An array; from 1.x also a text of values separated by commas or lines
    class List < ActiveModel::Type::Value
      def type = :list

      def cast(value)
        values = value.is_a?(String) ? value.split(/,|\n/).map(&:strip) : Array(value)
        values.reject { |element| Types.blank?(element) }
      end
    end

    # A hash; from 1.x also YAML (or JSON)
    class Map < ActiveModel::Type::Value
      def type = :map

      def cast(value)
        value = YAML.safe_load(value) if value.is_a?(String)
        value.to_h.deep_stringify_keys if value.respond_to?(:to_h) && !value.is_a?(Array)
      rescue Psych::Exception
        nil
      end
    end

    # A record of a model, by its id: a record is its id
    class Reference < ActiveModel::Type::Value
      def initialize(model)
        super()
        @model = model
      end

      def type = :reference

      def cast(value)
        value = value.id if value.is_a?(@model)
        @model.type_for_attribute(@model.primary_key).cast(value)
      end
    end
  end
end
