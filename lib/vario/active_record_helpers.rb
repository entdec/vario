# frozen_string_literal: true

module Vario
  module ActiveRecordHelpers
    extend ActiveSupport::Concern

    included do
      # provides settings_reader method to all models
      include Vario::SettingsReader
    end

    class_methods do
      def settable(options = {})
        include Vario::Settable

        configuration = { name: :settings }
        configuration.update(options) if options.is_a?(Hash)

        has_many configuration[:name], as: :settable, class_name: 'Vario::Setting'
      end
    end
  end
end
