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

  # Settings on a page of the host's (render_vario_settings)
  resource :values, only: :update
end
