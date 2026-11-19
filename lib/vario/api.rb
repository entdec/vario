# frozen_string_literal: true

require 'grape-swagger'

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
        error!("#{settable.name} not found", 404) unless record.present?
        record
      end

      # The keys it was called with, without blanks
      def context_params
        declared_params.except('id', 'value').to_h.compact_blank
      end

      def setting_response(record, name, context)
        { setting: name, value: record.reload.setting(name, context) }
      end
    end

    class << self
      def value_type_for(definition)
        case definition.type
        when :array then Array[String]
        when :boolean then Grape::API::Boolean
        when :integer then Integer
        else String
        end
      end
    end

    given configuration[:settable] do
      [*configuration[:include]].each do |m|
        include m
      end

      before do
        [*configuration[:before]].each do |method|
          send(method) if method.is_a?(Symbol)
        end
      end if configuration[:before].present?

      Vario::Topic.for(configuration[:settable]).flat_map { |topic| topic.definitions.values }.each do |definition|
        setting_name = definition.name
        group_name, short_setting_name = setting_name.split('.', 2)

        next unless Vario.config.show_group?(group_name)

        keys        = definition.legacy_keys
        description = definition.description || definition.label
        choices     = definition.choice_values.map(&:to_s) if definition.choices.is_a?(Array)

        route_param :id, type: String do
          namespace configuration[:prefix] do
            namespace group_name do
              desc "Get setting value" do
                detail "Get the setting value for #{setting_name}. Setting description: #{description}"
              end
              params do
                keys.each do |context_key|
                  optional context_key, type: String
                end
              end
              scopes = [configuration[:oauth2].to_sym, "#{configuration[:oath2]}:read".to_sym] if configuration[:oauth2]
              scopes ||= nil
              get "/#{short_setting_name}", scopes: scopes do
                record = find_settable(declared_params[:id])

                { setting: setting_name, value: record.setting(setting_name, context_params) }
              end

              desc "Add or change setting value" do
                detail "Add or change setting value for #{setting_name}. Setting description: #{description}"
              end
              params do
                keys.each do |context_key|
                  optional context_key, type: String, documentation: { in: 'body' }
                end
                requires :value, type: API.value_type_for(definition), values: choices, documentation: { in: 'body' }
              end
              scopes = [configuration[:oauth2].to_sym, "#{configuration[:oath2]}:write".to_sym] if configuration[:oauth2]
              scopes ||= nil
              # Without keys the settable's own value, else the value of the
              # refinement on exactly those (a new one goes first, as 1.x's
              # levels did)
              route [:post, :put], "/#{short_setting_name}", scopes: scopes do
                record        = find_settable(declared_params[:id])
                context       = context_params
                vario_setting = record.settings.find_or_initialize_by(name: setting_name)

                vario_setting.value_on!(context, declared_params[:value])

                setting_response(record, setting_name, context)
              end

              desc "Remove setting value" do
                detail "Remove setting value for #{setting_name}. Setting description: #{description}"
              end
              params do
                keys.each do |context_key|
                  optional context_key, type: String
                end
              end
              scopes = [configuration[:oauth2].to_sym, "#{configuration[:oath2]}:write".to_sym] if configuration[:oauth2]
              scopes ||= nil
              # Without keys the settable's own value, else the refinements
              # on exactly those
              delete "/#{short_setting_name}", scopes: scopes do
                record        = find_settable(declared_params[:id])
                context       = context_params
                vario_setting = record.settings.find_by(name: setting_name)

                vario_setting&.value_on!(context, nil)

                setting_response(record, setting_name, context)
              end
            end
          end
        end
      end
    end
  end
end
