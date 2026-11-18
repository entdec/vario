# frozen_string_literal: true

module Vario
  class Level
    include ActiveModel::Model
    attr_reader :conditions
    attr_accessor :id, :setting, :value

    def initialize(setting, level, new_record = false)
      level = level.to_h.with_indifferent_access
      @setting = setting
      @id = level[:id] || SecureRandom.hex
      @value = level[:value]
      @new_record = new_record
      self.conditions = level[:conditions]
    end

    def conditions=(new_conditions)
      new_conditions = (new_conditions || {}).with_indifferent_access
      @conditions = setting.keys.map do |key|
        Condition.new(setting, key, new_conditions[key])
      end
    end

    def conditions_for(context)
      conditions.select { |condition| context.key?(condition.key.to_sym) }
    end

    def conditions_not_for(context)
      conditions.reject { |condition| context.key?(condition.key.to_sym) }
    end

    def set_conditions
      conditions.reject { |condition| condition.value.blank? }
    end

    def conditions_hash
      set_conditions.map { |c| [c.key.to_sym, c.value] }.to_h
    end

    # The conditions' values as an object, for the form's fields_for
    def condition_values
      ConditionValues.new(conditions.to_h { |condition| [condition.key.to_s, condition.value] })
    end

    def with_context_values?(context)
      context.each do |key, value|
        condition = conditions.find { |condition| condition.key == key.to_s }
        return false if condition.value != value
      end

      true
    end

    def move(positions)
      if positions.positive?
        move_up(positions)
      else
        move_down(positions.abs)
      end
    end

    def move_up(positions = 1)
      positions.times { |time| setting.move_level_up(self) }
      setting.save!
    end

    def move_down(positions = 1)
      positions.times { |time| setting.move_level_down(self) }
      setting.save!
    end

    def human_value
      hv = setting.human_value(value)
      return unless hv
      setting.type == :array ? hv.join(', ') : hv.to_s
    end

    def to_h
      {
        id: id,
        conditions: conditions_hash,
        value: value
      }
    end

    def value_present?
      value === false || value.present?
    end

    def default?
      set_conditions.size.zero?
    end

    def persisted?
      !@new_record
    end

    # A reader per condition key, and the model API FormComponents' fields
    # ask their object for (validators, errors)
    class ConditionValues
      include ActiveModel::Model

      def initialize(values)
        @values = values
      end

      def respond_to_missing?(name, include_private = false)
        @values.key?(name.to_s) || super
      end

      def method_missing(name, *args)
        @values.key?(name.to_s) ? @values[name.to_s] : super
      end
    end
  end
end
