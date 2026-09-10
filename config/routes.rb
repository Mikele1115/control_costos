Rails.application.routes.draw do
  root "panel#index"

  resources :insumos do
    resources :precio_insumos, only: %i[new create destroy], path: "precios"
  end

  resources :recetas do
    # Duplicar MODIFICA el sistema, asi que es POST y no GET.
    # Un GET nunca debe cambiar nada: los navegadores y buscadores
    # los siguen solos, y un enlace que crea registros seria un
    # generador de basura.
    post :duplicar, on: :member

    resources :ingredientes, only: %i[create destroy]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
