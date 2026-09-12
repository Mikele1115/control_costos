class UsersController < ApplicationController
  include PantallaDeAjustes
  solo_administradores
  before_action :set_user, only: %i[update destroy]
  before_action :impedir_tocarse_a_si_mismo, only: %i[update destroy]

  def create
    @usuario_nuevo = User.new(user_params)

    if @usuario_nuevo.save
      redirect_to edit_configuracion_path,
                  notice: "Cuenta creada para #{@usuario_nuevo.email_address}."
    else
      cargar_ajustes
      render "configuraciones/edit", status: :unprocessable_entity
    end
  end

  def update
    if @user.update(rol: params.expect(user: [ :rol ])[:rol])
      redirect_to edit_configuracion_path,
                  notice: "#{@user.email_address} ahora es #{@user.rol}."
    else
      cargar_ajustes
      render "configuraciones/edit", status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to edit_configuracion_path, notice: "Se eliminó la cuenta de #{@user.email_address}."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  # Esta unica regla garantiza que siempre quede al menos un
  # administrador: el ultimo no puede degradarse ni borrarse, porque
  # nadie puede hacerlo sobre su propia cuenta. No hace falta ademas
  # contar administradores.
  def impedir_tocarse_a_si_mismo
    return unless @user == Current.user

    redirect_to edit_configuracion_path,
                alert: "No puedes cambiar ni eliminar tu propia cuenta.",
                status: :see_other
  end

  def user_params
    params.expect(user: %i[email_address password rol])
  end
end
