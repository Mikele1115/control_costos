class ConfiguracionesController < ApplicationController
  include PantallaDeAjustes
  solo_administradores
  before_action :cargar_ajustes

  def edit
  end

  def update
    if @configuracion.update(configuracion_params)
      redirect_to edit_configuracion_path, notice: mensaje
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def mensaje
    return "Ajustes guardados. Los avisos están apagados." unless @configuracion.avisos_activos?
    return "Ajustes guardados, pero no hay nadie en la lista." unless @configuracion.avisar?

    "Ajustes guardados. Avisaremos desde un food cost de #{helpers.porcentaje(@configuracion.umbral_aviso)}."
  end

  def configuracion_params
    params.expect(configuracion: %i[avisos_activos umbral_aviso])
  end
end
