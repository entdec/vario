Vario::Engine.routes.draw do
  resources :settings do
    resource :levels
  end
end
