class RecetasController < ApplicationController
  before_action :set_receta, only: %i[show]

  def index
    @fecha   = fecha_solicitada
    @recetas = Receta.order(:tipo, :nombre)
  end

  def show
    @fecha        = fecha_solicitada
    @ingredientes = @receta.ingredientes.includes(:insumable)
    @costeable    = @receta.costeable?(fecha: @fecha)
  end

  private

  def set_receta
    @receta = Receta.find(params[:id])
  end
end
