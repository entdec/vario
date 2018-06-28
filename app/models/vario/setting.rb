module Vario
  class Setting < ApplicationRecord
    has_paper_trail if respond_to?(:has_paper_trail)

    belongs_to :settable, polymorphic: true

    validates :keys, presence: true
    validates :levels, presence: true

    def value_for(context)
      context.stringify_keys!

      missing = keys - context.keys
      raise ArgumentError, "missing context '#{missing.join(', ')}''" if missing.present?

      result = levels.find do |level|
        context >= level['conditions']
      end

      result&.dig('value')
    end
  end
end
