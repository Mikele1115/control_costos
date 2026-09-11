Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  root "panel#index"

  get "margenes", to: "margenes#index"

  # Hay una sola: recurso singular, sin index ni id en la URL.
  resource :configuracion, only: %i[edit update]
  resources :destinatarios, only: %i[create update destroy]

  resources :proveedores

  resources :insumos do
    resources :precio_insumos, only: %i[new create destroy], path: "precios"
  end

  resources :recetas do
    # Duplicar MODIFICA el sistema, asi que es POST y no GET.
    post :duplicar, on: :member

    resources :ingredientes, only: %i[create destroy]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
