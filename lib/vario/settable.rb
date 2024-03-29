# frozen_string_literal: true

module Vario
  module Settable
    extend ActiveSupport::Concern

    included do
      def setting(name, context = {})
        name = name.to_s
        context.symbolize_keys!
        @vario_setting_cache ||= {}
        @vario_setting_cache[name] ||= settings.find_or_initialize_by(name: name)
        @vario_setting_cache[name]&.value_for(context)
      end

      def settings_hash(name, context = {})
        name = name.to_s
        context.symbolize_keys!
        raise ArgumentError, 'Cannot request hash with a default' if context.key?(:default)

        settings.where('name ILIKE ?', "#{name}.%").map do |vario_setting|
          [vario_setting.name.gsub("#{name}.", ''), vario_setting.value_for(context)]
        end.to_h.with_indifferent_access
      end

      def settings_save_unsaved
        return unless @vario_setting_cache

        @vario_setting_cache.each do |_key, vario_setting|
          vario_setting.save unless vario_setting.persisted?
        end
      end

      def settings_prepopulate_cache
        return if @vario_setting_cache

        @vario_setting_cache ||= {}
        settings.map do |vario_setting|
          @vario_setting_cache[vario_setting.name] ||= vario_setting
        end
      end
    end
  end
end
