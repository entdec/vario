Vario::Engine.routes.draw do
  resources :settings do
    resources :levels do
      member do
        get :move_up
        get :move_down
      end
    end
  end
end
