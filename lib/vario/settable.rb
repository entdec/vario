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

      # What a setting is in a context (1.x's way to read it, as explain)
      #
      #   account.setting('shipping.cutoff_time', location_id: id, default: '13:00')
      def setting(name, context = {})
        explain(name, context).value
      end

      # The values of a topic's settings by their keys (1.x)
      def settings_hash(name, context = {})
        raise ArgumentError, 'Cannot request hash with a default' if context.key?(:default) || context.key?('default')

        TopicReader.new(self, name, context).to_h.with_indifferent_access
      end

      # From 1.x, which created settings when they were read; 2.0 creates none
      def settings_save_unsaved; end

      # From 1.x; settings are loaded once anyway
      def settings_prepopulate_cache
        vario_settings_by_name
        nil
      end
    end
  end
end
