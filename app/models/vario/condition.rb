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
        find_in_collection(value)&.first
      else
        value
      end
    end

    def key_data
      Vario.config.key_data_for(key)
    end

    def collection
      return @collection if @collection

      collection = key_data[:collection]
      collection ||= key_data[:collection_proc]
      collection ||= []
      if value.present? && collection.is_a?(Array)
        current_value = collection.find { |entry| entry.last == value }
        collection << ["<#{value}>", value] unless current_value
      end

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

  end
end
