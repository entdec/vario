# frozen_string_literal: true

module Vario
  class Condition
    include ActiveModel::Model
    attr_accessor :key, :value

    def initialize(setting, key, value)
      @setting = setting
      @key = key
      @value = value
    end

    def human_value
      if key_data[:type] == :select
        collection.find { |entry| entry.last == value }.first
      else
        value
      end
    end

    def key_data
      Vario.config.key_data_for(key)
    end

    def collection
      return @collection if @collection

      @collection = key_data[:collection]
      @collection ||= instance_exec(&key_data[:collection_proc]) if key_data[:collection_proc]
      @collection ||= []
      if value.present?
        current_value = @collection.find { |entry| entry.last == value }
        @collection << ["<#{value}>", value] unless current_value
      end
      @collection
    end
  end
end
