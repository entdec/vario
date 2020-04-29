# frozen_literal_string: true

require 'grape-swagger'
require 'grape-swagger-entity'

module Vario
  class API < Grape::API
    default_format :json
    format :json

    helpers do
      def settable
        configuration[:settable]
      end

      def find_settable(id)
        record = settable.find(id)
        error!(404, "#{settable.name} not found") unless record.present?
        record
      end

      def settable_settings
        Vario.config.settable_settings[settable.name]
      end

      def settable_setting(setting)
        settable_settings[setting]
      end

      def settable_setting_context(setting, context)
        vario_setting = settable_setting(setting)
        context.symbolize_keys!
        vario_setting[:keys].each do |key|
          context[key] ||= nil
        end
        context
      end
    end

    given configuration[:settable] do
      Vario.config.settable_settings[configuration[:settable].name].each do |setting_name, setting_data|
        desc "Retrieve setting value for setting #{setting_name}."
        params do
          requires :id, type: String
          setting_data[:keys].each do |context_key|
            optional context_key, type: String
          end
        end
        get "/:id/#{setting_name}" do
          record  = find_settable(declared_params[:id])
          context = settable_setting_context(setting_name, declared_params.reject { |key, value| key == 'id' }.to_h )

          { setting: setting_name, value: record.setting(setting_name, context) }
        end

        setting_type =
          case setting_data[:type]
          when :array
            Array[String]
          when :boolean
            Boolean
          when :integer
            Integer
          else
            String
          end

        desc "Set setting value for setting #{setting_name}."
        params do
          requires :id, type: String
          setting_data[:keys].each do |context_key|
            optional context_key, type: String, documentation: { in: 'body' }
          end
          requires :value, type: setting_type, documentation: { in: 'body' }
        end
        route [:post, :put], "/:id/#{setting_name}" do
          record          = find_settable(declared_params[:id])
          context         = settable_setting_context(setting_name, declared_params.reject { |key, value| %w[id value].include?(key) }.to_h )
          vario_setting   = record.settings.find_or_initialize_by(name: setting_name)
          conditions_hash = context.values.compact.blank? ? {} : context
          level           = vario_setting.levels.find { |level| conditions_hash == level.conditions_hash }

          if level.nil?
            level = Level.new(vario_setting, { conditions: context })
            vario_setting.levels.unshift level
          end

          level.value = declared_params[:value]
          vario_setting.save!

          { setting: setting_name, value: record.setting(setting_name, context) }
        end

        desc "Remove setting value for setting #{setting_name}."
        params do
          requires :id, type: String
          setting_data[:keys].each do |context_key|
            optional context_key, type: String
          end
        end
        delete "/:id/#{setting_name}" do
          record           = find_settable(declared_params[:id])
          context          = settable_setting_context(setting_name, declared_params.reject { |key, value| key == 'id' }.to_h )
          conditions_hash  = context.values.compact.blank? ? {} : context

          vario_setting = record.settings.find_or_initialize_by(name: setting_name)
          vario_setting.levels.reject! { |level| conditions_hash == level.conditions_hash }
          vario_setting.save!

          { setting: setting_name, value: record.setting(setting_name, context) }
        end
      end
    end
  end
end

