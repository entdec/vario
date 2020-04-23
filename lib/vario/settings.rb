# frozen_string_literal: true

module Vario
  # Make vario settings accessible as readers on the object
  module Settings
    extend ActiveSupport::Concern

    class_methods do
      def settings_reader(klass, settings)
        settings.each do |setting|
          vario_setting = Vario.config.settable_settings[klass.name.to_s][setting]

          method_name = setting.split('.').last
          method_name += '?' if vario_setting[:type] == :boolean

          define_method(method_name.to_sym) do
            result = nil
            result = self.settings&.dig(setting.split('.')) if respond_to?(:settings)

            context = vario_setting[:keys].map { |key| [key, send(key)] }
            result = send(klass.name.underscore.to_sym).setting(setting, context.to_h) if result.nil?
            result
          end
        end
      end
    end
  end
end

