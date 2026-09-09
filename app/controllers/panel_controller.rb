class PanelController < ApplicationController
  def index
    @fecha = fecha_solicitada

    @platos        = Receta.platos.order(:nombre)
    @preparaciones = Receta.preparaciones.order(:nombre)
    @sin_precio    = Insumo.where.missing(:precio_insumos).order(:nombre)
  end

  private

  # Los parametros vienen del exterior: nunca se confia en su formato.
  def fecha_solicitada
    return Date.current if params[:fecha].blank?
    Date.parse(params[:fecha])
  rescue Date::Error
    Date.current
  end
end
