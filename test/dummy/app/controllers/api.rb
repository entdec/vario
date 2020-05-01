# frozen_string_literal: true

module ApiHelpers
  extend ActiveSupport::Concern

  included do
    helpers do
      def require_api_key!
        error!('Access Denied', 403) unless params[:api_key] == 'ThisIsMyApiKey'
      end
    end
  end
end

class Api < Grape::API
  mount({ Vario::API => '/account_settings' }, with: { settable: Account })
  mount({ Vario::API => '/accounts' }, with: { settable: Account, prefix: :settings })
  mount({ Vario::API => '/settings_with_one_include_and_before' }, with: { settable: Account, include: ApiHelpers, before: :require_api_key! })
end
