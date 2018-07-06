module Vario
  class Level
    include ActiveModel::Model
    attr_reader :conditions
    attr_accessor :id, :setting, :value

    def initialize(setting, level, new_record = false)
      @setting = setting
      @id = level['id'] || SecureRandom.hex
      @conditions = setting.keys.map { |key| Condition.new(setting, key, level.dig('conditions', key.to_s)) }
      @value = level['value']
      @new_record = new_record
    end

    def conditions=(new_conditions)
      @conditions = setting.keys.map { |key| Condition.new(setting, key, new_conditions[key]) }
    end

    def conditions_hash
      conditions.map { |c| [c.key, c.value] }.to_h
    end

    def set_conditions
      conditions.reject { |condition| condition.value.blank? }
    end

    def move_up
      setting.move_level_up(self)
      setting.save!
    end

    def move_down
      setting.move_level_down(self)
      setting.save!
    end

    def human_value
      hv = setting.parse_value(value)
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

    def default?
      set_conditions.size.zero?
    end

    def persisted?
      !@new_record
    end
  end
end
