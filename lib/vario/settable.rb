# frozen_string_literal: true

module Vario
  module Settable
    extend ActiveSupport::Concern

    included do
      # What a setting is in a context, and why (Vario::Resolution)
      #
      #   account.explain('shipping.cutoff_time', order: order).source # => :refinement
      def explain(name, context = {})
        Resolver.new(self, vario_settings_by_name).explain(name, context)
      end

      # Its settings' rows by name, with their refinements, loaded once
      # (until reload)
      def vario_settings_by_name
        @vario_settings_by_name ||= public_send(vario_settings_association).includes(:refinements).index_by(&:name)
      end

      def reload(*)
        @vario_settings_by_name = nil
        super
      end

      if vario_settings_association == :settings
        # Without arguments its rows (Vario::Setting); with a topic the
        # values of its settings in a context:
        #
        #   account.settings(:shipping, order: order).cutoff_time
        def settings(topic = nil, context = {})
          return super() if topic.nil?

          TopicReader.new(self, topic, context)
        end
      end

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
