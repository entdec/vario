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

    def set_conditions
      conditions.reject { |condition| condition.value.blank? }
    end

    def conditions_hash
      set_conditions.map { |c| [c.key.to_sym, c.value] }.to_h
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

    def default?
      set_conditions.size.zero?
    end

    def persisted?
      !@new_record
    end
  end
end
