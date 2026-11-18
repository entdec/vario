Rails.application.routes.draw do
  root to: redirect('/accounts')

  resources :accounts
  resources :products

  # The engine has no root: its index needs a settable, the first account's here
  get '/settings', to: redirect { Vario::Engine.routes.url_helpers.settings_path(settable: Account.order(:name).first&.to_sgid(for: 'Vario').to_s) }
  mount Vario::Engine, at: '/settings', as: 'vario'
  mount Api, at: '/api'
end
