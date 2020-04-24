# frozen_literal_string: true

require 'grape-swagger'
require 'grape-swagger-entity'

module Vario
  class API < Grape::API
    helpers do
      def settable
        configuration[:settable]
      end

      def settable_settings
        Vario.config.settable_settings[settable.name]
      end
    end

    desc 'Get settings'
    get '/' do
      settable_settings
    end

    desc 'Get setting for'
    params do
      requires :id, type: String
      requires :setting, type: String
      optional :context, type: Hash #
    end
    get '/:id/:setting' do
    end

    desc 'Add a setting'
    params do
      requires :id, type: String
      requires :setting, type: String
      optional :context, type: Hash #
    end
    post '/:id/:setting' do
    end

    desc 'Remove a setting'
    params do
      requires :id, type: String
      requires :setting, type: String
      optional :context, type: Hash #
    end
    delete '/:id/:setting' do
    end

    desc 'Update a setting'
    params do
      requires :id, type: String
      requires :setting, type: String
      optional :context, type: Hash #
    end
    put '/:id/:setting' do
    end
  end
end

