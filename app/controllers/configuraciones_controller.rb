class ConfiguracionesController < ApplicationController
  before_action :set_configuracion

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

  def set_configuracion
    @configuracion = Configuracion.actual
    @destinatarios = Destinatario.ordenados
    @destinatario  = Destinatario.new
  end

  def mensaje
    return "Ajustes guardados. Los avisos están apagados." unless @configuracion.avisos_activos?
    return "Ajustes guardados, pero no hay nadie en la lista." unless @configuracion.avisar?

    "Ajustes guardados. Avisaremos desde un food cost de #{helpers.porcentaje(@configuracion.umbral_aviso)}."
  end

  def configuracion_params
    params.expect(configuracion: %i[avisos_activos umbral_aviso])
  end
end
