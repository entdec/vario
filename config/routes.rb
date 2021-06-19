Vario::Engine.routes.draw do
  resources :settings do
    get :levels, on: :member
    resources :levels do
      member do
        patch :move
      end
    end
  end
end
