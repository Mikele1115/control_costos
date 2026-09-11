class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  # Entrar y salir queda fuera del sistema de permisos: ocurre antes
  # de tener rol, y cerrar sesion tiene que poder hacerlo cualquiera.
  permitir_sin_autorizacion
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: t("autenticacion.demasiados_intentos") }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: t("autenticacion.credenciales_invalidas")
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
