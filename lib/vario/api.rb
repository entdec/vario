# frozen_literal_string: true

require 'grape-swagger'
require 'grape-swagger-entity'

module Vario
  class API < Grape::API
    default_format :json
    format :json

    helpers do
      def declared_params
        declared(params, include_missing: false)
      end

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

      # maybe use namespace combined with route_param[:id] ?

      Vario.config.settable_settings[configuration[:settable].name].each do |setting_name, setting_data|
        group_name, short_setting_name  = setting_name.split('.', 2)
        route_param :id, type: String do
          namespace group_name do
            desc "Get setting value" do
              detail "Get the setting value for #{setting_name}. setting_data[:description]"
            end
            params do
              setting_data[:keys].each do |context_key|
                optional context_key, type: String
              end
            end
            get "/#{short_setting_name}" do
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

            desc "Add or change setting value" do
              detail "Add or change setting value for #{setting_name}. setting_data[:description]"
            end
            params do
              setting_data[:keys].each do |context_key|
                optional context_key, type: String, documentation: { in: 'body' }
              end
              requires :value, type: setting_type, values: setting_data[:collection].present? ? setting_data[:collection].map { |item| item.last.to_s } : nil, documentation: { in: 'body' }
            end
            route [:post, :put], "/#{short_setting_name}" do
              record          = find_settable(declared_params[:id])
              context         = settable_setting_context(setting_name, declared_params.reject { |key, value| %w[id value].include?(key) }.to_h )
              vario_setting   = record.settings.find_or_initialize_by(name: setting_name)
              conditions_hash = context.values.compact.blank? ? {} : context
              level           = vario_setting.levels.find { |level| conditions_hash == level.conditions_hash }

              if level.nil?
                level = Level.new(vario_setting, { conditions: context })
                vario_setting.levels.unshift level
              end

              value = declared_params[:value]
              value = '1' if declared_params[:value] === true
              value = '0' if declared_params[:value] === false

              level.value = value
              vario_setting.save!

              { setting: setting_name, value: record.setting(setting_name, context) }
            end

            desc "Remove setting value" do
              detail "Remove setting value for #{setting_name}. setting_data[:description]"
            end
            params do
              setting_data[:keys].each do |context_key|
                optional context_key, type: String
              end
            end
            delete "/#{short_setting_name}" do
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
  end
end

