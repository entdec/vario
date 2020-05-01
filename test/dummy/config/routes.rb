Rails.application.routes.draw do
  resources :accounts
  resources :products

  mount Vario::Engine, at: '/vario', as: 'vario'
  mount Api, at: '/api'
end
