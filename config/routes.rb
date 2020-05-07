Vario::Engine.routes.draw do
  resources :settings do
    resources :levels do
      member do
        patch :move
      end
    end
  end
end
