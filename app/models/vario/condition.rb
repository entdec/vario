module Vario
  class Condition
    include ActiveModel::Model
    attr_accessor :key, :value

    def initialize(setting, key, value)
      @setting = setting
      @key = key
      @value = value
    end
  end
end
