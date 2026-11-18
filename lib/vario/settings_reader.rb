# frozen_string_literal: true

module Vario
  # Make vario settings accessible as readers on the object
  #
  #   class Order < ApplicationRecord
  #     settings_reader Account, %w[shipping.cutoff_time shipping.partial_shipping]
  #   end
  #
  #   order.cutoff_time        # account.setting('shipping.cutoff_time', order: order, location: order.location, ...)
  #   order.partial_shipping?
  #
  # The context is the object for the setting's context roots it answers
  # to: itself for a root that is its model (order), else what it has for
  # the root (location, order_type) or its id (location_id). A value in the
  # object's own settings hash (Order's settings jsonb) comes first.
  module SettingsReader
    extend ActiveSupport::Concern

    class_methods do
      def settings_reader(klass, settings)
        Vario::Topic.when_loaded do
          settings.each do |setting|
            definition = Vario::Topic.definition(klass, setting)
            raise UnknownSetting, "Setting '#{setting}' is not defined for #{klass.name}" unless definition

            method_name = setting.split('.').last
            method_name += '?' if definition.type == :boolean

            define_method(method_name.to_sym) do
              result = nil

              if respond_to?(:settings) && self.settings.respond_to?(:dig)
                result = self.settings.dig(*setting.split('.'))
              end

              if result.nil?
                context = vario_reader_context(definition)
                result = self.setting(setting, context) if respond_to?(:settings) && self.class.name == klass.name
                result = send(klass.name.underscore.to_sym)&.setting(setting, context) if result.nil? && self.respond_to?(klass.name.underscore.to_sym)
              end

              result
            end
          end
        end
      end
    end

    private

    def vario_reader_context(definition)
      definition.context.each_key.with_object({}) do |root, context|
        model = root.camelize.safe_constantize
        if model.is_a?(Class) && is_a?(model)
          context[root] = self
        elsif respond_to?(root)
          context[root] = send(root)
        elsif respond_to?("#{root}_id")
          context["#{root}_id"] = send("#{root}_id")
        end
      end
    end
  end
end
