Rails.application.routes.draw do
  root to: redirect('/accounts')

  resources :accounts
  resources :products

  # The engine has no root: its topics are
  get '/settings', to: redirect('/settings/topics')
  mount Vario::Engine, at: '/settings', as: 'vario'
  mount Api, at: '/api'
end
