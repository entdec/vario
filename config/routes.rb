Vario::Engine.routes.draw do
  # A settable's topics, the settable signed in its settable param
  # (settable.to_sgid(for: 'Vario'))
  resources :topics, only: %i[index show update], param: :key do
    # For a setting's refinements' conditions: its variables at a path, and
    # an object variable's records
    member do
      get :variables
      get :records
    end
  end

  # 1.x's pages, until they go
  resources :settings do
    get :levels, on: :member
    resources :levels do
      member do
        patch :move
      end
    end
  end
end
