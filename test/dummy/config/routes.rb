Rails.application.routes.draw do
  mount Vario::Engine => "/vario"

  resources :accounts
end
