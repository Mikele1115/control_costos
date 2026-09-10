class PanelController < ApplicationController
  def index
    @fecha = fecha_solicitada

    @platos        = Receta.platos.order(:nombre)
    @preparaciones = Receta.preparaciones.order(:nombre)
    @sin_precio    = Insumo.where.missing(:precio_insumos).order(:nombre)
  end
end
