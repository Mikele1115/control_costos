Rails.application.routes.draw do
  root "panel#index"

  resources :insumos do
    # path: "precios" deja la URL bonita (/insumos/3/precios) sin
    # renombrar los helpers. Si le pusieramos `as:`, form_with dejaria
    # de encontrar la ruta: la deduce del nombre del modelo.
    resources :precio_insumos, only: %i[new create destroy], path: "precios"
  end

  resources :recetas do
    resources :ingredientes, only: %i[create destroy]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
