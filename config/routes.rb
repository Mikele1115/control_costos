Rails.application.routes.draw do
  root "panel#index"

  resources :insumos do
    resources :precios, only: %i[index new create destroy],
                        controller: "precio_insumos"
  end

  resources :recetas do
    resources :ingredientes, only: %i[create destroy]
  end

  # Chequeo de salud para balanceadores y monitores
  get "up" => "rails/health#show", as: :rails_health_check
end
