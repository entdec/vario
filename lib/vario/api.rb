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

    desc 'Get settings'
    get '/all_settings' do
      settable_settings
    end

    desc 'Get setting value'
    params do
      requires :id, type: String
      requires :setting, type: String, documentation: { in: 'body' }
      requires :context, type: Hash, documentation: { in: 'body' }
    end
    post '/:id/get' do
      record  = find_settable(declared_params[:id])
      context = settable_setting_context(declared_params[:setting], declared_params[:context].to_h)

      { setting: declared_params[:setting], value: record.setting(declared_params[:setting], context) }
    end

    desc 'Set setting value'
    params do
      requires :id, type: String
      requires :setting, type: String, documentation: { in: 'body' }
      requires :context, type: Hash, documentation: { in: 'body' }
      requires :value, type: String, documentation: { in: 'body' }
    end
    post '/:id/set' do
      record        = find_settable(declared_params[:id])
      context       = settable_setting_context(declared_params[:setting], declared_params[:context].to_h)
      vario_setting = record.settings.find_or_initialize_by(name: declared_params[:setting])
      level         = vario_setting.levels.find { |level| context == level.conditions_hash }

      if level.nil?
        level = Level.new(vario_setting, { conditions: context })
        vario_setting.levels.unshift level
      end

      level.value = declared_params[:value]
      vario_setting.save!

      { setting: declared_params[:setting], value: record.setting(declared_params[:setting], context) }
    end

    desc 'Remove setting value'
    params do
      requires :id, type: String
      requires :setting, type: String, documentation: { in: 'body' }
      requires :context, type: Hash, documentation: { in: 'body' }
    end
    delete '/:id' do
      record  = find_settable(declared_params[:id])
      context = settable_setting_context(declared_params[:setting], declared_params[:context].to_h)

      vario_setting = record.settings.find_or_initialize_by(name: declared_params[:setting])
      vario_setting.levels.reject! { |level| context == level.conditions_hash }
      vario_setting.save!

      { setting: declared_params[:setting], value: record.setting(declared_params[:setting], context) }
    end
  end
end

