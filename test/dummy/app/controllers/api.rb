# frozen_string_literal: true

class Api < Grape::API
  mount({ Vario::API => '/account_settings' }, with: { settable: Account })
end
