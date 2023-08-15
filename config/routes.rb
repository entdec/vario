Vario::Engine.routes.draw do
  get 'settings/settings/filter_collection', action: :filter_collection, as: :filter_collection

  resources :settings do
    get :levels, on: :member
    get :filter_collection, on: :collection
    resources :levels do
      member do
        patch :move
      end
    end
  end
end
