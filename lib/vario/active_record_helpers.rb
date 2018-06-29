# frozen_string_literal: true

module Vario::ActiveRecordHelpers
  extend ActiveSupport::Concern

  included do
    def setting(name, context = {})
      name = name.to_s
      context.symbolize_keys!
      default = context.delete(:default)

      settings.find_by(name: name)&.value_for(context) || default
    end

    def settings_hash(name, context = {})
      name = name.to_s
      context.symbolize_keys!
      raise ArgumentError, 'Cannot request hash with a default' if context.key?(:default)

      settings.where("name ILIKE ?", "#{name}.%").map do |vario_setting|
        [vario_setting.name.gsub("#{name}.", ''), vario_setting.value_for(context)]
      end.to_h.with_indifferent_access
    end
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
