# frozen_string_literal: true

module Vario::ActiveRecordHelpers
  extend ActiveSupport::Concern

  included do
    delegate :setting, to: :Vario
  end

  class_methods do
    def settable(options = {})
      configuration = {
        name:         :settings
      }

      configuration.update(options) if options.is_a?(Hash)

      has_many configuration[:name], as: :settable, class_name: 'Vario::Setting'
    end
  end
end
