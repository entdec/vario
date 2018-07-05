module Vario
  class Level
    include ActiveModel::Model
    attr_accessor :id, :setting, :conditions, :value

    def initialize(setting, level)
      @setting = setting
      @id = level['id'] || SecureRandom.hex
      @conditions = setting.keys.map { |key| Condition.new(setting, key, level.dig('conditions', key)) }
      @value = level['value']
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

    def to_h
      {
        id: id,
        conditions: conditions_hash,
        value: value
      }
    end
  end
end
