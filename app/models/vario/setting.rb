module Vario
  class Setting < ApplicationRecord
    has_paper_trail if respond_to?(:has_paper_trail)

    validates :data, presence: true

    def value_for(context)
      context.stringify_keys!

      result = rows.find do |row|
        context >= row['conditions'].symbolize_keys
      end

      result&.dig(:value)
    end
  end
end
